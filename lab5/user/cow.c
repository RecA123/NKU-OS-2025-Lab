#include <stdio.h>
#include <ulib.h>
#include <string.h>
#include <stdlib.h>

static char buf[2 * 4096];

int main(void) {
    buf[0] = 'A';
    buf[4096] = 'X';

    int pid = fork();
    if (pid < 0) {
        cprintf("fork failed\n");
        exit(-1);
    }

    if (pid == 0) {
        // child writes both pages, should trigger COW
        buf[0] = 'B';
        buf[4096] = 'Y';
        cprintf("child wrote pages: %c %c\n", buf[0], buf[4096]);
        exit(0);
    }

    // parent waits
    waitpid(pid, NULL);

    // parent should still see original contents
    if (buf[0] != 'A' || buf[4096] != 'X') {
        cprintf("COW failed: parent sees %c %c\n", buf[0], buf[4096]);
        exit(-1);
    }

    cprintf("cow pass.\n");
    return 0;
}
