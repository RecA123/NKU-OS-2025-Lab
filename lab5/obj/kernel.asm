
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000c2517          	auipc	a0,0xc2
ffffffffc020004e:	c8a50513          	addi	a0,a0,-886 # ffffffffc02c1cd4 <edata>
ffffffffc0200052:	000c6617          	auipc	a2,0xc6
ffffffffc0200056:	14a60613          	addi	a2,a2,330 # ffffffffc02c619c <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	18b050ef          	jal	ra,ffffffffc02059ec <memset>
    dtb_init();
ffffffffc0200066:	59e000ef          	jal	ra,ffffffffc0200604 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	1a1000ef          	jal	ra,ffffffffc0200a0a <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	db258593          	addi	a1,a1,-590 # ffffffffc0205e20 <etext+0x6>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	dca50513          	addi	a0,a0,-566 # ffffffffc0205e40 <etext+0x26>
ffffffffc020007e:	062000ef          	jal	ra,ffffffffc02000e0 <cprintf>

    print_kerninfo();
ffffffffc0200082:	23c000ef          	jal	ra,ffffffffc02002be <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	45f010ef          	jal	ra,ffffffffc0201ce4 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	1f3000ef          	jal	ra,ffffffffc0200a7c <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	1fd000ef          	jal	ra,ffffffffc0200a8a <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	168030ef          	jal	ra,ffffffffc02031fa <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	4c2050ef          	jal	ra,ffffffffc0205558 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	11d000ef          	jal	ra,ffffffffc02009b6 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	1e1000ef          	jal	ra,ffffffffc0200a7e <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	64e050ef          	jal	ra,ffffffffc02056f0 <cpu_idle>

ffffffffc02000a6 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc02000a6:	1141                	addi	sp,sp,-16
ffffffffc02000a8:	e022                	sd	s0,0(sp)
ffffffffc02000aa:	e406                	sd	ra,8(sp)
ffffffffc02000ac:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ae:	15f000ef          	jal	ra,ffffffffc0200a0c <cons_putc>
    (*cnt)++;
ffffffffc02000b2:	401c                	lw	a5,0(s0)
}
ffffffffc02000b4:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc02000b6:	2785                	addiw	a5,a5,1
ffffffffc02000b8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000ba:	6402                	ld	s0,0(sp)
ffffffffc02000bc:	0141                	addi	sp,sp,16
ffffffffc02000be:	8082                	ret

ffffffffc02000c0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc02000c0:	1101                	addi	sp,sp,-32
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a6 <cputch>
ffffffffc02000ce:	006c                	addi	a1,sp,12
{
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d2:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000d4:	1af050ef          	jal	ra,ffffffffc0205a82 <vprintfmt>
    return cnt;
}
ffffffffc02000d8:	60e2                	ld	ra,24(sp)
ffffffffc02000da:	4532                	lw	a0,12(sp)
ffffffffc02000dc:	6105                	addi	sp,sp,32
ffffffffc02000de:	8082                	ret

ffffffffc02000e0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc02000e0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e2:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
{
ffffffffc02000e6:	8e2a                	mv	t3,a0
ffffffffc02000e8:	f42e                	sd	a1,40(sp)
ffffffffc02000ea:	f832                	sd	a2,48(sp)
ffffffffc02000ec:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000ee:	00000517          	auipc	a0,0x0
ffffffffc02000f2:	fb850513          	addi	a0,a0,-72 # ffffffffc02000a6 <cputch>
ffffffffc02000f6:	004c                	addi	a1,sp,4
ffffffffc02000f8:	869a                	mv	a3,t1
ffffffffc02000fa:	8672                	mv	a2,t3
{
ffffffffc02000fc:	ec06                	sd	ra,24(sp)
ffffffffc02000fe:	e0ba                	sd	a4,64(sp)
ffffffffc0200100:	e4be                	sd	a5,72(sp)
ffffffffc0200102:	e8c2                	sd	a6,80(sp)
ffffffffc0200104:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200106:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200108:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020010a:	179050ef          	jal	ra,ffffffffc0205a82 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010e:	60e2                	ld	ra,24(sp)
ffffffffc0200110:	4512                	lw	a0,4(sp)
ffffffffc0200112:	6125                	addi	sp,sp,96
ffffffffc0200114:	8082                	ret

ffffffffc0200116 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc0200116:	0f70006f          	j	ffffffffc0200a0c <cons_putc>

ffffffffc020011a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc020011a:	1101                	addi	sp,sp,-32
ffffffffc020011c:	e822                	sd	s0,16(sp)
ffffffffc020011e:	ec06                	sd	ra,24(sp)
ffffffffc0200120:	e426                	sd	s1,8(sp)
ffffffffc0200122:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc0200124:	00054503          	lbu	a0,0(a0)
ffffffffc0200128:	c51d                	beqz	a0,ffffffffc0200156 <cputs+0x3c>
ffffffffc020012a:	0405                	addi	s0,s0,1
ffffffffc020012c:	4485                	li	s1,1
ffffffffc020012e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200130:	0dd000ef          	jal	ra,ffffffffc0200a0c <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc0200134:	00044503          	lbu	a0,0(s0)
ffffffffc0200138:	008487bb          	addw	a5,s1,s0
ffffffffc020013c:	0405                	addi	s0,s0,1
ffffffffc020013e:	f96d                	bnez	a0,ffffffffc0200130 <cputs+0x16>
    (*cnt)++;
ffffffffc0200140:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200144:	4529                	li	a0,10
ffffffffc0200146:	0c7000ef          	jal	ra,ffffffffc0200a0c <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020014a:	60e2                	ld	ra,24(sp)
ffffffffc020014c:	8522                	mv	a0,s0
ffffffffc020014e:	6442                	ld	s0,16(sp)
ffffffffc0200150:	64a2                	ld	s1,8(sp)
ffffffffc0200152:	6105                	addi	sp,sp,32
ffffffffc0200154:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200156:	4405                	li	s0,1
ffffffffc0200158:	b7f5                	j	ffffffffc0200144 <cputs+0x2a>

ffffffffc020015a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020015e:	0e3000ef          	jal	ra,ffffffffc0200a40 <cons_getc>
ffffffffc0200162:	dd75                	beqz	a0,ffffffffc020015e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200164:	60a2                	ld	ra,8(sp)
ffffffffc0200166:	0141                	addi	sp,sp,16
ffffffffc0200168:	8082                	ret

ffffffffc020016a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020016a:	715d                	addi	sp,sp,-80
ffffffffc020016c:	e486                	sd	ra,72(sp)
ffffffffc020016e:	e0a6                	sd	s1,64(sp)
ffffffffc0200170:	fc4a                	sd	s2,56(sp)
ffffffffc0200172:	f84e                	sd	s3,48(sp)
ffffffffc0200174:	f452                	sd	s4,40(sp)
ffffffffc0200176:	f056                	sd	s5,32(sp)
ffffffffc0200178:	ec5a                	sd	s6,24(sp)
ffffffffc020017a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc020017c:	c901                	beqz	a0,ffffffffc020018c <readline+0x22>
ffffffffc020017e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0200180:	00006517          	auipc	a0,0x6
ffffffffc0200184:	cc850513          	addi	a0,a0,-824 # ffffffffc0205e48 <etext+0x2e>
ffffffffc0200188:	f59ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
readline(const char *prompt) {
ffffffffc020018c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020018e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200190:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200192:	4aa9                	li	s5,10
ffffffffc0200194:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200196:	000c2b97          	auipc	s7,0xc2
ffffffffc020019a:	b42b8b93          	addi	s7,s7,-1214 # ffffffffc02c1cd8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020019e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02001a2:	fb9ff0ef          	jal	ra,ffffffffc020015a <getchar>
        if (c < 0) {
ffffffffc02001a6:	00054a63          	bltz	a0,ffffffffc02001ba <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001aa:	00a95a63          	bge	s2,a0,ffffffffc02001be <readline+0x54>
ffffffffc02001ae:	029a5263          	bge	s4,s1,ffffffffc02001d2 <readline+0x68>
        c = getchar();
ffffffffc02001b2:	fa9ff0ef          	jal	ra,ffffffffc020015a <getchar>
        if (c < 0) {
ffffffffc02001b6:	fe055ae3          	bgez	a0,ffffffffc02001aa <readline+0x40>
            return NULL;
ffffffffc02001ba:	4501                	li	a0,0
ffffffffc02001bc:	a091                	j	ffffffffc0200200 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02001be:	03351463          	bne	a0,s3,ffffffffc02001e6 <readline+0x7c>
ffffffffc02001c2:	e8a9                	bnez	s1,ffffffffc0200214 <readline+0xaa>
        c = getchar();
ffffffffc02001c4:	f97ff0ef          	jal	ra,ffffffffc020015a <getchar>
        if (c < 0) {
ffffffffc02001c8:	fe0549e3          	bltz	a0,ffffffffc02001ba <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001cc:	fea959e3          	bge	s2,a0,ffffffffc02001be <readline+0x54>
ffffffffc02001d0:	4481                	li	s1,0
            cputchar(c);
ffffffffc02001d2:	e42a                	sd	a0,8(sp)
ffffffffc02001d4:	f43ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i ++] = c;
ffffffffc02001d8:	6522                	ld	a0,8(sp)
ffffffffc02001da:	009b87b3          	add	a5,s7,s1
ffffffffc02001de:	2485                	addiw	s1,s1,1
ffffffffc02001e0:	00a78023          	sb	a0,0(a5)
ffffffffc02001e4:	bf7d                	j	ffffffffc02001a2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001e6:	01550463          	beq	a0,s5,ffffffffc02001ee <readline+0x84>
ffffffffc02001ea:	fb651ce3          	bne	a0,s6,ffffffffc02001a2 <readline+0x38>
            cputchar(c);
ffffffffc02001ee:	f29ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i] = '\0';
ffffffffc02001f2:	000c2517          	auipc	a0,0xc2
ffffffffc02001f6:	ae650513          	addi	a0,a0,-1306 # ffffffffc02c1cd8 <buf>
ffffffffc02001fa:	94aa                	add	s1,s1,a0
ffffffffc02001fc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200200:	60a6                	ld	ra,72(sp)
ffffffffc0200202:	6486                	ld	s1,64(sp)
ffffffffc0200204:	7962                	ld	s2,56(sp)
ffffffffc0200206:	79c2                	ld	s3,48(sp)
ffffffffc0200208:	7a22                	ld	s4,40(sp)
ffffffffc020020a:	7a82                	ld	s5,32(sp)
ffffffffc020020c:	6b62                	ld	s6,24(sp)
ffffffffc020020e:	6bc2                	ld	s7,16(sp)
ffffffffc0200210:	6161                	addi	sp,sp,80
ffffffffc0200212:	8082                	ret
            cputchar(c);
ffffffffc0200214:	4521                	li	a0,8
ffffffffc0200216:	f01ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            i --;
ffffffffc020021a:	34fd                	addiw	s1,s1,-1
ffffffffc020021c:	b759                	j	ffffffffc02001a2 <readline+0x38>

ffffffffc020021e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020021e:	000c6317          	auipc	t1,0xc6
ffffffffc0200222:	efa30313          	addi	t1,t1,-262 # ffffffffc02c6118 <is_panic>
ffffffffc0200226:	00033e03          	ld	t3,0(t1)
{
ffffffffc020022a:	715d                	addi	sp,sp,-80
ffffffffc020022c:	ec06                	sd	ra,24(sp)
ffffffffc020022e:	e822                	sd	s0,16(sp)
ffffffffc0200230:	f436                	sd	a3,40(sp)
ffffffffc0200232:	f83a                	sd	a4,48(sp)
ffffffffc0200234:	fc3e                	sd	a5,56(sp)
ffffffffc0200236:	e0c2                	sd	a6,64(sp)
ffffffffc0200238:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc020023a:	020e1a63          	bnez	t3,ffffffffc020026e <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020023e:	4785                	li	a5,1
ffffffffc0200240:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200244:	8432                	mv	s0,a2
ffffffffc0200246:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200248:	862e                	mv	a2,a1
ffffffffc020024a:	85aa                	mv	a1,a0
ffffffffc020024c:	00006517          	auipc	a0,0x6
ffffffffc0200250:	c0450513          	addi	a0,a0,-1020 # ffffffffc0205e50 <etext+0x36>
    va_start(ap, fmt);
ffffffffc0200254:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200256:	e8bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020025a:	65a2                	ld	a1,8(sp)
ffffffffc020025c:	8522                	mv	a0,s0
ffffffffc020025e:	e63ff0ef          	jal	ra,ffffffffc02000c0 <vcprintf>
    cprintf("\n");
ffffffffc0200262:	00007517          	auipc	a0,0x7
ffffffffc0200266:	dae50513          	addi	a0,a0,-594 # ffffffffc0207010 <commands+0xe18>
ffffffffc020026a:	e77ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020026e:	017000ef          	jal	ra,ffffffffc0200a84 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc0200272:	4501                	li	a0,0
ffffffffc0200274:	248000ef          	jal	ra,ffffffffc02004bc <kmonitor>
    while (1)
ffffffffc0200278:	bfed                	j	ffffffffc0200272 <__panic+0x54>

ffffffffc020027a <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc020027a:	715d                	addi	sp,sp,-80
ffffffffc020027c:	832e                	mv	t1,a1
ffffffffc020027e:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200280:	85aa                	mv	a1,a0
{
ffffffffc0200282:	8432                	mv	s0,a2
ffffffffc0200284:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200286:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200288:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020028a:	00006517          	auipc	a0,0x6
ffffffffc020028e:	be650513          	addi	a0,a0,-1050 # ffffffffc0205e70 <etext+0x56>
{
ffffffffc0200292:	ec06                	sd	ra,24(sp)
ffffffffc0200294:	f436                	sd	a3,40(sp)
ffffffffc0200296:	f83a                	sd	a4,48(sp)
ffffffffc0200298:	e0c2                	sd	a6,64(sp)
ffffffffc020029a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020029c:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020029e:	e43ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02002a2:	65a2                	ld	a1,8(sp)
ffffffffc02002a4:	8522                	mv	a0,s0
ffffffffc02002a6:	e1bff0ef          	jal	ra,ffffffffc02000c0 <vcprintf>
    cprintf("\n");
ffffffffc02002aa:	00007517          	auipc	a0,0x7
ffffffffc02002ae:	d6650513          	addi	a0,a0,-666 # ffffffffc0207010 <commands+0xe18>
ffffffffc02002b2:	e2fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    va_end(ap);
}
ffffffffc02002b6:	60e2                	ld	ra,24(sp)
ffffffffc02002b8:	6442                	ld	s0,16(sp)
ffffffffc02002ba:	6161                	addi	sp,sp,80
ffffffffc02002bc:	8082                	ret

ffffffffc02002be <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02002be:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02002c0:	00006517          	auipc	a0,0x6
ffffffffc02002c4:	bd050513          	addi	a0,a0,-1072 # ffffffffc0205e90 <etext+0x76>
{
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02002ca:	e17ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02002ce:	00000597          	auipc	a1,0x0
ffffffffc02002d2:	d7c58593          	addi	a1,a1,-644 # ffffffffc020004a <kern_init>
ffffffffc02002d6:	00006517          	auipc	a0,0x6
ffffffffc02002da:	bda50513          	addi	a0,a0,-1062 # ffffffffc0205eb0 <etext+0x96>
ffffffffc02002de:	e03ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02002e2:	00006597          	auipc	a1,0x6
ffffffffc02002e6:	b3858593          	addi	a1,a1,-1224 # ffffffffc0205e1a <etext>
ffffffffc02002ea:	00006517          	auipc	a0,0x6
ffffffffc02002ee:	be650513          	addi	a0,a0,-1050 # ffffffffc0205ed0 <etext+0xb6>
ffffffffc02002f2:	defff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02002f6:	000c2597          	auipc	a1,0xc2
ffffffffc02002fa:	9de58593          	addi	a1,a1,-1570 # ffffffffc02c1cd4 <edata>
ffffffffc02002fe:	00006517          	auipc	a0,0x6
ffffffffc0200302:	bf250513          	addi	a0,a0,-1038 # ffffffffc0205ef0 <etext+0xd6>
ffffffffc0200306:	ddbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020030a:	000c6597          	auipc	a1,0xc6
ffffffffc020030e:	e9258593          	addi	a1,a1,-366 # ffffffffc02c619c <end>
ffffffffc0200312:	00006517          	auipc	a0,0x6
ffffffffc0200316:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0205f10 <etext+0xf6>
ffffffffc020031a:	dc7ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020031e:	000c6597          	auipc	a1,0xc6
ffffffffc0200322:	27d58593          	addi	a1,a1,637 # ffffffffc02c659b <end+0x3ff>
ffffffffc0200326:	00000797          	auipc	a5,0x0
ffffffffc020032a:	d2478793          	addi	a5,a5,-732 # ffffffffc020004a <kern_init>
ffffffffc020032e:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200332:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200336:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200338:	3ff5f593          	andi	a1,a1,1023
ffffffffc020033c:	95be                	add	a1,a1,a5
ffffffffc020033e:	85a9                	srai	a1,a1,0xa
ffffffffc0200340:	00006517          	auipc	a0,0x6
ffffffffc0200344:	bf050513          	addi	a0,a0,-1040 # ffffffffc0205f30 <etext+0x116>
}
ffffffffc0200348:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020034a:	bb59                	j	ffffffffc02000e0 <cprintf>

ffffffffc020034c <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020034c:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020034e:	00006617          	auipc	a2,0x6
ffffffffc0200352:	c1260613          	addi	a2,a2,-1006 # ffffffffc0205f60 <etext+0x146>
ffffffffc0200356:	04f00593          	li	a1,79
ffffffffc020035a:	00006517          	auipc	a0,0x6
ffffffffc020035e:	c1e50513          	addi	a0,a0,-994 # ffffffffc0205f78 <etext+0x15e>
{
ffffffffc0200362:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200364:	ebbff0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0200368 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200368:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020036a:	00006617          	auipc	a2,0x6
ffffffffc020036e:	c2660613          	addi	a2,a2,-986 # ffffffffc0205f90 <etext+0x176>
ffffffffc0200372:	00006597          	auipc	a1,0x6
ffffffffc0200376:	c3e58593          	addi	a1,a1,-962 # ffffffffc0205fb0 <etext+0x196>
ffffffffc020037a:	00006517          	auipc	a0,0x6
ffffffffc020037e:	c3e50513          	addi	a0,a0,-962 # ffffffffc0205fb8 <etext+0x19e>
{
ffffffffc0200382:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200384:	d5dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200388:	00006617          	auipc	a2,0x6
ffffffffc020038c:	c4060613          	addi	a2,a2,-960 # ffffffffc0205fc8 <etext+0x1ae>
ffffffffc0200390:	00006597          	auipc	a1,0x6
ffffffffc0200394:	c6058593          	addi	a1,a1,-928 # ffffffffc0205ff0 <etext+0x1d6>
ffffffffc0200398:	00006517          	auipc	a0,0x6
ffffffffc020039c:	c2050513          	addi	a0,a0,-992 # ffffffffc0205fb8 <etext+0x19e>
ffffffffc02003a0:	d41ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02003a4:	00006617          	auipc	a2,0x6
ffffffffc02003a8:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206000 <etext+0x1e6>
ffffffffc02003ac:	00006597          	auipc	a1,0x6
ffffffffc02003b0:	c7458593          	addi	a1,a1,-908 # ffffffffc0206020 <etext+0x206>
ffffffffc02003b4:	00006517          	auipc	a0,0x6
ffffffffc02003b8:	c0450513          	addi	a0,a0,-1020 # ffffffffc0205fb8 <etext+0x19e>
ffffffffc02003bc:	d25ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02003c0:	00006617          	auipc	a2,0x6
ffffffffc02003c4:	c7060613          	addi	a2,a2,-912 # ffffffffc0206030 <etext+0x216>
ffffffffc02003c8:	00006597          	auipc	a1,0x6
ffffffffc02003cc:	c9058593          	addi	a1,a1,-880 # ffffffffc0206058 <etext+0x23e>
ffffffffc02003d0:	00006517          	auipc	a0,0x6
ffffffffc02003d4:	be850513          	addi	a0,a0,-1048 # ffffffffc0205fb8 <etext+0x19e>
ffffffffc02003d8:	d09ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    return 0;
}
ffffffffc02003dc:	60a2                	ld	ra,8(sp)
ffffffffc02003de:	4501                	li	a0,0
ffffffffc02003e0:	0141                	addi	sp,sp,16
ffffffffc02003e2:	8082                	ret

ffffffffc02003e4 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02003e4:	1141                	addi	sp,sp,-16
ffffffffc02003e6:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02003e8:	ed7ff0ef          	jal	ra,ffffffffc02002be <print_kerninfo>
    return 0;
}
ffffffffc02003ec:	60a2                	ld	ra,8(sp)
ffffffffc02003ee:	4501                	li	a0,0
ffffffffc02003f0:	0141                	addi	sp,sp,16
ffffffffc02003f2:	8082                	ret

ffffffffc02003f4 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02003f4:	1141                	addi	sp,sp,-16
ffffffffc02003f6:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02003f8:	f55ff0ef          	jal	ra,ffffffffc020034c <print_stackframe>
    return 0;
}
ffffffffc02003fc:	60a2                	ld	ra,8(sp)
ffffffffc02003fe:	4501                	li	a0,0
ffffffffc0200400:	0141                	addi	sp,sp,16
ffffffffc0200402:	8082                	ret

ffffffffc0200404 <mon_dirtycow>:

static int
mon_dirtycow(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200404:	1141                	addi	sp,sp,-16
ffffffffc0200406:	e406                	sd	ra,8(sp)
ffffffffc0200408:	e022                	sd	s0,0(sp)
    // dirtycow 命令实现：
    //   - 无参数：打印当前 Dirty COW 模式和统计计数，顺便提示用法
    //   - 参数 bug/fix：切换到漏洞/修复模式，再打印切换后的模式
    if (argc == 0)
ffffffffc020040a:	c135                	beqz	a0,ffffffffc020046e <mon_dirtycow+0x6a>
                dirtycow_stats.unsafe_writes, dirtycow_stats.repaired_writes);
        cprintf(" usage: dirtycow [bug|fix]\n");
        return 0;
    }

    if (strcmp(argv[0], "bug") == 0)
ffffffffc020040c:	6188                	ld	a0,0(a1)
ffffffffc020040e:	842e                	mv	s0,a1
ffffffffc0200410:	00006597          	auipc	a1,0x6
ffffffffc0200414:	cc858593          	addi	a1,a1,-824 # ffffffffc02060d8 <etext+0x2be>
ffffffffc0200418:	57a050ef          	jal	ra,ffffffffc0205992 <strcmp>
ffffffffc020041c:	e905                	bnez	a0,ffffffffc020044c <mon_dirtycow+0x48>
    {
        dirtycow_set_mode(1);
ffffffffc020041e:	4505                	li	a0,1
ffffffffc0200420:	60f000ef          	jal	ra,ffffffffc020122e <dirtycow_set_mode>
        cprintf("Dirty COW bug emulation enabled.\n");
ffffffffc0200424:	00006517          	auipc	a0,0x6
ffffffffc0200428:	cbc50513          	addi	a0,a0,-836 # ffffffffc02060e0 <etext+0x2c6>
ffffffffc020042c:	cb5ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    else
    {
        cprintf("usage: dirtycow [bug|fix]\n");
    }
    cprintf(" mode now: %s\n", dirtycow_mode_string());
ffffffffc0200430:	60d000ef          	jal	ra,ffffffffc020123c <dirtycow_mode_string>
ffffffffc0200434:	85aa                	mv	a1,a0
ffffffffc0200436:	00006517          	auipc	a0,0x6
ffffffffc020043a:	d1a50513          	addi	a0,a0,-742 # ffffffffc0206150 <etext+0x336>
ffffffffc020043e:	ca3ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
}
ffffffffc0200442:	60a2                	ld	ra,8(sp)
ffffffffc0200444:	6402                	ld	s0,0(sp)
ffffffffc0200446:	4501                	li	a0,0
ffffffffc0200448:	0141                	addi	sp,sp,16
ffffffffc020044a:	8082                	ret
    else if (strcmp(argv[0], "fix") == 0)
ffffffffc020044c:	6008                	ld	a0,0(s0)
ffffffffc020044e:	00006597          	auipc	a1,0x6
ffffffffc0200452:	cba58593          	addi	a1,a1,-838 # ffffffffc0206108 <etext+0x2ee>
ffffffffc0200456:	53c050ef          	jal	ra,ffffffffc0205992 <strcmp>
ffffffffc020045a:	e931                	bnez	a0,ffffffffc02004ae <mon_dirtycow+0xaa>
        dirtycow_set_mode(0);
ffffffffc020045c:	5d3000ef          	jal	ra,ffffffffc020122e <dirtycow_set_mode>
        cprintf("Dirty COW fix mode enabled.\n");
ffffffffc0200460:	00006517          	auipc	a0,0x6
ffffffffc0200464:	cb050513          	addi	a0,a0,-848 # ffffffffc0206110 <etext+0x2f6>
ffffffffc0200468:	c79ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc020046c:	b7d1                	j	ffffffffc0200430 <mon_dirtycow+0x2c>
        cprintf("Dirty COW demo mode: %s\n", dirtycow_mode_string());
ffffffffc020046e:	5cf000ef          	jal	ra,ffffffffc020123c <dirtycow_mode_string>
ffffffffc0200472:	85aa                	mv	a1,a0
ffffffffc0200474:	00006517          	auipc	a0,0x6
ffffffffc0200478:	bf450513          	addi	a0,a0,-1036 # ffffffffc0206068 <etext+0x24e>
ffffffffc020047c:	c65ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf(" unsafe writes=%llu repaired writes=%llu\n",
ffffffffc0200480:	000c2797          	auipc	a5,0xc2
ffffffffc0200484:	c5878793          	addi	a5,a5,-936 # ffffffffc02c20d8 <dirtycow_stats>
ffffffffc0200488:	6b90                	ld	a2,16(a5)
ffffffffc020048a:	678c                	ld	a1,8(a5)
ffffffffc020048c:	00006517          	auipc	a0,0x6
ffffffffc0200490:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0206088 <etext+0x26e>
ffffffffc0200494:	c4dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf(" usage: dirtycow [bug|fix]\n");
ffffffffc0200498:	00006517          	auipc	a0,0x6
ffffffffc020049c:	c2050513          	addi	a0,a0,-992 # ffffffffc02060b8 <etext+0x29e>
ffffffffc02004a0:	c41ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc02004a4:	60a2                	ld	ra,8(sp)
ffffffffc02004a6:	6402                	ld	s0,0(sp)
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	0141                	addi	sp,sp,16
ffffffffc02004ac:	8082                	ret
        cprintf("usage: dirtycow [bug|fix]\n");
ffffffffc02004ae:	00006517          	auipc	a0,0x6
ffffffffc02004b2:	c8250513          	addi	a0,a0,-894 # ffffffffc0206130 <etext+0x316>
ffffffffc02004b6:	c2bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02004ba:	bf9d                	j	ffffffffc0200430 <mon_dirtycow+0x2c>

ffffffffc02004bc <kmonitor>:
{
ffffffffc02004bc:	7115                	addi	sp,sp,-224
ffffffffc02004be:	ed5e                	sd	s7,152(sp)
ffffffffc02004c0:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02004c2:	00006517          	auipc	a0,0x6
ffffffffc02004c6:	c9e50513          	addi	a0,a0,-866 # ffffffffc0206160 <etext+0x346>
{
ffffffffc02004ca:	ed86                	sd	ra,216(sp)
ffffffffc02004cc:	e9a2                	sd	s0,208(sp)
ffffffffc02004ce:	e5a6                	sd	s1,200(sp)
ffffffffc02004d0:	e1ca                	sd	s2,192(sp)
ffffffffc02004d2:	fd4e                	sd	s3,184(sp)
ffffffffc02004d4:	f952                	sd	s4,176(sp)
ffffffffc02004d6:	f556                	sd	s5,168(sp)
ffffffffc02004d8:	f15a                	sd	s6,160(sp)
ffffffffc02004da:	e962                	sd	s8,144(sp)
ffffffffc02004dc:	e566                	sd	s9,136(sp)
ffffffffc02004de:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02004e0:	c01ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02004e4:	00006517          	auipc	a0,0x6
ffffffffc02004e8:	ca450513          	addi	a0,a0,-860 # ffffffffc0206188 <etext+0x36e>
ffffffffc02004ec:	bf5ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    if (tf != NULL)
ffffffffc02004f0:	000b8563          	beqz	s7,ffffffffc02004fa <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02004f4:	855e                	mv	a0,s7
ffffffffc02004f6:	77c000ef          	jal	ra,ffffffffc0200c72 <print_trapframe>
ffffffffc02004fa:	00006c17          	auipc	s8,0x6
ffffffffc02004fe:	cfec0c13          	addi	s8,s8,-770 # ffffffffc02061f8 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200502:	00006917          	auipc	s2,0x6
ffffffffc0200506:	cae90913          	addi	s2,s2,-850 # ffffffffc02061b0 <etext+0x396>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020050a:	00006497          	auipc	s1,0x6
ffffffffc020050e:	cae48493          	addi	s1,s1,-850 # ffffffffc02061b8 <etext+0x39e>
        if (argc == MAXARGS - 1)
ffffffffc0200512:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200514:	00006b17          	auipc	s6,0x6
ffffffffc0200518:	cacb0b13          	addi	s6,s6,-852 # ffffffffc02061c0 <etext+0x3a6>
        argv[argc++] = buf;
ffffffffc020051c:	00006a17          	auipc	s4,0x6
ffffffffc0200520:	a94a0a13          	addi	s4,s4,-1388 # ffffffffc0205fb0 <etext+0x196>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200524:	4a91                	li	s5,4
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200526:	854a                	mv	a0,s2
ffffffffc0200528:	c43ff0ef          	jal	ra,ffffffffc020016a <readline>
ffffffffc020052c:	842a                	mv	s0,a0
ffffffffc020052e:	dd65                	beqz	a0,ffffffffc0200526 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200530:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200534:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200536:	e1bd                	bnez	a1,ffffffffc020059c <kmonitor+0xe0>
    if (argc == 0)
ffffffffc0200538:	fe0c87e3          	beqz	s9,ffffffffc0200526 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020053c:	6582                	ld	a1,0(sp)
ffffffffc020053e:	00006d17          	auipc	s10,0x6
ffffffffc0200542:	cbad0d13          	addi	s10,s10,-838 # ffffffffc02061f8 <commands>
        argv[argc++] = buf;
ffffffffc0200546:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200548:	4401                	li	s0,0
ffffffffc020054a:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020054c:	446050ef          	jal	ra,ffffffffc0205992 <strcmp>
ffffffffc0200550:	c919                	beqz	a0,ffffffffc0200566 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200552:	2405                	addiw	s0,s0,1
ffffffffc0200554:	0b540063          	beq	s0,s5,ffffffffc02005f4 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200558:	000d3503          	ld	a0,0(s10)
ffffffffc020055c:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020055e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200560:	432050ef          	jal	ra,ffffffffc0205992 <strcmp>
ffffffffc0200564:	f57d                	bnez	a0,ffffffffc0200552 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200566:	00141793          	slli	a5,s0,0x1
ffffffffc020056a:	97a2                	add	a5,a5,s0
ffffffffc020056c:	078e                	slli	a5,a5,0x3
ffffffffc020056e:	97e2                	add	a5,a5,s8
ffffffffc0200570:	6b9c                	ld	a5,16(a5)
ffffffffc0200572:	865e                	mv	a2,s7
ffffffffc0200574:	002c                	addi	a1,sp,8
ffffffffc0200576:	fffc851b          	addiw	a0,s9,-1
ffffffffc020057a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc020057c:	fa0555e3          	bgez	a0,ffffffffc0200526 <kmonitor+0x6a>
}
ffffffffc0200580:	60ee                	ld	ra,216(sp)
ffffffffc0200582:	644e                	ld	s0,208(sp)
ffffffffc0200584:	64ae                	ld	s1,200(sp)
ffffffffc0200586:	690e                	ld	s2,192(sp)
ffffffffc0200588:	79ea                	ld	s3,184(sp)
ffffffffc020058a:	7a4a                	ld	s4,176(sp)
ffffffffc020058c:	7aaa                	ld	s5,168(sp)
ffffffffc020058e:	7b0a                	ld	s6,160(sp)
ffffffffc0200590:	6bea                	ld	s7,152(sp)
ffffffffc0200592:	6c4a                	ld	s8,144(sp)
ffffffffc0200594:	6caa                	ld	s9,136(sp)
ffffffffc0200596:	6d0a                	ld	s10,128(sp)
ffffffffc0200598:	612d                	addi	sp,sp,224
ffffffffc020059a:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020059c:	8526                	mv	a0,s1
ffffffffc020059e:	438050ef          	jal	ra,ffffffffc02059d6 <strchr>
ffffffffc02005a2:	c901                	beqz	a0,ffffffffc02005b2 <kmonitor+0xf6>
ffffffffc02005a4:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc02005a8:	00040023          	sb	zero,0(s0)
ffffffffc02005ac:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02005ae:	d5c9                	beqz	a1,ffffffffc0200538 <kmonitor+0x7c>
ffffffffc02005b0:	b7f5                	j	ffffffffc020059c <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc02005b2:	00044783          	lbu	a5,0(s0)
ffffffffc02005b6:	d3c9                	beqz	a5,ffffffffc0200538 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc02005b8:	033c8963          	beq	s9,s3,ffffffffc02005ea <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc02005bc:	003c9793          	slli	a5,s9,0x3
ffffffffc02005c0:	0118                	addi	a4,sp,128
ffffffffc02005c2:	97ba                	add	a5,a5,a4
ffffffffc02005c4:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02005c8:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc02005cc:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02005ce:	e591                	bnez	a1,ffffffffc02005da <kmonitor+0x11e>
ffffffffc02005d0:	b7b5                	j	ffffffffc020053c <kmonitor+0x80>
ffffffffc02005d2:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc02005d6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02005d8:	d1a5                	beqz	a1,ffffffffc0200538 <kmonitor+0x7c>
ffffffffc02005da:	8526                	mv	a0,s1
ffffffffc02005dc:	3fa050ef          	jal	ra,ffffffffc02059d6 <strchr>
ffffffffc02005e0:	d96d                	beqz	a0,ffffffffc02005d2 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02005e2:	00044583          	lbu	a1,0(s0)
ffffffffc02005e6:	d9a9                	beqz	a1,ffffffffc0200538 <kmonitor+0x7c>
ffffffffc02005e8:	bf55                	j	ffffffffc020059c <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02005ea:	45c1                	li	a1,16
ffffffffc02005ec:	855a                	mv	a0,s6
ffffffffc02005ee:	af3ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02005f2:	b7e9                	j	ffffffffc02005bc <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02005f4:	6582                	ld	a1,0(sp)
ffffffffc02005f6:	00006517          	auipc	a0,0x6
ffffffffc02005fa:	bea50513          	addi	a0,a0,-1046 # ffffffffc02061e0 <etext+0x3c6>
ffffffffc02005fe:	ae3ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
ffffffffc0200602:	b715                	j	ffffffffc0200526 <kmonitor+0x6a>

ffffffffc0200604 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200604:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200606:	00006517          	auipc	a0,0x6
ffffffffc020060a:	c5250513          	addi	a0,a0,-942 # ffffffffc0206258 <commands+0x60>
void dtb_init(void) {
ffffffffc020060e:	fc86                	sd	ra,120(sp)
ffffffffc0200610:	f8a2                	sd	s0,112(sp)
ffffffffc0200612:	e8d2                	sd	s4,80(sp)
ffffffffc0200614:	f4a6                	sd	s1,104(sp)
ffffffffc0200616:	f0ca                	sd	s2,96(sp)
ffffffffc0200618:	ecce                	sd	s3,88(sp)
ffffffffc020061a:	e4d6                	sd	s5,72(sp)
ffffffffc020061c:	e0da                	sd	s6,64(sp)
ffffffffc020061e:	fc5e                	sd	s7,56(sp)
ffffffffc0200620:	f862                	sd	s8,48(sp)
ffffffffc0200622:	f466                	sd	s9,40(sp)
ffffffffc0200624:	f06a                	sd	s10,32(sp)
ffffffffc0200626:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200628:	ab9ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020062c:	0000c597          	auipc	a1,0xc
ffffffffc0200630:	9d45b583          	ld	a1,-1580(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200634:	00006517          	auipc	a0,0x6
ffffffffc0200638:	c3450513          	addi	a0,a0,-972 # ffffffffc0206268 <commands+0x70>
ffffffffc020063c:	aa5ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200640:	0000c417          	auipc	s0,0xc
ffffffffc0200644:	9c840413          	addi	s0,s0,-1592 # ffffffffc020c008 <boot_dtb>
ffffffffc0200648:	600c                	ld	a1,0(s0)
ffffffffc020064a:	00006517          	auipc	a0,0x6
ffffffffc020064e:	c2e50513          	addi	a0,a0,-978 # ffffffffc0206278 <commands+0x80>
ffffffffc0200652:	a8fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200656:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020065a:	00006517          	auipc	a0,0x6
ffffffffc020065e:	c3650513          	addi	a0,a0,-970 # ffffffffc0206290 <commands+0x98>
    if (boot_dtb == 0) {
ffffffffc0200662:	120a0463          	beqz	s4,ffffffffc020078a <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200666:	57f5                	li	a5,-3
ffffffffc0200668:	07fa                	slli	a5,a5,0x1e
ffffffffc020066a:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020066e:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200674:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020067a:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200682:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020068c:	8ec9                	or	a3,a3,a0
ffffffffc020068e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200692:	1b7d                	addi	s6,s6,-1
ffffffffc0200694:	0167f7b3          	and	a5,a5,s6
ffffffffc0200698:	8dd5                	or	a1,a1,a3
ffffffffc020069a:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a0:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02006a2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe19d51>
ffffffffc02006a6:	10f59163          	bne	a1,a5,ffffffffc02007a8 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006aa:	471c                	lw	a5,8(a4)
ffffffffc02006ac:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006ae:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006b4:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b8:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006bc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c0:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c4:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c8:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006cc:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d0:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d8:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006da:	01146433          	or	s0,s0,a7
ffffffffc02006de:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006e2:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e6:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ec:	8c49                	or	s0,s0,a0
ffffffffc02006ee:	0166f6b3          	and	a3,a3,s6
ffffffffc02006f2:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f6:	0167f7b3          	and	a5,a5,s6
ffffffffc02006fa:	8c55                	or	s0,s0,a3
ffffffffc02006fc:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200700:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200702:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020070a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020070c:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200712:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200714:	00006917          	auipc	s2,0x6
ffffffffc0200718:	bcc90913          	addi	s2,s2,-1076 # ffffffffc02062e0 <commands+0xe8>
ffffffffc020071c:	49bd                	li	s3,15
        switch (token) {
ffffffffc020071e:	4d91                	li	s11,4
ffffffffc0200720:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200722:	00006497          	auipc	s1,0x6
ffffffffc0200726:	bb648493          	addi	s1,s1,-1098 # ffffffffc02062d8 <commands+0xe0>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020072a:	000a2703          	lw	a4,0(s4)
ffffffffc020072e:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200736:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073e:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200742:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200746:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200748:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074c:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200750:	8fd5                	or	a5,a5,a3
ffffffffc0200752:	00eb7733          	and	a4,s6,a4
ffffffffc0200756:	8fd9                	or	a5,a5,a4
ffffffffc0200758:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020075a:	09778d63          	beq	a5,s7,ffffffffc02007f4 <dtb_init+0x1f0>
ffffffffc020075e:	00fbea63          	bltu	s7,a5,ffffffffc0200772 <dtb_init+0x16e>
ffffffffc0200762:	07a78763          	beq	a5,s10,ffffffffc02007d0 <dtb_init+0x1cc>
ffffffffc0200766:	4709                	li	a4,2
ffffffffc0200768:	00e79763          	bne	a5,a4,ffffffffc0200776 <dtb_init+0x172>
ffffffffc020076c:	4c81                	li	s9,0
ffffffffc020076e:	8a56                	mv	s4,s5
ffffffffc0200770:	bf6d                	j	ffffffffc020072a <dtb_init+0x126>
ffffffffc0200772:	ffb78ee3          	beq	a5,s11,ffffffffc020076e <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200776:	00006517          	auipc	a0,0x6
ffffffffc020077a:	be250513          	addi	a0,a0,-1054 # ffffffffc0206358 <commands+0x160>
ffffffffc020077e:	963ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0206390 <commands+0x198>
}
ffffffffc020078a:	7446                	ld	s0,112(sp)
ffffffffc020078c:	70e6                	ld	ra,120(sp)
ffffffffc020078e:	74a6                	ld	s1,104(sp)
ffffffffc0200790:	7906                	ld	s2,96(sp)
ffffffffc0200792:	69e6                	ld	s3,88(sp)
ffffffffc0200794:	6a46                	ld	s4,80(sp)
ffffffffc0200796:	6aa6                	ld	s5,72(sp)
ffffffffc0200798:	6b06                	ld	s6,64(sp)
ffffffffc020079a:	7be2                	ld	s7,56(sp)
ffffffffc020079c:	7c42                	ld	s8,48(sp)
ffffffffc020079e:	7ca2                	ld	s9,40(sp)
ffffffffc02007a0:	7d02                	ld	s10,32(sp)
ffffffffc02007a2:	6de2                	ld	s11,24(sp)
ffffffffc02007a4:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a6:	ba2d                	j	ffffffffc02000e0 <cprintf>
}
ffffffffc02007a8:	7446                	ld	s0,112(sp)
ffffffffc02007aa:	70e6                	ld	ra,120(sp)
ffffffffc02007ac:	74a6                	ld	s1,104(sp)
ffffffffc02007ae:	7906                	ld	s2,96(sp)
ffffffffc02007b0:	69e6                	ld	s3,88(sp)
ffffffffc02007b2:	6a46                	ld	s4,80(sp)
ffffffffc02007b4:	6aa6                	ld	s5,72(sp)
ffffffffc02007b6:	6b06                	ld	s6,64(sp)
ffffffffc02007b8:	7be2                	ld	s7,56(sp)
ffffffffc02007ba:	7c42                	ld	s8,48(sp)
ffffffffc02007bc:	7ca2                	ld	s9,40(sp)
ffffffffc02007be:	7d02                	ld	s10,32(sp)
ffffffffc02007c0:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c2:	00006517          	auipc	a0,0x6
ffffffffc02007c6:	aee50513          	addi	a0,a0,-1298 # ffffffffc02062b0 <commands+0xb8>
}
ffffffffc02007ca:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007cc:	915ff06f          	j	ffffffffc02000e0 <cprintf>
                int name_len = strlen(name);
ffffffffc02007d0:	8556                	mv	a0,s5
ffffffffc02007d2:	178050ef          	jal	ra,ffffffffc020594a <strlen>
ffffffffc02007d6:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	4619                	li	a2,6
ffffffffc02007da:	85a6                	mv	a1,s1
ffffffffc02007dc:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007de:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007e0:	1d0050ef          	jal	ra,ffffffffc02059b0 <strncmp>
ffffffffc02007e4:	e111                	bnez	a0,ffffffffc02007e8 <dtb_init+0x1e4>
                    in_memory_node = 1;
ffffffffc02007e6:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e8:	0a91                	addi	s5,s5,4
ffffffffc02007ea:	9ad2                	add	s5,s5,s4
ffffffffc02007ec:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007f0:	8a56                	mv	s4,s5
ffffffffc02007f2:	bf25                	j	ffffffffc020072a <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f4:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f8:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fc:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200800:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200808:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200810:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200814:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200818:	0087979b          	slliw	a5,a5,0x8
ffffffffc020081c:	00eaeab3          	or	s5,s5,a4
ffffffffc0200820:	00fb77b3          	and	a5,s6,a5
ffffffffc0200824:	00faeab3          	or	s5,s5,a5
ffffffffc0200828:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020082a:	000c9c63          	bnez	s9,ffffffffc0200842 <dtb_init+0x23e>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020082e:	1a82                	slli	s5,s5,0x20
ffffffffc0200830:	00368793          	addi	a5,a3,3
ffffffffc0200834:	020ada93          	srli	s5,s5,0x20
ffffffffc0200838:	9abe                	add	s5,s5,a5
ffffffffc020083a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020083e:	8a56                	mv	s4,s5
ffffffffc0200840:	b5ed                	j	ffffffffc020072a <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200842:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200846:	85ca                	mv	a1,s2
ffffffffc0200848:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200856:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020085e:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200860:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200868:	8d59                	or	a0,a0,a4
ffffffffc020086a:	00fb77b3          	and	a5,s6,a5
ffffffffc020086e:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200870:	1502                	slli	a0,a0,0x20
ffffffffc0200872:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200874:	9522                	add	a0,a0,s0
ffffffffc0200876:	11c050ef          	jal	ra,ffffffffc0205992 <strcmp>
ffffffffc020087a:	66a2                	ld	a3,8(sp)
ffffffffc020087c:	f94d                	bnez	a0,ffffffffc020082e <dtb_init+0x22a>
ffffffffc020087e:	fb59f8e3          	bgeu	s3,s5,ffffffffc020082e <dtb_init+0x22a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200882:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200886:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02062e8 <commands+0xf0>
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200896:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020089a:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020089e:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02008a2:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008aa:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ae:	0187d693          	srli	a3,a5,0x18
ffffffffc02008b2:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008b6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008ba:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008be:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008c2:	010f6f33          	or	t5,t5,a6
ffffffffc02008c6:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008ca:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008d2:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008d6:	0186f6b3          	and	a3,a3,s8
ffffffffc02008da:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008de:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e2:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008e6:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ea:	8361                	srli	a4,a4,0x18
ffffffffc02008ec:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008f0:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008f4:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f8:	00cb7633          	and	a2,s6,a2
ffffffffc02008fc:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200900:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200904:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200910:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200914:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200918:	011b78b3          	and	a7,s6,a7
ffffffffc020091c:	005eeeb3          	or	t4,t4,t0
ffffffffc0200920:	00c6e733          	or	a4,a3,a2
ffffffffc0200924:	006c6c33          	or	s8,s8,t1
ffffffffc0200928:	010b76b3          	and	a3,s6,a6
ffffffffc020092c:	00bb7b33          	and	s6,s6,a1
ffffffffc0200930:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200934:	016c6b33          	or	s6,s8,s6
ffffffffc0200938:	01146433          	or	s0,s0,a7
ffffffffc020093c:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc020093e:	1702                	slli	a4,a4,0x20
ffffffffc0200940:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200942:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200944:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200946:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200948:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020094c:	0167eb33          	or	s6,a5,s6
ffffffffc0200950:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200952:	f8eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200956:	85a2                	mv	a1,s0
ffffffffc0200958:	00006517          	auipc	a0,0x6
ffffffffc020095c:	9b050513          	addi	a0,a0,-1616 # ffffffffc0206308 <commands+0x110>
ffffffffc0200960:	f80ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200964:	014b5613          	srli	a2,s6,0x14
ffffffffc0200968:	85da                	mv	a1,s6
ffffffffc020096a:	00006517          	auipc	a0,0x6
ffffffffc020096e:	9b650513          	addi	a0,a0,-1610 # ffffffffc0206320 <commands+0x128>
ffffffffc0200972:	f6eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200976:	008b05b3          	add	a1,s6,s0
ffffffffc020097a:	15fd                	addi	a1,a1,-1
ffffffffc020097c:	00006517          	auipc	a0,0x6
ffffffffc0200980:	9c450513          	addi	a0,a0,-1596 # ffffffffc0206340 <commands+0x148>
ffffffffc0200984:	f5cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200988:	00006517          	auipc	a0,0x6
ffffffffc020098c:	a0850513          	addi	a0,a0,-1528 # ffffffffc0206390 <commands+0x198>
        memory_base = mem_base;
ffffffffc0200990:	000c5797          	auipc	a5,0xc5
ffffffffc0200994:	7887b823          	sd	s0,1936(a5) # ffffffffc02c6120 <memory_base>
        memory_size = mem_size;
ffffffffc0200998:	000c5797          	auipc	a5,0xc5
ffffffffc020099c:	7967b823          	sd	s6,1936(a5) # ffffffffc02c6128 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02009a0:	b3ed                	j	ffffffffc020078a <dtb_init+0x186>

ffffffffc02009a2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02009a2:	000c5517          	auipc	a0,0xc5
ffffffffc02009a6:	77e53503          	ld	a0,1918(a0) # ffffffffc02c6120 <memory_base>
ffffffffc02009aa:	8082                	ret

ffffffffc02009ac <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009ac:	000c5517          	auipc	a0,0xc5
ffffffffc02009b0:	77c53503          	ld	a0,1916(a0) # ffffffffc02c6128 <memory_size>
ffffffffc02009b4:	8082                	ret

ffffffffc02009b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02009b6:	67e1                	lui	a5,0x18
ffffffffc02009b8:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xcfb0>
ffffffffc02009bc:	000c5717          	auipc	a4,0xc5
ffffffffc02009c0:	76f73e23          	sd	a5,1916(a4) # ffffffffc02c6138 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02009c4:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02009c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02009ca:	953e                	add	a0,a0,a5
ffffffffc02009cc:	4601                	li	a2,0
ffffffffc02009ce:	4881                	li	a7,0
ffffffffc02009d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02009d4:	02000793          	li	a5,32
ffffffffc02009d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02009dc:	00006517          	auipc	a0,0x6
ffffffffc02009e0:	9cc50513          	addi	a0,a0,-1588 # ffffffffc02063a8 <commands+0x1b0>
    ticks = 0;
ffffffffc02009e4:	000c5797          	auipc	a5,0xc5
ffffffffc02009e8:	7407b623          	sd	zero,1868(a5) # ffffffffc02c6130 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02009ec:	ef4ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc02009f0 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02009f0:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02009f4:	000c5797          	auipc	a5,0xc5
ffffffffc02009f8:	7447b783          	ld	a5,1860(a5) # ffffffffc02c6138 <timebase>
ffffffffc02009fc:	953e                	add	a0,a0,a5
ffffffffc02009fe:	4581                	li	a1,0
ffffffffc0200a00:	4601                	li	a2,0
ffffffffc0200a02:	4881                	li	a7,0
ffffffffc0200a04:	00000073          	ecall
ffffffffc0200a08:	8082                	ret

ffffffffc0200a0a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200a0a:	8082                	ret

ffffffffc0200a0c <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200a0c:	100027f3          	csrr	a5,sstatus
ffffffffc0200a10:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200a12:	0ff57513          	zext.b	a0,a0
ffffffffc0200a16:	e799                	bnez	a5,ffffffffc0200a24 <cons_putc+0x18>
ffffffffc0200a18:	4581                	li	a1,0
ffffffffc0200a1a:	4601                	li	a2,0
ffffffffc0200a1c:	4885                	li	a7,1
ffffffffc0200a1e:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc0200a22:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200a24:	1101                	addi	sp,sp,-32
ffffffffc0200a26:	ec06                	sd	ra,24(sp)
ffffffffc0200a28:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200a2a:	05a000ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc0200a2e:	6522                	ld	a0,8(sp)
ffffffffc0200a30:	4581                	li	a1,0
ffffffffc0200a32:	4601                	li	a2,0
ffffffffc0200a34:	4885                	li	a7,1
ffffffffc0200a36:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200a3a:	60e2                	ld	ra,24(sp)
ffffffffc0200a3c:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc0200a3e:	a081                	j	ffffffffc0200a7e <intr_enable>

ffffffffc0200a40 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200a40:	100027f3          	csrr	a5,sstatus
ffffffffc0200a44:	8b89                	andi	a5,a5,2
ffffffffc0200a46:	eb89                	bnez	a5,ffffffffc0200a58 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200a48:	4501                	li	a0,0
ffffffffc0200a4a:	4581                	li	a1,0
ffffffffc0200a4c:	4601                	li	a2,0
ffffffffc0200a4e:	4889                	li	a7,2
ffffffffc0200a50:	00000073          	ecall
ffffffffc0200a54:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200a56:	8082                	ret
int cons_getc(void) {
ffffffffc0200a58:	1101                	addi	sp,sp,-32
ffffffffc0200a5a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200a5c:	028000ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc0200a60:	4501                	li	a0,0
ffffffffc0200a62:	4581                	li	a1,0
ffffffffc0200a64:	4601                	li	a2,0
ffffffffc0200a66:	4889                	li	a7,2
ffffffffc0200a68:	00000073          	ecall
ffffffffc0200a6c:	2501                	sext.w	a0,a0
ffffffffc0200a6e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200a70:	00e000ef          	jal	ra,ffffffffc0200a7e <intr_enable>
}
ffffffffc0200a74:	60e2                	ld	ra,24(sp)
ffffffffc0200a76:	6522                	ld	a0,8(sp)
ffffffffc0200a78:	6105                	addi	sp,sp,32
ffffffffc0200a7a:	8082                	ret

ffffffffc0200a7c <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200a7c:	8082                	ret

ffffffffc0200a7e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200a7e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200a82:	8082                	ret

ffffffffc0200a84 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200a84:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200a88:	8082                	ret

ffffffffc0200a8a <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200a8a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200a8e:	00000797          	auipc	a5,0x0
ffffffffc0200a92:	62a78793          	addi	a5,a5,1578 # ffffffffc02010b8 <__alltraps>
ffffffffc0200a96:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200a9a:	000407b7          	lui	a5,0x40
ffffffffc0200a9e:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200aa2:	8082                	ret

ffffffffc0200aa4 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200aa4:	610c                	ld	a1,0(a0)
{
ffffffffc0200aa6:	1141                	addi	sp,sp,-16
ffffffffc0200aa8:	e022                	sd	s0,0(sp)
ffffffffc0200aaa:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200aac:	00006517          	auipc	a0,0x6
ffffffffc0200ab0:	91c50513          	addi	a0,a0,-1764 # ffffffffc02063c8 <commands+0x1d0>
{
ffffffffc0200ab4:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200ab6:	e2aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200aba:	640c                	ld	a1,8(s0)
ffffffffc0200abc:	00006517          	auipc	a0,0x6
ffffffffc0200ac0:	92450513          	addi	a0,a0,-1756 # ffffffffc02063e0 <commands+0x1e8>
ffffffffc0200ac4:	e1cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200ac8:	680c                	ld	a1,16(s0)
ffffffffc0200aca:	00006517          	auipc	a0,0x6
ffffffffc0200ace:	92e50513          	addi	a0,a0,-1746 # ffffffffc02063f8 <commands+0x200>
ffffffffc0200ad2:	e0eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200ad6:	6c0c                	ld	a1,24(s0)
ffffffffc0200ad8:	00006517          	auipc	a0,0x6
ffffffffc0200adc:	93850513          	addi	a0,a0,-1736 # ffffffffc0206410 <commands+0x218>
ffffffffc0200ae0:	e00ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200ae4:	700c                	ld	a1,32(s0)
ffffffffc0200ae6:	00006517          	auipc	a0,0x6
ffffffffc0200aea:	94250513          	addi	a0,a0,-1726 # ffffffffc0206428 <commands+0x230>
ffffffffc0200aee:	df2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200af2:	740c                	ld	a1,40(s0)
ffffffffc0200af4:	00006517          	auipc	a0,0x6
ffffffffc0200af8:	94c50513          	addi	a0,a0,-1716 # ffffffffc0206440 <commands+0x248>
ffffffffc0200afc:	de4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200b00:	780c                	ld	a1,48(s0)
ffffffffc0200b02:	00006517          	auipc	a0,0x6
ffffffffc0200b06:	95650513          	addi	a0,a0,-1706 # ffffffffc0206458 <commands+0x260>
ffffffffc0200b0a:	dd6ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200b0e:	7c0c                	ld	a1,56(s0)
ffffffffc0200b10:	00006517          	auipc	a0,0x6
ffffffffc0200b14:	96050513          	addi	a0,a0,-1696 # ffffffffc0206470 <commands+0x278>
ffffffffc0200b18:	dc8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200b1c:	602c                	ld	a1,64(s0)
ffffffffc0200b1e:	00006517          	auipc	a0,0x6
ffffffffc0200b22:	96a50513          	addi	a0,a0,-1686 # ffffffffc0206488 <commands+0x290>
ffffffffc0200b26:	dbaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200b2a:	642c                	ld	a1,72(s0)
ffffffffc0200b2c:	00006517          	auipc	a0,0x6
ffffffffc0200b30:	97450513          	addi	a0,a0,-1676 # ffffffffc02064a0 <commands+0x2a8>
ffffffffc0200b34:	dacff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200b38:	682c                	ld	a1,80(s0)
ffffffffc0200b3a:	00006517          	auipc	a0,0x6
ffffffffc0200b3e:	97e50513          	addi	a0,a0,-1666 # ffffffffc02064b8 <commands+0x2c0>
ffffffffc0200b42:	d9eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200b46:	6c2c                	ld	a1,88(s0)
ffffffffc0200b48:	00006517          	auipc	a0,0x6
ffffffffc0200b4c:	98850513          	addi	a0,a0,-1656 # ffffffffc02064d0 <commands+0x2d8>
ffffffffc0200b50:	d90ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200b54:	702c                	ld	a1,96(s0)
ffffffffc0200b56:	00006517          	auipc	a0,0x6
ffffffffc0200b5a:	99250513          	addi	a0,a0,-1646 # ffffffffc02064e8 <commands+0x2f0>
ffffffffc0200b5e:	d82ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200b62:	742c                	ld	a1,104(s0)
ffffffffc0200b64:	00006517          	auipc	a0,0x6
ffffffffc0200b68:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206500 <commands+0x308>
ffffffffc0200b6c:	d74ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200b70:	782c                	ld	a1,112(s0)
ffffffffc0200b72:	00006517          	auipc	a0,0x6
ffffffffc0200b76:	9a650513          	addi	a0,a0,-1626 # ffffffffc0206518 <commands+0x320>
ffffffffc0200b7a:	d66ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200b7e:	7c2c                	ld	a1,120(s0)
ffffffffc0200b80:	00006517          	auipc	a0,0x6
ffffffffc0200b84:	9b050513          	addi	a0,a0,-1616 # ffffffffc0206530 <commands+0x338>
ffffffffc0200b88:	d58ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200b8c:	604c                	ld	a1,128(s0)
ffffffffc0200b8e:	00006517          	auipc	a0,0x6
ffffffffc0200b92:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0206548 <commands+0x350>
ffffffffc0200b96:	d4aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200b9a:	644c                	ld	a1,136(s0)
ffffffffc0200b9c:	00006517          	auipc	a0,0x6
ffffffffc0200ba0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0206560 <commands+0x368>
ffffffffc0200ba4:	d3cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ba8:	684c                	ld	a1,144(s0)
ffffffffc0200baa:	00006517          	auipc	a0,0x6
ffffffffc0200bae:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0206578 <commands+0x380>
ffffffffc0200bb2:	d2eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200bb6:	6c4c                	ld	a1,152(s0)
ffffffffc0200bb8:	00006517          	auipc	a0,0x6
ffffffffc0200bbc:	9d850513          	addi	a0,a0,-1576 # ffffffffc0206590 <commands+0x398>
ffffffffc0200bc0:	d20ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200bc4:	704c                	ld	a1,160(s0)
ffffffffc0200bc6:	00006517          	auipc	a0,0x6
ffffffffc0200bca:	9e250513          	addi	a0,a0,-1566 # ffffffffc02065a8 <commands+0x3b0>
ffffffffc0200bce:	d12ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200bd2:	744c                	ld	a1,168(s0)
ffffffffc0200bd4:	00006517          	auipc	a0,0x6
ffffffffc0200bd8:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02065c0 <commands+0x3c8>
ffffffffc0200bdc:	d04ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200be0:	784c                	ld	a1,176(s0)
ffffffffc0200be2:	00006517          	auipc	a0,0x6
ffffffffc0200be6:	9f650513          	addi	a0,a0,-1546 # ffffffffc02065d8 <commands+0x3e0>
ffffffffc0200bea:	cf6ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200bee:	7c4c                	ld	a1,184(s0)
ffffffffc0200bf0:	00006517          	auipc	a0,0x6
ffffffffc0200bf4:	a0050513          	addi	a0,a0,-1536 # ffffffffc02065f0 <commands+0x3f8>
ffffffffc0200bf8:	ce8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200bfc:	606c                	ld	a1,192(s0)
ffffffffc0200bfe:	00006517          	auipc	a0,0x6
ffffffffc0200c02:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0206608 <commands+0x410>
ffffffffc0200c06:	cdaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200c0a:	646c                	ld	a1,200(s0)
ffffffffc0200c0c:	00006517          	auipc	a0,0x6
ffffffffc0200c10:	a1450513          	addi	a0,a0,-1516 # ffffffffc0206620 <commands+0x428>
ffffffffc0200c14:	cccff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200c18:	686c                	ld	a1,208(s0)
ffffffffc0200c1a:	00006517          	auipc	a0,0x6
ffffffffc0200c1e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0206638 <commands+0x440>
ffffffffc0200c22:	cbeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200c26:	6c6c                	ld	a1,216(s0)
ffffffffc0200c28:	00006517          	auipc	a0,0x6
ffffffffc0200c2c:	a2850513          	addi	a0,a0,-1496 # ffffffffc0206650 <commands+0x458>
ffffffffc0200c30:	cb0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200c34:	706c                	ld	a1,224(s0)
ffffffffc0200c36:	00006517          	auipc	a0,0x6
ffffffffc0200c3a:	a3250513          	addi	a0,a0,-1486 # ffffffffc0206668 <commands+0x470>
ffffffffc0200c3e:	ca2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200c42:	746c                	ld	a1,232(s0)
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0206680 <commands+0x488>
ffffffffc0200c4c:	c94ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200c50:	786c                	ld	a1,240(s0)
ffffffffc0200c52:	00006517          	auipc	a0,0x6
ffffffffc0200c56:	a4650513          	addi	a0,a0,-1466 # ffffffffc0206698 <commands+0x4a0>
ffffffffc0200c5a:	c86ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200c5e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200c60:	6402                	ld	s0,0(sp)
ffffffffc0200c62:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200c64:	00006517          	auipc	a0,0x6
ffffffffc0200c68:	a4c50513          	addi	a0,a0,-1460 # ffffffffc02066b0 <commands+0x4b8>
}
ffffffffc0200c6c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200c6e:	c72ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200c72 <print_trapframe>:
{
ffffffffc0200c72:	1141                	addi	sp,sp,-16
ffffffffc0200c74:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200c76:	85aa                	mv	a1,a0
{
ffffffffc0200c78:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200c7a:	00006517          	auipc	a0,0x6
ffffffffc0200c7e:	a4e50513          	addi	a0,a0,-1458 # ffffffffc02066c8 <commands+0x4d0>
{
ffffffffc0200c82:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200c84:	c5cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200c88:	8522                	mv	a0,s0
ffffffffc0200c8a:	e1bff0ef          	jal	ra,ffffffffc0200aa4 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200c8e:	10043583          	ld	a1,256(s0)
ffffffffc0200c92:	00006517          	auipc	a0,0x6
ffffffffc0200c96:	a4e50513          	addi	a0,a0,-1458 # ffffffffc02066e0 <commands+0x4e8>
ffffffffc0200c9a:	c46ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200c9e:	10843583          	ld	a1,264(s0)
ffffffffc0200ca2:	00006517          	auipc	a0,0x6
ffffffffc0200ca6:	a5650513          	addi	a0,a0,-1450 # ffffffffc02066f8 <commands+0x500>
ffffffffc0200caa:	c36ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200cae:	11043583          	ld	a1,272(s0)
ffffffffc0200cb2:	00006517          	auipc	a0,0x6
ffffffffc0200cb6:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0206710 <commands+0x518>
ffffffffc0200cba:	c26ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200cbe:	11843583          	ld	a1,280(s0)
}
ffffffffc0200cc2:	6402                	ld	s0,0(sp)
ffffffffc0200cc4:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200cc6:	00006517          	auipc	a0,0x6
ffffffffc0200cca:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0206720 <commands+0x528>
}
ffffffffc0200cce:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200cd0:	c10ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200cd4 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200cd4:	11853783          	ld	a5,280(a0)
ffffffffc0200cd8:	472d                	li	a4,11
ffffffffc0200cda:	0786                	slli	a5,a5,0x1
ffffffffc0200cdc:	8385                	srli	a5,a5,0x1
ffffffffc0200cde:	08f76a63          	bltu	a4,a5,ffffffffc0200d72 <interrupt_handler+0x9e>
ffffffffc0200ce2:	00006717          	auipc	a4,0x6
ffffffffc0200ce6:	b0670713          	addi	a4,a4,-1274 # ffffffffc02067e8 <commands+0x5f0>
ffffffffc0200cea:	078a                	slli	a5,a5,0x2
ffffffffc0200cec:	97ba                	add	a5,a5,a4
ffffffffc0200cee:	439c                	lw	a5,0(a5)
ffffffffc0200cf0:	97ba                	add	a5,a5,a4
ffffffffc0200cf2:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200cf4:	00006517          	auipc	a0,0x6
ffffffffc0200cf8:	aa450513          	addi	a0,a0,-1372 # ffffffffc0206798 <commands+0x5a0>
ffffffffc0200cfc:	be4ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200d00:	00006517          	auipc	a0,0x6
ffffffffc0200d04:	a7850513          	addi	a0,a0,-1416 # ffffffffc0206778 <commands+0x580>
ffffffffc0200d08:	bd8ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200d0c:	00006517          	auipc	a0,0x6
ffffffffc0200d10:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0206738 <commands+0x540>
ffffffffc0200d14:	bccff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200d18:	00006517          	auipc	a0,0x6
ffffffffc0200d1c:	a4050513          	addi	a0,a0,-1472 # ffffffffc0206758 <commands+0x560>
ffffffffc0200d20:	bc0ff06f          	j	ffffffffc02000e0 <cprintf>
{
ffffffffc0200d24:	1141                	addi	sp,sp,-16
ffffffffc0200d26:	e406                	sd	ra,8(sp)
        // "All bits besides SSIP and USIP in the sip register are
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // cprintf("Supervisor timer interrupt\n");
        clock_set_next_event();
ffffffffc0200d28:	cc9ff0ef          	jal	ra,ffffffffc02009f0 <clock_set_next_event>
        ticks++;
ffffffffc0200d2c:	000c5797          	auipc	a5,0xc5
ffffffffc0200d30:	40478793          	addi	a5,a5,1028 # ffffffffc02c6130 <ticks>
ffffffffc0200d34:	6398                	ld	a4,0(a5)
ffffffffc0200d36:	0705                	addi	a4,a4,1
ffffffffc0200d38:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0)
ffffffffc0200d3a:	639c                	ld	a5,0(a5)
ffffffffc0200d3c:	06400713          	li	a4,100
ffffffffc0200d40:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200d44:	cb85                	beqz	a5,ffffffffc0200d74 <interrupt_handler+0xa0>
            if (tick_prints >= 10)
            {
                sbi_shutdown();
            }
        }
        if (current != NULL && current != idleproc)
ffffffffc0200d46:	000c5797          	auipc	a5,0xc5
ffffffffc0200d4a:	43a7b783          	ld	a5,1082(a5) # ffffffffc02c6180 <current>
ffffffffc0200d4e:	cb89                	beqz	a5,ffffffffc0200d60 <interrupt_handler+0x8c>
ffffffffc0200d50:	000c5717          	auipc	a4,0xc5
ffffffffc0200d54:	43873703          	ld	a4,1080(a4) # ffffffffc02c6188 <idleproc>
ffffffffc0200d58:	00e78463          	beq	a5,a4,ffffffffc0200d60 <interrupt_handler+0x8c>
        {
            current->need_resched = 1;
ffffffffc0200d5c:	4705                	li	a4,1
ffffffffc0200d5e:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d60:	60a2                	ld	ra,8(sp)
ffffffffc0200d62:	0141                	addi	sp,sp,16
ffffffffc0200d64:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200d66:	00006517          	auipc	a0,0x6
ffffffffc0200d6a:	a6250513          	addi	a0,a0,-1438 # ffffffffc02067c8 <commands+0x5d0>
ffffffffc0200d6e:	b72ff06f          	j	ffffffffc02000e0 <cprintf>
        print_trapframe(tf);
ffffffffc0200d72:	b701                	j	ffffffffc0200c72 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200d74:	06400593          	li	a1,100
ffffffffc0200d78:	00006517          	auipc	a0,0x6
ffffffffc0200d7c:	a4050513          	addi	a0,a0,-1472 # ffffffffc02067b8 <commands+0x5c0>
ffffffffc0200d80:	b60ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
            tick_prints++;
ffffffffc0200d84:	000c5717          	auipc	a4,0xc5
ffffffffc0200d88:	3bc70713          	addi	a4,a4,956 # ffffffffc02c6140 <tick_prints>
ffffffffc0200d8c:	631c                	ld	a5,0(a4)
            if (tick_prints >= 10)
ffffffffc0200d8e:	46a5                	li	a3,9
            tick_prints++;
ffffffffc0200d90:	0785                	addi	a5,a5,1
ffffffffc0200d92:	e31c                	sd	a5,0(a4)
            if (tick_prints >= 10)
ffffffffc0200d94:	faf6f9e3          	bgeu	a3,a5,ffffffffc0200d46 <interrupt_handler+0x72>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200d98:	4501                	li	a0,0
ffffffffc0200d9a:	4581                	li	a1,0
ffffffffc0200d9c:	4601                	li	a2,0
ffffffffc0200d9e:	48a1                	li	a7,8
ffffffffc0200da0:	00000073          	ecall
}
ffffffffc0200da4:	b74d                	j	ffffffffc0200d46 <interrupt_handler+0x72>

ffffffffc0200da6 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    bool in_kernel = trap_in_kernel(tf);
ffffffffc0200da6:	11853783          	ld	a5,280(a0)
{
ffffffffc0200daa:	1101                	addi	sp,sp,-32
ffffffffc0200dac:	e822                	sd	s0,16(sp)
ffffffffc0200dae:	e426                	sd	s1,8(sp)
ffffffffc0200db0:	ec06                	sd	ra,24(sp)
ffffffffc0200db2:	46bd                	li	a3,15
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200db4:	10053483          	ld	s1,256(a0)
{
ffffffffc0200db8:	842a                	mv	s0,a0
    switch (tf->cause)
ffffffffc0200dba:	1af6e263          	bltu	a3,a5,ffffffffc0200f5e <exception_handler+0x1b8>
ffffffffc0200dbe:	00006697          	auipc	a3,0x6
ffffffffc0200dc2:	d1a68693          	addi	a3,a3,-742 # ffffffffc0206ad8 <commands+0x8e0>
ffffffffc0200dc6:	078a                	slli	a5,a5,0x2
ffffffffc0200dc8:	97b6                	add	a5,a5,a3
ffffffffc0200dca:	439c                	lw	a5,0(a5)
ffffffffc0200dcc:	1004f493          	andi	s1,s1,256
ffffffffc0200dd0:	00903733          	snez	a4,s1
ffffffffc0200dd4:	97b6                	add	a5,a5,a3
ffffffffc0200dd6:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200dd8:	00006517          	auipc	a0,0x6
ffffffffc0200ddc:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206900 <commands+0x708>
ffffffffc0200de0:	b00ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        tf->epc += 4;
ffffffffc0200de4:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200de8:	60e2                	ld	ra,24(sp)
ffffffffc0200dea:	64a2                	ld	s1,8(sp)
        tf->epc += 4;
ffffffffc0200dec:	0791                	addi	a5,a5,4
ffffffffc0200dee:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200df2:	6442                	ld	s0,16(sp)
ffffffffc0200df4:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200df6:	2d30406f          	j	ffffffffc02058c8 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200dfa:	00006517          	auipc	a0,0x6
ffffffffc0200dfe:	b2650513          	addi	a0,a0,-1242 # ffffffffc0206920 <commands+0x728>
}
ffffffffc0200e02:	6442                	ld	s0,16(sp)
ffffffffc0200e04:	60e2                	ld	ra,24(sp)
ffffffffc0200e06:	64a2                	ld	s1,8(sp)
ffffffffc0200e08:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200e0a:	ad6ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200e0e:	00006517          	auipc	a0,0x6
ffffffffc0200e12:	b3250513          	addi	a0,a0,-1230 # ffffffffc0206940 <commands+0x748>
ffffffffc0200e16:	b7f5                	j	ffffffffc0200e02 <exception_handler+0x5c>
        if (pgfault_report_left-- > 0)
ffffffffc0200e18:	000c1697          	auipc	a3,0xc1
ffffffffc0200e1c:	ea068693          	addi	a3,a3,-352 # ffffffffc02c1cb8 <pgfault_report_left>
ffffffffc0200e20:	429c                	lw	a5,0(a3)
ffffffffc0200e22:	fff7861b          	addiw	a2,a5,-1
ffffffffc0200e26:	c290                	sw	a2,0(a3)
ffffffffc0200e28:	1af05e63          	blez	a5,ffffffffc0200fe4 <exception_handler+0x23e>
            cprintf("Load page fault: pid %d epc=0x%lx badva=0x%lx in_kernel=%d\n", current ? current->pid : -1, tf->epc, tf->tval, in_kernel);
ffffffffc0200e2c:	000c5797          	auipc	a5,0xc5
ffffffffc0200e30:	3547b783          	ld	a5,852(a5) # ffffffffc02c6180 <current>
ffffffffc0200e34:	55fd                	li	a1,-1
ffffffffc0200e36:	c391                	beqz	a5,ffffffffc0200e3a <exception_handler+0x94>
ffffffffc0200e38:	43cc                	lw	a1,4(a5)
ffffffffc0200e3a:	11043683          	ld	a3,272(s0)
ffffffffc0200e3e:	10843603          	ld	a2,264(s0)
ffffffffc0200e42:	00006517          	auipc	a0,0x6
ffffffffc0200e46:	b9650513          	addi	a0,a0,-1130 # ffffffffc02069d8 <commands+0x7e0>
ffffffffc0200e4a:	a96ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        if (!in_kernel && current != NULL)
ffffffffc0200e4e:	e4e9                	bnez	s1,ffffffffc0200f18 <exception_handler+0x172>
ffffffffc0200e50:	000c5797          	auipc	a5,0xc5
ffffffffc0200e54:	3307b783          	ld	a5,816(a5) # ffffffffc02c6180 <current>
ffffffffc0200e58:	c3e1                	beqz	a5,ffffffffc0200f18 <exception_handler+0x172>
            ret = do_pgfault(current->mm, 0, tf->tval);
ffffffffc0200e5a:	11043603          	ld	a2,272(s0)
ffffffffc0200e5e:	7788                	ld	a0,40(a5)
ffffffffc0200e60:	4581                	li	a1,0
ffffffffc0200e62:	6bf010ef          	jal	ra,ffffffffc0202d20 <do_pgfault>
            if (ret != 0)
ffffffffc0200e66:	c94d                	beqz	a0,ffffffffc0200f18 <exception_handler+0x172>
                cprintf("pgfault failed: %e\n", ret);
ffffffffc0200e68:	85aa                	mv	a1,a0
ffffffffc0200e6a:	00006517          	auipc	a0,0x6
ffffffffc0200e6e:	bc650513          	addi	a0,a0,-1082 # ffffffffc0206a30 <commands+0x838>
ffffffffc0200e72:	a6eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
                panic("Unhandled load pgfault");
ffffffffc0200e76:	00006617          	auipc	a2,0x6
ffffffffc0200e7a:	bd260613          	addi	a2,a2,-1070 # ffffffffc0206a48 <commands+0x850>
ffffffffc0200e7e:	0f600593          	li	a1,246
ffffffffc0200e82:	00006517          	auipc	a0,0x6
ffffffffc0200e86:	a4e50513          	addi	a0,a0,-1458 # ffffffffc02068d0 <commands+0x6d8>
ffffffffc0200e8a:	b94ff0ef          	jal	ra,ffffffffc020021e <__panic>
        if (pgfault_report_left-- > 0)
ffffffffc0200e8e:	000c1697          	auipc	a3,0xc1
ffffffffc0200e92:	e2a68693          	addi	a3,a3,-470 # ffffffffc02c1cb8 <pgfault_report_left>
ffffffffc0200e96:	429c                	lw	a5,0(a3)
ffffffffc0200e98:	fff7861b          	addiw	a2,a5,-1
ffffffffc0200e9c:	c290                	sw	a2,0(a3)
ffffffffc0200e9e:	12f05b63          	blez	a5,ffffffffc0200fd4 <exception_handler+0x22e>
            cprintf("Store/AMO page fault: pid %d epc=0x%lx badva=0x%lx in_kernel=%d\n", current ? current->pid : -1, tf->epc, tf->tval, in_kernel);
ffffffffc0200ea2:	000c5797          	auipc	a5,0xc5
ffffffffc0200ea6:	2de7b783          	ld	a5,734(a5) # ffffffffc02c6180 <current>
ffffffffc0200eaa:	55fd                	li	a1,-1
ffffffffc0200eac:	c391                	beqz	a5,ffffffffc0200eb0 <exception_handler+0x10a>
ffffffffc0200eae:	43cc                	lw	a1,4(a5)
ffffffffc0200eb0:	11043683          	ld	a3,272(s0)
ffffffffc0200eb4:	10843603          	ld	a2,264(s0)
ffffffffc0200eb8:	00006517          	auipc	a0,0x6
ffffffffc0200ebc:	ba850513          	addi	a0,a0,-1112 # ffffffffc0206a60 <commands+0x868>
ffffffffc0200ec0:	a20ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        if (!in_kernel && current != NULL)
ffffffffc0200ec4:	e8b1                	bnez	s1,ffffffffc0200f18 <exception_handler+0x172>
ffffffffc0200ec6:	000c5797          	auipc	a5,0xc5
ffffffffc0200eca:	2ba7b783          	ld	a5,698(a5) # ffffffffc02c6180 <current>
ffffffffc0200ece:	c7a9                	beqz	a5,ffffffffc0200f18 <exception_handler+0x172>
            ret = do_pgfault(current->mm, PTE_W, tf->tval);
ffffffffc0200ed0:	11043603          	ld	a2,272(s0)
ffffffffc0200ed4:	7788                	ld	a0,40(a5)
ffffffffc0200ed6:	4591                	li	a1,4
ffffffffc0200ed8:	649010ef          	jal	ra,ffffffffc0202d20 <do_pgfault>
            if (ret != 0)
ffffffffc0200edc:	cd15                	beqz	a0,ffffffffc0200f18 <exception_handler+0x172>
                cprintf("pgfault failed: %e\n", ret);
ffffffffc0200ede:	85aa                	mv	a1,a0
ffffffffc0200ee0:	00006517          	auipc	a0,0x6
ffffffffc0200ee4:	b5050513          	addi	a0,a0,-1200 # ffffffffc0206a30 <commands+0x838>
ffffffffc0200ee8:	9f8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
                panic("Unhandled store pgfault");
ffffffffc0200eec:	00006617          	auipc	a2,0x6
ffffffffc0200ef0:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206ac0 <commands+0x8c8>
ffffffffc0200ef4:	10900593          	li	a1,265
ffffffffc0200ef8:	00006517          	auipc	a0,0x6
ffffffffc0200efc:	9d850513          	addi	a0,a0,-1576 # ffffffffc02068d0 <commands+0x6d8>
ffffffffc0200f00:	b1eff0ef          	jal	ra,ffffffffc020021e <__panic>
        cprintf("Breakpoint\n");
ffffffffc0200f04:	00006517          	auipc	a0,0x6
ffffffffc0200f08:	96c50513          	addi	a0,a0,-1684 # ffffffffc0206870 <commands+0x678>
ffffffffc0200f0c:	9d4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200f10:	6458                	ld	a4,136(s0)
ffffffffc0200f12:	47a9                	li	a5,10
ffffffffc0200f14:	0ef70063          	beq	a4,a5,ffffffffc0200ff4 <exception_handler+0x24e>
}
ffffffffc0200f18:	60e2                	ld	ra,24(sp)
ffffffffc0200f1a:	6442                	ld	s0,16(sp)
ffffffffc0200f1c:	64a2                	ld	s1,8(sp)
ffffffffc0200f1e:	6105                	addi	sp,sp,32
ffffffffc0200f20:	8082                	ret
        cprintf("Instruction access fault\n");
ffffffffc0200f22:	00006517          	auipc	a0,0x6
ffffffffc0200f26:	91650513          	addi	a0,a0,-1770 # ffffffffc0206838 <commands+0x640>
ffffffffc0200f2a:	bde1                	j	ffffffffc0200e02 <exception_handler+0x5c>
        cprintf("Illegal instruction\n");
ffffffffc0200f2c:	00006517          	auipc	a0,0x6
ffffffffc0200f30:	92c50513          	addi	a0,a0,-1748 # ffffffffc0206858 <commands+0x660>
ffffffffc0200f34:	b5f9                	j	ffffffffc0200e02 <exception_handler+0x5c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200f36:	00006517          	auipc	a0,0x6
ffffffffc0200f3a:	8e250513          	addi	a0,a0,-1822 # ffffffffc0206818 <commands+0x620>
ffffffffc0200f3e:	b5d1                	j	ffffffffc0200e02 <exception_handler+0x5c>
        cprintf("Load access fault\n");
ffffffffc0200f40:	00006517          	auipc	a0,0x6
ffffffffc0200f44:	96050513          	addi	a0,a0,-1696 # ffffffffc02068a0 <commands+0x6a8>
ffffffffc0200f48:	bd6d                	j	ffffffffc0200e02 <exception_handler+0x5c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200f4a:	00006517          	auipc	a0,0x6
ffffffffc0200f4e:	99e50513          	addi	a0,a0,-1634 # ffffffffc02068e8 <commands+0x6f0>
ffffffffc0200f52:	bd45                	j	ffffffffc0200e02 <exception_handler+0x5c>
        cprintf("Load address misaligned\n");
ffffffffc0200f54:	00006517          	auipc	a0,0x6
ffffffffc0200f58:	92c50513          	addi	a0,a0,-1748 # ffffffffc0206880 <commands+0x688>
ffffffffc0200f5c:	b55d                	j	ffffffffc0200e02 <exception_handler+0x5c>
        print_trapframe(tf);
ffffffffc0200f5e:	8522                	mv	a0,s0
}
ffffffffc0200f60:	6442                	ld	s0,16(sp)
ffffffffc0200f62:	60e2                	ld	ra,24(sp)
ffffffffc0200f64:	64a2                	ld	s1,8(sp)
ffffffffc0200f66:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200f68:	b329                	j	ffffffffc0200c72 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200f6a:	00006617          	auipc	a2,0x6
ffffffffc0200f6e:	94e60613          	addi	a2,a2,-1714 # ffffffffc02068b8 <commands+0x6c0>
ffffffffc0200f72:	0c600593          	li	a1,198
ffffffffc0200f76:	00006517          	auipc	a0,0x6
ffffffffc0200f7a:	95a50513          	addi	a0,a0,-1702 # ffffffffc02068d0 <commands+0x6d8>
ffffffffc0200f7e:	aa0ff0ef          	jal	ra,ffffffffc020021e <__panic>
        if (pgfault_report_left-- > 0)
ffffffffc0200f82:	000c1697          	auipc	a3,0xc1
ffffffffc0200f86:	d3668693          	addi	a3,a3,-714 # ffffffffc02c1cb8 <pgfault_report_left>
ffffffffc0200f8a:	429c                	lw	a5,0(a3)
ffffffffc0200f8c:	fff7861b          	addiw	a2,a5,-1
ffffffffc0200f90:	c290                	sw	a2,0(a3)
ffffffffc0200f92:	08f05763          	blez	a5,ffffffffc0201020 <exception_handler+0x27a>
            cprintf("Instruction page fault: pid %d epc=0x%lx badva=0x%lx in_kernel=%d\n", current ? current->pid : -1, tf->epc, tf->tval, in_kernel);
ffffffffc0200f96:	000c5797          	auipc	a5,0xc5
ffffffffc0200f9a:	1ea7b783          	ld	a5,490(a5) # ffffffffc02c6180 <current>
ffffffffc0200f9e:	cfbd                	beqz	a5,ffffffffc020101c <exception_handler+0x276>
ffffffffc0200fa0:	43cc                	lw	a1,4(a5)
ffffffffc0200fa2:	11043683          	ld	a3,272(s0)
ffffffffc0200fa6:	10843603          	ld	a2,264(s0)
ffffffffc0200faa:	00006517          	auipc	a0,0x6
ffffffffc0200fae:	9b650513          	addi	a0,a0,-1610 # ffffffffc0206960 <commands+0x768>
ffffffffc0200fb2:	92eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        print_trapframe(tf);
ffffffffc0200fb6:	8522                	mv	a0,s0
ffffffffc0200fb8:	cbbff0ef          	jal	ra,ffffffffc0200c72 <print_trapframe>
        panic("Instruction page fault");
ffffffffc0200fbc:	00006617          	auipc	a2,0x6
ffffffffc0200fc0:	a0460613          	addi	a2,a2,-1532 # ffffffffc02069c0 <commands+0x7c8>
ffffffffc0200fc4:	0e500593          	li	a1,229
ffffffffc0200fc8:	00006517          	auipc	a0,0x6
ffffffffc0200fcc:	90850513          	addi	a0,a0,-1784 # ffffffffc02068d0 <commands+0x6d8>
ffffffffc0200fd0:	a4eff0ef          	jal	ra,ffffffffc020021e <__panic>
            cprintf("Store/AMO page fault\n");
ffffffffc0200fd4:	00006517          	auipc	a0,0x6
ffffffffc0200fd8:	ad450513          	addi	a0,a0,-1324 # ffffffffc0206aa8 <commands+0x8b0>
ffffffffc0200fdc:	904ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        if (!in_kernel && current != NULL)
ffffffffc0200fe0:	fc85                	bnez	s1,ffffffffc0200f18 <exception_handler+0x172>
ffffffffc0200fe2:	b5d5                	j	ffffffffc0200ec6 <exception_handler+0x120>
            cprintf("Load page fault\n");
ffffffffc0200fe4:	00006517          	auipc	a0,0x6
ffffffffc0200fe8:	a3450513          	addi	a0,a0,-1484 # ffffffffc0206a18 <commands+0x820>
ffffffffc0200fec:	8f4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        if (!in_kernel && current != NULL)
ffffffffc0200ff0:	f485                	bnez	s1,ffffffffc0200f18 <exception_handler+0x172>
ffffffffc0200ff2:	bdb9                	j	ffffffffc0200e50 <exception_handler+0xaa>
            tf->epc += 4;
ffffffffc0200ff4:	10843783          	ld	a5,264(s0)
ffffffffc0200ff8:	0791                	addi	a5,a5,4
ffffffffc0200ffa:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200ffe:	0cb040ef          	jal	ra,ffffffffc02058c8 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0201002:	000c5797          	auipc	a5,0xc5
ffffffffc0201006:	17e7b783          	ld	a5,382(a5) # ffffffffc02c6180 <current>
ffffffffc020100a:	6b9c                	ld	a5,16(a5)
ffffffffc020100c:	8522                	mv	a0,s0
}
ffffffffc020100e:	6442                	ld	s0,16(sp)
ffffffffc0201010:	60e2                	ld	ra,24(sp)
ffffffffc0201012:	64a2                	ld	s1,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0201014:	6589                	lui	a1,0x2
ffffffffc0201016:	95be                	add	a1,a1,a5
}
ffffffffc0201018:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc020101a:	a2b5                	j	ffffffffc0201186 <kernel_execve_ret>
            cprintf("Instruction page fault: pid %d epc=0x%lx badva=0x%lx in_kernel=%d\n", current ? current->pid : -1, tf->epc, tf->tval, in_kernel);
ffffffffc020101c:	55fd                	li	a1,-1
ffffffffc020101e:	b751                	j	ffffffffc0200fa2 <exception_handler+0x1fc>
            cprintf("Instruction page fault\n");
ffffffffc0201020:	00006517          	auipc	a0,0x6
ffffffffc0201024:	98850513          	addi	a0,a0,-1656 # ffffffffc02069a8 <commands+0x7b0>
ffffffffc0201028:	8b8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc020102c:	b769                	j	ffffffffc0200fb6 <exception_handler+0x210>

ffffffffc020102e <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc020102e:	1101                	addi	sp,sp,-32
ffffffffc0201030:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0201032:	000c5417          	auipc	s0,0xc5
ffffffffc0201036:	14e40413          	addi	s0,s0,334 # ffffffffc02c6180 <current>
ffffffffc020103a:	6018                	ld	a4,0(s0)
{
ffffffffc020103c:	ec06                	sd	ra,24(sp)
ffffffffc020103e:	e426                	sd	s1,8(sp)
ffffffffc0201040:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0201042:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0201046:	cf1d                	beqz	a4,ffffffffc0201084 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0201048:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc020104c:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0201050:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0201052:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0201056:	0206c463          	bltz	a3,ffffffffc020107e <trap+0x50>
        exception_handler(tf);
ffffffffc020105a:	d4dff0ef          	jal	ra,ffffffffc0200da6 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc020105e:	601c                	ld	a5,0(s0)
ffffffffc0201060:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0201064:	e499                	bnez	s1,ffffffffc0201072 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0201066:	0b07a703          	lw	a4,176(a5)
ffffffffc020106a:	8b05                	andi	a4,a4,1
ffffffffc020106c:	e329                	bnez	a4,ffffffffc02010ae <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc020106e:	6f9c                	ld	a5,24(a5)
ffffffffc0201070:	eb85                	bnez	a5,ffffffffc02010a0 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0201072:	60e2                	ld	ra,24(sp)
ffffffffc0201074:	6442                	ld	s0,16(sp)
ffffffffc0201076:	64a2                	ld	s1,8(sp)
ffffffffc0201078:	6902                	ld	s2,0(sp)
ffffffffc020107a:	6105                	addi	sp,sp,32
ffffffffc020107c:	8082                	ret
        interrupt_handler(tf);
ffffffffc020107e:	c57ff0ef          	jal	ra,ffffffffc0200cd4 <interrupt_handler>
ffffffffc0201082:	bff1                	j	ffffffffc020105e <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0201084:	0006c863          	bltz	a3,ffffffffc0201094 <trap+0x66>
}
ffffffffc0201088:	6442                	ld	s0,16(sp)
ffffffffc020108a:	60e2                	ld	ra,24(sp)
ffffffffc020108c:	64a2                	ld	s1,8(sp)
ffffffffc020108e:	6902                	ld	s2,0(sp)
ffffffffc0201090:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0201092:	bb11                	j	ffffffffc0200da6 <exception_handler>
}
ffffffffc0201094:	6442                	ld	s0,16(sp)
ffffffffc0201096:	60e2                	ld	ra,24(sp)
ffffffffc0201098:	64a2                	ld	s1,8(sp)
ffffffffc020109a:	6902                	ld	s2,0(sp)
ffffffffc020109c:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc020109e:	b91d                	j	ffffffffc0200cd4 <interrupt_handler>
}
ffffffffc02010a0:	6442                	ld	s0,16(sp)
ffffffffc02010a2:	60e2                	ld	ra,24(sp)
ffffffffc02010a4:	64a2                	ld	s1,8(sp)
ffffffffc02010a6:	6902                	ld	s2,0(sp)
ffffffffc02010a8:	6105                	addi	sp,sp,32
                schedule();
ffffffffc02010aa:	6e00406f          	j	ffffffffc020578a <schedule>
                do_exit(-E_KILLED);
ffffffffc02010ae:	555d                	li	a0,-9
ffffffffc02010b0:	283030ef          	jal	ra,ffffffffc0204b32 <do_exit>
            if (current->need_resched)
ffffffffc02010b4:	601c                	ld	a5,0(s0)
ffffffffc02010b6:	bf65                	j	ffffffffc020106e <trap+0x40>

ffffffffc02010b8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02010b8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc02010bc:	00011463          	bnez	sp,ffffffffc02010c4 <__alltraps+0xc>
ffffffffc02010c0:	14002173          	csrr	sp,sscratch
ffffffffc02010c4:	712d                	addi	sp,sp,-288
ffffffffc02010c6:	e002                	sd	zero,0(sp)
ffffffffc02010c8:	e406                	sd	ra,8(sp)
ffffffffc02010ca:	ec0e                	sd	gp,24(sp)
ffffffffc02010cc:	f012                	sd	tp,32(sp)
ffffffffc02010ce:	f416                	sd	t0,40(sp)
ffffffffc02010d0:	f81a                	sd	t1,48(sp)
ffffffffc02010d2:	fc1e                	sd	t2,56(sp)
ffffffffc02010d4:	e0a2                	sd	s0,64(sp)
ffffffffc02010d6:	e4a6                	sd	s1,72(sp)
ffffffffc02010d8:	e8aa                	sd	a0,80(sp)
ffffffffc02010da:	ecae                	sd	a1,88(sp)
ffffffffc02010dc:	f0b2                	sd	a2,96(sp)
ffffffffc02010de:	f4b6                	sd	a3,104(sp)
ffffffffc02010e0:	f8ba                	sd	a4,112(sp)
ffffffffc02010e2:	fcbe                	sd	a5,120(sp)
ffffffffc02010e4:	e142                	sd	a6,128(sp)
ffffffffc02010e6:	e546                	sd	a7,136(sp)
ffffffffc02010e8:	e94a                	sd	s2,144(sp)
ffffffffc02010ea:	ed4e                	sd	s3,152(sp)
ffffffffc02010ec:	f152                	sd	s4,160(sp)
ffffffffc02010ee:	f556                	sd	s5,168(sp)
ffffffffc02010f0:	f95a                	sd	s6,176(sp)
ffffffffc02010f2:	fd5e                	sd	s7,184(sp)
ffffffffc02010f4:	e1e2                	sd	s8,192(sp)
ffffffffc02010f6:	e5e6                	sd	s9,200(sp)
ffffffffc02010f8:	e9ea                	sd	s10,208(sp)
ffffffffc02010fa:	edee                	sd	s11,216(sp)
ffffffffc02010fc:	f1f2                	sd	t3,224(sp)
ffffffffc02010fe:	f5f6                	sd	t4,232(sp)
ffffffffc0201100:	f9fa                	sd	t5,240(sp)
ffffffffc0201102:	fdfe                	sd	t6,248(sp)
ffffffffc0201104:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0201108:	100024f3          	csrr	s1,sstatus
ffffffffc020110c:	14102973          	csrr	s2,sepc
ffffffffc0201110:	143029f3          	csrr	s3,stval
ffffffffc0201114:	14202a73          	csrr	s4,scause
ffffffffc0201118:	e822                	sd	s0,16(sp)
ffffffffc020111a:	e226                	sd	s1,256(sp)
ffffffffc020111c:	e64a                	sd	s2,264(sp)
ffffffffc020111e:	ea4e                	sd	s3,272(sp)
ffffffffc0201120:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0201122:	850a                	mv	a0,sp
    jal trap
ffffffffc0201124:	f0bff0ef          	jal	ra,ffffffffc020102e <trap>

ffffffffc0201128 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0201128:	6492                	ld	s1,256(sp)
ffffffffc020112a:	6932                	ld	s2,264(sp)
ffffffffc020112c:	1004f413          	andi	s0,s1,256
ffffffffc0201130:	e401                	bnez	s0,ffffffffc0201138 <__trapret+0x10>
ffffffffc0201132:	1200                	addi	s0,sp,288
ffffffffc0201134:	14041073          	csrw	sscratch,s0
ffffffffc0201138:	10049073          	csrw	sstatus,s1
ffffffffc020113c:	14191073          	csrw	sepc,s2
ffffffffc0201140:	60a2                	ld	ra,8(sp)
ffffffffc0201142:	61e2                	ld	gp,24(sp)
ffffffffc0201144:	7202                	ld	tp,32(sp)
ffffffffc0201146:	72a2                	ld	t0,40(sp)
ffffffffc0201148:	7342                	ld	t1,48(sp)
ffffffffc020114a:	73e2                	ld	t2,56(sp)
ffffffffc020114c:	6406                	ld	s0,64(sp)
ffffffffc020114e:	64a6                	ld	s1,72(sp)
ffffffffc0201150:	6546                	ld	a0,80(sp)
ffffffffc0201152:	65e6                	ld	a1,88(sp)
ffffffffc0201154:	7606                	ld	a2,96(sp)
ffffffffc0201156:	76a6                	ld	a3,104(sp)
ffffffffc0201158:	7746                	ld	a4,112(sp)
ffffffffc020115a:	77e6                	ld	a5,120(sp)
ffffffffc020115c:	680a                	ld	a6,128(sp)
ffffffffc020115e:	68aa                	ld	a7,136(sp)
ffffffffc0201160:	694a                	ld	s2,144(sp)
ffffffffc0201162:	69ea                	ld	s3,152(sp)
ffffffffc0201164:	7a0a                	ld	s4,160(sp)
ffffffffc0201166:	7aaa                	ld	s5,168(sp)
ffffffffc0201168:	7b4a                	ld	s6,176(sp)
ffffffffc020116a:	7bea                	ld	s7,184(sp)
ffffffffc020116c:	6c0e                	ld	s8,192(sp)
ffffffffc020116e:	6cae                	ld	s9,200(sp)
ffffffffc0201170:	6d4e                	ld	s10,208(sp)
ffffffffc0201172:	6dee                	ld	s11,216(sp)
ffffffffc0201174:	7e0e                	ld	t3,224(sp)
ffffffffc0201176:	7eae                	ld	t4,232(sp)
ffffffffc0201178:	7f4e                	ld	t5,240(sp)
ffffffffc020117a:	7fee                	ld	t6,248(sp)
ffffffffc020117c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc020117e:	10200073          	sret

ffffffffc0201182 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0201182:	812a                	mv	sp,a0
    j __trapret
ffffffffc0201184:	b755                	j	ffffffffc0201128 <__trapret>

ffffffffc0201186 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0201186:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x82a0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc020118a:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc020118e:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0201192:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0201196:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc020119a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc020119e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc02011a2:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc02011a6:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc02011aa:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc02011ac:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc02011ae:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc02011b0:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc02011b2:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc02011b4:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc02011b6:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc02011b8:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc02011ba:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc02011bc:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc02011be:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc02011c0:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc02011c2:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc02011c4:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc02011c6:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc02011c8:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc02011ca:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc02011cc:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc02011ce:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc02011d0:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc02011d2:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc02011d4:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc02011d6:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc02011d8:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc02011da:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc02011dc:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc02011de:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc02011e0:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc02011e2:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc02011e4:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc02011e6:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc02011e8:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc02011ea:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc02011ec:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc02011ee:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc02011f0:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc02011f2:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc02011f4:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc02011f6:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc02011f8:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc02011fa:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc02011fc:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc02011fe:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201200:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0201202:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201204:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0201206:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201208:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc020120a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc020120c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc020120e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201210:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0201212:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201214:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201216:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201218:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc020121a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc020121c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020121e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201220:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201222:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201224:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201226:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201228:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020122a:	812e                	mv	sp,a1
ffffffffc020122c:	bdf5                	j	ffffffffc0201128 <__trapret>

ffffffffc020122e <dirtycow_set_mode>:
// dirtycow_set_mode - 切换 Dirty COW 演示模式
//   enable_bug = true  -> 进入漏洞复现模式（允许越权写）
//   enable_bug = false -> 进入修复模式（写前复制）
void dirtycow_set_mode(bool enable_bug)
{
    dirtycow_stats.emulate_bug = enable_bug ? 1 : 0;
ffffffffc020122e:	00a03533          	snez	a0,a0
ffffffffc0201232:	000c1797          	auipc	a5,0xc1
ffffffffc0201236:	eaa7b323          	sd	a0,-346(a5) # ffffffffc02c20d8 <dirtycow_stats>
}
ffffffffc020123a:	8082                	ret

ffffffffc020123c <dirtycow_mode_string>:

// dirtycow_mode_string - 返回 "buggy"/"fixed"，供日志/命令行显示
const char *dirtycow_mode_string(void)
{
    return dirtycow_stats.emulate_bug ? "buggy" : "fixed";
ffffffffc020123c:	000c1797          	auipc	a5,0xc1
ffffffffc0201240:	e9c7b783          	ld	a5,-356(a5) # ffffffffc02c20d8 <dirtycow_stats>
ffffffffc0201244:	00006517          	auipc	a0,0x6
ffffffffc0201248:	8d450513          	addi	a0,a0,-1836 # ffffffffc0206b18 <commands+0x920>
ffffffffc020124c:	e789                	bnez	a5,ffffffffc0201256 <dirtycow_mode_string+0x1a>
ffffffffc020124e:	00006517          	auipc	a0,0x6
ffffffffc0201252:	8d250513          	addi	a0,a0,-1838 # ffffffffc0206b20 <commands+0x928>
}
ffffffffc0201256:	8082                	ret

ffffffffc0201258 <dirtycow_mempoke>:
 *     3. 调用 dirtycow_user_mem_write 逐页写入（内部会根据模式触发/跳过 COW）
 *     4. 用 goto out 统一释放临时缓冲，避免重复代码
 */
int dirtycow_mempoke(struct mm_struct *mm, uintptr_t dst, const void *src, size_t len)
{
    if (mm == NULL)
ffffffffc0201258:	16050e63          	beqz	a0,ffffffffc02013d4 <dirtycow_mempoke+0x17c>
{
ffffffffc020125c:	7119                	addi	sp,sp,-128
ffffffffc020125e:	ecce                	sd	s3,88(sp)
ffffffffc0201260:	fc86                	sd	ra,120(sp)
ffffffffc0201262:	f8a2                	sd	s0,112(sp)
ffffffffc0201264:	f4a6                	sd	s1,104(sp)
ffffffffc0201266:	f0ca                	sd	s2,96(sp)
ffffffffc0201268:	e8d2                	sd	s4,80(sp)
ffffffffc020126a:	e4d6                	sd	s5,72(sp)
ffffffffc020126c:	e0da                	sd	s6,64(sp)
ffffffffc020126e:	fc5e                	sd	s7,56(sp)
ffffffffc0201270:	f862                	sd	s8,48(sp)
ffffffffc0201272:	f466                	sd	s9,40(sp)
ffffffffc0201274:	f06a                	sd	s10,32(sp)
ffffffffc0201276:	ec6e                	sd	s11,24(sp)
ffffffffc0201278:	89b6                	mv	s3,a3
    {
        return -E_INVAL;
    }
    if (len == 0)
    {
        return 0;
ffffffffc020127a:	4701                	li	a4,0
    if (len == 0)
ffffffffc020127c:	e28d                	bnez	a3,ffffffffc020129e <dirtycow_mempoke+0x46>
    ret = dirtycow_user_mem_write(mm, dst, kbuf, len);

out:
    kfree(kbuf);
    return ret;
}
ffffffffc020127e:	70e6                	ld	ra,120(sp)
ffffffffc0201280:	7446                	ld	s0,112(sp)
ffffffffc0201282:	74a6                	ld	s1,104(sp)
ffffffffc0201284:	7906                	ld	s2,96(sp)
ffffffffc0201286:	69e6                	ld	s3,88(sp)
ffffffffc0201288:	6a46                	ld	s4,80(sp)
ffffffffc020128a:	6aa6                	ld	s5,72(sp)
ffffffffc020128c:	6b06                	ld	s6,64(sp)
ffffffffc020128e:	7be2                	ld	s7,56(sp)
ffffffffc0201290:	7c42                	ld	s8,48(sp)
ffffffffc0201292:	7ca2                	ld	s9,40(sp)
ffffffffc0201294:	7d02                	ld	s10,32(sp)
ffffffffc0201296:	6de2                	ld	s11,24(sp)
ffffffffc0201298:	853a                	mv	a0,a4
ffffffffc020129a:	6109                	addi	sp,sp,128
ffffffffc020129c:	8082                	ret
ffffffffc020129e:	8a2a                	mv	s4,a0
    void *kbuf = kmalloc(len);
ffffffffc02012a0:	8536                	mv	a0,a3
ffffffffc02012a2:	8aae                	mv	s5,a1
ffffffffc02012a4:	8432                	mv	s0,a2
ffffffffc02012a6:	572020ef          	jal	ra,ffffffffc0203818 <kmalloc>
ffffffffc02012aa:	8b2a                	mv	s6,a0
    if (kbuf == NULL)
ffffffffc02012ac:	12050763          	beqz	a0,ffffffffc02013da <dirtycow_mempoke+0x182>
    if (!copy_from_user(mm, kbuf, src, len, 0))
ffffffffc02012b0:	85aa                	mv	a1,a0
ffffffffc02012b2:	4701                	li	a4,0
ffffffffc02012b4:	86ce                	mv	a3,s3
ffffffffc02012b6:	8622                	mv	a2,s0
ffffffffc02012b8:	8552                	mv	a0,s4
ffffffffc02012ba:	2f8020ef          	jal	ra,ffffffffc02035b2 <copy_from_user>
ffffffffc02012be:	10050063          	beqz	a0,ffffffffc02013be <dirtycow_mempoke+0x166>
    uintptr_t end = dst + len;
ffffffffc02012c2:	015987b3          	add	a5,s3,s5
    if (end < dst || !USER_ACCESS(dst, end))
ffffffffc02012c6:	1157e563          	bltu	a5,s5,ffffffffc02013d0 <dirtycow_mempoke+0x178>
ffffffffc02012ca:	00200737          	lui	a4,0x200
ffffffffc02012ce:	10eae163          	bltu	s5,a4,ffffffffc02013d0 <dirtycow_mempoke+0x178>
ffffffffc02012d2:	0efa8f63          	beq	s5,a5,ffffffffc02013d0 <dirtycow_mempoke+0x178>
ffffffffc02012d6:	4705                	li	a4,1
ffffffffc02012d8:	077e                	slli	a4,a4,0x1f
ffffffffc02012da:	0ef76b63          	bltu	a4,a5,ffffffffc02013d0 <dirtycow_mempoke+0x178>
}

static inline void *
page2kva(struct Page *page)
{
    return KADDR(page2pa(page));
ffffffffc02012de:	57fd                	li	a5,-1
ffffffffc02012e0:	83b1                	srli	a5,a5,0xc
    size_t copied = 0;
ffffffffc02012e2:	4481                	li	s1,0
        uintptr_t la_page = ROUNDDOWN(la, PGSIZE);
ffffffffc02012e4:	7cfd                	lui	s9,0xfffff
    if (dirtycow_stats.emulate_bug)
ffffffffc02012e6:	000c1b97          	auipc	s7,0xc1
ffffffffc02012ea:	df2b8b93          	addi	s7,s7,-526 # ffffffffc02c20d8 <dirtycow_stats>
    return &pages[PPN(pa) - nbase];
ffffffffc02012ee:	00007d97          	auipc	s11,0x7
ffffffffc02012f2:	f3ad8d93          	addi	s11,s11,-198 # ffffffffc0208228 <nbase>
    return KADDR(page2pa(page));
ffffffffc02012f6:	e43e                	sd	a5,8(sp)
ffffffffc02012f8:	000c5d17          	auipc	s10,0xc5
ffffffffc02012fc:	e78d0d13          	addi	s10,s10,-392 # ffffffffc02c6170 <va_pa_offset>
ffffffffc0201300:	a8b9                	j	ffffffffc020135e <dirtycow_mempoke+0x106>
    if ((*ptep & PTE_W) == 0)
ffffffffc0201302:	8b11                	andi	a4,a4,4
ffffffffc0201304:	c345                	beqz	a4,ffffffffc02013a4 <dirtycow_mempoke+0x14c>
        pte_t *ptep = get_pte(mm->pgdir, la_page, 0);
ffffffffc0201306:	018a3503          	ld	a0,24(s4)
ffffffffc020130a:	4601                	li	a2,0
ffffffffc020130c:	85e2                	mv	a1,s8
ffffffffc020130e:	1f0000ef          	jal	ra,ffffffffc02014fe <get_pte>
        if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0201312:	c555                	beqz	a0,ffffffffc02013be <dirtycow_mempoke+0x166>
ffffffffc0201314:	611c                	ld	a5,0(a0)
ffffffffc0201316:	0017f713          	andi	a4,a5,1
ffffffffc020131a:	c355                	beqz	a4,ffffffffc02013be <dirtycow_mempoke+0x166>
    if (PPN(pa) >= npage)
ffffffffc020131c:	000c5717          	auipc	a4,0xc5
ffffffffc0201320:	e3c70713          	addi	a4,a4,-452 # ffffffffc02c6158 <npage>
ffffffffc0201324:	6318                	ld	a4,0(a4)
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
ffffffffc0201326:	078a                	slli	a5,a5,0x2
ffffffffc0201328:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020132a:	0ae7fa63          	bgeu	a5,a4,ffffffffc02013de <dirtycow_mempoke+0x186>
    return &pages[PPN(pa) - nbase];
ffffffffc020132e:	000db503          	ld	a0,0(s11)
ffffffffc0201332:	40a786b3          	sub	a3,a5,a0
ffffffffc0201336:	069a                	slli	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201338:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc020133a:	8699                	srai	a3,a3,0x6
ffffffffc020133c:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc020133e:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201340:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201342:	0ae7fa63          	bgeu	a5,a4,ffffffffc02013f6 <dirtycow_mempoke+0x19e>
ffffffffc0201346:	000d3503          	ld	a0,0(s10)
        memcpy(kva + page_off, (const char *)buf + copied, chunk);
ffffffffc020134a:	009b05b3          	add	a1,s6,s1
ffffffffc020134e:	864a                	mv	a2,s2
ffffffffc0201350:	9536                	add	a0,a0,a3
        copied += chunk;
ffffffffc0201352:	94ca                	add	s1,s1,s2
        memcpy(kva + page_off, (const char *)buf + copied, chunk);
ffffffffc0201354:	9522                	add	a0,a0,s0
ffffffffc0201356:	6a8040ef          	jal	ra,ffffffffc02059fe <memcpy>
    while (copied < len)
ffffffffc020135a:	0734f963          	bgeu	s1,s3,ffffffffc02013cc <dirtycow_mempoke+0x174>
        uintptr_t la = dst + copied;
ffffffffc020135e:	009a8433          	add	s0,s5,s1
        uintptr_t la_page = ROUNDDOWN(la, PGSIZE);
ffffffffc0201362:	01947c33          	and	s8,s0,s9
        size_t remain = PGSIZE - page_off;
ffffffffc0201366:	408c0933          	sub	s2,s8,s0
ffffffffc020136a:	6785                	lui	a5,0x1
        size_t chunk = len - copied;
ffffffffc020136c:	40998733          	sub	a4,s3,s1
        size_t remain = PGSIZE - page_off;
ffffffffc0201370:	993e                	add	s2,s2,a5
        size_t page_off = la - la_page;
ffffffffc0201372:	41840433          	sub	s0,s0,s8
        if (chunk > remain)
ffffffffc0201376:	01277363          	bgeu	a4,s2,ffffffffc020137c <dirtycow_mempoke+0x124>
ffffffffc020137a:	893a                	mv	s2,a4
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc020137c:	018a3503          	ld	a0,24(s4)
ffffffffc0201380:	4601                	li	a2,0
ffffffffc0201382:	85e2                	mv	a1,s8
ffffffffc0201384:	17a000ef          	jal	ra,ffffffffc02014fe <get_pte>
    if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0201388:	c521                	beqz	a0,ffffffffc02013d0 <dirtycow_mempoke+0x178>
ffffffffc020138a:	6118                	ld	a4,0(a0)
ffffffffc020138c:	00177693          	andi	a3,a4,1
ffffffffc0201390:	c2a1                	beqz	a3,ffffffffc02013d0 <dirtycow_mempoke+0x178>
    if (dirtycow_stats.emulate_bug)
ffffffffc0201392:	000bb683          	ld	a3,0(s7)
ffffffffc0201396:	d6b5                	beqz	a3,ffffffffc0201302 <dirtycow_mempoke+0xaa>
        dirtycow_stats.unsafe_writes++;
ffffffffc0201398:	008bb703          	ld	a4,8(s7)
ffffffffc020139c:	0705                	addi	a4,a4,1
ffffffffc020139e:	00ebb423          	sd	a4,8(s7)
        if (ret != 0)
ffffffffc02013a2:	b795                	j	ffffffffc0201306 <dirtycow_mempoke+0xae>
        int ret = do_pgfault(mm, PTE_W, la);
ffffffffc02013a4:	8662                	mv	a2,s8
ffffffffc02013a6:	4591                	li	a1,4
ffffffffc02013a8:	8552                	mv	a0,s4
ffffffffc02013aa:	177010ef          	jal	ra,ffffffffc0202d20 <do_pgfault>
ffffffffc02013ae:	872a                	mv	a4,a0
        if (ret != 0)
ffffffffc02013b0:	e901                	bnez	a0,ffffffffc02013c0 <dirtycow_mempoke+0x168>
        dirtycow_stats.repaired_writes++; // 记录 fix 模式下成功触发 COW 的次数
ffffffffc02013b2:	010bb703          	ld	a4,16(s7)
ffffffffc02013b6:	0705                	addi	a4,a4,1
ffffffffc02013b8:	00ebb823          	sd	a4,16(s7)
        if (ret != 0)
ffffffffc02013bc:	b7a9                	j	ffffffffc0201306 <dirtycow_mempoke+0xae>
        ret = -E_FAULT;
ffffffffc02013be:	5769                	li	a4,-6
    kfree(kbuf);
ffffffffc02013c0:	855a                	mv	a0,s6
ffffffffc02013c2:	e43a                	sd	a4,8(sp)
ffffffffc02013c4:	504020ef          	jal	ra,ffffffffc02038c8 <kfree>
    return ret;
ffffffffc02013c8:	6722                	ld	a4,8(sp)
ffffffffc02013ca:	bd55                	j	ffffffffc020127e <dirtycow_mempoke+0x26>
    return 0;
ffffffffc02013cc:	4701                	li	a4,0
ffffffffc02013ce:	bfcd                	j	ffffffffc02013c0 <dirtycow_mempoke+0x168>
        return -E_INVAL;
ffffffffc02013d0:	5775                	li	a4,-3
ffffffffc02013d2:	b7fd                	j	ffffffffc02013c0 <dirtycow_mempoke+0x168>
        return -E_INVAL;
ffffffffc02013d4:	5775                	li	a4,-3
}
ffffffffc02013d6:	853a                	mv	a0,a4
ffffffffc02013d8:	8082                	ret
        return -E_NO_MEM;
ffffffffc02013da:	5771                	li	a4,-4
ffffffffc02013dc:	b54d                	j	ffffffffc020127e <dirtycow_mempoke+0x26>
        panic("pa2page called with invalid pa");
ffffffffc02013de:	00005617          	auipc	a2,0x5
ffffffffc02013e2:	74a60613          	addi	a2,a2,1866 # ffffffffc0206b28 <commands+0x930>
ffffffffc02013e6:	06900593          	li	a1,105
ffffffffc02013ea:	00005517          	auipc	a0,0x5
ffffffffc02013ee:	75e50513          	addi	a0,a0,1886 # ffffffffc0206b48 <commands+0x950>
ffffffffc02013f2:	e2dfe0ef          	jal	ra,ffffffffc020021e <__panic>
    return KADDR(page2pa(page));
ffffffffc02013f6:	00005617          	auipc	a2,0x5
ffffffffc02013fa:	76260613          	addi	a2,a2,1890 # ffffffffc0206b58 <commands+0x960>
ffffffffc02013fe:	07100593          	li	a1,113
ffffffffc0201402:	00005517          	auipc	a0,0x5
ffffffffc0201406:	74650513          	addi	a0,a0,1862 # ffffffffc0206b48 <commands+0x950>
ffffffffc020140a:	e15fe0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc020140e <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc020140e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201410:	00005617          	auipc	a2,0x5
ffffffffc0201414:	71860613          	addi	a2,a2,1816 # ffffffffc0206b28 <commands+0x930>
ffffffffc0201418:	06900593          	li	a1,105
ffffffffc020141c:	00005517          	auipc	a0,0x5
ffffffffc0201420:	72c50513          	addi	a0,a0,1836 # ffffffffc0206b48 <commands+0x950>
pa2page(uintptr_t pa)
ffffffffc0201424:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201426:	df9fe0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc020142a <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc020142a:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc020142c:	00005617          	auipc	a2,0x5
ffffffffc0201430:	75460613          	addi	a2,a2,1876 # ffffffffc0206b80 <commands+0x988>
ffffffffc0201434:	07f00593          	li	a1,127
ffffffffc0201438:	00005517          	auipc	a0,0x5
ffffffffc020143c:	71050513          	addi	a0,a0,1808 # ffffffffc0206b48 <commands+0x950>
pte2page(pte_t pte)
ffffffffc0201440:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201442:	dddfe0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0201446 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201446:	100027f3          	csrr	a5,sstatus
ffffffffc020144a:	8b89                	andi	a5,a5,2
ffffffffc020144c:	e799                	bnez	a5,ffffffffc020145a <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020144e:	000c5797          	auipc	a5,0xc5
ffffffffc0201452:	d1a7b783          	ld	a5,-742(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc0201456:	6f9c                	ld	a5,24(a5)
ffffffffc0201458:	8782                	jr	a5
{
ffffffffc020145a:	1141                	addi	sp,sp,-16
ffffffffc020145c:	e406                	sd	ra,8(sp)
ffffffffc020145e:	e022                	sd	s0,0(sp)
ffffffffc0201460:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201462:	e22ff0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201466:	000c5797          	auipc	a5,0xc5
ffffffffc020146a:	d027b783          	ld	a5,-766(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc020146e:	6f9c                	ld	a5,24(a5)
ffffffffc0201470:	8522                	mv	a0,s0
ffffffffc0201472:	9782                	jalr	a5
ffffffffc0201474:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201476:	e08ff0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020147a:	60a2                	ld	ra,8(sp)
ffffffffc020147c:	8522                	mv	a0,s0
ffffffffc020147e:	6402                	ld	s0,0(sp)
ffffffffc0201480:	0141                	addi	sp,sp,16
ffffffffc0201482:	8082                	ret

ffffffffc0201484 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201484:	100027f3          	csrr	a5,sstatus
ffffffffc0201488:	8b89                	andi	a5,a5,2
ffffffffc020148a:	e799                	bnez	a5,ffffffffc0201498 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020148c:	000c5797          	auipc	a5,0xc5
ffffffffc0201490:	cdc7b783          	ld	a5,-804(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc0201494:	739c                	ld	a5,32(a5)
ffffffffc0201496:	8782                	jr	a5
{
ffffffffc0201498:	1101                	addi	sp,sp,-32
ffffffffc020149a:	ec06                	sd	ra,24(sp)
ffffffffc020149c:	e822                	sd	s0,16(sp)
ffffffffc020149e:	e426                	sd	s1,8(sp)
ffffffffc02014a0:	842a                	mv	s0,a0
ffffffffc02014a2:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02014a4:	de0ff0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02014a8:	000c5797          	auipc	a5,0xc5
ffffffffc02014ac:	cc07b783          	ld	a5,-832(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc02014b0:	739c                	ld	a5,32(a5)
ffffffffc02014b2:	85a6                	mv	a1,s1
ffffffffc02014b4:	8522                	mv	a0,s0
ffffffffc02014b6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02014b8:	6442                	ld	s0,16(sp)
ffffffffc02014ba:	60e2                	ld	ra,24(sp)
ffffffffc02014bc:	64a2                	ld	s1,8(sp)
ffffffffc02014be:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02014c0:	dbeff06f          	j	ffffffffc0200a7e <intr_enable>

ffffffffc02014c4 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02014c4:	100027f3          	csrr	a5,sstatus
ffffffffc02014c8:	8b89                	andi	a5,a5,2
ffffffffc02014ca:	e799                	bnez	a5,ffffffffc02014d8 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02014cc:	000c5797          	auipc	a5,0xc5
ffffffffc02014d0:	c9c7b783          	ld	a5,-868(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc02014d4:	779c                	ld	a5,40(a5)
ffffffffc02014d6:	8782                	jr	a5
{
ffffffffc02014d8:	1141                	addi	sp,sp,-16
ffffffffc02014da:	e406                	sd	ra,8(sp)
ffffffffc02014dc:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02014de:	da6ff0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02014e2:	000c5797          	auipc	a5,0xc5
ffffffffc02014e6:	c867b783          	ld	a5,-890(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc02014ea:	779c                	ld	a5,40(a5)
ffffffffc02014ec:	9782                	jalr	a5
ffffffffc02014ee:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02014f0:	d8eff0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02014f4:	60a2                	ld	ra,8(sp)
ffffffffc02014f6:	8522                	mv	a0,s0
ffffffffc02014f8:	6402                	ld	s0,0(sp)
ffffffffc02014fa:	0141                	addi	sp,sp,16
ffffffffc02014fc:	8082                	ret

ffffffffc02014fe <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02014fe:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201502:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201506:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201508:	078e                	slli	a5,a5,0x3
{
ffffffffc020150a:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020150c:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201510:	6094                	ld	a3,0(s1)
{
ffffffffc0201512:	f04a                	sd	s2,32(sp)
ffffffffc0201514:	ec4e                	sd	s3,24(sp)
ffffffffc0201516:	e852                	sd	s4,16(sp)
ffffffffc0201518:	fc06                	sd	ra,56(sp)
ffffffffc020151a:	f822                	sd	s0,48(sp)
ffffffffc020151c:	e456                	sd	s5,8(sp)
ffffffffc020151e:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201520:	0016f793          	andi	a5,a3,1
{
ffffffffc0201524:	892e                	mv	s2,a1
ffffffffc0201526:	8a32                	mv	s4,a2
ffffffffc0201528:	000c5997          	auipc	s3,0xc5
ffffffffc020152c:	c3098993          	addi	s3,s3,-976 # ffffffffc02c6158 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201530:	efbd                	bnez	a5,ffffffffc02015ae <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201532:	14060c63          	beqz	a2,ffffffffc020168a <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201536:	100027f3          	csrr	a5,sstatus
ffffffffc020153a:	8b89                	andi	a5,a5,2
ffffffffc020153c:	14079963          	bnez	a5,ffffffffc020168e <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201540:	000c5797          	auipc	a5,0xc5
ffffffffc0201544:	c287b783          	ld	a5,-984(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc0201548:	6f9c                	ld	a5,24(a5)
ffffffffc020154a:	4505                	li	a0,1
ffffffffc020154c:	9782                	jalr	a5
ffffffffc020154e:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201550:	12040d63          	beqz	s0,ffffffffc020168a <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201554:	000c5b17          	auipc	s6,0xc5
ffffffffc0201558:	c0cb0b13          	addi	s6,s6,-1012 # ffffffffc02c6160 <pages>
ffffffffc020155c:	000b3503          	ld	a0,0(s6)
ffffffffc0201560:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201564:	000c5997          	auipc	s3,0xc5
ffffffffc0201568:	bf498993          	addi	s3,s3,-1036 # ffffffffc02c6158 <npage>
ffffffffc020156c:	40a40533          	sub	a0,s0,a0
ffffffffc0201570:	8519                	srai	a0,a0,0x6
ffffffffc0201572:	9556                	add	a0,a0,s5
ffffffffc0201574:	0009b703          	ld	a4,0(s3)
ffffffffc0201578:	00c51793          	slli	a5,a0,0xc
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020157c:	4685                	li	a3,1
ffffffffc020157e:	c014                	sw	a3,0(s0)
ffffffffc0201580:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201582:	0532                	slli	a0,a0,0xc
ffffffffc0201584:	16e7f763          	bgeu	a5,a4,ffffffffc02016f2 <get_pte+0x1f4>
ffffffffc0201588:	000c5797          	auipc	a5,0xc5
ffffffffc020158c:	be87b783          	ld	a5,-1048(a5) # ffffffffc02c6170 <va_pa_offset>
ffffffffc0201590:	6605                	lui	a2,0x1
ffffffffc0201592:	4581                	li	a1,0
ffffffffc0201594:	953e                	add	a0,a0,a5
ffffffffc0201596:	456040ef          	jal	ra,ffffffffc02059ec <memset>
    return page - pages + nbase;
ffffffffc020159a:	000b3683          	ld	a3,0(s6)
ffffffffc020159e:	40d406b3          	sub	a3,s0,a3
ffffffffc02015a2:	8699                	srai	a3,a3,0x6
ffffffffc02015a4:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02015a6:	06aa                	slli	a3,a3,0xa
ffffffffc02015a8:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02015ac:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02015ae:	77fd                	lui	a5,0xfffff
ffffffffc02015b0:	068a                	slli	a3,a3,0x2
ffffffffc02015b2:	0009b703          	ld	a4,0(s3)
ffffffffc02015b6:	8efd                	and	a3,a3,a5
ffffffffc02015b8:	00c6d793          	srli	a5,a3,0xc
ffffffffc02015bc:	10e7ff63          	bgeu	a5,a4,ffffffffc02016da <get_pte+0x1dc>
ffffffffc02015c0:	000c5a97          	auipc	s5,0xc5
ffffffffc02015c4:	bb0a8a93          	addi	s5,s5,-1104 # ffffffffc02c6170 <va_pa_offset>
ffffffffc02015c8:	000ab403          	ld	s0,0(s5)
ffffffffc02015cc:	01595793          	srli	a5,s2,0x15
ffffffffc02015d0:	1ff7f793          	andi	a5,a5,511
ffffffffc02015d4:	96a2                	add	a3,a3,s0
ffffffffc02015d6:	00379413          	slli	s0,a5,0x3
ffffffffc02015da:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02015dc:	6014                	ld	a3,0(s0)
ffffffffc02015de:	0016f793          	andi	a5,a3,1
ffffffffc02015e2:	ebad                	bnez	a5,ffffffffc0201654 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02015e4:	0a0a0363          	beqz	s4,ffffffffc020168a <get_pte+0x18c>
ffffffffc02015e8:	100027f3          	csrr	a5,sstatus
ffffffffc02015ec:	8b89                	andi	a5,a5,2
ffffffffc02015ee:	efcd                	bnez	a5,ffffffffc02016a8 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02015f0:	000c5797          	auipc	a5,0xc5
ffffffffc02015f4:	b787b783          	ld	a5,-1160(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc02015f8:	6f9c                	ld	a5,24(a5)
ffffffffc02015fa:	4505                	li	a0,1
ffffffffc02015fc:	9782                	jalr	a5
ffffffffc02015fe:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201600:	c4c9                	beqz	s1,ffffffffc020168a <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201602:	000c5b17          	auipc	s6,0xc5
ffffffffc0201606:	b5eb0b13          	addi	s6,s6,-1186 # ffffffffc02c6160 <pages>
ffffffffc020160a:	000b3503          	ld	a0,0(s6)
ffffffffc020160e:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201612:	0009b703          	ld	a4,0(s3)
ffffffffc0201616:	40a48533          	sub	a0,s1,a0
ffffffffc020161a:	8519                	srai	a0,a0,0x6
ffffffffc020161c:	9552                	add	a0,a0,s4
ffffffffc020161e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201622:	4685                	li	a3,1
ffffffffc0201624:	c094                	sw	a3,0(s1)
ffffffffc0201626:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201628:	0532                	slli	a0,a0,0xc
ffffffffc020162a:	0ee7f163          	bgeu	a5,a4,ffffffffc020170c <get_pte+0x20e>
ffffffffc020162e:	000ab783          	ld	a5,0(s5)
ffffffffc0201632:	6605                	lui	a2,0x1
ffffffffc0201634:	4581                	li	a1,0
ffffffffc0201636:	953e                	add	a0,a0,a5
ffffffffc0201638:	3b4040ef          	jal	ra,ffffffffc02059ec <memset>
    return page - pages + nbase;
ffffffffc020163c:	000b3683          	ld	a3,0(s6)
ffffffffc0201640:	40d486b3          	sub	a3,s1,a3
ffffffffc0201644:	8699                	srai	a3,a3,0x6
ffffffffc0201646:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201648:	06aa                	slli	a3,a3,0xa
ffffffffc020164a:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020164e:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201650:	0009b703          	ld	a4,0(s3)
ffffffffc0201654:	068a                	slli	a3,a3,0x2
ffffffffc0201656:	757d                	lui	a0,0xfffff
ffffffffc0201658:	8ee9                	and	a3,a3,a0
ffffffffc020165a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020165e:	06e7f263          	bgeu	a5,a4,ffffffffc02016c2 <get_pte+0x1c4>
ffffffffc0201662:	000ab503          	ld	a0,0(s5)
ffffffffc0201666:	00c95913          	srli	s2,s2,0xc
ffffffffc020166a:	1ff97913          	andi	s2,s2,511
ffffffffc020166e:	96aa                	add	a3,a3,a0
ffffffffc0201670:	00391513          	slli	a0,s2,0x3
ffffffffc0201674:	9536                	add	a0,a0,a3
}
ffffffffc0201676:	70e2                	ld	ra,56(sp)
ffffffffc0201678:	7442                	ld	s0,48(sp)
ffffffffc020167a:	74a2                	ld	s1,40(sp)
ffffffffc020167c:	7902                	ld	s2,32(sp)
ffffffffc020167e:	69e2                	ld	s3,24(sp)
ffffffffc0201680:	6a42                	ld	s4,16(sp)
ffffffffc0201682:	6aa2                	ld	s5,8(sp)
ffffffffc0201684:	6b02                	ld	s6,0(sp)
ffffffffc0201686:	6121                	addi	sp,sp,64
ffffffffc0201688:	8082                	ret
            return NULL;
ffffffffc020168a:	4501                	li	a0,0
ffffffffc020168c:	b7ed                	j	ffffffffc0201676 <get_pte+0x178>
        intr_disable();
ffffffffc020168e:	bf6ff0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201692:	000c5797          	auipc	a5,0xc5
ffffffffc0201696:	ad67b783          	ld	a5,-1322(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc020169a:	6f9c                	ld	a5,24(a5)
ffffffffc020169c:	4505                	li	a0,1
ffffffffc020169e:	9782                	jalr	a5
ffffffffc02016a0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02016a2:	bdcff0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02016a6:	b56d                	j	ffffffffc0201550 <get_pte+0x52>
        intr_disable();
ffffffffc02016a8:	bdcff0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc02016ac:	000c5797          	auipc	a5,0xc5
ffffffffc02016b0:	abc7b783          	ld	a5,-1348(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc02016b4:	6f9c                	ld	a5,24(a5)
ffffffffc02016b6:	4505                	li	a0,1
ffffffffc02016b8:	9782                	jalr	a5
ffffffffc02016ba:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02016bc:	bc2ff0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02016c0:	b781                	j	ffffffffc0201600 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02016c2:	00005617          	auipc	a2,0x5
ffffffffc02016c6:	49660613          	addi	a2,a2,1174 # ffffffffc0206b58 <commands+0x960>
ffffffffc02016ca:	0fa00593          	li	a1,250
ffffffffc02016ce:	00005517          	auipc	a0,0x5
ffffffffc02016d2:	4da50513          	addi	a0,a0,1242 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02016d6:	b49fe0ef          	jal	ra,ffffffffc020021e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02016da:	00005617          	auipc	a2,0x5
ffffffffc02016de:	47e60613          	addi	a2,a2,1150 # ffffffffc0206b58 <commands+0x960>
ffffffffc02016e2:	0ed00593          	li	a1,237
ffffffffc02016e6:	00005517          	auipc	a0,0x5
ffffffffc02016ea:	4c250513          	addi	a0,a0,1218 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02016ee:	b31fe0ef          	jal	ra,ffffffffc020021e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02016f2:	86aa                	mv	a3,a0
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	46460613          	addi	a2,a2,1124 # ffffffffc0206b58 <commands+0x960>
ffffffffc02016fc:	0e900593          	li	a1,233
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	4a850513          	addi	a0,a0,1192 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0201708:	b17fe0ef          	jal	ra,ffffffffc020021e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020170c:	86aa                	mv	a3,a0
ffffffffc020170e:	00005617          	auipc	a2,0x5
ffffffffc0201712:	44a60613          	addi	a2,a2,1098 # ffffffffc0206b58 <commands+0x960>
ffffffffc0201716:	0f700593          	li	a1,247
ffffffffc020171a:	00005517          	auipc	a0,0x5
ffffffffc020171e:	48e50513          	addi	a0,a0,1166 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0201722:	afdfe0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0201726 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201726:	1141                	addi	sp,sp,-16
ffffffffc0201728:	e022                	sd	s0,0(sp)
ffffffffc020172a:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020172c:	4601                	li	a2,0
{
ffffffffc020172e:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201730:	dcfff0ef          	jal	ra,ffffffffc02014fe <get_pte>
    if (ptep_store != NULL)
ffffffffc0201734:	c011                	beqz	s0,ffffffffc0201738 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201736:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201738:	c511                	beqz	a0,ffffffffc0201744 <get_page+0x1e>
ffffffffc020173a:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020173c:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020173e:	0017f713          	andi	a4,a5,1
ffffffffc0201742:	e709                	bnez	a4,ffffffffc020174c <get_page+0x26>
}
ffffffffc0201744:	60a2                	ld	ra,8(sp)
ffffffffc0201746:	6402                	ld	s0,0(sp)
ffffffffc0201748:	0141                	addi	sp,sp,16
ffffffffc020174a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020174c:	078a                	slli	a5,a5,0x2
ffffffffc020174e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201750:	000c5717          	auipc	a4,0xc5
ffffffffc0201754:	a0873703          	ld	a4,-1528(a4) # ffffffffc02c6158 <npage>
ffffffffc0201758:	00e7ff63          	bgeu	a5,a4,ffffffffc0201776 <get_page+0x50>
ffffffffc020175c:	60a2                	ld	ra,8(sp)
ffffffffc020175e:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201760:	fff80537          	lui	a0,0xfff80
ffffffffc0201764:	97aa                	add	a5,a5,a0
ffffffffc0201766:	079a                	slli	a5,a5,0x6
ffffffffc0201768:	000c5517          	auipc	a0,0xc5
ffffffffc020176c:	9f853503          	ld	a0,-1544(a0) # ffffffffc02c6160 <pages>
ffffffffc0201770:	953e                	add	a0,a0,a5
ffffffffc0201772:	0141                	addi	sp,sp,16
ffffffffc0201774:	8082                	ret
ffffffffc0201776:	c99ff0ef          	jal	ra,ffffffffc020140e <pa2page.part.0>

ffffffffc020177a <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc020177a:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020177c:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0201780:	f486                	sd	ra,104(sp)
ffffffffc0201782:	f0a2                	sd	s0,96(sp)
ffffffffc0201784:	eca6                	sd	s1,88(sp)
ffffffffc0201786:	e8ca                	sd	s2,80(sp)
ffffffffc0201788:	e4ce                	sd	s3,72(sp)
ffffffffc020178a:	e0d2                	sd	s4,64(sp)
ffffffffc020178c:	fc56                	sd	s5,56(sp)
ffffffffc020178e:	f85a                	sd	s6,48(sp)
ffffffffc0201790:	f45e                	sd	s7,40(sp)
ffffffffc0201792:	f062                	sd	s8,32(sp)
ffffffffc0201794:	ec66                	sd	s9,24(sp)
ffffffffc0201796:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201798:	17d2                	slli	a5,a5,0x34
ffffffffc020179a:	e3ed                	bnez	a5,ffffffffc020187c <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc020179c:	002007b7          	lui	a5,0x200
ffffffffc02017a0:	842e                	mv	s0,a1
ffffffffc02017a2:	0ef5ed63          	bltu	a1,a5,ffffffffc020189c <unmap_range+0x122>
ffffffffc02017a6:	8932                	mv	s2,a2
ffffffffc02017a8:	0ec5fa63          	bgeu	a1,a2,ffffffffc020189c <unmap_range+0x122>
ffffffffc02017ac:	4785                	li	a5,1
ffffffffc02017ae:	07fe                	slli	a5,a5,0x1f
ffffffffc02017b0:	0ec7e663          	bltu	a5,a2,ffffffffc020189c <unmap_range+0x122>
ffffffffc02017b4:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02017b6:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02017b8:	000c5c97          	auipc	s9,0xc5
ffffffffc02017bc:	9a0c8c93          	addi	s9,s9,-1632 # ffffffffc02c6158 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02017c0:	000c5c17          	auipc	s8,0xc5
ffffffffc02017c4:	9a0c0c13          	addi	s8,s8,-1632 # ffffffffc02c6160 <pages>
ffffffffc02017c8:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02017cc:	000c5d17          	auipc	s10,0xc5
ffffffffc02017d0:	99cd0d13          	addi	s10,s10,-1636 # ffffffffc02c6168 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02017d4:	00200b37          	lui	s6,0x200
ffffffffc02017d8:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02017dc:	4601                	li	a2,0
ffffffffc02017de:	85a2                	mv	a1,s0
ffffffffc02017e0:	854e                	mv	a0,s3
ffffffffc02017e2:	d1dff0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc02017e6:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02017e8:	cd29                	beqz	a0,ffffffffc0201842 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02017ea:	611c                	ld	a5,0(a0)
ffffffffc02017ec:	e395                	bnez	a5,ffffffffc0201810 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02017ee:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02017f0:	ff2466e3          	bltu	s0,s2,ffffffffc02017dc <unmap_range+0x62>
}
ffffffffc02017f4:	70a6                	ld	ra,104(sp)
ffffffffc02017f6:	7406                	ld	s0,96(sp)
ffffffffc02017f8:	64e6                	ld	s1,88(sp)
ffffffffc02017fa:	6946                	ld	s2,80(sp)
ffffffffc02017fc:	69a6                	ld	s3,72(sp)
ffffffffc02017fe:	6a06                	ld	s4,64(sp)
ffffffffc0201800:	7ae2                	ld	s5,56(sp)
ffffffffc0201802:	7b42                	ld	s6,48(sp)
ffffffffc0201804:	7ba2                	ld	s7,40(sp)
ffffffffc0201806:	7c02                	ld	s8,32(sp)
ffffffffc0201808:	6ce2                	ld	s9,24(sp)
ffffffffc020180a:	6d42                	ld	s10,16(sp)
ffffffffc020180c:	6165                	addi	sp,sp,112
ffffffffc020180e:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0201810:	0017f713          	andi	a4,a5,1
ffffffffc0201814:	df69                	beqz	a4,ffffffffc02017ee <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0201816:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020181a:	078a                	slli	a5,a5,0x2
ffffffffc020181c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020181e:	08e7ff63          	bgeu	a5,a4,ffffffffc02018bc <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0201822:	000c3503          	ld	a0,0(s8)
ffffffffc0201826:	97de                	add	a5,a5,s7
ffffffffc0201828:	079a                	slli	a5,a5,0x6
ffffffffc020182a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020182c:	411c                	lw	a5,0(a0)
ffffffffc020182e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201832:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0201834:	cf11                	beqz	a4,ffffffffc0201850 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc0201836:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020183a:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020183e:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0201840:	bf45                	j	ffffffffc02017f0 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0201842:	945a                	add	s0,s0,s6
ffffffffc0201844:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0201848:	d455                	beqz	s0,ffffffffc02017f4 <unmap_range+0x7a>
ffffffffc020184a:	f92469e3          	bltu	s0,s2,ffffffffc02017dc <unmap_range+0x62>
ffffffffc020184e:	b75d                	j	ffffffffc02017f4 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201850:	100027f3          	csrr	a5,sstatus
ffffffffc0201854:	8b89                	andi	a5,a5,2
ffffffffc0201856:	e799                	bnez	a5,ffffffffc0201864 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0201858:	000d3783          	ld	a5,0(s10)
ffffffffc020185c:	4585                	li	a1,1
ffffffffc020185e:	739c                	ld	a5,32(a5)
ffffffffc0201860:	9782                	jalr	a5
    if (flag)
ffffffffc0201862:	bfd1                	j	ffffffffc0201836 <unmap_range+0xbc>
ffffffffc0201864:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201866:	a1eff0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc020186a:	000d3783          	ld	a5,0(s10)
ffffffffc020186e:	6522                	ld	a0,8(sp)
ffffffffc0201870:	4585                	li	a1,1
ffffffffc0201872:	739c                	ld	a5,32(a5)
ffffffffc0201874:	9782                	jalr	a5
        intr_enable();
ffffffffc0201876:	a08ff0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc020187a:	bf75                	j	ffffffffc0201836 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020187c:	00005697          	auipc	a3,0x5
ffffffffc0201880:	33c68693          	addi	a3,a3,828 # ffffffffc0206bb8 <commands+0x9c0>
ffffffffc0201884:	00005617          	auipc	a2,0x5
ffffffffc0201888:	36460613          	addi	a2,a2,868 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020188c:	12000593          	li	a1,288
ffffffffc0201890:	00005517          	auipc	a0,0x5
ffffffffc0201894:	31850513          	addi	a0,a0,792 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0201898:	987fe0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020189c:	00005697          	auipc	a3,0x5
ffffffffc02018a0:	36468693          	addi	a3,a3,868 # ffffffffc0206c00 <commands+0xa08>
ffffffffc02018a4:	00005617          	auipc	a2,0x5
ffffffffc02018a8:	34460613          	addi	a2,a2,836 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02018ac:	12100593          	li	a1,289
ffffffffc02018b0:	00005517          	auipc	a0,0x5
ffffffffc02018b4:	2f850513          	addi	a0,a0,760 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02018b8:	967fe0ef          	jal	ra,ffffffffc020021e <__panic>
ffffffffc02018bc:	b53ff0ef          	jal	ra,ffffffffc020140e <pa2page.part.0>

ffffffffc02018c0 <exit_range>:
{
ffffffffc02018c0:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02018c2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02018c6:	fc86                	sd	ra,120(sp)
ffffffffc02018c8:	f8a2                	sd	s0,112(sp)
ffffffffc02018ca:	f4a6                	sd	s1,104(sp)
ffffffffc02018cc:	f0ca                	sd	s2,96(sp)
ffffffffc02018ce:	ecce                	sd	s3,88(sp)
ffffffffc02018d0:	e8d2                	sd	s4,80(sp)
ffffffffc02018d2:	e4d6                	sd	s5,72(sp)
ffffffffc02018d4:	e0da                	sd	s6,64(sp)
ffffffffc02018d6:	fc5e                	sd	s7,56(sp)
ffffffffc02018d8:	f862                	sd	s8,48(sp)
ffffffffc02018da:	f466                	sd	s9,40(sp)
ffffffffc02018dc:	f06a                	sd	s10,32(sp)
ffffffffc02018de:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02018e0:	17d2                	slli	a5,a5,0x34
ffffffffc02018e2:	20079a63          	bnez	a5,ffffffffc0201af6 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02018e6:	002007b7          	lui	a5,0x200
ffffffffc02018ea:	24f5e463          	bltu	a1,a5,ffffffffc0201b32 <exit_range+0x272>
ffffffffc02018ee:	8ab2                	mv	s5,a2
ffffffffc02018f0:	24c5f163          	bgeu	a1,a2,ffffffffc0201b32 <exit_range+0x272>
ffffffffc02018f4:	4785                	li	a5,1
ffffffffc02018f6:	07fe                	slli	a5,a5,0x1f
ffffffffc02018f8:	22c7ed63          	bltu	a5,a2,ffffffffc0201b32 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02018fc:	c00009b7          	lui	s3,0xc0000
ffffffffc0201900:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0201904:	ffe00937          	lui	s2,0xffe00
ffffffffc0201908:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020190c:	5cfd                	li	s9,-1
ffffffffc020190e:	8c2a                	mv	s8,a0
ffffffffc0201910:	0125f933          	and	s2,a1,s2
ffffffffc0201914:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0201916:	000c5d17          	auipc	s10,0xc5
ffffffffc020191a:	842d0d13          	addi	s10,s10,-1982 # ffffffffc02c6158 <npage>
    return KADDR(page2pa(page));
ffffffffc020191e:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0201922:	000c5717          	auipc	a4,0xc5
ffffffffc0201926:	83e70713          	addi	a4,a4,-1986 # ffffffffc02c6160 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020192a:	000c5d97          	auipc	s11,0xc5
ffffffffc020192e:	83ed8d93          	addi	s11,s11,-1986 # ffffffffc02c6168 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0201932:	c0000437          	lui	s0,0xc0000
ffffffffc0201936:	944e                	add	s0,s0,s3
ffffffffc0201938:	8079                	srli	s0,s0,0x1e
ffffffffc020193a:	1ff47413          	andi	s0,s0,511
ffffffffc020193e:	040e                	slli	s0,s0,0x3
ffffffffc0201940:	9462                	add	s0,s0,s8
ffffffffc0201942:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4910>
        if (pde1 & PTE_V)
ffffffffc0201946:	001a7793          	andi	a5,s4,1
ffffffffc020194a:	eb99                	bnez	a5,ffffffffc0201960 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020194c:	12098463          	beqz	s3,ffffffffc0201a74 <exit_range+0x1b4>
ffffffffc0201950:	400007b7          	lui	a5,0x40000
ffffffffc0201954:	97ce                	add	a5,a5,s3
ffffffffc0201956:	894e                	mv	s2,s3
ffffffffc0201958:	1159fe63          	bgeu	s3,s5,ffffffffc0201a74 <exit_range+0x1b4>
ffffffffc020195c:	89be                	mv	s3,a5
ffffffffc020195e:	bfd1                	j	ffffffffc0201932 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0201960:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201964:	0a0a                	slli	s4,s4,0x2
ffffffffc0201966:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc020196a:	1cfa7263          	bgeu	s4,a5,ffffffffc0201b2e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020196e:	fff80637          	lui	a2,0xfff80
ffffffffc0201972:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0201974:	000806b7          	lui	a3,0x80
ffffffffc0201978:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020197a:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020197e:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201980:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201982:	18f5fa63          	bgeu	a1,a5,ffffffffc0201b16 <exit_range+0x256>
ffffffffc0201986:	000c4817          	auipc	a6,0xc4
ffffffffc020198a:	7ea80813          	addi	a6,a6,2026 # ffffffffc02c6170 <va_pa_offset>
ffffffffc020198e:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0201992:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc0201994:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0201998:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc020199a:	00080337          	lui	t1,0x80
ffffffffc020199e:	6885                	lui	a7,0x1
ffffffffc02019a0:	a819                	j	ffffffffc02019b6 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02019a2:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02019a4:	002007b7          	lui	a5,0x200
ffffffffc02019a8:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02019aa:	08090c63          	beqz	s2,ffffffffc0201a42 <exit_range+0x182>
ffffffffc02019ae:	09397a63          	bgeu	s2,s3,ffffffffc0201a42 <exit_range+0x182>
ffffffffc02019b2:	0f597063          	bgeu	s2,s5,ffffffffc0201a92 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02019b6:	01595493          	srli	s1,s2,0x15
ffffffffc02019ba:	1ff4f493          	andi	s1,s1,511
ffffffffc02019be:	048e                	slli	s1,s1,0x3
ffffffffc02019c0:	94da                	add	s1,s1,s6
ffffffffc02019c2:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02019c4:	0017f693          	andi	a3,a5,1
ffffffffc02019c8:	dee9                	beqz	a3,ffffffffc02019a2 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02019ca:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02019ce:	078a                	slli	a5,a5,0x2
ffffffffc02019d0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02019d2:	14b7fe63          	bgeu	a5,a1,ffffffffc0201b2e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02019d6:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02019d8:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02019dc:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02019e0:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02019e4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02019e6:	12bef863          	bgeu	t4,a1,ffffffffc0201b16 <exit_range+0x256>
ffffffffc02019ea:	00083783          	ld	a5,0(a6)
ffffffffc02019ee:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02019f0:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02019f4:	629c                	ld	a5,0(a3)
ffffffffc02019f6:	8b85                	andi	a5,a5,1
ffffffffc02019f8:	f7d5                	bnez	a5,ffffffffc02019a4 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02019fa:	06a1                	addi	a3,a3,8
ffffffffc02019fc:	fed59ce3          	bne	a1,a3,ffffffffc02019f4 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a00:	631c                	ld	a5,0(a4)
ffffffffc0201a02:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a04:	100027f3          	csrr	a5,sstatus
ffffffffc0201a08:	8b89                	andi	a5,a5,2
ffffffffc0201a0a:	e7d9                	bnez	a5,ffffffffc0201a98 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0201a0c:	000db783          	ld	a5,0(s11)
ffffffffc0201a10:	4585                	li	a1,1
ffffffffc0201a12:	e032                	sd	a2,0(sp)
ffffffffc0201a14:	739c                	ld	a5,32(a5)
ffffffffc0201a16:	9782                	jalr	a5
    if (flag)
ffffffffc0201a18:	6602                	ld	a2,0(sp)
ffffffffc0201a1a:	000c4817          	auipc	a6,0xc4
ffffffffc0201a1e:	75680813          	addi	a6,a6,1878 # ffffffffc02c6170 <va_pa_offset>
ffffffffc0201a22:	fff80e37          	lui	t3,0xfff80
ffffffffc0201a26:	00080337          	lui	t1,0x80
ffffffffc0201a2a:	6885                	lui	a7,0x1
ffffffffc0201a2c:	000c4717          	auipc	a4,0xc4
ffffffffc0201a30:	73470713          	addi	a4,a4,1844 # ffffffffc02c6160 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0201a34:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0201a38:	002007b7          	lui	a5,0x200
ffffffffc0201a3c:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0201a3e:	f60918e3          	bnez	s2,ffffffffc02019ae <exit_range+0xee>
            if (free_pd0)
ffffffffc0201a42:	f00b85e3          	beqz	s7,ffffffffc020194c <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0201a46:	000d3783          	ld	a5,0(s10)
ffffffffc0201a4a:	0efa7263          	bgeu	s4,a5,ffffffffc0201b2e <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a4e:	6308                	ld	a0,0(a4)
ffffffffc0201a50:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a52:	100027f3          	csrr	a5,sstatus
ffffffffc0201a56:	8b89                	andi	a5,a5,2
ffffffffc0201a58:	efad                	bnez	a5,ffffffffc0201ad2 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0201a5a:	000db783          	ld	a5,0(s11)
ffffffffc0201a5e:	4585                	li	a1,1
ffffffffc0201a60:	739c                	ld	a5,32(a5)
ffffffffc0201a62:	9782                	jalr	a5
ffffffffc0201a64:	000c4717          	auipc	a4,0xc4
ffffffffc0201a68:	6fc70713          	addi	a4,a4,1788 # ffffffffc02c6160 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0201a6c:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0201a70:	ee0990e3          	bnez	s3,ffffffffc0201950 <exit_range+0x90>
}
ffffffffc0201a74:	70e6                	ld	ra,120(sp)
ffffffffc0201a76:	7446                	ld	s0,112(sp)
ffffffffc0201a78:	74a6                	ld	s1,104(sp)
ffffffffc0201a7a:	7906                	ld	s2,96(sp)
ffffffffc0201a7c:	69e6                	ld	s3,88(sp)
ffffffffc0201a7e:	6a46                	ld	s4,80(sp)
ffffffffc0201a80:	6aa6                	ld	s5,72(sp)
ffffffffc0201a82:	6b06                	ld	s6,64(sp)
ffffffffc0201a84:	7be2                	ld	s7,56(sp)
ffffffffc0201a86:	7c42                	ld	s8,48(sp)
ffffffffc0201a88:	7ca2                	ld	s9,40(sp)
ffffffffc0201a8a:	7d02                	ld	s10,32(sp)
ffffffffc0201a8c:	6de2                	ld	s11,24(sp)
ffffffffc0201a8e:	6109                	addi	sp,sp,128
ffffffffc0201a90:	8082                	ret
            if (free_pd0)
ffffffffc0201a92:	ea0b8fe3          	beqz	s7,ffffffffc0201950 <exit_range+0x90>
ffffffffc0201a96:	bf45                	j	ffffffffc0201a46 <exit_range+0x186>
ffffffffc0201a98:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0201a9a:	e42a                	sd	a0,8(sp)
ffffffffc0201a9c:	fe9fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201aa0:	000db783          	ld	a5,0(s11)
ffffffffc0201aa4:	6522                	ld	a0,8(sp)
ffffffffc0201aa6:	4585                	li	a1,1
ffffffffc0201aa8:	739c                	ld	a5,32(a5)
ffffffffc0201aaa:	9782                	jalr	a5
        intr_enable();
ffffffffc0201aac:	fd3fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0201ab0:	6602                	ld	a2,0(sp)
ffffffffc0201ab2:	000c4717          	auipc	a4,0xc4
ffffffffc0201ab6:	6ae70713          	addi	a4,a4,1710 # ffffffffc02c6160 <pages>
ffffffffc0201aba:	6885                	lui	a7,0x1
ffffffffc0201abc:	00080337          	lui	t1,0x80
ffffffffc0201ac0:	fff80e37          	lui	t3,0xfff80
ffffffffc0201ac4:	000c4817          	auipc	a6,0xc4
ffffffffc0201ac8:	6ac80813          	addi	a6,a6,1708 # ffffffffc02c6170 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0201acc:	0004b023          	sd	zero,0(s1)
ffffffffc0201ad0:	b7a5                	j	ffffffffc0201a38 <exit_range+0x178>
ffffffffc0201ad2:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201ad4:	fb1fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ad8:	000db783          	ld	a5,0(s11)
ffffffffc0201adc:	6502                	ld	a0,0(sp)
ffffffffc0201ade:	4585                	li	a1,1
ffffffffc0201ae0:	739c                	ld	a5,32(a5)
ffffffffc0201ae2:	9782                	jalr	a5
        intr_enable();
ffffffffc0201ae4:	f9bfe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0201ae8:	000c4717          	auipc	a4,0xc4
ffffffffc0201aec:	67870713          	addi	a4,a4,1656 # ffffffffc02c6160 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0201af0:	00043023          	sd	zero,0(s0)
ffffffffc0201af4:	bfb5                	j	ffffffffc0201a70 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201af6:	00005697          	auipc	a3,0x5
ffffffffc0201afa:	0c268693          	addi	a3,a3,194 # ffffffffc0206bb8 <commands+0x9c0>
ffffffffc0201afe:	00005617          	auipc	a2,0x5
ffffffffc0201b02:	0ea60613          	addi	a2,a2,234 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0201b06:	13500593          	li	a1,309
ffffffffc0201b0a:	00005517          	auipc	a0,0x5
ffffffffc0201b0e:	09e50513          	addi	a0,a0,158 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0201b12:	f0cfe0ef          	jal	ra,ffffffffc020021e <__panic>
    return KADDR(page2pa(page));
ffffffffc0201b16:	00005617          	auipc	a2,0x5
ffffffffc0201b1a:	04260613          	addi	a2,a2,66 # ffffffffc0206b58 <commands+0x960>
ffffffffc0201b1e:	07100593          	li	a1,113
ffffffffc0201b22:	00005517          	auipc	a0,0x5
ffffffffc0201b26:	02650513          	addi	a0,a0,38 # ffffffffc0206b48 <commands+0x950>
ffffffffc0201b2a:	ef4fe0ef          	jal	ra,ffffffffc020021e <__panic>
ffffffffc0201b2e:	8e1ff0ef          	jal	ra,ffffffffc020140e <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0201b32:	00005697          	auipc	a3,0x5
ffffffffc0201b36:	0ce68693          	addi	a3,a3,206 # ffffffffc0206c00 <commands+0xa08>
ffffffffc0201b3a:	00005617          	auipc	a2,0x5
ffffffffc0201b3e:	0ae60613          	addi	a2,a2,174 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0201b42:	13600593          	li	a1,310
ffffffffc0201b46:	00005517          	auipc	a0,0x5
ffffffffc0201b4a:	06250513          	addi	a0,a0,98 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0201b4e:	ed0fe0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0201b52 <page_remove>:
{
ffffffffc0201b52:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201b54:	4601                	li	a2,0
{
ffffffffc0201b56:	ec26                	sd	s1,24(sp)
ffffffffc0201b58:	f406                	sd	ra,40(sp)
ffffffffc0201b5a:	f022                	sd	s0,32(sp)
ffffffffc0201b5c:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201b5e:	9a1ff0ef          	jal	ra,ffffffffc02014fe <get_pte>
    if (ptep != NULL)
ffffffffc0201b62:	c511                	beqz	a0,ffffffffc0201b6e <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201b64:	611c                	ld	a5,0(a0)
ffffffffc0201b66:	842a                	mv	s0,a0
ffffffffc0201b68:	0017f713          	andi	a4,a5,1
ffffffffc0201b6c:	e711                	bnez	a4,ffffffffc0201b78 <page_remove+0x26>
}
ffffffffc0201b6e:	70a2                	ld	ra,40(sp)
ffffffffc0201b70:	7402                	ld	s0,32(sp)
ffffffffc0201b72:	64e2                	ld	s1,24(sp)
ffffffffc0201b74:	6145                	addi	sp,sp,48
ffffffffc0201b76:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201b78:	078a                	slli	a5,a5,0x2
ffffffffc0201b7a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201b7c:	000c4717          	auipc	a4,0xc4
ffffffffc0201b80:	5dc73703          	ld	a4,1500(a4) # ffffffffc02c6158 <npage>
ffffffffc0201b84:	06e7f363          	bgeu	a5,a4,ffffffffc0201bea <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b88:	fff80537          	lui	a0,0xfff80
ffffffffc0201b8c:	97aa                	add	a5,a5,a0
ffffffffc0201b8e:	079a                	slli	a5,a5,0x6
ffffffffc0201b90:	000c4517          	auipc	a0,0xc4
ffffffffc0201b94:	5d053503          	ld	a0,1488(a0) # ffffffffc02c6160 <pages>
ffffffffc0201b98:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201b9a:	411c                	lw	a5,0(a0)
ffffffffc0201b9c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201ba0:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0201ba2:	cb11                	beqz	a4,ffffffffc0201bb6 <page_remove+0x64>
        *ptep = 0;
ffffffffc0201ba4:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201ba8:	12048073          	sfence.vma	s1
}
ffffffffc0201bac:	70a2                	ld	ra,40(sp)
ffffffffc0201bae:	7402                	ld	s0,32(sp)
ffffffffc0201bb0:	64e2                	ld	s1,24(sp)
ffffffffc0201bb2:	6145                	addi	sp,sp,48
ffffffffc0201bb4:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bb6:	100027f3          	csrr	a5,sstatus
ffffffffc0201bba:	8b89                	andi	a5,a5,2
ffffffffc0201bbc:	eb89                	bnez	a5,ffffffffc0201bce <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0201bbe:	000c4797          	auipc	a5,0xc4
ffffffffc0201bc2:	5aa7b783          	ld	a5,1450(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc0201bc6:	739c                	ld	a5,32(a5)
ffffffffc0201bc8:	4585                	li	a1,1
ffffffffc0201bca:	9782                	jalr	a5
    if (flag)
ffffffffc0201bcc:	bfe1                	j	ffffffffc0201ba4 <page_remove+0x52>
        intr_disable();
ffffffffc0201bce:	e42a                	sd	a0,8(sp)
ffffffffc0201bd0:	eb5fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc0201bd4:	000c4797          	auipc	a5,0xc4
ffffffffc0201bd8:	5947b783          	ld	a5,1428(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc0201bdc:	739c                	ld	a5,32(a5)
ffffffffc0201bde:	6522                	ld	a0,8(sp)
ffffffffc0201be0:	4585                	li	a1,1
ffffffffc0201be2:	9782                	jalr	a5
        intr_enable();
ffffffffc0201be4:	e9bfe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0201be8:	bf75                	j	ffffffffc0201ba4 <page_remove+0x52>
ffffffffc0201bea:	825ff0ef          	jal	ra,ffffffffc020140e <pa2page.part.0>

ffffffffc0201bee <page_insert>:
{
ffffffffc0201bee:	7139                	addi	sp,sp,-64
ffffffffc0201bf0:	e852                	sd	s4,16(sp)
ffffffffc0201bf2:	8a32                	mv	s4,a2
ffffffffc0201bf4:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201bf6:	4605                	li	a2,1
{
ffffffffc0201bf8:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201bfa:	85d2                	mv	a1,s4
{
ffffffffc0201bfc:	f426                	sd	s1,40(sp)
ffffffffc0201bfe:	fc06                	sd	ra,56(sp)
ffffffffc0201c00:	f04a                	sd	s2,32(sp)
ffffffffc0201c02:	ec4e                	sd	s3,24(sp)
ffffffffc0201c04:	e456                	sd	s5,8(sp)
ffffffffc0201c06:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201c08:	8f7ff0ef          	jal	ra,ffffffffc02014fe <get_pte>
    if (ptep == NULL)
ffffffffc0201c0c:	c961                	beqz	a0,ffffffffc0201cdc <page_insert+0xee>
    page->ref += 1;
ffffffffc0201c0e:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0201c10:	611c                	ld	a5,0(a0)
ffffffffc0201c12:	89aa                	mv	s3,a0
ffffffffc0201c14:	0016871b          	addiw	a4,a3,1
ffffffffc0201c18:	c018                	sw	a4,0(s0)
ffffffffc0201c1a:	0017f713          	andi	a4,a5,1
ffffffffc0201c1e:	ef05                	bnez	a4,ffffffffc0201c56 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0201c20:	000c4717          	auipc	a4,0xc4
ffffffffc0201c24:	54073703          	ld	a4,1344(a4) # ffffffffc02c6160 <pages>
ffffffffc0201c28:	8c19                	sub	s0,s0,a4
ffffffffc0201c2a:	000807b7          	lui	a5,0x80
ffffffffc0201c2e:	8419                	srai	s0,s0,0x6
ffffffffc0201c30:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201c32:	042a                	slli	s0,s0,0xa
ffffffffc0201c34:	8cc1                	or	s1,s1,s0
ffffffffc0201c36:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201c3a:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4910>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201c3e:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0201c42:	4501                	li	a0,0
}
ffffffffc0201c44:	70e2                	ld	ra,56(sp)
ffffffffc0201c46:	7442                	ld	s0,48(sp)
ffffffffc0201c48:	74a2                	ld	s1,40(sp)
ffffffffc0201c4a:	7902                	ld	s2,32(sp)
ffffffffc0201c4c:	69e2                	ld	s3,24(sp)
ffffffffc0201c4e:	6a42                	ld	s4,16(sp)
ffffffffc0201c50:	6aa2                	ld	s5,8(sp)
ffffffffc0201c52:	6121                	addi	sp,sp,64
ffffffffc0201c54:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201c56:	078a                	slli	a5,a5,0x2
ffffffffc0201c58:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201c5a:	000c4717          	auipc	a4,0xc4
ffffffffc0201c5e:	4fe73703          	ld	a4,1278(a4) # ffffffffc02c6158 <npage>
ffffffffc0201c62:	06e7ff63          	bgeu	a5,a4,ffffffffc0201ce0 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201c66:	000c4a97          	auipc	s5,0xc4
ffffffffc0201c6a:	4faa8a93          	addi	s5,s5,1274 # ffffffffc02c6160 <pages>
ffffffffc0201c6e:	000ab703          	ld	a4,0(s5)
ffffffffc0201c72:	fff80937          	lui	s2,0xfff80
ffffffffc0201c76:	993e                	add	s2,s2,a5
ffffffffc0201c78:	091a                	slli	s2,s2,0x6
ffffffffc0201c7a:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0201c7c:	01240c63          	beq	s0,s2,ffffffffc0201c94 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0201c80:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcb9e64>
ffffffffc0201c84:	fff7869b          	addiw	a3,a5,-1
ffffffffc0201c88:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0201c8c:	c691                	beqz	a3,ffffffffc0201c98 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201c8e:	120a0073          	sfence.vma	s4
}
ffffffffc0201c92:	bf59                	j	ffffffffc0201c28 <page_insert+0x3a>
ffffffffc0201c94:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201c96:	bf49                	j	ffffffffc0201c28 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c98:	100027f3          	csrr	a5,sstatus
ffffffffc0201c9c:	8b89                	andi	a5,a5,2
ffffffffc0201c9e:	ef91                	bnez	a5,ffffffffc0201cba <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0201ca0:	000c4797          	auipc	a5,0xc4
ffffffffc0201ca4:	4c87b783          	ld	a5,1224(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc0201ca8:	739c                	ld	a5,32(a5)
ffffffffc0201caa:	4585                	li	a1,1
ffffffffc0201cac:	854a                	mv	a0,s2
ffffffffc0201cae:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0201cb0:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201cb4:	120a0073          	sfence.vma	s4
ffffffffc0201cb8:	bf85                	j	ffffffffc0201c28 <page_insert+0x3a>
        intr_disable();
ffffffffc0201cba:	dcbfe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cbe:	000c4797          	auipc	a5,0xc4
ffffffffc0201cc2:	4aa7b783          	ld	a5,1194(a5) # ffffffffc02c6168 <pmm_manager>
ffffffffc0201cc6:	739c                	ld	a5,32(a5)
ffffffffc0201cc8:	4585                	li	a1,1
ffffffffc0201cca:	854a                	mv	a0,s2
ffffffffc0201ccc:	9782                	jalr	a5
        intr_enable();
ffffffffc0201cce:	db1fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0201cd2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201cd6:	120a0073          	sfence.vma	s4
ffffffffc0201cda:	b7b9                	j	ffffffffc0201c28 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0201cdc:	5571                	li	a0,-4
ffffffffc0201cde:	b79d                	j	ffffffffc0201c44 <page_insert+0x56>
ffffffffc0201ce0:	f2eff0ef          	jal	ra,ffffffffc020140e <pa2page.part.0>

ffffffffc0201ce4 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201ce4:	00006797          	auipc	a5,0x6
ffffffffc0201ce8:	bc478793          	addi	a5,a5,-1084 # ffffffffc02078a8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201cec:	638c                	ld	a1,0(a5)
{
ffffffffc0201cee:	7159                	addi	sp,sp,-112
ffffffffc0201cf0:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201cf2:	00005517          	auipc	a0,0x5
ffffffffc0201cf6:	f2650513          	addi	a0,a0,-218 # ffffffffc0206c18 <commands+0xa20>
    pmm_manager = &default_pmm_manager;
ffffffffc0201cfa:	000c4b17          	auipc	s6,0xc4
ffffffffc0201cfe:	46eb0b13          	addi	s6,s6,1134 # ffffffffc02c6168 <pmm_manager>
{
ffffffffc0201d02:	f486                	sd	ra,104(sp)
ffffffffc0201d04:	e8ca                	sd	s2,80(sp)
ffffffffc0201d06:	e4ce                	sd	s3,72(sp)
ffffffffc0201d08:	f0a2                	sd	s0,96(sp)
ffffffffc0201d0a:	eca6                	sd	s1,88(sp)
ffffffffc0201d0c:	e0d2                	sd	s4,64(sp)
ffffffffc0201d0e:	fc56                	sd	s5,56(sp)
ffffffffc0201d10:	f45e                	sd	s7,40(sp)
ffffffffc0201d12:	f062                	sd	s8,32(sp)
ffffffffc0201d14:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201d16:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201d1a:	bc6fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    pmm_manager->init();
ffffffffc0201d1e:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201d22:	000c4997          	auipc	s3,0xc4
ffffffffc0201d26:	44e98993          	addi	s3,s3,1102 # ffffffffc02c6170 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201d2a:	679c                	ld	a5,8(a5)
ffffffffc0201d2c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201d2e:	57f5                	li	a5,-3
ffffffffc0201d30:	07fa                	slli	a5,a5,0x1e
ffffffffc0201d32:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201d36:	c6dfe0ef          	jal	ra,ffffffffc02009a2 <get_memory_base>
ffffffffc0201d3a:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0201d3c:	c71fe0ef          	jal	ra,ffffffffc02009ac <get_memory_size>
    if (mem_size == 0)
ffffffffc0201d40:	200505e3          	beqz	a0,ffffffffc020274a <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0201d44:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0201d46:	00005517          	auipc	a0,0x5
ffffffffc0201d4a:	f0a50513          	addi	a0,a0,-246 # ffffffffc0206c50 <commands+0xa58>
ffffffffc0201d4e:	b92fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0201d52:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201d56:	fff40693          	addi	a3,s0,-1
ffffffffc0201d5a:	864a                	mv	a2,s2
ffffffffc0201d5c:	85a6                	mv	a1,s1
ffffffffc0201d5e:	00005517          	auipc	a0,0x5
ffffffffc0201d62:	f0a50513          	addi	a0,a0,-246 # ffffffffc0206c68 <commands+0xa70>
ffffffffc0201d66:	b7afe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201d6a:	c8000737          	lui	a4,0xc8000
ffffffffc0201d6e:	87a2                	mv	a5,s0
ffffffffc0201d70:	54876163          	bltu	a4,s0,ffffffffc02022b2 <pmm_init+0x5ce>
ffffffffc0201d74:	757d                	lui	a0,0xfffff
ffffffffc0201d76:	000c5617          	auipc	a2,0xc5
ffffffffc0201d7a:	42560613          	addi	a2,a2,1061 # ffffffffc02c719b <end+0xfff>
ffffffffc0201d7e:	8e69                	and	a2,a2,a0
ffffffffc0201d80:	000c4497          	auipc	s1,0xc4
ffffffffc0201d84:	3d848493          	addi	s1,s1,984 # ffffffffc02c6158 <npage>
ffffffffc0201d88:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201d8c:	000c4b97          	auipc	s7,0xc4
ffffffffc0201d90:	3d4b8b93          	addi	s7,s7,980 # ffffffffc02c6160 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201d94:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201d96:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201d9a:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201d9e:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201da0:	02f50863          	beq	a0,a5,ffffffffc0201dd0 <pmm_init+0xec>
ffffffffc0201da4:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201da6:	4585                	li	a1,1
ffffffffc0201da8:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201dac:	00679513          	slli	a0,a5,0x6
ffffffffc0201db0:	9532                	add	a0,a0,a2
ffffffffc0201db2:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd38e6c>
ffffffffc0201db6:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201dba:	6088                	ld	a0,0(s1)
ffffffffc0201dbc:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201dbe:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201dc2:	00d50733          	add	a4,a0,a3
ffffffffc0201dc6:	fee7e3e3          	bltu	a5,a4,ffffffffc0201dac <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201dca:	071a                	slli	a4,a4,0x6
ffffffffc0201dcc:	00e606b3          	add	a3,a2,a4
ffffffffc0201dd0:	c02007b7          	lui	a5,0xc0200
ffffffffc0201dd4:	2ef6ece3          	bltu	a3,a5,ffffffffc02028cc <pmm_init+0xbe8>
ffffffffc0201dd8:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201ddc:	77fd                	lui	a5,0xfffff
ffffffffc0201dde:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201de0:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0201de2:	5086eb63          	bltu	a3,s0,ffffffffc02022f8 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0201de6:	00005517          	auipc	a0,0x5
ffffffffc0201dea:	ed250513          	addi	a0,a0,-302 # ffffffffc0206cb8 <commands+0xac0>
ffffffffc0201dee:	af2fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201df2:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0201df6:	000c4917          	auipc	s2,0xc4
ffffffffc0201dfa:	35a90913          	addi	s2,s2,858 # ffffffffc02c6150 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0201dfe:	7b9c                	ld	a5,48(a5)
ffffffffc0201e00:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201e02:	00005517          	auipc	a0,0x5
ffffffffc0201e06:	ece50513          	addi	a0,a0,-306 # ffffffffc0206cd0 <commands+0xad8>
ffffffffc0201e0a:	ad6fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0201e0e:	00009697          	auipc	a3,0x9
ffffffffc0201e12:	1f268693          	addi	a3,a3,498 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0201e16:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0201e1a:	c02007b7          	lui	a5,0xc0200
ffffffffc0201e1e:	28f6ebe3          	bltu	a3,a5,ffffffffc02028b4 <pmm_init+0xbd0>
ffffffffc0201e22:	0009b783          	ld	a5,0(s3)
ffffffffc0201e26:	8e9d                	sub	a3,a3,a5
ffffffffc0201e28:	000c4797          	auipc	a5,0xc4
ffffffffc0201e2c:	32d7b023          	sd	a3,800(a5) # ffffffffc02c6148 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e30:	100027f3          	csrr	a5,sstatus
ffffffffc0201e34:	8b89                	andi	a5,a5,2
ffffffffc0201e36:	4a079763          	bnez	a5,ffffffffc02022e4 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e3a:	000b3783          	ld	a5,0(s6)
ffffffffc0201e3e:	779c                	ld	a5,40(a5)
ffffffffc0201e40:	9782                	jalr	a5
ffffffffc0201e42:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201e44:	6098                	ld	a4,0(s1)
ffffffffc0201e46:	c80007b7          	lui	a5,0xc8000
ffffffffc0201e4a:	83b1                	srli	a5,a5,0xc
ffffffffc0201e4c:	66e7e363          	bltu	a5,a4,ffffffffc02024b2 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201e50:	00093503          	ld	a0,0(s2)
ffffffffc0201e54:	62050f63          	beqz	a0,ffffffffc0202492 <pmm_init+0x7ae>
ffffffffc0201e58:	03451793          	slli	a5,a0,0x34
ffffffffc0201e5c:	62079b63          	bnez	a5,ffffffffc0202492 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201e60:	4601                	li	a2,0
ffffffffc0201e62:	4581                	li	a1,0
ffffffffc0201e64:	8c3ff0ef          	jal	ra,ffffffffc0201726 <get_page>
ffffffffc0201e68:	60051563          	bnez	a0,ffffffffc0202472 <pmm_init+0x78e>
ffffffffc0201e6c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e70:	8b89                	andi	a5,a5,2
ffffffffc0201e72:	44079e63          	bnez	a5,ffffffffc02022ce <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e76:	000b3783          	ld	a5,0(s6)
ffffffffc0201e7a:	4505                	li	a0,1
ffffffffc0201e7c:	6f9c                	ld	a5,24(a5)
ffffffffc0201e7e:	9782                	jalr	a5
ffffffffc0201e80:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201e82:	00093503          	ld	a0,0(s2)
ffffffffc0201e86:	4681                	li	a3,0
ffffffffc0201e88:	4601                	li	a2,0
ffffffffc0201e8a:	85d2                	mv	a1,s4
ffffffffc0201e8c:	d63ff0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc0201e90:	26051ae3          	bnez	a0,ffffffffc0202904 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201e94:	00093503          	ld	a0,0(s2)
ffffffffc0201e98:	4601                	li	a2,0
ffffffffc0201e9a:	4581                	li	a1,0
ffffffffc0201e9c:	e62ff0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc0201ea0:	240502e3          	beqz	a0,ffffffffc02028e4 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0201ea4:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201ea6:	0017f713          	andi	a4,a5,1
ffffffffc0201eaa:	5a070263          	beqz	a4,ffffffffc020244e <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0201eae:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201eb0:	078a                	slli	a5,a5,0x2
ffffffffc0201eb2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201eb4:	58e7fb63          	bgeu	a5,a4,ffffffffc020244a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201eb8:	000bb683          	ld	a3,0(s7)
ffffffffc0201ebc:	fff80637          	lui	a2,0xfff80
ffffffffc0201ec0:	97b2                	add	a5,a5,a2
ffffffffc0201ec2:	079a                	slli	a5,a5,0x6
ffffffffc0201ec4:	97b6                	add	a5,a5,a3
ffffffffc0201ec6:	14fa17e3          	bne	s4,a5,ffffffffc0202814 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0201eca:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x9180>
ffffffffc0201ece:	4785                	li	a5,1
ffffffffc0201ed0:	12f692e3          	bne	a3,a5,ffffffffc02027f4 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0201ed4:	00093503          	ld	a0,0(s2)
ffffffffc0201ed8:	77fd                	lui	a5,0xfffff
ffffffffc0201eda:	6114                	ld	a3,0(a0)
ffffffffc0201edc:	068a                	slli	a3,a3,0x2
ffffffffc0201ede:	8efd                	and	a3,a3,a5
ffffffffc0201ee0:	00c6d613          	srli	a2,a3,0xc
ffffffffc0201ee4:	0ee67ce3          	bgeu	a2,a4,ffffffffc02027dc <pmm_init+0xaf8>
ffffffffc0201ee8:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201eec:	96e2                	add	a3,a3,s8
ffffffffc0201eee:	0006ba83          	ld	s5,0(a3)
ffffffffc0201ef2:	0a8a                	slli	s5,s5,0x2
ffffffffc0201ef4:	00fafab3          	and	s5,s5,a5
ffffffffc0201ef8:	00cad793          	srli	a5,s5,0xc
ffffffffc0201efc:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02027c2 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201f00:	4601                	li	a2,0
ffffffffc0201f02:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201f04:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201f06:	df8ff0ef          	jal	ra,ffffffffc02014fe <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201f0a:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201f0c:	55551363          	bne	a0,s5,ffffffffc0202452 <pmm_init+0x76e>
ffffffffc0201f10:	100027f3          	csrr	a5,sstatus
ffffffffc0201f14:	8b89                	andi	a5,a5,2
ffffffffc0201f16:	3a079163          	bnez	a5,ffffffffc02022b8 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f1a:	000b3783          	ld	a5,0(s6)
ffffffffc0201f1e:	4505                	li	a0,1
ffffffffc0201f20:	6f9c                	ld	a5,24(a5)
ffffffffc0201f22:	9782                	jalr	a5
ffffffffc0201f24:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201f26:	00093503          	ld	a0,0(s2)
ffffffffc0201f2a:	46d1                	li	a3,20
ffffffffc0201f2c:	6605                	lui	a2,0x1
ffffffffc0201f2e:	85e2                	mv	a1,s8
ffffffffc0201f30:	cbfff0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc0201f34:	060517e3          	bnez	a0,ffffffffc02027a2 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201f38:	00093503          	ld	a0,0(s2)
ffffffffc0201f3c:	4601                	li	a2,0
ffffffffc0201f3e:	6585                	lui	a1,0x1
ffffffffc0201f40:	dbeff0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc0201f44:	02050fe3          	beqz	a0,ffffffffc0202782 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0201f48:	611c                	ld	a5,0(a0)
ffffffffc0201f4a:	0107f713          	andi	a4,a5,16
ffffffffc0201f4e:	7c070e63          	beqz	a4,ffffffffc020272a <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0201f52:	8b91                	andi	a5,a5,4
ffffffffc0201f54:	7a078b63          	beqz	a5,ffffffffc020270a <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0201f58:	00093503          	ld	a0,0(s2)
ffffffffc0201f5c:	611c                	ld	a5,0(a0)
ffffffffc0201f5e:	8bc1                	andi	a5,a5,16
ffffffffc0201f60:	78078563          	beqz	a5,ffffffffc02026ea <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0201f64:	000c2703          	lw	a4,0(s8)
ffffffffc0201f68:	4785                	li	a5,1
ffffffffc0201f6a:	76f71063          	bne	a4,a5,ffffffffc02026ca <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201f6e:	4681                	li	a3,0
ffffffffc0201f70:	6605                	lui	a2,0x1
ffffffffc0201f72:	85d2                	mv	a1,s4
ffffffffc0201f74:	c7bff0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc0201f78:	72051963          	bnez	a0,ffffffffc02026aa <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0201f7c:	000a2703          	lw	a4,0(s4)
ffffffffc0201f80:	4789                	li	a5,2
ffffffffc0201f82:	70f71463          	bne	a4,a5,ffffffffc020268a <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0201f86:	000c2783          	lw	a5,0(s8)
ffffffffc0201f8a:	6e079063          	bnez	a5,ffffffffc020266a <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201f8e:	00093503          	ld	a0,0(s2)
ffffffffc0201f92:	4601                	li	a2,0
ffffffffc0201f94:	6585                	lui	a1,0x1
ffffffffc0201f96:	d68ff0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc0201f9a:	6a050863          	beqz	a0,ffffffffc020264a <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0201f9e:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201fa0:	00177793          	andi	a5,a4,1
ffffffffc0201fa4:	4a078563          	beqz	a5,ffffffffc020244e <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0201fa8:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201faa:	00271793          	slli	a5,a4,0x2
ffffffffc0201fae:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fb0:	48d7fd63          	bgeu	a5,a3,ffffffffc020244a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fb4:	000bb683          	ld	a3,0(s7)
ffffffffc0201fb8:	fff80ab7          	lui	s5,0xfff80
ffffffffc0201fbc:	97d6                	add	a5,a5,s5
ffffffffc0201fbe:	079a                	slli	a5,a5,0x6
ffffffffc0201fc0:	97b6                	add	a5,a5,a3
ffffffffc0201fc2:	66fa1463          	bne	s4,a5,ffffffffc020262a <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201fc6:	8b41                	andi	a4,a4,16
ffffffffc0201fc8:	64071163          	bnez	a4,ffffffffc020260a <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0201fcc:	00093503          	ld	a0,0(s2)
ffffffffc0201fd0:	4581                	li	a1,0
ffffffffc0201fd2:	b81ff0ef          	jal	ra,ffffffffc0201b52 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201fd6:	000a2c83          	lw	s9,0(s4)
ffffffffc0201fda:	4785                	li	a5,1
ffffffffc0201fdc:	60fc9763          	bne	s9,a5,ffffffffc02025ea <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0201fe0:	000c2783          	lw	a5,0(s8)
ffffffffc0201fe4:	5e079363          	bnez	a5,ffffffffc02025ca <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0201fe8:	00093503          	ld	a0,0(s2)
ffffffffc0201fec:	6585                	lui	a1,0x1
ffffffffc0201fee:	b65ff0ef          	jal	ra,ffffffffc0201b52 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201ff2:	000a2783          	lw	a5,0(s4)
ffffffffc0201ff6:	52079a63          	bnez	a5,ffffffffc020252a <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0201ffa:	000c2783          	lw	a5,0(s8)
ffffffffc0201ffe:	50079663          	bnez	a5,ffffffffc020250a <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202002:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202006:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202008:	000a3683          	ld	a3,0(s4)
ffffffffc020200c:	068a                	slli	a3,a3,0x2
ffffffffc020200e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202010:	42b6fd63          	bgeu	a3,a1,ffffffffc020244a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202014:	000bb503          	ld	a0,0(s7)
ffffffffc0202018:	96d6                	add	a3,a3,s5
ffffffffc020201a:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020201c:	00d507b3          	add	a5,a0,a3
ffffffffc0202020:	439c                	lw	a5,0(a5)
ffffffffc0202022:	4d979463          	bne	a5,s9,ffffffffc02024ea <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202026:	8699                	srai	a3,a3,0x6
ffffffffc0202028:	00080637          	lui	a2,0x80
ffffffffc020202c:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020202e:	00c69713          	slli	a4,a3,0xc
ffffffffc0202032:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202034:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202036:	48b77e63          	bgeu	a4,a1,ffffffffc02024d2 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020203a:	0009b703          	ld	a4,0(s3)
ffffffffc020203e:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202040:	629c                	ld	a5,0(a3)
ffffffffc0202042:	078a                	slli	a5,a5,0x2
ffffffffc0202044:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202046:	40b7f263          	bgeu	a5,a1,ffffffffc020244a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020204a:	8f91                	sub	a5,a5,a2
ffffffffc020204c:	079a                	slli	a5,a5,0x6
ffffffffc020204e:	953e                	add	a0,a0,a5
ffffffffc0202050:	100027f3          	csrr	a5,sstatus
ffffffffc0202054:	8b89                	andi	a5,a5,2
ffffffffc0202056:	30079963          	bnez	a5,ffffffffc0202368 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc020205a:	000b3783          	ld	a5,0(s6)
ffffffffc020205e:	4585                	li	a1,1
ffffffffc0202060:	739c                	ld	a5,32(a5)
ffffffffc0202062:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202064:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202068:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020206a:	078a                	slli	a5,a5,0x2
ffffffffc020206c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020206e:	3ce7fe63          	bgeu	a5,a4,ffffffffc020244a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202072:	000bb503          	ld	a0,0(s7)
ffffffffc0202076:	fff80737          	lui	a4,0xfff80
ffffffffc020207a:	97ba                	add	a5,a5,a4
ffffffffc020207c:	079a                	slli	a5,a5,0x6
ffffffffc020207e:	953e                	add	a0,a0,a5
ffffffffc0202080:	100027f3          	csrr	a5,sstatus
ffffffffc0202084:	8b89                	andi	a5,a5,2
ffffffffc0202086:	2c079563          	bnez	a5,ffffffffc0202350 <pmm_init+0x66c>
ffffffffc020208a:	000b3783          	ld	a5,0(s6)
ffffffffc020208e:	4585                	li	a1,1
ffffffffc0202090:	739c                	ld	a5,32(a5)
ffffffffc0202092:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202094:	00093783          	ld	a5,0(s2)
ffffffffc0202098:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd38e64>
    asm volatile("sfence.vma");
ffffffffc020209c:	12000073          	sfence.vma
ffffffffc02020a0:	100027f3          	csrr	a5,sstatus
ffffffffc02020a4:	8b89                	andi	a5,a5,2
ffffffffc02020a6:	28079b63          	bnez	a5,ffffffffc020233c <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc02020aa:	000b3783          	ld	a5,0(s6)
ffffffffc02020ae:	779c                	ld	a5,40(a5)
ffffffffc02020b0:	9782                	jalr	a5
ffffffffc02020b2:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02020b4:	4b441b63          	bne	s0,s4,ffffffffc020256a <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02020b8:	00005517          	auipc	a0,0x5
ffffffffc02020bc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206ff8 <commands+0xe00>
ffffffffc02020c0:	820fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02020c4:	100027f3          	csrr	a5,sstatus
ffffffffc02020c8:	8b89                	andi	a5,a5,2
ffffffffc02020ca:	24079f63          	bnez	a5,ffffffffc0202328 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc02020ce:	000b3783          	ld	a5,0(s6)
ffffffffc02020d2:	779c                	ld	a5,40(a5)
ffffffffc02020d4:	9782                	jalr	a5
ffffffffc02020d6:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02020d8:	6098                	ld	a4,0(s1)
ffffffffc02020da:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02020de:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02020e0:	00c71793          	slli	a5,a4,0xc
ffffffffc02020e4:	6a05                	lui	s4,0x1
ffffffffc02020e6:	02f47c63          	bgeu	s0,a5,ffffffffc020211e <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02020ea:	00c45793          	srli	a5,s0,0xc
ffffffffc02020ee:	00093503          	ld	a0,0(s2)
ffffffffc02020f2:	2ee7ff63          	bgeu	a5,a4,ffffffffc02023f0 <pmm_init+0x70c>
ffffffffc02020f6:	0009b583          	ld	a1,0(s3)
ffffffffc02020fa:	4601                	li	a2,0
ffffffffc02020fc:	95a2                	add	a1,a1,s0
ffffffffc02020fe:	c00ff0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc0202102:	32050463          	beqz	a0,ffffffffc020242a <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202106:	611c                	ld	a5,0(a0)
ffffffffc0202108:	078a                	slli	a5,a5,0x2
ffffffffc020210a:	0157f7b3          	and	a5,a5,s5
ffffffffc020210e:	2e879e63          	bne	a5,s0,ffffffffc020240a <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202112:	6098                	ld	a4,0(s1)
ffffffffc0202114:	9452                	add	s0,s0,s4
ffffffffc0202116:	00c71793          	slli	a5,a4,0xc
ffffffffc020211a:	fcf468e3          	bltu	s0,a5,ffffffffc02020ea <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc020211e:	00093783          	ld	a5,0(s2)
ffffffffc0202122:	639c                	ld	a5,0(a5)
ffffffffc0202124:	42079363          	bnez	a5,ffffffffc020254a <pmm_init+0x866>
ffffffffc0202128:	100027f3          	csrr	a5,sstatus
ffffffffc020212c:	8b89                	andi	a5,a5,2
ffffffffc020212e:	24079963          	bnez	a5,ffffffffc0202380 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202132:	000b3783          	ld	a5,0(s6)
ffffffffc0202136:	4505                	li	a0,1
ffffffffc0202138:	6f9c                	ld	a5,24(a5)
ffffffffc020213a:	9782                	jalr	a5
ffffffffc020213c:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020213e:	00093503          	ld	a0,0(s2)
ffffffffc0202142:	4699                	li	a3,6
ffffffffc0202144:	10000613          	li	a2,256
ffffffffc0202148:	85d2                	mv	a1,s4
ffffffffc020214a:	aa5ff0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc020214e:	44051e63          	bnez	a0,ffffffffc02025aa <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202152:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x9180>
ffffffffc0202156:	4785                	li	a5,1
ffffffffc0202158:	42f71963          	bne	a4,a5,ffffffffc020258a <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020215c:	00093503          	ld	a0,0(s2)
ffffffffc0202160:	6405                	lui	s0,0x1
ffffffffc0202162:	4699                	li	a3,6
ffffffffc0202164:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x9080>
ffffffffc0202168:	85d2                	mv	a1,s4
ffffffffc020216a:	a85ff0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc020216e:	72051363          	bnez	a0,ffffffffc0202894 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202172:	000a2703          	lw	a4,0(s4)
ffffffffc0202176:	4789                	li	a5,2
ffffffffc0202178:	6ef71e63          	bne	a4,a5,ffffffffc0202874 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020217c:	00005597          	auipc	a1,0x5
ffffffffc0202180:	fc458593          	addi	a1,a1,-60 # ffffffffc0207140 <commands+0xf48>
ffffffffc0202184:	10000513          	li	a0,256
ffffffffc0202188:	7f8030ef          	jal	ra,ffffffffc0205980 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020218c:	10040593          	addi	a1,s0,256
ffffffffc0202190:	10000513          	li	a0,256
ffffffffc0202194:	7fe030ef          	jal	ra,ffffffffc0205992 <strcmp>
ffffffffc0202198:	6a051e63          	bnez	a0,ffffffffc0202854 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020219c:	000bb683          	ld	a3,0(s7)
ffffffffc02021a0:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02021a4:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02021a6:	40da06b3          	sub	a3,s4,a3
ffffffffc02021aa:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02021ac:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02021ae:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02021b0:	8031                	srli	s0,s0,0xc
ffffffffc02021b2:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02021b6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02021b8:	30f77d63          	bgeu	a4,a5,ffffffffc02024d2 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02021bc:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02021c0:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02021c4:	96be                	add	a3,a3,a5
ffffffffc02021c6:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02021ca:	780030ef          	jal	ra,ffffffffc020594a <strlen>
ffffffffc02021ce:	66051363          	bnez	a0,ffffffffc0202834 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc02021d2:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02021d6:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02021d8:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd38e64>
ffffffffc02021dc:	068a                	slli	a3,a3,0x2
ffffffffc02021de:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02021e0:	26f6f563          	bgeu	a3,a5,ffffffffc020244a <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc02021e4:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02021e6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02021e8:	2ef47563          	bgeu	s0,a5,ffffffffc02024d2 <pmm_init+0x7ee>
ffffffffc02021ec:	0009b403          	ld	s0,0(s3)
ffffffffc02021f0:	9436                	add	s0,s0,a3
ffffffffc02021f2:	100027f3          	csrr	a5,sstatus
ffffffffc02021f6:	8b89                	andi	a5,a5,2
ffffffffc02021f8:	1e079163          	bnez	a5,ffffffffc02023da <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc02021fc:	000b3783          	ld	a5,0(s6)
ffffffffc0202200:	4585                	li	a1,1
ffffffffc0202202:	8552                	mv	a0,s4
ffffffffc0202204:	739c                	ld	a5,32(a5)
ffffffffc0202206:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202208:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc020220a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020220c:	078a                	slli	a5,a5,0x2
ffffffffc020220e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202210:	22e7fd63          	bgeu	a5,a4,ffffffffc020244a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202214:	000bb503          	ld	a0,0(s7)
ffffffffc0202218:	fff80737          	lui	a4,0xfff80
ffffffffc020221c:	97ba                	add	a5,a5,a4
ffffffffc020221e:	079a                	slli	a5,a5,0x6
ffffffffc0202220:	953e                	add	a0,a0,a5
ffffffffc0202222:	100027f3          	csrr	a5,sstatus
ffffffffc0202226:	8b89                	andi	a5,a5,2
ffffffffc0202228:	18079d63          	bnez	a5,ffffffffc02023c2 <pmm_init+0x6de>
ffffffffc020222c:	000b3783          	ld	a5,0(s6)
ffffffffc0202230:	4585                	li	a1,1
ffffffffc0202232:	739c                	ld	a5,32(a5)
ffffffffc0202234:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202236:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc020223a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020223c:	078a                	slli	a5,a5,0x2
ffffffffc020223e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202240:	20e7f563          	bgeu	a5,a4,ffffffffc020244a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202244:	000bb503          	ld	a0,0(s7)
ffffffffc0202248:	fff80737          	lui	a4,0xfff80
ffffffffc020224c:	97ba                	add	a5,a5,a4
ffffffffc020224e:	079a                	slli	a5,a5,0x6
ffffffffc0202250:	953e                	add	a0,a0,a5
ffffffffc0202252:	100027f3          	csrr	a5,sstatus
ffffffffc0202256:	8b89                	andi	a5,a5,2
ffffffffc0202258:	14079963          	bnez	a5,ffffffffc02023aa <pmm_init+0x6c6>
ffffffffc020225c:	000b3783          	ld	a5,0(s6)
ffffffffc0202260:	4585                	li	a1,1
ffffffffc0202262:	739c                	ld	a5,32(a5)
ffffffffc0202264:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202266:	00093783          	ld	a5,0(s2)
ffffffffc020226a:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc020226e:	12000073          	sfence.vma
ffffffffc0202272:	100027f3          	csrr	a5,sstatus
ffffffffc0202276:	8b89                	andi	a5,a5,2
ffffffffc0202278:	10079f63          	bnez	a5,ffffffffc0202396 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc020227c:	000b3783          	ld	a5,0(s6)
ffffffffc0202280:	779c                	ld	a5,40(a5)
ffffffffc0202282:	9782                	jalr	a5
ffffffffc0202284:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202286:	4c8c1e63          	bne	s8,s0,ffffffffc0202762 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020228a:	00005517          	auipc	a0,0x5
ffffffffc020228e:	f2e50513          	addi	a0,a0,-210 # ffffffffc02071b8 <commands+0xfc0>
ffffffffc0202292:	e4ffd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0202296:	7406                	ld	s0,96(sp)
ffffffffc0202298:	70a6                	ld	ra,104(sp)
ffffffffc020229a:	64e6                	ld	s1,88(sp)
ffffffffc020229c:	6946                	ld	s2,80(sp)
ffffffffc020229e:	69a6                	ld	s3,72(sp)
ffffffffc02022a0:	6a06                	ld	s4,64(sp)
ffffffffc02022a2:	7ae2                	ld	s5,56(sp)
ffffffffc02022a4:	7b42                	ld	s6,48(sp)
ffffffffc02022a6:	7ba2                	ld	s7,40(sp)
ffffffffc02022a8:	7c02                	ld	s8,32(sp)
ffffffffc02022aa:	6ce2                	ld	s9,24(sp)
ffffffffc02022ac:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02022ae:	5460106f          	j	ffffffffc02037f4 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc02022b2:	c80007b7          	lui	a5,0xc8000
ffffffffc02022b6:	bc7d                	j	ffffffffc0201d74 <pmm_init+0x90>
        intr_disable();
ffffffffc02022b8:	fccfe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022bc:	000b3783          	ld	a5,0(s6)
ffffffffc02022c0:	4505                	li	a0,1
ffffffffc02022c2:	6f9c                	ld	a5,24(a5)
ffffffffc02022c4:	9782                	jalr	a5
ffffffffc02022c6:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02022c8:	fb6fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02022cc:	b9a9                	j	ffffffffc0201f26 <pmm_init+0x242>
        intr_disable();
ffffffffc02022ce:	fb6fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc02022d2:	000b3783          	ld	a5,0(s6)
ffffffffc02022d6:	4505                	li	a0,1
ffffffffc02022d8:	6f9c                	ld	a5,24(a5)
ffffffffc02022da:	9782                	jalr	a5
ffffffffc02022dc:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02022de:	fa0fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02022e2:	b645                	j	ffffffffc0201e82 <pmm_init+0x19e>
        intr_disable();
ffffffffc02022e4:	fa0fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022e8:	000b3783          	ld	a5,0(s6)
ffffffffc02022ec:	779c                	ld	a5,40(a5)
ffffffffc02022ee:	9782                	jalr	a5
ffffffffc02022f0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02022f2:	f8cfe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02022f6:	b6b9                	j	ffffffffc0201e44 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02022f8:	6705                	lui	a4,0x1
ffffffffc02022fa:	177d                	addi	a4,a4,-1
ffffffffc02022fc:	96ba                	add	a3,a3,a4
ffffffffc02022fe:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202300:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202304:	14a77363          	bgeu	a4,a0,ffffffffc020244a <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202308:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020230c:	fff80537          	lui	a0,0xfff80
ffffffffc0202310:	972a                	add	a4,a4,a0
ffffffffc0202312:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202314:	8c1d                	sub	s0,s0,a5
ffffffffc0202316:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020231a:	00c45593          	srli	a1,s0,0xc
ffffffffc020231e:	9532                	add	a0,a0,a2
ffffffffc0202320:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202322:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202326:	b4c1                	j	ffffffffc0201de6 <pmm_init+0x102>
        intr_disable();
ffffffffc0202328:	f5cfe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020232c:	000b3783          	ld	a5,0(s6)
ffffffffc0202330:	779c                	ld	a5,40(a5)
ffffffffc0202332:	9782                	jalr	a5
ffffffffc0202334:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202336:	f48fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc020233a:	bb79                	j	ffffffffc02020d8 <pmm_init+0x3f4>
        intr_disable();
ffffffffc020233c:	f48fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc0202340:	000b3783          	ld	a5,0(s6)
ffffffffc0202344:	779c                	ld	a5,40(a5)
ffffffffc0202346:	9782                	jalr	a5
ffffffffc0202348:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020234a:	f34fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc020234e:	b39d                	j	ffffffffc02020b4 <pmm_init+0x3d0>
ffffffffc0202350:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202352:	f32fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202356:	000b3783          	ld	a5,0(s6)
ffffffffc020235a:	6522                	ld	a0,8(sp)
ffffffffc020235c:	4585                	li	a1,1
ffffffffc020235e:	739c                	ld	a5,32(a5)
ffffffffc0202360:	9782                	jalr	a5
        intr_enable();
ffffffffc0202362:	f1cfe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0202366:	b33d                	j	ffffffffc0202094 <pmm_init+0x3b0>
ffffffffc0202368:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020236a:	f1afe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc020236e:	000b3783          	ld	a5,0(s6)
ffffffffc0202372:	6522                	ld	a0,8(sp)
ffffffffc0202374:	4585                	li	a1,1
ffffffffc0202376:	739c                	ld	a5,32(a5)
ffffffffc0202378:	9782                	jalr	a5
        intr_enable();
ffffffffc020237a:	f04fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc020237e:	b1dd                	j	ffffffffc0202064 <pmm_init+0x380>
        intr_disable();
ffffffffc0202380:	f04fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202384:	000b3783          	ld	a5,0(s6)
ffffffffc0202388:	4505                	li	a0,1
ffffffffc020238a:	6f9c                	ld	a5,24(a5)
ffffffffc020238c:	9782                	jalr	a5
ffffffffc020238e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202390:	eeefe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0202394:	b36d                	j	ffffffffc020213e <pmm_init+0x45a>
        intr_disable();
ffffffffc0202396:	eeefe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020239a:	000b3783          	ld	a5,0(s6)
ffffffffc020239e:	779c                	ld	a5,40(a5)
ffffffffc02023a0:	9782                	jalr	a5
ffffffffc02023a2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02023a4:	edafe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02023a8:	bdf9                	j	ffffffffc0202286 <pmm_init+0x5a2>
ffffffffc02023aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02023ac:	ed8fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02023b0:	000b3783          	ld	a5,0(s6)
ffffffffc02023b4:	6522                	ld	a0,8(sp)
ffffffffc02023b6:	4585                	li	a1,1
ffffffffc02023b8:	739c                	ld	a5,32(a5)
ffffffffc02023ba:	9782                	jalr	a5
        intr_enable();
ffffffffc02023bc:	ec2fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02023c0:	b55d                	j	ffffffffc0202266 <pmm_init+0x582>
ffffffffc02023c2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02023c4:	ec0fe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc02023c8:	000b3783          	ld	a5,0(s6)
ffffffffc02023cc:	6522                	ld	a0,8(sp)
ffffffffc02023ce:	4585                	li	a1,1
ffffffffc02023d0:	739c                	ld	a5,32(a5)
ffffffffc02023d2:	9782                	jalr	a5
        intr_enable();
ffffffffc02023d4:	eaafe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02023d8:	bdb9                	j	ffffffffc0202236 <pmm_init+0x552>
        intr_disable();
ffffffffc02023da:	eaafe0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc02023de:	000b3783          	ld	a5,0(s6)
ffffffffc02023e2:	4585                	li	a1,1
ffffffffc02023e4:	8552                	mv	a0,s4
ffffffffc02023e6:	739c                	ld	a5,32(a5)
ffffffffc02023e8:	9782                	jalr	a5
        intr_enable();
ffffffffc02023ea:	e94fe0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02023ee:	bd29                	j	ffffffffc0202208 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02023f0:	86a2                	mv	a3,s0
ffffffffc02023f2:	00004617          	auipc	a2,0x4
ffffffffc02023f6:	76660613          	addi	a2,a2,1894 # ffffffffc0206b58 <commands+0x960>
ffffffffc02023fa:	25100593          	li	a1,593
ffffffffc02023fe:	00004517          	auipc	a0,0x4
ffffffffc0202402:	7aa50513          	addi	a0,a0,1962 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202406:	e19fd0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020240a:	00005697          	auipc	a3,0x5
ffffffffc020240e:	c4e68693          	addi	a3,a3,-946 # ffffffffc0207058 <commands+0xe60>
ffffffffc0202412:	00004617          	auipc	a2,0x4
ffffffffc0202416:	7d660613          	addi	a2,a2,2006 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020241a:	25200593          	li	a1,594
ffffffffc020241e:	00004517          	auipc	a0,0x4
ffffffffc0202422:	78a50513          	addi	a0,a0,1930 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202426:	df9fd0ef          	jal	ra,ffffffffc020021e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020242a:	00005697          	auipc	a3,0x5
ffffffffc020242e:	bee68693          	addi	a3,a3,-1042 # ffffffffc0207018 <commands+0xe20>
ffffffffc0202432:	00004617          	auipc	a2,0x4
ffffffffc0202436:	7b660613          	addi	a2,a2,1974 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020243a:	25100593          	li	a1,593
ffffffffc020243e:	00004517          	auipc	a0,0x4
ffffffffc0202442:	76a50513          	addi	a0,a0,1898 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202446:	dd9fd0ef          	jal	ra,ffffffffc020021e <__panic>
ffffffffc020244a:	fc5fe0ef          	jal	ra,ffffffffc020140e <pa2page.part.0>
ffffffffc020244e:	fddfe0ef          	jal	ra,ffffffffc020142a <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202452:	00005697          	auipc	a3,0x5
ffffffffc0202456:	9be68693          	addi	a3,a3,-1602 # ffffffffc0206e10 <commands+0xc18>
ffffffffc020245a:	00004617          	auipc	a2,0x4
ffffffffc020245e:	78e60613          	addi	a2,a2,1934 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202462:	22100593          	li	a1,545
ffffffffc0202466:	00004517          	auipc	a0,0x4
ffffffffc020246a:	74250513          	addi	a0,a0,1858 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc020246e:	db1fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202472:	00005697          	auipc	a3,0x5
ffffffffc0202476:	8de68693          	addi	a3,a3,-1826 # ffffffffc0206d50 <commands+0xb58>
ffffffffc020247a:	00004617          	auipc	a2,0x4
ffffffffc020247e:	76e60613          	addi	a2,a2,1902 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202482:	21400593          	li	a1,532
ffffffffc0202486:	00004517          	auipc	a0,0x4
ffffffffc020248a:	72250513          	addi	a0,a0,1826 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc020248e:	d91fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202492:	00005697          	auipc	a3,0x5
ffffffffc0202496:	87e68693          	addi	a3,a3,-1922 # ffffffffc0206d10 <commands+0xb18>
ffffffffc020249a:	00004617          	auipc	a2,0x4
ffffffffc020249e:	74e60613          	addi	a2,a2,1870 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02024a2:	21300593          	li	a1,531
ffffffffc02024a6:	00004517          	auipc	a0,0x4
ffffffffc02024aa:	70250513          	addi	a0,a0,1794 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02024ae:	d71fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02024b2:	00005697          	auipc	a3,0x5
ffffffffc02024b6:	83e68693          	addi	a3,a3,-1986 # ffffffffc0206cf0 <commands+0xaf8>
ffffffffc02024ba:	00004617          	auipc	a2,0x4
ffffffffc02024be:	72e60613          	addi	a2,a2,1838 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02024c2:	21200593          	li	a1,530
ffffffffc02024c6:	00004517          	auipc	a0,0x4
ffffffffc02024ca:	6e250513          	addi	a0,a0,1762 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02024ce:	d51fd0ef          	jal	ra,ffffffffc020021e <__panic>
    return KADDR(page2pa(page));
ffffffffc02024d2:	00004617          	auipc	a2,0x4
ffffffffc02024d6:	68660613          	addi	a2,a2,1670 # ffffffffc0206b58 <commands+0x960>
ffffffffc02024da:	07100593          	li	a1,113
ffffffffc02024de:	00004517          	auipc	a0,0x4
ffffffffc02024e2:	66a50513          	addi	a0,a0,1642 # ffffffffc0206b48 <commands+0x950>
ffffffffc02024e6:	d39fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02024ea:	00005697          	auipc	a3,0x5
ffffffffc02024ee:	ab668693          	addi	a3,a3,-1354 # ffffffffc0206fa0 <commands+0xda8>
ffffffffc02024f2:	00004617          	auipc	a2,0x4
ffffffffc02024f6:	6f660613          	addi	a2,a2,1782 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02024fa:	23a00593          	li	a1,570
ffffffffc02024fe:	00004517          	auipc	a0,0x4
ffffffffc0202502:	6aa50513          	addi	a0,a0,1706 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202506:	d19fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020250a:	00005697          	auipc	a3,0x5
ffffffffc020250e:	a4e68693          	addi	a3,a3,-1458 # ffffffffc0206f58 <commands+0xd60>
ffffffffc0202512:	00004617          	auipc	a2,0x4
ffffffffc0202516:	6d660613          	addi	a2,a2,1750 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020251a:	23800593          	li	a1,568
ffffffffc020251e:	00004517          	auipc	a0,0x4
ffffffffc0202522:	68a50513          	addi	a0,a0,1674 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202526:	cf9fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020252a:	00005697          	auipc	a3,0x5
ffffffffc020252e:	a5e68693          	addi	a3,a3,-1442 # ffffffffc0206f88 <commands+0xd90>
ffffffffc0202532:	00004617          	auipc	a2,0x4
ffffffffc0202536:	6b660613          	addi	a2,a2,1718 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020253a:	23700593          	li	a1,567
ffffffffc020253e:	00004517          	auipc	a0,0x4
ffffffffc0202542:	66a50513          	addi	a0,a0,1642 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202546:	cd9fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc020254a:	00005697          	auipc	a3,0x5
ffffffffc020254e:	b2668693          	addi	a3,a3,-1242 # ffffffffc0207070 <commands+0xe78>
ffffffffc0202552:	00004617          	auipc	a2,0x4
ffffffffc0202556:	69660613          	addi	a2,a2,1686 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020255a:	25500593          	li	a1,597
ffffffffc020255e:	00004517          	auipc	a0,0x4
ffffffffc0202562:	64a50513          	addi	a0,a0,1610 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202566:	cb9fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020256a:	00005697          	auipc	a3,0x5
ffffffffc020256e:	a6668693          	addi	a3,a3,-1434 # ffffffffc0206fd0 <commands+0xdd8>
ffffffffc0202572:	00004617          	auipc	a2,0x4
ffffffffc0202576:	67660613          	addi	a2,a2,1654 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020257a:	24200593          	li	a1,578
ffffffffc020257e:	00004517          	auipc	a0,0x4
ffffffffc0202582:	62a50513          	addi	a0,a0,1578 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202586:	c99fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p) == 1);
ffffffffc020258a:	00005697          	auipc	a3,0x5
ffffffffc020258e:	b3e68693          	addi	a3,a3,-1218 # ffffffffc02070c8 <commands+0xed0>
ffffffffc0202592:	00004617          	auipc	a2,0x4
ffffffffc0202596:	65660613          	addi	a2,a2,1622 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020259a:	25a00593          	li	a1,602
ffffffffc020259e:	00004517          	auipc	a0,0x4
ffffffffc02025a2:	60a50513          	addi	a0,a0,1546 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02025a6:	c79fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025aa:	00005697          	auipc	a3,0x5
ffffffffc02025ae:	ade68693          	addi	a3,a3,-1314 # ffffffffc0207088 <commands+0xe90>
ffffffffc02025b2:	00004617          	auipc	a2,0x4
ffffffffc02025b6:	63660613          	addi	a2,a2,1590 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02025ba:	25900593          	li	a1,601
ffffffffc02025be:	00004517          	auipc	a0,0x4
ffffffffc02025c2:	5ea50513          	addi	a0,a0,1514 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02025c6:	c59fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02025ca:	00005697          	auipc	a3,0x5
ffffffffc02025ce:	98e68693          	addi	a3,a3,-1650 # ffffffffc0206f58 <commands+0xd60>
ffffffffc02025d2:	00004617          	auipc	a2,0x4
ffffffffc02025d6:	61660613          	addi	a2,a2,1558 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02025da:	23400593          	li	a1,564
ffffffffc02025de:	00004517          	auipc	a0,0x4
ffffffffc02025e2:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02025e6:	c39fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02025ea:	00005697          	auipc	a3,0x5
ffffffffc02025ee:	80e68693          	addi	a3,a3,-2034 # ffffffffc0206df8 <commands+0xc00>
ffffffffc02025f2:	00004617          	auipc	a2,0x4
ffffffffc02025f6:	5f660613          	addi	a2,a2,1526 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02025fa:	23300593          	li	a1,563
ffffffffc02025fe:	00004517          	auipc	a0,0x4
ffffffffc0202602:	5aa50513          	addi	a0,a0,1450 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202606:	c19fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020260a:	00005697          	auipc	a3,0x5
ffffffffc020260e:	96668693          	addi	a3,a3,-1690 # ffffffffc0206f70 <commands+0xd78>
ffffffffc0202612:	00004617          	auipc	a2,0x4
ffffffffc0202616:	5d660613          	addi	a2,a2,1494 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020261a:	23000593          	li	a1,560
ffffffffc020261e:	00004517          	auipc	a0,0x4
ffffffffc0202622:	58a50513          	addi	a0,a0,1418 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202626:	bf9fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020262a:	00004697          	auipc	a3,0x4
ffffffffc020262e:	7b668693          	addi	a3,a3,1974 # ffffffffc0206de0 <commands+0xbe8>
ffffffffc0202632:	00004617          	auipc	a2,0x4
ffffffffc0202636:	5b660613          	addi	a2,a2,1462 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020263a:	22f00593          	li	a1,559
ffffffffc020263e:	00004517          	auipc	a0,0x4
ffffffffc0202642:	56a50513          	addi	a0,a0,1386 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202646:	bd9fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020264a:	00005697          	auipc	a3,0x5
ffffffffc020264e:	83668693          	addi	a3,a3,-1994 # ffffffffc0206e80 <commands+0xc88>
ffffffffc0202652:	00004617          	auipc	a2,0x4
ffffffffc0202656:	59660613          	addi	a2,a2,1430 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020265a:	22e00593          	li	a1,558
ffffffffc020265e:	00004517          	auipc	a0,0x4
ffffffffc0202662:	54a50513          	addi	a0,a0,1354 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202666:	bb9fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020266a:	00005697          	auipc	a3,0x5
ffffffffc020266e:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0206f58 <commands+0xd60>
ffffffffc0202672:	00004617          	auipc	a2,0x4
ffffffffc0202676:	57660613          	addi	a2,a2,1398 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020267a:	22d00593          	li	a1,557
ffffffffc020267e:	00004517          	auipc	a0,0x4
ffffffffc0202682:	52a50513          	addi	a0,a0,1322 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202686:	b99fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020268a:	00005697          	auipc	a3,0x5
ffffffffc020268e:	8b668693          	addi	a3,a3,-1866 # ffffffffc0206f40 <commands+0xd48>
ffffffffc0202692:	00004617          	auipc	a2,0x4
ffffffffc0202696:	55660613          	addi	a2,a2,1366 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020269a:	22c00593          	li	a1,556
ffffffffc020269e:	00004517          	auipc	a0,0x4
ffffffffc02026a2:	50a50513          	addi	a0,a0,1290 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02026a6:	b79fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02026aa:	00005697          	auipc	a3,0x5
ffffffffc02026ae:	86668693          	addi	a3,a3,-1946 # ffffffffc0206f10 <commands+0xd18>
ffffffffc02026b2:	00004617          	auipc	a2,0x4
ffffffffc02026b6:	53660613          	addi	a2,a2,1334 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02026ba:	22b00593          	li	a1,555
ffffffffc02026be:	00004517          	auipc	a0,0x4
ffffffffc02026c2:	4ea50513          	addi	a0,a0,1258 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02026c6:	b59fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02026ca:	00005697          	auipc	a3,0x5
ffffffffc02026ce:	82e68693          	addi	a3,a3,-2002 # ffffffffc0206ef8 <commands+0xd00>
ffffffffc02026d2:	00004617          	auipc	a2,0x4
ffffffffc02026d6:	51660613          	addi	a2,a2,1302 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02026da:	22900593          	li	a1,553
ffffffffc02026de:	00004517          	auipc	a0,0x4
ffffffffc02026e2:	4ca50513          	addi	a0,a0,1226 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02026e6:	b39fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02026ea:	00004697          	auipc	a3,0x4
ffffffffc02026ee:	7ee68693          	addi	a3,a3,2030 # ffffffffc0206ed8 <commands+0xce0>
ffffffffc02026f2:	00004617          	auipc	a2,0x4
ffffffffc02026f6:	4f660613          	addi	a2,a2,1270 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02026fa:	22800593          	li	a1,552
ffffffffc02026fe:	00004517          	auipc	a0,0x4
ffffffffc0202702:	4aa50513          	addi	a0,a0,1194 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202706:	b19fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(*ptep & PTE_W);
ffffffffc020270a:	00004697          	auipc	a3,0x4
ffffffffc020270e:	7be68693          	addi	a3,a3,1982 # ffffffffc0206ec8 <commands+0xcd0>
ffffffffc0202712:	00004617          	auipc	a2,0x4
ffffffffc0202716:	4d660613          	addi	a2,a2,1238 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020271a:	22700593          	li	a1,551
ffffffffc020271e:	00004517          	auipc	a0,0x4
ffffffffc0202722:	48a50513          	addi	a0,a0,1162 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202726:	af9fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(*ptep & PTE_U);
ffffffffc020272a:	00004697          	auipc	a3,0x4
ffffffffc020272e:	78e68693          	addi	a3,a3,1934 # ffffffffc0206eb8 <commands+0xcc0>
ffffffffc0202732:	00004617          	auipc	a2,0x4
ffffffffc0202736:	4b660613          	addi	a2,a2,1206 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020273a:	22600593          	li	a1,550
ffffffffc020273e:	00004517          	auipc	a0,0x4
ffffffffc0202742:	46a50513          	addi	a0,a0,1130 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202746:	ad9fd0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("DTB memory info not available");
ffffffffc020274a:	00004617          	auipc	a2,0x4
ffffffffc020274e:	4e660613          	addi	a2,a2,1254 # ffffffffc0206c30 <commands+0xa38>
ffffffffc0202752:	06500593          	li	a1,101
ffffffffc0202756:	00004517          	auipc	a0,0x4
ffffffffc020275a:	45250513          	addi	a0,a0,1106 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc020275e:	ac1fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202762:	00005697          	auipc	a3,0x5
ffffffffc0202766:	86e68693          	addi	a3,a3,-1938 # ffffffffc0206fd0 <commands+0xdd8>
ffffffffc020276a:	00004617          	auipc	a2,0x4
ffffffffc020276e:	47e60613          	addi	a2,a2,1150 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202772:	26c00593          	li	a1,620
ffffffffc0202776:	00004517          	auipc	a0,0x4
ffffffffc020277a:	43250513          	addi	a0,a0,1074 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc020277e:	aa1fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202782:	00004697          	auipc	a3,0x4
ffffffffc0202786:	6fe68693          	addi	a3,a3,1790 # ffffffffc0206e80 <commands+0xc88>
ffffffffc020278a:	00004617          	auipc	a2,0x4
ffffffffc020278e:	45e60613          	addi	a2,a2,1118 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202792:	22500593          	li	a1,549
ffffffffc0202796:	00004517          	auipc	a0,0x4
ffffffffc020279a:	41250513          	addi	a0,a0,1042 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc020279e:	a81fd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02027a2:	00004697          	auipc	a3,0x4
ffffffffc02027a6:	69e68693          	addi	a3,a3,1694 # ffffffffc0206e40 <commands+0xc48>
ffffffffc02027aa:	00004617          	auipc	a2,0x4
ffffffffc02027ae:	43e60613          	addi	a2,a2,1086 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02027b2:	22400593          	li	a1,548
ffffffffc02027b6:	00004517          	auipc	a0,0x4
ffffffffc02027ba:	3f250513          	addi	a0,a0,1010 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02027be:	a61fd0ef          	jal	ra,ffffffffc020021e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02027c2:	86d6                	mv	a3,s5
ffffffffc02027c4:	00004617          	auipc	a2,0x4
ffffffffc02027c8:	39460613          	addi	a2,a2,916 # ffffffffc0206b58 <commands+0x960>
ffffffffc02027cc:	22000593          	li	a1,544
ffffffffc02027d0:	00004517          	auipc	a0,0x4
ffffffffc02027d4:	3d850513          	addi	a0,a0,984 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02027d8:	a47fd0ef          	jal	ra,ffffffffc020021e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02027dc:	00004617          	auipc	a2,0x4
ffffffffc02027e0:	37c60613          	addi	a2,a2,892 # ffffffffc0206b58 <commands+0x960>
ffffffffc02027e4:	21f00593          	li	a1,543
ffffffffc02027e8:	00004517          	auipc	a0,0x4
ffffffffc02027ec:	3c050513          	addi	a0,a0,960 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02027f0:	a2ffd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02027f4:	00004697          	auipc	a3,0x4
ffffffffc02027f8:	60468693          	addi	a3,a3,1540 # ffffffffc0206df8 <commands+0xc00>
ffffffffc02027fc:	00004617          	auipc	a2,0x4
ffffffffc0202800:	3ec60613          	addi	a2,a2,1004 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202804:	21d00593          	li	a1,541
ffffffffc0202808:	00004517          	auipc	a0,0x4
ffffffffc020280c:	3a050513          	addi	a0,a0,928 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202810:	a0ffd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202814:	00004697          	auipc	a3,0x4
ffffffffc0202818:	5cc68693          	addi	a3,a3,1484 # ffffffffc0206de0 <commands+0xbe8>
ffffffffc020281c:	00004617          	auipc	a2,0x4
ffffffffc0202820:	3cc60613          	addi	a2,a2,972 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202824:	21c00593          	li	a1,540
ffffffffc0202828:	00004517          	auipc	a0,0x4
ffffffffc020282c:	38050513          	addi	a0,a0,896 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202830:	9effd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202834:	00005697          	auipc	a3,0x5
ffffffffc0202838:	95c68693          	addi	a3,a3,-1700 # ffffffffc0207190 <commands+0xf98>
ffffffffc020283c:	00004617          	auipc	a2,0x4
ffffffffc0202840:	3ac60613          	addi	a2,a2,940 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202844:	26300593          	li	a1,611
ffffffffc0202848:	00004517          	auipc	a0,0x4
ffffffffc020284c:	36050513          	addi	a0,a0,864 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202850:	9cffd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202854:	00005697          	auipc	a3,0x5
ffffffffc0202858:	90468693          	addi	a3,a3,-1788 # ffffffffc0207158 <commands+0xf60>
ffffffffc020285c:	00004617          	auipc	a2,0x4
ffffffffc0202860:	38c60613          	addi	a2,a2,908 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202864:	26000593          	li	a1,608
ffffffffc0202868:	00004517          	auipc	a0,0x4
ffffffffc020286c:	34050513          	addi	a0,a0,832 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202870:	9affd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202874:	00005697          	auipc	a3,0x5
ffffffffc0202878:	8b468693          	addi	a3,a3,-1868 # ffffffffc0207128 <commands+0xf30>
ffffffffc020287c:	00004617          	auipc	a2,0x4
ffffffffc0202880:	36c60613          	addi	a2,a2,876 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202884:	25c00593          	li	a1,604
ffffffffc0202888:	00004517          	auipc	a0,0x4
ffffffffc020288c:	32050513          	addi	a0,a0,800 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202890:	98ffd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202894:	00005697          	auipc	a3,0x5
ffffffffc0202898:	84c68693          	addi	a3,a3,-1972 # ffffffffc02070e0 <commands+0xee8>
ffffffffc020289c:	00004617          	auipc	a2,0x4
ffffffffc02028a0:	34c60613          	addi	a2,a2,844 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02028a4:	25b00593          	li	a1,603
ffffffffc02028a8:	00004517          	auipc	a0,0x4
ffffffffc02028ac:	30050513          	addi	a0,a0,768 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02028b0:	96ffd0ef          	jal	ra,ffffffffc020021e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028b4:	00004617          	auipc	a2,0x4
ffffffffc02028b8:	3dc60613          	addi	a2,a2,988 # ffffffffc0206c90 <commands+0xa98>
ffffffffc02028bc:	0c900593          	li	a1,201
ffffffffc02028c0:	00004517          	auipc	a0,0x4
ffffffffc02028c4:	2e850513          	addi	a0,a0,744 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02028c8:	957fd0ef          	jal	ra,ffffffffc020021e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028cc:	00004617          	auipc	a2,0x4
ffffffffc02028d0:	3c460613          	addi	a2,a2,964 # ffffffffc0206c90 <commands+0xa98>
ffffffffc02028d4:	08100593          	li	a1,129
ffffffffc02028d8:	00004517          	auipc	a0,0x4
ffffffffc02028dc:	2d050513          	addi	a0,a0,720 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc02028e0:	93ffd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028e4:	00004697          	auipc	a3,0x4
ffffffffc02028e8:	4cc68693          	addi	a3,a3,1228 # ffffffffc0206db0 <commands+0xbb8>
ffffffffc02028ec:	00004617          	auipc	a2,0x4
ffffffffc02028f0:	2fc60613          	addi	a2,a2,764 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02028f4:	21b00593          	li	a1,539
ffffffffc02028f8:	00004517          	auipc	a0,0x4
ffffffffc02028fc:	2b050513          	addi	a0,a0,688 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202900:	91ffd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202904:	00004697          	auipc	a3,0x4
ffffffffc0202908:	47c68693          	addi	a3,a3,1148 # ffffffffc0206d80 <commands+0xb88>
ffffffffc020290c:	00004617          	auipc	a2,0x4
ffffffffc0202910:	2dc60613          	addi	a2,a2,732 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202914:	21800593          	li	a1,536
ffffffffc0202918:	00004517          	auipc	a0,0x4
ffffffffc020291c:	29050513          	addi	a0,a0,656 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202920:	8fffd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0202924 <copy_range>:
{
ffffffffc0202924:	7119                	addi	sp,sp,-128
ffffffffc0202926:	f8a2                	sd	s0,112(sp)
ffffffffc0202928:	8436                	mv	s0,a3
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020292a:	8ed1                	or	a3,a3,a2
{
ffffffffc020292c:	fc86                	sd	ra,120(sp)
ffffffffc020292e:	f4a6                	sd	s1,104(sp)
ffffffffc0202930:	f0ca                	sd	s2,96(sp)
ffffffffc0202932:	ecce                	sd	s3,88(sp)
ffffffffc0202934:	e8d2                	sd	s4,80(sp)
ffffffffc0202936:	e4d6                	sd	s5,72(sp)
ffffffffc0202938:	e0da                	sd	s6,64(sp)
ffffffffc020293a:	fc5e                	sd	s7,56(sp)
ffffffffc020293c:	f862                	sd	s8,48(sp)
ffffffffc020293e:	f466                	sd	s9,40(sp)
ffffffffc0202940:	f06a                	sd	s10,32(sp)
ffffffffc0202942:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202944:	16d2                	slli	a3,a3,0x34
{
ffffffffc0202946:	e03a                	sd	a4,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202948:	24069e63          	bnez	a3,ffffffffc0202ba4 <copy_range+0x280>
    assert(USER_ACCESS(start, end));
ffffffffc020294c:	00200737          	lui	a4,0x200
ffffffffc0202950:	8c32                	mv	s8,a2
ffffffffc0202952:	22e66963          	bltu	a2,a4,ffffffffc0202b84 <copy_range+0x260>
ffffffffc0202956:	22867763          	bgeu	a2,s0,ffffffffc0202b84 <copy_range+0x260>
ffffffffc020295a:	4705                	li	a4,1
ffffffffc020295c:	077e                	slli	a4,a4,0x1f
ffffffffc020295e:	22876363          	bltu	a4,s0,ffffffffc0202b84 <copy_range+0x260>
ffffffffc0202962:	5bfd                	li	s7,-1
ffffffffc0202964:	8a2a                	mv	s4,a0
ffffffffc0202966:	84ae                	mv	s1,a1
        start += PGSIZE;
ffffffffc0202968:	6905                	lui	s2,0x1
    if (PPN(pa) >= npage)
ffffffffc020296a:	000c3b17          	auipc	s6,0xc3
ffffffffc020296e:	7eeb0b13          	addi	s6,s6,2030 # ffffffffc02c6158 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202972:	000c3a97          	auipc	s5,0xc3
ffffffffc0202976:	7eea8a93          	addi	s5,s5,2030 # ffffffffc02c6160 <pages>
ffffffffc020297a:	fff80cb7          	lui	s9,0xfff80
    return KADDR(page2pa(page));
ffffffffc020297e:	00cbdb93          	srli	s7,s7,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0202982:	000c3d17          	auipc	s10,0xc3
ffffffffc0202986:	7e6d0d13          	addi	s10,s10,2022 # ffffffffc02c6168 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020298a:	4601                	li	a2,0
ffffffffc020298c:	85e2                	mv	a1,s8
ffffffffc020298e:	8526                	mv	a0,s1
ffffffffc0202990:	b6ffe0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc0202994:	8daa                	mv	s11,a0
        if (ptep == NULL)
ffffffffc0202996:	c559                	beqz	a0,ffffffffc0202a24 <copy_range+0x100>
        if (*ptep & PTE_V)
ffffffffc0202998:	6114                	ld	a3,0(a0)
ffffffffc020299a:	8a85                	andi	a3,a3,1
ffffffffc020299c:	e68d                	bnez	a3,ffffffffc02029c6 <copy_range+0xa2>
        start += PGSIZE;
ffffffffc020299e:	9c4a                	add	s8,s8,s2
    } while (start != 0 && start < end);
ffffffffc02029a0:	fe8c65e3          	bltu	s8,s0,ffffffffc020298a <copy_range+0x66>
    return 0;
ffffffffc02029a4:	4981                	li	s3,0
}
ffffffffc02029a6:	70e6                	ld	ra,120(sp)
ffffffffc02029a8:	7446                	ld	s0,112(sp)
ffffffffc02029aa:	74a6                	ld	s1,104(sp)
ffffffffc02029ac:	7906                	ld	s2,96(sp)
ffffffffc02029ae:	6a46                	ld	s4,80(sp)
ffffffffc02029b0:	6aa6                	ld	s5,72(sp)
ffffffffc02029b2:	6b06                	ld	s6,64(sp)
ffffffffc02029b4:	7be2                	ld	s7,56(sp)
ffffffffc02029b6:	7c42                	ld	s8,48(sp)
ffffffffc02029b8:	7ca2                	ld	s9,40(sp)
ffffffffc02029ba:	7d02                	ld	s10,32(sp)
ffffffffc02029bc:	6de2                	ld	s11,24(sp)
ffffffffc02029be:	854e                	mv	a0,s3
ffffffffc02029c0:	69e6                	ld	s3,88(sp)
ffffffffc02029c2:	6109                	addi	sp,sp,128
ffffffffc02029c4:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02029c6:	4605                	li	a2,1
ffffffffc02029c8:	85e2                	mv	a1,s8
ffffffffc02029ca:	8552                	mv	a0,s4
ffffffffc02029cc:	b33fe0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc02029d0:	c921                	beqz	a0,ffffffffc0202a20 <copy_range+0xfc>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02029d2:	000db603          	ld	a2,0(s11)
    if (!(pte & PTE_V))
ffffffffc02029d6:	00167693          	andi	a3,a2,1
ffffffffc02029da:	0006099b          	sext.w	s3,a2
ffffffffc02029de:	16068a63          	beqz	a3,ffffffffc0202b52 <copy_range+0x22e>
    if (PPN(pa) >= npage)
ffffffffc02029e2:	000b3583          	ld	a1,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029e6:	00261693          	slli	a3,a2,0x2
ffffffffc02029ea:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02029ec:	14b6f763          	bgeu	a3,a1,ffffffffc0202b3a <copy_range+0x216>
    return &pages[PPN(pa) - nbase];
ffffffffc02029f0:	000ab583          	ld	a1,0(s5)
            if (share)
ffffffffc02029f4:	6782                	ld	a5,0(sp)
ffffffffc02029f6:	96e6                	add	a3,a3,s9
ffffffffc02029f8:	069a                	slli	a3,a3,0x6
ffffffffc02029fa:	95b6                	add	a1,a1,a3
ffffffffc02029fc:	c3a9                	beqz	a5,ffffffffc0202a3e <copy_range+0x11a>
                *ptep = (*ptep | PTE_COW) & ~PTE_W;
ffffffffc02029fe:	efb67613          	andi	a2,a2,-261
ffffffffc0202a02:	10066613          	ori	a2,a2,256
ffffffffc0202a06:	00cdb023          	sd	a2,0(s11)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202a0a:	120c0073          	sfence.vma	s8
                perm = (perm | PTE_COW) & ~PTE_W;
ffffffffc0202a0e:	01b9f693          	andi	a3,s3,27
                if (page_insert(to, page, start, perm) != 0)
ffffffffc0202a12:	1006e693          	ori	a3,a3,256
ffffffffc0202a16:	8662                	mv	a2,s8
ffffffffc0202a18:	8552                	mv	a0,s4
ffffffffc0202a1a:	9d4ff0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc0202a1e:	d141                	beqz	a0,ffffffffc020299e <copy_range+0x7a>
                return -E_NO_MEM;
ffffffffc0202a20:	59f1                	li	s3,-4
ffffffffc0202a22:	b751                	j	ffffffffc02029a6 <copy_range+0x82>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202a24:	00200637          	lui	a2,0x200
ffffffffc0202a28:	00cc07b3          	add	a5,s8,a2
ffffffffc0202a2c:	ffe00637          	lui	a2,0xffe00
ffffffffc0202a30:	00c7fc33          	and	s8,a5,a2
    } while (start != 0 && start < end);
ffffffffc0202a34:	f60c08e3          	beqz	s8,ffffffffc02029a4 <copy_range+0x80>
ffffffffc0202a38:	f48c69e3          	bltu	s8,s0,ffffffffc020298a <copy_range+0x66>
ffffffffc0202a3c:	b7a5                	j	ffffffffc02029a4 <copy_range+0x80>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202a3e:	10002773          	csrr	a4,sstatus
ffffffffc0202a42:	8b09                	andi	a4,a4,2
ffffffffc0202a44:	e42e                	sd	a1,8(sp)
ffffffffc0202a46:	e359                	bnez	a4,ffffffffc0202acc <copy_range+0x1a8>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a48:	000d3703          	ld	a4,0(s10)
ffffffffc0202a4c:	4505                	li	a0,1
ffffffffc0202a4e:	6f18                	ld	a4,24(a4)
ffffffffc0202a50:	9702                	jalr	a4
ffffffffc0202a52:	65a2                	ld	a1,8(sp)
ffffffffc0202a54:	8daa                	mv	s11,a0
                assert(page != NULL);
ffffffffc0202a56:	c1f1                	beqz	a1,ffffffffc0202b1a <copy_range+0x1f6>
                assert(npage != NULL);
ffffffffc0202a58:	0a0d8163          	beqz	s11,ffffffffc0202afa <copy_range+0x1d6>
    return page - pages + nbase;
ffffffffc0202a5c:	000ab603          	ld	a2,0(s5)
ffffffffc0202a60:	00080337          	lui	t1,0x80
    return KADDR(page2pa(page));
ffffffffc0202a64:	000b3883          	ld	a7,0(s6)
    return page - pages + nbase;
ffffffffc0202a68:	40c586b3          	sub	a3,a1,a2
ffffffffc0202a6c:	8699                	srai	a3,a3,0x6
ffffffffc0202a6e:	969a                	add	a3,a3,t1
    return KADDR(page2pa(page));
ffffffffc0202a70:	0176f733          	and	a4,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a74:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a76:	0f177b63          	bgeu	a4,a7,ffffffffc0202b6c <copy_range+0x248>
    return page - pages + nbase;
ffffffffc0202a7a:	40cd8733          	sub	a4,s11,a2
    return KADDR(page2pa(page));
ffffffffc0202a7e:	000c3797          	auipc	a5,0xc3
ffffffffc0202a82:	6f278793          	addi	a5,a5,1778 # ffffffffc02c6170 <va_pa_offset>
ffffffffc0202a86:	6388                	ld	a0,0(a5)
    return page - pages + nbase;
ffffffffc0202a88:	8719                	srai	a4,a4,0x6
ffffffffc0202a8a:	971a                	add	a4,a4,t1
    return KADDR(page2pa(page));
ffffffffc0202a8c:	01777633          	and	a2,a4,s7
ffffffffc0202a90:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a94:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc0202a96:	0d167a63          	bgeu	a2,a7,ffffffffc0202b6a <copy_range+0x246>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0202a9a:	6605                	lui	a2,0x1
ffffffffc0202a9c:	953a                	add	a0,a0,a4
ffffffffc0202a9e:	761020ef          	jal	ra,ffffffffc02059fe <memcpy>
                ret = page_insert(to, npage, start, perm);
ffffffffc0202aa2:	01f9f693          	andi	a3,s3,31
ffffffffc0202aa6:	8662                	mv	a2,s8
ffffffffc0202aa8:	85ee                	mv	a1,s11
ffffffffc0202aaa:	8552                	mv	a0,s4
ffffffffc0202aac:	942ff0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc0202ab0:	89aa                	mv	s3,a0
                if (ret != 0)
ffffffffc0202ab2:	ee0506e3          	beqz	a0,ffffffffc020299e <copy_range+0x7a>
ffffffffc0202ab6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aba:	8b89                	andi	a5,a5,2
ffffffffc0202abc:	e785                	bnez	a5,ffffffffc0202ae4 <copy_range+0x1c0>
        pmm_manager->free_pages(base, n);
ffffffffc0202abe:	000d3783          	ld	a5,0(s10)
ffffffffc0202ac2:	4585                	li	a1,1
ffffffffc0202ac4:	856e                	mv	a0,s11
ffffffffc0202ac6:	739c                	ld	a5,32(a5)
ffffffffc0202ac8:	9782                	jalr	a5
    if (flag)
ffffffffc0202aca:	bdf1                	j	ffffffffc02029a6 <copy_range+0x82>
        intr_disable();
ffffffffc0202acc:	fb9fd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202ad0:	000d3703          	ld	a4,0(s10)
ffffffffc0202ad4:	4505                	li	a0,1
ffffffffc0202ad6:	6f18                	ld	a4,24(a4)
ffffffffc0202ad8:	9702                	jalr	a4
ffffffffc0202ada:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc0202adc:	fa3fd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0202ae0:	65a2                	ld	a1,8(sp)
ffffffffc0202ae2:	bf95                	j	ffffffffc0202a56 <copy_range+0x132>
        intr_disable();
ffffffffc0202ae4:	fa1fd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ae8:	000d3783          	ld	a5,0(s10)
ffffffffc0202aec:	4585                	li	a1,1
ffffffffc0202aee:	856e                	mv	a0,s11
ffffffffc0202af0:	739c                	ld	a5,32(a5)
ffffffffc0202af2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202af4:	f8bfd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0202af8:	b57d                	j	ffffffffc02029a6 <copy_range+0x82>
                assert(npage != NULL);
ffffffffc0202afa:	00004697          	auipc	a3,0x4
ffffffffc0202afe:	6ee68693          	addi	a3,a3,1774 # ffffffffc02071e8 <commands+0xff0>
ffffffffc0202b02:	00004617          	auipc	a2,0x4
ffffffffc0202b06:	0e660613          	addi	a2,a2,230 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202b0a:	1a300593          	li	a1,419
ffffffffc0202b0e:	00004517          	auipc	a0,0x4
ffffffffc0202b12:	09a50513          	addi	a0,a0,154 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202b16:	f08fd0ef          	jal	ra,ffffffffc020021e <__panic>
                assert(page != NULL);
ffffffffc0202b1a:	00004697          	auipc	a3,0x4
ffffffffc0202b1e:	6be68693          	addi	a3,a3,1726 # ffffffffc02071d8 <commands+0xfe0>
ffffffffc0202b22:	00004617          	auipc	a2,0x4
ffffffffc0202b26:	0c660613          	addi	a2,a2,198 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202b2a:	1a200593          	li	a1,418
ffffffffc0202b2e:	00004517          	auipc	a0,0x4
ffffffffc0202b32:	07a50513          	addi	a0,a0,122 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202b36:	ee8fd0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202b3a:	00004617          	auipc	a2,0x4
ffffffffc0202b3e:	fee60613          	addi	a2,a2,-18 # ffffffffc0206b28 <commands+0x930>
ffffffffc0202b42:	06900593          	li	a1,105
ffffffffc0202b46:	00004517          	auipc	a0,0x4
ffffffffc0202b4a:	00250513          	addi	a0,a0,2 # ffffffffc0206b48 <commands+0x950>
ffffffffc0202b4e:	ed0fd0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202b52:	00004617          	auipc	a2,0x4
ffffffffc0202b56:	02e60613          	addi	a2,a2,46 # ffffffffc0206b80 <commands+0x988>
ffffffffc0202b5a:	07f00593          	li	a1,127
ffffffffc0202b5e:	00004517          	auipc	a0,0x4
ffffffffc0202b62:	fea50513          	addi	a0,a0,-22 # ffffffffc0206b48 <commands+0x950>
ffffffffc0202b66:	eb8fd0ef          	jal	ra,ffffffffc020021e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202b6a:	86ba                	mv	a3,a4
ffffffffc0202b6c:	00004617          	auipc	a2,0x4
ffffffffc0202b70:	fec60613          	addi	a2,a2,-20 # ffffffffc0206b58 <commands+0x960>
ffffffffc0202b74:	07100593          	li	a1,113
ffffffffc0202b78:	00004517          	auipc	a0,0x4
ffffffffc0202b7c:	fd050513          	addi	a0,a0,-48 # ffffffffc0206b48 <commands+0x950>
ffffffffc0202b80:	e9efd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202b84:	00004697          	auipc	a3,0x4
ffffffffc0202b88:	07c68693          	addi	a3,a3,124 # ffffffffc0206c00 <commands+0xa08>
ffffffffc0202b8c:	00004617          	auipc	a2,0x4
ffffffffc0202b90:	05c60613          	addi	a2,a2,92 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202b94:	17c00593          	li	a1,380
ffffffffc0202b98:	00004517          	auipc	a0,0x4
ffffffffc0202b9c:	01050513          	addi	a0,a0,16 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202ba0:	e7efd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202ba4:	00004697          	auipc	a3,0x4
ffffffffc0202ba8:	01468693          	addi	a3,a3,20 # ffffffffc0206bb8 <commands+0x9c0>
ffffffffc0202bac:	00004617          	auipc	a2,0x4
ffffffffc0202bb0:	03c60613          	addi	a2,a2,60 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202bb4:	17b00593          	li	a1,379
ffffffffc0202bb8:	00004517          	auipc	a0,0x4
ffffffffc0202bbc:	ff050513          	addi	a0,a0,-16 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202bc0:	e5efd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0202bc4 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202bc4:	12058073          	sfence.vma	a1
}
ffffffffc0202bc8:	8082                	ret

ffffffffc0202bca <pgdir_alloc_page>:
{
ffffffffc0202bca:	7179                	addi	sp,sp,-48
ffffffffc0202bcc:	ec26                	sd	s1,24(sp)
ffffffffc0202bce:	e84a                	sd	s2,16(sp)
ffffffffc0202bd0:	e052                	sd	s4,0(sp)
ffffffffc0202bd2:	f406                	sd	ra,40(sp)
ffffffffc0202bd4:	f022                	sd	s0,32(sp)
ffffffffc0202bd6:	e44e                	sd	s3,8(sp)
ffffffffc0202bd8:	8a2a                	mv	s4,a0
ffffffffc0202bda:	84ae                	mv	s1,a1
ffffffffc0202bdc:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202bde:	100027f3          	csrr	a5,sstatus
ffffffffc0202be2:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc0202be4:	000c3997          	auipc	s3,0xc3
ffffffffc0202be8:	58498993          	addi	s3,s3,1412 # ffffffffc02c6168 <pmm_manager>
ffffffffc0202bec:	ef8d                	bnez	a5,ffffffffc0202c26 <pgdir_alloc_page+0x5c>
ffffffffc0202bee:	0009b783          	ld	a5,0(s3)
ffffffffc0202bf2:	4505                	li	a0,1
ffffffffc0202bf4:	6f9c                	ld	a5,24(a5)
ffffffffc0202bf6:	9782                	jalr	a5
ffffffffc0202bf8:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0202bfa:	cc09                	beqz	s0,ffffffffc0202c14 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0202bfc:	86ca                	mv	a3,s2
ffffffffc0202bfe:	8626                	mv	a2,s1
ffffffffc0202c00:	85a2                	mv	a1,s0
ffffffffc0202c02:	8552                	mv	a0,s4
ffffffffc0202c04:	febfe0ef          	jal	ra,ffffffffc0201bee <page_insert>
ffffffffc0202c08:	e915                	bnez	a0,ffffffffc0202c3c <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0202c0a:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0202c0c:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0202c0e:	4785                	li	a5,1
ffffffffc0202c10:	04f71e63          	bne	a4,a5,ffffffffc0202c6c <pgdir_alloc_page+0xa2>
}
ffffffffc0202c14:	70a2                	ld	ra,40(sp)
ffffffffc0202c16:	8522                	mv	a0,s0
ffffffffc0202c18:	7402                	ld	s0,32(sp)
ffffffffc0202c1a:	64e2                	ld	s1,24(sp)
ffffffffc0202c1c:	6942                	ld	s2,16(sp)
ffffffffc0202c1e:	69a2                	ld	s3,8(sp)
ffffffffc0202c20:	6a02                	ld	s4,0(sp)
ffffffffc0202c22:	6145                	addi	sp,sp,48
ffffffffc0202c24:	8082                	ret
        intr_disable();
ffffffffc0202c26:	e5ffd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c2a:	0009b783          	ld	a5,0(s3)
ffffffffc0202c2e:	4505                	li	a0,1
ffffffffc0202c30:	6f9c                	ld	a5,24(a5)
ffffffffc0202c32:	9782                	jalr	a5
ffffffffc0202c34:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202c36:	e49fd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0202c3a:	b7c1                	j	ffffffffc0202bfa <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202c3c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c40:	8b89                	andi	a5,a5,2
ffffffffc0202c42:	eb89                	bnez	a5,ffffffffc0202c54 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0202c44:	0009b783          	ld	a5,0(s3)
ffffffffc0202c48:	8522                	mv	a0,s0
ffffffffc0202c4a:	4585                	li	a1,1
ffffffffc0202c4c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0202c4e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0202c50:	9782                	jalr	a5
    if (flag)
ffffffffc0202c52:	b7c9                	j	ffffffffc0202c14 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0202c54:	e31fd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
ffffffffc0202c58:	0009b783          	ld	a5,0(s3)
ffffffffc0202c5c:	8522                	mv	a0,s0
ffffffffc0202c5e:	4585                	li	a1,1
ffffffffc0202c60:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0202c62:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0202c64:	9782                	jalr	a5
        intr_enable();
ffffffffc0202c66:	e19fd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0202c6a:	b76d                	j	ffffffffc0202c14 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0202c6c:	00004697          	auipc	a3,0x4
ffffffffc0202c70:	58c68693          	addi	a3,a3,1420 # ffffffffc02071f8 <commands+0x1000>
ffffffffc0202c74:	00004617          	auipc	a2,0x4
ffffffffc0202c78:	f7460613          	addi	a2,a2,-140 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202c7c:	1f900593          	li	a1,505
ffffffffc0202c80:	00004517          	auipc	a0,0x4
ffffffffc0202c84:	f2850513          	addi	a0,a0,-216 # ffffffffc0206ba8 <commands+0x9b0>
ffffffffc0202c88:	d96fd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0202c8c <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202c8c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202c8e:	00004697          	auipc	a3,0x4
ffffffffc0202c92:	58268693          	addi	a3,a3,1410 # ffffffffc0207210 <commands+0x1018>
ffffffffc0202c96:	00004617          	auipc	a2,0x4
ffffffffc0202c9a:	f5260613          	addi	a2,a2,-174 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202c9e:	0c000593          	li	a1,192
ffffffffc0202ca2:	00004517          	auipc	a0,0x4
ffffffffc0202ca6:	58e50513          	addi	a0,a0,1422 # ffffffffc0207230 <commands+0x1038>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202caa:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202cac:	d72fd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0202cb0 <mm_create>:
{
ffffffffc0202cb0:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202cb2:	04000513          	li	a0,64
{
ffffffffc0202cb6:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202cb8:	361000ef          	jal	ra,ffffffffc0203818 <kmalloc>
    if (mm != NULL)
ffffffffc0202cbc:	cd19                	beqz	a0,ffffffffc0202cda <mm_create+0x2a>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0202cbe:	e508                	sd	a0,8(a0)
ffffffffc0202cc0:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202cc2:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202cc6:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202cca:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202cce:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0202cd2:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0202cd6:	02053c23          	sd	zero,56(a0)
}
ffffffffc0202cda:	60a2                	ld	ra,8(sp)
ffffffffc0202cdc:	0141                	addi	sp,sp,16
ffffffffc0202cde:	8082                	ret

ffffffffc0202ce0 <find_vma>:
{
ffffffffc0202ce0:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202ce2:	c505                	beqz	a0,ffffffffc0202d0a <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202ce4:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202ce6:	c501                	beqz	a0,ffffffffc0202cee <find_vma+0xe>
ffffffffc0202ce8:	651c                	ld	a5,8(a0)
ffffffffc0202cea:	02f5f263          	bgeu	a1,a5,ffffffffc0202d0e <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0202cee:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202cf0:	00f68d63          	beq	a3,a5,ffffffffc0202d0a <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202cf4:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202cf8:	00e5e663          	bltu	a1,a4,ffffffffc0202d04 <find_vma+0x24>
ffffffffc0202cfc:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202d00:	00e5ec63          	bltu	a1,a4,ffffffffc0202d18 <find_vma+0x38>
ffffffffc0202d04:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202d06:	fef697e3          	bne	a3,a5,ffffffffc0202cf4 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202d0a:	4501                	li	a0,0
}
ffffffffc0202d0c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d0e:	691c                	ld	a5,16(a0)
ffffffffc0202d10:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202cee <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202d14:	ea88                	sd	a0,16(a3)
ffffffffc0202d16:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202d18:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202d1c:	ea88                	sd	a0,16(a3)
ffffffffc0202d1e:	8082                	ret

ffffffffc0202d20 <do_pgfault>:
{
ffffffffc0202d20:	715d                	addi	sp,sp,-80
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0202d22:	77fd                	lui	a5,0xfffff
{
ffffffffc0202d24:	fc26                	sd	s1,56(sp)
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0202d26:	00f674b3          	and	s1,a2,a5
{
ffffffffc0202d2a:	e0a2                	sd	s0,64(sp)
ffffffffc0202d2c:	842e                	mv	s0,a1
    struct vma_struct *vma = find_vma(mm, la);
ffffffffc0202d2e:	85a6                	mv	a1,s1
{
ffffffffc0202d30:	f84a                	sd	s2,48(sp)
ffffffffc0202d32:	e486                	sd	ra,72(sp)
ffffffffc0202d34:	f44e                	sd	s3,40(sp)
ffffffffc0202d36:	f052                	sd	s4,32(sp)
ffffffffc0202d38:	ec56                	sd	s5,24(sp)
ffffffffc0202d3a:	e85a                	sd	s6,16(sp)
ffffffffc0202d3c:	e45e                	sd	s7,8(sp)
ffffffffc0202d3e:	892a                	mv	s2,a0
    struct vma_struct *vma = find_vma(mm, la);
ffffffffc0202d40:	fa1ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
    if (vma == NULL || vma->vm_start > la)
ffffffffc0202d44:	18050163          	beqz	a0,ffffffffc0202ec6 <do_pgfault+0x1a6>
ffffffffc0202d48:	651c                	ld	a5,8(a0)
ffffffffc0202d4a:	16f4ee63          	bltu	s1,a5,ffffffffc0202ec6 <do_pgfault+0x1a6>
    uint32_t perm = vma_perm(vma->vm_flags);
ffffffffc0202d4e:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U | PTE_V;
ffffffffc0202d50:	49c5                	li	s3,17
    if (vm_flags & VM_READ)
ffffffffc0202d52:	0017f713          	andi	a4,a5,1
ffffffffc0202d56:	c311                	beqz	a4,ffffffffc0202d5a <do_pgfault+0x3a>
        perm |= PTE_R;
ffffffffc0202d58:	49cd                	li	s3,19
    if (vm_flags & VM_WRITE)
ffffffffc0202d5a:	0027f713          	andi	a4,a5,2
ffffffffc0202d5e:	c311                	beqz	a4,ffffffffc0202d62 <do_pgfault+0x42>
        perm |= (PTE_W | PTE_R);
ffffffffc0202d60:	49dd                	li	s3,23
    if (vm_flags & VM_EXEC)
ffffffffc0202d62:	8b91                	andi	a5,a5,4
ffffffffc0202d64:	eff1                	bnez	a5,ffffffffc0202e40 <do_pgfault+0x120>
    pte_t *ptep = get_pte(mm->pgdir, la, 1);
ffffffffc0202d66:	01893503          	ld	a0,24(s2) # 1018 <_binary_obj___user_faultread_out_size-0x9168>
ffffffffc0202d6a:	4605                	li	a2,1
ffffffffc0202d6c:	85a6                	mv	a1,s1
ffffffffc0202d6e:	f90fe0ef          	jal	ra,ffffffffc02014fe <get_pte>
ffffffffc0202d72:	872a                	mv	a4,a0
    if (ptep == NULL)
ffffffffc0202d74:	14050b63          	beqz	a0,ffffffffc0202eca <do_pgfault+0x1aa>
    if (*ptep & PTE_V)
ffffffffc0202d78:	6110                	ld	a2,0(a0)
ffffffffc0202d7a:	00167793          	andi	a5,a2,1
ffffffffc0202d7e:	c7e1                	beqz	a5,ffffffffc0202e46 <do_pgfault+0x126>
        if ((*ptep & PTE_COW) && need_write)
ffffffffc0202d80:	10067793          	andi	a5,a2,256
ffffffffc0202d84:	14078163          	beqz	a5,ffffffffc0202ec6 <do_pgfault+0x1a6>
ffffffffc0202d88:	00447593          	andi	a1,s0,4
ffffffffc0202d8c:	12058d63          	beqz	a1,ffffffffc0202ec6 <do_pgfault+0x1a6>
    if (PPN(pa) >= npage)
ffffffffc0202d90:	000c3b17          	auipc	s6,0xc3
ffffffffc0202d94:	3c8b0b13          	addi	s6,s6,968 # ffffffffc02c6158 <npage>
ffffffffc0202d98:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202d9c:	00261793          	slli	a5,a2,0x2
ffffffffc0202da0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202da2:	14d7f263          	bgeu	a5,a3,ffffffffc0202ee6 <do_pgfault+0x1c6>
    return &pages[PPN(pa) - nbase];
ffffffffc0202da6:	000c3b97          	auipc	s7,0xc3
ffffffffc0202daa:	3bab8b93          	addi	s7,s7,954 # ffffffffc02c6160 <pages>
ffffffffc0202dae:	000bb403          	ld	s0,0(s7)
ffffffffc0202db2:	00005a97          	auipc	s5,0x5
ffffffffc0202db6:	476aba83          	ld	s5,1142(s5) # ffffffffc0208228 <nbase>
ffffffffc0202dba:	415787b3          	sub	a5,a5,s5
ffffffffc0202dbe:	079a                	slli	a5,a5,0x6
ffffffffc0202dc0:	943e                	add	s0,s0,a5
            if (page == NULL)
ffffffffc0202dc2:	10040263          	beqz	s0,ffffffffc0202ec6 <do_pgfault+0x1a6>
            if (page_ref(page) > 1)
ffffffffc0202dc6:	4014                	lw	a3,0(s0)
ffffffffc0202dc8:	4785                	li	a5,1
ffffffffc0202dca:	0cd7d863          	bge	a5,a3,ffffffffc0202e9a <do_pgfault+0x17a>
                struct Page *npage = alloc_page();
ffffffffc0202dce:	4505                	li	a0,1
ffffffffc0202dd0:	e76fe0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0202dd4:	8a2a                	mv	s4,a0
                if (npage == NULL)
ffffffffc0202dd6:	0e050a63          	beqz	a0,ffffffffc0202eca <do_pgfault+0x1aa>
    return page - pages + nbase;
ffffffffc0202dda:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0202dde:	577d                	li	a4,-1
ffffffffc0202de0:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc0202de4:	40d507b3          	sub	a5,a0,a3
ffffffffc0202de8:	8799                	srai	a5,a5,0x6
ffffffffc0202dea:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0202dec:	8331                	srli	a4,a4,0xc
ffffffffc0202dee:	00e7f5b3          	and	a1,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0202df2:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202df4:	10c5f563          	bgeu	a1,a2,ffffffffc0202efe <do_pgfault+0x1de>
    return page - pages + nbase;
ffffffffc0202df8:	40d406b3          	sub	a3,s0,a3
ffffffffc0202dfc:	8699                	srai	a3,a3,0x6
ffffffffc0202dfe:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0202e00:	000c3597          	auipc	a1,0xc3
ffffffffc0202e04:	3705b583          	ld	a1,880(a1) # ffffffffc02c6170 <va_pa_offset>
ffffffffc0202e08:	8f75                	and	a4,a4,a3
ffffffffc0202e0a:	00b78533          	add	a0,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e0e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e10:	0ac77f63          	bgeu	a4,a2,ffffffffc0202ece <do_pgfault+0x1ae>
                memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0202e14:	95b6                	add	a1,a1,a3
ffffffffc0202e16:	6605                	lui	a2,0x1
ffffffffc0202e18:	3e7020ef          	jal	ra,ffffffffc02059fe <memcpy>
                return page_insert(mm->pgdir, npage, la, perm);
ffffffffc0202e1c:	01893503          	ld	a0,24(s2)
ffffffffc0202e20:	0049e693          	ori	a3,s3,4
ffffffffc0202e24:	8626                	mv	a2,s1
ffffffffc0202e26:	85d2                	mv	a1,s4
}
ffffffffc0202e28:	6406                	ld	s0,64(sp)
ffffffffc0202e2a:	60a6                	ld	ra,72(sp)
ffffffffc0202e2c:	74e2                	ld	s1,56(sp)
ffffffffc0202e2e:	7942                	ld	s2,48(sp)
ffffffffc0202e30:	79a2                	ld	s3,40(sp)
ffffffffc0202e32:	7a02                	ld	s4,32(sp)
ffffffffc0202e34:	6ae2                	ld	s5,24(sp)
ffffffffc0202e36:	6b42                	ld	s6,16(sp)
ffffffffc0202e38:	6ba2                	ld	s7,8(sp)
ffffffffc0202e3a:	6161                	addi	sp,sp,80
    return page_insert(mm->pgdir, npage, la, perm);
ffffffffc0202e3c:	db3fe06f          	j	ffffffffc0201bee <page_insert>
        perm |= PTE_X;
ffffffffc0202e40:	0089e993          	ori	s3,s3,8
ffffffffc0202e44:	b70d                	j	ffffffffc0202d66 <do_pgfault+0x46>
    struct Page *npage = alloc_page();
ffffffffc0202e46:	4505                	li	a0,1
ffffffffc0202e48:	dfefe0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0202e4c:	842a                	mv	s0,a0
    if (npage == NULL)
ffffffffc0202e4e:	cd35                	beqz	a0,ffffffffc0202eca <do_pgfault+0x1aa>
    return page - pages + nbase;
ffffffffc0202e50:	000c3697          	auipc	a3,0xc3
ffffffffc0202e54:	3106b683          	ld	a3,784(a3) # ffffffffc02c6160 <pages>
ffffffffc0202e58:	40d506b3          	sub	a3,a0,a3
ffffffffc0202e5c:	8699                	srai	a3,a3,0x6
ffffffffc0202e5e:	00005517          	auipc	a0,0x5
ffffffffc0202e62:	3ca53503          	ld	a0,970(a0) # ffffffffc0208228 <nbase>
ffffffffc0202e66:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0202e68:	00c69793          	slli	a5,a3,0xc
ffffffffc0202e6c:	83b1                	srli	a5,a5,0xc
ffffffffc0202e6e:	000c3717          	auipc	a4,0xc3
ffffffffc0202e72:	2ea73703          	ld	a4,746(a4) # ffffffffc02c6158 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e76:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e78:	04e7fb63          	bgeu	a5,a4,ffffffffc0202ece <do_pgfault+0x1ae>
    memset(page2kva(npage), 0, PGSIZE);
ffffffffc0202e7c:	000c3517          	auipc	a0,0xc3
ffffffffc0202e80:	2f453503          	ld	a0,756(a0) # ffffffffc02c6170 <va_pa_offset>
ffffffffc0202e84:	6605                	lui	a2,0x1
ffffffffc0202e86:	4581                	li	a1,0
ffffffffc0202e88:	9536                	add	a0,a0,a3
ffffffffc0202e8a:	363020ef          	jal	ra,ffffffffc02059ec <memset>
    return page_insert(mm->pgdir, npage, la, perm);
ffffffffc0202e8e:	01893503          	ld	a0,24(s2)
ffffffffc0202e92:	86ce                	mv	a3,s3
ffffffffc0202e94:	8626                	mv	a2,s1
ffffffffc0202e96:	85a2                	mv	a1,s0
ffffffffc0202e98:	bf41                	j	ffffffffc0202e28 <do_pgfault+0x108>
            tlb_invalidate(mm->pgdir, la);
ffffffffc0202e9a:	01893503          	ld	a0,24(s2)
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
ffffffffc0202e9e:	efb67613          	andi	a2,a2,-261
ffffffffc0202ea2:	00466613          	ori	a2,a2,4
ffffffffc0202ea6:	e310                	sd	a2,0(a4)
            tlb_invalidate(mm->pgdir, la);
ffffffffc0202ea8:	85a6                	mv	a1,s1
ffffffffc0202eaa:	d1bff0ef          	jal	ra,ffffffffc0202bc4 <tlb_invalidate>
            return 0;
ffffffffc0202eae:	4501                	li	a0,0
}
ffffffffc0202eb0:	60a6                	ld	ra,72(sp)
ffffffffc0202eb2:	6406                	ld	s0,64(sp)
ffffffffc0202eb4:	74e2                	ld	s1,56(sp)
ffffffffc0202eb6:	7942                	ld	s2,48(sp)
ffffffffc0202eb8:	79a2                	ld	s3,40(sp)
ffffffffc0202eba:	7a02                	ld	s4,32(sp)
ffffffffc0202ebc:	6ae2                	ld	s5,24(sp)
ffffffffc0202ebe:	6b42                	ld	s6,16(sp)
ffffffffc0202ec0:	6ba2                	ld	s7,8(sp)
ffffffffc0202ec2:	6161                	addi	sp,sp,80
ffffffffc0202ec4:	8082                	ret
        return -E_INVAL;
ffffffffc0202ec6:	5575                	li	a0,-3
ffffffffc0202ec8:	b7e5                	j	ffffffffc0202eb0 <do_pgfault+0x190>
        return -E_NO_MEM;
ffffffffc0202eca:	5571                	li	a0,-4
ffffffffc0202ecc:	b7d5                	j	ffffffffc0202eb0 <do_pgfault+0x190>
ffffffffc0202ece:	00004617          	auipc	a2,0x4
ffffffffc0202ed2:	c8a60613          	addi	a2,a2,-886 # ffffffffc0206b58 <commands+0x960>
ffffffffc0202ed6:	07100593          	li	a1,113
ffffffffc0202eda:	00004517          	auipc	a0,0x4
ffffffffc0202ede:	c6e50513          	addi	a0,a0,-914 # ffffffffc0206b48 <commands+0x950>
ffffffffc0202ee2:	b3cfd0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202ee6:	00004617          	auipc	a2,0x4
ffffffffc0202eea:	c4260613          	addi	a2,a2,-958 # ffffffffc0206b28 <commands+0x930>
ffffffffc0202eee:	06900593          	li	a1,105
ffffffffc0202ef2:	00004517          	auipc	a0,0x4
ffffffffc0202ef6:	c5650513          	addi	a0,a0,-938 # ffffffffc0206b48 <commands+0x950>
ffffffffc0202efa:	b24fd0ef          	jal	ra,ffffffffc020021e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202efe:	86be                	mv	a3,a5
ffffffffc0202f00:	00004617          	auipc	a2,0x4
ffffffffc0202f04:	c5860613          	addi	a2,a2,-936 # ffffffffc0206b58 <commands+0x960>
ffffffffc0202f08:	07100593          	li	a1,113
ffffffffc0202f0c:	00004517          	auipc	a0,0x4
ffffffffc0202f10:	c3c50513          	addi	a0,a0,-964 # ffffffffc0206b48 <commands+0x950>
ffffffffc0202f14:	b0afd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0202f18 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202f18:	6590                	ld	a2,8(a1)
ffffffffc0202f1a:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202f1e:	1141                	addi	sp,sp,-16
ffffffffc0202f20:	e406                	sd	ra,8(sp)
ffffffffc0202f22:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202f24:	01066763          	bltu	a2,a6,ffffffffc0202f32 <insert_vma_struct+0x1a>
ffffffffc0202f28:	a085                	j	ffffffffc0202f88 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202f2a:	fe87b703          	ld	a4,-24(a5) # ffffffffffffefe8 <end+0x3fd38e4c>
ffffffffc0202f2e:	04e66863          	bltu	a2,a4,ffffffffc0202f7e <insert_vma_struct+0x66>
ffffffffc0202f32:	86be                	mv	a3,a5
ffffffffc0202f34:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202f36:	fef51ae3          	bne	a0,a5,ffffffffc0202f2a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202f3a:	02a68463          	beq	a3,a0,ffffffffc0202f62 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202f3e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202f42:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202f46:	08e8f163          	bgeu	a7,a4,ffffffffc0202fc8 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202f4a:	04e66f63          	bltu	a2,a4,ffffffffc0202fa8 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202f4e:	00f50a63          	beq	a0,a5,ffffffffc0202f62 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202f52:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202f56:	05076963          	bltu	a4,a6,ffffffffc0202fa8 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202f5a:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202f5e:	02c77363          	bgeu	a4,a2,ffffffffc0202f84 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202f62:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202f64:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202f66:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0202f6a:	e390                	sd	a2,0(a5)
ffffffffc0202f6c:	e690                	sd	a2,8(a3)
}
ffffffffc0202f6e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202f70:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202f72:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202f74:	0017079b          	addiw	a5,a4,1
ffffffffc0202f78:	d11c                	sw	a5,32(a0)
}
ffffffffc0202f7a:	0141                	addi	sp,sp,16
ffffffffc0202f7c:	8082                	ret
    if (le_prev != list)
ffffffffc0202f7e:	fca690e3          	bne	a3,a0,ffffffffc0202f3e <insert_vma_struct+0x26>
ffffffffc0202f82:	bfd1                	j	ffffffffc0202f56 <insert_vma_struct+0x3e>
ffffffffc0202f84:	d09ff0ef          	jal	ra,ffffffffc0202c8c <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202f88:	00004697          	auipc	a3,0x4
ffffffffc0202f8c:	2b868693          	addi	a3,a3,696 # ffffffffc0207240 <commands+0x1048>
ffffffffc0202f90:	00004617          	auipc	a2,0x4
ffffffffc0202f94:	c5860613          	addi	a2,a2,-936 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202f98:	0c600593          	li	a1,198
ffffffffc0202f9c:	00004517          	auipc	a0,0x4
ffffffffc0202fa0:	29450513          	addi	a0,a0,660 # ffffffffc0207230 <commands+0x1038>
ffffffffc0202fa4:	a7afd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202fa8:	00004697          	auipc	a3,0x4
ffffffffc0202fac:	2d868693          	addi	a3,a3,728 # ffffffffc0207280 <commands+0x1088>
ffffffffc0202fb0:	00004617          	auipc	a2,0x4
ffffffffc0202fb4:	c3860613          	addi	a2,a2,-968 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202fb8:	0bf00593          	li	a1,191
ffffffffc0202fbc:	00004517          	auipc	a0,0x4
ffffffffc0202fc0:	27450513          	addi	a0,a0,628 # ffffffffc0207230 <commands+0x1038>
ffffffffc0202fc4:	a5afd0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202fc8:	00004697          	auipc	a3,0x4
ffffffffc0202fcc:	29868693          	addi	a3,a3,664 # ffffffffc0207260 <commands+0x1068>
ffffffffc0202fd0:	00004617          	auipc	a2,0x4
ffffffffc0202fd4:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0202fd8:	0be00593          	li	a1,190
ffffffffc0202fdc:	00004517          	auipc	a0,0x4
ffffffffc0202fe0:	25450513          	addi	a0,a0,596 # ffffffffc0207230 <commands+0x1038>
ffffffffc0202fe4:	a3afd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0202fe8 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0202fe8:	591c                	lw	a5,48(a0)
{
ffffffffc0202fea:	1141                	addi	sp,sp,-16
ffffffffc0202fec:	e406                	sd	ra,8(sp)
ffffffffc0202fee:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0202ff0:	e78d                	bnez	a5,ffffffffc020301a <mm_destroy+0x32>
ffffffffc0202ff2:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0202ff4:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0202ff6:	00a40c63          	beq	s0,a0,ffffffffc020300e <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202ffa:	6118                	ld	a4,0(a0)
ffffffffc0202ffc:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0202ffe:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0203000:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203002:	e398                	sd	a4,0(a5)
ffffffffc0203004:	0c5000ef          	jal	ra,ffffffffc02038c8 <kfree>
    return listelm->next;
ffffffffc0203008:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020300a:	fea418e3          	bne	s0,a0,ffffffffc0202ffa <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020300e:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203010:	6402                	ld	s0,0(sp)
ffffffffc0203012:	60a2                	ld	ra,8(sp)
ffffffffc0203014:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203016:	0b30006f          	j	ffffffffc02038c8 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020301a:	00004697          	auipc	a3,0x4
ffffffffc020301e:	28668693          	addi	a3,a3,646 # ffffffffc02072a0 <commands+0x10a8>
ffffffffc0203022:	00004617          	auipc	a2,0x4
ffffffffc0203026:	bc660613          	addi	a2,a2,-1082 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020302a:	0ea00593          	li	a1,234
ffffffffc020302e:	00004517          	auipc	a0,0x4
ffffffffc0203032:	20250513          	addi	a0,a0,514 # ffffffffc0207230 <commands+0x1038>
ffffffffc0203036:	9e8fd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc020303a <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020303a:	7139                	addi	sp,sp,-64
ffffffffc020303c:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020303e:	6405                	lui	s0,0x1
ffffffffc0203040:	147d                	addi	s0,s0,-1
ffffffffc0203042:	77fd                	lui	a5,0xfffff
ffffffffc0203044:	9622                	add	a2,a2,s0
ffffffffc0203046:	962e                	add	a2,a2,a1
{
ffffffffc0203048:	f426                	sd	s1,40(sp)
ffffffffc020304a:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020304c:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203050:	f04a                	sd	s2,32(sp)
ffffffffc0203052:	ec4e                	sd	s3,24(sp)
ffffffffc0203054:	e852                	sd	s4,16(sp)
ffffffffc0203056:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203058:	002005b7          	lui	a1,0x200
ffffffffc020305c:	00f67433          	and	s0,a2,a5
ffffffffc0203060:	06b4e363          	bltu	s1,a1,ffffffffc02030c6 <mm_map+0x8c>
ffffffffc0203064:	0684f163          	bgeu	s1,s0,ffffffffc02030c6 <mm_map+0x8c>
ffffffffc0203068:	4785                	li	a5,1
ffffffffc020306a:	07fe                	slli	a5,a5,0x1f
ffffffffc020306c:	0487ed63          	bltu	a5,s0,ffffffffc02030c6 <mm_map+0x8c>
ffffffffc0203070:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203072:	cd21                	beqz	a0,ffffffffc02030ca <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203074:	85a6                	mv	a1,s1
ffffffffc0203076:	8ab6                	mv	s5,a3
ffffffffc0203078:	8a3a                	mv	s4,a4
ffffffffc020307a:	c67ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
ffffffffc020307e:	c501                	beqz	a0,ffffffffc0203086 <mm_map+0x4c>
ffffffffc0203080:	651c                	ld	a5,8(a0)
ffffffffc0203082:	0487e263          	bltu	a5,s0,ffffffffc02030c6 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203086:	03000513          	li	a0,48
ffffffffc020308a:	78e000ef          	jal	ra,ffffffffc0203818 <kmalloc>
ffffffffc020308e:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203090:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203092:	02090163          	beqz	s2,ffffffffc02030b4 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203096:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203098:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020309c:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02030a0:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02030a4:	85ca                	mv	a1,s2
ffffffffc02030a6:	e73ff0ef          	jal	ra,ffffffffc0202f18 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02030aa:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02030ac:	000a0463          	beqz	s4,ffffffffc02030b4 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02030b0:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc02030b4:	70e2                	ld	ra,56(sp)
ffffffffc02030b6:	7442                	ld	s0,48(sp)
ffffffffc02030b8:	74a2                	ld	s1,40(sp)
ffffffffc02030ba:	7902                	ld	s2,32(sp)
ffffffffc02030bc:	69e2                	ld	s3,24(sp)
ffffffffc02030be:	6a42                	ld	s4,16(sp)
ffffffffc02030c0:	6aa2                	ld	s5,8(sp)
ffffffffc02030c2:	6121                	addi	sp,sp,64
ffffffffc02030c4:	8082                	ret
        return -E_INVAL;
ffffffffc02030c6:	5575                	li	a0,-3
ffffffffc02030c8:	b7f5                	j	ffffffffc02030b4 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02030ca:	00004697          	auipc	a3,0x4
ffffffffc02030ce:	1ee68693          	addi	a3,a3,494 # ffffffffc02072b8 <commands+0x10c0>
ffffffffc02030d2:	00004617          	auipc	a2,0x4
ffffffffc02030d6:	b1660613          	addi	a2,a2,-1258 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02030da:	0ff00593          	li	a1,255
ffffffffc02030de:	00004517          	auipc	a0,0x4
ffffffffc02030e2:	15250513          	addi	a0,a0,338 # ffffffffc0207230 <commands+0x1038>
ffffffffc02030e6:	938fd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02030ea <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02030ea:	7139                	addi	sp,sp,-64
ffffffffc02030ec:	fc06                	sd	ra,56(sp)
ffffffffc02030ee:	f822                	sd	s0,48(sp)
ffffffffc02030f0:	f426                	sd	s1,40(sp)
ffffffffc02030f2:	f04a                	sd	s2,32(sp)
ffffffffc02030f4:	ec4e                	sd	s3,24(sp)
ffffffffc02030f6:	e852                	sd	s4,16(sp)
ffffffffc02030f8:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02030fa:	c52d                	beqz	a0,ffffffffc0203164 <dup_mmap+0x7a>
ffffffffc02030fc:	892a                	mv	s2,a0
ffffffffc02030fe:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203100:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203102:	e595                	bnez	a1,ffffffffc020312e <dup_mmap+0x44>
ffffffffc0203104:	a085                	j	ffffffffc0203164 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203106:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203108:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4918>
        vma->vm_end = vm_end;
ffffffffc020310c:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203110:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203114:	e05ff0ef          	jal	ra,ffffffffc0202f18 <insert_vma_struct>

        /* lab5: fork 默认共享用户页，依赖 COW 减少复制 */
        bool share = 1;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203118:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x9190>
ffffffffc020311c:	fe843603          	ld	a2,-24(s0)
ffffffffc0203120:	6c8c                	ld	a1,24(s1)
ffffffffc0203122:	01893503          	ld	a0,24(s2)
ffffffffc0203126:	4705                	li	a4,1
ffffffffc0203128:	ffcff0ef          	jal	ra,ffffffffc0202924 <copy_range>
ffffffffc020312c:	e105                	bnez	a0,ffffffffc020314c <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020312e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203130:	02848863          	beq	s1,s0,ffffffffc0203160 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203134:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203138:	fe843a83          	ld	s5,-24(s0)
ffffffffc020313c:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203140:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203144:	6d4000ef          	jal	ra,ffffffffc0203818 <kmalloc>
ffffffffc0203148:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020314a:	fd55                	bnez	a0,ffffffffc0203106 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020314c:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020314e:	70e2                	ld	ra,56(sp)
ffffffffc0203150:	7442                	ld	s0,48(sp)
ffffffffc0203152:	74a2                	ld	s1,40(sp)
ffffffffc0203154:	7902                	ld	s2,32(sp)
ffffffffc0203156:	69e2                	ld	s3,24(sp)
ffffffffc0203158:	6a42                	ld	s4,16(sp)
ffffffffc020315a:	6aa2                	ld	s5,8(sp)
ffffffffc020315c:	6121                	addi	sp,sp,64
ffffffffc020315e:	8082                	ret
    return 0;
ffffffffc0203160:	4501                	li	a0,0
ffffffffc0203162:	b7f5                	j	ffffffffc020314e <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203164:	00004697          	auipc	a3,0x4
ffffffffc0203168:	16468693          	addi	a3,a3,356 # ffffffffc02072c8 <commands+0x10d0>
ffffffffc020316c:	00004617          	auipc	a2,0x4
ffffffffc0203170:	a7c60613          	addi	a2,a2,-1412 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203174:	11b00593          	li	a1,283
ffffffffc0203178:	00004517          	auipc	a0,0x4
ffffffffc020317c:	0b850513          	addi	a0,a0,184 # ffffffffc0207230 <commands+0x1038>
ffffffffc0203180:	89efd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0203184 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203184:	1101                	addi	sp,sp,-32
ffffffffc0203186:	ec06                	sd	ra,24(sp)
ffffffffc0203188:	e822                	sd	s0,16(sp)
ffffffffc020318a:	e426                	sd	s1,8(sp)
ffffffffc020318c:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020318e:	c531                	beqz	a0,ffffffffc02031da <exit_mmap+0x56>
ffffffffc0203190:	591c                	lw	a5,48(a0)
ffffffffc0203192:	84aa                	mv	s1,a0
ffffffffc0203194:	e3b9                	bnez	a5,ffffffffc02031da <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203196:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203198:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc020319c:	02850663          	beq	a0,s0,ffffffffc02031c8 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02031a0:	ff043603          	ld	a2,-16(s0)
ffffffffc02031a4:	fe843583          	ld	a1,-24(s0)
ffffffffc02031a8:	854a                	mv	a0,s2
ffffffffc02031aa:	dd0fe0ef          	jal	ra,ffffffffc020177a <unmap_range>
ffffffffc02031ae:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02031b0:	fe8498e3          	bne	s1,s0,ffffffffc02031a0 <exit_mmap+0x1c>
ffffffffc02031b4:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02031b6:	00848c63          	beq	s1,s0,ffffffffc02031ce <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02031ba:	ff043603          	ld	a2,-16(s0)
ffffffffc02031be:	fe843583          	ld	a1,-24(s0)
ffffffffc02031c2:	854a                	mv	a0,s2
ffffffffc02031c4:	efcfe0ef          	jal	ra,ffffffffc02018c0 <exit_range>
ffffffffc02031c8:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02031ca:	fe8498e3          	bne	s1,s0,ffffffffc02031ba <exit_mmap+0x36>
    }
}
ffffffffc02031ce:	60e2                	ld	ra,24(sp)
ffffffffc02031d0:	6442                	ld	s0,16(sp)
ffffffffc02031d2:	64a2                	ld	s1,8(sp)
ffffffffc02031d4:	6902                	ld	s2,0(sp)
ffffffffc02031d6:	6105                	addi	sp,sp,32
ffffffffc02031d8:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02031da:	00004697          	auipc	a3,0x4
ffffffffc02031de:	10e68693          	addi	a3,a3,270 # ffffffffc02072e8 <commands+0x10f0>
ffffffffc02031e2:	00004617          	auipc	a2,0x4
ffffffffc02031e6:	a0660613          	addi	a2,a2,-1530 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02031ea:	13500593          	li	a1,309
ffffffffc02031ee:	00004517          	auipc	a0,0x4
ffffffffc02031f2:	04250513          	addi	a0,a0,66 # ffffffffc0207230 <commands+0x1038>
ffffffffc02031f6:	828fd0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02031fa <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02031fa:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02031fc:	04000513          	li	a0,64
{
ffffffffc0203200:	fc06                	sd	ra,56(sp)
ffffffffc0203202:	f822                	sd	s0,48(sp)
ffffffffc0203204:	f426                	sd	s1,40(sp)
ffffffffc0203206:	f04a                	sd	s2,32(sp)
ffffffffc0203208:	ec4e                	sd	s3,24(sp)
ffffffffc020320a:	e852                	sd	s4,16(sp)
ffffffffc020320c:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020320e:	60a000ef          	jal	ra,ffffffffc0203818 <kmalloc>
    if (mm != NULL)
ffffffffc0203212:	2e050663          	beqz	a0,ffffffffc02034fe <vmm_init+0x304>
ffffffffc0203216:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203218:	e508                	sd	a0,8(a0)
ffffffffc020321a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020321c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203220:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203224:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203228:	02053423          	sd	zero,40(a0)
ffffffffc020322c:	02052823          	sw	zero,48(a0)
ffffffffc0203230:	02053c23          	sd	zero,56(a0)
ffffffffc0203234:	03200413          	li	s0,50
ffffffffc0203238:	a811                	j	ffffffffc020324c <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc020323a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020323c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020323e:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203242:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203244:	8526                	mv	a0,s1
ffffffffc0203246:	cd3ff0ef          	jal	ra,ffffffffc0202f18 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020324a:	c80d                	beqz	s0,ffffffffc020327c <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020324c:	03000513          	li	a0,48
ffffffffc0203250:	5c8000ef          	jal	ra,ffffffffc0203818 <kmalloc>
ffffffffc0203254:	85aa                	mv	a1,a0
ffffffffc0203256:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020325a:	f165                	bnez	a0,ffffffffc020323a <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc020325c:	00004697          	auipc	a3,0x4
ffffffffc0203260:	22468693          	addi	a3,a3,548 # ffffffffc0207480 <commands+0x1288>
ffffffffc0203264:	00004617          	auipc	a2,0x4
ffffffffc0203268:	98460613          	addi	a2,a2,-1660 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020326c:	17900593          	li	a1,377
ffffffffc0203270:	00004517          	auipc	a0,0x4
ffffffffc0203274:	fc050513          	addi	a0,a0,-64 # ffffffffc0207230 <commands+0x1038>
ffffffffc0203278:	fa7fc0ef          	jal	ra,ffffffffc020021e <__panic>
ffffffffc020327c:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203280:	1f900913          	li	s2,505
ffffffffc0203284:	a819                	j	ffffffffc020329a <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203286:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203288:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020328a:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc020328e:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203290:	8526                	mv	a0,s1
ffffffffc0203292:	c87ff0ef          	jal	ra,ffffffffc0202f18 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203296:	03240a63          	beq	s0,s2,ffffffffc02032ca <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020329a:	03000513          	li	a0,48
ffffffffc020329e:	57a000ef          	jal	ra,ffffffffc0203818 <kmalloc>
ffffffffc02032a2:	85aa                	mv	a1,a0
ffffffffc02032a4:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02032a8:	fd79                	bnez	a0,ffffffffc0203286 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc02032aa:	00004697          	auipc	a3,0x4
ffffffffc02032ae:	1d668693          	addi	a3,a3,470 # ffffffffc0207480 <commands+0x1288>
ffffffffc02032b2:	00004617          	auipc	a2,0x4
ffffffffc02032b6:	93660613          	addi	a2,a2,-1738 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02032ba:	18000593          	li	a1,384
ffffffffc02032be:	00004517          	auipc	a0,0x4
ffffffffc02032c2:	f7250513          	addi	a0,a0,-142 # ffffffffc0207230 <commands+0x1038>
ffffffffc02032c6:	f59fc0ef          	jal	ra,ffffffffc020021e <__panic>
    return listelm->next;
ffffffffc02032ca:	649c                	ld	a5,8(s1)
ffffffffc02032cc:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02032ce:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02032d2:	16f48663          	beq	s1,a5,ffffffffc020343e <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02032d6:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd38e4c>
ffffffffc02032da:	ffe70693          	addi	a3,a4,-2
ffffffffc02032de:	10d61063          	bne	a2,a3,ffffffffc02033de <vmm_init+0x1e4>
ffffffffc02032e2:	ff07b683          	ld	a3,-16(a5)
ffffffffc02032e6:	0ed71c63          	bne	a4,a3,ffffffffc02033de <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc02032ea:	0715                	addi	a4,a4,5
ffffffffc02032ec:	679c                	ld	a5,8(a5)
ffffffffc02032ee:	feb712e3          	bne	a4,a1,ffffffffc02032d2 <vmm_init+0xd8>
ffffffffc02032f2:	4a1d                	li	s4,7
ffffffffc02032f4:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02032f6:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02032fa:	85a2                	mv	a1,s0
ffffffffc02032fc:	8526                	mv	a0,s1
ffffffffc02032fe:	9e3ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
ffffffffc0203302:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203304:	16050d63          	beqz	a0,ffffffffc020347e <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203308:	00140593          	addi	a1,s0,1
ffffffffc020330c:	8526                	mv	a0,s1
ffffffffc020330e:	9d3ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
ffffffffc0203312:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203314:	14050563          	beqz	a0,ffffffffc020345e <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203318:	85d2                	mv	a1,s4
ffffffffc020331a:	8526                	mv	a0,s1
ffffffffc020331c:	9c5ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203320:	16051f63          	bnez	a0,ffffffffc020349e <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203324:	00340593          	addi	a1,s0,3
ffffffffc0203328:	8526                	mv	a0,s1
ffffffffc020332a:	9b7ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
        assert(vma4 == NULL);
ffffffffc020332e:	1a051863          	bnez	a0,ffffffffc02034de <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203332:	00440593          	addi	a1,s0,4
ffffffffc0203336:	8526                	mv	a0,s1
ffffffffc0203338:	9a9ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
        assert(vma5 == NULL);
ffffffffc020333c:	18051163          	bnez	a0,ffffffffc02034be <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203340:	00893783          	ld	a5,8(s2)
ffffffffc0203344:	0a879d63          	bne	a5,s0,ffffffffc02033fe <vmm_init+0x204>
ffffffffc0203348:	01093783          	ld	a5,16(s2)
ffffffffc020334c:	0b479963          	bne	a5,s4,ffffffffc02033fe <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203350:	0089b783          	ld	a5,8(s3)
ffffffffc0203354:	0c879563          	bne	a5,s0,ffffffffc020341e <vmm_init+0x224>
ffffffffc0203358:	0109b783          	ld	a5,16(s3)
ffffffffc020335c:	0d479163          	bne	a5,s4,ffffffffc020341e <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203360:	0415                	addi	s0,s0,5
ffffffffc0203362:	0a15                	addi	s4,s4,5
ffffffffc0203364:	f9541be3          	bne	s0,s5,ffffffffc02032fa <vmm_init+0x100>
ffffffffc0203368:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc020336a:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc020336c:	85a2                	mv	a1,s0
ffffffffc020336e:	8526                	mv	a0,s1
ffffffffc0203370:	971ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
ffffffffc0203374:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203378:	c90d                	beqz	a0,ffffffffc02033aa <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc020337a:	6914                	ld	a3,16(a0)
ffffffffc020337c:	6510                	ld	a2,8(a0)
ffffffffc020337e:	00004517          	auipc	a0,0x4
ffffffffc0203382:	08a50513          	addi	a0,a0,138 # ffffffffc0207408 <commands+0x1210>
ffffffffc0203386:	d5bfc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc020338a:	00004697          	auipc	a3,0x4
ffffffffc020338e:	0a668693          	addi	a3,a3,166 # ffffffffc0207430 <commands+0x1238>
ffffffffc0203392:	00004617          	auipc	a2,0x4
ffffffffc0203396:	85660613          	addi	a2,a2,-1962 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020339a:	1a600593          	li	a1,422
ffffffffc020339e:	00004517          	auipc	a0,0x4
ffffffffc02033a2:	e9250513          	addi	a0,a0,-366 # ffffffffc0207230 <commands+0x1038>
ffffffffc02033a6:	e79fc0ef          	jal	ra,ffffffffc020021e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc02033aa:	147d                	addi	s0,s0,-1
ffffffffc02033ac:	fd2410e3          	bne	s0,s2,ffffffffc020336c <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc02033b0:	8526                	mv	a0,s1
ffffffffc02033b2:	c37ff0ef          	jal	ra,ffffffffc0202fe8 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02033b6:	00004517          	auipc	a0,0x4
ffffffffc02033ba:	09250513          	addi	a0,a0,146 # ffffffffc0207448 <commands+0x1250>
ffffffffc02033be:	d23fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc02033c2:	7442                	ld	s0,48(sp)
ffffffffc02033c4:	70e2                	ld	ra,56(sp)
ffffffffc02033c6:	74a2                	ld	s1,40(sp)
ffffffffc02033c8:	7902                	ld	s2,32(sp)
ffffffffc02033ca:	69e2                	ld	s3,24(sp)
ffffffffc02033cc:	6a42                	ld	s4,16(sp)
ffffffffc02033ce:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02033d0:	00004517          	auipc	a0,0x4
ffffffffc02033d4:	09850513          	addi	a0,a0,152 # ffffffffc0207468 <commands+0x1270>
}
ffffffffc02033d8:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02033da:	d07fc06f          	j	ffffffffc02000e0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02033de:	00004697          	auipc	a3,0x4
ffffffffc02033e2:	f4268693          	addi	a3,a3,-190 # ffffffffc0207320 <commands+0x1128>
ffffffffc02033e6:	00004617          	auipc	a2,0x4
ffffffffc02033ea:	80260613          	addi	a2,a2,-2046 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02033ee:	18a00593          	li	a1,394
ffffffffc02033f2:	00004517          	auipc	a0,0x4
ffffffffc02033f6:	e3e50513          	addi	a0,a0,-450 # ffffffffc0207230 <commands+0x1038>
ffffffffc02033fa:	e25fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02033fe:	00004697          	auipc	a3,0x4
ffffffffc0203402:	faa68693          	addi	a3,a3,-86 # ffffffffc02073a8 <commands+0x11b0>
ffffffffc0203406:	00003617          	auipc	a2,0x3
ffffffffc020340a:	7e260613          	addi	a2,a2,2018 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020340e:	19b00593          	li	a1,411
ffffffffc0203412:	00004517          	auipc	a0,0x4
ffffffffc0203416:	e1e50513          	addi	a0,a0,-482 # ffffffffc0207230 <commands+0x1038>
ffffffffc020341a:	e05fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020341e:	00004697          	auipc	a3,0x4
ffffffffc0203422:	fba68693          	addi	a3,a3,-70 # ffffffffc02073d8 <commands+0x11e0>
ffffffffc0203426:	00003617          	auipc	a2,0x3
ffffffffc020342a:	7c260613          	addi	a2,a2,1986 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020342e:	19c00593          	li	a1,412
ffffffffc0203432:	00004517          	auipc	a0,0x4
ffffffffc0203436:	dfe50513          	addi	a0,a0,-514 # ffffffffc0207230 <commands+0x1038>
ffffffffc020343a:	de5fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020343e:	00004697          	auipc	a3,0x4
ffffffffc0203442:	eca68693          	addi	a3,a3,-310 # ffffffffc0207308 <commands+0x1110>
ffffffffc0203446:	00003617          	auipc	a2,0x3
ffffffffc020344a:	7a260613          	addi	a2,a2,1954 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020344e:	18800593          	li	a1,392
ffffffffc0203452:	00004517          	auipc	a0,0x4
ffffffffc0203456:	dde50513          	addi	a0,a0,-546 # ffffffffc0207230 <commands+0x1038>
ffffffffc020345a:	dc5fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(vma2 != NULL);
ffffffffc020345e:	00004697          	auipc	a3,0x4
ffffffffc0203462:	f0a68693          	addi	a3,a3,-246 # ffffffffc0207368 <commands+0x1170>
ffffffffc0203466:	00003617          	auipc	a2,0x3
ffffffffc020346a:	78260613          	addi	a2,a2,1922 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020346e:	19300593          	li	a1,403
ffffffffc0203472:	00004517          	auipc	a0,0x4
ffffffffc0203476:	dbe50513          	addi	a0,a0,-578 # ffffffffc0207230 <commands+0x1038>
ffffffffc020347a:	da5fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(vma1 != NULL);
ffffffffc020347e:	00004697          	auipc	a3,0x4
ffffffffc0203482:	eda68693          	addi	a3,a3,-294 # ffffffffc0207358 <commands+0x1160>
ffffffffc0203486:	00003617          	auipc	a2,0x3
ffffffffc020348a:	76260613          	addi	a2,a2,1890 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020348e:	19100593          	li	a1,401
ffffffffc0203492:	00004517          	auipc	a0,0x4
ffffffffc0203496:	d9e50513          	addi	a0,a0,-610 # ffffffffc0207230 <commands+0x1038>
ffffffffc020349a:	d85fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(vma3 == NULL);
ffffffffc020349e:	00004697          	auipc	a3,0x4
ffffffffc02034a2:	eda68693          	addi	a3,a3,-294 # ffffffffc0207378 <commands+0x1180>
ffffffffc02034a6:	00003617          	auipc	a2,0x3
ffffffffc02034aa:	74260613          	addi	a2,a2,1858 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02034ae:	19500593          	li	a1,405
ffffffffc02034b2:	00004517          	auipc	a0,0x4
ffffffffc02034b6:	d7e50513          	addi	a0,a0,-642 # ffffffffc0207230 <commands+0x1038>
ffffffffc02034ba:	d65fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(vma5 == NULL);
ffffffffc02034be:	00004697          	auipc	a3,0x4
ffffffffc02034c2:	eda68693          	addi	a3,a3,-294 # ffffffffc0207398 <commands+0x11a0>
ffffffffc02034c6:	00003617          	auipc	a2,0x3
ffffffffc02034ca:	72260613          	addi	a2,a2,1826 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02034ce:	19900593          	li	a1,409
ffffffffc02034d2:	00004517          	auipc	a0,0x4
ffffffffc02034d6:	d5e50513          	addi	a0,a0,-674 # ffffffffc0207230 <commands+0x1038>
ffffffffc02034da:	d45fc0ef          	jal	ra,ffffffffc020021e <__panic>
        assert(vma4 == NULL);
ffffffffc02034de:	00004697          	auipc	a3,0x4
ffffffffc02034e2:	eaa68693          	addi	a3,a3,-342 # ffffffffc0207388 <commands+0x1190>
ffffffffc02034e6:	00003617          	auipc	a2,0x3
ffffffffc02034ea:	70260613          	addi	a2,a2,1794 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02034ee:	19700593          	li	a1,407
ffffffffc02034f2:	00004517          	auipc	a0,0x4
ffffffffc02034f6:	d3e50513          	addi	a0,a0,-706 # ffffffffc0207230 <commands+0x1038>
ffffffffc02034fa:	d25fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(mm != NULL);
ffffffffc02034fe:	00004697          	auipc	a3,0x4
ffffffffc0203502:	dba68693          	addi	a3,a3,-582 # ffffffffc02072b8 <commands+0x10c0>
ffffffffc0203506:	00003617          	auipc	a2,0x3
ffffffffc020350a:	6e260613          	addi	a2,a2,1762 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020350e:	17100593          	li	a1,369
ffffffffc0203512:	00004517          	auipc	a0,0x4
ffffffffc0203516:	d1e50513          	addi	a0,a0,-738 # ffffffffc0207230 <commands+0x1038>
ffffffffc020351a:	d05fc0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc020351e <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc020351e:	7179                	addi	sp,sp,-48
ffffffffc0203520:	f022                	sd	s0,32(sp)
ffffffffc0203522:	f406                	sd	ra,40(sp)
ffffffffc0203524:	ec26                	sd	s1,24(sp)
ffffffffc0203526:	e84a                	sd	s2,16(sp)
ffffffffc0203528:	e44e                	sd	s3,8(sp)
ffffffffc020352a:	e052                	sd	s4,0(sp)
ffffffffc020352c:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc020352e:	c135                	beqz	a0,ffffffffc0203592 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203530:	002007b7          	lui	a5,0x200
ffffffffc0203534:	04f5e663          	bltu	a1,a5,ffffffffc0203580 <user_mem_check+0x62>
ffffffffc0203538:	00c584b3          	add	s1,a1,a2
ffffffffc020353c:	0495f263          	bgeu	a1,s1,ffffffffc0203580 <user_mem_check+0x62>
ffffffffc0203540:	4785                	li	a5,1
ffffffffc0203542:	07fe                	slli	a5,a5,0x1f
ffffffffc0203544:	0297ee63          	bltu	a5,s1,ffffffffc0203580 <user_mem_check+0x62>
ffffffffc0203548:	892a                	mv	s2,a0
ffffffffc020354a:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc020354c:	6a05                	lui	s4,0x1
ffffffffc020354e:	a821                	j	ffffffffc0203566 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203550:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203554:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203556:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203558:	c685                	beqz	a3,ffffffffc0203580 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc020355a:	c399                	beqz	a5,ffffffffc0203560 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc020355c:	02e46263          	bltu	s0,a4,ffffffffc0203580 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203560:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203562:	04947663          	bgeu	s0,s1,ffffffffc02035ae <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203566:	85a2                	mv	a1,s0
ffffffffc0203568:	854a                	mv	a0,s2
ffffffffc020356a:	f76ff0ef          	jal	ra,ffffffffc0202ce0 <find_vma>
ffffffffc020356e:	c909                	beqz	a0,ffffffffc0203580 <user_mem_check+0x62>
ffffffffc0203570:	6518                	ld	a4,8(a0)
ffffffffc0203572:	00e46763          	bltu	s0,a4,ffffffffc0203580 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203576:	4d1c                	lw	a5,24(a0)
ffffffffc0203578:	fc099ce3          	bnez	s3,ffffffffc0203550 <user_mem_check+0x32>
ffffffffc020357c:	8b85                	andi	a5,a5,1
ffffffffc020357e:	f3ed                	bnez	a5,ffffffffc0203560 <user_mem_check+0x42>
            return 0;
ffffffffc0203580:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203582:	70a2                	ld	ra,40(sp)
ffffffffc0203584:	7402                	ld	s0,32(sp)
ffffffffc0203586:	64e2                	ld	s1,24(sp)
ffffffffc0203588:	6942                	ld	s2,16(sp)
ffffffffc020358a:	69a2                	ld	s3,8(sp)
ffffffffc020358c:	6a02                	ld	s4,0(sp)
ffffffffc020358e:	6145                	addi	sp,sp,48
ffffffffc0203590:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203592:	c02007b7          	lui	a5,0xc0200
ffffffffc0203596:	4501                	li	a0,0
ffffffffc0203598:	fef5e5e3          	bltu	a1,a5,ffffffffc0203582 <user_mem_check+0x64>
ffffffffc020359c:	962e                	add	a2,a2,a1
ffffffffc020359e:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203582 <user_mem_check+0x64>
ffffffffc02035a2:	c8000537          	lui	a0,0xc8000
ffffffffc02035a6:	0505                	addi	a0,a0,1
ffffffffc02035a8:	00a63533          	sltu	a0,a2,a0
ffffffffc02035ac:	bfd9                	j	ffffffffc0203582 <user_mem_check+0x64>
        return 1;
ffffffffc02035ae:	4505                	li	a0,1
ffffffffc02035b0:	bfc9                	j	ffffffffc0203582 <user_mem_check+0x64>

ffffffffc02035b2 <copy_from_user>:
{
ffffffffc02035b2:	1101                	addi	sp,sp,-32
ffffffffc02035b4:	e822                	sd	s0,16(sp)
ffffffffc02035b6:	e426                	sd	s1,8(sp)
ffffffffc02035b8:	8432                	mv	s0,a2
ffffffffc02035ba:	84b6                	mv	s1,a3
ffffffffc02035bc:	e04a                	sd	s2,0(sp)
    if (!user_mem_check(mm, (uintptr_t)src, len, writable))
ffffffffc02035be:	86ba                	mv	a3,a4
{
ffffffffc02035c0:	892e                	mv	s2,a1
    if (!user_mem_check(mm, (uintptr_t)src, len, writable))
ffffffffc02035c2:	8626                	mv	a2,s1
ffffffffc02035c4:	85a2                	mv	a1,s0
{
ffffffffc02035c6:	ec06                	sd	ra,24(sp)
    if (!user_mem_check(mm, (uintptr_t)src, len, writable))
ffffffffc02035c8:	f57ff0ef          	jal	ra,ffffffffc020351e <user_mem_check>
ffffffffc02035cc:	c519                	beqz	a0,ffffffffc02035da <copy_from_user+0x28>
    memcpy(dst, src, len);
ffffffffc02035ce:	8626                	mv	a2,s1
ffffffffc02035d0:	85a2                	mv	a1,s0
ffffffffc02035d2:	854a                	mv	a0,s2
ffffffffc02035d4:	42a020ef          	jal	ra,ffffffffc02059fe <memcpy>
    return 1;
ffffffffc02035d8:	4505                	li	a0,1
}
ffffffffc02035da:	60e2                	ld	ra,24(sp)
ffffffffc02035dc:	6442                	ld	s0,16(sp)
ffffffffc02035de:	64a2                	ld	s1,8(sp)
ffffffffc02035e0:	6902                	ld	s2,0(sp)
ffffffffc02035e2:	6105                	addi	sp,sp,32
ffffffffc02035e4:	8082                	ret

ffffffffc02035e6 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02035e6:	c94d                	beqz	a0,ffffffffc0203698 <slob_free+0xb2>
{
ffffffffc02035e8:	1141                	addi	sp,sp,-16
ffffffffc02035ea:	e022                	sd	s0,0(sp)
ffffffffc02035ec:	e406                	sd	ra,8(sp)
ffffffffc02035ee:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc02035f0:	e9c1                	bnez	a1,ffffffffc0203680 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035f2:	100027f3          	csrr	a5,sstatus
ffffffffc02035f6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02035f8:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035fa:	ebd9                	bnez	a5,ffffffffc0203690 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02035fc:	000be617          	auipc	a2,0xbe
ffffffffc0203600:	6c460613          	addi	a2,a2,1732 # ffffffffc02c1cc0 <slobfree>
ffffffffc0203604:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203606:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203608:	679c                	ld	a5,8(a5)
ffffffffc020360a:	02877a63          	bgeu	a4,s0,ffffffffc020363e <slob_free+0x58>
ffffffffc020360e:	00f46463          	bltu	s0,a5,ffffffffc0203616 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203612:	fef76ae3          	bltu	a4,a5,ffffffffc0203606 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0203616:	400c                	lw	a1,0(s0)
ffffffffc0203618:	00459693          	slli	a3,a1,0x4
ffffffffc020361c:	96a2                	add	a3,a3,s0
ffffffffc020361e:	02d78a63          	beq	a5,a3,ffffffffc0203652 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0203622:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0203624:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0203626:	00469793          	slli	a5,a3,0x4
ffffffffc020362a:	97ba                	add	a5,a5,a4
ffffffffc020362c:	02f40e63          	beq	s0,a5,ffffffffc0203668 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0203630:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0203632:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0203634:	e129                	bnez	a0,ffffffffc0203676 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0203636:	60a2                	ld	ra,8(sp)
ffffffffc0203638:	6402                	ld	s0,0(sp)
ffffffffc020363a:	0141                	addi	sp,sp,16
ffffffffc020363c:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020363e:	fcf764e3          	bltu	a4,a5,ffffffffc0203606 <slob_free+0x20>
ffffffffc0203642:	fcf472e3          	bgeu	s0,a5,ffffffffc0203606 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0203646:	400c                	lw	a1,0(s0)
ffffffffc0203648:	00459693          	slli	a3,a1,0x4
ffffffffc020364c:	96a2                	add	a3,a3,s0
ffffffffc020364e:	fcd79ae3          	bne	a5,a3,ffffffffc0203622 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0203652:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0203654:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0203656:	9db5                	addw	a1,a1,a3
ffffffffc0203658:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc020365a:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc020365c:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc020365e:	00469793          	slli	a5,a3,0x4
ffffffffc0203662:	97ba                	add	a5,a5,a4
ffffffffc0203664:	fcf416e3          	bne	s0,a5,ffffffffc0203630 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0203668:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc020366a:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc020366c:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc020366e:	9ebd                	addw	a3,a3,a5
ffffffffc0203670:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0203672:	e70c                	sd	a1,8(a4)
ffffffffc0203674:	d169                	beqz	a0,ffffffffc0203636 <slob_free+0x50>
}
ffffffffc0203676:	6402                	ld	s0,0(sp)
ffffffffc0203678:	60a2                	ld	ra,8(sp)
ffffffffc020367a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020367c:	c02fd06f          	j	ffffffffc0200a7e <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0203680:	25bd                	addiw	a1,a1,15
ffffffffc0203682:	8191                	srli	a1,a1,0x4
ffffffffc0203684:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203686:	100027f3          	csrr	a5,sstatus
ffffffffc020368a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020368c:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020368e:	d7bd                	beqz	a5,ffffffffc02035fc <slob_free+0x16>
        intr_disable();
ffffffffc0203690:	bf4fd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        return 1;
ffffffffc0203694:	4505                	li	a0,1
ffffffffc0203696:	b79d                	j	ffffffffc02035fc <slob_free+0x16>
ffffffffc0203698:	8082                	ret

ffffffffc020369a <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc020369a:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020369c:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc020369e:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02036a2:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc02036a4:	da3fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
	if (!page)
ffffffffc02036a8:	c91d                	beqz	a0,ffffffffc02036de <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02036aa:	000c3697          	auipc	a3,0xc3
ffffffffc02036ae:	ab66b683          	ld	a3,-1354(a3) # ffffffffc02c6160 <pages>
ffffffffc02036b2:	8d15                	sub	a0,a0,a3
ffffffffc02036b4:	8519                	srai	a0,a0,0x6
ffffffffc02036b6:	00005697          	auipc	a3,0x5
ffffffffc02036ba:	b726b683          	ld	a3,-1166(a3) # ffffffffc0208228 <nbase>
ffffffffc02036be:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02036c0:	00c51793          	slli	a5,a0,0xc
ffffffffc02036c4:	83b1                	srli	a5,a5,0xc
ffffffffc02036c6:	000c3717          	auipc	a4,0xc3
ffffffffc02036ca:	a9273703          	ld	a4,-1390(a4) # ffffffffc02c6158 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02036ce:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02036d0:	00e7fa63          	bgeu	a5,a4,ffffffffc02036e4 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02036d4:	000c3697          	auipc	a3,0xc3
ffffffffc02036d8:	a9c6b683          	ld	a3,-1380(a3) # ffffffffc02c6170 <va_pa_offset>
ffffffffc02036dc:	9536                	add	a0,a0,a3
}
ffffffffc02036de:	60a2                	ld	ra,8(sp)
ffffffffc02036e0:	0141                	addi	sp,sp,16
ffffffffc02036e2:	8082                	ret
ffffffffc02036e4:	86aa                	mv	a3,a0
ffffffffc02036e6:	00003617          	auipc	a2,0x3
ffffffffc02036ea:	47260613          	addi	a2,a2,1138 # ffffffffc0206b58 <commands+0x960>
ffffffffc02036ee:	07100593          	li	a1,113
ffffffffc02036f2:	00003517          	auipc	a0,0x3
ffffffffc02036f6:	45650513          	addi	a0,a0,1110 # ffffffffc0206b48 <commands+0x950>
ffffffffc02036fa:	b25fc0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02036fe <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02036fe:	1101                	addi	sp,sp,-32
ffffffffc0203700:	ec06                	sd	ra,24(sp)
ffffffffc0203702:	e822                	sd	s0,16(sp)
ffffffffc0203704:	e426                	sd	s1,8(sp)
ffffffffc0203706:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0203708:	01050713          	addi	a4,a0,16
ffffffffc020370c:	6785                	lui	a5,0x1
ffffffffc020370e:	0cf77363          	bgeu	a4,a5,ffffffffc02037d4 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0203712:	00f50493          	addi	s1,a0,15
ffffffffc0203716:	8091                	srli	s1,s1,0x4
ffffffffc0203718:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020371a:	10002673          	csrr	a2,sstatus
ffffffffc020371e:	8a09                	andi	a2,a2,2
ffffffffc0203720:	e25d                	bnez	a2,ffffffffc02037c6 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0203722:	000be917          	auipc	s2,0xbe
ffffffffc0203726:	59e90913          	addi	s2,s2,1438 # ffffffffc02c1cc0 <slobfree>
ffffffffc020372a:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc020372e:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0203730:	4398                	lw	a4,0(a5)
ffffffffc0203732:	08975e63          	bge	a4,s1,ffffffffc02037ce <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0203736:	00f68b63          	beq	a3,a5,ffffffffc020374c <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc020373a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc020373c:	4018                	lw	a4,0(s0)
ffffffffc020373e:	02975a63          	bge	a4,s1,ffffffffc0203772 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0203742:	00093683          	ld	a3,0(s2)
ffffffffc0203746:	87a2                	mv	a5,s0
ffffffffc0203748:	fef699e3          	bne	a3,a5,ffffffffc020373a <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc020374c:	ee31                	bnez	a2,ffffffffc02037a8 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc020374e:	4501                	li	a0,0
ffffffffc0203750:	f4bff0ef          	jal	ra,ffffffffc020369a <__slob_get_free_pages.constprop.0>
ffffffffc0203754:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0203756:	cd05                	beqz	a0,ffffffffc020378e <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0203758:	6585                	lui	a1,0x1
ffffffffc020375a:	e8dff0ef          	jal	ra,ffffffffc02035e6 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020375e:	10002673          	csrr	a2,sstatus
ffffffffc0203762:	8a09                	andi	a2,a2,2
ffffffffc0203764:	ee05                	bnez	a2,ffffffffc020379c <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0203766:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc020376a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc020376c:	4018                	lw	a4,0(s0)
ffffffffc020376e:	fc974ae3          	blt	a4,s1,ffffffffc0203742 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0203772:	04e48763          	beq	s1,a4,ffffffffc02037c0 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0203776:	00449693          	slli	a3,s1,0x4
ffffffffc020377a:	96a2                	add	a3,a3,s0
ffffffffc020377c:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc020377e:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0203780:	9f05                	subw	a4,a4,s1
ffffffffc0203782:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0203784:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0203786:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0203788:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc020378c:	e20d                	bnez	a2,ffffffffc02037ae <slob_alloc.constprop.0+0xb0>
}
ffffffffc020378e:	60e2                	ld	ra,24(sp)
ffffffffc0203790:	8522                	mv	a0,s0
ffffffffc0203792:	6442                	ld	s0,16(sp)
ffffffffc0203794:	64a2                	ld	s1,8(sp)
ffffffffc0203796:	6902                	ld	s2,0(sp)
ffffffffc0203798:	6105                	addi	sp,sp,32
ffffffffc020379a:	8082                	ret
        intr_disable();
ffffffffc020379c:	ae8fd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
			cur = slobfree;
ffffffffc02037a0:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02037a4:	4605                	li	a2,1
ffffffffc02037a6:	b7d1                	j	ffffffffc020376a <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02037a8:	ad6fd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02037ac:	b74d                	j	ffffffffc020374e <slob_alloc.constprop.0+0x50>
ffffffffc02037ae:	ad0fd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
}
ffffffffc02037b2:	60e2                	ld	ra,24(sp)
ffffffffc02037b4:	8522                	mv	a0,s0
ffffffffc02037b6:	6442                	ld	s0,16(sp)
ffffffffc02037b8:	64a2                	ld	s1,8(sp)
ffffffffc02037ba:	6902                	ld	s2,0(sp)
ffffffffc02037bc:	6105                	addi	sp,sp,32
ffffffffc02037be:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02037c0:	6418                	ld	a4,8(s0)
ffffffffc02037c2:	e798                	sd	a4,8(a5)
ffffffffc02037c4:	b7d1                	j	ffffffffc0203788 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02037c6:	abefd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        return 1;
ffffffffc02037ca:	4605                	li	a2,1
ffffffffc02037cc:	bf99                	j	ffffffffc0203722 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc02037ce:	843e                	mv	s0,a5
ffffffffc02037d0:	87b6                	mv	a5,a3
ffffffffc02037d2:	b745                	j	ffffffffc0203772 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02037d4:	00004697          	auipc	a3,0x4
ffffffffc02037d8:	cbc68693          	addi	a3,a3,-836 # ffffffffc0207490 <commands+0x1298>
ffffffffc02037dc:	00003617          	auipc	a2,0x3
ffffffffc02037e0:	40c60613          	addi	a2,a2,1036 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02037e4:	06300593          	li	a1,99
ffffffffc02037e8:	00004517          	auipc	a0,0x4
ffffffffc02037ec:	cc850513          	addi	a0,a0,-824 # ffffffffc02074b0 <commands+0x12b8>
ffffffffc02037f0:	a2ffc0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02037f4 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc02037f4:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc02037f6:	00004517          	auipc	a0,0x4
ffffffffc02037fa:	cd250513          	addi	a0,a0,-814 # ffffffffc02074c8 <commands+0x12d0>
{
ffffffffc02037fe:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0203800:	8e1fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0203804:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0203806:	00004517          	auipc	a0,0x4
ffffffffc020380a:	cda50513          	addi	a0,a0,-806 # ffffffffc02074e0 <commands+0x12e8>
}
ffffffffc020380e:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0203810:	8d1fc06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0203814 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0203814:	4501                	li	a0,0
ffffffffc0203816:	8082                	ret

ffffffffc0203818 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0203818:	1101                	addi	sp,sp,-32
ffffffffc020381a:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc020381c:	6905                	lui	s2,0x1
{
ffffffffc020381e:	e822                	sd	s0,16(sp)
ffffffffc0203820:	ec06                	sd	ra,24(sp)
ffffffffc0203822:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0203824:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x9191>
{
ffffffffc0203828:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc020382a:	04a7f963          	bgeu	a5,a0,ffffffffc020387c <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc020382e:	4561                	li	a0,24
ffffffffc0203830:	ecfff0ef          	jal	ra,ffffffffc02036fe <slob_alloc.constprop.0>
ffffffffc0203834:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0203836:	c929                	beqz	a0,ffffffffc0203888 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0203838:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc020383c:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc020383e:	00f95763          	bge	s2,a5,ffffffffc020384c <kmalloc+0x34>
ffffffffc0203842:	6705                	lui	a4,0x1
ffffffffc0203844:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0203846:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0203848:	fef74ee3          	blt	a4,a5,ffffffffc0203844 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc020384c:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc020384e:	e4dff0ef          	jal	ra,ffffffffc020369a <__slob_get_free_pages.constprop.0>
ffffffffc0203852:	e488                	sd	a0,8(s1)
ffffffffc0203854:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0203856:	c525                	beqz	a0,ffffffffc02038be <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203858:	100027f3          	csrr	a5,sstatus
ffffffffc020385c:	8b89                	andi	a5,a5,2
ffffffffc020385e:	ef8d                	bnez	a5,ffffffffc0203898 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0203860:	000c3797          	auipc	a5,0xc3
ffffffffc0203864:	91878793          	addi	a5,a5,-1768 # ffffffffc02c6178 <bigblocks>
ffffffffc0203868:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc020386a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020386c:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc020386e:	60e2                	ld	ra,24(sp)
ffffffffc0203870:	8522                	mv	a0,s0
ffffffffc0203872:	6442                	ld	s0,16(sp)
ffffffffc0203874:	64a2                	ld	s1,8(sp)
ffffffffc0203876:	6902                	ld	s2,0(sp)
ffffffffc0203878:	6105                	addi	sp,sp,32
ffffffffc020387a:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc020387c:	0541                	addi	a0,a0,16
ffffffffc020387e:	e81ff0ef          	jal	ra,ffffffffc02036fe <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0203882:	01050413          	addi	s0,a0,16
ffffffffc0203886:	f565                	bnez	a0,ffffffffc020386e <kmalloc+0x56>
ffffffffc0203888:	4401                	li	s0,0
}
ffffffffc020388a:	60e2                	ld	ra,24(sp)
ffffffffc020388c:	8522                	mv	a0,s0
ffffffffc020388e:	6442                	ld	s0,16(sp)
ffffffffc0203890:	64a2                	ld	s1,8(sp)
ffffffffc0203892:	6902                	ld	s2,0(sp)
ffffffffc0203894:	6105                	addi	sp,sp,32
ffffffffc0203896:	8082                	ret
        intr_disable();
ffffffffc0203898:	9ecfd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
		bb->next = bigblocks;
ffffffffc020389c:	000c3797          	auipc	a5,0xc3
ffffffffc02038a0:	8dc78793          	addi	a5,a5,-1828 # ffffffffc02c6178 <bigblocks>
ffffffffc02038a4:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc02038a6:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02038a8:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc02038aa:	9d4fd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
		return bb->pages;
ffffffffc02038ae:	6480                	ld	s0,8(s1)
}
ffffffffc02038b0:	60e2                	ld	ra,24(sp)
ffffffffc02038b2:	64a2                	ld	s1,8(sp)
ffffffffc02038b4:	8522                	mv	a0,s0
ffffffffc02038b6:	6442                	ld	s0,16(sp)
ffffffffc02038b8:	6902                	ld	s2,0(sp)
ffffffffc02038ba:	6105                	addi	sp,sp,32
ffffffffc02038bc:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc02038be:	45e1                	li	a1,24
ffffffffc02038c0:	8526                	mv	a0,s1
ffffffffc02038c2:	d25ff0ef          	jal	ra,ffffffffc02035e6 <slob_free>
	return __kmalloc(size, 0);
ffffffffc02038c6:	b765                	j	ffffffffc020386e <kmalloc+0x56>

ffffffffc02038c8 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc02038c8:	c179                	beqz	a0,ffffffffc020398e <kfree+0xc6>
{
ffffffffc02038ca:	1101                	addi	sp,sp,-32
ffffffffc02038cc:	e822                	sd	s0,16(sp)
ffffffffc02038ce:	ec06                	sd	ra,24(sp)
ffffffffc02038d0:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc02038d2:	03451793          	slli	a5,a0,0x34
ffffffffc02038d6:	842a                	mv	s0,a0
ffffffffc02038d8:	e7c1                	bnez	a5,ffffffffc0203960 <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02038da:	100027f3          	csrr	a5,sstatus
ffffffffc02038de:	8b89                	andi	a5,a5,2
ffffffffc02038e0:	ebc9                	bnez	a5,ffffffffc0203972 <kfree+0xaa>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc02038e2:	000c3797          	auipc	a5,0xc3
ffffffffc02038e6:	8967b783          	ld	a5,-1898(a5) # ffffffffc02c6178 <bigblocks>
    return 0;
ffffffffc02038ea:	4601                	li	a2,0
ffffffffc02038ec:	cbb5                	beqz	a5,ffffffffc0203960 <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc02038ee:	000c3697          	auipc	a3,0xc3
ffffffffc02038f2:	88a68693          	addi	a3,a3,-1910 # ffffffffc02c6178 <bigblocks>
ffffffffc02038f6:	a021                	j	ffffffffc02038fe <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc02038f8:	01048693          	addi	a3,s1,16
ffffffffc02038fc:	c3ad                	beqz	a5,ffffffffc020395e <kfree+0x96>
		{
			if (bb->pages == block)
ffffffffc02038fe:	6798                	ld	a4,8(a5)
ffffffffc0203900:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0203902:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0203904:	fe871ae3          	bne	a4,s0,ffffffffc02038f8 <kfree+0x30>
				*last = bb->next;
ffffffffc0203908:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc020390a:	ee3d                	bnez	a2,ffffffffc0203988 <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc020390c:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0203910:	4098                	lw	a4,0(s1)
ffffffffc0203912:	08f46b63          	bltu	s0,a5,ffffffffc02039a8 <kfree+0xe0>
ffffffffc0203916:	000c3697          	auipc	a3,0xc3
ffffffffc020391a:	85a6b683          	ld	a3,-1958(a3) # ffffffffc02c6170 <va_pa_offset>
ffffffffc020391e:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0203920:	8031                	srli	s0,s0,0xc
ffffffffc0203922:	000c3797          	auipc	a5,0xc3
ffffffffc0203926:	8367b783          	ld	a5,-1994(a5) # ffffffffc02c6158 <npage>
ffffffffc020392a:	06f47363          	bgeu	s0,a5,ffffffffc0203990 <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc020392e:	00005517          	auipc	a0,0x5
ffffffffc0203932:	8fa53503          	ld	a0,-1798(a0) # ffffffffc0208228 <nbase>
ffffffffc0203936:	8c09                	sub	s0,s0,a0
ffffffffc0203938:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc020393a:	000c3517          	auipc	a0,0xc3
ffffffffc020393e:	82653503          	ld	a0,-2010(a0) # ffffffffc02c6160 <pages>
ffffffffc0203942:	4585                	li	a1,1
ffffffffc0203944:	9522                	add	a0,a0,s0
ffffffffc0203946:	00e595bb          	sllw	a1,a1,a4
ffffffffc020394a:	b3bfd0ef          	jal	ra,ffffffffc0201484 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc020394e:	6442                	ld	s0,16(sp)
ffffffffc0203950:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203952:	8526                	mv	a0,s1
}
ffffffffc0203954:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203956:	45e1                	li	a1,24
}
ffffffffc0203958:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020395a:	c8dff06f          	j	ffffffffc02035e6 <slob_free>
ffffffffc020395e:	e215                	bnez	a2,ffffffffc0203982 <kfree+0xba>
ffffffffc0203960:	ff040513          	addi	a0,s0,-16
}
ffffffffc0203964:	6442                	ld	s0,16(sp)
ffffffffc0203966:	60e2                	ld	ra,24(sp)
ffffffffc0203968:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc020396a:	4581                	li	a1,0
}
ffffffffc020396c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020396e:	c79ff06f          	j	ffffffffc02035e6 <slob_free>
        intr_disable();
ffffffffc0203972:	912fd0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0203976:	000c3797          	auipc	a5,0xc3
ffffffffc020397a:	8027b783          	ld	a5,-2046(a5) # ffffffffc02c6178 <bigblocks>
        return 1;
ffffffffc020397e:	4605                	li	a2,1
ffffffffc0203980:	f7bd                	bnez	a5,ffffffffc02038ee <kfree+0x26>
        intr_enable();
ffffffffc0203982:	8fcfd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0203986:	bfe9                	j	ffffffffc0203960 <kfree+0x98>
ffffffffc0203988:	8f6fd0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc020398c:	b741                	j	ffffffffc020390c <kfree+0x44>
ffffffffc020398e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0203990:	00003617          	auipc	a2,0x3
ffffffffc0203994:	19860613          	addi	a2,a2,408 # ffffffffc0206b28 <commands+0x930>
ffffffffc0203998:	06900593          	li	a1,105
ffffffffc020399c:	00003517          	auipc	a0,0x3
ffffffffc02039a0:	1ac50513          	addi	a0,a0,428 # ffffffffc0206b48 <commands+0x950>
ffffffffc02039a4:	87bfc0ef          	jal	ra,ffffffffc020021e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02039a8:	86a2                	mv	a3,s0
ffffffffc02039aa:	00003617          	auipc	a2,0x3
ffffffffc02039ae:	2e660613          	addi	a2,a2,742 # ffffffffc0206c90 <commands+0xa98>
ffffffffc02039b2:	07700593          	li	a1,119
ffffffffc02039b6:	00003517          	auipc	a0,0x3
ffffffffc02039ba:	19250513          	addi	a0,a0,402 # ffffffffc0206b48 <commands+0x950>
ffffffffc02039be:	861fc0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02039c2 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02039c2:	000be797          	auipc	a5,0xbe
ffffffffc02039c6:	72e78793          	addi	a5,a5,1838 # ffffffffc02c20f0 <free_area>
ffffffffc02039ca:	e79c                	sd	a5,8(a5)
ffffffffc02039cc:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc02039ce:	0007a823          	sw	zero,16(a5)
}
ffffffffc02039d2:	8082                	ret

ffffffffc02039d4 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc02039d4:	000be517          	auipc	a0,0xbe
ffffffffc02039d8:	72c56503          	lwu	a0,1836(a0) # ffffffffc02c2100 <free_area+0x10>
ffffffffc02039dc:	8082                	ret

ffffffffc02039de <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc02039de:	715d                	addi	sp,sp,-80
ffffffffc02039e0:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02039e2:	000be417          	auipc	s0,0xbe
ffffffffc02039e6:	70e40413          	addi	s0,s0,1806 # ffffffffc02c20f0 <free_area>
ffffffffc02039ea:	641c                	ld	a5,8(s0)
ffffffffc02039ec:	e486                	sd	ra,72(sp)
ffffffffc02039ee:	fc26                	sd	s1,56(sp)
ffffffffc02039f0:	f84a                	sd	s2,48(sp)
ffffffffc02039f2:	f44e                	sd	s3,40(sp)
ffffffffc02039f4:	f052                	sd	s4,32(sp)
ffffffffc02039f6:	ec56                	sd	s5,24(sp)
ffffffffc02039f8:	e85a                	sd	s6,16(sp)
ffffffffc02039fa:	e45e                	sd	s7,8(sp)
ffffffffc02039fc:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02039fe:	2a878d63          	beq	a5,s0,ffffffffc0203cb8 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0203a02:	4481                	li	s1,0
ffffffffc0203a04:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203a06:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203a0a:	8b09                	andi	a4,a4,2
ffffffffc0203a0c:	2a070a63          	beqz	a4,ffffffffc0203cc0 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0203a10:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203a14:	679c                	ld	a5,8(a5)
ffffffffc0203a16:	2905                	addiw	s2,s2,1
ffffffffc0203a18:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0203a1a:	fe8796e3          	bne	a5,s0,ffffffffc0203a06 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0203a1e:	89a6                	mv	s3,s1
ffffffffc0203a20:	aa5fd0ef          	jal	ra,ffffffffc02014c4 <nr_free_pages>
ffffffffc0203a24:	6f351e63          	bne	a0,s3,ffffffffc0204120 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0203a28:	4505                	li	a0,1
ffffffffc0203a2a:	a1dfd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203a2e:	8aaa                	mv	s5,a0
ffffffffc0203a30:	42050863          	beqz	a0,ffffffffc0203e60 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203a34:	4505                	li	a0,1
ffffffffc0203a36:	a11fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203a3a:	89aa                	mv	s3,a0
ffffffffc0203a3c:	70050263          	beqz	a0,ffffffffc0204140 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203a40:	4505                	li	a0,1
ffffffffc0203a42:	a05fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203a46:	8a2a                	mv	s4,a0
ffffffffc0203a48:	48050c63          	beqz	a0,ffffffffc0203ee0 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203a4c:	293a8a63          	beq	s5,s3,ffffffffc0203ce0 <default_check+0x302>
ffffffffc0203a50:	28aa8863          	beq	s5,a0,ffffffffc0203ce0 <default_check+0x302>
ffffffffc0203a54:	28a98663          	beq	s3,a0,ffffffffc0203ce0 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203a58:	000aa783          	lw	a5,0(s5)
ffffffffc0203a5c:	2a079263          	bnez	a5,ffffffffc0203d00 <default_check+0x322>
ffffffffc0203a60:	0009a783          	lw	a5,0(s3)
ffffffffc0203a64:	28079e63          	bnez	a5,ffffffffc0203d00 <default_check+0x322>
ffffffffc0203a68:	411c                	lw	a5,0(a0)
ffffffffc0203a6a:	28079b63          	bnez	a5,ffffffffc0203d00 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0203a6e:	000c2797          	auipc	a5,0xc2
ffffffffc0203a72:	6f27b783          	ld	a5,1778(a5) # ffffffffc02c6160 <pages>
ffffffffc0203a76:	40fa8733          	sub	a4,s5,a5
ffffffffc0203a7a:	00004617          	auipc	a2,0x4
ffffffffc0203a7e:	7ae63603          	ld	a2,1966(a2) # ffffffffc0208228 <nbase>
ffffffffc0203a82:	8719                	srai	a4,a4,0x6
ffffffffc0203a84:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203a86:	000c2697          	auipc	a3,0xc2
ffffffffc0203a8a:	6d26b683          	ld	a3,1746(a3) # ffffffffc02c6158 <npage>
ffffffffc0203a8e:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203a90:	0732                	slli	a4,a4,0xc
ffffffffc0203a92:	28d77763          	bgeu	a4,a3,ffffffffc0203d20 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0203a96:	40f98733          	sub	a4,s3,a5
ffffffffc0203a9a:	8719                	srai	a4,a4,0x6
ffffffffc0203a9c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203a9e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0203aa0:	4cd77063          	bgeu	a4,a3,ffffffffc0203f60 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0203aa4:	40f507b3          	sub	a5,a0,a5
ffffffffc0203aa8:	8799                	srai	a5,a5,0x6
ffffffffc0203aaa:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203aac:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203aae:	30d7f963          	bgeu	a5,a3,ffffffffc0203dc0 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0203ab2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0203ab4:	00043c03          	ld	s8,0(s0)
ffffffffc0203ab8:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0203abc:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0203ac0:	e400                	sd	s0,8(s0)
ffffffffc0203ac2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0203ac4:	000be797          	auipc	a5,0xbe
ffffffffc0203ac8:	6207ae23          	sw	zero,1596(a5) # ffffffffc02c2100 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0203acc:	97bfd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203ad0:	2c051863          	bnez	a0,ffffffffc0203da0 <default_check+0x3c2>
    free_page(p0);
ffffffffc0203ad4:	4585                	li	a1,1
ffffffffc0203ad6:	8556                	mv	a0,s5
ffffffffc0203ad8:	9adfd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    free_page(p1);
ffffffffc0203adc:	4585                	li	a1,1
ffffffffc0203ade:	854e                	mv	a0,s3
ffffffffc0203ae0:	9a5fd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    free_page(p2);
ffffffffc0203ae4:	4585                	li	a1,1
ffffffffc0203ae6:	8552                	mv	a0,s4
ffffffffc0203ae8:	99dfd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    assert(nr_free == 3);
ffffffffc0203aec:	4818                	lw	a4,16(s0)
ffffffffc0203aee:	478d                	li	a5,3
ffffffffc0203af0:	28f71863          	bne	a4,a5,ffffffffc0203d80 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0203af4:	4505                	li	a0,1
ffffffffc0203af6:	951fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203afa:	89aa                	mv	s3,a0
ffffffffc0203afc:	26050263          	beqz	a0,ffffffffc0203d60 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203b00:	4505                	li	a0,1
ffffffffc0203b02:	945fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203b06:	8aaa                	mv	s5,a0
ffffffffc0203b08:	3a050c63          	beqz	a0,ffffffffc0203ec0 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203b0c:	4505                	li	a0,1
ffffffffc0203b0e:	939fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203b12:	8a2a                	mv	s4,a0
ffffffffc0203b14:	38050663          	beqz	a0,ffffffffc0203ea0 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0203b18:	4505                	li	a0,1
ffffffffc0203b1a:	92dfd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203b1e:	36051163          	bnez	a0,ffffffffc0203e80 <default_check+0x4a2>
    free_page(p0);
ffffffffc0203b22:	4585                	li	a1,1
ffffffffc0203b24:	854e                	mv	a0,s3
ffffffffc0203b26:	95ffd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0203b2a:	641c                	ld	a5,8(s0)
ffffffffc0203b2c:	20878a63          	beq	a5,s0,ffffffffc0203d40 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0203b30:	4505                	li	a0,1
ffffffffc0203b32:	915fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203b36:	30a99563          	bne	s3,a0,ffffffffc0203e40 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0203b3a:	4505                	li	a0,1
ffffffffc0203b3c:	90bfd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203b40:	2e051063          	bnez	a0,ffffffffc0203e20 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0203b44:	481c                	lw	a5,16(s0)
ffffffffc0203b46:	2a079d63          	bnez	a5,ffffffffc0203e00 <default_check+0x422>
    free_page(p);
ffffffffc0203b4a:	854e                	mv	a0,s3
ffffffffc0203b4c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0203b4e:	01843023          	sd	s8,0(s0)
ffffffffc0203b52:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0203b56:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0203b5a:	92bfd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    free_page(p1);
ffffffffc0203b5e:	4585                	li	a1,1
ffffffffc0203b60:	8556                	mv	a0,s5
ffffffffc0203b62:	923fd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    free_page(p2);
ffffffffc0203b66:	4585                	li	a1,1
ffffffffc0203b68:	8552                	mv	a0,s4
ffffffffc0203b6a:	91bfd0ef          	jal	ra,ffffffffc0201484 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0203b6e:	4515                	li	a0,5
ffffffffc0203b70:	8d7fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203b74:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0203b76:	26050563          	beqz	a0,ffffffffc0203de0 <default_check+0x402>
ffffffffc0203b7a:	651c                	ld	a5,8(a0)
ffffffffc0203b7c:	8385                	srli	a5,a5,0x1
ffffffffc0203b7e:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0203b80:	54079063          	bnez	a5,ffffffffc02040c0 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0203b84:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0203b86:	00043b03          	ld	s6,0(s0)
ffffffffc0203b8a:	00843a83          	ld	s5,8(s0)
ffffffffc0203b8e:	e000                	sd	s0,0(s0)
ffffffffc0203b90:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0203b92:	8b5fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203b96:	50051563          	bnez	a0,ffffffffc02040a0 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0203b9a:	08098a13          	addi	s4,s3,128
ffffffffc0203b9e:	8552                	mv	a0,s4
ffffffffc0203ba0:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0203ba2:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0203ba6:	000be797          	auipc	a5,0xbe
ffffffffc0203baa:	5407ad23          	sw	zero,1370(a5) # ffffffffc02c2100 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0203bae:	8d7fd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0203bb2:	4511                	li	a0,4
ffffffffc0203bb4:	893fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203bb8:	4c051463          	bnez	a0,ffffffffc0204080 <default_check+0x6a2>
ffffffffc0203bbc:	0889b783          	ld	a5,136(s3)
ffffffffc0203bc0:	8385                	srli	a5,a5,0x1
ffffffffc0203bc2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203bc4:	48078e63          	beqz	a5,ffffffffc0204060 <default_check+0x682>
ffffffffc0203bc8:	0909a703          	lw	a4,144(s3)
ffffffffc0203bcc:	478d                	li	a5,3
ffffffffc0203bce:	48f71963          	bne	a4,a5,ffffffffc0204060 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203bd2:	450d                	li	a0,3
ffffffffc0203bd4:	873fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203bd8:	8c2a                	mv	s8,a0
ffffffffc0203bda:	46050363          	beqz	a0,ffffffffc0204040 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0203bde:	4505                	li	a0,1
ffffffffc0203be0:	867fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203be4:	42051e63          	bnez	a0,ffffffffc0204020 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0203be8:	418a1c63          	bne	s4,s8,ffffffffc0204000 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0203bec:	4585                	li	a1,1
ffffffffc0203bee:	854e                	mv	a0,s3
ffffffffc0203bf0:	895fd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    free_pages(p1, 3);
ffffffffc0203bf4:	458d                	li	a1,3
ffffffffc0203bf6:	8552                	mv	a0,s4
ffffffffc0203bf8:	88dfd0ef          	jal	ra,ffffffffc0201484 <free_pages>
ffffffffc0203bfc:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0203c00:	04098c13          	addi	s8,s3,64
ffffffffc0203c04:	8385                	srli	a5,a5,0x1
ffffffffc0203c06:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203c08:	3c078c63          	beqz	a5,ffffffffc0203fe0 <default_check+0x602>
ffffffffc0203c0c:	0109a703          	lw	a4,16(s3)
ffffffffc0203c10:	4785                	li	a5,1
ffffffffc0203c12:	3cf71763          	bne	a4,a5,ffffffffc0203fe0 <default_check+0x602>
ffffffffc0203c16:	008a3783          	ld	a5,8(s4) # 1008 <_binary_obj___user_faultread_out_size-0x9178>
ffffffffc0203c1a:	8385                	srli	a5,a5,0x1
ffffffffc0203c1c:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203c1e:	3a078163          	beqz	a5,ffffffffc0203fc0 <default_check+0x5e2>
ffffffffc0203c22:	010a2703          	lw	a4,16(s4)
ffffffffc0203c26:	478d                	li	a5,3
ffffffffc0203c28:	38f71c63          	bne	a4,a5,ffffffffc0203fc0 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0203c2c:	4505                	li	a0,1
ffffffffc0203c2e:	819fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203c32:	36a99763          	bne	s3,a0,ffffffffc0203fa0 <default_check+0x5c2>
    free_page(p0);
ffffffffc0203c36:	4585                	li	a1,1
ffffffffc0203c38:	84dfd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0203c3c:	4509                	li	a0,2
ffffffffc0203c3e:	809fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203c42:	32aa1f63          	bne	s4,a0,ffffffffc0203f80 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0203c46:	4589                	li	a1,2
ffffffffc0203c48:	83dfd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    free_page(p2);
ffffffffc0203c4c:	4585                	li	a1,1
ffffffffc0203c4e:	8562                	mv	a0,s8
ffffffffc0203c50:	835fd0ef          	jal	ra,ffffffffc0201484 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203c54:	4515                	li	a0,5
ffffffffc0203c56:	ff0fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203c5a:	89aa                	mv	s3,a0
ffffffffc0203c5c:	48050263          	beqz	a0,ffffffffc02040e0 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0203c60:	4505                	li	a0,1
ffffffffc0203c62:	fe4fd0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0203c66:	2c051d63          	bnez	a0,ffffffffc0203f40 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0203c6a:	481c                	lw	a5,16(s0)
ffffffffc0203c6c:	2a079a63          	bnez	a5,ffffffffc0203f20 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0203c70:	4595                	li	a1,5
ffffffffc0203c72:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0203c74:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0203c78:	01643023          	sd	s6,0(s0)
ffffffffc0203c7c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0203c80:	805fd0ef          	jal	ra,ffffffffc0201484 <free_pages>
    return listelm->next;
ffffffffc0203c84:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0203c86:	00878963          	beq	a5,s0,ffffffffc0203c98 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0203c8a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203c8e:	679c                	ld	a5,8(a5)
ffffffffc0203c90:	397d                	addiw	s2,s2,-1
ffffffffc0203c92:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0203c94:	fe879be3          	bne	a5,s0,ffffffffc0203c8a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0203c98:	26091463          	bnez	s2,ffffffffc0203f00 <default_check+0x522>
    assert(total == 0);
ffffffffc0203c9c:	46049263          	bnez	s1,ffffffffc0204100 <default_check+0x722>
}
ffffffffc0203ca0:	60a6                	ld	ra,72(sp)
ffffffffc0203ca2:	6406                	ld	s0,64(sp)
ffffffffc0203ca4:	74e2                	ld	s1,56(sp)
ffffffffc0203ca6:	7942                	ld	s2,48(sp)
ffffffffc0203ca8:	79a2                	ld	s3,40(sp)
ffffffffc0203caa:	7a02                	ld	s4,32(sp)
ffffffffc0203cac:	6ae2                	ld	s5,24(sp)
ffffffffc0203cae:	6b42                	ld	s6,16(sp)
ffffffffc0203cb0:	6ba2                	ld	s7,8(sp)
ffffffffc0203cb2:	6c02                	ld	s8,0(sp)
ffffffffc0203cb4:	6161                	addi	sp,sp,80
ffffffffc0203cb6:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0203cb8:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0203cba:	4481                	li	s1,0
ffffffffc0203cbc:	4901                	li	s2,0
ffffffffc0203cbe:	b38d                	j	ffffffffc0203a20 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0203cc0:	00004697          	auipc	a3,0x4
ffffffffc0203cc4:	84068693          	addi	a3,a3,-1984 # ffffffffc0207500 <commands+0x1308>
ffffffffc0203cc8:	00003617          	auipc	a2,0x3
ffffffffc0203ccc:	f2060613          	addi	a2,a2,-224 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203cd0:	11000593          	li	a1,272
ffffffffc0203cd4:	00004517          	auipc	a0,0x4
ffffffffc0203cd8:	83c50513          	addi	a0,a0,-1988 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203cdc:	d42fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203ce0:	00004697          	auipc	a3,0x4
ffffffffc0203ce4:	8c868693          	addi	a3,a3,-1848 # ffffffffc02075a8 <commands+0x13b0>
ffffffffc0203ce8:	00003617          	auipc	a2,0x3
ffffffffc0203cec:	f0060613          	addi	a2,a2,-256 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203cf0:	0db00593          	li	a1,219
ffffffffc0203cf4:	00004517          	auipc	a0,0x4
ffffffffc0203cf8:	81c50513          	addi	a0,a0,-2020 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203cfc:	d22fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203d00:	00004697          	auipc	a3,0x4
ffffffffc0203d04:	8d068693          	addi	a3,a3,-1840 # ffffffffc02075d0 <commands+0x13d8>
ffffffffc0203d08:	00003617          	auipc	a2,0x3
ffffffffc0203d0c:	ee060613          	addi	a2,a2,-288 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203d10:	0dc00593          	li	a1,220
ffffffffc0203d14:	00003517          	auipc	a0,0x3
ffffffffc0203d18:	7fc50513          	addi	a0,a0,2044 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203d1c:	d02fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203d20:	00004697          	auipc	a3,0x4
ffffffffc0203d24:	8f068693          	addi	a3,a3,-1808 # ffffffffc0207610 <commands+0x1418>
ffffffffc0203d28:	00003617          	auipc	a2,0x3
ffffffffc0203d2c:	ec060613          	addi	a2,a2,-320 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203d30:	0de00593          	li	a1,222
ffffffffc0203d34:	00003517          	auipc	a0,0x3
ffffffffc0203d38:	7dc50513          	addi	a0,a0,2012 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203d3c:	ce2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0203d40:	00004697          	auipc	a3,0x4
ffffffffc0203d44:	95868693          	addi	a3,a3,-1704 # ffffffffc0207698 <commands+0x14a0>
ffffffffc0203d48:	00003617          	auipc	a2,0x3
ffffffffc0203d4c:	ea060613          	addi	a2,a2,-352 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203d50:	0f700593          	li	a1,247
ffffffffc0203d54:	00003517          	auipc	a0,0x3
ffffffffc0203d58:	7bc50513          	addi	a0,a0,1980 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203d5c:	cc2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0203d60:	00003697          	auipc	a3,0x3
ffffffffc0203d64:	7e868693          	addi	a3,a3,2024 # ffffffffc0207548 <commands+0x1350>
ffffffffc0203d68:	00003617          	auipc	a2,0x3
ffffffffc0203d6c:	e8060613          	addi	a2,a2,-384 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203d70:	0f000593          	li	a1,240
ffffffffc0203d74:	00003517          	auipc	a0,0x3
ffffffffc0203d78:	79c50513          	addi	a0,a0,1948 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203d7c:	ca2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(nr_free == 3);
ffffffffc0203d80:	00004697          	auipc	a3,0x4
ffffffffc0203d84:	90868693          	addi	a3,a3,-1784 # ffffffffc0207688 <commands+0x1490>
ffffffffc0203d88:	00003617          	auipc	a2,0x3
ffffffffc0203d8c:	e6060613          	addi	a2,a2,-416 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203d90:	0ee00593          	li	a1,238
ffffffffc0203d94:	00003517          	auipc	a0,0x3
ffffffffc0203d98:	77c50513          	addi	a0,a0,1916 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203d9c:	c82fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203da0:	00004697          	auipc	a3,0x4
ffffffffc0203da4:	8d068693          	addi	a3,a3,-1840 # ffffffffc0207670 <commands+0x1478>
ffffffffc0203da8:	00003617          	auipc	a2,0x3
ffffffffc0203dac:	e4060613          	addi	a2,a2,-448 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203db0:	0e900593          	li	a1,233
ffffffffc0203db4:	00003517          	auipc	a0,0x3
ffffffffc0203db8:	75c50513          	addi	a0,a0,1884 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203dbc:	c62fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203dc0:	00004697          	auipc	a3,0x4
ffffffffc0203dc4:	89068693          	addi	a3,a3,-1904 # ffffffffc0207650 <commands+0x1458>
ffffffffc0203dc8:	00003617          	auipc	a2,0x3
ffffffffc0203dcc:	e2060613          	addi	a2,a2,-480 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203dd0:	0e000593          	li	a1,224
ffffffffc0203dd4:	00003517          	auipc	a0,0x3
ffffffffc0203dd8:	73c50513          	addi	a0,a0,1852 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203ddc:	c42fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(p0 != NULL);
ffffffffc0203de0:	00004697          	auipc	a3,0x4
ffffffffc0203de4:	90068693          	addi	a3,a3,-1792 # ffffffffc02076e0 <commands+0x14e8>
ffffffffc0203de8:	00003617          	auipc	a2,0x3
ffffffffc0203dec:	e0060613          	addi	a2,a2,-512 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203df0:	11800593          	li	a1,280
ffffffffc0203df4:	00003517          	auipc	a0,0x3
ffffffffc0203df8:	71c50513          	addi	a0,a0,1820 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203dfc:	c22fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(nr_free == 0);
ffffffffc0203e00:	00004697          	auipc	a3,0x4
ffffffffc0203e04:	8d068693          	addi	a3,a3,-1840 # ffffffffc02076d0 <commands+0x14d8>
ffffffffc0203e08:	00003617          	auipc	a2,0x3
ffffffffc0203e0c:	de060613          	addi	a2,a2,-544 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203e10:	0fd00593          	li	a1,253
ffffffffc0203e14:	00003517          	auipc	a0,0x3
ffffffffc0203e18:	6fc50513          	addi	a0,a0,1788 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203e1c:	c02fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203e20:	00004697          	auipc	a3,0x4
ffffffffc0203e24:	85068693          	addi	a3,a3,-1968 # ffffffffc0207670 <commands+0x1478>
ffffffffc0203e28:	00003617          	auipc	a2,0x3
ffffffffc0203e2c:	dc060613          	addi	a2,a2,-576 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203e30:	0fb00593          	li	a1,251
ffffffffc0203e34:	00003517          	auipc	a0,0x3
ffffffffc0203e38:	6dc50513          	addi	a0,a0,1756 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203e3c:	be2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0203e40:	00004697          	auipc	a3,0x4
ffffffffc0203e44:	87068693          	addi	a3,a3,-1936 # ffffffffc02076b0 <commands+0x14b8>
ffffffffc0203e48:	00003617          	auipc	a2,0x3
ffffffffc0203e4c:	da060613          	addi	a2,a2,-608 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203e50:	0fa00593          	li	a1,250
ffffffffc0203e54:	00003517          	auipc	a0,0x3
ffffffffc0203e58:	6bc50513          	addi	a0,a0,1724 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203e5c:	bc2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0203e60:	00003697          	auipc	a3,0x3
ffffffffc0203e64:	6e868693          	addi	a3,a3,1768 # ffffffffc0207548 <commands+0x1350>
ffffffffc0203e68:	00003617          	auipc	a2,0x3
ffffffffc0203e6c:	d8060613          	addi	a2,a2,-640 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203e70:	0d700593          	li	a1,215
ffffffffc0203e74:	00003517          	auipc	a0,0x3
ffffffffc0203e78:	69c50513          	addi	a0,a0,1692 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203e7c:	ba2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203e80:	00003697          	auipc	a3,0x3
ffffffffc0203e84:	7f068693          	addi	a3,a3,2032 # ffffffffc0207670 <commands+0x1478>
ffffffffc0203e88:	00003617          	auipc	a2,0x3
ffffffffc0203e8c:	d6060613          	addi	a2,a2,-672 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203e90:	0f400593          	li	a1,244
ffffffffc0203e94:	00003517          	auipc	a0,0x3
ffffffffc0203e98:	67c50513          	addi	a0,a0,1660 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203e9c:	b82fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203ea0:	00003697          	auipc	a3,0x3
ffffffffc0203ea4:	6e868693          	addi	a3,a3,1768 # ffffffffc0207588 <commands+0x1390>
ffffffffc0203ea8:	00003617          	auipc	a2,0x3
ffffffffc0203eac:	d4060613          	addi	a2,a2,-704 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203eb0:	0f200593          	li	a1,242
ffffffffc0203eb4:	00003517          	auipc	a0,0x3
ffffffffc0203eb8:	65c50513          	addi	a0,a0,1628 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203ebc:	b62fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203ec0:	00003697          	auipc	a3,0x3
ffffffffc0203ec4:	6a868693          	addi	a3,a3,1704 # ffffffffc0207568 <commands+0x1370>
ffffffffc0203ec8:	00003617          	auipc	a2,0x3
ffffffffc0203ecc:	d2060613          	addi	a2,a2,-736 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203ed0:	0f100593          	li	a1,241
ffffffffc0203ed4:	00003517          	auipc	a0,0x3
ffffffffc0203ed8:	63c50513          	addi	a0,a0,1596 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203edc:	b42fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203ee0:	00003697          	auipc	a3,0x3
ffffffffc0203ee4:	6a868693          	addi	a3,a3,1704 # ffffffffc0207588 <commands+0x1390>
ffffffffc0203ee8:	00003617          	auipc	a2,0x3
ffffffffc0203eec:	d0060613          	addi	a2,a2,-768 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203ef0:	0d900593          	li	a1,217
ffffffffc0203ef4:	00003517          	auipc	a0,0x3
ffffffffc0203ef8:	61c50513          	addi	a0,a0,1564 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203efc:	b22fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(count == 0);
ffffffffc0203f00:	00004697          	auipc	a3,0x4
ffffffffc0203f04:	93068693          	addi	a3,a3,-1744 # ffffffffc0207830 <commands+0x1638>
ffffffffc0203f08:	00003617          	auipc	a2,0x3
ffffffffc0203f0c:	ce060613          	addi	a2,a2,-800 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203f10:	14600593          	li	a1,326
ffffffffc0203f14:	00003517          	auipc	a0,0x3
ffffffffc0203f18:	5fc50513          	addi	a0,a0,1532 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203f1c:	b02fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(nr_free == 0);
ffffffffc0203f20:	00003697          	auipc	a3,0x3
ffffffffc0203f24:	7b068693          	addi	a3,a3,1968 # ffffffffc02076d0 <commands+0x14d8>
ffffffffc0203f28:	00003617          	auipc	a2,0x3
ffffffffc0203f2c:	cc060613          	addi	a2,a2,-832 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203f30:	13a00593          	li	a1,314
ffffffffc0203f34:	00003517          	auipc	a0,0x3
ffffffffc0203f38:	5dc50513          	addi	a0,a0,1500 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203f3c:	ae2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203f40:	00003697          	auipc	a3,0x3
ffffffffc0203f44:	73068693          	addi	a3,a3,1840 # ffffffffc0207670 <commands+0x1478>
ffffffffc0203f48:	00003617          	auipc	a2,0x3
ffffffffc0203f4c:	ca060613          	addi	a2,a2,-864 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203f50:	13800593          	li	a1,312
ffffffffc0203f54:	00003517          	auipc	a0,0x3
ffffffffc0203f58:	5bc50513          	addi	a0,a0,1468 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203f5c:	ac2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0203f60:	00003697          	auipc	a3,0x3
ffffffffc0203f64:	6d068693          	addi	a3,a3,1744 # ffffffffc0207630 <commands+0x1438>
ffffffffc0203f68:	00003617          	auipc	a2,0x3
ffffffffc0203f6c:	c8060613          	addi	a2,a2,-896 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203f70:	0df00593          	li	a1,223
ffffffffc0203f74:	00003517          	auipc	a0,0x3
ffffffffc0203f78:	59c50513          	addi	a0,a0,1436 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203f7c:	aa2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0203f80:	00004697          	auipc	a3,0x4
ffffffffc0203f84:	87068693          	addi	a3,a3,-1936 # ffffffffc02077f0 <commands+0x15f8>
ffffffffc0203f88:	00003617          	auipc	a2,0x3
ffffffffc0203f8c:	c6060613          	addi	a2,a2,-928 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203f90:	13200593          	li	a1,306
ffffffffc0203f94:	00003517          	auipc	a0,0x3
ffffffffc0203f98:	57c50513          	addi	a0,a0,1404 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203f9c:	a82fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0203fa0:	00004697          	auipc	a3,0x4
ffffffffc0203fa4:	83068693          	addi	a3,a3,-2000 # ffffffffc02077d0 <commands+0x15d8>
ffffffffc0203fa8:	00003617          	auipc	a2,0x3
ffffffffc0203fac:	c4060613          	addi	a2,a2,-960 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203fb0:	13000593          	li	a1,304
ffffffffc0203fb4:	00003517          	auipc	a0,0x3
ffffffffc0203fb8:	55c50513          	addi	a0,a0,1372 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203fbc:	a62fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203fc0:	00003697          	auipc	a3,0x3
ffffffffc0203fc4:	7e868693          	addi	a3,a3,2024 # ffffffffc02077a8 <commands+0x15b0>
ffffffffc0203fc8:	00003617          	auipc	a2,0x3
ffffffffc0203fcc:	c2060613          	addi	a2,a2,-992 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203fd0:	12e00593          	li	a1,302
ffffffffc0203fd4:	00003517          	auipc	a0,0x3
ffffffffc0203fd8:	53c50513          	addi	a0,a0,1340 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203fdc:	a42fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203fe0:	00003697          	auipc	a3,0x3
ffffffffc0203fe4:	7a068693          	addi	a3,a3,1952 # ffffffffc0207780 <commands+0x1588>
ffffffffc0203fe8:	00003617          	auipc	a2,0x3
ffffffffc0203fec:	c0060613          	addi	a2,a2,-1024 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0203ff0:	12d00593          	li	a1,301
ffffffffc0203ff4:	00003517          	auipc	a0,0x3
ffffffffc0203ff8:	51c50513          	addi	a0,a0,1308 # ffffffffc0207510 <commands+0x1318>
ffffffffc0203ffc:	a22fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0204000:	00003697          	auipc	a3,0x3
ffffffffc0204004:	77068693          	addi	a3,a3,1904 # ffffffffc0207770 <commands+0x1578>
ffffffffc0204008:	00003617          	auipc	a2,0x3
ffffffffc020400c:	be060613          	addi	a2,a2,-1056 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204010:	12800593          	li	a1,296
ffffffffc0204014:	00003517          	auipc	a0,0x3
ffffffffc0204018:	4fc50513          	addi	a0,a0,1276 # ffffffffc0207510 <commands+0x1318>
ffffffffc020401c:	a02fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204020:	00003697          	auipc	a3,0x3
ffffffffc0204024:	65068693          	addi	a3,a3,1616 # ffffffffc0207670 <commands+0x1478>
ffffffffc0204028:	00003617          	auipc	a2,0x3
ffffffffc020402c:	bc060613          	addi	a2,a2,-1088 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204030:	12700593          	li	a1,295
ffffffffc0204034:	00003517          	auipc	a0,0x3
ffffffffc0204038:	4dc50513          	addi	a0,a0,1244 # ffffffffc0207510 <commands+0x1318>
ffffffffc020403c:	9e2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0204040:	00003697          	auipc	a3,0x3
ffffffffc0204044:	71068693          	addi	a3,a3,1808 # ffffffffc0207750 <commands+0x1558>
ffffffffc0204048:	00003617          	auipc	a2,0x3
ffffffffc020404c:	ba060613          	addi	a2,a2,-1120 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204050:	12600593          	li	a1,294
ffffffffc0204054:	00003517          	auipc	a0,0x3
ffffffffc0204058:	4bc50513          	addi	a0,a0,1212 # ffffffffc0207510 <commands+0x1318>
ffffffffc020405c:	9c2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0204060:	00003697          	auipc	a3,0x3
ffffffffc0204064:	6c068693          	addi	a3,a3,1728 # ffffffffc0207720 <commands+0x1528>
ffffffffc0204068:	00003617          	auipc	a2,0x3
ffffffffc020406c:	b8060613          	addi	a2,a2,-1152 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204070:	12500593          	li	a1,293
ffffffffc0204074:	00003517          	auipc	a0,0x3
ffffffffc0204078:	49c50513          	addi	a0,a0,1180 # ffffffffc0207510 <commands+0x1318>
ffffffffc020407c:	9a2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0204080:	00003697          	auipc	a3,0x3
ffffffffc0204084:	68868693          	addi	a3,a3,1672 # ffffffffc0207708 <commands+0x1510>
ffffffffc0204088:	00003617          	auipc	a2,0x3
ffffffffc020408c:	b6060613          	addi	a2,a2,-1184 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204090:	12400593          	li	a1,292
ffffffffc0204094:	00003517          	auipc	a0,0x3
ffffffffc0204098:	47c50513          	addi	a0,a0,1148 # ffffffffc0207510 <commands+0x1318>
ffffffffc020409c:	982fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02040a0:	00003697          	auipc	a3,0x3
ffffffffc02040a4:	5d068693          	addi	a3,a3,1488 # ffffffffc0207670 <commands+0x1478>
ffffffffc02040a8:	00003617          	auipc	a2,0x3
ffffffffc02040ac:	b4060613          	addi	a2,a2,-1216 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02040b0:	11e00593          	li	a1,286
ffffffffc02040b4:	00003517          	auipc	a0,0x3
ffffffffc02040b8:	45c50513          	addi	a0,a0,1116 # ffffffffc0207510 <commands+0x1318>
ffffffffc02040bc:	962fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(!PageProperty(p0));
ffffffffc02040c0:	00003697          	auipc	a3,0x3
ffffffffc02040c4:	63068693          	addi	a3,a3,1584 # ffffffffc02076f0 <commands+0x14f8>
ffffffffc02040c8:	00003617          	auipc	a2,0x3
ffffffffc02040cc:	b2060613          	addi	a2,a2,-1248 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02040d0:	11900593          	li	a1,281
ffffffffc02040d4:	00003517          	auipc	a0,0x3
ffffffffc02040d8:	43c50513          	addi	a0,a0,1084 # ffffffffc0207510 <commands+0x1318>
ffffffffc02040dc:	942fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02040e0:	00003697          	auipc	a3,0x3
ffffffffc02040e4:	73068693          	addi	a3,a3,1840 # ffffffffc0207810 <commands+0x1618>
ffffffffc02040e8:	00003617          	auipc	a2,0x3
ffffffffc02040ec:	b0060613          	addi	a2,a2,-1280 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02040f0:	13700593          	li	a1,311
ffffffffc02040f4:	00003517          	auipc	a0,0x3
ffffffffc02040f8:	41c50513          	addi	a0,a0,1052 # ffffffffc0207510 <commands+0x1318>
ffffffffc02040fc:	922fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(total == 0);
ffffffffc0204100:	00003697          	auipc	a3,0x3
ffffffffc0204104:	74068693          	addi	a3,a3,1856 # ffffffffc0207840 <commands+0x1648>
ffffffffc0204108:	00003617          	auipc	a2,0x3
ffffffffc020410c:	ae060613          	addi	a2,a2,-1312 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204110:	14700593          	li	a1,327
ffffffffc0204114:	00003517          	auipc	a0,0x3
ffffffffc0204118:	3fc50513          	addi	a0,a0,1020 # ffffffffc0207510 <commands+0x1318>
ffffffffc020411c:	902fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(total == nr_free_pages());
ffffffffc0204120:	00003697          	auipc	a3,0x3
ffffffffc0204124:	40868693          	addi	a3,a3,1032 # ffffffffc0207528 <commands+0x1330>
ffffffffc0204128:	00003617          	auipc	a2,0x3
ffffffffc020412c:	ac060613          	addi	a2,a2,-1344 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204130:	11300593          	li	a1,275
ffffffffc0204134:	00003517          	auipc	a0,0x3
ffffffffc0204138:	3dc50513          	addi	a0,a0,988 # ffffffffc0207510 <commands+0x1318>
ffffffffc020413c:	8e2fc0ef          	jal	ra,ffffffffc020021e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204140:	00003697          	auipc	a3,0x3
ffffffffc0204144:	42868693          	addi	a3,a3,1064 # ffffffffc0207568 <commands+0x1370>
ffffffffc0204148:	00003617          	auipc	a2,0x3
ffffffffc020414c:	aa060613          	addi	a2,a2,-1376 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204150:	0d800593          	li	a1,216
ffffffffc0204154:	00003517          	auipc	a0,0x3
ffffffffc0204158:	3bc50513          	addi	a0,a0,956 # ffffffffc0207510 <commands+0x1318>
ffffffffc020415c:	8c2fc0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0204160 <default_free_pages>:
{
ffffffffc0204160:	1141                	addi	sp,sp,-16
ffffffffc0204162:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204164:	14058463          	beqz	a1,ffffffffc02042ac <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0204168:	00659693          	slli	a3,a1,0x6
ffffffffc020416c:	96aa                	add	a3,a3,a0
ffffffffc020416e:	87aa                	mv	a5,a0
ffffffffc0204170:	02d50263          	beq	a0,a3,ffffffffc0204194 <default_free_pages+0x34>
ffffffffc0204174:	6798                	ld	a4,8(a5)
ffffffffc0204176:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0204178:	10071a63          	bnez	a4,ffffffffc020428c <default_free_pages+0x12c>
ffffffffc020417c:	6798                	ld	a4,8(a5)
ffffffffc020417e:	8b09                	andi	a4,a4,2
ffffffffc0204180:	10071663          	bnez	a4,ffffffffc020428c <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0204184:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0204188:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020418c:	04078793          	addi	a5,a5,64
ffffffffc0204190:	fed792e3          	bne	a5,a3,ffffffffc0204174 <default_free_pages+0x14>
    base->property = n;
ffffffffc0204194:	2581                	sext.w	a1,a1
ffffffffc0204196:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0204198:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020419c:	4789                	li	a5,2
ffffffffc020419e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02041a2:	000be697          	auipc	a3,0xbe
ffffffffc02041a6:	f4e68693          	addi	a3,a3,-178 # ffffffffc02c20f0 <free_area>
ffffffffc02041aa:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02041ac:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02041ae:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02041b2:	9db9                	addw	a1,a1,a4
ffffffffc02041b4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02041b6:	0ad78463          	beq	a5,a3,ffffffffc020425e <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02041ba:	fe878713          	addi	a4,a5,-24
ffffffffc02041be:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02041c2:	4581                	li	a1,0
            if (base < page)
ffffffffc02041c4:	00e56a63          	bltu	a0,a4,ffffffffc02041d8 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02041c8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02041ca:	04d70c63          	beq	a4,a3,ffffffffc0204222 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02041ce:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02041d0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02041d4:	fee57ae3          	bgeu	a0,a4,ffffffffc02041c8 <default_free_pages+0x68>
ffffffffc02041d8:	c199                	beqz	a1,ffffffffc02041de <default_free_pages+0x7e>
ffffffffc02041da:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02041de:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02041e0:	e390                	sd	a2,0(a5)
ffffffffc02041e2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02041e4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02041e6:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02041e8:	00d70d63          	beq	a4,a3,ffffffffc0204202 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02041ec:	ff872583          	lw	a1,-8(a4) # ff8 <_binary_obj___user_faultread_out_size-0x9188>
        p = le2page(le, page_link);
ffffffffc02041f0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02041f4:	02059813          	slli	a6,a1,0x20
ffffffffc02041f8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02041fc:	97b2                	add	a5,a5,a2
ffffffffc02041fe:	02f50c63          	beq	a0,a5,ffffffffc0204236 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0204202:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0204204:	00d78c63          	beq	a5,a3,ffffffffc020421c <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0204208:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020420a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020420e:	02061593          	slli	a1,a2,0x20
ffffffffc0204212:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0204216:	972a                	add	a4,a4,a0
ffffffffc0204218:	04e68a63          	beq	a3,a4,ffffffffc020426c <default_free_pages+0x10c>
}
ffffffffc020421c:	60a2                	ld	ra,8(sp)
ffffffffc020421e:	0141                	addi	sp,sp,16
ffffffffc0204220:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0204222:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204224:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0204226:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204228:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020422a:	02d70763          	beq	a4,a3,ffffffffc0204258 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020422e:	8832                	mv	a6,a2
ffffffffc0204230:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0204232:	87ba                	mv	a5,a4
ffffffffc0204234:	bf71                	j	ffffffffc02041d0 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0204236:	491c                	lw	a5,16(a0)
ffffffffc0204238:	9dbd                	addw	a1,a1,a5
ffffffffc020423a:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020423e:	57f5                	li	a5,-3
ffffffffc0204240:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204244:	01853803          	ld	a6,24(a0)
ffffffffc0204248:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020424a:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc020424c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0204250:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0204252:	0105b023          	sd	a6,0(a1) # 1000 <_binary_obj___user_faultread_out_size-0x9180>
ffffffffc0204256:	b77d                	j	ffffffffc0204204 <default_free_pages+0xa4>
ffffffffc0204258:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc020425a:	873e                	mv	a4,a5
ffffffffc020425c:	bf41                	j	ffffffffc02041ec <default_free_pages+0x8c>
}
ffffffffc020425e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0204260:	e390                	sd	a2,0(a5)
ffffffffc0204262:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204264:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204266:	ed1c                	sd	a5,24(a0)
ffffffffc0204268:	0141                	addi	sp,sp,16
ffffffffc020426a:	8082                	ret
            base->property += p->property;
ffffffffc020426c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204270:	ff078693          	addi	a3,a5,-16
ffffffffc0204274:	9e39                	addw	a2,a2,a4
ffffffffc0204276:	c910                	sw	a2,16(a0)
ffffffffc0204278:	5775                	li	a4,-3
ffffffffc020427a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020427e:	6398                	ld	a4,0(a5)
ffffffffc0204280:	679c                	ld	a5,8(a5)
}
ffffffffc0204282:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0204284:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0204286:	e398                	sd	a4,0(a5)
ffffffffc0204288:	0141                	addi	sp,sp,16
ffffffffc020428a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020428c:	00003697          	auipc	a3,0x3
ffffffffc0204290:	5cc68693          	addi	a3,a3,1484 # ffffffffc0207858 <commands+0x1660>
ffffffffc0204294:	00003617          	auipc	a2,0x3
ffffffffc0204298:	95460613          	addi	a2,a2,-1708 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020429c:	09400593          	li	a1,148
ffffffffc02042a0:	00003517          	auipc	a0,0x3
ffffffffc02042a4:	27050513          	addi	a0,a0,624 # ffffffffc0207510 <commands+0x1318>
ffffffffc02042a8:	f77fb0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(n > 0);
ffffffffc02042ac:	00003697          	auipc	a3,0x3
ffffffffc02042b0:	5a468693          	addi	a3,a3,1444 # ffffffffc0207850 <commands+0x1658>
ffffffffc02042b4:	00003617          	auipc	a2,0x3
ffffffffc02042b8:	93460613          	addi	a2,a2,-1740 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02042bc:	09000593          	li	a1,144
ffffffffc02042c0:	00003517          	auipc	a0,0x3
ffffffffc02042c4:	25050513          	addi	a0,a0,592 # ffffffffc0207510 <commands+0x1318>
ffffffffc02042c8:	f57fb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02042cc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02042cc:	c941                	beqz	a0,ffffffffc020435c <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02042ce:	000be597          	auipc	a1,0xbe
ffffffffc02042d2:	e2258593          	addi	a1,a1,-478 # ffffffffc02c20f0 <free_area>
ffffffffc02042d6:	0105a803          	lw	a6,16(a1)
ffffffffc02042da:	872a                	mv	a4,a0
ffffffffc02042dc:	02081793          	slli	a5,a6,0x20
ffffffffc02042e0:	9381                	srli	a5,a5,0x20
ffffffffc02042e2:	00a7ee63          	bltu	a5,a0,ffffffffc02042fe <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02042e6:	87ae                	mv	a5,a1
ffffffffc02042e8:	a801                	j	ffffffffc02042f8 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02042ea:	ff87a683          	lw	a3,-8(a5)
ffffffffc02042ee:	02069613          	slli	a2,a3,0x20
ffffffffc02042f2:	9201                	srli	a2,a2,0x20
ffffffffc02042f4:	00e67763          	bgeu	a2,a4,ffffffffc0204302 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02042f8:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02042fa:	feb798e3          	bne	a5,a1,ffffffffc02042ea <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02042fe:	4501                	li	a0,0
}
ffffffffc0204300:	8082                	ret
    return listelm->prev;
ffffffffc0204302:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204306:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020430a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020430e:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0204312:	0068b423          	sd	t1,8(a7) # 1008 <_binary_obj___user_faultread_out_size-0x9178>
    next->prev = prev;
ffffffffc0204316:	01133023          	sd	a7,0(t1) # 80000 <_binary_obj___user_exit_out_size+0x74910>
        if (page->property > n)
ffffffffc020431a:	02c77863          	bgeu	a4,a2,ffffffffc020434a <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020431e:	071a                	slli	a4,a4,0x6
ffffffffc0204320:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0204322:	41c686bb          	subw	a3,a3,t3
ffffffffc0204326:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204328:	00870613          	addi	a2,a4,8
ffffffffc020432c:	4689                	li	a3,2
ffffffffc020432e:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204332:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0204336:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020433a:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020433e:	e290                	sd	a2,0(a3)
ffffffffc0204340:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0204344:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0204346:	01173c23          	sd	a7,24(a4)
ffffffffc020434a:	41c8083b          	subw	a6,a6,t3
ffffffffc020434e:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204352:	5775                	li	a4,-3
ffffffffc0204354:	17c1                	addi	a5,a5,-16
ffffffffc0204356:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020435a:	8082                	ret
{
ffffffffc020435c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020435e:	00003697          	auipc	a3,0x3
ffffffffc0204362:	4f268693          	addi	a3,a3,1266 # ffffffffc0207850 <commands+0x1658>
ffffffffc0204366:	00003617          	auipc	a2,0x3
ffffffffc020436a:	88260613          	addi	a2,a2,-1918 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020436e:	06c00593          	li	a1,108
ffffffffc0204372:	00003517          	auipc	a0,0x3
ffffffffc0204376:	19e50513          	addi	a0,a0,414 # ffffffffc0207510 <commands+0x1318>
{
ffffffffc020437a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020437c:	ea3fb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0204380 <default_init_memmap>:
{
ffffffffc0204380:	1141                	addi	sp,sp,-16
ffffffffc0204382:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204384:	c5f1                	beqz	a1,ffffffffc0204450 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0204386:	00659693          	slli	a3,a1,0x6
ffffffffc020438a:	96aa                	add	a3,a3,a0
ffffffffc020438c:	87aa                	mv	a5,a0
ffffffffc020438e:	00d50f63          	beq	a0,a3,ffffffffc02043ac <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0204392:	6798                	ld	a4,8(a5)
ffffffffc0204394:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0204396:	cf49                	beqz	a4,ffffffffc0204430 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0204398:	0007a823          	sw	zero,16(a5)
ffffffffc020439c:	0007b423          	sd	zero,8(a5)
ffffffffc02043a0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02043a4:	04078793          	addi	a5,a5,64
ffffffffc02043a8:	fed795e3          	bne	a5,a3,ffffffffc0204392 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02043ac:	2581                	sext.w	a1,a1
ffffffffc02043ae:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02043b0:	4789                	li	a5,2
ffffffffc02043b2:	00850713          	addi	a4,a0,8
ffffffffc02043b6:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02043ba:	000be697          	auipc	a3,0xbe
ffffffffc02043be:	d3668693          	addi	a3,a3,-714 # ffffffffc02c20f0 <free_area>
ffffffffc02043c2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02043c4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02043c6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02043ca:	9db9                	addw	a1,a1,a4
ffffffffc02043cc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02043ce:	04d78a63          	beq	a5,a3,ffffffffc0204422 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02043d2:	fe878713          	addi	a4,a5,-24
ffffffffc02043d6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02043da:	4581                	li	a1,0
            if (base < page)
ffffffffc02043dc:	00e56a63          	bltu	a0,a4,ffffffffc02043f0 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02043e0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02043e2:	02d70263          	beq	a4,a3,ffffffffc0204406 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02043e6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02043e8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02043ec:	fee57ae3          	bgeu	a0,a4,ffffffffc02043e0 <default_init_memmap+0x60>
ffffffffc02043f0:	c199                	beqz	a1,ffffffffc02043f6 <default_init_memmap+0x76>
ffffffffc02043f2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02043f6:	6398                	ld	a4,0(a5)
}
ffffffffc02043f8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02043fa:	e390                	sd	a2,0(a5)
ffffffffc02043fc:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02043fe:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204400:	ed18                	sd	a4,24(a0)
ffffffffc0204402:	0141                	addi	sp,sp,16
ffffffffc0204404:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0204406:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204408:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020440a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020440c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020440e:	00d70663          	beq	a4,a3,ffffffffc020441a <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0204412:	8832                	mv	a6,a2
ffffffffc0204414:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0204416:	87ba                	mv	a5,a4
ffffffffc0204418:	bfc1                	j	ffffffffc02043e8 <default_init_memmap+0x68>
}
ffffffffc020441a:	60a2                	ld	ra,8(sp)
ffffffffc020441c:	e290                	sd	a2,0(a3)
ffffffffc020441e:	0141                	addi	sp,sp,16
ffffffffc0204420:	8082                	ret
ffffffffc0204422:	60a2                	ld	ra,8(sp)
ffffffffc0204424:	e390                	sd	a2,0(a5)
ffffffffc0204426:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204428:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020442a:	ed1c                	sd	a5,24(a0)
ffffffffc020442c:	0141                	addi	sp,sp,16
ffffffffc020442e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0204430:	00003697          	auipc	a3,0x3
ffffffffc0204434:	45068693          	addi	a3,a3,1104 # ffffffffc0207880 <commands+0x1688>
ffffffffc0204438:	00002617          	auipc	a2,0x2
ffffffffc020443c:	7b060613          	addi	a2,a2,1968 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204440:	04b00593          	li	a1,75
ffffffffc0204444:	00003517          	auipc	a0,0x3
ffffffffc0204448:	0cc50513          	addi	a0,a0,204 # ffffffffc0207510 <commands+0x1318>
ffffffffc020444c:	dd3fb0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(n > 0);
ffffffffc0204450:	00003697          	auipc	a3,0x3
ffffffffc0204454:	40068693          	addi	a3,a3,1024 # ffffffffc0207850 <commands+0x1658>
ffffffffc0204458:	00002617          	auipc	a2,0x2
ffffffffc020445c:	79060613          	addi	a2,a2,1936 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204460:	04700593          	li	a1,71
ffffffffc0204464:	00003517          	auipc	a0,0x3
ffffffffc0204468:	0ac50513          	addi	a0,a0,172 # ffffffffc0207510 <commands+0x1318>
ffffffffc020446c:	db3fb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0204470 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204470:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204472:	9402                	jalr	s0

	jal do_exit
ffffffffc0204474:	6be000ef          	jal	ra,ffffffffc0204b32 <do_exit>

ffffffffc0204478 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204478:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020447c:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204480:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204482:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204484:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204488:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020448c:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204490:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204494:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204498:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020449c:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02044a0:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02044a4:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02044a8:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02044ac:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02044b0:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02044b4:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02044b6:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02044b8:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02044bc:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02044c0:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02044c4:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02044c8:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02044cc:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02044d0:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02044d4:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02044d8:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02044dc:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02044e0:	8082                	ret

ffffffffc02044e2 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02044e2:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02044e4:	10800513          	li	a0,264
{
ffffffffc02044e8:	e022                	sd	s0,0(sp)
ffffffffc02044ea:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02044ec:	b2cff0ef          	jal	ra,ffffffffc0203818 <kmalloc>
ffffffffc02044f0:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02044f2:	c525                	beqz	a0,ffffffffc020455a <alloc_proc+0x78>
    {
        proc->state = PROC_UNINIT;
ffffffffc02044f4:	57fd                	li	a5,-1
ffffffffc02044f6:	1782                	slli	a5,a5,0x20
ffffffffc02044f8:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc02044fa:	07000613          	li	a2,112
ffffffffc02044fe:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0204500:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0204504:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204508:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc020450c:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0204510:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204514:	03050513          	addi	a0,a0,48
ffffffffc0204518:	4d4010ef          	jal	ra,ffffffffc02059ec <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc020451c:	000c2797          	auipc	a5,0xc2
ffffffffc0204520:	c2c7b783          	ld	a5,-980(a5) # ffffffffc02c6148 <boot_pgdir_pa>
ffffffffc0204524:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0204526:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc020452a:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc020452e:	4641                	li	a2,16
ffffffffc0204530:	4581                	li	a1,0
ffffffffc0204532:	0b440513          	addi	a0,s0,180
ffffffffc0204536:	4b6010ef          	jal	ra,ffffffffc02059ec <memset>
        list_init(&(proc->list_link));
ffffffffc020453a:	0c840713          	addi	a4,s0,200
        list_init(&(proc->hash_link));
ffffffffc020453e:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0204542:	e878                	sd	a4,208(s0)
ffffffffc0204544:	e478                	sd	a4,200(s0)
ffffffffc0204546:	f07c                	sd	a5,224(s0)
ffffffffc0204548:	ec7c                	sd	a5,216(s0)
        proc->exit_code = 0;
ffffffffc020454a:	0e043423          	sd	zero,232(s0)
        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc020454e:	0e043823          	sd	zero,240(s0)
ffffffffc0204552:	0e043c23          	sd	zero,248(s0)
ffffffffc0204556:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc020455a:	60a2                	ld	ra,8(sp)
ffffffffc020455c:	8522                	mv	a0,s0
ffffffffc020455e:	6402                	ld	s0,0(sp)
ffffffffc0204560:	0141                	addi	sp,sp,16
ffffffffc0204562:	8082                	ret

ffffffffc0204564 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204564:	000c2797          	auipc	a5,0xc2
ffffffffc0204568:	c1c7b783          	ld	a5,-996(a5) # ffffffffc02c6180 <current>
ffffffffc020456c:	73c8                	ld	a0,160(a5)
ffffffffc020456e:	c15fc06f          	j	ffffffffc0201182 <forkrets>

ffffffffc0204572 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204572:	000c2797          	auipc	a5,0xc2
ffffffffc0204576:	c0e7b783          	ld	a5,-1010(a5) # ffffffffc02c6180 <current>
ffffffffc020457a:	43cc                	lw	a1,4(a5)
{
ffffffffc020457c:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020457e:	00003617          	auipc	a2,0x3
ffffffffc0204582:	36260613          	addi	a2,a2,866 # ffffffffc02078e0 <default_pmm_manager+0x38>
ffffffffc0204586:	00003517          	auipc	a0,0x3
ffffffffc020458a:	36250513          	addi	a0,a0,866 # ffffffffc02078e8 <default_pmm_manager+0x40>
{
ffffffffc020458e:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204590:	b51fb0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0204594:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204598:	16c78793          	addi	a5,a5,364 # a700 <_binary_obj___user_cow_out_size>
ffffffffc020459c:	e43e                	sd	a5,8(sp)
ffffffffc020459e:	00003517          	auipc	a0,0x3
ffffffffc02045a2:	34250513          	addi	a0,a0,834 # ffffffffc02078e0 <default_pmm_manager+0x38>
ffffffffc02045a6:	00032797          	auipc	a5,0x32
ffffffffc02045aa:	4b278793          	addi	a5,a5,1202 # ffffffffc0236a58 <_binary_obj___user_cow_out_start>
ffffffffc02045ae:	f03e                	sd	a5,32(sp)
ffffffffc02045b0:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc02045b2:	e802                	sd	zero,16(sp)
ffffffffc02045b4:	396010ef          	jal	ra,ffffffffc020594a <strlen>
ffffffffc02045b8:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc02045ba:	4511                	li	a0,4
ffffffffc02045bc:	55a2                	lw	a1,40(sp)
ffffffffc02045be:	4662                	lw	a2,24(sp)
ffffffffc02045c0:	5682                	lw	a3,32(sp)
ffffffffc02045c2:	4722                	lw	a4,8(sp)
ffffffffc02045c4:	48a9                	li	a7,10
ffffffffc02045c6:	9002                	ebreak
ffffffffc02045c8:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc02045ca:	65c2                	ld	a1,16(sp)
ffffffffc02045cc:	00003517          	auipc	a0,0x3
ffffffffc02045d0:	34450513          	addi	a0,a0,836 # ffffffffc0207910 <default_pmm_manager+0x68>
ffffffffc02045d4:	b0dfb0ef          	jal	ra,ffffffffc02000e0 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc02045d8:	00003617          	auipc	a2,0x3
ffffffffc02045dc:	34860613          	addi	a2,a2,840 # ffffffffc0207920 <default_pmm_manager+0x78>
ffffffffc02045e0:	37c00593          	li	a1,892
ffffffffc02045e4:	00003517          	auipc	a0,0x3
ffffffffc02045e8:	35c50513          	addi	a0,a0,860 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc02045ec:	c33fb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02045f0 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc02045f0:	6d14                	ld	a3,24(a0)
{
ffffffffc02045f2:	1141                	addi	sp,sp,-16
ffffffffc02045f4:	e406                	sd	ra,8(sp)
ffffffffc02045f6:	c02007b7          	lui	a5,0xc0200
ffffffffc02045fa:	02f6ee63          	bltu	a3,a5,ffffffffc0204636 <put_pgdir+0x46>
ffffffffc02045fe:	000c2517          	auipc	a0,0xc2
ffffffffc0204602:	b7253503          	ld	a0,-1166(a0) # ffffffffc02c6170 <va_pa_offset>
ffffffffc0204606:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0204608:	82b1                	srli	a3,a3,0xc
ffffffffc020460a:	000c2797          	auipc	a5,0xc2
ffffffffc020460e:	b4e7b783          	ld	a5,-1202(a5) # ffffffffc02c6158 <npage>
ffffffffc0204612:	02f6fe63          	bgeu	a3,a5,ffffffffc020464e <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204616:	00004517          	auipc	a0,0x4
ffffffffc020461a:	c1253503          	ld	a0,-1006(a0) # ffffffffc0208228 <nbase>
}
ffffffffc020461e:	60a2                	ld	ra,8(sp)
ffffffffc0204620:	8e89                	sub	a3,a3,a0
ffffffffc0204622:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204624:	000c2517          	auipc	a0,0xc2
ffffffffc0204628:	b3c53503          	ld	a0,-1220(a0) # ffffffffc02c6160 <pages>
ffffffffc020462c:	4585                	li	a1,1
ffffffffc020462e:	9536                	add	a0,a0,a3
}
ffffffffc0204630:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204632:	e53fc06f          	j	ffffffffc0201484 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204636:	00002617          	auipc	a2,0x2
ffffffffc020463a:	65a60613          	addi	a2,a2,1626 # ffffffffc0206c90 <commands+0xa98>
ffffffffc020463e:	07700593          	li	a1,119
ffffffffc0204642:	00002517          	auipc	a0,0x2
ffffffffc0204646:	50650513          	addi	a0,a0,1286 # ffffffffc0206b48 <commands+0x950>
ffffffffc020464a:	bd5fb0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020464e:	00002617          	auipc	a2,0x2
ffffffffc0204652:	4da60613          	addi	a2,a2,1242 # ffffffffc0206b28 <commands+0x930>
ffffffffc0204656:	06900593          	li	a1,105
ffffffffc020465a:	00002517          	auipc	a0,0x2
ffffffffc020465e:	4ee50513          	addi	a0,a0,1262 # ffffffffc0206b48 <commands+0x950>
ffffffffc0204662:	bbdfb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0204666 <proc_run>:
{
ffffffffc0204666:	7179                	addi	sp,sp,-48
ffffffffc0204668:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020466a:	000c2497          	auipc	s1,0xc2
ffffffffc020466e:	b1648493          	addi	s1,s1,-1258 # ffffffffc02c6180 <current>
ffffffffc0204672:	6098                	ld	a4,0(s1)
{
ffffffffc0204674:	f406                	sd	ra,40(sp)
ffffffffc0204676:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204678:	02a70763          	beq	a4,a0,ffffffffc02046a6 <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020467c:	100027f3          	csrr	a5,sstatus
ffffffffc0204680:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204682:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204684:	ef85                	bnez	a5,ffffffffc02046bc <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204686:	755c                	ld	a5,168(a0)
ffffffffc0204688:	56fd                	li	a3,-1
ffffffffc020468a:	16fe                	slli	a3,a3,0x3f
ffffffffc020468c:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc020468e:	e088                	sd	a0,0(s1)
ffffffffc0204690:	8fd5                	or	a5,a5,a3
ffffffffc0204692:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(current->context));
ffffffffc0204696:	03050593          	addi	a1,a0,48
ffffffffc020469a:	03070513          	addi	a0,a4,48
ffffffffc020469e:	ddbff0ef          	jal	ra,ffffffffc0204478 <switch_to>
    if (flag)
ffffffffc02046a2:	00091763          	bnez	s2,ffffffffc02046b0 <proc_run+0x4a>
}
ffffffffc02046a6:	70a2                	ld	ra,40(sp)
ffffffffc02046a8:	7482                	ld	s1,32(sp)
ffffffffc02046aa:	6962                	ld	s2,24(sp)
ffffffffc02046ac:	6145                	addi	sp,sp,48
ffffffffc02046ae:	8082                	ret
ffffffffc02046b0:	70a2                	ld	ra,40(sp)
ffffffffc02046b2:	7482                	ld	s1,32(sp)
ffffffffc02046b4:	6962                	ld	s2,24(sp)
ffffffffc02046b6:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02046b8:	bc6fc06f          	j	ffffffffc0200a7e <intr_enable>
ffffffffc02046bc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02046be:	bc6fc0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
            struct proc_struct *prev = current;
ffffffffc02046c2:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02046c4:	6522                	ld	a0,8(sp)
ffffffffc02046c6:	4905                	li	s2,1
ffffffffc02046c8:	bf7d                	j	ffffffffc0204686 <proc_run+0x20>

ffffffffc02046ca <do_fork>:
{
ffffffffc02046ca:	7119                	addi	sp,sp,-128
ffffffffc02046cc:	f4a6                	sd	s1,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02046ce:	000c2497          	auipc	s1,0xc2
ffffffffc02046d2:	aca48493          	addi	s1,s1,-1334 # ffffffffc02c6198 <nr_process>
ffffffffc02046d6:	4098                	lw	a4,0(s1)
{
ffffffffc02046d8:	fc86                	sd	ra,120(sp)
ffffffffc02046da:	f8a2                	sd	s0,112(sp)
ffffffffc02046dc:	f0ca                	sd	s2,96(sp)
ffffffffc02046de:	ecce                	sd	s3,88(sp)
ffffffffc02046e0:	e8d2                	sd	s4,80(sp)
ffffffffc02046e2:	e4d6                	sd	s5,72(sp)
ffffffffc02046e4:	e0da                	sd	s6,64(sp)
ffffffffc02046e6:	fc5e                	sd	s7,56(sp)
ffffffffc02046e8:	f862                	sd	s8,48(sp)
ffffffffc02046ea:	f466                	sd	s9,40(sp)
ffffffffc02046ec:	f06a                	sd	s10,32(sp)
ffffffffc02046ee:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02046f0:	6785                	lui	a5,0x1
ffffffffc02046f2:	34f75d63          	bge	a4,a5,ffffffffc0204a4c <do_fork+0x382>
ffffffffc02046f6:	8a2a                	mv	s4,a0
ffffffffc02046f8:	89ae                	mv	s3,a1
ffffffffc02046fa:	8932                	mv	s2,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc02046fc:	de7ff0ef          	jal	ra,ffffffffc02044e2 <alloc_proc>
ffffffffc0204700:	842a                	mv	s0,a0
ffffffffc0204702:	34050c63          	beqz	a0,ffffffffc0204a5a <do_fork+0x390>
    proc->parent = current;
ffffffffc0204706:	000c2b97          	auipc	s7,0xc2
ffffffffc020470a:	a7ab8b93          	addi	s7,s7,-1414 # ffffffffc02c6180 <current>
ffffffffc020470e:	000bb783          	ld	a5,0(s7)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204712:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0204714:	f01c                	sd	a5,32(s0)
    current->wait_state = 0;
ffffffffc0204716:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x9094>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020471a:	d2dfc0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
    if (page != NULL)
ffffffffc020471e:	32050563          	beqz	a0,ffffffffc0204a48 <do_fork+0x37e>
    return page - pages + nbase;
ffffffffc0204722:	000c2c97          	auipc	s9,0xc2
ffffffffc0204726:	a3ec8c93          	addi	s9,s9,-1474 # ffffffffc02c6160 <pages>
ffffffffc020472a:	000cb683          	ld	a3,0(s9)
ffffffffc020472e:	00004a97          	auipc	s5,0x4
ffffffffc0204732:	afaa8a93          	addi	s5,s5,-1286 # ffffffffc0208228 <nbase>
ffffffffc0204736:	000ab703          	ld	a4,0(s5)
ffffffffc020473a:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc020473e:	000c2d17          	auipc	s10,0xc2
ffffffffc0204742:	a1ad0d13          	addi	s10,s10,-1510 # ffffffffc02c6158 <npage>
    return page - pages + nbase;
ffffffffc0204746:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204748:	5b7d                	li	s6,-1
ffffffffc020474a:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc020474e:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204750:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0204754:	0166f633          	and	a2,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0204758:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020475a:	30f67763          	bgeu	a2,a5,ffffffffc0204a68 <do_fork+0x39e>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020475e:	000bb603          	ld	a2,0(s7)
ffffffffc0204762:	000c2d97          	auipc	s11,0xc2
ffffffffc0204766:	a0ed8d93          	addi	s11,s11,-1522 # ffffffffc02c6170 <va_pa_offset>
ffffffffc020476a:	000db783          	ld	a5,0(s11)
ffffffffc020476e:	02863b83          	ld	s7,40(a2)
ffffffffc0204772:	e43a                	sd	a4,8(sp)
ffffffffc0204774:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204776:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0204778:	020b8863          	beqz	s7,ffffffffc02047a8 <do_fork+0xde>
    if (clone_flags & CLONE_VM)
ffffffffc020477c:	100a7a13          	andi	s4,s4,256
ffffffffc0204780:	1c0a0063          	beqz	s4,ffffffffc0204940 <do_fork+0x276>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204784:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204788:	018bb783          	ld	a5,24(s7)
ffffffffc020478c:	c02006b7          	lui	a3,0xc0200
ffffffffc0204790:	2705                	addiw	a4,a4,1
ffffffffc0204792:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc0204796:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020479a:	2ed7e363          	bltu	a5,a3,ffffffffc0204a80 <do_fork+0x3b6>
ffffffffc020479e:	000db703          	ld	a4,0(s11)
    uintptr_t kstacktop = proc->kstack + KSTACKSIZE;
ffffffffc02047a2:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02047a4:	8f99                	sub	a5,a5,a4
ffffffffc02047a6:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(kstacktop) - 1;
ffffffffc02047a8:	6709                	lui	a4,0x2
ffffffffc02047aa:	ee070713          	addi	a4,a4,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x82a0>
ffffffffc02047ae:	9736                	add	a4,a4,a3
    *(proc->tf) = *tf;
ffffffffc02047b0:	864a                	mv	a2,s2
    proc->tf = (struct trapframe *)(kstacktop) - 1;
ffffffffc02047b2:	f058                	sd	a4,160(s0)
    *(proc->tf) = *tf;
ffffffffc02047b4:	87ba                	mv	a5,a4
ffffffffc02047b6:	12090313          	addi	t1,s2,288
ffffffffc02047ba:	00063883          	ld	a7,0(a2)
ffffffffc02047be:	00863803          	ld	a6,8(a2)
ffffffffc02047c2:	6a08                	ld	a0,16(a2)
ffffffffc02047c4:	6e0c                	ld	a1,24(a2)
ffffffffc02047c6:	0117b023          	sd	a7,0(a5)
ffffffffc02047ca:	0107b423          	sd	a6,8(a5)
ffffffffc02047ce:	eb88                	sd	a0,16(a5)
ffffffffc02047d0:	ef8c                	sd	a1,24(a5)
ffffffffc02047d2:	02060613          	addi	a2,a2,32
ffffffffc02047d6:	02078793          	addi	a5,a5,32
ffffffffc02047da:	fe6610e3          	bne	a2,t1,ffffffffc02047ba <do_fork+0xf0>
    proc->tf->gpr.a0 = 0;
ffffffffc02047de:	04073823          	sd	zero,80(a4)
    if (esp == 0)
ffffffffc02047e2:	1e098963          	beqz	s3,ffffffffc02049d4 <do_fork+0x30a>
        proc->tf->gpr.sp = esp;
ffffffffc02047e6:	01373823          	sd	s3,16(a4)
    if (debug_forks-- > 0)
ffffffffc02047ea:	000bd697          	auipc	a3,0xbd
ffffffffc02047ee:	4de68693          	addi	a3,a3,1246 # ffffffffc02c1cc8 <debug_forks.2>
ffffffffc02047f2:	429c                	lw	a5,0(a3)
ffffffffc02047f4:	fff7861b          	addiw	a2,a5,-1
ffffffffc02047f8:	c290                	sw	a2,0(a3)
ffffffffc02047fa:	00f05e63          	blez	a5,ffffffffc0204816 <do_fork+0x14c>
        cprintf("copy_thread: future pid? epc=0x%lx sp=0x%lx status=0x%lx\n", proc->tf->epc, proc->tf->gpr.sp, proc->tf->status);
ffffffffc02047fe:	10073683          	ld	a3,256(a4)
ffffffffc0204802:	6b10                	ld	a2,16(a4)
ffffffffc0204804:	10873583          	ld	a1,264(a4)
ffffffffc0204808:	00003517          	auipc	a0,0x3
ffffffffc020480c:	17850513          	addi	a0,a0,376 # ffffffffc0207980 <default_pmm_manager+0xd8>
ffffffffc0204810:	8d1fb0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204814:	7058                	ld	a4,160(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204816:	00000797          	auipc	a5,0x0
ffffffffc020481a:	d4e78793          	addi	a5,a5,-690 # ffffffffc0204564 <forkret>
ffffffffc020481e:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204820:	fc18                	sd	a4,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204822:	100027f3          	csrr	a5,sstatus
ffffffffc0204826:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204828:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020482a:	20079b63          	bnez	a5,ffffffffc0204a40 <do_fork+0x376>
    if (++last_pid >= MAX_PID)
ffffffffc020482e:	000bd817          	auipc	a6,0xbd
ffffffffc0204832:	49e80813          	addi	a6,a6,1182 # ffffffffc02c1ccc <last_pid.1>
ffffffffc0204836:	00082783          	lw	a5,0(a6)
ffffffffc020483a:	6709                	lui	a4,0x2
ffffffffc020483c:	0017851b          	addiw	a0,a5,1
ffffffffc0204840:	00a82023          	sw	a0,0(a6)
ffffffffc0204844:	18e55e63          	bge	a0,a4,ffffffffc02049e0 <do_fork+0x316>
    if (last_pid >= next_safe)
ffffffffc0204848:	000bd317          	auipc	t1,0xbd
ffffffffc020484c:	48830313          	addi	t1,t1,1160 # ffffffffc02c1cd0 <next_safe.0>
ffffffffc0204850:	00032783          	lw	a5,0(t1)
ffffffffc0204854:	000c2917          	auipc	s2,0xc2
ffffffffc0204858:	8b490913          	addi	s2,s2,-1868 # ffffffffc02c6108 <proc_list>
ffffffffc020485c:	06f54063          	blt	a0,a5,ffffffffc02048bc <do_fork+0x1f2>
    return listelm->next;
ffffffffc0204860:	000c2917          	auipc	s2,0xc2
ffffffffc0204864:	8a890913          	addi	s2,s2,-1880 # ffffffffc02c6108 <proc_list>
ffffffffc0204868:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;
ffffffffc020486c:	6789                	lui	a5,0x2
ffffffffc020486e:	00f32023          	sw	a5,0(t1)
ffffffffc0204872:	86aa                	mv	a3,a0
ffffffffc0204874:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204876:	6e89                	lui	t4,0x2
ffffffffc0204878:	1d2e0c63          	beq	t3,s2,ffffffffc0204a50 <do_fork+0x386>
ffffffffc020487c:	88ae                	mv	a7,a1
ffffffffc020487e:	87f2                	mv	a5,t3
ffffffffc0204880:	6609                	lui	a2,0x2
ffffffffc0204882:	a811                	j	ffffffffc0204896 <do_fork+0x1cc>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204884:	00e6d663          	bge	a3,a4,ffffffffc0204890 <do_fork+0x1c6>
ffffffffc0204888:	00c75463          	bge	a4,a2,ffffffffc0204890 <do_fork+0x1c6>
ffffffffc020488c:	863a                	mv	a2,a4
ffffffffc020488e:	4885                	li	a7,1
ffffffffc0204890:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204892:	01278d63          	beq	a5,s2,ffffffffc02048ac <do_fork+0x1e2>
            if (proc->pid == last_pid)
ffffffffc0204896:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x8244>
ffffffffc020489a:	fed715e3          	bne	a4,a3,ffffffffc0204884 <do_fork+0x1ba>
                if (++last_pid >= next_safe)
ffffffffc020489e:	2685                	addiw	a3,a3,1
ffffffffc02048a0:	18c6db63          	bge	a3,a2,ffffffffc0204a36 <do_fork+0x36c>
ffffffffc02048a4:	679c                	ld	a5,8(a5)
ffffffffc02048a6:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02048a8:	ff2797e3          	bne	a5,s2,ffffffffc0204896 <do_fork+0x1cc>
ffffffffc02048ac:	c581                	beqz	a1,ffffffffc02048b4 <do_fork+0x1ea>
ffffffffc02048ae:	00d82023          	sw	a3,0(a6)
ffffffffc02048b2:	8536                	mv	a0,a3
ffffffffc02048b4:	00088463          	beqz	a7,ffffffffc02048bc <do_fork+0x1f2>
ffffffffc02048b8:	00c32023          	sw	a2,0(t1)
        proc->pid = get_pid();
ffffffffc02048bc:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02048be:	45a9                	li	a1,10
ffffffffc02048c0:	2501                	sext.w	a0,a0
ffffffffc02048c2:	542010ef          	jal	ra,ffffffffc0205e04 <hash32>
ffffffffc02048c6:	02051793          	slli	a5,a0,0x20
ffffffffc02048ca:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02048ce:	000be797          	auipc	a5,0xbe
ffffffffc02048d2:	83a78793          	addi	a5,a5,-1990 # ffffffffc02c2108 <hash_list>
ffffffffc02048d6:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02048d8:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02048da:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02048dc:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc02048e0:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02048e2:	00893603          	ld	a2,8(s2)
    prev->next = next->prev = elm;
ffffffffc02048e6:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02048e8:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02048ea:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc02048ee:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc02048f0:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02048f2:	e21c                	sd	a5,0(a2)
ffffffffc02048f4:	00f93423          	sd	a5,8(s2)
    elm->next = next;
ffffffffc02048f8:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02048fa:	0d243423          	sd	s2,200(s0)
    proc->yptr = NULL;
ffffffffc02048fe:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204902:	10e43023          	sd	a4,256(s0)
ffffffffc0204906:	c311                	beqz	a4,ffffffffc020490a <do_fork+0x240>
        proc->optr->yptr = proc;
ffffffffc0204908:	ff60                	sd	s0,248(a4)
    nr_process++;
ffffffffc020490a:	409c                	lw	a5,0(s1)
    proc->parent->cptr = proc;
ffffffffc020490c:	fae0                	sd	s0,240(a3)
    nr_process++;
ffffffffc020490e:	2785                	addiw	a5,a5,1
ffffffffc0204910:	c09c                	sw	a5,0(s1)
    if (flag)
ffffffffc0204912:	0e099063          	bnez	s3,ffffffffc02049f2 <do_fork+0x328>
    wakeup_proc(proc);
ffffffffc0204916:	8522                	mv	a0,s0
ffffffffc0204918:	5f3000ef          	jal	ra,ffffffffc020570a <wakeup_proc>
    ret = proc->pid;
ffffffffc020491c:	00442a03          	lw	s4,4(s0)
}
ffffffffc0204920:	70e6                	ld	ra,120(sp)
ffffffffc0204922:	7446                	ld	s0,112(sp)
ffffffffc0204924:	74a6                	ld	s1,104(sp)
ffffffffc0204926:	7906                	ld	s2,96(sp)
ffffffffc0204928:	69e6                	ld	s3,88(sp)
ffffffffc020492a:	6aa6                	ld	s5,72(sp)
ffffffffc020492c:	6b06                	ld	s6,64(sp)
ffffffffc020492e:	7be2                	ld	s7,56(sp)
ffffffffc0204930:	7c42                	ld	s8,48(sp)
ffffffffc0204932:	7ca2                	ld	s9,40(sp)
ffffffffc0204934:	7d02                	ld	s10,32(sp)
ffffffffc0204936:	6de2                	ld	s11,24(sp)
ffffffffc0204938:	8552                	mv	a0,s4
ffffffffc020493a:	6a46                	ld	s4,80(sp)
ffffffffc020493c:	6109                	addi	sp,sp,128
ffffffffc020493e:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204940:	b70fe0ef          	jal	ra,ffffffffc0202cb0 <mm_create>
ffffffffc0204944:	8c2a                	mv	s8,a0
ffffffffc0204946:	10050f63          	beqz	a0,ffffffffc0204a64 <do_fork+0x39a>
    if ((page = alloc_page()) == NULL)
ffffffffc020494a:	4505                	li	a0,1
ffffffffc020494c:	afbfc0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc0204950:	c545                	beqz	a0,ffffffffc02049f8 <do_fork+0x32e>
    return page - pages + nbase;
ffffffffc0204952:	000cb683          	ld	a3,0(s9)
ffffffffc0204956:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204958:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc020495c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204960:	8699                	srai	a3,a3,0x6
ffffffffc0204962:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204964:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0204968:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020496a:	0efb7f63          	bgeu	s6,a5,ffffffffc0204a68 <do_fork+0x39e>
ffffffffc020496e:	000dba03          	ld	s4,0(s11)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204972:	6605                	lui	a2,0x1
ffffffffc0204974:	000c1597          	auipc	a1,0xc1
ffffffffc0204978:	7dc5b583          	ld	a1,2012(a1) # ffffffffc02c6150 <boot_pgdir_va>
ffffffffc020497c:	9a36                	add	s4,s4,a3
ffffffffc020497e:	8552                	mv	a0,s4
ffffffffc0204980:	07e010ef          	jal	ra,ffffffffc02059fe <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204984:	038b8b13          	addi	s6,s7,56
    mm->pgdir = pgdir;
ffffffffc0204988:	014c3c23          	sd	s4,24(s8)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020498c:	4785                	li	a5,1
ffffffffc020498e:	40fb37af          	amoor.d	a5,a5,(s6)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204992:	8b85                	andi	a5,a5,1
ffffffffc0204994:	4a05                	li	s4,1
ffffffffc0204996:	c799                	beqz	a5,ffffffffc02049a4 <do_fork+0x2da>
    {
        schedule();
ffffffffc0204998:	5f3000ef          	jal	ra,ffffffffc020578a <schedule>
ffffffffc020499c:	414b37af          	amoor.d	a5,s4,(s6)
    while (!try_lock(lock))
ffffffffc02049a0:	8b85                	andi	a5,a5,1
ffffffffc02049a2:	fbfd                	bnez	a5,ffffffffc0204998 <do_fork+0x2ce>
        ret = dup_mmap(mm, oldmm);
ffffffffc02049a4:	85de                	mv	a1,s7
ffffffffc02049a6:	8562                	mv	a0,s8
ffffffffc02049a8:	f42fe0ef          	jal	ra,ffffffffc02030ea <dup_mmap>
ffffffffc02049ac:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02049ae:	57f9                	li	a5,-2
ffffffffc02049b0:	60fb37af          	amoand.d	a5,a5,(s6)
ffffffffc02049b4:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02049b6:	0e078263          	beqz	a5,ffffffffc0204a9a <do_fork+0x3d0>
good_mm:
ffffffffc02049ba:	8be2                	mv	s7,s8
    if (ret != 0)
ffffffffc02049bc:	dc0504e3          	beqz	a0,ffffffffc0204784 <do_fork+0xba>
    exit_mmap(mm);
ffffffffc02049c0:	8562                	mv	a0,s8
ffffffffc02049c2:	fc2fe0ef          	jal	ra,ffffffffc0203184 <exit_mmap>
    put_pgdir(mm);
ffffffffc02049c6:	8562                	mv	a0,s8
ffffffffc02049c8:	c29ff0ef          	jal	ra,ffffffffc02045f0 <put_pgdir>
    mm_destroy(mm);
ffffffffc02049cc:	8562                	mv	a0,s8
ffffffffc02049ce:	e1afe0ef          	jal	ra,ffffffffc0202fe8 <mm_destroy>
ffffffffc02049d2:	a03d                	j	ffffffffc0204a00 <do_fork+0x336>
        proc->tf->gpr.sp = (proc->tf->gpr.sp == 0) ? kstacktop : proc->tf->gpr.sp;
ffffffffc02049d4:	6b1c                	ld	a5,16(a4)
ffffffffc02049d6:	e399                	bnez	a5,ffffffffc02049dc <do_fork+0x312>
    uintptr_t kstacktop = proc->kstack + KSTACKSIZE;
ffffffffc02049d8:	6789                	lui	a5,0x2
ffffffffc02049da:	97b6                	add	a5,a5,a3
        proc->tf->gpr.sp = (proc->tf->gpr.sp == 0) ? kstacktop : proc->tf->gpr.sp;
ffffffffc02049dc:	eb1c                	sd	a5,16(a4)
ffffffffc02049de:	b531                	j	ffffffffc02047ea <do_fork+0x120>
        last_pid = 1;
ffffffffc02049e0:	4785                	li	a5,1
ffffffffc02049e2:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02049e6:	4505                	li	a0,1
ffffffffc02049e8:	000bd317          	auipc	t1,0xbd
ffffffffc02049ec:	2e830313          	addi	t1,t1,744 # ffffffffc02c1cd0 <next_safe.0>
ffffffffc02049f0:	bd85                	j	ffffffffc0204860 <do_fork+0x196>
        intr_enable();
ffffffffc02049f2:	88cfc0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc02049f6:	b705                	j	ffffffffc0204916 <do_fork+0x24c>
    mm_destroy(mm);
ffffffffc02049f8:	8562                	mv	a0,s8
ffffffffc02049fa:	deefe0ef          	jal	ra,ffffffffc0202fe8 <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc02049fe:	5a71                	li	s4,-4
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204a00:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204a02:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a06:	0cf6e263          	bltu	a3,a5,ffffffffc0204aca <do_fork+0x400>
ffffffffc0204a0a:	000db703          	ld	a4,0(s11)
    if (PPN(pa) >= npage)
ffffffffc0204a0e:	000d3783          	ld	a5,0(s10)
    return pa2page(PADDR(kva));
ffffffffc0204a12:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0204a14:	82b1                	srli	a3,a3,0xc
ffffffffc0204a16:	08f6fe63          	bgeu	a3,a5,ffffffffc0204ab2 <do_fork+0x3e8>
    return &pages[PPN(pa) - nbase];
ffffffffc0204a1a:	000ab783          	ld	a5,0(s5)
ffffffffc0204a1e:	000cb503          	ld	a0,0(s9)
ffffffffc0204a22:	4589                	li	a1,2
ffffffffc0204a24:	8e9d                	sub	a3,a3,a5
ffffffffc0204a26:	069a                	slli	a3,a3,0x6
ffffffffc0204a28:	9536                	add	a0,a0,a3
ffffffffc0204a2a:	a5bfc0ef          	jal	ra,ffffffffc0201484 <free_pages>
    kfree(proc);
ffffffffc0204a2e:	8522                	mv	a0,s0
ffffffffc0204a30:	e99fe0ef          	jal	ra,ffffffffc02038c8 <kfree>
    return ret;
ffffffffc0204a34:	b5f5                	j	ffffffffc0204920 <do_fork+0x256>
                    if (last_pid >= MAX_PID)
ffffffffc0204a36:	01d6c363          	blt	a3,t4,ffffffffc0204a3c <do_fork+0x372>
                        last_pid = 1;
ffffffffc0204a3a:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204a3c:	4585                	li	a1,1
ffffffffc0204a3e:	bd2d                	j	ffffffffc0204878 <do_fork+0x1ae>
        intr_disable();
ffffffffc0204a40:	844fc0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        return 1;
ffffffffc0204a44:	4985                	li	s3,1
ffffffffc0204a46:	b3e5                	j	ffffffffc020482e <do_fork+0x164>
    return -E_NO_MEM;
ffffffffc0204a48:	5a71                	li	s4,-4
ffffffffc0204a4a:	b7d5                	j	ffffffffc0204a2e <do_fork+0x364>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204a4c:	5a6d                	li	s4,-5
ffffffffc0204a4e:	bdc9                	j	ffffffffc0204920 <do_fork+0x256>
ffffffffc0204a50:	c599                	beqz	a1,ffffffffc0204a5e <do_fork+0x394>
ffffffffc0204a52:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204a56:	8536                	mv	a0,a3
ffffffffc0204a58:	b595                	j	ffffffffc02048bc <do_fork+0x1f2>
    ret = -E_NO_MEM;
ffffffffc0204a5a:	5a71                	li	s4,-4
ffffffffc0204a5c:	b5d1                	j	ffffffffc0204920 <do_fork+0x256>
    return last_pid;
ffffffffc0204a5e:	00082503          	lw	a0,0(a6)
ffffffffc0204a62:	bda9                	j	ffffffffc02048bc <do_fork+0x1f2>
    int ret = -E_NO_MEM;
ffffffffc0204a64:	5a71                	li	s4,-4
ffffffffc0204a66:	bf69                	j	ffffffffc0204a00 <do_fork+0x336>
    return KADDR(page2pa(page));
ffffffffc0204a68:	00002617          	auipc	a2,0x2
ffffffffc0204a6c:	0f060613          	addi	a2,a2,240 # ffffffffc0206b58 <commands+0x960>
ffffffffc0204a70:	07100593          	li	a1,113
ffffffffc0204a74:	00002517          	auipc	a0,0x2
ffffffffc0204a78:	0d450513          	addi	a0,a0,212 # ffffffffc0206b48 <commands+0x950>
ffffffffc0204a7c:	fa2fb0ef          	jal	ra,ffffffffc020021e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204a80:	86be                	mv	a3,a5
ffffffffc0204a82:	00002617          	auipc	a2,0x2
ffffffffc0204a86:	20e60613          	addi	a2,a2,526 # ffffffffc0206c90 <commands+0xa98>
ffffffffc0204a8a:	16c00593          	li	a1,364
ffffffffc0204a8e:	00003517          	auipc	a0,0x3
ffffffffc0204a92:	eb250513          	addi	a0,a0,-334 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204a96:	f88fb0ef          	jal	ra,ffffffffc020021e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204a9a:	00003617          	auipc	a2,0x3
ffffffffc0204a9e:	ebe60613          	addi	a2,a2,-322 # ffffffffc0207958 <default_pmm_manager+0xb0>
ffffffffc0204aa2:	03f00593          	li	a1,63
ffffffffc0204aa6:	00003517          	auipc	a0,0x3
ffffffffc0204aaa:	ec250513          	addi	a0,a0,-318 # ffffffffc0207968 <default_pmm_manager+0xc0>
ffffffffc0204aae:	f70fb0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204ab2:	00002617          	auipc	a2,0x2
ffffffffc0204ab6:	07660613          	addi	a2,a2,118 # ffffffffc0206b28 <commands+0x930>
ffffffffc0204aba:	06900593          	li	a1,105
ffffffffc0204abe:	00002517          	auipc	a0,0x2
ffffffffc0204ac2:	08a50513          	addi	a0,a0,138 # ffffffffc0206b48 <commands+0x950>
ffffffffc0204ac6:	f58fb0ef          	jal	ra,ffffffffc020021e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204aca:	00002617          	auipc	a2,0x2
ffffffffc0204ace:	1c660613          	addi	a2,a2,454 # ffffffffc0206c90 <commands+0xa98>
ffffffffc0204ad2:	07700593          	li	a1,119
ffffffffc0204ad6:	00002517          	auipc	a0,0x2
ffffffffc0204ada:	07250513          	addi	a0,a0,114 # ffffffffc0206b48 <commands+0x950>
ffffffffc0204ade:	f40fb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0204ae2 <kernel_thread>:
{
ffffffffc0204ae2:	7129                	addi	sp,sp,-320
ffffffffc0204ae4:	fa22                	sd	s0,304(sp)
ffffffffc0204ae6:	f626                	sd	s1,296(sp)
ffffffffc0204ae8:	f24a                	sd	s2,288(sp)
ffffffffc0204aea:	84ae                	mv	s1,a1
ffffffffc0204aec:	892a                	mv	s2,a0
ffffffffc0204aee:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204af0:	4581                	li	a1,0
ffffffffc0204af2:	12000613          	li	a2,288
ffffffffc0204af6:	850a                	mv	a0,sp
{
ffffffffc0204af8:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204afa:	6f3000ef          	jal	ra,ffffffffc02059ec <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204afe:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204b00:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204b02:	100027f3          	csrr	a5,sstatus
ffffffffc0204b06:	edd7f793          	andi	a5,a5,-291
ffffffffc0204b0a:	1207e793          	ori	a5,a5,288
ffffffffc0204b0e:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204b10:	860a                	mv	a2,sp
ffffffffc0204b12:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204b16:	00000797          	auipc	a5,0x0
ffffffffc0204b1a:	95a78793          	addi	a5,a5,-1702 # ffffffffc0204470 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204b1e:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204b20:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204b22:	ba9ff0ef          	jal	ra,ffffffffc02046ca <do_fork>
}
ffffffffc0204b26:	70f2                	ld	ra,312(sp)
ffffffffc0204b28:	7452                	ld	s0,304(sp)
ffffffffc0204b2a:	74b2                	ld	s1,296(sp)
ffffffffc0204b2c:	7912                	ld	s2,288(sp)
ffffffffc0204b2e:	6131                	addi	sp,sp,320
ffffffffc0204b30:	8082                	ret

ffffffffc0204b32 <do_exit>:
{
ffffffffc0204b32:	7179                	addi	sp,sp,-48
ffffffffc0204b34:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204b36:	000c1417          	auipc	s0,0xc1
ffffffffc0204b3a:	64a40413          	addi	s0,s0,1610 # ffffffffc02c6180 <current>
ffffffffc0204b3e:	601c                	ld	a5,0(s0)
{
ffffffffc0204b40:	f406                	sd	ra,40(sp)
ffffffffc0204b42:	ec26                	sd	s1,24(sp)
ffffffffc0204b44:	e84a                	sd	s2,16(sp)
ffffffffc0204b46:	e44e                	sd	s3,8(sp)
ffffffffc0204b48:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204b4a:	000c1717          	auipc	a4,0xc1
ffffffffc0204b4e:	63e73703          	ld	a4,1598(a4) # ffffffffc02c6188 <idleproc>
ffffffffc0204b52:	0ce78c63          	beq	a5,a4,ffffffffc0204c2a <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204b56:	000c1497          	auipc	s1,0xc1
ffffffffc0204b5a:	63a48493          	addi	s1,s1,1594 # ffffffffc02c6190 <initproc>
ffffffffc0204b5e:	6098                	ld	a4,0(s1)
ffffffffc0204b60:	0ee78b63          	beq	a5,a4,ffffffffc0204c56 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204b64:	0287b983          	ld	s3,40(a5)
ffffffffc0204b68:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204b6a:	02098663          	beqz	s3,ffffffffc0204b96 <do_exit+0x64>
ffffffffc0204b6e:	000c1797          	auipc	a5,0xc1
ffffffffc0204b72:	5da7b783          	ld	a5,1498(a5) # ffffffffc02c6148 <boot_pgdir_pa>
ffffffffc0204b76:	577d                	li	a4,-1
ffffffffc0204b78:	177e                	slli	a4,a4,0x3f
ffffffffc0204b7a:	83b1                	srli	a5,a5,0xc
ffffffffc0204b7c:	8fd9                	or	a5,a5,a4
ffffffffc0204b7e:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204b82:	0309a783          	lw	a5,48(s3)
ffffffffc0204b86:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204b8a:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204b8e:	cb55                	beqz	a4,ffffffffc0204c42 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204b90:	601c                	ld	a5,0(s0)
ffffffffc0204b92:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204b96:	601c                	ld	a5,0(s0)
ffffffffc0204b98:	470d                	li	a4,3
ffffffffc0204b9a:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204b9c:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204ba0:	100027f3          	csrr	a5,sstatus
ffffffffc0204ba4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204ba6:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204ba8:	e3f9                	bnez	a5,ffffffffc0204c6e <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204baa:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204bac:	800007b7          	lui	a5,0x80000
ffffffffc0204bb0:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204bb2:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204bb4:	0ec52703          	lw	a4,236(a0)
ffffffffc0204bb8:	0af70f63          	beq	a4,a5,ffffffffc0204c76 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204bbc:	6018                	ld	a4,0(s0)
ffffffffc0204bbe:	7b7c                	ld	a5,240(a4)
ffffffffc0204bc0:	c3a1                	beqz	a5,ffffffffc0204c00 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204bc2:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204bc6:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204bc8:	0985                	addi	s3,s3,1
ffffffffc0204bca:	a021                	j	ffffffffc0204bd2 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204bcc:	6018                	ld	a4,0(s0)
ffffffffc0204bce:	7b7c                	ld	a5,240(a4)
ffffffffc0204bd0:	cb85                	beqz	a5,ffffffffc0204c00 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204bd2:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4a10>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204bd6:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204bd8:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204bda:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204bdc:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204be0:	10e7b023          	sd	a4,256(a5)
ffffffffc0204be4:	c311                	beqz	a4,ffffffffc0204be8 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204be6:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204be8:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204bea:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204bec:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204bee:	fd271fe3          	bne	a4,s2,ffffffffc0204bcc <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204bf2:	0ec52783          	lw	a5,236(a0)
ffffffffc0204bf6:	fd379be3          	bne	a5,s3,ffffffffc0204bcc <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204bfa:	311000ef          	jal	ra,ffffffffc020570a <wakeup_proc>
ffffffffc0204bfe:	b7f9                	j	ffffffffc0204bcc <do_exit+0x9a>
    if (flag)
ffffffffc0204c00:	020a1263          	bnez	s4,ffffffffc0204c24 <do_exit+0xf2>
    schedule();
ffffffffc0204c04:	387000ef          	jal	ra,ffffffffc020578a <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204c08:	601c                	ld	a5,0(s0)
ffffffffc0204c0a:	00003617          	auipc	a2,0x3
ffffffffc0204c0e:	dd660613          	addi	a2,a2,-554 # ffffffffc02079e0 <default_pmm_manager+0x138>
ffffffffc0204c12:	20800593          	li	a1,520
ffffffffc0204c16:	43d4                	lw	a3,4(a5)
ffffffffc0204c18:	00003517          	auipc	a0,0x3
ffffffffc0204c1c:	d2850513          	addi	a0,a0,-728 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204c20:	dfefb0ef          	jal	ra,ffffffffc020021e <__panic>
        intr_enable();
ffffffffc0204c24:	e5bfb0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0204c28:	bff1                	j	ffffffffc0204c04 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204c2a:	00003617          	auipc	a2,0x3
ffffffffc0204c2e:	d9660613          	addi	a2,a2,-618 # ffffffffc02079c0 <default_pmm_manager+0x118>
ffffffffc0204c32:	1d400593          	li	a1,468
ffffffffc0204c36:	00003517          	auipc	a0,0x3
ffffffffc0204c3a:	d0a50513          	addi	a0,a0,-758 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204c3e:	de0fb0ef          	jal	ra,ffffffffc020021e <__panic>
            exit_mmap(mm);
ffffffffc0204c42:	854e                	mv	a0,s3
ffffffffc0204c44:	d40fe0ef          	jal	ra,ffffffffc0203184 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c48:	854e                	mv	a0,s3
ffffffffc0204c4a:	9a7ff0ef          	jal	ra,ffffffffc02045f0 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c4e:	854e                	mv	a0,s3
ffffffffc0204c50:	b98fe0ef          	jal	ra,ffffffffc0202fe8 <mm_destroy>
ffffffffc0204c54:	bf35                	j	ffffffffc0204b90 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204c56:	00003617          	auipc	a2,0x3
ffffffffc0204c5a:	d7a60613          	addi	a2,a2,-646 # ffffffffc02079d0 <default_pmm_manager+0x128>
ffffffffc0204c5e:	1d800593          	li	a1,472
ffffffffc0204c62:	00003517          	auipc	a0,0x3
ffffffffc0204c66:	cde50513          	addi	a0,a0,-802 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204c6a:	db4fb0ef          	jal	ra,ffffffffc020021e <__panic>
        intr_disable();
ffffffffc0204c6e:	e17fb0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        return 1;
ffffffffc0204c72:	4a05                	li	s4,1
ffffffffc0204c74:	bf1d                	j	ffffffffc0204baa <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204c76:	295000ef          	jal	ra,ffffffffc020570a <wakeup_proc>
ffffffffc0204c7a:	b789                	j	ffffffffc0204bbc <do_exit+0x8a>

ffffffffc0204c7c <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204c7c:	715d                	addi	sp,sp,-80
ffffffffc0204c7e:	f84a                	sd	s2,48(sp)
ffffffffc0204c80:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204c82:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204c86:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204c88:	fc26                	sd	s1,56(sp)
ffffffffc0204c8a:	f052                	sd	s4,32(sp)
ffffffffc0204c8c:	ec56                	sd	s5,24(sp)
ffffffffc0204c8e:	e85a                	sd	s6,16(sp)
ffffffffc0204c90:	e45e                	sd	s7,8(sp)
ffffffffc0204c92:	e486                	sd	ra,72(sp)
ffffffffc0204c94:	e0a2                	sd	s0,64(sp)
ffffffffc0204c96:	84aa                	mv	s1,a0
ffffffffc0204c98:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204c9a:	000c1b97          	auipc	s7,0xc1
ffffffffc0204c9e:	4e6b8b93          	addi	s7,s7,1254 # ffffffffc02c6180 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ca2:	00050b1b          	sext.w	s6,a0
ffffffffc0204ca6:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204caa:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204cac:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204cae:	ccbd                	beqz	s1,ffffffffc0204d2c <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204cb0:	0359e863          	bltu	s3,s5,ffffffffc0204ce0 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204cb4:	45a9                	li	a1,10
ffffffffc0204cb6:	855a                	mv	a0,s6
ffffffffc0204cb8:	14c010ef          	jal	ra,ffffffffc0205e04 <hash32>
ffffffffc0204cbc:	02051793          	slli	a5,a0,0x20
ffffffffc0204cc0:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204cc4:	000bd797          	auipc	a5,0xbd
ffffffffc0204cc8:	44478793          	addi	a5,a5,1092 # ffffffffc02c2108 <hash_list>
ffffffffc0204ccc:	953e                	add	a0,a0,a5
ffffffffc0204cce:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204cd0:	a029                	j	ffffffffc0204cda <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204cd2:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204cd6:	02978163          	beq	a5,s1,ffffffffc0204cf8 <do_wait.part.0+0x7c>
    return listelm->next;
ffffffffc0204cda:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204cdc:	fe851be3          	bne	a0,s0,ffffffffc0204cd2 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204ce0:	5579                	li	a0,-2
}
ffffffffc0204ce2:	60a6                	ld	ra,72(sp)
ffffffffc0204ce4:	6406                	ld	s0,64(sp)
ffffffffc0204ce6:	74e2                	ld	s1,56(sp)
ffffffffc0204ce8:	7942                	ld	s2,48(sp)
ffffffffc0204cea:	79a2                	ld	s3,40(sp)
ffffffffc0204cec:	7a02                	ld	s4,32(sp)
ffffffffc0204cee:	6ae2                	ld	s5,24(sp)
ffffffffc0204cf0:	6b42                	ld	s6,16(sp)
ffffffffc0204cf2:	6ba2                	ld	s7,8(sp)
ffffffffc0204cf4:	6161                	addi	sp,sp,80
ffffffffc0204cf6:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204cf8:	000bb683          	ld	a3,0(s7)
ffffffffc0204cfc:	f4843783          	ld	a5,-184(s0)
ffffffffc0204d00:	fed790e3          	bne	a5,a3,ffffffffc0204ce0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204d04:	f2842703          	lw	a4,-216(s0)
ffffffffc0204d08:	478d                	li	a5,3
ffffffffc0204d0a:	0ef70b63          	beq	a4,a5,ffffffffc0204e00 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204d0e:	4785                	li	a5,1
ffffffffc0204d10:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204d12:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204d16:	275000ef          	jal	ra,ffffffffc020578a <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204d1a:	000bb783          	ld	a5,0(s7)
ffffffffc0204d1e:	0b07a783          	lw	a5,176(a5)
ffffffffc0204d22:	8b85                	andi	a5,a5,1
ffffffffc0204d24:	d7c9                	beqz	a5,ffffffffc0204cae <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204d26:	555d                	li	a0,-9
ffffffffc0204d28:	e0bff0ef          	jal	ra,ffffffffc0204b32 <do_exit>
        proc = current->cptr;
ffffffffc0204d2c:	000bb683          	ld	a3,0(s7)
ffffffffc0204d30:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204d32:	d45d                	beqz	s0,ffffffffc0204ce0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204d34:	470d                	li	a4,3
ffffffffc0204d36:	a021                	j	ffffffffc0204d3e <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204d38:	10043403          	ld	s0,256(s0)
ffffffffc0204d3c:	d869                	beqz	s0,ffffffffc0204d0e <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204d3e:	401c                	lw	a5,0(s0)
ffffffffc0204d40:	fee79ce3          	bne	a5,a4,ffffffffc0204d38 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204d44:	000c1797          	auipc	a5,0xc1
ffffffffc0204d48:	4447b783          	ld	a5,1092(a5) # ffffffffc02c6188 <idleproc>
ffffffffc0204d4c:	0c878963          	beq	a5,s0,ffffffffc0204e1e <do_wait.part.0+0x1a2>
ffffffffc0204d50:	000c1797          	auipc	a5,0xc1
ffffffffc0204d54:	4407b783          	ld	a5,1088(a5) # ffffffffc02c6190 <initproc>
ffffffffc0204d58:	0cf40363          	beq	s0,a5,ffffffffc0204e1e <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204d5c:	000a0663          	beqz	s4,ffffffffc0204d68 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204d60:	0e842783          	lw	a5,232(s0)
ffffffffc0204d64:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204d68:	100027f3          	csrr	a5,sstatus
ffffffffc0204d6c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204d6e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204d70:	e7c1                	bnez	a5,ffffffffc0204df8 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204d72:	6c70                	ld	a2,216(s0)
ffffffffc0204d74:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204d76:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204d7a:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204d7c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204d7e:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204d80:	6470                	ld	a2,200(s0)
ffffffffc0204d82:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204d84:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204d86:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204d88:	c319                	beqz	a4,ffffffffc0204d8e <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204d8a:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204d8c:	7c7c                	ld	a5,248(s0)
ffffffffc0204d8e:	c3b5                	beqz	a5,ffffffffc0204df2 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204d90:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204d94:	000c1717          	auipc	a4,0xc1
ffffffffc0204d98:	40470713          	addi	a4,a4,1028 # ffffffffc02c6198 <nr_process>
ffffffffc0204d9c:	431c                	lw	a5,0(a4)
ffffffffc0204d9e:	37fd                	addiw	a5,a5,-1
ffffffffc0204da0:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204da2:	e5a9                	bnez	a1,ffffffffc0204dec <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204da4:	6814                	ld	a3,16(s0)
ffffffffc0204da6:	c02007b7          	lui	a5,0xc0200
ffffffffc0204daa:	04f6ee63          	bltu	a3,a5,ffffffffc0204e06 <do_wait.part.0+0x18a>
ffffffffc0204dae:	000c1797          	auipc	a5,0xc1
ffffffffc0204db2:	3c27b783          	ld	a5,962(a5) # ffffffffc02c6170 <va_pa_offset>
ffffffffc0204db6:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204db8:	82b1                	srli	a3,a3,0xc
ffffffffc0204dba:	000c1797          	auipc	a5,0xc1
ffffffffc0204dbe:	39e7b783          	ld	a5,926(a5) # ffffffffc02c6158 <npage>
ffffffffc0204dc2:	06f6fa63          	bgeu	a3,a5,ffffffffc0204e36 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204dc6:	00003517          	auipc	a0,0x3
ffffffffc0204dca:	46253503          	ld	a0,1122(a0) # ffffffffc0208228 <nbase>
ffffffffc0204dce:	8e89                	sub	a3,a3,a0
ffffffffc0204dd0:	069a                	slli	a3,a3,0x6
ffffffffc0204dd2:	000c1517          	auipc	a0,0xc1
ffffffffc0204dd6:	38e53503          	ld	a0,910(a0) # ffffffffc02c6160 <pages>
ffffffffc0204dda:	9536                	add	a0,a0,a3
ffffffffc0204ddc:	4589                	li	a1,2
ffffffffc0204dde:	ea6fc0ef          	jal	ra,ffffffffc0201484 <free_pages>
    kfree(proc);
ffffffffc0204de2:	8522                	mv	a0,s0
ffffffffc0204de4:	ae5fe0ef          	jal	ra,ffffffffc02038c8 <kfree>
    return 0;
ffffffffc0204de8:	4501                	li	a0,0
ffffffffc0204dea:	bde5                	j	ffffffffc0204ce2 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204dec:	c93fb0ef          	jal	ra,ffffffffc0200a7e <intr_enable>
ffffffffc0204df0:	bf55                	j	ffffffffc0204da4 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204df2:	701c                	ld	a5,32(s0)
ffffffffc0204df4:	fbf8                	sd	a4,240(a5)
ffffffffc0204df6:	bf79                	j	ffffffffc0204d94 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204df8:	c8dfb0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        return 1;
ffffffffc0204dfc:	4585                	li	a1,1
ffffffffc0204dfe:	bf95                	j	ffffffffc0204d72 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204e00:	f2840413          	addi	s0,s0,-216
ffffffffc0204e04:	b781                	j	ffffffffc0204d44 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204e06:	00002617          	auipc	a2,0x2
ffffffffc0204e0a:	e8a60613          	addi	a2,a2,-374 # ffffffffc0206c90 <commands+0xa98>
ffffffffc0204e0e:	07700593          	li	a1,119
ffffffffc0204e12:	00002517          	auipc	a0,0x2
ffffffffc0204e16:	d3650513          	addi	a0,a0,-714 # ffffffffc0206b48 <commands+0x950>
ffffffffc0204e1a:	c04fb0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204e1e:	00003617          	auipc	a2,0x3
ffffffffc0204e22:	be260613          	addi	a2,a2,-1054 # ffffffffc0207a00 <default_pmm_manager+0x158>
ffffffffc0204e26:	32400593          	li	a1,804
ffffffffc0204e2a:	00003517          	auipc	a0,0x3
ffffffffc0204e2e:	b1650513          	addi	a0,a0,-1258 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204e32:	becfb0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204e36:	00002617          	auipc	a2,0x2
ffffffffc0204e3a:	cf260613          	addi	a2,a2,-782 # ffffffffc0206b28 <commands+0x930>
ffffffffc0204e3e:	06900593          	li	a1,105
ffffffffc0204e42:	00002517          	auipc	a0,0x2
ffffffffc0204e46:	d0650513          	addi	a0,a0,-762 # ffffffffc0206b48 <commands+0x950>
ffffffffc0204e4a:	bd4fb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0204e4e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204e4e:	1141                	addi	sp,sp,-16
ffffffffc0204e50:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204e52:	e72fc0ef          	jal	ra,ffffffffc02014c4 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204e56:	9bffe0ef          	jal	ra,ffffffffc0203814 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204e5a:	4601                	li	a2,0
ffffffffc0204e5c:	4581                	li	a1,0
ffffffffc0204e5e:	fffff517          	auipc	a0,0xfffff
ffffffffc0204e62:	71450513          	addi	a0,a0,1812 # ffffffffc0204572 <user_main>
ffffffffc0204e66:	c7dff0ef          	jal	ra,ffffffffc0204ae2 <kernel_thread>
    if (pid <= 0)
ffffffffc0204e6a:	00a04563          	bgtz	a0,ffffffffc0204e74 <init_main+0x26>
ffffffffc0204e6e:	a071                	j	ffffffffc0204efa <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204e70:	11b000ef          	jal	ra,ffffffffc020578a <schedule>
    if (code_store != NULL)
ffffffffc0204e74:	4581                	li	a1,0
ffffffffc0204e76:	4501                	li	a0,0
ffffffffc0204e78:	e05ff0ef          	jal	ra,ffffffffc0204c7c <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204e7c:	d975                	beqz	a0,ffffffffc0204e70 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204e7e:	00003517          	auipc	a0,0x3
ffffffffc0204e82:	bc250513          	addi	a0,a0,-1086 # ffffffffc0207a40 <default_pmm_manager+0x198>
ffffffffc0204e86:	a5afb0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204e8a:	000c1797          	auipc	a5,0xc1
ffffffffc0204e8e:	3067b783          	ld	a5,774(a5) # ffffffffc02c6190 <initproc>
ffffffffc0204e92:	7bf8                	ld	a4,240(a5)
ffffffffc0204e94:	e339                	bnez	a4,ffffffffc0204eda <init_main+0x8c>
ffffffffc0204e96:	7ff8                	ld	a4,248(a5)
ffffffffc0204e98:	e329                	bnez	a4,ffffffffc0204eda <init_main+0x8c>
ffffffffc0204e9a:	1007b703          	ld	a4,256(a5)
ffffffffc0204e9e:	ef15                	bnez	a4,ffffffffc0204eda <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204ea0:	000c1697          	auipc	a3,0xc1
ffffffffc0204ea4:	2f86a683          	lw	a3,760(a3) # ffffffffc02c6198 <nr_process>
ffffffffc0204ea8:	4709                	li	a4,2
ffffffffc0204eaa:	0ae69463          	bne	a3,a4,ffffffffc0204f52 <init_main+0x104>
    return listelm->next;
ffffffffc0204eae:	000c1697          	auipc	a3,0xc1
ffffffffc0204eb2:	25a68693          	addi	a3,a3,602 # ffffffffc02c6108 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204eb6:	6698                	ld	a4,8(a3)
ffffffffc0204eb8:	0c878793          	addi	a5,a5,200
ffffffffc0204ebc:	06f71b63          	bne	a4,a5,ffffffffc0204f32 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204ec0:	629c                	ld	a5,0(a3)
ffffffffc0204ec2:	04f71863          	bne	a4,a5,ffffffffc0204f12 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204ec6:	00003517          	auipc	a0,0x3
ffffffffc0204eca:	c6250513          	addi	a0,a0,-926 # ffffffffc0207b28 <default_pmm_manager+0x280>
ffffffffc0204ece:	a12fb0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
}
ffffffffc0204ed2:	60a2                	ld	ra,8(sp)
ffffffffc0204ed4:	4501                	li	a0,0
ffffffffc0204ed6:	0141                	addi	sp,sp,16
ffffffffc0204ed8:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204eda:	00003697          	auipc	a3,0x3
ffffffffc0204ede:	b8e68693          	addi	a3,a3,-1138 # ffffffffc0207a68 <default_pmm_manager+0x1c0>
ffffffffc0204ee2:	00002617          	auipc	a2,0x2
ffffffffc0204ee6:	d0660613          	addi	a2,a2,-762 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204eea:	39200593          	li	a1,914
ffffffffc0204eee:	00003517          	auipc	a0,0x3
ffffffffc0204ef2:	a5250513          	addi	a0,a0,-1454 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204ef6:	b28fb0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204efa:	00003617          	auipc	a2,0x3
ffffffffc0204efe:	b2660613          	addi	a2,a2,-1242 # ffffffffc0207a20 <default_pmm_manager+0x178>
ffffffffc0204f02:	38900593          	li	a1,905
ffffffffc0204f06:	00003517          	auipc	a0,0x3
ffffffffc0204f0a:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204f0e:	b10fb0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204f12:	00003697          	auipc	a3,0x3
ffffffffc0204f16:	be668693          	addi	a3,a3,-1050 # ffffffffc0207af8 <default_pmm_manager+0x250>
ffffffffc0204f1a:	00002617          	auipc	a2,0x2
ffffffffc0204f1e:	cce60613          	addi	a2,a2,-818 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204f22:	39500593          	li	a1,917
ffffffffc0204f26:	00003517          	auipc	a0,0x3
ffffffffc0204f2a:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204f2e:	af0fb0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204f32:	00003697          	auipc	a3,0x3
ffffffffc0204f36:	b9668693          	addi	a3,a3,-1130 # ffffffffc0207ac8 <default_pmm_manager+0x220>
ffffffffc0204f3a:	00002617          	auipc	a2,0x2
ffffffffc0204f3e:	cae60613          	addi	a2,a2,-850 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204f42:	39400593          	li	a1,916
ffffffffc0204f46:	00003517          	auipc	a0,0x3
ffffffffc0204f4a:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204f4e:	ad0fb0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(nr_process == 2);
ffffffffc0204f52:	00003697          	auipc	a3,0x3
ffffffffc0204f56:	b6668693          	addi	a3,a3,-1178 # ffffffffc0207ab8 <default_pmm_manager+0x210>
ffffffffc0204f5a:	00002617          	auipc	a2,0x2
ffffffffc0204f5e:	c8e60613          	addi	a2,a2,-882 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc0204f62:	39300593          	li	a1,915
ffffffffc0204f66:	00003517          	auipc	a0,0x3
ffffffffc0204f6a:	9da50513          	addi	a0,a0,-1574 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0204f6e:	ab0fb0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc0204f72 <do_execve>:
{
ffffffffc0204f72:	7171                	addi	sp,sp,-176
ffffffffc0204f74:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204f76:	000c1d97          	auipc	s11,0xc1
ffffffffc0204f7a:	20ad8d93          	addi	s11,s11,522 # ffffffffc02c6180 <current>
ffffffffc0204f7e:	000db783          	ld	a5,0(s11)
{
ffffffffc0204f82:	e54e                	sd	s3,136(sp)
ffffffffc0204f84:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204f86:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204f8a:	e94a                	sd	s2,144(sp)
ffffffffc0204f8c:	f4de                	sd	s7,104(sp)
ffffffffc0204f8e:	892a                	mv	s2,a0
ffffffffc0204f90:	8bb2                	mv	s7,a2
ffffffffc0204f92:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204f94:	862e                	mv	a2,a1
ffffffffc0204f96:	4681                	li	a3,0
ffffffffc0204f98:	85aa                	mv	a1,a0
ffffffffc0204f9a:	854e                	mv	a0,s3
{
ffffffffc0204f9c:	f506                	sd	ra,168(sp)
ffffffffc0204f9e:	f122                	sd	s0,160(sp)
ffffffffc0204fa0:	e152                	sd	s4,128(sp)
ffffffffc0204fa2:	fcd6                	sd	s5,120(sp)
ffffffffc0204fa4:	f8da                	sd	s6,112(sp)
ffffffffc0204fa6:	f0e2                	sd	s8,96(sp)
ffffffffc0204fa8:	ece6                	sd	s9,88(sp)
ffffffffc0204faa:	e8ea                	sd	s10,80(sp)
ffffffffc0204fac:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204fae:	d70fe0ef          	jal	ra,ffffffffc020351e <user_mem_check>
ffffffffc0204fb2:	40050e63          	beqz	a0,ffffffffc02053ce <do_execve+0x45c>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204fb6:	4641                	li	a2,16
ffffffffc0204fb8:	4581                	li	a1,0
ffffffffc0204fba:	1808                	addi	a0,sp,48
ffffffffc0204fbc:	231000ef          	jal	ra,ffffffffc02059ec <memset>
    memcpy(local_name, name, len);
ffffffffc0204fc0:	47bd                	li	a5,15
ffffffffc0204fc2:	8626                	mv	a2,s1
ffffffffc0204fc4:	1e97e663          	bltu	a5,s1,ffffffffc02051b0 <do_execve+0x23e>
ffffffffc0204fc8:	85ca                	mv	a1,s2
ffffffffc0204fca:	1808                	addi	a0,sp,48
ffffffffc0204fcc:	233000ef          	jal	ra,ffffffffc02059fe <memcpy>
    if (mm != NULL)
ffffffffc0204fd0:	1e098763          	beqz	s3,ffffffffc02051be <do_execve+0x24c>
        cputs("mm != NULL");
ffffffffc0204fd4:	00002517          	auipc	a0,0x2
ffffffffc0204fd8:	2e450513          	addi	a0,a0,740 # ffffffffc02072b8 <commands+0x10c0>
ffffffffc0204fdc:	93efb0ef          	jal	ra,ffffffffc020011a <cputs>
ffffffffc0204fe0:	000c1797          	auipc	a5,0xc1
ffffffffc0204fe4:	1687b783          	ld	a5,360(a5) # ffffffffc02c6148 <boot_pgdir_pa>
ffffffffc0204fe8:	577d                	li	a4,-1
ffffffffc0204fea:	177e                	slli	a4,a4,0x3f
ffffffffc0204fec:	83b1                	srli	a5,a5,0xc
ffffffffc0204fee:	8fd9                	or	a5,a5,a4
ffffffffc0204ff0:	18079073          	csrw	satp,a5
ffffffffc0204ff4:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x8150>
ffffffffc0204ff8:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204ffc:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0205000:	2c070863          	beqz	a4,ffffffffc02052d0 <do_execve+0x35e>
        current->mm = NULL;
ffffffffc0205004:	000db783          	ld	a5,0(s11)
ffffffffc0205008:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc020500c:	ca5fd0ef          	jal	ra,ffffffffc0202cb0 <mm_create>
ffffffffc0205010:	84aa                	mv	s1,a0
ffffffffc0205012:	1e050163          	beqz	a0,ffffffffc02051f4 <do_execve+0x282>
    if ((page = alloc_page()) == NULL)
ffffffffc0205016:	4505                	li	a0,1
ffffffffc0205018:	c2efc0ef          	jal	ra,ffffffffc0201446 <alloc_pages>
ffffffffc020501c:	3a050d63          	beqz	a0,ffffffffc02053d6 <do_execve+0x464>
    return page - pages + nbase;
ffffffffc0205020:	000c1c97          	auipc	s9,0xc1
ffffffffc0205024:	140c8c93          	addi	s9,s9,320 # ffffffffc02c6160 <pages>
ffffffffc0205028:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc020502c:	000c1c17          	auipc	s8,0xc1
ffffffffc0205030:	12cc0c13          	addi	s8,s8,300 # ffffffffc02c6158 <npage>
    return page - pages + nbase;
ffffffffc0205034:	00003717          	auipc	a4,0x3
ffffffffc0205038:	1f473703          	ld	a4,500(a4) # ffffffffc0208228 <nbase>
ffffffffc020503c:	40d506b3          	sub	a3,a0,a3
ffffffffc0205040:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205042:	5afd                	li	s5,-1
ffffffffc0205044:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0205048:	96ba                	add	a3,a3,a4
ffffffffc020504a:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc020504c:	00cad713          	srli	a4,s5,0xc
ffffffffc0205050:	ec3a                	sd	a4,24(sp)
ffffffffc0205052:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205054:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205056:	38f77463          	bgeu	a4,a5,ffffffffc02053de <do_execve+0x46c>
ffffffffc020505a:	000c1b17          	auipc	s6,0xc1
ffffffffc020505e:	116b0b13          	addi	s6,s6,278 # ffffffffc02c6170 <va_pa_offset>
ffffffffc0205062:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0205066:	6605                	lui	a2,0x1
ffffffffc0205068:	000c1597          	auipc	a1,0xc1
ffffffffc020506c:	0e85b583          	ld	a1,232(a1) # ffffffffc02c6150 <boot_pgdir_va>
ffffffffc0205070:	9936                	add	s2,s2,a3
ffffffffc0205072:	854a                	mv	a0,s2
ffffffffc0205074:	18b000ef          	jal	ra,ffffffffc02059fe <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0205078:	7782                	ld	a5,32(sp)
ffffffffc020507a:	4398                	lw	a4,0(a5)
ffffffffc020507c:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0205080:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0205084:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b8e8f>
ffffffffc0205088:	14f71c63          	bne	a4,a5,ffffffffc02051e0 <do_execve+0x26e>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020508c:	7682                	ld	a3,32(sp)
ffffffffc020508e:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205092:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205096:	00371793          	slli	a5,a4,0x3
ffffffffc020509a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020509c:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020509e:	078e                	slli	a5,a5,0x3
ffffffffc02050a0:	97ce                	add	a5,a5,s3
ffffffffc02050a2:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02050a4:	00f9fc63          	bgeu	s3,a5,ffffffffc02050bc <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02050a8:	0009a783          	lw	a5,0(s3)
ffffffffc02050ac:	4705                	li	a4,1
ffffffffc02050ae:	14e78563          	beq	a5,a4,ffffffffc02051f8 <do_execve+0x286>
    for (; ph < ph_end; ph++)
ffffffffc02050b2:	77a2                	ld	a5,40(sp)
ffffffffc02050b4:	03898993          	addi	s3,s3,56
ffffffffc02050b8:	fef9e8e3          	bltu	s3,a5,ffffffffc02050a8 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02050bc:	4701                	li	a4,0
ffffffffc02050be:	46ad                	li	a3,11
ffffffffc02050c0:	00100637          	lui	a2,0x100
ffffffffc02050c4:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02050c8:	8526                	mv	a0,s1
ffffffffc02050ca:	f71fd0ef          	jal	ra,ffffffffc020303a <mm_map>
ffffffffc02050ce:	8a2a                	mv	s4,a0
ffffffffc02050d0:	1e051663          	bnez	a0,ffffffffc02052bc <do_execve+0x34a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02050d4:	6c88                	ld	a0,24(s1)
ffffffffc02050d6:	467d                	li	a2,31
ffffffffc02050d8:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02050dc:	aeffd0ef          	jal	ra,ffffffffc0202bca <pgdir_alloc_page>
ffffffffc02050e0:	38050763          	beqz	a0,ffffffffc020546e <do_execve+0x4fc>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02050e4:	6c88                	ld	a0,24(s1)
ffffffffc02050e6:	467d                	li	a2,31
ffffffffc02050e8:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02050ec:	adffd0ef          	jal	ra,ffffffffc0202bca <pgdir_alloc_page>
ffffffffc02050f0:	34050f63          	beqz	a0,ffffffffc020544e <do_execve+0x4dc>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02050f4:	6c88                	ld	a0,24(s1)
ffffffffc02050f6:	467d                	li	a2,31
ffffffffc02050f8:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02050fc:	acffd0ef          	jal	ra,ffffffffc0202bca <pgdir_alloc_page>
ffffffffc0205100:	32050763          	beqz	a0,ffffffffc020542e <do_execve+0x4bc>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205104:	6c88                	ld	a0,24(s1)
ffffffffc0205106:	467d                	li	a2,31
ffffffffc0205108:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc020510c:	abffd0ef          	jal	ra,ffffffffc0202bca <pgdir_alloc_page>
ffffffffc0205110:	2e050f63          	beqz	a0,ffffffffc020540e <do_execve+0x49c>
    mm->mm_count += 1;
ffffffffc0205114:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0205116:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020511a:	6c94                	ld	a3,24(s1)
ffffffffc020511c:	2785                	addiw	a5,a5,1
ffffffffc020511e:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0205120:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0205122:	c02007b7          	lui	a5,0xc0200
ffffffffc0205126:	2cf6e863          	bltu	a3,a5,ffffffffc02053f6 <do_execve+0x484>
ffffffffc020512a:	000b3783          	ld	a5,0(s6)
ffffffffc020512e:	577d                	li	a4,-1
ffffffffc0205130:	177e                	slli	a4,a4,0x3f
ffffffffc0205132:	8e9d                	sub	a3,a3,a5
ffffffffc0205134:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205138:	f654                	sd	a3,168(a2)
ffffffffc020513a:	8fd9                	or	a5,a5,a4
ffffffffc020513c:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205140:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205142:	4581                	li	a1,0
ffffffffc0205144:	12000613          	li	a2,288
ffffffffc0205148:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc020514a:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020514e:	09f000ef          	jal	ra,ffffffffc02059ec <memset>
    tf->epc = elf->e_entry;
ffffffffc0205152:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205154:	000db903          	ld	s2,0(s11)
    tf->status &= ~SSTATUS_SIE;
ffffffffc0205158:	edd4f493          	andi	s1,s1,-291
    tf->epc = elf->e_entry;
ffffffffc020515c:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc020515e:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205160:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff49c4>
    tf->gpr.sp = USTACKTOP;
ffffffffc0205164:	07fe                	slli	a5,a5,0x1f
    tf->status &= ~SSTATUS_SIE;
ffffffffc0205166:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020516a:	4641                	li	a2,16
ffffffffc020516c:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc020516e:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205170:	10e43423          	sd	a4,264(s0)
    tf->status &= ~SSTATUS_SIE;
ffffffffc0205174:	10943023          	sd	s1,256(s0)
    tf->gpr.a0 = 0;
ffffffffc0205178:	04043823          	sd	zero,80(s0)
    tf->gpr.a1 = 0;
ffffffffc020517c:	04043c23          	sd	zero,88(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205180:	854a                	mv	a0,s2
ffffffffc0205182:	06b000ef          	jal	ra,ffffffffc02059ec <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205186:	463d                	li	a2,15
ffffffffc0205188:	180c                	addi	a1,sp,48
ffffffffc020518a:	854a                	mv	a0,s2
ffffffffc020518c:	073000ef          	jal	ra,ffffffffc02059fe <memcpy>
}
ffffffffc0205190:	70aa                	ld	ra,168(sp)
ffffffffc0205192:	740a                	ld	s0,160(sp)
ffffffffc0205194:	64ea                	ld	s1,152(sp)
ffffffffc0205196:	694a                	ld	s2,144(sp)
ffffffffc0205198:	69aa                	ld	s3,136(sp)
ffffffffc020519a:	7ae6                	ld	s5,120(sp)
ffffffffc020519c:	7b46                	ld	s6,112(sp)
ffffffffc020519e:	7ba6                	ld	s7,104(sp)
ffffffffc02051a0:	7c06                	ld	s8,96(sp)
ffffffffc02051a2:	6ce6                	ld	s9,88(sp)
ffffffffc02051a4:	6d46                	ld	s10,80(sp)
ffffffffc02051a6:	6da6                	ld	s11,72(sp)
ffffffffc02051a8:	8552                	mv	a0,s4
ffffffffc02051aa:	6a0a                	ld	s4,128(sp)
ffffffffc02051ac:	614d                	addi	sp,sp,176
ffffffffc02051ae:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc02051b0:	463d                	li	a2,15
ffffffffc02051b2:	85ca                	mv	a1,s2
ffffffffc02051b4:	1808                	addi	a0,sp,48
ffffffffc02051b6:	049000ef          	jal	ra,ffffffffc02059fe <memcpy>
    if (mm != NULL)
ffffffffc02051ba:	e0099de3          	bnez	s3,ffffffffc0204fd4 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc02051be:	000db783          	ld	a5,0(s11)
ffffffffc02051c2:	779c                	ld	a5,40(a5)
ffffffffc02051c4:	e40784e3          	beqz	a5,ffffffffc020500c <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02051c8:	00003617          	auipc	a2,0x3
ffffffffc02051cc:	98060613          	addi	a2,a2,-1664 # ffffffffc0207b48 <default_pmm_manager+0x2a0>
ffffffffc02051d0:	21400593          	li	a1,532
ffffffffc02051d4:	00002517          	auipc	a0,0x2
ffffffffc02051d8:	76c50513          	addi	a0,a0,1900 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc02051dc:	842fb0ef          	jal	ra,ffffffffc020021e <__panic>
    put_pgdir(mm);
ffffffffc02051e0:	8526                	mv	a0,s1
ffffffffc02051e2:	c0eff0ef          	jal	ra,ffffffffc02045f0 <put_pgdir>
    mm_destroy(mm);
ffffffffc02051e6:	8526                	mv	a0,s1
ffffffffc02051e8:	e01fd0ef          	jal	ra,ffffffffc0202fe8 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02051ec:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc02051ee:	8552                	mv	a0,s4
ffffffffc02051f0:	943ff0ef          	jal	ra,ffffffffc0204b32 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc02051f4:	5a71                	li	s4,-4
ffffffffc02051f6:	bfe5                	j	ffffffffc02051ee <do_execve+0x27c>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc02051f8:	0289b603          	ld	a2,40(s3)
ffffffffc02051fc:	0209b783          	ld	a5,32(s3)
ffffffffc0205200:	1cf66d63          	bltu	a2,a5,ffffffffc02053da <do_execve+0x468>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0205204:	0049a783          	lw	a5,4(s3)
ffffffffc0205208:	0017f693          	andi	a3,a5,1
ffffffffc020520c:	c291                	beqz	a3,ffffffffc0205210 <do_execve+0x29e>
            vm_flags |= VM_EXEC;
ffffffffc020520e:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205210:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205214:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205216:	e779                	bnez	a4,ffffffffc02052e4 <do_execve+0x372>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205218:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc020521a:	c781                	beqz	a5,ffffffffc0205222 <do_execve+0x2b0>
            vm_flags |= VM_READ;
ffffffffc020521c:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0205220:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0205222:	0026f793          	andi	a5,a3,2
ffffffffc0205226:	e3f1                	bnez	a5,ffffffffc02052ea <do_execve+0x378>
        if (vm_flags & VM_EXEC)
ffffffffc0205228:	0046f793          	andi	a5,a3,4
ffffffffc020522c:	c399                	beqz	a5,ffffffffc0205232 <do_execve+0x2c0>
            perm |= PTE_X;
ffffffffc020522e:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0205232:	0109b583          	ld	a1,16(s3)
ffffffffc0205236:	4701                	li	a4,0
ffffffffc0205238:	8526                	mv	a0,s1
ffffffffc020523a:	e01fd0ef          	jal	ra,ffffffffc020303a <mm_map>
ffffffffc020523e:	8a2a                	mv	s4,a0
ffffffffc0205240:	ed35                	bnez	a0,ffffffffc02052bc <do_execve+0x34a>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205242:	0109bb83          	ld	s7,16(s3)
ffffffffc0205246:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205248:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc020524c:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205250:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205254:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205256:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205258:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc020525a:	054be963          	bltu	s7,s4,ffffffffc02052ac <do_execve+0x33a>
ffffffffc020525e:	aa95                	j	ffffffffc02053d2 <do_execve+0x460>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205260:	6785                	lui	a5,0x1
ffffffffc0205262:	415b8533          	sub	a0,s7,s5
ffffffffc0205266:	9abe                	add	s5,s5,a5
ffffffffc0205268:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc020526c:	015a7463          	bgeu	s4,s5,ffffffffc0205274 <do_execve+0x302>
                size -= la - end;
ffffffffc0205270:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0205274:	000cb683          	ld	a3,0(s9)
ffffffffc0205278:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020527a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc020527e:	40d406b3          	sub	a3,s0,a3
ffffffffc0205282:	8699                	srai	a3,a3,0x6
ffffffffc0205284:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205286:	67e2                	ld	a5,24(sp)
ffffffffc0205288:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020528c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020528e:	14b87863          	bgeu	a6,a1,ffffffffc02053de <do_execve+0x46c>
ffffffffc0205292:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205296:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0205298:	9bb2                	add	s7,s7,a2
ffffffffc020529a:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc020529c:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc020529e:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02052a0:	75e000ef          	jal	ra,ffffffffc02059fe <memcpy>
            start += size, from += size;
ffffffffc02052a4:	6622                	ld	a2,8(sp)
ffffffffc02052a6:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc02052a8:	054bf363          	bgeu	s7,s4,ffffffffc02052ee <do_execve+0x37c>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc02052ac:	6c88                	ld	a0,24(s1)
ffffffffc02052ae:	866a                	mv	a2,s10
ffffffffc02052b0:	85d6                	mv	a1,s5
ffffffffc02052b2:	919fd0ef          	jal	ra,ffffffffc0202bca <pgdir_alloc_page>
ffffffffc02052b6:	842a                	mv	s0,a0
ffffffffc02052b8:	f545                	bnez	a0,ffffffffc0205260 <do_execve+0x2ee>
        ret = -E_NO_MEM;
ffffffffc02052ba:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc02052bc:	8526                	mv	a0,s1
ffffffffc02052be:	ec7fd0ef          	jal	ra,ffffffffc0203184 <exit_mmap>
    put_pgdir(mm);
ffffffffc02052c2:	8526                	mv	a0,s1
ffffffffc02052c4:	b2cff0ef          	jal	ra,ffffffffc02045f0 <put_pgdir>
    mm_destroy(mm);
ffffffffc02052c8:	8526                	mv	a0,s1
ffffffffc02052ca:	d1ffd0ef          	jal	ra,ffffffffc0202fe8 <mm_destroy>
    return ret;
ffffffffc02052ce:	b705                	j	ffffffffc02051ee <do_execve+0x27c>
            exit_mmap(mm);
ffffffffc02052d0:	854e                	mv	a0,s3
ffffffffc02052d2:	eb3fd0ef          	jal	ra,ffffffffc0203184 <exit_mmap>
            put_pgdir(mm);
ffffffffc02052d6:	854e                	mv	a0,s3
ffffffffc02052d8:	b18ff0ef          	jal	ra,ffffffffc02045f0 <put_pgdir>
            mm_destroy(mm);
ffffffffc02052dc:	854e                	mv	a0,s3
ffffffffc02052de:	d0bfd0ef          	jal	ra,ffffffffc0202fe8 <mm_destroy>
ffffffffc02052e2:	b30d                	j	ffffffffc0205004 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc02052e4:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc02052e8:	fb95                	bnez	a5,ffffffffc020521c <do_execve+0x2aa>
            perm |= (PTE_W | PTE_R);
ffffffffc02052ea:	4d5d                	li	s10,23
ffffffffc02052ec:	bf35                	j	ffffffffc0205228 <do_execve+0x2b6>
        end = ph->p_va + ph->p_memsz;
ffffffffc02052ee:	0109b683          	ld	a3,16(s3)
ffffffffc02052f2:	0289b903          	ld	s2,40(s3)
ffffffffc02052f6:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc02052f8:	075bfd63          	bgeu	s7,s5,ffffffffc0205372 <do_execve+0x400>
            if (start == end)
ffffffffc02052fc:	db790be3          	beq	s2,s7,ffffffffc02050b2 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205300:	6785                	lui	a5,0x1
ffffffffc0205302:	00fb8533          	add	a0,s7,a5
ffffffffc0205306:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc020530a:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc020530e:	0b597d63          	bgeu	s2,s5,ffffffffc02053c8 <do_execve+0x456>
    return page - pages + nbase;
ffffffffc0205312:	000cb683          	ld	a3,0(s9)
ffffffffc0205316:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205318:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc020531c:	40d406b3          	sub	a3,s0,a3
ffffffffc0205320:	8699                	srai	a3,a3,0x6
ffffffffc0205322:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205324:	67e2                	ld	a5,24(sp)
ffffffffc0205326:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020532a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020532c:	0ac5f963          	bgeu	a1,a2,ffffffffc02053de <do_execve+0x46c>
ffffffffc0205330:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205334:	8652                	mv	a2,s4
ffffffffc0205336:	4581                	li	a1,0
ffffffffc0205338:	96c2                	add	a3,a3,a6
ffffffffc020533a:	9536                	add	a0,a0,a3
ffffffffc020533c:	6b0000ef          	jal	ra,ffffffffc02059ec <memset>
            start += size;
ffffffffc0205340:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205344:	03597463          	bgeu	s2,s5,ffffffffc020536c <do_execve+0x3fa>
ffffffffc0205348:	d6e905e3          	beq	s2,a4,ffffffffc02050b2 <do_execve+0x140>
ffffffffc020534c:	00003697          	auipc	a3,0x3
ffffffffc0205350:	82468693          	addi	a3,a3,-2012 # ffffffffc0207b70 <default_pmm_manager+0x2c8>
ffffffffc0205354:	00002617          	auipc	a2,0x2
ffffffffc0205358:	89460613          	addi	a2,a2,-1900 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020535c:	27d00593          	li	a1,637
ffffffffc0205360:	00002517          	auipc	a0,0x2
ffffffffc0205364:	5e050513          	addi	a0,a0,1504 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0205368:	eb7fa0ef          	jal	ra,ffffffffc020021e <__panic>
ffffffffc020536c:	ff5710e3          	bne	a4,s5,ffffffffc020534c <do_execve+0x3da>
ffffffffc0205370:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0205372:	d52bf0e3          	bgeu	s7,s2,ffffffffc02050b2 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205376:	6c88                	ld	a0,24(s1)
ffffffffc0205378:	866a                	mv	a2,s10
ffffffffc020537a:	85d6                	mv	a1,s5
ffffffffc020537c:	84ffd0ef          	jal	ra,ffffffffc0202bca <pgdir_alloc_page>
ffffffffc0205380:	842a                	mv	s0,a0
ffffffffc0205382:	dd05                	beqz	a0,ffffffffc02052ba <do_execve+0x348>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205384:	6785                	lui	a5,0x1
ffffffffc0205386:	415b8533          	sub	a0,s7,s5
ffffffffc020538a:	9abe                	add	s5,s5,a5
ffffffffc020538c:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0205390:	01597463          	bgeu	s2,s5,ffffffffc0205398 <do_execve+0x426>
                size -= la - end;
ffffffffc0205394:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0205398:	000cb683          	ld	a3,0(s9)
ffffffffc020539c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020539e:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02053a2:	40d406b3          	sub	a3,s0,a3
ffffffffc02053a6:	8699                	srai	a3,a3,0x6
ffffffffc02053a8:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02053aa:	67e2                	ld	a5,24(sp)
ffffffffc02053ac:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02053b0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02053b2:	02b87663          	bgeu	a6,a1,ffffffffc02053de <do_execve+0x46c>
ffffffffc02053b6:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc02053ba:	4581                	li	a1,0
            start += size;
ffffffffc02053bc:	9bb2                	add	s7,s7,a2
ffffffffc02053be:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc02053c0:	9536                	add	a0,a0,a3
ffffffffc02053c2:	62a000ef          	jal	ra,ffffffffc02059ec <memset>
ffffffffc02053c6:	b775                	j	ffffffffc0205372 <do_execve+0x400>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc02053c8:	417a8a33          	sub	s4,s5,s7
ffffffffc02053cc:	b799                	j	ffffffffc0205312 <do_execve+0x3a0>
        return -E_INVAL;
ffffffffc02053ce:	5a75                	li	s4,-3
ffffffffc02053d0:	b3c1                	j	ffffffffc0205190 <do_execve+0x21e>
        while (start < end)
ffffffffc02053d2:	86de                	mv	a3,s7
ffffffffc02053d4:	bf39                	j	ffffffffc02052f2 <do_execve+0x380>
    int ret = -E_NO_MEM;
ffffffffc02053d6:	5a71                	li	s4,-4
ffffffffc02053d8:	bdc5                	j	ffffffffc02052c8 <do_execve+0x356>
            ret = -E_INVAL_ELF;
ffffffffc02053da:	5a61                	li	s4,-8
ffffffffc02053dc:	b5c5                	j	ffffffffc02052bc <do_execve+0x34a>
ffffffffc02053de:	00001617          	auipc	a2,0x1
ffffffffc02053e2:	77a60613          	addi	a2,a2,1914 # ffffffffc0206b58 <commands+0x960>
ffffffffc02053e6:	07100593          	li	a1,113
ffffffffc02053ea:	00001517          	auipc	a0,0x1
ffffffffc02053ee:	75e50513          	addi	a0,a0,1886 # ffffffffc0206b48 <commands+0x950>
ffffffffc02053f2:	e2dfa0ef          	jal	ra,ffffffffc020021e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02053f6:	00002617          	auipc	a2,0x2
ffffffffc02053fa:	89a60613          	addi	a2,a2,-1894 # ffffffffc0206c90 <commands+0xa98>
ffffffffc02053fe:	29c00593          	li	a1,668
ffffffffc0205402:	00002517          	auipc	a0,0x2
ffffffffc0205406:	53e50513          	addi	a0,a0,1342 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc020540a:	e15fa0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020540e:	00003697          	auipc	a3,0x3
ffffffffc0205412:	87a68693          	addi	a3,a3,-1926 # ffffffffc0207c88 <default_pmm_manager+0x3e0>
ffffffffc0205416:	00001617          	auipc	a2,0x1
ffffffffc020541a:	7d260613          	addi	a2,a2,2002 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020541e:	29700593          	li	a1,663
ffffffffc0205422:	00002517          	auipc	a0,0x2
ffffffffc0205426:	51e50513          	addi	a0,a0,1310 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc020542a:	df5fa0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020542e:	00003697          	auipc	a3,0x3
ffffffffc0205432:	81268693          	addi	a3,a3,-2030 # ffffffffc0207c40 <default_pmm_manager+0x398>
ffffffffc0205436:	00001617          	auipc	a2,0x1
ffffffffc020543a:	7b260613          	addi	a2,a2,1970 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020543e:	29600593          	li	a1,662
ffffffffc0205442:	00002517          	auipc	a0,0x2
ffffffffc0205446:	4fe50513          	addi	a0,a0,1278 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc020544a:	dd5fa0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc020544e:	00002697          	auipc	a3,0x2
ffffffffc0205452:	7aa68693          	addi	a3,a3,1962 # ffffffffc0207bf8 <default_pmm_manager+0x350>
ffffffffc0205456:	00001617          	auipc	a2,0x1
ffffffffc020545a:	79260613          	addi	a2,a2,1938 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020545e:	29500593          	li	a1,661
ffffffffc0205462:	00002517          	auipc	a0,0x2
ffffffffc0205466:	4de50513          	addi	a0,a0,1246 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc020546a:	db5fa0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc020546e:	00002697          	auipc	a3,0x2
ffffffffc0205472:	74268693          	addi	a3,a3,1858 # ffffffffc0207bb0 <default_pmm_manager+0x308>
ffffffffc0205476:	00001617          	auipc	a2,0x1
ffffffffc020547a:	77260613          	addi	a2,a2,1906 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020547e:	29400593          	li	a1,660
ffffffffc0205482:	00002517          	auipc	a0,0x2
ffffffffc0205486:	4be50513          	addi	a0,a0,1214 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc020548a:	d95fa0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc020548e <do_yield>:
    current->need_resched = 1;
ffffffffc020548e:	000c1797          	auipc	a5,0xc1
ffffffffc0205492:	cf27b783          	ld	a5,-782(a5) # ffffffffc02c6180 <current>
ffffffffc0205496:	4705                	li	a4,1
ffffffffc0205498:	ef98                	sd	a4,24(a5)
}
ffffffffc020549a:	4501                	li	a0,0
ffffffffc020549c:	8082                	ret

ffffffffc020549e <do_wait>:
{
ffffffffc020549e:	1101                	addi	sp,sp,-32
ffffffffc02054a0:	e822                	sd	s0,16(sp)
ffffffffc02054a2:	e426                	sd	s1,8(sp)
ffffffffc02054a4:	ec06                	sd	ra,24(sp)
ffffffffc02054a6:	842e                	mv	s0,a1
ffffffffc02054a8:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc02054aa:	c999                	beqz	a1,ffffffffc02054c0 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc02054ac:	000c1797          	auipc	a5,0xc1
ffffffffc02054b0:	cd47b783          	ld	a5,-812(a5) # ffffffffc02c6180 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc02054b4:	7788                	ld	a0,40(a5)
ffffffffc02054b6:	4685                	li	a3,1
ffffffffc02054b8:	4611                	li	a2,4
ffffffffc02054ba:	864fe0ef          	jal	ra,ffffffffc020351e <user_mem_check>
ffffffffc02054be:	c909                	beqz	a0,ffffffffc02054d0 <do_wait+0x32>
ffffffffc02054c0:	85a2                	mv	a1,s0
}
ffffffffc02054c2:	6442                	ld	s0,16(sp)
ffffffffc02054c4:	60e2                	ld	ra,24(sp)
ffffffffc02054c6:	8526                	mv	a0,s1
ffffffffc02054c8:	64a2                	ld	s1,8(sp)
ffffffffc02054ca:	6105                	addi	sp,sp,32
ffffffffc02054cc:	fb0ff06f          	j	ffffffffc0204c7c <do_wait.part.0>
ffffffffc02054d0:	60e2                	ld	ra,24(sp)
ffffffffc02054d2:	6442                	ld	s0,16(sp)
ffffffffc02054d4:	64a2                	ld	s1,8(sp)
ffffffffc02054d6:	5575                	li	a0,-3
ffffffffc02054d8:	6105                	addi	sp,sp,32
ffffffffc02054da:	8082                	ret

ffffffffc02054dc <do_kill>:
{
ffffffffc02054dc:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc02054de:	6789                	lui	a5,0x2
{
ffffffffc02054e0:	e406                	sd	ra,8(sp)
ffffffffc02054e2:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc02054e4:	fff5071b          	addiw	a4,a0,-1
ffffffffc02054e8:	17f9                	addi	a5,a5,-2
ffffffffc02054ea:	02e7e963          	bltu	a5,a4,ffffffffc020551c <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02054ee:	842a                	mv	s0,a0
ffffffffc02054f0:	45a9                	li	a1,10
ffffffffc02054f2:	2501                	sext.w	a0,a0
ffffffffc02054f4:	111000ef          	jal	ra,ffffffffc0205e04 <hash32>
ffffffffc02054f8:	02051793          	slli	a5,a0,0x20
ffffffffc02054fc:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205500:	000bd797          	auipc	a5,0xbd
ffffffffc0205504:	c0878793          	addi	a5,a5,-1016 # ffffffffc02c2108 <hash_list>
ffffffffc0205508:	953e                	add	a0,a0,a5
ffffffffc020550a:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc020550c:	a029                	j	ffffffffc0205516 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc020550e:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205512:	00870b63          	beq	a4,s0,ffffffffc0205528 <do_kill+0x4c>
ffffffffc0205516:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205518:	fef51be3          	bne	a0,a5,ffffffffc020550e <do_kill+0x32>
    return -E_INVAL;
ffffffffc020551c:	5475                	li	s0,-3
}
ffffffffc020551e:	60a2                	ld	ra,8(sp)
ffffffffc0205520:	8522                	mv	a0,s0
ffffffffc0205522:	6402                	ld	s0,0(sp)
ffffffffc0205524:	0141                	addi	sp,sp,16
ffffffffc0205526:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0205528:	fd87a703          	lw	a4,-40(a5)
ffffffffc020552c:	00177693          	andi	a3,a4,1
ffffffffc0205530:	e295                	bnez	a3,ffffffffc0205554 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205532:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0205534:	00176713          	ori	a4,a4,1
ffffffffc0205538:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc020553c:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc020553e:	fe06d0e3          	bgez	a3,ffffffffc020551e <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0205542:	f2878513          	addi	a0,a5,-216
ffffffffc0205546:	1c4000ef          	jal	ra,ffffffffc020570a <wakeup_proc>
}
ffffffffc020554a:	60a2                	ld	ra,8(sp)
ffffffffc020554c:	8522                	mv	a0,s0
ffffffffc020554e:	6402                	ld	s0,0(sp)
ffffffffc0205550:	0141                	addi	sp,sp,16
ffffffffc0205552:	8082                	ret
        return -E_KILLED;
ffffffffc0205554:	545d                	li	s0,-9
ffffffffc0205556:	b7e1                	j	ffffffffc020551e <do_kill+0x42>

ffffffffc0205558 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0205558:	1101                	addi	sp,sp,-32
ffffffffc020555a:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc020555c:	000c1797          	auipc	a5,0xc1
ffffffffc0205560:	bac78793          	addi	a5,a5,-1108 # ffffffffc02c6108 <proc_list>
ffffffffc0205564:	ec06                	sd	ra,24(sp)
ffffffffc0205566:	e822                	sd	s0,16(sp)
ffffffffc0205568:	e04a                	sd	s2,0(sp)
ffffffffc020556a:	000bd497          	auipc	s1,0xbd
ffffffffc020556e:	b9e48493          	addi	s1,s1,-1122 # ffffffffc02c2108 <hash_list>
ffffffffc0205572:	e79c                	sd	a5,8(a5)
ffffffffc0205574:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0205576:	000c1717          	auipc	a4,0xc1
ffffffffc020557a:	b9270713          	addi	a4,a4,-1134 # ffffffffc02c6108 <proc_list>
ffffffffc020557e:	87a6                	mv	a5,s1
ffffffffc0205580:	e79c                	sd	a5,8(a5)
ffffffffc0205582:	e39c                	sd	a5,0(a5)
ffffffffc0205584:	07c1                	addi	a5,a5,16
ffffffffc0205586:	fef71de3          	bne	a4,a5,ffffffffc0205580 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020558a:	f59fe0ef          	jal	ra,ffffffffc02044e2 <alloc_proc>
ffffffffc020558e:	000c1917          	auipc	s2,0xc1
ffffffffc0205592:	bfa90913          	addi	s2,s2,-1030 # ffffffffc02c6188 <idleproc>
ffffffffc0205596:	00a93023          	sd	a0,0(s2)
ffffffffc020559a:	0e050f63          	beqz	a0,ffffffffc0205698 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020559e:	4789                	li	a5,2
ffffffffc02055a0:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02055a2:	00004797          	auipc	a5,0x4
ffffffffc02055a6:	a5e78793          	addi	a5,a5,-1442 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02055aa:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02055ae:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc02055b0:	4785                	li	a5,1
ffffffffc02055b2:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02055b4:	4641                	li	a2,16
ffffffffc02055b6:	4581                	li	a1,0
ffffffffc02055b8:	8522                	mv	a0,s0
ffffffffc02055ba:	432000ef          	jal	ra,ffffffffc02059ec <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02055be:	463d                	li	a2,15
ffffffffc02055c0:	00002597          	auipc	a1,0x2
ffffffffc02055c4:	72858593          	addi	a1,a1,1832 # ffffffffc0207ce8 <default_pmm_manager+0x440>
ffffffffc02055c8:	8522                	mv	a0,s0
ffffffffc02055ca:	434000ef          	jal	ra,ffffffffc02059fe <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02055ce:	000c1717          	auipc	a4,0xc1
ffffffffc02055d2:	bca70713          	addi	a4,a4,-1078 # ffffffffc02c6198 <nr_process>
ffffffffc02055d6:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02055d8:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc02055dc:	4601                	li	a2,0
    nr_process++;
ffffffffc02055de:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc02055e0:	4581                	li	a1,0
ffffffffc02055e2:	00000517          	auipc	a0,0x0
ffffffffc02055e6:	86c50513          	addi	a0,a0,-1940 # ffffffffc0204e4e <init_main>
    nr_process++;
ffffffffc02055ea:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02055ec:	000c1797          	auipc	a5,0xc1
ffffffffc02055f0:	b8d7ba23          	sd	a3,-1132(a5) # ffffffffc02c6180 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc02055f4:	ceeff0ef          	jal	ra,ffffffffc0204ae2 <kernel_thread>
ffffffffc02055f8:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02055fa:	08a05363          	blez	a0,ffffffffc0205680 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc02055fe:	6789                	lui	a5,0x2
ffffffffc0205600:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205604:	17f9                	addi	a5,a5,-2
ffffffffc0205606:	2501                	sext.w	a0,a0
ffffffffc0205608:	02e7e363          	bltu	a5,a4,ffffffffc020562e <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020560c:	45a9                	li	a1,10
ffffffffc020560e:	7f6000ef          	jal	ra,ffffffffc0205e04 <hash32>
ffffffffc0205612:	02051793          	slli	a5,a0,0x20
ffffffffc0205616:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020561a:	96a6                	add	a3,a3,s1
ffffffffc020561c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020561e:	a029                	j	ffffffffc0205628 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0205620:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8254>
ffffffffc0205624:	04870b63          	beq	a4,s0,ffffffffc020567a <proc_init+0x122>
    return listelm->next;
ffffffffc0205628:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020562a:	fef69be3          	bne	a3,a5,ffffffffc0205620 <proc_init+0xc8>
    return NULL;
ffffffffc020562e:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205630:	0b478493          	addi	s1,a5,180
ffffffffc0205634:	4641                	li	a2,16
ffffffffc0205636:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205638:	000c1417          	auipc	s0,0xc1
ffffffffc020563c:	b5840413          	addi	s0,s0,-1192 # ffffffffc02c6190 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205640:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205642:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205644:	3a8000ef          	jal	ra,ffffffffc02059ec <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205648:	463d                	li	a2,15
ffffffffc020564a:	00002597          	auipc	a1,0x2
ffffffffc020564e:	6c658593          	addi	a1,a1,1734 # ffffffffc0207d10 <default_pmm_manager+0x468>
ffffffffc0205652:	8526                	mv	a0,s1
ffffffffc0205654:	3aa000ef          	jal	ra,ffffffffc02059fe <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205658:	00093783          	ld	a5,0(s2)
ffffffffc020565c:	cbb5                	beqz	a5,ffffffffc02056d0 <proc_init+0x178>
ffffffffc020565e:	43dc                	lw	a5,4(a5)
ffffffffc0205660:	eba5                	bnez	a5,ffffffffc02056d0 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205662:	601c                	ld	a5,0(s0)
ffffffffc0205664:	c7b1                	beqz	a5,ffffffffc02056b0 <proc_init+0x158>
ffffffffc0205666:	43d8                	lw	a4,4(a5)
ffffffffc0205668:	4785                	li	a5,1
ffffffffc020566a:	04f71363          	bne	a4,a5,ffffffffc02056b0 <proc_init+0x158>
}
ffffffffc020566e:	60e2                	ld	ra,24(sp)
ffffffffc0205670:	6442                	ld	s0,16(sp)
ffffffffc0205672:	64a2                	ld	s1,8(sp)
ffffffffc0205674:	6902                	ld	s2,0(sp)
ffffffffc0205676:	6105                	addi	sp,sp,32
ffffffffc0205678:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020567a:	f2878793          	addi	a5,a5,-216
ffffffffc020567e:	bf4d                	j	ffffffffc0205630 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205680:	00002617          	auipc	a2,0x2
ffffffffc0205684:	67060613          	addi	a2,a2,1648 # ffffffffc0207cf0 <default_pmm_manager+0x448>
ffffffffc0205688:	3b800593          	li	a1,952
ffffffffc020568c:	00002517          	auipc	a0,0x2
ffffffffc0205690:	2b450513          	addi	a0,a0,692 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc0205694:	b8bfa0ef          	jal	ra,ffffffffc020021e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205698:	00002617          	auipc	a2,0x2
ffffffffc020569c:	63860613          	addi	a2,a2,1592 # ffffffffc0207cd0 <default_pmm_manager+0x428>
ffffffffc02056a0:	3a900593          	li	a1,937
ffffffffc02056a4:	00002517          	auipc	a0,0x2
ffffffffc02056a8:	29c50513          	addi	a0,a0,668 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc02056ac:	b73fa0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02056b0:	00002697          	auipc	a3,0x2
ffffffffc02056b4:	69068693          	addi	a3,a3,1680 # ffffffffc0207d40 <default_pmm_manager+0x498>
ffffffffc02056b8:	00001617          	auipc	a2,0x1
ffffffffc02056bc:	53060613          	addi	a2,a2,1328 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02056c0:	3bf00593          	li	a1,959
ffffffffc02056c4:	00002517          	auipc	a0,0x2
ffffffffc02056c8:	27c50513          	addi	a0,a0,636 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc02056cc:	b53fa0ef          	jal	ra,ffffffffc020021e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02056d0:	00002697          	auipc	a3,0x2
ffffffffc02056d4:	64868693          	addi	a3,a3,1608 # ffffffffc0207d18 <default_pmm_manager+0x470>
ffffffffc02056d8:	00001617          	auipc	a2,0x1
ffffffffc02056dc:	51060613          	addi	a2,a2,1296 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc02056e0:	3be00593          	li	a1,958
ffffffffc02056e4:	00002517          	auipc	a0,0x2
ffffffffc02056e8:	25c50513          	addi	a0,a0,604 # ffffffffc0207940 <default_pmm_manager+0x98>
ffffffffc02056ec:	b33fa0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc02056f0 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02056f0:	1141                	addi	sp,sp,-16
ffffffffc02056f2:	e022                	sd	s0,0(sp)
ffffffffc02056f4:	e406                	sd	ra,8(sp)
ffffffffc02056f6:	000c1417          	auipc	s0,0xc1
ffffffffc02056fa:	a8a40413          	addi	s0,s0,-1398 # ffffffffc02c6180 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02056fe:	6018                	ld	a4,0(s0)
ffffffffc0205700:	6f1c                	ld	a5,24(a4)
ffffffffc0205702:	dffd                	beqz	a5,ffffffffc0205700 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205704:	086000ef          	jal	ra,ffffffffc020578a <schedule>
ffffffffc0205708:	bfdd                	j	ffffffffc02056fe <cpu_idle+0xe>

ffffffffc020570a <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020570a:	4118                	lw	a4,0(a0)
{
ffffffffc020570c:	1101                	addi	sp,sp,-32
ffffffffc020570e:	ec06                	sd	ra,24(sp)
ffffffffc0205710:	e822                	sd	s0,16(sp)
ffffffffc0205712:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205714:	478d                	li	a5,3
ffffffffc0205716:	04f70b63          	beq	a4,a5,ffffffffc020576c <wakeup_proc+0x62>
ffffffffc020571a:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020571c:	100027f3          	csrr	a5,sstatus
ffffffffc0205720:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205722:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205724:	ef9d                	bnez	a5,ffffffffc0205762 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205726:	4789                	li	a5,2
ffffffffc0205728:	02f70163          	beq	a4,a5,ffffffffc020574a <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020572c:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc020572e:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205732:	e491                	bnez	s1,ffffffffc020573e <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205734:	60e2                	ld	ra,24(sp)
ffffffffc0205736:	6442                	ld	s0,16(sp)
ffffffffc0205738:	64a2                	ld	s1,8(sp)
ffffffffc020573a:	6105                	addi	sp,sp,32
ffffffffc020573c:	8082                	ret
ffffffffc020573e:	6442                	ld	s0,16(sp)
ffffffffc0205740:	60e2                	ld	ra,24(sp)
ffffffffc0205742:	64a2                	ld	s1,8(sp)
ffffffffc0205744:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205746:	b38fb06f          	j	ffffffffc0200a7e <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020574a:	00002617          	auipc	a2,0x2
ffffffffc020574e:	65660613          	addi	a2,a2,1622 # ffffffffc0207da0 <default_pmm_manager+0x4f8>
ffffffffc0205752:	45d1                	li	a1,20
ffffffffc0205754:	00002517          	auipc	a0,0x2
ffffffffc0205758:	63450513          	addi	a0,a0,1588 # ffffffffc0207d88 <default_pmm_manager+0x4e0>
ffffffffc020575c:	b1ffa0ef          	jal	ra,ffffffffc020027a <__warn>
ffffffffc0205760:	bfc9                	j	ffffffffc0205732 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205762:	b22fb0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205766:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205768:	4485                	li	s1,1
ffffffffc020576a:	bf75                	j	ffffffffc0205726 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020576c:	00002697          	auipc	a3,0x2
ffffffffc0205770:	5fc68693          	addi	a3,a3,1532 # ffffffffc0207d68 <default_pmm_manager+0x4c0>
ffffffffc0205774:	00001617          	auipc	a2,0x1
ffffffffc0205778:	47460613          	addi	a2,a2,1140 # ffffffffc0206be8 <commands+0x9f0>
ffffffffc020577c:	45a5                	li	a1,9
ffffffffc020577e:	00002517          	auipc	a0,0x2
ffffffffc0205782:	60a50513          	addi	a0,a0,1546 # ffffffffc0207d88 <default_pmm_manager+0x4e0>
ffffffffc0205786:	a99fa0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc020578a <schedule>:

void schedule(void)
{
ffffffffc020578a:	1141                	addi	sp,sp,-16
ffffffffc020578c:	e406                	sd	ra,8(sp)
ffffffffc020578e:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205790:	100027f3          	csrr	a5,sstatus
ffffffffc0205794:	8b89                	andi	a5,a5,2
ffffffffc0205796:	4401                	li	s0,0
ffffffffc0205798:	efbd                	bnez	a5,ffffffffc0205816 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020579a:	000c1897          	auipc	a7,0xc1
ffffffffc020579e:	9e68b883          	ld	a7,-1562(a7) # ffffffffc02c6180 <current>
ffffffffc02057a2:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02057a6:	000c1517          	auipc	a0,0xc1
ffffffffc02057aa:	9e253503          	ld	a0,-1566(a0) # ffffffffc02c6188 <idleproc>
ffffffffc02057ae:	04a88e63          	beq	a7,a0,ffffffffc020580a <schedule+0x80>
ffffffffc02057b2:	0c888693          	addi	a3,a7,200
ffffffffc02057b6:	000c1617          	auipc	a2,0xc1
ffffffffc02057ba:	95260613          	addi	a2,a2,-1710 # ffffffffc02c6108 <proc_list>
        le = last;
ffffffffc02057be:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02057c0:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02057c2:	4809                	li	a6,2
ffffffffc02057c4:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02057c6:	00c78863          	beq	a5,a2,ffffffffc02057d6 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02057ca:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02057ce:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02057d2:	03070163          	beq	a4,a6,ffffffffc02057f4 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02057d6:	fef697e3          	bne	a3,a5,ffffffffc02057c4 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02057da:	ed89                	bnez	a1,ffffffffc02057f4 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02057dc:	451c                	lw	a5,8(a0)
ffffffffc02057de:	2785                	addiw	a5,a5,1
ffffffffc02057e0:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02057e2:	00a88463          	beq	a7,a0,ffffffffc02057ea <schedule+0x60>
        {
            proc_run(next);
ffffffffc02057e6:	e81fe0ef          	jal	ra,ffffffffc0204666 <proc_run>
    if (flag)
ffffffffc02057ea:	e819                	bnez	s0,ffffffffc0205800 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02057ec:	60a2                	ld	ra,8(sp)
ffffffffc02057ee:	6402                	ld	s0,0(sp)
ffffffffc02057f0:	0141                	addi	sp,sp,16
ffffffffc02057f2:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02057f4:	4198                	lw	a4,0(a1)
ffffffffc02057f6:	4789                	li	a5,2
ffffffffc02057f8:	fef712e3          	bne	a4,a5,ffffffffc02057dc <schedule+0x52>
ffffffffc02057fc:	852e                	mv	a0,a1
ffffffffc02057fe:	bff9                	j	ffffffffc02057dc <schedule+0x52>
}
ffffffffc0205800:	6402                	ld	s0,0(sp)
ffffffffc0205802:	60a2                	ld	ra,8(sp)
ffffffffc0205804:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205806:	a78fb06f          	j	ffffffffc0200a7e <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020580a:	000c1617          	auipc	a2,0xc1
ffffffffc020580e:	8fe60613          	addi	a2,a2,-1794 # ffffffffc02c6108 <proc_list>
ffffffffc0205812:	86b2                	mv	a3,a2
ffffffffc0205814:	b76d                	j	ffffffffc02057be <schedule+0x34>
        intr_disable();
ffffffffc0205816:	a6efb0ef          	jal	ra,ffffffffc0200a84 <intr_disable>
        return 1;
ffffffffc020581a:	4405                	li	s0,1
ffffffffc020581c:	bfbd                	j	ffffffffc020579a <schedule+0x10>

ffffffffc020581e <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020581e:	000c1797          	auipc	a5,0xc1
ffffffffc0205822:	9627b783          	ld	a5,-1694(a5) # ffffffffc02c6180 <current>
}
ffffffffc0205826:	43c8                	lw	a0,4(a5)
ffffffffc0205828:	8082                	ret

ffffffffc020582a <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020582a:	4501                	li	a0,0
ffffffffc020582c:	8082                	ret

ffffffffc020582e <sys_dirtycowctl>:
//   mode = -1: 查询当前模式，0 表示修复，1 表示漏洞复现
//   mode = 0/1: 切换到 fix/bug 模式
//   其它数值返回 -E_INVAL
static int
sys_dirtycowctl(uint64_t arg[]) {
    int mode = (int)arg[0];
ffffffffc020582e:	411c                	lw	a5,0(a0)
    if (mode == -1)
ffffffffc0205830:	577d                	li	a4,-1
ffffffffc0205832:	02e78663          	beq	a5,a4,ffffffffc020585e <sys_dirtycowctl+0x30>
sys_dirtycowctl(uint64_t arg[]) {
ffffffffc0205836:	1141                	addi	sp,sp,-16
ffffffffc0205838:	e406                	sd	ra,8(sp)
    {
        return dirtycow_stats.emulate_bug;
    }
    if (mode == 0)
ffffffffc020583a:	cf91                	beqz	a5,ffffffffc0205856 <sys_dirtycowctl+0x28>
    {
        dirtycow_set_mode(0);
    }
    else if (mode == 1)
ffffffffc020583c:	4705                	li	a4,1
ffffffffc020583e:	02e79563          	bne	a5,a4,ffffffffc0205868 <sys_dirtycowctl+0x3a>
    {
        dirtycow_set_mode(1);
ffffffffc0205842:	4505                	li	a0,1
ffffffffc0205844:	9ebfb0ef          	jal	ra,ffffffffc020122e <dirtycow_set_mode>
    }
    else
    {
        return -E_INVAL;
    }
    return dirtycow_stats.emulate_bug;
ffffffffc0205848:	000bd517          	auipc	a0,0xbd
ffffffffc020584c:	89052503          	lw	a0,-1904(a0) # ffffffffc02c20d8 <dirtycow_stats>
}
ffffffffc0205850:	60a2                	ld	ra,8(sp)
ffffffffc0205852:	0141                	addi	sp,sp,16
ffffffffc0205854:	8082                	ret
        dirtycow_set_mode(0);
ffffffffc0205856:	4501                	li	a0,0
ffffffffc0205858:	9d7fb0ef          	jal	ra,ffffffffc020122e <dirtycow_set_mode>
ffffffffc020585c:	b7f5                	j	ffffffffc0205848 <sys_dirtycowctl+0x1a>
        return dirtycow_stats.emulate_bug;
ffffffffc020585e:	000bd517          	auipc	a0,0xbd
ffffffffc0205862:	87a52503          	lw	a0,-1926(a0) # ffffffffc02c20d8 <dirtycow_stats>
}
ffffffffc0205866:	8082                	ret
        return -E_INVAL;
ffffffffc0205868:	5575                	li	a0,-3
ffffffffc020586a:	b7dd                	j	ffffffffc0205850 <sys_dirtycowctl+0x22>

ffffffffc020586c <sys_mempoke>:
    return dirtycow_mempoke(current->mm, dst, src, len);
ffffffffc020586c:	000c1797          	auipc	a5,0xc1
ffffffffc0205870:	9147b783          	ld	a5,-1772(a5) # ffffffffc02c6180 <current>
ffffffffc0205874:	6914                	ld	a3,16(a0)
ffffffffc0205876:	6510                	ld	a2,8(a0)
ffffffffc0205878:	610c                	ld	a1,0(a0)
ffffffffc020587a:	7788                	ld	a0,40(a5)
ffffffffc020587c:	9ddfb06f          	j	ffffffffc0201258 <dirtycow_mempoke>

ffffffffc0205880 <sys_putc>:
    cputchar(c);
ffffffffc0205880:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205882:	1141                	addi	sp,sp,-16
ffffffffc0205884:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205886:	891fa0ef          	jal	ra,ffffffffc0200116 <cputchar>
}
ffffffffc020588a:	60a2                	ld	ra,8(sp)
ffffffffc020588c:	4501                	li	a0,0
ffffffffc020588e:	0141                	addi	sp,sp,16
ffffffffc0205890:	8082                	ret

ffffffffc0205892 <sys_kill>:
    return do_kill(pid);
ffffffffc0205892:	4108                	lw	a0,0(a0)
ffffffffc0205894:	c49ff06f          	j	ffffffffc02054dc <do_kill>

ffffffffc0205898 <sys_yield>:
    return do_yield();
ffffffffc0205898:	bf7ff06f          	j	ffffffffc020548e <do_yield>

ffffffffc020589c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020589c:	6d14                	ld	a3,24(a0)
ffffffffc020589e:	6910                	ld	a2,16(a0)
ffffffffc02058a0:	650c                	ld	a1,8(a0)
ffffffffc02058a2:	6108                	ld	a0,0(a0)
ffffffffc02058a4:	eceff06f          	j	ffffffffc0204f72 <do_execve>

ffffffffc02058a8 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02058a8:	650c                	ld	a1,8(a0)
ffffffffc02058aa:	4108                	lw	a0,0(a0)
ffffffffc02058ac:	bf3ff06f          	j	ffffffffc020549e <do_wait>

ffffffffc02058b0 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02058b0:	000c1797          	auipc	a5,0xc1
ffffffffc02058b4:	8d07b783          	ld	a5,-1840(a5) # ffffffffc02c6180 <current>
ffffffffc02058b8:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02058ba:	4501                	li	a0,0
ffffffffc02058bc:	6a0c                	ld	a1,16(a2)
ffffffffc02058be:	e0dfe06f          	j	ffffffffc02046ca <do_fork>

ffffffffc02058c2 <sys_exit>:
    return do_exit(error_code);
ffffffffc02058c2:	4108                	lw	a0,0(a0)
ffffffffc02058c4:	a6eff06f          	j	ffffffffc0204b32 <do_exit>

ffffffffc02058c8 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02058c8:	715d                	addi	sp,sp,-80
ffffffffc02058ca:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02058cc:	000c1497          	auipc	s1,0xc1
ffffffffc02058d0:	8b448493          	addi	s1,s1,-1868 # ffffffffc02c6180 <current>
ffffffffc02058d4:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02058d6:	e0a2                	sd	s0,64(sp)
ffffffffc02058d8:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02058da:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02058dc:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02058de:	02100793          	li	a5,33
    int num = tf->gpr.a0;
ffffffffc02058e2:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02058e6:	0327ee63          	bltu	a5,s2,ffffffffc0205922 <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc02058ea:	00391713          	slli	a4,s2,0x3
ffffffffc02058ee:	00002797          	auipc	a5,0x2
ffffffffc02058f2:	51a78793          	addi	a5,a5,1306 # ffffffffc0207e08 <syscalls>
ffffffffc02058f6:	97ba                	add	a5,a5,a4
ffffffffc02058f8:	639c                	ld	a5,0(a5)
ffffffffc02058fa:	c785                	beqz	a5,ffffffffc0205922 <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc02058fc:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02058fe:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205900:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205902:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205904:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205906:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205908:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020590a:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020590c:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020590e:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205910:	0028                	addi	a0,sp,8
ffffffffc0205912:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205914:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205916:	e828                	sd	a0,80(s0)
}
ffffffffc0205918:	6406                	ld	s0,64(sp)
ffffffffc020591a:	74e2                	ld	s1,56(sp)
ffffffffc020591c:	7942                	ld	s2,48(sp)
ffffffffc020591e:	6161                	addi	sp,sp,80
ffffffffc0205920:	8082                	ret
    print_trapframe(tf);
ffffffffc0205922:	8522                	mv	a0,s0
ffffffffc0205924:	b4efb0ef          	jal	ra,ffffffffc0200c72 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205928:	609c                	ld	a5,0(s1)
ffffffffc020592a:	86ca                	mv	a3,s2
ffffffffc020592c:	00002617          	auipc	a2,0x2
ffffffffc0205930:	49460613          	addi	a2,a2,1172 # ffffffffc0207dc0 <default_pmm_manager+0x518>
ffffffffc0205934:	43d8                	lw	a4,4(a5)
ffffffffc0205936:	08c00593          	li	a1,140
ffffffffc020593a:	0b478793          	addi	a5,a5,180
ffffffffc020593e:	00002517          	auipc	a0,0x2
ffffffffc0205942:	4b250513          	addi	a0,a0,1202 # ffffffffc0207df0 <default_pmm_manager+0x548>
ffffffffc0205946:	8d9fa0ef          	jal	ra,ffffffffc020021e <__panic>

ffffffffc020594a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020594a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020594e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205950:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205952:	cb81                	beqz	a5,ffffffffc0205962 <strlen+0x18>
        cnt ++;
ffffffffc0205954:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205956:	00a707b3          	add	a5,a4,a0
ffffffffc020595a:	0007c783          	lbu	a5,0(a5)
ffffffffc020595e:	fbfd                	bnez	a5,ffffffffc0205954 <strlen+0xa>
ffffffffc0205960:	8082                	ret
    }
    return cnt;
}
ffffffffc0205962:	8082                	ret

ffffffffc0205964 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205964:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205966:	e589                	bnez	a1,ffffffffc0205970 <strnlen+0xc>
ffffffffc0205968:	a811                	j	ffffffffc020597c <strnlen+0x18>
        cnt ++;
ffffffffc020596a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020596c:	00f58863          	beq	a1,a5,ffffffffc020597c <strnlen+0x18>
ffffffffc0205970:	00f50733          	add	a4,a0,a5
ffffffffc0205974:	00074703          	lbu	a4,0(a4)
ffffffffc0205978:	fb6d                	bnez	a4,ffffffffc020596a <strnlen+0x6>
ffffffffc020597a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020597c:	852e                	mv	a0,a1
ffffffffc020597e:	8082                	ret

ffffffffc0205980 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205980:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205982:	0005c703          	lbu	a4,0(a1)
ffffffffc0205986:	0785                	addi	a5,a5,1
ffffffffc0205988:	0585                	addi	a1,a1,1
ffffffffc020598a:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020598e:	fb75                	bnez	a4,ffffffffc0205982 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205990:	8082                	ret

ffffffffc0205992 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205992:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205996:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020599a:	cb89                	beqz	a5,ffffffffc02059ac <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020599c:	0505                	addi	a0,a0,1
ffffffffc020599e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02059a0:	fee789e3          	beq	a5,a4,ffffffffc0205992 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059a4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02059a8:	9d19                	subw	a0,a0,a4
ffffffffc02059aa:	8082                	ret
ffffffffc02059ac:	4501                	li	a0,0
ffffffffc02059ae:	bfed                	j	ffffffffc02059a8 <strcmp+0x16>

ffffffffc02059b0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059b0:	c20d                	beqz	a2,ffffffffc02059d2 <strncmp+0x22>
ffffffffc02059b2:	962e                	add	a2,a2,a1
ffffffffc02059b4:	a031                	j	ffffffffc02059c0 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02059b6:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059b8:	00e79a63          	bne	a5,a4,ffffffffc02059cc <strncmp+0x1c>
ffffffffc02059bc:	00b60b63          	beq	a2,a1,ffffffffc02059d2 <strncmp+0x22>
ffffffffc02059c0:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02059c4:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02059c6:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02059ca:	f7f5                	bnez	a5,ffffffffc02059b6 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059cc:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02059d0:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02059d2:	4501                	li	a0,0
ffffffffc02059d4:	8082                	ret

ffffffffc02059d6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02059d6:	00054783          	lbu	a5,0(a0)
ffffffffc02059da:	c799                	beqz	a5,ffffffffc02059e8 <strchr+0x12>
        if (*s == c) {
ffffffffc02059dc:	00f58763          	beq	a1,a5,ffffffffc02059ea <strchr+0x14>
    while (*s != '\0') {
ffffffffc02059e0:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02059e4:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02059e6:	fbfd                	bnez	a5,ffffffffc02059dc <strchr+0x6>
    }
    return NULL;
ffffffffc02059e8:	4501                	li	a0,0
}
ffffffffc02059ea:	8082                	ret

ffffffffc02059ec <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02059ec:	ca01                	beqz	a2,ffffffffc02059fc <memset+0x10>
ffffffffc02059ee:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02059f0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02059f2:	0785                	addi	a5,a5,1
ffffffffc02059f4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02059f8:	fec79de3          	bne	a5,a2,ffffffffc02059f2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02059fc:	8082                	ret

ffffffffc02059fe <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02059fe:	ca19                	beqz	a2,ffffffffc0205a14 <memcpy+0x16>
ffffffffc0205a00:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205a02:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205a04:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a08:	0585                	addi	a1,a1,1
ffffffffc0205a0a:	0785                	addi	a5,a5,1
ffffffffc0205a0c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205a10:	fec59ae3          	bne	a1,a2,ffffffffc0205a04 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205a14:	8082                	ret

ffffffffc0205a16 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205a16:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205a1a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205a1c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205a20:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205a22:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205a26:	f022                	sd	s0,32(sp)
ffffffffc0205a28:	ec26                	sd	s1,24(sp)
ffffffffc0205a2a:	e84a                	sd	s2,16(sp)
ffffffffc0205a2c:	f406                	sd	ra,40(sp)
ffffffffc0205a2e:	e44e                	sd	s3,8(sp)
ffffffffc0205a30:	84aa                	mv	s1,a0
ffffffffc0205a32:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205a34:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205a38:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205a3a:	03067e63          	bgeu	a2,a6,ffffffffc0205a76 <printnum+0x60>
ffffffffc0205a3e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205a40:	00805763          	blez	s0,ffffffffc0205a4e <printnum+0x38>
ffffffffc0205a44:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205a46:	85ca                	mv	a1,s2
ffffffffc0205a48:	854e                	mv	a0,s3
ffffffffc0205a4a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205a4c:	fc65                	bnez	s0,ffffffffc0205a44 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205a4e:	1a02                	slli	s4,s4,0x20
ffffffffc0205a50:	00002797          	auipc	a5,0x2
ffffffffc0205a54:	4c878793          	addi	a5,a5,1224 # ffffffffc0207f18 <syscalls+0x110>
ffffffffc0205a58:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205a5c:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205a5e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205a60:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205a64:	70a2                	ld	ra,40(sp)
ffffffffc0205a66:	69a2                	ld	s3,8(sp)
ffffffffc0205a68:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205a6a:	85ca                	mv	a1,s2
ffffffffc0205a6c:	87a6                	mv	a5,s1
}
ffffffffc0205a6e:	6942                	ld	s2,16(sp)
ffffffffc0205a70:	64e2                	ld	s1,24(sp)
ffffffffc0205a72:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205a74:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205a76:	03065633          	divu	a2,a2,a6
ffffffffc0205a7a:	8722                	mv	a4,s0
ffffffffc0205a7c:	f9bff0ef          	jal	ra,ffffffffc0205a16 <printnum>
ffffffffc0205a80:	b7f9                	j	ffffffffc0205a4e <printnum+0x38>

ffffffffc0205a82 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205a82:	7119                	addi	sp,sp,-128
ffffffffc0205a84:	f4a6                	sd	s1,104(sp)
ffffffffc0205a86:	f0ca                	sd	s2,96(sp)
ffffffffc0205a88:	ecce                	sd	s3,88(sp)
ffffffffc0205a8a:	e8d2                	sd	s4,80(sp)
ffffffffc0205a8c:	e4d6                	sd	s5,72(sp)
ffffffffc0205a8e:	e0da                	sd	s6,64(sp)
ffffffffc0205a90:	fc5e                	sd	s7,56(sp)
ffffffffc0205a92:	f06a                	sd	s10,32(sp)
ffffffffc0205a94:	fc86                	sd	ra,120(sp)
ffffffffc0205a96:	f8a2                	sd	s0,112(sp)
ffffffffc0205a98:	f862                	sd	s8,48(sp)
ffffffffc0205a9a:	f466                	sd	s9,40(sp)
ffffffffc0205a9c:	ec6e                	sd	s11,24(sp)
ffffffffc0205a9e:	892a                	mv	s2,a0
ffffffffc0205aa0:	84ae                	mv	s1,a1
ffffffffc0205aa2:	8d32                	mv	s10,a2
ffffffffc0205aa4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205aa6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205aaa:	5b7d                	li	s6,-1
ffffffffc0205aac:	00002a97          	auipc	s5,0x2
ffffffffc0205ab0:	498a8a93          	addi	s5,s5,1176 # ffffffffc0207f44 <syscalls+0x13c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205ab4:	00002b97          	auipc	s7,0x2
ffffffffc0205ab8:	6acb8b93          	addi	s7,s7,1708 # ffffffffc0208160 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205abc:	000d4503          	lbu	a0,0(s10)
ffffffffc0205ac0:	001d0413          	addi	s0,s10,1
ffffffffc0205ac4:	01350a63          	beq	a0,s3,ffffffffc0205ad8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205ac8:	c121                	beqz	a0,ffffffffc0205b08 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205aca:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205acc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205ace:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205ad0:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205ad4:	ff351ae3          	bne	a0,s3,ffffffffc0205ac8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205ad8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205adc:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205ae0:	4c81                	li	s9,0
ffffffffc0205ae2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205ae4:	5c7d                	li	s8,-1
ffffffffc0205ae6:	5dfd                	li	s11,-1
ffffffffc0205ae8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205aec:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205aee:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205af2:	0ff5f593          	zext.b	a1,a1
ffffffffc0205af6:	00140d13          	addi	s10,s0,1
ffffffffc0205afa:	04b56263          	bltu	a0,a1,ffffffffc0205b3e <vprintfmt+0xbc>
ffffffffc0205afe:	058a                	slli	a1,a1,0x2
ffffffffc0205b00:	95d6                	add	a1,a1,s5
ffffffffc0205b02:	4194                	lw	a3,0(a1)
ffffffffc0205b04:	96d6                	add	a3,a3,s5
ffffffffc0205b06:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205b08:	70e6                	ld	ra,120(sp)
ffffffffc0205b0a:	7446                	ld	s0,112(sp)
ffffffffc0205b0c:	74a6                	ld	s1,104(sp)
ffffffffc0205b0e:	7906                	ld	s2,96(sp)
ffffffffc0205b10:	69e6                	ld	s3,88(sp)
ffffffffc0205b12:	6a46                	ld	s4,80(sp)
ffffffffc0205b14:	6aa6                	ld	s5,72(sp)
ffffffffc0205b16:	6b06                	ld	s6,64(sp)
ffffffffc0205b18:	7be2                	ld	s7,56(sp)
ffffffffc0205b1a:	7c42                	ld	s8,48(sp)
ffffffffc0205b1c:	7ca2                	ld	s9,40(sp)
ffffffffc0205b1e:	7d02                	ld	s10,32(sp)
ffffffffc0205b20:	6de2                	ld	s11,24(sp)
ffffffffc0205b22:	6109                	addi	sp,sp,128
ffffffffc0205b24:	8082                	ret
            padc = '0';
ffffffffc0205b26:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205b28:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b2c:	846a                	mv	s0,s10
ffffffffc0205b2e:	00140d13          	addi	s10,s0,1
ffffffffc0205b32:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205b36:	0ff5f593          	zext.b	a1,a1
ffffffffc0205b3a:	fcb572e3          	bgeu	a0,a1,ffffffffc0205afe <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205b3e:	85a6                	mv	a1,s1
ffffffffc0205b40:	02500513          	li	a0,37
ffffffffc0205b44:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205b46:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205b4a:	8d22                	mv	s10,s0
ffffffffc0205b4c:	f73788e3          	beq	a5,s3,ffffffffc0205abc <vprintfmt+0x3a>
ffffffffc0205b50:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205b54:	1d7d                	addi	s10,s10,-1
ffffffffc0205b56:	ff379de3          	bne	a5,s3,ffffffffc0205b50 <vprintfmt+0xce>
ffffffffc0205b5a:	b78d                	j	ffffffffc0205abc <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205b5c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205b60:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b64:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205b66:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205b6a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205b6e:	02d86463          	bltu	a6,a3,ffffffffc0205b96 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205b72:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205b76:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205b7a:	0186873b          	addw	a4,a3,s8
ffffffffc0205b7e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205b82:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205b84:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205b88:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205b8a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205b8e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205b92:	fed870e3          	bgeu	a6,a3,ffffffffc0205b72 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205b96:	f40ddce3          	bgez	s11,ffffffffc0205aee <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205b9a:	8de2                	mv	s11,s8
ffffffffc0205b9c:	5c7d                	li	s8,-1
ffffffffc0205b9e:	bf81                	j	ffffffffc0205aee <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205ba0:	fffdc693          	not	a3,s11
ffffffffc0205ba4:	96fd                	srai	a3,a3,0x3f
ffffffffc0205ba6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205baa:	00144603          	lbu	a2,1(s0)
ffffffffc0205bae:	2d81                	sext.w	s11,s11
ffffffffc0205bb0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205bb2:	bf35                	j	ffffffffc0205aee <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205bb4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205bb8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205bbc:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205bbe:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205bc0:	bfd9                	j	ffffffffc0205b96 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205bc2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205bc4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205bc8:	01174463          	blt	a4,a7,ffffffffc0205bd0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205bcc:	1a088e63          	beqz	a7,ffffffffc0205d88 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205bd0:	000a3603          	ld	a2,0(s4)
ffffffffc0205bd4:	46c1                	li	a3,16
ffffffffc0205bd6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205bd8:	2781                	sext.w	a5,a5
ffffffffc0205bda:	876e                	mv	a4,s11
ffffffffc0205bdc:	85a6                	mv	a1,s1
ffffffffc0205bde:	854a                	mv	a0,s2
ffffffffc0205be0:	e37ff0ef          	jal	ra,ffffffffc0205a16 <printnum>
            break;
ffffffffc0205be4:	bde1                	j	ffffffffc0205abc <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205be6:	000a2503          	lw	a0,0(s4)
ffffffffc0205bea:	85a6                	mv	a1,s1
ffffffffc0205bec:	0a21                	addi	s4,s4,8
ffffffffc0205bee:	9902                	jalr	s2
            break;
ffffffffc0205bf0:	b5f1                	j	ffffffffc0205abc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205bf2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205bf4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205bf8:	01174463          	blt	a4,a7,ffffffffc0205c00 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205bfc:	18088163          	beqz	a7,ffffffffc0205d7e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205c00:	000a3603          	ld	a2,0(s4)
ffffffffc0205c04:	46a9                	li	a3,10
ffffffffc0205c06:	8a2e                	mv	s4,a1
ffffffffc0205c08:	bfc1                	j	ffffffffc0205bd8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205c0a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205c0e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205c10:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205c12:	bdf1                	j	ffffffffc0205aee <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205c14:	85a6                	mv	a1,s1
ffffffffc0205c16:	02500513          	li	a0,37
ffffffffc0205c1a:	9902                	jalr	s2
            break;
ffffffffc0205c1c:	b545                	j	ffffffffc0205abc <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205c1e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205c22:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205c24:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205c26:	b5e1                	j	ffffffffc0205aee <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205c28:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205c2a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205c2e:	01174463          	blt	a4,a7,ffffffffc0205c36 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205c32:	14088163          	beqz	a7,ffffffffc0205d74 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205c36:	000a3603          	ld	a2,0(s4)
ffffffffc0205c3a:	46a1                	li	a3,8
ffffffffc0205c3c:	8a2e                	mv	s4,a1
ffffffffc0205c3e:	bf69                	j	ffffffffc0205bd8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205c40:	03000513          	li	a0,48
ffffffffc0205c44:	85a6                	mv	a1,s1
ffffffffc0205c46:	e03e                	sd	a5,0(sp)
ffffffffc0205c48:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205c4a:	85a6                	mv	a1,s1
ffffffffc0205c4c:	07800513          	li	a0,120
ffffffffc0205c50:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205c52:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205c54:	6782                	ld	a5,0(sp)
ffffffffc0205c56:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205c58:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205c5c:	bfb5                	j	ffffffffc0205bd8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205c5e:	000a3403          	ld	s0,0(s4)
ffffffffc0205c62:	008a0713          	addi	a4,s4,8
ffffffffc0205c66:	e03a                	sd	a4,0(sp)
ffffffffc0205c68:	14040263          	beqz	s0,ffffffffc0205dac <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205c6c:	0fb05763          	blez	s11,ffffffffc0205d5a <vprintfmt+0x2d8>
ffffffffc0205c70:	02d00693          	li	a3,45
ffffffffc0205c74:	0cd79163          	bne	a5,a3,ffffffffc0205d36 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205c78:	00044783          	lbu	a5,0(s0)
ffffffffc0205c7c:	0007851b          	sext.w	a0,a5
ffffffffc0205c80:	cf85                	beqz	a5,ffffffffc0205cb8 <vprintfmt+0x236>
ffffffffc0205c82:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205c86:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205c8a:	000c4563          	bltz	s8,ffffffffc0205c94 <vprintfmt+0x212>
ffffffffc0205c8e:	3c7d                	addiw	s8,s8,-1
ffffffffc0205c90:	036c0263          	beq	s8,s6,ffffffffc0205cb4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205c94:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205c96:	0e0c8e63          	beqz	s9,ffffffffc0205d92 <vprintfmt+0x310>
ffffffffc0205c9a:	3781                	addiw	a5,a5,-32
ffffffffc0205c9c:	0ef47b63          	bgeu	s0,a5,ffffffffc0205d92 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205ca0:	03f00513          	li	a0,63
ffffffffc0205ca4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205ca6:	000a4783          	lbu	a5,0(s4)
ffffffffc0205caa:	3dfd                	addiw	s11,s11,-1
ffffffffc0205cac:	0a05                	addi	s4,s4,1
ffffffffc0205cae:	0007851b          	sext.w	a0,a5
ffffffffc0205cb2:	ffe1                	bnez	a5,ffffffffc0205c8a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205cb4:	01b05963          	blez	s11,ffffffffc0205cc6 <vprintfmt+0x244>
ffffffffc0205cb8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205cba:	85a6                	mv	a1,s1
ffffffffc0205cbc:	02000513          	li	a0,32
ffffffffc0205cc0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205cc2:	fe0d9be3          	bnez	s11,ffffffffc0205cb8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205cc6:	6a02                	ld	s4,0(sp)
ffffffffc0205cc8:	bbd5                	j	ffffffffc0205abc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205cca:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205ccc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205cd0:	01174463          	blt	a4,a7,ffffffffc0205cd8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205cd4:	08088d63          	beqz	a7,ffffffffc0205d6e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205cd8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205cdc:	0a044d63          	bltz	s0,ffffffffc0205d96 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205ce0:	8622                	mv	a2,s0
ffffffffc0205ce2:	8a66                	mv	s4,s9
ffffffffc0205ce4:	46a9                	li	a3,10
ffffffffc0205ce6:	bdcd                	j	ffffffffc0205bd8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205ce8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205cec:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205cee:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205cf0:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205cf4:	8fb5                	xor	a5,a5,a3
ffffffffc0205cf6:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205cfa:	02d74163          	blt	a4,a3,ffffffffc0205d1c <vprintfmt+0x29a>
ffffffffc0205cfe:	00369793          	slli	a5,a3,0x3
ffffffffc0205d02:	97de                	add	a5,a5,s7
ffffffffc0205d04:	639c                	ld	a5,0(a5)
ffffffffc0205d06:	cb99                	beqz	a5,ffffffffc0205d1c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205d08:	86be                	mv	a3,a5
ffffffffc0205d0a:	00000617          	auipc	a2,0x0
ffffffffc0205d0e:	13e60613          	addi	a2,a2,318 # ffffffffc0205e48 <etext+0x2e>
ffffffffc0205d12:	85a6                	mv	a1,s1
ffffffffc0205d14:	854a                	mv	a0,s2
ffffffffc0205d16:	0ce000ef          	jal	ra,ffffffffc0205de4 <printfmt>
ffffffffc0205d1a:	b34d                	j	ffffffffc0205abc <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205d1c:	00002617          	auipc	a2,0x2
ffffffffc0205d20:	21c60613          	addi	a2,a2,540 # ffffffffc0207f38 <syscalls+0x130>
ffffffffc0205d24:	85a6                	mv	a1,s1
ffffffffc0205d26:	854a                	mv	a0,s2
ffffffffc0205d28:	0bc000ef          	jal	ra,ffffffffc0205de4 <printfmt>
ffffffffc0205d2c:	bb41                	j	ffffffffc0205abc <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205d2e:	00002417          	auipc	s0,0x2
ffffffffc0205d32:	20240413          	addi	s0,s0,514 # ffffffffc0207f30 <syscalls+0x128>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205d36:	85e2                	mv	a1,s8
ffffffffc0205d38:	8522                	mv	a0,s0
ffffffffc0205d3a:	e43e                	sd	a5,8(sp)
ffffffffc0205d3c:	c29ff0ef          	jal	ra,ffffffffc0205964 <strnlen>
ffffffffc0205d40:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205d44:	01b05b63          	blez	s11,ffffffffc0205d5a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205d48:	67a2                	ld	a5,8(sp)
ffffffffc0205d4a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205d4e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205d50:	85a6                	mv	a1,s1
ffffffffc0205d52:	8552                	mv	a0,s4
ffffffffc0205d54:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205d56:	fe0d9ce3          	bnez	s11,ffffffffc0205d4e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205d5a:	00044783          	lbu	a5,0(s0)
ffffffffc0205d5e:	00140a13          	addi	s4,s0,1
ffffffffc0205d62:	0007851b          	sext.w	a0,a5
ffffffffc0205d66:	d3a5                	beqz	a5,ffffffffc0205cc6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205d68:	05e00413          	li	s0,94
ffffffffc0205d6c:	bf39                	j	ffffffffc0205c8a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205d6e:	000a2403          	lw	s0,0(s4)
ffffffffc0205d72:	b7ad                	j	ffffffffc0205cdc <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205d74:	000a6603          	lwu	a2,0(s4)
ffffffffc0205d78:	46a1                	li	a3,8
ffffffffc0205d7a:	8a2e                	mv	s4,a1
ffffffffc0205d7c:	bdb1                	j	ffffffffc0205bd8 <vprintfmt+0x156>
ffffffffc0205d7e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205d82:	46a9                	li	a3,10
ffffffffc0205d84:	8a2e                	mv	s4,a1
ffffffffc0205d86:	bd89                	j	ffffffffc0205bd8 <vprintfmt+0x156>
ffffffffc0205d88:	000a6603          	lwu	a2,0(s4)
ffffffffc0205d8c:	46c1                	li	a3,16
ffffffffc0205d8e:	8a2e                	mv	s4,a1
ffffffffc0205d90:	b5a1                	j	ffffffffc0205bd8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205d92:	9902                	jalr	s2
ffffffffc0205d94:	bf09                	j	ffffffffc0205ca6 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205d96:	85a6                	mv	a1,s1
ffffffffc0205d98:	02d00513          	li	a0,45
ffffffffc0205d9c:	e03e                	sd	a5,0(sp)
ffffffffc0205d9e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205da0:	6782                	ld	a5,0(sp)
ffffffffc0205da2:	8a66                	mv	s4,s9
ffffffffc0205da4:	40800633          	neg	a2,s0
ffffffffc0205da8:	46a9                	li	a3,10
ffffffffc0205daa:	b53d                	j	ffffffffc0205bd8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205dac:	03b05163          	blez	s11,ffffffffc0205dce <vprintfmt+0x34c>
ffffffffc0205db0:	02d00693          	li	a3,45
ffffffffc0205db4:	f6d79de3          	bne	a5,a3,ffffffffc0205d2e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205db8:	00002417          	auipc	s0,0x2
ffffffffc0205dbc:	17840413          	addi	s0,s0,376 # ffffffffc0207f30 <syscalls+0x128>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205dc0:	02800793          	li	a5,40
ffffffffc0205dc4:	02800513          	li	a0,40
ffffffffc0205dc8:	00140a13          	addi	s4,s0,1
ffffffffc0205dcc:	bd6d                	j	ffffffffc0205c86 <vprintfmt+0x204>
ffffffffc0205dce:	00002a17          	auipc	s4,0x2
ffffffffc0205dd2:	163a0a13          	addi	s4,s4,355 # ffffffffc0207f31 <syscalls+0x129>
ffffffffc0205dd6:	02800513          	li	a0,40
ffffffffc0205dda:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205dde:	05e00413          	li	s0,94
ffffffffc0205de2:	b565                	j	ffffffffc0205c8a <vprintfmt+0x208>

ffffffffc0205de4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205de4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205de6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205dea:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205dec:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205dee:	ec06                	sd	ra,24(sp)
ffffffffc0205df0:	f83a                	sd	a4,48(sp)
ffffffffc0205df2:	fc3e                	sd	a5,56(sp)
ffffffffc0205df4:	e0c2                	sd	a6,64(sp)
ffffffffc0205df6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205df8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205dfa:	c89ff0ef          	jal	ra,ffffffffc0205a82 <vprintfmt>
}
ffffffffc0205dfe:	60e2                	ld	ra,24(sp)
ffffffffc0205e00:	6161                	addi	sp,sp,80
ffffffffc0205e02:	8082                	ret

ffffffffc0205e04 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205e04:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205e08:	2785                	addiw	a5,a5,1
ffffffffc0205e0a:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205e0e:	02000793          	li	a5,32
ffffffffc0205e12:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205e14:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205e18:	8082                	ret
