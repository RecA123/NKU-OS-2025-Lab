
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
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
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	241010ef          	jal	ra,ffffffffc0201aac <memset>
    dtb_init();
ffffffffc0200070:	3dc000ef          	jal	ra,ffffffffc020044c <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	7cc000ef          	jal	ra,ffffffffc0200840 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f9050513          	addi	a0,a0,-112 # ffffffffc0202008 <etext+0x3e>
ffffffffc0200080:	0ae000ef          	jal	ra,ffffffffc020012e <cputs>

    print_kerninfo();
ffffffffc0200084:	156000ef          	jal	ra,ffffffffc02001da <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7d2000ef          	jal	ra,ffffffffc020085a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	4d9000ef          	jal	ra,ffffffffc0200d64 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7ca000ef          	jal	ra,ffffffffc020085a <idt_init>

    cprintf("非法指令异常测试...\n");
ffffffffc0200094:	00002517          	auipc	a0,0x2
ffffffffc0200098:	f3c50513          	addi	a0,a0,-196 # ffffffffc0201fd0 <etext+0x6>
ffffffffc020009c:	05a000ef          	jal	ra,ffffffffc02000f6 <cprintf>
ffffffffc02000a0:	0000                	unimp
ffffffffc02000a2:	0000                	unimp
    __asm__ volatile(".word 0x00000000"); 

    cprintf("断点异常测试...\n");
ffffffffc02000a4:	00002517          	auipc	a0,0x2
ffffffffc02000a8:	f4c50513          	addi	a0,a0,-180 # ffffffffc0201ff0 <etext+0x26>
ffffffffc02000ac:	04a000ef          	jal	ra,ffffffffc02000f6 <cprintf>
    __asm__ volatile("ebreak"); 
ffffffffc02000b0:	9002                	ebreak

    clock_init();   // init clock interrupt
ffffffffc02000b2:	74a000ef          	jal	ra,ffffffffc02007fc <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc02000b6:	798000ef          	jal	ra,ffffffffc020084e <intr_enable>

    /* do nothing */
    while (1)
ffffffffc02000ba:	a001                	j	ffffffffc02000ba <kern_init+0x66>

ffffffffc02000bc <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000bc:	1141                	addi	sp,sp,-16
ffffffffc02000be:	e022                	sd	s0,0(sp)
ffffffffc02000c0:	e406                	sd	ra,8(sp)
ffffffffc02000c2:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000c4:	77e000ef          	jal	ra,ffffffffc0200842 <cons_putc>
    (*cnt) ++;
ffffffffc02000c8:	401c                	lw	a5,0(s0)
}
ffffffffc02000ca:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000cc:	2785                	addiw	a5,a5,1
ffffffffc02000ce:	c01c                	sw	a5,0(s0)
}
ffffffffc02000d0:	6402                	ld	s0,0(sp)
ffffffffc02000d2:	0141                	addi	sp,sp,16
ffffffffc02000d4:	8082                	ret

ffffffffc02000d6 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000d6:	1101                	addi	sp,sp,-32
ffffffffc02000d8:	862a                	mv	a2,a0
ffffffffc02000da:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	00000517          	auipc	a0,0x0
ffffffffc02000e0:	fe050513          	addi	a0,a0,-32 # ffffffffc02000bc <cputch>
ffffffffc02000e4:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000e6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000e8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ea:	241010ef          	jal	ra,ffffffffc0201b2a <vprintfmt>
    return cnt;
}
ffffffffc02000ee:	60e2                	ld	ra,24(sp)
ffffffffc02000f0:	4532                	lw	a0,12(sp)
ffffffffc02000f2:	6105                	addi	sp,sp,32
ffffffffc02000f4:	8082                	ret

ffffffffc02000f6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000f6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000f8:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000fc:	8e2a                	mv	t3,a0
ffffffffc02000fe:	f42e                	sd	a1,40(sp)
ffffffffc0200100:	f832                	sd	a2,48(sp)
ffffffffc0200102:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200104:	00000517          	auipc	a0,0x0
ffffffffc0200108:	fb850513          	addi	a0,a0,-72 # ffffffffc02000bc <cputch>
ffffffffc020010c:	004c                	addi	a1,sp,4
ffffffffc020010e:	869a                	mv	a3,t1
ffffffffc0200110:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e0ba                	sd	a4,64(sp)
ffffffffc0200116:	e4be                	sd	a5,72(sp)
ffffffffc0200118:	e8c2                	sd	a6,80(sp)
ffffffffc020011a:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020011c:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020011e:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200120:	20b010ef          	jal	ra,ffffffffc0201b2a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200124:	60e2                	ld	ra,24(sp)
ffffffffc0200126:	4512                	lw	a0,4(sp)
ffffffffc0200128:	6125                	addi	sp,sp,96
ffffffffc020012a:	8082                	ret

ffffffffc020012c <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020012c:	af19                	j	ffffffffc0200842 <cons_putc>

ffffffffc020012e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020012e:	1101                	addi	sp,sp,-32
ffffffffc0200130:	e822                	sd	s0,16(sp)
ffffffffc0200132:	ec06                	sd	ra,24(sp)
ffffffffc0200134:	e426                	sd	s1,8(sp)
ffffffffc0200136:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200138:	00054503          	lbu	a0,0(a0)
ffffffffc020013c:	c51d                	beqz	a0,ffffffffc020016a <cputs+0x3c>
ffffffffc020013e:	0405                	addi	s0,s0,1
ffffffffc0200140:	4485                	li	s1,1
ffffffffc0200142:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200144:	6fe000ef          	jal	ra,ffffffffc0200842 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200148:	00044503          	lbu	a0,0(s0)
ffffffffc020014c:	008487bb          	addw	a5,s1,s0
ffffffffc0200150:	0405                	addi	s0,s0,1
ffffffffc0200152:	f96d                	bnez	a0,ffffffffc0200144 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200154:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200158:	4529                	li	a0,10
ffffffffc020015a:	6e8000ef          	jal	ra,ffffffffc0200842 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020015e:	60e2                	ld	ra,24(sp)
ffffffffc0200160:	8522                	mv	a0,s0
ffffffffc0200162:	6442                	ld	s0,16(sp)
ffffffffc0200164:	64a2                	ld	s1,8(sp)
ffffffffc0200166:	6105                	addi	sp,sp,32
ffffffffc0200168:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020016a:	4405                	li	s0,1
ffffffffc020016c:	b7f5                	j	ffffffffc0200158 <cputs+0x2a>

ffffffffc020016e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020016e:	1141                	addi	sp,sp,-16
ffffffffc0200170:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200172:	6d8000ef          	jal	ra,ffffffffc020084a <cons_getc>
ffffffffc0200176:	dd75                	beqz	a0,ffffffffc0200172 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200178:	60a2                	ld	ra,8(sp)
ffffffffc020017a:	0141                	addi	sp,sp,16
ffffffffc020017c:	8082                	ret

ffffffffc020017e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020017e:	00007317          	auipc	t1,0x7
ffffffffc0200182:	2c230313          	addi	t1,t1,706 # ffffffffc0207440 <is_panic>
ffffffffc0200186:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020018a:	715d                	addi	sp,sp,-80
ffffffffc020018c:	ec06                	sd	ra,24(sp)
ffffffffc020018e:	e822                	sd	s0,16(sp)
ffffffffc0200190:	f436                	sd	a3,40(sp)
ffffffffc0200192:	f83a                	sd	a4,48(sp)
ffffffffc0200194:	fc3e                	sd	a5,56(sp)
ffffffffc0200196:	e0c2                	sd	a6,64(sp)
ffffffffc0200198:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020019a:	020e1a63          	bnez	t3,ffffffffc02001ce <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020019e:	4785                	li	a5,1
ffffffffc02001a0:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02001a4:	8432                	mv	s0,a2
ffffffffc02001a6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001a8:	862e                	mv	a2,a1
ffffffffc02001aa:	85aa                	mv	a1,a0
ffffffffc02001ac:	00002517          	auipc	a0,0x2
ffffffffc02001b0:	e7c50513          	addi	a0,a0,-388 # ffffffffc0202028 <etext+0x5e>
    va_start(ap, fmt);
ffffffffc02001b4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001b6:	f41ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02001ba:	65a2                	ld	a1,8(sp)
ffffffffc02001bc:	8522                	mv	a0,s0
ffffffffc02001be:	f19ff0ef          	jal	ra,ffffffffc02000d6 <vcprintf>
    cprintf("\n");
ffffffffc02001c2:	00002517          	auipc	a0,0x2
ffffffffc02001c6:	6a650513          	addi	a0,a0,1702 # ffffffffc0202868 <commands+0x5e8>
ffffffffc02001ca:	f2dff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02001ce:	686000ef          	jal	ra,ffffffffc0200854 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02001d2:	4501                	li	a0,0
ffffffffc02001d4:	130000ef          	jal	ra,ffffffffc0200304 <kmonitor>
    while (1) {
ffffffffc02001d8:	bfed                	j	ffffffffc02001d2 <__panic+0x54>

ffffffffc02001da <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001da:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001dc:	00002517          	auipc	a0,0x2
ffffffffc02001e0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0202048 <etext+0x7e>
void print_kerninfo(void) {
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e6:	f11ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001ea:	00000597          	auipc	a1,0x0
ffffffffc02001ee:	e6a58593          	addi	a1,a1,-406 # ffffffffc0200054 <kern_init>
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	e7650513          	addi	a0,a0,-394 # ffffffffc0202068 <etext+0x9e>
ffffffffc02001fa:	efdff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001fe:	00002597          	auipc	a1,0x2
ffffffffc0200202:	dcc58593          	addi	a1,a1,-564 # ffffffffc0201fca <etext>
ffffffffc0200206:	00002517          	auipc	a0,0x2
ffffffffc020020a:	e8250513          	addi	a0,a0,-382 # ffffffffc0202088 <etext+0xbe>
ffffffffc020020e:	ee9ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200212:	00007597          	auipc	a1,0x7
ffffffffc0200216:	e1658593          	addi	a1,a1,-490 # ffffffffc0207028 <free_area>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	e8e50513          	addi	a0,a0,-370 # ffffffffc02020a8 <etext+0xde>
ffffffffc0200222:	ed5ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200226:	00007597          	auipc	a1,0x7
ffffffffc020022a:	27a58593          	addi	a1,a1,634 # ffffffffc02074a0 <end>
ffffffffc020022e:	00002517          	auipc	a0,0x2
ffffffffc0200232:	e9a50513          	addi	a0,a0,-358 # ffffffffc02020c8 <etext+0xfe>
ffffffffc0200236:	ec1ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023a:	00007597          	auipc	a1,0x7
ffffffffc020023e:	66558593          	addi	a1,a1,1637 # ffffffffc020789f <end+0x3ff>
ffffffffc0200242:	00000797          	auipc	a5,0x0
ffffffffc0200246:	e1278793          	addi	a5,a5,-494 # ffffffffc0200054 <kern_init>
ffffffffc020024a:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024e:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200254:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200258:	95be                	add	a1,a1,a5
ffffffffc020025a:	85a9                	srai	a1,a1,0xa
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	e8c50513          	addi	a0,a0,-372 # ffffffffc02020e8 <etext+0x11e>
}
ffffffffc0200264:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200266:	bd41                	j	ffffffffc02000f6 <cprintf>

ffffffffc0200268 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200268:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026a:	00002617          	auipc	a2,0x2
ffffffffc020026e:	eae60613          	addi	a2,a2,-338 # ffffffffc0202118 <etext+0x14e>
ffffffffc0200272:	04d00593          	li	a1,77
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	eba50513          	addi	a0,a0,-326 # ffffffffc0202130 <etext+0x166>
void print_stackframe(void) {
ffffffffc020027e:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200280:	effff0ef          	jal	ra,ffffffffc020017e <__panic>

ffffffffc0200284 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200284:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	ec260613          	addi	a2,a2,-318 # ffffffffc0202148 <etext+0x17e>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	eda58593          	addi	a1,a1,-294 # ffffffffc0202168 <etext+0x19e>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	eda50513          	addi	a0,a0,-294 # ffffffffc0202170 <etext+0x1a6>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020029e:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a0:	e57ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
ffffffffc02002a4:	00002617          	auipc	a2,0x2
ffffffffc02002a8:	edc60613          	addi	a2,a2,-292 # ffffffffc0202180 <etext+0x1b6>
ffffffffc02002ac:	00002597          	auipc	a1,0x2
ffffffffc02002b0:	efc58593          	addi	a1,a1,-260 # ffffffffc02021a8 <etext+0x1de>
ffffffffc02002b4:	00002517          	auipc	a0,0x2
ffffffffc02002b8:	ebc50513          	addi	a0,a0,-324 # ffffffffc0202170 <etext+0x1a6>
ffffffffc02002bc:	e3bff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
ffffffffc02002c0:	00002617          	auipc	a2,0x2
ffffffffc02002c4:	ef860613          	addi	a2,a2,-264 # ffffffffc02021b8 <etext+0x1ee>
ffffffffc02002c8:	00002597          	auipc	a1,0x2
ffffffffc02002cc:	f1058593          	addi	a1,a1,-240 # ffffffffc02021d8 <etext+0x20e>
ffffffffc02002d0:	00002517          	auipc	a0,0x2
ffffffffc02002d4:	ea050513          	addi	a0,a0,-352 # ffffffffc0202170 <etext+0x1a6>
ffffffffc02002d8:	e1fff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    }
    return 0;
}
ffffffffc02002dc:	60a2                	ld	ra,8(sp)
ffffffffc02002de:	4501                	li	a0,0
ffffffffc02002e0:	0141                	addi	sp,sp,16
ffffffffc02002e2:	8082                	ret

ffffffffc02002e4 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	1141                	addi	sp,sp,-16
ffffffffc02002e6:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002e8:	ef3ff0ef          	jal	ra,ffffffffc02001da <print_kerninfo>
    return 0;
}
ffffffffc02002ec:	60a2                	ld	ra,8(sp)
ffffffffc02002ee:	4501                	li	a0,0
ffffffffc02002f0:	0141                	addi	sp,sp,16
ffffffffc02002f2:	8082                	ret

ffffffffc02002f4 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f4:	1141                	addi	sp,sp,-16
ffffffffc02002f6:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002f8:	f71ff0ef          	jal	ra,ffffffffc0200268 <print_stackframe>
    return 0;
}
ffffffffc02002fc:	60a2                	ld	ra,8(sp)
ffffffffc02002fe:	4501                	li	a0,0
ffffffffc0200300:	0141                	addi	sp,sp,16
ffffffffc0200302:	8082                	ret

ffffffffc0200304 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200304:	7115                	addi	sp,sp,-224
ffffffffc0200306:	ed5e                	sd	s7,152(sp)
ffffffffc0200308:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030a:	00002517          	auipc	a0,0x2
ffffffffc020030e:	ede50513          	addi	a0,a0,-290 # ffffffffc02021e8 <etext+0x21e>
kmonitor(struct trapframe *tf) {
ffffffffc0200312:	ed86                	sd	ra,216(sp)
ffffffffc0200314:	e9a2                	sd	s0,208(sp)
ffffffffc0200316:	e5a6                	sd	s1,200(sp)
ffffffffc0200318:	e1ca                	sd	s2,192(sp)
ffffffffc020031a:	fd4e                	sd	s3,184(sp)
ffffffffc020031c:	f952                	sd	s4,176(sp)
ffffffffc020031e:	f556                	sd	s5,168(sp)
ffffffffc0200320:	f15a                	sd	s6,160(sp)
ffffffffc0200322:	e962                	sd	s8,144(sp)
ffffffffc0200324:	e566                	sd	s9,136(sp)
ffffffffc0200326:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200328:	dcfff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032c:	00002517          	auipc	a0,0x2
ffffffffc0200330:	ee450513          	addi	a0,a0,-284 # ffffffffc0202210 <etext+0x246>
ffffffffc0200334:	dc3ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    if (tf != NULL) {
ffffffffc0200338:	000b8563          	beqz	s7,ffffffffc0200342 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033c:	855e                	mv	a0,s7
ffffffffc020033e:	6fc000ef          	jal	ra,ffffffffc0200a3a <print_trapframe>
ffffffffc0200342:	00002c17          	auipc	s8,0x2
ffffffffc0200346:	f3ec0c13          	addi	s8,s8,-194 # ffffffffc0202280 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020034a:	00002917          	auipc	s2,0x2
ffffffffc020034e:	eee90913          	addi	s2,s2,-274 # ffffffffc0202238 <etext+0x26e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200352:	00002497          	auipc	s1,0x2
ffffffffc0200356:	eee48493          	addi	s1,s1,-274 # ffffffffc0202240 <etext+0x276>
        if (argc == MAXARGS - 1) {
ffffffffc020035a:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020035c:	00002b17          	auipc	s6,0x2
ffffffffc0200360:	eecb0b13          	addi	s6,s6,-276 # ffffffffc0202248 <etext+0x27e>
        argv[argc ++] = buf;
ffffffffc0200364:	00002a17          	auipc	s4,0x2
ffffffffc0200368:	e04a0a13          	addi	s4,s4,-508 # ffffffffc0202168 <etext+0x19e>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020036c:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020036e:	854a                	mv	a0,s2
ffffffffc0200370:	33d010ef          	jal	ra,ffffffffc0201eac <readline>
ffffffffc0200374:	842a                	mv	s0,a0
ffffffffc0200376:	dd65                	beqz	a0,ffffffffc020036e <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200378:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037c:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037e:	e1bd                	bnez	a1,ffffffffc02003e4 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200380:	fe0c87e3          	beqz	s9,ffffffffc020036e <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200384:	6582                	ld	a1,0(sp)
ffffffffc0200386:	00002d17          	auipc	s10,0x2
ffffffffc020038a:	efad0d13          	addi	s10,s10,-262 # ffffffffc0202280 <commands>
        argv[argc ++] = buf;
ffffffffc020038e:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200390:	4401                	li	s0,0
ffffffffc0200392:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200394:	6be010ef          	jal	ra,ffffffffc0201a52 <strcmp>
ffffffffc0200398:	c919                	beqz	a0,ffffffffc02003ae <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039a:	2405                	addiw	s0,s0,1
ffffffffc020039c:	0b540063          	beq	s0,s5,ffffffffc020043c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a0:	000d3503          	ld	a0,0(s10)
ffffffffc02003a4:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a6:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a8:	6aa010ef          	jal	ra,ffffffffc0201a52 <strcmp>
ffffffffc02003ac:	f57d                	bnez	a0,ffffffffc020039a <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003ae:	00141793          	slli	a5,s0,0x1
ffffffffc02003b2:	97a2                	add	a5,a5,s0
ffffffffc02003b4:	078e                	slli	a5,a5,0x3
ffffffffc02003b6:	97e2                	add	a5,a5,s8
ffffffffc02003b8:	6b9c                	ld	a5,16(a5)
ffffffffc02003ba:	865e                	mv	a2,s7
ffffffffc02003bc:	002c                	addi	a1,sp,8
ffffffffc02003be:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003c2:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003c4:	fa0555e3          	bgez	a0,ffffffffc020036e <kmonitor+0x6a>
}
ffffffffc02003c8:	60ee                	ld	ra,216(sp)
ffffffffc02003ca:	644e                	ld	s0,208(sp)
ffffffffc02003cc:	64ae                	ld	s1,200(sp)
ffffffffc02003ce:	690e                	ld	s2,192(sp)
ffffffffc02003d0:	79ea                	ld	s3,184(sp)
ffffffffc02003d2:	7a4a                	ld	s4,176(sp)
ffffffffc02003d4:	7aaa                	ld	s5,168(sp)
ffffffffc02003d6:	7b0a                	ld	s6,160(sp)
ffffffffc02003d8:	6bea                	ld	s7,152(sp)
ffffffffc02003da:	6c4a                	ld	s8,144(sp)
ffffffffc02003dc:	6caa                	ld	s9,136(sp)
ffffffffc02003de:	6d0a                	ld	s10,128(sp)
ffffffffc02003e0:	612d                	addi	sp,sp,224
ffffffffc02003e2:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e4:	8526                	mv	a0,s1
ffffffffc02003e6:	6b0010ef          	jal	ra,ffffffffc0201a96 <strchr>
ffffffffc02003ea:	c901                	beqz	a0,ffffffffc02003fa <kmonitor+0xf6>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003f0:	00040023          	sb	zero,0(s0)
ffffffffc02003f4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f6:	d5c9                	beqz	a1,ffffffffc0200380 <kmonitor+0x7c>
ffffffffc02003f8:	b7f5                	j	ffffffffc02003e4 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003fa:	00044783          	lbu	a5,0(s0)
ffffffffc02003fe:	d3c9                	beqz	a5,ffffffffc0200380 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200400:	033c8963          	beq	s9,s3,ffffffffc0200432 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200404:	003c9793          	slli	a5,s9,0x3
ffffffffc0200408:	0118                	addi	a4,sp,128
ffffffffc020040a:	97ba                	add	a5,a5,a4
ffffffffc020040c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200410:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200414:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200416:	e591                	bnez	a1,ffffffffc0200422 <kmonitor+0x11e>
ffffffffc0200418:	b7b5                	j	ffffffffc0200384 <kmonitor+0x80>
ffffffffc020041a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020041e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200420:	d1a5                	beqz	a1,ffffffffc0200380 <kmonitor+0x7c>
ffffffffc0200422:	8526                	mv	a0,s1
ffffffffc0200424:	672010ef          	jal	ra,ffffffffc0201a96 <strchr>
ffffffffc0200428:	d96d                	beqz	a0,ffffffffc020041a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042a:	00044583          	lbu	a1,0(s0)
ffffffffc020042e:	d9a9                	beqz	a1,ffffffffc0200380 <kmonitor+0x7c>
ffffffffc0200430:	bf55                	j	ffffffffc02003e4 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200432:	45c1                	li	a1,16
ffffffffc0200434:	855a                	mv	a0,s6
ffffffffc0200436:	cc1ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
ffffffffc020043a:	b7e9                	j	ffffffffc0200404 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020043c:	6582                	ld	a1,0(sp)
ffffffffc020043e:	00002517          	auipc	a0,0x2
ffffffffc0200442:	e2a50513          	addi	a0,a0,-470 # ffffffffc0202268 <etext+0x29e>
ffffffffc0200446:	cb1ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    return 0;
ffffffffc020044a:	b715                	j	ffffffffc020036e <kmonitor+0x6a>

ffffffffc020044c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020044c:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020044e:	00002517          	auipc	a0,0x2
ffffffffc0200452:	e7a50513          	addi	a0,a0,-390 # ffffffffc02022c8 <commands+0x48>
void dtb_init(void) {
ffffffffc0200456:	fc86                	sd	ra,120(sp)
ffffffffc0200458:	f8a2                	sd	s0,112(sp)
ffffffffc020045a:	e8d2                	sd	s4,80(sp)
ffffffffc020045c:	f4a6                	sd	s1,104(sp)
ffffffffc020045e:	f0ca                	sd	s2,96(sp)
ffffffffc0200460:	ecce                	sd	s3,88(sp)
ffffffffc0200462:	e4d6                	sd	s5,72(sp)
ffffffffc0200464:	e0da                	sd	s6,64(sp)
ffffffffc0200466:	fc5e                	sd	s7,56(sp)
ffffffffc0200468:	f862                	sd	s8,48(sp)
ffffffffc020046a:	f466                	sd	s9,40(sp)
ffffffffc020046c:	f06a                	sd	s10,32(sp)
ffffffffc020046e:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200470:	c87ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200474:	00007597          	auipc	a1,0x7
ffffffffc0200478:	b8c5b583          	ld	a1,-1140(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc020047c:	00002517          	auipc	a0,0x2
ffffffffc0200480:	e5c50513          	addi	a0,a0,-420 # ffffffffc02022d8 <commands+0x58>
ffffffffc0200484:	c73ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200488:	00007417          	auipc	s0,0x7
ffffffffc020048c:	b8040413          	addi	s0,s0,-1152 # ffffffffc0207008 <boot_dtb>
ffffffffc0200490:	600c                	ld	a1,0(s0)
ffffffffc0200492:	00002517          	auipc	a0,0x2
ffffffffc0200496:	e5650513          	addi	a0,a0,-426 # ffffffffc02022e8 <commands+0x68>
ffffffffc020049a:	c5dff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020049e:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	e5e50513          	addi	a0,a0,-418 # ffffffffc0202300 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc02004aa:	120a0463          	beqz	s4,ffffffffc02005d2 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004ae:	57f5                	li	a5,-3
ffffffffc02004b0:	07fa                	slli	a5,a5,0x1e
ffffffffc02004b2:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004b6:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b8:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004bc:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004be:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004c2:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d4:	8ec9                	or	a3,a3,a0
ffffffffc02004d6:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004da:	1b7d                	addi	s6,s6,-1
ffffffffc02004dc:	0167f7b3          	and	a5,a5,s6
ffffffffc02004e0:	8dd5                	or	a1,a1,a3
ffffffffc02004e2:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02004e4:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e8:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02004ea:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc02004ee:	10f59163          	bne	a1,a5,ffffffffc02005f0 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02004f2:	471c                	lw	a5,8(a4)
ffffffffc02004f4:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02004f6:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004fc:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200500:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200508:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050c:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200510:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200514:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200518:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051c:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200520:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200522:	01146433          	or	s0,s0,a7
ffffffffc0200526:	0086969b          	slliw	a3,a3,0x8
ffffffffc020052a:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052e:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200530:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200534:	8c49                	or	s0,s0,a0
ffffffffc0200536:	0166f6b3          	and	a3,a3,s6
ffffffffc020053a:	00ca6a33          	or	s4,s4,a2
ffffffffc020053e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200542:	8c55                	or	s0,s0,a3
ffffffffc0200544:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200548:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020054a:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020054c:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020054e:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200552:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200554:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200556:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020055a:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020055c:	00002917          	auipc	s2,0x2
ffffffffc0200560:	df490913          	addi	s2,s2,-524 # ffffffffc0202350 <commands+0xd0>
ffffffffc0200564:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200566:	4d91                	li	s11,4
ffffffffc0200568:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020056a:	00002497          	auipc	s1,0x2
ffffffffc020056e:	dde48493          	addi	s1,s1,-546 # ffffffffc0202348 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200572:	000a2703          	lw	a4,0(s4)
ffffffffc0200576:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057a:	0087569b          	srliw	a3,a4,0x8
ffffffffc020057e:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200582:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200586:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058a:	0107571b          	srliw	a4,a4,0x10
ffffffffc020058e:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200590:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200594:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200598:	8fd5                	or	a5,a5,a3
ffffffffc020059a:	00eb7733          	and	a4,s6,a4
ffffffffc020059e:	8fd9                	or	a5,a5,a4
ffffffffc02005a0:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005a2:	09778c63          	beq	a5,s7,ffffffffc020063a <dtb_init+0x1ee>
ffffffffc02005a6:	00fbea63          	bltu	s7,a5,ffffffffc02005ba <dtb_init+0x16e>
ffffffffc02005aa:	07a78663          	beq	a5,s10,ffffffffc0200616 <dtb_init+0x1ca>
ffffffffc02005ae:	4709                	li	a4,2
ffffffffc02005b0:	00e79763          	bne	a5,a4,ffffffffc02005be <dtb_init+0x172>
ffffffffc02005b4:	4c81                	li	s9,0
ffffffffc02005b6:	8a56                	mv	s4,s5
ffffffffc02005b8:	bf6d                	j	ffffffffc0200572 <dtb_init+0x126>
ffffffffc02005ba:	ffb78ee3          	beq	a5,s11,ffffffffc02005b6 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005be:	00002517          	auipc	a0,0x2
ffffffffc02005c2:	e0a50513          	addi	a0,a0,-502 # ffffffffc02023c8 <commands+0x148>
ffffffffc02005c6:	b31ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005ca:	00002517          	auipc	a0,0x2
ffffffffc02005ce:	e3650513          	addi	a0,a0,-458 # ffffffffc0202400 <commands+0x180>
}
ffffffffc02005d2:	7446                	ld	s0,112(sp)
ffffffffc02005d4:	70e6                	ld	ra,120(sp)
ffffffffc02005d6:	74a6                	ld	s1,104(sp)
ffffffffc02005d8:	7906                	ld	s2,96(sp)
ffffffffc02005da:	69e6                	ld	s3,88(sp)
ffffffffc02005dc:	6a46                	ld	s4,80(sp)
ffffffffc02005de:	6aa6                	ld	s5,72(sp)
ffffffffc02005e0:	6b06                	ld	s6,64(sp)
ffffffffc02005e2:	7be2                	ld	s7,56(sp)
ffffffffc02005e4:	7c42                	ld	s8,48(sp)
ffffffffc02005e6:	7ca2                	ld	s9,40(sp)
ffffffffc02005e8:	7d02                	ld	s10,32(sp)
ffffffffc02005ea:	6de2                	ld	s11,24(sp)
ffffffffc02005ec:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02005ee:	b621                	j	ffffffffc02000f6 <cprintf>
}
ffffffffc02005f0:	7446                	ld	s0,112(sp)
ffffffffc02005f2:	70e6                	ld	ra,120(sp)
ffffffffc02005f4:	74a6                	ld	s1,104(sp)
ffffffffc02005f6:	7906                	ld	s2,96(sp)
ffffffffc02005f8:	69e6                	ld	s3,88(sp)
ffffffffc02005fa:	6a46                	ld	s4,80(sp)
ffffffffc02005fc:	6aa6                	ld	s5,72(sp)
ffffffffc02005fe:	6b06                	ld	s6,64(sp)
ffffffffc0200600:	7be2                	ld	s7,56(sp)
ffffffffc0200602:	7c42                	ld	s8,48(sp)
ffffffffc0200604:	7ca2                	ld	s9,40(sp)
ffffffffc0200606:	7d02                	ld	s10,32(sp)
ffffffffc0200608:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020060a:	00002517          	auipc	a0,0x2
ffffffffc020060e:	d1650513          	addi	a0,a0,-746 # ffffffffc0202320 <commands+0xa0>
}
ffffffffc0200612:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200614:	b4cd                	j	ffffffffc02000f6 <cprintf>
                int name_len = strlen(name);
ffffffffc0200616:	8556                	mv	a0,s5
ffffffffc0200618:	404010ef          	jal	ra,ffffffffc0201a1c <strlen>
ffffffffc020061c:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020061e:	4619                	li	a2,6
ffffffffc0200620:	85a6                	mv	a1,s1
ffffffffc0200622:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200624:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200626:	44a010ef          	jal	ra,ffffffffc0201a70 <strncmp>
ffffffffc020062a:	e111                	bnez	a0,ffffffffc020062e <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020062c:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020062e:	0a91                	addi	s5,s5,4
ffffffffc0200630:	9ad2                	add	s5,s5,s4
ffffffffc0200632:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200636:	8a56                	mv	s4,s5
ffffffffc0200638:	bf2d                	j	ffffffffc0200572 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063a:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200646:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200652:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200656:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065a:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	00eaeab3          	or	s5,s5,a4
ffffffffc0200666:	00fb77b3          	and	a5,s6,a5
ffffffffc020066a:	00faeab3          	or	s5,s5,a5
ffffffffc020066e:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200670:	000c9c63          	bnez	s9,ffffffffc0200688 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200674:	1a82                	slli	s5,s5,0x20
ffffffffc0200676:	00368793          	addi	a5,a3,3
ffffffffc020067a:	020ada93          	srli	s5,s5,0x20
ffffffffc020067e:	9abe                	add	s5,s5,a5
ffffffffc0200680:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200684:	8a56                	mv	s4,s5
ffffffffc0200686:	b5f5                	j	ffffffffc0200572 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200688:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068c:	85ca                	mv	a1,s2
ffffffffc020068e:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200690:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200698:	0187971b          	slliw	a4,a5,0x18
ffffffffc020069c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a0:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006a4:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ae:	8d59                	or	a0,a0,a4
ffffffffc02006b0:	00fb77b3          	and	a5,s6,a5
ffffffffc02006b4:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006b6:	1502                	slli	a0,a0,0x20
ffffffffc02006b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ba:	9522                	add	a0,a0,s0
ffffffffc02006bc:	396010ef          	jal	ra,ffffffffc0201a52 <strcmp>
ffffffffc02006c0:	66a2                	ld	a3,8(sp)
ffffffffc02006c2:	f94d                	bnez	a0,ffffffffc0200674 <dtb_init+0x228>
ffffffffc02006c4:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200674 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006c8:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006cc:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006d0:	00002517          	auipc	a0,0x2
ffffffffc02006d4:	c8850513          	addi	a0,a0,-888 # ffffffffc0202358 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc02006d8:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006dc:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02006e0:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e4:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02006e8:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ec:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f0:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f4:	0187d693          	srli	a3,a5,0x18
ffffffffc02006f8:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02006fc:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200700:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200704:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200708:	010f6f33          	or	t5,t5,a6
ffffffffc020070c:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200710:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200714:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200718:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071c:	0186f6b3          	and	a3,a3,s8
ffffffffc0200720:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200724:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200728:	0107581b          	srliw	a6,a4,0x10
ffffffffc020072c:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200730:	8361                	srli	a4,a4,0x18
ffffffffc0200732:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020073a:	01e6e6b3          	or	a3,a3,t5
ffffffffc020073e:	00cb7633          	and	a2,s6,a2
ffffffffc0200742:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200746:	0085959b          	slliw	a1,a1,0x8
ffffffffc020074a:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200752:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200756:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075a:	0088989b          	slliw	a7,a7,0x8
ffffffffc020075e:	011b78b3          	and	a7,s6,a7
ffffffffc0200762:	005eeeb3          	or	t4,t4,t0
ffffffffc0200766:	00c6e733          	or	a4,a3,a2
ffffffffc020076a:	006c6c33          	or	s8,s8,t1
ffffffffc020076e:	010b76b3          	and	a3,s6,a6
ffffffffc0200772:	00bb7b33          	and	s6,s6,a1
ffffffffc0200776:	01d7e7b3          	or	a5,a5,t4
ffffffffc020077a:	016c6b33          	or	s6,s8,s6
ffffffffc020077e:	01146433          	or	s0,s0,a7
ffffffffc0200782:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200784:	1702                	slli	a4,a4,0x20
ffffffffc0200786:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200788:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020078a:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020078c:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020078e:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200792:	0167eb33          	or	s6,a5,s6
ffffffffc0200796:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200798:	95fff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020079c:	85a2                	mv	a1,s0
ffffffffc020079e:	00002517          	auipc	a0,0x2
ffffffffc02007a2:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202378 <commands+0xf8>
ffffffffc02007a6:	951ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007aa:	014b5613          	srli	a2,s6,0x14
ffffffffc02007ae:	85da                	mv	a1,s6
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	be050513          	addi	a0,a0,-1056 # ffffffffc0202390 <commands+0x110>
ffffffffc02007b8:	93fff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007bc:	008b05b3          	add	a1,s6,s0
ffffffffc02007c0:	15fd                	addi	a1,a1,-1
ffffffffc02007c2:	00002517          	auipc	a0,0x2
ffffffffc02007c6:	bee50513          	addi	a0,a0,-1042 # ffffffffc02023b0 <commands+0x130>
ffffffffc02007ca:	92dff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007ce:	00002517          	auipc	a0,0x2
ffffffffc02007d2:	c3250513          	addi	a0,a0,-974 # ffffffffc0202400 <commands+0x180>
        memory_base = mem_base;
ffffffffc02007d6:	00007797          	auipc	a5,0x7
ffffffffc02007da:	c687b923          	sd	s0,-910(a5) # ffffffffc0207448 <memory_base>
        memory_size = mem_size;
ffffffffc02007de:	00007797          	auipc	a5,0x7
ffffffffc02007e2:	c767b923          	sd	s6,-910(a5) # ffffffffc0207450 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007e6:	b3f5                	j	ffffffffc02005d2 <dtb_init+0x186>

ffffffffc02007e8 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007e8:	00007517          	auipc	a0,0x7
ffffffffc02007ec:	c6053503          	ld	a0,-928(a0) # ffffffffc0207448 <memory_base>
ffffffffc02007f0:	8082                	ret

ffffffffc02007f2 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007f2:	00007517          	auipc	a0,0x7
ffffffffc02007f6:	c5e53503          	ld	a0,-930(a0) # ffffffffc0207450 <memory_size>
ffffffffc02007fa:	8082                	ret

ffffffffc02007fc <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc02007fc:	1141                	addi	sp,sp,-16
ffffffffc02007fe:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200800:	02000793          	li	a5,32
ffffffffc0200804:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200808:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020080c:	67e1                	lui	a5,0x18
ffffffffc020080e:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200812:	953e                	add	a0,a0,a5
ffffffffc0200814:	766010ef          	jal	ra,ffffffffc0201f7a <sbi_set_timer>
}
ffffffffc0200818:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020081a:	00007797          	auipc	a5,0x7
ffffffffc020081e:	c207bf23          	sd	zero,-962(a5) # ffffffffc0207458 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200822:	00002517          	auipc	a0,0x2
ffffffffc0200826:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202418 <commands+0x198>
}
ffffffffc020082a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020082c:	8cbff06f          	j	ffffffffc02000f6 <cprintf>

ffffffffc0200830 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200830:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200834:	67e1                	lui	a5,0x18
ffffffffc0200836:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020083a:	953e                	add	a0,a0,a5
ffffffffc020083c:	73e0106f          	j	ffffffffc0201f7a <sbi_set_timer>

ffffffffc0200840 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200840:	8082                	ret

ffffffffc0200842 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200842:	0ff57513          	zext.b	a0,a0
ffffffffc0200846:	71a0106f          	j	ffffffffc0201f60 <sbi_console_putchar>

ffffffffc020084a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020084a:	74a0106f          	j	ffffffffc0201f94 <sbi_console_getchar>

ffffffffc020084e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020084e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200852:	8082                	ret

ffffffffc0200854 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200854:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200858:	8082                	ret

ffffffffc020085a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020085a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020085e:	00000797          	auipc	a5,0x0
ffffffffc0200862:	39a78793          	addi	a5,a5,922 # ffffffffc0200bf8 <__alltraps>
ffffffffc0200866:	10579073          	csrw	stvec,a5
}
ffffffffc020086a:	8082                	ret

ffffffffc020086c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020086c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020086e:	1141                	addi	sp,sp,-16
ffffffffc0200870:	e022                	sd	s0,0(sp)
ffffffffc0200872:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200874:	00002517          	auipc	a0,0x2
ffffffffc0200878:	bc450513          	addi	a0,a0,-1084 # ffffffffc0202438 <commands+0x1b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020087c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020087e:	879ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200882:	640c                	ld	a1,8(s0)
ffffffffc0200884:	00002517          	auipc	a0,0x2
ffffffffc0200888:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0202450 <commands+0x1d0>
ffffffffc020088c:	86bff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200890:	680c                	ld	a1,16(s0)
ffffffffc0200892:	00002517          	auipc	a0,0x2
ffffffffc0200896:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202468 <commands+0x1e8>
ffffffffc020089a:	85dff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020089e:	6c0c                	ld	a1,24(s0)
ffffffffc02008a0:	00002517          	auipc	a0,0x2
ffffffffc02008a4:	be050513          	addi	a0,a0,-1056 # ffffffffc0202480 <commands+0x200>
ffffffffc02008a8:	84fff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008ac:	700c                	ld	a1,32(s0)
ffffffffc02008ae:	00002517          	auipc	a0,0x2
ffffffffc02008b2:	bea50513          	addi	a0,a0,-1046 # ffffffffc0202498 <commands+0x218>
ffffffffc02008b6:	841ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008ba:	740c                	ld	a1,40(s0)
ffffffffc02008bc:	00002517          	auipc	a0,0x2
ffffffffc02008c0:	bf450513          	addi	a0,a0,-1036 # ffffffffc02024b0 <commands+0x230>
ffffffffc02008c4:	833ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008c8:	780c                	ld	a1,48(s0)
ffffffffc02008ca:	00002517          	auipc	a0,0x2
ffffffffc02008ce:	bfe50513          	addi	a0,a0,-1026 # ffffffffc02024c8 <commands+0x248>
ffffffffc02008d2:	825ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008d6:	7c0c                	ld	a1,56(s0)
ffffffffc02008d8:	00002517          	auipc	a0,0x2
ffffffffc02008dc:	c0850513          	addi	a0,a0,-1016 # ffffffffc02024e0 <commands+0x260>
ffffffffc02008e0:	817ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008e4:	602c                	ld	a1,64(s0)
ffffffffc02008e6:	00002517          	auipc	a0,0x2
ffffffffc02008ea:	c1250513          	addi	a0,a0,-1006 # ffffffffc02024f8 <commands+0x278>
ffffffffc02008ee:	809ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008f2:	642c                	ld	a1,72(s0)
ffffffffc02008f4:	00002517          	auipc	a0,0x2
ffffffffc02008f8:	c1c50513          	addi	a0,a0,-996 # ffffffffc0202510 <commands+0x290>
ffffffffc02008fc:	ffaff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200900:	682c                	ld	a1,80(s0)
ffffffffc0200902:	00002517          	auipc	a0,0x2
ffffffffc0200906:	c2650513          	addi	a0,a0,-986 # ffffffffc0202528 <commands+0x2a8>
ffffffffc020090a:	fecff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020090e:	6c2c                	ld	a1,88(s0)
ffffffffc0200910:	00002517          	auipc	a0,0x2
ffffffffc0200914:	c3050513          	addi	a0,a0,-976 # ffffffffc0202540 <commands+0x2c0>
ffffffffc0200918:	fdeff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020091c:	702c                	ld	a1,96(s0)
ffffffffc020091e:	00002517          	auipc	a0,0x2
ffffffffc0200922:	c3a50513          	addi	a0,a0,-966 # ffffffffc0202558 <commands+0x2d8>
ffffffffc0200926:	fd0ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020092a:	742c                	ld	a1,104(s0)
ffffffffc020092c:	00002517          	auipc	a0,0x2
ffffffffc0200930:	c4450513          	addi	a0,a0,-956 # ffffffffc0202570 <commands+0x2f0>
ffffffffc0200934:	fc2ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200938:	782c                	ld	a1,112(s0)
ffffffffc020093a:	00002517          	auipc	a0,0x2
ffffffffc020093e:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202588 <commands+0x308>
ffffffffc0200942:	fb4ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200946:	7c2c                	ld	a1,120(s0)
ffffffffc0200948:	00002517          	auipc	a0,0x2
ffffffffc020094c:	c5850513          	addi	a0,a0,-936 # ffffffffc02025a0 <commands+0x320>
ffffffffc0200950:	fa6ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200954:	604c                	ld	a1,128(s0)
ffffffffc0200956:	00002517          	auipc	a0,0x2
ffffffffc020095a:	c6250513          	addi	a0,a0,-926 # ffffffffc02025b8 <commands+0x338>
ffffffffc020095e:	f98ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200962:	644c                	ld	a1,136(s0)
ffffffffc0200964:	00002517          	auipc	a0,0x2
ffffffffc0200968:	c6c50513          	addi	a0,a0,-916 # ffffffffc02025d0 <commands+0x350>
ffffffffc020096c:	f8aff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200970:	684c                	ld	a1,144(s0)
ffffffffc0200972:	00002517          	auipc	a0,0x2
ffffffffc0200976:	c7650513          	addi	a0,a0,-906 # ffffffffc02025e8 <commands+0x368>
ffffffffc020097a:	f7cff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020097e:	6c4c                	ld	a1,152(s0)
ffffffffc0200980:	00002517          	auipc	a0,0x2
ffffffffc0200984:	c8050513          	addi	a0,a0,-896 # ffffffffc0202600 <commands+0x380>
ffffffffc0200988:	f6eff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020098c:	704c                	ld	a1,160(s0)
ffffffffc020098e:	00002517          	auipc	a0,0x2
ffffffffc0200992:	c8a50513          	addi	a0,a0,-886 # ffffffffc0202618 <commands+0x398>
ffffffffc0200996:	f60ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020099a:	744c                	ld	a1,168(s0)
ffffffffc020099c:	00002517          	auipc	a0,0x2
ffffffffc02009a0:	c9450513          	addi	a0,a0,-876 # ffffffffc0202630 <commands+0x3b0>
ffffffffc02009a4:	f52ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009a8:	784c                	ld	a1,176(s0)
ffffffffc02009aa:	00002517          	auipc	a0,0x2
ffffffffc02009ae:	c9e50513          	addi	a0,a0,-866 # ffffffffc0202648 <commands+0x3c8>
ffffffffc02009b2:	f44ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009b6:	7c4c                	ld	a1,184(s0)
ffffffffc02009b8:	00002517          	auipc	a0,0x2
ffffffffc02009bc:	ca850513          	addi	a0,a0,-856 # ffffffffc0202660 <commands+0x3e0>
ffffffffc02009c0:	f36ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009c4:	606c                	ld	a1,192(s0)
ffffffffc02009c6:	00002517          	auipc	a0,0x2
ffffffffc02009ca:	cb250513          	addi	a0,a0,-846 # ffffffffc0202678 <commands+0x3f8>
ffffffffc02009ce:	f28ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009d2:	646c                	ld	a1,200(s0)
ffffffffc02009d4:	00002517          	auipc	a0,0x2
ffffffffc02009d8:	cbc50513          	addi	a0,a0,-836 # ffffffffc0202690 <commands+0x410>
ffffffffc02009dc:	f1aff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009e0:	686c                	ld	a1,208(s0)
ffffffffc02009e2:	00002517          	auipc	a0,0x2
ffffffffc02009e6:	cc650513          	addi	a0,a0,-826 # ffffffffc02026a8 <commands+0x428>
ffffffffc02009ea:	f0cff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009ee:	6c6c                	ld	a1,216(s0)
ffffffffc02009f0:	00002517          	auipc	a0,0x2
ffffffffc02009f4:	cd050513          	addi	a0,a0,-816 # ffffffffc02026c0 <commands+0x440>
ffffffffc02009f8:	efeff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009fc:	706c                	ld	a1,224(s0)
ffffffffc02009fe:	00002517          	auipc	a0,0x2
ffffffffc0200a02:	cda50513          	addi	a0,a0,-806 # ffffffffc02026d8 <commands+0x458>
ffffffffc0200a06:	ef0ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a0a:	746c                	ld	a1,232(s0)
ffffffffc0200a0c:	00002517          	auipc	a0,0x2
ffffffffc0200a10:	ce450513          	addi	a0,a0,-796 # ffffffffc02026f0 <commands+0x470>
ffffffffc0200a14:	ee2ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a18:	786c                	ld	a1,240(s0)
ffffffffc0200a1a:	00002517          	auipc	a0,0x2
ffffffffc0200a1e:	cee50513          	addi	a0,a0,-786 # ffffffffc0202708 <commands+0x488>
ffffffffc0200a22:	ed4ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a26:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a28:	6402                	ld	s0,0(sp)
ffffffffc0200a2a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a2c:	00002517          	auipc	a0,0x2
ffffffffc0200a30:	cf450513          	addi	a0,a0,-780 # ffffffffc0202720 <commands+0x4a0>
}
ffffffffc0200a34:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a36:	ec0ff06f          	j	ffffffffc02000f6 <cprintf>

ffffffffc0200a3a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a3a:	1141                	addi	sp,sp,-16
ffffffffc0200a3c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a3e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a40:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	cf650513          	addi	a0,a0,-778 # ffffffffc0202738 <commands+0x4b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a4a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a4c:	eaaff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a50:	8522                	mv	a0,s0
ffffffffc0200a52:	e1bff0ef          	jal	ra,ffffffffc020086c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a56:	10043583          	ld	a1,256(s0)
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	cf650513          	addi	a0,a0,-778 # ffffffffc0202750 <commands+0x4d0>
ffffffffc0200a62:	e94ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a66:	10843583          	ld	a1,264(s0)
ffffffffc0200a6a:	00002517          	auipc	a0,0x2
ffffffffc0200a6e:	cfe50513          	addi	a0,a0,-770 # ffffffffc0202768 <commands+0x4e8>
ffffffffc0200a72:	e84ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a76:	11043583          	ld	a1,272(s0)
ffffffffc0200a7a:	00002517          	auipc	a0,0x2
ffffffffc0200a7e:	d0650513          	addi	a0,a0,-762 # ffffffffc0202780 <commands+0x500>
ffffffffc0200a82:	e74ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a86:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a8a:	6402                	ld	s0,0(sp)
ffffffffc0200a8c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a8e:	00002517          	auipc	a0,0x2
ffffffffc0200a92:	d0a50513          	addi	a0,a0,-758 # ffffffffc0202798 <commands+0x518>
}
ffffffffc0200a96:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a98:	e5eff06f          	j	ffffffffc02000f6 <cprintf>

ffffffffc0200a9c <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a9c:	11853783          	ld	a5,280(a0)
ffffffffc0200aa0:	472d                	li	a4,11
ffffffffc0200aa2:	0786                	slli	a5,a5,0x1
ffffffffc0200aa4:	8385                	srli	a5,a5,0x1
ffffffffc0200aa6:	08f76363          	bltu	a4,a5,ffffffffc0200b2c <interrupt_handler+0x90>
ffffffffc0200aaa:	00002717          	auipc	a4,0x2
ffffffffc0200aae:	de670713          	addi	a4,a4,-538 # ffffffffc0202890 <commands+0x610>
ffffffffc0200ab2:	078a                	slli	a5,a5,0x2
ffffffffc0200ab4:	97ba                	add	a5,a5,a4
ffffffffc0200ab6:	439c                	lw	a5,0(a5)
ffffffffc0200ab8:	97ba                	add	a5,a5,a4
ffffffffc0200aba:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200abc:	00002517          	auipc	a0,0x2
ffffffffc0200ac0:	d5450513          	addi	a0,a0,-684 # ffffffffc0202810 <commands+0x590>
ffffffffc0200ac4:	e32ff06f          	j	ffffffffc02000f6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200ac8:	00002517          	auipc	a0,0x2
ffffffffc0200acc:	d2850513          	addi	a0,a0,-728 # ffffffffc02027f0 <commands+0x570>
ffffffffc0200ad0:	e26ff06f          	j	ffffffffc02000f6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ad4:	00002517          	auipc	a0,0x2
ffffffffc0200ad8:	cdc50513          	addi	a0,a0,-804 # ffffffffc02027b0 <commands+0x530>
ffffffffc0200adc:	e1aff06f          	j	ffffffffc02000f6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ae0:	00002517          	auipc	a0,0x2
ffffffffc0200ae4:	d5050513          	addi	a0,a0,-688 # ffffffffc0202830 <commands+0x5b0>
ffffffffc0200ae8:	e0eff06f          	j	ffffffffc02000f6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200aec:	1141                	addi	sp,sp,-16
ffffffffc0200aee:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200af0:	d41ff0ef          	jal	ra,ffffffffc0200830 <clock_set_next_event>
            ticks++;
ffffffffc0200af4:	00007797          	auipc	a5,0x7
ffffffffc0200af8:	96478793          	addi	a5,a5,-1692 # ffffffffc0207458 <ticks>
ffffffffc0200afc:	6398                	ld	a4,0(a5)
ffffffffc0200afe:	0705                	addi	a4,a4,1
ffffffffc0200b00:	e398                	sd	a4,0(a5)
            if(ticks%TICK_NUM == 0){
ffffffffc0200b02:	639c                	ld	a5,0(a5)
ffffffffc0200b04:	06400713          	li	a4,100
ffffffffc0200b08:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200b0c:	c38d                	beqz	a5,ffffffffc0200b2e <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b0e:	60a2                	ld	ra,8(sp)
ffffffffc0200b10:	0141                	addi	sp,sp,16
ffffffffc0200b12:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b14:	00002517          	auipc	a0,0x2
ffffffffc0200b18:	d5c50513          	addi	a0,a0,-676 # ffffffffc0202870 <commands+0x5f0>
ffffffffc0200b1c:	ddaff06f          	j	ffffffffc02000f6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b20:	00002517          	auipc	a0,0x2
ffffffffc0200b24:	cb050513          	addi	a0,a0,-848 # ffffffffc02027d0 <commands+0x550>
ffffffffc0200b28:	dceff06f          	j	ffffffffc02000f6 <cprintf>
            print_trapframe(tf);
ffffffffc0200b2c:	b739                	j	ffffffffc0200a3a <print_trapframe>
                cprintf("100ticks\n");
ffffffffc0200b2e:	00002517          	auipc	a0,0x2
ffffffffc0200b32:	d1a50513          	addi	a0,a0,-742 # ffffffffc0202848 <commands+0x5c8>
ffffffffc0200b36:	dc0ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
                num++;
ffffffffc0200b3a:	00007797          	auipc	a5,0x7
ffffffffc0200b3e:	92678793          	addi	a5,a5,-1754 # ffffffffc0207460 <num>
ffffffffc0200b42:	6398                	ld	a4,0(a5)
                if(num == 10){
ffffffffc0200b44:	46a9                	li	a3,10
                num++;
ffffffffc0200b46:	0705                	addi	a4,a4,1
ffffffffc0200b48:	e398                	sd	a4,0(a5)
                if(num == 10){
ffffffffc0200b4a:	639c                	ld	a5,0(a5)
ffffffffc0200b4c:	fcd791e3          	bne	a5,a3,ffffffffc0200b0e <interrupt_handler+0x72>
                    cprintf("shutting down...\n");
ffffffffc0200b50:	00002517          	auipc	a0,0x2
ffffffffc0200b54:	d0850513          	addi	a0,a0,-760 # ffffffffc0202858 <commands+0x5d8>
ffffffffc0200b58:	d9eff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
}
ffffffffc0200b5c:	60a2                	ld	ra,8(sp)
ffffffffc0200b5e:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b60:	4500106f          	j	ffffffffc0201fb0 <sbi_shutdown>

ffffffffc0200b64 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b64:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b68:	1141                	addi	sp,sp,-16
ffffffffc0200b6a:	e022                	sd	s0,0(sp)
ffffffffc0200b6c:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b6e:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b70:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b72:	04e78663          	beq	a5,a4,ffffffffc0200bbe <exception_handler+0x5a>
ffffffffc0200b76:	02f76c63          	bltu	a4,a5,ffffffffc0200bae <exception_handler+0x4a>
ffffffffc0200b7a:	4709                	li	a4,2
ffffffffc0200b7c:	02e79563          	bne	a5,a4,ffffffffc0200ba6 <exception_handler+0x42>
             /* LAB3 CHALLENGE3   YOUR CODE : 2312331 */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b80:	10853583          	ld	a1,264(a0)
ffffffffc0200b84:	00002517          	auipc	a0,0x2
ffffffffc0200b88:	d3c50513          	addi	a0,a0,-708 # ffffffffc02028c0 <commands+0x640>
ffffffffc0200b8c:	d6aff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b90:	00002517          	auipc	a0,0x2
ffffffffc0200b94:	d5850513          	addi	a0,a0,-680 # ffffffffc02028e8 <commands+0x668>
ffffffffc0200b98:	d5eff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
            // 跳过导致异常的指令，避免返回后再次陷入
            tf->epc += 4;
ffffffffc0200b9c:	10843783          	ld	a5,264(s0)
ffffffffc0200ba0:	0791                	addi	a5,a5,4
ffffffffc0200ba2:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ba6:	60a2                	ld	ra,8(sp)
ffffffffc0200ba8:	6402                	ld	s0,0(sp)
ffffffffc0200baa:	0141                	addi	sp,sp,16
ffffffffc0200bac:	8082                	ret
    switch (tf->cause) {
ffffffffc0200bae:	17f1                	addi	a5,a5,-4
ffffffffc0200bb0:	471d                	li	a4,7
ffffffffc0200bb2:	fef77ae3          	bgeu	a4,a5,ffffffffc0200ba6 <exception_handler+0x42>
}
ffffffffc0200bb6:	6402                	ld	s0,0(sp)
ffffffffc0200bb8:	60a2                	ld	ra,8(sp)
ffffffffc0200bba:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200bbc:	bdbd                	j	ffffffffc0200a3a <print_trapframe>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200bbe:	10853583          	ld	a1,264(a0)
ffffffffc0200bc2:	00002517          	auipc	a0,0x2
ffffffffc0200bc6:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202910 <commands+0x690>
ffffffffc0200bca:	d2cff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200bce:	00002517          	auipc	a0,0x2
ffffffffc0200bd2:	d6250513          	addi	a0,a0,-670 # ffffffffc0202930 <commands+0x6b0>
ffffffffc0200bd6:	d20ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
            tf->epc += 2;
ffffffffc0200bda:	10843783          	ld	a5,264(s0)
}
ffffffffc0200bde:	60a2                	ld	ra,8(sp)
            tf->epc += 2;
ffffffffc0200be0:	0789                	addi	a5,a5,2
ffffffffc0200be2:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200be6:	6402                	ld	s0,0(sp)
ffffffffc0200be8:	0141                	addi	sp,sp,16
ffffffffc0200bea:	8082                	ret

ffffffffc0200bec <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bec:	11853783          	ld	a5,280(a0)
ffffffffc0200bf0:	0007c363          	bltz	a5,ffffffffc0200bf6 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bf4:	bf85                	j	ffffffffc0200b64 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bf6:	b55d                	j	ffffffffc0200a9c <interrupt_handler>

ffffffffc0200bf8 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200bf8:	14011073          	csrw	sscratch,sp
ffffffffc0200bfc:	712d                	addi	sp,sp,-288
ffffffffc0200bfe:	e002                	sd	zero,0(sp)
ffffffffc0200c00:	e406                	sd	ra,8(sp)
ffffffffc0200c02:	ec0e                	sd	gp,24(sp)
ffffffffc0200c04:	f012                	sd	tp,32(sp)
ffffffffc0200c06:	f416                	sd	t0,40(sp)
ffffffffc0200c08:	f81a                	sd	t1,48(sp)
ffffffffc0200c0a:	fc1e                	sd	t2,56(sp)
ffffffffc0200c0c:	e0a2                	sd	s0,64(sp)
ffffffffc0200c0e:	e4a6                	sd	s1,72(sp)
ffffffffc0200c10:	e8aa                	sd	a0,80(sp)
ffffffffc0200c12:	ecae                	sd	a1,88(sp)
ffffffffc0200c14:	f0b2                	sd	a2,96(sp)
ffffffffc0200c16:	f4b6                	sd	a3,104(sp)
ffffffffc0200c18:	f8ba                	sd	a4,112(sp)
ffffffffc0200c1a:	fcbe                	sd	a5,120(sp)
ffffffffc0200c1c:	e142                	sd	a6,128(sp)
ffffffffc0200c1e:	e546                	sd	a7,136(sp)
ffffffffc0200c20:	e94a                	sd	s2,144(sp)
ffffffffc0200c22:	ed4e                	sd	s3,152(sp)
ffffffffc0200c24:	f152                	sd	s4,160(sp)
ffffffffc0200c26:	f556                	sd	s5,168(sp)
ffffffffc0200c28:	f95a                	sd	s6,176(sp)
ffffffffc0200c2a:	fd5e                	sd	s7,184(sp)
ffffffffc0200c2c:	e1e2                	sd	s8,192(sp)
ffffffffc0200c2e:	e5e6                	sd	s9,200(sp)
ffffffffc0200c30:	e9ea                	sd	s10,208(sp)
ffffffffc0200c32:	edee                	sd	s11,216(sp)
ffffffffc0200c34:	f1f2                	sd	t3,224(sp)
ffffffffc0200c36:	f5f6                	sd	t4,232(sp)
ffffffffc0200c38:	f9fa                	sd	t5,240(sp)
ffffffffc0200c3a:	fdfe                	sd	t6,248(sp)
ffffffffc0200c3c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c40:	100024f3          	csrr	s1,sstatus
ffffffffc0200c44:	14102973          	csrr	s2,sepc
ffffffffc0200c48:	143029f3          	csrr	s3,stval
ffffffffc0200c4c:	14202a73          	csrr	s4,scause
ffffffffc0200c50:	e822                	sd	s0,16(sp)
ffffffffc0200c52:	e226                	sd	s1,256(sp)
ffffffffc0200c54:	e64a                	sd	s2,264(sp)
ffffffffc0200c56:	ea4e                	sd	s3,272(sp)
ffffffffc0200c58:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c5a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c5c:	f91ff0ef          	jal	ra,ffffffffc0200bec <trap>

ffffffffc0200c60 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c60:	6492                	ld	s1,256(sp)
ffffffffc0200c62:	6932                	ld	s2,264(sp)
ffffffffc0200c64:	10049073          	csrw	sstatus,s1
ffffffffc0200c68:	14191073          	csrw	sepc,s2
ffffffffc0200c6c:	60a2                	ld	ra,8(sp)
ffffffffc0200c6e:	61e2                	ld	gp,24(sp)
ffffffffc0200c70:	7202                	ld	tp,32(sp)
ffffffffc0200c72:	72a2                	ld	t0,40(sp)
ffffffffc0200c74:	7342                	ld	t1,48(sp)
ffffffffc0200c76:	73e2                	ld	t2,56(sp)
ffffffffc0200c78:	6406                	ld	s0,64(sp)
ffffffffc0200c7a:	64a6                	ld	s1,72(sp)
ffffffffc0200c7c:	6546                	ld	a0,80(sp)
ffffffffc0200c7e:	65e6                	ld	a1,88(sp)
ffffffffc0200c80:	7606                	ld	a2,96(sp)
ffffffffc0200c82:	76a6                	ld	a3,104(sp)
ffffffffc0200c84:	7746                	ld	a4,112(sp)
ffffffffc0200c86:	77e6                	ld	a5,120(sp)
ffffffffc0200c88:	680a                	ld	a6,128(sp)
ffffffffc0200c8a:	68aa                	ld	a7,136(sp)
ffffffffc0200c8c:	694a                	ld	s2,144(sp)
ffffffffc0200c8e:	69ea                	ld	s3,152(sp)
ffffffffc0200c90:	7a0a                	ld	s4,160(sp)
ffffffffc0200c92:	7aaa                	ld	s5,168(sp)
ffffffffc0200c94:	7b4a                	ld	s6,176(sp)
ffffffffc0200c96:	7bea                	ld	s7,184(sp)
ffffffffc0200c98:	6c0e                	ld	s8,192(sp)
ffffffffc0200c9a:	6cae                	ld	s9,200(sp)
ffffffffc0200c9c:	6d4e                	ld	s10,208(sp)
ffffffffc0200c9e:	6dee                	ld	s11,216(sp)
ffffffffc0200ca0:	7e0e                	ld	t3,224(sp)
ffffffffc0200ca2:	7eae                	ld	t4,232(sp)
ffffffffc0200ca4:	7f4e                	ld	t5,240(sp)
ffffffffc0200ca6:	7fee                	ld	t6,248(sp)
ffffffffc0200ca8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200caa:	10200073          	sret

ffffffffc0200cae <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200cae:	100027f3          	csrr	a5,sstatus
ffffffffc0200cb2:	8b89                	andi	a5,a5,2
ffffffffc0200cb4:	e799                	bnez	a5,ffffffffc0200cc2 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200cb6:	00006797          	auipc	a5,0x6
ffffffffc0200cba:	7c27b783          	ld	a5,1986(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200cbe:	6f9c                	ld	a5,24(a5)
ffffffffc0200cc0:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200cc2:	1141                	addi	sp,sp,-16
ffffffffc0200cc4:	e406                	sd	ra,8(sp)
ffffffffc0200cc6:	e022                	sd	s0,0(sp)
ffffffffc0200cc8:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200cca:	b8bff0ef          	jal	ra,ffffffffc0200854 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200cce:	00006797          	auipc	a5,0x6
ffffffffc0200cd2:	7aa7b783          	ld	a5,1962(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200cd6:	6f9c                	ld	a5,24(a5)
ffffffffc0200cd8:	8522                	mv	a0,s0
ffffffffc0200cda:	9782                	jalr	a5
ffffffffc0200cdc:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200cde:	b71ff0ef          	jal	ra,ffffffffc020084e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200ce2:	60a2                	ld	ra,8(sp)
ffffffffc0200ce4:	8522                	mv	a0,s0
ffffffffc0200ce6:	6402                	ld	s0,0(sp)
ffffffffc0200ce8:	0141                	addi	sp,sp,16
ffffffffc0200cea:	8082                	ret

ffffffffc0200cec <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200cec:	100027f3          	csrr	a5,sstatus
ffffffffc0200cf0:	8b89                	andi	a5,a5,2
ffffffffc0200cf2:	e799                	bnez	a5,ffffffffc0200d00 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200cf4:	00006797          	auipc	a5,0x6
ffffffffc0200cf8:	7847b783          	ld	a5,1924(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200cfc:	739c                	ld	a5,32(a5)
ffffffffc0200cfe:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200d00:	1101                	addi	sp,sp,-32
ffffffffc0200d02:	ec06                	sd	ra,24(sp)
ffffffffc0200d04:	e822                	sd	s0,16(sp)
ffffffffc0200d06:	e426                	sd	s1,8(sp)
ffffffffc0200d08:	842a                	mv	s0,a0
ffffffffc0200d0a:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200d0c:	b49ff0ef          	jal	ra,ffffffffc0200854 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200d10:	00006797          	auipc	a5,0x6
ffffffffc0200d14:	7687b783          	ld	a5,1896(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200d18:	739c                	ld	a5,32(a5)
ffffffffc0200d1a:	85a6                	mv	a1,s1
ffffffffc0200d1c:	8522                	mv	a0,s0
ffffffffc0200d1e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200d20:	6442                	ld	s0,16(sp)
ffffffffc0200d22:	60e2                	ld	ra,24(sp)
ffffffffc0200d24:	64a2                	ld	s1,8(sp)
ffffffffc0200d26:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200d28:	b61d                	j	ffffffffc020084e <intr_enable>

ffffffffc0200d2a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200d2a:	100027f3          	csrr	a5,sstatus
ffffffffc0200d2e:	8b89                	andi	a5,a5,2
ffffffffc0200d30:	e799                	bnez	a5,ffffffffc0200d3e <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200d32:	00006797          	auipc	a5,0x6
ffffffffc0200d36:	7467b783          	ld	a5,1862(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200d3a:	779c                	ld	a5,40(a5)
ffffffffc0200d3c:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200d3e:	1141                	addi	sp,sp,-16
ffffffffc0200d40:	e406                	sd	ra,8(sp)
ffffffffc0200d42:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200d44:	b11ff0ef          	jal	ra,ffffffffc0200854 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200d48:	00006797          	auipc	a5,0x6
ffffffffc0200d4c:	7307b783          	ld	a5,1840(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200d50:	779c                	ld	a5,40(a5)
ffffffffc0200d52:	9782                	jalr	a5
ffffffffc0200d54:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200d56:	af9ff0ef          	jal	ra,ffffffffc020084e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200d5a:	60a2                	ld	ra,8(sp)
ffffffffc0200d5c:	8522                	mv	a0,s0
ffffffffc0200d5e:	6402                	ld	s0,0(sp)
ffffffffc0200d60:	0141                	addi	sp,sp,16
ffffffffc0200d62:	8082                	ret

ffffffffc0200d64 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0200d64:	00002797          	auipc	a5,0x2
ffffffffc0200d68:	0f478793          	addi	a5,a5,244 # ffffffffc0202e58 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d6c:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200d6e:	7179                	addi	sp,sp,-48
ffffffffc0200d70:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d72:	00002517          	auipc	a0,0x2
ffffffffc0200d76:	bde50513          	addi	a0,a0,-1058 # ffffffffc0202950 <commands+0x6d0>
    pmm_manager = &default_pmm_manager;
ffffffffc0200d7a:	00006417          	auipc	s0,0x6
ffffffffc0200d7e:	6fe40413          	addi	s0,s0,1790 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc0200d82:	f406                	sd	ra,40(sp)
ffffffffc0200d84:	ec26                	sd	s1,24(sp)
ffffffffc0200d86:	e44e                	sd	s3,8(sp)
ffffffffc0200d88:	e84a                	sd	s2,16(sp)
ffffffffc0200d8a:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200d8c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d8e:	b68ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    pmm_manager->init();
ffffffffc0200d92:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200d94:	00006497          	auipc	s1,0x6
ffffffffc0200d98:	6fc48493          	addi	s1,s1,1788 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200d9c:	679c                	ld	a5,8(a5)
ffffffffc0200d9e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200da0:	57f5                	li	a5,-3
ffffffffc0200da2:	07fa                	slli	a5,a5,0x1e
ffffffffc0200da4:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200da6:	a43ff0ef          	jal	ra,ffffffffc02007e8 <get_memory_base>
ffffffffc0200daa:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200dac:	a47ff0ef          	jal	ra,ffffffffc02007f2 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200db0:	16050163          	beqz	a0,ffffffffc0200f12 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200db4:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200db6:	00002517          	auipc	a0,0x2
ffffffffc0200dba:	be250513          	addi	a0,a0,-1054 # ffffffffc0202998 <commands+0x718>
ffffffffc0200dbe:	b38ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200dc2:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200dc6:	864e                	mv	a2,s3
ffffffffc0200dc8:	fffa0693          	addi	a3,s4,-1
ffffffffc0200dcc:	85ca                	mv	a1,s2
ffffffffc0200dce:	00002517          	auipc	a0,0x2
ffffffffc0200dd2:	be250513          	addi	a0,a0,-1054 # ffffffffc02029b0 <commands+0x730>
ffffffffc0200dd6:	b20ff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200dda:	c80007b7          	lui	a5,0xc8000
ffffffffc0200dde:	8652                	mv	a2,s4
ffffffffc0200de0:	0d47e863          	bltu	a5,s4,ffffffffc0200eb0 <pmm_init+0x14c>
ffffffffc0200de4:	00007797          	auipc	a5,0x7
ffffffffc0200de8:	6bb78793          	addi	a5,a5,1723 # ffffffffc020849f <end+0xfff>
ffffffffc0200dec:	757d                	lui	a0,0xfffff
ffffffffc0200dee:	8d7d                	and	a0,a0,a5
ffffffffc0200df0:	8231                	srli	a2,a2,0xc
ffffffffc0200df2:	00006597          	auipc	a1,0x6
ffffffffc0200df6:	67658593          	addi	a1,a1,1654 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200dfa:	00006817          	auipc	a6,0x6
ffffffffc0200dfe:	67680813          	addi	a6,a6,1654 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200e02:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e04:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e08:	000807b7          	lui	a5,0x80
ffffffffc0200e0c:	02f60663          	beq	a2,a5,ffffffffc0200e38 <pmm_init+0xd4>
ffffffffc0200e10:	4701                	li	a4,0
ffffffffc0200e12:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200e14:	4305                	li	t1,1
ffffffffc0200e16:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0200e1a:	953a                	add	a0,a0,a4
ffffffffc0200e1c:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc0200e20:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e24:	6190                	ld	a2,0(a1)
ffffffffc0200e26:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0200e28:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e2c:	011606b3          	add	a3,a2,a7
ffffffffc0200e30:	02870713          	addi	a4,a4,40
ffffffffc0200e34:	fed7e3e3          	bltu	a5,a3,ffffffffc0200e1a <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e38:	00261693          	slli	a3,a2,0x2
ffffffffc0200e3c:	96b2                	add	a3,a3,a2
ffffffffc0200e3e:	fec007b7          	lui	a5,0xfec00
ffffffffc0200e42:	97aa                	add	a5,a5,a0
ffffffffc0200e44:	068e                	slli	a3,a3,0x3
ffffffffc0200e46:	96be                	add	a3,a3,a5
ffffffffc0200e48:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e4c:	0af6e763          	bltu	a3,a5,ffffffffc0200efa <pmm_init+0x196>
ffffffffc0200e50:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200e52:	77fd                	lui	a5,0xfffff
ffffffffc0200e54:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e58:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200e5a:	04b6ee63          	bltu	a3,a1,ffffffffc0200eb6 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200e5e:	601c                	ld	a5,0(s0)
ffffffffc0200e60:	7b9c                	ld	a5,48(a5)
ffffffffc0200e62:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200e64:	00002517          	auipc	a0,0x2
ffffffffc0200e68:	bd450513          	addi	a0,a0,-1068 # ffffffffc0202a38 <commands+0x7b8>
ffffffffc0200e6c:	a8aff0ef          	jal	ra,ffffffffc02000f6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200e70:	00005597          	auipc	a1,0x5
ffffffffc0200e74:	19058593          	addi	a1,a1,400 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0200e78:	00006797          	auipc	a5,0x6
ffffffffc0200e7c:	60b7b823          	sd	a1,1552(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e80:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e84:	0af5e363          	bltu	a1,a5,ffffffffc0200f2a <pmm_init+0x1c6>
ffffffffc0200e88:	6090                	ld	a2,0(s1)
}
ffffffffc0200e8a:	7402                	ld	s0,32(sp)
ffffffffc0200e8c:	70a2                	ld	ra,40(sp)
ffffffffc0200e8e:	64e2                	ld	s1,24(sp)
ffffffffc0200e90:	6942                	ld	s2,16(sp)
ffffffffc0200e92:	69a2                	ld	s3,8(sp)
ffffffffc0200e94:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e96:	40c58633          	sub	a2,a1,a2
ffffffffc0200e9a:	00006797          	auipc	a5,0x6
ffffffffc0200e9e:	5ec7b323          	sd	a2,1510(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200ea2:	00002517          	auipc	a0,0x2
ffffffffc0200ea6:	bb650513          	addi	a0,a0,-1098 # ffffffffc0202a58 <commands+0x7d8>
}
ffffffffc0200eaa:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200eac:	a4aff06f          	j	ffffffffc02000f6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200eb0:	c8000637          	lui	a2,0xc8000
ffffffffc0200eb4:	bf05                	j	ffffffffc0200de4 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200eb6:	6705                	lui	a4,0x1
ffffffffc0200eb8:	177d                	addi	a4,a4,-1
ffffffffc0200eba:	96ba                	add	a3,a3,a4
ffffffffc0200ebc:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200ebe:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200ec2:	02c7f063          	bgeu	a5,a2,ffffffffc0200ee2 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0200ec6:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200ec8:	fff80737          	lui	a4,0xfff80
ffffffffc0200ecc:	973e                	add	a4,a4,a5
ffffffffc0200ece:	00271793          	slli	a5,a4,0x2
ffffffffc0200ed2:	97ba                	add	a5,a5,a4
ffffffffc0200ed4:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200ed6:	8d95                	sub	a1,a1,a3
ffffffffc0200ed8:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200eda:	81b1                	srli	a1,a1,0xc
ffffffffc0200edc:	953e                	add	a0,a0,a5
ffffffffc0200ede:	9702                	jalr	a4
}
ffffffffc0200ee0:	bfbd                	j	ffffffffc0200e5e <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0200ee2:	00002617          	auipc	a2,0x2
ffffffffc0200ee6:	b2660613          	addi	a2,a2,-1242 # ffffffffc0202a08 <commands+0x788>
ffffffffc0200eea:	06b00593          	li	a1,107
ffffffffc0200eee:	00002517          	auipc	a0,0x2
ffffffffc0200ef2:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202a28 <commands+0x7a8>
ffffffffc0200ef6:	a88ff0ef          	jal	ra,ffffffffc020017e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200efa:	00002617          	auipc	a2,0x2
ffffffffc0200efe:	ae660613          	addi	a2,a2,-1306 # ffffffffc02029e0 <commands+0x760>
ffffffffc0200f02:	07100593          	li	a1,113
ffffffffc0200f06:	00002517          	auipc	a0,0x2
ffffffffc0200f0a:	a8250513          	addi	a0,a0,-1406 # ffffffffc0202988 <commands+0x708>
ffffffffc0200f0e:	a70ff0ef          	jal	ra,ffffffffc020017e <__panic>
        panic("DTB memory info not available");
ffffffffc0200f12:	00002617          	auipc	a2,0x2
ffffffffc0200f16:	a5660613          	addi	a2,a2,-1450 # ffffffffc0202968 <commands+0x6e8>
ffffffffc0200f1a:	05a00593          	li	a1,90
ffffffffc0200f1e:	00002517          	auipc	a0,0x2
ffffffffc0200f22:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0202988 <commands+0x708>
ffffffffc0200f26:	a58ff0ef          	jal	ra,ffffffffc020017e <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f2a:	86ae                	mv	a3,a1
ffffffffc0200f2c:	00002617          	auipc	a2,0x2
ffffffffc0200f30:	ab460613          	addi	a2,a2,-1356 # ffffffffc02029e0 <commands+0x760>
ffffffffc0200f34:	08c00593          	li	a1,140
ffffffffc0200f38:	00002517          	auipc	a0,0x2
ffffffffc0200f3c:	a5050513          	addi	a0,a0,-1456 # ffffffffc0202988 <commands+0x708>
ffffffffc0200f40:	a3eff0ef          	jal	ra,ffffffffc020017e <__panic>

ffffffffc0200f44 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f44:	00006797          	auipc	a5,0x6
ffffffffc0200f48:	0e478793          	addi	a5,a5,228 # ffffffffc0207028 <free_area>
ffffffffc0200f4c:	e79c                	sd	a5,8(a5)
ffffffffc0200f4e:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f50:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f54:	8082                	ret

ffffffffc0200f56 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200f56:	00006517          	auipc	a0,0x6
ffffffffc0200f5a:	0e256503          	lwu	a0,226(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200f5e:	8082                	ret

ffffffffc0200f60 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200f60:	715d                	addi	sp,sp,-80
ffffffffc0200f62:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f64:	00006417          	auipc	s0,0x6
ffffffffc0200f68:	0c440413          	addi	s0,s0,196 # ffffffffc0207028 <free_area>
ffffffffc0200f6c:	641c                	ld	a5,8(s0)
ffffffffc0200f6e:	e486                	sd	ra,72(sp)
ffffffffc0200f70:	fc26                	sd	s1,56(sp)
ffffffffc0200f72:	f84a                	sd	s2,48(sp)
ffffffffc0200f74:	f44e                	sd	s3,40(sp)
ffffffffc0200f76:	f052                	sd	s4,32(sp)
ffffffffc0200f78:	ec56                	sd	s5,24(sp)
ffffffffc0200f7a:	e85a                	sd	s6,16(sp)
ffffffffc0200f7c:	e45e                	sd	s7,8(sp)
ffffffffc0200f7e:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f80:	2c878763          	beq	a5,s0,ffffffffc020124e <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200f84:	4481                	li	s1,0
ffffffffc0200f86:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f88:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f8c:	8b09                	andi	a4,a4,2
ffffffffc0200f8e:	2c070463          	beqz	a4,ffffffffc0201256 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200f92:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f96:	679c                	ld	a5,8(a5)
ffffffffc0200f98:	2905                	addiw	s2,s2,1
ffffffffc0200f9a:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f9c:	fe8796e3          	bne	a5,s0,ffffffffc0200f88 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200fa0:	89a6                	mv	s3,s1
ffffffffc0200fa2:	d89ff0ef          	jal	ra,ffffffffc0200d2a <nr_free_pages>
ffffffffc0200fa6:	71351863          	bne	a0,s3,ffffffffc02016b6 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200faa:	4505                	li	a0,1
ffffffffc0200fac:	d03ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc0200fb0:	8a2a                	mv	s4,a0
ffffffffc0200fb2:	44050263          	beqz	a0,ffffffffc02013f6 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fb6:	4505                	li	a0,1
ffffffffc0200fb8:	cf7ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc0200fbc:	89aa                	mv	s3,a0
ffffffffc0200fbe:	70050c63          	beqz	a0,ffffffffc02016d6 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fc2:	4505                	li	a0,1
ffffffffc0200fc4:	cebff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc0200fc8:	8aaa                	mv	s5,a0
ffffffffc0200fca:	4a050663          	beqz	a0,ffffffffc0201476 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200fce:	2b3a0463          	beq	s4,s3,ffffffffc0201276 <default_check+0x316>
ffffffffc0200fd2:	2aaa0263          	beq	s4,a0,ffffffffc0201276 <default_check+0x316>
ffffffffc0200fd6:	2aa98063          	beq	s3,a0,ffffffffc0201276 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200fda:	000a2783          	lw	a5,0(s4)
ffffffffc0200fde:	2a079c63          	bnez	a5,ffffffffc0201296 <default_check+0x336>
ffffffffc0200fe2:	0009a783          	lw	a5,0(s3)
ffffffffc0200fe6:	2a079863          	bnez	a5,ffffffffc0201296 <default_check+0x336>
ffffffffc0200fea:	411c                	lw	a5,0(a0)
ffffffffc0200fec:	2a079563          	bnez	a5,ffffffffc0201296 <default_check+0x336>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ff0:	00006797          	auipc	a5,0x6
ffffffffc0200ff4:	4807b783          	ld	a5,1152(a5) # ffffffffc0207470 <pages>
ffffffffc0200ff8:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ffc:	870d                	srai	a4,a4,0x3
ffffffffc0200ffe:	00002597          	auipc	a1,0x2
ffffffffc0201002:	0e25b583          	ld	a1,226(a1) # ffffffffc02030e0 <nbase+0x8>
ffffffffc0201006:	02b70733          	mul	a4,a4,a1
ffffffffc020100a:	00002617          	auipc	a2,0x2
ffffffffc020100e:	0ce63603          	ld	a2,206(a2) # ffffffffc02030d8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201012:	00006697          	auipc	a3,0x6
ffffffffc0201016:	4566b683          	ld	a3,1110(a3) # ffffffffc0207468 <npage>
ffffffffc020101a:	06b2                	slli	a3,a3,0xc
ffffffffc020101c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020101e:	0732                	slli	a4,a4,0xc
ffffffffc0201020:	28d77b63          	bgeu	a4,a3,ffffffffc02012b6 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201024:	40f98733          	sub	a4,s3,a5
ffffffffc0201028:	870d                	srai	a4,a4,0x3
ffffffffc020102a:	02b70733          	mul	a4,a4,a1
ffffffffc020102e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201030:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201032:	4cd77263          	bgeu	a4,a3,ffffffffc02014f6 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201036:	40f507b3          	sub	a5,a0,a5
ffffffffc020103a:	878d                	srai	a5,a5,0x3
ffffffffc020103c:	02b787b3          	mul	a5,a5,a1
ffffffffc0201040:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201042:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201044:	30d7f963          	bgeu	a5,a3,ffffffffc0201356 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0201048:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104a:	00043c03          	ld	s8,0(s0)
ffffffffc020104e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201052:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201056:	e400                	sd	s0,8(s0)
ffffffffc0201058:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020105a:	00006797          	auipc	a5,0x6
ffffffffc020105e:	fc07af23          	sw	zero,-34(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201062:	c4dff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc0201066:	2c051863          	bnez	a0,ffffffffc0201336 <default_check+0x3d6>
    free_page(p0);
ffffffffc020106a:	4585                	li	a1,1
ffffffffc020106c:	8552                	mv	a0,s4
ffffffffc020106e:	c7fff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    free_page(p1);
ffffffffc0201072:	4585                	li	a1,1
ffffffffc0201074:	854e                	mv	a0,s3
ffffffffc0201076:	c77ff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    free_page(p2);
ffffffffc020107a:	4585                	li	a1,1
ffffffffc020107c:	8556                	mv	a0,s5
ffffffffc020107e:	c6fff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    assert(nr_free == 3);
ffffffffc0201082:	4818                	lw	a4,16(s0)
ffffffffc0201084:	478d                	li	a5,3
ffffffffc0201086:	28f71863          	bne	a4,a5,ffffffffc0201316 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020108a:	4505                	li	a0,1
ffffffffc020108c:	c23ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc0201090:	89aa                	mv	s3,a0
ffffffffc0201092:	26050263          	beqz	a0,ffffffffc02012f6 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201096:	4505                	li	a0,1
ffffffffc0201098:	c17ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc020109c:	8aaa                	mv	s5,a0
ffffffffc020109e:	3a050c63          	beqz	a0,ffffffffc0201456 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010a2:	4505                	li	a0,1
ffffffffc02010a4:	c0bff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02010a8:	8a2a                	mv	s4,a0
ffffffffc02010aa:	38050663          	beqz	a0,ffffffffc0201436 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc02010ae:	4505                	li	a0,1
ffffffffc02010b0:	bffff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02010b4:	36051163          	bnez	a0,ffffffffc0201416 <default_check+0x4b6>
    free_page(p0);
ffffffffc02010b8:	4585                	li	a1,1
ffffffffc02010ba:	854e                	mv	a0,s3
ffffffffc02010bc:	c31ff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02010c0:	641c                	ld	a5,8(s0)
ffffffffc02010c2:	20878a63          	beq	a5,s0,ffffffffc02012d6 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc02010c6:	4505                	li	a0,1
ffffffffc02010c8:	be7ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02010cc:	30a99563          	bne	s3,a0,ffffffffc02013d6 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc02010d0:	4505                	li	a0,1
ffffffffc02010d2:	bddff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02010d6:	2e051063          	bnez	a0,ffffffffc02013b6 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc02010da:	481c                	lw	a5,16(s0)
ffffffffc02010dc:	2a079d63          	bnez	a5,ffffffffc0201396 <default_check+0x436>
    free_page(p);
ffffffffc02010e0:	854e                	mv	a0,s3
ffffffffc02010e2:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02010e4:	01843023          	sd	s8,0(s0)
ffffffffc02010e8:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02010ec:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02010f0:	bfdff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    free_page(p1);
ffffffffc02010f4:	4585                	li	a1,1
ffffffffc02010f6:	8556                	mv	a0,s5
ffffffffc02010f8:	bf5ff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    free_page(p2);
ffffffffc02010fc:	4585                	li	a1,1
ffffffffc02010fe:	8552                	mv	a0,s4
ffffffffc0201100:	bedff0ef          	jal	ra,ffffffffc0200cec <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201104:	4515                	li	a0,5
ffffffffc0201106:	ba9ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc020110a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020110c:	26050563          	beqz	a0,ffffffffc0201376 <default_check+0x416>
ffffffffc0201110:	651c                	ld	a5,8(a0)
ffffffffc0201112:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0201114:	8b85                	andi	a5,a5,1
ffffffffc0201116:	54079063          	bnez	a5,ffffffffc0201656 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020111a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020111c:	00043b03          	ld	s6,0(s0)
ffffffffc0201120:	00843a83          	ld	s5,8(s0)
ffffffffc0201124:	e000                	sd	s0,0(s0)
ffffffffc0201126:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201128:	b87ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc020112c:	50051563          	bnez	a0,ffffffffc0201636 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201130:	05098a13          	addi	s4,s3,80
ffffffffc0201134:	8552                	mv	a0,s4
ffffffffc0201136:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201138:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020113c:	00006797          	auipc	a5,0x6
ffffffffc0201140:	ee07ae23          	sw	zero,-260(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201144:	ba9ff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201148:	4511                	li	a0,4
ffffffffc020114a:	b65ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc020114e:	4c051463          	bnez	a0,ffffffffc0201616 <default_check+0x6b6>
ffffffffc0201152:	0589b783          	ld	a5,88(s3)
ffffffffc0201156:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201158:	8b85                	andi	a5,a5,1
ffffffffc020115a:	48078e63          	beqz	a5,ffffffffc02015f6 <default_check+0x696>
ffffffffc020115e:	0609a703          	lw	a4,96(s3)
ffffffffc0201162:	478d                	li	a5,3
ffffffffc0201164:	48f71963          	bne	a4,a5,ffffffffc02015f6 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201168:	450d                	li	a0,3
ffffffffc020116a:	b45ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc020116e:	8c2a                	mv	s8,a0
ffffffffc0201170:	46050363          	beqz	a0,ffffffffc02015d6 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0201174:	4505                	li	a0,1
ffffffffc0201176:	b39ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc020117a:	42051e63          	bnez	a0,ffffffffc02015b6 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc020117e:	418a1c63          	bne	s4,s8,ffffffffc0201596 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201182:	4585                	li	a1,1
ffffffffc0201184:	854e                	mv	a0,s3
ffffffffc0201186:	b67ff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    free_pages(p1, 3);
ffffffffc020118a:	458d                	li	a1,3
ffffffffc020118c:	8552                	mv	a0,s4
ffffffffc020118e:	b5fff0ef          	jal	ra,ffffffffc0200cec <free_pages>
ffffffffc0201192:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201196:	02898c13          	addi	s8,s3,40
ffffffffc020119a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020119c:	8b85                	andi	a5,a5,1
ffffffffc020119e:	3c078c63          	beqz	a5,ffffffffc0201576 <default_check+0x616>
ffffffffc02011a2:	0109a703          	lw	a4,16(s3)
ffffffffc02011a6:	4785                	li	a5,1
ffffffffc02011a8:	3cf71763          	bne	a4,a5,ffffffffc0201576 <default_check+0x616>
ffffffffc02011ac:	008a3783          	ld	a5,8(s4)
ffffffffc02011b0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011b2:	8b85                	andi	a5,a5,1
ffffffffc02011b4:	3a078163          	beqz	a5,ffffffffc0201556 <default_check+0x5f6>
ffffffffc02011b8:	010a2703          	lw	a4,16(s4)
ffffffffc02011bc:	478d                	li	a5,3
ffffffffc02011be:	38f71c63          	bne	a4,a5,ffffffffc0201556 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011c2:	4505                	li	a0,1
ffffffffc02011c4:	aebff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02011c8:	36a99763          	bne	s3,a0,ffffffffc0201536 <default_check+0x5d6>
    free_page(p0);
ffffffffc02011cc:	4585                	li	a1,1
ffffffffc02011ce:	b1fff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011d2:	4509                	li	a0,2
ffffffffc02011d4:	adbff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02011d8:	32aa1f63          	bne	s4,a0,ffffffffc0201516 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc02011dc:	4589                	li	a1,2
ffffffffc02011de:	b0fff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    free_page(p2);
ffffffffc02011e2:	4585                	li	a1,1
ffffffffc02011e4:	8562                	mv	a0,s8
ffffffffc02011e6:	b07ff0ef          	jal	ra,ffffffffc0200cec <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02011ea:	4515                	li	a0,5
ffffffffc02011ec:	ac3ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02011f0:	89aa                	mv	s3,a0
ffffffffc02011f2:	48050263          	beqz	a0,ffffffffc0201676 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc02011f6:	4505                	li	a0,1
ffffffffc02011f8:	ab7ff0ef          	jal	ra,ffffffffc0200cae <alloc_pages>
ffffffffc02011fc:	2c051d63          	bnez	a0,ffffffffc02014d6 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0201200:	481c                	lw	a5,16(s0)
ffffffffc0201202:	2a079a63          	bnez	a5,ffffffffc02014b6 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201206:	4595                	li	a1,5
ffffffffc0201208:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020120a:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020120e:	01643023          	sd	s6,0(s0)
ffffffffc0201212:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201216:	ad7ff0ef          	jal	ra,ffffffffc0200cec <free_pages>
    return listelm->next;
ffffffffc020121a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020121c:	00878963          	beq	a5,s0,ffffffffc020122e <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201220:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201224:	679c                	ld	a5,8(a5)
ffffffffc0201226:	397d                	addiw	s2,s2,-1
ffffffffc0201228:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020122a:	fe879be3          	bne	a5,s0,ffffffffc0201220 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc020122e:	26091463          	bnez	s2,ffffffffc0201496 <default_check+0x536>
    assert(total == 0);
ffffffffc0201232:	46049263          	bnez	s1,ffffffffc0201696 <default_check+0x736>
}
ffffffffc0201236:	60a6                	ld	ra,72(sp)
ffffffffc0201238:	6406                	ld	s0,64(sp)
ffffffffc020123a:	74e2                	ld	s1,56(sp)
ffffffffc020123c:	7942                	ld	s2,48(sp)
ffffffffc020123e:	79a2                	ld	s3,40(sp)
ffffffffc0201240:	7a02                	ld	s4,32(sp)
ffffffffc0201242:	6ae2                	ld	s5,24(sp)
ffffffffc0201244:	6b42                	ld	s6,16(sp)
ffffffffc0201246:	6ba2                	ld	s7,8(sp)
ffffffffc0201248:	6c02                	ld	s8,0(sp)
ffffffffc020124a:	6161                	addi	sp,sp,80
ffffffffc020124c:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020124e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201250:	4481                	li	s1,0
ffffffffc0201252:	4901                	li	s2,0
ffffffffc0201254:	b3b9                	j	ffffffffc0200fa2 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201256:	00002697          	auipc	a3,0x2
ffffffffc020125a:	84268693          	addi	a3,a3,-1982 # ffffffffc0202a98 <commands+0x818>
ffffffffc020125e:	00002617          	auipc	a2,0x2
ffffffffc0201262:	84a60613          	addi	a2,a2,-1974 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201266:	0f000593          	li	a1,240
ffffffffc020126a:	00002517          	auipc	a0,0x2
ffffffffc020126e:	85650513          	addi	a0,a0,-1962 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201272:	f0dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201276:	00002697          	auipc	a3,0x2
ffffffffc020127a:	8e268693          	addi	a3,a3,-1822 # ffffffffc0202b58 <commands+0x8d8>
ffffffffc020127e:	00002617          	auipc	a2,0x2
ffffffffc0201282:	82a60613          	addi	a2,a2,-2006 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201286:	0bd00593          	li	a1,189
ffffffffc020128a:	00002517          	auipc	a0,0x2
ffffffffc020128e:	83650513          	addi	a0,a0,-1994 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201292:	eedfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201296:	00002697          	auipc	a3,0x2
ffffffffc020129a:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0202b80 <commands+0x900>
ffffffffc020129e:	00002617          	auipc	a2,0x2
ffffffffc02012a2:	80a60613          	addi	a2,a2,-2038 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02012a6:	0be00593          	li	a1,190
ffffffffc02012aa:	00002517          	auipc	a0,0x2
ffffffffc02012ae:	81650513          	addi	a0,a0,-2026 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02012b2:	ecdfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012b6:	00002697          	auipc	a3,0x2
ffffffffc02012ba:	90a68693          	addi	a3,a3,-1782 # ffffffffc0202bc0 <commands+0x940>
ffffffffc02012be:	00001617          	auipc	a2,0x1
ffffffffc02012c2:	7ea60613          	addi	a2,a2,2026 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02012c6:	0c000593          	li	a1,192
ffffffffc02012ca:	00001517          	auipc	a0,0x1
ffffffffc02012ce:	7f650513          	addi	a0,a0,2038 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02012d2:	eadfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012d6:	00002697          	auipc	a3,0x2
ffffffffc02012da:	97268693          	addi	a3,a3,-1678 # ffffffffc0202c48 <commands+0x9c8>
ffffffffc02012de:	00001617          	auipc	a2,0x1
ffffffffc02012e2:	7ca60613          	addi	a2,a2,1994 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02012e6:	0d900593          	li	a1,217
ffffffffc02012ea:	00001517          	auipc	a0,0x1
ffffffffc02012ee:	7d650513          	addi	a0,a0,2006 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02012f2:	e8dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012f6:	00002697          	auipc	a3,0x2
ffffffffc02012fa:	80268693          	addi	a3,a3,-2046 # ffffffffc0202af8 <commands+0x878>
ffffffffc02012fe:	00001617          	auipc	a2,0x1
ffffffffc0201302:	7aa60613          	addi	a2,a2,1962 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201306:	0d200593          	li	a1,210
ffffffffc020130a:	00001517          	auipc	a0,0x1
ffffffffc020130e:	7b650513          	addi	a0,a0,1974 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201312:	e6dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(nr_free == 3);
ffffffffc0201316:	00002697          	auipc	a3,0x2
ffffffffc020131a:	92268693          	addi	a3,a3,-1758 # ffffffffc0202c38 <commands+0x9b8>
ffffffffc020131e:	00001617          	auipc	a2,0x1
ffffffffc0201322:	78a60613          	addi	a2,a2,1930 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201326:	0d000593          	li	a1,208
ffffffffc020132a:	00001517          	auipc	a0,0x1
ffffffffc020132e:	79650513          	addi	a0,a0,1942 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201332:	e4dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201336:	00002697          	auipc	a3,0x2
ffffffffc020133a:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0202c20 <commands+0x9a0>
ffffffffc020133e:	00001617          	auipc	a2,0x1
ffffffffc0201342:	76a60613          	addi	a2,a2,1898 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201346:	0cb00593          	li	a1,203
ffffffffc020134a:	00001517          	auipc	a0,0x1
ffffffffc020134e:	77650513          	addi	a0,a0,1910 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201352:	e2dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201356:	00002697          	auipc	a3,0x2
ffffffffc020135a:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0202c00 <commands+0x980>
ffffffffc020135e:	00001617          	auipc	a2,0x1
ffffffffc0201362:	74a60613          	addi	a2,a2,1866 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201366:	0c200593          	li	a1,194
ffffffffc020136a:	00001517          	auipc	a0,0x1
ffffffffc020136e:	75650513          	addi	a0,a0,1878 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201372:	e0dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(p0 != NULL);
ffffffffc0201376:	00002697          	auipc	a3,0x2
ffffffffc020137a:	91a68693          	addi	a3,a3,-1766 # ffffffffc0202c90 <commands+0xa10>
ffffffffc020137e:	00001617          	auipc	a2,0x1
ffffffffc0201382:	72a60613          	addi	a2,a2,1834 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201386:	0f800593          	li	a1,248
ffffffffc020138a:	00001517          	auipc	a0,0x1
ffffffffc020138e:	73650513          	addi	a0,a0,1846 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201392:	dedfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(nr_free == 0);
ffffffffc0201396:	00002697          	auipc	a3,0x2
ffffffffc020139a:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0202c80 <commands+0xa00>
ffffffffc020139e:	00001617          	auipc	a2,0x1
ffffffffc02013a2:	70a60613          	addi	a2,a2,1802 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02013a6:	0df00593          	li	a1,223
ffffffffc02013aa:	00001517          	auipc	a0,0x1
ffffffffc02013ae:	71650513          	addi	a0,a0,1814 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02013b2:	dcdfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013b6:	00002697          	auipc	a3,0x2
ffffffffc02013ba:	86a68693          	addi	a3,a3,-1942 # ffffffffc0202c20 <commands+0x9a0>
ffffffffc02013be:	00001617          	auipc	a2,0x1
ffffffffc02013c2:	6ea60613          	addi	a2,a2,1770 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02013c6:	0dd00593          	li	a1,221
ffffffffc02013ca:	00001517          	auipc	a0,0x1
ffffffffc02013ce:	6f650513          	addi	a0,a0,1782 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02013d2:	dadfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02013d6:	00002697          	auipc	a3,0x2
ffffffffc02013da:	88a68693          	addi	a3,a3,-1910 # ffffffffc0202c60 <commands+0x9e0>
ffffffffc02013de:	00001617          	auipc	a2,0x1
ffffffffc02013e2:	6ca60613          	addi	a2,a2,1738 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02013e6:	0dc00593          	li	a1,220
ffffffffc02013ea:	00001517          	auipc	a0,0x1
ffffffffc02013ee:	6d650513          	addi	a0,a0,1750 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02013f2:	d8dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013f6:	00001697          	auipc	a3,0x1
ffffffffc02013fa:	70268693          	addi	a3,a3,1794 # ffffffffc0202af8 <commands+0x878>
ffffffffc02013fe:	00001617          	auipc	a2,0x1
ffffffffc0201402:	6aa60613          	addi	a2,a2,1706 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201406:	0b900593          	li	a1,185
ffffffffc020140a:	00001517          	auipc	a0,0x1
ffffffffc020140e:	6b650513          	addi	a0,a0,1718 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201412:	d6dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201416:	00002697          	auipc	a3,0x2
ffffffffc020141a:	80a68693          	addi	a3,a3,-2038 # ffffffffc0202c20 <commands+0x9a0>
ffffffffc020141e:	00001617          	auipc	a2,0x1
ffffffffc0201422:	68a60613          	addi	a2,a2,1674 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201426:	0d600593          	li	a1,214
ffffffffc020142a:	00001517          	auipc	a0,0x1
ffffffffc020142e:	69650513          	addi	a0,a0,1686 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201432:	d4dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201436:	00001697          	auipc	a3,0x1
ffffffffc020143a:	70268693          	addi	a3,a3,1794 # ffffffffc0202b38 <commands+0x8b8>
ffffffffc020143e:	00001617          	auipc	a2,0x1
ffffffffc0201442:	66a60613          	addi	a2,a2,1642 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201446:	0d400593          	li	a1,212
ffffffffc020144a:	00001517          	auipc	a0,0x1
ffffffffc020144e:	67650513          	addi	a0,a0,1654 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201452:	d2dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201456:	00001697          	auipc	a3,0x1
ffffffffc020145a:	6c268693          	addi	a3,a3,1730 # ffffffffc0202b18 <commands+0x898>
ffffffffc020145e:	00001617          	auipc	a2,0x1
ffffffffc0201462:	64a60613          	addi	a2,a2,1610 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201466:	0d300593          	li	a1,211
ffffffffc020146a:	00001517          	auipc	a0,0x1
ffffffffc020146e:	65650513          	addi	a0,a0,1622 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201472:	d0dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201476:	00001697          	auipc	a3,0x1
ffffffffc020147a:	6c268693          	addi	a3,a3,1730 # ffffffffc0202b38 <commands+0x8b8>
ffffffffc020147e:	00001617          	auipc	a2,0x1
ffffffffc0201482:	62a60613          	addi	a2,a2,1578 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201486:	0bb00593          	li	a1,187
ffffffffc020148a:	00001517          	auipc	a0,0x1
ffffffffc020148e:	63650513          	addi	a0,a0,1590 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201492:	cedfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(count == 0);
ffffffffc0201496:	00002697          	auipc	a3,0x2
ffffffffc020149a:	94a68693          	addi	a3,a3,-1718 # ffffffffc0202de0 <commands+0xb60>
ffffffffc020149e:	00001617          	auipc	a2,0x1
ffffffffc02014a2:	60a60613          	addi	a2,a2,1546 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02014a6:	12500593          	li	a1,293
ffffffffc02014aa:	00001517          	auipc	a0,0x1
ffffffffc02014ae:	61650513          	addi	a0,a0,1558 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02014b2:	ccdfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(nr_free == 0);
ffffffffc02014b6:	00001697          	auipc	a3,0x1
ffffffffc02014ba:	7ca68693          	addi	a3,a3,1994 # ffffffffc0202c80 <commands+0xa00>
ffffffffc02014be:	00001617          	auipc	a2,0x1
ffffffffc02014c2:	5ea60613          	addi	a2,a2,1514 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02014c6:	11a00593          	li	a1,282
ffffffffc02014ca:	00001517          	auipc	a0,0x1
ffffffffc02014ce:	5f650513          	addi	a0,a0,1526 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02014d2:	cadfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014d6:	00001697          	auipc	a3,0x1
ffffffffc02014da:	74a68693          	addi	a3,a3,1866 # ffffffffc0202c20 <commands+0x9a0>
ffffffffc02014de:	00001617          	auipc	a2,0x1
ffffffffc02014e2:	5ca60613          	addi	a2,a2,1482 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02014e6:	11800593          	li	a1,280
ffffffffc02014ea:	00001517          	auipc	a0,0x1
ffffffffc02014ee:	5d650513          	addi	a0,a0,1494 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02014f2:	c8dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02014f6:	00001697          	auipc	a3,0x1
ffffffffc02014fa:	6ea68693          	addi	a3,a3,1770 # ffffffffc0202be0 <commands+0x960>
ffffffffc02014fe:	00001617          	auipc	a2,0x1
ffffffffc0201502:	5aa60613          	addi	a2,a2,1450 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201506:	0c100593          	li	a1,193
ffffffffc020150a:	00001517          	auipc	a0,0x1
ffffffffc020150e:	5b650513          	addi	a0,a0,1462 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201512:	c6dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201516:	00002697          	auipc	a3,0x2
ffffffffc020151a:	88a68693          	addi	a3,a3,-1910 # ffffffffc0202da0 <commands+0xb20>
ffffffffc020151e:	00001617          	auipc	a2,0x1
ffffffffc0201522:	58a60613          	addi	a2,a2,1418 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201526:	11200593          	li	a1,274
ffffffffc020152a:	00001517          	auipc	a0,0x1
ffffffffc020152e:	59650513          	addi	a0,a0,1430 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201532:	c4dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201536:	00002697          	auipc	a3,0x2
ffffffffc020153a:	84a68693          	addi	a3,a3,-1974 # ffffffffc0202d80 <commands+0xb00>
ffffffffc020153e:	00001617          	auipc	a2,0x1
ffffffffc0201542:	56a60613          	addi	a2,a2,1386 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201546:	11000593          	li	a1,272
ffffffffc020154a:	00001517          	auipc	a0,0x1
ffffffffc020154e:	57650513          	addi	a0,a0,1398 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201552:	c2dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201556:	00002697          	auipc	a3,0x2
ffffffffc020155a:	80268693          	addi	a3,a3,-2046 # ffffffffc0202d58 <commands+0xad8>
ffffffffc020155e:	00001617          	auipc	a2,0x1
ffffffffc0201562:	54a60613          	addi	a2,a2,1354 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201566:	10e00593          	li	a1,270
ffffffffc020156a:	00001517          	auipc	a0,0x1
ffffffffc020156e:	55650513          	addi	a0,a0,1366 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201572:	c0dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201576:	00001697          	auipc	a3,0x1
ffffffffc020157a:	7ba68693          	addi	a3,a3,1978 # ffffffffc0202d30 <commands+0xab0>
ffffffffc020157e:	00001617          	auipc	a2,0x1
ffffffffc0201582:	52a60613          	addi	a2,a2,1322 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201586:	10d00593          	li	a1,269
ffffffffc020158a:	00001517          	auipc	a0,0x1
ffffffffc020158e:	53650513          	addi	a0,a0,1334 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201592:	bedfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201596:	00001697          	auipc	a3,0x1
ffffffffc020159a:	78a68693          	addi	a3,a3,1930 # ffffffffc0202d20 <commands+0xaa0>
ffffffffc020159e:	00001617          	auipc	a2,0x1
ffffffffc02015a2:	50a60613          	addi	a2,a2,1290 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02015a6:	10800593          	li	a1,264
ffffffffc02015aa:	00001517          	auipc	a0,0x1
ffffffffc02015ae:	51650513          	addi	a0,a0,1302 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02015b2:	bcdfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015b6:	00001697          	auipc	a3,0x1
ffffffffc02015ba:	66a68693          	addi	a3,a3,1642 # ffffffffc0202c20 <commands+0x9a0>
ffffffffc02015be:	00001617          	auipc	a2,0x1
ffffffffc02015c2:	4ea60613          	addi	a2,a2,1258 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02015c6:	10700593          	li	a1,263
ffffffffc02015ca:	00001517          	auipc	a0,0x1
ffffffffc02015ce:	4f650513          	addi	a0,a0,1270 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02015d2:	badfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02015d6:	00001697          	auipc	a3,0x1
ffffffffc02015da:	72a68693          	addi	a3,a3,1834 # ffffffffc0202d00 <commands+0xa80>
ffffffffc02015de:	00001617          	auipc	a2,0x1
ffffffffc02015e2:	4ca60613          	addi	a2,a2,1226 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02015e6:	10600593          	li	a1,262
ffffffffc02015ea:	00001517          	auipc	a0,0x1
ffffffffc02015ee:	4d650513          	addi	a0,a0,1238 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02015f2:	b8dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02015f6:	00001697          	auipc	a3,0x1
ffffffffc02015fa:	6da68693          	addi	a3,a3,1754 # ffffffffc0202cd0 <commands+0xa50>
ffffffffc02015fe:	00001617          	auipc	a2,0x1
ffffffffc0201602:	4aa60613          	addi	a2,a2,1194 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201606:	10500593          	li	a1,261
ffffffffc020160a:	00001517          	auipc	a0,0x1
ffffffffc020160e:	4b650513          	addi	a0,a0,1206 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201612:	b6dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201616:	00001697          	auipc	a3,0x1
ffffffffc020161a:	6a268693          	addi	a3,a3,1698 # ffffffffc0202cb8 <commands+0xa38>
ffffffffc020161e:	00001617          	auipc	a2,0x1
ffffffffc0201622:	48a60613          	addi	a2,a2,1162 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201626:	10400593          	li	a1,260
ffffffffc020162a:	00001517          	auipc	a0,0x1
ffffffffc020162e:	49650513          	addi	a0,a0,1174 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201632:	b4dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201636:	00001697          	auipc	a3,0x1
ffffffffc020163a:	5ea68693          	addi	a3,a3,1514 # ffffffffc0202c20 <commands+0x9a0>
ffffffffc020163e:	00001617          	auipc	a2,0x1
ffffffffc0201642:	46a60613          	addi	a2,a2,1130 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201646:	0fe00593          	li	a1,254
ffffffffc020164a:	00001517          	auipc	a0,0x1
ffffffffc020164e:	47650513          	addi	a0,a0,1142 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201652:	b2dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201656:	00001697          	auipc	a3,0x1
ffffffffc020165a:	64a68693          	addi	a3,a3,1610 # ffffffffc0202ca0 <commands+0xa20>
ffffffffc020165e:	00001617          	auipc	a2,0x1
ffffffffc0201662:	44a60613          	addi	a2,a2,1098 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201666:	0f900593          	li	a1,249
ffffffffc020166a:	00001517          	auipc	a0,0x1
ffffffffc020166e:	45650513          	addi	a0,a0,1110 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201672:	b0dfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201676:	00001697          	auipc	a3,0x1
ffffffffc020167a:	74a68693          	addi	a3,a3,1866 # ffffffffc0202dc0 <commands+0xb40>
ffffffffc020167e:	00001617          	auipc	a2,0x1
ffffffffc0201682:	42a60613          	addi	a2,a2,1066 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201686:	11700593          	li	a1,279
ffffffffc020168a:	00001517          	auipc	a0,0x1
ffffffffc020168e:	43650513          	addi	a0,a0,1078 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201692:	aedfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(total == 0);
ffffffffc0201696:	00001697          	auipc	a3,0x1
ffffffffc020169a:	75a68693          	addi	a3,a3,1882 # ffffffffc0202df0 <commands+0xb70>
ffffffffc020169e:	00001617          	auipc	a2,0x1
ffffffffc02016a2:	40a60613          	addi	a2,a2,1034 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02016a6:	12600593          	li	a1,294
ffffffffc02016aa:	00001517          	auipc	a0,0x1
ffffffffc02016ae:	41650513          	addi	a0,a0,1046 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02016b2:	acdfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(total == nr_free_pages());
ffffffffc02016b6:	00001697          	auipc	a3,0x1
ffffffffc02016ba:	42268693          	addi	a3,a3,1058 # ffffffffc0202ad8 <commands+0x858>
ffffffffc02016be:	00001617          	auipc	a2,0x1
ffffffffc02016c2:	3ea60613          	addi	a2,a2,1002 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02016c6:	0f300593          	li	a1,243
ffffffffc02016ca:	00001517          	auipc	a0,0x1
ffffffffc02016ce:	3f650513          	addi	a0,a0,1014 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02016d2:	aadfe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02016d6:	00001697          	auipc	a3,0x1
ffffffffc02016da:	44268693          	addi	a3,a3,1090 # ffffffffc0202b18 <commands+0x898>
ffffffffc02016de:	00001617          	auipc	a2,0x1
ffffffffc02016e2:	3ca60613          	addi	a2,a2,970 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02016e6:	0ba00593          	li	a1,186
ffffffffc02016ea:	00001517          	auipc	a0,0x1
ffffffffc02016ee:	3d650513          	addi	a0,a0,982 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02016f2:	a8dfe0ef          	jal	ra,ffffffffc020017e <__panic>

ffffffffc02016f6 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02016f6:	1141                	addi	sp,sp,-16
ffffffffc02016f8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016fa:	14058a63          	beqz	a1,ffffffffc020184e <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02016fe:	00259693          	slli	a3,a1,0x2
ffffffffc0201702:	96ae                	add	a3,a3,a1
ffffffffc0201704:	068e                	slli	a3,a3,0x3
ffffffffc0201706:	96aa                	add	a3,a3,a0
ffffffffc0201708:	87aa                	mv	a5,a0
ffffffffc020170a:	02d50263          	beq	a0,a3,ffffffffc020172e <default_free_pages+0x38>
ffffffffc020170e:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201710:	8b05                	andi	a4,a4,1
ffffffffc0201712:	10071e63          	bnez	a4,ffffffffc020182e <default_free_pages+0x138>
ffffffffc0201716:	6798                	ld	a4,8(a5)
ffffffffc0201718:	8b09                	andi	a4,a4,2
ffffffffc020171a:	10071a63          	bnez	a4,ffffffffc020182e <default_free_pages+0x138>
        p->flags = 0;
ffffffffc020171e:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201722:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201726:	02878793          	addi	a5,a5,40
ffffffffc020172a:	fed792e3          	bne	a5,a3,ffffffffc020170e <default_free_pages+0x18>
    base->property = n;
ffffffffc020172e:	2581                	sext.w	a1,a1
ffffffffc0201730:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201732:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201736:	4789                	li	a5,2
ffffffffc0201738:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020173c:	00006697          	auipc	a3,0x6
ffffffffc0201740:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0207028 <free_area>
ffffffffc0201744:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201746:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201748:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020174c:	9db9                	addw	a1,a1,a4
ffffffffc020174e:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201750:	0ad78863          	beq	a5,a3,ffffffffc0201800 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201754:	fe878713          	addi	a4,a5,-24
ffffffffc0201758:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020175c:	4581                	li	a1,0
            if (base < page) {
ffffffffc020175e:	00e56a63          	bltu	a0,a4,ffffffffc0201772 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0201762:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201764:	06d70263          	beq	a4,a3,ffffffffc02017c8 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201768:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020176a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020176e:	fee57ae3          	bgeu	a0,a4,ffffffffc0201762 <default_free_pages+0x6c>
ffffffffc0201772:	c199                	beqz	a1,ffffffffc0201778 <default_free_pages+0x82>
ffffffffc0201774:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201778:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020177a:	e390                	sd	a2,0(a5)
ffffffffc020177c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020177e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201780:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201782:	02d70063          	beq	a4,a3,ffffffffc02017a2 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201786:	ff872803          	lw	a6,-8(a4) # fffffffffff7fff8 <end+0x3fd78b58>
        p = le2page(le, page_link);
ffffffffc020178a:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc020178e:	02081613          	slli	a2,a6,0x20
ffffffffc0201792:	9201                	srli	a2,a2,0x20
ffffffffc0201794:	00261793          	slli	a5,a2,0x2
ffffffffc0201798:	97b2                	add	a5,a5,a2
ffffffffc020179a:	078e                	slli	a5,a5,0x3
ffffffffc020179c:	97ae                	add	a5,a5,a1
ffffffffc020179e:	02f50f63          	beq	a0,a5,ffffffffc02017dc <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02017a2:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02017a4:	00d70f63          	beq	a4,a3,ffffffffc02017c2 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02017a8:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02017aa:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02017ae:	02059613          	slli	a2,a1,0x20
ffffffffc02017b2:	9201                	srli	a2,a2,0x20
ffffffffc02017b4:	00261793          	slli	a5,a2,0x2
ffffffffc02017b8:	97b2                	add	a5,a5,a2
ffffffffc02017ba:	078e                	slli	a5,a5,0x3
ffffffffc02017bc:	97aa                	add	a5,a5,a0
ffffffffc02017be:	04f68863          	beq	a3,a5,ffffffffc020180e <default_free_pages+0x118>
}
ffffffffc02017c2:	60a2                	ld	ra,8(sp)
ffffffffc02017c4:	0141                	addi	sp,sp,16
ffffffffc02017c6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017c8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017ca:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017cc:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017ce:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017d0:	02d70563          	beq	a4,a3,ffffffffc02017fa <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02017d4:	8832                	mv	a6,a2
ffffffffc02017d6:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02017d8:	87ba                	mv	a5,a4
ffffffffc02017da:	bf41                	j	ffffffffc020176a <default_free_pages+0x74>
            p->property += base->property;
ffffffffc02017dc:	491c                	lw	a5,16(a0)
ffffffffc02017de:	0107883b          	addw	a6,a5,a6
ffffffffc02017e2:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02017e6:	57f5                	li	a5,-3
ffffffffc02017e8:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017ec:	6d10                	ld	a2,24(a0)
ffffffffc02017ee:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02017f0:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02017f2:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02017f4:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02017f6:	e390                	sd	a2,0(a5)
ffffffffc02017f8:	b775                	j	ffffffffc02017a4 <default_free_pages+0xae>
ffffffffc02017fa:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017fc:	873e                	mv	a4,a5
ffffffffc02017fe:	b761                	j	ffffffffc0201786 <default_free_pages+0x90>
}
ffffffffc0201800:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201802:	e390                	sd	a2,0(a5)
ffffffffc0201804:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201806:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201808:	ed1c                	sd	a5,24(a0)
ffffffffc020180a:	0141                	addi	sp,sp,16
ffffffffc020180c:	8082                	ret
            base->property += p->property;
ffffffffc020180e:	ff872783          	lw	a5,-8(a4)
ffffffffc0201812:	ff070693          	addi	a3,a4,-16
ffffffffc0201816:	9dbd                	addw	a1,a1,a5
ffffffffc0201818:	c90c                	sw	a1,16(a0)
ffffffffc020181a:	57f5                	li	a5,-3
ffffffffc020181c:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201820:	6314                	ld	a3,0(a4)
ffffffffc0201822:	671c                	ld	a5,8(a4)
}
ffffffffc0201824:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201826:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201828:	e394                	sd	a3,0(a5)
ffffffffc020182a:	0141                	addi	sp,sp,16
ffffffffc020182c:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020182e:	00001697          	auipc	a3,0x1
ffffffffc0201832:	5da68693          	addi	a3,a3,1498 # ffffffffc0202e08 <commands+0xb88>
ffffffffc0201836:	00001617          	auipc	a2,0x1
ffffffffc020183a:	27260613          	addi	a2,a2,626 # ffffffffc0202aa8 <commands+0x828>
ffffffffc020183e:	08300593          	li	a1,131
ffffffffc0201842:	00001517          	auipc	a0,0x1
ffffffffc0201846:	27e50513          	addi	a0,a0,638 # ffffffffc0202ac0 <commands+0x840>
ffffffffc020184a:	935fe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(n > 0);
ffffffffc020184e:	00001697          	auipc	a3,0x1
ffffffffc0201852:	5b268693          	addi	a3,a3,1458 # ffffffffc0202e00 <commands+0xb80>
ffffffffc0201856:	00001617          	auipc	a2,0x1
ffffffffc020185a:	25260613          	addi	a2,a2,594 # ffffffffc0202aa8 <commands+0x828>
ffffffffc020185e:	08000593          	li	a1,128
ffffffffc0201862:	00001517          	auipc	a0,0x1
ffffffffc0201866:	25e50513          	addi	a0,a0,606 # ffffffffc0202ac0 <commands+0x840>
ffffffffc020186a:	915fe0ef          	jal	ra,ffffffffc020017e <__panic>

ffffffffc020186e <default_alloc_pages>:
    assert(n > 0);
ffffffffc020186e:	c959                	beqz	a0,ffffffffc0201904 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0201870:	00005597          	auipc	a1,0x5
ffffffffc0201874:	7b858593          	addi	a1,a1,1976 # ffffffffc0207028 <free_area>
ffffffffc0201878:	0105a803          	lw	a6,16(a1)
ffffffffc020187c:	862a                	mv	a2,a0
ffffffffc020187e:	02081793          	slli	a5,a6,0x20
ffffffffc0201882:	9381                	srli	a5,a5,0x20
ffffffffc0201884:	00a7ee63          	bltu	a5,a0,ffffffffc02018a0 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201888:	87ae                	mv	a5,a1
ffffffffc020188a:	a801                	j	ffffffffc020189a <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020188c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201890:	02071693          	slli	a3,a4,0x20
ffffffffc0201894:	9281                	srli	a3,a3,0x20
ffffffffc0201896:	00c6f763          	bgeu	a3,a2,ffffffffc02018a4 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020189a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020189c:	feb798e3          	bne	a5,a1,ffffffffc020188c <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02018a0:	4501                	li	a0,0
}
ffffffffc02018a2:	8082                	ret
    return listelm->prev;
ffffffffc02018a4:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018a8:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02018ac:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02018b0:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc02018b4:	0068b423          	sd	t1,8(a7) # fffffffffff80008 <end+0x3fd78b68>
    next->prev = prev;
ffffffffc02018b8:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02018bc:	02d67b63          	bgeu	a2,a3,ffffffffc02018f2 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc02018c0:	00261693          	slli	a3,a2,0x2
ffffffffc02018c4:	96b2                	add	a3,a3,a2
ffffffffc02018c6:	068e                	slli	a3,a3,0x3
ffffffffc02018c8:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02018ca:	41c7073b          	subw	a4,a4,t3
ffffffffc02018ce:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018d0:	00868613          	addi	a2,a3,8
ffffffffc02018d4:	4709                	li	a4,2
ffffffffc02018d6:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02018da:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02018de:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc02018e2:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02018e6:	e310                	sd	a2,0(a4)
ffffffffc02018e8:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02018ec:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc02018ee:	0116bc23          	sd	a7,24(a3)
ffffffffc02018f2:	41c8083b          	subw	a6,a6,t3
ffffffffc02018f6:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018fa:	5775                	li	a4,-3
ffffffffc02018fc:	17c1                	addi	a5,a5,-16
ffffffffc02018fe:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201902:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201904:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201906:	00001697          	auipc	a3,0x1
ffffffffc020190a:	4fa68693          	addi	a3,a3,1274 # ffffffffc0202e00 <commands+0xb80>
ffffffffc020190e:	00001617          	auipc	a2,0x1
ffffffffc0201912:	19a60613          	addi	a2,a2,410 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201916:	06200593          	li	a1,98
ffffffffc020191a:	00001517          	auipc	a0,0x1
ffffffffc020191e:	1a650513          	addi	a0,a0,422 # ffffffffc0202ac0 <commands+0x840>
default_alloc_pages(size_t n) {
ffffffffc0201922:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201924:	85bfe0ef          	jal	ra,ffffffffc020017e <__panic>

ffffffffc0201928 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201928:	1141                	addi	sp,sp,-16
ffffffffc020192a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020192c:	c9e1                	beqz	a1,ffffffffc02019fc <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020192e:	00259693          	slli	a3,a1,0x2
ffffffffc0201932:	96ae                	add	a3,a3,a1
ffffffffc0201934:	068e                	slli	a3,a3,0x3
ffffffffc0201936:	96aa                	add	a3,a3,a0
ffffffffc0201938:	87aa                	mv	a5,a0
ffffffffc020193a:	00d50f63          	beq	a0,a3,ffffffffc0201958 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020193e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201940:	8b05                	andi	a4,a4,1
ffffffffc0201942:	cf49                	beqz	a4,ffffffffc02019dc <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201944:	0007a823          	sw	zero,16(a5)
ffffffffc0201948:	0007b423          	sd	zero,8(a5)
ffffffffc020194c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201950:	02878793          	addi	a5,a5,40
ffffffffc0201954:	fed795e3          	bne	a5,a3,ffffffffc020193e <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201958:	2581                	sext.w	a1,a1
ffffffffc020195a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020195c:	4789                	li	a5,2
ffffffffc020195e:	00850713          	addi	a4,a0,8
ffffffffc0201962:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201966:	00005697          	auipc	a3,0x5
ffffffffc020196a:	6c268693          	addi	a3,a3,1730 # ffffffffc0207028 <free_area>
ffffffffc020196e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201970:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201972:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201976:	9db9                	addw	a1,a1,a4
ffffffffc0201978:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020197a:	04d78a63          	beq	a5,a3,ffffffffc02019ce <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc020197e:	fe878713          	addi	a4,a5,-24
ffffffffc0201982:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201986:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201988:	00e56a63          	bltu	a0,a4,ffffffffc020199c <default_init_memmap+0x74>
    return listelm->next;
ffffffffc020198c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020198e:	02d70263          	beq	a4,a3,ffffffffc02019b2 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201992:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201994:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201998:	fee57ae3          	bgeu	a0,a4,ffffffffc020198c <default_init_memmap+0x64>
ffffffffc020199c:	c199                	beqz	a1,ffffffffc02019a2 <default_init_memmap+0x7a>
ffffffffc020199e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019a2:	6398                	ld	a4,0(a5)
}
ffffffffc02019a4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019a6:	e390                	sd	a2,0(a5)
ffffffffc02019a8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02019aa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019ac:	ed18                	sd	a4,24(a0)
ffffffffc02019ae:	0141                	addi	sp,sp,16
ffffffffc02019b0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019b2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019b4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019b6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019b8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02019ba:	00d70663          	beq	a4,a3,ffffffffc02019c6 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02019be:	8832                	mv	a6,a2
ffffffffc02019c0:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02019c2:	87ba                	mv	a5,a4
ffffffffc02019c4:	bfc1                	j	ffffffffc0201994 <default_init_memmap+0x6c>
}
ffffffffc02019c6:	60a2                	ld	ra,8(sp)
ffffffffc02019c8:	e290                	sd	a2,0(a3)
ffffffffc02019ca:	0141                	addi	sp,sp,16
ffffffffc02019cc:	8082                	ret
ffffffffc02019ce:	60a2                	ld	ra,8(sp)
ffffffffc02019d0:	e390                	sd	a2,0(a5)
ffffffffc02019d2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019d4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019d6:	ed1c                	sd	a5,24(a0)
ffffffffc02019d8:	0141                	addi	sp,sp,16
ffffffffc02019da:	8082                	ret
        assert(PageReserved(p));
ffffffffc02019dc:	00001697          	auipc	a3,0x1
ffffffffc02019e0:	45468693          	addi	a3,a3,1108 # ffffffffc0202e30 <commands+0xbb0>
ffffffffc02019e4:	00001617          	auipc	a2,0x1
ffffffffc02019e8:	0c460613          	addi	a2,a2,196 # ffffffffc0202aa8 <commands+0x828>
ffffffffc02019ec:	04900593          	li	a1,73
ffffffffc02019f0:	00001517          	auipc	a0,0x1
ffffffffc02019f4:	0d050513          	addi	a0,a0,208 # ffffffffc0202ac0 <commands+0x840>
ffffffffc02019f8:	f86fe0ef          	jal	ra,ffffffffc020017e <__panic>
    assert(n > 0);
ffffffffc02019fc:	00001697          	auipc	a3,0x1
ffffffffc0201a00:	40468693          	addi	a3,a3,1028 # ffffffffc0202e00 <commands+0xb80>
ffffffffc0201a04:	00001617          	auipc	a2,0x1
ffffffffc0201a08:	0a460613          	addi	a2,a2,164 # ffffffffc0202aa8 <commands+0x828>
ffffffffc0201a0c:	04600593          	li	a1,70
ffffffffc0201a10:	00001517          	auipc	a0,0x1
ffffffffc0201a14:	0b050513          	addi	a0,a0,176 # ffffffffc0202ac0 <commands+0x840>
ffffffffc0201a18:	f66fe0ef          	jal	ra,ffffffffc020017e <__panic>

ffffffffc0201a1c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201a1c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201a20:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201a22:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201a24:	cb81                	beqz	a5,ffffffffc0201a34 <strlen+0x18>
        cnt ++;
ffffffffc0201a26:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201a28:	00a707b3          	add	a5,a4,a0
ffffffffc0201a2c:	0007c783          	lbu	a5,0(a5)
ffffffffc0201a30:	fbfd                	bnez	a5,ffffffffc0201a26 <strlen+0xa>
ffffffffc0201a32:	8082                	ret
    }
    return cnt;
}
ffffffffc0201a34:	8082                	ret

ffffffffc0201a36 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a36:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a38:	e589                	bnez	a1,ffffffffc0201a42 <strnlen+0xc>
ffffffffc0201a3a:	a811                	j	ffffffffc0201a4e <strnlen+0x18>
        cnt ++;
ffffffffc0201a3c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a3e:	00f58863          	beq	a1,a5,ffffffffc0201a4e <strnlen+0x18>
ffffffffc0201a42:	00f50733          	add	a4,a0,a5
ffffffffc0201a46:	00074703          	lbu	a4,0(a4)
ffffffffc0201a4a:	fb6d                	bnez	a4,ffffffffc0201a3c <strnlen+0x6>
ffffffffc0201a4c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201a4e:	852e                	mv	a0,a1
ffffffffc0201a50:	8082                	ret

ffffffffc0201a52 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a52:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a56:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a5a:	cb89                	beqz	a5,ffffffffc0201a6c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201a5c:	0505                	addi	a0,a0,1
ffffffffc0201a5e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a60:	fee789e3          	beq	a5,a4,ffffffffc0201a52 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a64:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201a68:	9d19                	subw	a0,a0,a4
ffffffffc0201a6a:	8082                	ret
ffffffffc0201a6c:	4501                	li	a0,0
ffffffffc0201a6e:	bfed                	j	ffffffffc0201a68 <strcmp+0x16>

ffffffffc0201a70 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201a70:	c20d                	beqz	a2,ffffffffc0201a92 <strncmp+0x22>
ffffffffc0201a72:	962e                	add	a2,a2,a1
ffffffffc0201a74:	a031                	j	ffffffffc0201a80 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201a76:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201a78:	00e79a63          	bne	a5,a4,ffffffffc0201a8c <strncmp+0x1c>
ffffffffc0201a7c:	00b60b63          	beq	a2,a1,ffffffffc0201a92 <strncmp+0x22>
ffffffffc0201a80:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201a84:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201a86:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201a8a:	f7f5                	bnez	a5,ffffffffc0201a76 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a8c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201a90:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a92:	4501                	li	a0,0
ffffffffc0201a94:	8082                	ret

ffffffffc0201a96 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201a96:	00054783          	lbu	a5,0(a0)
ffffffffc0201a9a:	c799                	beqz	a5,ffffffffc0201aa8 <strchr+0x12>
        if (*s == c) {
ffffffffc0201a9c:	00f58763          	beq	a1,a5,ffffffffc0201aaa <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201aa0:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201aa4:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201aa6:	fbfd                	bnez	a5,ffffffffc0201a9c <strchr+0x6>
    }
    return NULL;
ffffffffc0201aa8:	4501                	li	a0,0
}
ffffffffc0201aaa:	8082                	ret

ffffffffc0201aac <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201aac:	ca01                	beqz	a2,ffffffffc0201abc <memset+0x10>
ffffffffc0201aae:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ab0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ab2:	0785                	addi	a5,a5,1
ffffffffc0201ab4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201ab8:	fec79de3          	bne	a5,a2,ffffffffc0201ab2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201abc:	8082                	ret

ffffffffc0201abe <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201abe:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201ac2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201ac4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201ac8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201aca:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201ace:	f022                	sd	s0,32(sp)
ffffffffc0201ad0:	ec26                	sd	s1,24(sp)
ffffffffc0201ad2:	e84a                	sd	s2,16(sp)
ffffffffc0201ad4:	f406                	sd	ra,40(sp)
ffffffffc0201ad6:	e44e                	sd	s3,8(sp)
ffffffffc0201ad8:	84aa                	mv	s1,a0
ffffffffc0201ada:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201adc:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201ae0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201ae2:	03067e63          	bgeu	a2,a6,ffffffffc0201b1e <printnum+0x60>
ffffffffc0201ae6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201ae8:	00805763          	blez	s0,ffffffffc0201af6 <printnum+0x38>
ffffffffc0201aec:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201aee:	85ca                	mv	a1,s2
ffffffffc0201af0:	854e                	mv	a0,s3
ffffffffc0201af2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201af4:	fc65                	bnez	s0,ffffffffc0201aec <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201af6:	1a02                	slli	s4,s4,0x20
ffffffffc0201af8:	00001797          	auipc	a5,0x1
ffffffffc0201afc:	39878793          	addi	a5,a5,920 # ffffffffc0202e90 <default_pmm_manager+0x38>
ffffffffc0201b00:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201b04:	9a3e                	add	s4,s4,a5
}
ffffffffc0201b06:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b08:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201b0c:	70a2                	ld	ra,40(sp)
ffffffffc0201b0e:	69a2                	ld	s3,8(sp)
ffffffffc0201b10:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b12:	85ca                	mv	a1,s2
ffffffffc0201b14:	87a6                	mv	a5,s1
}
ffffffffc0201b16:	6942                	ld	s2,16(sp)
ffffffffc0201b18:	64e2                	ld	s1,24(sp)
ffffffffc0201b1a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b1c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201b1e:	03065633          	divu	a2,a2,a6
ffffffffc0201b22:	8722                	mv	a4,s0
ffffffffc0201b24:	f9bff0ef          	jal	ra,ffffffffc0201abe <printnum>
ffffffffc0201b28:	b7f9                	j	ffffffffc0201af6 <printnum+0x38>

ffffffffc0201b2a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201b2a:	7119                	addi	sp,sp,-128
ffffffffc0201b2c:	f4a6                	sd	s1,104(sp)
ffffffffc0201b2e:	f0ca                	sd	s2,96(sp)
ffffffffc0201b30:	ecce                	sd	s3,88(sp)
ffffffffc0201b32:	e8d2                	sd	s4,80(sp)
ffffffffc0201b34:	e4d6                	sd	s5,72(sp)
ffffffffc0201b36:	e0da                	sd	s6,64(sp)
ffffffffc0201b38:	fc5e                	sd	s7,56(sp)
ffffffffc0201b3a:	f06a                	sd	s10,32(sp)
ffffffffc0201b3c:	fc86                	sd	ra,120(sp)
ffffffffc0201b3e:	f8a2                	sd	s0,112(sp)
ffffffffc0201b40:	f862                	sd	s8,48(sp)
ffffffffc0201b42:	f466                	sd	s9,40(sp)
ffffffffc0201b44:	ec6e                	sd	s11,24(sp)
ffffffffc0201b46:	892a                	mv	s2,a0
ffffffffc0201b48:	84ae                	mv	s1,a1
ffffffffc0201b4a:	8d32                	mv	s10,a2
ffffffffc0201b4c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b4e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201b52:	5b7d                	li	s6,-1
ffffffffc0201b54:	00001a97          	auipc	s5,0x1
ffffffffc0201b58:	370a8a93          	addi	s5,s5,880 # ffffffffc0202ec4 <default_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b5c:	00001b97          	auipc	s7,0x1
ffffffffc0201b60:	544b8b93          	addi	s7,s7,1348 # ffffffffc02030a0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b64:	000d4503          	lbu	a0,0(s10)
ffffffffc0201b68:	001d0413          	addi	s0,s10,1
ffffffffc0201b6c:	01350a63          	beq	a0,s3,ffffffffc0201b80 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201b70:	c121                	beqz	a0,ffffffffc0201bb0 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201b72:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b74:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201b76:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b78:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201b7c:	ff351ae3          	bne	a0,s3,ffffffffc0201b70 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b80:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201b84:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201b88:	4c81                	li	s9,0
ffffffffc0201b8a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201b8c:	5c7d                	li	s8,-1
ffffffffc0201b8e:	5dfd                	li	s11,-1
ffffffffc0201b90:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201b94:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b96:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b9a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b9e:	00140d13          	addi	s10,s0,1
ffffffffc0201ba2:	04b56263          	bltu	a0,a1,ffffffffc0201be6 <vprintfmt+0xbc>
ffffffffc0201ba6:	058a                	slli	a1,a1,0x2
ffffffffc0201ba8:	95d6                	add	a1,a1,s5
ffffffffc0201baa:	4194                	lw	a3,0(a1)
ffffffffc0201bac:	96d6                	add	a3,a3,s5
ffffffffc0201bae:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201bb0:	70e6                	ld	ra,120(sp)
ffffffffc0201bb2:	7446                	ld	s0,112(sp)
ffffffffc0201bb4:	74a6                	ld	s1,104(sp)
ffffffffc0201bb6:	7906                	ld	s2,96(sp)
ffffffffc0201bb8:	69e6                	ld	s3,88(sp)
ffffffffc0201bba:	6a46                	ld	s4,80(sp)
ffffffffc0201bbc:	6aa6                	ld	s5,72(sp)
ffffffffc0201bbe:	6b06                	ld	s6,64(sp)
ffffffffc0201bc0:	7be2                	ld	s7,56(sp)
ffffffffc0201bc2:	7c42                	ld	s8,48(sp)
ffffffffc0201bc4:	7ca2                	ld	s9,40(sp)
ffffffffc0201bc6:	7d02                	ld	s10,32(sp)
ffffffffc0201bc8:	6de2                	ld	s11,24(sp)
ffffffffc0201bca:	6109                	addi	sp,sp,128
ffffffffc0201bcc:	8082                	ret
            padc = '0';
ffffffffc0201bce:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201bd0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bd4:	846a                	mv	s0,s10
ffffffffc0201bd6:	00140d13          	addi	s10,s0,1
ffffffffc0201bda:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201bde:	0ff5f593          	zext.b	a1,a1
ffffffffc0201be2:	fcb572e3          	bgeu	a0,a1,ffffffffc0201ba6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201be6:	85a6                	mv	a1,s1
ffffffffc0201be8:	02500513          	li	a0,37
ffffffffc0201bec:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201bee:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201bf2:	8d22                	mv	s10,s0
ffffffffc0201bf4:	f73788e3          	beq	a5,s3,ffffffffc0201b64 <vprintfmt+0x3a>
ffffffffc0201bf8:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201bfc:	1d7d                	addi	s10,s10,-1
ffffffffc0201bfe:	ff379de3          	bne	a5,s3,ffffffffc0201bf8 <vprintfmt+0xce>
ffffffffc0201c02:	b78d                	j	ffffffffc0201b64 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201c04:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201c08:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c0c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201c0e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201c12:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201c16:	02d86463          	bltu	a6,a3,ffffffffc0201c3e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201c1a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201c1e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201c22:	0186873b          	addw	a4,a3,s8
ffffffffc0201c26:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201c2a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201c2c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201c30:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201c32:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201c36:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201c3a:	fed870e3          	bgeu	a6,a3,ffffffffc0201c1a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201c3e:	f40ddce3          	bgez	s11,ffffffffc0201b96 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201c42:	8de2                	mv	s11,s8
ffffffffc0201c44:	5c7d                	li	s8,-1
ffffffffc0201c46:	bf81                	j	ffffffffc0201b96 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201c48:	fffdc693          	not	a3,s11
ffffffffc0201c4c:	96fd                	srai	a3,a3,0x3f
ffffffffc0201c4e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c52:	00144603          	lbu	a2,1(s0)
ffffffffc0201c56:	2d81                	sext.w	s11,s11
ffffffffc0201c58:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c5a:	bf35                	j	ffffffffc0201b96 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201c5c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c60:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201c64:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c66:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201c68:	bfd9                	j	ffffffffc0201c3e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201c6a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c6c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c70:	01174463          	blt	a4,a7,ffffffffc0201c78 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201c74:	1a088e63          	beqz	a7,ffffffffc0201e30 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201c78:	000a3603          	ld	a2,0(s4)
ffffffffc0201c7c:	46c1                	li	a3,16
ffffffffc0201c7e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c80:	2781                	sext.w	a5,a5
ffffffffc0201c82:	876e                	mv	a4,s11
ffffffffc0201c84:	85a6                	mv	a1,s1
ffffffffc0201c86:	854a                	mv	a0,s2
ffffffffc0201c88:	e37ff0ef          	jal	ra,ffffffffc0201abe <printnum>
            break;
ffffffffc0201c8c:	bde1                	j	ffffffffc0201b64 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c8e:	000a2503          	lw	a0,0(s4)
ffffffffc0201c92:	85a6                	mv	a1,s1
ffffffffc0201c94:	0a21                	addi	s4,s4,8
ffffffffc0201c96:	9902                	jalr	s2
            break;
ffffffffc0201c98:	b5f1                	j	ffffffffc0201b64 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c9a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c9c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ca0:	01174463          	blt	a4,a7,ffffffffc0201ca8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201ca4:	18088163          	beqz	a7,ffffffffc0201e26 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201ca8:	000a3603          	ld	a2,0(s4)
ffffffffc0201cac:	46a9                	li	a3,10
ffffffffc0201cae:	8a2e                	mv	s4,a1
ffffffffc0201cb0:	bfc1                	j	ffffffffc0201c80 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cb2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201cb6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cb8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201cba:	bdf1                	j	ffffffffc0201b96 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201cbc:	85a6                	mv	a1,s1
ffffffffc0201cbe:	02500513          	li	a0,37
ffffffffc0201cc2:	9902                	jalr	s2
            break;
ffffffffc0201cc4:	b545                	j	ffffffffc0201b64 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cc6:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201cca:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ccc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201cce:	b5e1                	j	ffffffffc0201b96 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201cd0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cd2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201cd6:	01174463          	blt	a4,a7,ffffffffc0201cde <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201cda:	14088163          	beqz	a7,ffffffffc0201e1c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201cde:	000a3603          	ld	a2,0(s4)
ffffffffc0201ce2:	46a1                	li	a3,8
ffffffffc0201ce4:	8a2e                	mv	s4,a1
ffffffffc0201ce6:	bf69                	j	ffffffffc0201c80 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201ce8:	03000513          	li	a0,48
ffffffffc0201cec:	85a6                	mv	a1,s1
ffffffffc0201cee:	e03e                	sd	a5,0(sp)
ffffffffc0201cf0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201cf2:	85a6                	mv	a1,s1
ffffffffc0201cf4:	07800513          	li	a0,120
ffffffffc0201cf8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201cfa:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201cfc:	6782                	ld	a5,0(sp)
ffffffffc0201cfe:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201d00:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201d04:	bfb5                	j	ffffffffc0201c80 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d06:	000a3403          	ld	s0,0(s4)
ffffffffc0201d0a:	008a0713          	addi	a4,s4,8
ffffffffc0201d0e:	e03a                	sd	a4,0(sp)
ffffffffc0201d10:	14040263          	beqz	s0,ffffffffc0201e54 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201d14:	0fb05763          	blez	s11,ffffffffc0201e02 <vprintfmt+0x2d8>
ffffffffc0201d18:	02d00693          	li	a3,45
ffffffffc0201d1c:	0cd79163          	bne	a5,a3,ffffffffc0201dde <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d20:	00044783          	lbu	a5,0(s0)
ffffffffc0201d24:	0007851b          	sext.w	a0,a5
ffffffffc0201d28:	cf85                	beqz	a5,ffffffffc0201d60 <vprintfmt+0x236>
ffffffffc0201d2a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d2e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d32:	000c4563          	bltz	s8,ffffffffc0201d3c <vprintfmt+0x212>
ffffffffc0201d36:	3c7d                	addiw	s8,s8,-1
ffffffffc0201d38:	036c0263          	beq	s8,s6,ffffffffc0201d5c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201d3c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d3e:	0e0c8e63          	beqz	s9,ffffffffc0201e3a <vprintfmt+0x310>
ffffffffc0201d42:	3781                	addiw	a5,a5,-32
ffffffffc0201d44:	0ef47b63          	bgeu	s0,a5,ffffffffc0201e3a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201d48:	03f00513          	li	a0,63
ffffffffc0201d4c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d4e:	000a4783          	lbu	a5,0(s4)
ffffffffc0201d52:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d54:	0a05                	addi	s4,s4,1
ffffffffc0201d56:	0007851b          	sext.w	a0,a5
ffffffffc0201d5a:	ffe1                	bnez	a5,ffffffffc0201d32 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201d5c:	01b05963          	blez	s11,ffffffffc0201d6e <vprintfmt+0x244>
ffffffffc0201d60:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201d62:	85a6                	mv	a1,s1
ffffffffc0201d64:	02000513          	li	a0,32
ffffffffc0201d68:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201d6a:	fe0d9be3          	bnez	s11,ffffffffc0201d60 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d6e:	6a02                	ld	s4,0(sp)
ffffffffc0201d70:	bbd5                	j	ffffffffc0201b64 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201d72:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d74:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201d78:	01174463          	blt	a4,a7,ffffffffc0201d80 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201d7c:	08088d63          	beqz	a7,ffffffffc0201e16 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201d80:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201d84:	0a044d63          	bltz	s0,ffffffffc0201e3e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201d88:	8622                	mv	a2,s0
ffffffffc0201d8a:	8a66                	mv	s4,s9
ffffffffc0201d8c:	46a9                	li	a3,10
ffffffffc0201d8e:	bdcd                	j	ffffffffc0201c80 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201d90:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d94:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201d96:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201d98:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d9c:	8fb5                	xor	a5,a5,a3
ffffffffc0201d9e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201da2:	02d74163          	blt	a4,a3,ffffffffc0201dc4 <vprintfmt+0x29a>
ffffffffc0201da6:	00369793          	slli	a5,a3,0x3
ffffffffc0201daa:	97de                	add	a5,a5,s7
ffffffffc0201dac:	639c                	ld	a5,0(a5)
ffffffffc0201dae:	cb99                	beqz	a5,ffffffffc0201dc4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201db0:	86be                	mv	a3,a5
ffffffffc0201db2:	00001617          	auipc	a2,0x1
ffffffffc0201db6:	10e60613          	addi	a2,a2,270 # ffffffffc0202ec0 <default_pmm_manager+0x68>
ffffffffc0201dba:	85a6                	mv	a1,s1
ffffffffc0201dbc:	854a                	mv	a0,s2
ffffffffc0201dbe:	0ce000ef          	jal	ra,ffffffffc0201e8c <printfmt>
ffffffffc0201dc2:	b34d                	j	ffffffffc0201b64 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201dc4:	00001617          	auipc	a2,0x1
ffffffffc0201dc8:	0ec60613          	addi	a2,a2,236 # ffffffffc0202eb0 <default_pmm_manager+0x58>
ffffffffc0201dcc:	85a6                	mv	a1,s1
ffffffffc0201dce:	854a                	mv	a0,s2
ffffffffc0201dd0:	0bc000ef          	jal	ra,ffffffffc0201e8c <printfmt>
ffffffffc0201dd4:	bb41                	j	ffffffffc0201b64 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201dd6:	00001417          	auipc	s0,0x1
ffffffffc0201dda:	0d240413          	addi	s0,s0,210 # ffffffffc0202ea8 <default_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201dde:	85e2                	mv	a1,s8
ffffffffc0201de0:	8522                	mv	a0,s0
ffffffffc0201de2:	e43e                	sd	a5,8(sp)
ffffffffc0201de4:	c53ff0ef          	jal	ra,ffffffffc0201a36 <strnlen>
ffffffffc0201de8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201dec:	01b05b63          	blez	s11,ffffffffc0201e02 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201df0:	67a2                	ld	a5,8(sp)
ffffffffc0201df2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201df6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201df8:	85a6                	mv	a1,s1
ffffffffc0201dfa:	8552                	mv	a0,s4
ffffffffc0201dfc:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201dfe:	fe0d9ce3          	bnez	s11,ffffffffc0201df6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e02:	00044783          	lbu	a5,0(s0)
ffffffffc0201e06:	00140a13          	addi	s4,s0,1
ffffffffc0201e0a:	0007851b          	sext.w	a0,a5
ffffffffc0201e0e:	d3a5                	beqz	a5,ffffffffc0201d6e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e10:	05e00413          	li	s0,94
ffffffffc0201e14:	bf39                	j	ffffffffc0201d32 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201e16:	000a2403          	lw	s0,0(s4)
ffffffffc0201e1a:	b7ad                	j	ffffffffc0201d84 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201e1c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e20:	46a1                	li	a3,8
ffffffffc0201e22:	8a2e                	mv	s4,a1
ffffffffc0201e24:	bdb1                	j	ffffffffc0201c80 <vprintfmt+0x156>
ffffffffc0201e26:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e2a:	46a9                	li	a3,10
ffffffffc0201e2c:	8a2e                	mv	s4,a1
ffffffffc0201e2e:	bd89                	j	ffffffffc0201c80 <vprintfmt+0x156>
ffffffffc0201e30:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e34:	46c1                	li	a3,16
ffffffffc0201e36:	8a2e                	mv	s4,a1
ffffffffc0201e38:	b5a1                	j	ffffffffc0201c80 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201e3a:	9902                	jalr	s2
ffffffffc0201e3c:	bf09                	j	ffffffffc0201d4e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201e3e:	85a6                	mv	a1,s1
ffffffffc0201e40:	02d00513          	li	a0,45
ffffffffc0201e44:	e03e                	sd	a5,0(sp)
ffffffffc0201e46:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201e48:	6782                	ld	a5,0(sp)
ffffffffc0201e4a:	8a66                	mv	s4,s9
ffffffffc0201e4c:	40800633          	neg	a2,s0
ffffffffc0201e50:	46a9                	li	a3,10
ffffffffc0201e52:	b53d                	j	ffffffffc0201c80 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201e54:	03b05163          	blez	s11,ffffffffc0201e76 <vprintfmt+0x34c>
ffffffffc0201e58:	02d00693          	li	a3,45
ffffffffc0201e5c:	f6d79de3          	bne	a5,a3,ffffffffc0201dd6 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201e60:	00001417          	auipc	s0,0x1
ffffffffc0201e64:	04840413          	addi	s0,s0,72 # ffffffffc0202ea8 <default_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e68:	02800793          	li	a5,40
ffffffffc0201e6c:	02800513          	li	a0,40
ffffffffc0201e70:	00140a13          	addi	s4,s0,1
ffffffffc0201e74:	bd6d                	j	ffffffffc0201d2e <vprintfmt+0x204>
ffffffffc0201e76:	00001a17          	auipc	s4,0x1
ffffffffc0201e7a:	033a0a13          	addi	s4,s4,51 # ffffffffc0202ea9 <default_pmm_manager+0x51>
ffffffffc0201e7e:	02800513          	li	a0,40
ffffffffc0201e82:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e86:	05e00413          	li	s0,94
ffffffffc0201e8a:	b565                	j	ffffffffc0201d32 <vprintfmt+0x208>

ffffffffc0201e8c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e8c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e8e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e92:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e94:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e96:	ec06                	sd	ra,24(sp)
ffffffffc0201e98:	f83a                	sd	a4,48(sp)
ffffffffc0201e9a:	fc3e                	sd	a5,56(sp)
ffffffffc0201e9c:	e0c2                	sd	a6,64(sp)
ffffffffc0201e9e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201ea0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201ea2:	c89ff0ef          	jal	ra,ffffffffc0201b2a <vprintfmt>
}
ffffffffc0201ea6:	60e2                	ld	ra,24(sp)
ffffffffc0201ea8:	6161                	addi	sp,sp,80
ffffffffc0201eaa:	8082                	ret

ffffffffc0201eac <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201eac:	715d                	addi	sp,sp,-80
ffffffffc0201eae:	e486                	sd	ra,72(sp)
ffffffffc0201eb0:	e0a6                	sd	s1,64(sp)
ffffffffc0201eb2:	fc4a                	sd	s2,56(sp)
ffffffffc0201eb4:	f84e                	sd	s3,48(sp)
ffffffffc0201eb6:	f452                	sd	s4,40(sp)
ffffffffc0201eb8:	f056                	sd	s5,32(sp)
ffffffffc0201eba:	ec5a                	sd	s6,24(sp)
ffffffffc0201ebc:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201ebe:	c901                	beqz	a0,ffffffffc0201ece <readline+0x22>
ffffffffc0201ec0:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201ec2:	00001517          	auipc	a0,0x1
ffffffffc0201ec6:	ffe50513          	addi	a0,a0,-2 # ffffffffc0202ec0 <default_pmm_manager+0x68>
ffffffffc0201eca:	a2cfe0ef          	jal	ra,ffffffffc02000f6 <cprintf>
readline(const char *prompt) {
ffffffffc0201ece:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ed0:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201ed2:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201ed4:	4aa9                	li	s5,10
ffffffffc0201ed6:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201ed8:	00005b97          	auipc	s7,0x5
ffffffffc0201edc:	168b8b93          	addi	s7,s7,360 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ee0:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201ee4:	a8afe0ef          	jal	ra,ffffffffc020016e <getchar>
        if (c < 0) {
ffffffffc0201ee8:	00054a63          	bltz	a0,ffffffffc0201efc <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201eec:	00a95a63          	bge	s2,a0,ffffffffc0201f00 <readline+0x54>
ffffffffc0201ef0:	029a5263          	bge	s4,s1,ffffffffc0201f14 <readline+0x68>
        c = getchar();
ffffffffc0201ef4:	a7afe0ef          	jal	ra,ffffffffc020016e <getchar>
        if (c < 0) {
ffffffffc0201ef8:	fe055ae3          	bgez	a0,ffffffffc0201eec <readline+0x40>
            return NULL;
ffffffffc0201efc:	4501                	li	a0,0
ffffffffc0201efe:	a091                	j	ffffffffc0201f42 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201f00:	03351463          	bne	a0,s3,ffffffffc0201f28 <readline+0x7c>
ffffffffc0201f04:	e8a9                	bnez	s1,ffffffffc0201f56 <readline+0xaa>
        c = getchar();
ffffffffc0201f06:	a68fe0ef          	jal	ra,ffffffffc020016e <getchar>
        if (c < 0) {
ffffffffc0201f0a:	fe0549e3          	bltz	a0,ffffffffc0201efc <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201f0e:	fea959e3          	bge	s2,a0,ffffffffc0201f00 <readline+0x54>
ffffffffc0201f12:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201f14:	e42a                	sd	a0,8(sp)
ffffffffc0201f16:	a16fe0ef          	jal	ra,ffffffffc020012c <cputchar>
            buf[i ++] = c;
ffffffffc0201f1a:	6522                	ld	a0,8(sp)
ffffffffc0201f1c:	009b87b3          	add	a5,s7,s1
ffffffffc0201f20:	2485                	addiw	s1,s1,1
ffffffffc0201f22:	00a78023          	sb	a0,0(a5)
ffffffffc0201f26:	bf7d                	j	ffffffffc0201ee4 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201f28:	01550463          	beq	a0,s5,ffffffffc0201f30 <readline+0x84>
ffffffffc0201f2c:	fb651ce3          	bne	a0,s6,ffffffffc0201ee4 <readline+0x38>
            cputchar(c);
ffffffffc0201f30:	9fcfe0ef          	jal	ra,ffffffffc020012c <cputchar>
            buf[i] = '\0';
ffffffffc0201f34:	00005517          	auipc	a0,0x5
ffffffffc0201f38:	10c50513          	addi	a0,a0,268 # ffffffffc0207040 <buf>
ffffffffc0201f3c:	94aa                	add	s1,s1,a0
ffffffffc0201f3e:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201f42:	60a6                	ld	ra,72(sp)
ffffffffc0201f44:	6486                	ld	s1,64(sp)
ffffffffc0201f46:	7962                	ld	s2,56(sp)
ffffffffc0201f48:	79c2                	ld	s3,48(sp)
ffffffffc0201f4a:	7a22                	ld	s4,40(sp)
ffffffffc0201f4c:	7a82                	ld	s5,32(sp)
ffffffffc0201f4e:	6b62                	ld	s6,24(sp)
ffffffffc0201f50:	6bc2                	ld	s7,16(sp)
ffffffffc0201f52:	6161                	addi	sp,sp,80
ffffffffc0201f54:	8082                	ret
            cputchar(c);
ffffffffc0201f56:	4521                	li	a0,8
ffffffffc0201f58:	9d4fe0ef          	jal	ra,ffffffffc020012c <cputchar>
            i --;
ffffffffc0201f5c:	34fd                	addiw	s1,s1,-1
ffffffffc0201f5e:	b759                	j	ffffffffc0201ee4 <readline+0x38>

ffffffffc0201f60 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201f60:	4781                	li	a5,0
ffffffffc0201f62:	00005717          	auipc	a4,0x5
ffffffffc0201f66:	0b673703          	ld	a4,182(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f6a:	88ba                	mv	a7,a4
ffffffffc0201f6c:	852a                	mv	a0,a0
ffffffffc0201f6e:	85be                	mv	a1,a5
ffffffffc0201f70:	863e                	mv	a2,a5
ffffffffc0201f72:	00000073          	ecall
ffffffffc0201f76:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201f78:	8082                	ret

ffffffffc0201f7a <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201f7a:	4781                	li	a5,0
ffffffffc0201f7c:	00005717          	auipc	a4,0x5
ffffffffc0201f80:	51c73703          	ld	a4,1308(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201f84:	88ba                	mv	a7,a4
ffffffffc0201f86:	852a                	mv	a0,a0
ffffffffc0201f88:	85be                	mv	a1,a5
ffffffffc0201f8a:	863e                	mv	a2,a5
ffffffffc0201f8c:	00000073          	ecall
ffffffffc0201f90:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201f92:	8082                	ret

ffffffffc0201f94 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201f94:	4501                	li	a0,0
ffffffffc0201f96:	00005797          	auipc	a5,0x5
ffffffffc0201f9a:	07a7b783          	ld	a5,122(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f9e:	88be                	mv	a7,a5
ffffffffc0201fa0:	852a                	mv	a0,a0
ffffffffc0201fa2:	85aa                	mv	a1,a0
ffffffffc0201fa4:	862a                	mv	a2,a0
ffffffffc0201fa6:	00000073          	ecall
ffffffffc0201faa:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201fac:	2501                	sext.w	a0,a0
ffffffffc0201fae:	8082                	ret

ffffffffc0201fb0 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201fb0:	4781                	li	a5,0
ffffffffc0201fb2:	00005717          	auipc	a4,0x5
ffffffffc0201fb6:	06e73703          	ld	a4,110(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201fba:	88ba                	mv	a7,a4
ffffffffc0201fbc:	853e                	mv	a0,a5
ffffffffc0201fbe:	85be                	mv	a1,a5
ffffffffc0201fc0:	863e                	mv	a2,a5
ffffffffc0201fc2:	00000073          	ecall
ffffffffc0201fc6:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201fc8:	8082                	ret
