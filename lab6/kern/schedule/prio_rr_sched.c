#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <sched.h>
#include <default_sched.h>

// LAB6 CH2:2312632 Priority-based Round Robin scheduler

#define MAX_PRIORITY_SLICE 8

static inline int
calc_time_slice(struct run_queue *rq, struct proc_struct *proc)
{
    int weight = (int)proc->lab6_priority;
    if (weight <= 0)
    {
        weight = 1;
    }
    if (weight > MAX_PRIORITY_SLICE)
    {
        weight = MAX_PRIORITY_SLICE;
    }
    return rq->max_time_slice * weight;
}

static void
prio_rr_init(struct run_queue *rq)
{
    list_init(&(rq->run_list));
    rq->proc_num = 0;
    rq->lab6_run_pool = NULL;
}

static void
prio_rr_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(proc->rq == NULL);
    proc->time_slice = calc_time_slice(rq, proc);
    proc->rq = rq;
    list_add_before(&(rq->run_list), &(proc->run_link));
    rq->proc_num++;
}

static void
prio_rr_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(proc->rq == rq);
    list_del_init(&(proc->run_link));
    proc->rq = NULL;
    assert(rq->proc_num > 0);
    rq->proc_num--;
}

static struct proc_struct *
prio_rr_pick_next(struct run_queue *rq)
{
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list))
    {
        return le2proc(le, run_link);
    }
    return NULL;
}

static void
prio_rr_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    if (proc->time_slice > 0)
    {
        proc->time_slice--;
    }
    if (proc->time_slice <= 0)
    {
        proc->need_resched = 1;
        proc->time_slice = calc_time_slice(rq, proc);
    }
}

struct sched_class prio_rr_sched_class = {
    .name = "prio_rr_scheduler",
    .init = prio_rr_init,
    .enqueue = prio_rr_enqueue,
    .dequeue = prio_rr_dequeue,
    .pick_next = prio_rr_pick_next,
    .proc_tick = prio_rr_proc_tick,
};
