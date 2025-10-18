#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>

/*
 * 面向教学的 SLUB 风格物理页分配器。
 *
 * 实现复刻了 Linux SLUB 的双层设计思想：
 *   1. “页分配器”（此处复用最佳适配风格的空闲链表）负责按 slab 为单位
 *      申请连续页块，每个 slab 由固定数量的页组成。
 *   2. 每个 slab 再被切分为页大小的对象并缓存在“部分占用”链表上，
 *      使得频繁的单页申请无需访问全局空闲链表。
 *
 * 与 Linux 不同，本版本只面向 uCore 的单核教学环境，
 * 因此省去了每 CPU 缓存以及调试设施，但保留了 slab 供给与对象分配的核心分离。
 */

/* -------------------------------------------------------------------------- */
/* 配置参数                                                                    */
/* -------------------------------------------------------------------------- */

/* 每个 slab 中包含的页数（=2^order，对应 Linux SLUB 中的 oo_order）。 */
#define SLUB_SLAB_ORDER      2U
#define SLUB_SLAB_PAGES      (1U << SLUB_SLAB_ORDER)

/* slab 内部对象的粒度：此版本中一个对象就是一页。 */
#define SLUB_OBJECT_PAGES    1U
#define SLUB_OBJECTS_PER_SLAB (SLUB_SLAB_PAGES / SLUB_OBJECT_PAGES)

/* 基于 uCore 支持的最大物理内存推导出的全局上限。 */
#define MAX_PHYS_PAGES       (KMEMSIZE / PGSIZE)
#define MAX_SLABS            ((MAX_PHYS_PAGES + SLUB_SLAB_PAGES - 1) / SLUB_SLAB_PAGES)

/* 每个页的状态值，用于区分是否由 SLUB 管理。 */
#define SLUB_STATE_UNUSED    0   /* 页未被 SLUB 跟踪（仍由后端管理）。 */
#define SLUB_STATE_FREE      1   /* 页隶属于某个 slab，当前空闲。 */
#define SLUB_STATE_ALLOCATED 2   /* 页隶属于某个 slab，当前已分配。 */

/* 帮助宏：从 slab 链表节点恢复出其元数据结构指针。 */
#define le2slab(le) to_struct((le), struct slub_slab_meta, link)

/* -------------------------------------------------------------------------- */
/* 后端页分配器（第一层）                                                      */
/* -------------------------------------------------------------------------- */

/*
 * 后端页分配器是对最佳适配算法（best-fit）的轻量改写。
 * 它只负责维护较大的连续空闲物理页块，对上层的 slab 管理一无所知；
 * slab 层在需要时向它申请一整块 slab，用完后再完整归还。
 * 通过这种分层设计，既保留了通用的页块回收机制，又能让 slab 层专注于小对象复用。
 */
typedef struct {
    list_entry_t free_list;    // 按物理地址排序的空闲块链表
    size_t nr_free;            // 后端当前持有的空闲页总数
} backend_area_t;

static backend_area_t backend_area;

#define backend_free_list (backend_area.free_list)
#define backend_nr_free   (backend_area.nr_free)

/* 初始化后端页分配器的状态。 */
static void
backend_init(void) {
    list_init(&backend_free_list);
    backend_nr_free = 0;
}

/* 前向声明：使得 slab 层可以在 slab 完全空闲时归还给后端。 */
static void backend_free_pages(struct Page *base, size_t n);

/*
 * 将新的空闲块 [base, base + n) 插入后端链表。
 * 这些页既可能来自启动阶段（init_memmap），也可能来自 slab 层归还的整块 slab。
 */
static void
backend_insert_block(struct Page *base, size_t n) {
    assert(n > 0);

    // 恢复页元数据，确保重新挂回空闲链表时处于干净状态。
    struct Page *p = base;
    list_entry_t *le;
    list_entry_t *prev;
    list_entry_t *next;
    struct Page *page;
    struct Page *pp;
    struct Page *np;

    for (; p != base + n; ++p) {
        p->flags = 0;
        set_page_ref(p, 0);
        ClearPageProperty(p);
    }

    base->property = n;
    SetPageProperty(base);
    backend_nr_free += n;

    if (list_empty(&backend_free_list)) {
        list_add(&backend_free_list, &(base->page_link));
        return;
    }

    le = &backend_free_list;
    while ((le = list_next(le)) != &backend_free_list) {
        page = le2page(le, page_link);
        if (base < page) {
            list_add_before(le, &(base->page_link));
            goto try_merge;
        }
    }

    // 没有找到更高地址的插入点，则挂到链表尾部。
    list_add(list_prev(&backend_free_list), &(base->page_link));

try_merge:
    /*
     * 如果插入范围与链表前后相邻，尝试做物理合并，
     * 以保持后端空闲块尽量大，降低外部碎片。
     */
    prev = list_prev(&(base->page_link));
    if (prev != &backend_free_list) {
        pp = le2page(prev, page_link);
        if (pp + pp->property == base) {
            pp->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = pp;
        }
    }

    next = list_next(&(base->page_link));
    if (next != &backend_free_list) {
        np = le2page(next, page_link);
        if (base + base->property == np) {
            base->property += np->property;
            ClearPageProperty(np);
            list_del(&(np->page_link));
        }
    }
}

/*
 * 从后端分配不少于 n 页，算法沿用经典的最佳适配搜索。
 * 实质上与 best_fit_alloc_pages 相同，但只在本模块内部使用，
 * 方便 slab 层按需拉取 slab，而无需暴露额外的内存管理器接口。
 */
static struct Page *
backend_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > backend_nr_free) {
        return NULL;
    }

    struct Page *candidate = NULL;
    size_t best_size = backend_nr_free + 1;
    list_entry_t *le = &backend_free_list;

    while ((le = list_next(le)) != &backend_free_list) {
        struct Page *page = le2page(le, page_link);
        if (page->property >= n && page->property < best_size) {
            candidate = page;
            best_size = page->property;
        }
    }

    if (candidate == NULL) {
        return NULL;
    }

    list_entry_t *prev = list_prev(&(candidate->page_link));
    list_del(&(candidate->page_link));

    if (candidate->property > n) {
        struct Page *remain = candidate + n;
        remain->property = candidate->property - n;
        SetPageProperty(remain);
        list_add(prev, &(remain->page_link));
    }

    backend_nr_free -= n;
    ClearPageProperty(candidate);
    return candidate;
}

/*
 * 释放不少于 n 页回到后端；这些页必须来源于 backend_alloc_pages，
 * 否则会破坏后端的块结构。
 */
static void
backend_free_pages(struct Page *base, size_t n) {
    assert(n > 0);

    struct Page *p = base;
    for (; p != base + n; ++p) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    backend_insert_block(base, n);
}

static size_t
backend_nr_free_pages(void) {
    return backend_nr_free;
}

/* -------------------------------------------------------------------------- */
/* Slab 元数据（第二层）                                                       */
/* -------------------------------------------------------------------------- */

struct slub_slab_meta {
    struct Page *base;       // slab 的首页指针，未使用时为 NULL
    struct Page *freelist;   // slab 内第一块空闲对象（页）
    unsigned int free_objects;   // 当前 slab 中空闲对象数量
    unsigned int total_objects;  // 记录该 slab 总对象数（等于 SLUB_OBJECTS_PER_SLAB）
    int on_partial;          // 连接在部分占用链表时为非零
    int on_full;             // 连接在满载链表时为非零
    list_entry_t link;       // 用于挂接到 partial/full 链表的结点指针
};

static struct slub_slab_meta slab_table[MAX_SLABS];
static struct Page *slub_page_next[MAX_PHYS_PAGES];
static uint8_t slub_page_state[MAX_PHYS_PAGES];

static struct {
    list_entry_t partial;    // 至少还有一个空闲对象的 slab
    list_entry_t full;       // 已无空闲对象的 slab（保留用于说明状态）
    size_t free_objects_total;
} slub_cache;

static int slub_initialized;

/* 一组便捷函数，在 Page* 与索引化存储之间转换。 */
static inline size_t
page_index(struct Page *page) {
    return (size_t)(page - pages);
}

static inline struct slub_slab_meta *
page_to_slab(struct Page *page) {
    size_t idx = page_index(page) / SLUB_SLAB_PAGES;
    assert(idx < MAX_SLABS);
    return &slab_table[idx];
}

static inline void
slub_object_set_next(struct Page *page, struct Page *next) {
    slub_page_next[page_index(page)] = next;
}

static inline struct Page *
slub_object_get_next(struct Page *page) {
    return slub_page_next[page_index(page)];
}

static inline uint8_t
slub_object_state(struct Page *page) {
    return slub_page_state[page_index(page)];
}

static inline void
slub_object_set_state(struct Page *page, uint8_t state) {
    slub_page_state[page_index(page)] = state;
}

static void
slub_cache_add_partial(struct slub_slab_meta *meta) {
    if (!meta->on_partial) {
        list_add(&slub_cache.partial, &(meta->link));
        meta->on_partial = 1;
    }
}

static void
slub_cache_remove_partial(struct slub_slab_meta *meta) {
    if (meta->on_partial) {
        list_del(&(meta->link));
        meta->on_partial = 0;
        list_init(&(meta->link));
    }
}

static void
slub_cache_move_to_full(struct slub_slab_meta *meta) {
    slub_cache_remove_partial(meta);
    list_add(&slub_cache.full, &(meta->link));
    meta->on_full = 1;
}

static void
slub_cache_remove_from_full(struct slub_slab_meta *meta) {
    if (meta->on_full) {
        list_del(&(meta->link));
        list_init(&(meta->link));
        meta->on_full = 0;
    }
}

/*
 * 为后端新返回的 slab 填充元数据并初始化 freelist。
 * 这里会把 slab 内的每一页串成单向链表，同时标记状态为 FREE，
 * 以便上层可以快速地按页粒度分配。
 */
static void
slub_prepare_slab(struct Page *base) {
    struct slub_slab_meta *meta = page_to_slab(base);

    meta->base = base;
    meta->freelist = base;
    meta->free_objects = SLUB_OBJECTS_PER_SLAB;
    meta->total_objects = SLUB_OBJECTS_PER_SLAB;
    meta->on_partial = 0;
    meta->on_full = 0;
    list_init(&(meta->link));

    for (unsigned int i = 0; i < SLUB_OBJECTS_PER_SLAB; ++i) {
        struct Page *page = base + (i * SLUB_OBJECT_PAGES);
        struct Page *next = (i + 1 < SLUB_OBJECTS_PER_SLAB)
                                ? (page + SLUB_OBJECT_PAGES)
                                : NULL;
        slub_object_set_next(page, next);
        slub_object_set_state(page, SLUB_STATE_FREE);
        page->flags = 0;
        set_page_ref(page, 0);
    }

    slub_cache.free_objects_total += SLUB_OBJECTS_PER_SLAB;
    slub_cache_add_partial(meta);
}

/*
 * 当 slab 中所有对象都被归还时，将其彻底拆除并把物理页交还后端。
 * 需要重置状态，防止旧的 next 指针泄露到下一次使用。
 */
static void
slub_release_slab(struct slub_slab_meta *meta) {
    assert(meta->base != NULL);
    slub_cache_remove_partial(meta);
    slub_cache_remove_from_full(meta);

    for (unsigned int i = 0; i < meta->total_objects; ++i) {
        struct Page *page = meta->base + (i * SLUB_OBJECT_PAGES);
        slub_object_set_state(page, SLUB_STATE_UNUSED);
        slub_object_set_next(page, NULL);
    }

    size_t pages = meta->total_objects * SLUB_OBJECT_PAGES;
    slub_cache.free_objects_total -= meta->total_objects;
    struct Page *base = meta->base;

    meta->base = NULL;
    meta->freelist = NULL;
    meta->free_objects = 0;
    meta->total_objects = 0;
    meta->on_full = 0;

    backend_free_pages(base, pages);
}

/* 从 slab 中取出一个空闲页对象，用于满足上层的单页分配。 */
static struct Page *
slub_pop_object(struct slub_slab_meta *meta) {
    assert(meta->freelist != NULL);
    struct Page *page = meta->freelist;
    struct Page *next = slub_object_get_next(page);

    meta->freelist = next;
    meta->free_objects--;
    slub_cache.free_objects_total--;
    slub_object_set_state(page, SLUB_STATE_ALLOCATED);
    slub_object_set_next(page, NULL);

    if (meta->free_objects == 0) {
        slub_cache_move_to_full(meta);
    }

    ClearPageProperty(page);
    return page;
}

/* 将归还的页对象重新压回所在 slab 的 freelist，并根据状态更新链表。 */
static void
slub_push_object(struct slub_slab_meta *meta, struct Page *page) {
    slub_object_set_next(page, meta->freelist);
    slub_object_set_state(page, SLUB_STATE_FREE);
    meta->freelist = page;
    meta->free_objects++;
    slub_cache.free_objects_total++;
    page->flags = 0;
    set_page_ref(page, 0);

    slub_cache_remove_from_full(meta);
    if (meta->free_objects == 1) {
        slub_cache_add_partial(meta);
    }
    if (meta->free_objects == meta->total_objects) {
        slub_release_slab(meta);
    }
}

/* 提供给 PMM 接口的查询函数，返回 slab 层尚未用掉的页数量。 */
static size_t
slub_nr_free_objects(void) {
    return slub_cache.free_objects_total;
}

/* -------------------------------------------------------------------------- */
/* PMM 管理器前端接口                                                           */
/* -------------------------------------------------------------------------- */

static void
slub_init(void) {
    if (slub_initialized) {
        return;
    }
    backend_init();
    memset(slab_table, 0, sizeof(slab_table));
    memset(slub_page_next, 0, sizeof(slub_page_next));
    memset(slub_page_state, 0, sizeof(slub_page_state));

    list_init(&slub_cache.partial);
    list_init(&slub_cache.full);
    slub_cache.free_objects_total = 0;
    slub_initialized = 1;
}

/*
 * init_memmap 会在启动阶段，对每一段探测到的空闲物理内存调用一次。
 * 此时我们直接把页面交给后端分配器；真正的 slab 会在首次分配时按需切割。
 */
static void
slub_init_memmap(struct Page *base, size_t n) {
    assert(slub_initialized);
    backend_insert_block(base, n);
}

/*
 * 单页分配逻辑：
 *   1. 优先从 partial 链表中取 slab；若链表为空则向后端申请新 slab。
 *   2. 调用 slub_pop_object 弹出一个页对象。
 */
static struct Page *
slub_alloc_small(void) {
    if (list_empty(&slub_cache.partial)) {
        struct Page *slab_base = backend_alloc_pages(SLUB_SLAB_PAGES);
        if (slab_base == NULL) {
            return NULL;
        }
        slub_prepare_slab(slab_base);
    }

    struct slub_slab_meta *meta = le2slab(list_next(&slub_cache.partial));
    return slub_pop_object(meta);
}

/* 多页或跨 slab 的需求直接透传给后端，以复用 best-fit 能力。 */
static struct Page *
slub_alloc_large(size_t n) {
    struct Page *page = backend_alloc_pages(n);
    return page;
}

static struct Page *
slub_alloc_pages(size_t n) {
    assert(n > 0);
    if (n == SLUB_OBJECT_PAGES) {
        return slub_alloc_small();
    }
    return slub_alloc_large(n);
}

/* 将单页释放回 slab，自然复用 partial/full 链表的维护逻辑。 */
static void
slub_free_small(struct Page *page) {
    struct slub_slab_meta *meta = page_to_slab(page);
    assert(meta->base != NULL);
    slub_push_object(meta, page);
}

/* 多页释放相对稀疏，直接交还给后端集中维护。 */
static void
slub_free_large(struct Page *base, size_t n) {
    backend_free_pages(base, n);
}

/*
 * 按请求的规模决定释放路径：
 *   - 单页且已被 SLUB 接管：走 slab 回收；
 *   - 其他情况：走后端回收。
 */
static void
slub_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    if (n == SLUB_OBJECT_PAGES && slub_object_state(base) != SLUB_STATE_UNUSED) {
        slub_free_small(base);
    } else {
        slub_free_large(base, n);
    }
}

static size_t
slub_nr_free_pages_wrapper(void) {
    return backend_nr_free_pages() + slub_nr_free_objects();
}

/* -------------------------------------------------------------------------- */
/* 自测函数                                                                    */
/* -------------------------------------------------------------------------- */

static void
slub_basic_check(void) {
    struct Page *pages_buf[SLUB_OBJECTS_PER_SLAB];

    // 申请一个 slab 的全部页，确保返回的页互不相同。
    for (unsigned int i = 0; i < SLUB_OBJECTS_PER_SLAB; ++i) {
        struct Page *p = slub_alloc_pages(1);
        assert(p != NULL);
        pages_buf[i] = p;
        assert(slub_object_state(p) == SLUB_STATE_ALLOCATED);
    }

    // 下一次分配应该命中新 slab。
    struct Page *p_extra = slub_alloc_pages(1);
    assert(p_extra != NULL);
    struct slub_slab_meta *meta0 = page_to_slab(pages_buf[0]);
    struct slub_slab_meta *meta_extra = page_to_slab(p_extra);
    assert(meta0 != meta_extra);

    // 释放第一个 slab 的所有页，检查是否重新合并。
    for (unsigned int i = 0; i < SLUB_OBJECTS_PER_SLAB; ++i) {
        slub_free_pages(pages_buf[i], 1);
        assert(slub_object_state(pages_buf[i]) != SLUB_STATE_ALLOCATED);
    }

    // 全部对象释放后，该 slab 应当被归还给后端。
    assert(meta0->base == NULL);

    // 释放额外申请的那一页。
    slub_free_pages(p_extra, 1);
}

static void
slub_mixed_size_check(void) {
    // 先直接向后端申请大块，确保计数不会错乱。
    const size_t large_n = SLUB_SLAB_PAGES * 2;
    struct Page *block = slub_alloc_pages(large_n);
    assert(block != NULL);

    size_t before = slub_nr_free_pages_wrapper();
    struct Page *p = slub_alloc_pages(1);
    assert(p != NULL);
    slub_free_pages(p, 1);
    size_t after = slub_nr_free_pages_wrapper();
    assert(before == after);

    slub_free_pages(block, large_n);
}

static void
slub_partial_reuse_check(void) {
    const unsigned int sample = SLUB_OBJECTS_PER_SLAB + 2;
    struct Page *pages_local[sample];

    for (unsigned int i = 0; i < sample; ++i) {
        pages_local[i] = slub_alloc_pages(1);
        assert(pages_local[i] != NULL);
    }

    struct Page *candidate = pages_local[SLUB_OBJECTS_PER_SLAB - 1];
    struct slub_slab_meta *meta = page_to_slab(candidate);
    assert(meta->free_objects == 0);
    assert(meta->on_full);

    slub_free_pages(candidate, 1);
    assert(meta->free_objects == 1);
    assert(meta->on_partial);
    assert(!meta->on_full);

    struct Page *reused = slub_alloc_pages(1);
    assert(reused == candidate);
    assert(meta->on_full || meta->free_objects == 0);

    pages_local[SLUB_OBJECTS_PER_SLAB - 1] = reused;
    for (unsigned int i = 0; i < sample; ++i) {
        slub_free_pages(pages_local[i], 1);
    }
}

static void
slub_check(void) {
    slub_basic_check();
    slub_mixed_size_check();
    slub_partial_reuse_check();
}

/* -------------------------------------------------------------------------- */
/* 管理器描述表                                                                */
/* -------------------------------------------------------------------------- */

const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages_wrapper,
    .check = slub_check,
};
