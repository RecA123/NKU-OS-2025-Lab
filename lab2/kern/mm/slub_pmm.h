#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <pmm.h>

/*
 * slub_pmm_manager – simplified SLUB style physical memory allocator.
 *
 * The implementation lives in slub_pmm.c.  Expose the manager so that
 * kern/mm/pmm.c can pick it up in the same fashion as other managers.
 */
extern const struct pmm_manager slub_pmm_manager;

#endif /* __KERN_MM_SLUB_PMM_H__ */
