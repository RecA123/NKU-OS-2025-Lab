# 简化版 SLUB 物理内存分配器设计文档

本文档详细阐述 `kern/mm/slub_pmm.c` 与 `slub_pmm.h` 中实现的教学版 SLUB 物理内存管理器。该实现基于 uCore 的单核环境，对 Linux 内核中的 SLUB 机制做了裁剪与简化，但完整保留了“两层分配 + 局部缓存”的核心思想。

---

## 1. 背景与设计目标

### 1.1 背景
Linux 的 SLUB 通过“页面分配器 + 局部对象缓存”的两层架构，在降低外部碎片率的同时实现高吞吐的对象分配。uCore 课程实验中原有的物理内存管理器多为单层页表或伙伴算法，需要频繁访问全局空闲链表，难以体现 SLUB 的性能思路。

### 1.2 目标
- **教学友好**：在不引入 per-CPU、RCU、调试探针等复杂机制的前提下，呈现 SLUB 的核心概念。
- **接口兼容**：对外仍遵循 `struct pmm_manager` 接口，使得 `pmm.c` 可以无缝切换到该实现。
- **可验证性**：内置若干自测用例，覆盖主要路径（单页分配、混合大小、部分回收）。
- **可扩展性**：保留清晰的数据结构边界，方便后续扩展支持多种对象粒度或多核。

---

## 2. 总体架构

整体设计仍分为上下两层：

1. **Backend 页分配器**  
   - 职责：维护较大、连续的空闲物理页块，对 slab 层“无感知”。  
   - 实现：沿用 `best_fit` 算法，管理一条按物理地址排序的空闲链表，可进行相邻块合并。  
   - 接口：`backend_alloc_pages(n)` / `backend_free_pages(base, n)` / `backend_insert_block(base, n)`。

2. **SLUB Cache（Slab 层）**  
   - 职责：将后端提供的 slab 切分成页粒度对象，缓存于部分占用链表，提供 O(1) 的单页分配与释放。  
   - 实现：使用 `partial` / `full` 两条链表管理 slab 状态，单 slab 大小为固定 `2^order` 页。  
   - 接口：`slub_alloc_pages(n)` / `slub_free_pages(base, n)` 等，符合 `pmm_manager` 约定。

层间协作流程如下：

1. 启动阶段，`slub_init_memmap` 将探测到的连续空闲页块交给 backend。
2. 第一次单页分配时，slab 层向 backend 申请一整个 slab，并初始化其 freelist。
3. slab 层维护部分占用 slab 的对象链表，重复分配/释放时无需触碰 backend。
4. 当某 slab 的对象全部归还时，将整块 slab 退回 backend 并尝试与邻接块合并。

---

## 3. 配置参数与静态上限

| 常量 | 默认值 | 含义 |
| ---- | ------ | ---- |
| `SLUB_SLAB_ORDER` | `2` | 每个 slab 的页数为 `2^order`，默认 4 页。 |
| `SLUB_OBJECT_PAGES` | `1` | slab 内部对象粒度：当前实现中对象就是一页。 |
| `SLUB_OBJECTS_PER_SLAB` | `SLUB_SLAB_PAGES / SLUB_OBJECT_PAGES` | 单个 slab 可容纳的对象数。 |
| `MAX_PHYS_PAGES` | `KMEMSIZE / PGSIZE` | 根据 uCore 支持的最大物理内存推导的页数上界。 |
| `MAX_SLABS` | `(MAX_PHYS_PAGES + SLUB_SLAB_PAGES - 1) / SLUB_SLAB_PAGES` | 允许存在的 slab 元数据上限。 |

静态上限保证了无需动态分配元数据结构。若将来需要支持更大物理内存或多种对象粒度，可考虑动态扩容或分层存储。

---

## 4. 核心数据结构

### 4.1 Backend 相关
- `backend_area_t`：包含一个空闲块链表 `free_list` 与空闲页计数 `nr_free`。链表元素使用 `struct Page::page_link` 挂接，按物理地址有序，便于做相邻块合并。

### 4.2 Slab 元数据
- `struct slub_slab_meta`  
  - `base`：slab 的首页指针；`NULL` 表示该项未被占用。  
  - `freelist`：指向 slab 内第一个空闲对象页。  
  - `free_objects` / `total_objects`：记录剩余对象数与总容量。  
  - `on_partial` / `on_full`：布尔位，标记当前是否挂在对应链表。  
  - `link`：链表节点，供 `partial` / `full` 使用。

- `slab_table[MAX_SLABS]`：静态数组存放所有 slab 元数据，按 slab 序号索引。序号计算方式为 `page_index / SLUB_SLAB_PAGES`。

### 4.3 对象级状态
- `slub_page_state[MAX_PHYS_PAGES]`：记录每一页是否属于某 slab 以及所属状态（`UNUSED`、`FREE`、`ALLOCATED`）。
- `slub_page_next[MAX_PHYS_PAGES]`：保存 freelist 链指针，避免占用 `struct Page` 内的成员。

### 4.4 SLUB Cache 总体状态
- `slub_cache.partial` / `slub_cache.full`：分别维护“仍有空闲对象”和“已经满载”的 slab 链表。
- `slub_cache.free_objects_total`：整个平台尚未被分配的页对象数量，供 `nr_free_pages()` 统计使用。

### 4.5 辅助宏和函数
- `page_index(page)`：将 `struct Page *` 转为全局页索引。
- `page_to_slab(page)`：依据页索引计算所属的 `slub_slab_meta`。
- `slub_object_get/set_state` / `slub_object_get/set_next`：操作 per-page 状态数组。

---

## 5. 生命周期与流程细节

### 5.1 初始化阶段
1. **`slub_init()`**  
   - 初始化 backend 空闲链表与计数。  
   - 将 slab 元数据表与状态数组置零。  
   - 初始化 `partial` / `full` 链表与统计计数。  
   - 设置 `slub_initialized` 标志，防止重复初始化。

2. **`slub_init_memmap(base, n)`**  
   - 在内核探测到一段连续空闲内存时调用。  
   - 将 `[base, base + n)` 直接插入 backend 空闲链表，由后端统一管理连续块。  
   - slab 层不立即划分 slab，实现了“懒分配”。

### 5.2 单页分配流程
1. `slub_alloc_pages(1)` → `slub_alloc_small()`。  
2. 若 `partial` 链表为空，则向 backend 申请一个新的 slab：  
   - `backend_alloc_pages(SLUB_SLAB_PAGES)` 获取连续页。  
   - 调用 `slub_prepare_slab(base)` 初始化元数据与 freelist：  
     - 逐个对象设置 `slub_page_state` 为 `FREE`，串联 `slub_page_next`。  
     - 将 slab 元数据填入 `slab_table` 并加入 partial 链表。  
     - 更新 `slub_cache.free_objects_total`。
3. 从 partial 链表头部取出一个 slab，调用 `slub_pop_object`：  
   - 弹出 freelist 头对象；  
  - 将其状态设置为 `ALLOCATED`，并从链表中移除；  
  - 递减 `free_objects` 与 `free_objects_total`；  
  - 若 `free_objects` 变为 0，则将该 slab 从 partial 转移到 full 链表。

### 5.3 单页释放流程
1. `slub_free_pages(page, 1)` → `slub_free_small(page)`。  
2. 根据页索引定位所属 slab 元数据，调用 `slub_push_object`：  
   - 将页对象重新压回 slab freelist；  
   - 重置引用计数与 Flags，状态改为 `FREE`；  
   - `free_objects` 与 `free_objects_total` 递增；  
   - 若该 slab 原在 full 链表，先移除，再视情况重新加入 partial；  
   - 当 `free_objects == total_objects`，说明 slab 全空，调用 `slub_release_slab(meta)`。
3. `slub_release_slab` 会：  
   - 将 slab 的所有页状态重置为 `UNUSED`；  
   - 清空元数据并将 slab 从链表中移除；  
   - 将整块物理页交还给 backend，并尝试与邻近块合并。

### 5.4 多页分配与释放
- 当请求 `n > 1` 页或目标页不在 SLUB 管理范围时，直接调用 backend 接口：  
  - `slub_alloc_large(n)` → `backend_alloc_pages(n)`  
  - `slub_free_large(base, n)` → `backend_free_pages(base, n)`  
- 这样保持了原有 `alloc_pages` 的语义，并兼顾大块一次性分配场景。

### 5.5 状态示意图
```
Backend 空闲块  ←→  SLUB slab (partial/full)  ←→  Freed 对象
          ^             |           ^                 |
          |             v           |                 v
    init_memmap     slub_prepare   slub_pop     slub_push / release
```

---

## 6. 与 Backend 的交互及合并策略

- `backend_insert_block`：插入新空闲块时按地址有序，并尝试与前后相邻块合并。  
- `backend_alloc_pages`：使用最佳适配策略遍历链表，选出最小满足请求的块。  
- `backend_free_pages`：释放时先重置 `struct Page` 的状态，再调用 `backend_insert_block` 完成合并。  
- slab 层拿到整块 slab 后不会拆散页表结构，因此 backend 只需感知“整块分配/归还”事件。

---

## 7. 接口与调用方协作

`slub_pmm_manager` 实例化了 `struct pmm_manager` 的六个函数指针：

| 接口 | 角色 | 说明 |
| ---- | ---- | ---- |
| `init` | pmm 初始化 | 调用 `slub_init`，准备所有元数据结构。 |
| `init_memmap` | 建立空闲页表 | 将物理空闲段注册到 backend。 |
| `alloc_pages` | 分配接口 | 根据页数选择 slab 流程或 backend 流程。 |
| `free_pages` | 释放接口 | 根据页状态决定走 slab 回收还是 backend 回收。 |
| `nr_free_pages` | 统计接口 | 返回 `backend_nr_free + slub_cache.free_objects_total`。 |
| `check` | 自测入口 | 依次执行三个场景的校验函数。 |

`kern/mm/pmm.c` 只需将 `pmm_manager` 指向 `slub_pmm_manager`，其余流程无需改动。

---

## 8. 一致性、并发与错误检测

- **单核假设**：uCore 默认单核环境，无需加锁；若迁移到多核，可考虑为每个 CPU 维护 `partial` 链表，并设立全局 fallback。  
- **断言与状态检查**：核心路径广泛使用 `assert` 验证：  
  - slab 元数据存在 (`meta->base != NULL`)；  
  - 页必须在预期状态下才允许释放；  
  - 输入参数合法且非零。  
 这些断言在教学环境中可帮助快速定位实现问题。

---

## 9. 统计与调试手段

- `slub_nr_free_pages_wrapper()` 保证对上保持 `nr_free_pages()` 的语义与原有管理器一致。  
- `slub_cache.free_objects_total` 可用于监控 slab 层缓存的规模。  
- `slub_page_state` 数组提供 per-page 的可视化信息，便于调试时查看单个页属于哪个 slab 以及当前状态。  
- 若需要进一步调试，可添加统计项记录 partial/full 链表长度或 slab 准备次数等。

---

## 10. 内置测试说明

`slub_check()` 中包含三个独立测试用例，覆盖主要行为：

1. **`slub_basic_check`**  
   - 连续申请一个 slab 内的所有页，再额外申请一个页，验证会分配新 slab。  
   - 逐一释放原 slab 中的页，确认 slab 被完全回收并归还给 backend。

2. **`slub_mixed_size_check`**  
   - 同时申请多页大块和单页，检测混合场景下 `nr_free_pages` 的计数准确。  
   - 释放顺序交错，以捕获潜在的统计遗漏。

3. **`slub_partial_reuse_check`**  
   - 构造跨多个 slab 的分配，释放其中一个对象，再立即申请新对象。  
   - 验证 partial/full 链表转换逻辑以及对象的重用顺序。

所有测试都在 `assert` 失败时立即触发 panic，适合作为自动化回归的基础。

---

## 11. 局限性与扩展方向

1. **对象粒度固定为一页**  
   - 若要支持任意大小对象，需要像 Linux 那样为不同尺寸维护多条 cache 链表，并在分配前选择合适的 cache。

2. **缺乏多核优化**  
   - 当前实现仅维护全局 partial/full 链表，多核情况下可能产生锁竞争。  
   - 可扩展为 per-CPU cache，加上共享 slab 池或锁分离策略。

3. **调试功能简化**  
   - 未实现 Linux SLUB 的调试功能（如 redzone、poison、对象跟踪）。  
   - 若有教学需求，可在 `slub_prepare_slab` / `slub_pop_object` 中加入额外标记。

4. **静态元数据规模有限**  
   - `MAX_SLABS` 与 `MAX_PHYS_PAGES` 均基于课程默认物理内存上限计算。  
   - 若运行环境显著扩大，可考虑动态分配或按需分段初始化相关数组。

---

## 12. 总结

该简化版 SLUB 管理器在保持 uCore 接口兼容的前提下，清晰地展示了 Linux SLUB 的关键理念：

- 通过两层结构将大块页管理与小粒度分配解耦。  
- 借助 partial/full 链表实现常见对象的快速复用。  
- 在 slab 完全空闲时将整块页面归还 backend，抑制长期碎片。

文中的设计和测试为学生理解 SLUB 工作原理提供了直观材料，也为后续扩展（多种对象大小、多核、调试）奠定了良好基础。
