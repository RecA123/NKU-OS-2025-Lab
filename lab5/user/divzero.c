#include <stdio.h>
#include <ulib.h>

volatile int zero;

int
main(void) {
    int result;
    asm volatile("div %0, %1, %2"
                 : "=r"(result)
                 : "r"(1), "r"(zero));
    cprintf("value is %d.\n", result);
    panic("FAIL: T.T\n");
}
