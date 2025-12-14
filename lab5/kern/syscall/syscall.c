#include <unistd.h>
#include <proc.h>
#include <syscall.h>
#include <trap.h>
#include <stdio.h>
#include <pmm.h>
#include <assert.h>
#include <error.h>
#include <cow.h>

static int
sys_exit(uint64_t arg[]) {
    int error_code = (int)arg[0];
    return do_exit(error_code);
}

static int
sys_fork(uint64_t arg[]) {
    struct trapframe *tf = current->tf;
    uintptr_t stack = tf->gpr.sp;
    return do_fork(0, stack, tf);
}

static int
sys_wait(uint64_t arg[]) {
    int pid = (int)arg[0];
    int *store = (int *)arg[1];
    return do_wait(pid, store);
}

static int
sys_exec(uint64_t arg[]) {
    const char *name = (const char *)arg[0];
    size_t len = (size_t)arg[1];
    unsigned char *binary = (unsigned char *)arg[2];
    size_t size = (size_t)arg[3];
    return do_execve(name, len, binary, size);
}

static int
sys_yield(uint64_t arg[]) {
    return do_yield();
}

static int
sys_kill(uint64_t arg[]) {
    int pid = (int)arg[0];
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
}

static int
sys_putc(uint64_t arg[]) {
    int c = (int)arg[0];
    cputchar(c);
    return 0;
}

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}

// sys_mempoke - Dirty COW 演示用的“内核代写”系统调用
//   arg[0] = dst 目标用户虚拟地址；arg[1] = src 用户缓冲区；arg[2] = len
//   这里直接把三个参数转换，再交给 dirtycow_mempoke 处理，
//   它会根据当前“bug / fix”模式决定是否触发真正的 COW 拆分
static int
sys_mempoke(uint64_t arg[]) {
    uintptr_t dst = (uintptr_t)arg[0];
    const void *src = (const void *)arg[1];
    size_t len = (size_t)arg[2];
    return dirtycow_mempoke(current->mm, dst, src, len);
}

// sys_dirtycowctl - Dirty COW 演示模式控制
//   mode = -1: 查询当前模式，0 表示修复，1 表示漏洞复现
//   mode = 0/1: 切换到 fix/bug 模式
//   其它数值返回 -E_INVAL
static int
sys_dirtycowctl(uint64_t arg[]) {
    int mode = (int)arg[0];
    if (mode == -1)
    {
        return dirtycow_stats.emulate_bug;
    }
    if (mode == 0)
    {
        dirtycow_set_mode(0);
    }
    else if (mode == 1)
    {
        dirtycow_set_mode(1);
    }
    else
    {
        return -E_INVAL;
    }
    return dirtycow_stats.emulate_bug;
}

static int (*syscalls[])(uint64_t arg[]) = {
    [SYS_exit]              sys_exit,
    [SYS_fork]              sys_fork,
    [SYS_wait]              sys_wait,
    [SYS_exec]              sys_exec,
    [SYS_yield]             sys_yield,
    [SYS_kill]              sys_kill,
    [SYS_getpid]            sys_getpid,
    [SYS_putc]              sys_putc,
    [SYS_pgdir]             sys_pgdir,
    [SYS_mempoke]           sys_mempoke,
    [SYS_dirtycowctl]       sys_dirtycowctl,
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
        if (syscalls[num] != NULL) {
            arg[0] = tf->gpr.a1;
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
            return ;
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}

