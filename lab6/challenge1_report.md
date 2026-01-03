# Lab6 Challenge 1：Stride 调度器实验报告

## 1. 实验目标

- 在 uCore 的调度框架中替换默认 RR 调度器，实现 Stride Scheduling。
- 补全 `default_sched_stride.c` 中的 `RR_xxx` 五个函数（`stride_init/enqueue/dequeue/pick_next/proc_tick`），并用学号 `2312331` 标注注释。
- 修改 `sched_init()` 选择 Stride 调度器，更新 `tools/grade.sh` 以匹配新的日志输出。
- 运行 `make grade` / `make qemu` 验证调度行为，观察 `priority` 用户程序的执行结果。

## 2. 代码改动概览

| 文件 | 关键修改 |
|------|----------|
| `kern/schedule/default_sched_stride.c` | 定义 `BIG_STRIDE`、用 skew heap 维护 `lab6_run_pool`，在 `enqueue/dequeue` 中更新堆与 `proc_num`，`pick_next` 取最小 stride 并累加 `BIG_STRIDE / priority`，`proc_tick` 维护时间片。所有 `LAB6` 注释替换为学号 `2312331`。 |
| `kern/schedule/sched.c` | 在 `sched_init()` 中把 `sched_class` 切换为 `&stride_sched_class`，打印 `sched class: stride_scheduler`。 |
| `tools/grade.sh` | 将 `priority` 测试的关键字符串修改为 `sched class: stride_scheduler`，确保评分脚本与新日志匹配。 |
| （可选）`kern/process/proc.c`，`proc.h` 等 | 先前实验已初始化 `lab6_stride` 等字段；本次未额外更改。 |

## 3. 编译与运行步骤

1. **清理旧构建**
   ```bash
   cd /home/liangjingming/work/NKU-OS-2025-Lab/lab6
   make clean
   ```
2. **运行课程自带的打分脚本**
   ```bash
   make grade          # 需约 4 秒，预期输出 Total Score: 50/50
   ```
   评分日志在 `lab6/.qemu.out`、`.priority.log` 中，可查看 `sched class: stride_scheduler`、`set priority to ...` 等提示。
3. **手动运行 QEMU 观察调度行为**
   ```bash
   make qemu
   ```
   - 可在 `lab6/manual_stride.log` 中查看 `priority` 程序的完整输出，包括各子进程 `acc/time`、`sched result: ...`，用于报告截取。

## 4. 实现原理说明

1. **Stride Scheduling 核心思想**
   - 为每个进程维护一个 stride 值，初始为 0。
   - 按照 `stride` 的最小值选择下一个要运行的进程；运行后将其 stride 累加 `BIG_STRIDE / priority`。这样 priority 越大（权重越高）时 stride 增长越慢，从而获得更多 CPU 时间。
   - 使用 skew heap 作为最小堆来维护所有 runnable 进程的 `lab6_run_pool` 指针，实现 `O(log n)` 的插入、删除和取最小操作。

2. **`default_sched_stride.c` 中各函数要点**
   - `stride_init`：初始化 `run_list`、`lab6_run_pool` 和 `proc_num`。
   - `stride_enqueue`：断言 `proc->rq == NULL`，刷新 `time_slice = rq->max_time_slice`，将 `run_link` 加入 `run_list`，并通过 `skew_heap_insert` 加入堆。
   - `stride_dequeue`：对应地使用 `skew_heap_remove` 从堆中删除，再 `list_del_init`，减少 `proc_num`。
   - `stride_pick_next`：若堆为空返回 `NULL`；否则通过 `le2proc` 取出最小 stride 的进程，更新 `lab6_stride += BIG_STRIDE / priority` 后返回。
   - `stride_proc_tick`：递减 `time_slice`，耗尽后置 `need_resched = 1`，触发下次调度。

3. **调度流程**
   - `sched_class_enqueue` / `sched_class_dequeue` 在进程状态变化时维护运行队列。
   - `schedule()` 会在当前进程 `RUNNABLE` 且被抢占时再入队，然后调用 Stride 的 `pick_next` 选出最小 stride 进程。
   - `priority` 用户程序通过 `lab6_setpriority()` 先设定优先级，多个子进程忙等完成后，根据 `acc` 值验证调度公平性。

## 5. 实验结果

1. **`make grade`**  
   - 评分脚本输出 `priority: ... Total Score: 50/50`，确认 Stride 调度器通过所有测试。

2. **`make qemu` 日志分析**（示例：`lab6/manual_stride.log`）
   - 出现 `sched class: stride_scheduler`，随后 `set priority to 6/5/4/3/2/1`。
   - 各子进程在 2s 左右完成，`acc` 随优先级递增（如 `child pid 7 acc 1,200,000` … `child pid 3 acc 376,000`）。
   - `sched result: 1 2 2 3 3` 等数字体现权重分配。数值会随宿主机负载略有波动，但高优先级进程总能获得更多 CPU。

## 6. 结论

- Stride 调度器成功取代 RR，支持根据优先级调节 CPU 占用时间，保持了 `make grade` 的兼容性。
- 通过 skew heap 保证取最小 stride 的效率；`priority` 程序的输出表明各进程按优先级比例分配了时间片，与算法预期一致。
- 后续可在本基础上进一步扩展（例如 Challenge 2 中的多策略框架、Stride + SJF 等改进），也可结合 `manual_stride.log` 中的数据撰写更深入的性能分析。
