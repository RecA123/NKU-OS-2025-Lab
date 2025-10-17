#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>

/*
 * A teaching-oriented SLUB style physical page allocator.
 *
 * The implementation mirrors the two-layer idea of Linux's SLUB:
 *   1. A "page allocator" (here we reuse a best-fit style free list) hands out
 *      contiguous slabs that consist of a fixed number of pages.
 *   2. Each slab is sub-divided into page-sized objects and cached on a
 *      partially-used list so that frequent single-page allocations can be
 *      satisfied without touching the global free list.
 *
 * Compared with Linux, this version targets uCore's simple single-core setting.
 * Therefore we drop per-CPU structures and debugging features, but keep the
 * essential separation between slab provisioning and object allocation.
 */

/* -------------------------------------------------------------------------- */
/* Configuration                                                               */
/* -------------------------------------------------------------------------- */

/* Number of pages in one slab (= 2^order, similar to SLUB's oo_order). */
#define SLUB_SLAB_ORDER      2U
#define SLUB_SLAB_PAGES      (1U << SLUB_SLAB_ORDER)

/* Object granularity inside a slab: here each object is exactly one page. */
#define SLUB_OBJECT_PAGES    1U
#define SLUB_OBJECTS_PER_SLAB (SLUB_SLAB_PAGES / SLUB_OBJECT_PAGES)

/* Global bounds derived from the maximum physical memory supported by uCore. */
#define MAX_PHYS_PAGES       (KMEMSIZE / PGSIZE)
#define MAX_SLABS            ((MAX_PHYS_PAGES + SLUB_SLAB_PAGES - 1) / SLUB_SLAB_PAGES)

/* Per-page state values so we can identify whether a page is SLUB-managed. */
#define SLUB_STATE_UNUSED    0   /* Page not tracked by SLUB (managed by backend). */
#define SLUB_STATE_FREE      1   /* Page belongs to a slab and is currently free. */
#define SLUB_STATE_ALLOCATED 2   /* Page belongs to a slab and is allocated. */

/* Helper macro to translate a slab list entry back to its metadata record. */
#define le2slab(le) to_struct((le), struct slub_slab_meta, link)

/* -------------------------------------------------------------------------- */
/* Backend allocator (layer 1)                                                 */
/* -------------------------------------------------------------------------- */

/*
 * The backend allocator is a lightly adapted copy of the best-fit allocator.
 * It is responsible for managing large contiguous chunks of free pages and
 * knows nothing about the slab layer.  The slab layer simply requests and
 * returns slabs through this interface.
 */
typedef struct {
    list_entry_t free_list;    // sorted (by address) list of free blocks
    size_t nr_free;            // total number of free pages managed here
} backend_area_t;

static backend_area_t backend_area;

#define backend_free_list (backend_area.free_list)
#define backend_nr_free   (backend_area.nr_free)

static void
backend_init(void) {
    list_init(&backend_free_list);
    backend_nr_free = 0;
}

/* Forward declaration so the slab layer can release completely free slabs. */
static void backend_free_pages(struct Page *base, size_t n);

/*
 * Insert a new free block [base, base + n) into the backend free list.
 * Pages arrive here during boot (via init_memmap) or when the slab layer
 * releases a fully unused slab.
 */
static void
backend_insert_block(struct Page *base, size_t n) {
    assert(n > 0);

    // Normalise the page metadata before linking back to the free list.
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

    // No larger address found, append at the tail.
    list_add(list_prev(&backend_free_list), &(base->page_link));

try_merge:
    /*
     * Attempt to merge with the previous and next blocks if they sit next to
     * the inserted range.  This keeps the backend allocator roughly coalesced.
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
 * Allocate >= n pages from the backend using the classic best-fit search.
 * This function mirrors best_fit_alloc_pages but is intentionally private so
 * the slab layer can request slabs without exposing another manager.
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
 * Free >= n pages back to the backend allocator.  The block must have been
 * allocated from backend_alloc_pages.
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
/* Slab metadata (layer 2)                                                     */
/* -------------------------------------------------------------------------- */

struct slub_slab_meta {
    struct Page *base;       // first page of the slab, NULL when unused
    struct Page *freelist;   // first free object (page) inside the slab
    unsigned int free_objects;   // number of free objects in this slab
    unsigned int total_objects;  // cached copy of SLUB_OBJECTS_PER_SLAB
    int on_partial;          // non-zero when linked on the partial list
    int on_full;             // non-zero when linked on the full list
    list_entry_t link;       // list hook for partial/full bookkeeping
};

static struct slub_slab_meta slab_table[MAX_SLABS];
static struct Page *slub_page_next[MAX_PHYS_PAGES];
static uint8_t slub_page_state[MAX_PHYS_PAGES];

static struct {
    list_entry_t partial;    // slabs with at least one free object
    list_entry_t full;       // slabs with no free objects (for illustration)
    size_t free_objects_total;
} slub_cache;

static int slub_initialized;

/* Convenience helpers to translate between Page* and index based storage. */
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

/* Prepare metadata and freelist for a brand-new slab returned by the backend. */
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

/* Tear down a slab and hand the underlying pages back to the backend. */
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

/* Pop one free page-sized object from a slab. */
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

/* Push a page-sized object back into its slab's freelist. */
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

/* Query function used by the PMM interface. */
static size_t
slub_nr_free_objects(void) {
    return slub_cache.free_objects_total;
}

/* -------------------------------------------------------------------------- */
/* PMM manager front-end                                                       */
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
 * init_memmap is called once per free memory range discovered during boot.
 * We simply pass the pages to the backend allocator.  Slabs are carved out
 * lazily when the first SLUB allocation happens.
 */
static void
slub_init_memmap(struct Page *base, size_t n) {
    assert(slub_initialized);
    backend_insert_block(base, n);
}

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

static void
slub_free_small(struct Page *page) {
    struct slub_slab_meta *meta = page_to_slab(page);
    assert(meta->base != NULL);
    slub_push_object(meta, page);
}

static void
slub_free_large(struct Page *base, size_t n) {
    backend_free_pages(base, n);
}

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
/* Tests                                                                       */
/* -------------------------------------------------------------------------- */

static void
slub_basic_check(void) {
    struct Page *pages_buf[SLUB_OBJECTS_PER_SLAB];

    // Allocate a full slab worth of pages and make sure they are distinct.
    for (unsigned int i = 0; i < SLUB_OBJECTS_PER_SLAB; ++i) {
        struct Page *p = slub_alloc_pages(1);
        assert(p != NULL);
        pages_buf[i] = p;
        assert(slub_object_state(p) == SLUB_STATE_ALLOCATED);
    }

    // The next allocation should come from a different slab.
    struct Page *p_extra = slub_alloc_pages(1);
    assert(p_extra != NULL);
    struct slub_slab_meta *meta0 = page_to_slab(pages_buf[0]);
    struct slub_slab_meta *meta_extra = page_to_slab(p_extra);
    assert(meta0 != meta_extra);

    // Free the first slab worth of pages and ensure they merge back.
    for (unsigned int i = 0; i < SLUB_OBJECTS_PER_SLAB; ++i) {
        slub_free_pages(pages_buf[i], 1);
        assert(slub_object_state(pages_buf[i]) != SLUB_STATE_ALLOCATED);
    }

    // After releasing all objects, the slab should have been returned to backend.
    assert(meta0->base == NULL);

    // Cleanup the extra allocation.
    slub_free_pages(p_extra, 1);
}

static void
slub_mixed_size_check(void) {
    // Allocate a large block directly from the backend and ensure accounting.
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
/* Manager descriptor                                                           */
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
