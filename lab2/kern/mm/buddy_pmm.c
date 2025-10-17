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
    for (int i = 0; i < BUDDY_MAX_ORDER; i++) {
        list_init(&free_area[i]);
    }
    free_nr_pages = 0;
    buddy_base = NULL;
    buddy_npages = 0;
}

// 选在 idx 处的“最大且对齐”的块阶数
static unsigned pick_largest_order(size_t idx, size_t remain) {
    unsigned o = 0;
    while ((o + 1) < BUDDY_MAX_ORDER
        && ((1UL << (o + 1)) <= remain)
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
        o++;
    }
    return o;
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    buddy_base   = base;
    buddy_npages = n;

    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        p->property = 0;
        ClearPageProperty(p);
        set_page_ref(p, 0);
    }

    // 把 [0, n) 区间切成 2^k 对齐的最大块
    size_t idx = 0;
    while (idx < n) {
        size_t remain = n - idx;
        unsigned o = pick_largest_order(idx, remain);
        add_block(o, page_at(idx));
        idx += (1UL << o);
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0) return NULL;
    unsigned need = ceil_order(n);
    if (need >= BUDDY_MAX_ORDER) return NULL;  

    // 从 need 阶起，向上寻找首个非空阶
    unsigned o = need;
    while (o < BUDDY_MAX_ORDER && list_empty(&free_area[o])) o++;
    if (o >= BUDDY_MAX_ORDER) return NULL;     

    // 从阶 o 链表取出一个大块
    list_entry_t *le = list_next(&free_area[o]);
    struct Page *p = le2page(le, page_link);
    size_t idx = page_idx(p);
    del_block(o, p); // 先删除该大块

    // 自顶向下拆分，右半块归还到低一阶空闲链表，左半块继续参与拆分
    while (o > need) {
        o--;
        size_t right_idx = idx + (1UL << o);
        struct Page *right = page_at(right_idx);
        add_block(o, right);       // 右半块空闲
        // 左半块（idx 不变）继续下一轮拆分
    }

    // 返回左半块：按 ucore 习惯，分配出去的块头不保留 PageProperty 标记
    struct Page *ret = page_at(idx);
    ClearPageProperty(ret);
    ret->property = 0;
    set_page_ref(ret, 0);
    return ret;
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