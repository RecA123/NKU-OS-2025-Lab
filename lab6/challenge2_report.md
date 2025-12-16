# Lab6 Challenge 2 调度器实验报告

## 1. 环境准备

1. 安装 RISC-V 交叉编译链与 QEMU 4.1.1，项目默认使用 `/home/liangjingming/work/qemu-4.1.1/build/riscv64-softmmu/qemu-system-riscv64`。
2. 克隆仓库后进入 `lab6` 目录，所有命令均在该目录下执行。
3. `Makefile` 新增 `SCHED` 与 `TEST` 变量，可在命令行通过 `make SCHED=<策略> TEST=<用户程序> ...` 选择调度算法和启动的用户态基准程序。

## 2. 调度框架实现概述

- 在 `kern/schedule/sched.h` 定义 `SCHED_RR/SCHED_STRIDE/SCHED_FIFO/SCHED_SJF/SCHED_PRIO_RR` 宏，`sched.c` 内的 `select_sched_class()` 会在 `sched_init()` 时根据 `SCHED_POLICY` 选择对应的调度器。
- 新增调度器实现文件：
  - `kern/schedule/fifo_sched.c`：先来先服务（非抢占）。
  - `kern/schedule/sjf_sched.c`：短作业优先（非抢占，基于 `lab6_expected_runtime` 的最小堆）。
  - `kern/schedule/prio_rr_sched.c`：带权时间片轮转（按优先级放大 `time_slice`）。
- `proc_struct` 增加 `lab6_expected_runtime` 字段，并通过新 syscall `SYS_lab6_set_runtime`/`lab6_set_runtime()` 在用户态提供运行时间提示，方便 SJF 与分析用例使用。
- `Makefile` 的 `TEST` 变量会把指定用户程序的 `_binary_obj___user_xxx_out_*` 符号编译进内核，`user_main` 会自动执行该程序以便复现实验。

## 3. 基准测试设计（`user/sched_bench.c`）

1. 在 `sched bench start` 处 fork 5 个 CPU-bound 子进程，工作量设为 200/400/600/800/1000 ms，并分别调用 `lab6_setpriority()` 与 `lab6_set_runtime()`。
2. 每个子进程忙等到 `workload` 到期后退出，退出码打包 `(elapsed_ms << 16) | workload`，方便父进程解码。
3. 父进程 `waitpid` 收集所有任务的 `work/elapsed/wait`，统计平均周转时间与平均等待时间，并打印 `bench summary`。

## 4. 运行方法（可复现实验的完整流程）

```bash
cd /home/liangjingming/work/NKU-OS-2025-Lab/lab6

# 1) 清理旧构建
make clean

# 2) 选择调度器 + 运行 bench 程序（示例：Stride）
make SCHED=stride TEST=sched_bench qemu    # 输出记录在 lab6/manual_stride_bench.log

# 3) 依次评估其他调度器
make clean && make SCHED=rr TEST=sched_bench qemu
make clean && make SCHED=fifo TEST=sched_bench qemu
make clean && make SCHED=sjf TEST=sched_bench qemu
make clean && make SCHED=prio_rr TEST=sched_bench qemu

# 4) 运行课程自带 priority 测例（默认 Stride）
make clean
make grade     # 应获得 Total Score 50/50，日志存于 .priority.log/.qemu.out
```

所有运行日志会保存在 `lab6/manual_*.log` 中，可直接用于报告引用。

## 5. 数据与分析

| 调度器      | 平均周转时间 (ms) | 平均等待时间 (ms) | 数据来源日志                    |
|-------------|-------------------|-------------------|---------------------------------|
| Stride      | 660               | 60                | `lab6/manual_stride_bench.log`  |
| RR          | 620               | 20                | `lab6/manual_rr_bench.log`      |
| FIFO        | 600               | 0                 | `lab6/manual_fifo_bench.log`    |
| SJF         | 600               | 0                 | `lab6/manual_sjf_bench.log`     |
| Priority RR | 650               | 50                | `lab6/manual_prio_rr_bench.log` |

- **FIFO（非抢占）**：先到先服务，开销最小且等待时间为 0，但一个长任务会阻塞其后的所有任务，适合批处理或对响应要求低的场景。
- **SJF（非抢占）**：依赖 `lab6_set_runtime` 提示，始终运行剩余时间最短的任务，等待时间也为 0，吞吐与 FIFO 相当，但必须事先估计工作量，对在线任务不够友好。
- **RR（抢占）**：固定时间片轮转，公平性与响应速度最好，平均等待仅 20ms，但短任务无法获得额外优势，切换频繁时会有一定开销，适合交互式负载。
- **Stride（抢占）**：根据优先级调整 stride，能够确保高优先级任务获得更多 CPU 时间，平均等待 60ms；实现依赖堆结构，适合需要细粒度配额控制的场景。
- **Priority RR（抢占）**：在 RR 基础上按优先级放大时间片，平均等待 50ms，既保留 RR 的抢占响应，也增强了区分度；需要额外的优先级管理防止饥饿。
- **非抢占 vs 抢占**：非抢占（FIFO/SJF）等待时间最短，但缺乏交互性；抢占式（RR/Stride/Prio-RR）响应及时、任务公平性高，但平均等待随时间片与优先级策略而变化。

## 6. 结论与扩展思考

- Challenge 2 中通过统一的 `SCHED` 机制，可方便地在 uCore 中切换多种调度策略；`sched_bench` 提供了定量比较的依据，可直接在日志中观察每个任务的工作量与等待时间。
- 如果需要进一步扩展实验，可尝试：
  1. 在 `sched_bench` 中增添 I/O 绑定或突发 workload，评估调度器在混合场景下的表现。
  2. 实现抢占式 SJF（即最短剩余时间优先）或多级反馈队列，根据任务历史动态调节优先级。
  3. 改进 `priority` 程序或编写脚本自动解析 `manual_*.log`，生成图表或 CSV，便于在报告与答辩中展示。

通过本文档的步骤，即使未亲自完成代码，也可以在同一环境中复现所有调度器的构建、运行与数据分析过程。只需依次执行“清理 → 选择调度器 → 运行 bench/priority → 收集日志”四步，即可得到完整的 Challenge 2 结果。
