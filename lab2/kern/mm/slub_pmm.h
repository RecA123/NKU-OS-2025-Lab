#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <pmm.h>

/*
 * slub_pmm_manager 描述了一个简化版的 SLUB 风格物理内存分配器。
 *
 * 具体实现位于 slub_pmm.c。将该管理器向外暴露，使得 kern/mm/pmm.c
 * 可以像选择其他分配器那样，把它注册为当前的物理内存管理方案。
 */
extern const struct pmm_manager slub_pmm_manager;

#endif /* __KERN_MM_SLUB_PMM_H__ */
