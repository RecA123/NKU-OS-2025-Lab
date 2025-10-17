#include <defs.h>
#include <list.h>
#include <string.h>
#include <pmm.h>
#include <buddy_pmm.h>

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