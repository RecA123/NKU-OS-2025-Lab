#include <slub_pmm.h>

#include <assert.h>
#include <list.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>

/* 当前实现仅面向单页容量的对象，超出单页的请求将返回 NULL。 */
/*
 * 实现了一个简化版的 SLUB 内存分配器，采用“两层架构”：
 *   1. 底层使用best_fit策略管理物理页，负责完成页粒度的物理内存分配与回收。
 *   2. 上层在页分配器之上构建 slab/对象缓存，支持任意尺寸的对象分配。
 *
 * 代码被拆分为若干区域：
 *   - 通用宏、结构体定义；
 *   - 页层分配与回收的内部工具函数；
 *   - SLUB 缓存（cache/slab）管理逻辑；
 *   - 面向外部的 API 以及check例程。
 */

/* 统一的日志/断言输出，便于快速定位失败场景 */
#define SLUB_LOG(...) cprintf("[slub] " __VA_ARGS__)
#define SLUB_ASSERT(cond)                                                  \
    do {                                                                   \
        if (!(cond)) {                                                     \
            cprintf("[slub] assertion failed: %s:%d: %s\n", __FILE__,      \
                    __LINE__, #cond);                                      \
            panic("slub assertion");                                       \
        }                                                                  \
    } while (0)

#define SLUB_SLAB_MAGIC 0xFFFFFFFFU /* slab 首页魔数，用于校验指针合法性   */
#define SLUB_FREELIST_END 0xFFFFu   /* 空闲对象链表终止标记                */
#define SLUB_MIN_ALIGN 8            /* 默认对齐要求，兼顾大多数内核对象     */
#define SLUB_DEFAULT_CLASS_COUNT 12 /* 默认 size class 数目                */
#define SLUB_MAX_CUSTOM_CACHES 8    /* 静态可维护的自定义 cache 数量上限    */

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

extern uint64_t va_pa_offset;

struct slub_cache;

/* slab 首页的元数据。结构体紧跟在页面起始位置，用于管理本页内对象。 */
struct slub_slab {
    uint32_t magic;              // 魔数，用于基本合法性检查
    struct slub_cache *cache;    // 指向所属的对象缓存
    struct Page *page;           // 物理页描述符，便于回收
    uint16_t free_count;         // 当前剩余空闲对象数
    uint16_t capacity;           // slab 可容纳的对象总数
    uint16_t free_head;          // 空闲对象链表头（保存的是索引）
    uint16_t obj_stride;         // 对象步长（包含对齐后大小）
    list_entry_t link;           // 串入 cache 的 partial/full 链表
};

/* 对象缓存，维护同类尺寸对象的 slab 列表与统计信息。 */
struct slub_cache {
    const char *name;            // 缓存名称（调试使用）
    size_t obj_size;             // 用户请求的对象大小
    size_t obj_stride;           // 实际分配的步长（包含对齐和 freelist 空间）
    size_t align;                // 对齐要求
    uint16_t objs_per_slab;      // 每个 slab 可容纳的对象数量
    size_t slabs_total;          // 当前总共持有的 slab 数
    size_t slabs_partial;        // 位于 partial 链表中的 slab 数
    size_t inuse_objs;           // 已分配但未释放的对象总数
    bool is_default;             // 是否为默认 size class
    bool active;                 // 缓存是否处于激活状态
    list_entry_t node;           // 串入全局 cache 链表
    list_entry_t partial;        // 局部链表：仍有空闲对象的 slab
    list_entry_t full;           // 局部链表：满载的 slab
};

static free_area_t page_area;

#define page_free_list (page_area.free_list)
#define page_nr_free (page_area.nr_free)

static list_entry_t slub_cache_list;

/* 默认 size class，覆盖常见的内核对象尺寸区间。 */
static const size_t slub_default_sizes[SLUB_DEFAULT_CLASS_COUNT] = {
    8, 16, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768,
};

static struct slub_cache slub_default_caches[SLUB_DEFAULT_CLASS_COUNT];
static char slub_default_names[SLUB_DEFAULT_CLASS_COUNT][16];

/* 自定义 cache 采用静态数组管理，避免依赖其他分配器。 */
static struct slub_cache slub_custom_caches[SLUB_MAX_CUSTOM_CACHES];
static bool slub_custom_used[SLUB_MAX_CUSTOM_CACHES];

/* ---------- 常用小工具 ---------- */

/* 将页描述符转换成内核直接映射地址。 */
static inline void *page2kva_local(struct Page *page) {
    return (void *)(page2pa(page) + va_pa_offset);
}

/* 将内核直接映射地址反向定位到页描述符。 */
static inline struct Page *kva2page_local(const void *kva) {
    uintptr_t kva_val = (uintptr_t)kva;
    SLUB_ASSERT(kva_val >= va_pa_offset);
    uintptr_t pa = kva_val - va_pa_offset;
    return pa2page(pa);
}

/* slab 内部对象区域的起始地址（紧挨着 struct slub_slab 之后）。 */
static inline uint8_t *slab_obj_base(struct slub_slab *slab) {
    return (uint8_t *)(slab + 1);
}

/* 结合 list_head 与容器结构之间的关系，取回 slab 指针。 */
static inline struct slub_slab *le2slab(list_entry_t *le) {
    return to_struct(le, struct slub_slab, link);
}

/* ---------- 底层：页级分配器 ---------- */

/* 初始化页层空闲链表与统计。 */
static void page_area_init(void) {
    list_init(&page_free_list);
    page_nr_free = 0;
}

/*
 * page_insert_block - 将一个空闲块按物理地址顺序插入空闲链表。
 * 保持链表有序有助于后续的合并操作。
 */
static void page_insert_block(struct Page *base) {
    list_entry_t *le = &page_free_list;
    while ((le = list_next(le)) != &page_free_list) {
        if (base < le2page(le, page_link)) {
            break;
        }
    }
    list_add_before(le, &(base->page_link));
}

/*
 * page_try_merge - 尝试与前后相邻空闲块合并，避免碎片。
 * 约定：base 已经插入到空闲链表。
 */
static void page_try_merge(struct Page *base) {
    list_entry_t *prev = list_prev(&(base->page_link));
    if (prev != &page_free_list) {
        struct Page *p = le2page(prev, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
    list_entry_t *next = list_next(&(base->page_link));
    if (next != &page_free_list) {
        struct Page *p = le2page(next, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

/*
 * slub_page_init_memmap - 接管一段连续物理页，建立空闲块描述。
 * 调用场景：内核在启动阶段发现空闲物理内存后调用 init_memmap。
 */
static void slub_page_init_memmap(struct Page *base, size_t n) {
    SLUB_ASSERT(n > 0);
    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        SLUB_ASSERT(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    page_nr_free += n;
    list_init(&(base->page_link));
    page_insert_block(base);
    page_try_merge(base);
}

/*
 * slub_page_alloc - 从空闲链表中申请 n 个连续页。
 * 算法：遍历寻找最小满足块（最佳适应），如有剩余切分到新节点。
 */
static struct Page *slub_page_alloc(size_t n) {
    SLUB_ASSERT(n > 0);
    if (n > page_nr_free) {
        return NULL;
    }
    struct Page *best = NULL;
    size_t best_size = 0;
    list_entry_t *le = &page_free_list;
    while ((le = list_next(le)) != &page_free_list) {
        struct Page *p = le2page(le, page_link);
        SLUB_ASSERT(PageProperty(p));
        if (p->property >= n &&
            (best == NULL || p->property < best_size)) {
            best = p;
            best_size = p->property;
        }
    }
    if (best == NULL) {
        return NULL;
    }
    list_del(&(best->page_link));
    if (best_size > n) {
        struct Page *remain = best + n;
        remain->property = best_size - n;
        SetPageProperty(remain);
        list_init(&(remain->page_link));
        page_insert_block(remain);
    }
    for (size_t i = 0; i < n; i++) {
        struct Page *p = best + i;
        p->property = 0;
        ClearPageProperty(p);
    }
    page_nr_free -= n;
    return best;
}

/*
 * slub_page_free - 归还连续的 n 个页，恢复空闲块并尝试合并。
 */
static void slub_page_free(struct Page *base, size_t n) {
    SLUB_ASSERT(n > 0);
    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        SLUB_ASSERT(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    page_nr_free += n;
    list_init(&(base->page_link));
    page_insert_block(base);
    page_try_merge(base);
}

static size_t slub_page_nr_free(void) {
    return page_nr_free;
}

/* ---------- 上层：SLUB 缓存与 slab 管理 ---------- */

/*
 * slub_cache_setup - 初始化 cache 元数据。
 * 说明：
 *   - 对齐值不足时最少使用 sizeof(uint16_t)，以容纳 freelist 索引。
 *   - obj_stride 经过对齐，确保每个对象 slot 在 slab 中结构一致。
 *   - objs_per_slab 根据单页可用空间计算，若不足一项则 cache 不可用。
 */
static void slub_cache_setup(struct slub_cache *cache, const char *name,
                             size_t obj_size, size_t align, bool is_default) {
    memset(cache, 0, sizeof(*cache));
    cache->name = name;
    cache->obj_size = obj_size;
    cache->align = (align == 0 ? SLUB_MIN_ALIGN : align);
    if (cache->align < sizeof(uint16_t)) {
        cache->align = sizeof(uint16_t);
    }
    size_t stride = obj_size;
    if (stride < sizeof(uint16_t)) {
        stride = sizeof(uint16_t);
    }
    stride = ROUNDUP(stride, cache->align);
    cache->obj_stride = stride;
    size_t usable = PGSIZE - sizeof(struct slub_slab);
    cache->objs_per_slab = (usable >= stride)
                               ? (uint16_t)(usable / stride)
                               : 0;
    cache->slabs_total = 0;
    cache->slabs_partial = 0;
    cache->inuse_objs = 0;
    cache->is_default = is_default;
    cache->active = 1;
    list_init(&cache->node);
    list_init(&cache->partial);
    list_init(&cache->full);
    list_add(&slub_cache_list, &cache->node);
}

/*
 * slub_select_cache - 根据请求尺寸在默认 size class 中选择最合适的 cache。
 * 返回第一个对象大小 >= 需求的缓存，若无则返回 NULL。
 */
static struct slub_cache *slub_select_cache(size_t size) {
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
        struct slub_cache *cache = &slub_default_caches[i];
        if (!cache->active) {
            continue;
        }
        if (size <= cache->obj_size) {
            return cache;
        }
    }
    return NULL;
}

/*
 * slub_alloc_cache_slot - 在静态数组中找一个空闲的 cache 槽位。
 * 该步骤避免使用额外的动态内存管理，从而在早期阶段也能安全运行。
 */
static struct slub_cache *slub_alloc_cache_slot(void) {
    for (size_t i = 0; i < SLUB_MAX_CUSTOM_CACHES; i++) {
        if (!slub_custom_used[i]) {
            slub_custom_used[i] = 1;
            return &slub_custom_caches[i];
        }
    }
    return NULL;
}

/* slub_release_cache_slot - 释放之前占用的自定义 cache 槽位。 */
static void slub_release_cache_slot(struct slub_cache *cache) {
    for (size_t i = 0; i < SLUB_MAX_CUSTOM_CACHES; i++) {
        if (&slub_custom_caches[i] == cache) {
            slub_custom_used[i] = 0;
            return;
        }
    }
}

/*
 * slub_new_slab - 从页层申请一页并初始化为新的 slab。
 * 步骤：
 *   1. 申请单页并清零结构体；
 *   2. 初始化空闲链表，将所有对象串成单向链接；
 *   3. 将新 slab 挂入 cache->partial。
 */
static struct slub_slab *slub_new_slab(struct slub_cache *cache) {
    SLUB_ASSERT(cache->objs_per_slab > 0);
    struct Page *page = slub_page_alloc(1);
    if (page == NULL) {
        return NULL;
    }
    struct slub_slab *slab = (struct slub_slab *)page2kva_local(page);
    memset(slab, 0, sizeof(*slab));
    slab->magic = SLUB_SLAB_MAGIC;
    slab->cache = cache;
    slab->page = page;
    slab->capacity = cache->objs_per_slab;
    slab->free_count = slab->capacity;
    slab->free_head = (slab->capacity == 0) ? SLUB_FREELIST_END : 0;
    slab->obj_stride = (uint16_t)cache->obj_stride;
    list_init(&slab->link);
    uint8_t *base = slab_obj_base(slab);
    for (uint16_t i = 0; i < slab->capacity; i++) {
        uint8_t *slot = base + i * slab->obj_stride;
        uint16_t next = (i + 1 < slab->capacity) ? (i + 1) : SLUB_FREELIST_END;
        *((uint16_t *)slot) = next;
    }
    cache->slabs_total++;
    cache->slabs_partial++;
    list_add(&cache->partial, &slab->link);
    return slab;
}

/*
 * slub_release_slab - 释放一个空闲 slab 对应的页面。
 * 要求 slab 上所有对象均为未使用状态。
 */
static void slub_release_slab(struct slub_slab *slab) {
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
    struct slub_cache *cache = slab->cache;
    slab->magic = 0;
    SLUB_ASSERT(slab->free_count == slab->capacity);
    SLUB_ASSERT(cache->slabs_total > 0);
    cache->slabs_total--;
    slub_page_free(slab->page, 1);
}

/*
 * slub_cache_do_alloc - 从指定 cache 分配一个对象。
 * 若 partial 链为空，会先创建新的 slab。
 */
static void *slub_cache_do_alloc(struct slub_cache *cache) {
    if (cache->objs_per_slab == 0) {
        return NULL;
    }
    if (list_empty(&cache->partial)) {
        if (slub_new_slab(cache) == NULL) {
            return NULL;
        }
    }
    list_entry_t *le = list_next(&cache->partial);
    struct slub_slab *slab = le2slab(le);
    SLUB_ASSERT(slab->free_count > 0);
    uint16_t obj_index = slab->free_head;
    uint8_t *slot = slab_obj_base(slab) + obj_index * slab->obj_stride;
    slab->free_head = *((uint16_t *)slot);
    slab->free_count--;
    cache->inuse_objs++;
    if (slab->free_count == 0) {
        list_del(&slab->link);
        list_add(&cache->full, &slab->link);
        SLUB_ASSERT(cache->slabs_partial > 0);
        cache->slabs_partial--;
    }
    memset(slot, 0, cache->obj_size);
    return slot;
}

/*
 * slub_cache_do_free - 将对象归还给 slab。
 * 注意：obj 必须来自 cache 对应的 slab 中。
 */
static void slub_cache_do_free(struct slub_cache *cache, struct slub_slab *slab,
                               void *obj) {
    uint8_t *base = slab_obj_base(slab);
    uintptr_t offset = (uint8_t *)obj - base;
    SLUB_ASSERT(offset % slab->obj_stride == 0);
    uint16_t idx = offset / slab->obj_stride;
    *((uint16_t *)obj) = slab->free_head;
    slab->free_head = idx;
    slab->free_count++;
    SLUB_ASSERT(cache->inuse_objs > 0);
    cache->inuse_objs--;
    if (slab->free_count == 1) {
        list_del(&slab->link);
        list_add(&cache->partial, &slab->link);
        cache->slabs_partial++;
    }
    if (slab->free_count == slab->capacity) {
        list_del(&slab->link);
        SLUB_ASSERT(cache->slabs_partial > 0);
        cache->slabs_partial--;
        slub_release_slab(slab);
    }
}

/*
 * slub_bootstrap_default_caches - 为默认尺寸类填充名称并初始化元数据。
 */
static void slub_bootstrap_default_caches(void) {
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
        struct slub_cache *cache = &slub_default_caches[i];
        snprintf(slub_default_names[i],
                 sizeof(slub_default_names[i]),
                 "slub-%u", (unsigned)slub_default_sizes[i]);
        slub_cache_setup(cache, slub_default_names[i],
                         slub_default_sizes[i], SLUB_MIN_ALIGN, 1);
    }
}

/* 回收 cache 时遍历所有剩余 slab 并释放之。 */
static void slub_cache_cleanup(struct slub_cache *cache) {
    SLUB_ASSERT(cache != NULL);
    SLUB_ASSERT(cache->inuse_objs == 0);
    while (!list_empty(&cache->partial)) {
        list_entry_t *le = list_next(&cache->partial);
        struct slub_slab *slab = le2slab(le);
        list_del(&slab->link);
        SLUB_ASSERT(slab->free_count == slab->capacity);
        SLUB_ASSERT(cache->slabs_partial > 0);
        cache->slabs_partial--;
        slub_release_slab(slab);
    }
    SLUB_ASSERT(list_empty(&cache->full));
    list_del_init(&cache->node);
    cache->active = 0;
}

struct slub_cache *slub_cache_create(const char *name, size_t obj_size,
                                     size_t align) {
    struct slub_cache *slot = slub_alloc_cache_slot();
    if (slot == NULL) {
        return NULL;
    }
    slub_cache_setup(slot, name, obj_size, align, 0);
    return slot;
}

void slub_cache_destroy(struct slub_cache *cache) {
    if (cache == NULL) {
        return;
    }
    slub_cache_cleanup(cache);
    if (!cache->is_default) {
        slub_release_cache_slot(cache);
    }
}

void *slub_cache_alloc(struct slub_cache *cache) {
    if (cache == NULL || !cache->active) {
        return NULL;
    }
    void *ptr = slub_cache_do_alloc(cache);
    return ptr;
}

void slub_cache_free(struct slub_cache *cache, void *obj) {
    if (cache == NULL || obj == NULL) {
        return;
    }
    struct Page *page = kva2page_local(obj);
    struct slub_slab *slab = (struct slub_slab *)page2kva_local(page);
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
    SLUB_ASSERT(slab->cache == cache);
    slub_cache_do_free(cache, slab, obj);
}

void *slub_alloc(size_t size) {
    if (size == 0) {
        return NULL;
    }
    struct slub_cache *cache = slub_select_cache(size);
    if (cache != NULL) {
        return slub_cache_do_alloc(cache);
    }
    /* 设计约束：当前实现仅覆盖单页 SLUB 缓存，不支持跨页大对象。 */
    return NULL;
}

void slub_free(void *ptr) {
    if (ptr == NULL) {
        return;
    }
    struct Page *page = kva2page_local(ptr);
    void *base = page2kva_local(page);
    uint32_t magic = *((uint32_t *)base);
    SLUB_ASSERT(magic == SLUB_SLAB_MAGIC);
    struct slub_slab *slab = (struct slub_slab *)base;
    slub_cache_do_free(slab->cache, slab, ptr);
}

void slub_dump_stats(void) {
    list_entry_t *le = &slub_cache_list;
    while ((le = list_next(le)) != &slub_cache_list) {
        struct slub_cache *cache = to_struct(le, struct slub_cache, node);
        SLUB_LOG("cache %s: obj=%u stride=%u per_slab=%u total_slabs=%u inuse=%u\n",
                 cache->name, (unsigned)cache->obj_size,
                 (unsigned)cache->obj_stride, (unsigned)cache->objs_per_slab,
                 (unsigned)cache->slabs_total, (unsigned)cache->inuse_objs);
    }
}

/* ---------- 自检check ---------- */

/* 基础页分配/释放验证。 */
static void slub_page_basic_check(void) {
    SLUB_LOG("page_basic_check begin\n");
    struct Page *p0 = slub_page_alloc(1);
    struct Page *p1 = slub_page_alloc(1);
    struct Page *p2 = slub_page_alloc(1);
    SLUB_ASSERT(p0 != NULL && p1 != NULL && p2 != NULL);
    SLUB_ASSERT(p0 != p1 && p0 != p2 && p1 != p2);
    slub_page_free(p0, 1);
    slub_page_free(p1, 1);
    slub_page_free(p2, 1);
    SLUB_LOG("page_basic_check passed\n");
}

/* 验证碎片化场景下的合并能力。 */
static void slub_page_fragment_check(void) {
    SLUB_LOG("page_fragment_check begin\n");
    struct Page *block = slub_page_alloc(8);
    SLUB_ASSERT(block != NULL);
    struct Page *middle = block + 3;
    slub_page_free(block, 3);
    slub_page_free(middle, 5);
    struct Page *all = slub_page_alloc(8);
    SLUB_ASSERT(all == block);
    slub_page_free(all, 8);
    SLUB_LOG("page_fragment_check passed\n");
}

/* 验证自定义 cache 的分配、释放及 slab 复用行为。 */
static void slub_cache_basic_check(void) {
    SLUB_LOG("cache_basic_check begin\n");
    struct slub_cache *cache = slub_cache_create("test-64", 64, SLUB_MIN_ALIGN);
    SLUB_ASSERT(cache != NULL);
    size_t per = cache->objs_per_slab;
    SLUB_ASSERT(per > 0);
    size_t total = per * 2;
    void *objs[256];
    SLUB_ASSERT(total <= ARRAY_SIZE(objs));
    for (size_t i = 0; i < total; i++) {
        objs[i] = slub_cache_alloc(cache);
        SLUB_ASSERT(objs[i] != NULL);
        memset(objs[i], 0xA5, 64);
        for (size_t j = 0; j < i; j++) {
            SLUB_ASSERT(objs[i] != objs[j]);
        }
    }
    for (size_t i = 0; i < total; i += 2) {
        slub_cache_free(cache, objs[i]);
        objs[i] = NULL;
    }
    for (size_t i = 0; i < total; i++) {
        if (objs[i] != NULL) {
            slub_cache_free(cache, objs[i]);
            objs[i] = NULL;
        }
    }
    SLUB_ASSERT(cache->slabs_total == 0);
    slub_cache_destroy(cache);
    SLUB_LOG("cache_basic_check passed\n");
}

/* 综合测试 slub_alloc/slub_free 是否保持页数一致。 */
static void slub_alloc_general_check(void) {
    SLUB_LOG("alloc_general_check begin\n");
    size_t before = slub_page_nr_free();
    size_t sizes[] = {1, 7, 15, 23, 63, 117, 191, 255, 383, 511};
    void *ptrs[ARRAY_SIZE(sizes)];
    for (size_t i = 0; i < ARRAY_SIZE(sizes); i++) {
        ptrs[i] = slub_alloc(sizes[i]);
        SLUB_ASSERT(ptrs[i] != NULL);
        memset(ptrs[i], 0x3C, sizes[i]);
    }
    for (size_t i = 0; i < ARRAY_SIZE(sizes); i++) {
        slub_free(ptrs[i]);
    }
    size_t after = slub_page_nr_free();
    SLUB_ASSERT(before == after);
    SLUB_LOG("alloc_general_check passed\n");
}

/* 批量压力测试，验证在多轮操作下的稳定性。 */
static void slub_stress_check(void) {
    SLUB_LOG("stress_check begin\n");
    const size_t rounds = 4;
    const size_t batch = 96;
    void *ptrs[batch];
    for (size_t r = 0; r < rounds; r++) {
        for (size_t i = 0; i < batch; i++) {
            ptrs[i] = slub_alloc(48);
            SLUB_ASSERT(ptrs[i] != NULL);
        }
        for (size_t i = 0; i < batch; i++) {
            slub_free(ptrs[i]);
        }
    }
    SLUB_LOG("stress_check passed\n");
}

static void slub_check(void) {
    slub_page_basic_check();
    slub_page_fragment_check();
    slub_cache_basic_check();
    slub_alloc_general_check();
    slub_stress_check();
    SLUB_LOG("all checks passed\n");
}

/* ---------- pmm_manager 接口实现 ---------- */

static void slub_init(void) {
    page_area_init();
    list_init(&slub_cache_list);
    memset(slub_custom_used, 0, sizeof(slub_custom_used));
    slub_bootstrap_default_caches();
}

static void slub_init_memmap(struct Page *base, size_t n) {
    slub_page_init_memmap(base, n);
}

static struct Page *slub_alloc_pages_iface(size_t n) {
    return slub_page_alloc(n);
}

static void slub_free_pages_iface(struct Page *base, size_t n) {
    slub_page_free(base, n);
}

static size_t slub_nr_free_pages_iface(void) {
    return slub_page_nr_free();
}

const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages_iface,
    .free_pages = slub_free_pages_iface,
    .nr_free_pages = slub_nr_free_pages_iface,
    .check = slub_check,
};
