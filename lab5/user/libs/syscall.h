#ifndef __USER_LIBS_SYSCALL_H__
#define __USER_LIBS_SYSCALL_H__

int sys_exit(int64_t error_code);
int sys_fork(void);
int sys_wait(int64_t pid, int *store);
int sys_yield(void);
int sys_kill(int64_t pid);
int sys_getpid(void);
int sys_putc(int64_t c);
int sys_pgdir(void);
int sys_mempoke(uintptr_t dst, uintptr_t src, size_t len); // Dirty COW 内核代写接口
int sys_dirtycowctl(int mode); // Dirty COW 模式控制

#endif /* !__USER_LIBS_SYSCALL_H__ */

