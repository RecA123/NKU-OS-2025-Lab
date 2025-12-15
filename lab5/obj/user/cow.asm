
obj/__user_cow.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  800020:	7175                	addi	sp,sp,-144
  800022:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  800024:	e0ba                	sd	a4,64(sp)
  800026:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  800028:	e42a                	sd	a0,8(sp)
  80002a:	ecae                	sd	a1,88(sp)
  80002c:	f0b2                	sd	a2,96(sp)
  80002e:	f4b6                	sd	a3,104(sp)
  800030:	fcbe                	sd	a5,120(sp)
  800032:	e142                	sd	a6,128(sp)
  800034:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  800036:	f42e                	sd	a1,40(sp)
  800038:	f832                	sd	a2,48(sp)
  80003a:	fc36                	sd	a3,56(sp)
  80003c:	f03a                	sd	a4,32(sp)
  80003e:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);

    asm volatile (
  800040:	6522                	ld	a0,8(sp)
  800042:	75a2                	ld	a1,40(sp)
  800044:	7642                	ld	a2,48(sp)
  800046:	76e2                	ld	a3,56(sp)
  800048:	6706                	ld	a4,64(sp)
  80004a:	67a6                	ld	a5,72(sp)
  80004c:	00000073          	ecall
  800050:	00a13e23          	sd	a0,28(sp)
        "sd a0, %0"
        : "=m" (ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        :"memory");
    return ret;
}
  800054:	4572                	lw	a0,28(sp)
  800056:	6149                	addi	sp,sp,144
  800058:	8082                	ret

000000000080005a <sys_exit>:

int
sys_exit(int64_t error_code) {
  80005a:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  80005c:	4505                	li	a0,1
  80005e:	b7c9                	j	800020 <syscall>

0000000000800060 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800060:	4509                	li	a0,2
  800062:	bf7d                	j	800020 <syscall>

0000000000800064 <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  800064:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  800066:	85aa                	mv	a1,a0
  800068:	450d                	li	a0,3
  80006a:	bf5d                	j	800020 <syscall>

000000000080006c <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  80006c:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  80006e:	4579                	li	a0,30
  800070:	bf45                	j	800020 <syscall>

0000000000800072 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  800072:	1141                	addi	sp,sp,-16
  800074:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800076:	fe5ff0ef          	jal	ra,80005a <sys_exit>
    cprintf("BUG: exit failed.\n");
  80007a:	00000517          	auipc	a0,0x0
  80007e:	53e50513          	addi	a0,a0,1342 # 8005b8 <main+0xc0>
  800082:	02a000ef          	jal	ra,8000ac <cprintf>
    while (1);
  800086:	a001                	j	800086 <exit+0x14>

0000000000800088 <fork>:
}

int
fork(void) {
    return sys_fork();
  800088:	bfe1                	j	800060 <sys_fork>

000000000080008a <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  80008a:	bfe9                	j	800064 <sys_wait>

000000000080008c <_start>:
.text
.globl _start
_start:
    # call user-program function
    call umain
  80008c:	056000ef          	jal	ra,8000e2 <umain>
1:  j 1b
  800090:	a001                	j	800090 <_start+0x4>

0000000000800092 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800092:	1141                	addi	sp,sp,-16
  800094:	e022                	sd	s0,0(sp)
  800096:	e406                	sd	ra,8(sp)
  800098:	842e                	mv	s0,a1
    sys_putc(c);
  80009a:	fd3ff0ef          	jal	ra,80006c <sys_putc>
    (*cnt) ++;
  80009e:	401c                	lw	a5,0(s0)
}
  8000a0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  8000a2:	2785                	addiw	a5,a5,1
  8000a4:	c01c                	sw	a5,0(s0)
}
  8000a6:	6402                	ld	s0,0(sp)
  8000a8:	0141                	addi	sp,sp,16
  8000aa:	8082                	ret

00000000008000ac <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000ac:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000ae:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000b2:	8e2a                	mv	t3,a0
  8000b4:	f42e                	sd	a1,40(sp)
  8000b6:	f832                	sd	a2,48(sp)
  8000b8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000ba:	00000517          	auipc	a0,0x0
  8000be:	fd850513          	addi	a0,a0,-40 # 800092 <cputch>
  8000c2:	004c                	addi	a1,sp,4
  8000c4:	869a                	mv	a3,t1
  8000c6:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  8000c8:	ec06                	sd	ra,24(sp)
  8000ca:	e0ba                	sd	a4,64(sp)
  8000cc:	e4be                	sd	a5,72(sp)
  8000ce:	e8c2                	sd	a6,80(sp)
  8000d0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  8000d2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  8000d4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000d6:	0a0000ef          	jal	ra,800176 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000da:	60e2                	ld	ra,24(sp)
  8000dc:	4512                	lw	a0,4(sp)
  8000de:	6125                	addi	sp,sp,96
  8000e0:	8082                	ret

00000000008000e2 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000e2:	1141                	addi	sp,sp,-16
  8000e4:	e406                	sd	ra,8(sp)
    int ret = main();
  8000e6:	412000ef          	jal	ra,8004f8 <main>
    exit(ret);
  8000ea:	f89ff0ef          	jal	ra,800072 <exit>

00000000008000ee <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8000ee:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8000f0:	e589                	bnez	a1,8000fa <strnlen+0xc>
  8000f2:	a811                	j	800106 <strnlen+0x18>
        cnt ++;
  8000f4:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8000f6:	00f58863          	beq	a1,a5,800106 <strnlen+0x18>
  8000fa:	00f50733          	add	a4,a0,a5
  8000fe:	00074703          	lbu	a4,0(a4)
  800102:	fb6d                	bnez	a4,8000f4 <strnlen+0x6>
  800104:	85be                	mv	a1,a5
    }
    return cnt;
}
  800106:	852e                	mv	a0,a1
  800108:	8082                	ret

000000000080010a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  80010a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80010e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  800110:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800114:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800116:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  80011a:	f022                	sd	s0,32(sp)
  80011c:	ec26                	sd	s1,24(sp)
  80011e:	e84a                	sd	s2,16(sp)
  800120:	f406                	sd	ra,40(sp)
  800122:	e44e                	sd	s3,8(sp)
  800124:	84aa                	mv	s1,a0
  800126:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800128:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  80012c:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80012e:	03067e63          	bgeu	a2,a6,80016a <printnum+0x60>
  800132:	89be                	mv	s3,a5
        while (-- width > 0)
  800134:	00805763          	blez	s0,800142 <printnum+0x38>
  800138:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80013a:	85ca                	mv	a1,s2
  80013c:	854e                	mv	a0,s3
  80013e:	9482                	jalr	s1
        while (-- width > 0)
  800140:	fc65                	bnez	s0,800138 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800142:	1a02                	slli	s4,s4,0x20
  800144:	00000797          	auipc	a5,0x0
  800148:	48c78793          	addi	a5,a5,1164 # 8005d0 <main+0xd8>
  80014c:	020a5a13          	srli	s4,s4,0x20
  800150:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800152:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800154:	000a4503          	lbu	a0,0(s4)
}
  800158:	70a2                	ld	ra,40(sp)
  80015a:	69a2                	ld	s3,8(sp)
  80015c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80015e:	85ca                	mv	a1,s2
  800160:	87a6                	mv	a5,s1
}
  800162:	6942                	ld	s2,16(sp)
  800164:	64e2                	ld	s1,24(sp)
  800166:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800168:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80016a:	03065633          	divu	a2,a2,a6
  80016e:	8722                	mv	a4,s0
  800170:	f9bff0ef          	jal	ra,80010a <printnum>
  800174:	b7f9                	j	800142 <printnum+0x38>

0000000000800176 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800176:	7119                	addi	sp,sp,-128
  800178:	f4a6                	sd	s1,104(sp)
  80017a:	f0ca                	sd	s2,96(sp)
  80017c:	ecce                	sd	s3,88(sp)
  80017e:	e8d2                	sd	s4,80(sp)
  800180:	e4d6                	sd	s5,72(sp)
  800182:	e0da                	sd	s6,64(sp)
  800184:	fc5e                	sd	s7,56(sp)
  800186:	f06a                	sd	s10,32(sp)
  800188:	fc86                	sd	ra,120(sp)
  80018a:	f8a2                	sd	s0,112(sp)
  80018c:	f862                	sd	s8,48(sp)
  80018e:	f466                	sd	s9,40(sp)
  800190:	ec6e                	sd	s11,24(sp)
  800192:	892a                	mv	s2,a0
  800194:	84ae                	mv	s1,a1
  800196:	8d32                	mv	s10,a2
  800198:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80019a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  80019e:	5b7d                	li	s6,-1
  8001a0:	00000a97          	auipc	s5,0x0
  8001a4:	464a8a93          	addi	s5,s5,1124 # 800604 <main+0x10c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8001a8:	00000b97          	auipc	s7,0x0
  8001ac:	678b8b93          	addi	s7,s7,1656 # 800820 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b0:	000d4503          	lbu	a0,0(s10)
  8001b4:	001d0413          	addi	s0,s10,1
  8001b8:	01350a63          	beq	a0,s3,8001cc <vprintfmt+0x56>
            if (ch == '\0') {
  8001bc:	c121                	beqz	a0,8001fc <vprintfmt+0x86>
            putch(ch, putdat);
  8001be:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001c0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001c2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001c4:	fff44503          	lbu	a0,-1(s0)
  8001c8:	ff351ae3          	bne	a0,s3,8001bc <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001cc:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001d0:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001d4:	4c81                	li	s9,0
  8001d6:	4881                	li	a7,0
        width = precision = -1;
  8001d8:	5c7d                	li	s8,-1
  8001da:	5dfd                	li	s11,-1
  8001dc:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001e0:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001e2:	fdd6059b          	addiw	a1,a2,-35
  8001e6:	0ff5f593          	zext.b	a1,a1
  8001ea:	00140d13          	addi	s10,s0,1
  8001ee:	04b56263          	bltu	a0,a1,800232 <vprintfmt+0xbc>
  8001f2:	058a                	slli	a1,a1,0x2
  8001f4:	95d6                	add	a1,a1,s5
  8001f6:	4194                	lw	a3,0(a1)
  8001f8:	96d6                	add	a3,a3,s5
  8001fa:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001fc:	70e6                	ld	ra,120(sp)
  8001fe:	7446                	ld	s0,112(sp)
  800200:	74a6                	ld	s1,104(sp)
  800202:	7906                	ld	s2,96(sp)
  800204:	69e6                	ld	s3,88(sp)
  800206:	6a46                	ld	s4,80(sp)
  800208:	6aa6                	ld	s5,72(sp)
  80020a:	6b06                	ld	s6,64(sp)
  80020c:	7be2                	ld	s7,56(sp)
  80020e:	7c42                	ld	s8,48(sp)
  800210:	7ca2                	ld	s9,40(sp)
  800212:	7d02                	ld	s10,32(sp)
  800214:	6de2                	ld	s11,24(sp)
  800216:	6109                	addi	sp,sp,128
  800218:	8082                	ret
            padc = '0';
  80021a:	87b2                	mv	a5,a2
            goto reswitch;
  80021c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800220:	846a                	mv	s0,s10
  800222:	00140d13          	addi	s10,s0,1
  800226:	fdd6059b          	addiw	a1,a2,-35
  80022a:	0ff5f593          	zext.b	a1,a1
  80022e:	fcb572e3          	bgeu	a0,a1,8001f2 <vprintfmt+0x7c>
            putch('%', putdat);
  800232:	85a6                	mv	a1,s1
  800234:	02500513          	li	a0,37
  800238:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  80023a:	fff44783          	lbu	a5,-1(s0)
  80023e:	8d22                	mv	s10,s0
  800240:	f73788e3          	beq	a5,s3,8001b0 <vprintfmt+0x3a>
  800244:	ffed4783          	lbu	a5,-2(s10)
  800248:	1d7d                	addi	s10,s10,-1
  80024a:	ff379de3          	bne	a5,s3,800244 <vprintfmt+0xce>
  80024e:	b78d                	j	8001b0 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  800250:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800254:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800258:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  80025a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  80025e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800262:	02d86463          	bltu	a6,a3,80028a <vprintfmt+0x114>
                ch = *fmt;
  800266:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  80026a:	002c169b          	slliw	a3,s8,0x2
  80026e:	0186873b          	addw	a4,a3,s8
  800272:	0017171b          	slliw	a4,a4,0x1
  800276:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  800278:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  80027c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80027e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800282:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800286:	fed870e3          	bgeu	a6,a3,800266 <vprintfmt+0xf0>
            if (width < 0)
  80028a:	f40ddce3          	bgez	s11,8001e2 <vprintfmt+0x6c>
                width = precision, precision = -1;
  80028e:	8de2                	mv	s11,s8
  800290:	5c7d                	li	s8,-1
  800292:	bf81                	j	8001e2 <vprintfmt+0x6c>
            if (width < 0)
  800294:	fffdc693          	not	a3,s11
  800298:	96fd                	srai	a3,a3,0x3f
  80029a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  80029e:	00144603          	lbu	a2,1(s0)
  8002a2:	2d81                	sext.w	s11,s11
  8002a4:	846a                	mv	s0,s10
            goto reswitch;
  8002a6:	bf35                	j	8001e2 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  8002a8:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002ac:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002b0:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002b2:	846a                	mv	s0,s10
            goto process_precision;
  8002b4:	bfd9                	j	80028a <vprintfmt+0x114>
    if (lflag >= 2) {
  8002b6:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002b8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002bc:	01174463          	blt	a4,a7,8002c4 <vprintfmt+0x14e>
    else if (lflag) {
  8002c0:	1a088e63          	beqz	a7,80047c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002c4:	000a3603          	ld	a2,0(s4)
  8002c8:	46c1                	li	a3,16
  8002ca:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002cc:	2781                	sext.w	a5,a5
  8002ce:	876e                	mv	a4,s11
  8002d0:	85a6                	mv	a1,s1
  8002d2:	854a                	mv	a0,s2
  8002d4:	e37ff0ef          	jal	ra,80010a <printnum>
            break;
  8002d8:	bde1                	j	8001b0 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002da:	000a2503          	lw	a0,0(s4)
  8002de:	85a6                	mv	a1,s1
  8002e0:	0a21                	addi	s4,s4,8
  8002e2:	9902                	jalr	s2
            break;
  8002e4:	b5f1                	j	8001b0 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002e6:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002e8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ec:	01174463          	blt	a4,a7,8002f4 <vprintfmt+0x17e>
    else if (lflag) {
  8002f0:	18088163          	beqz	a7,800472 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002f4:	000a3603          	ld	a2,0(s4)
  8002f8:	46a9                	li	a3,10
  8002fa:	8a2e                	mv	s4,a1
  8002fc:	bfc1                	j	8002cc <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002fe:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  800302:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800304:	846a                	mv	s0,s10
            goto reswitch;
  800306:	bdf1                	j	8001e2 <vprintfmt+0x6c>
            putch(ch, putdat);
  800308:	85a6                	mv	a1,s1
  80030a:	02500513          	li	a0,37
  80030e:	9902                	jalr	s2
            break;
  800310:	b545                	j	8001b0 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800312:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800316:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800318:	846a                	mv	s0,s10
            goto reswitch;
  80031a:	b5e1                	j	8001e2 <vprintfmt+0x6c>
    if (lflag >= 2) {
  80031c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80031e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800322:	01174463          	blt	a4,a7,80032a <vprintfmt+0x1b4>
    else if (lflag) {
  800326:	14088163          	beqz	a7,800468 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  80032a:	000a3603          	ld	a2,0(s4)
  80032e:	46a1                	li	a3,8
  800330:	8a2e                	mv	s4,a1
  800332:	bf69                	j	8002cc <vprintfmt+0x156>
            putch('0', putdat);
  800334:	03000513          	li	a0,48
  800338:	85a6                	mv	a1,s1
  80033a:	e03e                	sd	a5,0(sp)
  80033c:	9902                	jalr	s2
            putch('x', putdat);
  80033e:	85a6                	mv	a1,s1
  800340:	07800513          	li	a0,120
  800344:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800346:	0a21                	addi	s4,s4,8
            goto number;
  800348:	6782                	ld	a5,0(sp)
  80034a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80034c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  800350:	bfb5                	j	8002cc <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800352:	000a3403          	ld	s0,0(s4)
  800356:	008a0713          	addi	a4,s4,8
  80035a:	e03a                	sd	a4,0(sp)
  80035c:	14040263          	beqz	s0,8004a0 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  800360:	0fb05763          	blez	s11,80044e <vprintfmt+0x2d8>
  800364:	02d00693          	li	a3,45
  800368:	0cd79163          	bne	a5,a3,80042a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80036c:	00044783          	lbu	a5,0(s0)
  800370:	0007851b          	sext.w	a0,a5
  800374:	cf85                	beqz	a5,8003ac <vprintfmt+0x236>
  800376:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  80037a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80037e:	000c4563          	bltz	s8,800388 <vprintfmt+0x212>
  800382:	3c7d                	addiw	s8,s8,-1
  800384:	036c0263          	beq	s8,s6,8003a8 <vprintfmt+0x232>
                    putch('?', putdat);
  800388:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  80038a:	0e0c8e63          	beqz	s9,800486 <vprintfmt+0x310>
  80038e:	3781                	addiw	a5,a5,-32
  800390:	0ef47b63          	bgeu	s0,a5,800486 <vprintfmt+0x310>
                    putch('?', putdat);
  800394:	03f00513          	li	a0,63
  800398:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80039a:	000a4783          	lbu	a5,0(s4)
  80039e:	3dfd                	addiw	s11,s11,-1
  8003a0:	0a05                	addi	s4,s4,1
  8003a2:	0007851b          	sext.w	a0,a5
  8003a6:	ffe1                	bnez	a5,80037e <vprintfmt+0x208>
            for (; width > 0; width --) {
  8003a8:	01b05963          	blez	s11,8003ba <vprintfmt+0x244>
  8003ac:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  8003ae:	85a6                	mv	a1,s1
  8003b0:	02000513          	li	a0,32
  8003b4:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003b6:	fe0d9be3          	bnez	s11,8003ac <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003ba:	6a02                	ld	s4,0(sp)
  8003bc:	bbd5                	j	8001b0 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003be:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003c0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003c4:	01174463          	blt	a4,a7,8003cc <vprintfmt+0x256>
    else if (lflag) {
  8003c8:	08088d63          	beqz	a7,800462 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003cc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003d0:	0a044d63          	bltz	s0,80048a <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003d4:	8622                	mv	a2,s0
  8003d6:	8a66                	mv	s4,s9
  8003d8:	46a9                	li	a3,10
  8003da:	bdcd                	j	8002cc <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003dc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003e0:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003e2:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003e4:	41f7d69b          	sraiw	a3,a5,0x1f
  8003e8:	8fb5                	xor	a5,a5,a3
  8003ea:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003ee:	02d74163          	blt	a4,a3,800410 <vprintfmt+0x29a>
  8003f2:	00369793          	slli	a5,a3,0x3
  8003f6:	97de                	add	a5,a5,s7
  8003f8:	639c                	ld	a5,0(a5)
  8003fa:	cb99                	beqz	a5,800410 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003fc:	86be                	mv	a3,a5
  8003fe:	00000617          	auipc	a2,0x0
  800402:	20260613          	addi	a2,a2,514 # 800600 <main+0x108>
  800406:	85a6                	mv	a1,s1
  800408:	854a                	mv	a0,s2
  80040a:	0ce000ef          	jal	ra,8004d8 <printfmt>
  80040e:	b34d                	j	8001b0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800410:	00000617          	auipc	a2,0x0
  800414:	1e060613          	addi	a2,a2,480 # 8005f0 <main+0xf8>
  800418:	85a6                	mv	a1,s1
  80041a:	854a                	mv	a0,s2
  80041c:	0bc000ef          	jal	ra,8004d8 <printfmt>
  800420:	bb41                	j	8001b0 <vprintfmt+0x3a>
                p = "(null)";
  800422:	00000417          	auipc	s0,0x0
  800426:	1c640413          	addi	s0,s0,454 # 8005e8 <main+0xf0>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80042a:	85e2                	mv	a1,s8
  80042c:	8522                	mv	a0,s0
  80042e:	e43e                	sd	a5,8(sp)
  800430:	cbfff0ef          	jal	ra,8000ee <strnlen>
  800434:	40ad8dbb          	subw	s11,s11,a0
  800438:	01b05b63          	blez	s11,80044e <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80043c:	67a2                	ld	a5,8(sp)
  80043e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800442:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800444:	85a6                	mv	a1,s1
  800446:	8552                	mv	a0,s4
  800448:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  80044a:	fe0d9ce3          	bnez	s11,800442 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80044e:	00044783          	lbu	a5,0(s0)
  800452:	00140a13          	addi	s4,s0,1
  800456:	0007851b          	sext.w	a0,a5
  80045a:	d3a5                	beqz	a5,8003ba <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  80045c:	05e00413          	li	s0,94
  800460:	bf39                	j	80037e <vprintfmt+0x208>
        return va_arg(*ap, int);
  800462:	000a2403          	lw	s0,0(s4)
  800466:	b7ad                	j	8003d0 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  800468:	000a6603          	lwu	a2,0(s4)
  80046c:	46a1                	li	a3,8
  80046e:	8a2e                	mv	s4,a1
  800470:	bdb1                	j	8002cc <vprintfmt+0x156>
  800472:	000a6603          	lwu	a2,0(s4)
  800476:	46a9                	li	a3,10
  800478:	8a2e                	mv	s4,a1
  80047a:	bd89                	j	8002cc <vprintfmt+0x156>
  80047c:	000a6603          	lwu	a2,0(s4)
  800480:	46c1                	li	a3,16
  800482:	8a2e                	mv	s4,a1
  800484:	b5a1                	j	8002cc <vprintfmt+0x156>
                    putch(ch, putdat);
  800486:	9902                	jalr	s2
  800488:	bf09                	j	80039a <vprintfmt+0x224>
                putch('-', putdat);
  80048a:	85a6                	mv	a1,s1
  80048c:	02d00513          	li	a0,45
  800490:	e03e                	sd	a5,0(sp)
  800492:	9902                	jalr	s2
                num = -(long long)num;
  800494:	6782                	ld	a5,0(sp)
  800496:	8a66                	mv	s4,s9
  800498:	40800633          	neg	a2,s0
  80049c:	46a9                	li	a3,10
  80049e:	b53d                	j	8002cc <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  8004a0:	03b05163          	blez	s11,8004c2 <vprintfmt+0x34c>
  8004a4:	02d00693          	li	a3,45
  8004a8:	f6d79de3          	bne	a5,a3,800422 <vprintfmt+0x2ac>
                p = "(null)";
  8004ac:	00000417          	auipc	s0,0x0
  8004b0:	13c40413          	addi	s0,s0,316 # 8005e8 <main+0xf0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004b4:	02800793          	li	a5,40
  8004b8:	02800513          	li	a0,40
  8004bc:	00140a13          	addi	s4,s0,1
  8004c0:	bd6d                	j	80037a <vprintfmt+0x204>
  8004c2:	00000a17          	auipc	s4,0x0
  8004c6:	127a0a13          	addi	s4,s4,295 # 8005e9 <main+0xf1>
  8004ca:	02800513          	li	a0,40
  8004ce:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004d2:	05e00413          	li	s0,94
  8004d6:	b565                	j	80037e <vprintfmt+0x208>

00000000008004d8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004d8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004da:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004de:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004e0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004e2:	ec06                	sd	ra,24(sp)
  8004e4:	f83a                	sd	a4,48(sp)
  8004e6:	fc3e                	sd	a5,56(sp)
  8004e8:	e0c2                	sd	a6,64(sp)
  8004ea:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004ec:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004ee:	c89ff0ef          	jal	ra,800176 <vprintfmt>
}
  8004f2:	60e2                	ld	ra,24(sp)
  8004f4:	6161                	addi	sp,sp,80
  8004f6:	8082                	ret

00000000008004f8 <main>:
#include <string.h>
#include <stdlib.h>

static char buf[2 * 4096];

int main(void) {
  8004f8:	7179                	addi	sp,sp,-48
  8004fa:	f022                	sd	s0,32(sp)
  8004fc:	ec26                	sd	s1,24(sp)
  8004fe:	e84a                	sd	s2,16(sp)
  800500:	e44e                	sd	s3,8(sp)
    buf[0] = 'A';
  800502:	00001497          	auipc	s1,0x1
  800506:	afe48493          	addi	s1,s1,-1282 # 801000 <buf>
  80050a:	04100913          	li	s2,65
    buf[4096] = 'X';
  80050e:	00002417          	auipc	s0,0x2
  800512:	af240413          	addi	s0,s0,-1294 # 802000 <buf+0x1000>
  800516:	05800993          	li	s3,88
int main(void) {
  80051a:	f406                	sd	ra,40(sp)
    buf[0] = 'A';
  80051c:	01248023          	sb	s2,0(s1)
    buf[4096] = 'X';
  800520:	01340023          	sb	s3,0(s0)

    int pid = fork();
  800524:	b65ff0ef          	jal	ra,800088 <fork>
    if (pid < 0) {
  800528:	06054c63          	bltz	a0,8005a0 <main+0xa8>
        cprintf("fork failed\n");
        exit(-1);
    }

    if (pid == 0) {
  80052c:	c529                	beqz	a0,800576 <main+0x7e>
        cprintf("child wrote pages: %c %c\n", buf[0], buf[4096]);
        exit(0);
    }

    // parent waits
    waitpid(pid, NULL);
  80052e:	4581                	li	a1,0
  800530:	b5bff0ef          	jal	ra,80008a <waitpid>

    // parent should still see original contents
    if (buf[0] != 'A' || buf[4096] != 'X') {
  800534:	0004c583          	lbu	a1,0(s1)
  800538:	03259463          	bne	a1,s2,800560 <main+0x68>
  80053c:	00044783          	lbu	a5,0(s0)
  800540:	03379063          	bne	a5,s3,800560 <main+0x68>
        cprintf("COW failed: parent sees %c %c\n", buf[0], buf[4096]);
        exit(-1);
    }

    cprintf("cow pass.\n");
  800544:	00000517          	auipc	a0,0x0
  800548:	3f450513          	addi	a0,a0,1012 # 800938 <error_string+0x118>
  80054c:	b61ff0ef          	jal	ra,8000ac <cprintf>
    return 0;
}
  800550:	70a2                	ld	ra,40(sp)
  800552:	7402                	ld	s0,32(sp)
  800554:	64e2                	ld	s1,24(sp)
  800556:	6942                	ld	s2,16(sp)
  800558:	69a2                	ld	s3,8(sp)
  80055a:	4501                	li	a0,0
  80055c:	6145                	addi	sp,sp,48
  80055e:	8082                	ret
        cprintf("COW failed: parent sees %c %c\n", buf[0], buf[4096]);
  800560:	00044603          	lbu	a2,0(s0)
  800564:	00000517          	auipc	a0,0x0
  800568:	3b450513          	addi	a0,a0,948 # 800918 <error_string+0xf8>
  80056c:	b41ff0ef          	jal	ra,8000ac <cprintf>
        exit(-1);
  800570:	557d                	li	a0,-1
  800572:	b01ff0ef          	jal	ra,800072 <exit>
        buf[0] = 'B';
  800576:	04200793          	li	a5,66
  80057a:	00f48023          	sb	a5,0(s1)
        cprintf("child wrote pages: %c %c\n", buf[0], buf[4096]);
  80057e:	05900613          	li	a2,89
        buf[4096] = 'Y';
  800582:	05900793          	li	a5,89
        cprintf("child wrote pages: %c %c\n", buf[0], buf[4096]);
  800586:	04200593          	li	a1,66
  80058a:	00000517          	auipc	a0,0x0
  80058e:	36e50513          	addi	a0,a0,878 # 8008f8 <error_string+0xd8>
        buf[4096] = 'Y';
  800592:	00f40023          	sb	a5,0(s0)
        cprintf("child wrote pages: %c %c\n", buf[0], buf[4096]);
  800596:	b17ff0ef          	jal	ra,8000ac <cprintf>
        exit(0);
  80059a:	4501                	li	a0,0
  80059c:	ad7ff0ef          	jal	ra,800072 <exit>
        cprintf("fork failed\n");
  8005a0:	00000517          	auipc	a0,0x0
  8005a4:	34850513          	addi	a0,a0,840 # 8008e8 <error_string+0xc8>
  8005a8:	b05ff0ef          	jal	ra,8000ac <cprintf>
        exit(-1);
  8005ac:	557d                	li	a0,-1
  8005ae:	ac5ff0ef          	jal	ra,800072 <exit>
