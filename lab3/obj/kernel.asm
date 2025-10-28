
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
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
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fcc50513          	addi	a0,a0,-52 # ffffffffc0206020 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	43460613          	addi	a2,a2,1076 # ffffffffc0206490 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	139010ef          	jal	ra,ffffffffc02019a4 <memset>
    dtb_init();
ffffffffc0200070:	3be000ef          	jal	ra,ffffffffc020042e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	79e000ef          	jal	ra,ffffffffc0200812 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e3050513          	addi	a0,a0,-464 # ffffffffc0201ea8 <etext>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	138000ef          	jal	ra,ffffffffc02001bc <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7a4000ef          	jal	ra,ffffffffc020082c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	3d1000ef          	jal	ra,ffffffffc0200c5c <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	79c000ef          	jal	ra,ffffffffc020082c <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	74a000ef          	jal	ra,ffffffffc02007de <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	788000ef          	jal	ra,ffffffffc0200820 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	76e000ef          	jal	ra,ffffffffc0200814 <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	157010ef          	jal	ra,ffffffffc0201a22 <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	121010ef          	jal	ra,ffffffffc0201a22 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	a719                	j	ffffffffc0200814 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	6ee000ef          	jal	ra,ffffffffc0200814 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	6d8000ef          	jal	ra,ffffffffc0200814 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	6c8000ef          	jal	ra,ffffffffc020081c <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200160:	00006317          	auipc	t1,0x6
ffffffffc0200164:	2d830313          	addi	t1,t1,728 # ffffffffc0206438 <is_panic>
ffffffffc0200168:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020016c:	715d                	addi	sp,sp,-80
ffffffffc020016e:	ec06                	sd	ra,24(sp)
ffffffffc0200170:	e822                	sd	s0,16(sp)
ffffffffc0200172:	f436                	sd	a3,40(sp)
ffffffffc0200174:	f83a                	sd	a4,48(sp)
ffffffffc0200176:	fc3e                	sd	a5,56(sp)
ffffffffc0200178:	e0c2                	sd	a6,64(sp)
ffffffffc020017a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020017c:	020e1a63          	bnez	t3,ffffffffc02001b0 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200180:	4785                	li	a5,1
ffffffffc0200182:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200186:	8432                	mv	s0,a2
ffffffffc0200188:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020018a:	862e                	mv	a2,a1
ffffffffc020018c:	85aa                	mv	a1,a0
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	d3a50513          	addi	a0,a0,-710 # ffffffffc0201ec8 <etext+0x20>
    va_start(ap, fmt);
ffffffffc0200196:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200198:	f41ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020019c:	65a2                	ld	a1,8(sp)
ffffffffc020019e:	8522                	mv	a0,s0
ffffffffc02001a0:	f19ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc02001a4:	00002517          	auipc	a0,0x2
ffffffffc02001a8:	e0c50513          	addi	a0,a0,-500 # ffffffffc0201fb0 <etext+0x108>
ffffffffc02001ac:	f2dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02001b0:	676000ef          	jal	ra,ffffffffc0200826 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02001b4:	4501                	li	a0,0
ffffffffc02001b6:	130000ef          	jal	ra,ffffffffc02002e6 <kmonitor>
    while (1) {
ffffffffc02001ba:	bfed                	j	ffffffffc02001b4 <__panic+0x54>

ffffffffc02001bc <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001bc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001be:	00002517          	auipc	a0,0x2
ffffffffc02001c2:	d2a50513          	addi	a0,a0,-726 # ffffffffc0201ee8 <etext+0x40>
void print_kerninfo(void) {
ffffffffc02001c6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001c8:	f11ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001cc:	00000597          	auipc	a1,0x0
ffffffffc02001d0:	e8858593          	addi	a1,a1,-376 # ffffffffc0200054 <kern_init>
ffffffffc02001d4:	00002517          	auipc	a0,0x2
ffffffffc02001d8:	d3450513          	addi	a0,a0,-716 # ffffffffc0201f08 <etext+0x60>
ffffffffc02001dc:	efdff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001e0:	00002597          	auipc	a1,0x2
ffffffffc02001e4:	cc858593          	addi	a1,a1,-824 # ffffffffc0201ea8 <etext>
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	d4050513          	addi	a0,a0,-704 # ffffffffc0201f28 <etext+0x80>
ffffffffc02001f0:	ee9ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001f4:	00006597          	auipc	a1,0x6
ffffffffc02001f8:	e2c58593          	addi	a1,a1,-468 # ffffffffc0206020 <free_area>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	d4c50513          	addi	a0,a0,-692 # ffffffffc0201f48 <etext+0xa0>
ffffffffc0200204:	ed5ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200208:	00006597          	auipc	a1,0x6
ffffffffc020020c:	28858593          	addi	a1,a1,648 # ffffffffc0206490 <end>
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	d5850513          	addi	a0,a0,-680 # ffffffffc0201f68 <etext+0xc0>
ffffffffc0200218:	ec1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020021c:	00006597          	auipc	a1,0x6
ffffffffc0200220:	67358593          	addi	a1,a1,1651 # ffffffffc020688f <end+0x3ff>
ffffffffc0200224:	00000797          	auipc	a5,0x0
ffffffffc0200228:	e3078793          	addi	a5,a5,-464 # ffffffffc0200054 <kern_init>
ffffffffc020022c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200230:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200234:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200236:	3ff5f593          	andi	a1,a1,1023
ffffffffc020023a:	95be                	add	a1,a1,a5
ffffffffc020023c:	85a9                	srai	a1,a1,0xa
ffffffffc020023e:	00002517          	auipc	a0,0x2
ffffffffc0200242:	d4a50513          	addi	a0,a0,-694 # ffffffffc0201f88 <etext+0xe0>
}
ffffffffc0200246:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200248:	bd41                	j	ffffffffc02000d8 <cprintf>

ffffffffc020024a <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	d6c60613          	addi	a2,a2,-660 # ffffffffc0201fb8 <etext+0x110>
ffffffffc0200254:	04d00593          	li	a1,77
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	d7850513          	addi	a0,a0,-648 # ffffffffc0201fd0 <etext+0x128>
void print_stackframe(void) {
ffffffffc0200260:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200262:	effff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200266 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200266:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200268:	00002617          	auipc	a2,0x2
ffffffffc020026c:	d8060613          	addi	a2,a2,-640 # ffffffffc0201fe8 <etext+0x140>
ffffffffc0200270:	00002597          	auipc	a1,0x2
ffffffffc0200274:	d9858593          	addi	a1,a1,-616 # ffffffffc0202008 <etext+0x160>
ffffffffc0200278:	00002517          	auipc	a0,0x2
ffffffffc020027c:	d9850513          	addi	a0,a0,-616 # ffffffffc0202010 <etext+0x168>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200280:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200282:	e57ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	d9a60613          	addi	a2,a2,-614 # ffffffffc0202020 <etext+0x178>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	dba58593          	addi	a1,a1,-582 # ffffffffc0202048 <etext+0x1a0>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	d7a50513          	addi	a0,a0,-646 # ffffffffc0202010 <etext+0x168>
ffffffffc020029e:	e3bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02002a2:	00002617          	auipc	a2,0x2
ffffffffc02002a6:	db660613          	addi	a2,a2,-586 # ffffffffc0202058 <etext+0x1b0>
ffffffffc02002aa:	00002597          	auipc	a1,0x2
ffffffffc02002ae:	dce58593          	addi	a1,a1,-562 # ffffffffc0202078 <etext+0x1d0>
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	d5e50513          	addi	a0,a0,-674 # ffffffffc0202010 <etext+0x168>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc02002be:	60a2                	ld	ra,8(sp)
ffffffffc02002c0:	4501                	li	a0,0
ffffffffc02002c2:	0141                	addi	sp,sp,16
ffffffffc02002c4:	8082                	ret

ffffffffc02002c6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c6:	1141                	addi	sp,sp,-16
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ca:	ef3ff0ef          	jal	ra,ffffffffc02001bc <print_kerninfo>
    return 0;
}
ffffffffc02002ce:	60a2                	ld	ra,8(sp)
ffffffffc02002d0:	4501                	li	a0,0
ffffffffc02002d2:	0141                	addi	sp,sp,16
ffffffffc02002d4:	8082                	ret

ffffffffc02002d6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d6:	1141                	addi	sp,sp,-16
ffffffffc02002d8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002da:	f71ff0ef          	jal	ra,ffffffffc020024a <print_stackframe>
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002e6:	7115                	addi	sp,sp,-224
ffffffffc02002e8:	ed5e                	sd	s7,152(sp)
ffffffffc02002ea:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ec:	00002517          	auipc	a0,0x2
ffffffffc02002f0:	d9c50513          	addi	a0,a0,-612 # ffffffffc0202088 <etext+0x1e0>
kmonitor(struct trapframe *tf) {
ffffffffc02002f4:	ed86                	sd	ra,216(sp)
ffffffffc02002f6:	e9a2                	sd	s0,208(sp)
ffffffffc02002f8:	e5a6                	sd	s1,200(sp)
ffffffffc02002fa:	e1ca                	sd	s2,192(sp)
ffffffffc02002fc:	fd4e                	sd	s3,184(sp)
ffffffffc02002fe:	f952                	sd	s4,176(sp)
ffffffffc0200300:	f556                	sd	s5,168(sp)
ffffffffc0200302:	f15a                	sd	s6,160(sp)
ffffffffc0200304:	e962                	sd	s8,144(sp)
ffffffffc0200306:	e566                	sd	s9,136(sp)
ffffffffc0200308:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030a:	dcfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020030e:	00002517          	auipc	a0,0x2
ffffffffc0200312:	da250513          	addi	a0,a0,-606 # ffffffffc02020b0 <etext+0x208>
ffffffffc0200316:	dc3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc020031a:	000b8563          	beqz	s7,ffffffffc0200324 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020031e:	855e                	mv	a0,s7
ffffffffc0200320:	6ec000ef          	jal	ra,ffffffffc0200a0c <print_trapframe>
ffffffffc0200324:	00002c17          	auipc	s8,0x2
ffffffffc0200328:	dfcc0c13          	addi	s8,s8,-516 # ffffffffc0202120 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032c:	00002917          	auipc	s2,0x2
ffffffffc0200330:	dac90913          	addi	s2,s2,-596 # ffffffffc02020d8 <etext+0x230>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200334:	00002497          	auipc	s1,0x2
ffffffffc0200338:	dac48493          	addi	s1,s1,-596 # ffffffffc02020e0 <etext+0x238>
        if (argc == MAXARGS - 1) {
ffffffffc020033c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020033e:	00002b17          	auipc	s6,0x2
ffffffffc0200342:	daab0b13          	addi	s6,s6,-598 # ffffffffc02020e8 <etext+0x240>
        argv[argc ++] = buf;
ffffffffc0200346:	00002a17          	auipc	s4,0x2
ffffffffc020034a:	cc2a0a13          	addi	s4,s4,-830 # ffffffffc0202008 <etext+0x160>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034e:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200350:	854a                	mv	a0,s2
ffffffffc0200352:	253010ef          	jal	ra,ffffffffc0201da4 <readline>
ffffffffc0200356:	842a                	mv	s0,a0
ffffffffc0200358:	dd65                	beqz	a0,ffffffffc0200350 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020035e:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	e1bd                	bnez	a1,ffffffffc02003c6 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200362:	fe0c87e3          	beqz	s9,ffffffffc0200350 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200366:	6582                	ld	a1,0(sp)
ffffffffc0200368:	00002d17          	auipc	s10,0x2
ffffffffc020036c:	db8d0d13          	addi	s10,s10,-584 # ffffffffc0202120 <commands>
        argv[argc ++] = buf;
ffffffffc0200370:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200372:	4401                	li	s0,0
ffffffffc0200374:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200376:	5d4010ef          	jal	ra,ffffffffc020194a <strcmp>
ffffffffc020037a:	c919                	beqz	a0,ffffffffc0200390 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037c:	2405                	addiw	s0,s0,1
ffffffffc020037e:	0b540063          	beq	s0,s5,ffffffffc020041e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200382:	000d3503          	ld	a0,0(s10)
ffffffffc0200386:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200388:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020038a:	5c0010ef          	jal	ra,ffffffffc020194a <strcmp>
ffffffffc020038e:	f57d                	bnez	a0,ffffffffc020037c <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200390:	00141793          	slli	a5,s0,0x1
ffffffffc0200394:	97a2                	add	a5,a5,s0
ffffffffc0200396:	078e                	slli	a5,a5,0x3
ffffffffc0200398:	97e2                	add	a5,a5,s8
ffffffffc020039a:	6b9c                	ld	a5,16(a5)
ffffffffc020039c:	865e                	mv	a2,s7
ffffffffc020039e:	002c                	addi	a1,sp,8
ffffffffc02003a0:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003a4:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003a6:	fa0555e3          	bgez	a0,ffffffffc0200350 <kmonitor+0x6a>
}
ffffffffc02003aa:	60ee                	ld	ra,216(sp)
ffffffffc02003ac:	644e                	ld	s0,208(sp)
ffffffffc02003ae:	64ae                	ld	s1,200(sp)
ffffffffc02003b0:	690e                	ld	s2,192(sp)
ffffffffc02003b2:	79ea                	ld	s3,184(sp)
ffffffffc02003b4:	7a4a                	ld	s4,176(sp)
ffffffffc02003b6:	7aaa                	ld	s5,168(sp)
ffffffffc02003b8:	7b0a                	ld	s6,160(sp)
ffffffffc02003ba:	6bea                	ld	s7,152(sp)
ffffffffc02003bc:	6c4a                	ld	s8,144(sp)
ffffffffc02003be:	6caa                	ld	s9,136(sp)
ffffffffc02003c0:	6d0a                	ld	s10,128(sp)
ffffffffc02003c2:	612d                	addi	sp,sp,224
ffffffffc02003c4:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c6:	8526                	mv	a0,s1
ffffffffc02003c8:	5c6010ef          	jal	ra,ffffffffc020198e <strchr>
ffffffffc02003cc:	c901                	beqz	a0,ffffffffc02003dc <kmonitor+0xf6>
ffffffffc02003ce:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003d2:	00040023          	sb	zero,0(s0)
ffffffffc02003d6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d8:	d5c9                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc02003da:	b7f5                	j	ffffffffc02003c6 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003dc:	00044783          	lbu	a5,0(s0)
ffffffffc02003e0:	d3c9                	beqz	a5,ffffffffc0200362 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003e2:	033c8963          	beq	s9,s3,ffffffffc0200414 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003e6:	003c9793          	slli	a5,s9,0x3
ffffffffc02003ea:	0118                	addi	a4,sp,128
ffffffffc02003ec:	97ba                	add	a5,a5,a4
ffffffffc02003ee:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f2:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003f6:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f8:	e591                	bnez	a1,ffffffffc0200404 <kmonitor+0x11e>
ffffffffc02003fa:	b7b5                	j	ffffffffc0200366 <kmonitor+0x80>
ffffffffc02003fc:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200400:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200402:	d1a5                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc0200404:	8526                	mv	a0,s1
ffffffffc0200406:	588010ef          	jal	ra,ffffffffc020198e <strchr>
ffffffffc020040a:	d96d                	beqz	a0,ffffffffc02003fc <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020040c:	00044583          	lbu	a1,0(s0)
ffffffffc0200410:	d9a9                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc0200412:	bf55                	j	ffffffffc02003c6 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200414:	45c1                	li	a1,16
ffffffffc0200416:	855a                	mv	a0,s6
ffffffffc0200418:	cc1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020041c:	b7e9                	j	ffffffffc02003e6 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020041e:	6582                	ld	a1,0(sp)
ffffffffc0200420:	00002517          	auipc	a0,0x2
ffffffffc0200424:	ce850513          	addi	a0,a0,-792 # ffffffffc0202108 <etext+0x260>
ffffffffc0200428:	cb1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc020042c:	b715                	j	ffffffffc0200350 <kmonitor+0x6a>

ffffffffc020042e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020042e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200430:	00002517          	auipc	a0,0x2
ffffffffc0200434:	d3850513          	addi	a0,a0,-712 # ffffffffc0202168 <commands+0x48>
void dtb_init(void) {
ffffffffc0200438:	fc86                	sd	ra,120(sp)
ffffffffc020043a:	f8a2                	sd	s0,112(sp)
ffffffffc020043c:	e8d2                	sd	s4,80(sp)
ffffffffc020043e:	f4a6                	sd	s1,104(sp)
ffffffffc0200440:	f0ca                	sd	s2,96(sp)
ffffffffc0200442:	ecce                	sd	s3,88(sp)
ffffffffc0200444:	e4d6                	sd	s5,72(sp)
ffffffffc0200446:	e0da                	sd	s6,64(sp)
ffffffffc0200448:	fc5e                	sd	s7,56(sp)
ffffffffc020044a:	f862                	sd	s8,48(sp)
ffffffffc020044c:	f466                	sd	s9,40(sp)
ffffffffc020044e:	f06a                	sd	s10,32(sp)
ffffffffc0200450:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200452:	c87ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200456:	00006597          	auipc	a1,0x6
ffffffffc020045a:	baa5b583          	ld	a1,-1110(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc020045e:	00002517          	auipc	a0,0x2
ffffffffc0200462:	d1a50513          	addi	a0,a0,-742 # ffffffffc0202178 <commands+0x58>
ffffffffc0200466:	c73ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020046a:	00006417          	auipc	s0,0x6
ffffffffc020046e:	b9e40413          	addi	s0,s0,-1122 # ffffffffc0206008 <boot_dtb>
ffffffffc0200472:	600c                	ld	a1,0(s0)
ffffffffc0200474:	00002517          	auipc	a0,0x2
ffffffffc0200478:	d1450513          	addi	a0,a0,-748 # ffffffffc0202188 <commands+0x68>
ffffffffc020047c:	c5dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200480:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	d1c50513          	addi	a0,a0,-740 # ffffffffc02021a0 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc020048c:	120a0463          	beqz	s4,ffffffffc02005b4 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200490:	57f5                	li	a5,-3
ffffffffc0200492:	07fa                	slli	a5,a5,0x1e
ffffffffc0200494:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200498:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004a4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ac:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b4:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b6:	8ec9                	or	a3,a3,a0
ffffffffc02004b8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004bc:	1b7d                	addi	s6,s6,-1
ffffffffc02004be:	0167f7b3          	and	a5,a5,s6
ffffffffc02004c2:	8dd5                	or	a1,a1,a3
ffffffffc02004c4:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02004c6:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ca:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02004cc:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a5d>
ffffffffc02004d0:	10f59163          	bne	a1,a5,ffffffffc02005d2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02004d4:	471c                	lw	a5,8(a4)
ffffffffc02004d6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02004d8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004da:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004de:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02004e2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fa:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fe:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200502:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	01146433          	or	s0,s0,a7
ffffffffc0200508:	0086969b          	slliw	a3,a3,0x8
ffffffffc020050c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200510:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200516:	8c49                	or	s0,s0,a0
ffffffffc0200518:	0166f6b3          	and	a3,a3,s6
ffffffffc020051c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200520:	0167f7b3          	and	a5,a5,s6
ffffffffc0200524:	8c55                	or	s0,s0,a3
ffffffffc0200526:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020052a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020052c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020052e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200530:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200534:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200536:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200538:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020053c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020053e:	00002917          	auipc	s2,0x2
ffffffffc0200542:	cb290913          	addi	s2,s2,-846 # ffffffffc02021f0 <commands+0xd0>
ffffffffc0200546:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200548:	4d91                	li	s11,4
ffffffffc020054a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020054c:	00002497          	auipc	s1,0x2
ffffffffc0200550:	c9c48493          	addi	s1,s1,-868 # ffffffffc02021e8 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200554:	000a2703          	lw	a4,0(s4)
ffffffffc0200558:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200560:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200564:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200568:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200570:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200572:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200576:	0087171b          	slliw	a4,a4,0x8
ffffffffc020057a:	8fd5                	or	a5,a5,a3
ffffffffc020057c:	00eb7733          	and	a4,s6,a4
ffffffffc0200580:	8fd9                	or	a5,a5,a4
ffffffffc0200582:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200584:	09778c63          	beq	a5,s7,ffffffffc020061c <dtb_init+0x1ee>
ffffffffc0200588:	00fbea63          	bltu	s7,a5,ffffffffc020059c <dtb_init+0x16e>
ffffffffc020058c:	07a78663          	beq	a5,s10,ffffffffc02005f8 <dtb_init+0x1ca>
ffffffffc0200590:	4709                	li	a4,2
ffffffffc0200592:	00e79763          	bne	a5,a4,ffffffffc02005a0 <dtb_init+0x172>
ffffffffc0200596:	4c81                	li	s9,0
ffffffffc0200598:	8a56                	mv	s4,s5
ffffffffc020059a:	bf6d                	j	ffffffffc0200554 <dtb_init+0x126>
ffffffffc020059c:	ffb78ee3          	beq	a5,s11,ffffffffc0200598 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005a0:	00002517          	auipc	a0,0x2
ffffffffc02005a4:	cc850513          	addi	a0,a0,-824 # ffffffffc0202268 <commands+0x148>
ffffffffc02005a8:	b31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	cf450513          	addi	a0,a0,-780 # ffffffffc02022a0 <commands+0x180>
}
ffffffffc02005b4:	7446                	ld	s0,112(sp)
ffffffffc02005b6:	70e6                	ld	ra,120(sp)
ffffffffc02005b8:	74a6                	ld	s1,104(sp)
ffffffffc02005ba:	7906                	ld	s2,96(sp)
ffffffffc02005bc:	69e6                	ld	s3,88(sp)
ffffffffc02005be:	6a46                	ld	s4,80(sp)
ffffffffc02005c0:	6aa6                	ld	s5,72(sp)
ffffffffc02005c2:	6b06                	ld	s6,64(sp)
ffffffffc02005c4:	7be2                	ld	s7,56(sp)
ffffffffc02005c6:	7c42                	ld	s8,48(sp)
ffffffffc02005c8:	7ca2                	ld	s9,40(sp)
ffffffffc02005ca:	7d02                	ld	s10,32(sp)
ffffffffc02005cc:	6de2                	ld	s11,24(sp)
ffffffffc02005ce:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02005d0:	b621                	j	ffffffffc02000d8 <cprintf>
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
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	bd450513          	addi	a0,a0,-1068 # ffffffffc02021c0 <commands+0xa0>
}
ffffffffc02005f4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005f6:	b4cd                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc02005f8:	8556                	mv	a0,s5
ffffffffc02005fa:	31a010ef          	jal	ra,ffffffffc0201914 <strlen>
ffffffffc02005fe:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200600:	4619                	li	a2,6
ffffffffc0200602:	85a6                	mv	a1,s1
ffffffffc0200604:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200606:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200608:	360010ef          	jal	ra,ffffffffc0201968 <strncmp>
ffffffffc020060c:	e111                	bnez	a0,ffffffffc0200610 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020060e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200610:	0a91                	addi	s5,s5,4
ffffffffc0200612:	9ad2                	add	s5,s5,s4
ffffffffc0200614:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200618:	8a56                	mv	s4,s5
ffffffffc020061a:	bf2d                	j	ffffffffc0200554 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020061c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200620:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200624:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200628:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200630:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200634:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200638:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200640:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200644:	00eaeab3          	or	s5,s5,a4
ffffffffc0200648:	00fb77b3          	and	a5,s6,a5
ffffffffc020064c:	00faeab3          	or	s5,s5,a5
ffffffffc0200650:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200652:	000c9c63          	bnez	s9,ffffffffc020066a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200656:	1a82                	slli	s5,s5,0x20
ffffffffc0200658:	00368793          	addi	a5,a3,3
ffffffffc020065c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200660:	9abe                	add	s5,s5,a5
ffffffffc0200662:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200666:	8a56                	mv	s4,s5
ffffffffc0200668:	b5f5                	j	ffffffffc0200554 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020066a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020066e:	85ca                	mv	a1,s2
ffffffffc0200670:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020067e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200682:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200686:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200688:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020068c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200690:	8d59                	or	a0,a0,a4
ffffffffc0200692:	00fb77b3          	and	a5,s6,a5
ffffffffc0200696:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200698:	1502                	slli	a0,a0,0x20
ffffffffc020069a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020069c:	9522                	add	a0,a0,s0
ffffffffc020069e:	2ac010ef          	jal	ra,ffffffffc020194a <strcmp>
ffffffffc02006a2:	66a2                	ld	a3,8(sp)
ffffffffc02006a4:	f94d                	bnez	a0,ffffffffc0200656 <dtb_init+0x228>
ffffffffc02006a6:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200656 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006aa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006ae:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006b2:	00002517          	auipc	a0,0x2
ffffffffc02006b6:	b4650513          	addi	a0,a0,-1210 # ffffffffc02021f8 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc02006ba:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02006c2:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02006ca:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ce:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d6:	0187d693          	srli	a3,a5,0x18
ffffffffc02006da:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02006de:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006e2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02006ea:	010f6f33          	or	t5,t5,a6
ffffffffc02006ee:	0187529b          	srliw	t0,a4,0x18
ffffffffc02006f2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006fa:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fe:	0186f6b3          	and	a3,a3,s8
ffffffffc0200702:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200706:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020070e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	8361                	srli	a4,a4,0x18
ffffffffc0200714:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200718:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020071c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200720:	00cb7633          	and	a2,s6,a2
ffffffffc0200724:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200728:	0085959b          	slliw	a1,a1,0x8
ffffffffc020072c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200730:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200740:	011b78b3          	and	a7,s6,a7
ffffffffc0200744:	005eeeb3          	or	t4,t4,t0
ffffffffc0200748:	00c6e733          	or	a4,a3,a2
ffffffffc020074c:	006c6c33          	or	s8,s8,t1
ffffffffc0200750:	010b76b3          	and	a3,s6,a6
ffffffffc0200754:	00bb7b33          	and	s6,s6,a1
ffffffffc0200758:	01d7e7b3          	or	a5,a5,t4
ffffffffc020075c:	016c6b33          	or	s6,s8,s6
ffffffffc0200760:	01146433          	or	s0,s0,a7
ffffffffc0200764:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200766:	1702                	slli	a4,a4,0x20
ffffffffc0200768:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020076a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020076c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020076e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200770:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200774:	0167eb33          	or	s6,a5,s6
ffffffffc0200778:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020077a:	95fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020077e:	85a2                	mv	a1,s0
ffffffffc0200780:	00002517          	auipc	a0,0x2
ffffffffc0200784:	a9850513          	addi	a0,a0,-1384 # ffffffffc0202218 <commands+0xf8>
ffffffffc0200788:	951ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020078c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200790:	85da                	mv	a1,s6
ffffffffc0200792:	00002517          	auipc	a0,0x2
ffffffffc0200796:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0202230 <commands+0x110>
ffffffffc020079a:	93fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020079e:	008b05b3          	add	a1,s6,s0
ffffffffc02007a2:	15fd                	addi	a1,a1,-1
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	aac50513          	addi	a0,a0,-1364 # ffffffffc0202250 <commands+0x130>
ffffffffc02007ac:	92dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	af050513          	addi	a0,a0,-1296 # ffffffffc02022a0 <commands+0x180>
        memory_base = mem_base;
ffffffffc02007b8:	00006797          	auipc	a5,0x6
ffffffffc02007bc:	c887b423          	sd	s0,-888(a5) # ffffffffc0206440 <memory_base>
        memory_size = mem_size;
ffffffffc02007c0:	00006797          	auipc	a5,0x6
ffffffffc02007c4:	c967b423          	sd	s6,-888(a5) # ffffffffc0206448 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007c8:	b3f5                	j	ffffffffc02005b4 <dtb_init+0x186>

ffffffffc02007ca <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007ca:	00006517          	auipc	a0,0x6
ffffffffc02007ce:	c7653503          	ld	a0,-906(a0) # ffffffffc0206440 <memory_base>
ffffffffc02007d2:	8082                	ret

ffffffffc02007d4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007d4:	00006517          	auipc	a0,0x6
ffffffffc02007d8:	c7453503          	ld	a0,-908(a0) # ffffffffc0206448 <memory_size>
ffffffffc02007dc:	8082                	ret

ffffffffc02007de <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc02007de:	1141                	addi	sp,sp,-16
ffffffffc02007e0:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc02007e2:	02000793          	li	a5,32
ffffffffc02007e6:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02007ea:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02007ee:	67e1                	lui	a5,0x18
ffffffffc02007f0:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02007f4:	953e                	add	a0,a0,a5
ffffffffc02007f6:	67c010ef          	jal	ra,ffffffffc0201e72 <sbi_set_timer>
}
ffffffffc02007fa:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc02007fc:	00006797          	auipc	a5,0x6
ffffffffc0200800:	c407ba23          	sd	zero,-940(a5) # ffffffffc0206450 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200804:	00002517          	auipc	a0,0x2
ffffffffc0200808:	ab450513          	addi	a0,a0,-1356 # ffffffffc02022b8 <commands+0x198>
}
ffffffffc020080c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020080e:	8cbff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200812 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200814:	0ff57513          	zext.b	a0,a0
ffffffffc0200818:	6400106f          	j	ffffffffc0201e58 <sbi_console_putchar>

ffffffffc020081c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020081c:	6700106f          	j	ffffffffc0201e8c <sbi_console_getchar>

ffffffffc0200820 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200820:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200824:	8082                	ret

ffffffffc0200826 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200826:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020082a:	8082                	ret

ffffffffc020082c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020082c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200830:	00000797          	auipc	a5,0x0
ffffffffc0200834:	2c078793          	addi	a5,a5,704 # ffffffffc0200af0 <__alltraps>
ffffffffc0200838:	10579073          	csrw	stvec,a5
}
ffffffffc020083c:	8082                	ret

ffffffffc020083e <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020083e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200840:	1141                	addi	sp,sp,-16
ffffffffc0200842:	e022                	sd	s0,0(sp)
ffffffffc0200844:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200846:	00002517          	auipc	a0,0x2
ffffffffc020084a:	a9250513          	addi	a0,a0,-1390 # ffffffffc02022d8 <commands+0x1b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020084e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200850:	889ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200854:	640c                	ld	a1,8(s0)
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02022f0 <commands+0x1d0>
ffffffffc020085e:	87bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200862:	680c                	ld	a1,16(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	aa450513          	addi	a0,a0,-1372 # ffffffffc0202308 <commands+0x1e8>
ffffffffc020086c:	86dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200870:	6c0c                	ld	a1,24(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	aae50513          	addi	a0,a0,-1362 # ffffffffc0202320 <commands+0x200>
ffffffffc020087a:	85fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020087e:	700c                	ld	a1,32(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	ab850513          	addi	a0,a0,-1352 # ffffffffc0202338 <commands+0x218>
ffffffffc0200888:	851ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020088c:	740c                	ld	a1,40(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	ac250513          	addi	a0,a0,-1342 # ffffffffc0202350 <commands+0x230>
ffffffffc0200896:	843ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020089a:	780c                	ld	a1,48(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	acc50513          	addi	a0,a0,-1332 # ffffffffc0202368 <commands+0x248>
ffffffffc02008a4:	835ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008a8:	7c0c                	ld	a1,56(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	ad650513          	addi	a0,a0,-1322 # ffffffffc0202380 <commands+0x260>
ffffffffc02008b2:	827ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008b6:	602c                	ld	a1,64(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202398 <commands+0x278>
ffffffffc02008c0:	819ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008c4:	642c                	ld	a1,72(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	aea50513          	addi	a0,a0,-1302 # ffffffffc02023b0 <commands+0x290>
ffffffffc02008ce:	80bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008d2:	682c                	ld	a1,80(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	af450513          	addi	a0,a0,-1292 # ffffffffc02023c8 <commands+0x2a8>
ffffffffc02008dc:	ffcff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008e0:	6c2c                	ld	a1,88(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	afe50513          	addi	a0,a0,-1282 # ffffffffc02023e0 <commands+0x2c0>
ffffffffc02008ea:	feeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008ee:	702c                	ld	a1,96(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	b0850513          	addi	a0,a0,-1272 # ffffffffc02023f8 <commands+0x2d8>
ffffffffc02008f8:	fe0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008fc:	742c                	ld	a1,104(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	b1250513          	addi	a0,a0,-1262 # ffffffffc0202410 <commands+0x2f0>
ffffffffc0200906:	fd2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020090a:	782c                	ld	a1,112(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0202428 <commands+0x308>
ffffffffc0200914:	fc4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200918:	7c2c                	ld	a1,120(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	b2650513          	addi	a0,a0,-1242 # ffffffffc0202440 <commands+0x320>
ffffffffc0200922:	fb6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200926:	604c                	ld	a1,128(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	b3050513          	addi	a0,a0,-1232 # ffffffffc0202458 <commands+0x338>
ffffffffc0200930:	fa8ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200934:	644c                	ld	a1,136(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202470 <commands+0x350>
ffffffffc020093e:	f9aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200942:	684c                	ld	a1,144(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	b4450513          	addi	a0,a0,-1212 # ffffffffc0202488 <commands+0x368>
ffffffffc020094c:	f8cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200950:	6c4c                	ld	a1,152(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	b4e50513          	addi	a0,a0,-1202 # ffffffffc02024a0 <commands+0x380>
ffffffffc020095a:	f7eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020095e:	704c                	ld	a1,160(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	b5850513          	addi	a0,a0,-1192 # ffffffffc02024b8 <commands+0x398>
ffffffffc0200968:	f70ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020096c:	744c                	ld	a1,168(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	b6250513          	addi	a0,a0,-1182 # ffffffffc02024d0 <commands+0x3b0>
ffffffffc0200976:	f62ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020097a:	784c                	ld	a1,176(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	b6c50513          	addi	a0,a0,-1172 # ffffffffc02024e8 <commands+0x3c8>
ffffffffc0200984:	f54ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200988:	7c4c                	ld	a1,184(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	b7650513          	addi	a0,a0,-1162 # ffffffffc0202500 <commands+0x3e0>
ffffffffc0200992:	f46ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200996:	606c                	ld	a1,192(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	b8050513          	addi	a0,a0,-1152 # ffffffffc0202518 <commands+0x3f8>
ffffffffc02009a0:	f38ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009a4:	646c                	ld	a1,200(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0202530 <commands+0x410>
ffffffffc02009ae:	f2aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009b2:	686c                	ld	a1,208(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202548 <commands+0x428>
ffffffffc02009bc:	f1cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009c0:	6c6c                	ld	a1,216(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0202560 <commands+0x440>
ffffffffc02009ca:	f0eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009ce:	706c                	ld	a1,224(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202578 <commands+0x458>
ffffffffc02009d8:	f00ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009dc:	746c                	ld	a1,232(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202590 <commands+0x470>
ffffffffc02009e6:	ef2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009ea:	786c                	ld	a1,240(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02025a8 <commands+0x488>
ffffffffc02009f4:	ee4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009f8:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009fa:	6402                	ld	s0,0(sp)
ffffffffc02009fc:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009fe:	00002517          	auipc	a0,0x2
ffffffffc0200a02:	bc250513          	addi	a0,a0,-1086 # ffffffffc02025c0 <commands+0x4a0>
}
ffffffffc0200a06:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a08:	ed0ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a0c <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a0c:	1141                	addi	sp,sp,-16
ffffffffc0200a0e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a10:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a12:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a14:	00002517          	auipc	a0,0x2
ffffffffc0200a18:	bc450513          	addi	a0,a0,-1084 # ffffffffc02025d8 <commands+0x4b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a1e:	ebaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a22:	8522                	mv	a0,s0
ffffffffc0200a24:	e1bff0ef          	jal	ra,ffffffffc020083e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a28:	10043583          	ld	a1,256(s0)
ffffffffc0200a2c:	00002517          	auipc	a0,0x2
ffffffffc0200a30:	bc450513          	addi	a0,a0,-1084 # ffffffffc02025f0 <commands+0x4d0>
ffffffffc0200a34:	ea4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a38:	10843583          	ld	a1,264(s0)
ffffffffc0200a3c:	00002517          	auipc	a0,0x2
ffffffffc0200a40:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0202608 <commands+0x4e8>
ffffffffc0200a44:	e94ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a48:	11043583          	ld	a1,272(s0)
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	bd450513          	addi	a0,a0,-1068 # ffffffffc0202620 <commands+0x500>
ffffffffc0200a54:	e84ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a58:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a5c:	6402                	ld	s0,0(sp)
ffffffffc0200a5e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a60:	00002517          	auipc	a0,0x2
ffffffffc0200a64:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202638 <commands+0x518>
}
ffffffffc0200a68:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6a:	e6eff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a6e <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a6e:	11853783          	ld	a5,280(a0)
ffffffffc0200a72:	472d                	li	a4,11
ffffffffc0200a74:	0786                	slli	a5,a5,0x1
ffffffffc0200a76:	8385                	srli	a5,a5,0x1
ffffffffc0200a78:	06f76063          	bltu	a4,a5,ffffffffc0200ad8 <interrupt_handler+0x6a>
ffffffffc0200a7c:	00002717          	auipc	a4,0x2
ffffffffc0200a80:	c8c70713          	addi	a4,a4,-884 # ffffffffc0202708 <commands+0x5e8>
ffffffffc0200a84:	078a                	slli	a5,a5,0x2
ffffffffc0200a86:	97ba                	add	a5,a5,a4
ffffffffc0200a88:	439c                	lw	a5,0(a5)
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a8e:	00002517          	auipc	a0,0x2
ffffffffc0200a92:	c2250513          	addi	a0,a0,-990 # ffffffffc02026b0 <commands+0x590>
ffffffffc0200a96:	e42ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a9a:	00002517          	auipc	a0,0x2
ffffffffc0200a9e:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202690 <commands+0x570>
ffffffffc0200aa2:	e36ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200aa6:	00002517          	auipc	a0,0x2
ffffffffc0200aaa:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202650 <commands+0x530>
ffffffffc0200aae:	e2aff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ab2:	00002517          	auipc	a0,0x2
ffffffffc0200ab6:	c1e50513          	addi	a0,a0,-994 # ffffffffc02026d0 <commands+0x5b0>
ffffffffc0200aba:	e1eff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200abe:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200ac0:	00002517          	auipc	a0,0x2
ffffffffc0200ac4:	c2850513          	addi	a0,a0,-984 # ffffffffc02026e8 <commands+0x5c8>
ffffffffc0200ac8:	e10ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200acc:	00002517          	auipc	a0,0x2
ffffffffc0200ad0:	ba450513          	addi	a0,a0,-1116 # ffffffffc0202670 <commands+0x550>
ffffffffc0200ad4:	e04ff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200ad8:	bf15                	j	ffffffffc0200a0c <print_trapframe>

ffffffffc0200ada <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ada:	11853783          	ld	a5,280(a0)
ffffffffc0200ade:	0007c763          	bltz	a5,ffffffffc0200aec <trap+0x12>
    switch (tf->cause) {
ffffffffc0200ae2:	472d                	li	a4,11
ffffffffc0200ae4:	00f76363          	bltu	a4,a5,ffffffffc0200aea <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200ae8:	8082                	ret
            print_trapframe(tf);
ffffffffc0200aea:	b70d                	j	ffffffffc0200a0c <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200aec:	b749                	j	ffffffffc0200a6e <interrupt_handler>
	...

ffffffffc0200af0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200af0:	14011073          	csrw	sscratch,sp
ffffffffc0200af4:	712d                	addi	sp,sp,-288
ffffffffc0200af6:	e002                	sd	zero,0(sp)
ffffffffc0200af8:	e406                	sd	ra,8(sp)
ffffffffc0200afa:	ec0e                	sd	gp,24(sp)
ffffffffc0200afc:	f012                	sd	tp,32(sp)
ffffffffc0200afe:	f416                	sd	t0,40(sp)
ffffffffc0200b00:	f81a                	sd	t1,48(sp)
ffffffffc0200b02:	fc1e                	sd	t2,56(sp)
ffffffffc0200b04:	e0a2                	sd	s0,64(sp)
ffffffffc0200b06:	e4a6                	sd	s1,72(sp)
ffffffffc0200b08:	e8aa                	sd	a0,80(sp)
ffffffffc0200b0a:	ecae                	sd	a1,88(sp)
ffffffffc0200b0c:	f0b2                	sd	a2,96(sp)
ffffffffc0200b0e:	f4b6                	sd	a3,104(sp)
ffffffffc0200b10:	f8ba                	sd	a4,112(sp)
ffffffffc0200b12:	fcbe                	sd	a5,120(sp)
ffffffffc0200b14:	e142                	sd	a6,128(sp)
ffffffffc0200b16:	e546                	sd	a7,136(sp)
ffffffffc0200b18:	e94a                	sd	s2,144(sp)
ffffffffc0200b1a:	ed4e                	sd	s3,152(sp)
ffffffffc0200b1c:	f152                	sd	s4,160(sp)
ffffffffc0200b1e:	f556                	sd	s5,168(sp)
ffffffffc0200b20:	f95a                	sd	s6,176(sp)
ffffffffc0200b22:	fd5e                	sd	s7,184(sp)
ffffffffc0200b24:	e1e2                	sd	s8,192(sp)
ffffffffc0200b26:	e5e6                	sd	s9,200(sp)
ffffffffc0200b28:	e9ea                	sd	s10,208(sp)
ffffffffc0200b2a:	edee                	sd	s11,216(sp)
ffffffffc0200b2c:	f1f2                	sd	t3,224(sp)
ffffffffc0200b2e:	f5f6                	sd	t4,232(sp)
ffffffffc0200b30:	f9fa                	sd	t5,240(sp)
ffffffffc0200b32:	fdfe                	sd	t6,248(sp)
ffffffffc0200b34:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200b38:	100024f3          	csrr	s1,sstatus
ffffffffc0200b3c:	14102973          	csrr	s2,sepc
ffffffffc0200b40:	143029f3          	csrr	s3,stval
ffffffffc0200b44:	14202a73          	csrr	s4,scause
ffffffffc0200b48:	e822                	sd	s0,16(sp)
ffffffffc0200b4a:	e226                	sd	s1,256(sp)
ffffffffc0200b4c:	e64a                	sd	s2,264(sp)
ffffffffc0200b4e:	ea4e                	sd	s3,272(sp)
ffffffffc0200b50:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b52:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b54:	f87ff0ef          	jal	ra,ffffffffc0200ada <trap>

ffffffffc0200b58 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b58:	6492                	ld	s1,256(sp)
ffffffffc0200b5a:	6932                	ld	s2,264(sp)
ffffffffc0200b5c:	10049073          	csrw	sstatus,s1
ffffffffc0200b60:	14191073          	csrw	sepc,s2
ffffffffc0200b64:	60a2                	ld	ra,8(sp)
ffffffffc0200b66:	61e2                	ld	gp,24(sp)
ffffffffc0200b68:	7202                	ld	tp,32(sp)
ffffffffc0200b6a:	72a2                	ld	t0,40(sp)
ffffffffc0200b6c:	7342                	ld	t1,48(sp)
ffffffffc0200b6e:	73e2                	ld	t2,56(sp)
ffffffffc0200b70:	6406                	ld	s0,64(sp)
ffffffffc0200b72:	64a6                	ld	s1,72(sp)
ffffffffc0200b74:	6546                	ld	a0,80(sp)
ffffffffc0200b76:	65e6                	ld	a1,88(sp)
ffffffffc0200b78:	7606                	ld	a2,96(sp)
ffffffffc0200b7a:	76a6                	ld	a3,104(sp)
ffffffffc0200b7c:	7746                	ld	a4,112(sp)
ffffffffc0200b7e:	77e6                	ld	a5,120(sp)
ffffffffc0200b80:	680a                	ld	a6,128(sp)
ffffffffc0200b82:	68aa                	ld	a7,136(sp)
ffffffffc0200b84:	694a                	ld	s2,144(sp)
ffffffffc0200b86:	69ea                	ld	s3,152(sp)
ffffffffc0200b88:	7a0a                	ld	s4,160(sp)
ffffffffc0200b8a:	7aaa                	ld	s5,168(sp)
ffffffffc0200b8c:	7b4a                	ld	s6,176(sp)
ffffffffc0200b8e:	7bea                	ld	s7,184(sp)
ffffffffc0200b90:	6c0e                	ld	s8,192(sp)
ffffffffc0200b92:	6cae                	ld	s9,200(sp)
ffffffffc0200b94:	6d4e                	ld	s10,208(sp)
ffffffffc0200b96:	6dee                	ld	s11,216(sp)
ffffffffc0200b98:	7e0e                	ld	t3,224(sp)
ffffffffc0200b9a:	7eae                	ld	t4,232(sp)
ffffffffc0200b9c:	7f4e                	ld	t5,240(sp)
ffffffffc0200b9e:	7fee                	ld	t6,248(sp)
ffffffffc0200ba0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200ba2:	10200073          	sret

ffffffffc0200ba6 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200ba6:	100027f3          	csrr	a5,sstatus
ffffffffc0200baa:	8b89                	andi	a5,a5,2
ffffffffc0200bac:	e799                	bnez	a5,ffffffffc0200bba <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200bae:	00006797          	auipc	a5,0x6
ffffffffc0200bb2:	8ba7b783          	ld	a5,-1862(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0200bb6:	6f9c                	ld	a5,24(a5)
ffffffffc0200bb8:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200bba:	1141                	addi	sp,sp,-16
ffffffffc0200bbc:	e406                	sd	ra,8(sp)
ffffffffc0200bbe:	e022                	sd	s0,0(sp)
ffffffffc0200bc0:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200bc2:	c65ff0ef          	jal	ra,ffffffffc0200826 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200bc6:	00006797          	auipc	a5,0x6
ffffffffc0200bca:	8a27b783          	ld	a5,-1886(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0200bce:	6f9c                	ld	a5,24(a5)
ffffffffc0200bd0:	8522                	mv	a0,s0
ffffffffc0200bd2:	9782                	jalr	a5
ffffffffc0200bd4:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200bd6:	c4bff0ef          	jal	ra,ffffffffc0200820 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200bda:	60a2                	ld	ra,8(sp)
ffffffffc0200bdc:	8522                	mv	a0,s0
ffffffffc0200bde:	6402                	ld	s0,0(sp)
ffffffffc0200be0:	0141                	addi	sp,sp,16
ffffffffc0200be2:	8082                	ret

ffffffffc0200be4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200be4:	100027f3          	csrr	a5,sstatus
ffffffffc0200be8:	8b89                	andi	a5,a5,2
ffffffffc0200bea:	e799                	bnez	a5,ffffffffc0200bf8 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200bec:	00006797          	auipc	a5,0x6
ffffffffc0200bf0:	87c7b783          	ld	a5,-1924(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0200bf4:	739c                	ld	a5,32(a5)
ffffffffc0200bf6:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200bf8:	1101                	addi	sp,sp,-32
ffffffffc0200bfa:	ec06                	sd	ra,24(sp)
ffffffffc0200bfc:	e822                	sd	s0,16(sp)
ffffffffc0200bfe:	e426                	sd	s1,8(sp)
ffffffffc0200c00:	842a                	mv	s0,a0
ffffffffc0200c02:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200c04:	c23ff0ef          	jal	ra,ffffffffc0200826 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200c08:	00006797          	auipc	a5,0x6
ffffffffc0200c0c:	8607b783          	ld	a5,-1952(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0200c10:	739c                	ld	a5,32(a5)
ffffffffc0200c12:	85a6                	mv	a1,s1
ffffffffc0200c14:	8522                	mv	a0,s0
ffffffffc0200c16:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200c18:	6442                	ld	s0,16(sp)
ffffffffc0200c1a:	60e2                	ld	ra,24(sp)
ffffffffc0200c1c:	64a2                	ld	s1,8(sp)
ffffffffc0200c1e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200c20:	b101                	j	ffffffffc0200820 <intr_enable>

ffffffffc0200c22 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200c22:	100027f3          	csrr	a5,sstatus
ffffffffc0200c26:	8b89                	andi	a5,a5,2
ffffffffc0200c28:	e799                	bnez	a5,ffffffffc0200c36 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200c2a:	00006797          	auipc	a5,0x6
ffffffffc0200c2e:	83e7b783          	ld	a5,-1986(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0200c32:	779c                	ld	a5,40(a5)
ffffffffc0200c34:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200c36:	1141                	addi	sp,sp,-16
ffffffffc0200c38:	e406                	sd	ra,8(sp)
ffffffffc0200c3a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200c3c:	bebff0ef          	jal	ra,ffffffffc0200826 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200c40:	00006797          	auipc	a5,0x6
ffffffffc0200c44:	8287b783          	ld	a5,-2008(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0200c48:	779c                	ld	a5,40(a5)
ffffffffc0200c4a:	9782                	jalr	a5
ffffffffc0200c4c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200c4e:	bd3ff0ef          	jal	ra,ffffffffc0200820 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200c52:	60a2                	ld	ra,8(sp)
ffffffffc0200c54:	8522                	mv	a0,s0
ffffffffc0200c56:	6402                	ld	s0,0(sp)
ffffffffc0200c58:	0141                	addi	sp,sp,16
ffffffffc0200c5a:	8082                	ret

ffffffffc0200c5c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0200c5c:	00002797          	auipc	a5,0x2
ffffffffc0200c60:	fe478793          	addi	a5,a5,-28 # ffffffffc0202c40 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c64:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200c66:	7179                	addi	sp,sp,-48
ffffffffc0200c68:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c6a:	00002517          	auipc	a0,0x2
ffffffffc0200c6e:	ace50513          	addi	a0,a0,-1330 # ffffffffc0202738 <commands+0x618>
    pmm_manager = &default_pmm_manager;
ffffffffc0200c72:	00005417          	auipc	s0,0x5
ffffffffc0200c76:	7f640413          	addi	s0,s0,2038 # ffffffffc0206468 <pmm_manager>
void pmm_init(void) {
ffffffffc0200c7a:	f406                	sd	ra,40(sp)
ffffffffc0200c7c:	ec26                	sd	s1,24(sp)
ffffffffc0200c7e:	e44e                	sd	s3,8(sp)
ffffffffc0200c80:	e84a                	sd	s2,16(sp)
ffffffffc0200c82:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200c84:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c86:	c52ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0200c8a:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200c8c:	00005497          	auipc	s1,0x5
ffffffffc0200c90:	7f448493          	addi	s1,s1,2036 # ffffffffc0206480 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200c94:	679c                	ld	a5,8(a5)
ffffffffc0200c96:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200c98:	57f5                	li	a5,-3
ffffffffc0200c9a:	07fa                	slli	a5,a5,0x1e
ffffffffc0200c9c:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200c9e:	b2dff0ef          	jal	ra,ffffffffc02007ca <get_memory_base>
ffffffffc0200ca2:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200ca4:	b31ff0ef          	jal	ra,ffffffffc02007d4 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200ca8:	16050163          	beqz	a0,ffffffffc0200e0a <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200cac:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200cae:	00002517          	auipc	a0,0x2
ffffffffc0200cb2:	ad250513          	addi	a0,a0,-1326 # ffffffffc0202780 <commands+0x660>
ffffffffc0200cb6:	c22ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200cba:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200cbe:	864e                	mv	a2,s3
ffffffffc0200cc0:	fffa0693          	addi	a3,s4,-1
ffffffffc0200cc4:	85ca                	mv	a1,s2
ffffffffc0200cc6:	00002517          	auipc	a0,0x2
ffffffffc0200cca:	ad250513          	addi	a0,a0,-1326 # ffffffffc0202798 <commands+0x678>
ffffffffc0200cce:	c0aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200cd2:	c80007b7          	lui	a5,0xc8000
ffffffffc0200cd6:	8652                	mv	a2,s4
ffffffffc0200cd8:	0d47e863          	bltu	a5,s4,ffffffffc0200da8 <pmm_init+0x14c>
ffffffffc0200cdc:	00006797          	auipc	a5,0x6
ffffffffc0200ce0:	7b378793          	addi	a5,a5,1971 # ffffffffc020748f <end+0xfff>
ffffffffc0200ce4:	757d                	lui	a0,0xfffff
ffffffffc0200ce6:	8d7d                	and	a0,a0,a5
ffffffffc0200ce8:	8231                	srli	a2,a2,0xc
ffffffffc0200cea:	00005597          	auipc	a1,0x5
ffffffffc0200cee:	76e58593          	addi	a1,a1,1902 # ffffffffc0206458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200cf2:	00005817          	auipc	a6,0x5
ffffffffc0200cf6:	76e80813          	addi	a6,a6,1902 # ffffffffc0206460 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200cfa:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200cfc:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d00:	000807b7          	lui	a5,0x80
ffffffffc0200d04:	02f60663          	beq	a2,a5,ffffffffc0200d30 <pmm_init+0xd4>
ffffffffc0200d08:	4701                	li	a4,0
ffffffffc0200d0a:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d0c:	4305                	li	t1,1
ffffffffc0200d0e:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0200d12:	953a                	add	a0,a0,a4
ffffffffc0200d14:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b78>
ffffffffc0200d18:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d1c:	6190                	ld	a2,0(a1)
ffffffffc0200d1e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0200d20:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d24:	011606b3          	add	a3,a2,a7
ffffffffc0200d28:	02870713          	addi	a4,a4,40
ffffffffc0200d2c:	fed7e3e3          	bltu	a5,a3,ffffffffc0200d12 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d30:	00261693          	slli	a3,a2,0x2
ffffffffc0200d34:	96b2                	add	a3,a3,a2
ffffffffc0200d36:	fec007b7          	lui	a5,0xfec00
ffffffffc0200d3a:	97aa                	add	a5,a5,a0
ffffffffc0200d3c:	068e                	slli	a3,a3,0x3
ffffffffc0200d3e:	96be                	add	a3,a3,a5
ffffffffc0200d40:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d44:	0af6e763          	bltu	a3,a5,ffffffffc0200df2 <pmm_init+0x196>
ffffffffc0200d48:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200d4a:	77fd                	lui	a5,0xfffff
ffffffffc0200d4c:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d50:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200d52:	04b6ee63          	bltu	a3,a1,ffffffffc0200dae <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200d56:	601c                	ld	a5,0(s0)
ffffffffc0200d58:	7b9c                	ld	a5,48(a5)
ffffffffc0200d5a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200d5c:	00002517          	auipc	a0,0x2
ffffffffc0200d60:	ac450513          	addi	a0,a0,-1340 # ffffffffc0202820 <commands+0x700>
ffffffffc0200d64:	b74ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200d68:	00004597          	auipc	a1,0x4
ffffffffc0200d6c:	29858593          	addi	a1,a1,664 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200d70:	00005797          	auipc	a5,0x5
ffffffffc0200d74:	70b7b423          	sd	a1,1800(a5) # ffffffffc0206478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d78:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d7c:	0af5e363          	bltu	a1,a5,ffffffffc0200e22 <pmm_init+0x1c6>
ffffffffc0200d80:	6090                	ld	a2,0(s1)
}
ffffffffc0200d82:	7402                	ld	s0,32(sp)
ffffffffc0200d84:	70a2                	ld	ra,40(sp)
ffffffffc0200d86:	64e2                	ld	s1,24(sp)
ffffffffc0200d88:	6942                	ld	s2,16(sp)
ffffffffc0200d8a:	69a2                	ld	s3,8(sp)
ffffffffc0200d8c:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d8e:	40c58633          	sub	a2,a1,a2
ffffffffc0200d92:	00005797          	auipc	a5,0x5
ffffffffc0200d96:	6cc7bf23          	sd	a2,1758(a5) # ffffffffc0206470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200d9a:	00002517          	auipc	a0,0x2
ffffffffc0200d9e:	aa650513          	addi	a0,a0,-1370 # ffffffffc0202840 <commands+0x720>
}
ffffffffc0200da2:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200da4:	b34ff06f          	j	ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200da8:	c8000637          	lui	a2,0xc8000
ffffffffc0200dac:	bf05                	j	ffffffffc0200cdc <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200dae:	6705                	lui	a4,0x1
ffffffffc0200db0:	177d                	addi	a4,a4,-1
ffffffffc0200db2:	96ba                	add	a3,a3,a4
ffffffffc0200db4:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200db6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200dba:	02c7f063          	bgeu	a5,a2,ffffffffc0200dda <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0200dbe:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200dc0:	fff80737          	lui	a4,0xfff80
ffffffffc0200dc4:	973e                	add	a4,a4,a5
ffffffffc0200dc6:	00271793          	slli	a5,a4,0x2
ffffffffc0200dca:	97ba                	add	a5,a5,a4
ffffffffc0200dcc:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200dce:	8d95                	sub	a1,a1,a3
ffffffffc0200dd0:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200dd2:	81b1                	srli	a1,a1,0xc
ffffffffc0200dd4:	953e                	add	a0,a0,a5
ffffffffc0200dd6:	9702                	jalr	a4
}
ffffffffc0200dd8:	bfbd                	j	ffffffffc0200d56 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0200dda:	00002617          	auipc	a2,0x2
ffffffffc0200dde:	a1660613          	addi	a2,a2,-1514 # ffffffffc02027f0 <commands+0x6d0>
ffffffffc0200de2:	06b00593          	li	a1,107
ffffffffc0200de6:	00002517          	auipc	a0,0x2
ffffffffc0200dea:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0202810 <commands+0x6f0>
ffffffffc0200dee:	b72ff0ef          	jal	ra,ffffffffc0200160 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200df2:	00002617          	auipc	a2,0x2
ffffffffc0200df6:	9d660613          	addi	a2,a2,-1578 # ffffffffc02027c8 <commands+0x6a8>
ffffffffc0200dfa:	07100593          	li	a1,113
ffffffffc0200dfe:	00002517          	auipc	a0,0x2
ffffffffc0200e02:	97250513          	addi	a0,a0,-1678 # ffffffffc0202770 <commands+0x650>
ffffffffc0200e06:	b5aff0ef          	jal	ra,ffffffffc0200160 <__panic>
        panic("DTB memory info not available");
ffffffffc0200e0a:	00002617          	auipc	a2,0x2
ffffffffc0200e0e:	94660613          	addi	a2,a2,-1722 # ffffffffc0202750 <commands+0x630>
ffffffffc0200e12:	05a00593          	li	a1,90
ffffffffc0200e16:	00002517          	auipc	a0,0x2
ffffffffc0200e1a:	95a50513          	addi	a0,a0,-1702 # ffffffffc0202770 <commands+0x650>
ffffffffc0200e1e:	b42ff0ef          	jal	ra,ffffffffc0200160 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e22:	86ae                	mv	a3,a1
ffffffffc0200e24:	00002617          	auipc	a2,0x2
ffffffffc0200e28:	9a460613          	addi	a2,a2,-1628 # ffffffffc02027c8 <commands+0x6a8>
ffffffffc0200e2c:	08c00593          	li	a1,140
ffffffffc0200e30:	00002517          	auipc	a0,0x2
ffffffffc0200e34:	94050513          	addi	a0,a0,-1728 # ffffffffc0202770 <commands+0x650>
ffffffffc0200e38:	b28ff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200e3c <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e3c:	00005797          	auipc	a5,0x5
ffffffffc0200e40:	1e478793          	addi	a5,a5,484 # ffffffffc0206020 <free_area>
ffffffffc0200e44:	e79c                	sd	a5,8(a5)
ffffffffc0200e46:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e48:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e4c:	8082                	ret

ffffffffc0200e4e <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e4e:	00005517          	auipc	a0,0x5
ffffffffc0200e52:	1e256503          	lwu	a0,482(a0) # ffffffffc0206030 <free_area+0x10>
ffffffffc0200e56:	8082                	ret

ffffffffc0200e58 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e58:	715d                	addi	sp,sp,-80
ffffffffc0200e5a:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e5c:	00005417          	auipc	s0,0x5
ffffffffc0200e60:	1c440413          	addi	s0,s0,452 # ffffffffc0206020 <free_area>
ffffffffc0200e64:	641c                	ld	a5,8(s0)
ffffffffc0200e66:	e486                	sd	ra,72(sp)
ffffffffc0200e68:	fc26                	sd	s1,56(sp)
ffffffffc0200e6a:	f84a                	sd	s2,48(sp)
ffffffffc0200e6c:	f44e                	sd	s3,40(sp)
ffffffffc0200e6e:	f052                	sd	s4,32(sp)
ffffffffc0200e70:	ec56                	sd	s5,24(sp)
ffffffffc0200e72:	e85a                	sd	s6,16(sp)
ffffffffc0200e74:	e45e                	sd	s7,8(sp)
ffffffffc0200e76:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e78:	2c878763          	beq	a5,s0,ffffffffc0201146 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200e7c:	4481                	li	s1,0
ffffffffc0200e7e:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e80:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e84:	8b09                	andi	a4,a4,2
ffffffffc0200e86:	2c070463          	beqz	a4,ffffffffc020114e <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200e8a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e8e:	679c                	ld	a5,8(a5)
ffffffffc0200e90:	2905                	addiw	s2,s2,1
ffffffffc0200e92:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e94:	fe8796e3          	bne	a5,s0,ffffffffc0200e80 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e98:	89a6                	mv	s3,s1
ffffffffc0200e9a:	d89ff0ef          	jal	ra,ffffffffc0200c22 <nr_free_pages>
ffffffffc0200e9e:	71351863          	bne	a0,s3,ffffffffc02015ae <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ea2:	4505                	li	a0,1
ffffffffc0200ea4:	d03ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200ea8:	8a2a                	mv	s4,a0
ffffffffc0200eaa:	44050263          	beqz	a0,ffffffffc02012ee <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200eae:	4505                	li	a0,1
ffffffffc0200eb0:	cf7ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200eb4:	89aa                	mv	s3,a0
ffffffffc0200eb6:	70050c63          	beqz	a0,ffffffffc02015ce <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200eba:	4505                	li	a0,1
ffffffffc0200ebc:	cebff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200ec0:	8aaa                	mv	s5,a0
ffffffffc0200ec2:	4a050663          	beqz	a0,ffffffffc020136e <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ec6:	2b3a0463          	beq	s4,s3,ffffffffc020116e <default_check+0x316>
ffffffffc0200eca:	2aaa0263          	beq	s4,a0,ffffffffc020116e <default_check+0x316>
ffffffffc0200ece:	2aa98063          	beq	s3,a0,ffffffffc020116e <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ed2:	000a2783          	lw	a5,0(s4)
ffffffffc0200ed6:	2a079c63          	bnez	a5,ffffffffc020118e <default_check+0x336>
ffffffffc0200eda:	0009a783          	lw	a5,0(s3)
ffffffffc0200ede:	2a079863          	bnez	a5,ffffffffc020118e <default_check+0x336>
ffffffffc0200ee2:	411c                	lw	a5,0(a0)
ffffffffc0200ee4:	2a079563          	bnez	a5,ffffffffc020118e <default_check+0x336>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ee8:	00005797          	auipc	a5,0x5
ffffffffc0200eec:	5787b783          	ld	a5,1400(a5) # ffffffffc0206460 <pages>
ffffffffc0200ef0:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ef4:	870d                	srai	a4,a4,0x3
ffffffffc0200ef6:	00002597          	auipc	a1,0x2
ffffffffc0200efa:	fd25b583          	ld	a1,-46(a1) # ffffffffc0202ec8 <nbase+0x8>
ffffffffc0200efe:	02b70733          	mul	a4,a4,a1
ffffffffc0200f02:	00002617          	auipc	a2,0x2
ffffffffc0200f06:	fbe63603          	ld	a2,-66(a2) # ffffffffc0202ec0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f0a:	00005697          	auipc	a3,0x5
ffffffffc0200f0e:	54e6b683          	ld	a3,1358(a3) # ffffffffc0206458 <npage>
ffffffffc0200f12:	06b2                	slli	a3,a3,0xc
ffffffffc0200f14:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f16:	0732                	slli	a4,a4,0xc
ffffffffc0200f18:	28d77b63          	bgeu	a4,a3,ffffffffc02011ae <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f1c:	40f98733          	sub	a4,s3,a5
ffffffffc0200f20:	870d                	srai	a4,a4,0x3
ffffffffc0200f22:	02b70733          	mul	a4,a4,a1
ffffffffc0200f26:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f28:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f2a:	4cd77263          	bgeu	a4,a3,ffffffffc02013ee <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f2e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f32:	878d                	srai	a5,a5,0x3
ffffffffc0200f34:	02b787b3          	mul	a5,a5,a1
ffffffffc0200f38:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f3a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f3c:	30d7f963          	bgeu	a5,a3,ffffffffc020124e <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200f40:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f42:	00043c03          	ld	s8,0(s0)
ffffffffc0200f46:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f4a:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f4e:	e400                	sd	s0,8(s0)
ffffffffc0200f50:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f52:	00005797          	auipc	a5,0x5
ffffffffc0200f56:	0c07af23          	sw	zero,222(a5) # ffffffffc0206030 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f5a:	c4dff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200f5e:	2c051863          	bnez	a0,ffffffffc020122e <default_check+0x3d6>
    free_page(p0);
ffffffffc0200f62:	4585                	li	a1,1
ffffffffc0200f64:	8552                	mv	a0,s4
ffffffffc0200f66:	c7fff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    free_page(p1);
ffffffffc0200f6a:	4585                	li	a1,1
ffffffffc0200f6c:	854e                	mv	a0,s3
ffffffffc0200f6e:	c77ff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    free_page(p2);
ffffffffc0200f72:	4585                	li	a1,1
ffffffffc0200f74:	8556                	mv	a0,s5
ffffffffc0200f76:	c6fff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f7a:	4818                	lw	a4,16(s0)
ffffffffc0200f7c:	478d                	li	a5,3
ffffffffc0200f7e:	28f71863          	bne	a4,a5,ffffffffc020120e <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f82:	4505                	li	a0,1
ffffffffc0200f84:	c23ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200f88:	89aa                	mv	s3,a0
ffffffffc0200f8a:	26050263          	beqz	a0,ffffffffc02011ee <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f8e:	4505                	li	a0,1
ffffffffc0200f90:	c17ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200f94:	8aaa                	mv	s5,a0
ffffffffc0200f96:	3a050c63          	beqz	a0,ffffffffc020134e <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f9a:	4505                	li	a0,1
ffffffffc0200f9c:	c0bff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200fa0:	8a2a                	mv	s4,a0
ffffffffc0200fa2:	38050663          	beqz	a0,ffffffffc020132e <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200fa6:	4505                	li	a0,1
ffffffffc0200fa8:	bffff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200fac:	36051163          	bnez	a0,ffffffffc020130e <default_check+0x4b6>
    free_page(p0);
ffffffffc0200fb0:	4585                	li	a1,1
ffffffffc0200fb2:	854e                	mv	a0,s3
ffffffffc0200fb4:	c31ff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fb8:	641c                	ld	a5,8(s0)
ffffffffc0200fba:	20878a63          	beq	a5,s0,ffffffffc02011ce <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200fbe:	4505                	li	a0,1
ffffffffc0200fc0:	be7ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200fc4:	30a99563          	bne	s3,a0,ffffffffc02012ce <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200fc8:	4505                	li	a0,1
ffffffffc0200fca:	bddff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200fce:	2e051063          	bnez	a0,ffffffffc02012ae <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200fd2:	481c                	lw	a5,16(s0)
ffffffffc0200fd4:	2a079d63          	bnez	a5,ffffffffc020128e <default_check+0x436>
    free_page(p);
ffffffffc0200fd8:	854e                	mv	a0,s3
ffffffffc0200fda:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200fdc:	01843023          	sd	s8,0(s0)
ffffffffc0200fe0:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200fe4:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200fe8:	bfdff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    free_page(p1);
ffffffffc0200fec:	4585                	li	a1,1
ffffffffc0200fee:	8556                	mv	a0,s5
ffffffffc0200ff0:	bf5ff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    free_page(p2);
ffffffffc0200ff4:	4585                	li	a1,1
ffffffffc0200ff6:	8552                	mv	a0,s4
ffffffffc0200ff8:	bedff0ef          	jal	ra,ffffffffc0200be4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200ffc:	4515                	li	a0,5
ffffffffc0200ffe:	ba9ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201002:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201004:	26050563          	beqz	a0,ffffffffc020126e <default_check+0x416>
ffffffffc0201008:	651c                	ld	a5,8(a0)
ffffffffc020100a:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc020100c:	8b85                	andi	a5,a5,1
ffffffffc020100e:	54079063          	bnez	a5,ffffffffc020154e <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201012:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201014:	00043b03          	ld	s6,0(s0)
ffffffffc0201018:	00843a83          	ld	s5,8(s0)
ffffffffc020101c:	e000                	sd	s0,0(s0)
ffffffffc020101e:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201020:	b87ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201024:	50051563          	bnez	a0,ffffffffc020152e <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201028:	05098a13          	addi	s4,s3,80
ffffffffc020102c:	8552                	mv	a0,s4
ffffffffc020102e:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201030:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201034:	00005797          	auipc	a5,0x5
ffffffffc0201038:	fe07ae23          	sw	zero,-4(a5) # ffffffffc0206030 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020103c:	ba9ff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201040:	4511                	li	a0,4
ffffffffc0201042:	b65ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201046:	4c051463          	bnez	a0,ffffffffc020150e <default_check+0x6b6>
ffffffffc020104a:	0589b783          	ld	a5,88(s3)
ffffffffc020104e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201050:	8b85                	andi	a5,a5,1
ffffffffc0201052:	48078e63          	beqz	a5,ffffffffc02014ee <default_check+0x696>
ffffffffc0201056:	0609a703          	lw	a4,96(s3)
ffffffffc020105a:	478d                	li	a5,3
ffffffffc020105c:	48f71963          	bne	a4,a5,ffffffffc02014ee <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201060:	450d                	li	a0,3
ffffffffc0201062:	b45ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201066:	8c2a                	mv	s8,a0
ffffffffc0201068:	46050363          	beqz	a0,ffffffffc02014ce <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc020106c:	4505                	li	a0,1
ffffffffc020106e:	b39ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201072:	42051e63          	bnez	a0,ffffffffc02014ae <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0201076:	418a1c63          	bne	s4,s8,ffffffffc020148e <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020107a:	4585                	li	a1,1
ffffffffc020107c:	854e                	mv	a0,s3
ffffffffc020107e:	b67ff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    free_pages(p1, 3);
ffffffffc0201082:	458d                	li	a1,3
ffffffffc0201084:	8552                	mv	a0,s4
ffffffffc0201086:	b5fff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
ffffffffc020108a:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020108e:	02898c13          	addi	s8,s3,40
ffffffffc0201092:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201094:	8b85                	andi	a5,a5,1
ffffffffc0201096:	3c078c63          	beqz	a5,ffffffffc020146e <default_check+0x616>
ffffffffc020109a:	0109a703          	lw	a4,16(s3)
ffffffffc020109e:	4785                	li	a5,1
ffffffffc02010a0:	3cf71763          	bne	a4,a5,ffffffffc020146e <default_check+0x616>
ffffffffc02010a4:	008a3783          	ld	a5,8(s4)
ffffffffc02010a8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010aa:	8b85                	andi	a5,a5,1
ffffffffc02010ac:	3a078163          	beqz	a5,ffffffffc020144e <default_check+0x5f6>
ffffffffc02010b0:	010a2703          	lw	a4,16(s4)
ffffffffc02010b4:	478d                	li	a5,3
ffffffffc02010b6:	38f71c63          	bne	a4,a5,ffffffffc020144e <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010ba:	4505                	li	a0,1
ffffffffc02010bc:	aebff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02010c0:	36a99763          	bne	s3,a0,ffffffffc020142e <default_check+0x5d6>
    free_page(p0);
ffffffffc02010c4:	4585                	li	a1,1
ffffffffc02010c6:	b1fff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02010ca:	4509                	li	a0,2
ffffffffc02010cc:	adbff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02010d0:	32aa1f63          	bne	s4,a0,ffffffffc020140e <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc02010d4:	4589                	li	a1,2
ffffffffc02010d6:	b0fff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    free_page(p2);
ffffffffc02010da:	4585                	li	a1,1
ffffffffc02010dc:	8562                	mv	a0,s8
ffffffffc02010de:	b07ff0ef          	jal	ra,ffffffffc0200be4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02010e2:	4515                	li	a0,5
ffffffffc02010e4:	ac3ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02010e8:	89aa                	mv	s3,a0
ffffffffc02010ea:	48050263          	beqz	a0,ffffffffc020156e <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc02010ee:	4505                	li	a0,1
ffffffffc02010f0:	ab7ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02010f4:	2c051d63          	bnez	a0,ffffffffc02013ce <default_check+0x576>

    assert(nr_free == 0);
ffffffffc02010f8:	481c                	lw	a5,16(s0)
ffffffffc02010fa:	2a079a63          	bnez	a5,ffffffffc02013ae <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02010fe:	4595                	li	a1,5
ffffffffc0201100:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201102:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201106:	01643023          	sd	s6,0(s0)
ffffffffc020110a:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020110e:	ad7ff0ef          	jal	ra,ffffffffc0200be4 <free_pages>
    return listelm->next;
ffffffffc0201112:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201114:	00878963          	beq	a5,s0,ffffffffc0201126 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201118:	ff87a703          	lw	a4,-8(a5)
ffffffffc020111c:	679c                	ld	a5,8(a5)
ffffffffc020111e:	397d                	addiw	s2,s2,-1
ffffffffc0201120:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201122:	fe879be3          	bne	a5,s0,ffffffffc0201118 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0201126:	26091463          	bnez	s2,ffffffffc020138e <default_check+0x536>
    assert(total == 0);
ffffffffc020112a:	46049263          	bnez	s1,ffffffffc020158e <default_check+0x736>
}
ffffffffc020112e:	60a6                	ld	ra,72(sp)
ffffffffc0201130:	6406                	ld	s0,64(sp)
ffffffffc0201132:	74e2                	ld	s1,56(sp)
ffffffffc0201134:	7942                	ld	s2,48(sp)
ffffffffc0201136:	79a2                	ld	s3,40(sp)
ffffffffc0201138:	7a02                	ld	s4,32(sp)
ffffffffc020113a:	6ae2                	ld	s5,24(sp)
ffffffffc020113c:	6b42                	ld	s6,16(sp)
ffffffffc020113e:	6ba2                	ld	s7,8(sp)
ffffffffc0201140:	6c02                	ld	s8,0(sp)
ffffffffc0201142:	6161                	addi	sp,sp,80
ffffffffc0201144:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201146:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201148:	4481                	li	s1,0
ffffffffc020114a:	4901                	li	s2,0
ffffffffc020114c:	b3b9                	j	ffffffffc0200e9a <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020114e:	00001697          	auipc	a3,0x1
ffffffffc0201152:	73268693          	addi	a3,a3,1842 # ffffffffc0202880 <commands+0x760>
ffffffffc0201156:	00001617          	auipc	a2,0x1
ffffffffc020115a:	73a60613          	addi	a2,a2,1850 # ffffffffc0202890 <commands+0x770>
ffffffffc020115e:	0f000593          	li	a1,240
ffffffffc0201162:	00001517          	auipc	a0,0x1
ffffffffc0201166:	74650513          	addi	a0,a0,1862 # ffffffffc02028a8 <commands+0x788>
ffffffffc020116a:	ff7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020116e:	00001697          	auipc	a3,0x1
ffffffffc0201172:	7d268693          	addi	a3,a3,2002 # ffffffffc0202940 <commands+0x820>
ffffffffc0201176:	00001617          	auipc	a2,0x1
ffffffffc020117a:	71a60613          	addi	a2,a2,1818 # ffffffffc0202890 <commands+0x770>
ffffffffc020117e:	0bd00593          	li	a1,189
ffffffffc0201182:	00001517          	auipc	a0,0x1
ffffffffc0201186:	72650513          	addi	a0,a0,1830 # ffffffffc02028a8 <commands+0x788>
ffffffffc020118a:	fd7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020118e:	00001697          	auipc	a3,0x1
ffffffffc0201192:	7da68693          	addi	a3,a3,2010 # ffffffffc0202968 <commands+0x848>
ffffffffc0201196:	00001617          	auipc	a2,0x1
ffffffffc020119a:	6fa60613          	addi	a2,a2,1786 # ffffffffc0202890 <commands+0x770>
ffffffffc020119e:	0be00593          	li	a1,190
ffffffffc02011a2:	00001517          	auipc	a0,0x1
ffffffffc02011a6:	70650513          	addi	a0,a0,1798 # ffffffffc02028a8 <commands+0x788>
ffffffffc02011aa:	fb7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011ae:	00001697          	auipc	a3,0x1
ffffffffc02011b2:	7fa68693          	addi	a3,a3,2042 # ffffffffc02029a8 <commands+0x888>
ffffffffc02011b6:	00001617          	auipc	a2,0x1
ffffffffc02011ba:	6da60613          	addi	a2,a2,1754 # ffffffffc0202890 <commands+0x770>
ffffffffc02011be:	0c000593          	li	a1,192
ffffffffc02011c2:	00001517          	auipc	a0,0x1
ffffffffc02011c6:	6e650513          	addi	a0,a0,1766 # ffffffffc02028a8 <commands+0x788>
ffffffffc02011ca:	f97fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02011ce:	00002697          	auipc	a3,0x2
ffffffffc02011d2:	86268693          	addi	a3,a3,-1950 # ffffffffc0202a30 <commands+0x910>
ffffffffc02011d6:	00001617          	auipc	a2,0x1
ffffffffc02011da:	6ba60613          	addi	a2,a2,1722 # ffffffffc0202890 <commands+0x770>
ffffffffc02011de:	0d900593          	li	a1,217
ffffffffc02011e2:	00001517          	auipc	a0,0x1
ffffffffc02011e6:	6c650513          	addi	a0,a0,1734 # ffffffffc02028a8 <commands+0x788>
ffffffffc02011ea:	f77fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011ee:	00001697          	auipc	a3,0x1
ffffffffc02011f2:	6f268693          	addi	a3,a3,1778 # ffffffffc02028e0 <commands+0x7c0>
ffffffffc02011f6:	00001617          	auipc	a2,0x1
ffffffffc02011fa:	69a60613          	addi	a2,a2,1690 # ffffffffc0202890 <commands+0x770>
ffffffffc02011fe:	0d200593          	li	a1,210
ffffffffc0201202:	00001517          	auipc	a0,0x1
ffffffffc0201206:	6a650513          	addi	a0,a0,1702 # ffffffffc02028a8 <commands+0x788>
ffffffffc020120a:	f57fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 3);
ffffffffc020120e:	00002697          	auipc	a3,0x2
ffffffffc0201212:	81268693          	addi	a3,a3,-2030 # ffffffffc0202a20 <commands+0x900>
ffffffffc0201216:	00001617          	auipc	a2,0x1
ffffffffc020121a:	67a60613          	addi	a2,a2,1658 # ffffffffc0202890 <commands+0x770>
ffffffffc020121e:	0d000593          	li	a1,208
ffffffffc0201222:	00001517          	auipc	a0,0x1
ffffffffc0201226:	68650513          	addi	a0,a0,1670 # ffffffffc02028a8 <commands+0x788>
ffffffffc020122a:	f37fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020122e:	00001697          	auipc	a3,0x1
ffffffffc0201232:	7da68693          	addi	a3,a3,2010 # ffffffffc0202a08 <commands+0x8e8>
ffffffffc0201236:	00001617          	auipc	a2,0x1
ffffffffc020123a:	65a60613          	addi	a2,a2,1626 # ffffffffc0202890 <commands+0x770>
ffffffffc020123e:	0cb00593          	li	a1,203
ffffffffc0201242:	00001517          	auipc	a0,0x1
ffffffffc0201246:	66650513          	addi	a0,a0,1638 # ffffffffc02028a8 <commands+0x788>
ffffffffc020124a:	f17fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020124e:	00001697          	auipc	a3,0x1
ffffffffc0201252:	79a68693          	addi	a3,a3,1946 # ffffffffc02029e8 <commands+0x8c8>
ffffffffc0201256:	00001617          	auipc	a2,0x1
ffffffffc020125a:	63a60613          	addi	a2,a2,1594 # ffffffffc0202890 <commands+0x770>
ffffffffc020125e:	0c200593          	li	a1,194
ffffffffc0201262:	00001517          	auipc	a0,0x1
ffffffffc0201266:	64650513          	addi	a0,a0,1606 # ffffffffc02028a8 <commands+0x788>
ffffffffc020126a:	ef7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != NULL);
ffffffffc020126e:	00002697          	auipc	a3,0x2
ffffffffc0201272:	80a68693          	addi	a3,a3,-2038 # ffffffffc0202a78 <commands+0x958>
ffffffffc0201276:	00001617          	auipc	a2,0x1
ffffffffc020127a:	61a60613          	addi	a2,a2,1562 # ffffffffc0202890 <commands+0x770>
ffffffffc020127e:	0f800593          	li	a1,248
ffffffffc0201282:	00001517          	auipc	a0,0x1
ffffffffc0201286:	62650513          	addi	a0,a0,1574 # ffffffffc02028a8 <commands+0x788>
ffffffffc020128a:	ed7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc020128e:	00001697          	auipc	a3,0x1
ffffffffc0201292:	7da68693          	addi	a3,a3,2010 # ffffffffc0202a68 <commands+0x948>
ffffffffc0201296:	00001617          	auipc	a2,0x1
ffffffffc020129a:	5fa60613          	addi	a2,a2,1530 # ffffffffc0202890 <commands+0x770>
ffffffffc020129e:	0df00593          	li	a1,223
ffffffffc02012a2:	00001517          	auipc	a0,0x1
ffffffffc02012a6:	60650513          	addi	a0,a0,1542 # ffffffffc02028a8 <commands+0x788>
ffffffffc02012aa:	eb7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012ae:	00001697          	auipc	a3,0x1
ffffffffc02012b2:	75a68693          	addi	a3,a3,1882 # ffffffffc0202a08 <commands+0x8e8>
ffffffffc02012b6:	00001617          	auipc	a2,0x1
ffffffffc02012ba:	5da60613          	addi	a2,a2,1498 # ffffffffc0202890 <commands+0x770>
ffffffffc02012be:	0dd00593          	li	a1,221
ffffffffc02012c2:	00001517          	auipc	a0,0x1
ffffffffc02012c6:	5e650513          	addi	a0,a0,1510 # ffffffffc02028a8 <commands+0x788>
ffffffffc02012ca:	e97fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02012ce:	00001697          	auipc	a3,0x1
ffffffffc02012d2:	77a68693          	addi	a3,a3,1914 # ffffffffc0202a48 <commands+0x928>
ffffffffc02012d6:	00001617          	auipc	a2,0x1
ffffffffc02012da:	5ba60613          	addi	a2,a2,1466 # ffffffffc0202890 <commands+0x770>
ffffffffc02012de:	0dc00593          	li	a1,220
ffffffffc02012e2:	00001517          	auipc	a0,0x1
ffffffffc02012e6:	5c650513          	addi	a0,a0,1478 # ffffffffc02028a8 <commands+0x788>
ffffffffc02012ea:	e77fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012ee:	00001697          	auipc	a3,0x1
ffffffffc02012f2:	5f268693          	addi	a3,a3,1522 # ffffffffc02028e0 <commands+0x7c0>
ffffffffc02012f6:	00001617          	auipc	a2,0x1
ffffffffc02012fa:	59a60613          	addi	a2,a2,1434 # ffffffffc0202890 <commands+0x770>
ffffffffc02012fe:	0b900593          	li	a1,185
ffffffffc0201302:	00001517          	auipc	a0,0x1
ffffffffc0201306:	5a650513          	addi	a0,a0,1446 # ffffffffc02028a8 <commands+0x788>
ffffffffc020130a:	e57fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020130e:	00001697          	auipc	a3,0x1
ffffffffc0201312:	6fa68693          	addi	a3,a3,1786 # ffffffffc0202a08 <commands+0x8e8>
ffffffffc0201316:	00001617          	auipc	a2,0x1
ffffffffc020131a:	57a60613          	addi	a2,a2,1402 # ffffffffc0202890 <commands+0x770>
ffffffffc020131e:	0d600593          	li	a1,214
ffffffffc0201322:	00001517          	auipc	a0,0x1
ffffffffc0201326:	58650513          	addi	a0,a0,1414 # ffffffffc02028a8 <commands+0x788>
ffffffffc020132a:	e37fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020132e:	00001697          	auipc	a3,0x1
ffffffffc0201332:	5f268693          	addi	a3,a3,1522 # ffffffffc0202920 <commands+0x800>
ffffffffc0201336:	00001617          	auipc	a2,0x1
ffffffffc020133a:	55a60613          	addi	a2,a2,1370 # ffffffffc0202890 <commands+0x770>
ffffffffc020133e:	0d400593          	li	a1,212
ffffffffc0201342:	00001517          	auipc	a0,0x1
ffffffffc0201346:	56650513          	addi	a0,a0,1382 # ffffffffc02028a8 <commands+0x788>
ffffffffc020134a:	e17fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020134e:	00001697          	auipc	a3,0x1
ffffffffc0201352:	5b268693          	addi	a3,a3,1458 # ffffffffc0202900 <commands+0x7e0>
ffffffffc0201356:	00001617          	auipc	a2,0x1
ffffffffc020135a:	53a60613          	addi	a2,a2,1338 # ffffffffc0202890 <commands+0x770>
ffffffffc020135e:	0d300593          	li	a1,211
ffffffffc0201362:	00001517          	auipc	a0,0x1
ffffffffc0201366:	54650513          	addi	a0,a0,1350 # ffffffffc02028a8 <commands+0x788>
ffffffffc020136a:	df7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020136e:	00001697          	auipc	a3,0x1
ffffffffc0201372:	5b268693          	addi	a3,a3,1458 # ffffffffc0202920 <commands+0x800>
ffffffffc0201376:	00001617          	auipc	a2,0x1
ffffffffc020137a:	51a60613          	addi	a2,a2,1306 # ffffffffc0202890 <commands+0x770>
ffffffffc020137e:	0bb00593          	li	a1,187
ffffffffc0201382:	00001517          	auipc	a0,0x1
ffffffffc0201386:	52650513          	addi	a0,a0,1318 # ffffffffc02028a8 <commands+0x788>
ffffffffc020138a:	dd7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(count == 0);
ffffffffc020138e:	00002697          	auipc	a3,0x2
ffffffffc0201392:	83a68693          	addi	a3,a3,-1990 # ffffffffc0202bc8 <commands+0xaa8>
ffffffffc0201396:	00001617          	auipc	a2,0x1
ffffffffc020139a:	4fa60613          	addi	a2,a2,1274 # ffffffffc0202890 <commands+0x770>
ffffffffc020139e:	12500593          	li	a1,293
ffffffffc02013a2:	00001517          	auipc	a0,0x1
ffffffffc02013a6:	50650513          	addi	a0,a0,1286 # ffffffffc02028a8 <commands+0x788>
ffffffffc02013aa:	db7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc02013ae:	00001697          	auipc	a3,0x1
ffffffffc02013b2:	6ba68693          	addi	a3,a3,1722 # ffffffffc0202a68 <commands+0x948>
ffffffffc02013b6:	00001617          	auipc	a2,0x1
ffffffffc02013ba:	4da60613          	addi	a2,a2,1242 # ffffffffc0202890 <commands+0x770>
ffffffffc02013be:	11a00593          	li	a1,282
ffffffffc02013c2:	00001517          	auipc	a0,0x1
ffffffffc02013c6:	4e650513          	addi	a0,a0,1254 # ffffffffc02028a8 <commands+0x788>
ffffffffc02013ca:	d97fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013ce:	00001697          	auipc	a3,0x1
ffffffffc02013d2:	63a68693          	addi	a3,a3,1594 # ffffffffc0202a08 <commands+0x8e8>
ffffffffc02013d6:	00001617          	auipc	a2,0x1
ffffffffc02013da:	4ba60613          	addi	a2,a2,1210 # ffffffffc0202890 <commands+0x770>
ffffffffc02013de:	11800593          	li	a1,280
ffffffffc02013e2:	00001517          	auipc	a0,0x1
ffffffffc02013e6:	4c650513          	addi	a0,a0,1222 # ffffffffc02028a8 <commands+0x788>
ffffffffc02013ea:	d77fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02013ee:	00001697          	auipc	a3,0x1
ffffffffc02013f2:	5da68693          	addi	a3,a3,1498 # ffffffffc02029c8 <commands+0x8a8>
ffffffffc02013f6:	00001617          	auipc	a2,0x1
ffffffffc02013fa:	49a60613          	addi	a2,a2,1178 # ffffffffc0202890 <commands+0x770>
ffffffffc02013fe:	0c100593          	li	a1,193
ffffffffc0201402:	00001517          	auipc	a0,0x1
ffffffffc0201406:	4a650513          	addi	a0,a0,1190 # ffffffffc02028a8 <commands+0x788>
ffffffffc020140a:	d57fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020140e:	00001697          	auipc	a3,0x1
ffffffffc0201412:	77a68693          	addi	a3,a3,1914 # ffffffffc0202b88 <commands+0xa68>
ffffffffc0201416:	00001617          	auipc	a2,0x1
ffffffffc020141a:	47a60613          	addi	a2,a2,1146 # ffffffffc0202890 <commands+0x770>
ffffffffc020141e:	11200593          	li	a1,274
ffffffffc0201422:	00001517          	auipc	a0,0x1
ffffffffc0201426:	48650513          	addi	a0,a0,1158 # ffffffffc02028a8 <commands+0x788>
ffffffffc020142a:	d37fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020142e:	00001697          	auipc	a3,0x1
ffffffffc0201432:	73a68693          	addi	a3,a3,1850 # ffffffffc0202b68 <commands+0xa48>
ffffffffc0201436:	00001617          	auipc	a2,0x1
ffffffffc020143a:	45a60613          	addi	a2,a2,1114 # ffffffffc0202890 <commands+0x770>
ffffffffc020143e:	11000593          	li	a1,272
ffffffffc0201442:	00001517          	auipc	a0,0x1
ffffffffc0201446:	46650513          	addi	a0,a0,1126 # ffffffffc02028a8 <commands+0x788>
ffffffffc020144a:	d17fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020144e:	00001697          	auipc	a3,0x1
ffffffffc0201452:	6f268693          	addi	a3,a3,1778 # ffffffffc0202b40 <commands+0xa20>
ffffffffc0201456:	00001617          	auipc	a2,0x1
ffffffffc020145a:	43a60613          	addi	a2,a2,1082 # ffffffffc0202890 <commands+0x770>
ffffffffc020145e:	10e00593          	li	a1,270
ffffffffc0201462:	00001517          	auipc	a0,0x1
ffffffffc0201466:	44650513          	addi	a0,a0,1094 # ffffffffc02028a8 <commands+0x788>
ffffffffc020146a:	cf7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020146e:	00001697          	auipc	a3,0x1
ffffffffc0201472:	6aa68693          	addi	a3,a3,1706 # ffffffffc0202b18 <commands+0x9f8>
ffffffffc0201476:	00001617          	auipc	a2,0x1
ffffffffc020147a:	41a60613          	addi	a2,a2,1050 # ffffffffc0202890 <commands+0x770>
ffffffffc020147e:	10d00593          	li	a1,269
ffffffffc0201482:	00001517          	auipc	a0,0x1
ffffffffc0201486:	42650513          	addi	a0,a0,1062 # ffffffffc02028a8 <commands+0x788>
ffffffffc020148a:	cd7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020148e:	00001697          	auipc	a3,0x1
ffffffffc0201492:	67a68693          	addi	a3,a3,1658 # ffffffffc0202b08 <commands+0x9e8>
ffffffffc0201496:	00001617          	auipc	a2,0x1
ffffffffc020149a:	3fa60613          	addi	a2,a2,1018 # ffffffffc0202890 <commands+0x770>
ffffffffc020149e:	10800593          	li	a1,264
ffffffffc02014a2:	00001517          	auipc	a0,0x1
ffffffffc02014a6:	40650513          	addi	a0,a0,1030 # ffffffffc02028a8 <commands+0x788>
ffffffffc02014aa:	cb7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014ae:	00001697          	auipc	a3,0x1
ffffffffc02014b2:	55a68693          	addi	a3,a3,1370 # ffffffffc0202a08 <commands+0x8e8>
ffffffffc02014b6:	00001617          	auipc	a2,0x1
ffffffffc02014ba:	3da60613          	addi	a2,a2,986 # ffffffffc0202890 <commands+0x770>
ffffffffc02014be:	10700593          	li	a1,263
ffffffffc02014c2:	00001517          	auipc	a0,0x1
ffffffffc02014c6:	3e650513          	addi	a0,a0,998 # ffffffffc02028a8 <commands+0x788>
ffffffffc02014ca:	c97fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02014ce:	00001697          	auipc	a3,0x1
ffffffffc02014d2:	61a68693          	addi	a3,a3,1562 # ffffffffc0202ae8 <commands+0x9c8>
ffffffffc02014d6:	00001617          	auipc	a2,0x1
ffffffffc02014da:	3ba60613          	addi	a2,a2,954 # ffffffffc0202890 <commands+0x770>
ffffffffc02014de:	10600593          	li	a1,262
ffffffffc02014e2:	00001517          	auipc	a0,0x1
ffffffffc02014e6:	3c650513          	addi	a0,a0,966 # ffffffffc02028a8 <commands+0x788>
ffffffffc02014ea:	c77fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02014ee:	00001697          	auipc	a3,0x1
ffffffffc02014f2:	5ca68693          	addi	a3,a3,1482 # ffffffffc0202ab8 <commands+0x998>
ffffffffc02014f6:	00001617          	auipc	a2,0x1
ffffffffc02014fa:	39a60613          	addi	a2,a2,922 # ffffffffc0202890 <commands+0x770>
ffffffffc02014fe:	10500593          	li	a1,261
ffffffffc0201502:	00001517          	auipc	a0,0x1
ffffffffc0201506:	3a650513          	addi	a0,a0,934 # ffffffffc02028a8 <commands+0x788>
ffffffffc020150a:	c57fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020150e:	00001697          	auipc	a3,0x1
ffffffffc0201512:	59268693          	addi	a3,a3,1426 # ffffffffc0202aa0 <commands+0x980>
ffffffffc0201516:	00001617          	auipc	a2,0x1
ffffffffc020151a:	37a60613          	addi	a2,a2,890 # ffffffffc0202890 <commands+0x770>
ffffffffc020151e:	10400593          	li	a1,260
ffffffffc0201522:	00001517          	auipc	a0,0x1
ffffffffc0201526:	38650513          	addi	a0,a0,902 # ffffffffc02028a8 <commands+0x788>
ffffffffc020152a:	c37fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020152e:	00001697          	auipc	a3,0x1
ffffffffc0201532:	4da68693          	addi	a3,a3,1242 # ffffffffc0202a08 <commands+0x8e8>
ffffffffc0201536:	00001617          	auipc	a2,0x1
ffffffffc020153a:	35a60613          	addi	a2,a2,858 # ffffffffc0202890 <commands+0x770>
ffffffffc020153e:	0fe00593          	li	a1,254
ffffffffc0201542:	00001517          	auipc	a0,0x1
ffffffffc0201546:	36650513          	addi	a0,a0,870 # ffffffffc02028a8 <commands+0x788>
ffffffffc020154a:	c17fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!PageProperty(p0));
ffffffffc020154e:	00001697          	auipc	a3,0x1
ffffffffc0201552:	53a68693          	addi	a3,a3,1338 # ffffffffc0202a88 <commands+0x968>
ffffffffc0201556:	00001617          	auipc	a2,0x1
ffffffffc020155a:	33a60613          	addi	a2,a2,826 # ffffffffc0202890 <commands+0x770>
ffffffffc020155e:	0f900593          	li	a1,249
ffffffffc0201562:	00001517          	auipc	a0,0x1
ffffffffc0201566:	34650513          	addi	a0,a0,838 # ffffffffc02028a8 <commands+0x788>
ffffffffc020156a:	bf7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020156e:	00001697          	auipc	a3,0x1
ffffffffc0201572:	63a68693          	addi	a3,a3,1594 # ffffffffc0202ba8 <commands+0xa88>
ffffffffc0201576:	00001617          	auipc	a2,0x1
ffffffffc020157a:	31a60613          	addi	a2,a2,794 # ffffffffc0202890 <commands+0x770>
ffffffffc020157e:	11700593          	li	a1,279
ffffffffc0201582:	00001517          	auipc	a0,0x1
ffffffffc0201586:	32650513          	addi	a0,a0,806 # ffffffffc02028a8 <commands+0x788>
ffffffffc020158a:	bd7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == 0);
ffffffffc020158e:	00001697          	auipc	a3,0x1
ffffffffc0201592:	64a68693          	addi	a3,a3,1610 # ffffffffc0202bd8 <commands+0xab8>
ffffffffc0201596:	00001617          	auipc	a2,0x1
ffffffffc020159a:	2fa60613          	addi	a2,a2,762 # ffffffffc0202890 <commands+0x770>
ffffffffc020159e:	12600593          	li	a1,294
ffffffffc02015a2:	00001517          	auipc	a0,0x1
ffffffffc02015a6:	30650513          	addi	a0,a0,774 # ffffffffc02028a8 <commands+0x788>
ffffffffc02015aa:	bb7fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == nr_free_pages());
ffffffffc02015ae:	00001697          	auipc	a3,0x1
ffffffffc02015b2:	31268693          	addi	a3,a3,786 # ffffffffc02028c0 <commands+0x7a0>
ffffffffc02015b6:	00001617          	auipc	a2,0x1
ffffffffc02015ba:	2da60613          	addi	a2,a2,730 # ffffffffc0202890 <commands+0x770>
ffffffffc02015be:	0f300593          	li	a1,243
ffffffffc02015c2:	00001517          	auipc	a0,0x1
ffffffffc02015c6:	2e650513          	addi	a0,a0,742 # ffffffffc02028a8 <commands+0x788>
ffffffffc02015ca:	b97fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02015ce:	00001697          	auipc	a3,0x1
ffffffffc02015d2:	33268693          	addi	a3,a3,818 # ffffffffc0202900 <commands+0x7e0>
ffffffffc02015d6:	00001617          	auipc	a2,0x1
ffffffffc02015da:	2ba60613          	addi	a2,a2,698 # ffffffffc0202890 <commands+0x770>
ffffffffc02015de:	0ba00593          	li	a1,186
ffffffffc02015e2:	00001517          	auipc	a0,0x1
ffffffffc02015e6:	2c650513          	addi	a0,a0,710 # ffffffffc02028a8 <commands+0x788>
ffffffffc02015ea:	b77fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc02015ee <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02015ee:	1141                	addi	sp,sp,-16
ffffffffc02015f0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015f2:	14058a63          	beqz	a1,ffffffffc0201746 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02015f6:	00259693          	slli	a3,a1,0x2
ffffffffc02015fa:	96ae                	add	a3,a3,a1
ffffffffc02015fc:	068e                	slli	a3,a3,0x3
ffffffffc02015fe:	96aa                	add	a3,a3,a0
ffffffffc0201600:	87aa                	mv	a5,a0
ffffffffc0201602:	02d50263          	beq	a0,a3,ffffffffc0201626 <default_free_pages+0x38>
ffffffffc0201606:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201608:	8b05                	andi	a4,a4,1
ffffffffc020160a:	10071e63          	bnez	a4,ffffffffc0201726 <default_free_pages+0x138>
ffffffffc020160e:	6798                	ld	a4,8(a5)
ffffffffc0201610:	8b09                	andi	a4,a4,2
ffffffffc0201612:	10071a63          	bnez	a4,ffffffffc0201726 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0201616:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020161a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020161e:	02878793          	addi	a5,a5,40
ffffffffc0201622:	fed792e3          	bne	a5,a3,ffffffffc0201606 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201626:	2581                	sext.w	a1,a1
ffffffffc0201628:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020162a:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020162e:	4789                	li	a5,2
ffffffffc0201630:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201634:	00005697          	auipc	a3,0x5
ffffffffc0201638:	9ec68693          	addi	a3,a3,-1556 # ffffffffc0206020 <free_area>
ffffffffc020163c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020163e:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201640:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201644:	9db9                	addw	a1,a1,a4
ffffffffc0201646:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201648:	0ad78863          	beq	a5,a3,ffffffffc02016f8 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc020164c:	fe878713          	addi	a4,a5,-24
ffffffffc0201650:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201654:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201656:	00e56a63          	bltu	a0,a4,ffffffffc020166a <default_free_pages+0x7c>
    return listelm->next;
ffffffffc020165a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020165c:	06d70263          	beq	a4,a3,ffffffffc02016c0 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201660:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201662:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201666:	fee57ae3          	bgeu	a0,a4,ffffffffc020165a <default_free_pages+0x6c>
ffffffffc020166a:	c199                	beqz	a1,ffffffffc0201670 <default_free_pages+0x82>
ffffffffc020166c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201670:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201672:	e390                	sd	a2,0(a5)
ffffffffc0201674:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201676:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201678:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020167a:	02d70063          	beq	a4,a3,ffffffffc020169a <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc020167e:	ff872803          	lw	a6,-8(a4) # fffffffffff7fff8 <end+0x3fd79b68>
        p = le2page(le, page_link);
ffffffffc0201682:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201686:	02081613          	slli	a2,a6,0x20
ffffffffc020168a:	9201                	srli	a2,a2,0x20
ffffffffc020168c:	00261793          	slli	a5,a2,0x2
ffffffffc0201690:	97b2                	add	a5,a5,a2
ffffffffc0201692:	078e                	slli	a5,a5,0x3
ffffffffc0201694:	97ae                	add	a5,a5,a1
ffffffffc0201696:	02f50f63          	beq	a0,a5,ffffffffc02016d4 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc020169a:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020169c:	00d70f63          	beq	a4,a3,ffffffffc02016ba <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02016a0:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02016a2:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02016a6:	02059613          	slli	a2,a1,0x20
ffffffffc02016aa:	9201                	srli	a2,a2,0x20
ffffffffc02016ac:	00261793          	slli	a5,a2,0x2
ffffffffc02016b0:	97b2                	add	a5,a5,a2
ffffffffc02016b2:	078e                	slli	a5,a5,0x3
ffffffffc02016b4:	97aa                	add	a5,a5,a0
ffffffffc02016b6:	04f68863          	beq	a3,a5,ffffffffc0201706 <default_free_pages+0x118>
}
ffffffffc02016ba:	60a2                	ld	ra,8(sp)
ffffffffc02016bc:	0141                	addi	sp,sp,16
ffffffffc02016be:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016c0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016c2:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016c4:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016c6:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016c8:	02d70563          	beq	a4,a3,ffffffffc02016f2 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02016cc:	8832                	mv	a6,a2
ffffffffc02016ce:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02016d0:	87ba                	mv	a5,a4
ffffffffc02016d2:	bf41                	j	ffffffffc0201662 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc02016d4:	491c                	lw	a5,16(a0)
ffffffffc02016d6:	0107883b          	addw	a6,a5,a6
ffffffffc02016da:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02016de:	57f5                	li	a5,-3
ffffffffc02016e0:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016e4:	6d10                	ld	a2,24(a0)
ffffffffc02016e6:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02016e8:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02016ea:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02016ec:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02016ee:	e390                	sd	a2,0(a5)
ffffffffc02016f0:	b775                	j	ffffffffc020169c <default_free_pages+0xae>
ffffffffc02016f2:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016f4:	873e                	mv	a4,a5
ffffffffc02016f6:	b761                	j	ffffffffc020167e <default_free_pages+0x90>
}
ffffffffc02016f8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016fa:	e390                	sd	a2,0(a5)
ffffffffc02016fc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016fe:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201700:	ed1c                	sd	a5,24(a0)
ffffffffc0201702:	0141                	addi	sp,sp,16
ffffffffc0201704:	8082                	ret
            base->property += p->property;
ffffffffc0201706:	ff872783          	lw	a5,-8(a4)
ffffffffc020170a:	ff070693          	addi	a3,a4,-16
ffffffffc020170e:	9dbd                	addw	a1,a1,a5
ffffffffc0201710:	c90c                	sw	a1,16(a0)
ffffffffc0201712:	57f5                	li	a5,-3
ffffffffc0201714:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201718:	6314                	ld	a3,0(a4)
ffffffffc020171a:	671c                	ld	a5,8(a4)
}
ffffffffc020171c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020171e:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201720:	e394                	sd	a3,0(a5)
ffffffffc0201722:	0141                	addi	sp,sp,16
ffffffffc0201724:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201726:	00001697          	auipc	a3,0x1
ffffffffc020172a:	4ca68693          	addi	a3,a3,1226 # ffffffffc0202bf0 <commands+0xad0>
ffffffffc020172e:	00001617          	auipc	a2,0x1
ffffffffc0201732:	16260613          	addi	a2,a2,354 # ffffffffc0202890 <commands+0x770>
ffffffffc0201736:	08300593          	li	a1,131
ffffffffc020173a:	00001517          	auipc	a0,0x1
ffffffffc020173e:	16e50513          	addi	a0,a0,366 # ffffffffc02028a8 <commands+0x788>
ffffffffc0201742:	a1ffe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc0201746:	00001697          	auipc	a3,0x1
ffffffffc020174a:	4a268693          	addi	a3,a3,1186 # ffffffffc0202be8 <commands+0xac8>
ffffffffc020174e:	00001617          	auipc	a2,0x1
ffffffffc0201752:	14260613          	addi	a2,a2,322 # ffffffffc0202890 <commands+0x770>
ffffffffc0201756:	08000593          	li	a1,128
ffffffffc020175a:	00001517          	auipc	a0,0x1
ffffffffc020175e:	14e50513          	addi	a0,a0,334 # ffffffffc02028a8 <commands+0x788>
ffffffffc0201762:	9fffe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201766 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201766:	c959                	beqz	a0,ffffffffc02017fc <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0201768:	00005597          	auipc	a1,0x5
ffffffffc020176c:	8b858593          	addi	a1,a1,-1864 # ffffffffc0206020 <free_area>
ffffffffc0201770:	0105a803          	lw	a6,16(a1)
ffffffffc0201774:	862a                	mv	a2,a0
ffffffffc0201776:	02081793          	slli	a5,a6,0x20
ffffffffc020177a:	9381                	srli	a5,a5,0x20
ffffffffc020177c:	00a7ee63          	bltu	a5,a0,ffffffffc0201798 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201780:	87ae                	mv	a5,a1
ffffffffc0201782:	a801                	j	ffffffffc0201792 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201784:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201788:	02071693          	slli	a3,a4,0x20
ffffffffc020178c:	9281                	srli	a3,a3,0x20
ffffffffc020178e:	00c6f763          	bgeu	a3,a2,ffffffffc020179c <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201792:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201794:	feb798e3          	bne	a5,a1,ffffffffc0201784 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201798:	4501                	li	a0,0
}
ffffffffc020179a:	8082                	ret
    return listelm->prev;
ffffffffc020179c:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017a0:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02017a4:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02017a8:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc02017ac:	0068b423          	sd	t1,8(a7) # fffffffffff80008 <end+0x3fd79b78>
    next->prev = prev;
ffffffffc02017b0:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02017b4:	02d67b63          	bgeu	a2,a3,ffffffffc02017ea <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc02017b8:	00261693          	slli	a3,a2,0x2
ffffffffc02017bc:	96b2                	add	a3,a3,a2
ffffffffc02017be:	068e                	slli	a3,a3,0x3
ffffffffc02017c0:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02017c2:	41c7073b          	subw	a4,a4,t3
ffffffffc02017c6:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017c8:	00868613          	addi	a2,a3,8
ffffffffc02017cc:	4709                	li	a4,2
ffffffffc02017ce:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02017d2:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02017d6:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc02017da:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02017de:	e310                	sd	a2,0(a4)
ffffffffc02017e0:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02017e4:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc02017e6:	0116bc23          	sd	a7,24(a3)
ffffffffc02017ea:	41c8083b          	subw	a6,a6,t3
ffffffffc02017ee:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02017f2:	5775                	li	a4,-3
ffffffffc02017f4:	17c1                	addi	a5,a5,-16
ffffffffc02017f6:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02017fa:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02017fc:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02017fe:	00001697          	auipc	a3,0x1
ffffffffc0201802:	3ea68693          	addi	a3,a3,1002 # ffffffffc0202be8 <commands+0xac8>
ffffffffc0201806:	00001617          	auipc	a2,0x1
ffffffffc020180a:	08a60613          	addi	a2,a2,138 # ffffffffc0202890 <commands+0x770>
ffffffffc020180e:	06200593          	li	a1,98
ffffffffc0201812:	00001517          	auipc	a0,0x1
ffffffffc0201816:	09650513          	addi	a0,a0,150 # ffffffffc02028a8 <commands+0x788>
default_alloc_pages(size_t n) {
ffffffffc020181a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020181c:	945fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201820 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201820:	1141                	addi	sp,sp,-16
ffffffffc0201822:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201824:	c9e1                	beqz	a1,ffffffffc02018f4 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201826:	00259693          	slli	a3,a1,0x2
ffffffffc020182a:	96ae                	add	a3,a3,a1
ffffffffc020182c:	068e                	slli	a3,a3,0x3
ffffffffc020182e:	96aa                	add	a3,a3,a0
ffffffffc0201830:	87aa                	mv	a5,a0
ffffffffc0201832:	00d50f63          	beq	a0,a3,ffffffffc0201850 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201836:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201838:	8b05                	andi	a4,a4,1
ffffffffc020183a:	cf49                	beqz	a4,ffffffffc02018d4 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020183c:	0007a823          	sw	zero,16(a5)
ffffffffc0201840:	0007b423          	sd	zero,8(a5)
ffffffffc0201844:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201848:	02878793          	addi	a5,a5,40
ffffffffc020184c:	fed795e3          	bne	a5,a3,ffffffffc0201836 <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201850:	2581                	sext.w	a1,a1
ffffffffc0201852:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201854:	4789                	li	a5,2
ffffffffc0201856:	00850713          	addi	a4,a0,8
ffffffffc020185a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020185e:	00004697          	auipc	a3,0x4
ffffffffc0201862:	7c268693          	addi	a3,a3,1986 # ffffffffc0206020 <free_area>
ffffffffc0201866:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201868:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020186a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020186e:	9db9                	addw	a1,a1,a4
ffffffffc0201870:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201872:	04d78a63          	beq	a5,a3,ffffffffc02018c6 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201876:	fe878713          	addi	a4,a5,-24
ffffffffc020187a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020187e:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201880:	00e56a63          	bltu	a0,a4,ffffffffc0201894 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc0201884:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201886:	02d70263          	beq	a4,a3,ffffffffc02018aa <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc020188a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020188c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201890:	fee57ae3          	bgeu	a0,a4,ffffffffc0201884 <default_init_memmap+0x64>
ffffffffc0201894:	c199                	beqz	a1,ffffffffc020189a <default_init_memmap+0x7a>
ffffffffc0201896:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020189a:	6398                	ld	a4,0(a5)
}
ffffffffc020189c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020189e:	e390                	sd	a2,0(a5)
ffffffffc02018a0:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018a2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018a4:	ed18                	sd	a4,24(a0)
ffffffffc02018a6:	0141                	addi	sp,sp,16
ffffffffc02018a8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018aa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018ac:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018ae:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018b0:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02018b2:	00d70663          	beq	a4,a3,ffffffffc02018be <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02018b6:	8832                	mv	a6,a2
ffffffffc02018b8:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02018ba:	87ba                	mv	a5,a4
ffffffffc02018bc:	bfc1                	j	ffffffffc020188c <default_init_memmap+0x6c>
}
ffffffffc02018be:	60a2                	ld	ra,8(sp)
ffffffffc02018c0:	e290                	sd	a2,0(a3)
ffffffffc02018c2:	0141                	addi	sp,sp,16
ffffffffc02018c4:	8082                	ret
ffffffffc02018c6:	60a2                	ld	ra,8(sp)
ffffffffc02018c8:	e390                	sd	a2,0(a5)
ffffffffc02018ca:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018cc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018ce:	ed1c                	sd	a5,24(a0)
ffffffffc02018d0:	0141                	addi	sp,sp,16
ffffffffc02018d2:	8082                	ret
        assert(PageReserved(p));
ffffffffc02018d4:	00001697          	auipc	a3,0x1
ffffffffc02018d8:	34468693          	addi	a3,a3,836 # ffffffffc0202c18 <commands+0xaf8>
ffffffffc02018dc:	00001617          	auipc	a2,0x1
ffffffffc02018e0:	fb460613          	addi	a2,a2,-76 # ffffffffc0202890 <commands+0x770>
ffffffffc02018e4:	04900593          	li	a1,73
ffffffffc02018e8:	00001517          	auipc	a0,0x1
ffffffffc02018ec:	fc050513          	addi	a0,a0,-64 # ffffffffc02028a8 <commands+0x788>
ffffffffc02018f0:	871fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc02018f4:	00001697          	auipc	a3,0x1
ffffffffc02018f8:	2f468693          	addi	a3,a3,756 # ffffffffc0202be8 <commands+0xac8>
ffffffffc02018fc:	00001617          	auipc	a2,0x1
ffffffffc0201900:	f9460613          	addi	a2,a2,-108 # ffffffffc0202890 <commands+0x770>
ffffffffc0201904:	04600593          	li	a1,70
ffffffffc0201908:	00001517          	auipc	a0,0x1
ffffffffc020190c:	fa050513          	addi	a0,a0,-96 # ffffffffc02028a8 <commands+0x788>
ffffffffc0201910:	851fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201914 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201914:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201918:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020191a:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020191c:	cb81                	beqz	a5,ffffffffc020192c <strlen+0x18>
        cnt ++;
ffffffffc020191e:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201920:	00a707b3          	add	a5,a4,a0
ffffffffc0201924:	0007c783          	lbu	a5,0(a5)
ffffffffc0201928:	fbfd                	bnez	a5,ffffffffc020191e <strlen+0xa>
ffffffffc020192a:	8082                	ret
    }
    return cnt;
}
ffffffffc020192c:	8082                	ret

ffffffffc020192e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020192e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201930:	e589                	bnez	a1,ffffffffc020193a <strnlen+0xc>
ffffffffc0201932:	a811                	j	ffffffffc0201946 <strnlen+0x18>
        cnt ++;
ffffffffc0201934:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201936:	00f58863          	beq	a1,a5,ffffffffc0201946 <strnlen+0x18>
ffffffffc020193a:	00f50733          	add	a4,a0,a5
ffffffffc020193e:	00074703          	lbu	a4,0(a4)
ffffffffc0201942:	fb6d                	bnez	a4,ffffffffc0201934 <strnlen+0x6>
ffffffffc0201944:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201946:	852e                	mv	a0,a1
ffffffffc0201948:	8082                	ret

ffffffffc020194a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020194a:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020194e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201952:	cb89                	beqz	a5,ffffffffc0201964 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201954:	0505                	addi	a0,a0,1
ffffffffc0201956:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201958:	fee789e3          	beq	a5,a4,ffffffffc020194a <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020195c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201960:	9d19                	subw	a0,a0,a4
ffffffffc0201962:	8082                	ret
ffffffffc0201964:	4501                	li	a0,0
ffffffffc0201966:	bfed                	j	ffffffffc0201960 <strcmp+0x16>

ffffffffc0201968 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201968:	c20d                	beqz	a2,ffffffffc020198a <strncmp+0x22>
ffffffffc020196a:	962e                	add	a2,a2,a1
ffffffffc020196c:	a031                	j	ffffffffc0201978 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020196e:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201970:	00e79a63          	bne	a5,a4,ffffffffc0201984 <strncmp+0x1c>
ffffffffc0201974:	00b60b63          	beq	a2,a1,ffffffffc020198a <strncmp+0x22>
ffffffffc0201978:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020197c:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020197e:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201982:	f7f5                	bnez	a5,ffffffffc020196e <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201984:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201988:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020198a:	4501                	li	a0,0
ffffffffc020198c:	8082                	ret

ffffffffc020198e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020198e:	00054783          	lbu	a5,0(a0)
ffffffffc0201992:	c799                	beqz	a5,ffffffffc02019a0 <strchr+0x12>
        if (*s == c) {
ffffffffc0201994:	00f58763          	beq	a1,a5,ffffffffc02019a2 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201998:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020199c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020199e:	fbfd                	bnez	a5,ffffffffc0201994 <strchr+0x6>
    }
    return NULL;
ffffffffc02019a0:	4501                	li	a0,0
}
ffffffffc02019a2:	8082                	ret

ffffffffc02019a4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02019a4:	ca01                	beqz	a2,ffffffffc02019b4 <memset+0x10>
ffffffffc02019a6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02019a8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02019aa:	0785                	addi	a5,a5,1
ffffffffc02019ac:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02019b0:	fec79de3          	bne	a5,a2,ffffffffc02019aa <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02019b4:	8082                	ret

ffffffffc02019b6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019b6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019ba:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019bc:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019c0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019c2:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019c6:	f022                	sd	s0,32(sp)
ffffffffc02019c8:	ec26                	sd	s1,24(sp)
ffffffffc02019ca:	e84a                	sd	s2,16(sp)
ffffffffc02019cc:	f406                	sd	ra,40(sp)
ffffffffc02019ce:	e44e                	sd	s3,8(sp)
ffffffffc02019d0:	84aa                	mv	s1,a0
ffffffffc02019d2:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019d4:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019d8:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02019da:	03067e63          	bgeu	a2,a6,ffffffffc0201a16 <printnum+0x60>
ffffffffc02019de:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019e0:	00805763          	blez	s0,ffffffffc02019ee <printnum+0x38>
ffffffffc02019e4:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019e6:	85ca                	mv	a1,s2
ffffffffc02019e8:	854e                	mv	a0,s3
ffffffffc02019ea:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019ec:	fc65                	bnez	s0,ffffffffc02019e4 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019ee:	1a02                	slli	s4,s4,0x20
ffffffffc02019f0:	00001797          	auipc	a5,0x1
ffffffffc02019f4:	28878793          	addi	a5,a5,648 # ffffffffc0202c78 <default_pmm_manager+0x38>
ffffffffc02019f8:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019fc:	9a3e                	add	s4,s4,a5
}
ffffffffc02019fe:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a00:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a04:	70a2                	ld	ra,40(sp)
ffffffffc0201a06:	69a2                	ld	s3,8(sp)
ffffffffc0201a08:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a0a:	85ca                	mv	a1,s2
ffffffffc0201a0c:	87a6                	mv	a5,s1
}
ffffffffc0201a0e:	6942                	ld	s2,16(sp)
ffffffffc0201a10:	64e2                	ld	s1,24(sp)
ffffffffc0201a12:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a14:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a16:	03065633          	divu	a2,a2,a6
ffffffffc0201a1a:	8722                	mv	a4,s0
ffffffffc0201a1c:	f9bff0ef          	jal	ra,ffffffffc02019b6 <printnum>
ffffffffc0201a20:	b7f9                	j	ffffffffc02019ee <printnum+0x38>

ffffffffc0201a22 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a22:	7119                	addi	sp,sp,-128
ffffffffc0201a24:	f4a6                	sd	s1,104(sp)
ffffffffc0201a26:	f0ca                	sd	s2,96(sp)
ffffffffc0201a28:	ecce                	sd	s3,88(sp)
ffffffffc0201a2a:	e8d2                	sd	s4,80(sp)
ffffffffc0201a2c:	e4d6                	sd	s5,72(sp)
ffffffffc0201a2e:	e0da                	sd	s6,64(sp)
ffffffffc0201a30:	fc5e                	sd	s7,56(sp)
ffffffffc0201a32:	f06a                	sd	s10,32(sp)
ffffffffc0201a34:	fc86                	sd	ra,120(sp)
ffffffffc0201a36:	f8a2                	sd	s0,112(sp)
ffffffffc0201a38:	f862                	sd	s8,48(sp)
ffffffffc0201a3a:	f466                	sd	s9,40(sp)
ffffffffc0201a3c:	ec6e                	sd	s11,24(sp)
ffffffffc0201a3e:	892a                	mv	s2,a0
ffffffffc0201a40:	84ae                	mv	s1,a1
ffffffffc0201a42:	8d32                	mv	s10,a2
ffffffffc0201a44:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a46:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a4a:	5b7d                	li	s6,-1
ffffffffc0201a4c:	00001a97          	auipc	s5,0x1
ffffffffc0201a50:	260a8a93          	addi	s5,s5,608 # ffffffffc0202cac <default_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a54:	00001b97          	auipc	s7,0x1
ffffffffc0201a58:	434b8b93          	addi	s7,s7,1076 # ffffffffc0202e88 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a5c:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a60:	001d0413          	addi	s0,s10,1
ffffffffc0201a64:	01350a63          	beq	a0,s3,ffffffffc0201a78 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a68:	c121                	beqz	a0,ffffffffc0201aa8 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a6a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a6c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a6e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a70:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a74:	ff351ae3          	bne	a0,s3,ffffffffc0201a68 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a78:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a7c:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a80:	4c81                	li	s9,0
ffffffffc0201a82:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a84:	5c7d                	li	s8,-1
ffffffffc0201a86:	5dfd                	li	s11,-1
ffffffffc0201a88:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a8c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a8e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a92:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a96:	00140d13          	addi	s10,s0,1
ffffffffc0201a9a:	04b56263          	bltu	a0,a1,ffffffffc0201ade <vprintfmt+0xbc>
ffffffffc0201a9e:	058a                	slli	a1,a1,0x2
ffffffffc0201aa0:	95d6                	add	a1,a1,s5
ffffffffc0201aa2:	4194                	lw	a3,0(a1)
ffffffffc0201aa4:	96d6                	add	a3,a3,s5
ffffffffc0201aa6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201aa8:	70e6                	ld	ra,120(sp)
ffffffffc0201aaa:	7446                	ld	s0,112(sp)
ffffffffc0201aac:	74a6                	ld	s1,104(sp)
ffffffffc0201aae:	7906                	ld	s2,96(sp)
ffffffffc0201ab0:	69e6                	ld	s3,88(sp)
ffffffffc0201ab2:	6a46                	ld	s4,80(sp)
ffffffffc0201ab4:	6aa6                	ld	s5,72(sp)
ffffffffc0201ab6:	6b06                	ld	s6,64(sp)
ffffffffc0201ab8:	7be2                	ld	s7,56(sp)
ffffffffc0201aba:	7c42                	ld	s8,48(sp)
ffffffffc0201abc:	7ca2                	ld	s9,40(sp)
ffffffffc0201abe:	7d02                	ld	s10,32(sp)
ffffffffc0201ac0:	6de2                	ld	s11,24(sp)
ffffffffc0201ac2:	6109                	addi	sp,sp,128
ffffffffc0201ac4:	8082                	ret
            padc = '0';
ffffffffc0201ac6:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201ac8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201acc:	846a                	mv	s0,s10
ffffffffc0201ace:	00140d13          	addi	s10,s0,1
ffffffffc0201ad2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201ad6:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ada:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a9e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201ade:	85a6                	mv	a1,s1
ffffffffc0201ae0:	02500513          	li	a0,37
ffffffffc0201ae4:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201ae6:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201aea:	8d22                	mv	s10,s0
ffffffffc0201aec:	f73788e3          	beq	a5,s3,ffffffffc0201a5c <vprintfmt+0x3a>
ffffffffc0201af0:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201af4:	1d7d                	addi	s10,s10,-1
ffffffffc0201af6:	ff379de3          	bne	a5,s3,ffffffffc0201af0 <vprintfmt+0xce>
ffffffffc0201afa:	b78d                	j	ffffffffc0201a5c <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201afc:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b00:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b04:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b06:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b0a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b0e:	02d86463          	bltu	a6,a3,ffffffffc0201b36 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b12:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b16:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b1a:	0186873b          	addw	a4,a3,s8
ffffffffc0201b1e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b22:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b24:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b28:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b2a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b2e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b32:	fed870e3          	bgeu	a6,a3,ffffffffc0201b12 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b36:	f40ddce3          	bgez	s11,ffffffffc0201a8e <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b3a:	8de2                	mv	s11,s8
ffffffffc0201b3c:	5c7d                	li	s8,-1
ffffffffc0201b3e:	bf81                	j	ffffffffc0201a8e <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b40:	fffdc693          	not	a3,s11
ffffffffc0201b44:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b46:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b4a:	00144603          	lbu	a2,1(s0)
ffffffffc0201b4e:	2d81                	sext.w	s11,s11
ffffffffc0201b50:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b52:	bf35                	j	ffffffffc0201a8e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201b54:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b58:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b5c:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b5e:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b60:	bfd9                	j	ffffffffc0201b36 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b62:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b64:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b68:	01174463          	blt	a4,a7,ffffffffc0201b70 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b6c:	1a088e63          	beqz	a7,ffffffffc0201d28 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b70:	000a3603          	ld	a2,0(s4)
ffffffffc0201b74:	46c1                	li	a3,16
ffffffffc0201b76:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b78:	2781                	sext.w	a5,a5
ffffffffc0201b7a:	876e                	mv	a4,s11
ffffffffc0201b7c:	85a6                	mv	a1,s1
ffffffffc0201b7e:	854a                	mv	a0,s2
ffffffffc0201b80:	e37ff0ef          	jal	ra,ffffffffc02019b6 <printnum>
            break;
ffffffffc0201b84:	bde1                	j	ffffffffc0201a5c <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b86:	000a2503          	lw	a0,0(s4)
ffffffffc0201b8a:	85a6                	mv	a1,s1
ffffffffc0201b8c:	0a21                	addi	s4,s4,8
ffffffffc0201b8e:	9902                	jalr	s2
            break;
ffffffffc0201b90:	b5f1                	j	ffffffffc0201a5c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b92:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b94:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b98:	01174463          	blt	a4,a7,ffffffffc0201ba0 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b9c:	18088163          	beqz	a7,ffffffffc0201d1e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201ba0:	000a3603          	ld	a2,0(s4)
ffffffffc0201ba4:	46a9                	li	a3,10
ffffffffc0201ba6:	8a2e                	mv	s4,a1
ffffffffc0201ba8:	bfc1                	j	ffffffffc0201b78 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201baa:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201bae:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bb0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bb2:	bdf1                	j	ffffffffc0201a8e <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201bb4:	85a6                	mv	a1,s1
ffffffffc0201bb6:	02500513          	li	a0,37
ffffffffc0201bba:	9902                	jalr	s2
            break;
ffffffffc0201bbc:	b545                	j	ffffffffc0201a5c <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bbe:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201bc2:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bc6:	b5e1                	j	ffffffffc0201a8e <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201bc8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bca:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bce:	01174463          	blt	a4,a7,ffffffffc0201bd6 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201bd2:	14088163          	beqz	a7,ffffffffc0201d14 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bd6:	000a3603          	ld	a2,0(s4)
ffffffffc0201bda:	46a1                	li	a3,8
ffffffffc0201bdc:	8a2e                	mv	s4,a1
ffffffffc0201bde:	bf69                	j	ffffffffc0201b78 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201be0:	03000513          	li	a0,48
ffffffffc0201be4:	85a6                	mv	a1,s1
ffffffffc0201be6:	e03e                	sd	a5,0(sp)
ffffffffc0201be8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201bea:	85a6                	mv	a1,s1
ffffffffc0201bec:	07800513          	li	a0,120
ffffffffc0201bf0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bf2:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201bf4:	6782                	ld	a5,0(sp)
ffffffffc0201bf6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bf8:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201bfc:	bfb5                	j	ffffffffc0201b78 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bfe:	000a3403          	ld	s0,0(s4)
ffffffffc0201c02:	008a0713          	addi	a4,s4,8
ffffffffc0201c06:	e03a                	sd	a4,0(sp)
ffffffffc0201c08:	14040263          	beqz	s0,ffffffffc0201d4c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c0c:	0fb05763          	blez	s11,ffffffffc0201cfa <vprintfmt+0x2d8>
ffffffffc0201c10:	02d00693          	li	a3,45
ffffffffc0201c14:	0cd79163          	bne	a5,a3,ffffffffc0201cd6 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c18:	00044783          	lbu	a5,0(s0)
ffffffffc0201c1c:	0007851b          	sext.w	a0,a5
ffffffffc0201c20:	cf85                	beqz	a5,ffffffffc0201c58 <vprintfmt+0x236>
ffffffffc0201c22:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c26:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c2a:	000c4563          	bltz	s8,ffffffffc0201c34 <vprintfmt+0x212>
ffffffffc0201c2e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c30:	036c0263          	beq	s8,s6,ffffffffc0201c54 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c34:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c36:	0e0c8e63          	beqz	s9,ffffffffc0201d32 <vprintfmt+0x310>
ffffffffc0201c3a:	3781                	addiw	a5,a5,-32
ffffffffc0201c3c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d32 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c40:	03f00513          	li	a0,63
ffffffffc0201c44:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c46:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c4a:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c4c:	0a05                	addi	s4,s4,1
ffffffffc0201c4e:	0007851b          	sext.w	a0,a5
ffffffffc0201c52:	ffe1                	bnez	a5,ffffffffc0201c2a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201c54:	01b05963          	blez	s11,ffffffffc0201c66 <vprintfmt+0x244>
ffffffffc0201c58:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c5a:	85a6                	mv	a1,s1
ffffffffc0201c5c:	02000513          	li	a0,32
ffffffffc0201c60:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c62:	fe0d9be3          	bnez	s11,ffffffffc0201c58 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c66:	6a02                	ld	s4,0(sp)
ffffffffc0201c68:	bbd5                	j	ffffffffc0201a5c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c6a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c6c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c70:	01174463          	blt	a4,a7,ffffffffc0201c78 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c74:	08088d63          	beqz	a7,ffffffffc0201d0e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c78:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c7c:	0a044d63          	bltz	s0,ffffffffc0201d36 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c80:	8622                	mv	a2,s0
ffffffffc0201c82:	8a66                	mv	s4,s9
ffffffffc0201c84:	46a9                	li	a3,10
ffffffffc0201c86:	bdcd                	j	ffffffffc0201b78 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c88:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c8c:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c8e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c90:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c94:	8fb5                	xor	a5,a5,a3
ffffffffc0201c96:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c9a:	02d74163          	blt	a4,a3,ffffffffc0201cbc <vprintfmt+0x29a>
ffffffffc0201c9e:	00369793          	slli	a5,a3,0x3
ffffffffc0201ca2:	97de                	add	a5,a5,s7
ffffffffc0201ca4:	639c                	ld	a5,0(a5)
ffffffffc0201ca6:	cb99                	beqz	a5,ffffffffc0201cbc <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201ca8:	86be                	mv	a3,a5
ffffffffc0201caa:	00001617          	auipc	a2,0x1
ffffffffc0201cae:	ffe60613          	addi	a2,a2,-2 # ffffffffc0202ca8 <default_pmm_manager+0x68>
ffffffffc0201cb2:	85a6                	mv	a1,s1
ffffffffc0201cb4:	854a                	mv	a0,s2
ffffffffc0201cb6:	0ce000ef          	jal	ra,ffffffffc0201d84 <printfmt>
ffffffffc0201cba:	b34d                	j	ffffffffc0201a5c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cbc:	00001617          	auipc	a2,0x1
ffffffffc0201cc0:	fdc60613          	addi	a2,a2,-36 # ffffffffc0202c98 <default_pmm_manager+0x58>
ffffffffc0201cc4:	85a6                	mv	a1,s1
ffffffffc0201cc6:	854a                	mv	a0,s2
ffffffffc0201cc8:	0bc000ef          	jal	ra,ffffffffc0201d84 <printfmt>
ffffffffc0201ccc:	bb41                	j	ffffffffc0201a5c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201cce:	00001417          	auipc	s0,0x1
ffffffffc0201cd2:	fc240413          	addi	s0,s0,-62 # ffffffffc0202c90 <default_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cd6:	85e2                	mv	a1,s8
ffffffffc0201cd8:	8522                	mv	a0,s0
ffffffffc0201cda:	e43e                	sd	a5,8(sp)
ffffffffc0201cdc:	c53ff0ef          	jal	ra,ffffffffc020192e <strnlen>
ffffffffc0201ce0:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201ce4:	01b05b63          	blez	s11,ffffffffc0201cfa <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201ce8:	67a2                	ld	a5,8(sp)
ffffffffc0201cea:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cee:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201cf0:	85a6                	mv	a1,s1
ffffffffc0201cf2:	8552                	mv	a0,s4
ffffffffc0201cf4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cf6:	fe0d9ce3          	bnez	s11,ffffffffc0201cee <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cfa:	00044783          	lbu	a5,0(s0)
ffffffffc0201cfe:	00140a13          	addi	s4,s0,1
ffffffffc0201d02:	0007851b          	sext.w	a0,a5
ffffffffc0201d06:	d3a5                	beqz	a5,ffffffffc0201c66 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d08:	05e00413          	li	s0,94
ffffffffc0201d0c:	bf39                	j	ffffffffc0201c2a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d0e:	000a2403          	lw	s0,0(s4)
ffffffffc0201d12:	b7ad                	j	ffffffffc0201c7c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d14:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d18:	46a1                	li	a3,8
ffffffffc0201d1a:	8a2e                	mv	s4,a1
ffffffffc0201d1c:	bdb1                	j	ffffffffc0201b78 <vprintfmt+0x156>
ffffffffc0201d1e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d22:	46a9                	li	a3,10
ffffffffc0201d24:	8a2e                	mv	s4,a1
ffffffffc0201d26:	bd89                	j	ffffffffc0201b78 <vprintfmt+0x156>
ffffffffc0201d28:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d2c:	46c1                	li	a3,16
ffffffffc0201d2e:	8a2e                	mv	s4,a1
ffffffffc0201d30:	b5a1                	j	ffffffffc0201b78 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d32:	9902                	jalr	s2
ffffffffc0201d34:	bf09                	j	ffffffffc0201c46 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d36:	85a6                	mv	a1,s1
ffffffffc0201d38:	02d00513          	li	a0,45
ffffffffc0201d3c:	e03e                	sd	a5,0(sp)
ffffffffc0201d3e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d40:	6782                	ld	a5,0(sp)
ffffffffc0201d42:	8a66                	mv	s4,s9
ffffffffc0201d44:	40800633          	neg	a2,s0
ffffffffc0201d48:	46a9                	li	a3,10
ffffffffc0201d4a:	b53d                	j	ffffffffc0201b78 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d4c:	03b05163          	blez	s11,ffffffffc0201d6e <vprintfmt+0x34c>
ffffffffc0201d50:	02d00693          	li	a3,45
ffffffffc0201d54:	f6d79de3          	bne	a5,a3,ffffffffc0201cce <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d58:	00001417          	auipc	s0,0x1
ffffffffc0201d5c:	f3840413          	addi	s0,s0,-200 # ffffffffc0202c90 <default_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d60:	02800793          	li	a5,40
ffffffffc0201d64:	02800513          	li	a0,40
ffffffffc0201d68:	00140a13          	addi	s4,s0,1
ffffffffc0201d6c:	bd6d                	j	ffffffffc0201c26 <vprintfmt+0x204>
ffffffffc0201d6e:	00001a17          	auipc	s4,0x1
ffffffffc0201d72:	f23a0a13          	addi	s4,s4,-221 # ffffffffc0202c91 <default_pmm_manager+0x51>
ffffffffc0201d76:	02800513          	li	a0,40
ffffffffc0201d7a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d7e:	05e00413          	li	s0,94
ffffffffc0201d82:	b565                	j	ffffffffc0201c2a <vprintfmt+0x208>

ffffffffc0201d84 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d84:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d86:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d8a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d8c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d8e:	ec06                	sd	ra,24(sp)
ffffffffc0201d90:	f83a                	sd	a4,48(sp)
ffffffffc0201d92:	fc3e                	sd	a5,56(sp)
ffffffffc0201d94:	e0c2                	sd	a6,64(sp)
ffffffffc0201d96:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d98:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d9a:	c89ff0ef          	jal	ra,ffffffffc0201a22 <vprintfmt>
}
ffffffffc0201d9e:	60e2                	ld	ra,24(sp)
ffffffffc0201da0:	6161                	addi	sp,sp,80
ffffffffc0201da2:	8082                	ret

ffffffffc0201da4 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201da4:	715d                	addi	sp,sp,-80
ffffffffc0201da6:	e486                	sd	ra,72(sp)
ffffffffc0201da8:	e0a6                	sd	s1,64(sp)
ffffffffc0201daa:	fc4a                	sd	s2,56(sp)
ffffffffc0201dac:	f84e                	sd	s3,48(sp)
ffffffffc0201dae:	f452                	sd	s4,40(sp)
ffffffffc0201db0:	f056                	sd	s5,32(sp)
ffffffffc0201db2:	ec5a                	sd	s6,24(sp)
ffffffffc0201db4:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201db6:	c901                	beqz	a0,ffffffffc0201dc6 <readline+0x22>
ffffffffc0201db8:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201dba:	00001517          	auipc	a0,0x1
ffffffffc0201dbe:	eee50513          	addi	a0,a0,-274 # ffffffffc0202ca8 <default_pmm_manager+0x68>
ffffffffc0201dc2:	b16fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201dc6:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dc8:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201dca:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201dcc:	4aa9                	li	s5,10
ffffffffc0201dce:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201dd0:	00004b97          	auipc	s7,0x4
ffffffffc0201dd4:	268b8b93          	addi	s7,s7,616 # ffffffffc0206038 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dd8:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201ddc:	b74fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201de0:	00054a63          	bltz	a0,ffffffffc0201df4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201de4:	00a95a63          	bge	s2,a0,ffffffffc0201df8 <readline+0x54>
ffffffffc0201de8:	029a5263          	bge	s4,s1,ffffffffc0201e0c <readline+0x68>
        c = getchar();
ffffffffc0201dec:	b64fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201df0:	fe055ae3          	bgez	a0,ffffffffc0201de4 <readline+0x40>
            return NULL;
ffffffffc0201df4:	4501                	li	a0,0
ffffffffc0201df6:	a091                	j	ffffffffc0201e3a <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201df8:	03351463          	bne	a0,s3,ffffffffc0201e20 <readline+0x7c>
ffffffffc0201dfc:	e8a9                	bnez	s1,ffffffffc0201e4e <readline+0xaa>
        c = getchar();
ffffffffc0201dfe:	b52fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e02:	fe0549e3          	bltz	a0,ffffffffc0201df4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e06:	fea959e3          	bge	s2,a0,ffffffffc0201df8 <readline+0x54>
ffffffffc0201e0a:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e0c:	e42a                	sd	a0,8(sp)
ffffffffc0201e0e:	b00fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201e12:	6522                	ld	a0,8(sp)
ffffffffc0201e14:	009b87b3          	add	a5,s7,s1
ffffffffc0201e18:	2485                	addiw	s1,s1,1
ffffffffc0201e1a:	00a78023          	sb	a0,0(a5)
ffffffffc0201e1e:	bf7d                	j	ffffffffc0201ddc <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e20:	01550463          	beq	a0,s5,ffffffffc0201e28 <readline+0x84>
ffffffffc0201e24:	fb651ce3          	bne	a0,s6,ffffffffc0201ddc <readline+0x38>
            cputchar(c);
ffffffffc0201e28:	ae6fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201e2c:	00004517          	auipc	a0,0x4
ffffffffc0201e30:	20c50513          	addi	a0,a0,524 # ffffffffc0206038 <buf>
ffffffffc0201e34:	94aa                	add	s1,s1,a0
ffffffffc0201e36:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e3a:	60a6                	ld	ra,72(sp)
ffffffffc0201e3c:	6486                	ld	s1,64(sp)
ffffffffc0201e3e:	7962                	ld	s2,56(sp)
ffffffffc0201e40:	79c2                	ld	s3,48(sp)
ffffffffc0201e42:	7a22                	ld	s4,40(sp)
ffffffffc0201e44:	7a82                	ld	s5,32(sp)
ffffffffc0201e46:	6b62                	ld	s6,24(sp)
ffffffffc0201e48:	6bc2                	ld	s7,16(sp)
ffffffffc0201e4a:	6161                	addi	sp,sp,80
ffffffffc0201e4c:	8082                	ret
            cputchar(c);
ffffffffc0201e4e:	4521                	li	a0,8
ffffffffc0201e50:	abefe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201e54:	34fd                	addiw	s1,s1,-1
ffffffffc0201e56:	b759                	j	ffffffffc0201ddc <readline+0x38>

ffffffffc0201e58 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e58:	4781                	li	a5,0
ffffffffc0201e5a:	00004717          	auipc	a4,0x4
ffffffffc0201e5e:	1be73703          	ld	a4,446(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e62:	88ba                	mv	a7,a4
ffffffffc0201e64:	852a                	mv	a0,a0
ffffffffc0201e66:	85be                	mv	a1,a5
ffffffffc0201e68:	863e                	mv	a2,a5
ffffffffc0201e6a:	00000073          	ecall
ffffffffc0201e6e:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e70:	8082                	ret

ffffffffc0201e72 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e72:	4781                	li	a5,0
ffffffffc0201e74:	00004717          	auipc	a4,0x4
ffffffffc0201e78:	61473703          	ld	a4,1556(a4) # ffffffffc0206488 <SBI_SET_TIMER>
ffffffffc0201e7c:	88ba                	mv	a7,a4
ffffffffc0201e7e:	852a                	mv	a0,a0
ffffffffc0201e80:	85be                	mv	a1,a5
ffffffffc0201e82:	863e                	mv	a2,a5
ffffffffc0201e84:	00000073          	ecall
ffffffffc0201e88:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e8a:	8082                	ret

ffffffffc0201e8c <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e8c:	4501                	li	a0,0
ffffffffc0201e8e:	00004797          	auipc	a5,0x4
ffffffffc0201e92:	1827b783          	ld	a5,386(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e96:	88be                	mv	a7,a5
ffffffffc0201e98:	852a                	mv	a0,a0
ffffffffc0201e9a:	85aa                	mv	a1,a0
ffffffffc0201e9c:	862a                	mv	a2,a0
ffffffffc0201e9e:	00000073          	ecall
ffffffffc0201ea2:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201ea4:	2501                	sext.w	a0,a0
ffffffffc0201ea6:	8082                	ret
