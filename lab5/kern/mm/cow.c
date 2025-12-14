#include <cow.h>
#include <error.h>
#include <kmalloc.h>
#include <memlayout.h>
#include <pmm.h>
#include <string.h>
#include <vmm.h>

// 全局统计变量，配合 kmonitor 的 dirtycow 命令输出
struct dirtycow_stats dirtycow_stats = {
    .emulate_bug = 0,
    .unsafe_writes = 0,
    .repaired_writes = 0,
};

// dirtycow_set_mode - 切换 Dirty COW 演示模式
//   enable_bug = true  -> 进入漏洞复现模式（允许越权写）
//   enable_bug = false -> 进入修复模式（写前复制）
void dirtycow_set_mode(bool enable_bug)
{
    dirtycow_stats.emulate_bug = enable_bug ? 1 : 0;
}

// dirtycow_mode_string - 返回 "buggy"/"fixed"，供日志/命令行显示
const char *dirtycow_mode_string(void)
{
    return dirtycow_stats.emulate_bug ? "buggy" : "fixed";
}

// dirtycow_prepare_page - 在 mempoke 真正写数据之前，根据当前模式做预处理
//   1. 先确认目标页存在且有效
//   2. bug 模式：只做计数，直接放行，模拟 Dirty COW 漏洞
//   3. fix 模式：若 PTE 没有写权限，调用 do_pgfault(mm,PTE_W,la)
//      * do_pgfault 会根据引用计数决定“复制新页”还是“恢复写位”
//      * 成功后统计 repaired_writes++
//   返回值 0 表示可以继续写数据；负值为错误码
static int dirtycow_prepare_page(struct mm_struct *mm, uintptr_t la)
{
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
    if (ptep == NULL || !(*ptep & PTE_V))
    {
        return -E_INVAL;
    }

    if (dirtycow_stats.emulate_bug)
    {
        dirtycow_stats.unsafe_writes++;
        return 0;
    }

    if ((*ptep & PTE_W) == 0)
    {
        int ret = do_pgfault(mm, PTE_W, la);
        if (ret != 0)
        {
            return ret;
        }
        dirtycow_stats.repaired_writes++; // 记录 fix 模式下成功触发 COW 的次数
    }
    return 0;
}

// dirtycow_user_mem_write - 把临时缓冲区写入用户地址空间
//   1. 做地址合法性检查，确保 dst..dst+len 在用户区
//   2. 逐页处理：把 [dst,dst+len) 划分为一段段不跨页的块
//      * 每个块写入前调用 dirtycow_prepare_page
//      * fix 模式下就可以在此处触发写时复制
//   3. 通过页表拿到物理页的 kva，执行 memcpy
static int dirtycow_user_mem_write(struct mm_struct *mm, uintptr_t dst, const void *buf, size_t len)
{
    uintptr_t end = dst + len;
    if (end < dst || !USER_ACCESS(dst, end))
    {
        return -E_INVAL;
    }

    size_t copied = 0;
    while (copied < len)
    {
        uintptr_t la = dst + copied;
        uintptr_t la_page = ROUNDDOWN(la, PGSIZE);
        size_t page_off = la - la_page;
        size_t chunk = len - copied;
        size_t remain = PGSIZE - page_off;
        if (chunk > remain)
        {
            chunk = remain;
        }

        int ret = dirtycow_prepare_page(mm, la_page);
        if (ret != 0)
        {
            return ret;
        }

        pte_t *ptep = get_pte(mm->pgdir, la_page, 0);
        if (ptep == NULL || !(*ptep & PTE_V))
        {
            return -E_FAULT;
        }
        char *kva = page2kva(pte2page(*ptep));
        memcpy(kva + page_off, (const char *)buf + copied, chunk);

        copied += chunk;
    }

    return 0;
}

/*
 * dirtycow_mempoke - Dirty COW PoC 的真正入口（供 sys_mempoke 调用）
 *   - mm       : 当前进程的地址空间描述符
 *   - dst/src  : 用户传入的目的/源地址
 *   - len      : 要写入的字节数
 *
 *   执行流程：
 *     1. 检查参数（空 mm 或 len=0 都直接返回）
 *     2. kmalloc 临时缓冲，把用户数据 copy 进内核，保证后续不受用户态修改影响
 *     3. 调用 dirtycow_user_mem_write 逐页写入（内部会根据模式触发/跳过 COW）
 *     4. 用 goto out 统一释放临时缓冲，避免重复代码
 */
int dirtycow_mempoke(struct mm_struct *mm, uintptr_t dst, const void *src, size_t len)
{
    if (mm == NULL)
    {
        return -E_INVAL;
    }
    if (len == 0)
    {
        return 0;
    }

    void *kbuf = kmalloc(len);
    if (kbuf == NULL)
    {
        return -E_NO_MEM;
    }

    int ret = 0;
    if (!copy_from_user(mm, kbuf, src, len, 0))
    {
        ret = -E_FAULT;
        goto out;
    }

    ret = dirtycow_user_mem_write(mm, dst, kbuf, len);

out:
    kfree(kbuf);
    return ret;
}
