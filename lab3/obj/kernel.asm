
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
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	1a5010ef          	jal	ra,ffffffffc0201a10 <memset>
    dtb_init();
ffffffffc0200070:	3be000ef          	jal	ra,ffffffffc020042e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	7ae000ef          	jal	ra,ffffffffc0200822 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	eb850513          	addi	a0,a0,-328 # ffffffffc0201f30 <etext+0x2>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	138000ef          	jal	ra,ffffffffc02001bc <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b4000ef          	jal	ra,ffffffffc020083c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	43d000ef          	jal	ra,ffffffffc0200cc8 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7ac000ef          	jal	ra,ffffffffc020083c <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	74a000ef          	jal	ra,ffffffffc02007de <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	798000ef          	jal	ra,ffffffffc0200830 <intr_enable>

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
ffffffffc02000a6:	77e000ef          	jal	ra,ffffffffc0200824 <cons_putc>
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
ffffffffc02000cc:	1c3010ef          	jal	ra,ffffffffc0201a8e <vprintfmt>
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
ffffffffc0200102:	18d010ef          	jal	ra,ffffffffc0201a8e <vprintfmt>
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
ffffffffc020010e:	af19                	j	ffffffffc0200824 <cons_putc>

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
ffffffffc0200126:	6fe000ef          	jal	ra,ffffffffc0200824 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	6e8000ef          	jal	ra,ffffffffc0200824 <cons_putc>
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
ffffffffc0200154:	6d8000ef          	jal	ra,ffffffffc020082c <cons_getc>
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
ffffffffc0200164:	2e030313          	addi	t1,t1,736 # ffffffffc0206440 <is_panic>
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
ffffffffc0200192:	dc250513          	addi	a0,a0,-574 # ffffffffc0201f50 <etext+0x22>
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
ffffffffc02001a8:	5ec50513          	addi	a0,a0,1516 # ffffffffc0202790 <commands+0x5e8>
ffffffffc02001ac:	f2dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02001b0:	686000ef          	jal	ra,ffffffffc0200836 <intr_disable>
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
ffffffffc02001c2:	db250513          	addi	a0,a0,-590 # ffffffffc0201f70 <etext+0x42>
void print_kerninfo(void) {
ffffffffc02001c6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001c8:	f11ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001cc:	00000597          	auipc	a1,0x0
ffffffffc02001d0:	e8858593          	addi	a1,a1,-376 # ffffffffc0200054 <kern_init>
ffffffffc02001d4:	00002517          	auipc	a0,0x2
ffffffffc02001d8:	dbc50513          	addi	a0,a0,-580 # ffffffffc0201f90 <etext+0x62>
ffffffffc02001dc:	efdff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001e0:	00002597          	auipc	a1,0x2
ffffffffc02001e4:	d4e58593          	addi	a1,a1,-690 # ffffffffc0201f2e <etext>
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	dc850513          	addi	a0,a0,-568 # ffffffffc0201fb0 <etext+0x82>
ffffffffc02001f0:	ee9ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001f4:	00006597          	auipc	a1,0x6
ffffffffc02001f8:	e3458593          	addi	a1,a1,-460 # ffffffffc0206028 <free_area>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	dd450513          	addi	a0,a0,-556 # ffffffffc0201fd0 <etext+0xa2>
ffffffffc0200204:	ed5ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200208:	00006597          	auipc	a1,0x6
ffffffffc020020c:	29858593          	addi	a1,a1,664 # ffffffffc02064a0 <end>
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	de050513          	addi	a0,a0,-544 # ffffffffc0201ff0 <etext+0xc2>
ffffffffc0200218:	ec1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020021c:	00006597          	auipc	a1,0x6
ffffffffc0200220:	68358593          	addi	a1,a1,1667 # ffffffffc020689f <end+0x3ff>
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
ffffffffc0200242:	dd250513          	addi	a0,a0,-558 # ffffffffc0202010 <etext+0xe2>
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
ffffffffc0200250:	df460613          	addi	a2,a2,-524 # ffffffffc0202040 <etext+0x112>
ffffffffc0200254:	04d00593          	li	a1,77
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	e0050513          	addi	a0,a0,-512 # ffffffffc0202058 <etext+0x12a>
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
ffffffffc020026c:	e0860613          	addi	a2,a2,-504 # ffffffffc0202070 <etext+0x142>
ffffffffc0200270:	00002597          	auipc	a1,0x2
ffffffffc0200274:	e2058593          	addi	a1,a1,-480 # ffffffffc0202090 <etext+0x162>
ffffffffc0200278:	00002517          	auipc	a0,0x2
ffffffffc020027c:	e2050513          	addi	a0,a0,-480 # ffffffffc0202098 <etext+0x16a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200280:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200282:	e57ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	e2260613          	addi	a2,a2,-478 # ffffffffc02020a8 <etext+0x17a>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	e4258593          	addi	a1,a1,-446 # ffffffffc02020d0 <etext+0x1a2>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	e0250513          	addi	a0,a0,-510 # ffffffffc0202098 <etext+0x16a>
ffffffffc020029e:	e3bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02002a2:	00002617          	auipc	a2,0x2
ffffffffc02002a6:	e3e60613          	addi	a2,a2,-450 # ffffffffc02020e0 <etext+0x1b2>
ffffffffc02002aa:	00002597          	auipc	a1,0x2
ffffffffc02002ae:	e5658593          	addi	a1,a1,-426 # ffffffffc0202100 <etext+0x1d2>
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	de650513          	addi	a0,a0,-538 # ffffffffc0202098 <etext+0x16a>
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
ffffffffc02002f0:	e2450513          	addi	a0,a0,-476 # ffffffffc0202110 <etext+0x1e2>
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
ffffffffc0200312:	e2a50513          	addi	a0,a0,-470 # ffffffffc0202138 <etext+0x20a>
ffffffffc0200316:	dc3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc020031a:	000b8563          	beqz	s7,ffffffffc0200324 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020031e:	855e                	mv	a0,s7
ffffffffc0200320:	6fc000ef          	jal	ra,ffffffffc0200a1c <print_trapframe>
ffffffffc0200324:	00002c17          	auipc	s8,0x2
ffffffffc0200328:	e84c0c13          	addi	s8,s8,-380 # ffffffffc02021a8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032c:	00002917          	auipc	s2,0x2
ffffffffc0200330:	e3490913          	addi	s2,s2,-460 # ffffffffc0202160 <etext+0x232>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200334:	00002497          	auipc	s1,0x2
ffffffffc0200338:	e3448493          	addi	s1,s1,-460 # ffffffffc0202168 <etext+0x23a>
        if (argc == MAXARGS - 1) {
ffffffffc020033c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020033e:	00002b17          	auipc	s6,0x2
ffffffffc0200342:	e32b0b13          	addi	s6,s6,-462 # ffffffffc0202170 <etext+0x242>
        argv[argc ++] = buf;
ffffffffc0200346:	00002a17          	auipc	s4,0x2
ffffffffc020034a:	d4aa0a13          	addi	s4,s4,-694 # ffffffffc0202090 <etext+0x162>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034e:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200350:	854a                	mv	a0,s2
ffffffffc0200352:	2bf010ef          	jal	ra,ffffffffc0201e10 <readline>
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
ffffffffc020036c:	e40d0d13          	addi	s10,s10,-448 # ffffffffc02021a8 <commands>
        argv[argc ++] = buf;
ffffffffc0200370:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200372:	4401                	li	s0,0
ffffffffc0200374:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200376:	640010ef          	jal	ra,ffffffffc02019b6 <strcmp>
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
ffffffffc020038a:	62c010ef          	jal	ra,ffffffffc02019b6 <strcmp>
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
ffffffffc02003c8:	632010ef          	jal	ra,ffffffffc02019fa <strchr>
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
ffffffffc0200406:	5f4010ef          	jal	ra,ffffffffc02019fa <strchr>
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
ffffffffc0200424:	d7050513          	addi	a0,a0,-656 # ffffffffc0202190 <etext+0x262>
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
ffffffffc0200434:	dc050513          	addi	a0,a0,-576 # ffffffffc02021f0 <commands+0x48>
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
ffffffffc0200462:	da250513          	addi	a0,a0,-606 # ffffffffc0202200 <commands+0x58>
ffffffffc0200466:	c73ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020046a:	00006417          	auipc	s0,0x6
ffffffffc020046e:	b9e40413          	addi	s0,s0,-1122 # ffffffffc0206008 <boot_dtb>
ffffffffc0200472:	600c                	ld	a1,0(s0)
ffffffffc0200474:	00002517          	auipc	a0,0x2
ffffffffc0200478:	d9c50513          	addi	a0,a0,-612 # ffffffffc0202210 <commands+0x68>
ffffffffc020047c:	c5dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200480:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	da450513          	addi	a0,a0,-604 # ffffffffc0202228 <commands+0x80>
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
ffffffffc02004cc:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
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
ffffffffc0200542:	d3a90913          	addi	s2,s2,-710 # ffffffffc0202278 <commands+0xd0>
ffffffffc0200546:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200548:	4d91                	li	s11,4
ffffffffc020054a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020054c:	00002497          	auipc	s1,0x2
ffffffffc0200550:	d2448493          	addi	s1,s1,-732 # ffffffffc0202270 <commands+0xc8>
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
ffffffffc02005a4:	d5050513          	addi	a0,a0,-688 # ffffffffc02022f0 <commands+0x148>
ffffffffc02005a8:	b31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202328 <commands+0x180>
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
ffffffffc02005f0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0202248 <commands+0xa0>
}
ffffffffc02005f4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005f6:	b4cd                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc02005f8:	8556                	mv	a0,s5
ffffffffc02005fa:	386010ef          	jal	ra,ffffffffc0201980 <strlen>
ffffffffc02005fe:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200600:	4619                	li	a2,6
ffffffffc0200602:	85a6                	mv	a1,s1
ffffffffc0200604:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200606:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200608:	3cc010ef          	jal	ra,ffffffffc02019d4 <strncmp>
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
ffffffffc020069e:	318010ef          	jal	ra,ffffffffc02019b6 <strcmp>
ffffffffc02006a2:	66a2                	ld	a3,8(sp)
ffffffffc02006a4:	f94d                	bnez	a0,ffffffffc0200656 <dtb_init+0x228>
ffffffffc02006a6:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200656 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006aa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006ae:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006b2:	00002517          	auipc	a0,0x2
ffffffffc02006b6:	bce50513          	addi	a0,a0,-1074 # ffffffffc0202280 <commands+0xd8>
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
ffffffffc0200784:	b2050513          	addi	a0,a0,-1248 # ffffffffc02022a0 <commands+0xf8>
ffffffffc0200788:	951ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020078c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200790:	85da                	mv	a1,s6
ffffffffc0200792:	00002517          	auipc	a0,0x2
ffffffffc0200796:	b2650513          	addi	a0,a0,-1242 # ffffffffc02022b8 <commands+0x110>
ffffffffc020079a:	93fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020079e:	008b05b3          	add	a1,s6,s0
ffffffffc02007a2:	15fd                	addi	a1,a1,-1
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	b3450513          	addi	a0,a0,-1228 # ffffffffc02022d8 <commands+0x130>
ffffffffc02007ac:	92dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202328 <commands+0x180>
        memory_base = mem_base;
ffffffffc02007b8:	00006797          	auipc	a5,0x6
ffffffffc02007bc:	c887b823          	sd	s0,-880(a5) # ffffffffc0206448 <memory_base>
        memory_size = mem_size;
ffffffffc02007c0:	00006797          	auipc	a5,0x6
ffffffffc02007c4:	c967b823          	sd	s6,-880(a5) # ffffffffc0206450 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007c8:	b3f5                	j	ffffffffc02005b4 <dtb_init+0x186>

ffffffffc02007ca <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007ca:	00006517          	auipc	a0,0x6
ffffffffc02007ce:	c7e53503          	ld	a0,-898(a0) # ffffffffc0206448 <memory_base>
ffffffffc02007d2:	8082                	ret

ffffffffc02007d4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007d4:	00006517          	auipc	a0,0x6
ffffffffc02007d8:	c7c53503          	ld	a0,-900(a0) # ffffffffc0206450 <memory_size>
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
ffffffffc02007f6:	6e8010ef          	jal	ra,ffffffffc0201ede <sbi_set_timer>
}
ffffffffc02007fa:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc02007fc:	00006797          	auipc	a5,0x6
ffffffffc0200800:	c407be23          	sd	zero,-932(a5) # ffffffffc0206458 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200804:	00002517          	auipc	a0,0x2
ffffffffc0200808:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0202340 <commands+0x198>
}
ffffffffc020080c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020080e:	8cbff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200812 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200812:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200816:	67e1                	lui	a5,0x18
ffffffffc0200818:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020081c:	953e                	add	a0,a0,a5
ffffffffc020081e:	6c00106f          	j	ffffffffc0201ede <sbi_set_timer>

ffffffffc0200822 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200824:	0ff57513          	zext.b	a0,a0
ffffffffc0200828:	69c0106f          	j	ffffffffc0201ec4 <sbi_console_putchar>

ffffffffc020082c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020082c:	6cc0106f          	j	ffffffffc0201ef8 <sbi_console_getchar>

ffffffffc0200830 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200830:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200834:	8082                	ret

ffffffffc0200836 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200836:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020083a:	8082                	ret

ffffffffc020083c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020083c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200840:	00000797          	auipc	a5,0x0
ffffffffc0200844:	31c78793          	addi	a5,a5,796 # ffffffffc0200b5c <__alltraps>
ffffffffc0200848:	10579073          	csrw	stvec,a5
}
ffffffffc020084c:	8082                	ret

ffffffffc020084e <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020084e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200850:	1141                	addi	sp,sp,-16
ffffffffc0200852:	e022                	sd	s0,0(sp)
ffffffffc0200854:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0202360 <commands+0x1b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200860:	879ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200864:	640c                	ld	a1,8(s0)
ffffffffc0200866:	00002517          	auipc	a0,0x2
ffffffffc020086a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0202378 <commands+0x1d0>
ffffffffc020086e:	86bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200872:	680c                	ld	a1,16(s0)
ffffffffc0200874:	00002517          	auipc	a0,0x2
ffffffffc0200878:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0202390 <commands+0x1e8>
ffffffffc020087c:	85dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200880:	6c0c                	ld	a1,24(s0)
ffffffffc0200882:	00002517          	auipc	a0,0x2
ffffffffc0200886:	b2650513          	addi	a0,a0,-1242 # ffffffffc02023a8 <commands+0x200>
ffffffffc020088a:	84fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088e:	700c                	ld	a1,32(s0)
ffffffffc0200890:	00002517          	auipc	a0,0x2
ffffffffc0200894:	b3050513          	addi	a0,a0,-1232 # ffffffffc02023c0 <commands+0x218>
ffffffffc0200898:	841ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089c:	740c                	ld	a1,40(s0)
ffffffffc020089e:	00002517          	auipc	a0,0x2
ffffffffc02008a2:	b3a50513          	addi	a0,a0,-1222 # ffffffffc02023d8 <commands+0x230>
ffffffffc02008a6:	833ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008aa:	780c                	ld	a1,48(s0)
ffffffffc02008ac:	00002517          	auipc	a0,0x2
ffffffffc02008b0:	b4450513          	addi	a0,a0,-1212 # ffffffffc02023f0 <commands+0x248>
ffffffffc02008b4:	825ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b8:	7c0c                	ld	a1,56(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0202408 <commands+0x260>
ffffffffc02008c2:	817ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c6:	602c                	ld	a1,64(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202420 <commands+0x278>
ffffffffc02008d0:	809ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d4:	642c                	ld	a1,72(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202438 <commands+0x290>
ffffffffc02008de:	ffaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e2:	682c                	ld	a1,80(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0202450 <commands+0x2a8>
ffffffffc02008ec:	fecff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008f0:	6c2c                	ld	a1,88(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	b7650513          	addi	a0,a0,-1162 # ffffffffc0202468 <commands+0x2c0>
ffffffffc02008fa:	fdeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fe:	702c                	ld	a1,96(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	b8050513          	addi	a0,a0,-1152 # ffffffffc0202480 <commands+0x2d8>
ffffffffc0200908:	fd0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090c:	742c                	ld	a1,104(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0202498 <commands+0x2f0>
ffffffffc0200916:	fc2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020091a:	782c                	ld	a1,112(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	b9450513          	addi	a0,a0,-1132 # ffffffffc02024b0 <commands+0x308>
ffffffffc0200924:	fb4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200928:	7c2c                	ld	a1,120(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc02024c8 <commands+0x320>
ffffffffc0200932:	fa6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200936:	604c                	ld	a1,128(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	ba850513          	addi	a0,a0,-1112 # ffffffffc02024e0 <commands+0x338>
ffffffffc0200940:	f98ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200944:	644c                	ld	a1,136(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	bb250513          	addi	a0,a0,-1102 # ffffffffc02024f8 <commands+0x350>
ffffffffc020094e:	f8aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200952:	684c                	ld	a1,144(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202510 <commands+0x368>
ffffffffc020095c:	f7cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200960:	6c4c                	ld	a1,152(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202528 <commands+0x380>
ffffffffc020096a:	f6eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096e:	704c                	ld	a1,160(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	bd050513          	addi	a0,a0,-1072 # ffffffffc0202540 <commands+0x398>
ffffffffc0200978:	f60ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097c:	744c                	ld	a1,168(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202558 <commands+0x3b0>
ffffffffc0200986:	f52ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020098a:	784c                	ld	a1,176(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	be450513          	addi	a0,a0,-1052 # ffffffffc0202570 <commands+0x3c8>
ffffffffc0200994:	f44ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200998:	7c4c                	ld	a1,184(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	bee50513          	addi	a0,a0,-1042 # ffffffffc0202588 <commands+0x3e0>
ffffffffc02009a2:	f36ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a6:	606c                	ld	a1,192(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	bf850513          	addi	a0,a0,-1032 # ffffffffc02025a0 <commands+0x3f8>
ffffffffc02009b0:	f28ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b4:	646c                	ld	a1,200(s0)
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	c0250513          	addi	a0,a0,-1022 # ffffffffc02025b8 <commands+0x410>
ffffffffc02009be:	f1aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c2:	686c                	ld	a1,208(s0)
ffffffffc02009c4:	00002517          	auipc	a0,0x2
ffffffffc02009c8:	c0c50513          	addi	a0,a0,-1012 # ffffffffc02025d0 <commands+0x428>
ffffffffc02009cc:	f0cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009d0:	6c6c                	ld	a1,216(s0)
ffffffffc02009d2:	00002517          	auipc	a0,0x2
ffffffffc02009d6:	c1650513          	addi	a0,a0,-1002 # ffffffffc02025e8 <commands+0x440>
ffffffffc02009da:	efeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009de:	706c                	ld	a1,224(s0)
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	c2050513          	addi	a0,a0,-992 # ffffffffc0202600 <commands+0x458>
ffffffffc02009e8:	ef0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ec:	746c                	ld	a1,232(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	c2a50513          	addi	a0,a0,-982 # ffffffffc0202618 <commands+0x470>
ffffffffc02009f6:	ee2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009fa:	786c                	ld	a1,240(s0)
ffffffffc02009fc:	00002517          	auipc	a0,0x2
ffffffffc0200a00:	c3450513          	addi	a0,a0,-972 # ffffffffc0202630 <commands+0x488>
ffffffffc0200a04:	ed4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a08:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a0a:	6402                	ld	s0,0(sp)
ffffffffc0200a0c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	c3a50513          	addi	a0,a0,-966 # ffffffffc0202648 <commands+0x4a0>
}
ffffffffc0200a16:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a18:	ec0ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a1c <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1c:	1141                	addi	sp,sp,-16
ffffffffc0200a1e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a20:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a22:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a24:	00002517          	auipc	a0,0x2
ffffffffc0200a28:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202660 <commands+0x4b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2e:	eaaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a32:	8522                	mv	a0,s0
ffffffffc0200a34:	e1bff0ef          	jal	ra,ffffffffc020084e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a38:	10043583          	ld	a1,256(s0)
ffffffffc0200a3c:	00002517          	auipc	a0,0x2
ffffffffc0200a40:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202678 <commands+0x4d0>
ffffffffc0200a44:	e94ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a48:	10843583          	ld	a1,264(s0)
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	c4450513          	addi	a0,a0,-956 # ffffffffc0202690 <commands+0x4e8>
ffffffffc0200a54:	e84ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a58:	11043583          	ld	a1,272(s0)
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	c4c50513          	addi	a0,a0,-948 # ffffffffc02026a8 <commands+0x500>
ffffffffc0200a64:	e74ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a68:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6c:	6402                	ld	s0,0(sp)
ffffffffc0200a6e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	c5050513          	addi	a0,a0,-944 # ffffffffc02026c0 <commands+0x518>
}
ffffffffc0200a78:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a7a:	e5eff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7e <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a7e:	11853783          	ld	a5,280(a0)
ffffffffc0200a82:	472d                	li	a4,11
ffffffffc0200a84:	0786                	slli	a5,a5,0x1
ffffffffc0200a86:	8385                	srli	a5,a5,0x1
ffffffffc0200a88:	08f76363          	bltu	a4,a5,ffffffffc0200b0e <interrupt_handler+0x90>
ffffffffc0200a8c:	00002717          	auipc	a4,0x2
ffffffffc0200a90:	d2c70713          	addi	a4,a4,-724 # ffffffffc02027b8 <commands+0x610>
ffffffffc0200a94:	078a                	slli	a5,a5,0x2
ffffffffc0200a96:	97ba                	add	a5,a5,a4
ffffffffc0200a98:	439c                	lw	a5,0(a5)
ffffffffc0200a9a:	97ba                	add	a5,a5,a4
ffffffffc0200a9c:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a9e:	00002517          	auipc	a0,0x2
ffffffffc0200aa2:	c9a50513          	addi	a0,a0,-870 # ffffffffc0202738 <commands+0x590>
ffffffffc0200aa6:	e32ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aaa:	00002517          	auipc	a0,0x2
ffffffffc0200aae:	c6e50513          	addi	a0,a0,-914 # ffffffffc0202718 <commands+0x570>
ffffffffc0200ab2:	e26ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	c2250513          	addi	a0,a0,-990 # ffffffffc02026d8 <commands+0x530>
ffffffffc0200abe:	e1aff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	c9650513          	addi	a0,a0,-874 # ffffffffc0202758 <commands+0x5b0>
ffffffffc0200aca:	e0eff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200ace:	1141                	addi	sp,sp,-16
ffffffffc0200ad0:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200ad2:	d41ff0ef          	jal	ra,ffffffffc0200812 <clock_set_next_event>
            ticks++;
ffffffffc0200ad6:	00006797          	auipc	a5,0x6
ffffffffc0200ada:	98278793          	addi	a5,a5,-1662 # ffffffffc0206458 <ticks>
ffffffffc0200ade:	6398                	ld	a4,0(a5)
ffffffffc0200ae0:	0705                	addi	a4,a4,1
ffffffffc0200ae2:	e398                	sd	a4,0(a5)
            if(ticks%TICK_NUM == 0){
ffffffffc0200ae4:	639c                	ld	a5,0(a5)
ffffffffc0200ae6:	06400713          	li	a4,100
ffffffffc0200aea:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200aee:	c38d                	beqz	a5,ffffffffc0200b10 <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200af0:	60a2                	ld	ra,8(sp)
ffffffffc0200af2:	0141                	addi	sp,sp,16
ffffffffc0200af4:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200af6:	00002517          	auipc	a0,0x2
ffffffffc0200afa:	ca250513          	addi	a0,a0,-862 # ffffffffc0202798 <commands+0x5f0>
ffffffffc0200afe:	ddaff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	bf650513          	addi	a0,a0,-1034 # ffffffffc02026f8 <commands+0x550>
ffffffffc0200b0a:	dceff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b0e:	b739                	j	ffffffffc0200a1c <print_trapframe>
                cprintf("100ticks\n");
ffffffffc0200b10:	00002517          	auipc	a0,0x2
ffffffffc0200b14:	c6050513          	addi	a0,a0,-928 # ffffffffc0202770 <commands+0x5c8>
ffffffffc0200b18:	dc0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                num++;
ffffffffc0200b1c:	00006797          	auipc	a5,0x6
ffffffffc0200b20:	94478793          	addi	a5,a5,-1724 # ffffffffc0206460 <num>
ffffffffc0200b24:	6398                	ld	a4,0(a5)
                if(num == 10){
ffffffffc0200b26:	46a9                	li	a3,10
                num++;
ffffffffc0200b28:	0705                	addi	a4,a4,1
ffffffffc0200b2a:	e398                	sd	a4,0(a5)
                if(num == 10){
ffffffffc0200b2c:	639c                	ld	a5,0(a5)
ffffffffc0200b2e:	fcd791e3          	bne	a5,a3,ffffffffc0200af0 <interrupt_handler+0x72>
                    cprintf("shutting down...\n");
ffffffffc0200b32:	00002517          	auipc	a0,0x2
ffffffffc0200b36:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202780 <commands+0x5d8>
ffffffffc0200b3a:	d9eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
}
ffffffffc0200b3e:	60a2                	ld	ra,8(sp)
ffffffffc0200b40:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b42:	3d20106f          	j	ffffffffc0201f14 <sbi_shutdown>

ffffffffc0200b46 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b46:	11853783          	ld	a5,280(a0)
ffffffffc0200b4a:	0007c763          	bltz	a5,ffffffffc0200b58 <trap+0x12>
    switch (tf->cause) {
ffffffffc0200b4e:	472d                	li	a4,11
ffffffffc0200b50:	00f76363          	bltu	a4,a5,ffffffffc0200b56 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200b54:	8082                	ret
            print_trapframe(tf);
ffffffffc0200b56:	b5d9                	j	ffffffffc0200a1c <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200b58:	b71d                	j	ffffffffc0200a7e <interrupt_handler>
	...

ffffffffc0200b5c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b5c:	14011073          	csrw	sscratch,sp
ffffffffc0200b60:	712d                	addi	sp,sp,-288
ffffffffc0200b62:	e002                	sd	zero,0(sp)
ffffffffc0200b64:	e406                	sd	ra,8(sp)
ffffffffc0200b66:	ec0e                	sd	gp,24(sp)
ffffffffc0200b68:	f012                	sd	tp,32(sp)
ffffffffc0200b6a:	f416                	sd	t0,40(sp)
ffffffffc0200b6c:	f81a                	sd	t1,48(sp)
ffffffffc0200b6e:	fc1e                	sd	t2,56(sp)
ffffffffc0200b70:	e0a2                	sd	s0,64(sp)
ffffffffc0200b72:	e4a6                	sd	s1,72(sp)
ffffffffc0200b74:	e8aa                	sd	a0,80(sp)
ffffffffc0200b76:	ecae                	sd	a1,88(sp)
ffffffffc0200b78:	f0b2                	sd	a2,96(sp)
ffffffffc0200b7a:	f4b6                	sd	a3,104(sp)
ffffffffc0200b7c:	f8ba                	sd	a4,112(sp)
ffffffffc0200b7e:	fcbe                	sd	a5,120(sp)
ffffffffc0200b80:	e142                	sd	a6,128(sp)
ffffffffc0200b82:	e546                	sd	a7,136(sp)
ffffffffc0200b84:	e94a                	sd	s2,144(sp)
ffffffffc0200b86:	ed4e                	sd	s3,152(sp)
ffffffffc0200b88:	f152                	sd	s4,160(sp)
ffffffffc0200b8a:	f556                	sd	s5,168(sp)
ffffffffc0200b8c:	f95a                	sd	s6,176(sp)
ffffffffc0200b8e:	fd5e                	sd	s7,184(sp)
ffffffffc0200b90:	e1e2                	sd	s8,192(sp)
ffffffffc0200b92:	e5e6                	sd	s9,200(sp)
ffffffffc0200b94:	e9ea                	sd	s10,208(sp)
ffffffffc0200b96:	edee                	sd	s11,216(sp)
ffffffffc0200b98:	f1f2                	sd	t3,224(sp)
ffffffffc0200b9a:	f5f6                	sd	t4,232(sp)
ffffffffc0200b9c:	f9fa                	sd	t5,240(sp)
ffffffffc0200b9e:	fdfe                	sd	t6,248(sp)
ffffffffc0200ba0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ba4:	100024f3          	csrr	s1,sstatus
ffffffffc0200ba8:	14102973          	csrr	s2,sepc
ffffffffc0200bac:	143029f3          	csrr	s3,stval
ffffffffc0200bb0:	14202a73          	csrr	s4,scause
ffffffffc0200bb4:	e822                	sd	s0,16(sp)
ffffffffc0200bb6:	e226                	sd	s1,256(sp)
ffffffffc0200bb8:	e64a                	sd	s2,264(sp)
ffffffffc0200bba:	ea4e                	sd	s3,272(sp)
ffffffffc0200bbc:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bbe:	850a                	mv	a0,sp
    jal trap
ffffffffc0200bc0:	f87ff0ef          	jal	ra,ffffffffc0200b46 <trap>

ffffffffc0200bc4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200bc4:	6492                	ld	s1,256(sp)
ffffffffc0200bc6:	6932                	ld	s2,264(sp)
ffffffffc0200bc8:	10049073          	csrw	sstatus,s1
ffffffffc0200bcc:	14191073          	csrw	sepc,s2
ffffffffc0200bd0:	60a2                	ld	ra,8(sp)
ffffffffc0200bd2:	61e2                	ld	gp,24(sp)
ffffffffc0200bd4:	7202                	ld	tp,32(sp)
ffffffffc0200bd6:	72a2                	ld	t0,40(sp)
ffffffffc0200bd8:	7342                	ld	t1,48(sp)
ffffffffc0200bda:	73e2                	ld	t2,56(sp)
ffffffffc0200bdc:	6406                	ld	s0,64(sp)
ffffffffc0200bde:	64a6                	ld	s1,72(sp)
ffffffffc0200be0:	6546                	ld	a0,80(sp)
ffffffffc0200be2:	65e6                	ld	a1,88(sp)
ffffffffc0200be4:	7606                	ld	a2,96(sp)
ffffffffc0200be6:	76a6                	ld	a3,104(sp)
ffffffffc0200be8:	7746                	ld	a4,112(sp)
ffffffffc0200bea:	77e6                	ld	a5,120(sp)
ffffffffc0200bec:	680a                	ld	a6,128(sp)
ffffffffc0200bee:	68aa                	ld	a7,136(sp)
ffffffffc0200bf0:	694a                	ld	s2,144(sp)
ffffffffc0200bf2:	69ea                	ld	s3,152(sp)
ffffffffc0200bf4:	7a0a                	ld	s4,160(sp)
ffffffffc0200bf6:	7aaa                	ld	s5,168(sp)
ffffffffc0200bf8:	7b4a                	ld	s6,176(sp)
ffffffffc0200bfa:	7bea                	ld	s7,184(sp)
ffffffffc0200bfc:	6c0e                	ld	s8,192(sp)
ffffffffc0200bfe:	6cae                	ld	s9,200(sp)
ffffffffc0200c00:	6d4e                	ld	s10,208(sp)
ffffffffc0200c02:	6dee                	ld	s11,216(sp)
ffffffffc0200c04:	7e0e                	ld	t3,224(sp)
ffffffffc0200c06:	7eae                	ld	t4,232(sp)
ffffffffc0200c08:	7f4e                	ld	t5,240(sp)
ffffffffc0200c0a:	7fee                	ld	t6,248(sp)
ffffffffc0200c0c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c0e:	10200073          	sret

ffffffffc0200c12 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200c12:	100027f3          	csrr	a5,sstatus
ffffffffc0200c16:	8b89                	andi	a5,a5,2
ffffffffc0200c18:	e799                	bnez	a5,ffffffffc0200c26 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200c1a:	00006797          	auipc	a5,0x6
ffffffffc0200c1e:	85e7b783          	ld	a5,-1954(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200c22:	6f9c                	ld	a5,24(a5)
ffffffffc0200c24:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200c26:	1141                	addi	sp,sp,-16
ffffffffc0200c28:	e406                	sd	ra,8(sp)
ffffffffc0200c2a:	e022                	sd	s0,0(sp)
ffffffffc0200c2c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200c2e:	c09ff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200c32:	00006797          	auipc	a5,0x6
ffffffffc0200c36:	8467b783          	ld	a5,-1978(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200c3a:	6f9c                	ld	a5,24(a5)
ffffffffc0200c3c:	8522                	mv	a0,s0
ffffffffc0200c3e:	9782                	jalr	a5
ffffffffc0200c40:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200c42:	befff0ef          	jal	ra,ffffffffc0200830 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200c46:	60a2                	ld	ra,8(sp)
ffffffffc0200c48:	8522                	mv	a0,s0
ffffffffc0200c4a:	6402                	ld	s0,0(sp)
ffffffffc0200c4c:	0141                	addi	sp,sp,16
ffffffffc0200c4e:	8082                	ret

ffffffffc0200c50 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200c50:	100027f3          	csrr	a5,sstatus
ffffffffc0200c54:	8b89                	andi	a5,a5,2
ffffffffc0200c56:	e799                	bnez	a5,ffffffffc0200c64 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200c58:	00006797          	auipc	a5,0x6
ffffffffc0200c5c:	8207b783          	ld	a5,-2016(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200c60:	739c                	ld	a5,32(a5)
ffffffffc0200c62:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200c64:	1101                	addi	sp,sp,-32
ffffffffc0200c66:	ec06                	sd	ra,24(sp)
ffffffffc0200c68:	e822                	sd	s0,16(sp)
ffffffffc0200c6a:	e426                	sd	s1,8(sp)
ffffffffc0200c6c:	842a                	mv	s0,a0
ffffffffc0200c6e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200c70:	bc7ff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200c74:	00006797          	auipc	a5,0x6
ffffffffc0200c78:	8047b783          	ld	a5,-2044(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200c7c:	739c                	ld	a5,32(a5)
ffffffffc0200c7e:	85a6                	mv	a1,s1
ffffffffc0200c80:	8522                	mv	a0,s0
ffffffffc0200c82:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200c84:	6442                	ld	s0,16(sp)
ffffffffc0200c86:	60e2                	ld	ra,24(sp)
ffffffffc0200c88:	64a2                	ld	s1,8(sp)
ffffffffc0200c8a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200c8c:	b655                	j	ffffffffc0200830 <intr_enable>

ffffffffc0200c8e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200c8e:	100027f3          	csrr	a5,sstatus
ffffffffc0200c92:	8b89                	andi	a5,a5,2
ffffffffc0200c94:	e799                	bnez	a5,ffffffffc0200ca2 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200c96:	00005797          	auipc	a5,0x5
ffffffffc0200c9a:	7e27b783          	ld	a5,2018(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200c9e:	779c                	ld	a5,40(a5)
ffffffffc0200ca0:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200ca2:	1141                	addi	sp,sp,-16
ffffffffc0200ca4:	e406                	sd	ra,8(sp)
ffffffffc0200ca6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200ca8:	b8fff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200cac:	00005797          	auipc	a5,0x5
ffffffffc0200cb0:	7cc7b783          	ld	a5,1996(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200cb4:	779c                	ld	a5,40(a5)
ffffffffc0200cb6:	9782                	jalr	a5
ffffffffc0200cb8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200cba:	b77ff0ef          	jal	ra,ffffffffc0200830 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200cbe:	60a2                	ld	ra,8(sp)
ffffffffc0200cc0:	8522                	mv	a0,s0
ffffffffc0200cc2:	6402                	ld	s0,0(sp)
ffffffffc0200cc4:	0141                	addi	sp,sp,16
ffffffffc0200cc6:	8082                	ret

ffffffffc0200cc8 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0200cc8:	00002797          	auipc	a5,0x2
ffffffffc0200ccc:	02878793          	addi	a5,a5,40 # ffffffffc0202cf0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200cd0:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200cd2:	7179                	addi	sp,sp,-48
ffffffffc0200cd4:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200cd6:	00002517          	auipc	a0,0x2
ffffffffc0200cda:	b1250513          	addi	a0,a0,-1262 # ffffffffc02027e8 <commands+0x640>
    pmm_manager = &default_pmm_manager;
ffffffffc0200cde:	00005417          	auipc	s0,0x5
ffffffffc0200ce2:	79a40413          	addi	s0,s0,1946 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc0200ce6:	f406                	sd	ra,40(sp)
ffffffffc0200ce8:	ec26                	sd	s1,24(sp)
ffffffffc0200cea:	e44e                	sd	s3,8(sp)
ffffffffc0200cec:	e84a                	sd	s2,16(sp)
ffffffffc0200cee:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200cf0:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200cf2:	be6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0200cf6:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200cf8:	00005497          	auipc	s1,0x5
ffffffffc0200cfc:	79848493          	addi	s1,s1,1944 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200d00:	679c                	ld	a5,8(a5)
ffffffffc0200d02:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200d04:	57f5                	li	a5,-3
ffffffffc0200d06:	07fa                	slli	a5,a5,0x1e
ffffffffc0200d08:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200d0a:	ac1ff0ef          	jal	ra,ffffffffc02007ca <get_memory_base>
ffffffffc0200d0e:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200d10:	ac5ff0ef          	jal	ra,ffffffffc02007d4 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200d14:	16050163          	beqz	a0,ffffffffc0200e76 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200d18:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200d1a:	00002517          	auipc	a0,0x2
ffffffffc0200d1e:	b1650513          	addi	a0,a0,-1258 # ffffffffc0202830 <commands+0x688>
ffffffffc0200d22:	bb6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200d26:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200d2a:	864e                	mv	a2,s3
ffffffffc0200d2c:	fffa0693          	addi	a3,s4,-1
ffffffffc0200d30:	85ca                	mv	a1,s2
ffffffffc0200d32:	00002517          	auipc	a0,0x2
ffffffffc0200d36:	b1650513          	addi	a0,a0,-1258 # ffffffffc0202848 <commands+0x6a0>
ffffffffc0200d3a:	b9eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200d3e:	c80007b7          	lui	a5,0xc8000
ffffffffc0200d42:	8652                	mv	a2,s4
ffffffffc0200d44:	0d47e863          	bltu	a5,s4,ffffffffc0200e14 <pmm_init+0x14c>
ffffffffc0200d48:	00006797          	auipc	a5,0x6
ffffffffc0200d4c:	75778793          	addi	a5,a5,1879 # ffffffffc020749f <end+0xfff>
ffffffffc0200d50:	757d                	lui	a0,0xfffff
ffffffffc0200d52:	8d7d                	and	a0,a0,a5
ffffffffc0200d54:	8231                	srli	a2,a2,0xc
ffffffffc0200d56:	00005597          	auipc	a1,0x5
ffffffffc0200d5a:	71258593          	addi	a1,a1,1810 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200d5e:	00005817          	auipc	a6,0x5
ffffffffc0200d62:	71280813          	addi	a6,a6,1810 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200d66:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200d68:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d6c:	000807b7          	lui	a5,0x80
ffffffffc0200d70:	02f60663          	beq	a2,a5,ffffffffc0200d9c <pmm_init+0xd4>
ffffffffc0200d74:	4701                	li	a4,0
ffffffffc0200d76:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d78:	4305                	li	t1,1
ffffffffc0200d7a:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0200d7e:	953a                	add	a0,a0,a4
ffffffffc0200d80:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc0200d84:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d88:	6190                	ld	a2,0(a1)
ffffffffc0200d8a:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0200d8c:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d90:	011606b3          	add	a3,a2,a7
ffffffffc0200d94:	02870713          	addi	a4,a4,40
ffffffffc0200d98:	fed7e3e3          	bltu	a5,a3,ffffffffc0200d7e <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d9c:	00261693          	slli	a3,a2,0x2
ffffffffc0200da0:	96b2                	add	a3,a3,a2
ffffffffc0200da2:	fec007b7          	lui	a5,0xfec00
ffffffffc0200da6:	97aa                	add	a5,a5,a0
ffffffffc0200da8:	068e                	slli	a3,a3,0x3
ffffffffc0200daa:	96be                	add	a3,a3,a5
ffffffffc0200dac:	c02007b7          	lui	a5,0xc0200
ffffffffc0200db0:	0af6e763          	bltu	a3,a5,ffffffffc0200e5e <pmm_init+0x196>
ffffffffc0200db4:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200db6:	77fd                	lui	a5,0xfffff
ffffffffc0200db8:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200dbc:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200dbe:	04b6ee63          	bltu	a3,a1,ffffffffc0200e1a <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200dc2:	601c                	ld	a5,0(s0)
ffffffffc0200dc4:	7b9c                	ld	a5,48(a5)
ffffffffc0200dc6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200dc8:	00002517          	auipc	a0,0x2
ffffffffc0200dcc:	b0850513          	addi	a0,a0,-1272 # ffffffffc02028d0 <commands+0x728>
ffffffffc0200dd0:	b08ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200dd4:	00004597          	auipc	a1,0x4
ffffffffc0200dd8:	22c58593          	addi	a1,a1,556 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200ddc:	00005797          	auipc	a5,0x5
ffffffffc0200de0:	6ab7b623          	sd	a1,1708(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200de4:	c02007b7          	lui	a5,0xc0200
ffffffffc0200de8:	0af5e363          	bltu	a1,a5,ffffffffc0200e8e <pmm_init+0x1c6>
ffffffffc0200dec:	6090                	ld	a2,0(s1)
}
ffffffffc0200dee:	7402                	ld	s0,32(sp)
ffffffffc0200df0:	70a2                	ld	ra,40(sp)
ffffffffc0200df2:	64e2                	ld	s1,24(sp)
ffffffffc0200df4:	6942                	ld	s2,16(sp)
ffffffffc0200df6:	69a2                	ld	s3,8(sp)
ffffffffc0200df8:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200dfa:	40c58633          	sub	a2,a1,a2
ffffffffc0200dfe:	00005797          	auipc	a5,0x5
ffffffffc0200e02:	68c7b123          	sd	a2,1666(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200e06:	00002517          	auipc	a0,0x2
ffffffffc0200e0a:	aea50513          	addi	a0,a0,-1302 # ffffffffc02028f0 <commands+0x748>
}
ffffffffc0200e0e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200e10:	ac8ff06f          	j	ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200e14:	c8000637          	lui	a2,0xc8000
ffffffffc0200e18:	bf05                	j	ffffffffc0200d48 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200e1a:	6705                	lui	a4,0x1
ffffffffc0200e1c:	177d                	addi	a4,a4,-1
ffffffffc0200e1e:	96ba                	add	a3,a3,a4
ffffffffc0200e20:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200e22:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200e26:	02c7f063          	bgeu	a5,a2,ffffffffc0200e46 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0200e2a:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200e2c:	fff80737          	lui	a4,0xfff80
ffffffffc0200e30:	973e                	add	a4,a4,a5
ffffffffc0200e32:	00271793          	slli	a5,a4,0x2
ffffffffc0200e36:	97ba                	add	a5,a5,a4
ffffffffc0200e38:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200e3a:	8d95                	sub	a1,a1,a3
ffffffffc0200e3c:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200e3e:	81b1                	srli	a1,a1,0xc
ffffffffc0200e40:	953e                	add	a0,a0,a5
ffffffffc0200e42:	9702                	jalr	a4
}
ffffffffc0200e44:	bfbd                	j	ffffffffc0200dc2 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0200e46:	00002617          	auipc	a2,0x2
ffffffffc0200e4a:	a5a60613          	addi	a2,a2,-1446 # ffffffffc02028a0 <commands+0x6f8>
ffffffffc0200e4e:	06b00593          	li	a1,107
ffffffffc0200e52:	00002517          	auipc	a0,0x2
ffffffffc0200e56:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02028c0 <commands+0x718>
ffffffffc0200e5a:	b06ff0ef          	jal	ra,ffffffffc0200160 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e5e:	00002617          	auipc	a2,0x2
ffffffffc0200e62:	a1a60613          	addi	a2,a2,-1510 # ffffffffc0202878 <commands+0x6d0>
ffffffffc0200e66:	07100593          	li	a1,113
ffffffffc0200e6a:	00002517          	auipc	a0,0x2
ffffffffc0200e6e:	9b650513          	addi	a0,a0,-1610 # ffffffffc0202820 <commands+0x678>
ffffffffc0200e72:	aeeff0ef          	jal	ra,ffffffffc0200160 <__panic>
        panic("DTB memory info not available");
ffffffffc0200e76:	00002617          	auipc	a2,0x2
ffffffffc0200e7a:	98a60613          	addi	a2,a2,-1654 # ffffffffc0202800 <commands+0x658>
ffffffffc0200e7e:	05a00593          	li	a1,90
ffffffffc0200e82:	00002517          	auipc	a0,0x2
ffffffffc0200e86:	99e50513          	addi	a0,a0,-1634 # ffffffffc0202820 <commands+0x678>
ffffffffc0200e8a:	ad6ff0ef          	jal	ra,ffffffffc0200160 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e8e:	86ae                	mv	a3,a1
ffffffffc0200e90:	00002617          	auipc	a2,0x2
ffffffffc0200e94:	9e860613          	addi	a2,a2,-1560 # ffffffffc0202878 <commands+0x6d0>
ffffffffc0200e98:	08c00593          	li	a1,140
ffffffffc0200e9c:	00002517          	auipc	a0,0x2
ffffffffc0200ea0:	98450513          	addi	a0,a0,-1660 # ffffffffc0202820 <commands+0x678>
ffffffffc0200ea4:	abcff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200ea8 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ea8:	00005797          	auipc	a5,0x5
ffffffffc0200eac:	18078793          	addi	a5,a5,384 # ffffffffc0206028 <free_area>
ffffffffc0200eb0:	e79c                	sd	a5,8(a5)
ffffffffc0200eb2:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200eb4:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200eb8:	8082                	ret

ffffffffc0200eba <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200eba:	00005517          	auipc	a0,0x5
ffffffffc0200ebe:	17e56503          	lwu	a0,382(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200ec2:	8082                	ret

ffffffffc0200ec4 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200ec4:	715d                	addi	sp,sp,-80
ffffffffc0200ec6:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ec8:	00005417          	auipc	s0,0x5
ffffffffc0200ecc:	16040413          	addi	s0,s0,352 # ffffffffc0206028 <free_area>
ffffffffc0200ed0:	641c                	ld	a5,8(s0)
ffffffffc0200ed2:	e486                	sd	ra,72(sp)
ffffffffc0200ed4:	fc26                	sd	s1,56(sp)
ffffffffc0200ed6:	f84a                	sd	s2,48(sp)
ffffffffc0200ed8:	f44e                	sd	s3,40(sp)
ffffffffc0200eda:	f052                	sd	s4,32(sp)
ffffffffc0200edc:	ec56                	sd	s5,24(sp)
ffffffffc0200ede:	e85a                	sd	s6,16(sp)
ffffffffc0200ee0:	e45e                	sd	s7,8(sp)
ffffffffc0200ee2:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ee4:	2c878763          	beq	a5,s0,ffffffffc02011b2 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200ee8:	4481                	li	s1,0
ffffffffc0200eea:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200eec:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ef0:	8b09                	andi	a4,a4,2
ffffffffc0200ef2:	2c070463          	beqz	a4,ffffffffc02011ba <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200ef6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200efa:	679c                	ld	a5,8(a5)
ffffffffc0200efc:	2905                	addiw	s2,s2,1
ffffffffc0200efe:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f00:	fe8796e3          	bne	a5,s0,ffffffffc0200eec <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200f04:	89a6                	mv	s3,s1
ffffffffc0200f06:	d89ff0ef          	jal	ra,ffffffffc0200c8e <nr_free_pages>
ffffffffc0200f0a:	71351863          	bne	a0,s3,ffffffffc020161a <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f0e:	4505                	li	a0,1
ffffffffc0200f10:	d03ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0200f14:	8a2a                	mv	s4,a0
ffffffffc0200f16:	44050263          	beqz	a0,ffffffffc020135a <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f1a:	4505                	li	a0,1
ffffffffc0200f1c:	cf7ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0200f20:	89aa                	mv	s3,a0
ffffffffc0200f22:	70050c63          	beqz	a0,ffffffffc020163a <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f26:	4505                	li	a0,1
ffffffffc0200f28:	cebff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0200f2c:	8aaa                	mv	s5,a0
ffffffffc0200f2e:	4a050663          	beqz	a0,ffffffffc02013da <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f32:	2b3a0463          	beq	s4,s3,ffffffffc02011da <default_check+0x316>
ffffffffc0200f36:	2aaa0263          	beq	s4,a0,ffffffffc02011da <default_check+0x316>
ffffffffc0200f3a:	2aa98063          	beq	s3,a0,ffffffffc02011da <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f3e:	000a2783          	lw	a5,0(s4)
ffffffffc0200f42:	2a079c63          	bnez	a5,ffffffffc02011fa <default_check+0x336>
ffffffffc0200f46:	0009a783          	lw	a5,0(s3)
ffffffffc0200f4a:	2a079863          	bnez	a5,ffffffffc02011fa <default_check+0x336>
ffffffffc0200f4e:	411c                	lw	a5,0(a0)
ffffffffc0200f50:	2a079563          	bnez	a5,ffffffffc02011fa <default_check+0x336>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f54:	00005797          	auipc	a5,0x5
ffffffffc0200f58:	51c7b783          	ld	a5,1308(a5) # ffffffffc0206470 <pages>
ffffffffc0200f5c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f60:	870d                	srai	a4,a4,0x3
ffffffffc0200f62:	00002597          	auipc	a1,0x2
ffffffffc0200f66:	0165b583          	ld	a1,22(a1) # ffffffffc0202f78 <nbase+0x8>
ffffffffc0200f6a:	02b70733          	mul	a4,a4,a1
ffffffffc0200f6e:	00002617          	auipc	a2,0x2
ffffffffc0200f72:	00263603          	ld	a2,2(a2) # ffffffffc0202f70 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f76:	00005697          	auipc	a3,0x5
ffffffffc0200f7a:	4f26b683          	ld	a3,1266(a3) # ffffffffc0206468 <npage>
ffffffffc0200f7e:	06b2                	slli	a3,a3,0xc
ffffffffc0200f80:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f82:	0732                	slli	a4,a4,0xc
ffffffffc0200f84:	28d77b63          	bgeu	a4,a3,ffffffffc020121a <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f88:	40f98733          	sub	a4,s3,a5
ffffffffc0200f8c:	870d                	srai	a4,a4,0x3
ffffffffc0200f8e:	02b70733          	mul	a4,a4,a1
ffffffffc0200f92:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f94:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f96:	4cd77263          	bgeu	a4,a3,ffffffffc020145a <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f9a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f9e:	878d                	srai	a5,a5,0x3
ffffffffc0200fa0:	02b787b3          	mul	a5,a5,a1
ffffffffc0200fa4:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fa6:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fa8:	30d7f963          	bgeu	a5,a3,ffffffffc02012ba <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200fac:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fae:	00043c03          	ld	s8,0(s0)
ffffffffc0200fb2:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200fb6:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200fba:	e400                	sd	s0,8(s0)
ffffffffc0200fbc:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200fbe:	00005797          	auipc	a5,0x5
ffffffffc0200fc2:	0607ad23          	sw	zero,122(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200fc6:	c4dff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0200fca:	2c051863          	bnez	a0,ffffffffc020129a <default_check+0x3d6>
    free_page(p0);
ffffffffc0200fce:	4585                	li	a1,1
ffffffffc0200fd0:	8552                	mv	a0,s4
ffffffffc0200fd2:	c7fff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    free_page(p1);
ffffffffc0200fd6:	4585                	li	a1,1
ffffffffc0200fd8:	854e                	mv	a0,s3
ffffffffc0200fda:	c77ff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    free_page(p2);
ffffffffc0200fde:	4585                	li	a1,1
ffffffffc0200fe0:	8556                	mv	a0,s5
ffffffffc0200fe2:	c6fff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    assert(nr_free == 3);
ffffffffc0200fe6:	4818                	lw	a4,16(s0)
ffffffffc0200fe8:	478d                	li	a5,3
ffffffffc0200fea:	28f71863          	bne	a4,a5,ffffffffc020127a <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fee:	4505                	li	a0,1
ffffffffc0200ff0:	c23ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0200ff4:	89aa                	mv	s3,a0
ffffffffc0200ff6:	26050263          	beqz	a0,ffffffffc020125a <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ffa:	4505                	li	a0,1
ffffffffc0200ffc:	c17ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0201000:	8aaa                	mv	s5,a0
ffffffffc0201002:	3a050c63          	beqz	a0,ffffffffc02013ba <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201006:	4505                	li	a0,1
ffffffffc0201008:	c0bff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc020100c:	8a2a                	mv	s4,a0
ffffffffc020100e:	38050663          	beqz	a0,ffffffffc020139a <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0201012:	4505                	li	a0,1
ffffffffc0201014:	bffff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0201018:	36051163          	bnez	a0,ffffffffc020137a <default_check+0x4b6>
    free_page(p0);
ffffffffc020101c:	4585                	li	a1,1
ffffffffc020101e:	854e                	mv	a0,s3
ffffffffc0201020:	c31ff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201024:	641c                	ld	a5,8(s0)
ffffffffc0201026:	20878a63          	beq	a5,s0,ffffffffc020123a <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc020102a:	4505                	li	a0,1
ffffffffc020102c:	be7ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0201030:	30a99563          	bne	s3,a0,ffffffffc020133a <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0201034:	4505                	li	a0,1
ffffffffc0201036:	bddff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc020103a:	2e051063          	bnez	a0,ffffffffc020131a <default_check+0x456>
    assert(nr_free == 0);
ffffffffc020103e:	481c                	lw	a5,16(s0)
ffffffffc0201040:	2a079d63          	bnez	a5,ffffffffc02012fa <default_check+0x436>
    free_page(p);
ffffffffc0201044:	854e                	mv	a0,s3
ffffffffc0201046:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201048:	01843023          	sd	s8,0(s0)
ffffffffc020104c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201050:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201054:	bfdff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    free_page(p1);
ffffffffc0201058:	4585                	li	a1,1
ffffffffc020105a:	8556                	mv	a0,s5
ffffffffc020105c:	bf5ff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    free_page(p2);
ffffffffc0201060:	4585                	li	a1,1
ffffffffc0201062:	8552                	mv	a0,s4
ffffffffc0201064:	bedff0ef          	jal	ra,ffffffffc0200c50 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201068:	4515                	li	a0,5
ffffffffc020106a:	ba9ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc020106e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201070:	26050563          	beqz	a0,ffffffffc02012da <default_check+0x416>
ffffffffc0201074:	651c                	ld	a5,8(a0)
ffffffffc0201076:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0201078:	8b85                	andi	a5,a5,1
ffffffffc020107a:	54079063          	bnez	a5,ffffffffc02015ba <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020107e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201080:	00043b03          	ld	s6,0(s0)
ffffffffc0201084:	00843a83          	ld	s5,8(s0)
ffffffffc0201088:	e000                	sd	s0,0(s0)
ffffffffc020108a:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020108c:	b87ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0201090:	50051563          	bnez	a0,ffffffffc020159a <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201094:	05098a13          	addi	s4,s3,80
ffffffffc0201098:	8552                	mv	a0,s4
ffffffffc020109a:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020109c:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02010a0:	00005797          	auipc	a5,0x5
ffffffffc02010a4:	f807ac23          	sw	zero,-104(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010a8:	ba9ff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010ac:	4511                	li	a0,4
ffffffffc02010ae:	b65ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc02010b2:	4c051463          	bnez	a0,ffffffffc020157a <default_check+0x6b6>
ffffffffc02010b6:	0589b783          	ld	a5,88(s3)
ffffffffc02010ba:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010bc:	8b85                	andi	a5,a5,1
ffffffffc02010be:	48078e63          	beqz	a5,ffffffffc020155a <default_check+0x696>
ffffffffc02010c2:	0609a703          	lw	a4,96(s3)
ffffffffc02010c6:	478d                	li	a5,3
ffffffffc02010c8:	48f71963          	bne	a4,a5,ffffffffc020155a <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010cc:	450d                	li	a0,3
ffffffffc02010ce:	b45ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc02010d2:	8c2a                	mv	s8,a0
ffffffffc02010d4:	46050363          	beqz	a0,ffffffffc020153a <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc02010d8:	4505                	li	a0,1
ffffffffc02010da:	b39ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc02010de:	42051e63          	bnez	a0,ffffffffc020151a <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc02010e2:	418a1c63          	bne	s4,s8,ffffffffc02014fa <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010e6:	4585                	li	a1,1
ffffffffc02010e8:	854e                	mv	a0,s3
ffffffffc02010ea:	b67ff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    free_pages(p1, 3);
ffffffffc02010ee:	458d                	li	a1,3
ffffffffc02010f0:	8552                	mv	a0,s4
ffffffffc02010f2:	b5fff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
ffffffffc02010f6:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010fa:	02898c13          	addi	s8,s3,40
ffffffffc02010fe:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201100:	8b85                	andi	a5,a5,1
ffffffffc0201102:	3c078c63          	beqz	a5,ffffffffc02014da <default_check+0x616>
ffffffffc0201106:	0109a703          	lw	a4,16(s3)
ffffffffc020110a:	4785                	li	a5,1
ffffffffc020110c:	3cf71763          	bne	a4,a5,ffffffffc02014da <default_check+0x616>
ffffffffc0201110:	008a3783          	ld	a5,8(s4)
ffffffffc0201114:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201116:	8b85                	andi	a5,a5,1
ffffffffc0201118:	3a078163          	beqz	a5,ffffffffc02014ba <default_check+0x5f6>
ffffffffc020111c:	010a2703          	lw	a4,16(s4)
ffffffffc0201120:	478d                	li	a5,3
ffffffffc0201122:	38f71c63          	bne	a4,a5,ffffffffc02014ba <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201126:	4505                	li	a0,1
ffffffffc0201128:	aebff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc020112c:	36a99763          	bne	s3,a0,ffffffffc020149a <default_check+0x5d6>
    free_page(p0);
ffffffffc0201130:	4585                	li	a1,1
ffffffffc0201132:	b1fff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201136:	4509                	li	a0,2
ffffffffc0201138:	adbff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc020113c:	32aa1f63          	bne	s4,a0,ffffffffc020147a <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0201140:	4589                	li	a1,2
ffffffffc0201142:	b0fff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    free_page(p2);
ffffffffc0201146:	4585                	li	a1,1
ffffffffc0201148:	8562                	mv	a0,s8
ffffffffc020114a:	b07ff0ef          	jal	ra,ffffffffc0200c50 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020114e:	4515                	li	a0,5
ffffffffc0201150:	ac3ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0201154:	89aa                	mv	s3,a0
ffffffffc0201156:	48050263          	beqz	a0,ffffffffc02015da <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc020115a:	4505                	li	a0,1
ffffffffc020115c:	ab7ff0ef          	jal	ra,ffffffffc0200c12 <alloc_pages>
ffffffffc0201160:	2c051d63          	bnez	a0,ffffffffc020143a <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0201164:	481c                	lw	a5,16(s0)
ffffffffc0201166:	2a079a63          	bnez	a5,ffffffffc020141a <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020116a:	4595                	li	a1,5
ffffffffc020116c:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020116e:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201172:	01643023          	sd	s6,0(s0)
ffffffffc0201176:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020117a:	ad7ff0ef          	jal	ra,ffffffffc0200c50 <free_pages>
    return listelm->next;
ffffffffc020117e:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201180:	00878963          	beq	a5,s0,ffffffffc0201192 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201184:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201188:	679c                	ld	a5,8(a5)
ffffffffc020118a:	397d                	addiw	s2,s2,-1
ffffffffc020118c:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020118e:	fe879be3          	bne	a5,s0,ffffffffc0201184 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0201192:	26091463          	bnez	s2,ffffffffc02013fa <default_check+0x536>
    assert(total == 0);
ffffffffc0201196:	46049263          	bnez	s1,ffffffffc02015fa <default_check+0x736>
}
ffffffffc020119a:	60a6                	ld	ra,72(sp)
ffffffffc020119c:	6406                	ld	s0,64(sp)
ffffffffc020119e:	74e2                	ld	s1,56(sp)
ffffffffc02011a0:	7942                	ld	s2,48(sp)
ffffffffc02011a2:	79a2                	ld	s3,40(sp)
ffffffffc02011a4:	7a02                	ld	s4,32(sp)
ffffffffc02011a6:	6ae2                	ld	s5,24(sp)
ffffffffc02011a8:	6b42                	ld	s6,16(sp)
ffffffffc02011aa:	6ba2                	ld	s7,8(sp)
ffffffffc02011ac:	6c02                	ld	s8,0(sp)
ffffffffc02011ae:	6161                	addi	sp,sp,80
ffffffffc02011b0:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02011b2:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011b4:	4481                	li	s1,0
ffffffffc02011b6:	4901                	li	s2,0
ffffffffc02011b8:	b3b9                	j	ffffffffc0200f06 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02011ba:	00001697          	auipc	a3,0x1
ffffffffc02011be:	77668693          	addi	a3,a3,1910 # ffffffffc0202930 <commands+0x788>
ffffffffc02011c2:	00001617          	auipc	a2,0x1
ffffffffc02011c6:	77e60613          	addi	a2,a2,1918 # ffffffffc0202940 <commands+0x798>
ffffffffc02011ca:	0f000593          	li	a1,240
ffffffffc02011ce:	00001517          	auipc	a0,0x1
ffffffffc02011d2:	78a50513          	addi	a0,a0,1930 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02011d6:	f8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011da:	00002697          	auipc	a3,0x2
ffffffffc02011de:	81668693          	addi	a3,a3,-2026 # ffffffffc02029f0 <commands+0x848>
ffffffffc02011e2:	00001617          	auipc	a2,0x1
ffffffffc02011e6:	75e60613          	addi	a2,a2,1886 # ffffffffc0202940 <commands+0x798>
ffffffffc02011ea:	0bd00593          	li	a1,189
ffffffffc02011ee:	00001517          	auipc	a0,0x1
ffffffffc02011f2:	76a50513          	addi	a0,a0,1898 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02011f6:	f6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011fa:	00002697          	auipc	a3,0x2
ffffffffc02011fe:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202a18 <commands+0x870>
ffffffffc0201202:	00001617          	auipc	a2,0x1
ffffffffc0201206:	73e60613          	addi	a2,a2,1854 # ffffffffc0202940 <commands+0x798>
ffffffffc020120a:	0be00593          	li	a1,190
ffffffffc020120e:	00001517          	auipc	a0,0x1
ffffffffc0201212:	74a50513          	addi	a0,a0,1866 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201216:	f4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020121a:	00002697          	auipc	a3,0x2
ffffffffc020121e:	83e68693          	addi	a3,a3,-1986 # ffffffffc0202a58 <commands+0x8b0>
ffffffffc0201222:	00001617          	auipc	a2,0x1
ffffffffc0201226:	71e60613          	addi	a2,a2,1822 # ffffffffc0202940 <commands+0x798>
ffffffffc020122a:	0c000593          	li	a1,192
ffffffffc020122e:	00001517          	auipc	a0,0x1
ffffffffc0201232:	72a50513          	addi	a0,a0,1834 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201236:	f2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020123a:	00002697          	auipc	a3,0x2
ffffffffc020123e:	8a668693          	addi	a3,a3,-1882 # ffffffffc0202ae0 <commands+0x938>
ffffffffc0201242:	00001617          	auipc	a2,0x1
ffffffffc0201246:	6fe60613          	addi	a2,a2,1790 # ffffffffc0202940 <commands+0x798>
ffffffffc020124a:	0d900593          	li	a1,217
ffffffffc020124e:	00001517          	auipc	a0,0x1
ffffffffc0201252:	70a50513          	addi	a0,a0,1802 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201256:	f0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020125a:	00001697          	auipc	a3,0x1
ffffffffc020125e:	73668693          	addi	a3,a3,1846 # ffffffffc0202990 <commands+0x7e8>
ffffffffc0201262:	00001617          	auipc	a2,0x1
ffffffffc0201266:	6de60613          	addi	a2,a2,1758 # ffffffffc0202940 <commands+0x798>
ffffffffc020126a:	0d200593          	li	a1,210
ffffffffc020126e:	00001517          	auipc	a0,0x1
ffffffffc0201272:	6ea50513          	addi	a0,a0,1770 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201276:	eebfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 3);
ffffffffc020127a:	00002697          	auipc	a3,0x2
ffffffffc020127e:	85668693          	addi	a3,a3,-1962 # ffffffffc0202ad0 <commands+0x928>
ffffffffc0201282:	00001617          	auipc	a2,0x1
ffffffffc0201286:	6be60613          	addi	a2,a2,1726 # ffffffffc0202940 <commands+0x798>
ffffffffc020128a:	0d000593          	li	a1,208
ffffffffc020128e:	00001517          	auipc	a0,0x1
ffffffffc0201292:	6ca50513          	addi	a0,a0,1738 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201296:	ecbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020129a:	00002697          	auipc	a3,0x2
ffffffffc020129e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202ab8 <commands+0x910>
ffffffffc02012a2:	00001617          	auipc	a2,0x1
ffffffffc02012a6:	69e60613          	addi	a2,a2,1694 # ffffffffc0202940 <commands+0x798>
ffffffffc02012aa:	0cb00593          	li	a1,203
ffffffffc02012ae:	00001517          	auipc	a0,0x1
ffffffffc02012b2:	6aa50513          	addi	a0,a0,1706 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02012b6:	eabfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012ba:	00001697          	auipc	a3,0x1
ffffffffc02012be:	7de68693          	addi	a3,a3,2014 # ffffffffc0202a98 <commands+0x8f0>
ffffffffc02012c2:	00001617          	auipc	a2,0x1
ffffffffc02012c6:	67e60613          	addi	a2,a2,1662 # ffffffffc0202940 <commands+0x798>
ffffffffc02012ca:	0c200593          	li	a1,194
ffffffffc02012ce:	00001517          	auipc	a0,0x1
ffffffffc02012d2:	68a50513          	addi	a0,a0,1674 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02012d6:	e8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != NULL);
ffffffffc02012da:	00002697          	auipc	a3,0x2
ffffffffc02012de:	84e68693          	addi	a3,a3,-1970 # ffffffffc0202b28 <commands+0x980>
ffffffffc02012e2:	00001617          	auipc	a2,0x1
ffffffffc02012e6:	65e60613          	addi	a2,a2,1630 # ffffffffc0202940 <commands+0x798>
ffffffffc02012ea:	0f800593          	li	a1,248
ffffffffc02012ee:	00001517          	auipc	a0,0x1
ffffffffc02012f2:	66a50513          	addi	a0,a0,1642 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02012f6:	e6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc02012fa:	00002697          	auipc	a3,0x2
ffffffffc02012fe:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202b18 <commands+0x970>
ffffffffc0201302:	00001617          	auipc	a2,0x1
ffffffffc0201306:	63e60613          	addi	a2,a2,1598 # ffffffffc0202940 <commands+0x798>
ffffffffc020130a:	0df00593          	li	a1,223
ffffffffc020130e:	00001517          	auipc	a0,0x1
ffffffffc0201312:	64a50513          	addi	a0,a0,1610 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201316:	e4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020131a:	00001697          	auipc	a3,0x1
ffffffffc020131e:	79e68693          	addi	a3,a3,1950 # ffffffffc0202ab8 <commands+0x910>
ffffffffc0201322:	00001617          	auipc	a2,0x1
ffffffffc0201326:	61e60613          	addi	a2,a2,1566 # ffffffffc0202940 <commands+0x798>
ffffffffc020132a:	0dd00593          	li	a1,221
ffffffffc020132e:	00001517          	auipc	a0,0x1
ffffffffc0201332:	62a50513          	addi	a0,a0,1578 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201336:	e2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020133a:	00001697          	auipc	a3,0x1
ffffffffc020133e:	7be68693          	addi	a3,a3,1982 # ffffffffc0202af8 <commands+0x950>
ffffffffc0201342:	00001617          	auipc	a2,0x1
ffffffffc0201346:	5fe60613          	addi	a2,a2,1534 # ffffffffc0202940 <commands+0x798>
ffffffffc020134a:	0dc00593          	li	a1,220
ffffffffc020134e:	00001517          	auipc	a0,0x1
ffffffffc0201352:	60a50513          	addi	a0,a0,1546 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201356:	e0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020135a:	00001697          	auipc	a3,0x1
ffffffffc020135e:	63668693          	addi	a3,a3,1590 # ffffffffc0202990 <commands+0x7e8>
ffffffffc0201362:	00001617          	auipc	a2,0x1
ffffffffc0201366:	5de60613          	addi	a2,a2,1502 # ffffffffc0202940 <commands+0x798>
ffffffffc020136a:	0b900593          	li	a1,185
ffffffffc020136e:	00001517          	auipc	a0,0x1
ffffffffc0201372:	5ea50513          	addi	a0,a0,1514 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201376:	debfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020137a:	00001697          	auipc	a3,0x1
ffffffffc020137e:	73e68693          	addi	a3,a3,1854 # ffffffffc0202ab8 <commands+0x910>
ffffffffc0201382:	00001617          	auipc	a2,0x1
ffffffffc0201386:	5be60613          	addi	a2,a2,1470 # ffffffffc0202940 <commands+0x798>
ffffffffc020138a:	0d600593          	li	a1,214
ffffffffc020138e:	00001517          	auipc	a0,0x1
ffffffffc0201392:	5ca50513          	addi	a0,a0,1482 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201396:	dcbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020139a:	00001697          	auipc	a3,0x1
ffffffffc020139e:	63668693          	addi	a3,a3,1590 # ffffffffc02029d0 <commands+0x828>
ffffffffc02013a2:	00001617          	auipc	a2,0x1
ffffffffc02013a6:	59e60613          	addi	a2,a2,1438 # ffffffffc0202940 <commands+0x798>
ffffffffc02013aa:	0d400593          	li	a1,212
ffffffffc02013ae:	00001517          	auipc	a0,0x1
ffffffffc02013b2:	5aa50513          	addi	a0,a0,1450 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02013b6:	dabfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013ba:	00001697          	auipc	a3,0x1
ffffffffc02013be:	5f668693          	addi	a3,a3,1526 # ffffffffc02029b0 <commands+0x808>
ffffffffc02013c2:	00001617          	auipc	a2,0x1
ffffffffc02013c6:	57e60613          	addi	a2,a2,1406 # ffffffffc0202940 <commands+0x798>
ffffffffc02013ca:	0d300593          	li	a1,211
ffffffffc02013ce:	00001517          	auipc	a0,0x1
ffffffffc02013d2:	58a50513          	addi	a0,a0,1418 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02013d6:	d8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013da:	00001697          	auipc	a3,0x1
ffffffffc02013de:	5f668693          	addi	a3,a3,1526 # ffffffffc02029d0 <commands+0x828>
ffffffffc02013e2:	00001617          	auipc	a2,0x1
ffffffffc02013e6:	55e60613          	addi	a2,a2,1374 # ffffffffc0202940 <commands+0x798>
ffffffffc02013ea:	0bb00593          	li	a1,187
ffffffffc02013ee:	00001517          	auipc	a0,0x1
ffffffffc02013f2:	56a50513          	addi	a0,a0,1386 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02013f6:	d6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(count == 0);
ffffffffc02013fa:	00002697          	auipc	a3,0x2
ffffffffc02013fe:	87e68693          	addi	a3,a3,-1922 # ffffffffc0202c78 <commands+0xad0>
ffffffffc0201402:	00001617          	auipc	a2,0x1
ffffffffc0201406:	53e60613          	addi	a2,a2,1342 # ffffffffc0202940 <commands+0x798>
ffffffffc020140a:	12500593          	li	a1,293
ffffffffc020140e:	00001517          	auipc	a0,0x1
ffffffffc0201412:	54a50513          	addi	a0,a0,1354 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201416:	d4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc020141a:	00001697          	auipc	a3,0x1
ffffffffc020141e:	6fe68693          	addi	a3,a3,1790 # ffffffffc0202b18 <commands+0x970>
ffffffffc0201422:	00001617          	auipc	a2,0x1
ffffffffc0201426:	51e60613          	addi	a2,a2,1310 # ffffffffc0202940 <commands+0x798>
ffffffffc020142a:	11a00593          	li	a1,282
ffffffffc020142e:	00001517          	auipc	a0,0x1
ffffffffc0201432:	52a50513          	addi	a0,a0,1322 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201436:	d2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020143a:	00001697          	auipc	a3,0x1
ffffffffc020143e:	67e68693          	addi	a3,a3,1662 # ffffffffc0202ab8 <commands+0x910>
ffffffffc0201442:	00001617          	auipc	a2,0x1
ffffffffc0201446:	4fe60613          	addi	a2,a2,1278 # ffffffffc0202940 <commands+0x798>
ffffffffc020144a:	11800593          	li	a1,280
ffffffffc020144e:	00001517          	auipc	a0,0x1
ffffffffc0201452:	50a50513          	addi	a0,a0,1290 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201456:	d0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020145a:	00001697          	auipc	a3,0x1
ffffffffc020145e:	61e68693          	addi	a3,a3,1566 # ffffffffc0202a78 <commands+0x8d0>
ffffffffc0201462:	00001617          	auipc	a2,0x1
ffffffffc0201466:	4de60613          	addi	a2,a2,1246 # ffffffffc0202940 <commands+0x798>
ffffffffc020146a:	0c100593          	li	a1,193
ffffffffc020146e:	00001517          	auipc	a0,0x1
ffffffffc0201472:	4ea50513          	addi	a0,a0,1258 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201476:	cebfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020147a:	00001697          	auipc	a3,0x1
ffffffffc020147e:	7be68693          	addi	a3,a3,1982 # ffffffffc0202c38 <commands+0xa90>
ffffffffc0201482:	00001617          	auipc	a2,0x1
ffffffffc0201486:	4be60613          	addi	a2,a2,1214 # ffffffffc0202940 <commands+0x798>
ffffffffc020148a:	11200593          	li	a1,274
ffffffffc020148e:	00001517          	auipc	a0,0x1
ffffffffc0201492:	4ca50513          	addi	a0,a0,1226 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201496:	ccbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020149a:	00001697          	auipc	a3,0x1
ffffffffc020149e:	77e68693          	addi	a3,a3,1918 # ffffffffc0202c18 <commands+0xa70>
ffffffffc02014a2:	00001617          	auipc	a2,0x1
ffffffffc02014a6:	49e60613          	addi	a2,a2,1182 # ffffffffc0202940 <commands+0x798>
ffffffffc02014aa:	11000593          	li	a1,272
ffffffffc02014ae:	00001517          	auipc	a0,0x1
ffffffffc02014b2:	4aa50513          	addi	a0,a0,1194 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02014b6:	cabfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014ba:	00001697          	auipc	a3,0x1
ffffffffc02014be:	73668693          	addi	a3,a3,1846 # ffffffffc0202bf0 <commands+0xa48>
ffffffffc02014c2:	00001617          	auipc	a2,0x1
ffffffffc02014c6:	47e60613          	addi	a2,a2,1150 # ffffffffc0202940 <commands+0x798>
ffffffffc02014ca:	10e00593          	li	a1,270
ffffffffc02014ce:	00001517          	auipc	a0,0x1
ffffffffc02014d2:	48a50513          	addi	a0,a0,1162 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02014d6:	c8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014da:	00001697          	auipc	a3,0x1
ffffffffc02014de:	6ee68693          	addi	a3,a3,1774 # ffffffffc0202bc8 <commands+0xa20>
ffffffffc02014e2:	00001617          	auipc	a2,0x1
ffffffffc02014e6:	45e60613          	addi	a2,a2,1118 # ffffffffc0202940 <commands+0x798>
ffffffffc02014ea:	10d00593          	li	a1,269
ffffffffc02014ee:	00001517          	auipc	a0,0x1
ffffffffc02014f2:	46a50513          	addi	a0,a0,1130 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02014f6:	c6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014fa:	00001697          	auipc	a3,0x1
ffffffffc02014fe:	6be68693          	addi	a3,a3,1726 # ffffffffc0202bb8 <commands+0xa10>
ffffffffc0201502:	00001617          	auipc	a2,0x1
ffffffffc0201506:	43e60613          	addi	a2,a2,1086 # ffffffffc0202940 <commands+0x798>
ffffffffc020150a:	10800593          	li	a1,264
ffffffffc020150e:	00001517          	auipc	a0,0x1
ffffffffc0201512:	44a50513          	addi	a0,a0,1098 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201516:	c4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020151a:	00001697          	auipc	a3,0x1
ffffffffc020151e:	59e68693          	addi	a3,a3,1438 # ffffffffc0202ab8 <commands+0x910>
ffffffffc0201522:	00001617          	auipc	a2,0x1
ffffffffc0201526:	41e60613          	addi	a2,a2,1054 # ffffffffc0202940 <commands+0x798>
ffffffffc020152a:	10700593          	li	a1,263
ffffffffc020152e:	00001517          	auipc	a0,0x1
ffffffffc0201532:	42a50513          	addi	a0,a0,1066 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201536:	c2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020153a:	00001697          	auipc	a3,0x1
ffffffffc020153e:	65e68693          	addi	a3,a3,1630 # ffffffffc0202b98 <commands+0x9f0>
ffffffffc0201542:	00001617          	auipc	a2,0x1
ffffffffc0201546:	3fe60613          	addi	a2,a2,1022 # ffffffffc0202940 <commands+0x798>
ffffffffc020154a:	10600593          	li	a1,262
ffffffffc020154e:	00001517          	auipc	a0,0x1
ffffffffc0201552:	40a50513          	addi	a0,a0,1034 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201556:	c0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020155a:	00001697          	auipc	a3,0x1
ffffffffc020155e:	60e68693          	addi	a3,a3,1550 # ffffffffc0202b68 <commands+0x9c0>
ffffffffc0201562:	00001617          	auipc	a2,0x1
ffffffffc0201566:	3de60613          	addi	a2,a2,990 # ffffffffc0202940 <commands+0x798>
ffffffffc020156a:	10500593          	li	a1,261
ffffffffc020156e:	00001517          	auipc	a0,0x1
ffffffffc0201572:	3ea50513          	addi	a0,a0,1002 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201576:	bebfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020157a:	00001697          	auipc	a3,0x1
ffffffffc020157e:	5d668693          	addi	a3,a3,1494 # ffffffffc0202b50 <commands+0x9a8>
ffffffffc0201582:	00001617          	auipc	a2,0x1
ffffffffc0201586:	3be60613          	addi	a2,a2,958 # ffffffffc0202940 <commands+0x798>
ffffffffc020158a:	10400593          	li	a1,260
ffffffffc020158e:	00001517          	auipc	a0,0x1
ffffffffc0201592:	3ca50513          	addi	a0,a0,970 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201596:	bcbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020159a:	00001697          	auipc	a3,0x1
ffffffffc020159e:	51e68693          	addi	a3,a3,1310 # ffffffffc0202ab8 <commands+0x910>
ffffffffc02015a2:	00001617          	auipc	a2,0x1
ffffffffc02015a6:	39e60613          	addi	a2,a2,926 # ffffffffc0202940 <commands+0x798>
ffffffffc02015aa:	0fe00593          	li	a1,254
ffffffffc02015ae:	00001517          	auipc	a0,0x1
ffffffffc02015b2:	3aa50513          	addi	a0,a0,938 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02015b6:	babfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015ba:	00001697          	auipc	a3,0x1
ffffffffc02015be:	57e68693          	addi	a3,a3,1406 # ffffffffc0202b38 <commands+0x990>
ffffffffc02015c2:	00001617          	auipc	a2,0x1
ffffffffc02015c6:	37e60613          	addi	a2,a2,894 # ffffffffc0202940 <commands+0x798>
ffffffffc02015ca:	0f900593          	li	a1,249
ffffffffc02015ce:	00001517          	auipc	a0,0x1
ffffffffc02015d2:	38a50513          	addi	a0,a0,906 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02015d6:	b8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015da:	00001697          	auipc	a3,0x1
ffffffffc02015de:	67e68693          	addi	a3,a3,1662 # ffffffffc0202c58 <commands+0xab0>
ffffffffc02015e2:	00001617          	auipc	a2,0x1
ffffffffc02015e6:	35e60613          	addi	a2,a2,862 # ffffffffc0202940 <commands+0x798>
ffffffffc02015ea:	11700593          	li	a1,279
ffffffffc02015ee:	00001517          	auipc	a0,0x1
ffffffffc02015f2:	36a50513          	addi	a0,a0,874 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02015f6:	b6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == 0);
ffffffffc02015fa:	00001697          	auipc	a3,0x1
ffffffffc02015fe:	68e68693          	addi	a3,a3,1678 # ffffffffc0202c88 <commands+0xae0>
ffffffffc0201602:	00001617          	auipc	a2,0x1
ffffffffc0201606:	33e60613          	addi	a2,a2,830 # ffffffffc0202940 <commands+0x798>
ffffffffc020160a:	12600593          	li	a1,294
ffffffffc020160e:	00001517          	auipc	a0,0x1
ffffffffc0201612:	34a50513          	addi	a0,a0,842 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201616:	b4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == nr_free_pages());
ffffffffc020161a:	00001697          	auipc	a3,0x1
ffffffffc020161e:	35668693          	addi	a3,a3,854 # ffffffffc0202970 <commands+0x7c8>
ffffffffc0201622:	00001617          	auipc	a2,0x1
ffffffffc0201626:	31e60613          	addi	a2,a2,798 # ffffffffc0202940 <commands+0x798>
ffffffffc020162a:	0f300593          	li	a1,243
ffffffffc020162e:	00001517          	auipc	a0,0x1
ffffffffc0201632:	32a50513          	addi	a0,a0,810 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201636:	b2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020163a:	00001697          	auipc	a3,0x1
ffffffffc020163e:	37668693          	addi	a3,a3,886 # ffffffffc02029b0 <commands+0x808>
ffffffffc0201642:	00001617          	auipc	a2,0x1
ffffffffc0201646:	2fe60613          	addi	a2,a2,766 # ffffffffc0202940 <commands+0x798>
ffffffffc020164a:	0ba00593          	li	a1,186
ffffffffc020164e:	00001517          	auipc	a0,0x1
ffffffffc0201652:	30a50513          	addi	a0,a0,778 # ffffffffc0202958 <commands+0x7b0>
ffffffffc0201656:	b0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc020165a <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020165a:	1141                	addi	sp,sp,-16
ffffffffc020165c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020165e:	14058a63          	beqz	a1,ffffffffc02017b2 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201662:	00259693          	slli	a3,a1,0x2
ffffffffc0201666:	96ae                	add	a3,a3,a1
ffffffffc0201668:	068e                	slli	a3,a3,0x3
ffffffffc020166a:	96aa                	add	a3,a3,a0
ffffffffc020166c:	87aa                	mv	a5,a0
ffffffffc020166e:	02d50263          	beq	a0,a3,ffffffffc0201692 <default_free_pages+0x38>
ffffffffc0201672:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201674:	8b05                	andi	a4,a4,1
ffffffffc0201676:	10071e63          	bnez	a4,ffffffffc0201792 <default_free_pages+0x138>
ffffffffc020167a:	6798                	ld	a4,8(a5)
ffffffffc020167c:	8b09                	andi	a4,a4,2
ffffffffc020167e:	10071a63          	bnez	a4,ffffffffc0201792 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0201682:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201686:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020168a:	02878793          	addi	a5,a5,40
ffffffffc020168e:	fed792e3          	bne	a5,a3,ffffffffc0201672 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201692:	2581                	sext.w	a1,a1
ffffffffc0201694:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201696:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020169a:	4789                	li	a5,2
ffffffffc020169c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02016a0:	00005697          	auipc	a3,0x5
ffffffffc02016a4:	98868693          	addi	a3,a3,-1656 # ffffffffc0206028 <free_area>
ffffffffc02016a8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016aa:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016ac:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016b0:	9db9                	addw	a1,a1,a4
ffffffffc02016b2:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02016b4:	0ad78863          	beq	a5,a3,ffffffffc0201764 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02016b8:	fe878713          	addi	a4,a5,-24
ffffffffc02016bc:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02016c0:	4581                	li	a1,0
            if (base < page) {
ffffffffc02016c2:	00e56a63          	bltu	a0,a4,ffffffffc02016d6 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc02016c6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016c8:	06d70263          	beq	a4,a3,ffffffffc020172c <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02016cc:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016ce:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016d2:	fee57ae3          	bgeu	a0,a4,ffffffffc02016c6 <default_free_pages+0x6c>
ffffffffc02016d6:	c199                	beqz	a1,ffffffffc02016dc <default_free_pages+0x82>
ffffffffc02016d8:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016dc:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016de:	e390                	sd	a2,0(a5)
ffffffffc02016e0:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016e2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016e4:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02016e6:	02d70063          	beq	a4,a3,ffffffffc0201706 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02016ea:	ff872803          	lw	a6,-8(a4) # fffffffffff7fff8 <end+0x3fd79b58>
        p = le2page(le, page_link);
ffffffffc02016ee:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02016f2:	02081613          	slli	a2,a6,0x20
ffffffffc02016f6:	9201                	srli	a2,a2,0x20
ffffffffc02016f8:	00261793          	slli	a5,a2,0x2
ffffffffc02016fc:	97b2                	add	a5,a5,a2
ffffffffc02016fe:	078e                	slli	a5,a5,0x3
ffffffffc0201700:	97ae                	add	a5,a5,a1
ffffffffc0201702:	02f50f63          	beq	a0,a5,ffffffffc0201740 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc0201706:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201708:	00d70f63          	beq	a4,a3,ffffffffc0201726 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc020170c:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc020170e:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201712:	02059613          	slli	a2,a1,0x20
ffffffffc0201716:	9201                	srli	a2,a2,0x20
ffffffffc0201718:	00261793          	slli	a5,a2,0x2
ffffffffc020171c:	97b2                	add	a5,a5,a2
ffffffffc020171e:	078e                	slli	a5,a5,0x3
ffffffffc0201720:	97aa                	add	a5,a5,a0
ffffffffc0201722:	04f68863          	beq	a3,a5,ffffffffc0201772 <default_free_pages+0x118>
}
ffffffffc0201726:	60a2                	ld	ra,8(sp)
ffffffffc0201728:	0141                	addi	sp,sp,16
ffffffffc020172a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020172c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020172e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201730:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201732:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201734:	02d70563          	beq	a4,a3,ffffffffc020175e <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201738:	8832                	mv	a6,a2
ffffffffc020173a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020173c:	87ba                	mv	a5,a4
ffffffffc020173e:	bf41                	j	ffffffffc02016ce <default_free_pages+0x74>
            p->property += base->property;
ffffffffc0201740:	491c                	lw	a5,16(a0)
ffffffffc0201742:	0107883b          	addw	a6,a5,a6
ffffffffc0201746:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020174a:	57f5                	li	a5,-3
ffffffffc020174c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201750:	6d10                	ld	a2,24(a0)
ffffffffc0201752:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201754:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201756:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201758:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc020175a:	e390                	sd	a2,0(a5)
ffffffffc020175c:	b775                	j	ffffffffc0201708 <default_free_pages+0xae>
ffffffffc020175e:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201760:	873e                	mv	a4,a5
ffffffffc0201762:	b761                	j	ffffffffc02016ea <default_free_pages+0x90>
}
ffffffffc0201764:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201766:	e390                	sd	a2,0(a5)
ffffffffc0201768:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020176a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020176c:	ed1c                	sd	a5,24(a0)
ffffffffc020176e:	0141                	addi	sp,sp,16
ffffffffc0201770:	8082                	ret
            base->property += p->property;
ffffffffc0201772:	ff872783          	lw	a5,-8(a4)
ffffffffc0201776:	ff070693          	addi	a3,a4,-16
ffffffffc020177a:	9dbd                	addw	a1,a1,a5
ffffffffc020177c:	c90c                	sw	a1,16(a0)
ffffffffc020177e:	57f5                	li	a5,-3
ffffffffc0201780:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201784:	6314                	ld	a3,0(a4)
ffffffffc0201786:	671c                	ld	a5,8(a4)
}
ffffffffc0201788:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020178a:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020178c:	e394                	sd	a3,0(a5)
ffffffffc020178e:	0141                	addi	sp,sp,16
ffffffffc0201790:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201792:	00001697          	auipc	a3,0x1
ffffffffc0201796:	50e68693          	addi	a3,a3,1294 # ffffffffc0202ca0 <commands+0xaf8>
ffffffffc020179a:	00001617          	auipc	a2,0x1
ffffffffc020179e:	1a660613          	addi	a2,a2,422 # ffffffffc0202940 <commands+0x798>
ffffffffc02017a2:	08300593          	li	a1,131
ffffffffc02017a6:	00001517          	auipc	a0,0x1
ffffffffc02017aa:	1b250513          	addi	a0,a0,434 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02017ae:	9b3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc02017b2:	00001697          	auipc	a3,0x1
ffffffffc02017b6:	4e668693          	addi	a3,a3,1254 # ffffffffc0202c98 <commands+0xaf0>
ffffffffc02017ba:	00001617          	auipc	a2,0x1
ffffffffc02017be:	18660613          	addi	a2,a2,390 # ffffffffc0202940 <commands+0x798>
ffffffffc02017c2:	08000593          	li	a1,128
ffffffffc02017c6:	00001517          	auipc	a0,0x1
ffffffffc02017ca:	19250513          	addi	a0,a0,402 # ffffffffc0202958 <commands+0x7b0>
ffffffffc02017ce:	993fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc02017d2 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017d2:	c959                	beqz	a0,ffffffffc0201868 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02017d4:	00005597          	auipc	a1,0x5
ffffffffc02017d8:	85458593          	addi	a1,a1,-1964 # ffffffffc0206028 <free_area>
ffffffffc02017dc:	0105a803          	lw	a6,16(a1)
ffffffffc02017e0:	862a                	mv	a2,a0
ffffffffc02017e2:	02081793          	slli	a5,a6,0x20
ffffffffc02017e6:	9381                	srli	a5,a5,0x20
ffffffffc02017e8:	00a7ee63          	bltu	a5,a0,ffffffffc0201804 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017ec:	87ae                	mv	a5,a1
ffffffffc02017ee:	a801                	j	ffffffffc02017fe <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02017f0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02017f4:	02071693          	slli	a3,a4,0x20
ffffffffc02017f8:	9281                	srli	a3,a3,0x20
ffffffffc02017fa:	00c6f763          	bgeu	a3,a2,ffffffffc0201808 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02017fe:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201800:	feb798e3          	bne	a5,a1,ffffffffc02017f0 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201804:	4501                	li	a0,0
}
ffffffffc0201806:	8082                	ret
    return listelm->prev;
ffffffffc0201808:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020180c:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201810:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201814:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc0201818:	0068b423          	sd	t1,8(a7) # fffffffffff80008 <end+0x3fd79b68>
    next->prev = prev;
ffffffffc020181c:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201820:	02d67b63          	bgeu	a2,a3,ffffffffc0201856 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0201824:	00261693          	slli	a3,a2,0x2
ffffffffc0201828:	96b2                	add	a3,a3,a2
ffffffffc020182a:	068e                	slli	a3,a3,0x3
ffffffffc020182c:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc020182e:	41c7073b          	subw	a4,a4,t3
ffffffffc0201832:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201834:	00868613          	addi	a2,a3,8
ffffffffc0201838:	4709                	li	a4,2
ffffffffc020183a:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020183e:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201842:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc0201846:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020184a:	e310                	sd	a2,0(a4)
ffffffffc020184c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201850:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0201852:	0116bc23          	sd	a7,24(a3)
ffffffffc0201856:	41c8083b          	subw	a6,a6,t3
ffffffffc020185a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020185e:	5775                	li	a4,-3
ffffffffc0201860:	17c1                	addi	a5,a5,-16
ffffffffc0201862:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201866:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201868:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020186a:	00001697          	auipc	a3,0x1
ffffffffc020186e:	42e68693          	addi	a3,a3,1070 # ffffffffc0202c98 <commands+0xaf0>
ffffffffc0201872:	00001617          	auipc	a2,0x1
ffffffffc0201876:	0ce60613          	addi	a2,a2,206 # ffffffffc0202940 <commands+0x798>
ffffffffc020187a:	06200593          	li	a1,98
ffffffffc020187e:	00001517          	auipc	a0,0x1
ffffffffc0201882:	0da50513          	addi	a0,a0,218 # ffffffffc0202958 <commands+0x7b0>
default_alloc_pages(size_t n) {
ffffffffc0201886:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201888:	8d9fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc020188c <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020188c:	1141                	addi	sp,sp,-16
ffffffffc020188e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201890:	c9e1                	beqz	a1,ffffffffc0201960 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201892:	00259693          	slli	a3,a1,0x2
ffffffffc0201896:	96ae                	add	a3,a3,a1
ffffffffc0201898:	068e                	slli	a3,a3,0x3
ffffffffc020189a:	96aa                	add	a3,a3,a0
ffffffffc020189c:	87aa                	mv	a5,a0
ffffffffc020189e:	00d50f63          	beq	a0,a3,ffffffffc02018bc <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018a2:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02018a4:	8b05                	andi	a4,a4,1
ffffffffc02018a6:	cf49                	beqz	a4,ffffffffc0201940 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02018a8:	0007a823          	sw	zero,16(a5)
ffffffffc02018ac:	0007b423          	sd	zero,8(a5)
ffffffffc02018b0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02018b4:	02878793          	addi	a5,a5,40
ffffffffc02018b8:	fed795e3          	bne	a5,a3,ffffffffc02018a2 <default_init_memmap+0x16>
    base->property = n;
ffffffffc02018bc:	2581                	sext.w	a1,a1
ffffffffc02018be:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018c0:	4789                	li	a5,2
ffffffffc02018c2:	00850713          	addi	a4,a0,8
ffffffffc02018c6:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018ca:	00004697          	auipc	a3,0x4
ffffffffc02018ce:	75e68693          	addi	a3,a3,1886 # ffffffffc0206028 <free_area>
ffffffffc02018d2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018d4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018d6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018da:	9db9                	addw	a1,a1,a4
ffffffffc02018dc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02018de:	04d78a63          	beq	a5,a3,ffffffffc0201932 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02018e2:	fe878713          	addi	a4,a5,-24
ffffffffc02018e6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02018ea:	4581                	li	a1,0
            if (base < page) {
ffffffffc02018ec:	00e56a63          	bltu	a0,a4,ffffffffc0201900 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02018f0:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02018f2:	02d70263          	beq	a4,a3,ffffffffc0201916 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02018f6:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02018f8:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02018fc:	fee57ae3          	bgeu	a0,a4,ffffffffc02018f0 <default_init_memmap+0x64>
ffffffffc0201900:	c199                	beqz	a1,ffffffffc0201906 <default_init_memmap+0x7a>
ffffffffc0201902:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201906:	6398                	ld	a4,0(a5)
}
ffffffffc0201908:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020190a:	e390                	sd	a2,0(a5)
ffffffffc020190c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020190e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201910:	ed18                	sd	a4,24(a0)
ffffffffc0201912:	0141                	addi	sp,sp,16
ffffffffc0201914:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201916:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201918:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020191a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020191c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020191e:	00d70663          	beq	a4,a3,ffffffffc020192a <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201922:	8832                	mv	a6,a2
ffffffffc0201924:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201926:	87ba                	mv	a5,a4
ffffffffc0201928:	bfc1                	j	ffffffffc02018f8 <default_init_memmap+0x6c>
}
ffffffffc020192a:	60a2                	ld	ra,8(sp)
ffffffffc020192c:	e290                	sd	a2,0(a3)
ffffffffc020192e:	0141                	addi	sp,sp,16
ffffffffc0201930:	8082                	ret
ffffffffc0201932:	60a2                	ld	ra,8(sp)
ffffffffc0201934:	e390                	sd	a2,0(a5)
ffffffffc0201936:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201938:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020193a:	ed1c                	sd	a5,24(a0)
ffffffffc020193c:	0141                	addi	sp,sp,16
ffffffffc020193e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201940:	00001697          	auipc	a3,0x1
ffffffffc0201944:	38868693          	addi	a3,a3,904 # ffffffffc0202cc8 <commands+0xb20>
ffffffffc0201948:	00001617          	auipc	a2,0x1
ffffffffc020194c:	ff860613          	addi	a2,a2,-8 # ffffffffc0202940 <commands+0x798>
ffffffffc0201950:	04900593          	li	a1,73
ffffffffc0201954:	00001517          	auipc	a0,0x1
ffffffffc0201958:	00450513          	addi	a0,a0,4 # ffffffffc0202958 <commands+0x7b0>
ffffffffc020195c:	805fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc0201960:	00001697          	auipc	a3,0x1
ffffffffc0201964:	33868693          	addi	a3,a3,824 # ffffffffc0202c98 <commands+0xaf0>
ffffffffc0201968:	00001617          	auipc	a2,0x1
ffffffffc020196c:	fd860613          	addi	a2,a2,-40 # ffffffffc0202940 <commands+0x798>
ffffffffc0201970:	04600593          	li	a1,70
ffffffffc0201974:	00001517          	auipc	a0,0x1
ffffffffc0201978:	fe450513          	addi	a0,a0,-28 # ffffffffc0202958 <commands+0x7b0>
ffffffffc020197c:	fe4fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201980 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201980:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201984:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201986:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201988:	cb81                	beqz	a5,ffffffffc0201998 <strlen+0x18>
        cnt ++;
ffffffffc020198a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020198c:	00a707b3          	add	a5,a4,a0
ffffffffc0201990:	0007c783          	lbu	a5,0(a5)
ffffffffc0201994:	fbfd                	bnez	a5,ffffffffc020198a <strlen+0xa>
ffffffffc0201996:	8082                	ret
    }
    return cnt;
}
ffffffffc0201998:	8082                	ret

ffffffffc020199a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020199a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020199c:	e589                	bnez	a1,ffffffffc02019a6 <strnlen+0xc>
ffffffffc020199e:	a811                	j	ffffffffc02019b2 <strnlen+0x18>
        cnt ++;
ffffffffc02019a0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019a2:	00f58863          	beq	a1,a5,ffffffffc02019b2 <strnlen+0x18>
ffffffffc02019a6:	00f50733          	add	a4,a0,a5
ffffffffc02019aa:	00074703          	lbu	a4,0(a4)
ffffffffc02019ae:	fb6d                	bnez	a4,ffffffffc02019a0 <strnlen+0x6>
ffffffffc02019b0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02019b2:	852e                	mv	a0,a1
ffffffffc02019b4:	8082                	ret

ffffffffc02019b6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019b6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019ba:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019be:	cb89                	beqz	a5,ffffffffc02019d0 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02019c0:	0505                	addi	a0,a0,1
ffffffffc02019c2:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019c4:	fee789e3          	beq	a5,a4,ffffffffc02019b6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019c8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02019cc:	9d19                	subw	a0,a0,a4
ffffffffc02019ce:	8082                	ret
ffffffffc02019d0:	4501                	li	a0,0
ffffffffc02019d2:	bfed                	j	ffffffffc02019cc <strcmp+0x16>

ffffffffc02019d4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02019d4:	c20d                	beqz	a2,ffffffffc02019f6 <strncmp+0x22>
ffffffffc02019d6:	962e                	add	a2,a2,a1
ffffffffc02019d8:	a031                	j	ffffffffc02019e4 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02019da:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02019dc:	00e79a63          	bne	a5,a4,ffffffffc02019f0 <strncmp+0x1c>
ffffffffc02019e0:	00b60b63          	beq	a2,a1,ffffffffc02019f6 <strncmp+0x22>
ffffffffc02019e4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02019e8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02019ea:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02019ee:	f7f5                	bnez	a5,ffffffffc02019da <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019f0:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02019f4:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019f6:	4501                	li	a0,0
ffffffffc02019f8:	8082                	ret

ffffffffc02019fa <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02019fa:	00054783          	lbu	a5,0(a0)
ffffffffc02019fe:	c799                	beqz	a5,ffffffffc0201a0c <strchr+0x12>
        if (*s == c) {
ffffffffc0201a00:	00f58763          	beq	a1,a5,ffffffffc0201a0e <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201a04:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201a08:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201a0a:	fbfd                	bnez	a5,ffffffffc0201a00 <strchr+0x6>
    }
    return NULL;
ffffffffc0201a0c:	4501                	li	a0,0
}
ffffffffc0201a0e:	8082                	ret

ffffffffc0201a10 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201a10:	ca01                	beqz	a2,ffffffffc0201a20 <memset+0x10>
ffffffffc0201a12:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201a14:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201a16:	0785                	addi	a5,a5,1
ffffffffc0201a18:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201a1c:	fec79de3          	bne	a5,a2,ffffffffc0201a16 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201a20:	8082                	ret

ffffffffc0201a22 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a22:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a26:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a28:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a2c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a2e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a32:	f022                	sd	s0,32(sp)
ffffffffc0201a34:	ec26                	sd	s1,24(sp)
ffffffffc0201a36:	e84a                	sd	s2,16(sp)
ffffffffc0201a38:	f406                	sd	ra,40(sp)
ffffffffc0201a3a:	e44e                	sd	s3,8(sp)
ffffffffc0201a3c:	84aa                	mv	s1,a0
ffffffffc0201a3e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a40:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a44:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a46:	03067e63          	bgeu	a2,a6,ffffffffc0201a82 <printnum+0x60>
ffffffffc0201a4a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a4c:	00805763          	blez	s0,ffffffffc0201a5a <printnum+0x38>
ffffffffc0201a50:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a52:	85ca                	mv	a1,s2
ffffffffc0201a54:	854e                	mv	a0,s3
ffffffffc0201a56:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a58:	fc65                	bnez	s0,ffffffffc0201a50 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a5a:	1a02                	slli	s4,s4,0x20
ffffffffc0201a5c:	00001797          	auipc	a5,0x1
ffffffffc0201a60:	2cc78793          	addi	a5,a5,716 # ffffffffc0202d28 <default_pmm_manager+0x38>
ffffffffc0201a64:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a68:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a6a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a6c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a70:	70a2                	ld	ra,40(sp)
ffffffffc0201a72:	69a2                	ld	s3,8(sp)
ffffffffc0201a74:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a76:	85ca                	mv	a1,s2
ffffffffc0201a78:	87a6                	mv	a5,s1
}
ffffffffc0201a7a:	6942                	ld	s2,16(sp)
ffffffffc0201a7c:	64e2                	ld	s1,24(sp)
ffffffffc0201a7e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a80:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a82:	03065633          	divu	a2,a2,a6
ffffffffc0201a86:	8722                	mv	a4,s0
ffffffffc0201a88:	f9bff0ef          	jal	ra,ffffffffc0201a22 <printnum>
ffffffffc0201a8c:	b7f9                	j	ffffffffc0201a5a <printnum+0x38>

ffffffffc0201a8e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a8e:	7119                	addi	sp,sp,-128
ffffffffc0201a90:	f4a6                	sd	s1,104(sp)
ffffffffc0201a92:	f0ca                	sd	s2,96(sp)
ffffffffc0201a94:	ecce                	sd	s3,88(sp)
ffffffffc0201a96:	e8d2                	sd	s4,80(sp)
ffffffffc0201a98:	e4d6                	sd	s5,72(sp)
ffffffffc0201a9a:	e0da                	sd	s6,64(sp)
ffffffffc0201a9c:	fc5e                	sd	s7,56(sp)
ffffffffc0201a9e:	f06a                	sd	s10,32(sp)
ffffffffc0201aa0:	fc86                	sd	ra,120(sp)
ffffffffc0201aa2:	f8a2                	sd	s0,112(sp)
ffffffffc0201aa4:	f862                	sd	s8,48(sp)
ffffffffc0201aa6:	f466                	sd	s9,40(sp)
ffffffffc0201aa8:	ec6e                	sd	s11,24(sp)
ffffffffc0201aaa:	892a                	mv	s2,a0
ffffffffc0201aac:	84ae                	mv	s1,a1
ffffffffc0201aae:	8d32                	mv	s10,a2
ffffffffc0201ab0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ab2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201ab6:	5b7d                	li	s6,-1
ffffffffc0201ab8:	00001a97          	auipc	s5,0x1
ffffffffc0201abc:	2a4a8a93          	addi	s5,s5,676 # ffffffffc0202d5c <default_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ac0:	00001b97          	auipc	s7,0x1
ffffffffc0201ac4:	478b8b93          	addi	s7,s7,1144 # ffffffffc0202f38 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ac8:	000d4503          	lbu	a0,0(s10)
ffffffffc0201acc:	001d0413          	addi	s0,s10,1
ffffffffc0201ad0:	01350a63          	beq	a0,s3,ffffffffc0201ae4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201ad4:	c121                	beqz	a0,ffffffffc0201b14 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201ad6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ad8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201ada:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201adc:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201ae0:	ff351ae3          	bne	a0,s3,ffffffffc0201ad4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201ae8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201aec:	4c81                	li	s9,0
ffffffffc0201aee:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201af0:	5c7d                	li	s8,-1
ffffffffc0201af2:	5dfd                	li	s11,-1
ffffffffc0201af4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201af8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201afa:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201afe:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b02:	00140d13          	addi	s10,s0,1
ffffffffc0201b06:	04b56263          	bltu	a0,a1,ffffffffc0201b4a <vprintfmt+0xbc>
ffffffffc0201b0a:	058a                	slli	a1,a1,0x2
ffffffffc0201b0c:	95d6                	add	a1,a1,s5
ffffffffc0201b0e:	4194                	lw	a3,0(a1)
ffffffffc0201b10:	96d6                	add	a3,a3,s5
ffffffffc0201b12:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b14:	70e6                	ld	ra,120(sp)
ffffffffc0201b16:	7446                	ld	s0,112(sp)
ffffffffc0201b18:	74a6                	ld	s1,104(sp)
ffffffffc0201b1a:	7906                	ld	s2,96(sp)
ffffffffc0201b1c:	69e6                	ld	s3,88(sp)
ffffffffc0201b1e:	6a46                	ld	s4,80(sp)
ffffffffc0201b20:	6aa6                	ld	s5,72(sp)
ffffffffc0201b22:	6b06                	ld	s6,64(sp)
ffffffffc0201b24:	7be2                	ld	s7,56(sp)
ffffffffc0201b26:	7c42                	ld	s8,48(sp)
ffffffffc0201b28:	7ca2                	ld	s9,40(sp)
ffffffffc0201b2a:	7d02                	ld	s10,32(sp)
ffffffffc0201b2c:	6de2                	ld	s11,24(sp)
ffffffffc0201b2e:	6109                	addi	sp,sp,128
ffffffffc0201b30:	8082                	ret
            padc = '0';
ffffffffc0201b32:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b34:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b38:	846a                	mv	s0,s10
ffffffffc0201b3a:	00140d13          	addi	s10,s0,1
ffffffffc0201b3e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b42:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b46:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b0a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b4a:	85a6                	mv	a1,s1
ffffffffc0201b4c:	02500513          	li	a0,37
ffffffffc0201b50:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b52:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b56:	8d22                	mv	s10,s0
ffffffffc0201b58:	f73788e3          	beq	a5,s3,ffffffffc0201ac8 <vprintfmt+0x3a>
ffffffffc0201b5c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b60:	1d7d                	addi	s10,s10,-1
ffffffffc0201b62:	ff379de3          	bne	a5,s3,ffffffffc0201b5c <vprintfmt+0xce>
ffffffffc0201b66:	b78d                	j	ffffffffc0201ac8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b68:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b6c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b70:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b72:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b76:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b7a:	02d86463          	bltu	a6,a3,ffffffffc0201ba2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b7e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b82:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b86:	0186873b          	addw	a4,a3,s8
ffffffffc0201b8a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b8e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b90:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b94:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b96:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b9a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b9e:	fed870e3          	bgeu	a6,a3,ffffffffc0201b7e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201ba2:	f40ddce3          	bgez	s11,ffffffffc0201afa <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201ba6:	8de2                	mv	s11,s8
ffffffffc0201ba8:	5c7d                	li	s8,-1
ffffffffc0201baa:	bf81                	j	ffffffffc0201afa <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201bac:	fffdc693          	not	a3,s11
ffffffffc0201bb0:	96fd                	srai	a3,a3,0x3f
ffffffffc0201bb2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bb6:	00144603          	lbu	a2,1(s0)
ffffffffc0201bba:	2d81                	sext.w	s11,s11
ffffffffc0201bbc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bbe:	bf35                	j	ffffffffc0201afa <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201bc0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201bc8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bca:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201bcc:	bfd9                	j	ffffffffc0201ba2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201bce:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bd0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bd4:	01174463          	blt	a4,a7,ffffffffc0201bdc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201bd8:	1a088e63          	beqz	a7,ffffffffc0201d94 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201bdc:	000a3603          	ld	a2,0(s4)
ffffffffc0201be0:	46c1                	li	a3,16
ffffffffc0201be2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201be4:	2781                	sext.w	a5,a5
ffffffffc0201be6:	876e                	mv	a4,s11
ffffffffc0201be8:	85a6                	mv	a1,s1
ffffffffc0201bea:	854a                	mv	a0,s2
ffffffffc0201bec:	e37ff0ef          	jal	ra,ffffffffc0201a22 <printnum>
            break;
ffffffffc0201bf0:	bde1                	j	ffffffffc0201ac8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201bf2:	000a2503          	lw	a0,0(s4)
ffffffffc0201bf6:	85a6                	mv	a1,s1
ffffffffc0201bf8:	0a21                	addi	s4,s4,8
ffffffffc0201bfa:	9902                	jalr	s2
            break;
ffffffffc0201bfc:	b5f1                	j	ffffffffc0201ac8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201bfe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c00:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c04:	01174463          	blt	a4,a7,ffffffffc0201c0c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201c08:	18088163          	beqz	a7,ffffffffc0201d8a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201c0c:	000a3603          	ld	a2,0(s4)
ffffffffc0201c10:	46a9                	li	a3,10
ffffffffc0201c12:	8a2e                	mv	s4,a1
ffffffffc0201c14:	bfc1                	j	ffffffffc0201be4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c16:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c1a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c1c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c1e:	bdf1                	j	ffffffffc0201afa <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c20:	85a6                	mv	a1,s1
ffffffffc0201c22:	02500513          	li	a0,37
ffffffffc0201c26:	9902                	jalr	s2
            break;
ffffffffc0201c28:	b545                	j	ffffffffc0201ac8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c2a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c2e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c30:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c32:	b5e1                	j	ffffffffc0201afa <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c34:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c36:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c3a:	01174463          	blt	a4,a7,ffffffffc0201c42 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c3e:	14088163          	beqz	a7,ffffffffc0201d80 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c42:	000a3603          	ld	a2,0(s4)
ffffffffc0201c46:	46a1                	li	a3,8
ffffffffc0201c48:	8a2e                	mv	s4,a1
ffffffffc0201c4a:	bf69                	j	ffffffffc0201be4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c4c:	03000513          	li	a0,48
ffffffffc0201c50:	85a6                	mv	a1,s1
ffffffffc0201c52:	e03e                	sd	a5,0(sp)
ffffffffc0201c54:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c56:	85a6                	mv	a1,s1
ffffffffc0201c58:	07800513          	li	a0,120
ffffffffc0201c5c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c5e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c60:	6782                	ld	a5,0(sp)
ffffffffc0201c62:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c64:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c68:	bfb5                	j	ffffffffc0201be4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c6a:	000a3403          	ld	s0,0(s4)
ffffffffc0201c6e:	008a0713          	addi	a4,s4,8
ffffffffc0201c72:	e03a                	sd	a4,0(sp)
ffffffffc0201c74:	14040263          	beqz	s0,ffffffffc0201db8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c78:	0fb05763          	blez	s11,ffffffffc0201d66 <vprintfmt+0x2d8>
ffffffffc0201c7c:	02d00693          	li	a3,45
ffffffffc0201c80:	0cd79163          	bne	a5,a3,ffffffffc0201d42 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c84:	00044783          	lbu	a5,0(s0)
ffffffffc0201c88:	0007851b          	sext.w	a0,a5
ffffffffc0201c8c:	cf85                	beqz	a5,ffffffffc0201cc4 <vprintfmt+0x236>
ffffffffc0201c8e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c92:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c96:	000c4563          	bltz	s8,ffffffffc0201ca0 <vprintfmt+0x212>
ffffffffc0201c9a:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c9c:	036c0263          	beq	s8,s6,ffffffffc0201cc0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201ca0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ca2:	0e0c8e63          	beqz	s9,ffffffffc0201d9e <vprintfmt+0x310>
ffffffffc0201ca6:	3781                	addiw	a5,a5,-32
ffffffffc0201ca8:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d9e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201cac:	03f00513          	li	a0,63
ffffffffc0201cb0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cb2:	000a4783          	lbu	a5,0(s4)
ffffffffc0201cb6:	3dfd                	addiw	s11,s11,-1
ffffffffc0201cb8:	0a05                	addi	s4,s4,1
ffffffffc0201cba:	0007851b          	sext.w	a0,a5
ffffffffc0201cbe:	ffe1                	bnez	a5,ffffffffc0201c96 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201cc0:	01b05963          	blez	s11,ffffffffc0201cd2 <vprintfmt+0x244>
ffffffffc0201cc4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201cc6:	85a6                	mv	a1,s1
ffffffffc0201cc8:	02000513          	li	a0,32
ffffffffc0201ccc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201cce:	fe0d9be3          	bnez	s11,ffffffffc0201cc4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cd2:	6a02                	ld	s4,0(sp)
ffffffffc0201cd4:	bbd5                	j	ffffffffc0201ac8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201cd6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cd8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201cdc:	01174463          	blt	a4,a7,ffffffffc0201ce4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201ce0:	08088d63          	beqz	a7,ffffffffc0201d7a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201ce4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201ce8:	0a044d63          	bltz	s0,ffffffffc0201da2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201cec:	8622                	mv	a2,s0
ffffffffc0201cee:	8a66                	mv	s4,s9
ffffffffc0201cf0:	46a9                	li	a3,10
ffffffffc0201cf2:	bdcd                	j	ffffffffc0201be4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201cf4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cf8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201cfa:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201cfc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d00:	8fb5                	xor	a5,a5,a3
ffffffffc0201d02:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d06:	02d74163          	blt	a4,a3,ffffffffc0201d28 <vprintfmt+0x29a>
ffffffffc0201d0a:	00369793          	slli	a5,a3,0x3
ffffffffc0201d0e:	97de                	add	a5,a5,s7
ffffffffc0201d10:	639c                	ld	a5,0(a5)
ffffffffc0201d12:	cb99                	beqz	a5,ffffffffc0201d28 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d14:	86be                	mv	a3,a5
ffffffffc0201d16:	00001617          	auipc	a2,0x1
ffffffffc0201d1a:	04260613          	addi	a2,a2,66 # ffffffffc0202d58 <default_pmm_manager+0x68>
ffffffffc0201d1e:	85a6                	mv	a1,s1
ffffffffc0201d20:	854a                	mv	a0,s2
ffffffffc0201d22:	0ce000ef          	jal	ra,ffffffffc0201df0 <printfmt>
ffffffffc0201d26:	b34d                	j	ffffffffc0201ac8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d28:	00001617          	auipc	a2,0x1
ffffffffc0201d2c:	02060613          	addi	a2,a2,32 # ffffffffc0202d48 <default_pmm_manager+0x58>
ffffffffc0201d30:	85a6                	mv	a1,s1
ffffffffc0201d32:	854a                	mv	a0,s2
ffffffffc0201d34:	0bc000ef          	jal	ra,ffffffffc0201df0 <printfmt>
ffffffffc0201d38:	bb41                	j	ffffffffc0201ac8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d3a:	00001417          	auipc	s0,0x1
ffffffffc0201d3e:	00640413          	addi	s0,s0,6 # ffffffffc0202d40 <default_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d42:	85e2                	mv	a1,s8
ffffffffc0201d44:	8522                	mv	a0,s0
ffffffffc0201d46:	e43e                	sd	a5,8(sp)
ffffffffc0201d48:	c53ff0ef          	jal	ra,ffffffffc020199a <strnlen>
ffffffffc0201d4c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d50:	01b05b63          	blez	s11,ffffffffc0201d66 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d54:	67a2                	ld	a5,8(sp)
ffffffffc0201d56:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d5a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d5c:	85a6                	mv	a1,s1
ffffffffc0201d5e:	8552                	mv	a0,s4
ffffffffc0201d60:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d62:	fe0d9ce3          	bnez	s11,ffffffffc0201d5a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d66:	00044783          	lbu	a5,0(s0)
ffffffffc0201d6a:	00140a13          	addi	s4,s0,1
ffffffffc0201d6e:	0007851b          	sext.w	a0,a5
ffffffffc0201d72:	d3a5                	beqz	a5,ffffffffc0201cd2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d74:	05e00413          	li	s0,94
ffffffffc0201d78:	bf39                	j	ffffffffc0201c96 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d7a:	000a2403          	lw	s0,0(s4)
ffffffffc0201d7e:	b7ad                	j	ffffffffc0201ce8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d80:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d84:	46a1                	li	a3,8
ffffffffc0201d86:	8a2e                	mv	s4,a1
ffffffffc0201d88:	bdb1                	j	ffffffffc0201be4 <vprintfmt+0x156>
ffffffffc0201d8a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d8e:	46a9                	li	a3,10
ffffffffc0201d90:	8a2e                	mv	s4,a1
ffffffffc0201d92:	bd89                	j	ffffffffc0201be4 <vprintfmt+0x156>
ffffffffc0201d94:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d98:	46c1                	li	a3,16
ffffffffc0201d9a:	8a2e                	mv	s4,a1
ffffffffc0201d9c:	b5a1                	j	ffffffffc0201be4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d9e:	9902                	jalr	s2
ffffffffc0201da0:	bf09                	j	ffffffffc0201cb2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201da2:	85a6                	mv	a1,s1
ffffffffc0201da4:	02d00513          	li	a0,45
ffffffffc0201da8:	e03e                	sd	a5,0(sp)
ffffffffc0201daa:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201dac:	6782                	ld	a5,0(sp)
ffffffffc0201dae:	8a66                	mv	s4,s9
ffffffffc0201db0:	40800633          	neg	a2,s0
ffffffffc0201db4:	46a9                	li	a3,10
ffffffffc0201db6:	b53d                	j	ffffffffc0201be4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201db8:	03b05163          	blez	s11,ffffffffc0201dda <vprintfmt+0x34c>
ffffffffc0201dbc:	02d00693          	li	a3,45
ffffffffc0201dc0:	f6d79de3          	bne	a5,a3,ffffffffc0201d3a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201dc4:	00001417          	auipc	s0,0x1
ffffffffc0201dc8:	f7c40413          	addi	s0,s0,-132 # ffffffffc0202d40 <default_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201dcc:	02800793          	li	a5,40
ffffffffc0201dd0:	02800513          	li	a0,40
ffffffffc0201dd4:	00140a13          	addi	s4,s0,1
ffffffffc0201dd8:	bd6d                	j	ffffffffc0201c92 <vprintfmt+0x204>
ffffffffc0201dda:	00001a17          	auipc	s4,0x1
ffffffffc0201dde:	f67a0a13          	addi	s4,s4,-153 # ffffffffc0202d41 <default_pmm_manager+0x51>
ffffffffc0201de2:	02800513          	li	a0,40
ffffffffc0201de6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dea:	05e00413          	li	s0,94
ffffffffc0201dee:	b565                	j	ffffffffc0201c96 <vprintfmt+0x208>

ffffffffc0201df0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201df0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201df2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201df6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201df8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dfa:	ec06                	sd	ra,24(sp)
ffffffffc0201dfc:	f83a                	sd	a4,48(sp)
ffffffffc0201dfe:	fc3e                	sd	a5,56(sp)
ffffffffc0201e00:	e0c2                	sd	a6,64(sp)
ffffffffc0201e02:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e04:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e06:	c89ff0ef          	jal	ra,ffffffffc0201a8e <vprintfmt>
}
ffffffffc0201e0a:	60e2                	ld	ra,24(sp)
ffffffffc0201e0c:	6161                	addi	sp,sp,80
ffffffffc0201e0e:	8082                	ret

ffffffffc0201e10 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e10:	715d                	addi	sp,sp,-80
ffffffffc0201e12:	e486                	sd	ra,72(sp)
ffffffffc0201e14:	e0a6                	sd	s1,64(sp)
ffffffffc0201e16:	fc4a                	sd	s2,56(sp)
ffffffffc0201e18:	f84e                	sd	s3,48(sp)
ffffffffc0201e1a:	f452                	sd	s4,40(sp)
ffffffffc0201e1c:	f056                	sd	s5,32(sp)
ffffffffc0201e1e:	ec5a                	sd	s6,24(sp)
ffffffffc0201e20:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e22:	c901                	beqz	a0,ffffffffc0201e32 <readline+0x22>
ffffffffc0201e24:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e26:	00001517          	auipc	a0,0x1
ffffffffc0201e2a:	f3250513          	addi	a0,a0,-206 # ffffffffc0202d58 <default_pmm_manager+0x68>
ffffffffc0201e2e:	aaafe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201e32:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e34:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e36:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e38:	4aa9                	li	s5,10
ffffffffc0201e3a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e3c:	00004b97          	auipc	s7,0x4
ffffffffc0201e40:	204b8b93          	addi	s7,s7,516 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e44:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e48:	b08fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e4c:	00054a63          	bltz	a0,ffffffffc0201e60 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e50:	00a95a63          	bge	s2,a0,ffffffffc0201e64 <readline+0x54>
ffffffffc0201e54:	029a5263          	bge	s4,s1,ffffffffc0201e78 <readline+0x68>
        c = getchar();
ffffffffc0201e58:	af8fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e5c:	fe055ae3          	bgez	a0,ffffffffc0201e50 <readline+0x40>
            return NULL;
ffffffffc0201e60:	4501                	li	a0,0
ffffffffc0201e62:	a091                	j	ffffffffc0201ea6 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e64:	03351463          	bne	a0,s3,ffffffffc0201e8c <readline+0x7c>
ffffffffc0201e68:	e8a9                	bnez	s1,ffffffffc0201eba <readline+0xaa>
        c = getchar();
ffffffffc0201e6a:	ae6fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e6e:	fe0549e3          	bltz	a0,ffffffffc0201e60 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e72:	fea959e3          	bge	s2,a0,ffffffffc0201e64 <readline+0x54>
ffffffffc0201e76:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e78:	e42a                	sd	a0,8(sp)
ffffffffc0201e7a:	a94fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201e7e:	6522                	ld	a0,8(sp)
ffffffffc0201e80:	009b87b3          	add	a5,s7,s1
ffffffffc0201e84:	2485                	addiw	s1,s1,1
ffffffffc0201e86:	00a78023          	sb	a0,0(a5)
ffffffffc0201e8a:	bf7d                	j	ffffffffc0201e48 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e8c:	01550463          	beq	a0,s5,ffffffffc0201e94 <readline+0x84>
ffffffffc0201e90:	fb651ce3          	bne	a0,s6,ffffffffc0201e48 <readline+0x38>
            cputchar(c);
ffffffffc0201e94:	a7afe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201e98:	00004517          	auipc	a0,0x4
ffffffffc0201e9c:	1a850513          	addi	a0,a0,424 # ffffffffc0206040 <buf>
ffffffffc0201ea0:	94aa                	add	s1,s1,a0
ffffffffc0201ea2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ea6:	60a6                	ld	ra,72(sp)
ffffffffc0201ea8:	6486                	ld	s1,64(sp)
ffffffffc0201eaa:	7962                	ld	s2,56(sp)
ffffffffc0201eac:	79c2                	ld	s3,48(sp)
ffffffffc0201eae:	7a22                	ld	s4,40(sp)
ffffffffc0201eb0:	7a82                	ld	s5,32(sp)
ffffffffc0201eb2:	6b62                	ld	s6,24(sp)
ffffffffc0201eb4:	6bc2                	ld	s7,16(sp)
ffffffffc0201eb6:	6161                	addi	sp,sp,80
ffffffffc0201eb8:	8082                	ret
            cputchar(c);
ffffffffc0201eba:	4521                	li	a0,8
ffffffffc0201ebc:	a52fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201ec0:	34fd                	addiw	s1,s1,-1
ffffffffc0201ec2:	b759                	j	ffffffffc0201e48 <readline+0x38>

ffffffffc0201ec4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201ec4:	4781                	li	a5,0
ffffffffc0201ec6:	00004717          	auipc	a4,0x4
ffffffffc0201eca:	15273703          	ld	a4,338(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201ece:	88ba                	mv	a7,a4
ffffffffc0201ed0:	852a                	mv	a0,a0
ffffffffc0201ed2:	85be                	mv	a1,a5
ffffffffc0201ed4:	863e                	mv	a2,a5
ffffffffc0201ed6:	00000073          	ecall
ffffffffc0201eda:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201edc:	8082                	ret

ffffffffc0201ede <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201ede:	4781                	li	a5,0
ffffffffc0201ee0:	00004717          	auipc	a4,0x4
ffffffffc0201ee4:	5b873703          	ld	a4,1464(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201ee8:	88ba                	mv	a7,a4
ffffffffc0201eea:	852a                	mv	a0,a0
ffffffffc0201eec:	85be                	mv	a1,a5
ffffffffc0201eee:	863e                	mv	a2,a5
ffffffffc0201ef0:	00000073          	ecall
ffffffffc0201ef4:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201ef6:	8082                	ret

ffffffffc0201ef8 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201ef8:	4501                	li	a0,0
ffffffffc0201efa:	00004797          	auipc	a5,0x4
ffffffffc0201efe:	1167b783          	ld	a5,278(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f02:	88be                	mv	a7,a5
ffffffffc0201f04:	852a                	mv	a0,a0
ffffffffc0201f06:	85aa                	mv	a1,a0
ffffffffc0201f08:	862a                	mv	a2,a0
ffffffffc0201f0a:	00000073          	ecall
ffffffffc0201f0e:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201f10:	2501                	sext.w	a0,a0
ffffffffc0201f12:	8082                	ret

ffffffffc0201f14 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201f14:	4781                	li	a5,0
ffffffffc0201f16:	00004717          	auipc	a4,0x4
ffffffffc0201f1a:	10a73703          	ld	a4,266(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201f1e:	88ba                	mv	a7,a4
ffffffffc0201f20:	853e                	mv	a0,a5
ffffffffc0201f22:	85be                	mv	a1,a5
ffffffffc0201f24:	863e                	mv	a2,a5
ffffffffc0201f26:	00000073          	ecall
ffffffffc0201f2a:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201f2c:	8082                	ret
