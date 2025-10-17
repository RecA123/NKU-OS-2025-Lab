#include <defs.h>
#include <list.h>
#include <string.h>
#include <pmm.h>
#include <buddy_pmm.h>

#define BUDDY_MAX_ORDER 11                      // 支持到 2^(11-1) 页 (4MB) 连续分配
static list_entry_t free_area[BUDDY_MAX_ORDER]; 
static size_t free_nr_pages = 0;                

// 管理的连续物理页区间
static struct Page *buddy_base = NULL;
static size_t buddy_npages = 0;

// 工具：页索引
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }

// 向上取整：找到满足 (1<<order) >= n 的最小 order
static inline unsigned ceil_order(size_t n) {
    unsigned o = 0; size_t s = 1;
    while (s < n) { s <<= 1; o++; }
    return o;
}

// 伙伴索引
static inline size_t buddy_idx_of(size_t idx, unsigned order) {
    return idx ^ (1UL << order);
}

// 在某个 order 的 free list 里查找“起始索引 == want_idx”的空闲块头页
static struct Page *find_free_block(unsigned order, size_t want_idx) {
    list_entry_t *le = &free_area[order];
    list_entry_t *cur = list_next(le);
    while (cur != le) {
        struct Page *p = le2page(cur, page_link);
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
            return p;
        cur = list_next(cur);
    }
    return NULL;
}

// 把一个空闲块头页插入某阶 free list，更新统计
static inline void add_block(unsigned order, struct Page *p) {
    set_page_ref(p, 0);
    p->property = (1U << order);
    SetPageProperty(p);
    list_add(&free_area[order], &(p->page_link));
    free_nr_pages += (1U << order);
}

// 从 free list 删除一个空闲块头页，更新统计
static inline void del_block(unsigned order, struct Page *p) {
    list_del(&(p->page_link));
    ClearPageProperty(p);
    free_nr_pages -= (1U << order);
}

static void buddy_init(void) {
  
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    
    (void)base; (void)n;
}

static struct Page *buddy_alloc_pages(size_t n) {
    
    (void)n;
    return NULL;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    
    (void)base; (void)n;
}

static size_t buddy_nr_free_pages(void) {
   
    return 0;
}

static void buddy_check(void) {
   
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",   // 2312632
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};