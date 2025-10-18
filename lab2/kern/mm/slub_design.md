# 简化版 SLUB 内存管理器设计文档

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

## 9. 总结
SLUB 原理

  - 代码里实现的是“两层”分配：底层仍是最小适应的页分配器（slub_page_alloc/free），上层在一页的基础上构建 slub_cache + slub_slab，
    每个 slab 固定占 1 页，在页头记元数据、用 uint16_t 串起对象槽。
  - 分配时根据对象尺寸选择默认或自定义 cache → 如需新 slab 就向页层要 1 页 → 从 free_head 取槽位；释放时写回索引，必要时把 slab
    从 full 挂回 partial，完全空闲则整页回收。
  - 这种 slab 化策略让同尺寸运行时复用同一页，避免反复在页层拆分，同时 SLUB_SLAB_MAGIC 等校验保证误用时立即暴露问题。自检函数覆盖
    页层、缓存、通用接口和压力场景，确保流程闭环。

与 best_fit 的区别

  - best_fit 只做页粒度（一次申请 n 页、一页就是最小单位），没有对象缓存：大量小对象会造成“整页只放一个小对象”的浪费，并且每次都
    要在全局链表里找最优块。
  - SLUB 在页层仍用最佳适应，但在其上加了 size-class：同类小对象在 1 页内循环利用，拆 slab 后还能整页回收，因此显著降低小块外碎
    片、提高命中率。
  - 此外，SLUB 的 cache/slab 元数据记录统计、状态，适合扩展调试功能；best_fit 则几乎没有额外信息。

  与 buddy_pmm 的区别

  - buddy 通过幂次拆分/合并让合并 O(logN)、数据结构简单，但粒度始终是 2^k 页，无法直接为“非页对齐的小对象”服务，上层仍需额外
    管理。
  - 我们的 SLUB 仍然以“整页”为 slab，但能细粒度分配到对象尺寸，且每页内部自由链表避免了 buddy 系统常见的内部碎片；同时依赖最佳适
    应可接受任意长度（非幂次）页块，不再受 2^k 限制。
  - 代价是链表遍历和元数据维护相对复杂；目前代码没有实现 per-CPU 缓存或跨页 slab，所以在超大对象场景下仍需其他分配器补充，而
    buddy 天然能分配大块页。

  总结：相较 best_fit，SLUB 在页层基础上扩展了对象缓存，极大改善小块管理；相较 buddy，它保持分块灵活并提供对象级接口。当前实现把
  slab 限定为单页，适合实验环境，也为后续扩展（多页 slab、per-CPU cache）预留空间。


## 10. 一些Q&A帮助理解
Q：在初始化时就已经为每个默认size划分了一个slab了吗，也就是说在一开始就有几个slab里是默认大小的对象，然后内核申请时直接从中占用一个对象，对吗

A:不是的。slub_init() 阶段只给 12 个默认 slub_cache 做了元数据初始化（名字、对象步长、每页可容纳对象数等），并没有提前向页分配器要页来做 slab。真正的 slab 只会在第一次分配该尺寸对象时才创建：slub_cache_do_alloc() 发现 partial 为空，会调用 slub_new_slab()向底层申请 1 页并初始化 freelist，然后再从这页里取对象。所以系统启动时并不存在“预先铺好”的 slab，都是按需创建、用完再整页回收的。

Q:那么，用到一个大小的对象才会创建对应的slab，然后这个slab就一直等待对应大小内存的申请，对吗

A:对，某个 cache 第一次被使用时才会创建 slab：
   - slub_cache_do_alloc() 发现 partial 链空，调用 slub_new_slab() 向页层申请 1 页并初始化 freelist，然后从中分配对象。
   - 之后这页会一直服务同一尺寸的请求；对象被释放后回到同一个 slab 的空闲链。
不过 slab 不是永久“等待”的：当某个 slab 上的对象全部被释放，slub_cache_do_free() 会把它从 partial 链上摘掉并调用slub_release_slab()，把整页还回页层。所以只有“仍然有对象在用”的 slab 会留在 cache 里，空的 slab 会立即归还，不会长期占着一页。

Q:看起来cache是有数量的，如果我用到的大小类型数量超过了可以创建的cache数量，会发生什么？

A:默认的 12 个 size class 是一次初始化好、之间共享的，不受数量限制；限制只出现在“自定义 cache”。代码里给自定义缓存预留了SLUB_MAX_CUSTOM_CACHES = 8 个槽位（slub_custom_caches 数组），slub_cache_create() 每成功调用一次就占用一个槽，超过就返回 NULL，表示无法再创建新的 cache，上层需要自己处理这个失败。
可以通过两种方式解决：1> 复用现有 cache（例如取最接近的一个）；2>调整实现，增大 SLUB_MAX_CUSTOM_CACHES 或改写为动态扩容。
默认尺寸的 cache 与此无关，因此一般内核常见尺寸不会触碰到这个上限。

Q:关于自定义cache的创建，他是申请一个页作为slab然后划分成一个个对应大小的对象吗？这个对象的大小正好等于申请的内存大小吗

A:自定义 cache 的创建过程和默认 cache 一样：
  1. slub_cache_create() 只是登记对象尺寸、对齐、每页能装多少个，并把 cache 挂到全局链表；此时不会立即去申请页。
  2. 只有当首次调用 slub_cache_alloc() 时，才会触发 slub_new_slab() 向页层申请 1 页，并在这页上划分成多个槽位。
  关于“槽位的大小”：
  - 代码里把 obj_size 向上取整到 obj_stride：既要满足对齐（至少 8 字节），又要保证能放下 uint16_t 的 freelist 指针。
  - 插槽在分配前会把整个 obj_size 区域清零，因此应用侧看到的可用字节数就是创建 cache 时指定的大小。
  - 当对象被释放时，前 2 个字节会写入下一个空闲槽的索引（用来维持单向链表）；下一次重新分配时，整个 obj_size 会再次清零覆盖掉这些数据。
  总结：一个自定义 cache 第一次用到时才实际拿一页，把这一页按照 obj_stride 切成若干块；块的“可用部分”恰好等于申请时的 obj_size，只是在内部为了链表和对齐，真实占用可能比要求的略大一些。

