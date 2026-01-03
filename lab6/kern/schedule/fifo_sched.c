#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <sched.h>
#include <default_sched.h>

// LAB6 CH2:2312632 First-Come-First-Serve scheduler (non-preemptive)

static void
fifo_init(struct run_queue *rq)
{
    list_init(&(rq->run_list));
    rq->proc_num = 0;
    rq->lab6_run_pool = NULL;
}

static void
fifo_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(proc->rq == NULL);
    proc->time_slice = rq->max_time_slice;
    proc->rq = rq;
    list_add_before(&(rq->run_list), &(proc->run_link));
    rq->proc_num++;
}

static void
fifo_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(proc->rq == rq);
    list_del_init(&(proc->run_link));
    proc->rq = NULL;
    assert(rq->proc_num > 0);
    rq->proc_num--;
}

static struct proc_struct *
fifo_pick_next(struct run_queue *rq)
{
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list))
    {
        return le2proc(le, run_link);
    }
    return NULL;
}

static void
fifo_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // FCFS is non-preemptive; keep refreshing slice to avoid forced reschedule.
    proc->time_slice = rq->max_time_slice;
}

struct sched_class fifo_sched_class = {
    .name = "fifo_scheduler",
    .init = fifo_init,
    .enqueue = fifo_enqueue,
    .dequeue = fifo_dequeue,
    .pick_next = fifo_pick_next,
    .proc_tick = fifo_proc_tick,
};
