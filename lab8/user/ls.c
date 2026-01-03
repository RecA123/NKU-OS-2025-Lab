#include <stdio.h>
#include <ulib.h>
#include <dir.h>
#include <string.h>

int
main(int argc, char **argv)
{
    const char *path = (argc >= 2) ? argv[1] : "/";
    DIR *d = opendir(path);
    if (d == NULL)
    {
        cprintf("ls: cannot open %s\n", path);
        return -1;
    }

    struct dirent *de;
    while ((de = readdir(d)) != NULL)
    {
        cprintf("%s\n", de->name);
    }
    closedir(d);
    return 0;
}
