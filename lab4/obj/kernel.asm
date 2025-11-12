
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

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
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fde50513          	addi	a0,a0,-34 # ffffffffc0209028 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	48a60613          	addi	a2,a2,1162 # ffffffffc020d4dc <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	572030ef          	jal	ra,ffffffffc02035d4 <memset>
    dtb_init();
ffffffffc0200066:	452000ef          	jal	ra,ffffffffc02004b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	039000ef          	jal	ra,ffffffffc02008a2 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	9ba58593          	addi	a1,a1,-1606 # ffffffffc0203a28 <etext+0x2>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	9d250513          	addi	a0,a0,-1582 # ffffffffc0203a48 <etext+0x22>
ffffffffc020007e:	062000ef          	jal	ra,ffffffffc02000e0 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1b8000ef          	jal	ra,ffffffffc020023a <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	1dc010ef          	jal	ra,ffffffffc0201262 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	08b000ef          	jal	ra,ffffffffc0200914 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	095000ef          	jal	ra,ffffffffc0200922 <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	745010ef          	jal	ra,ffffffffc0201fd6 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	19a030ef          	jal	ra,ffffffffc0203230 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	7ce000ef          	jal	ra,ffffffffc0200868 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	079000ef          	jal	ra,ffffffffc0200916 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	3e0030ef          	jal	ra,ffffffffc0203482 <cpu_idle>

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
ffffffffc02000ae:	7f6000ef          	jal	ra,ffffffffc02008a4 <cons_putc>
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
ffffffffc02000d4:	5ba030ef          	jal	ra,ffffffffc020368e <vprintfmt>
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
ffffffffc02000e2:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
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
ffffffffc020010a:	584030ef          	jal	ra,ffffffffc020368e <vprintfmt>
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
ffffffffc0200116:	78e0006f          	j	ffffffffc02008a4 <cons_putc>

ffffffffc020011a <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020011e:	7ba000ef          	jal	ra,ffffffffc02008d8 <cons_getc>
ffffffffc0200122:	dd75                	beqz	a0,ffffffffc020011e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200124:	60a2                	ld	ra,8(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020012a:	715d                	addi	sp,sp,-80
ffffffffc020012c:	e486                	sd	ra,72(sp)
ffffffffc020012e:	e0a6                	sd	s1,64(sp)
ffffffffc0200130:	fc4a                	sd	s2,56(sp)
ffffffffc0200132:	f84e                	sd	s3,48(sp)
ffffffffc0200134:	f452                	sd	s4,40(sp)
ffffffffc0200136:	f056                	sd	s5,32(sp)
ffffffffc0200138:	ec5a                	sd	s6,24(sp)
ffffffffc020013a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc020013c:	c901                	beqz	a0,ffffffffc020014c <readline+0x22>
ffffffffc020013e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0200140:	00004517          	auipc	a0,0x4
ffffffffc0200144:	91050513          	addi	a0,a0,-1776 # ffffffffc0203a50 <etext+0x2a>
ffffffffc0200148:	f99ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
readline(const char *prompt) {
ffffffffc020014c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020014e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200150:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200152:	4aa9                	li	s5,10
ffffffffc0200154:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200156:	00009b97          	auipc	s7,0x9
ffffffffc020015a:	ed2b8b93          	addi	s7,s7,-302 # ffffffffc0209028 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020015e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0200162:	fb9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200166:	00054a63          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020016a:	00a95a63          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc020016e:	029a5263          	bge	s4,s1,ffffffffc0200192 <readline+0x68>
        c = getchar();
ffffffffc0200172:	fa9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200176:	fe055ae3          	bgez	a0,ffffffffc020016a <readline+0x40>
            return NULL;
ffffffffc020017a:	4501                	li	a0,0
ffffffffc020017c:	a091                	j	ffffffffc02001c0 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020017e:	03351463          	bne	a0,s3,ffffffffc02001a6 <readline+0x7c>
ffffffffc0200182:	e8a9                	bnez	s1,ffffffffc02001d4 <readline+0xaa>
        c = getchar();
ffffffffc0200184:	f97ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200188:	fe0549e3          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020018c:	fea959e3          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc0200190:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200192:	e42a                	sd	a0,8(sp)
ffffffffc0200194:	f83ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i ++] = c;
ffffffffc0200198:	6522                	ld	a0,8(sp)
ffffffffc020019a:	009b87b3          	add	a5,s7,s1
ffffffffc020019e:	2485                	addiw	s1,s1,1
ffffffffc02001a0:	00a78023          	sb	a0,0(a5)
ffffffffc02001a4:	bf7d                	j	ffffffffc0200162 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001a6:	01550463          	beq	a0,s5,ffffffffc02001ae <readline+0x84>
ffffffffc02001aa:	fb651ce3          	bne	a0,s6,ffffffffc0200162 <readline+0x38>
            cputchar(c);
ffffffffc02001ae:	f69ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i] = '\0';
ffffffffc02001b2:	00009517          	auipc	a0,0x9
ffffffffc02001b6:	e7650513          	addi	a0,a0,-394 # ffffffffc0209028 <buf>
ffffffffc02001ba:	94aa                	add	s1,s1,a0
ffffffffc02001bc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001c0:	60a6                	ld	ra,72(sp)
ffffffffc02001c2:	6486                	ld	s1,64(sp)
ffffffffc02001c4:	7962                	ld	s2,56(sp)
ffffffffc02001c6:	79c2                	ld	s3,48(sp)
ffffffffc02001c8:	7a22                	ld	s4,40(sp)
ffffffffc02001ca:	7a82                	ld	s5,32(sp)
ffffffffc02001cc:	6b62                	ld	s6,24(sp)
ffffffffc02001ce:	6bc2                	ld	s7,16(sp)
ffffffffc02001d0:	6161                	addi	sp,sp,80
ffffffffc02001d2:	8082                	ret
            cputchar(c);
ffffffffc02001d4:	4521                	li	a0,8
ffffffffc02001d6:	f41ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            i --;
ffffffffc02001da:	34fd                	addiw	s1,s1,-1
ffffffffc02001dc:	b759                	j	ffffffffc0200162 <readline+0x38>

ffffffffc02001de <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001de:	0000d317          	auipc	t1,0xd
ffffffffc02001e2:	28230313          	addi	t1,t1,642 # ffffffffc020d460 <is_panic>
ffffffffc02001e6:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ea:	715d                	addi	sp,sp,-80
ffffffffc02001ec:	ec06                	sd	ra,24(sp)
ffffffffc02001ee:	e822                	sd	s0,16(sp)
ffffffffc02001f0:	f436                	sd	a3,40(sp)
ffffffffc02001f2:	f83a                	sd	a4,48(sp)
ffffffffc02001f4:	fc3e                	sd	a5,56(sp)
ffffffffc02001f6:	e0c2                	sd	a6,64(sp)
ffffffffc02001f8:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001fa:	020e1a63          	bnez	t3,ffffffffc020022e <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001fe:	4785                	li	a5,1
ffffffffc0200200:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200204:	8432                	mv	s0,a2
ffffffffc0200206:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200208:	862e                	mv	a2,a1
ffffffffc020020a:	85aa                	mv	a1,a0
ffffffffc020020c:	00004517          	auipc	a0,0x4
ffffffffc0200210:	84c50513          	addi	a0,a0,-1972 # ffffffffc0203a58 <etext+0x32>
    va_start(ap, fmt);
ffffffffc0200214:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200216:	ecbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020021a:	65a2                	ld	a1,8(sp)
ffffffffc020021c:	8522                	mv	a0,s0
ffffffffc020021e:	ea3ff0ef          	jal	ra,ffffffffc02000c0 <vcprintf>
    cprintf("\n");
ffffffffc0200222:	00004517          	auipc	a0,0x4
ffffffffc0200226:	70650513          	addi	a0,a0,1798 # ffffffffc0204928 <commands+0xc78>
ffffffffc020022a:	eb7ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020022e:	6ee000ef          	jal	ra,ffffffffc020091c <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200232:	4501                	li	a0,0
ffffffffc0200234:	130000ef          	jal	ra,ffffffffc0200364 <kmonitor>
    while (1) {
ffffffffc0200238:	bfed                	j	ffffffffc0200232 <__panic+0x54>

ffffffffc020023a <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020023a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020023c:	00004517          	auipc	a0,0x4
ffffffffc0200240:	83c50513          	addi	a0,a0,-1988 # ffffffffc0203a78 <etext+0x52>
{
ffffffffc0200244:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200246:	e9bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020024a:	00000597          	auipc	a1,0x0
ffffffffc020024e:	e0058593          	addi	a1,a1,-512 # ffffffffc020004a <kern_init>
ffffffffc0200252:	00004517          	auipc	a0,0x4
ffffffffc0200256:	84650513          	addi	a0,a0,-1978 # ffffffffc0203a98 <etext+0x72>
ffffffffc020025a:	e87ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020025e:	00003597          	auipc	a1,0x3
ffffffffc0200262:	7c858593          	addi	a1,a1,1992 # ffffffffc0203a26 <etext>
ffffffffc0200266:	00004517          	auipc	a0,0x4
ffffffffc020026a:	85250513          	addi	a0,a0,-1966 # ffffffffc0203ab8 <etext+0x92>
ffffffffc020026e:	e73ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200272:	00009597          	auipc	a1,0x9
ffffffffc0200276:	db658593          	addi	a1,a1,-586 # ffffffffc0209028 <buf>
ffffffffc020027a:	00004517          	auipc	a0,0x4
ffffffffc020027e:	85e50513          	addi	a0,a0,-1954 # ffffffffc0203ad8 <etext+0xb2>
ffffffffc0200282:	e5fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200286:	0000d597          	auipc	a1,0xd
ffffffffc020028a:	25658593          	addi	a1,a1,598 # ffffffffc020d4dc <end>
ffffffffc020028e:	00004517          	auipc	a0,0x4
ffffffffc0200292:	86a50513          	addi	a0,a0,-1942 # ffffffffc0203af8 <etext+0xd2>
ffffffffc0200296:	e4bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020029a:	0000d597          	auipc	a1,0xd
ffffffffc020029e:	64158593          	addi	a1,a1,1601 # ffffffffc020d8db <end+0x3ff>
ffffffffc02002a2:	00000797          	auipc	a5,0x0
ffffffffc02002a6:	da878793          	addi	a5,a5,-600 # ffffffffc020004a <kern_init>
ffffffffc02002aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002b8:	95be                	add	a1,a1,a5
ffffffffc02002ba:	85a9                	srai	a1,a1,0xa
ffffffffc02002bc:	00004517          	auipc	a0,0x4
ffffffffc02002c0:	85c50513          	addi	a0,a0,-1956 # ffffffffc0203b18 <etext+0xf2>
}
ffffffffc02002c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002c6:	bd29                	j	ffffffffc02000e0 <cprintf>

ffffffffc02002c8 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002c8:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ca:	00004617          	auipc	a2,0x4
ffffffffc02002ce:	87e60613          	addi	a2,a2,-1922 # ffffffffc0203b48 <etext+0x122>
ffffffffc02002d2:	04900593          	li	a1,73
ffffffffc02002d6:	00004517          	auipc	a0,0x4
ffffffffc02002da:	88a50513          	addi	a0,a0,-1910 # ffffffffc0203b60 <etext+0x13a>
{
ffffffffc02002de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002e0:	effff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02002e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	00004617          	auipc	a2,0x4
ffffffffc02002ea:	89260613          	addi	a2,a2,-1902 # ffffffffc0203b78 <etext+0x152>
ffffffffc02002ee:	00004597          	auipc	a1,0x4
ffffffffc02002f2:	8aa58593          	addi	a1,a1,-1878 # ffffffffc0203b98 <etext+0x172>
ffffffffc02002f6:	00004517          	auipc	a0,0x4
ffffffffc02002fa:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0203ba0 <etext+0x17a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200300:	de1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200304:	00004617          	auipc	a2,0x4
ffffffffc0200308:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0203bb0 <etext+0x18a>
ffffffffc020030c:	00004597          	auipc	a1,0x4
ffffffffc0200310:	8cc58593          	addi	a1,a1,-1844 # ffffffffc0203bd8 <etext+0x1b2>
ffffffffc0200314:	00004517          	auipc	a0,0x4
ffffffffc0200318:	88c50513          	addi	a0,a0,-1908 # ffffffffc0203ba0 <etext+0x17a>
ffffffffc020031c:	dc5ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200320:	00004617          	auipc	a2,0x4
ffffffffc0200324:	8c860613          	addi	a2,a2,-1848 # ffffffffc0203be8 <etext+0x1c2>
ffffffffc0200328:	00004597          	auipc	a1,0x4
ffffffffc020032c:	8e058593          	addi	a1,a1,-1824 # ffffffffc0203c08 <etext+0x1e2>
ffffffffc0200330:	00004517          	auipc	a0,0x4
ffffffffc0200334:	87050513          	addi	a0,a0,-1936 # ffffffffc0203ba0 <etext+0x17a>
ffffffffc0200338:	da9ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    return 0;
}
ffffffffc020033c:	60a2                	ld	ra,8(sp)
ffffffffc020033e:	4501                	li	a0,0
ffffffffc0200340:	0141                	addi	sp,sp,16
ffffffffc0200342:	8082                	ret

ffffffffc0200344 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200344:	1141                	addi	sp,sp,-16
ffffffffc0200346:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200348:	ef3ff0ef          	jal	ra,ffffffffc020023a <print_kerninfo>
    return 0;
}
ffffffffc020034c:	60a2                	ld	ra,8(sp)
ffffffffc020034e:	4501                	li	a0,0
ffffffffc0200350:	0141                	addi	sp,sp,16
ffffffffc0200352:	8082                	ret

ffffffffc0200354 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200354:	1141                	addi	sp,sp,-16
ffffffffc0200356:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200358:	f71ff0ef          	jal	ra,ffffffffc02002c8 <print_stackframe>
    return 0;
}
ffffffffc020035c:	60a2                	ld	ra,8(sp)
ffffffffc020035e:	4501                	li	a0,0
ffffffffc0200360:	0141                	addi	sp,sp,16
ffffffffc0200362:	8082                	ret

ffffffffc0200364 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200364:	7115                	addi	sp,sp,-224
ffffffffc0200366:	ed5e                	sd	s7,152(sp)
ffffffffc0200368:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	00004517          	auipc	a0,0x4
ffffffffc020036e:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0203c18 <etext+0x1f2>
kmonitor(struct trapframe *tf) {
ffffffffc0200372:	ed86                	sd	ra,216(sp)
ffffffffc0200374:	e9a2                	sd	s0,208(sp)
ffffffffc0200376:	e5a6                	sd	s1,200(sp)
ffffffffc0200378:	e1ca                	sd	s2,192(sp)
ffffffffc020037a:	fd4e                	sd	s3,184(sp)
ffffffffc020037c:	f952                	sd	s4,176(sp)
ffffffffc020037e:	f556                	sd	s5,168(sp)
ffffffffc0200380:	f15a                	sd	s6,160(sp)
ffffffffc0200382:	e962                	sd	s8,144(sp)
ffffffffc0200384:	e566                	sd	s9,136(sp)
ffffffffc0200386:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200388:	d59ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020038c:	00004517          	auipc	a0,0x4
ffffffffc0200390:	8b450513          	addi	a0,a0,-1868 # ffffffffc0203c40 <etext+0x21a>
ffffffffc0200394:	d4dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    if (tf != NULL) {
ffffffffc0200398:	000b8563          	beqz	s7,ffffffffc02003a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020039c:	855e                	mv	a0,s7
ffffffffc020039e:	76c000ef          	jal	ra,ffffffffc0200b0a <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02003a2:	4501                	li	a0,0
ffffffffc02003a4:	4581                	li	a1,0
ffffffffc02003a6:	4601                	li	a2,0
ffffffffc02003a8:	48a1                	li	a7,8
ffffffffc02003aa:	00000073          	ecall
ffffffffc02003ae:	00004c17          	auipc	s8,0x4
ffffffffc02003b2:	902c0c13          	addi	s8,s8,-1790 # ffffffffc0203cb0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b6:	00004917          	auipc	s2,0x4
ffffffffc02003ba:	8b290913          	addi	s2,s2,-1870 # ffffffffc0203c68 <etext+0x242>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00004497          	auipc	s1,0x4
ffffffffc02003c2:	8b248493          	addi	s1,s1,-1870 # ffffffffc0203c70 <etext+0x24a>
        if (argc == MAXARGS - 1) {
ffffffffc02003c6:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c8:	00004b17          	auipc	s6,0x4
ffffffffc02003cc:	8b0b0b13          	addi	s6,s6,-1872 # ffffffffc0203c78 <etext+0x252>
        argv[argc ++] = buf;
ffffffffc02003d0:	00003a17          	auipc	s4,0x3
ffffffffc02003d4:	7c8a0a13          	addi	s4,s4,1992 # ffffffffc0203b98 <etext+0x172>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d8:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003da:	854a                	mv	a0,s2
ffffffffc02003dc:	d4fff0ef          	jal	ra,ffffffffc020012a <readline>
ffffffffc02003e0:	842a                	mv	s0,a0
ffffffffc02003e2:	dd65                	beqz	a0,ffffffffc02003da <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e4:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003e8:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ea:	e1bd                	bnez	a1,ffffffffc0200450 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc02003ec:	fe0c87e3          	beqz	s9,ffffffffc02003da <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f0:	6582                	ld	a1,0(sp)
ffffffffc02003f2:	00004d17          	auipc	s10,0x4
ffffffffc02003f6:	8bed0d13          	addi	s10,s10,-1858 # ffffffffc0203cb0 <commands>
        argv[argc ++] = buf;
ffffffffc02003fa:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003fc:	4401                	li	s0,0
ffffffffc02003fe:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200400:	17a030ef          	jal	ra,ffffffffc020357a <strcmp>
ffffffffc0200404:	c919                	beqz	a0,ffffffffc020041a <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200406:	2405                	addiw	s0,s0,1
ffffffffc0200408:	0b540063          	beq	s0,s5,ffffffffc02004a8 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020040c:	000d3503          	ld	a0,0(s10)
ffffffffc0200410:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200412:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200414:	166030ef          	jal	ra,ffffffffc020357a <strcmp>
ffffffffc0200418:	f57d                	bnez	a0,ffffffffc0200406 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97e2                	add	a5,a5,s8
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	865e                	mv	a2,s7
ffffffffc0200428:	002c                	addi	a1,sp,8
ffffffffc020042a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200430:	fa0555e3          	bgez	a0,ffffffffc02003da <kmonitor+0x76>
}
ffffffffc0200434:	60ee                	ld	ra,216(sp)
ffffffffc0200436:	644e                	ld	s0,208(sp)
ffffffffc0200438:	64ae                	ld	s1,200(sp)
ffffffffc020043a:	690e                	ld	s2,192(sp)
ffffffffc020043c:	79ea                	ld	s3,184(sp)
ffffffffc020043e:	7a4a                	ld	s4,176(sp)
ffffffffc0200440:	7aaa                	ld	s5,168(sp)
ffffffffc0200442:	7b0a                	ld	s6,160(sp)
ffffffffc0200444:	6bea                	ld	s7,152(sp)
ffffffffc0200446:	6c4a                	ld	s8,144(sp)
ffffffffc0200448:	6caa                	ld	s9,136(sp)
ffffffffc020044a:	6d0a                	ld	s10,128(sp)
ffffffffc020044c:	612d                	addi	sp,sp,224
ffffffffc020044e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200450:	8526                	mv	a0,s1
ffffffffc0200452:	16c030ef          	jal	ra,ffffffffc02035be <strchr>
ffffffffc0200456:	c901                	beqz	a0,ffffffffc0200466 <kmonitor+0x102>
ffffffffc0200458:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020045c:	00040023          	sb	zero,0(s0)
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200462:	d5c9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc0200464:	b7f5                	j	ffffffffc0200450 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200466:	00044783          	lbu	a5,0(s0)
ffffffffc020046a:	d3c9                	beqz	a5,ffffffffc02003ec <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020046c:	033c8963          	beq	s9,s3,ffffffffc020049e <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200470:	003c9793          	slli	a5,s9,0x3
ffffffffc0200474:	0118                	addi	a4,sp,128
ffffffffc0200476:	97ba                	add	a5,a5,a4
ffffffffc0200478:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020047c:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200480:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200482:	e591                	bnez	a1,ffffffffc020048e <kmonitor+0x12a>
ffffffffc0200484:	b7b5                	j	ffffffffc02003f0 <kmonitor+0x8c>
ffffffffc0200486:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020048a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020048c:	d1a5                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020048e:	8526                	mv	a0,s1
ffffffffc0200490:	12e030ef          	jal	ra,ffffffffc02035be <strchr>
ffffffffc0200494:	d96d                	beqz	a0,ffffffffc0200486 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200496:	00044583          	lbu	a1,0(s0)
ffffffffc020049a:	d9a9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020049c:	bf55                	j	ffffffffc0200450 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020049e:	45c1                	li	a1,16
ffffffffc02004a0:	855a                	mv	a0,s6
ffffffffc02004a2:	c3fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02004a6:	b7e9                	j	ffffffffc0200470 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02004a8:	6582                	ld	a1,0(sp)
ffffffffc02004aa:	00003517          	auipc	a0,0x3
ffffffffc02004ae:	7ee50513          	addi	a0,a0,2030 # ffffffffc0203c98 <etext+0x272>
ffffffffc02004b2:	c2fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
ffffffffc02004b6:	b715                	j	ffffffffc02003da <kmonitor+0x76>

ffffffffc02004b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004b8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004ba:	00004517          	auipc	a0,0x4
ffffffffc02004be:	83e50513          	addi	a0,a0,-1986 # ffffffffc0203cf8 <commands+0x48>
void dtb_init(void) {
ffffffffc02004c2:	fc86                	sd	ra,120(sp)
ffffffffc02004c4:	f8a2                	sd	s0,112(sp)
ffffffffc02004c6:	e8d2                	sd	s4,80(sp)
ffffffffc02004c8:	f4a6                	sd	s1,104(sp)
ffffffffc02004ca:	f0ca                	sd	s2,96(sp)
ffffffffc02004cc:	ecce                	sd	s3,88(sp)
ffffffffc02004ce:	e4d6                	sd	s5,72(sp)
ffffffffc02004d0:	e0da                	sd	s6,64(sp)
ffffffffc02004d2:	fc5e                	sd	s7,56(sp)
ffffffffc02004d4:	f862                	sd	s8,48(sp)
ffffffffc02004d6:	f466                	sd	s9,40(sp)
ffffffffc02004d8:	f06a                	sd	s10,32(sp)
ffffffffc02004da:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004dc:	c05ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004e0:	00009597          	auipc	a1,0x9
ffffffffc02004e4:	b205b583          	ld	a1,-1248(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02004e8:	00004517          	auipc	a0,0x4
ffffffffc02004ec:	82050513          	addi	a0,a0,-2016 # ffffffffc0203d08 <commands+0x58>
ffffffffc02004f0:	bf1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004f4:	00009417          	auipc	s0,0x9
ffffffffc02004f8:	b1440413          	addi	s0,s0,-1260 # ffffffffc0209008 <boot_dtb>
ffffffffc02004fc:	600c                	ld	a1,0(s0)
ffffffffc02004fe:	00004517          	auipc	a0,0x4
ffffffffc0200502:	81a50513          	addi	a0,a0,-2022 # ffffffffc0203d18 <commands+0x68>
ffffffffc0200506:	bdbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020050a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020050e:	00004517          	auipc	a0,0x4
ffffffffc0200512:	82250513          	addi	a0,a0,-2014 # ffffffffc0203d30 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc0200516:	120a0463          	beqz	s4,ffffffffc020063e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020051a:	57f5                	li	a5,-3
ffffffffc020051c:	07fa                	slli	a5,a5,0x1e
ffffffffc020051e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200522:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200540:	8ec9                	or	a3,a3,a0
ffffffffc0200542:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200546:	1b7d                	addi	s6,s6,-1
ffffffffc0200548:	0167f7b3          	and	a5,a5,s6
ffffffffc020054c:	8dd5                	or	a1,a1,a3
ffffffffc020054e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200550:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200556:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a11>
ffffffffc020055a:	10f59163          	bne	a1,a5,ffffffffc020065c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020055e:	471c                	lw	a5,8(a4)
ffffffffc0200560:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200562:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200568:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020056c:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200574:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200578:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200580:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200584:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200588:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058c:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	01146433          	or	s0,s0,a7
ffffffffc0200592:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200596:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059c:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005a0:	8c49                	or	s0,s0,a0
ffffffffc02005a2:	0166f6b3          	and	a3,a3,s6
ffffffffc02005a6:	00ca6a33          	or	s4,s4,a2
ffffffffc02005aa:	0167f7b3          	and	a5,a5,s6
ffffffffc02005ae:	8c55                	or	s0,s0,a3
ffffffffc02005b0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005ba:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005be:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005c0:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005c6:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005c8:	00003917          	auipc	s2,0x3
ffffffffc02005cc:	7b890913          	addi	s2,s2,1976 # ffffffffc0203d80 <commands+0xd0>
ffffffffc02005d0:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005d2:	4d91                	li	s11,4
ffffffffc02005d4:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d6:	00003497          	auipc	s1,0x3
ffffffffc02005da:	7a248493          	addi	s1,s1,1954 # ffffffffc0203d78 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005de:	000a2703          	lw	a4,0(s4)
ffffffffc02005e2:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005ea:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f2:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f6:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005fa:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fc:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200600:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200604:	8fd5                	or	a5,a5,a3
ffffffffc0200606:	00eb7733          	and	a4,s6,a4
ffffffffc020060a:	8fd9                	or	a5,a5,a4
ffffffffc020060c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020060e:	09778c63          	beq	a5,s7,ffffffffc02006a6 <dtb_init+0x1ee>
ffffffffc0200612:	00fbea63          	bltu	s7,a5,ffffffffc0200626 <dtb_init+0x16e>
ffffffffc0200616:	07a78663          	beq	a5,s10,ffffffffc0200682 <dtb_init+0x1ca>
ffffffffc020061a:	4709                	li	a4,2
ffffffffc020061c:	00e79763          	bne	a5,a4,ffffffffc020062a <dtb_init+0x172>
ffffffffc0200620:	4c81                	li	s9,0
ffffffffc0200622:	8a56                	mv	s4,s5
ffffffffc0200624:	bf6d                	j	ffffffffc02005de <dtb_init+0x126>
ffffffffc0200626:	ffb78ee3          	beq	a5,s11,ffffffffc0200622 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020062a:	00003517          	auipc	a0,0x3
ffffffffc020062e:	7ce50513          	addi	a0,a0,1998 # ffffffffc0203df8 <commands+0x148>
ffffffffc0200632:	aafff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200636:	00003517          	auipc	a0,0x3
ffffffffc020063a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0203e30 <commands+0x180>
}
ffffffffc020063e:	7446                	ld	s0,112(sp)
ffffffffc0200640:	70e6                	ld	ra,120(sp)
ffffffffc0200642:	74a6                	ld	s1,104(sp)
ffffffffc0200644:	7906                	ld	s2,96(sp)
ffffffffc0200646:	69e6                	ld	s3,88(sp)
ffffffffc0200648:	6a46                	ld	s4,80(sp)
ffffffffc020064a:	6aa6                	ld	s5,72(sp)
ffffffffc020064c:	6b06                	ld	s6,64(sp)
ffffffffc020064e:	7be2                	ld	s7,56(sp)
ffffffffc0200650:	7c42                	ld	s8,48(sp)
ffffffffc0200652:	7ca2                	ld	s9,40(sp)
ffffffffc0200654:	7d02                	ld	s10,32(sp)
ffffffffc0200656:	6de2                	ld	s11,24(sp)
ffffffffc0200658:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020065a:	b459                	j	ffffffffc02000e0 <cprintf>
}
ffffffffc020065c:	7446                	ld	s0,112(sp)
ffffffffc020065e:	70e6                	ld	ra,120(sp)
ffffffffc0200660:	74a6                	ld	s1,104(sp)
ffffffffc0200662:	7906                	ld	s2,96(sp)
ffffffffc0200664:	69e6                	ld	s3,88(sp)
ffffffffc0200666:	6a46                	ld	s4,80(sp)
ffffffffc0200668:	6aa6                	ld	s5,72(sp)
ffffffffc020066a:	6b06                	ld	s6,64(sp)
ffffffffc020066c:	7be2                	ld	s7,56(sp)
ffffffffc020066e:	7c42                	ld	s8,48(sp)
ffffffffc0200670:	7ca2                	ld	s9,40(sp)
ffffffffc0200672:	7d02                	ld	s10,32(sp)
ffffffffc0200674:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200676:	00003517          	auipc	a0,0x3
ffffffffc020067a:	6da50513          	addi	a0,a0,1754 # ffffffffc0203d50 <commands+0xa0>
}
ffffffffc020067e:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200680:	b485                	j	ffffffffc02000e0 <cprintf>
                int name_len = strlen(name);
ffffffffc0200682:	8556                	mv	a0,s5
ffffffffc0200684:	6af020ef          	jal	ra,ffffffffc0203532 <strlen>
ffffffffc0200688:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020068a:	4619                	li	a2,6
ffffffffc020068c:	85a6                	mv	a1,s1
ffffffffc020068e:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200690:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200692:	707020ef          	jal	ra,ffffffffc0203598 <strncmp>
ffffffffc0200696:	e111                	bnez	a0,ffffffffc020069a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200698:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020069a:	0a91                	addi	s5,s5,4
ffffffffc020069c:	9ad2                	add	s5,s5,s4
ffffffffc020069e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006a2:	8a56                	mv	s4,s5
ffffffffc02006a4:	bf2d                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006aa:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ae:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006b2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006c2:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c6:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ca:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ce:	00eaeab3          	or	s5,s5,a4
ffffffffc02006d2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006d6:	00faeab3          	or	s5,s5,a5
ffffffffc02006da:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006dc:	000c9c63          	bnez	s9,ffffffffc02006f4 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006e0:	1a82                	slli	s5,s5,0x20
ffffffffc02006e2:	00368793          	addi	a5,a3,3
ffffffffc02006e6:	020ada93          	srli	s5,s5,0x20
ffffffffc02006ea:	9abe                	add	s5,s5,a5
ffffffffc02006ec:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006f0:	8a56                	mv	s4,s5
ffffffffc02006f2:	b5f5                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f4:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	85ca                	mv	a1,s2
ffffffffc02006fa:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fc:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200700:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200704:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200708:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200710:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0087979b          	slliw	a5,a5,0x8
ffffffffc020071a:	8d59                	or	a0,a0,a4
ffffffffc020071c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200720:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200722:	1502                	slli	a0,a0,0x20
ffffffffc0200724:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200726:	9522                	add	a0,a0,s0
ffffffffc0200728:	653020ef          	jal	ra,ffffffffc020357a <strcmp>
ffffffffc020072c:	66a2                	ld	a3,8(sp)
ffffffffc020072e:	f94d                	bnez	a0,ffffffffc02006e0 <dtb_init+0x228>
ffffffffc0200730:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006e0 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200734:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200738:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020073c:	00003517          	auipc	a0,0x3
ffffffffc0200740:	64c50513          	addi	a0,a0,1612 # ffffffffc0203d88 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc0200744:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200748:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020074c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200750:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200754:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200758:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200760:	0187d693          	srli	a3,a5,0x18
ffffffffc0200764:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200768:	0087579b          	srliw	a5,a4,0x8
ffffffffc020076c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200770:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200774:	010f6f33          	or	t5,t5,a6
ffffffffc0200778:	0187529b          	srliw	t0,a4,0x18
ffffffffc020077c:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	0186f6b3          	and	a3,a3,s8
ffffffffc020078c:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200790:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200794:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200798:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079c:	8361                	srli	a4,a4,0x18
ffffffffc020079e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007a6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007aa:	00cb7633          	and	a2,s6,a2
ffffffffc02007ae:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007b2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007b6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ba:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007ca:	011b78b3          	and	a7,s6,a7
ffffffffc02007ce:	005eeeb3          	or	t4,t4,t0
ffffffffc02007d2:	00c6e733          	or	a4,a3,a2
ffffffffc02007d6:	006c6c33          	or	s8,s8,t1
ffffffffc02007da:	010b76b3          	and	a3,s6,a6
ffffffffc02007de:	00bb7b33          	and	s6,s6,a1
ffffffffc02007e2:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007e6:	016c6b33          	or	s6,s8,s6
ffffffffc02007ea:	01146433          	or	s0,s0,a7
ffffffffc02007ee:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007f0:	1702                	slli	a4,a4,0x20
ffffffffc02007f2:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f4:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007f6:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f8:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007fa:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fe:	0167eb33          	or	s6,a5,s6
ffffffffc0200802:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200804:	8ddff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200808:	85a2                	mv	a1,s0
ffffffffc020080a:	00003517          	auipc	a0,0x3
ffffffffc020080e:	59e50513          	addi	a0,a0,1438 # ffffffffc0203da8 <commands+0xf8>
ffffffffc0200812:	8cfff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200816:	014b5613          	srli	a2,s6,0x14
ffffffffc020081a:	85da                	mv	a1,s6
ffffffffc020081c:	00003517          	auipc	a0,0x3
ffffffffc0200820:	5a450513          	addi	a0,a0,1444 # ffffffffc0203dc0 <commands+0x110>
ffffffffc0200824:	8bdff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200828:	008b05b3          	add	a1,s6,s0
ffffffffc020082c:	15fd                	addi	a1,a1,-1
ffffffffc020082e:	00003517          	auipc	a0,0x3
ffffffffc0200832:	5b250513          	addi	a0,a0,1458 # ffffffffc0203de0 <commands+0x130>
ffffffffc0200836:	8abff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020083a:	00003517          	auipc	a0,0x3
ffffffffc020083e:	5f650513          	addi	a0,a0,1526 # ffffffffc0203e30 <commands+0x180>
        memory_base = mem_base;
ffffffffc0200842:	0000d797          	auipc	a5,0xd
ffffffffc0200846:	c287b323          	sd	s0,-986(a5) # ffffffffc020d468 <memory_base>
        memory_size = mem_size;
ffffffffc020084a:	0000d797          	auipc	a5,0xd
ffffffffc020084e:	c367b323          	sd	s6,-986(a5) # ffffffffc020d470 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200852:	b3f5                	j	ffffffffc020063e <dtb_init+0x186>

ffffffffc0200854 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200854:	0000d517          	auipc	a0,0xd
ffffffffc0200858:	c1453503          	ld	a0,-1004(a0) # ffffffffc020d468 <memory_base>
ffffffffc020085c:	8082                	ret

ffffffffc020085e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020085e:	0000d517          	auipc	a0,0xd
ffffffffc0200862:	c1253503          	ld	a0,-1006(a0) # ffffffffc020d470 <memory_size>
ffffffffc0200866:	8082                	ret

ffffffffc0200868 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200868:	67e1                	lui	a5,0x18
ffffffffc020086a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020086e:	0000d717          	auipc	a4,0xd
ffffffffc0200872:	c0f73923          	sd	a5,-1006(a4) # ffffffffc020d480 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200876:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020087a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020087c:	953e                	add	a0,a0,a5
ffffffffc020087e:	4601                	li	a2,0
ffffffffc0200880:	4881                	li	a7,0
ffffffffc0200882:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200886:	02000793          	li	a5,32
ffffffffc020088a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020088e:	00003517          	auipc	a0,0x3
ffffffffc0200892:	5ba50513          	addi	a0,a0,1466 # ffffffffc0203e48 <commands+0x198>
    ticks = 0;
ffffffffc0200896:	0000d797          	auipc	a5,0xd
ffffffffc020089a:	be07b123          	sd	zero,-1054(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020089e:	843ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc02008a2 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02008a2:	8082                	ret

ffffffffc02008a4 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008a4:	100027f3          	csrr	a5,sstatus
ffffffffc02008a8:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02008aa:	0ff57513          	zext.b	a0,a0
ffffffffc02008ae:	e799                	bnez	a5,ffffffffc02008bc <cons_putc+0x18>
ffffffffc02008b0:	4581                	li	a1,0
ffffffffc02008b2:	4601                	li	a2,0
ffffffffc02008b4:	4885                	li	a7,1
ffffffffc02008b6:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02008ba:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02008bc:	1101                	addi	sp,sp,-32
ffffffffc02008be:	ec06                	sd	ra,24(sp)
ffffffffc02008c0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02008c2:	05a000ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc02008c6:	6522                	ld	a0,8(sp)
ffffffffc02008c8:	4581                	li	a1,0
ffffffffc02008ca:	4601                	li	a2,0
ffffffffc02008cc:	4885                	li	a7,1
ffffffffc02008ce:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02008d2:	60e2                	ld	ra,24(sp)
ffffffffc02008d4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02008d6:	a081                	j	ffffffffc0200916 <intr_enable>

ffffffffc02008d8 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008d8:	100027f3          	csrr	a5,sstatus
ffffffffc02008dc:	8b89                	andi	a5,a5,2
ffffffffc02008de:	eb89                	bnez	a5,ffffffffc02008f0 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02008e0:	4501                	li	a0,0
ffffffffc02008e2:	4581                	li	a1,0
ffffffffc02008e4:	4601                	li	a2,0
ffffffffc02008e6:	4889                	li	a7,2
ffffffffc02008e8:	00000073          	ecall
ffffffffc02008ec:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02008ee:	8082                	ret
int cons_getc(void) {
ffffffffc02008f0:	1101                	addi	sp,sp,-32
ffffffffc02008f2:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02008f4:	028000ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc02008f8:	4501                	li	a0,0
ffffffffc02008fa:	4581                	li	a1,0
ffffffffc02008fc:	4601                	li	a2,0
ffffffffc02008fe:	4889                	li	a7,2
ffffffffc0200900:	00000073          	ecall
ffffffffc0200904:	2501                	sext.w	a0,a0
ffffffffc0200906:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200908:	00e000ef          	jal	ra,ffffffffc0200916 <intr_enable>
}
ffffffffc020090c:	60e2                	ld	ra,24(sp)
ffffffffc020090e:	6522                	ld	a0,8(sp)
ffffffffc0200910:	6105                	addi	sp,sp,32
ffffffffc0200912:	8082                	ret

ffffffffc0200914 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200914:	8082                	ret

ffffffffc0200916 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200916:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020091a:	8082                	ret

ffffffffc020091c <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020091c:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200920:	8082                	ret

ffffffffc0200922 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200922:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200926:	00000797          	auipc	a5,0x0
ffffffffc020092a:	38678793          	addi	a5,a5,902 # ffffffffc0200cac <__alltraps>
ffffffffc020092e:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200932:	000407b7          	lui	a5,0x40
ffffffffc0200936:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020093a:	8082                	ret

ffffffffc020093c <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020093c:	610c                	ld	a1,0(a0)
{
ffffffffc020093e:	1141                	addi	sp,sp,-16
ffffffffc0200940:	e022                	sd	s0,0(sp)
ffffffffc0200942:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200944:	00003517          	auipc	a0,0x3
ffffffffc0200948:	52450513          	addi	a0,a0,1316 # ffffffffc0203e68 <commands+0x1b8>
{
ffffffffc020094c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020094e:	f92ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200952:	640c                	ld	a1,8(s0)
ffffffffc0200954:	00003517          	auipc	a0,0x3
ffffffffc0200958:	52c50513          	addi	a0,a0,1324 # ffffffffc0203e80 <commands+0x1d0>
ffffffffc020095c:	f84ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200960:	680c                	ld	a1,16(s0)
ffffffffc0200962:	00003517          	auipc	a0,0x3
ffffffffc0200966:	53650513          	addi	a0,a0,1334 # ffffffffc0203e98 <commands+0x1e8>
ffffffffc020096a:	f76ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020096e:	6c0c                	ld	a1,24(s0)
ffffffffc0200970:	00003517          	auipc	a0,0x3
ffffffffc0200974:	54050513          	addi	a0,a0,1344 # ffffffffc0203eb0 <commands+0x200>
ffffffffc0200978:	f68ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020097c:	700c                	ld	a1,32(s0)
ffffffffc020097e:	00003517          	auipc	a0,0x3
ffffffffc0200982:	54a50513          	addi	a0,a0,1354 # ffffffffc0203ec8 <commands+0x218>
ffffffffc0200986:	f5aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020098a:	740c                	ld	a1,40(s0)
ffffffffc020098c:	00003517          	auipc	a0,0x3
ffffffffc0200990:	55450513          	addi	a0,a0,1364 # ffffffffc0203ee0 <commands+0x230>
ffffffffc0200994:	f4cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200998:	780c                	ld	a1,48(s0)
ffffffffc020099a:	00003517          	auipc	a0,0x3
ffffffffc020099e:	55e50513          	addi	a0,a0,1374 # ffffffffc0203ef8 <commands+0x248>
ffffffffc02009a2:	f3eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009a6:	7c0c                	ld	a1,56(s0)
ffffffffc02009a8:	00003517          	auipc	a0,0x3
ffffffffc02009ac:	56850513          	addi	a0,a0,1384 # ffffffffc0203f10 <commands+0x260>
ffffffffc02009b0:	f30ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009b4:	602c                	ld	a1,64(s0)
ffffffffc02009b6:	00003517          	auipc	a0,0x3
ffffffffc02009ba:	57250513          	addi	a0,a0,1394 # ffffffffc0203f28 <commands+0x278>
ffffffffc02009be:	f22ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009c2:	642c                	ld	a1,72(s0)
ffffffffc02009c4:	00003517          	auipc	a0,0x3
ffffffffc02009c8:	57c50513          	addi	a0,a0,1404 # ffffffffc0203f40 <commands+0x290>
ffffffffc02009cc:	f14ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009d0:	682c                	ld	a1,80(s0)
ffffffffc02009d2:	00003517          	auipc	a0,0x3
ffffffffc02009d6:	58650513          	addi	a0,a0,1414 # ffffffffc0203f58 <commands+0x2a8>
ffffffffc02009da:	f06ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009de:	6c2c                	ld	a1,88(s0)
ffffffffc02009e0:	00003517          	auipc	a0,0x3
ffffffffc02009e4:	59050513          	addi	a0,a0,1424 # ffffffffc0203f70 <commands+0x2c0>
ffffffffc02009e8:	ef8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009ec:	702c                	ld	a1,96(s0)
ffffffffc02009ee:	00003517          	auipc	a0,0x3
ffffffffc02009f2:	59a50513          	addi	a0,a0,1434 # ffffffffc0203f88 <commands+0x2d8>
ffffffffc02009f6:	eeaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009fa:	742c                	ld	a1,104(s0)
ffffffffc02009fc:	00003517          	auipc	a0,0x3
ffffffffc0200a00:	5a450513          	addi	a0,a0,1444 # ffffffffc0203fa0 <commands+0x2f0>
ffffffffc0200a04:	edcff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a08:	782c                	ld	a1,112(s0)
ffffffffc0200a0a:	00003517          	auipc	a0,0x3
ffffffffc0200a0e:	5ae50513          	addi	a0,a0,1454 # ffffffffc0203fb8 <commands+0x308>
ffffffffc0200a12:	eceff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a16:	7c2c                	ld	a1,120(s0)
ffffffffc0200a18:	00003517          	auipc	a0,0x3
ffffffffc0200a1c:	5b850513          	addi	a0,a0,1464 # ffffffffc0203fd0 <commands+0x320>
ffffffffc0200a20:	ec0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a24:	604c                	ld	a1,128(s0)
ffffffffc0200a26:	00003517          	auipc	a0,0x3
ffffffffc0200a2a:	5c250513          	addi	a0,a0,1474 # ffffffffc0203fe8 <commands+0x338>
ffffffffc0200a2e:	eb2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a32:	644c                	ld	a1,136(s0)
ffffffffc0200a34:	00003517          	auipc	a0,0x3
ffffffffc0200a38:	5cc50513          	addi	a0,a0,1484 # ffffffffc0204000 <commands+0x350>
ffffffffc0200a3c:	ea4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a40:	684c                	ld	a1,144(s0)
ffffffffc0200a42:	00003517          	auipc	a0,0x3
ffffffffc0200a46:	5d650513          	addi	a0,a0,1494 # ffffffffc0204018 <commands+0x368>
ffffffffc0200a4a:	e96ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a4e:	6c4c                	ld	a1,152(s0)
ffffffffc0200a50:	00003517          	auipc	a0,0x3
ffffffffc0200a54:	5e050513          	addi	a0,a0,1504 # ffffffffc0204030 <commands+0x380>
ffffffffc0200a58:	e88ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a5c:	704c                	ld	a1,160(s0)
ffffffffc0200a5e:	00003517          	auipc	a0,0x3
ffffffffc0200a62:	5ea50513          	addi	a0,a0,1514 # ffffffffc0204048 <commands+0x398>
ffffffffc0200a66:	e7aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a6a:	744c                	ld	a1,168(s0)
ffffffffc0200a6c:	00003517          	auipc	a0,0x3
ffffffffc0200a70:	5f450513          	addi	a0,a0,1524 # ffffffffc0204060 <commands+0x3b0>
ffffffffc0200a74:	e6cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a78:	784c                	ld	a1,176(s0)
ffffffffc0200a7a:	00003517          	auipc	a0,0x3
ffffffffc0200a7e:	5fe50513          	addi	a0,a0,1534 # ffffffffc0204078 <commands+0x3c8>
ffffffffc0200a82:	e5eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a86:	7c4c                	ld	a1,184(s0)
ffffffffc0200a88:	00003517          	auipc	a0,0x3
ffffffffc0200a8c:	60850513          	addi	a0,a0,1544 # ffffffffc0204090 <commands+0x3e0>
ffffffffc0200a90:	e50ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a94:	606c                	ld	a1,192(s0)
ffffffffc0200a96:	00003517          	auipc	a0,0x3
ffffffffc0200a9a:	61250513          	addi	a0,a0,1554 # ffffffffc02040a8 <commands+0x3f8>
ffffffffc0200a9e:	e42ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200aa2:	646c                	ld	a1,200(s0)
ffffffffc0200aa4:	00003517          	auipc	a0,0x3
ffffffffc0200aa8:	61c50513          	addi	a0,a0,1564 # ffffffffc02040c0 <commands+0x410>
ffffffffc0200aac:	e34ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ab0:	686c                	ld	a1,208(s0)
ffffffffc0200ab2:	00003517          	auipc	a0,0x3
ffffffffc0200ab6:	62650513          	addi	a0,a0,1574 # ffffffffc02040d8 <commands+0x428>
ffffffffc0200aba:	e26ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200abe:	6c6c                	ld	a1,216(s0)
ffffffffc0200ac0:	00003517          	auipc	a0,0x3
ffffffffc0200ac4:	63050513          	addi	a0,a0,1584 # ffffffffc02040f0 <commands+0x440>
ffffffffc0200ac8:	e18ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200acc:	706c                	ld	a1,224(s0)
ffffffffc0200ace:	00003517          	auipc	a0,0x3
ffffffffc0200ad2:	63a50513          	addi	a0,a0,1594 # ffffffffc0204108 <commands+0x458>
ffffffffc0200ad6:	e0aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ada:	746c                	ld	a1,232(s0)
ffffffffc0200adc:	00003517          	auipc	a0,0x3
ffffffffc0200ae0:	64450513          	addi	a0,a0,1604 # ffffffffc0204120 <commands+0x470>
ffffffffc0200ae4:	dfcff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ae8:	786c                	ld	a1,240(s0)
ffffffffc0200aea:	00003517          	auipc	a0,0x3
ffffffffc0200aee:	64e50513          	addi	a0,a0,1614 # ffffffffc0204138 <commands+0x488>
ffffffffc0200af2:	deeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af6:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200af8:	6402                	ld	s0,0(sp)
ffffffffc0200afa:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200afc:	00003517          	auipc	a0,0x3
ffffffffc0200b00:	65450513          	addi	a0,a0,1620 # ffffffffc0204150 <commands+0x4a0>
}
ffffffffc0200b04:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b06:	ddaff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b0a <print_trapframe>:
{
ffffffffc0200b0a:	1141                	addi	sp,sp,-16
ffffffffc0200b0c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b0e:	85aa                	mv	a1,a0
{
ffffffffc0200b10:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b12:	00003517          	auipc	a0,0x3
ffffffffc0200b16:	65650513          	addi	a0,a0,1622 # ffffffffc0204168 <commands+0x4b8>
{
ffffffffc0200b1a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b1c:	dc4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b20:	8522                	mv	a0,s0
ffffffffc0200b22:	e1bff0ef          	jal	ra,ffffffffc020093c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b26:	10043583          	ld	a1,256(s0)
ffffffffc0200b2a:	00003517          	auipc	a0,0x3
ffffffffc0200b2e:	65650513          	addi	a0,a0,1622 # ffffffffc0204180 <commands+0x4d0>
ffffffffc0200b32:	daeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b36:	10843583          	ld	a1,264(s0)
ffffffffc0200b3a:	00003517          	auipc	a0,0x3
ffffffffc0200b3e:	65e50513          	addi	a0,a0,1630 # ffffffffc0204198 <commands+0x4e8>
ffffffffc0200b42:	d9eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b46:	11043583          	ld	a1,272(s0)
ffffffffc0200b4a:	00003517          	auipc	a0,0x3
ffffffffc0200b4e:	66650513          	addi	a0,a0,1638 # ffffffffc02041b0 <commands+0x500>
ffffffffc0200b52:	d8eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b56:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b5a:	6402                	ld	s0,0(sp)
ffffffffc0200b5c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b5e:	00003517          	auipc	a0,0x3
ffffffffc0200b62:	66a50513          	addi	a0,a0,1642 # ffffffffc02041c8 <commands+0x518>
}
ffffffffc0200b66:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b68:	d78ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b6c <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b6c:	11853783          	ld	a5,280(a0)
ffffffffc0200b70:	472d                	li	a4,11
ffffffffc0200b72:	0786                	slli	a5,a5,0x1
ffffffffc0200b74:	8385                	srli	a5,a5,0x1
ffffffffc0200b76:	04f76a63          	bltu	a4,a5,ffffffffc0200bca <interrupt_handler+0x5e>
ffffffffc0200b7a:	00003717          	auipc	a4,0x3
ffffffffc0200b7e:	70670713          	addi	a4,a4,1798 # ffffffffc0204280 <commands+0x5d0>
ffffffffc0200b82:	078a                	slli	a5,a5,0x2
ffffffffc0200b84:	97ba                	add	a5,a5,a4
ffffffffc0200b86:	439c                	lw	a5,0(a5)
ffffffffc0200b88:	97ba                	add	a5,a5,a4
ffffffffc0200b8a:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b8c:	00003517          	auipc	a0,0x3
ffffffffc0200b90:	6b450513          	addi	a0,a0,1716 # ffffffffc0204240 <commands+0x590>
ffffffffc0200b94:	d4cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b98:	00003517          	auipc	a0,0x3
ffffffffc0200b9c:	68850513          	addi	a0,a0,1672 # ffffffffc0204220 <commands+0x570>
ffffffffc0200ba0:	d40ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200ba4:	00003517          	auipc	a0,0x3
ffffffffc0200ba8:	63c50513          	addi	a0,a0,1596 # ffffffffc02041e0 <commands+0x530>
ffffffffc0200bac:	d34ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bb0:	00003517          	auipc	a0,0x3
ffffffffc0200bb4:	65050513          	addi	a0,a0,1616 # ffffffffc0204200 <commands+0x550>
ffffffffc0200bb8:	d28ff06f          	j	ffffffffc02000e0 <cprintf>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bbc:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bbe:	00003517          	auipc	a0,0x3
ffffffffc0200bc2:	6a250513          	addi	a0,a0,1698 # ffffffffc0204260 <commands+0x5b0>
ffffffffc0200bc6:	d1aff06f          	j	ffffffffc02000e0 <cprintf>
        print_trapframe(tf);
ffffffffc0200bca:	b781                	j	ffffffffc0200b0a <print_trapframe>

ffffffffc0200bcc <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200bcc:	11853783          	ld	a5,280(a0)
ffffffffc0200bd0:	473d                	li	a4,15
ffffffffc0200bd2:	0cf76563          	bltu	a4,a5,ffffffffc0200c9c <exception_handler+0xd0>
ffffffffc0200bd6:	00004717          	auipc	a4,0x4
ffffffffc0200bda:	87270713          	addi	a4,a4,-1934 # ffffffffc0204448 <commands+0x798>
ffffffffc0200bde:	078a                	slli	a5,a5,0x2
ffffffffc0200be0:	97ba                	add	a5,a5,a4
ffffffffc0200be2:	439c                	lw	a5,0(a5)
ffffffffc0200be4:	97ba                	add	a5,a5,a4
ffffffffc0200be6:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200be8:	00004517          	auipc	a0,0x4
ffffffffc0200bec:	84850513          	addi	a0,a0,-1976 # ffffffffc0204430 <commands+0x780>
ffffffffc0200bf0:	cf0ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200bf4:	00003517          	auipc	a0,0x3
ffffffffc0200bf8:	6bc50513          	addi	a0,a0,1724 # ffffffffc02042b0 <commands+0x600>
ffffffffc0200bfc:	ce4ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c00:	00003517          	auipc	a0,0x3
ffffffffc0200c04:	6d050513          	addi	a0,a0,1744 # ffffffffc02042d0 <commands+0x620>
ffffffffc0200c08:	cd8ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c0c:	00003517          	auipc	a0,0x3
ffffffffc0200c10:	6e450513          	addi	a0,a0,1764 # ffffffffc02042f0 <commands+0x640>
ffffffffc0200c14:	cccff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c18:	00003517          	auipc	a0,0x3
ffffffffc0200c1c:	6f050513          	addi	a0,a0,1776 # ffffffffc0204308 <commands+0x658>
ffffffffc0200c20:	cc0ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200c24:	00003517          	auipc	a0,0x3
ffffffffc0200c28:	6f450513          	addi	a0,a0,1780 # ffffffffc0204318 <commands+0x668>
ffffffffc0200c2c:	cb4ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200c30:	00003517          	auipc	a0,0x3
ffffffffc0200c34:	70850513          	addi	a0,a0,1800 # ffffffffc0204338 <commands+0x688>
ffffffffc0200c38:	ca8ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200c3c:	00003517          	auipc	a0,0x3
ffffffffc0200c40:	71450513          	addi	a0,a0,1812 # ffffffffc0204350 <commands+0x6a0>
ffffffffc0200c44:	c9cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200c48:	00003517          	auipc	a0,0x3
ffffffffc0200c4c:	72050513          	addi	a0,a0,1824 # ffffffffc0204368 <commands+0x6b8>
ffffffffc0200c50:	c90ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200c54:	00003517          	auipc	a0,0x3
ffffffffc0200c58:	72c50513          	addi	a0,a0,1836 # ffffffffc0204380 <commands+0x6d0>
ffffffffc0200c5c:	c84ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200c60:	00003517          	auipc	a0,0x3
ffffffffc0200c64:	74050513          	addi	a0,a0,1856 # ffffffffc02043a0 <commands+0x6f0>
ffffffffc0200c68:	c78ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c6c:	00003517          	auipc	a0,0x3
ffffffffc0200c70:	75450513          	addi	a0,a0,1876 # ffffffffc02043c0 <commands+0x710>
ffffffffc0200c74:	c6cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200c78:	00003517          	auipc	a0,0x3
ffffffffc0200c7c:	76850513          	addi	a0,a0,1896 # ffffffffc02043e0 <commands+0x730>
ffffffffc0200c80:	c60ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200c84:	00003517          	auipc	a0,0x3
ffffffffc0200c88:	77c50513          	addi	a0,a0,1916 # ffffffffc0204400 <commands+0x750>
ffffffffc0200c8c:	c54ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200c90:	00003517          	auipc	a0,0x3
ffffffffc0200c94:	78850513          	addi	a0,a0,1928 # ffffffffc0204418 <commands+0x768>
ffffffffc0200c98:	c48ff06f          	j	ffffffffc02000e0 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200c9c:	b5bd                	j	ffffffffc0200b0a <print_trapframe>

ffffffffc0200c9e <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c9e:	11853783          	ld	a5,280(a0)
ffffffffc0200ca2:	0007c363          	bltz	a5,ffffffffc0200ca8 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200ca6:	b71d                	j	ffffffffc0200bcc <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ca8:	b5d1                	j	ffffffffc0200b6c <interrupt_handler>
	...

ffffffffc0200cac <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cac:	14011073          	csrw	sscratch,sp
ffffffffc0200cb0:	712d                	addi	sp,sp,-288
ffffffffc0200cb2:	e406                	sd	ra,8(sp)
ffffffffc0200cb4:	ec0e                	sd	gp,24(sp)
ffffffffc0200cb6:	f012                	sd	tp,32(sp)
ffffffffc0200cb8:	f416                	sd	t0,40(sp)
ffffffffc0200cba:	f81a                	sd	t1,48(sp)
ffffffffc0200cbc:	fc1e                	sd	t2,56(sp)
ffffffffc0200cbe:	e0a2                	sd	s0,64(sp)
ffffffffc0200cc0:	e4a6                	sd	s1,72(sp)
ffffffffc0200cc2:	e8aa                	sd	a0,80(sp)
ffffffffc0200cc4:	ecae                	sd	a1,88(sp)
ffffffffc0200cc6:	f0b2                	sd	a2,96(sp)
ffffffffc0200cc8:	f4b6                	sd	a3,104(sp)
ffffffffc0200cca:	f8ba                	sd	a4,112(sp)
ffffffffc0200ccc:	fcbe                	sd	a5,120(sp)
ffffffffc0200cce:	e142                	sd	a6,128(sp)
ffffffffc0200cd0:	e546                	sd	a7,136(sp)
ffffffffc0200cd2:	e94a                	sd	s2,144(sp)
ffffffffc0200cd4:	ed4e                	sd	s3,152(sp)
ffffffffc0200cd6:	f152                	sd	s4,160(sp)
ffffffffc0200cd8:	f556                	sd	s5,168(sp)
ffffffffc0200cda:	f95a                	sd	s6,176(sp)
ffffffffc0200cdc:	fd5e                	sd	s7,184(sp)
ffffffffc0200cde:	e1e2                	sd	s8,192(sp)
ffffffffc0200ce0:	e5e6                	sd	s9,200(sp)
ffffffffc0200ce2:	e9ea                	sd	s10,208(sp)
ffffffffc0200ce4:	edee                	sd	s11,216(sp)
ffffffffc0200ce6:	f1f2                	sd	t3,224(sp)
ffffffffc0200ce8:	f5f6                	sd	t4,232(sp)
ffffffffc0200cea:	f9fa                	sd	t5,240(sp)
ffffffffc0200cec:	fdfe                	sd	t6,248(sp)
ffffffffc0200cee:	14002473          	csrr	s0,sscratch
ffffffffc0200cf2:	100024f3          	csrr	s1,sstatus
ffffffffc0200cf6:	14102973          	csrr	s2,sepc
ffffffffc0200cfa:	143029f3          	csrr	s3,stval
ffffffffc0200cfe:	14202a73          	csrr	s4,scause
ffffffffc0200d02:	e822                	sd	s0,16(sp)
ffffffffc0200d04:	e226                	sd	s1,256(sp)
ffffffffc0200d06:	e64a                	sd	s2,264(sp)
ffffffffc0200d08:	ea4e                	sd	s3,272(sp)
ffffffffc0200d0a:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d0c:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d0e:	f91ff0ef          	jal	ra,ffffffffc0200c9e <trap>

ffffffffc0200d12 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d12:	6492                	ld	s1,256(sp)
ffffffffc0200d14:	6932                	ld	s2,264(sp)
ffffffffc0200d16:	10049073          	csrw	sstatus,s1
ffffffffc0200d1a:	14191073          	csrw	sepc,s2
ffffffffc0200d1e:	60a2                	ld	ra,8(sp)
ffffffffc0200d20:	61e2                	ld	gp,24(sp)
ffffffffc0200d22:	7202                	ld	tp,32(sp)
ffffffffc0200d24:	72a2                	ld	t0,40(sp)
ffffffffc0200d26:	7342                	ld	t1,48(sp)
ffffffffc0200d28:	73e2                	ld	t2,56(sp)
ffffffffc0200d2a:	6406                	ld	s0,64(sp)
ffffffffc0200d2c:	64a6                	ld	s1,72(sp)
ffffffffc0200d2e:	6546                	ld	a0,80(sp)
ffffffffc0200d30:	65e6                	ld	a1,88(sp)
ffffffffc0200d32:	7606                	ld	a2,96(sp)
ffffffffc0200d34:	76a6                	ld	a3,104(sp)
ffffffffc0200d36:	7746                	ld	a4,112(sp)
ffffffffc0200d38:	77e6                	ld	a5,120(sp)
ffffffffc0200d3a:	680a                	ld	a6,128(sp)
ffffffffc0200d3c:	68aa                	ld	a7,136(sp)
ffffffffc0200d3e:	694a                	ld	s2,144(sp)
ffffffffc0200d40:	69ea                	ld	s3,152(sp)
ffffffffc0200d42:	7a0a                	ld	s4,160(sp)
ffffffffc0200d44:	7aaa                	ld	s5,168(sp)
ffffffffc0200d46:	7b4a                	ld	s6,176(sp)
ffffffffc0200d48:	7bea                	ld	s7,184(sp)
ffffffffc0200d4a:	6c0e                	ld	s8,192(sp)
ffffffffc0200d4c:	6cae                	ld	s9,200(sp)
ffffffffc0200d4e:	6d4e                	ld	s10,208(sp)
ffffffffc0200d50:	6dee                	ld	s11,216(sp)
ffffffffc0200d52:	7e0e                	ld	t3,224(sp)
ffffffffc0200d54:	7eae                	ld	t4,232(sp)
ffffffffc0200d56:	7f4e                	ld	t5,240(sp)
ffffffffc0200d58:	7fee                	ld	t6,248(sp)
ffffffffc0200d5a:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d5c:	10200073          	sret

ffffffffc0200d60 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d60:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d62:	bf45                	j	ffffffffc0200d12 <__trapret>
	...

ffffffffc0200d66 <pa2page.part.0>:
{
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa)
ffffffffc0200d66:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0200d68:	00003617          	auipc	a2,0x3
ffffffffc0200d6c:	72060613          	addi	a2,a2,1824 # ffffffffc0204488 <commands+0x7d8>
ffffffffc0200d70:	06900593          	li	a1,105
ffffffffc0200d74:	00003517          	auipc	a0,0x3
ffffffffc0200d78:	73450513          	addi	a0,a0,1844 # ffffffffc02044a8 <commands+0x7f8>
pa2page(uintptr_t pa)
ffffffffc0200d7c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200d7e:	c60ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200d82 <pte2page.part.0>:
{
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte)
ffffffffc0200d82:	1141                	addi	sp,sp,-16
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
ffffffffc0200d84:	00003617          	auipc	a2,0x3
ffffffffc0200d88:	73460613          	addi	a2,a2,1844 # ffffffffc02044b8 <commands+0x808>
ffffffffc0200d8c:	07f00593          	li	a1,127
ffffffffc0200d90:	00003517          	auipc	a0,0x3
ffffffffc0200d94:	71850513          	addi	a0,a0,1816 # ffffffffc02044a8 <commands+0x7f8>
pte2page(pte_t pte)
ffffffffc0200d98:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200d9a:	c44ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200d9e <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200d9e:	100027f3          	csrr	a5,sstatus
ffffffffc0200da2:	8b89                	andi	a5,a5,2
ffffffffc0200da4:	e799                	bnez	a5,ffffffffc0200db2 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200da6:	0000c797          	auipc	a5,0xc
ffffffffc0200daa:	7027b783          	ld	a5,1794(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200dae:	6f9c                	ld	a5,24(a5)
ffffffffc0200db0:	8782                	jr	a5
{
ffffffffc0200db2:	1141                	addi	sp,sp,-16
ffffffffc0200db4:	e406                	sd	ra,8(sp)
ffffffffc0200db6:	e022                	sd	s0,0(sp)
ffffffffc0200db8:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200dba:	b63ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200dbe:	0000c797          	auipc	a5,0xc
ffffffffc0200dc2:	6ea7b783          	ld	a5,1770(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200dc6:	6f9c                	ld	a5,24(a5)
ffffffffc0200dc8:	8522                	mv	a0,s0
ffffffffc0200dca:	9782                	jalr	a5
ffffffffc0200dcc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200dce:	b49ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200dd2:	60a2                	ld	ra,8(sp)
ffffffffc0200dd4:	8522                	mv	a0,s0
ffffffffc0200dd6:	6402                	ld	s0,0(sp)
ffffffffc0200dd8:	0141                	addi	sp,sp,16
ffffffffc0200dda:	8082                	ret

ffffffffc0200ddc <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200ddc:	100027f3          	csrr	a5,sstatus
ffffffffc0200de0:	8b89                	andi	a5,a5,2
ffffffffc0200de2:	e799                	bnez	a5,ffffffffc0200df0 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200de4:	0000c797          	auipc	a5,0xc
ffffffffc0200de8:	6c47b783          	ld	a5,1732(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200dec:	739c                	ld	a5,32(a5)
ffffffffc0200dee:	8782                	jr	a5
{
ffffffffc0200df0:	1101                	addi	sp,sp,-32
ffffffffc0200df2:	ec06                	sd	ra,24(sp)
ffffffffc0200df4:	e822                	sd	s0,16(sp)
ffffffffc0200df6:	e426                	sd	s1,8(sp)
ffffffffc0200df8:	842a                	mv	s0,a0
ffffffffc0200dfa:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200dfc:	b21ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200e00:	0000c797          	auipc	a5,0xc
ffffffffc0200e04:	6a87b783          	ld	a5,1704(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200e08:	739c                	ld	a5,32(a5)
ffffffffc0200e0a:	85a6                	mv	a1,s1
ffffffffc0200e0c:	8522                	mv	a0,s0
ffffffffc0200e0e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200e10:	6442                	ld	s0,16(sp)
ffffffffc0200e12:	60e2                	ld	ra,24(sp)
ffffffffc0200e14:	64a2                	ld	s1,8(sp)
ffffffffc0200e16:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200e18:	bcfd                	j	ffffffffc0200916 <intr_enable>

ffffffffc0200e1a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e1a:	100027f3          	csrr	a5,sstatus
ffffffffc0200e1e:	8b89                	andi	a5,a5,2
ffffffffc0200e20:	e799                	bnez	a5,ffffffffc0200e2e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200e22:	0000c797          	auipc	a5,0xc
ffffffffc0200e26:	6867b783          	ld	a5,1670(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200e2a:	779c                	ld	a5,40(a5)
ffffffffc0200e2c:	8782                	jr	a5
{
ffffffffc0200e2e:	1141                	addi	sp,sp,-16
ffffffffc0200e30:	e406                	sd	ra,8(sp)
ffffffffc0200e32:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200e34:	ae9ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200e38:	0000c797          	auipc	a5,0xc
ffffffffc0200e3c:	6707b783          	ld	a5,1648(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200e40:	779c                	ld	a5,40(a5)
ffffffffc0200e42:	9782                	jalr	a5
ffffffffc0200e44:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200e46:	ad1ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200e4a:	60a2                	ld	ra,8(sp)
ffffffffc0200e4c:	8522                	mv	a0,s0
ffffffffc0200e4e:	6402                	ld	s0,0(sp)
ffffffffc0200e50:	0141                	addi	sp,sp,16
ffffffffc0200e52:	8082                	ret

ffffffffc0200e54 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200e54:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0200e58:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0200e5c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200e5e:	078e                	slli	a5,a5,0x3
{
ffffffffc0200e60:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200e62:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0200e66:	6094                	ld	a3,0(s1)
{
ffffffffc0200e68:	f04a                	sd	s2,32(sp)
ffffffffc0200e6a:	ec4e                	sd	s3,24(sp)
ffffffffc0200e6c:	e852                	sd	s4,16(sp)
ffffffffc0200e6e:	fc06                	sd	ra,56(sp)
ffffffffc0200e70:	f822                	sd	s0,48(sp)
ffffffffc0200e72:	e456                	sd	s5,8(sp)
ffffffffc0200e74:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0200e76:	0016f793          	andi	a5,a3,1
{
ffffffffc0200e7a:	892e                	mv	s2,a1
ffffffffc0200e7c:	8a32                	mv	s4,a2
ffffffffc0200e7e:	0000c997          	auipc	s3,0xc
ffffffffc0200e82:	61a98993          	addi	s3,s3,1562 # ffffffffc020d498 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0200e86:	efbd                	bnez	a5,ffffffffc0200f04 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200e88:	14060c63          	beqz	a2,ffffffffc0200fe0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e8c:	100027f3          	csrr	a5,sstatus
ffffffffc0200e90:	8b89                	andi	a5,a5,2
ffffffffc0200e92:	14079963          	bnez	a5,ffffffffc0200fe4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200e96:	0000c797          	auipc	a5,0xc
ffffffffc0200e9a:	6127b783          	ld	a5,1554(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200e9e:	6f9c                	ld	a5,24(a5)
ffffffffc0200ea0:	4505                	li	a0,1
ffffffffc0200ea2:	9782                	jalr	a5
ffffffffc0200ea4:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200ea6:	12040d63          	beqz	s0,ffffffffc0200fe0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200eaa:	0000cb17          	auipc	s6,0xc
ffffffffc0200eae:	5f6b0b13          	addi	s6,s6,1526 # ffffffffc020d4a0 <pages>
ffffffffc0200eb2:	000b3503          	ld	a0,0(s6)
ffffffffc0200eb6:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200eba:	0000c997          	auipc	s3,0xc
ffffffffc0200ebe:	5de98993          	addi	s3,s3,1502 # ffffffffc020d498 <npage>
ffffffffc0200ec2:	40a40533          	sub	a0,s0,a0
ffffffffc0200ec6:	8519                	srai	a0,a0,0x6
ffffffffc0200ec8:	9556                	add	a0,a0,s5
ffffffffc0200eca:	0009b703          	ld	a4,0(s3)
ffffffffc0200ece:	00c51793          	slli	a5,a0,0xc
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0200ed2:	4685                	li	a3,1
ffffffffc0200ed4:	c014                	sw	a3,0(s0)
ffffffffc0200ed6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ed8:	0532                	slli	a0,a0,0xc
ffffffffc0200eda:	16e7f763          	bgeu	a5,a4,ffffffffc0201048 <get_pte+0x1f4>
ffffffffc0200ede:	0000c797          	auipc	a5,0xc
ffffffffc0200ee2:	5d27b783          	ld	a5,1490(a5) # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0200ee6:	6605                	lui	a2,0x1
ffffffffc0200ee8:	4581                	li	a1,0
ffffffffc0200eea:	953e                	add	a0,a0,a5
ffffffffc0200eec:	6e8020ef          	jal	ra,ffffffffc02035d4 <memset>
    return page - pages + nbase;
ffffffffc0200ef0:	000b3683          	ld	a3,0(s6)
ffffffffc0200ef4:	40d406b3          	sub	a3,s0,a3
ffffffffc0200ef8:	8699                	srai	a3,a3,0x6
ffffffffc0200efa:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200efc:	06aa                	slli	a3,a3,0xa
ffffffffc0200efe:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200f02:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200f04:	77fd                	lui	a5,0xfffff
ffffffffc0200f06:	068a                	slli	a3,a3,0x2
ffffffffc0200f08:	0009b703          	ld	a4,0(s3)
ffffffffc0200f0c:	8efd                	and	a3,a3,a5
ffffffffc0200f0e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f12:	10e7ff63          	bgeu	a5,a4,ffffffffc0201030 <get_pte+0x1dc>
ffffffffc0200f16:	0000ca97          	auipc	s5,0xc
ffffffffc0200f1a:	59aa8a93          	addi	s5,s5,1434 # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0200f1e:	000ab403          	ld	s0,0(s5)
ffffffffc0200f22:	01595793          	srli	a5,s2,0x15
ffffffffc0200f26:	1ff7f793          	andi	a5,a5,511
ffffffffc0200f2a:	96a2                	add	a3,a3,s0
ffffffffc0200f2c:	00379413          	slli	s0,a5,0x3
ffffffffc0200f30:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0200f32:	6014                	ld	a3,0(s0)
ffffffffc0200f34:	0016f793          	andi	a5,a3,1
ffffffffc0200f38:	ebad                	bnez	a5,ffffffffc0200faa <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200f3a:	0a0a0363          	beqz	s4,ffffffffc0200fe0 <get_pte+0x18c>
ffffffffc0200f3e:	100027f3          	csrr	a5,sstatus
ffffffffc0200f42:	8b89                	andi	a5,a5,2
ffffffffc0200f44:	efcd                	bnez	a5,ffffffffc0200ffe <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f46:	0000c797          	auipc	a5,0xc
ffffffffc0200f4a:	5627b783          	ld	a5,1378(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200f4e:	6f9c                	ld	a5,24(a5)
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	9782                	jalr	a5
ffffffffc0200f54:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200f56:	c4c9                	beqz	s1,ffffffffc0200fe0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200f58:	0000cb17          	auipc	s6,0xc
ffffffffc0200f5c:	548b0b13          	addi	s6,s6,1352 # ffffffffc020d4a0 <pages>
ffffffffc0200f60:	000b3503          	ld	a0,0(s6)
ffffffffc0200f64:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200f68:	0009b703          	ld	a4,0(s3)
ffffffffc0200f6c:	40a48533          	sub	a0,s1,a0
ffffffffc0200f70:	8519                	srai	a0,a0,0x6
ffffffffc0200f72:	9552                	add	a0,a0,s4
ffffffffc0200f74:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0200f78:	4685                	li	a3,1
ffffffffc0200f7a:	c094                	sw	a3,0(s1)
ffffffffc0200f7c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f7e:	0532                	slli	a0,a0,0xc
ffffffffc0200f80:	0ee7f163          	bgeu	a5,a4,ffffffffc0201062 <get_pte+0x20e>
ffffffffc0200f84:	000ab783          	ld	a5,0(s5)
ffffffffc0200f88:	6605                	lui	a2,0x1
ffffffffc0200f8a:	4581                	li	a1,0
ffffffffc0200f8c:	953e                	add	a0,a0,a5
ffffffffc0200f8e:	646020ef          	jal	ra,ffffffffc02035d4 <memset>
    return page - pages + nbase;
ffffffffc0200f92:	000b3683          	ld	a3,0(s6)
ffffffffc0200f96:	40d486b3          	sub	a3,s1,a3
ffffffffc0200f9a:	8699                	srai	a3,a3,0x6
ffffffffc0200f9c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200f9e:	06aa                	slli	a3,a3,0xa
ffffffffc0200fa0:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200fa4:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200fa6:	0009b703          	ld	a4,0(s3)
ffffffffc0200faa:	068a                	slli	a3,a3,0x2
ffffffffc0200fac:	757d                	lui	a0,0xfffff
ffffffffc0200fae:	8ee9                	and	a3,a3,a0
ffffffffc0200fb0:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200fb4:	06e7f263          	bgeu	a5,a4,ffffffffc0201018 <get_pte+0x1c4>
ffffffffc0200fb8:	000ab503          	ld	a0,0(s5)
ffffffffc0200fbc:	00c95913          	srli	s2,s2,0xc
ffffffffc0200fc0:	1ff97913          	andi	s2,s2,511
ffffffffc0200fc4:	96aa                	add	a3,a3,a0
ffffffffc0200fc6:	00391513          	slli	a0,s2,0x3
ffffffffc0200fca:	9536                	add	a0,a0,a3
}
ffffffffc0200fcc:	70e2                	ld	ra,56(sp)
ffffffffc0200fce:	7442                	ld	s0,48(sp)
ffffffffc0200fd0:	74a2                	ld	s1,40(sp)
ffffffffc0200fd2:	7902                	ld	s2,32(sp)
ffffffffc0200fd4:	69e2                	ld	s3,24(sp)
ffffffffc0200fd6:	6a42                	ld	s4,16(sp)
ffffffffc0200fd8:	6aa2                	ld	s5,8(sp)
ffffffffc0200fda:	6b02                	ld	s6,0(sp)
ffffffffc0200fdc:	6121                	addi	sp,sp,64
ffffffffc0200fde:	8082                	ret
            return NULL;
ffffffffc0200fe0:	4501                	li	a0,0
ffffffffc0200fe2:	b7ed                	j	ffffffffc0200fcc <get_pte+0x178>
        intr_disable();
ffffffffc0200fe4:	939ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200fe8:	0000c797          	auipc	a5,0xc
ffffffffc0200fec:	4c07b783          	ld	a5,1216(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0200ff0:	6f9c                	ld	a5,24(a5)
ffffffffc0200ff2:	4505                	li	a0,1
ffffffffc0200ff4:	9782                	jalr	a5
ffffffffc0200ff6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200ff8:	91fff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0200ffc:	b56d                	j	ffffffffc0200ea6 <get_pte+0x52>
        intr_disable();
ffffffffc0200ffe:	91fff0ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc0201002:	0000c797          	auipc	a5,0xc
ffffffffc0201006:	4a67b783          	ld	a5,1190(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc020100a:	6f9c                	ld	a5,24(a5)
ffffffffc020100c:	4505                	li	a0,1
ffffffffc020100e:	9782                	jalr	a5
ffffffffc0201010:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201012:	905ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201016:	b781                	j	ffffffffc0200f56 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201018:	00003617          	auipc	a2,0x3
ffffffffc020101c:	4c860613          	addi	a2,a2,1224 # ffffffffc02044e0 <commands+0x830>
ffffffffc0201020:	0fb00593          	li	a1,251
ffffffffc0201024:	00003517          	auipc	a0,0x3
ffffffffc0201028:	4e450513          	addi	a0,a0,1252 # ffffffffc0204508 <commands+0x858>
ffffffffc020102c:	9b2ff0ef          	jal	ra,ffffffffc02001de <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201030:	00003617          	auipc	a2,0x3
ffffffffc0201034:	4b060613          	addi	a2,a2,1200 # ffffffffc02044e0 <commands+0x830>
ffffffffc0201038:	0ee00593          	li	a1,238
ffffffffc020103c:	00003517          	auipc	a0,0x3
ffffffffc0201040:	4cc50513          	addi	a0,a0,1228 # ffffffffc0204508 <commands+0x858>
ffffffffc0201044:	99aff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201048:	86aa                	mv	a3,a0
ffffffffc020104a:	00003617          	auipc	a2,0x3
ffffffffc020104e:	49660613          	addi	a2,a2,1174 # ffffffffc02044e0 <commands+0x830>
ffffffffc0201052:	0eb00593          	li	a1,235
ffffffffc0201056:	00003517          	auipc	a0,0x3
ffffffffc020105a:	4b250513          	addi	a0,a0,1202 # ffffffffc0204508 <commands+0x858>
ffffffffc020105e:	980ff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201062:	86aa                	mv	a3,a0
ffffffffc0201064:	00003617          	auipc	a2,0x3
ffffffffc0201068:	47c60613          	addi	a2,a2,1148 # ffffffffc02044e0 <commands+0x830>
ffffffffc020106c:	0f800593          	li	a1,248
ffffffffc0201070:	00003517          	auipc	a0,0x3
ffffffffc0201074:	49850513          	addi	a0,a0,1176 # ffffffffc0204508 <commands+0x858>
ffffffffc0201078:	966ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020107c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020107c:	1141                	addi	sp,sp,-16
ffffffffc020107e:	e022                	sd	s0,0(sp)
ffffffffc0201080:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201082:	4601                	li	a2,0
{
ffffffffc0201084:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201086:	dcfff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
    if (ptep_store != NULL)
ffffffffc020108a:	c011                	beqz	s0,ffffffffc020108e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020108c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020108e:	c511                	beqz	a0,ffffffffc020109a <get_page+0x1e>
ffffffffc0201090:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201092:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201094:	0017f713          	andi	a4,a5,1
ffffffffc0201098:	e709                	bnez	a4,ffffffffc02010a2 <get_page+0x26>
}
ffffffffc020109a:	60a2                	ld	ra,8(sp)
ffffffffc020109c:	6402                	ld	s0,0(sp)
ffffffffc020109e:	0141                	addi	sp,sp,16
ffffffffc02010a0:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02010a2:	078a                	slli	a5,a5,0x2
ffffffffc02010a4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02010a6:	0000c717          	auipc	a4,0xc
ffffffffc02010aa:	3f273703          	ld	a4,1010(a4) # ffffffffc020d498 <npage>
ffffffffc02010ae:	00e7ff63          	bgeu	a5,a4,ffffffffc02010cc <get_page+0x50>
ffffffffc02010b2:	60a2                	ld	ra,8(sp)
ffffffffc02010b4:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02010b6:	fff80537          	lui	a0,0xfff80
ffffffffc02010ba:	97aa                	add	a5,a5,a0
ffffffffc02010bc:	079a                	slli	a5,a5,0x6
ffffffffc02010be:	0000c517          	auipc	a0,0xc
ffffffffc02010c2:	3e253503          	ld	a0,994(a0) # ffffffffc020d4a0 <pages>
ffffffffc02010c6:	953e                	add	a0,a0,a5
ffffffffc02010c8:	0141                	addi	sp,sp,16
ffffffffc02010ca:	8082                	ret
ffffffffc02010cc:	c9bff0ef          	jal	ra,ffffffffc0200d66 <pa2page.part.0>

ffffffffc02010d0 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc02010d0:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02010d2:	4601                	li	a2,0
{
ffffffffc02010d4:	ec26                	sd	s1,24(sp)
ffffffffc02010d6:	f406                	sd	ra,40(sp)
ffffffffc02010d8:	f022                	sd	s0,32(sp)
ffffffffc02010da:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02010dc:	d79ff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
    if (ptep != NULL)
ffffffffc02010e0:	c511                	beqz	a0,ffffffffc02010ec <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02010e2:	611c                	ld	a5,0(a0)
ffffffffc02010e4:	842a                	mv	s0,a0
ffffffffc02010e6:	0017f713          	andi	a4,a5,1
ffffffffc02010ea:	e711                	bnez	a4,ffffffffc02010f6 <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc02010ec:	70a2                	ld	ra,40(sp)
ffffffffc02010ee:	7402                	ld	s0,32(sp)
ffffffffc02010f0:	64e2                	ld	s1,24(sp)
ffffffffc02010f2:	6145                	addi	sp,sp,48
ffffffffc02010f4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02010f6:	078a                	slli	a5,a5,0x2
ffffffffc02010f8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02010fa:	0000c717          	auipc	a4,0xc
ffffffffc02010fe:	39e73703          	ld	a4,926(a4) # ffffffffc020d498 <npage>
ffffffffc0201102:	06e7f363          	bgeu	a5,a4,ffffffffc0201168 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201106:	fff80537          	lui	a0,0xfff80
ffffffffc020110a:	97aa                	add	a5,a5,a0
ffffffffc020110c:	079a                	slli	a5,a5,0x6
ffffffffc020110e:	0000c517          	auipc	a0,0xc
ffffffffc0201112:	39253503          	ld	a0,914(a0) # ffffffffc020d4a0 <pages>
ffffffffc0201116:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201118:	411c                	lw	a5,0(a0)
ffffffffc020111a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020111e:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201120:	cb11                	beqz	a4,ffffffffc0201134 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201122:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201126:	12048073          	sfence.vma	s1
}
ffffffffc020112a:	70a2                	ld	ra,40(sp)
ffffffffc020112c:	7402                	ld	s0,32(sp)
ffffffffc020112e:	64e2                	ld	s1,24(sp)
ffffffffc0201130:	6145                	addi	sp,sp,48
ffffffffc0201132:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201134:	100027f3          	csrr	a5,sstatus
ffffffffc0201138:	8b89                	andi	a5,a5,2
ffffffffc020113a:	eb89                	bnez	a5,ffffffffc020114c <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc020113c:	0000c797          	auipc	a5,0xc
ffffffffc0201140:	36c7b783          	ld	a5,876(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0201144:	739c                	ld	a5,32(a5)
ffffffffc0201146:	4585                	li	a1,1
ffffffffc0201148:	9782                	jalr	a5
    if (flag) {
ffffffffc020114a:	bfe1                	j	ffffffffc0201122 <page_remove+0x52>
        intr_disable();
ffffffffc020114c:	e42a                	sd	a0,8(sp)
ffffffffc020114e:	fceff0ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc0201152:	0000c797          	auipc	a5,0xc
ffffffffc0201156:	3567b783          	ld	a5,854(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc020115a:	739c                	ld	a5,32(a5)
ffffffffc020115c:	6522                	ld	a0,8(sp)
ffffffffc020115e:	4585                	li	a1,1
ffffffffc0201160:	9782                	jalr	a5
        intr_enable();
ffffffffc0201162:	fb4ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201166:	bf75                	j	ffffffffc0201122 <page_remove+0x52>
ffffffffc0201168:	bffff0ef          	jal	ra,ffffffffc0200d66 <pa2page.part.0>

ffffffffc020116c <page_insert>:
{
ffffffffc020116c:	7139                	addi	sp,sp,-64
ffffffffc020116e:	e852                	sd	s4,16(sp)
ffffffffc0201170:	8a32                	mv	s4,a2
ffffffffc0201172:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201174:	4605                	li	a2,1
{
ffffffffc0201176:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201178:	85d2                	mv	a1,s4
{
ffffffffc020117a:	f426                	sd	s1,40(sp)
ffffffffc020117c:	fc06                	sd	ra,56(sp)
ffffffffc020117e:	f04a                	sd	s2,32(sp)
ffffffffc0201180:	ec4e                	sd	s3,24(sp)
ffffffffc0201182:	e456                	sd	s5,8(sp)
ffffffffc0201184:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201186:	ccfff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
    if (ptep == NULL)
ffffffffc020118a:	c961                	beqz	a0,ffffffffc020125a <page_insert+0xee>
    page->ref += 1;
ffffffffc020118c:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020118e:	611c                	ld	a5,0(a0)
ffffffffc0201190:	89aa                	mv	s3,a0
ffffffffc0201192:	0016871b          	addiw	a4,a3,1
ffffffffc0201196:	c018                	sw	a4,0(s0)
ffffffffc0201198:	0017f713          	andi	a4,a5,1
ffffffffc020119c:	ef05                	bnez	a4,ffffffffc02011d4 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020119e:	0000c717          	auipc	a4,0xc
ffffffffc02011a2:	30273703          	ld	a4,770(a4) # ffffffffc020d4a0 <pages>
ffffffffc02011a6:	8c19                	sub	s0,s0,a4
ffffffffc02011a8:	000807b7          	lui	a5,0x80
ffffffffc02011ac:	8419                	srai	s0,s0,0x6
ffffffffc02011ae:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02011b0:	042a                	slli	s0,s0,0xa
ffffffffc02011b2:	8cc1                	or	s1,s1,s0
ffffffffc02011b4:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02011b8:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02011bc:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02011c0:	4501                	li	a0,0
}
ffffffffc02011c2:	70e2                	ld	ra,56(sp)
ffffffffc02011c4:	7442                	ld	s0,48(sp)
ffffffffc02011c6:	74a2                	ld	s1,40(sp)
ffffffffc02011c8:	7902                	ld	s2,32(sp)
ffffffffc02011ca:	69e2                	ld	s3,24(sp)
ffffffffc02011cc:	6a42                	ld	s4,16(sp)
ffffffffc02011ce:	6aa2                	ld	s5,8(sp)
ffffffffc02011d0:	6121                	addi	sp,sp,64
ffffffffc02011d2:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02011d4:	078a                	slli	a5,a5,0x2
ffffffffc02011d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02011d8:	0000c717          	auipc	a4,0xc
ffffffffc02011dc:	2c073703          	ld	a4,704(a4) # ffffffffc020d498 <npage>
ffffffffc02011e0:	06e7ff63          	bgeu	a5,a4,ffffffffc020125e <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02011e4:	0000ca97          	auipc	s5,0xc
ffffffffc02011e8:	2bca8a93          	addi	s5,s5,700 # ffffffffc020d4a0 <pages>
ffffffffc02011ec:	000ab703          	ld	a4,0(s5)
ffffffffc02011f0:	fff80937          	lui	s2,0xfff80
ffffffffc02011f4:	993e                	add	s2,s2,a5
ffffffffc02011f6:	091a                	slli	s2,s2,0x6
ffffffffc02011f8:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02011fa:	01240c63          	beq	s0,s2,ffffffffc0201212 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02011fe:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b24>
ffffffffc0201202:	fff7869b          	addiw	a3,a5,-1
ffffffffc0201206:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020120a:	c691                	beqz	a3,ffffffffc0201216 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020120c:	120a0073          	sfence.vma	s4
}
ffffffffc0201210:	bf59                	j	ffffffffc02011a6 <page_insert+0x3a>
ffffffffc0201212:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201214:	bf49                	j	ffffffffc02011a6 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201216:	100027f3          	csrr	a5,sstatus
ffffffffc020121a:	8b89                	andi	a5,a5,2
ffffffffc020121c:	ef91                	bnez	a5,ffffffffc0201238 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020121e:	0000c797          	auipc	a5,0xc
ffffffffc0201222:	28a7b783          	ld	a5,650(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0201226:	739c                	ld	a5,32(a5)
ffffffffc0201228:	4585                	li	a1,1
ffffffffc020122a:	854a                	mv	a0,s2
ffffffffc020122c:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020122e:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201232:	120a0073          	sfence.vma	s4
ffffffffc0201236:	bf85                	j	ffffffffc02011a6 <page_insert+0x3a>
        intr_disable();
ffffffffc0201238:	ee4ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020123c:	0000c797          	auipc	a5,0xc
ffffffffc0201240:	26c7b783          	ld	a5,620(a5) # ffffffffc020d4a8 <pmm_manager>
ffffffffc0201244:	739c                	ld	a5,32(a5)
ffffffffc0201246:	4585                	li	a1,1
ffffffffc0201248:	854a                	mv	a0,s2
ffffffffc020124a:	9782                	jalr	a5
        intr_enable();
ffffffffc020124c:	ecaff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201250:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201254:	120a0073          	sfence.vma	s4
ffffffffc0201258:	b7b9                	j	ffffffffc02011a6 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020125a:	5571                	li	a0,-4
ffffffffc020125c:	b79d                	j	ffffffffc02011c2 <page_insert+0x56>
ffffffffc020125e:	b09ff0ef          	jal	ra,ffffffffc0200d66 <pa2page.part.0>

ffffffffc0201262 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201262:	00004797          	auipc	a5,0x4
ffffffffc0201266:	ece78793          	addi	a5,a5,-306 # ffffffffc0205130 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020126a:	638c                	ld	a1,0(a5)
{
ffffffffc020126c:	7159                	addi	sp,sp,-112
ffffffffc020126e:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201270:	00003517          	auipc	a0,0x3
ffffffffc0201274:	2a850513          	addi	a0,a0,680 # ffffffffc0204518 <commands+0x868>
    pmm_manager = &default_pmm_manager;
ffffffffc0201278:	0000cb17          	auipc	s6,0xc
ffffffffc020127c:	230b0b13          	addi	s6,s6,560 # ffffffffc020d4a8 <pmm_manager>
{
ffffffffc0201280:	f486                	sd	ra,104(sp)
ffffffffc0201282:	e8ca                	sd	s2,80(sp)
ffffffffc0201284:	e4ce                	sd	s3,72(sp)
ffffffffc0201286:	f0a2                	sd	s0,96(sp)
ffffffffc0201288:	eca6                	sd	s1,88(sp)
ffffffffc020128a:	e0d2                	sd	s4,64(sp)
ffffffffc020128c:	fc56                	sd	s5,56(sp)
ffffffffc020128e:	f45e                	sd	s7,40(sp)
ffffffffc0201290:	f062                	sd	s8,32(sp)
ffffffffc0201292:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201294:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201298:	e49fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    pmm_manager->init();
ffffffffc020129c:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012a0:	0000c997          	auipc	s3,0xc
ffffffffc02012a4:	21098993          	addi	s3,s3,528 # ffffffffc020d4b0 <va_pa_offset>
    pmm_manager->init();
ffffffffc02012a8:	679c                	ld	a5,8(a5)
ffffffffc02012aa:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012ac:	57f5                	li	a5,-3
ffffffffc02012ae:	07fa                	slli	a5,a5,0x1e
ffffffffc02012b0:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02012b4:	da0ff0ef          	jal	ra,ffffffffc0200854 <get_memory_base>
ffffffffc02012b8:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02012ba:	da4ff0ef          	jal	ra,ffffffffc020085e <get_memory_size>
    if (mem_size == 0) {
ffffffffc02012be:	200505e3          	beqz	a0,ffffffffc0201cc8 <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02012c2:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02012c4:	00003517          	auipc	a0,0x3
ffffffffc02012c8:	28c50513          	addi	a0,a0,652 # ffffffffc0204550 <commands+0x8a0>
ffffffffc02012cc:	e15fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02012d0:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02012d4:	fff40693          	addi	a3,s0,-1
ffffffffc02012d8:	864a                	mv	a2,s2
ffffffffc02012da:	85a6                	mv	a1,s1
ffffffffc02012dc:	00003517          	auipc	a0,0x3
ffffffffc02012e0:	28c50513          	addi	a0,a0,652 # ffffffffc0204568 <commands+0x8b8>
ffffffffc02012e4:	dfdfe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02012e8:	c8000737          	lui	a4,0xc8000
ffffffffc02012ec:	87a2                	mv	a5,s0
ffffffffc02012ee:	54876163          	bltu	a4,s0,ffffffffc0201830 <pmm_init+0x5ce>
ffffffffc02012f2:	757d                	lui	a0,0xfffff
ffffffffc02012f4:	0000d617          	auipc	a2,0xd
ffffffffc02012f8:	1e760613          	addi	a2,a2,487 # ffffffffc020e4db <end+0xfff>
ffffffffc02012fc:	8e69                	and	a2,a2,a0
ffffffffc02012fe:	0000c497          	auipc	s1,0xc
ffffffffc0201302:	19a48493          	addi	s1,s1,410 # ffffffffc020d498 <npage>
ffffffffc0201306:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020130a:	0000cb97          	auipc	s7,0xc
ffffffffc020130e:	196b8b93          	addi	s7,s7,406 # ffffffffc020d4a0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201312:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201314:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201318:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020131c:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020131e:	02f50863          	beq	a0,a5,ffffffffc020134e <pmm_init+0xec>
ffffffffc0201322:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201324:	4585                	li	a1,1
ffffffffc0201326:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020132a:	00679513          	slli	a0,a5,0x6
ffffffffc020132e:	9532                	add	a0,a0,a2
ffffffffc0201330:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b2c>
ffffffffc0201334:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201338:	6088                	ld	a0,0(s1)
ffffffffc020133a:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020133c:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201340:	00d50733          	add	a4,a0,a3
ffffffffc0201344:	fee7e3e3          	bltu	a5,a4,ffffffffc020132a <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201348:	071a                	slli	a4,a4,0x6
ffffffffc020134a:	00e606b3          	add	a3,a2,a4
ffffffffc020134e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201352:	2ef6ece3          	bltu	a3,a5,ffffffffc0201e4a <pmm_init+0xbe8>
ffffffffc0201356:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020135a:	77fd                	lui	a5,0xfffff
ffffffffc020135c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020135e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0201360:	5086eb63          	bltu	a3,s0,ffffffffc0201876 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0201364:	00003517          	auipc	a0,0x3
ffffffffc0201368:	25450513          	addi	a0,a0,596 # ffffffffc02045b8 <commands+0x908>
ffffffffc020136c:	d75fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201370:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0201374:	0000c917          	auipc	s2,0xc
ffffffffc0201378:	11c90913          	addi	s2,s2,284 # ffffffffc020d490 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020137c:	7b9c                	ld	a5,48(a5)
ffffffffc020137e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201380:	00003517          	auipc	a0,0x3
ffffffffc0201384:	25050513          	addi	a0,a0,592 # ffffffffc02045d0 <commands+0x920>
ffffffffc0201388:	d59fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020138c:	00007697          	auipc	a3,0x7
ffffffffc0201390:	c7468693          	addi	a3,a3,-908 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0201394:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0201398:	c02007b7          	lui	a5,0xc0200
ffffffffc020139c:	28f6ebe3          	bltu	a3,a5,ffffffffc0201e32 <pmm_init+0xbd0>
ffffffffc02013a0:	0009b783          	ld	a5,0(s3)
ffffffffc02013a4:	8e9d                	sub	a3,a3,a5
ffffffffc02013a6:	0000c797          	auipc	a5,0xc
ffffffffc02013aa:	0ed7b123          	sd	a3,226(a5) # ffffffffc020d488 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02013ae:	100027f3          	csrr	a5,sstatus
ffffffffc02013b2:	8b89                	andi	a5,a5,2
ffffffffc02013b4:	4a079763          	bnez	a5,ffffffffc0201862 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02013b8:	000b3783          	ld	a5,0(s6)
ffffffffc02013bc:	779c                	ld	a5,40(a5)
ffffffffc02013be:	9782                	jalr	a5
ffffffffc02013c0:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02013c2:	6098                	ld	a4,0(s1)
ffffffffc02013c4:	c80007b7          	lui	a5,0xc8000
ffffffffc02013c8:	83b1                	srli	a5,a5,0xc
ffffffffc02013ca:	66e7e363          	bltu	a5,a4,ffffffffc0201a30 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02013ce:	00093503          	ld	a0,0(s2)
ffffffffc02013d2:	62050f63          	beqz	a0,ffffffffc0201a10 <pmm_init+0x7ae>
ffffffffc02013d6:	03451793          	slli	a5,a0,0x34
ffffffffc02013da:	62079b63          	bnez	a5,ffffffffc0201a10 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02013de:	4601                	li	a2,0
ffffffffc02013e0:	4581                	li	a1,0
ffffffffc02013e2:	c9bff0ef          	jal	ra,ffffffffc020107c <get_page>
ffffffffc02013e6:	60051563          	bnez	a0,ffffffffc02019f0 <pmm_init+0x78e>
ffffffffc02013ea:	100027f3          	csrr	a5,sstatus
ffffffffc02013ee:	8b89                	andi	a5,a5,2
ffffffffc02013f0:	44079e63          	bnez	a5,ffffffffc020184c <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02013f4:	000b3783          	ld	a5,0(s6)
ffffffffc02013f8:	4505                	li	a0,1
ffffffffc02013fa:	6f9c                	ld	a5,24(a5)
ffffffffc02013fc:	9782                	jalr	a5
ffffffffc02013fe:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201400:	00093503          	ld	a0,0(s2)
ffffffffc0201404:	4681                	li	a3,0
ffffffffc0201406:	4601                	li	a2,0
ffffffffc0201408:	85d2                	mv	a1,s4
ffffffffc020140a:	d63ff0ef          	jal	ra,ffffffffc020116c <page_insert>
ffffffffc020140e:	26051ae3          	bnez	a0,ffffffffc0201e82 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201412:	00093503          	ld	a0,0(s2)
ffffffffc0201416:	4601                	li	a2,0
ffffffffc0201418:	4581                	li	a1,0
ffffffffc020141a:	a3bff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
ffffffffc020141e:	240502e3          	beqz	a0,ffffffffc0201e62 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0201422:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201424:	0017f713          	andi	a4,a5,1
ffffffffc0201428:	5a070263          	beqz	a4,ffffffffc02019cc <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020142c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020142e:	078a                	slli	a5,a5,0x2
ffffffffc0201430:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201432:	58e7fb63          	bgeu	a5,a4,ffffffffc02019c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201436:	000bb683          	ld	a3,0(s7)
ffffffffc020143a:	fff80637          	lui	a2,0xfff80
ffffffffc020143e:	97b2                	add	a5,a5,a2
ffffffffc0201440:	079a                	slli	a5,a5,0x6
ffffffffc0201442:	97b6                	add	a5,a5,a3
ffffffffc0201444:	14fa17e3          	bne	s4,a5,ffffffffc0201d92 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0201448:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc020144c:	4785                	li	a5,1
ffffffffc020144e:	12f692e3          	bne	a3,a5,ffffffffc0201d72 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0201452:	00093503          	ld	a0,0(s2)
ffffffffc0201456:	77fd                	lui	a5,0xfffff
ffffffffc0201458:	6114                	ld	a3,0(a0)
ffffffffc020145a:	068a                	slli	a3,a3,0x2
ffffffffc020145c:	8efd                	and	a3,a3,a5
ffffffffc020145e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0201462:	0ee67ce3          	bgeu	a2,a4,ffffffffc0201d5a <pmm_init+0xaf8>
ffffffffc0201466:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020146a:	96e2                	add	a3,a3,s8
ffffffffc020146c:	0006ba83          	ld	s5,0(a3)
ffffffffc0201470:	0a8a                	slli	s5,s5,0x2
ffffffffc0201472:	00fafab3          	and	s5,s5,a5
ffffffffc0201476:	00cad793          	srli	a5,s5,0xc
ffffffffc020147a:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0201d40 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020147e:	4601                	li	a2,0
ffffffffc0201480:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201482:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201484:	9d1ff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201488:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020148a:	55551363          	bne	a0,s5,ffffffffc02019d0 <pmm_init+0x76e>
ffffffffc020148e:	100027f3          	csrr	a5,sstatus
ffffffffc0201492:	8b89                	andi	a5,a5,2
ffffffffc0201494:	3a079163          	bnez	a5,ffffffffc0201836 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201498:	000b3783          	ld	a5,0(s6)
ffffffffc020149c:	4505                	li	a0,1
ffffffffc020149e:	6f9c                	ld	a5,24(a5)
ffffffffc02014a0:	9782                	jalr	a5
ffffffffc02014a2:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02014a4:	00093503          	ld	a0,0(s2)
ffffffffc02014a8:	46d1                	li	a3,20
ffffffffc02014aa:	6605                	lui	a2,0x1
ffffffffc02014ac:	85e2                	mv	a1,s8
ffffffffc02014ae:	cbfff0ef          	jal	ra,ffffffffc020116c <page_insert>
ffffffffc02014b2:	060517e3          	bnez	a0,ffffffffc0201d20 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02014b6:	00093503          	ld	a0,0(s2)
ffffffffc02014ba:	4601                	li	a2,0
ffffffffc02014bc:	6585                	lui	a1,0x1
ffffffffc02014be:	997ff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
ffffffffc02014c2:	02050fe3          	beqz	a0,ffffffffc0201d00 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02014c6:	611c                	ld	a5,0(a0)
ffffffffc02014c8:	0107f713          	andi	a4,a5,16
ffffffffc02014cc:	7c070e63          	beqz	a4,ffffffffc0201ca8 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02014d0:	8b91                	andi	a5,a5,4
ffffffffc02014d2:	7a078b63          	beqz	a5,ffffffffc0201c88 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02014d6:	00093503          	ld	a0,0(s2)
ffffffffc02014da:	611c                	ld	a5,0(a0)
ffffffffc02014dc:	8bc1                	andi	a5,a5,16
ffffffffc02014de:	78078563          	beqz	a5,ffffffffc0201c68 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02014e2:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02014e6:	4785                	li	a5,1
ffffffffc02014e8:	76f71063          	bne	a4,a5,ffffffffc0201c48 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02014ec:	4681                	li	a3,0
ffffffffc02014ee:	6605                	lui	a2,0x1
ffffffffc02014f0:	85d2                	mv	a1,s4
ffffffffc02014f2:	c7bff0ef          	jal	ra,ffffffffc020116c <page_insert>
ffffffffc02014f6:	72051963          	bnez	a0,ffffffffc0201c28 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02014fa:	000a2703          	lw	a4,0(s4)
ffffffffc02014fe:	4789                	li	a5,2
ffffffffc0201500:	70f71463          	bne	a4,a5,ffffffffc0201c08 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0201504:	000c2783          	lw	a5,0(s8)
ffffffffc0201508:	6e079063          	bnez	a5,ffffffffc0201be8 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020150c:	00093503          	ld	a0,0(s2)
ffffffffc0201510:	4601                	li	a2,0
ffffffffc0201512:	6585                	lui	a1,0x1
ffffffffc0201514:	941ff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
ffffffffc0201518:	6a050863          	beqz	a0,ffffffffc0201bc8 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc020151c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020151e:	00177793          	andi	a5,a4,1
ffffffffc0201522:	4a078563          	beqz	a5,ffffffffc02019cc <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0201526:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201528:	00271793          	slli	a5,a4,0x2
ffffffffc020152c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020152e:	48d7fd63          	bgeu	a5,a3,ffffffffc02019c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201532:	000bb683          	ld	a3,0(s7)
ffffffffc0201536:	fff80ab7          	lui	s5,0xfff80
ffffffffc020153a:	97d6                	add	a5,a5,s5
ffffffffc020153c:	079a                	slli	a5,a5,0x6
ffffffffc020153e:	97b6                	add	a5,a5,a3
ffffffffc0201540:	66fa1463          	bne	s4,a5,ffffffffc0201ba8 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201544:	8b41                	andi	a4,a4,16
ffffffffc0201546:	64071163          	bnez	a4,ffffffffc0201b88 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020154a:	00093503          	ld	a0,0(s2)
ffffffffc020154e:	4581                	li	a1,0
ffffffffc0201550:	b81ff0ef          	jal	ra,ffffffffc02010d0 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201554:	000a2c83          	lw	s9,0(s4)
ffffffffc0201558:	4785                	li	a5,1
ffffffffc020155a:	60fc9763          	bne	s9,a5,ffffffffc0201b68 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc020155e:	000c2783          	lw	a5,0(s8)
ffffffffc0201562:	5e079363          	bnez	a5,ffffffffc0201b48 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0201566:	00093503          	ld	a0,0(s2)
ffffffffc020156a:	6585                	lui	a1,0x1
ffffffffc020156c:	b65ff0ef          	jal	ra,ffffffffc02010d0 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201570:	000a2783          	lw	a5,0(s4)
ffffffffc0201574:	52079a63          	bnez	a5,ffffffffc0201aa8 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0201578:	000c2783          	lw	a5,0(s8)
ffffffffc020157c:	50079663          	bnez	a5,ffffffffc0201a88 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0201580:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0201584:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201586:	000a3683          	ld	a3,0(s4)
ffffffffc020158a:	068a                	slli	a3,a3,0x2
ffffffffc020158c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020158e:	42b6fd63          	bgeu	a3,a1,ffffffffc02019c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201592:	000bb503          	ld	a0,0(s7)
ffffffffc0201596:	96d6                	add	a3,a3,s5
ffffffffc0201598:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020159a:	00d507b3          	add	a5,a0,a3
ffffffffc020159e:	439c                	lw	a5,0(a5)
ffffffffc02015a0:	4d979463          	bne	a5,s9,ffffffffc0201a68 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc02015a4:	8699                	srai	a3,a3,0x6
ffffffffc02015a6:	00080637          	lui	a2,0x80
ffffffffc02015aa:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02015ac:	00c69713          	slli	a4,a3,0xc
ffffffffc02015b0:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02015b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02015b4:	48b77e63          	bgeu	a4,a1,ffffffffc0201a50 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02015b8:	0009b703          	ld	a4,0(s3)
ffffffffc02015bc:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02015be:	629c                	ld	a5,0(a3)
ffffffffc02015c0:	078a                	slli	a5,a5,0x2
ffffffffc02015c2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02015c4:	40b7f263          	bgeu	a5,a1,ffffffffc02019c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02015c8:	8f91                	sub	a5,a5,a2
ffffffffc02015ca:	079a                	slli	a5,a5,0x6
ffffffffc02015cc:	953e                	add	a0,a0,a5
ffffffffc02015ce:	100027f3          	csrr	a5,sstatus
ffffffffc02015d2:	8b89                	andi	a5,a5,2
ffffffffc02015d4:	30079963          	bnez	a5,ffffffffc02018e6 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02015d8:	000b3783          	ld	a5,0(s6)
ffffffffc02015dc:	4585                	li	a1,1
ffffffffc02015de:	739c                	ld	a5,32(a5)
ffffffffc02015e0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02015e2:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02015e6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02015e8:	078a                	slli	a5,a5,0x2
ffffffffc02015ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02015ec:	3ce7fe63          	bgeu	a5,a4,ffffffffc02019c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02015f0:	000bb503          	ld	a0,0(s7)
ffffffffc02015f4:	fff80737          	lui	a4,0xfff80
ffffffffc02015f8:	97ba                	add	a5,a5,a4
ffffffffc02015fa:	079a                	slli	a5,a5,0x6
ffffffffc02015fc:	953e                	add	a0,a0,a5
ffffffffc02015fe:	100027f3          	csrr	a5,sstatus
ffffffffc0201602:	8b89                	andi	a5,a5,2
ffffffffc0201604:	2c079563          	bnez	a5,ffffffffc02018ce <pmm_init+0x66c>
ffffffffc0201608:	000b3783          	ld	a5,0(s6)
ffffffffc020160c:	4585                	li	a1,1
ffffffffc020160e:	739c                	ld	a5,32(a5)
ffffffffc0201610:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201612:	00093783          	ld	a5,0(s2)
ffffffffc0201616:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b24>
    asm volatile("sfence.vma");
ffffffffc020161a:	12000073          	sfence.vma
ffffffffc020161e:	100027f3          	csrr	a5,sstatus
ffffffffc0201622:	8b89                	andi	a5,a5,2
ffffffffc0201624:	28079b63          	bnez	a5,ffffffffc02018ba <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201628:	000b3783          	ld	a5,0(s6)
ffffffffc020162c:	779c                	ld	a5,40(a5)
ffffffffc020162e:	9782                	jalr	a5
ffffffffc0201630:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0201632:	4b441b63          	bne	s0,s4,ffffffffc0201ae8 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201636:	00003517          	auipc	a0,0x3
ffffffffc020163a:	2da50513          	addi	a0,a0,730 # ffffffffc0204910 <commands+0xc60>
ffffffffc020163e:	aa3fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0201642:	100027f3          	csrr	a5,sstatus
ffffffffc0201646:	8b89                	andi	a5,a5,2
ffffffffc0201648:	24079f63          	bnez	a5,ffffffffc02018a6 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc020164c:	000b3783          	ld	a5,0(s6)
ffffffffc0201650:	779c                	ld	a5,40(a5)
ffffffffc0201652:	9782                	jalr	a5
ffffffffc0201654:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201656:	6098                	ld	a4,0(s1)
ffffffffc0201658:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020165c:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020165e:	00c71793          	slli	a5,a4,0xc
ffffffffc0201662:	6a05                	lui	s4,0x1
ffffffffc0201664:	02f47c63          	bgeu	s0,a5,ffffffffc020169c <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201668:	00c45793          	srli	a5,s0,0xc
ffffffffc020166c:	00093503          	ld	a0,0(s2)
ffffffffc0201670:	2ee7ff63          	bgeu	a5,a4,ffffffffc020196e <pmm_init+0x70c>
ffffffffc0201674:	0009b583          	ld	a1,0(s3)
ffffffffc0201678:	4601                	li	a2,0
ffffffffc020167a:	95a2                	add	a1,a1,s0
ffffffffc020167c:	fd8ff0ef          	jal	ra,ffffffffc0200e54 <get_pte>
ffffffffc0201680:	32050463          	beqz	a0,ffffffffc02019a8 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201684:	611c                	ld	a5,0(a0)
ffffffffc0201686:	078a                	slli	a5,a5,0x2
ffffffffc0201688:	0157f7b3          	and	a5,a5,s5
ffffffffc020168c:	2e879e63          	bne	a5,s0,ffffffffc0201988 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201690:	6098                	ld	a4,0(s1)
ffffffffc0201692:	9452                	add	s0,s0,s4
ffffffffc0201694:	00c71793          	slli	a5,a4,0xc
ffffffffc0201698:	fcf468e3          	bltu	s0,a5,ffffffffc0201668 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc020169c:	00093783          	ld	a5,0(s2)
ffffffffc02016a0:	639c                	ld	a5,0(a5)
ffffffffc02016a2:	42079363          	bnez	a5,ffffffffc0201ac8 <pmm_init+0x866>
ffffffffc02016a6:	100027f3          	csrr	a5,sstatus
ffffffffc02016aa:	8b89                	andi	a5,a5,2
ffffffffc02016ac:	24079963          	bnez	a5,ffffffffc02018fe <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02016b0:	000b3783          	ld	a5,0(s6)
ffffffffc02016b4:	4505                	li	a0,1
ffffffffc02016b6:	6f9c                	ld	a5,24(a5)
ffffffffc02016b8:	9782                	jalr	a5
ffffffffc02016ba:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02016bc:	00093503          	ld	a0,0(s2)
ffffffffc02016c0:	4699                	li	a3,6
ffffffffc02016c2:	10000613          	li	a2,256
ffffffffc02016c6:	85d2                	mv	a1,s4
ffffffffc02016c8:	aa5ff0ef          	jal	ra,ffffffffc020116c <page_insert>
ffffffffc02016cc:	44051e63          	bnez	a0,ffffffffc0201b28 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc02016d0:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02016d4:	4785                	li	a5,1
ffffffffc02016d6:	42f71963          	bne	a4,a5,ffffffffc0201b08 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02016da:	00093503          	ld	a0,0(s2)
ffffffffc02016de:	6405                	lui	s0,0x1
ffffffffc02016e0:	4699                	li	a3,6
ffffffffc02016e2:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02016e6:	85d2                	mv	a1,s4
ffffffffc02016e8:	a85ff0ef          	jal	ra,ffffffffc020116c <page_insert>
ffffffffc02016ec:	72051363          	bnez	a0,ffffffffc0201e12 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc02016f0:	000a2703          	lw	a4,0(s4)
ffffffffc02016f4:	4789                	li	a5,2
ffffffffc02016f6:	6ef71e63          	bne	a4,a5,ffffffffc0201df2 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02016fa:	00003597          	auipc	a1,0x3
ffffffffc02016fe:	35e58593          	addi	a1,a1,862 # ffffffffc0204a58 <commands+0xda8>
ffffffffc0201702:	10000513          	li	a0,256
ffffffffc0201706:	663010ef          	jal	ra,ffffffffc0203568 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020170a:	10040593          	addi	a1,s0,256
ffffffffc020170e:	10000513          	li	a0,256
ffffffffc0201712:	669010ef          	jal	ra,ffffffffc020357a <strcmp>
ffffffffc0201716:	6a051e63          	bnez	a0,ffffffffc0201dd2 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020171a:	000bb683          	ld	a3,0(s7)
ffffffffc020171e:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0201722:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0201724:	40da06b3          	sub	a3,s4,a3
ffffffffc0201728:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020172a:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc020172c:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc020172e:	8031                	srli	s0,s0,0xc
ffffffffc0201730:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201734:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201736:	30f77d63          	bgeu	a4,a5,ffffffffc0201a50 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020173a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020173e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201742:	96be                	add	a3,a3,a5
ffffffffc0201744:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201748:	5eb010ef          	jal	ra,ffffffffc0203532 <strlen>
ffffffffc020174c:	66051363          	bnez	a0,ffffffffc0201db2 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0201750:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0201754:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201756:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b24>
ffffffffc020175a:	068a                	slli	a3,a3,0x2
ffffffffc020175c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020175e:	26f6f563          	bgeu	a3,a5,ffffffffc02019c8 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0201762:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201764:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201766:	2ef47563          	bgeu	s0,a5,ffffffffc0201a50 <pmm_init+0x7ee>
ffffffffc020176a:	0009b403          	ld	s0,0(s3)
ffffffffc020176e:	9436                	add	s0,s0,a3
ffffffffc0201770:	100027f3          	csrr	a5,sstatus
ffffffffc0201774:	8b89                	andi	a5,a5,2
ffffffffc0201776:	1e079163          	bnez	a5,ffffffffc0201958 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc020177a:	000b3783          	ld	a5,0(s6)
ffffffffc020177e:	4585                	li	a1,1
ffffffffc0201780:	8552                	mv	a0,s4
ffffffffc0201782:	739c                	ld	a5,32(a5)
ffffffffc0201784:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201786:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0201788:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020178a:	078a                	slli	a5,a5,0x2
ffffffffc020178c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020178e:	22e7fd63          	bgeu	a5,a4,ffffffffc02019c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201792:	000bb503          	ld	a0,0(s7)
ffffffffc0201796:	fff80737          	lui	a4,0xfff80
ffffffffc020179a:	97ba                	add	a5,a5,a4
ffffffffc020179c:	079a                	slli	a5,a5,0x6
ffffffffc020179e:	953e                	add	a0,a0,a5
ffffffffc02017a0:	100027f3          	csrr	a5,sstatus
ffffffffc02017a4:	8b89                	andi	a5,a5,2
ffffffffc02017a6:	18079d63          	bnez	a5,ffffffffc0201940 <pmm_init+0x6de>
ffffffffc02017aa:	000b3783          	ld	a5,0(s6)
ffffffffc02017ae:	4585                	li	a1,1
ffffffffc02017b0:	739c                	ld	a5,32(a5)
ffffffffc02017b2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02017b4:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc02017b8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02017ba:	078a                	slli	a5,a5,0x2
ffffffffc02017bc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02017be:	20e7f563          	bgeu	a5,a4,ffffffffc02019c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02017c2:	000bb503          	ld	a0,0(s7)
ffffffffc02017c6:	fff80737          	lui	a4,0xfff80
ffffffffc02017ca:	97ba                	add	a5,a5,a4
ffffffffc02017cc:	079a                	slli	a5,a5,0x6
ffffffffc02017ce:	953e                	add	a0,a0,a5
ffffffffc02017d0:	100027f3          	csrr	a5,sstatus
ffffffffc02017d4:	8b89                	andi	a5,a5,2
ffffffffc02017d6:	14079963          	bnez	a5,ffffffffc0201928 <pmm_init+0x6c6>
ffffffffc02017da:	000b3783          	ld	a5,0(s6)
ffffffffc02017de:	4585                	li	a1,1
ffffffffc02017e0:	739c                	ld	a5,32(a5)
ffffffffc02017e2:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02017e4:	00093783          	ld	a5,0(s2)
ffffffffc02017e8:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02017ec:	12000073          	sfence.vma
ffffffffc02017f0:	100027f3          	csrr	a5,sstatus
ffffffffc02017f4:	8b89                	andi	a5,a5,2
ffffffffc02017f6:	10079f63          	bnez	a5,ffffffffc0201914 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02017fa:	000b3783          	ld	a5,0(s6)
ffffffffc02017fe:	779c                	ld	a5,40(a5)
ffffffffc0201800:	9782                	jalr	a5
ffffffffc0201802:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0201804:	4c8c1e63          	bne	s8,s0,ffffffffc0201ce0 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201808:	00003517          	auipc	a0,0x3
ffffffffc020180c:	2c850513          	addi	a0,a0,712 # ffffffffc0204ad0 <commands+0xe20>
ffffffffc0201810:	8d1fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0201814:	7406                	ld	s0,96(sp)
ffffffffc0201816:	70a6                	ld	ra,104(sp)
ffffffffc0201818:	64e6                	ld	s1,88(sp)
ffffffffc020181a:	6946                	ld	s2,80(sp)
ffffffffc020181c:	69a6                	ld	s3,72(sp)
ffffffffc020181e:	6a06                	ld	s4,64(sp)
ffffffffc0201820:	7ae2                	ld	s5,56(sp)
ffffffffc0201822:	7b42                	ld	s6,48(sp)
ffffffffc0201824:	7ba2                	ld	s7,40(sp)
ffffffffc0201826:	7c02                	ld	s8,32(sp)
ffffffffc0201828:	6ce2                	ld	s9,24(sp)
ffffffffc020182a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc020182c:	4ef0006f          	j	ffffffffc020251a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0201830:	c80007b7          	lui	a5,0xc8000
ffffffffc0201834:	bc7d                	j	ffffffffc02012f2 <pmm_init+0x90>
        intr_disable();
ffffffffc0201836:	8e6ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020183a:	000b3783          	ld	a5,0(s6)
ffffffffc020183e:	4505                	li	a0,1
ffffffffc0201840:	6f9c                	ld	a5,24(a5)
ffffffffc0201842:	9782                	jalr	a5
ffffffffc0201844:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201846:	8d0ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc020184a:	b9a9                	j	ffffffffc02014a4 <pmm_init+0x242>
        intr_disable();
ffffffffc020184c:	8d0ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc0201850:	000b3783          	ld	a5,0(s6)
ffffffffc0201854:	4505                	li	a0,1
ffffffffc0201856:	6f9c                	ld	a5,24(a5)
ffffffffc0201858:	9782                	jalr	a5
ffffffffc020185a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020185c:	8baff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201860:	b645                	j	ffffffffc0201400 <pmm_init+0x19e>
        intr_disable();
ffffffffc0201862:	8baff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201866:	000b3783          	ld	a5,0(s6)
ffffffffc020186a:	779c                	ld	a5,40(a5)
ffffffffc020186c:	9782                	jalr	a5
ffffffffc020186e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201870:	8a6ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201874:	b6b9                	j	ffffffffc02013c2 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201876:	6705                	lui	a4,0x1
ffffffffc0201878:	177d                	addi	a4,a4,-1
ffffffffc020187a:	96ba                	add	a3,a3,a4
ffffffffc020187c:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc020187e:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201882:	14a77363          	bgeu	a4,a0,ffffffffc02019c8 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0201886:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020188a:	fff80537          	lui	a0,0xfff80
ffffffffc020188e:	972a                	add	a4,a4,a0
ffffffffc0201890:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201892:	8c1d                	sub	s0,s0,a5
ffffffffc0201894:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0201898:	00c45593          	srli	a1,s0,0xc
ffffffffc020189c:	9532                	add	a0,a0,a2
ffffffffc020189e:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02018a0:	0009b583          	ld	a1,0(s3)
}
ffffffffc02018a4:	b4c1                	j	ffffffffc0201364 <pmm_init+0x102>
        intr_disable();
ffffffffc02018a6:	876ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02018aa:	000b3783          	ld	a5,0(s6)
ffffffffc02018ae:	779c                	ld	a5,40(a5)
ffffffffc02018b0:	9782                	jalr	a5
ffffffffc02018b2:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02018b4:	862ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc02018b8:	bb79                	j	ffffffffc0201656 <pmm_init+0x3f4>
        intr_disable();
ffffffffc02018ba:	862ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc02018be:	000b3783          	ld	a5,0(s6)
ffffffffc02018c2:	779c                	ld	a5,40(a5)
ffffffffc02018c4:	9782                	jalr	a5
ffffffffc02018c6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02018c8:	84eff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc02018cc:	b39d                	j	ffffffffc0201632 <pmm_init+0x3d0>
ffffffffc02018ce:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02018d0:	84cff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02018d4:	000b3783          	ld	a5,0(s6)
ffffffffc02018d8:	6522                	ld	a0,8(sp)
ffffffffc02018da:	4585                	li	a1,1
ffffffffc02018dc:	739c                	ld	a5,32(a5)
ffffffffc02018de:	9782                	jalr	a5
        intr_enable();
ffffffffc02018e0:	836ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc02018e4:	b33d                	j	ffffffffc0201612 <pmm_init+0x3b0>
ffffffffc02018e6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02018e8:	834ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc02018ec:	000b3783          	ld	a5,0(s6)
ffffffffc02018f0:	6522                	ld	a0,8(sp)
ffffffffc02018f2:	4585                	li	a1,1
ffffffffc02018f4:	739c                	ld	a5,32(a5)
ffffffffc02018f6:	9782                	jalr	a5
        intr_enable();
ffffffffc02018f8:	81eff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc02018fc:	b1dd                	j	ffffffffc02015e2 <pmm_init+0x380>
        intr_disable();
ffffffffc02018fe:	81eff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201902:	000b3783          	ld	a5,0(s6)
ffffffffc0201906:	4505                	li	a0,1
ffffffffc0201908:	6f9c                	ld	a5,24(a5)
ffffffffc020190a:	9782                	jalr	a5
ffffffffc020190c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020190e:	808ff0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201912:	b36d                	j	ffffffffc02016bc <pmm_init+0x45a>
        intr_disable();
ffffffffc0201914:	808ff0ef          	jal	ra,ffffffffc020091c <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201918:	000b3783          	ld	a5,0(s6)
ffffffffc020191c:	779c                	ld	a5,40(a5)
ffffffffc020191e:	9782                	jalr	a5
ffffffffc0201920:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201922:	ff5fe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201926:	bdf9                	j	ffffffffc0201804 <pmm_init+0x5a2>
ffffffffc0201928:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020192a:	ff3fe0ef          	jal	ra,ffffffffc020091c <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020192e:	000b3783          	ld	a5,0(s6)
ffffffffc0201932:	6522                	ld	a0,8(sp)
ffffffffc0201934:	4585                	li	a1,1
ffffffffc0201936:	739c                	ld	a5,32(a5)
ffffffffc0201938:	9782                	jalr	a5
        intr_enable();
ffffffffc020193a:	fddfe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc020193e:	b55d                	j	ffffffffc02017e4 <pmm_init+0x582>
ffffffffc0201940:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201942:	fdbfe0ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc0201946:	000b3783          	ld	a5,0(s6)
ffffffffc020194a:	6522                	ld	a0,8(sp)
ffffffffc020194c:	4585                	li	a1,1
ffffffffc020194e:	739c                	ld	a5,32(a5)
ffffffffc0201950:	9782                	jalr	a5
        intr_enable();
ffffffffc0201952:	fc5fe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc0201956:	bdb9                	j	ffffffffc02017b4 <pmm_init+0x552>
        intr_disable();
ffffffffc0201958:	fc5fe0ef          	jal	ra,ffffffffc020091c <intr_disable>
ffffffffc020195c:	000b3783          	ld	a5,0(s6)
ffffffffc0201960:	4585                	li	a1,1
ffffffffc0201962:	8552                	mv	a0,s4
ffffffffc0201964:	739c                	ld	a5,32(a5)
ffffffffc0201966:	9782                	jalr	a5
        intr_enable();
ffffffffc0201968:	faffe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc020196c:	bd29                	j	ffffffffc0201786 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020196e:	86a2                	mv	a3,s0
ffffffffc0201970:	00003617          	auipc	a2,0x3
ffffffffc0201974:	b7060613          	addi	a2,a2,-1168 # ffffffffc02044e0 <commands+0x830>
ffffffffc0201978:	1a400593          	li	a1,420
ffffffffc020197c:	00003517          	auipc	a0,0x3
ffffffffc0201980:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0204508 <commands+0x858>
ffffffffc0201984:	85bfe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201988:	00003697          	auipc	a3,0x3
ffffffffc020198c:	fe868693          	addi	a3,a3,-24 # ffffffffc0204970 <commands+0xcc0>
ffffffffc0201990:	00003617          	auipc	a2,0x3
ffffffffc0201994:	c8060613          	addi	a2,a2,-896 # ffffffffc0204610 <commands+0x960>
ffffffffc0201998:	1a500593          	li	a1,421
ffffffffc020199c:	00003517          	auipc	a0,0x3
ffffffffc02019a0:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204508 <commands+0x858>
ffffffffc02019a4:	83bfe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02019a8:	00003697          	auipc	a3,0x3
ffffffffc02019ac:	f8868693          	addi	a3,a3,-120 # ffffffffc0204930 <commands+0xc80>
ffffffffc02019b0:	00003617          	auipc	a2,0x3
ffffffffc02019b4:	c6060613          	addi	a2,a2,-928 # ffffffffc0204610 <commands+0x960>
ffffffffc02019b8:	1a400593          	li	a1,420
ffffffffc02019bc:	00003517          	auipc	a0,0x3
ffffffffc02019c0:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0204508 <commands+0x858>
ffffffffc02019c4:	81bfe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc02019c8:	b9eff0ef          	jal	ra,ffffffffc0200d66 <pa2page.part.0>
ffffffffc02019cc:	bb6ff0ef          	jal	ra,ffffffffc0200d82 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02019d0:	00003697          	auipc	a3,0x3
ffffffffc02019d4:	d5868693          	addi	a3,a3,-680 # ffffffffc0204728 <commands+0xa78>
ffffffffc02019d8:	00003617          	auipc	a2,0x3
ffffffffc02019dc:	c3860613          	addi	a2,a2,-968 # ffffffffc0204610 <commands+0x960>
ffffffffc02019e0:	17400593          	li	a1,372
ffffffffc02019e4:	00003517          	auipc	a0,0x3
ffffffffc02019e8:	b2450513          	addi	a0,a0,-1244 # ffffffffc0204508 <commands+0x858>
ffffffffc02019ec:	ff2fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02019f0:	00003697          	auipc	a3,0x3
ffffffffc02019f4:	c7868693          	addi	a3,a3,-904 # ffffffffc0204668 <commands+0x9b8>
ffffffffc02019f8:	00003617          	auipc	a2,0x3
ffffffffc02019fc:	c1860613          	addi	a2,a2,-1000 # ffffffffc0204610 <commands+0x960>
ffffffffc0201a00:	16700593          	li	a1,359
ffffffffc0201a04:	00003517          	auipc	a0,0x3
ffffffffc0201a08:	b0450513          	addi	a0,a0,-1276 # ffffffffc0204508 <commands+0x858>
ffffffffc0201a0c:	fd2fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201a10:	00003697          	auipc	a3,0x3
ffffffffc0201a14:	c1868693          	addi	a3,a3,-1000 # ffffffffc0204628 <commands+0x978>
ffffffffc0201a18:	00003617          	auipc	a2,0x3
ffffffffc0201a1c:	bf860613          	addi	a2,a2,-1032 # ffffffffc0204610 <commands+0x960>
ffffffffc0201a20:	16600593          	li	a1,358
ffffffffc0201a24:	00003517          	auipc	a0,0x3
ffffffffc0201a28:	ae450513          	addi	a0,a0,-1308 # ffffffffc0204508 <commands+0x858>
ffffffffc0201a2c:	fb2fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201a30:	00003697          	auipc	a3,0x3
ffffffffc0201a34:	bc068693          	addi	a3,a3,-1088 # ffffffffc02045f0 <commands+0x940>
ffffffffc0201a38:	00003617          	auipc	a2,0x3
ffffffffc0201a3c:	bd860613          	addi	a2,a2,-1064 # ffffffffc0204610 <commands+0x960>
ffffffffc0201a40:	16500593          	li	a1,357
ffffffffc0201a44:	00003517          	auipc	a0,0x3
ffffffffc0201a48:	ac450513          	addi	a0,a0,-1340 # ffffffffc0204508 <commands+0x858>
ffffffffc0201a4c:	f92fe0ef          	jal	ra,ffffffffc02001de <__panic>
    return KADDR(page2pa(page));
ffffffffc0201a50:	00003617          	auipc	a2,0x3
ffffffffc0201a54:	a9060613          	addi	a2,a2,-1392 # ffffffffc02044e0 <commands+0x830>
ffffffffc0201a58:	07100593          	li	a1,113
ffffffffc0201a5c:	00003517          	auipc	a0,0x3
ffffffffc0201a60:	a4c50513          	addi	a0,a0,-1460 # ffffffffc02044a8 <commands+0x7f8>
ffffffffc0201a64:	f7afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0201a68:	00003697          	auipc	a3,0x3
ffffffffc0201a6c:	e5068693          	addi	a3,a3,-432 # ffffffffc02048b8 <commands+0xc08>
ffffffffc0201a70:	00003617          	auipc	a2,0x3
ffffffffc0201a74:	ba060613          	addi	a2,a2,-1120 # ffffffffc0204610 <commands+0x960>
ffffffffc0201a78:	18d00593          	li	a1,397
ffffffffc0201a7c:	00003517          	auipc	a0,0x3
ffffffffc0201a80:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204508 <commands+0x858>
ffffffffc0201a84:	f5afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201a88:	00003697          	auipc	a3,0x3
ffffffffc0201a8c:	de868693          	addi	a3,a3,-536 # ffffffffc0204870 <commands+0xbc0>
ffffffffc0201a90:	00003617          	auipc	a2,0x3
ffffffffc0201a94:	b8060613          	addi	a2,a2,-1152 # ffffffffc0204610 <commands+0x960>
ffffffffc0201a98:	18b00593          	li	a1,395
ffffffffc0201a9c:	00003517          	auipc	a0,0x3
ffffffffc0201aa0:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0204508 <commands+0x858>
ffffffffc0201aa4:	f3afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201aa8:	00003697          	auipc	a3,0x3
ffffffffc0201aac:	df868693          	addi	a3,a3,-520 # ffffffffc02048a0 <commands+0xbf0>
ffffffffc0201ab0:	00003617          	auipc	a2,0x3
ffffffffc0201ab4:	b6060613          	addi	a2,a2,-1184 # ffffffffc0204610 <commands+0x960>
ffffffffc0201ab8:	18a00593          	li	a1,394
ffffffffc0201abc:	00003517          	auipc	a0,0x3
ffffffffc0201ac0:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0204508 <commands+0x858>
ffffffffc0201ac4:	f1afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0201ac8:	00003697          	auipc	a3,0x3
ffffffffc0201acc:	ec068693          	addi	a3,a3,-320 # ffffffffc0204988 <commands+0xcd8>
ffffffffc0201ad0:	00003617          	auipc	a2,0x3
ffffffffc0201ad4:	b4060613          	addi	a2,a2,-1216 # ffffffffc0204610 <commands+0x960>
ffffffffc0201ad8:	1a800593          	li	a1,424
ffffffffc0201adc:	00003517          	auipc	a0,0x3
ffffffffc0201ae0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0204508 <commands+0x858>
ffffffffc0201ae4:	efafe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201ae8:	00003697          	auipc	a3,0x3
ffffffffc0201aec:	e0068693          	addi	a3,a3,-512 # ffffffffc02048e8 <commands+0xc38>
ffffffffc0201af0:	00003617          	auipc	a2,0x3
ffffffffc0201af4:	b2060613          	addi	a2,a2,-1248 # ffffffffc0204610 <commands+0x960>
ffffffffc0201af8:	19500593          	li	a1,405
ffffffffc0201afc:	00003517          	auipc	a0,0x3
ffffffffc0201b00:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0204508 <commands+0x858>
ffffffffc0201b04:	edafe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201b08:	00003697          	auipc	a3,0x3
ffffffffc0201b0c:	ed868693          	addi	a3,a3,-296 # ffffffffc02049e0 <commands+0xd30>
ffffffffc0201b10:	00003617          	auipc	a2,0x3
ffffffffc0201b14:	b0060613          	addi	a2,a2,-1280 # ffffffffc0204610 <commands+0x960>
ffffffffc0201b18:	1ad00593          	li	a1,429
ffffffffc0201b1c:	00003517          	auipc	a0,0x3
ffffffffc0201b20:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0204508 <commands+0x858>
ffffffffc0201b24:	ebafe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201b28:	00003697          	auipc	a3,0x3
ffffffffc0201b2c:	e7868693          	addi	a3,a3,-392 # ffffffffc02049a0 <commands+0xcf0>
ffffffffc0201b30:	00003617          	auipc	a2,0x3
ffffffffc0201b34:	ae060613          	addi	a2,a2,-1312 # ffffffffc0204610 <commands+0x960>
ffffffffc0201b38:	1ac00593          	li	a1,428
ffffffffc0201b3c:	00003517          	auipc	a0,0x3
ffffffffc0201b40:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0204508 <commands+0x858>
ffffffffc0201b44:	e9afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201b48:	00003697          	auipc	a3,0x3
ffffffffc0201b4c:	d2868693          	addi	a3,a3,-728 # ffffffffc0204870 <commands+0xbc0>
ffffffffc0201b50:	00003617          	auipc	a2,0x3
ffffffffc0201b54:	ac060613          	addi	a2,a2,-1344 # ffffffffc0204610 <commands+0x960>
ffffffffc0201b58:	18700593          	li	a1,391
ffffffffc0201b5c:	00003517          	auipc	a0,0x3
ffffffffc0201b60:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0204508 <commands+0x858>
ffffffffc0201b64:	e7afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201b68:	00003697          	auipc	a3,0x3
ffffffffc0201b6c:	ba868693          	addi	a3,a3,-1112 # ffffffffc0204710 <commands+0xa60>
ffffffffc0201b70:	00003617          	auipc	a2,0x3
ffffffffc0201b74:	aa060613          	addi	a2,a2,-1376 # ffffffffc0204610 <commands+0x960>
ffffffffc0201b78:	18600593          	li	a1,390
ffffffffc0201b7c:	00003517          	auipc	a0,0x3
ffffffffc0201b80:	98c50513          	addi	a0,a0,-1652 # ffffffffc0204508 <commands+0x858>
ffffffffc0201b84:	e5afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201b88:	00003697          	auipc	a3,0x3
ffffffffc0201b8c:	d0068693          	addi	a3,a3,-768 # ffffffffc0204888 <commands+0xbd8>
ffffffffc0201b90:	00003617          	auipc	a2,0x3
ffffffffc0201b94:	a8060613          	addi	a2,a2,-1408 # ffffffffc0204610 <commands+0x960>
ffffffffc0201b98:	18300593          	li	a1,387
ffffffffc0201b9c:	00003517          	auipc	a0,0x3
ffffffffc0201ba0:	96c50513          	addi	a0,a0,-1684 # ffffffffc0204508 <commands+0x858>
ffffffffc0201ba4:	e3afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201ba8:	00003697          	auipc	a3,0x3
ffffffffc0201bac:	b5068693          	addi	a3,a3,-1200 # ffffffffc02046f8 <commands+0xa48>
ffffffffc0201bb0:	00003617          	auipc	a2,0x3
ffffffffc0201bb4:	a6060613          	addi	a2,a2,-1440 # ffffffffc0204610 <commands+0x960>
ffffffffc0201bb8:	18200593          	li	a1,386
ffffffffc0201bbc:	00003517          	auipc	a0,0x3
ffffffffc0201bc0:	94c50513          	addi	a0,a0,-1716 # ffffffffc0204508 <commands+0x858>
ffffffffc0201bc4:	e1afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201bc8:	00003697          	auipc	a3,0x3
ffffffffc0201bcc:	bd068693          	addi	a3,a3,-1072 # ffffffffc0204798 <commands+0xae8>
ffffffffc0201bd0:	00003617          	auipc	a2,0x3
ffffffffc0201bd4:	a4060613          	addi	a2,a2,-1472 # ffffffffc0204610 <commands+0x960>
ffffffffc0201bd8:	18100593          	li	a1,385
ffffffffc0201bdc:	00003517          	auipc	a0,0x3
ffffffffc0201be0:	92c50513          	addi	a0,a0,-1748 # ffffffffc0204508 <commands+0x858>
ffffffffc0201be4:	dfafe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201be8:	00003697          	auipc	a3,0x3
ffffffffc0201bec:	c8868693          	addi	a3,a3,-888 # ffffffffc0204870 <commands+0xbc0>
ffffffffc0201bf0:	00003617          	auipc	a2,0x3
ffffffffc0201bf4:	a2060613          	addi	a2,a2,-1504 # ffffffffc0204610 <commands+0x960>
ffffffffc0201bf8:	18000593          	li	a1,384
ffffffffc0201bfc:	00003517          	auipc	a0,0x3
ffffffffc0201c00:	90c50513          	addi	a0,a0,-1780 # ffffffffc0204508 <commands+0x858>
ffffffffc0201c04:	ddafe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201c08:	00003697          	auipc	a3,0x3
ffffffffc0201c0c:	c5068693          	addi	a3,a3,-944 # ffffffffc0204858 <commands+0xba8>
ffffffffc0201c10:	00003617          	auipc	a2,0x3
ffffffffc0201c14:	a0060613          	addi	a2,a2,-1536 # ffffffffc0204610 <commands+0x960>
ffffffffc0201c18:	17f00593          	li	a1,383
ffffffffc0201c1c:	00003517          	auipc	a0,0x3
ffffffffc0201c20:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0204508 <commands+0x858>
ffffffffc0201c24:	dbafe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201c28:	00003697          	auipc	a3,0x3
ffffffffc0201c2c:	c0068693          	addi	a3,a3,-1024 # ffffffffc0204828 <commands+0xb78>
ffffffffc0201c30:	00003617          	auipc	a2,0x3
ffffffffc0201c34:	9e060613          	addi	a2,a2,-1568 # ffffffffc0204610 <commands+0x960>
ffffffffc0201c38:	17e00593          	li	a1,382
ffffffffc0201c3c:	00003517          	auipc	a0,0x3
ffffffffc0201c40:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0204508 <commands+0x858>
ffffffffc0201c44:	d9afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201c48:	00003697          	auipc	a3,0x3
ffffffffc0201c4c:	bc868693          	addi	a3,a3,-1080 # ffffffffc0204810 <commands+0xb60>
ffffffffc0201c50:	00003617          	auipc	a2,0x3
ffffffffc0201c54:	9c060613          	addi	a2,a2,-1600 # ffffffffc0204610 <commands+0x960>
ffffffffc0201c58:	17c00593          	li	a1,380
ffffffffc0201c5c:	00003517          	auipc	a0,0x3
ffffffffc0201c60:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0204508 <commands+0x858>
ffffffffc0201c64:	d7afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0201c68:	00003697          	auipc	a3,0x3
ffffffffc0201c6c:	b8868693          	addi	a3,a3,-1144 # ffffffffc02047f0 <commands+0xb40>
ffffffffc0201c70:	00003617          	auipc	a2,0x3
ffffffffc0201c74:	9a060613          	addi	a2,a2,-1632 # ffffffffc0204610 <commands+0x960>
ffffffffc0201c78:	17b00593          	li	a1,379
ffffffffc0201c7c:	00003517          	auipc	a0,0x3
ffffffffc0201c80:	88c50513          	addi	a0,a0,-1908 # ffffffffc0204508 <commands+0x858>
ffffffffc0201c84:	d5afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201c88:	00003697          	auipc	a3,0x3
ffffffffc0201c8c:	b5868693          	addi	a3,a3,-1192 # ffffffffc02047e0 <commands+0xb30>
ffffffffc0201c90:	00003617          	auipc	a2,0x3
ffffffffc0201c94:	98060613          	addi	a2,a2,-1664 # ffffffffc0204610 <commands+0x960>
ffffffffc0201c98:	17a00593          	li	a1,378
ffffffffc0201c9c:	00003517          	auipc	a0,0x3
ffffffffc0201ca0:	86c50513          	addi	a0,a0,-1940 # ffffffffc0204508 <commands+0x858>
ffffffffc0201ca4:	d3afe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201ca8:	00003697          	auipc	a3,0x3
ffffffffc0201cac:	b2868693          	addi	a3,a3,-1240 # ffffffffc02047d0 <commands+0xb20>
ffffffffc0201cb0:	00003617          	auipc	a2,0x3
ffffffffc0201cb4:	96060613          	addi	a2,a2,-1696 # ffffffffc0204610 <commands+0x960>
ffffffffc0201cb8:	17900593          	li	a1,377
ffffffffc0201cbc:	00003517          	auipc	a0,0x3
ffffffffc0201cc0:	84c50513          	addi	a0,a0,-1972 # ffffffffc0204508 <commands+0x858>
ffffffffc0201cc4:	d1afe0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("DTB memory info not available");
ffffffffc0201cc8:	00003617          	auipc	a2,0x3
ffffffffc0201ccc:	86860613          	addi	a2,a2,-1944 # ffffffffc0204530 <commands+0x880>
ffffffffc0201cd0:	06400593          	li	a1,100
ffffffffc0201cd4:	00003517          	auipc	a0,0x3
ffffffffc0201cd8:	83450513          	addi	a0,a0,-1996 # ffffffffc0204508 <commands+0x858>
ffffffffc0201cdc:	d02fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201ce0:	00003697          	auipc	a3,0x3
ffffffffc0201ce4:	c0868693          	addi	a3,a3,-1016 # ffffffffc02048e8 <commands+0xc38>
ffffffffc0201ce8:	00003617          	auipc	a2,0x3
ffffffffc0201cec:	92860613          	addi	a2,a2,-1752 # ffffffffc0204610 <commands+0x960>
ffffffffc0201cf0:	1bf00593          	li	a1,447
ffffffffc0201cf4:	00003517          	auipc	a0,0x3
ffffffffc0201cf8:	81450513          	addi	a0,a0,-2028 # ffffffffc0204508 <commands+0x858>
ffffffffc0201cfc:	ce2fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201d00:	00003697          	auipc	a3,0x3
ffffffffc0201d04:	a9868693          	addi	a3,a3,-1384 # ffffffffc0204798 <commands+0xae8>
ffffffffc0201d08:	00003617          	auipc	a2,0x3
ffffffffc0201d0c:	90860613          	addi	a2,a2,-1784 # ffffffffc0204610 <commands+0x960>
ffffffffc0201d10:	17800593          	li	a1,376
ffffffffc0201d14:	00002517          	auipc	a0,0x2
ffffffffc0201d18:	7f450513          	addi	a0,a0,2036 # ffffffffc0204508 <commands+0x858>
ffffffffc0201d1c:	cc2fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d20:	00003697          	auipc	a3,0x3
ffffffffc0201d24:	a3868693          	addi	a3,a3,-1480 # ffffffffc0204758 <commands+0xaa8>
ffffffffc0201d28:	00003617          	auipc	a2,0x3
ffffffffc0201d2c:	8e860613          	addi	a2,a2,-1816 # ffffffffc0204610 <commands+0x960>
ffffffffc0201d30:	17700593          	li	a1,375
ffffffffc0201d34:	00002517          	auipc	a0,0x2
ffffffffc0201d38:	7d450513          	addi	a0,a0,2004 # ffffffffc0204508 <commands+0x858>
ffffffffc0201d3c:	ca2fe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d40:	86d6                	mv	a3,s5
ffffffffc0201d42:	00002617          	auipc	a2,0x2
ffffffffc0201d46:	79e60613          	addi	a2,a2,1950 # ffffffffc02044e0 <commands+0x830>
ffffffffc0201d4a:	17300593          	li	a1,371
ffffffffc0201d4e:	00002517          	auipc	a0,0x2
ffffffffc0201d52:	7ba50513          	addi	a0,a0,1978 # ffffffffc0204508 <commands+0x858>
ffffffffc0201d56:	c88fe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0201d5a:	00002617          	auipc	a2,0x2
ffffffffc0201d5e:	78660613          	addi	a2,a2,1926 # ffffffffc02044e0 <commands+0x830>
ffffffffc0201d62:	17200593          	li	a1,370
ffffffffc0201d66:	00002517          	auipc	a0,0x2
ffffffffc0201d6a:	7a250513          	addi	a0,a0,1954 # ffffffffc0204508 <commands+0x858>
ffffffffc0201d6e:	c70fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201d72:	00003697          	auipc	a3,0x3
ffffffffc0201d76:	99e68693          	addi	a3,a3,-1634 # ffffffffc0204710 <commands+0xa60>
ffffffffc0201d7a:	00003617          	auipc	a2,0x3
ffffffffc0201d7e:	89660613          	addi	a2,a2,-1898 # ffffffffc0204610 <commands+0x960>
ffffffffc0201d82:	17000593          	li	a1,368
ffffffffc0201d86:	00002517          	auipc	a0,0x2
ffffffffc0201d8a:	78250513          	addi	a0,a0,1922 # ffffffffc0204508 <commands+0x858>
ffffffffc0201d8e:	c50fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201d92:	00003697          	auipc	a3,0x3
ffffffffc0201d96:	96668693          	addi	a3,a3,-1690 # ffffffffc02046f8 <commands+0xa48>
ffffffffc0201d9a:	00003617          	auipc	a2,0x3
ffffffffc0201d9e:	87660613          	addi	a2,a2,-1930 # ffffffffc0204610 <commands+0x960>
ffffffffc0201da2:	16f00593          	li	a1,367
ffffffffc0201da6:	00002517          	auipc	a0,0x2
ffffffffc0201daa:	76250513          	addi	a0,a0,1890 # ffffffffc0204508 <commands+0x858>
ffffffffc0201dae:	c30fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201db2:	00003697          	auipc	a3,0x3
ffffffffc0201db6:	cf668693          	addi	a3,a3,-778 # ffffffffc0204aa8 <commands+0xdf8>
ffffffffc0201dba:	00003617          	auipc	a2,0x3
ffffffffc0201dbe:	85660613          	addi	a2,a2,-1962 # ffffffffc0204610 <commands+0x960>
ffffffffc0201dc2:	1b600593          	li	a1,438
ffffffffc0201dc6:	00002517          	auipc	a0,0x2
ffffffffc0201dca:	74250513          	addi	a0,a0,1858 # ffffffffc0204508 <commands+0x858>
ffffffffc0201dce:	c10fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201dd2:	00003697          	auipc	a3,0x3
ffffffffc0201dd6:	c9e68693          	addi	a3,a3,-866 # ffffffffc0204a70 <commands+0xdc0>
ffffffffc0201dda:	00003617          	auipc	a2,0x3
ffffffffc0201dde:	83660613          	addi	a2,a2,-1994 # ffffffffc0204610 <commands+0x960>
ffffffffc0201de2:	1b300593          	li	a1,435
ffffffffc0201de6:	00002517          	auipc	a0,0x2
ffffffffc0201dea:	72250513          	addi	a0,a0,1826 # ffffffffc0204508 <commands+0x858>
ffffffffc0201dee:	bf0fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201df2:	00003697          	auipc	a3,0x3
ffffffffc0201df6:	c4e68693          	addi	a3,a3,-946 # ffffffffc0204a40 <commands+0xd90>
ffffffffc0201dfa:	00003617          	auipc	a2,0x3
ffffffffc0201dfe:	81660613          	addi	a2,a2,-2026 # ffffffffc0204610 <commands+0x960>
ffffffffc0201e02:	1af00593          	li	a1,431
ffffffffc0201e06:	00002517          	auipc	a0,0x2
ffffffffc0201e0a:	70250513          	addi	a0,a0,1794 # ffffffffc0204508 <commands+0x858>
ffffffffc0201e0e:	bd0fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201e12:	00003697          	auipc	a3,0x3
ffffffffc0201e16:	be668693          	addi	a3,a3,-1050 # ffffffffc02049f8 <commands+0xd48>
ffffffffc0201e1a:	00002617          	auipc	a2,0x2
ffffffffc0201e1e:	7f660613          	addi	a2,a2,2038 # ffffffffc0204610 <commands+0x960>
ffffffffc0201e22:	1ae00593          	li	a1,430
ffffffffc0201e26:	00002517          	auipc	a0,0x2
ffffffffc0201e2a:	6e250513          	addi	a0,a0,1762 # ffffffffc0204508 <commands+0x858>
ffffffffc0201e2e:	bb0fe0ef          	jal	ra,ffffffffc02001de <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0201e32:	00002617          	auipc	a2,0x2
ffffffffc0201e36:	75e60613          	addi	a2,a2,1886 # ffffffffc0204590 <commands+0x8e0>
ffffffffc0201e3a:	0cb00593          	li	a1,203
ffffffffc0201e3e:	00002517          	auipc	a0,0x2
ffffffffc0201e42:	6ca50513          	addi	a0,a0,1738 # ffffffffc0204508 <commands+0x858>
ffffffffc0201e46:	b98fe0ef          	jal	ra,ffffffffc02001de <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201e4a:	00002617          	auipc	a2,0x2
ffffffffc0201e4e:	74660613          	addi	a2,a2,1862 # ffffffffc0204590 <commands+0x8e0>
ffffffffc0201e52:	08000593          	li	a1,128
ffffffffc0201e56:	00002517          	auipc	a0,0x2
ffffffffc0201e5a:	6b250513          	addi	a0,a0,1714 # ffffffffc0204508 <commands+0x858>
ffffffffc0201e5e:	b80fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201e62:	00003697          	auipc	a3,0x3
ffffffffc0201e66:	86668693          	addi	a3,a3,-1946 # ffffffffc02046c8 <commands+0xa18>
ffffffffc0201e6a:	00002617          	auipc	a2,0x2
ffffffffc0201e6e:	7a660613          	addi	a2,a2,1958 # ffffffffc0204610 <commands+0x960>
ffffffffc0201e72:	16e00593          	li	a1,366
ffffffffc0201e76:	00002517          	auipc	a0,0x2
ffffffffc0201e7a:	69250513          	addi	a0,a0,1682 # ffffffffc0204508 <commands+0x858>
ffffffffc0201e7e:	b60fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201e82:	00003697          	auipc	a3,0x3
ffffffffc0201e86:	81668693          	addi	a3,a3,-2026 # ffffffffc0204698 <commands+0x9e8>
ffffffffc0201e8a:	00002617          	auipc	a2,0x2
ffffffffc0201e8e:	78660613          	addi	a2,a2,1926 # ffffffffc0204610 <commands+0x960>
ffffffffc0201e92:	16b00593          	li	a1,363
ffffffffc0201e96:	00002517          	auipc	a0,0x2
ffffffffc0201e9a:	67250513          	addi	a0,a0,1650 # ffffffffc0204508 <commands+0x858>
ffffffffc0201e9e:	b40fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201ea2 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201ea2:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0201ea4:	00003697          	auipc	a3,0x3
ffffffffc0201ea8:	c4c68693          	addi	a3,a3,-948 # ffffffffc0204af0 <commands+0xe40>
ffffffffc0201eac:	00002617          	auipc	a2,0x2
ffffffffc0201eb0:	76460613          	addi	a2,a2,1892 # ffffffffc0204610 <commands+0x960>
ffffffffc0201eb4:	08800593          	li	a1,136
ffffffffc0201eb8:	00003517          	auipc	a0,0x3
ffffffffc0201ebc:	c5850513          	addi	a0,a0,-936 # ffffffffc0204b10 <commands+0xe60>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201ec0:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0201ec2:	b1cfe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201ec6 <find_vma>:
{
ffffffffc0201ec6:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0201ec8:	c505                	beqz	a0,ffffffffc0201ef0 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0201eca:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201ecc:	c501                	beqz	a0,ffffffffc0201ed4 <find_vma+0xe>
ffffffffc0201ece:	651c                	ld	a5,8(a0)
ffffffffc0201ed0:	02f5f263          	bgeu	a1,a5,ffffffffc0201ef4 <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201ed4:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0201ed6:	00f68d63          	beq	a3,a5,ffffffffc0201ef0 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0201eda:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2b0c>
ffffffffc0201ede:	00e5e663          	bltu	a1,a4,ffffffffc0201eea <find_vma+0x24>
ffffffffc0201ee2:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201ee6:	00e5ec63          	bltu	a1,a4,ffffffffc0201efe <find_vma+0x38>
ffffffffc0201eea:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0201eec:	fef697e3          	bne	a3,a5,ffffffffc0201eda <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0201ef0:	4501                	li	a0,0
}
ffffffffc0201ef2:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201ef4:	691c                	ld	a5,16(a0)
ffffffffc0201ef6:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0201ed4 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0201efa:	ea88                	sd	a0,16(a3)
ffffffffc0201efc:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0201efe:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0201f02:	ea88                	sd	a0,16(a3)
ffffffffc0201f04:	8082                	ret

ffffffffc0201f06 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f06:	6590                	ld	a2,8(a1)
ffffffffc0201f08:	0105b803          	ld	a6,16(a1)
{
ffffffffc0201f0c:	1141                	addi	sp,sp,-16
ffffffffc0201f0e:	e406                	sd	ra,8(sp)
ffffffffc0201f10:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f12:	01066763          	bltu	a2,a6,ffffffffc0201f20 <insert_vma_struct+0x1a>
ffffffffc0201f16:	a085                	j	ffffffffc0201f76 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201f18:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201f1c:	04e66863          	bltu	a2,a4,ffffffffc0201f6c <insert_vma_struct+0x66>
ffffffffc0201f20:	86be                	mv	a3,a5
ffffffffc0201f22:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0201f24:	fef51ae3          	bne	a0,a5,ffffffffc0201f18 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0201f28:	02a68463          	beq	a3,a0,ffffffffc0201f50 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201f2c:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201f30:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201f34:	08e8f163          	bgeu	a7,a4,ffffffffc0201fb6 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201f38:	04e66f63          	bltu	a2,a4,ffffffffc0201f96 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0201f3c:	00f50a63          	beq	a0,a5,ffffffffc0201f50 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201f40:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201f44:	05076963          	bltu	a4,a6,ffffffffc0201f96 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0201f48:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201f4c:	02c77363          	bgeu	a4,a2,ffffffffc0201f72 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0201f50:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0201f52:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201f54:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201f58:	e390                	sd	a2,0(a5)
ffffffffc0201f5a:	e690                	sd	a2,8(a3)
}
ffffffffc0201f5c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201f5e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0201f60:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0201f62:	0017079b          	addiw	a5,a4,1
ffffffffc0201f66:	d11c                	sw	a5,32(a0)
}
ffffffffc0201f68:	0141                	addi	sp,sp,16
ffffffffc0201f6a:	8082                	ret
    if (le_prev != list)
ffffffffc0201f6c:	fca690e3          	bne	a3,a0,ffffffffc0201f2c <insert_vma_struct+0x26>
ffffffffc0201f70:	bfd1                	j	ffffffffc0201f44 <insert_vma_struct+0x3e>
ffffffffc0201f72:	f31ff0ef          	jal	ra,ffffffffc0201ea2 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f76:	00003697          	auipc	a3,0x3
ffffffffc0201f7a:	baa68693          	addi	a3,a3,-1110 # ffffffffc0204b20 <commands+0xe70>
ffffffffc0201f7e:	00002617          	auipc	a2,0x2
ffffffffc0201f82:	69260613          	addi	a2,a2,1682 # ffffffffc0204610 <commands+0x960>
ffffffffc0201f86:	08e00593          	li	a1,142
ffffffffc0201f8a:	00003517          	auipc	a0,0x3
ffffffffc0201f8e:	b8650513          	addi	a0,a0,-1146 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0201f92:	a4cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201f96:	00003697          	auipc	a3,0x3
ffffffffc0201f9a:	bca68693          	addi	a3,a3,-1078 # ffffffffc0204b60 <commands+0xeb0>
ffffffffc0201f9e:	00002617          	auipc	a2,0x2
ffffffffc0201fa2:	67260613          	addi	a2,a2,1650 # ffffffffc0204610 <commands+0x960>
ffffffffc0201fa6:	08700593          	li	a1,135
ffffffffc0201faa:	00003517          	auipc	a0,0x3
ffffffffc0201fae:	b6650513          	addi	a0,a0,-1178 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0201fb2:	a2cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201fb6:	00003697          	auipc	a3,0x3
ffffffffc0201fba:	b8a68693          	addi	a3,a3,-1142 # ffffffffc0204b40 <commands+0xe90>
ffffffffc0201fbe:	00002617          	auipc	a2,0x2
ffffffffc0201fc2:	65260613          	addi	a2,a2,1618 # ffffffffc0204610 <commands+0x960>
ffffffffc0201fc6:	08600593          	li	a1,134
ffffffffc0201fca:	00003517          	auipc	a0,0x3
ffffffffc0201fce:	b4650513          	addi	a0,a0,-1210 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0201fd2:	a0cfe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201fd6 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0201fd6:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201fd8:	03000513          	li	a0,48
{
ffffffffc0201fdc:	fc06                	sd	ra,56(sp)
ffffffffc0201fde:	f822                	sd	s0,48(sp)
ffffffffc0201fe0:	f426                	sd	s1,40(sp)
ffffffffc0201fe2:	f04a                	sd	s2,32(sp)
ffffffffc0201fe4:	ec4e                	sd	s3,24(sp)
ffffffffc0201fe6:	e852                	sd	s4,16(sp)
ffffffffc0201fe8:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201fea:	550000ef          	jal	ra,ffffffffc020253a <kmalloc>
    if (mm != NULL)
ffffffffc0201fee:	2e050f63          	beqz	a0,ffffffffc02022ec <vmm_init+0x316>
ffffffffc0201ff2:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0201ff4:	e508                	sd	a0,8(a0)
ffffffffc0201ff6:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0201ff8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0201ffc:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202000:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202004:	02053423          	sd	zero,40(a0)
ffffffffc0202008:	03200413          	li	s0,50
ffffffffc020200c:	a811                	j	ffffffffc0202020 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc020200e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202010:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202012:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202016:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202018:	8526                	mv	a0,s1
ffffffffc020201a:	eedff0ef          	jal	ra,ffffffffc0201f06 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020201e:	c80d                	beqz	s0,ffffffffc0202050 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202020:	03000513          	li	a0,48
ffffffffc0202024:	516000ef          	jal	ra,ffffffffc020253a <kmalloc>
ffffffffc0202028:	85aa                	mv	a1,a0
ffffffffc020202a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020202e:	f165                	bnez	a0,ffffffffc020200e <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202030:	00003697          	auipc	a3,0x3
ffffffffc0202034:	cc868693          	addi	a3,a3,-824 # ffffffffc0204cf8 <commands+0x1048>
ffffffffc0202038:	00002617          	auipc	a2,0x2
ffffffffc020203c:	5d860613          	addi	a2,a2,1496 # ffffffffc0204610 <commands+0x960>
ffffffffc0202040:	0da00593          	li	a1,218
ffffffffc0202044:	00003517          	auipc	a0,0x3
ffffffffc0202048:	acc50513          	addi	a0,a0,-1332 # ffffffffc0204b10 <commands+0xe60>
ffffffffc020204c:	992fe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc0202050:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202054:	1f900913          	li	s2,505
ffffffffc0202058:	a819                	j	ffffffffc020206e <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc020205a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020205c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020205e:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202062:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202064:	8526                	mv	a0,s1
ffffffffc0202066:	ea1ff0ef          	jal	ra,ffffffffc0201f06 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc020206a:	03240a63          	beq	s0,s2,ffffffffc020209e <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020206e:	03000513          	li	a0,48
ffffffffc0202072:	4c8000ef          	jal	ra,ffffffffc020253a <kmalloc>
ffffffffc0202076:	85aa                	mv	a1,a0
ffffffffc0202078:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020207c:	fd79                	bnez	a0,ffffffffc020205a <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc020207e:	00003697          	auipc	a3,0x3
ffffffffc0202082:	c7a68693          	addi	a3,a3,-902 # ffffffffc0204cf8 <commands+0x1048>
ffffffffc0202086:	00002617          	auipc	a2,0x2
ffffffffc020208a:	58a60613          	addi	a2,a2,1418 # ffffffffc0204610 <commands+0x960>
ffffffffc020208e:	0e100593          	li	a1,225
ffffffffc0202092:	00003517          	auipc	a0,0x3
ffffffffc0202096:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0204b10 <commands+0xe60>
ffffffffc020209a:	944fe0ef          	jal	ra,ffffffffc02001de <__panic>
    return listelm->next;
ffffffffc020209e:	649c                	ld	a5,8(s1)
ffffffffc02020a0:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02020a2:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02020a6:	18f48363          	beq	s1,a5,ffffffffc020222c <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02020aa:	fe87b603          	ld	a2,-24(a5)
ffffffffc02020ae:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc02020b2:	10d61d63          	bne	a2,a3,ffffffffc02021cc <vmm_init+0x1f6>
ffffffffc02020b6:	ff07b683          	ld	a3,-16(a5)
ffffffffc02020ba:	10e69963          	bne	a3,a4,ffffffffc02021cc <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc02020be:	0715                	addi	a4,a4,5
ffffffffc02020c0:	679c                	ld	a5,8(a5)
ffffffffc02020c2:	feb712e3          	bne	a4,a1,ffffffffc02020a6 <vmm_init+0xd0>
ffffffffc02020c6:	4a1d                	li	s4,7
ffffffffc02020c8:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02020ca:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02020ce:	85a2                	mv	a1,s0
ffffffffc02020d0:	8526                	mv	a0,s1
ffffffffc02020d2:	df5ff0ef          	jal	ra,ffffffffc0201ec6 <find_vma>
ffffffffc02020d6:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc02020d8:	18050a63          	beqz	a0,ffffffffc020226c <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc02020dc:	00140593          	addi	a1,s0,1
ffffffffc02020e0:	8526                	mv	a0,s1
ffffffffc02020e2:	de5ff0ef          	jal	ra,ffffffffc0201ec6 <find_vma>
ffffffffc02020e6:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02020e8:	16050263          	beqz	a0,ffffffffc020224c <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc02020ec:	85d2                	mv	a1,s4
ffffffffc02020ee:	8526                	mv	a0,s1
ffffffffc02020f0:	dd7ff0ef          	jal	ra,ffffffffc0201ec6 <find_vma>
        assert(vma3 == NULL);
ffffffffc02020f4:	18051c63          	bnez	a0,ffffffffc020228c <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc02020f8:	00340593          	addi	a1,s0,3
ffffffffc02020fc:	8526                	mv	a0,s1
ffffffffc02020fe:	dc9ff0ef          	jal	ra,ffffffffc0201ec6 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202102:	1c051563          	bnez	a0,ffffffffc02022cc <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202106:	00440593          	addi	a1,s0,4
ffffffffc020210a:	8526                	mv	a0,s1
ffffffffc020210c:	dbbff0ef          	jal	ra,ffffffffc0201ec6 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202110:	18051e63          	bnez	a0,ffffffffc02022ac <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202114:	00893783          	ld	a5,8(s2)
ffffffffc0202118:	0c879a63          	bne	a5,s0,ffffffffc02021ec <vmm_init+0x216>
ffffffffc020211c:	01093783          	ld	a5,16(s2)
ffffffffc0202120:	0d479663          	bne	a5,s4,ffffffffc02021ec <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202124:	0089b783          	ld	a5,8(s3)
ffffffffc0202128:	0e879263          	bne	a5,s0,ffffffffc020220c <vmm_init+0x236>
ffffffffc020212c:	0109b783          	ld	a5,16(s3)
ffffffffc0202130:	0d479e63          	bne	a5,s4,ffffffffc020220c <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202134:	0415                	addi	s0,s0,5
ffffffffc0202136:	0a15                	addi	s4,s4,5
ffffffffc0202138:	f9541be3          	bne	s0,s5,ffffffffc02020ce <vmm_init+0xf8>
ffffffffc020213c:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc020213e:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202140:	85a2                	mv	a1,s0
ffffffffc0202142:	8526                	mv	a0,s1
ffffffffc0202144:	d83ff0ef          	jal	ra,ffffffffc0201ec6 <find_vma>
ffffffffc0202148:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc020214c:	c90d                	beqz	a0,ffffffffc020217e <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc020214e:	6914                	ld	a3,16(a0)
ffffffffc0202150:	6510                	ld	a2,8(a0)
ffffffffc0202152:	00003517          	auipc	a0,0x3
ffffffffc0202156:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0204c80 <commands+0xfd0>
ffffffffc020215a:	f87fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc020215e:	00003697          	auipc	a3,0x3
ffffffffc0202162:	b4a68693          	addi	a3,a3,-1206 # ffffffffc0204ca8 <commands+0xff8>
ffffffffc0202166:	00002617          	auipc	a2,0x2
ffffffffc020216a:	4aa60613          	addi	a2,a2,1194 # ffffffffc0204610 <commands+0x960>
ffffffffc020216e:	10700593          	li	a1,263
ffffffffc0202172:	00003517          	auipc	a0,0x3
ffffffffc0202176:	99e50513          	addi	a0,a0,-1634 # ffffffffc0204b10 <commands+0xe60>
ffffffffc020217a:	864fe0ef          	jal	ra,ffffffffc02001de <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc020217e:	147d                	addi	s0,s0,-1
ffffffffc0202180:	fd2410e3          	bne	s0,s2,ffffffffc0202140 <vmm_init+0x16a>
ffffffffc0202184:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc0202186:	00a48c63          	beq	s1,a0,ffffffffc020219e <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc020218a:	6118                	ld	a4,0(a0)
ffffffffc020218c:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020218e:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0202190:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202192:	e398                	sd	a4,0(a5)
ffffffffc0202194:	456000ef          	jal	ra,ffffffffc02025ea <kfree>
    return listelm->next;
ffffffffc0202198:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020219a:	fea498e3          	bne	s1,a0,ffffffffc020218a <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc020219e:	8526                	mv	a0,s1
ffffffffc02021a0:	44a000ef          	jal	ra,ffffffffc02025ea <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02021a4:	00003517          	auipc	a0,0x3
ffffffffc02021a8:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0204cc0 <commands+0x1010>
ffffffffc02021ac:	f35fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc02021b0:	7442                	ld	s0,48(sp)
ffffffffc02021b2:	70e2                	ld	ra,56(sp)
ffffffffc02021b4:	74a2                	ld	s1,40(sp)
ffffffffc02021b6:	7902                	ld	s2,32(sp)
ffffffffc02021b8:	69e2                	ld	s3,24(sp)
ffffffffc02021ba:	6a42                	ld	s4,16(sp)
ffffffffc02021bc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02021be:	00003517          	auipc	a0,0x3
ffffffffc02021c2:	b2250513          	addi	a0,a0,-1246 # ffffffffc0204ce0 <commands+0x1030>
}
ffffffffc02021c6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02021c8:	f19fd06f          	j	ffffffffc02000e0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02021cc:	00003697          	auipc	a3,0x3
ffffffffc02021d0:	9cc68693          	addi	a3,a3,-1588 # ffffffffc0204b98 <commands+0xee8>
ffffffffc02021d4:	00002617          	auipc	a2,0x2
ffffffffc02021d8:	43c60613          	addi	a2,a2,1084 # ffffffffc0204610 <commands+0x960>
ffffffffc02021dc:	0eb00593          	li	a1,235
ffffffffc02021e0:	00003517          	auipc	a0,0x3
ffffffffc02021e4:	93050513          	addi	a0,a0,-1744 # ffffffffc0204b10 <commands+0xe60>
ffffffffc02021e8:	ff7fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02021ec:	00003697          	auipc	a3,0x3
ffffffffc02021f0:	a3468693          	addi	a3,a3,-1484 # ffffffffc0204c20 <commands+0xf70>
ffffffffc02021f4:	00002617          	auipc	a2,0x2
ffffffffc02021f8:	41c60613          	addi	a2,a2,1052 # ffffffffc0204610 <commands+0x960>
ffffffffc02021fc:	0fc00593          	li	a1,252
ffffffffc0202200:	00003517          	auipc	a0,0x3
ffffffffc0202204:	91050513          	addi	a0,a0,-1776 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0202208:	fd7fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020220c:	00003697          	auipc	a3,0x3
ffffffffc0202210:	a4468693          	addi	a3,a3,-1468 # ffffffffc0204c50 <commands+0xfa0>
ffffffffc0202214:	00002617          	auipc	a2,0x2
ffffffffc0202218:	3fc60613          	addi	a2,a2,1020 # ffffffffc0204610 <commands+0x960>
ffffffffc020221c:	0fd00593          	li	a1,253
ffffffffc0202220:	00003517          	auipc	a0,0x3
ffffffffc0202224:	8f050513          	addi	a0,a0,-1808 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0202228:	fb7fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020222c:	00003697          	auipc	a3,0x3
ffffffffc0202230:	95468693          	addi	a3,a3,-1708 # ffffffffc0204b80 <commands+0xed0>
ffffffffc0202234:	00002617          	auipc	a2,0x2
ffffffffc0202238:	3dc60613          	addi	a2,a2,988 # ffffffffc0204610 <commands+0x960>
ffffffffc020223c:	0e900593          	li	a1,233
ffffffffc0202240:	00003517          	auipc	a0,0x3
ffffffffc0202244:	8d050513          	addi	a0,a0,-1840 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0202248:	f97fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2 != NULL);
ffffffffc020224c:	00003697          	auipc	a3,0x3
ffffffffc0202250:	99468693          	addi	a3,a3,-1644 # ffffffffc0204be0 <commands+0xf30>
ffffffffc0202254:	00002617          	auipc	a2,0x2
ffffffffc0202258:	3bc60613          	addi	a2,a2,956 # ffffffffc0204610 <commands+0x960>
ffffffffc020225c:	0f400593          	li	a1,244
ffffffffc0202260:	00003517          	auipc	a0,0x3
ffffffffc0202264:	8b050513          	addi	a0,a0,-1872 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0202268:	f77fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1 != NULL);
ffffffffc020226c:	00003697          	auipc	a3,0x3
ffffffffc0202270:	96468693          	addi	a3,a3,-1692 # ffffffffc0204bd0 <commands+0xf20>
ffffffffc0202274:	00002617          	auipc	a2,0x2
ffffffffc0202278:	39c60613          	addi	a2,a2,924 # ffffffffc0204610 <commands+0x960>
ffffffffc020227c:	0f200593          	li	a1,242
ffffffffc0202280:	00003517          	auipc	a0,0x3
ffffffffc0202284:	89050513          	addi	a0,a0,-1904 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0202288:	f57fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma3 == NULL);
ffffffffc020228c:	00003697          	auipc	a3,0x3
ffffffffc0202290:	96468693          	addi	a3,a3,-1692 # ffffffffc0204bf0 <commands+0xf40>
ffffffffc0202294:	00002617          	auipc	a2,0x2
ffffffffc0202298:	37c60613          	addi	a2,a2,892 # ffffffffc0204610 <commands+0x960>
ffffffffc020229c:	0f600593          	li	a1,246
ffffffffc02022a0:	00003517          	auipc	a0,0x3
ffffffffc02022a4:	87050513          	addi	a0,a0,-1936 # ffffffffc0204b10 <commands+0xe60>
ffffffffc02022a8:	f37fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma5 == NULL);
ffffffffc02022ac:	00003697          	auipc	a3,0x3
ffffffffc02022b0:	96468693          	addi	a3,a3,-1692 # ffffffffc0204c10 <commands+0xf60>
ffffffffc02022b4:	00002617          	auipc	a2,0x2
ffffffffc02022b8:	35c60613          	addi	a2,a2,860 # ffffffffc0204610 <commands+0x960>
ffffffffc02022bc:	0fa00593          	li	a1,250
ffffffffc02022c0:	00003517          	auipc	a0,0x3
ffffffffc02022c4:	85050513          	addi	a0,a0,-1968 # ffffffffc0204b10 <commands+0xe60>
ffffffffc02022c8:	f17fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma4 == NULL);
ffffffffc02022cc:	00003697          	auipc	a3,0x3
ffffffffc02022d0:	93468693          	addi	a3,a3,-1740 # ffffffffc0204c00 <commands+0xf50>
ffffffffc02022d4:	00002617          	auipc	a2,0x2
ffffffffc02022d8:	33c60613          	addi	a2,a2,828 # ffffffffc0204610 <commands+0x960>
ffffffffc02022dc:	0f800593          	li	a1,248
ffffffffc02022e0:	00003517          	auipc	a0,0x3
ffffffffc02022e4:	83050513          	addi	a0,a0,-2000 # ffffffffc0204b10 <commands+0xe60>
ffffffffc02022e8:	ef7fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(mm != NULL);
ffffffffc02022ec:	00003697          	auipc	a3,0x3
ffffffffc02022f0:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0204d08 <commands+0x1058>
ffffffffc02022f4:	00002617          	auipc	a2,0x2
ffffffffc02022f8:	31c60613          	addi	a2,a2,796 # ffffffffc0204610 <commands+0x960>
ffffffffc02022fc:	0d200593          	li	a1,210
ffffffffc0202300:	00003517          	auipc	a0,0x3
ffffffffc0202304:	81050513          	addi	a0,a0,-2032 # ffffffffc0204b10 <commands+0xe60>
ffffffffc0202308:	ed7fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020230c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc020230c:	c94d                	beqz	a0,ffffffffc02023be <slob_free+0xb2>
{
ffffffffc020230e:	1141                	addi	sp,sp,-16
ffffffffc0202310:	e022                	sd	s0,0(sp)
ffffffffc0202312:	e406                	sd	ra,8(sp)
ffffffffc0202314:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0202316:	e9c1                	bnez	a1,ffffffffc02023a6 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202318:	100027f3          	csrr	a5,sstatus
ffffffffc020231c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020231e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202320:	ebd9                	bnez	a5,ffffffffc02023b6 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202322:	00007617          	auipc	a2,0x7
ffffffffc0202326:	cfe60613          	addi	a2,a2,-770 # ffffffffc0209020 <slobfree>
ffffffffc020232a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020232c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020232e:	679c                	ld	a5,8(a5)
ffffffffc0202330:	02877a63          	bgeu	a4,s0,ffffffffc0202364 <slob_free+0x58>
ffffffffc0202334:	00f46463          	bltu	s0,a5,ffffffffc020233c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202338:	fef76ae3          	bltu	a4,a5,ffffffffc020232c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc020233c:	400c                	lw	a1,0(s0)
ffffffffc020233e:	00459693          	slli	a3,a1,0x4
ffffffffc0202342:	96a2                	add	a3,a3,s0
ffffffffc0202344:	02d78a63          	beq	a5,a3,ffffffffc0202378 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0202348:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc020234a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc020234c:	00469793          	slli	a5,a3,0x4
ffffffffc0202350:	97ba                	add	a5,a5,a4
ffffffffc0202352:	02f40e63          	beq	s0,a5,ffffffffc020238e <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0202356:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0202358:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc020235a:	e129                	bnez	a0,ffffffffc020239c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc020235c:	60a2                	ld	ra,8(sp)
ffffffffc020235e:	6402                	ld	s0,0(sp)
ffffffffc0202360:	0141                	addi	sp,sp,16
ffffffffc0202362:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202364:	fcf764e3          	bltu	a4,a5,ffffffffc020232c <slob_free+0x20>
ffffffffc0202368:	fcf472e3          	bgeu	s0,a5,ffffffffc020232c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc020236c:	400c                	lw	a1,0(s0)
ffffffffc020236e:	00459693          	slli	a3,a1,0x4
ffffffffc0202372:	96a2                	add	a3,a3,s0
ffffffffc0202374:	fcd79ae3          	bne	a5,a3,ffffffffc0202348 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0202378:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020237a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc020237c:	9db5                	addw	a1,a1,a3
ffffffffc020237e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0202380:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0202382:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0202384:	00469793          	slli	a5,a3,0x4
ffffffffc0202388:	97ba                	add	a5,a5,a4
ffffffffc020238a:	fcf416e3          	bne	s0,a5,ffffffffc0202356 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc020238e:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0202390:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0202392:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0202394:	9ebd                	addw	a3,a3,a5
ffffffffc0202396:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0202398:	e70c                	sd	a1,8(a4)
ffffffffc020239a:	d169                	beqz	a0,ffffffffc020235c <slob_free+0x50>
}
ffffffffc020239c:	6402                	ld	s0,0(sp)
ffffffffc020239e:	60a2                	ld	ra,8(sp)
ffffffffc02023a0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02023a2:	d74fe06f          	j	ffffffffc0200916 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02023a6:	25bd                	addiw	a1,a1,15
ffffffffc02023a8:	8191                	srli	a1,a1,0x4
ffffffffc02023aa:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02023ac:	100027f3          	csrr	a5,sstatus
ffffffffc02023b0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02023b2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02023b4:	d7bd                	beqz	a5,ffffffffc0202322 <slob_free+0x16>
        intr_disable();
ffffffffc02023b6:	d66fe0ef          	jal	ra,ffffffffc020091c <intr_disable>
        return 1;
ffffffffc02023ba:	4505                	li	a0,1
ffffffffc02023bc:	b79d                	j	ffffffffc0202322 <slob_free+0x16>
ffffffffc02023be:	8082                	ret

ffffffffc02023c0 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc02023c0:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02023c2:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc02023c4:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02023c8:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc02023ca:	9d5fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
	if (!page)
ffffffffc02023ce:	c91d                	beqz	a0,ffffffffc0202404 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02023d0:	0000b697          	auipc	a3,0xb
ffffffffc02023d4:	0d06b683          	ld	a3,208(a3) # ffffffffc020d4a0 <pages>
ffffffffc02023d8:	8d15                	sub	a0,a0,a3
ffffffffc02023da:	8519                	srai	a0,a0,0x6
ffffffffc02023dc:	00003697          	auipc	a3,0x3
ffffffffc02023e0:	1146b683          	ld	a3,276(a3) # ffffffffc02054f0 <nbase>
ffffffffc02023e4:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02023e6:	00c51793          	slli	a5,a0,0xc
ffffffffc02023ea:	83b1                	srli	a5,a5,0xc
ffffffffc02023ec:	0000b717          	auipc	a4,0xb
ffffffffc02023f0:	0ac73703          	ld	a4,172(a4) # ffffffffc020d498 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02023f4:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02023f6:	00e7fa63          	bgeu	a5,a4,ffffffffc020240a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02023fa:	0000b697          	auipc	a3,0xb
ffffffffc02023fe:	0b66b683          	ld	a3,182(a3) # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0202402:	9536                	add	a0,a0,a3
}
ffffffffc0202404:	60a2                	ld	ra,8(sp)
ffffffffc0202406:	0141                	addi	sp,sp,16
ffffffffc0202408:	8082                	ret
ffffffffc020240a:	86aa                	mv	a3,a0
ffffffffc020240c:	00002617          	auipc	a2,0x2
ffffffffc0202410:	0d460613          	addi	a2,a2,212 # ffffffffc02044e0 <commands+0x830>
ffffffffc0202414:	07100593          	li	a1,113
ffffffffc0202418:	00002517          	auipc	a0,0x2
ffffffffc020241c:	09050513          	addi	a0,a0,144 # ffffffffc02044a8 <commands+0x7f8>
ffffffffc0202420:	dbffd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202424 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0202424:	1101                	addi	sp,sp,-32
ffffffffc0202426:	ec06                	sd	ra,24(sp)
ffffffffc0202428:	e822                	sd	s0,16(sp)
ffffffffc020242a:	e426                	sd	s1,8(sp)
ffffffffc020242c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc020242e:	01050713          	addi	a4,a0,16
ffffffffc0202432:	6785                	lui	a5,0x1
ffffffffc0202434:	0cf77363          	bgeu	a4,a5,ffffffffc02024fa <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0202438:	00f50493          	addi	s1,a0,15
ffffffffc020243c:	8091                	srli	s1,s1,0x4
ffffffffc020243e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202440:	10002673          	csrr	a2,sstatus
ffffffffc0202444:	8a09                	andi	a2,a2,2
ffffffffc0202446:	e25d                	bnez	a2,ffffffffc02024ec <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0202448:	00007917          	auipc	s2,0x7
ffffffffc020244c:	bd890913          	addi	s2,s2,-1064 # ffffffffc0209020 <slobfree>
ffffffffc0202450:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0202454:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0202456:	4398                	lw	a4,0(a5)
ffffffffc0202458:	08975e63          	bge	a4,s1,ffffffffc02024f4 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc020245c:	00d78b63          	beq	a5,a3,ffffffffc0202472 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0202460:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0202462:	4018                	lw	a4,0(s0)
ffffffffc0202464:	02975a63          	bge	a4,s1,ffffffffc0202498 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0202468:	00093683          	ld	a3,0(s2)
ffffffffc020246c:	87a2                	mv	a5,s0
ffffffffc020246e:	fed799e3          	bne	a5,a3,ffffffffc0202460 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0202472:	ee31                	bnez	a2,ffffffffc02024ce <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0202474:	4501                	li	a0,0
ffffffffc0202476:	f4bff0ef          	jal	ra,ffffffffc02023c0 <__slob_get_free_pages.constprop.0>
ffffffffc020247a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc020247c:	cd05                	beqz	a0,ffffffffc02024b4 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc020247e:	6585                	lui	a1,0x1
ffffffffc0202480:	e8dff0ef          	jal	ra,ffffffffc020230c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202484:	10002673          	csrr	a2,sstatus
ffffffffc0202488:	8a09                	andi	a2,a2,2
ffffffffc020248a:	ee05                	bnez	a2,ffffffffc02024c2 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc020248c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0202490:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0202492:	4018                	lw	a4,0(s0)
ffffffffc0202494:	fc974ae3          	blt	a4,s1,ffffffffc0202468 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0202498:	04e48763          	beq	s1,a4,ffffffffc02024e6 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc020249c:	00449693          	slli	a3,s1,0x4
ffffffffc02024a0:	96a2                	add	a3,a3,s0
ffffffffc02024a2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02024a4:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02024a6:	9f05                	subw	a4,a4,s1
ffffffffc02024a8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02024aa:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02024ac:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02024ae:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02024b2:	e20d                	bnez	a2,ffffffffc02024d4 <slob_alloc.constprop.0+0xb0>
}
ffffffffc02024b4:	60e2                	ld	ra,24(sp)
ffffffffc02024b6:	8522                	mv	a0,s0
ffffffffc02024b8:	6442                	ld	s0,16(sp)
ffffffffc02024ba:	64a2                	ld	s1,8(sp)
ffffffffc02024bc:	6902                	ld	s2,0(sp)
ffffffffc02024be:	6105                	addi	sp,sp,32
ffffffffc02024c0:	8082                	ret
        intr_disable();
ffffffffc02024c2:	c5afe0ef          	jal	ra,ffffffffc020091c <intr_disable>
			cur = slobfree;
ffffffffc02024c6:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02024ca:	4605                	li	a2,1
ffffffffc02024cc:	b7d1                	j	ffffffffc0202490 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02024ce:	c48fe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc02024d2:	b74d                	j	ffffffffc0202474 <slob_alloc.constprop.0+0x50>
ffffffffc02024d4:	c42fe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
}
ffffffffc02024d8:	60e2                	ld	ra,24(sp)
ffffffffc02024da:	8522                	mv	a0,s0
ffffffffc02024dc:	6442                	ld	s0,16(sp)
ffffffffc02024de:	64a2                	ld	s1,8(sp)
ffffffffc02024e0:	6902                	ld	s2,0(sp)
ffffffffc02024e2:	6105                	addi	sp,sp,32
ffffffffc02024e4:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02024e6:	6418                	ld	a4,8(s0)
ffffffffc02024e8:	e798                	sd	a4,8(a5)
ffffffffc02024ea:	b7d1                	j	ffffffffc02024ae <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02024ec:	c30fe0ef          	jal	ra,ffffffffc020091c <intr_disable>
        return 1;
ffffffffc02024f0:	4605                	li	a2,1
ffffffffc02024f2:	bf99                	j	ffffffffc0202448 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc02024f4:	843e                	mv	s0,a5
ffffffffc02024f6:	87b6                	mv	a5,a3
ffffffffc02024f8:	b745                	j	ffffffffc0202498 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02024fa:	00003697          	auipc	a3,0x3
ffffffffc02024fe:	81e68693          	addi	a3,a3,-2018 # ffffffffc0204d18 <commands+0x1068>
ffffffffc0202502:	00002617          	auipc	a2,0x2
ffffffffc0202506:	10e60613          	addi	a2,a2,270 # ffffffffc0204610 <commands+0x960>
ffffffffc020250a:	06300593          	li	a1,99
ffffffffc020250e:	00003517          	auipc	a0,0x3
ffffffffc0202512:	82a50513          	addi	a0,a0,-2006 # ffffffffc0204d38 <commands+0x1088>
ffffffffc0202516:	cc9fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020251a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc020251a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc020251c:	00003517          	auipc	a0,0x3
ffffffffc0202520:	83450513          	addi	a0,a0,-1996 # ffffffffc0204d50 <commands+0x10a0>
{
ffffffffc0202524:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0202526:	bbbfd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc020252a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc020252c:	00003517          	auipc	a0,0x3
ffffffffc0202530:	83c50513          	addi	a0,a0,-1988 # ffffffffc0204d68 <commands+0x10b8>
}
ffffffffc0202534:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0202536:	babfd06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc020253a <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc020253a:	1101                	addi	sp,sp,-32
ffffffffc020253c:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc020253e:	6905                	lui	s2,0x1
{
ffffffffc0202540:	e822                	sd	s0,16(sp)
ffffffffc0202542:	ec06                	sd	ra,24(sp)
ffffffffc0202544:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0202546:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc020254a:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc020254c:	04a7f963          	bgeu	a5,a0,ffffffffc020259e <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0202550:	4561                	li	a0,24
ffffffffc0202552:	ed3ff0ef          	jal	ra,ffffffffc0202424 <slob_alloc.constprop.0>
ffffffffc0202556:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0202558:	c929                	beqz	a0,ffffffffc02025aa <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc020255a:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc020255e:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0202560:	00f95763          	bge	s2,a5,ffffffffc020256e <kmalloc+0x34>
ffffffffc0202564:	6705                	lui	a4,0x1
ffffffffc0202566:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0202568:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc020256a:	fef74ee3          	blt	a4,a5,ffffffffc0202566 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc020256e:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0202570:	e51ff0ef          	jal	ra,ffffffffc02023c0 <__slob_get_free_pages.constprop.0>
ffffffffc0202574:	e488                	sd	a0,8(s1)
ffffffffc0202576:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0202578:	c525                	beqz	a0,ffffffffc02025e0 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020257a:	100027f3          	csrr	a5,sstatus
ffffffffc020257e:	8b89                	andi	a5,a5,2
ffffffffc0202580:	ef8d                	bnez	a5,ffffffffc02025ba <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0202582:	0000b797          	auipc	a5,0xb
ffffffffc0202586:	f3678793          	addi	a5,a5,-202 # ffffffffc020d4b8 <bigblocks>
ffffffffc020258a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc020258c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020258e:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0202590:	60e2                	ld	ra,24(sp)
ffffffffc0202592:	8522                	mv	a0,s0
ffffffffc0202594:	6442                	ld	s0,16(sp)
ffffffffc0202596:	64a2                	ld	s1,8(sp)
ffffffffc0202598:	6902                	ld	s2,0(sp)
ffffffffc020259a:	6105                	addi	sp,sp,32
ffffffffc020259c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc020259e:	0541                	addi	a0,a0,16
ffffffffc02025a0:	e85ff0ef          	jal	ra,ffffffffc0202424 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc02025a4:	01050413          	addi	s0,a0,16
ffffffffc02025a8:	f565                	bnez	a0,ffffffffc0202590 <kmalloc+0x56>
ffffffffc02025aa:	4401                	li	s0,0
}
ffffffffc02025ac:	60e2                	ld	ra,24(sp)
ffffffffc02025ae:	8522                	mv	a0,s0
ffffffffc02025b0:	6442                	ld	s0,16(sp)
ffffffffc02025b2:	64a2                	ld	s1,8(sp)
ffffffffc02025b4:	6902                	ld	s2,0(sp)
ffffffffc02025b6:	6105                	addi	sp,sp,32
ffffffffc02025b8:	8082                	ret
        intr_disable();
ffffffffc02025ba:	b62fe0ef          	jal	ra,ffffffffc020091c <intr_disable>
		bb->next = bigblocks;
ffffffffc02025be:	0000b797          	auipc	a5,0xb
ffffffffc02025c2:	efa78793          	addi	a5,a5,-262 # ffffffffc020d4b8 <bigblocks>
ffffffffc02025c6:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc02025c8:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02025ca:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc02025cc:	b4afe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
		return bb->pages;
ffffffffc02025d0:	6480                	ld	s0,8(s1)
}
ffffffffc02025d2:	60e2                	ld	ra,24(sp)
ffffffffc02025d4:	64a2                	ld	s1,8(sp)
ffffffffc02025d6:	8522                	mv	a0,s0
ffffffffc02025d8:	6442                	ld	s0,16(sp)
ffffffffc02025da:	6902                	ld	s2,0(sp)
ffffffffc02025dc:	6105                	addi	sp,sp,32
ffffffffc02025de:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc02025e0:	45e1                	li	a1,24
ffffffffc02025e2:	8526                	mv	a0,s1
ffffffffc02025e4:	d29ff0ef          	jal	ra,ffffffffc020230c <slob_free>
	return __kmalloc(size, 0);
ffffffffc02025e8:	b765                	j	ffffffffc0202590 <kmalloc+0x56>

ffffffffc02025ea <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc02025ea:	c179                	beqz	a0,ffffffffc02026b0 <kfree+0xc6>
{
ffffffffc02025ec:	1101                	addi	sp,sp,-32
ffffffffc02025ee:	e822                	sd	s0,16(sp)
ffffffffc02025f0:	ec06                	sd	ra,24(sp)
ffffffffc02025f2:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc02025f4:	03451793          	slli	a5,a0,0x34
ffffffffc02025f8:	842a                	mv	s0,a0
ffffffffc02025fa:	e7c1                	bnez	a5,ffffffffc0202682 <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02025fc:	100027f3          	csrr	a5,sstatus
ffffffffc0202600:	8b89                	andi	a5,a5,2
ffffffffc0202602:	ebc9                	bnez	a5,ffffffffc0202694 <kfree+0xaa>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202604:	0000b797          	auipc	a5,0xb
ffffffffc0202608:	eb47b783          	ld	a5,-332(a5) # ffffffffc020d4b8 <bigblocks>
    return 0;
ffffffffc020260c:	4601                	li	a2,0
ffffffffc020260e:	cbb5                	beqz	a5,ffffffffc0202682 <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0202610:	0000b697          	auipc	a3,0xb
ffffffffc0202614:	ea868693          	addi	a3,a3,-344 # ffffffffc020d4b8 <bigblocks>
ffffffffc0202618:	a021                	j	ffffffffc0202620 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc020261a:	01048693          	addi	a3,s1,16
ffffffffc020261e:	c3ad                	beqz	a5,ffffffffc0202680 <kfree+0x96>
		{
			if (bb->pages == block)
ffffffffc0202620:	6798                	ld	a4,8(a5)
ffffffffc0202622:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0202624:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0202626:	fe871ae3          	bne	a4,s0,ffffffffc020261a <kfree+0x30>
				*last = bb->next;
ffffffffc020262a:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc020262c:	ee3d                	bnez	a2,ffffffffc02026aa <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc020262e:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0202632:	4098                	lw	a4,0(s1)
ffffffffc0202634:	08f46b63          	bltu	s0,a5,ffffffffc02026ca <kfree+0xe0>
ffffffffc0202638:	0000b697          	auipc	a3,0xb
ffffffffc020263c:	e786b683          	ld	a3,-392(a3) # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0202640:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0202642:	8031                	srli	s0,s0,0xc
ffffffffc0202644:	0000b797          	auipc	a5,0xb
ffffffffc0202648:	e547b783          	ld	a5,-428(a5) # ffffffffc020d498 <npage>
ffffffffc020264c:	06f47363          	bgeu	s0,a5,ffffffffc02026b2 <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202650:	00003517          	auipc	a0,0x3
ffffffffc0202654:	ea053503          	ld	a0,-352(a0) # ffffffffc02054f0 <nbase>
ffffffffc0202658:	8c09                	sub	s0,s0,a0
ffffffffc020265a:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc020265c:	0000b517          	auipc	a0,0xb
ffffffffc0202660:	e4453503          	ld	a0,-444(a0) # ffffffffc020d4a0 <pages>
ffffffffc0202664:	4585                	li	a1,1
ffffffffc0202666:	9522                	add	a0,a0,s0
ffffffffc0202668:	00e595bb          	sllw	a1,a1,a4
ffffffffc020266c:	f70fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0202670:	6442                	ld	s0,16(sp)
ffffffffc0202672:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202674:	8526                	mv	a0,s1
}
ffffffffc0202676:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202678:	45e1                	li	a1,24
}
ffffffffc020267a:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020267c:	c91ff06f          	j	ffffffffc020230c <slob_free>
ffffffffc0202680:	e215                	bnez	a2,ffffffffc02026a4 <kfree+0xba>
ffffffffc0202682:	ff040513          	addi	a0,s0,-16
}
ffffffffc0202686:	6442                	ld	s0,16(sp)
ffffffffc0202688:	60e2                	ld	ra,24(sp)
ffffffffc020268a:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc020268c:	4581                	li	a1,0
}
ffffffffc020268e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202690:	c7dff06f          	j	ffffffffc020230c <slob_free>
        intr_disable();
ffffffffc0202694:	a88fe0ef          	jal	ra,ffffffffc020091c <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202698:	0000b797          	auipc	a5,0xb
ffffffffc020269c:	e207b783          	ld	a5,-480(a5) # ffffffffc020d4b8 <bigblocks>
        return 1;
ffffffffc02026a0:	4605                	li	a2,1
ffffffffc02026a2:	f7bd                	bnez	a5,ffffffffc0202610 <kfree+0x26>
        intr_enable();
ffffffffc02026a4:	a72fe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc02026a8:	bfe9                	j	ffffffffc0202682 <kfree+0x98>
ffffffffc02026aa:	a6cfe0ef          	jal	ra,ffffffffc0200916 <intr_enable>
ffffffffc02026ae:	b741                	j	ffffffffc020262e <kfree+0x44>
ffffffffc02026b0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02026b2:	00002617          	auipc	a2,0x2
ffffffffc02026b6:	dd660613          	addi	a2,a2,-554 # ffffffffc0204488 <commands+0x7d8>
ffffffffc02026ba:	06900593          	li	a1,105
ffffffffc02026be:	00002517          	auipc	a0,0x2
ffffffffc02026c2:	dea50513          	addi	a0,a0,-534 # ffffffffc02044a8 <commands+0x7f8>
ffffffffc02026c6:	b19fd0ef          	jal	ra,ffffffffc02001de <__panic>
    return pa2page(PADDR(kva));
ffffffffc02026ca:	86a2                	mv	a3,s0
ffffffffc02026cc:	00002617          	auipc	a2,0x2
ffffffffc02026d0:	ec460613          	addi	a2,a2,-316 # ffffffffc0204590 <commands+0x8e0>
ffffffffc02026d4:	07700593          	li	a1,119
ffffffffc02026d8:	00002517          	auipc	a0,0x2
ffffffffc02026dc:	dd050513          	addi	a0,a0,-560 # ffffffffc02044a8 <commands+0x7f8>
ffffffffc02026e0:	afffd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02026e4 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02026e4:	00007797          	auipc	a5,0x7
ffffffffc02026e8:	d4478793          	addi	a5,a5,-700 # ffffffffc0209428 <free_area>
ffffffffc02026ec:	e79c                	sd	a5,8(a5)
ffffffffc02026ee:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02026f0:	0007a823          	sw	zero,16(a5)
}
ffffffffc02026f4:	8082                	ret

ffffffffc02026f6 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02026f6:	00007517          	auipc	a0,0x7
ffffffffc02026fa:	d4256503          	lwu	a0,-702(a0) # ffffffffc0209438 <free_area+0x10>
ffffffffc02026fe:	8082                	ret

ffffffffc0202700 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0202700:	715d                	addi	sp,sp,-80
ffffffffc0202702:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0202704:	00007417          	auipc	s0,0x7
ffffffffc0202708:	d2440413          	addi	s0,s0,-732 # ffffffffc0209428 <free_area>
ffffffffc020270c:	641c                	ld	a5,8(s0)
ffffffffc020270e:	e486                	sd	ra,72(sp)
ffffffffc0202710:	fc26                	sd	s1,56(sp)
ffffffffc0202712:	f84a                	sd	s2,48(sp)
ffffffffc0202714:	f44e                	sd	s3,40(sp)
ffffffffc0202716:	f052                	sd	s4,32(sp)
ffffffffc0202718:	ec56                	sd	s5,24(sp)
ffffffffc020271a:	e85a                	sd	s6,16(sp)
ffffffffc020271c:	e45e                	sd	s7,8(sp)
ffffffffc020271e:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202720:	2a878d63          	beq	a5,s0,ffffffffc02029da <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0202724:	4481                	li	s1,0
ffffffffc0202726:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202728:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020272c:	8b09                	andi	a4,a4,2
ffffffffc020272e:	2a070a63          	beqz	a4,ffffffffc02029e2 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0202732:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202736:	679c                	ld	a5,8(a5)
ffffffffc0202738:	2905                	addiw	s2,s2,1
ffffffffc020273a:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020273c:	fe8796e3          	bne	a5,s0,ffffffffc0202728 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0202740:	89a6                	mv	s3,s1
ffffffffc0202742:	ed8fe0ef          	jal	ra,ffffffffc0200e1a <nr_free_pages>
ffffffffc0202746:	6f351e63          	bne	a0,s3,ffffffffc0202e42 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020274a:	4505                	li	a0,1
ffffffffc020274c:	e52fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202750:	8aaa                	mv	s5,a0
ffffffffc0202752:	42050863          	beqz	a0,ffffffffc0202b82 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202756:	4505                	li	a0,1
ffffffffc0202758:	e46fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc020275c:	89aa                	mv	s3,a0
ffffffffc020275e:	70050263          	beqz	a0,ffffffffc0202e62 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202762:	4505                	li	a0,1
ffffffffc0202764:	e3afe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202768:	8a2a                	mv	s4,a0
ffffffffc020276a:	48050c63          	beqz	a0,ffffffffc0202c02 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020276e:	293a8a63          	beq	s5,s3,ffffffffc0202a02 <default_check+0x302>
ffffffffc0202772:	28aa8863          	beq	s5,a0,ffffffffc0202a02 <default_check+0x302>
ffffffffc0202776:	28a98663          	beq	s3,a0,ffffffffc0202a02 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020277a:	000aa783          	lw	a5,0(s5)
ffffffffc020277e:	2a079263          	bnez	a5,ffffffffc0202a22 <default_check+0x322>
ffffffffc0202782:	0009a783          	lw	a5,0(s3)
ffffffffc0202786:	28079e63          	bnez	a5,ffffffffc0202a22 <default_check+0x322>
ffffffffc020278a:	411c                	lw	a5,0(a0)
ffffffffc020278c:	28079b63          	bnez	a5,ffffffffc0202a22 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0202790:	0000b797          	auipc	a5,0xb
ffffffffc0202794:	d107b783          	ld	a5,-752(a5) # ffffffffc020d4a0 <pages>
ffffffffc0202798:	40fa8733          	sub	a4,s5,a5
ffffffffc020279c:	00003617          	auipc	a2,0x3
ffffffffc02027a0:	d5463603          	ld	a2,-684(a2) # ffffffffc02054f0 <nbase>
ffffffffc02027a4:	8719                	srai	a4,a4,0x6
ffffffffc02027a6:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02027a8:	0000b697          	auipc	a3,0xb
ffffffffc02027ac:	cf06b683          	ld	a3,-784(a3) # ffffffffc020d498 <npage>
ffffffffc02027b0:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02027b2:	0732                	slli	a4,a4,0xc
ffffffffc02027b4:	28d77763          	bgeu	a4,a3,ffffffffc0202a42 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02027b8:	40f98733          	sub	a4,s3,a5
ffffffffc02027bc:	8719                	srai	a4,a4,0x6
ffffffffc02027be:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02027c0:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02027c2:	4cd77063          	bgeu	a4,a3,ffffffffc0202c82 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02027c6:	40f507b3          	sub	a5,a0,a5
ffffffffc02027ca:	8799                	srai	a5,a5,0x6
ffffffffc02027cc:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02027ce:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02027d0:	30d7f963          	bgeu	a5,a3,ffffffffc0202ae2 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02027d4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02027d6:	00043c03          	ld	s8,0(s0)
ffffffffc02027da:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02027de:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02027e2:	e400                	sd	s0,8(s0)
ffffffffc02027e4:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02027e6:	00007797          	auipc	a5,0x7
ffffffffc02027ea:	c407a923          	sw	zero,-942(a5) # ffffffffc0209438 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02027ee:	db0fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc02027f2:	2c051863          	bnez	a0,ffffffffc0202ac2 <default_check+0x3c2>
    free_page(p0);
ffffffffc02027f6:	4585                	li	a1,1
ffffffffc02027f8:	8556                	mv	a0,s5
ffffffffc02027fa:	de2fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    free_page(p1);
ffffffffc02027fe:	4585                	li	a1,1
ffffffffc0202800:	854e                	mv	a0,s3
ffffffffc0202802:	ddafe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    free_page(p2);
ffffffffc0202806:	4585                	li	a1,1
ffffffffc0202808:	8552                	mv	a0,s4
ffffffffc020280a:	dd2fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    assert(nr_free == 3);
ffffffffc020280e:	4818                	lw	a4,16(s0)
ffffffffc0202810:	478d                	li	a5,3
ffffffffc0202812:	28f71863          	bne	a4,a5,ffffffffc0202aa2 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202816:	4505                	li	a0,1
ffffffffc0202818:	d86fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc020281c:	89aa                	mv	s3,a0
ffffffffc020281e:	26050263          	beqz	a0,ffffffffc0202a82 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202822:	4505                	li	a0,1
ffffffffc0202824:	d7afe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202828:	8aaa                	mv	s5,a0
ffffffffc020282a:	3a050c63          	beqz	a0,ffffffffc0202be2 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020282e:	4505                	li	a0,1
ffffffffc0202830:	d6efe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202834:	8a2a                	mv	s4,a0
ffffffffc0202836:	38050663          	beqz	a0,ffffffffc0202bc2 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc020283a:	4505                	li	a0,1
ffffffffc020283c:	d62fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202840:	36051163          	bnez	a0,ffffffffc0202ba2 <default_check+0x4a2>
    free_page(p0);
ffffffffc0202844:	4585                	li	a1,1
ffffffffc0202846:	854e                	mv	a0,s3
ffffffffc0202848:	d94fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020284c:	641c                	ld	a5,8(s0)
ffffffffc020284e:	20878a63          	beq	a5,s0,ffffffffc0202a62 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0202852:	4505                	li	a0,1
ffffffffc0202854:	d4afe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202858:	30a99563          	bne	s3,a0,ffffffffc0202b62 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc020285c:	4505                	li	a0,1
ffffffffc020285e:	d40fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202862:	2e051063          	bnez	a0,ffffffffc0202b42 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0202866:	481c                	lw	a5,16(s0)
ffffffffc0202868:	2a079d63          	bnez	a5,ffffffffc0202b22 <default_check+0x422>
    free_page(p);
ffffffffc020286c:	854e                	mv	a0,s3
ffffffffc020286e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0202870:	01843023          	sd	s8,0(s0)
ffffffffc0202874:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0202878:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020287c:	d60fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    free_page(p1);
ffffffffc0202880:	4585                	li	a1,1
ffffffffc0202882:	8556                	mv	a0,s5
ffffffffc0202884:	d58fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    free_page(p2);
ffffffffc0202888:	4585                	li	a1,1
ffffffffc020288a:	8552                	mv	a0,s4
ffffffffc020288c:	d50fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0202890:	4515                	li	a0,5
ffffffffc0202892:	d0cfe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202896:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0202898:	26050563          	beqz	a0,ffffffffc0202b02 <default_check+0x402>
ffffffffc020289c:	651c                	ld	a5,8(a0)
ffffffffc020289e:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc02028a0:	8b85                	andi	a5,a5,1
ffffffffc02028a2:	54079063          	bnez	a5,ffffffffc0202de2 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02028a6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02028a8:	00043b03          	ld	s6,0(s0)
ffffffffc02028ac:	00843a83          	ld	s5,8(s0)
ffffffffc02028b0:	e000                	sd	s0,0(s0)
ffffffffc02028b2:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02028b4:	ceafe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc02028b8:	50051563          	bnez	a0,ffffffffc0202dc2 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02028bc:	08098a13          	addi	s4,s3,128
ffffffffc02028c0:	8552                	mv	a0,s4
ffffffffc02028c2:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02028c4:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02028c8:	00007797          	auipc	a5,0x7
ffffffffc02028cc:	b607a823          	sw	zero,-1168(a5) # ffffffffc0209438 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02028d0:	d0cfe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02028d4:	4511                	li	a0,4
ffffffffc02028d6:	cc8fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc02028da:	4c051463          	bnez	a0,ffffffffc0202da2 <default_check+0x6a2>
ffffffffc02028de:	0889b783          	ld	a5,136(s3)
ffffffffc02028e2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02028e4:	8b85                	andi	a5,a5,1
ffffffffc02028e6:	48078e63          	beqz	a5,ffffffffc0202d82 <default_check+0x682>
ffffffffc02028ea:	0909a703          	lw	a4,144(s3)
ffffffffc02028ee:	478d                	li	a5,3
ffffffffc02028f0:	48f71963          	bne	a4,a5,ffffffffc0202d82 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02028f4:	450d                	li	a0,3
ffffffffc02028f6:	ca8fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc02028fa:	8c2a                	mv	s8,a0
ffffffffc02028fc:	46050363          	beqz	a0,ffffffffc0202d62 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0202900:	4505                	li	a0,1
ffffffffc0202902:	c9cfe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202906:	42051e63          	bnez	a0,ffffffffc0202d42 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc020290a:	418a1c63          	bne	s4,s8,ffffffffc0202d22 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020290e:	4585                	li	a1,1
ffffffffc0202910:	854e                	mv	a0,s3
ffffffffc0202912:	ccafe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    free_pages(p1, 3);
ffffffffc0202916:	458d                	li	a1,3
ffffffffc0202918:	8552                	mv	a0,s4
ffffffffc020291a:	cc2fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
ffffffffc020291e:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0202922:	04098c13          	addi	s8,s3,64
ffffffffc0202926:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202928:	8b85                	andi	a5,a5,1
ffffffffc020292a:	3c078c63          	beqz	a5,ffffffffc0202d02 <default_check+0x602>
ffffffffc020292e:	0109a703          	lw	a4,16(s3)
ffffffffc0202932:	4785                	li	a5,1
ffffffffc0202934:	3cf71763          	bne	a4,a5,ffffffffc0202d02 <default_check+0x602>
ffffffffc0202938:	008a3783          	ld	a5,8(s4)
ffffffffc020293c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020293e:	8b85                	andi	a5,a5,1
ffffffffc0202940:	3a078163          	beqz	a5,ffffffffc0202ce2 <default_check+0x5e2>
ffffffffc0202944:	010a2703          	lw	a4,16(s4)
ffffffffc0202948:	478d                	li	a5,3
ffffffffc020294a:	38f71c63          	bne	a4,a5,ffffffffc0202ce2 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020294e:	4505                	li	a0,1
ffffffffc0202950:	c4efe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202954:	36a99763          	bne	s3,a0,ffffffffc0202cc2 <default_check+0x5c2>
    free_page(p0);
ffffffffc0202958:	4585                	li	a1,1
ffffffffc020295a:	c82fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020295e:	4509                	li	a0,2
ffffffffc0202960:	c3efe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202964:	32aa1f63          	bne	s4,a0,ffffffffc0202ca2 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0202968:	4589                	li	a1,2
ffffffffc020296a:	c72fe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    free_page(p2);
ffffffffc020296e:	4585                	li	a1,1
ffffffffc0202970:	8562                	mv	a0,s8
ffffffffc0202972:	c6afe0ef          	jal	ra,ffffffffc0200ddc <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202976:	4515                	li	a0,5
ffffffffc0202978:	c26fe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc020297c:	89aa                	mv	s3,a0
ffffffffc020297e:	48050263          	beqz	a0,ffffffffc0202e02 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0202982:	4505                	li	a0,1
ffffffffc0202984:	c1afe0ef          	jal	ra,ffffffffc0200d9e <alloc_pages>
ffffffffc0202988:	2c051d63          	bnez	a0,ffffffffc0202c62 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020298c:	481c                	lw	a5,16(s0)
ffffffffc020298e:	2a079a63          	bnez	a5,ffffffffc0202c42 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0202992:	4595                	li	a1,5
ffffffffc0202994:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202996:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020299a:	01643023          	sd	s6,0(s0)
ffffffffc020299e:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02029a2:	c3afe0ef          	jal	ra,ffffffffc0200ddc <free_pages>
    return listelm->next;
ffffffffc02029a6:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02029a8:	00878963          	beq	a5,s0,ffffffffc02029ba <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02029ac:	ff87a703          	lw	a4,-8(a5)
ffffffffc02029b0:	679c                	ld	a5,8(a5)
ffffffffc02029b2:	397d                	addiw	s2,s2,-1
ffffffffc02029b4:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02029b6:	fe879be3          	bne	a5,s0,ffffffffc02029ac <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02029ba:	26091463          	bnez	s2,ffffffffc0202c22 <default_check+0x522>
    assert(total == 0);
ffffffffc02029be:	46049263          	bnez	s1,ffffffffc0202e22 <default_check+0x722>
}
ffffffffc02029c2:	60a6                	ld	ra,72(sp)
ffffffffc02029c4:	6406                	ld	s0,64(sp)
ffffffffc02029c6:	74e2                	ld	s1,56(sp)
ffffffffc02029c8:	7942                	ld	s2,48(sp)
ffffffffc02029ca:	79a2                	ld	s3,40(sp)
ffffffffc02029cc:	7a02                	ld	s4,32(sp)
ffffffffc02029ce:	6ae2                	ld	s5,24(sp)
ffffffffc02029d0:	6b42                	ld	s6,16(sp)
ffffffffc02029d2:	6ba2                	ld	s7,8(sp)
ffffffffc02029d4:	6c02                	ld	s8,0(sp)
ffffffffc02029d6:	6161                	addi	sp,sp,80
ffffffffc02029d8:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02029da:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02029dc:	4481                	li	s1,0
ffffffffc02029de:	4901                	li	s2,0
ffffffffc02029e0:	b38d                	j	ffffffffc0202742 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02029e2:	00002697          	auipc	a3,0x2
ffffffffc02029e6:	3a668693          	addi	a3,a3,934 # ffffffffc0204d88 <commands+0x10d8>
ffffffffc02029ea:	00002617          	auipc	a2,0x2
ffffffffc02029ee:	c2660613          	addi	a2,a2,-986 # ffffffffc0204610 <commands+0x960>
ffffffffc02029f2:	0f000593          	li	a1,240
ffffffffc02029f6:	00002517          	auipc	a0,0x2
ffffffffc02029fa:	3a250513          	addi	a0,a0,930 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc02029fe:	fe0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202a02:	00002697          	auipc	a3,0x2
ffffffffc0202a06:	42e68693          	addi	a3,a3,1070 # ffffffffc0204e30 <commands+0x1180>
ffffffffc0202a0a:	00002617          	auipc	a2,0x2
ffffffffc0202a0e:	c0660613          	addi	a2,a2,-1018 # ffffffffc0204610 <commands+0x960>
ffffffffc0202a12:	0bd00593          	li	a1,189
ffffffffc0202a16:	00002517          	auipc	a0,0x2
ffffffffc0202a1a:	38250513          	addi	a0,a0,898 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202a1e:	fc0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202a22:	00002697          	auipc	a3,0x2
ffffffffc0202a26:	43668693          	addi	a3,a3,1078 # ffffffffc0204e58 <commands+0x11a8>
ffffffffc0202a2a:	00002617          	auipc	a2,0x2
ffffffffc0202a2e:	be660613          	addi	a2,a2,-1050 # ffffffffc0204610 <commands+0x960>
ffffffffc0202a32:	0be00593          	li	a1,190
ffffffffc0202a36:	00002517          	auipc	a0,0x2
ffffffffc0202a3a:	36250513          	addi	a0,a0,866 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202a3e:	fa0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202a42:	00002697          	auipc	a3,0x2
ffffffffc0202a46:	45668693          	addi	a3,a3,1110 # ffffffffc0204e98 <commands+0x11e8>
ffffffffc0202a4a:	00002617          	auipc	a2,0x2
ffffffffc0202a4e:	bc660613          	addi	a2,a2,-1082 # ffffffffc0204610 <commands+0x960>
ffffffffc0202a52:	0c000593          	li	a1,192
ffffffffc0202a56:	00002517          	auipc	a0,0x2
ffffffffc0202a5a:	34250513          	addi	a0,a0,834 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202a5e:	f80fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!list_empty(&free_list));
ffffffffc0202a62:	00002697          	auipc	a3,0x2
ffffffffc0202a66:	4be68693          	addi	a3,a3,1214 # ffffffffc0204f20 <commands+0x1270>
ffffffffc0202a6a:	00002617          	auipc	a2,0x2
ffffffffc0202a6e:	ba660613          	addi	a2,a2,-1114 # ffffffffc0204610 <commands+0x960>
ffffffffc0202a72:	0d900593          	li	a1,217
ffffffffc0202a76:	00002517          	auipc	a0,0x2
ffffffffc0202a7a:	32250513          	addi	a0,a0,802 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202a7e:	f60fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202a82:	00002697          	auipc	a3,0x2
ffffffffc0202a86:	34e68693          	addi	a3,a3,846 # ffffffffc0204dd0 <commands+0x1120>
ffffffffc0202a8a:	00002617          	auipc	a2,0x2
ffffffffc0202a8e:	b8660613          	addi	a2,a2,-1146 # ffffffffc0204610 <commands+0x960>
ffffffffc0202a92:	0d200593          	li	a1,210
ffffffffc0202a96:	00002517          	auipc	a0,0x2
ffffffffc0202a9a:	30250513          	addi	a0,a0,770 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202a9e:	f40fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 3);
ffffffffc0202aa2:	00002697          	auipc	a3,0x2
ffffffffc0202aa6:	46e68693          	addi	a3,a3,1134 # ffffffffc0204f10 <commands+0x1260>
ffffffffc0202aaa:	00002617          	auipc	a2,0x2
ffffffffc0202aae:	b6660613          	addi	a2,a2,-1178 # ffffffffc0204610 <commands+0x960>
ffffffffc0202ab2:	0d000593          	li	a1,208
ffffffffc0202ab6:	00002517          	auipc	a0,0x2
ffffffffc0202aba:	2e250513          	addi	a0,a0,738 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202abe:	f20fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202ac2:	00002697          	auipc	a3,0x2
ffffffffc0202ac6:	43668693          	addi	a3,a3,1078 # ffffffffc0204ef8 <commands+0x1248>
ffffffffc0202aca:	00002617          	auipc	a2,0x2
ffffffffc0202ace:	b4660613          	addi	a2,a2,-1210 # ffffffffc0204610 <commands+0x960>
ffffffffc0202ad2:	0cb00593          	li	a1,203
ffffffffc0202ad6:	00002517          	auipc	a0,0x2
ffffffffc0202ada:	2c250513          	addi	a0,a0,706 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202ade:	f00fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202ae2:	00002697          	auipc	a3,0x2
ffffffffc0202ae6:	3f668693          	addi	a3,a3,1014 # ffffffffc0204ed8 <commands+0x1228>
ffffffffc0202aea:	00002617          	auipc	a2,0x2
ffffffffc0202aee:	b2660613          	addi	a2,a2,-1242 # ffffffffc0204610 <commands+0x960>
ffffffffc0202af2:	0c200593          	li	a1,194
ffffffffc0202af6:	00002517          	auipc	a0,0x2
ffffffffc0202afa:	2a250513          	addi	a0,a0,674 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202afe:	ee0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != NULL);
ffffffffc0202b02:	00002697          	auipc	a3,0x2
ffffffffc0202b06:	46668693          	addi	a3,a3,1126 # ffffffffc0204f68 <commands+0x12b8>
ffffffffc0202b0a:	00002617          	auipc	a2,0x2
ffffffffc0202b0e:	b0660613          	addi	a2,a2,-1274 # ffffffffc0204610 <commands+0x960>
ffffffffc0202b12:	0f800593          	li	a1,248
ffffffffc0202b16:	00002517          	auipc	a0,0x2
ffffffffc0202b1a:	28250513          	addi	a0,a0,642 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202b1e:	ec0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202b22:	00002697          	auipc	a3,0x2
ffffffffc0202b26:	43668693          	addi	a3,a3,1078 # ffffffffc0204f58 <commands+0x12a8>
ffffffffc0202b2a:	00002617          	auipc	a2,0x2
ffffffffc0202b2e:	ae660613          	addi	a2,a2,-1306 # ffffffffc0204610 <commands+0x960>
ffffffffc0202b32:	0df00593          	li	a1,223
ffffffffc0202b36:	00002517          	auipc	a0,0x2
ffffffffc0202b3a:	26250513          	addi	a0,a0,610 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202b3e:	ea0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202b42:	00002697          	auipc	a3,0x2
ffffffffc0202b46:	3b668693          	addi	a3,a3,950 # ffffffffc0204ef8 <commands+0x1248>
ffffffffc0202b4a:	00002617          	auipc	a2,0x2
ffffffffc0202b4e:	ac660613          	addi	a2,a2,-1338 # ffffffffc0204610 <commands+0x960>
ffffffffc0202b52:	0dd00593          	li	a1,221
ffffffffc0202b56:	00002517          	auipc	a0,0x2
ffffffffc0202b5a:	24250513          	addi	a0,a0,578 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202b5e:	e80fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0202b62:	00002697          	auipc	a3,0x2
ffffffffc0202b66:	3d668693          	addi	a3,a3,982 # ffffffffc0204f38 <commands+0x1288>
ffffffffc0202b6a:	00002617          	auipc	a2,0x2
ffffffffc0202b6e:	aa660613          	addi	a2,a2,-1370 # ffffffffc0204610 <commands+0x960>
ffffffffc0202b72:	0dc00593          	li	a1,220
ffffffffc0202b76:	00002517          	auipc	a0,0x2
ffffffffc0202b7a:	22250513          	addi	a0,a0,546 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202b7e:	e60fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202b82:	00002697          	auipc	a3,0x2
ffffffffc0202b86:	24e68693          	addi	a3,a3,590 # ffffffffc0204dd0 <commands+0x1120>
ffffffffc0202b8a:	00002617          	auipc	a2,0x2
ffffffffc0202b8e:	a8660613          	addi	a2,a2,-1402 # ffffffffc0204610 <commands+0x960>
ffffffffc0202b92:	0b900593          	li	a1,185
ffffffffc0202b96:	00002517          	auipc	a0,0x2
ffffffffc0202b9a:	20250513          	addi	a0,a0,514 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202b9e:	e40fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202ba2:	00002697          	auipc	a3,0x2
ffffffffc0202ba6:	35668693          	addi	a3,a3,854 # ffffffffc0204ef8 <commands+0x1248>
ffffffffc0202baa:	00002617          	auipc	a2,0x2
ffffffffc0202bae:	a6660613          	addi	a2,a2,-1434 # ffffffffc0204610 <commands+0x960>
ffffffffc0202bb2:	0d600593          	li	a1,214
ffffffffc0202bb6:	00002517          	auipc	a0,0x2
ffffffffc0202bba:	1e250513          	addi	a0,a0,482 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202bbe:	e20fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202bc2:	00002697          	auipc	a3,0x2
ffffffffc0202bc6:	24e68693          	addi	a3,a3,590 # ffffffffc0204e10 <commands+0x1160>
ffffffffc0202bca:	00002617          	auipc	a2,0x2
ffffffffc0202bce:	a4660613          	addi	a2,a2,-1466 # ffffffffc0204610 <commands+0x960>
ffffffffc0202bd2:	0d400593          	li	a1,212
ffffffffc0202bd6:	00002517          	auipc	a0,0x2
ffffffffc0202bda:	1c250513          	addi	a0,a0,450 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202bde:	e00fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202be2:	00002697          	auipc	a3,0x2
ffffffffc0202be6:	20e68693          	addi	a3,a3,526 # ffffffffc0204df0 <commands+0x1140>
ffffffffc0202bea:	00002617          	auipc	a2,0x2
ffffffffc0202bee:	a2660613          	addi	a2,a2,-1498 # ffffffffc0204610 <commands+0x960>
ffffffffc0202bf2:	0d300593          	li	a1,211
ffffffffc0202bf6:	00002517          	auipc	a0,0x2
ffffffffc0202bfa:	1a250513          	addi	a0,a0,418 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202bfe:	de0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202c02:	00002697          	auipc	a3,0x2
ffffffffc0202c06:	20e68693          	addi	a3,a3,526 # ffffffffc0204e10 <commands+0x1160>
ffffffffc0202c0a:	00002617          	auipc	a2,0x2
ffffffffc0202c0e:	a0660613          	addi	a2,a2,-1530 # ffffffffc0204610 <commands+0x960>
ffffffffc0202c12:	0bb00593          	li	a1,187
ffffffffc0202c16:	00002517          	auipc	a0,0x2
ffffffffc0202c1a:	18250513          	addi	a0,a0,386 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202c1e:	dc0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(count == 0);
ffffffffc0202c22:	00002697          	auipc	a3,0x2
ffffffffc0202c26:	49668693          	addi	a3,a3,1174 # ffffffffc02050b8 <commands+0x1408>
ffffffffc0202c2a:	00002617          	auipc	a2,0x2
ffffffffc0202c2e:	9e660613          	addi	a2,a2,-1562 # ffffffffc0204610 <commands+0x960>
ffffffffc0202c32:	12500593          	li	a1,293
ffffffffc0202c36:	00002517          	auipc	a0,0x2
ffffffffc0202c3a:	16250513          	addi	a0,a0,354 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202c3e:	da0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202c42:	00002697          	auipc	a3,0x2
ffffffffc0202c46:	31668693          	addi	a3,a3,790 # ffffffffc0204f58 <commands+0x12a8>
ffffffffc0202c4a:	00002617          	auipc	a2,0x2
ffffffffc0202c4e:	9c660613          	addi	a2,a2,-1594 # ffffffffc0204610 <commands+0x960>
ffffffffc0202c52:	11a00593          	li	a1,282
ffffffffc0202c56:	00002517          	auipc	a0,0x2
ffffffffc0202c5a:	14250513          	addi	a0,a0,322 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202c5e:	d80fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202c62:	00002697          	auipc	a3,0x2
ffffffffc0202c66:	29668693          	addi	a3,a3,662 # ffffffffc0204ef8 <commands+0x1248>
ffffffffc0202c6a:	00002617          	auipc	a2,0x2
ffffffffc0202c6e:	9a660613          	addi	a2,a2,-1626 # ffffffffc0204610 <commands+0x960>
ffffffffc0202c72:	11800593          	li	a1,280
ffffffffc0202c76:	00002517          	auipc	a0,0x2
ffffffffc0202c7a:	12250513          	addi	a0,a0,290 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202c7e:	d60fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202c82:	00002697          	auipc	a3,0x2
ffffffffc0202c86:	23668693          	addi	a3,a3,566 # ffffffffc0204eb8 <commands+0x1208>
ffffffffc0202c8a:	00002617          	auipc	a2,0x2
ffffffffc0202c8e:	98660613          	addi	a2,a2,-1658 # ffffffffc0204610 <commands+0x960>
ffffffffc0202c92:	0c100593          	li	a1,193
ffffffffc0202c96:	00002517          	auipc	a0,0x2
ffffffffc0202c9a:	10250513          	addi	a0,a0,258 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202c9e:	d40fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202ca2:	00002697          	auipc	a3,0x2
ffffffffc0202ca6:	3d668693          	addi	a3,a3,982 # ffffffffc0205078 <commands+0x13c8>
ffffffffc0202caa:	00002617          	auipc	a2,0x2
ffffffffc0202cae:	96660613          	addi	a2,a2,-1690 # ffffffffc0204610 <commands+0x960>
ffffffffc0202cb2:	11200593          	li	a1,274
ffffffffc0202cb6:	00002517          	auipc	a0,0x2
ffffffffc0202cba:	0e250513          	addi	a0,a0,226 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202cbe:	d20fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202cc2:	00002697          	auipc	a3,0x2
ffffffffc0202cc6:	39668693          	addi	a3,a3,918 # ffffffffc0205058 <commands+0x13a8>
ffffffffc0202cca:	00002617          	auipc	a2,0x2
ffffffffc0202cce:	94660613          	addi	a2,a2,-1722 # ffffffffc0204610 <commands+0x960>
ffffffffc0202cd2:	11000593          	li	a1,272
ffffffffc0202cd6:	00002517          	auipc	a0,0x2
ffffffffc0202cda:	0c250513          	addi	a0,a0,194 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202cde:	d00fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202ce2:	00002697          	auipc	a3,0x2
ffffffffc0202ce6:	34e68693          	addi	a3,a3,846 # ffffffffc0205030 <commands+0x1380>
ffffffffc0202cea:	00002617          	auipc	a2,0x2
ffffffffc0202cee:	92660613          	addi	a2,a2,-1754 # ffffffffc0204610 <commands+0x960>
ffffffffc0202cf2:	10e00593          	li	a1,270
ffffffffc0202cf6:	00002517          	auipc	a0,0x2
ffffffffc0202cfa:	0a250513          	addi	a0,a0,162 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202cfe:	ce0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202d02:	00002697          	auipc	a3,0x2
ffffffffc0202d06:	30668693          	addi	a3,a3,774 # ffffffffc0205008 <commands+0x1358>
ffffffffc0202d0a:	00002617          	auipc	a2,0x2
ffffffffc0202d0e:	90660613          	addi	a2,a2,-1786 # ffffffffc0204610 <commands+0x960>
ffffffffc0202d12:	10d00593          	li	a1,269
ffffffffc0202d16:	00002517          	auipc	a0,0x2
ffffffffc0202d1a:	08250513          	addi	a0,a0,130 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202d1e:	cc0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202d22:	00002697          	auipc	a3,0x2
ffffffffc0202d26:	2d668693          	addi	a3,a3,726 # ffffffffc0204ff8 <commands+0x1348>
ffffffffc0202d2a:	00002617          	auipc	a2,0x2
ffffffffc0202d2e:	8e660613          	addi	a2,a2,-1818 # ffffffffc0204610 <commands+0x960>
ffffffffc0202d32:	10800593          	li	a1,264
ffffffffc0202d36:	00002517          	auipc	a0,0x2
ffffffffc0202d3a:	06250513          	addi	a0,a0,98 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202d3e:	ca0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202d42:	00002697          	auipc	a3,0x2
ffffffffc0202d46:	1b668693          	addi	a3,a3,438 # ffffffffc0204ef8 <commands+0x1248>
ffffffffc0202d4a:	00002617          	auipc	a2,0x2
ffffffffc0202d4e:	8c660613          	addi	a2,a2,-1850 # ffffffffc0204610 <commands+0x960>
ffffffffc0202d52:	10700593          	li	a1,263
ffffffffc0202d56:	00002517          	auipc	a0,0x2
ffffffffc0202d5a:	04250513          	addi	a0,a0,66 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202d5e:	c80fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202d62:	00002697          	auipc	a3,0x2
ffffffffc0202d66:	27668693          	addi	a3,a3,630 # ffffffffc0204fd8 <commands+0x1328>
ffffffffc0202d6a:	00002617          	auipc	a2,0x2
ffffffffc0202d6e:	8a660613          	addi	a2,a2,-1882 # ffffffffc0204610 <commands+0x960>
ffffffffc0202d72:	10600593          	li	a1,262
ffffffffc0202d76:	00002517          	auipc	a0,0x2
ffffffffc0202d7a:	02250513          	addi	a0,a0,34 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202d7e:	c60fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202d82:	00002697          	auipc	a3,0x2
ffffffffc0202d86:	22668693          	addi	a3,a3,550 # ffffffffc0204fa8 <commands+0x12f8>
ffffffffc0202d8a:	00002617          	auipc	a2,0x2
ffffffffc0202d8e:	88660613          	addi	a2,a2,-1914 # ffffffffc0204610 <commands+0x960>
ffffffffc0202d92:	10500593          	li	a1,261
ffffffffc0202d96:	00002517          	auipc	a0,0x2
ffffffffc0202d9a:	00250513          	addi	a0,a0,2 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202d9e:	c40fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202da2:	00002697          	auipc	a3,0x2
ffffffffc0202da6:	1ee68693          	addi	a3,a3,494 # ffffffffc0204f90 <commands+0x12e0>
ffffffffc0202daa:	00002617          	auipc	a2,0x2
ffffffffc0202dae:	86660613          	addi	a2,a2,-1946 # ffffffffc0204610 <commands+0x960>
ffffffffc0202db2:	10400593          	li	a1,260
ffffffffc0202db6:	00002517          	auipc	a0,0x2
ffffffffc0202dba:	fe250513          	addi	a0,a0,-30 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202dbe:	c20fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202dc2:	00002697          	auipc	a3,0x2
ffffffffc0202dc6:	13668693          	addi	a3,a3,310 # ffffffffc0204ef8 <commands+0x1248>
ffffffffc0202dca:	00002617          	auipc	a2,0x2
ffffffffc0202dce:	84660613          	addi	a2,a2,-1978 # ffffffffc0204610 <commands+0x960>
ffffffffc0202dd2:	0fe00593          	li	a1,254
ffffffffc0202dd6:	00002517          	auipc	a0,0x2
ffffffffc0202dda:	fc250513          	addi	a0,a0,-62 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202dde:	c00fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!PageProperty(p0));
ffffffffc0202de2:	00002697          	auipc	a3,0x2
ffffffffc0202de6:	19668693          	addi	a3,a3,406 # ffffffffc0204f78 <commands+0x12c8>
ffffffffc0202dea:	00002617          	auipc	a2,0x2
ffffffffc0202dee:	82660613          	addi	a2,a2,-2010 # ffffffffc0204610 <commands+0x960>
ffffffffc0202df2:	0f900593          	li	a1,249
ffffffffc0202df6:	00002517          	auipc	a0,0x2
ffffffffc0202dfa:	fa250513          	addi	a0,a0,-94 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202dfe:	be0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202e02:	00002697          	auipc	a3,0x2
ffffffffc0202e06:	29668693          	addi	a3,a3,662 # ffffffffc0205098 <commands+0x13e8>
ffffffffc0202e0a:	00002617          	auipc	a2,0x2
ffffffffc0202e0e:	80660613          	addi	a2,a2,-2042 # ffffffffc0204610 <commands+0x960>
ffffffffc0202e12:	11700593          	li	a1,279
ffffffffc0202e16:	00002517          	auipc	a0,0x2
ffffffffc0202e1a:	f8250513          	addi	a0,a0,-126 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202e1e:	bc0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == 0);
ffffffffc0202e22:	00002697          	auipc	a3,0x2
ffffffffc0202e26:	2a668693          	addi	a3,a3,678 # ffffffffc02050c8 <commands+0x1418>
ffffffffc0202e2a:	00001617          	auipc	a2,0x1
ffffffffc0202e2e:	7e660613          	addi	a2,a2,2022 # ffffffffc0204610 <commands+0x960>
ffffffffc0202e32:	12600593          	li	a1,294
ffffffffc0202e36:	00002517          	auipc	a0,0x2
ffffffffc0202e3a:	f6250513          	addi	a0,a0,-158 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202e3e:	ba0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == nr_free_pages());
ffffffffc0202e42:	00002697          	auipc	a3,0x2
ffffffffc0202e46:	f6e68693          	addi	a3,a3,-146 # ffffffffc0204db0 <commands+0x1100>
ffffffffc0202e4a:	00001617          	auipc	a2,0x1
ffffffffc0202e4e:	7c660613          	addi	a2,a2,1990 # ffffffffc0204610 <commands+0x960>
ffffffffc0202e52:	0f300593          	li	a1,243
ffffffffc0202e56:	00002517          	auipc	a0,0x2
ffffffffc0202e5a:	f4250513          	addi	a0,a0,-190 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202e5e:	b80fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202e62:	00002697          	auipc	a3,0x2
ffffffffc0202e66:	f8e68693          	addi	a3,a3,-114 # ffffffffc0204df0 <commands+0x1140>
ffffffffc0202e6a:	00001617          	auipc	a2,0x1
ffffffffc0202e6e:	7a660613          	addi	a2,a2,1958 # ffffffffc0204610 <commands+0x960>
ffffffffc0202e72:	0ba00593          	li	a1,186
ffffffffc0202e76:	00002517          	auipc	a0,0x2
ffffffffc0202e7a:	f2250513          	addi	a0,a0,-222 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202e7e:	b60fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202e82 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202e82:	1141                	addi	sp,sp,-16
ffffffffc0202e84:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202e86:	14058463          	beqz	a1,ffffffffc0202fce <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0202e8a:	00659693          	slli	a3,a1,0x6
ffffffffc0202e8e:	96aa                	add	a3,a3,a0
ffffffffc0202e90:	87aa                	mv	a5,a0
ffffffffc0202e92:	02d50263          	beq	a0,a3,ffffffffc0202eb6 <default_free_pages+0x34>
ffffffffc0202e96:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202e98:	8b05                	andi	a4,a4,1
ffffffffc0202e9a:	10071a63          	bnez	a4,ffffffffc0202fae <default_free_pages+0x12c>
ffffffffc0202e9e:	6798                	ld	a4,8(a5)
ffffffffc0202ea0:	8b09                	andi	a4,a4,2
ffffffffc0202ea2:	10071663          	bnez	a4,ffffffffc0202fae <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0202ea6:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0202eaa:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202eae:	04078793          	addi	a5,a5,64
ffffffffc0202eb2:	fed792e3          	bne	a5,a3,ffffffffc0202e96 <default_free_pages+0x14>
    base->property = n;
ffffffffc0202eb6:	2581                	sext.w	a1,a1
ffffffffc0202eb8:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0202eba:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202ebe:	4789                	li	a5,2
ffffffffc0202ec0:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0202ec4:	00006697          	auipc	a3,0x6
ffffffffc0202ec8:	56468693          	addi	a3,a3,1380 # ffffffffc0209428 <free_area>
ffffffffc0202ecc:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202ece:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202ed0:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202ed4:	9db9                	addw	a1,a1,a4
ffffffffc0202ed6:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202ed8:	0ad78463          	beq	a5,a3,ffffffffc0202f80 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc0202edc:	fe878713          	addi	a4,a5,-24
ffffffffc0202ee0:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202ee4:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202ee6:	00e56a63          	bltu	a0,a4,ffffffffc0202efa <default_free_pages+0x78>
    return listelm->next;
ffffffffc0202eea:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202eec:	04d70c63          	beq	a4,a3,ffffffffc0202f44 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0202ef0:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202ef2:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202ef6:	fee57ae3          	bgeu	a0,a4,ffffffffc0202eea <default_free_pages+0x68>
ffffffffc0202efa:	c199                	beqz	a1,ffffffffc0202f00 <default_free_pages+0x7e>
ffffffffc0202efc:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202f00:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202f02:	e390                	sd	a2,0(a5)
ffffffffc0202f04:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202f06:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f08:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0202f0a:	00d70d63          	beq	a4,a3,ffffffffc0202f24 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0202f0e:	ff872583          	lw	a1,-8(a4) # ff8 <kern_entry-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0202f12:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0202f16:	02059813          	slli	a6,a1,0x20
ffffffffc0202f1a:	01a85793          	srli	a5,a6,0x1a
ffffffffc0202f1e:	97b2                	add	a5,a5,a2
ffffffffc0202f20:	02f50c63          	beq	a0,a5,ffffffffc0202f58 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0202f24:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0202f26:	00d78c63          	beq	a5,a3,ffffffffc0202f3e <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0202f2a:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0202f2c:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0202f30:	02061593          	slli	a1,a2,0x20
ffffffffc0202f34:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0202f38:	972a                	add	a4,a4,a0
ffffffffc0202f3a:	04e68a63          	beq	a3,a4,ffffffffc0202f8e <default_free_pages+0x10c>
}
ffffffffc0202f3e:	60a2                	ld	ra,8(sp)
ffffffffc0202f40:	0141                	addi	sp,sp,16
ffffffffc0202f42:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202f44:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202f46:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202f48:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202f4a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202f4c:	02d70763          	beq	a4,a3,ffffffffc0202f7a <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0202f50:	8832                	mv	a6,a2
ffffffffc0202f52:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202f54:	87ba                	mv	a5,a4
ffffffffc0202f56:	bf71                	j	ffffffffc0202ef2 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0202f58:	491c                	lw	a5,16(a0)
ffffffffc0202f5a:	9dbd                	addw	a1,a1,a5
ffffffffc0202f5c:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202f60:	57f5                	li	a5,-3
ffffffffc0202f62:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202f66:	01853803          	ld	a6,24(a0)
ffffffffc0202f6a:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0202f6c:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0202f6e:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0202f72:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0202f74:	0105b023          	sd	a6,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202f78:	b77d                	j	ffffffffc0202f26 <default_free_pages+0xa4>
ffffffffc0202f7a:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202f7c:	873e                	mv	a4,a5
ffffffffc0202f7e:	bf41                	j	ffffffffc0202f0e <default_free_pages+0x8c>
}
ffffffffc0202f80:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202f82:	e390                	sd	a2,0(a5)
ffffffffc0202f84:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202f86:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f88:	ed1c                	sd	a5,24(a0)
ffffffffc0202f8a:	0141                	addi	sp,sp,16
ffffffffc0202f8c:	8082                	ret
            base->property += p->property;
ffffffffc0202f8e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202f92:	ff078693          	addi	a3,a5,-16
ffffffffc0202f96:	9e39                	addw	a2,a2,a4
ffffffffc0202f98:	c910                	sw	a2,16(a0)
ffffffffc0202f9a:	5775                	li	a4,-3
ffffffffc0202f9c:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202fa0:	6398                	ld	a4,0(a5)
ffffffffc0202fa2:	679c                	ld	a5,8(a5)
}
ffffffffc0202fa4:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0202fa6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202fa8:	e398                	sd	a4,0(a5)
ffffffffc0202faa:	0141                	addi	sp,sp,16
ffffffffc0202fac:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202fae:	00002697          	auipc	a3,0x2
ffffffffc0202fb2:	13268693          	addi	a3,a3,306 # ffffffffc02050e0 <commands+0x1430>
ffffffffc0202fb6:	00001617          	auipc	a2,0x1
ffffffffc0202fba:	65a60613          	addi	a2,a2,1626 # ffffffffc0204610 <commands+0x960>
ffffffffc0202fbe:	08300593          	li	a1,131
ffffffffc0202fc2:	00002517          	auipc	a0,0x2
ffffffffc0202fc6:	dd650513          	addi	a0,a0,-554 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202fca:	a14fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc0202fce:	00002697          	auipc	a3,0x2
ffffffffc0202fd2:	10a68693          	addi	a3,a3,266 # ffffffffc02050d8 <commands+0x1428>
ffffffffc0202fd6:	00001617          	auipc	a2,0x1
ffffffffc0202fda:	63a60613          	addi	a2,a2,1594 # ffffffffc0204610 <commands+0x960>
ffffffffc0202fde:	08000593          	li	a1,128
ffffffffc0202fe2:	00002517          	auipc	a0,0x2
ffffffffc0202fe6:	db650513          	addi	a0,a0,-586 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc0202fea:	9f4fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202fee <default_alloc_pages>:
    assert(n > 0);
ffffffffc0202fee:	c941                	beqz	a0,ffffffffc020307e <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0202ff0:	00006597          	auipc	a1,0x6
ffffffffc0202ff4:	43858593          	addi	a1,a1,1080 # ffffffffc0209428 <free_area>
ffffffffc0202ff8:	0105a803          	lw	a6,16(a1)
ffffffffc0202ffc:	872a                	mv	a4,a0
ffffffffc0202ffe:	02081793          	slli	a5,a6,0x20
ffffffffc0203002:	9381                	srli	a5,a5,0x20
ffffffffc0203004:	00a7ee63          	bltu	a5,a0,ffffffffc0203020 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203008:	87ae                	mv	a5,a1
ffffffffc020300a:	a801                	j	ffffffffc020301a <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020300c:	ff87a683          	lw	a3,-8(a5)
ffffffffc0203010:	02069613          	slli	a2,a3,0x20
ffffffffc0203014:	9201                	srli	a2,a2,0x20
ffffffffc0203016:	00e67763          	bgeu	a2,a4,ffffffffc0203024 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020301a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020301c:	feb798e3          	bne	a5,a1,ffffffffc020300c <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0203020:	4501                	li	a0,0
}
ffffffffc0203022:	8082                	ret
    return listelm->prev;
ffffffffc0203024:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203028:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020302c:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0203030:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0203034:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0203038:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020303c:	02c77863          	bgeu	a4,a2,ffffffffc020306c <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0203040:	071a                	slli	a4,a4,0x6
ffffffffc0203042:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0203044:	41c686bb          	subw	a3,a3,t3
ffffffffc0203048:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020304a:	00870613          	addi	a2,a4,8
ffffffffc020304e:	4689                	li	a3,2
ffffffffc0203050:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203054:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0203058:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020305c:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0203060:	e290                	sd	a2,0(a3)
ffffffffc0203062:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0203066:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0203068:	01173c23          	sd	a7,24(a4)
ffffffffc020306c:	41c8083b          	subw	a6,a6,t3
ffffffffc0203070:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203074:	5775                	li	a4,-3
ffffffffc0203076:	17c1                	addi	a5,a5,-16
ffffffffc0203078:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020307c:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020307e:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203080:	00002697          	auipc	a3,0x2
ffffffffc0203084:	05868693          	addi	a3,a3,88 # ffffffffc02050d8 <commands+0x1428>
ffffffffc0203088:	00001617          	auipc	a2,0x1
ffffffffc020308c:	58860613          	addi	a2,a2,1416 # ffffffffc0204610 <commands+0x960>
ffffffffc0203090:	06200593          	li	a1,98
ffffffffc0203094:	00002517          	auipc	a0,0x2
ffffffffc0203098:	d0450513          	addi	a0,a0,-764 # ffffffffc0204d98 <commands+0x10e8>
default_alloc_pages(size_t n) {
ffffffffc020309c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020309e:	940fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02030a2 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02030a2:	1141                	addi	sp,sp,-16
ffffffffc02030a4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02030a6:	c5f1                	beqz	a1,ffffffffc0203172 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02030a8:	00659693          	slli	a3,a1,0x6
ffffffffc02030ac:	96aa                	add	a3,a3,a0
ffffffffc02030ae:	87aa                	mv	a5,a0
ffffffffc02030b0:	00d50f63          	beq	a0,a3,ffffffffc02030ce <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02030b4:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02030b6:	8b05                	andi	a4,a4,1
ffffffffc02030b8:	cf49                	beqz	a4,ffffffffc0203152 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02030ba:	0007a823          	sw	zero,16(a5)
ffffffffc02030be:	0007b423          	sd	zero,8(a5)
ffffffffc02030c2:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02030c6:	04078793          	addi	a5,a5,64
ffffffffc02030ca:	fed795e3          	bne	a5,a3,ffffffffc02030b4 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02030ce:	2581                	sext.w	a1,a1
ffffffffc02030d0:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02030d2:	4789                	li	a5,2
ffffffffc02030d4:	00850713          	addi	a4,a0,8
ffffffffc02030d8:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02030dc:	00006697          	auipc	a3,0x6
ffffffffc02030e0:	34c68693          	addi	a3,a3,844 # ffffffffc0209428 <free_area>
ffffffffc02030e4:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02030e6:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02030e8:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02030ec:	9db9                	addw	a1,a1,a4
ffffffffc02030ee:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02030f0:	04d78a63          	beq	a5,a3,ffffffffc0203144 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc02030f4:	fe878713          	addi	a4,a5,-24
ffffffffc02030f8:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02030fc:	4581                	li	a1,0
            if (base < page) {
ffffffffc02030fe:	00e56a63          	bltu	a0,a4,ffffffffc0203112 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0203102:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203104:	02d70263          	beq	a4,a3,ffffffffc0203128 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0203108:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020310a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020310e:	fee57ae3          	bgeu	a0,a4,ffffffffc0203102 <default_init_memmap+0x60>
ffffffffc0203112:	c199                	beqz	a1,ffffffffc0203118 <default_init_memmap+0x76>
ffffffffc0203114:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203118:	6398                	ld	a4,0(a5)
}
ffffffffc020311a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020311c:	e390                	sd	a2,0(a5)
ffffffffc020311e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203120:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203122:	ed18                	sd	a4,24(a0)
ffffffffc0203124:	0141                	addi	sp,sp,16
ffffffffc0203126:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203128:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020312a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020312c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020312e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203130:	00d70663          	beq	a4,a3,ffffffffc020313c <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0203134:	8832                	mv	a6,a2
ffffffffc0203136:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0203138:	87ba                	mv	a5,a4
ffffffffc020313a:	bfc1                	j	ffffffffc020310a <default_init_memmap+0x68>
}
ffffffffc020313c:	60a2                	ld	ra,8(sp)
ffffffffc020313e:	e290                	sd	a2,0(a3)
ffffffffc0203140:	0141                	addi	sp,sp,16
ffffffffc0203142:	8082                	ret
ffffffffc0203144:	60a2                	ld	ra,8(sp)
ffffffffc0203146:	e390                	sd	a2,0(a5)
ffffffffc0203148:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020314a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020314c:	ed1c                	sd	a5,24(a0)
ffffffffc020314e:	0141                	addi	sp,sp,16
ffffffffc0203150:	8082                	ret
        assert(PageReserved(p));
ffffffffc0203152:	00002697          	auipc	a3,0x2
ffffffffc0203156:	fb668693          	addi	a3,a3,-74 # ffffffffc0205108 <commands+0x1458>
ffffffffc020315a:	00001617          	auipc	a2,0x1
ffffffffc020315e:	4b660613          	addi	a2,a2,1206 # ffffffffc0204610 <commands+0x960>
ffffffffc0203162:	04900593          	li	a1,73
ffffffffc0203166:	00002517          	auipc	a0,0x2
ffffffffc020316a:	c3250513          	addi	a0,a0,-974 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc020316e:	870fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc0203172:	00002697          	auipc	a3,0x2
ffffffffc0203176:	f6668693          	addi	a3,a3,-154 # ffffffffc02050d8 <commands+0x1428>
ffffffffc020317a:	00001617          	auipc	a2,0x1
ffffffffc020317e:	49660613          	addi	a2,a2,1174 # ffffffffc0204610 <commands+0x960>
ffffffffc0203182:	04600593          	li	a1,70
ffffffffc0203186:	00002517          	auipc	a0,0x2
ffffffffc020318a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0204d98 <commands+0x10e8>
ffffffffc020318e:	850fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203192 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203192:	7179                	addi	sp,sp,-48
ffffffffc0203194:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203196:	0000a497          	auipc	s1,0xa
ffffffffc020319a:	2aa48493          	addi	s1,s1,682 # ffffffffc020d440 <name.0>
{
ffffffffc020319e:	f022                	sd	s0,32(sp)
ffffffffc02031a0:	e84a                	sd	s2,16(sp)
ffffffffc02031a2:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02031a4:	0000a917          	auipc	s2,0xa
ffffffffc02031a8:	31c93903          	ld	s2,796(s2) # ffffffffc020d4c0 <current>
    memset(name, 0, sizeof(name));
ffffffffc02031ac:	4641                	li	a2,16
ffffffffc02031ae:	4581                	li	a1,0
ffffffffc02031b0:	8526                	mv	a0,s1
{
ffffffffc02031b2:	f406                	sd	ra,40(sp)
ffffffffc02031b4:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02031b6:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc02031ba:	41a000ef          	jal	ra,ffffffffc02035d4 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02031be:	0b490593          	addi	a1,s2,180
ffffffffc02031c2:	463d                	li	a2,15
ffffffffc02031c4:	8526                	mv	a0,s1
ffffffffc02031c6:	420000ef          	jal	ra,ffffffffc02035e6 <memcpy>
ffffffffc02031ca:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02031cc:	85ce                	mv	a1,s3
ffffffffc02031ce:	00002517          	auipc	a0,0x2
ffffffffc02031d2:	f9a50513          	addi	a0,a0,-102 # ffffffffc0205168 <default_pmm_manager+0x38>
ffffffffc02031d6:	f0bfc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02031da:	85a2                	mv	a1,s0
ffffffffc02031dc:	00002517          	auipc	a0,0x2
ffffffffc02031e0:	fb450513          	addi	a0,a0,-76 # ffffffffc0205190 <default_pmm_manager+0x60>
ffffffffc02031e4:	efdfc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02031e8:	00002517          	auipc	a0,0x2
ffffffffc02031ec:	fb850513          	addi	a0,a0,-72 # ffffffffc02051a0 <default_pmm_manager+0x70>
ffffffffc02031f0:	ef1fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
}
ffffffffc02031f4:	70a2                	ld	ra,40(sp)
ffffffffc02031f6:	7402                	ld	s0,32(sp)
ffffffffc02031f8:	64e2                	ld	s1,24(sp)
ffffffffc02031fa:	6942                	ld	s2,16(sp)
ffffffffc02031fc:	69a2                	ld	s3,8(sp)
ffffffffc02031fe:	4501                	li	a0,0
ffffffffc0203200:	6145                	addi	sp,sp,48
ffffffffc0203202:	8082                	ret

ffffffffc0203204 <proc_run>:
}
ffffffffc0203204:	8082                	ret

ffffffffc0203206 <kernel_thread>:
{
ffffffffc0203206:	7169                	addi	sp,sp,-304
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203208:	12000613          	li	a2,288
ffffffffc020320c:	4581                	li	a1,0
ffffffffc020320e:	850a                	mv	a0,sp
{
ffffffffc0203210:	f606                	sd	ra,296(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203212:	3c2000ef          	jal	ra,ffffffffc02035d4 <memset>
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203216:	100027f3          	csrr	a5,sstatus
}
ffffffffc020321a:	70b2                	ld	ra,296(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020321c:	0000a517          	auipc	a0,0xa
ffffffffc0203220:	2bc52503          	lw	a0,700(a0) # ffffffffc020d4d8 <nr_process>
ffffffffc0203224:	6785                	lui	a5,0x1
    int ret = -E_NO_FREE_PROC;
ffffffffc0203226:	00f52533          	slt	a0,a0,a5
}
ffffffffc020322a:	156d                	addi	a0,a0,-5
ffffffffc020322c:	6155                	addi	sp,sp,304
ffffffffc020322e:	8082                	ret

ffffffffc0203230 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0203230:	7179                	addi	sp,sp,-48
ffffffffc0203232:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203234:	0000a797          	auipc	a5,0xa
ffffffffc0203238:	21c78793          	addi	a5,a5,540 # ffffffffc020d450 <proc_list>
ffffffffc020323c:	f406                	sd	ra,40(sp)
ffffffffc020323e:	f022                	sd	s0,32(sp)
ffffffffc0203240:	e84a                	sd	s2,16(sp)
ffffffffc0203242:	e44e                	sd	s3,8(sp)
ffffffffc0203244:	00006497          	auipc	s1,0x6
ffffffffc0203248:	1fc48493          	addi	s1,s1,508 # ffffffffc0209440 <hash_list>
ffffffffc020324c:	e79c                	sd	a5,8(a5)
ffffffffc020324e:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203250:	0000a717          	auipc	a4,0xa
ffffffffc0203254:	1f070713          	addi	a4,a4,496 # ffffffffc020d440 <name.0>
ffffffffc0203258:	87a6                	mv	a5,s1
ffffffffc020325a:	e79c                	sd	a5,8(a5)
ffffffffc020325c:	e39c                	sd	a5,0(a5)
ffffffffc020325e:	07c1                	addi	a5,a5,16
ffffffffc0203260:	fef71de3          	bne	a4,a5,ffffffffc020325a <proc_init+0x2a>
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203264:	0e800513          	li	a0,232
ffffffffc0203268:	ad2ff0ef          	jal	ra,ffffffffc020253a <kmalloc>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020326c:	0000a917          	auipc	s2,0xa
ffffffffc0203270:	25c90913          	addi	s2,s2,604 # ffffffffc020d4c8 <idleproc>
ffffffffc0203274:	00a93023          	sd	a0,0(s2)
ffffffffc0203278:	18050d63          	beqz	a0,ffffffffc0203412 <proc_init+0x1e2>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020327c:	07000513          	li	a0,112
ffffffffc0203280:	abaff0ef          	jal	ra,ffffffffc020253a <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203284:	07000613          	li	a2,112
ffffffffc0203288:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020328a:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020328c:	348000ef          	jal	ra,ffffffffc02035d4 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0203290:	00093503          	ld	a0,0(s2)
ffffffffc0203294:	85a2                	mv	a1,s0
ffffffffc0203296:	07000613          	li	a2,112
ffffffffc020329a:	03050513          	addi	a0,a0,48
ffffffffc020329e:	360000ef          	jal	ra,ffffffffc02035fe <memcmp>
ffffffffc02032a2:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02032a4:	453d                	li	a0,15
ffffffffc02032a6:	a94ff0ef          	jal	ra,ffffffffc020253a <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02032aa:	463d                	li	a2,15
ffffffffc02032ac:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02032ae:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02032b0:	324000ef          	jal	ra,ffffffffc02035d4 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02032b4:	00093503          	ld	a0,0(s2)
ffffffffc02032b8:	463d                	li	a2,15
ffffffffc02032ba:	85a2                	mv	a1,s0
ffffffffc02032bc:	0b450513          	addi	a0,a0,180
ffffffffc02032c0:	33e000ef          	jal	ra,ffffffffc02035fe <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02032c4:	00093783          	ld	a5,0(s2)
ffffffffc02032c8:	0000a717          	auipc	a4,0xa
ffffffffc02032cc:	1c073703          	ld	a4,448(a4) # ffffffffc020d488 <boot_pgdir_pa>
ffffffffc02032d0:	77d4                	ld	a3,168(a5)
ffffffffc02032d2:	0ee68463          	beq	a3,a4,ffffffffc02033ba <proc_init+0x18a>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02032d6:	4709                	li	a4,2
ffffffffc02032d8:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02032da:	00003717          	auipc	a4,0x3
ffffffffc02032de:	d2670713          	addi	a4,a4,-730 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02032e2:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02032e6:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02032e8:	4705                	li	a4,1
ffffffffc02032ea:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02032ec:	4641                	li	a2,16
ffffffffc02032ee:	4581                	li	a1,0
ffffffffc02032f0:	8522                	mv	a0,s0
ffffffffc02032f2:	2e2000ef          	jal	ra,ffffffffc02035d4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02032f6:	463d                	li	a2,15
ffffffffc02032f8:	00002597          	auipc	a1,0x2
ffffffffc02032fc:	f2858593          	addi	a1,a1,-216 # ffffffffc0205220 <default_pmm_manager+0xf0>
ffffffffc0203300:	8522                	mv	a0,s0
ffffffffc0203302:	2e4000ef          	jal	ra,ffffffffc02035e6 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0203306:	0000a717          	auipc	a4,0xa
ffffffffc020330a:	1d270713          	addi	a4,a4,466 # ffffffffc020d4d8 <nr_process>
ffffffffc020330e:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0203310:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203314:	4601                	li	a2,0
    nr_process++;
ffffffffc0203316:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203318:	00002597          	auipc	a1,0x2
ffffffffc020331c:	f1058593          	addi	a1,a1,-240 # ffffffffc0205228 <default_pmm_manager+0xf8>
ffffffffc0203320:	00000517          	auipc	a0,0x0
ffffffffc0203324:	e7250513          	addi	a0,a0,-398 # ffffffffc0203192 <init_main>
    nr_process++;
ffffffffc0203328:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc020332a:	0000a797          	auipc	a5,0xa
ffffffffc020332e:	18d7bb23          	sd	a3,406(a5) # ffffffffc020d4c0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203332:	ed5ff0ef          	jal	ra,ffffffffc0203206 <kernel_thread>
ffffffffc0203336:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203338:	0ea05963          	blez	a0,ffffffffc020342a <proc_init+0x1fa>
    if (0 < pid && pid < MAX_PID)
ffffffffc020333c:	6789                	lui	a5,0x2
ffffffffc020333e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203342:	17f9                	addi	a5,a5,-2
ffffffffc0203344:	2501                	sext.w	a0,a0
ffffffffc0203346:	02e7e363          	bltu	a5,a4,ffffffffc020336c <proc_init+0x13c>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020334a:	45a9                	li	a1,10
ffffffffc020334c:	6c4000ef          	jal	ra,ffffffffc0203a10 <hash32>
ffffffffc0203350:	02051793          	slli	a5,a0,0x20
ffffffffc0203354:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0203358:	96a6                	add	a3,a3,s1
ffffffffc020335a:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020335c:	a029                	j	ffffffffc0203366 <proc_init+0x136>
            if (proc->pid == pid)
ffffffffc020335e:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0203362:	0a870563          	beq	a4,s0,ffffffffc020340c <proc_init+0x1dc>
    return listelm->next;
ffffffffc0203366:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203368:	fef69be3          	bne	a3,a5,ffffffffc020335e <proc_init+0x12e>
    return NULL;
ffffffffc020336c:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020336e:	0b478493          	addi	s1,a5,180
ffffffffc0203372:	4641                	li	a2,16
ffffffffc0203374:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203376:	0000a417          	auipc	s0,0xa
ffffffffc020337a:	15a40413          	addi	s0,s0,346 # ffffffffc020d4d0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020337e:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0203380:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203382:	252000ef          	jal	ra,ffffffffc02035d4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203386:	463d                	li	a2,15
ffffffffc0203388:	00002597          	auipc	a1,0x2
ffffffffc020338c:	ed058593          	addi	a1,a1,-304 # ffffffffc0205258 <default_pmm_manager+0x128>
ffffffffc0203390:	8526                	mv	a0,s1
ffffffffc0203392:	254000ef          	jal	ra,ffffffffc02035e6 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203396:	00093783          	ld	a5,0(s2)
ffffffffc020339a:	c7e1                	beqz	a5,ffffffffc0203462 <proc_init+0x232>
ffffffffc020339c:	43dc                	lw	a5,4(a5)
ffffffffc020339e:	e3f1                	bnez	a5,ffffffffc0203462 <proc_init+0x232>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02033a0:	601c                	ld	a5,0(s0)
ffffffffc02033a2:	c3c5                	beqz	a5,ffffffffc0203442 <proc_init+0x212>
ffffffffc02033a4:	43d8                	lw	a4,4(a5)
ffffffffc02033a6:	4785                	li	a5,1
ffffffffc02033a8:	08f71d63          	bne	a4,a5,ffffffffc0203442 <proc_init+0x212>
}
ffffffffc02033ac:	70a2                	ld	ra,40(sp)
ffffffffc02033ae:	7402                	ld	s0,32(sp)
ffffffffc02033b0:	64e2                	ld	s1,24(sp)
ffffffffc02033b2:	6942                	ld	s2,16(sp)
ffffffffc02033b4:	69a2                	ld	s3,8(sp)
ffffffffc02033b6:	6145                	addi	sp,sp,48
ffffffffc02033b8:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02033ba:	73d8                	ld	a4,160(a5)
ffffffffc02033bc:	ff09                	bnez	a4,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033be:	f0099ce3          	bnez	s3,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033c2:	6394                	ld	a3,0(a5)
ffffffffc02033c4:	577d                	li	a4,-1
ffffffffc02033c6:	1702                	slli	a4,a4,0x20
ffffffffc02033c8:	f0e697e3          	bne	a3,a4,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033cc:	4798                	lw	a4,8(a5)
ffffffffc02033ce:	f00714e3          	bnez	a4,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033d2:	6b98                	ld	a4,16(a5)
ffffffffc02033d4:	f00711e3          	bnez	a4,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033d8:	4f98                	lw	a4,24(a5)
ffffffffc02033da:	2701                	sext.w	a4,a4
ffffffffc02033dc:	ee071de3          	bnez	a4,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033e0:	7398                	ld	a4,32(a5)
ffffffffc02033e2:	ee071ae3          	bnez	a4,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033e6:	7798                	ld	a4,40(a5)
ffffffffc02033e8:	ee0717e3          	bnez	a4,ffffffffc02032d6 <proc_init+0xa6>
ffffffffc02033ec:	0b07a703          	lw	a4,176(a5)
ffffffffc02033f0:	8d59                	or	a0,a0,a4
ffffffffc02033f2:	0005071b          	sext.w	a4,a0
ffffffffc02033f6:	ee0710e3          	bnez	a4,ffffffffc02032d6 <proc_init+0xa6>
        cprintf("alloc_proc() correct!\n");
ffffffffc02033fa:	00002517          	auipc	a0,0x2
ffffffffc02033fe:	e0e50513          	addi	a0,a0,-498 # ffffffffc0205208 <default_pmm_manager+0xd8>
ffffffffc0203402:	cdffc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    idleproc->pid = 0;
ffffffffc0203406:	00093783          	ld	a5,0(s2)
ffffffffc020340a:	b5f1                	j	ffffffffc02032d6 <proc_init+0xa6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020340c:	f2878793          	addi	a5,a5,-216
ffffffffc0203410:	bfb9                	j	ffffffffc020336e <proc_init+0x13e>
        panic("cannot alloc idleproc.\n");
ffffffffc0203412:	00002617          	auipc	a2,0x2
ffffffffc0203416:	dde60613          	addi	a2,a2,-546 # ffffffffc02051f0 <default_pmm_manager+0xc0>
ffffffffc020341a:	17100593          	li	a1,369
ffffffffc020341e:	00002517          	auipc	a0,0x2
ffffffffc0203422:	dba50513          	addi	a0,a0,-582 # ffffffffc02051d8 <default_pmm_manager+0xa8>
ffffffffc0203426:	db9fc0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("create init_main failed.\n");
ffffffffc020342a:	00002617          	auipc	a2,0x2
ffffffffc020342e:	e0e60613          	addi	a2,a2,-498 # ffffffffc0205238 <default_pmm_manager+0x108>
ffffffffc0203432:	18e00593          	li	a1,398
ffffffffc0203436:	00002517          	auipc	a0,0x2
ffffffffc020343a:	da250513          	addi	a0,a0,-606 # ffffffffc02051d8 <default_pmm_manager+0xa8>
ffffffffc020343e:	da1fc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203442:	00002697          	auipc	a3,0x2
ffffffffc0203446:	e4668693          	addi	a3,a3,-442 # ffffffffc0205288 <default_pmm_manager+0x158>
ffffffffc020344a:	00001617          	auipc	a2,0x1
ffffffffc020344e:	1c660613          	addi	a2,a2,454 # ffffffffc0204610 <commands+0x960>
ffffffffc0203452:	19500593          	li	a1,405
ffffffffc0203456:	00002517          	auipc	a0,0x2
ffffffffc020345a:	d8250513          	addi	a0,a0,-638 # ffffffffc02051d8 <default_pmm_manager+0xa8>
ffffffffc020345e:	d81fc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203462:	00002697          	auipc	a3,0x2
ffffffffc0203466:	dfe68693          	addi	a3,a3,-514 # ffffffffc0205260 <default_pmm_manager+0x130>
ffffffffc020346a:	00001617          	auipc	a2,0x1
ffffffffc020346e:	1a660613          	addi	a2,a2,422 # ffffffffc0204610 <commands+0x960>
ffffffffc0203472:	19400593          	li	a1,404
ffffffffc0203476:	00002517          	auipc	a0,0x2
ffffffffc020347a:	d6250513          	addi	a0,a0,-670 # ffffffffc02051d8 <default_pmm_manager+0xa8>
ffffffffc020347e:	d61fc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203482 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203482:	1141                	addi	sp,sp,-16
ffffffffc0203484:	e022                	sd	s0,0(sp)
ffffffffc0203486:	e406                	sd	ra,8(sp)
ffffffffc0203488:	0000a417          	auipc	s0,0xa
ffffffffc020348c:	03840413          	addi	s0,s0,56 # ffffffffc020d4c0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0203490:	6018                	ld	a4,0(s0)
ffffffffc0203492:	4f1c                	lw	a5,24(a4)
ffffffffc0203494:	2781                	sext.w	a5,a5
ffffffffc0203496:	dff5                	beqz	a5,ffffffffc0203492 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0203498:	006000ef          	jal	ra,ffffffffc020349e <schedule>
ffffffffc020349c:	bfd5                	j	ffffffffc0203490 <cpu_idle+0xe>

ffffffffc020349e <schedule>:
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

void
schedule(void) {
ffffffffc020349e:	1141                	addi	sp,sp,-16
ffffffffc02034a0:	e406                	sd	ra,8(sp)
ffffffffc02034a2:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02034a4:	100027f3          	csrr	a5,sstatus
ffffffffc02034a8:	8b89                	andi	a5,a5,2
ffffffffc02034aa:	4401                	li	s0,0
ffffffffc02034ac:	efbd                	bnez	a5,ffffffffc020352a <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02034ae:	0000a897          	auipc	a7,0xa
ffffffffc02034b2:	0128b883          	ld	a7,18(a7) # ffffffffc020d4c0 <current>
ffffffffc02034b6:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02034ba:	0000a517          	auipc	a0,0xa
ffffffffc02034be:	00e53503          	ld	a0,14(a0) # ffffffffc020d4c8 <idleproc>
ffffffffc02034c2:	04a88e63          	beq	a7,a0,ffffffffc020351e <schedule+0x80>
ffffffffc02034c6:	0c888693          	addi	a3,a7,200
ffffffffc02034ca:	0000a617          	auipc	a2,0xa
ffffffffc02034ce:	f8660613          	addi	a2,a2,-122 # ffffffffc020d450 <proc_list>
        le = last;
ffffffffc02034d2:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02034d4:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02034d6:	4809                	li	a6,2
ffffffffc02034d8:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02034da:	00c78863          	beq	a5,a2,ffffffffc02034ea <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02034de:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02034e2:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc02034e6:	03070163          	beq	a4,a6,ffffffffc0203508 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc02034ea:	fef697e3          	bne	a3,a5,ffffffffc02034d8 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02034ee:	ed89                	bnez	a1,ffffffffc0203508 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc02034f0:	451c                	lw	a5,8(a0)
ffffffffc02034f2:	2785                	addiw	a5,a5,1
ffffffffc02034f4:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02034f6:	00a88463          	beq	a7,a0,ffffffffc02034fe <schedule+0x60>
            proc_run(next);
ffffffffc02034fa:	d0bff0ef          	jal	ra,ffffffffc0203204 <proc_run>
    if (flag) {
ffffffffc02034fe:	e819                	bnez	s0,ffffffffc0203514 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0203500:	60a2                	ld	ra,8(sp)
ffffffffc0203502:	6402                	ld	s0,0(sp)
ffffffffc0203504:	0141                	addi	sp,sp,16
ffffffffc0203506:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203508:	4198                	lw	a4,0(a1)
ffffffffc020350a:	4789                	li	a5,2
ffffffffc020350c:	fef712e3          	bne	a4,a5,ffffffffc02034f0 <schedule+0x52>
ffffffffc0203510:	852e                	mv	a0,a1
ffffffffc0203512:	bff9                	j	ffffffffc02034f0 <schedule+0x52>
}
ffffffffc0203514:	6402                	ld	s0,0(sp)
ffffffffc0203516:	60a2                	ld	ra,8(sp)
ffffffffc0203518:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020351a:	bfcfd06f          	j	ffffffffc0200916 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020351e:	0000a617          	auipc	a2,0xa
ffffffffc0203522:	f3260613          	addi	a2,a2,-206 # ffffffffc020d450 <proc_list>
ffffffffc0203526:	86b2                	mv	a3,a2
ffffffffc0203528:	b76d                	j	ffffffffc02034d2 <schedule+0x34>
        intr_disable();
ffffffffc020352a:	bf2fd0ef          	jal	ra,ffffffffc020091c <intr_disable>
        return 1;
ffffffffc020352e:	4405                	li	s0,1
ffffffffc0203530:	bfbd                	j	ffffffffc02034ae <schedule+0x10>

ffffffffc0203532 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203532:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203536:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203538:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020353a:	cb81                	beqz	a5,ffffffffc020354a <strlen+0x18>
        cnt ++;
ffffffffc020353c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020353e:	00a707b3          	add	a5,a4,a0
ffffffffc0203542:	0007c783          	lbu	a5,0(a5)
ffffffffc0203546:	fbfd                	bnez	a5,ffffffffc020353c <strlen+0xa>
ffffffffc0203548:	8082                	ret
    }
    return cnt;
}
ffffffffc020354a:	8082                	ret

ffffffffc020354c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020354c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020354e:	e589                	bnez	a1,ffffffffc0203558 <strnlen+0xc>
ffffffffc0203550:	a811                	j	ffffffffc0203564 <strnlen+0x18>
        cnt ++;
ffffffffc0203552:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203554:	00f58863          	beq	a1,a5,ffffffffc0203564 <strnlen+0x18>
ffffffffc0203558:	00f50733          	add	a4,a0,a5
ffffffffc020355c:	00074703          	lbu	a4,0(a4)
ffffffffc0203560:	fb6d                	bnez	a4,ffffffffc0203552 <strnlen+0x6>
ffffffffc0203562:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203564:	852e                	mv	a0,a1
ffffffffc0203566:	8082                	ret

ffffffffc0203568 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203568:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020356a:	0005c703          	lbu	a4,0(a1)
ffffffffc020356e:	0785                	addi	a5,a5,1
ffffffffc0203570:	0585                	addi	a1,a1,1
ffffffffc0203572:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203576:	fb75                	bnez	a4,ffffffffc020356a <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203578:	8082                	ret

ffffffffc020357a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020357a:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020357e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203582:	cb89                	beqz	a5,ffffffffc0203594 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203584:	0505                	addi	a0,a0,1
ffffffffc0203586:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203588:	fee789e3          	beq	a5,a4,ffffffffc020357a <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020358c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203590:	9d19                	subw	a0,a0,a4
ffffffffc0203592:	8082                	ret
ffffffffc0203594:	4501                	li	a0,0
ffffffffc0203596:	bfed                	j	ffffffffc0203590 <strcmp+0x16>

ffffffffc0203598 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203598:	c20d                	beqz	a2,ffffffffc02035ba <strncmp+0x22>
ffffffffc020359a:	962e                	add	a2,a2,a1
ffffffffc020359c:	a031                	j	ffffffffc02035a8 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020359e:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02035a0:	00e79a63          	bne	a5,a4,ffffffffc02035b4 <strncmp+0x1c>
ffffffffc02035a4:	00b60b63          	beq	a2,a1,ffffffffc02035ba <strncmp+0x22>
ffffffffc02035a8:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02035ac:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02035ae:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02035b2:	f7f5                	bnez	a5,ffffffffc020359e <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02035b4:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02035b8:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02035ba:	4501                	li	a0,0
ffffffffc02035bc:	8082                	ret

ffffffffc02035be <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02035be:	00054783          	lbu	a5,0(a0)
ffffffffc02035c2:	c799                	beqz	a5,ffffffffc02035d0 <strchr+0x12>
        if (*s == c) {
ffffffffc02035c4:	00f58763          	beq	a1,a5,ffffffffc02035d2 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02035c8:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02035cc:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02035ce:	fbfd                	bnez	a5,ffffffffc02035c4 <strchr+0x6>
    }
    return NULL;
ffffffffc02035d0:	4501                	li	a0,0
}
ffffffffc02035d2:	8082                	ret

ffffffffc02035d4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02035d4:	ca01                	beqz	a2,ffffffffc02035e4 <memset+0x10>
ffffffffc02035d6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02035d8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02035da:	0785                	addi	a5,a5,1
ffffffffc02035dc:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02035e0:	fec79de3          	bne	a5,a2,ffffffffc02035da <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02035e4:	8082                	ret

ffffffffc02035e6 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02035e6:	ca19                	beqz	a2,ffffffffc02035fc <memcpy+0x16>
ffffffffc02035e8:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02035ea:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02035ec:	0005c703          	lbu	a4,0(a1)
ffffffffc02035f0:	0585                	addi	a1,a1,1
ffffffffc02035f2:	0785                	addi	a5,a5,1
ffffffffc02035f4:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02035f8:	fec59ae3          	bne	a1,a2,ffffffffc02035ec <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02035fc:	8082                	ret

ffffffffc02035fe <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc02035fe:	c205                	beqz	a2,ffffffffc020361e <memcmp+0x20>
ffffffffc0203600:	962e                	add	a2,a2,a1
ffffffffc0203602:	a019                	j	ffffffffc0203608 <memcmp+0xa>
ffffffffc0203604:	00c58d63          	beq	a1,a2,ffffffffc020361e <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203608:	00054783          	lbu	a5,0(a0)
ffffffffc020360c:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203610:	0505                	addi	a0,a0,1
ffffffffc0203612:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203614:	fee788e3          	beq	a5,a4,ffffffffc0203604 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203618:	40e7853b          	subw	a0,a5,a4
ffffffffc020361c:	8082                	ret
    }
    return 0;
ffffffffc020361e:	4501                	li	a0,0
}
ffffffffc0203620:	8082                	ret

ffffffffc0203622 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203622:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203626:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203628:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020362c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020362e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203632:	f022                	sd	s0,32(sp)
ffffffffc0203634:	ec26                	sd	s1,24(sp)
ffffffffc0203636:	e84a                	sd	s2,16(sp)
ffffffffc0203638:	f406                	sd	ra,40(sp)
ffffffffc020363a:	e44e                	sd	s3,8(sp)
ffffffffc020363c:	84aa                	mv	s1,a0
ffffffffc020363e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203640:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203644:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203646:	03067e63          	bgeu	a2,a6,ffffffffc0203682 <printnum+0x60>
ffffffffc020364a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020364c:	00805763          	blez	s0,ffffffffc020365a <printnum+0x38>
ffffffffc0203650:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203652:	85ca                	mv	a1,s2
ffffffffc0203654:	854e                	mv	a0,s3
ffffffffc0203656:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203658:	fc65                	bnez	s0,ffffffffc0203650 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020365a:	1a02                	slli	s4,s4,0x20
ffffffffc020365c:	00002797          	auipc	a5,0x2
ffffffffc0203660:	c5478793          	addi	a5,a5,-940 # ffffffffc02052b0 <default_pmm_manager+0x180>
ffffffffc0203664:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203668:	9a3e                	add	s4,s4,a5
}
ffffffffc020366a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020366c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203670:	70a2                	ld	ra,40(sp)
ffffffffc0203672:	69a2                	ld	s3,8(sp)
ffffffffc0203674:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203676:	85ca                	mv	a1,s2
ffffffffc0203678:	87a6                	mv	a5,s1
}
ffffffffc020367a:	6942                	ld	s2,16(sp)
ffffffffc020367c:	64e2                	ld	s1,24(sp)
ffffffffc020367e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203680:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203682:	03065633          	divu	a2,a2,a6
ffffffffc0203686:	8722                	mv	a4,s0
ffffffffc0203688:	f9bff0ef          	jal	ra,ffffffffc0203622 <printnum>
ffffffffc020368c:	b7f9                	j	ffffffffc020365a <printnum+0x38>

ffffffffc020368e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020368e:	7119                	addi	sp,sp,-128
ffffffffc0203690:	f4a6                	sd	s1,104(sp)
ffffffffc0203692:	f0ca                	sd	s2,96(sp)
ffffffffc0203694:	ecce                	sd	s3,88(sp)
ffffffffc0203696:	e8d2                	sd	s4,80(sp)
ffffffffc0203698:	e4d6                	sd	s5,72(sp)
ffffffffc020369a:	e0da                	sd	s6,64(sp)
ffffffffc020369c:	fc5e                	sd	s7,56(sp)
ffffffffc020369e:	f06a                	sd	s10,32(sp)
ffffffffc02036a0:	fc86                	sd	ra,120(sp)
ffffffffc02036a2:	f8a2                	sd	s0,112(sp)
ffffffffc02036a4:	f862                	sd	s8,48(sp)
ffffffffc02036a6:	f466                	sd	s9,40(sp)
ffffffffc02036a8:	ec6e                	sd	s11,24(sp)
ffffffffc02036aa:	892a                	mv	s2,a0
ffffffffc02036ac:	84ae                	mv	s1,a1
ffffffffc02036ae:	8d32                	mv	s10,a2
ffffffffc02036b0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02036b2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02036b6:	5b7d                	li	s6,-1
ffffffffc02036b8:	00002a97          	auipc	s5,0x2
ffffffffc02036bc:	c24a8a93          	addi	s5,s5,-988 # ffffffffc02052dc <default_pmm_manager+0x1ac>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02036c0:	00002b97          	auipc	s7,0x2
ffffffffc02036c4:	df8b8b93          	addi	s7,s7,-520 # ffffffffc02054b8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02036c8:	000d4503          	lbu	a0,0(s10)
ffffffffc02036cc:	001d0413          	addi	s0,s10,1
ffffffffc02036d0:	01350a63          	beq	a0,s3,ffffffffc02036e4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02036d4:	c121                	beqz	a0,ffffffffc0203714 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02036d6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02036d8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02036da:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02036dc:	fff44503          	lbu	a0,-1(s0)
ffffffffc02036e0:	ff351ae3          	bne	a0,s3,ffffffffc02036d4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02036e4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02036e8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02036ec:	4c81                	li	s9,0
ffffffffc02036ee:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02036f0:	5c7d                	li	s8,-1
ffffffffc02036f2:	5dfd                	li	s11,-1
ffffffffc02036f4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02036f8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02036fa:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02036fe:	0ff5f593          	zext.b	a1,a1
ffffffffc0203702:	00140d13          	addi	s10,s0,1
ffffffffc0203706:	04b56263          	bltu	a0,a1,ffffffffc020374a <vprintfmt+0xbc>
ffffffffc020370a:	058a                	slli	a1,a1,0x2
ffffffffc020370c:	95d6                	add	a1,a1,s5
ffffffffc020370e:	4194                	lw	a3,0(a1)
ffffffffc0203710:	96d6                	add	a3,a3,s5
ffffffffc0203712:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203714:	70e6                	ld	ra,120(sp)
ffffffffc0203716:	7446                	ld	s0,112(sp)
ffffffffc0203718:	74a6                	ld	s1,104(sp)
ffffffffc020371a:	7906                	ld	s2,96(sp)
ffffffffc020371c:	69e6                	ld	s3,88(sp)
ffffffffc020371e:	6a46                	ld	s4,80(sp)
ffffffffc0203720:	6aa6                	ld	s5,72(sp)
ffffffffc0203722:	6b06                	ld	s6,64(sp)
ffffffffc0203724:	7be2                	ld	s7,56(sp)
ffffffffc0203726:	7c42                	ld	s8,48(sp)
ffffffffc0203728:	7ca2                	ld	s9,40(sp)
ffffffffc020372a:	7d02                	ld	s10,32(sp)
ffffffffc020372c:	6de2                	ld	s11,24(sp)
ffffffffc020372e:	6109                	addi	sp,sp,128
ffffffffc0203730:	8082                	ret
            padc = '0';
ffffffffc0203732:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203734:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203738:	846a                	mv	s0,s10
ffffffffc020373a:	00140d13          	addi	s10,s0,1
ffffffffc020373e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203742:	0ff5f593          	zext.b	a1,a1
ffffffffc0203746:	fcb572e3          	bgeu	a0,a1,ffffffffc020370a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020374a:	85a6                	mv	a1,s1
ffffffffc020374c:	02500513          	li	a0,37
ffffffffc0203750:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203752:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203756:	8d22                	mv	s10,s0
ffffffffc0203758:	f73788e3          	beq	a5,s3,ffffffffc02036c8 <vprintfmt+0x3a>
ffffffffc020375c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203760:	1d7d                	addi	s10,s10,-1
ffffffffc0203762:	ff379de3          	bne	a5,s3,ffffffffc020375c <vprintfmt+0xce>
ffffffffc0203766:	b78d                	j	ffffffffc02036c8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203768:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020376c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203770:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203772:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203776:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020377a:	02d86463          	bltu	a6,a3,ffffffffc02037a2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020377e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203782:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203786:	0186873b          	addw	a4,a3,s8
ffffffffc020378a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020378e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203790:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203794:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203796:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020379a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020379e:	fed870e3          	bgeu	a6,a3,ffffffffc020377e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02037a2:	f40ddce3          	bgez	s11,ffffffffc02036fa <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02037a6:	8de2                	mv	s11,s8
ffffffffc02037a8:	5c7d                	li	s8,-1
ffffffffc02037aa:	bf81                	j	ffffffffc02036fa <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02037ac:	fffdc693          	not	a3,s11
ffffffffc02037b0:	96fd                	srai	a3,a3,0x3f
ffffffffc02037b2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02037b6:	00144603          	lbu	a2,1(s0)
ffffffffc02037ba:	2d81                	sext.w	s11,s11
ffffffffc02037bc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02037be:	bf35                	j	ffffffffc02036fa <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02037c0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02037c4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02037c8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02037ca:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02037cc:	bfd9                	j	ffffffffc02037a2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02037ce:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02037d0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02037d4:	01174463          	blt	a4,a7,ffffffffc02037dc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02037d8:	1a088e63          	beqz	a7,ffffffffc0203994 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02037dc:	000a3603          	ld	a2,0(s4)
ffffffffc02037e0:	46c1                	li	a3,16
ffffffffc02037e2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02037e4:	2781                	sext.w	a5,a5
ffffffffc02037e6:	876e                	mv	a4,s11
ffffffffc02037e8:	85a6                	mv	a1,s1
ffffffffc02037ea:	854a                	mv	a0,s2
ffffffffc02037ec:	e37ff0ef          	jal	ra,ffffffffc0203622 <printnum>
            break;
ffffffffc02037f0:	bde1                	j	ffffffffc02036c8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02037f2:	000a2503          	lw	a0,0(s4)
ffffffffc02037f6:	85a6                	mv	a1,s1
ffffffffc02037f8:	0a21                	addi	s4,s4,8
ffffffffc02037fa:	9902                	jalr	s2
            break;
ffffffffc02037fc:	b5f1                	j	ffffffffc02036c8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02037fe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203800:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203804:	01174463          	blt	a4,a7,ffffffffc020380c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203808:	18088163          	beqz	a7,ffffffffc020398a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020380c:	000a3603          	ld	a2,0(s4)
ffffffffc0203810:	46a9                	li	a3,10
ffffffffc0203812:	8a2e                	mv	s4,a1
ffffffffc0203814:	bfc1                	j	ffffffffc02037e4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203816:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020381a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020381c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020381e:	bdf1                	j	ffffffffc02036fa <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203820:	85a6                	mv	a1,s1
ffffffffc0203822:	02500513          	li	a0,37
ffffffffc0203826:	9902                	jalr	s2
            break;
ffffffffc0203828:	b545                	j	ffffffffc02036c8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020382a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020382e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203830:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203832:	b5e1                	j	ffffffffc02036fa <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203834:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203836:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020383a:	01174463          	blt	a4,a7,ffffffffc0203842 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020383e:	14088163          	beqz	a7,ffffffffc0203980 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203842:	000a3603          	ld	a2,0(s4)
ffffffffc0203846:	46a1                	li	a3,8
ffffffffc0203848:	8a2e                	mv	s4,a1
ffffffffc020384a:	bf69                	j	ffffffffc02037e4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020384c:	03000513          	li	a0,48
ffffffffc0203850:	85a6                	mv	a1,s1
ffffffffc0203852:	e03e                	sd	a5,0(sp)
ffffffffc0203854:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203856:	85a6                	mv	a1,s1
ffffffffc0203858:	07800513          	li	a0,120
ffffffffc020385c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020385e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203860:	6782                	ld	a5,0(sp)
ffffffffc0203862:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203864:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203868:	bfb5                	j	ffffffffc02037e4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020386a:	000a3403          	ld	s0,0(s4)
ffffffffc020386e:	008a0713          	addi	a4,s4,8
ffffffffc0203872:	e03a                	sd	a4,0(sp)
ffffffffc0203874:	14040263          	beqz	s0,ffffffffc02039b8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203878:	0fb05763          	blez	s11,ffffffffc0203966 <vprintfmt+0x2d8>
ffffffffc020387c:	02d00693          	li	a3,45
ffffffffc0203880:	0cd79163          	bne	a5,a3,ffffffffc0203942 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203884:	00044783          	lbu	a5,0(s0)
ffffffffc0203888:	0007851b          	sext.w	a0,a5
ffffffffc020388c:	cf85                	beqz	a5,ffffffffc02038c4 <vprintfmt+0x236>
ffffffffc020388e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203892:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203896:	000c4563          	bltz	s8,ffffffffc02038a0 <vprintfmt+0x212>
ffffffffc020389a:	3c7d                	addiw	s8,s8,-1
ffffffffc020389c:	036c0263          	beq	s8,s6,ffffffffc02038c0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02038a0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02038a2:	0e0c8e63          	beqz	s9,ffffffffc020399e <vprintfmt+0x310>
ffffffffc02038a6:	3781                	addiw	a5,a5,-32
ffffffffc02038a8:	0ef47b63          	bgeu	s0,a5,ffffffffc020399e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02038ac:	03f00513          	li	a0,63
ffffffffc02038b0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02038b2:	000a4783          	lbu	a5,0(s4)
ffffffffc02038b6:	3dfd                	addiw	s11,s11,-1
ffffffffc02038b8:	0a05                	addi	s4,s4,1
ffffffffc02038ba:	0007851b          	sext.w	a0,a5
ffffffffc02038be:	ffe1                	bnez	a5,ffffffffc0203896 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02038c0:	01b05963          	blez	s11,ffffffffc02038d2 <vprintfmt+0x244>
ffffffffc02038c4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02038c6:	85a6                	mv	a1,s1
ffffffffc02038c8:	02000513          	li	a0,32
ffffffffc02038cc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02038ce:	fe0d9be3          	bnez	s11,ffffffffc02038c4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02038d2:	6a02                	ld	s4,0(sp)
ffffffffc02038d4:	bbd5                	j	ffffffffc02036c8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02038d6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02038d8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02038dc:	01174463          	blt	a4,a7,ffffffffc02038e4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02038e0:	08088d63          	beqz	a7,ffffffffc020397a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02038e4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02038e8:	0a044d63          	bltz	s0,ffffffffc02039a2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02038ec:	8622                	mv	a2,s0
ffffffffc02038ee:	8a66                	mv	s4,s9
ffffffffc02038f0:	46a9                	li	a3,10
ffffffffc02038f2:	bdcd                	j	ffffffffc02037e4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02038f4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02038f8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02038fa:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02038fc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203900:	8fb5                	xor	a5,a5,a3
ffffffffc0203902:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203906:	02d74163          	blt	a4,a3,ffffffffc0203928 <vprintfmt+0x29a>
ffffffffc020390a:	00369793          	slli	a5,a3,0x3
ffffffffc020390e:	97de                	add	a5,a5,s7
ffffffffc0203910:	639c                	ld	a5,0(a5)
ffffffffc0203912:	cb99                	beqz	a5,ffffffffc0203928 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203914:	86be                	mv	a3,a5
ffffffffc0203916:	00000617          	auipc	a2,0x0
ffffffffc020391a:	13a60613          	addi	a2,a2,314 # ffffffffc0203a50 <etext+0x2a>
ffffffffc020391e:	85a6                	mv	a1,s1
ffffffffc0203920:	854a                	mv	a0,s2
ffffffffc0203922:	0ce000ef          	jal	ra,ffffffffc02039f0 <printfmt>
ffffffffc0203926:	b34d                	j	ffffffffc02036c8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203928:	00002617          	auipc	a2,0x2
ffffffffc020392c:	9a860613          	addi	a2,a2,-1624 # ffffffffc02052d0 <default_pmm_manager+0x1a0>
ffffffffc0203930:	85a6                	mv	a1,s1
ffffffffc0203932:	854a                	mv	a0,s2
ffffffffc0203934:	0bc000ef          	jal	ra,ffffffffc02039f0 <printfmt>
ffffffffc0203938:	bb41                	j	ffffffffc02036c8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020393a:	00002417          	auipc	s0,0x2
ffffffffc020393e:	98e40413          	addi	s0,s0,-1650 # ffffffffc02052c8 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203942:	85e2                	mv	a1,s8
ffffffffc0203944:	8522                	mv	a0,s0
ffffffffc0203946:	e43e                	sd	a5,8(sp)
ffffffffc0203948:	c05ff0ef          	jal	ra,ffffffffc020354c <strnlen>
ffffffffc020394c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203950:	01b05b63          	blez	s11,ffffffffc0203966 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203954:	67a2                	ld	a5,8(sp)
ffffffffc0203956:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020395a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020395c:	85a6                	mv	a1,s1
ffffffffc020395e:	8552                	mv	a0,s4
ffffffffc0203960:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203962:	fe0d9ce3          	bnez	s11,ffffffffc020395a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203966:	00044783          	lbu	a5,0(s0)
ffffffffc020396a:	00140a13          	addi	s4,s0,1
ffffffffc020396e:	0007851b          	sext.w	a0,a5
ffffffffc0203972:	d3a5                	beqz	a5,ffffffffc02038d2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203974:	05e00413          	li	s0,94
ffffffffc0203978:	bf39                	j	ffffffffc0203896 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020397a:	000a2403          	lw	s0,0(s4)
ffffffffc020397e:	b7ad                	j	ffffffffc02038e8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203980:	000a6603          	lwu	a2,0(s4)
ffffffffc0203984:	46a1                	li	a3,8
ffffffffc0203986:	8a2e                	mv	s4,a1
ffffffffc0203988:	bdb1                	j	ffffffffc02037e4 <vprintfmt+0x156>
ffffffffc020398a:	000a6603          	lwu	a2,0(s4)
ffffffffc020398e:	46a9                	li	a3,10
ffffffffc0203990:	8a2e                	mv	s4,a1
ffffffffc0203992:	bd89                	j	ffffffffc02037e4 <vprintfmt+0x156>
ffffffffc0203994:	000a6603          	lwu	a2,0(s4)
ffffffffc0203998:	46c1                	li	a3,16
ffffffffc020399a:	8a2e                	mv	s4,a1
ffffffffc020399c:	b5a1                	j	ffffffffc02037e4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020399e:	9902                	jalr	s2
ffffffffc02039a0:	bf09                	j	ffffffffc02038b2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02039a2:	85a6                	mv	a1,s1
ffffffffc02039a4:	02d00513          	li	a0,45
ffffffffc02039a8:	e03e                	sd	a5,0(sp)
ffffffffc02039aa:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02039ac:	6782                	ld	a5,0(sp)
ffffffffc02039ae:	8a66                	mv	s4,s9
ffffffffc02039b0:	40800633          	neg	a2,s0
ffffffffc02039b4:	46a9                	li	a3,10
ffffffffc02039b6:	b53d                	j	ffffffffc02037e4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02039b8:	03b05163          	blez	s11,ffffffffc02039da <vprintfmt+0x34c>
ffffffffc02039bc:	02d00693          	li	a3,45
ffffffffc02039c0:	f6d79de3          	bne	a5,a3,ffffffffc020393a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02039c4:	00002417          	auipc	s0,0x2
ffffffffc02039c8:	90440413          	addi	s0,s0,-1788 # ffffffffc02052c8 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02039cc:	02800793          	li	a5,40
ffffffffc02039d0:	02800513          	li	a0,40
ffffffffc02039d4:	00140a13          	addi	s4,s0,1
ffffffffc02039d8:	bd6d                	j	ffffffffc0203892 <vprintfmt+0x204>
ffffffffc02039da:	00002a17          	auipc	s4,0x2
ffffffffc02039de:	8efa0a13          	addi	s4,s4,-1809 # ffffffffc02052c9 <default_pmm_manager+0x199>
ffffffffc02039e2:	02800513          	li	a0,40
ffffffffc02039e6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02039ea:	05e00413          	li	s0,94
ffffffffc02039ee:	b565                	j	ffffffffc0203896 <vprintfmt+0x208>

ffffffffc02039f0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02039f0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02039f2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02039f6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02039f8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02039fa:	ec06                	sd	ra,24(sp)
ffffffffc02039fc:	f83a                	sd	a4,48(sp)
ffffffffc02039fe:	fc3e                	sd	a5,56(sp)
ffffffffc0203a00:	e0c2                	sd	a6,64(sp)
ffffffffc0203a02:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203a04:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203a06:	c89ff0ef          	jal	ra,ffffffffc020368e <vprintfmt>
}
ffffffffc0203a0a:	60e2                	ld	ra,24(sp)
ffffffffc0203a0c:	6161                	addi	sp,sp,80
ffffffffc0203a0e:	8082                	ret

ffffffffc0203a10 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203a10:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203a14:	2785                	addiw	a5,a5,1
ffffffffc0203a16:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203a1a:	02000793          	li	a5,32
ffffffffc0203a1e:	9f8d                	subw	a5,a5,a1
}
ffffffffc0203a20:	00f5553b          	srlw	a0,a0,a5
ffffffffc0203a24:	8082                	ret
