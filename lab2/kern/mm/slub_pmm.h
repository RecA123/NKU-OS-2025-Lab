#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <defs.h>
#include <pmm.h>

struct slub_cache;

extern const struct pmm_manager slub_pmm_manager;

struct slub_cache *slub_cache_create(const char *name, size_t obj_size, size_t align);
void slub_cache_destroy(struct slub_cache *cache);
void *slub_cache_alloc(struct slub_cache *cache);
void slub_cache_free(struct slub_cache *cache, void *obj);

void *slub_alloc(size_t size);
void slub_free(void *ptr);

void slub_dump_stats(void);

#endif /* __KERN_MM_SLUB_PMM_H__ */

