# 简化版 SLUB 物理内存分配器设计说明

## 目标与背景

Linux 的 SLUB 通过“页面分配 + 局部对象缓存”的两层架构，在保持碎片率可控的同时获得极高的分配效率。本实验在 uCore 的物理内存管理框架上实现了一个教学版 SLUB：

- **第一层（Backend）**：仍旧使用段表式（best-fit）页面分配器，负责管理大块、连续的空闲物理页。
- **第二层（SLUB Cache）**：当上层请求单页时，从 Backend 领取“slab”（固定 2^order 个物理页），再切分成页粒度的对象，放入局部缓存列表，形成“冻结/解冻”的行为。

目标是在保持接口兼容的前提下，展现 SLUB 的核心思想：按需冻结 slab、维护 partial/full 列表、当 slab 重新空闲时退回给底层页面分配器。

## 核心数据结构

| 结构             | 作用描述 |
| ---------------- | -------- |
| `backend_area_t` | Backend 分配器，基本沿用 best-fit 逻辑，维护有序空闲块列表和 `nr_free`，对 slab 层完全无感。 |
| `slub_slab_meta` | 记录单个 slab 的状态：基址、freelist、剩余对象数、是否挂在 partial/full 列表。元数据保存在静态表 `slab_table` 中，通过页索引 O(1) 查找。 |
| `slub_cache`     | SLUB Cache 管理器，维护 partial/full 两条链表及当前可用对象计数。 |
| `slub_page_state[]` / `slub_page_next[]` | 每页的状态与下一个空闲对象指针，避免占用 `struct Page` 中有限的字段。 |

对象粒度固定为 1 页，slab 大小配置为 `2^2 = 4` 页，可通过 `SLUB_SLAB_ORDER` 修改。总页数上界依据 `KMEMSIZE` 计算，因此无需动态分配元数据。

## 关键流程

### 初始化

1. `slub_init()` 建立 backend 空闲链表、清空 slab 元数据和状态数组。
2. `slub_init_memmap()` 被内核探测到的每段空闲内存调用一次，直接交给 backend 作为待用大块，slab 层按需懒加载。

### 单页分配（slab 层）

1. 若 partial list 为空，则调用 `backend_alloc_pages(SLUB_SLAB_PAGES)` 领取新 slab，并执行 `slub_prepare_slab()`：
   - 在 `slab_table` 中建立元数据；
   - 将 slab 内页串成单链 freelist；
   - 将状态标记为 `SLUB_STATE_FREE` 并统计对象数；
   - slab 加入 partial list。
2. 从 partial list 头部 slab 的 freelist 弹出一个对象：
   - 更新 `free_objects`、`slub_cache.free_objects_total`；
   - 当计数降为 0 时转移到 full list。

### 单页释放

1. 通过页索引定位所属 slab 元数据，重新压入 slab freelist，并恢复状态。
2. 若该 slab 原先在 full list，则先移除再放回 partial。
3. 当 `free_objects == total_objects` 时表明 slab 全空，执行 `slub_release_slab()`：
   - 清理状态数组；
   - 将对齐后的整块页交还 backend，与相邻空闲块合并。

### 多页分配 / 释放

当请求页数 `n > 1` 时，直接调用 backend 的 best-fit 分配器，保持与原有 `alloc_pages` 行为一致。SLUB 层仅在 `n == 1` 且该页由 slab 管理时介入，从而兼顾大块一次性分配场景。

## 一致性与统计

- `slub_nr_free_pages_wrapper()` 将 backend 剩余页数与 SLUB cache 空闲对象数相加，保证外部 `nr_free_pages()` 语义不变。
- 所有元数据修改均在单核环境下完成，无需锁；若移植到多核，可进一步拆分为 per-CPU partial list。

## 测试策略

实现内置了三组测试，在 `slub_check()` 中自动执行：

1. **`slub_basic_check`**：申请一个 slab 的全部页，再额外申请一个新页，验证会从新 slab 分配；随后逐一释放，确保 slab 被完全回收至 backend。
2. **`slub_mixed_size_check`**：混合请求单页和大块（`2 × slab`），检查跨层分配后 `nr_free_pages()` 统计保持一致。
3. **`slub_partial_reuse_check`**：构造跨多个 slab 的分配，释放其中一个后再分配新的页，验证 partial list 的重用顺序和 full→partial 转换逻辑。

开发者可在 `kern/mm/pmm.c` 中切换到 `slub_pmm_manager` 并通过 `pmm_manager->check()` 复用这些测试。

## 局限与扩展方向

- 仅支持“页大小对象”这一种缓存；要支持任意对象尺寸，需要像 Linux 那样维护多条 cache 链表。
- 未实现 per-CPU 缓存、KASAN/RCU 等拓展机制。
- 元数据使用静态数组，兼容 uCore 默认 128MiB 物理内存。若要支持更大容量，可改为运行期分配或按需压缩。

尽管做了简化，该实现清晰展示了 SLUB 的两层分配思路，并为进一步扩展提供了可靠基础。 |
