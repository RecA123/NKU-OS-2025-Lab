#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>
#include <stdio.h>

/* 在 Lab 2 中，我们使用 First-Fit 策略来管理物理内存。
 * free_area 是一个链表头，用于管理所有的空闲页。
 */
static list_entry_t free_list;
#define free_list_init() list_init(&free_list)
#define free_list_add(page) list_add_before(&free_list, &(page->page_link))
#define free_list_del(page) list_del(&(page->page_link))

/* default_init: 初始化 free_list */
static void
default_init(void) {
    free_list_init();
}

/* default_init_memmap: 将所有空闲页加入 free_list */
static void
default_init_memmap(struct Page *base, size_t n) {
    cprintf("  default_init_memmap: call base %p n %lu\n", base, n);
    for (struct Page *p = base; p < base + n; p++) {
        if (PageProperty(p)) {
            // 如果页面被保留 (reserved)，则什么也不做
        } else {
            // 否则，将其标记为空闲并加入 free_list
            SetPageProperty(p); // 标记为已管理
            p->flags = 0;
            p->property = 1; // 1 个空闲页
            free_list_add(p);
        }
    }
}

/* default_alloc_pages: 分配 n 个连续的物理页 */
static struct Page *
default_alloc_pages(size_t n) {
    if (n == 0) {
        return NULL;
    }

    struct Page *page = NULL;
    list_entry_t *le = &free_list;

    // First-Fit 搜索
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) { // 找到了足够大的空闲块
            page = p;
            break;
        }
    }

    if (page != NULL) {
        if (page->property > n) {
            // 如果找到的块大于所需，则分裂
            struct Page *p = page + n;
            p->property = page->property - n;
            free_list_add(p); // 将剩余部分加回空闲链表
        }

        // 从空闲链表中移除被分配的块
        free_list_del(page);
        page->property = 0; // 标记为已分配
        ClearPageProperty(page); // 标记为非空闲
    }
    return page;
}

/* default_free_pages: 释放 n 个连续的物理页 */
static void
default_free_pages(struct Page *base, size_t n) {
    if (n == 0) {
        return;
    }

    struct Page *p = base;
    for (; p < base + n; p++) {
        // 确保页面是保留的（即已分配的）
        if (PageProperty(p)) {
            panic("default_free_pages: page %p is already free", p);
        }
        SetPageProperty(p); // 标记为已管理
        p->flags = 0;
    }

    base->property = n; // 设置释放的页块大小
    free_list_add(base); // 加回空闲链表

    // (可选) 尝试合并空闲块，Lab 2 不强制要求
}

static size_t
default_nr_free_pages(void) {
    size_t count = 0;
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
        struct Page *p = le2page(le, page_link);
        count += p->property;
        le = list_next(le);
    }
    return count;
}

const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
};
