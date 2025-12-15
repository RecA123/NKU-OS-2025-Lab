
obj/__user_dirtycow.out:     file format elf64-littleriscv


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

0000000000800060 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  800060:	4549                	li	a0,18
  800062:	bf7d                	j	800020 <syscall>

0000000000800064 <sys_putc>:
}

int
sys_putc(int64_t c) {
  800064:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800066:	4579                	li	a0,30
  800068:	bf65                	j	800020 <syscall>

000000000080006a <sys_mempoke>:
    return syscall(SYS_pgdir);
}
// sys_mempoke - 用户态封装：调用 Dirty COW 的“内核代写”系统调用
//   参数语义与内核一致，这里只是把指针转换成 uintptr_t 后直接发起 syscall
int
sys_mempoke(uintptr_t dst, uintptr_t src, size_t len) {
  80006a:	86b2                	mv	a3,a2
    return syscall(SYS_mempoke, dst, src, len);
  80006c:	862e                	mv	a2,a1
  80006e:	85aa                	mv	a1,a0
  800070:	02000513          	li	a0,32
  800074:	b775                	j	800020 <syscall>

0000000000800076 <sys_dirtycowctl>:
}

// sys_dirtycowctl - 用户态封装：切换/查询 Dirty COW 演示模式
//   mode = -1/0/1 的含义同内核，返回值也是当前模式值
int
sys_dirtycowctl(int mode) {
  800076:	85aa                	mv	a1,a0
    return syscall(SYS_dirtycowctl, mode);
  800078:	02100513          	li	a0,33
  80007c:	b755                	j	800020 <syscall>

000000000080007e <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80007e:	1141                	addi	sp,sp,-16
  800080:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800082:	fd9ff0ef          	jal	ra,80005a <sys_exit>
    cprintf("BUG: exit failed.\n");
  800086:	00000517          	auipc	a0,0x0
  80008a:	55250513          	addi	a0,a0,1362 # 8005d8 <main+0x7a>
  80008e:	02c000ef          	jal	ra,8000ba <cprintf>
    while (1);
  800092:	a001                	j	800092 <exit+0x14>

0000000000800094 <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  800094:	b7f1                	j	800060 <sys_getpid>

0000000000800096 <mempoke>:
//   参数 src：用户提供的缓冲区（将先复制到内核，再由内核写回 dst）
//   参数 len：写入长度
//   返回值：直接返回 sys_mempoke 的执行结果（0 表示成功，负值为错误码）
int
mempoke(void *dst, const void *src, size_t len) {
    return sys_mempoke((uintptr_t)dst, (uintptr_t)src, len);
  800096:	bfd1                	j	80006a <sys_mempoke>

0000000000800098 <dirtycowctl>:
// dirtycowctl - 控制 Dirty COW 演示模式
//   mode = -1：只查询当前模式；0：切到修复模式；1：切到漏洞模式
//   返回值：sys_dirtycowctl 的返回值，也就是内核当前记录的模式（0=fix,1=bug）
int
dirtycowctl(int mode) {
    return sys_dirtycowctl(mode);
  800098:	bff9                	j	800076 <sys_dirtycowctl>

000000000080009a <_start>:
.text
.globl _start
_start:
    # call user-program function
    call umain
  80009a:	056000ef          	jal	ra,8000f0 <umain>
1:  j 1b
  80009e:	a001                	j	80009e <_start+0x4>

00000000008000a0 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  8000a0:	1141                	addi	sp,sp,-16
  8000a2:	e022                	sd	s0,0(sp)
  8000a4:	e406                	sd	ra,8(sp)
  8000a6:	842e                	mv	s0,a1
    sys_putc(c);
  8000a8:	fbdff0ef          	jal	ra,800064 <sys_putc>
    (*cnt) ++;
  8000ac:	401c                	lw	a5,0(s0)
}
  8000ae:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  8000b0:	2785                	addiw	a5,a5,1
  8000b2:	c01c                	sw	a5,0(s0)
}
  8000b4:	6402                	ld	s0,0(sp)
  8000b6:	0141                	addi	sp,sp,16
  8000b8:	8082                	ret

00000000008000ba <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000ba:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000bc:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000c0:	8e2a                	mv	t3,a0
  8000c2:	f42e                	sd	a1,40(sp)
  8000c4:	f832                	sd	a2,48(sp)
  8000c6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000c8:	00000517          	auipc	a0,0x0
  8000cc:	fd850513          	addi	a0,a0,-40 # 8000a0 <cputch>
  8000d0:	004c                	addi	a1,sp,4
  8000d2:	869a                	mv	a3,t1
  8000d4:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  8000d6:	ec06                	sd	ra,24(sp)
  8000d8:	e0ba                	sd	a4,64(sp)
  8000da:	e4be                	sd	a5,72(sp)
  8000dc:	e8c2                	sd	a6,80(sp)
  8000de:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  8000e0:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  8000e2:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000e4:	0a0000ef          	jal	ra,800184 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000e8:	60e2                	ld	ra,24(sp)
  8000ea:	4512                	lw	a0,4(sp)
  8000ec:	6125                	addi	sp,sp,96
  8000ee:	8082                	ret

00000000008000f0 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000f0:	1141                	addi	sp,sp,-16
  8000f2:	e406                	sd	ra,8(sp)
    int ret = main();
  8000f4:	46a000ef          	jal	ra,80055e <main>
    exit(ret);
  8000f8:	f87ff0ef          	jal	ra,80007e <exit>

00000000008000fc <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8000fc:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8000fe:	e589                	bnez	a1,800108 <strnlen+0xc>
  800100:	a811                	j	800114 <strnlen+0x18>
        cnt ++;
  800102:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800104:	00f58863          	beq	a1,a5,800114 <strnlen+0x18>
  800108:	00f50733          	add	a4,a0,a5
  80010c:	00074703          	lbu	a4,0(a4)
  800110:	fb6d                	bnez	a4,800102 <strnlen+0x6>
  800112:	85be                	mv	a1,a5
    }
    return cnt;
}
  800114:	852e                	mv	a0,a1
  800116:	8082                	ret

0000000000800118 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800118:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80011c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  80011e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800122:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800124:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  800128:	f022                	sd	s0,32(sp)
  80012a:	ec26                	sd	s1,24(sp)
  80012c:	e84a                	sd	s2,16(sp)
  80012e:	f406                	sd	ra,40(sp)
  800130:	e44e                	sd	s3,8(sp)
  800132:	84aa                	mv	s1,a0
  800134:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800136:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  80013a:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80013c:	03067e63          	bgeu	a2,a6,800178 <printnum+0x60>
  800140:	89be                	mv	s3,a5
        while (-- width > 0)
  800142:	00805763          	blez	s0,800150 <printnum+0x38>
  800146:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800148:	85ca                	mv	a1,s2
  80014a:	854e                	mv	a0,s3
  80014c:	9482                	jalr	s1
        while (-- width > 0)
  80014e:	fc65                	bnez	s0,800146 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800150:	1a02                	slli	s4,s4,0x20
  800152:	00000797          	auipc	a5,0x0
  800156:	49e78793          	addi	a5,a5,1182 # 8005f0 <main+0x92>
  80015a:	020a5a13          	srli	s4,s4,0x20
  80015e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800160:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800162:	000a4503          	lbu	a0,0(s4)
}
  800166:	70a2                	ld	ra,40(sp)
  800168:	69a2                	ld	s3,8(sp)
  80016a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80016c:	85ca                	mv	a1,s2
  80016e:	87a6                	mv	a5,s1
}
  800170:	6942                	ld	s2,16(sp)
  800172:	64e2                	ld	s1,24(sp)
  800174:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800176:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  800178:	03065633          	divu	a2,a2,a6
  80017c:	8722                	mv	a4,s0
  80017e:	f9bff0ef          	jal	ra,800118 <printnum>
  800182:	b7f9                	j	800150 <printnum+0x38>

0000000000800184 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800184:	7119                	addi	sp,sp,-128
  800186:	f4a6                	sd	s1,104(sp)
  800188:	f0ca                	sd	s2,96(sp)
  80018a:	ecce                	sd	s3,88(sp)
  80018c:	e8d2                	sd	s4,80(sp)
  80018e:	e4d6                	sd	s5,72(sp)
  800190:	e0da                	sd	s6,64(sp)
  800192:	fc5e                	sd	s7,56(sp)
  800194:	f06a                	sd	s10,32(sp)
  800196:	fc86                	sd	ra,120(sp)
  800198:	f8a2                	sd	s0,112(sp)
  80019a:	f862                	sd	s8,48(sp)
  80019c:	f466                	sd	s9,40(sp)
  80019e:	ec6e                	sd	s11,24(sp)
  8001a0:	892a                	mv	s2,a0
  8001a2:	84ae                	mv	s1,a1
  8001a4:	8d32                	mv	s10,a2
  8001a6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001a8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  8001ac:	5b7d                	li	s6,-1
  8001ae:	00000a97          	auipc	s5,0x0
  8001b2:	476a8a93          	addi	s5,s5,1142 # 800624 <main+0xc6>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8001b6:	00000b97          	auipc	s7,0x0
  8001ba:	68ab8b93          	addi	s7,s7,1674 # 800840 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001be:	000d4503          	lbu	a0,0(s10)
  8001c2:	001d0413          	addi	s0,s10,1
  8001c6:	01350a63          	beq	a0,s3,8001da <vprintfmt+0x56>
            if (ch == '\0') {
  8001ca:	c121                	beqz	a0,80020a <vprintfmt+0x86>
            putch(ch, putdat);
  8001cc:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001ce:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001d0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001d2:	fff44503          	lbu	a0,-1(s0)
  8001d6:	ff351ae3          	bne	a0,s3,8001ca <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001da:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001de:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001e2:	4c81                	li	s9,0
  8001e4:	4881                	li	a7,0
        width = precision = -1;
  8001e6:	5c7d                	li	s8,-1
  8001e8:	5dfd                	li	s11,-1
  8001ea:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001ee:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001f0:	fdd6059b          	addiw	a1,a2,-35
  8001f4:	0ff5f593          	zext.b	a1,a1
  8001f8:	00140d13          	addi	s10,s0,1
  8001fc:	04b56263          	bltu	a0,a1,800240 <vprintfmt+0xbc>
  800200:	058a                	slli	a1,a1,0x2
  800202:	95d6                	add	a1,a1,s5
  800204:	4194                	lw	a3,0(a1)
  800206:	96d6                	add	a3,a3,s5
  800208:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  80020a:	70e6                	ld	ra,120(sp)
  80020c:	7446                	ld	s0,112(sp)
  80020e:	74a6                	ld	s1,104(sp)
  800210:	7906                	ld	s2,96(sp)
  800212:	69e6                	ld	s3,88(sp)
  800214:	6a46                	ld	s4,80(sp)
  800216:	6aa6                	ld	s5,72(sp)
  800218:	6b06                	ld	s6,64(sp)
  80021a:	7be2                	ld	s7,56(sp)
  80021c:	7c42                	ld	s8,48(sp)
  80021e:	7ca2                	ld	s9,40(sp)
  800220:	7d02                	ld	s10,32(sp)
  800222:	6de2                	ld	s11,24(sp)
  800224:	6109                	addi	sp,sp,128
  800226:	8082                	ret
            padc = '0';
  800228:	87b2                	mv	a5,a2
            goto reswitch;
  80022a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80022e:	846a                	mv	s0,s10
  800230:	00140d13          	addi	s10,s0,1
  800234:	fdd6059b          	addiw	a1,a2,-35
  800238:	0ff5f593          	zext.b	a1,a1
  80023c:	fcb572e3          	bgeu	a0,a1,800200 <vprintfmt+0x7c>
            putch('%', putdat);
  800240:	85a6                	mv	a1,s1
  800242:	02500513          	li	a0,37
  800246:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800248:	fff44783          	lbu	a5,-1(s0)
  80024c:	8d22                	mv	s10,s0
  80024e:	f73788e3          	beq	a5,s3,8001be <vprintfmt+0x3a>
  800252:	ffed4783          	lbu	a5,-2(s10)
  800256:	1d7d                	addi	s10,s10,-1
  800258:	ff379de3          	bne	a5,s3,800252 <vprintfmt+0xce>
  80025c:	b78d                	j	8001be <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  80025e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800262:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800266:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  800268:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  80026c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800270:	02d86463          	bltu	a6,a3,800298 <vprintfmt+0x114>
                ch = *fmt;
  800274:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  800278:	002c169b          	slliw	a3,s8,0x2
  80027c:	0186873b          	addw	a4,a3,s8
  800280:	0017171b          	slliw	a4,a4,0x1
  800284:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  800286:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  80028a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80028c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800290:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800294:	fed870e3          	bgeu	a6,a3,800274 <vprintfmt+0xf0>
            if (width < 0)
  800298:	f40ddce3          	bgez	s11,8001f0 <vprintfmt+0x6c>
                width = precision, precision = -1;
  80029c:	8de2                	mv	s11,s8
  80029e:	5c7d                	li	s8,-1
  8002a0:	bf81                	j	8001f0 <vprintfmt+0x6c>
            if (width < 0)
  8002a2:	fffdc693          	not	a3,s11
  8002a6:	96fd                	srai	a3,a3,0x3f
  8002a8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  8002ac:	00144603          	lbu	a2,1(s0)
  8002b0:	2d81                	sext.w	s11,s11
  8002b2:	846a                	mv	s0,s10
            goto reswitch;
  8002b4:	bf35                	j	8001f0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  8002b6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002ba:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002be:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002c0:	846a                	mv	s0,s10
            goto process_precision;
  8002c2:	bfd9                	j	800298 <vprintfmt+0x114>
    if (lflag >= 2) {
  8002c4:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002c6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ca:	01174463          	blt	a4,a7,8002d2 <vprintfmt+0x14e>
    else if (lflag) {
  8002ce:	1a088e63          	beqz	a7,80048a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002d2:	000a3603          	ld	a2,0(s4)
  8002d6:	46c1                	li	a3,16
  8002d8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002da:	2781                	sext.w	a5,a5
  8002dc:	876e                	mv	a4,s11
  8002de:	85a6                	mv	a1,s1
  8002e0:	854a                	mv	a0,s2
  8002e2:	e37ff0ef          	jal	ra,800118 <printnum>
            break;
  8002e6:	bde1                	j	8001be <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002e8:	000a2503          	lw	a0,0(s4)
  8002ec:	85a6                	mv	a1,s1
  8002ee:	0a21                	addi	s4,s4,8
  8002f0:	9902                	jalr	s2
            break;
  8002f2:	b5f1                	j	8001be <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002f4:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002f6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002fa:	01174463          	blt	a4,a7,800302 <vprintfmt+0x17e>
    else if (lflag) {
  8002fe:	18088163          	beqz	a7,800480 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  800302:	000a3603          	ld	a2,0(s4)
  800306:	46a9                	li	a3,10
  800308:	8a2e                	mv	s4,a1
  80030a:	bfc1                	j	8002da <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  80030c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  800310:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800312:	846a                	mv	s0,s10
            goto reswitch;
  800314:	bdf1                	j	8001f0 <vprintfmt+0x6c>
            putch(ch, putdat);
  800316:	85a6                	mv	a1,s1
  800318:	02500513          	li	a0,37
  80031c:	9902                	jalr	s2
            break;
  80031e:	b545                	j	8001be <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800320:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800324:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800326:	846a                	mv	s0,s10
            goto reswitch;
  800328:	b5e1                	j	8001f0 <vprintfmt+0x6c>
    if (lflag >= 2) {
  80032a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80032c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800330:	01174463          	blt	a4,a7,800338 <vprintfmt+0x1b4>
    else if (lflag) {
  800334:	14088163          	beqz	a7,800476 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800338:	000a3603          	ld	a2,0(s4)
  80033c:	46a1                	li	a3,8
  80033e:	8a2e                	mv	s4,a1
  800340:	bf69                	j	8002da <vprintfmt+0x156>
            putch('0', putdat);
  800342:	03000513          	li	a0,48
  800346:	85a6                	mv	a1,s1
  800348:	e03e                	sd	a5,0(sp)
  80034a:	9902                	jalr	s2
            putch('x', putdat);
  80034c:	85a6                	mv	a1,s1
  80034e:	07800513          	li	a0,120
  800352:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800354:	0a21                	addi	s4,s4,8
            goto number;
  800356:	6782                	ld	a5,0(sp)
  800358:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80035a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  80035e:	bfb5                	j	8002da <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800360:	000a3403          	ld	s0,0(s4)
  800364:	008a0713          	addi	a4,s4,8
  800368:	e03a                	sd	a4,0(sp)
  80036a:	14040263          	beqz	s0,8004ae <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  80036e:	0fb05763          	blez	s11,80045c <vprintfmt+0x2d8>
  800372:	02d00693          	li	a3,45
  800376:	0cd79163          	bne	a5,a3,800438 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80037a:	00044783          	lbu	a5,0(s0)
  80037e:	0007851b          	sext.w	a0,a5
  800382:	cf85                	beqz	a5,8003ba <vprintfmt+0x236>
  800384:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  800388:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80038c:	000c4563          	bltz	s8,800396 <vprintfmt+0x212>
  800390:	3c7d                	addiw	s8,s8,-1
  800392:	036c0263          	beq	s8,s6,8003b6 <vprintfmt+0x232>
                    putch('?', putdat);
  800396:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  800398:	0e0c8e63          	beqz	s9,800494 <vprintfmt+0x310>
  80039c:	3781                	addiw	a5,a5,-32
  80039e:	0ef47b63          	bgeu	s0,a5,800494 <vprintfmt+0x310>
                    putch('?', putdat);
  8003a2:	03f00513          	li	a0,63
  8003a6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003a8:	000a4783          	lbu	a5,0(s4)
  8003ac:	3dfd                	addiw	s11,s11,-1
  8003ae:	0a05                	addi	s4,s4,1
  8003b0:	0007851b          	sext.w	a0,a5
  8003b4:	ffe1                	bnez	a5,80038c <vprintfmt+0x208>
            for (; width > 0; width --) {
  8003b6:	01b05963          	blez	s11,8003c8 <vprintfmt+0x244>
  8003ba:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  8003bc:	85a6                	mv	a1,s1
  8003be:	02000513          	li	a0,32
  8003c2:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003c4:	fe0d9be3          	bnez	s11,8003ba <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003c8:	6a02                	ld	s4,0(sp)
  8003ca:	bbd5                	j	8001be <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003cc:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003ce:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003d2:	01174463          	blt	a4,a7,8003da <vprintfmt+0x256>
    else if (lflag) {
  8003d6:	08088d63          	beqz	a7,800470 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003da:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003de:	0a044d63          	bltz	s0,800498 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003e2:	8622                	mv	a2,s0
  8003e4:	8a66                	mv	s4,s9
  8003e6:	46a9                	li	a3,10
  8003e8:	bdcd                	j	8002da <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003ea:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003ee:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003f0:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003f2:	41f7d69b          	sraiw	a3,a5,0x1f
  8003f6:	8fb5                	xor	a5,a5,a3
  8003f8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003fc:	02d74163          	blt	a4,a3,80041e <vprintfmt+0x29a>
  800400:	00369793          	slli	a5,a3,0x3
  800404:	97de                	add	a5,a5,s7
  800406:	639c                	ld	a5,0(a5)
  800408:	cb99                	beqz	a5,80041e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  80040a:	86be                	mv	a3,a5
  80040c:	00000617          	auipc	a2,0x0
  800410:	21460613          	addi	a2,a2,532 # 800620 <main+0xc2>
  800414:	85a6                	mv	a1,s1
  800416:	854a                	mv	a0,s2
  800418:	0ce000ef          	jal	ra,8004e6 <printfmt>
  80041c:	b34d                	j	8001be <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  80041e:	00000617          	auipc	a2,0x0
  800422:	1f260613          	addi	a2,a2,498 # 800610 <main+0xb2>
  800426:	85a6                	mv	a1,s1
  800428:	854a                	mv	a0,s2
  80042a:	0bc000ef          	jal	ra,8004e6 <printfmt>
  80042e:	bb41                	j	8001be <vprintfmt+0x3a>
                p = "(null)";
  800430:	00000417          	auipc	s0,0x0
  800434:	1d840413          	addi	s0,s0,472 # 800608 <main+0xaa>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800438:	85e2                	mv	a1,s8
  80043a:	8522                	mv	a0,s0
  80043c:	e43e                	sd	a5,8(sp)
  80043e:	cbfff0ef          	jal	ra,8000fc <strnlen>
  800442:	40ad8dbb          	subw	s11,s11,a0
  800446:	01b05b63          	blez	s11,80045c <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80044a:	67a2                	ld	a5,8(sp)
  80044c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800450:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800452:	85a6                	mv	a1,s1
  800454:	8552                	mv	a0,s4
  800456:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  800458:	fe0d9ce3          	bnez	s11,800450 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80045c:	00044783          	lbu	a5,0(s0)
  800460:	00140a13          	addi	s4,s0,1
  800464:	0007851b          	sext.w	a0,a5
  800468:	d3a5                	beqz	a5,8003c8 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  80046a:	05e00413          	li	s0,94
  80046e:	bf39                	j	80038c <vprintfmt+0x208>
        return va_arg(*ap, int);
  800470:	000a2403          	lw	s0,0(s4)
  800474:	b7ad                	j	8003de <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  800476:	000a6603          	lwu	a2,0(s4)
  80047a:	46a1                	li	a3,8
  80047c:	8a2e                	mv	s4,a1
  80047e:	bdb1                	j	8002da <vprintfmt+0x156>
  800480:	000a6603          	lwu	a2,0(s4)
  800484:	46a9                	li	a3,10
  800486:	8a2e                	mv	s4,a1
  800488:	bd89                	j	8002da <vprintfmt+0x156>
  80048a:	000a6603          	lwu	a2,0(s4)
  80048e:	46c1                	li	a3,16
  800490:	8a2e                	mv	s4,a1
  800492:	b5a1                	j	8002da <vprintfmt+0x156>
                    putch(ch, putdat);
  800494:	9902                	jalr	s2
  800496:	bf09                	j	8003a8 <vprintfmt+0x224>
                putch('-', putdat);
  800498:	85a6                	mv	a1,s1
  80049a:	02d00513          	li	a0,45
  80049e:	e03e                	sd	a5,0(sp)
  8004a0:	9902                	jalr	s2
                num = -(long long)num;
  8004a2:	6782                	ld	a5,0(sp)
  8004a4:	8a66                	mv	s4,s9
  8004a6:	40800633          	neg	a2,s0
  8004aa:	46a9                	li	a3,10
  8004ac:	b53d                	j	8002da <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  8004ae:	03b05163          	blez	s11,8004d0 <vprintfmt+0x34c>
  8004b2:	02d00693          	li	a3,45
  8004b6:	f6d79de3          	bne	a5,a3,800430 <vprintfmt+0x2ac>
                p = "(null)";
  8004ba:	00000417          	auipc	s0,0x0
  8004be:	14e40413          	addi	s0,s0,334 # 800608 <main+0xaa>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004c2:	02800793          	li	a5,40
  8004c6:	02800513          	li	a0,40
  8004ca:	00140a13          	addi	s4,s0,1
  8004ce:	bd6d                	j	800388 <vprintfmt+0x204>
  8004d0:	00000a17          	auipc	s4,0x0
  8004d4:	139a0a13          	addi	s4,s4,313 # 800609 <main+0xab>
  8004d8:	02800513          	li	a0,40
  8004dc:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004e0:	05e00413          	li	s0,94
  8004e4:	b565                	j	80038c <vprintfmt+0x208>

00000000008004e6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004e6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004e8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004ec:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004ee:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004f0:	ec06                	sd	ra,24(sp)
  8004f2:	f83a                	sd	a4,48(sp)
  8004f4:	fc3e                	sd	a5,56(sp)
  8004f6:	e0c2                	sd	a6,64(sp)
  8004f8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004fa:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004fc:	c89ff0ef          	jal	ra,800184 <vprintfmt>
}
  800500:	60e2                	ld	ra,24(sp)
  800502:	6161                	addi	sp,sp,80
  800504:	8082                	ret

0000000000800506 <try_patch>:
static const char payload[] = "DIRTYCOW DEMO: OWNED BY USER!";

// try_patch - 封装一次 mempoke 调用并打印结果
//   tag 用来区分当前处于 fix 还是 bug 测试阶段
static void try_patch(const char *tag)
{
  800506:	1141                	addi	sp,sp,-16
  800508:	e022                	sd	s0,0(sp)
    int ret = mempoke((void *)victim, payload, sizeof(payload) - 1);
  80050a:	4675                	li	a2,29
{
  80050c:	842a                	mv	s0,a0
    int ret = mempoke((void *)victim, payload, sizeof(payload) - 1);
  80050e:	00000597          	auipc	a1,0x0
  800512:	4ea58593          	addi	a1,a1,1258 # 8009f8 <payload>
  800516:	00000517          	auipc	a0,0x0
  80051a:	50250513          	addi	a0,a0,1282 # 800a18 <victim>
{
  80051e:	e406                	sd	ra,8(sp)
    int ret = mempoke((void *)victim, payload, sizeof(payload) - 1);
  800520:	b77ff0ef          	jal	ra,800096 <mempoke>
    if (ret < 0)
  800524:	00054f63          	bltz	a0,800542 <try_patch+0x3c>
        cprintf("[dirtycow][%s] blocked (ret=%d), victim -> \"%s\"\n", tag, ret, victim);
    }
    else
    {
        // ret==0 表示写入成功（bug 模式），只读字符串被篡改
        cprintf("[dirtycow][%s] succeeded, victim -> \"%s\"\n", tag, victim);
  800528:	85a2                	mv	a1,s0
    }
}
  80052a:	6402                	ld	s0,0(sp)
  80052c:	60a2                	ld	ra,8(sp)
        cprintf("[dirtycow][%s] succeeded, victim -> \"%s\"\n", tag, victim);
  80052e:	00000617          	auipc	a2,0x0
  800532:	4ea60613          	addi	a2,a2,1258 # 800a18 <victim>
  800536:	00000517          	auipc	a0,0x0
  80053a:	40a50513          	addi	a0,a0,1034 # 800940 <error_string+0x100>
}
  80053e:	0141                	addi	sp,sp,16
        cprintf("[dirtycow][%s] succeeded, victim -> \"%s\"\n", tag, victim);
  800540:	bead                	j	8000ba <cprintf>
        cprintf("[dirtycow][%s] blocked (ret=%d), victim -> \"%s\"\n", tag, ret, victim);
  800542:	85a2                	mv	a1,s0
}
  800544:	6402                	ld	s0,0(sp)
  800546:	60a2                	ld	ra,8(sp)
        cprintf("[dirtycow][%s] blocked (ret=%d), victim -> \"%s\"\n", tag, ret, victim);
  800548:	862a                	mv	a2,a0
  80054a:	00000697          	auipc	a3,0x0
  80054e:	4ce68693          	addi	a3,a3,1230 # 800a18 <victim>
  800552:	00000517          	auipc	a0,0x0
  800556:	3b650513          	addi	a0,a0,950 # 800908 <error_string+0xc8>
}
  80055a:	0141                	addi	sp,sp,16
        cprintf("[dirtycow][%s] blocked (ret=%d), victim -> \"%s\"\n", tag, ret, victim);
  80055c:	beb9                	j	8000ba <cprintf>

000000000080055e <main>:

int main(void)
{
  80055e:	1141                	addi	sp,sp,-16
  800560:	e406                	sd	ra,8(sp)
  800562:	e022                	sd	s0,0(sp)
    cprintf("[dirtycow] pid=%d victim@%p -> \"%s\"\n", getpid(), victim, victim);
  800564:	b31ff0ef          	jal	ra,800094 <getpid>
  800568:	00000697          	auipc	a3,0x0
  80056c:	4b068693          	addi	a3,a3,1200 # 800a18 <victim>
  800570:	85aa                	mv	a1,a0
  800572:	8636                	mv	a2,a3
  800574:	00000517          	auipc	a0,0x0
  800578:	3fc50513          	addi	a0,a0,1020 # 800970 <error_string+0x130>
  80057c:	b3fff0ef          	jal	ra,8000ba <cprintf>
    cprintf("[dirtycow] dirtycowctl(-1) queries mode, dirtycowctl(0/1) toggles fix/bug.\n");
  800580:	00000517          	auipc	a0,0x0
  800584:	41850513          	addi	a0,a0,1048 # 800998 <error_string+0x158>
  800588:	b33ff0ef          	jal	ra,8000ba <cprintf>

    // 记录运行前的模式，便于退出前还原，避免影响其他测试
    int prev = dirtycowctl(-1);
  80058c:	557d                	li	a0,-1
  80058e:	b0bff0ef          	jal	ra,800098 <dirtycowctl>
  800592:	842a                	mv	s0,a0

    dirtycowctl(0);             // 1) 切到修复模式，预期 mempoke 会返回错误
  800594:	4501                	li	a0,0
  800596:	b03ff0ef          	jal	ra,800098 <dirtycowctl>
    try_patch("fix");
  80059a:	00000517          	auipc	a0,0x0
  80059e:	44e50513          	addi	a0,a0,1102 # 8009e8 <error_string+0x1a8>
  8005a2:	f65ff0ef          	jal	ra,800506 <try_patch>

    dirtycowctl(1);             // 2) 切到漏洞模式，预期 mempoke 能成功修改 victim
  8005a6:	4505                	li	a0,1
  8005a8:	af1ff0ef          	jal	ra,800098 <dirtycowctl>
    try_patch("bug");
  8005ac:	00000517          	auipc	a0,0x0
  8005b0:	44450513          	addi	a0,a0,1092 # 8009f0 <error_string+0x1b0>
  8005b4:	f53ff0ef          	jal	ra,800506 <try_patch>

    // 3) 恢复原有模式，保持测试环境整洁
    if (prev == 0 || prev == 1)
  8005b8:	0004071b          	sext.w	a4,s0
  8005bc:	4785                	li	a5,1
  8005be:	00e7f763          	bgeu	a5,a4,8005cc <main+0x6e>
    {
        dirtycowctl(prev);
    }
    return 0;
}
  8005c2:	60a2                	ld	ra,8(sp)
  8005c4:	6402                	ld	s0,0(sp)
  8005c6:	4501                	li	a0,0
  8005c8:	0141                	addi	sp,sp,16
  8005ca:	8082                	ret
        dirtycowctl(prev);
  8005cc:	8522                	mv	a0,s0
  8005ce:	acbff0ef          	jal	ra,800098 <dirtycowctl>
  8005d2:	bfc5                	j	8005c2 <main+0x64>
