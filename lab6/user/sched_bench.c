#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define TASKS 5

static const uint32_t workloads[TASKS] = {200, 400, 600, 800, 1000};
static const uint32_t priorities[TASKS] = {6, 5, 4, 3, 2};

static void
spin_unit(void)
{
    volatile int x = 0;
    for (int i = 0; i < 1024; i++)
    {
        x += i;
    }
}

static void
run_child(int idx)
{
    uint32_t work = workloads[idx];
    uint32_t prio = priorities[idx];
    lab6_setpriority(prio);
    lab6_set_runtime(work);
    uint32_t start = gettime_msec();
    uint32_t deadline = start + work;
    while (gettime_msec() < deadline)
    {
        spin_unit();
    }
    uint32_t end = gettime_msec();
    uint32_t elapsed = end - start;
    uint32_t wait = (elapsed > work) ? (elapsed - work) : 0;
    cprintf("bench child #%d pid %d work=%u elapsed=%u wait=%u\n",
            idx, getpid(), work, elapsed, wait);
    uint32_t packed = ((elapsed & 0xFFFFU) << 16) | (work & 0xFFFFU);
    exit((int)packed);
}

static int
find_task_idx(uint32_t work)
{
    for (int i = 0; i < TASKS; i++)
    {
        if (workloads[i] == work)
        {
            return i;
        }
    }
    return -1;
}

int main(void)
{
    cprintf("sched bench start: tasks=%d\n", TASKS);
    for (int i = 0; i < TASKS; i++)
    {
        int pid = fork();
        if (pid == 0)
        {
            run_child(i);
        }
        if (pid < 0)
        {
            panic("fork failed\n");
        }
    }

    uint64_t total_elapsed = 0;
    uint64_t total_wait = 0;
    int finished = 0;
    while (finished < TASKS)
    {
        int status = 0;
        if (waitpid(0, &status) != 0)
        {
            panic("waitpid failed\n");
        }
        uint32_t work = status & 0xFFFFU;
        uint32_t elapsed = (status >> 16) & 0xFFFFU;
        uint32_t wait = (elapsed > work) ? (elapsed - work) : 0;
        int idx = find_task_idx(work);
        total_elapsed += elapsed;
        total_wait += wait;
        cprintf("parent: task_idx=%d work=%u elapsed=%u wait=%u\n",
                idx, work, elapsed, wait);
        finished++;
    }

    cprintf("bench summary: avg turnaround=%u avg wait=%u\n",
            (uint32_t)(total_elapsed / TASKS),
            (uint32_t)(total_wait / TASKS));
    cprintf("sched bench done\n");
    return 0;
}
