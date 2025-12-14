#include <stdio.h>
#include <string.h>
#include <ulib.h>

/*
 * Dirty COW PoC（用户态）整体思路：
 *   1. victim 指向代码段/只读数据段里的字符串，按照内存保护机制只能读不能写。
 *   2. mempoke() 会触发 SYS_mempoke，内核在 bug 模式下直接修改共享物理页，
 *      在 fix 模式下会先拆分 COW，从而阻止越权写。
 *   3. dirtycowctl() 用来查询/切换模式，实现“同一次运行展示失败与成功”。
 */

// victim 指向的是只读段（全局 const 字符串），理论上用户态无法写入
static const char victim[] = "DIRTYCOW DEMO: READ ONLY DATA";
// payload 是我们想“注入”的内容
static const char payload[] = "DIRTYCOW DEMO: OWNED BY USER!";

// try_patch - 封装一次 mempoke 调用并打印结果
//   tag 用来区分当前处于 fix 还是 bug 测试阶段
static void try_patch(const char *tag)
{
    int ret = mempoke((void *)victim, payload, sizeof(payload) - 1);
    if (ret < 0)
    {
        // ret<0 代表内核拒绝了写入（fix 模式），victim 保持原状
        cprintf("[dirtycow][%s] blocked (ret=%d), victim -> \"%s\"\n", tag, ret, victim);
    }
    else
    {
        // ret==0 表示写入成功（bug 模式），只读字符串被篡改
        cprintf("[dirtycow][%s] succeeded, victim -> \"%s\"\n", tag, victim);
    }
}

int main(void)
{
    cprintf("[dirtycow] pid=%d victim@%p -> \"%s\"\n", getpid(), victim, victim);
    cprintf("[dirtycow] dirtycowctl(-1) queries mode, dirtycowctl(0/1) toggles fix/bug.\n");

    // 记录运行前的模式，便于退出前还原，避免影响其他测试
    int prev = dirtycowctl(-1);

    dirtycowctl(0);             // 1) 切到修复模式，预期 mempoke 会返回错误
    try_patch("fix");

    dirtycowctl(1);             // 2) 切到漏洞模式，预期 mempoke 能成功修改 victim
    try_patch("bug");

    // 3) 恢复原有模式，保持测试环境整洁
    if (prev == 0 || prev == 1)
    {
        dirtycowctl(prev);
    }
    return 0;
}
