#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <sched.h>
#include <default_sched.h>
#include <skew_heap.h>

// LAB6 CH2:2312632 Shortest Job First scheduler (non-preemptive)

static int
proc_sjf_comp(void *a, void *b)
{
    struct proc_struct *p = le2proc(a, lab6_run_pool);
    struct proc_struct *q = le2proc(b, lab6_run_pool);
    int32_t diff = (int32_t)p->lab6_expected_runtime - (int32_t)q->lab6_expected_runtime;
    if (diff > 0)
        return 1;
    if (diff < 0)
        return -1;
    if (p->pid > q->pid)
        return 1;
    if (p->pid < q->pid)
        return -1;
    return 0;
}

static void
sjf_init(struct run_queue *rq)
{
    list_init(&(rq->run_list));
    rq->proc_num = 0;
    rq->lab6_run_pool = NULL;
}

static void
sjf_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(proc->rq == NULL);
    if (proc->lab6_expected_runtime == 0)
    {
        proc->lab6_expected_runtime = rq->max_time_slice;
    }
    proc->time_slice = proc->lab6_expected_runtime;
    proc->rq = rq;
    list_add_before(&(rq->run_list), &(proc->run_link));
    rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool,
                                         &(proc->lab6_run_pool),
                                         proc_sjf_comp);
    rq->proc_num++;
}

static void
sjf_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(proc->rq == rq);
    rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool,
                                         &(proc->lab6_run_pool),
                                         proc_sjf_comp);
    list_del_init(&(proc->run_link));
    proc->rq = NULL;
    assert(rq->proc_num > 0);
    rq->proc_num--;
}

static struct proc_struct *
sjf_pick_next(struct run_queue *rq)
{
    if (rq->lab6_run_pool == NULL)
    {
        return NULL;
    }
    return le2proc(rq->lab6_run_pool, lab6_run_pool);
}

static void
sjf_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // Non-preemptive SJF; keep hint available for next enqueue.
    proc->time_slice = proc->lab6_expected_runtime;
}

struct sched_class sjf_sched_class = {
    .name = "sjf_scheduler",
    .init = sjf_init,
    .enqueue = sjf_enqueue,
    .dequeue = sjf_dequeue,
    .pick_next = sjf_pick_next,
    .proc_tick = sjf_proc_tick,
};
