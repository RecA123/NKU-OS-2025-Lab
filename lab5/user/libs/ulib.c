#include <defs.h>
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
    sys_exit(error_code);
    cprintf("BUG: exit failed.\n");
    while (1);
}

int
fork(void) {
    return sys_fork();
}

int
wait(void) {
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
}

void
yield(void) {
    sys_yield();
}

int
kill(int pid) {
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
}

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    sys_pgdir();
}
// mempoke - Dirty COW 演示用“越权写”接口，相当于 /proc/self/mem
// mempoke - Dirty COW 演示中的“内核代写”接口
//   参数 dst：用户态要写入的目标虚拟地址
//   参数 src：用户提供的缓冲区（将先复制到内核，再由内核写回 dst）
//   参数 len：写入长度
//   返回值：直接返回 sys_mempoke 的执行结果（0 表示成功，负值为错误码）
int
mempoke(void *dst, const void *src, size_t len) {
    return sys_mempoke((uintptr_t)dst, (uintptr_t)src, len);
}

// dirtycowctl - 控制 Dirty COW 演示模式
//   mode = -1：只查询当前模式；0：切到修复模式；1：切到漏洞模式
//   返回值：sys_dirtycowctl 的返回值，也就是内核当前记录的模式（0=fix,1=bug）
int
dirtycowctl(int mode) {
    return sys_dirtycowctl(mode);
}

