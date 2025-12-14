#ifndef __KERN_MM_COW_H__
#define __KERN_MM_COW_H__

#include <defs.h>

struct mm_struct;

/*
 * Dirty COW 统计结构：
 *   emulate_bug    : 1 表示复现漏洞，0 表示启用修复路径。
 *   unsafe_writes  : 记录在 bug 模式下，mempoke 被“无防护”执行的次数，用来展示漏洞影响。
 *   repaired_writes: 记录在 fix 模式下，一次写操作触发 COW 拆分并被安全处理的次数。
 *  这两个计数会在 kmonitor 的 dirtycow 命令里打印，方便实验展示。
 */
struct dirtycow_stats
{
    bool emulate_bug;       // 当前是否处于故意复现 Dirty COW 漏洞的“bug 模式”
    uint64_t unsafe_writes; // 在 bug 模式下被允许的“危险写”次数
    uint64_t repaired_writes; // 在 fix 模式下被成功拦截并触发 COW 拆分的写次数
};

extern struct dirtycow_stats dirtycow_stats;

// dirtycow_set_mode - 切换漏洞/修复模式（传 1 或 0）
void dirtycow_set_mode(bool enable_bug);
// dirtycow_mode_string - 以字符串形式（buggy/fixed）返回当前模式，供调试输出
const char *dirtycow_mode_string(void);
// dirtycow_mempoke - Dirty COW PoC 的主要实现：
//   1) 先把用户缓冲复制进内核
//   2) fix 模式下为每一页调用 do_pgfault，确保写前复制
//   3) 最终直接改写用户页内容
int dirtycow_mempoke(struct mm_struct *mm, uintptr_t dst, const void *src, size_t len);

#endif /* !__KERN_MM_COW_H__ */
