# 简化版 SLUB 内存管理器设计文档

> 版本：2025-10-20  
> 适用代码：`kern/mm/slub_pmm.c`

---

## 1. 总体架构概览

该实现采用“两层分配架构”：

```
            ┌─────────────────────────────────────────┐
            │              对象层（SLUB）              │
            │ ┌────────────┐   ┌────────────┐         │
            │ │slub_cache#0│ … │slub_cache#N│  默认 + 自定义
            │ └─────┬──────┘   └─────┬──────┘         │
            │       │                │                │
            │   ┌───▼──────────┐ ┌───▼──────────┐    │
            │   │slub_slab(part)| │slub_slab(full)|   │
            │   └────┬─────────┘ └────┬─────────┘    │
            │        │                │               │
            └────────▼────────────────┴──────────────┘
                         │  struct slub_slab::page
            ┌────────────▼────────────────────────────┐
            │              页层（最佳适应）            │
            │ free_area_t page_area.free_list          │
            │  ├─ block#0 (Page.property = 长度)       │
            │  └─ block#1 …                            │
            └─────────────────────────────────────────┘
```

- **页层（`page_area`）** 负责物理页粒度的管理，使用“最佳适应”策略维护空闲块（`struct Page` 的 `property` 字段记录连续页数；链表按物理地址升序排列）。
- **对象层（SLUB）** 在页层之上构建对象缓存，每个 slab 固定占用一页；当前实现仅支持“单页可容纳”的对象，超出范围的请求将返回 `NULL`。

该架构通过 `pmm_manager` 接口与内核其他模块对接，所有外部调用都经由 `slub_pmm_manager`（`slub_pmm.c:684`）完成。

---

## 2. 核心数据结构

### 2.1 页层结构

| 结构/字段 | 所在代码 | 说明 |
|-----------|----------|------|
| `free_area_t page_area` | `slub_pmm.c:78` | 保存空闲块链表及空闲页总数 |
| `struct Page::property` | `memlayout.h` | 当 `PG_property=1` 时表示这是空闲块头页，值为连续页数 |
| `struct Page::page_link` | `memlayout.h` | 双向链表节点，用于挂入 `free_list` |

**插入/合并流程（`page_insert_block` / `page_try_merge`）** 详见 `slub_pmm.c:104-146`，通过保持链表有序来实现 O(1) 的邻接块合并。

### 2.2 SLUB 缓存与 slab

| 结构/字段 | 所在代码 | 说明 |
|-----------|----------|------|
| `struct slub_cache` | `slub_pmm.c:62` | 描述对象缓存：对象尺寸、对齐、每页容量、统计信息、`partial/full` 链等 |
| `struct slub_slab`  | `slub_pmm.c:49` | 驻留在 slab 首页的元数据，记录空闲链头、容量、所属 cache 等 |
| `SLUB_SLAB_MAGIC`   | `slub_pmm.c:37` | 用于校验 `slub_free` 传入指针的合法性（防止野指针破坏结构） |

每个 cache 的对象槽位使用紧凑的 `uint16_t` 单向链表表示，见 `slub_new_slab` 的初始化逻辑（`slub_pmm.c:299-317`）。

### 2.3 全局状态

- 默认尺寸数组：`slub_default_sizes`（`slub_pmm.c:85`）涵盖 8~768 字节共 12 个 size class。
- 自定义缓存槽：`slub_custom_caches` + `slub_custom_used`（`slub_pmm.c:92-95`），避免额外动态分配。

---

## 3. 初始化流程

初始化包含“页层准备”与“对象层 bootstrap”两阶段，对应 `slub_init()`。

```
┌───────────────────────────────────────┐
│ slub_init()  (slub_pmm.c:661)         │
│   ├─ page_area_init()                │
│   │   └─ list_init + 清零统计        │
│   ├─ list_init(&slub_cache_list)      │
│   ├─ 清空 slub_custom_used            │
│   └─ slub_bootstrap_default_caches()  │
│        └─ 初始化 12 个默认 cache      │
└───────────────────────────────────────┘
```

### 3.1 页层初始化

内核启动时调用 `pmm_manager->init_memmap()`，对应 `slub_init_memmap()`（`slub_pmm.c:668`），实际执行 `slub_page_init_memmap()`（`slub_pmm.c:174-198`）：

1. 校验所有页处于 `PageReserved` 状态并清理标志；
2. 设置头页 `property = n`、`PG_property = 1`；
3. 插入空闲链表并尝试与邻接块合并（避免碎片）。

### 3.2 默认缓存构建

`slub_bootstrap_default_caches()`（`slub_pmm.c:332-340`）为每个 size class：

- 生成名称（如 `slub-64`）、调用 `slub_cache_setup()` 计算步长、每页对象数；
- 将 cache 节点挂入全局 `slub_cache_list`，并准备好 `partial/full` 链表。

对象步长的关键计算位于 `slub_cache_setup()`（`slub_pmm.c:225-248`），确保对齐至少为 8 字节，并为 freelist 链表预留 `uint16_t` 空间。

---

## 4. 分配流程

### 4.1 SLUB 对象分配

入口：`slub_alloc(size_t size)`（`slub_pmm.c:515`）

流程图：

```
┌─────────────────────────────┐
│ slub_alloc(size)            │
└──────────────┬──────────────┘
               │ size == 0 ?
               ├─Yes→ return NULL
               │
               ▼
      ┌─────────────────────┐
      │ slub_select_cache   │ (默认缓存)
      └────────┬────────────┘
               │ cache != NULL ?
               ├─Yes→ slub_cache_do_alloc(cache)
               │
               ▼
        return NULL  (超出单页容量)
```

#### 关键函数分解

- `slub_select_cache()`（`slub_pmm.c:255-268`）：遍历默认 cache，返回首个 `obj_size >= size` 的实例。
- `slub_cache_do_alloc()`（`slub_pmm.c:337-366`）：真正从缓存中取对象。
  1. 若 `partial` 为空，调用 `slub_new_slab()` 向页层申请新 slab；
  2. 从 `free_head` 取出槽位索引，更新单向链表；
  3. `slab->free_count == 0` 时，将 slab 移到 `full` 链。
- `slub_new_slab()`（`slub_pmm.c:299-334`）：
  - 调用 `slub_page_alloc(1)` 从页层取一页；
  - 将页面清零，填写 `slub_slab` 元数据；
  - 初始化每个槽位的 `uint16_t` 指针，形成 freelist。

### 4.2 页层分配

`slub_page_alloc(size_t n)`（`slub_pmm.c:199-238`）实现最佳适应：

1. 遍历空闲链表，选取最小可满足块；
2. 若块大于需求，拆分剩余部分重插链表；
3. 清除分配页的 `PG_property`，更新 `nr_free`。

由于链表有序，拆分后的剩余块也能够快速再度合并。

---

## 5. 释放流程

### 5.1 SLUB 对象释放

入口：`slub_free(void *ptr)`（`slub_pmm.c:527`）

```
┌───────────────────────────────┐
│ slub_free(ptr)                │
└──────────────┬────────────────┘
               │ ptr == NULL ?
               ├─Yes→ return
               │
               ▼
    ┌─────────────────────────┐
    │ page = kva2page(ptr)    │
    │ magic = *(uint32_t*)page│
    └──────────┬──────────────┘
               │ magic == SLUB_SLAB_MAGIC ?
               ├─No→ panic (非法指针)
               │
               ▼
  slub_cache_do_free(slab->cache, slab, ptr)
```

`slub_cache_do_free()`（`slub_pmm.c:368-386`）将对象重新插入 slab 的 freelist，更新 `free_count` 与 `inuse_objs`，当 slab 完全空闲时调用 `slub_release_slab()`（`slub_pmm.c:319-334`）归还整页。

### 5.2 页层释放

`slub_page_free(struct Page *base, size_t n)`（`slub_pmm.c:240-259`）：

1. 清除页标志、重置引用计数；
2. 插入空闲链表（有序）；
3. 调用 `page_try_merge()`（`slub_pmm.c:118-146`）尝试与前后块合并；
4. 更新 `nr_free`。

---

## 6. 数据结构与流程示意

### 6.1 slab 空闲链示意

```
struct slub_slab
├─ magic = 0xFFFFFFFF
├─ cache -> struct slub_cache
├─ free_head = 0
├─ free_count = capacity
├─ obj_stride = 64
└─ 对象区:
    slot[0] -> 1
    slot[1] -> 2
    ...
    slot[n-2] -> n-1
    slot[n-1] -> SLUB_FREELIST_END
```

### 6.2 页层空闲链（最佳适应）

```
free_list(head)
    ↓
┌──────────┐    ┌──────────┐    ┌──────────┐
│Page A    │ -> │Page B    │ -> │Page C    │ -> head
│property=4│    │property=2│    │property=8│
└──────────┘    └──────────┘    └──────────┘
```

当请求 2 页时，遍历链表找到 Page B，直接满足请求；当 Page A 部分分配 1 页后，剩余 3 页会重新挂入链表（保持有序）以便后续合并。

---

## 7. 与核心代码的对应关系

| 功能模块 | 关键函数 | 代码位置 |
|----------|----------|----------|
| 页层初始化 | `slub_page_init_memmap` | `slub_pmm.c:174-198` |
| 页层分配 | `slub_page_alloc` | `slub_pmm.c:199-238` |
| 页层释放 | `slub_page_free` | `slub_pmm.c:240-259` |
| cache 配置 | `slub_cache_setup` | `slub_pmm.c:225-248` |
| slab 创建 | `slub_new_slab` | `slub_pmm.c:299-334` |
| 对象分配 | `slub_cache_do_alloc` | `slub_pmm.c:337-366` |
| 对象释放 | `slub_cache_do_free` | `slub_pmm.c:368-386` |
| API 封装 | `slub_alloc` / `slub_free` | `slub_pmm.c:515-546` |
| `pmm_manager` 实现 | `slub_pmm_manager` | `slub_pmm.c:684-692` |

面对具体问题时，可从文档定位到函数，再参阅对应实现。

---

## 8. 测试设计

`slub_check()`（`slub_pmm.c:650-656`）汇总五类测试场景，确保页层与对象层协同可靠：

1. **基础页测试（`slub_page_basic_check`，`slub_pmm.c:541-556`）**  
   连续申请三个单页并归还，验证最简单的分配/释放路径。

2. **碎片合并（`slub_page_fragment_check`，`slub_pmm.c:566-577`）**  
   通过“先分配大块，再拆分释放”模拟碎片化，确保再次申请时得到原始整块。

3. **自定义 cache 验证（`slub_cache_basic_check`，`slub_pmm.c:580-610`）**  
   分配多个 slab，交错释放以触发部分空闲、完全空闲两种路径，最终确认所有 slab 被回收。

4. **通用接口回归（`slub_alloc_general_check`，`slub_pmm.c:613-629`）**  
   多种对象尺寸循环申请/释放，检查 `slub_page_nr_free()` 前后不变。

5. **压力测试（`slub_stress_check`，`slub_pmm.c:632-647`）**  
   多轮批量分配/释放 48 字节对象，模拟高频场景。

所有测试共用断言宏 `SLUB_ASSERT`（`slub_pmm.c:27-35`），若任一条件失败会打印具体函数与行号，并触发 `panic`，便于快速定位问题。

---

## 9. 约束与扩展方向

- **当前约束**：只面向单页容量对象；若期望支持跨页分配，需要扩展“大对象”路径并回收时记录页数。
- **潜在优化**：
  1. 引入 per-CPU 局部缓存减少锁竞争；
  2. 增强统计与调试信息（如泄漏检测、slab 状态导出）；
  3. 对超大对象按需临时创建 cache，实现自动适配。

---

## 10. 结语

本文档从架构、数据结构、流程与测试四个角度全面阐述了简化版 SLUB 管理器的设计与实现。通过“页层负责粗粒度、对象层负责细粒度”的分层策略，我们获得了结构清晰、易于扩展的内存分配模块。测试部分覆盖核心路径，可作为后续改动的回归基准。若在使用中出现新的需求，可在此基础上逐步扩展。

