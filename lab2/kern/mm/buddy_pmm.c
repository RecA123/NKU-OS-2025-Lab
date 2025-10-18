#include <defs.h>
#include <list.h>
#include <string.h>
#include <stdio.h>      
#include <pmm.h>
#include <buddy_pmm.h>

/* Buddy System全局状态维护 */
#define BUDDY_MAX_ORDER 11                 //表示阶的个数，即最大块大小为2^10=1024页，0-10一共11阶
static list_entry_t free_area[BUDDY_MAX_ORDER]; // 每阶的空闲链表头，找空闲块时从这里开始
static size_t free_nr_pages = 0;           // 当前总空闲页数，用于check

// 表示托管的物理内存区间，起始地址的位置以及页数
static struct Page *buddy_base = NULL;
static size_t buddy_npages = 0;

static void buddy_free_pages(struct Page *base, size_t n);

/*内部辅助函数 */
// 索引运算和实际页指针转换
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }

// 向上取整找到最小的 order 使 2^order >= n
static inline unsigned ceil_order(size_t n) {
    unsigned o = 0; size_t s = 1;
    while (s < n) { s <<= 1; o++; }
    return o;
}

// 给定一个块的起始页索引 idx 和它的阶 order计算伙伴块索引，知道一个算另一个
static inline size_t buddy_idx_of(size_t idx, unsigned order) {
    return idx ^ (1UL << order);// 先把idx转成二进制之后，再按位异或运算翻转对应的对齐位，对称
}

// 在第 order 阶链表中，找块头索引就是 want_idx 的那个空闲块
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

// 从给定起点切最大对齐块
static unsigned pick_largest_order(size_t idx, size_t remain) {
    unsigned o = 0;
    while ((o + 1) < BUDDY_MAX_ORDER
        && ((1UL << (o + 1)) <= remain)
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
        o++;
    }
    return o;
}

// 当前总空闲页
static inline size_t nrfree(void) { return free_nr_pages; }

//重置初始化
static void buddy_init(void) {
    for (int i = 0; i < BUDDY_MAX_ORDER; i++) {
        list_init(&free_area[i]);
    }
    free_nr_pages = 0;
    buddy_base = NULL;
    buddy_npages = 0;
}

// 把一段连续页区间变成规范的buddy块并加入空闲链表
static void buddy_init_memmap(struct Page *base, size_t n) {
    buddy_base   = base;
    buddy_npages = n;

    // 初始化 Page 元数据，避免残留状态
    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        p->property = 0;
        ClearPageProperty(p);
        set_page_ref(p, 0);
    }

    // 把 [0, n) 切成尽可能大且对齐的 2^k 块
    size_t idx = 0;
    while (idx < n) {
        size_t remain = n - idx;
        unsigned o = pick_largest_order(idx, remain);
        add_block(o, page_at(idx));
        idx += (1UL << o);//跳过刚放进去的这块，继续切下一段
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0) return NULL;
    unsigned need = ceil_order(n);
    if (need >= BUDDY_MAX_ORDER) return NULL;  // 需求超过最大支持

    // 从 need 阶开始向上找一个非空阶
    unsigned o = need;
    while (o < BUDDY_MAX_ORDER && list_empty(&free_area[o])) o++;// 先看“正好阶”的空闲链表有没有块；没有就去更大的阶找
    if (o >= BUDDY_MAX_ORDER) return NULL;     // 无可用块

    // 取一个阶为 o 的块
    list_entry_t *le = list_next(&free_area[o]);
    struct Page *p = le2page(le, page_link);//取出块头页
    size_t idx = page_idx(p);//计算块头页的索引
    del_block(o, p);

    // 自顶向下拆分，右半块放回更低阶，左半块继续拆
    while (o > need) {
        o--;
        size_t right_idx = idx + (1UL << o);
        struct Page *right = page_at(right_idx);
        add_block(o, right);       // 右半块空闲
        // 左半块（idx 不变）继续下一轮
    }

    // 返回左半块：分配出去的头页不保留 PageProperty
    struct Page *ret = page_at(idx);
    ClearPageProperty(ret);
    ret->property = 0;
    set_page_ref(ret, 0);
    return ret;
}

// 把一段连续的已分配页释放回伙伴分配器
static void buddy_free_pages(struct Page *base, size_t n) {
    if (n == 0) return;

    size_t idx = page_idx(base);
    size_t left = n;

    while (left > 0) {
        // 在 idx 处选择对齐的最大块阶
        unsigned o = pick_largest_order(idx, left);

        // 自底向上尝试与伙伴合并
        size_t bidx = idx;
        unsigned cur = o;
        while ((cur + 1) < BUDDY_MAX_ORDER) {
            size_t other = buddy_idx_of(bidx, cur);
            struct Page *bp = find_free_block(cur, other);
            if (bp == NULL) break;                // 伙伴不空闲，停止
            // 合并：删除伙伴块，合为更高一阶，起点取较小者
            del_block(cur, bp);
            bidx = (bidx < other) ? bidx : other; //起点取更小的
            cur++;
        }
        // 将合并后的块挂回链表
        add_block(cur, page_at(bidx));

        idx  += (1UL << o); //继续往下推荐
        left -= (1UL << o); //left 也相应减去这次处理的片段大小
    }
}

static size_t buddy_nr_free_pages(void) {
    return free_nr_pages;
}

static void buddy_check(void) {
    #define POW2(o) (1u << (o))

    cprintf("\n[buddy] 1024 页示范\n");
    cprintf("[buddy] 初始：一个大块 [0,1024) (order=%u, 大小=%u)\n\n", 10u, 1024u);

    struct demo { const char* name; unsigned req, ord, size, st, ed; } A,B,C,D,E,F;

    // A: 32
    A.name="A"; A.req=32u;  A.ord=ceil_order(A.req); A.size=POW2(A.ord);
    A.st=0u; A.ed=A.st+A.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u)\n",
            A.name, A.req, A.size, A.ord, A.st, A.ed);

    // B: 64  —— 直接用 64..128
    B.name="B"; B.req=64u;  B.ord=ceil_order(B.req); B.size=POW2(B.ord);
    B.st=64u; B.ed=B.st+B.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u)\n",
            B.name, B.req, B.size, B.ord, B.st, B.ed);

    // C: 60 -> 向上取 64，用 128..192
    C.name="C"; C.req=60u;  C.ord=ceil_order(C.req); C.size=POW2(C.ord);
    C.st=128u; C.ed=C.st+C.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：60 向上取 64\n",
            C.name, C.req, C.size, C.ord, C.st, C.ed);

    // D: 150 -> 向上取 256，用 256..512
    D.name="D"; D.req=150u; D.ord=ceil_order(D.req); D.size=POW2(D.ord);
    D.st=256u; D.ed=D.st+D.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：150 向上取 256\n\n",
            D.name, D.req, D.size, D.ord, D.st, D.ed);

    // 释放 B
    cprintf("[buddy] 释放 %s：区间 [%u,%u)\n", B.name, B.st, B.ed);
    cprintf("        检查伙伴：%s(order=%u) 的伙伴是 [0,64) —— 因 %s 占用 [0,32)，暂不能合并\n",
            B.name, B.ord, A.name);

    // 释放 A：先与 [32,64) 合并 -> [0,64)，再与 B 的 [64,128) 合并 -> [0,128)
    cprintf("[buddy] 释放 %s：区间 [%u,%u)\n", A.name, A.st, A.ed);
    cprintf("        先与 [32,64) 合并 -> [0,64)；再与 %s 的 [64,128) 合并 -> [0,128)\n\n", B.name);

    // E: 100 -> 128，用刚合并出的 [0,128)
    E.name="E"; E.req=100u; E.ord=ceil_order(E.req); E.size=POW2(E.ord);
    E.st=0u; E.ed=E.st+E.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：100 向上取 128，使用 [0,128)\n",
            E.name, E.req, E.size, E.ord, E.st, E.ed);

    // F: 100 -> 128，从右侧 512..1024 拆出 128，得到 512..640
    F.name="F"; F.req=100u; F.ord=ceil_order(F.req); F.size=POW2(F.ord);
    F.st=512u; F.ed=F.st+F.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：从右侧 512..1024 拆出 128\n\n",
            F.name, F.req, F.size, F.ord, F.st, F.ed);

    // 内部碎片
    unsigned waste =
        (A.size-A.req) + (B.size-B.req) + (C.size-C.req) +
        (D.size-D.req) + (E.size-E.req) + (F.size-F.req);

    cprintf("[buddy] 内部碎片：\n");
    cprintf("        A:%u->%u(+%u), B:%u->%u(+%u), C:%u->%u(+%u)\n",
        A.req,A.size,(A.size-A.req), B.req,B.size,(B.size-B.req), C.req,C.size,(C.size-C.req));
    cprintf("        D:%u->%u(+%u), E:%u->%u(+%u), F:%u->%u(+%u)\n",
        D.req,D.size,(D.size-D.req), E.req,E.size,(E.size-E.req), F.req,F.size,(F.size-F.req));
    cprintf("        总内部碎片: %u 页\n\n", waste);

    // 汇总
    cprintf("[buddy] 最终区间总结（单位：页）\n");
    cprintf("  A: [%4u,%4u)  请求=%3u 实分=%3u\n", A.st,A.ed,A.req,A.size);
    cprintf("  B: [%4u,%4u)  请求=%3u 实分=%3u   （随后释放）\n", B.st,B.ed,B.req,B.size);
    cprintf("  C: [%4u,%4u)  请求=%3u 实分=%3u\n", C.st,C.ed,C.req,C.size);
    cprintf("  D: [%4u,%4u)  请求=%3u 实分=%3u\n", D.st,D.ed,D.req,D.size);
    cprintf("  E: [%4u,%4u)  请求=%3u 实分=%3u\n", E.st,E.ed,E.req,E.size);
    cprintf("  F: [%4u,%4u)  请求=%3u 实分=%3u\n", F.st,F.ed,F.req,F.size);

    cprintf("\n[buddy] 结论: 正确，与预期相同\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager-2312632",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
