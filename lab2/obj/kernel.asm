
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	29c50513          	addi	a0,a0,668 # ffffffffc02012e8 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	2a650513          	addi	a0,a0,678 # ffffffffc0201308 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	27458593          	addi	a1,a1,628 # ffffffffc02012e2 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	2b250513          	addi	a0,a0,690 # ffffffffc0201328 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	2be50513          	addi	a0,a0,702 # ffffffffc0201348 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	08a58593          	addi	a1,a1,138 # ffffffffc0205120 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	2ca50513          	addi	a0,a0,714 # ffffffffc0201368 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	47558593          	addi	a1,a1,1141 # ffffffffc020551f <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	2bc50513          	addi	a0,a0,700 # ffffffffc0201388 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <free_area>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	04060613          	addi	a2,a2,64 # ffffffffc0205120 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	1e0010ef          	jal	ra,ffffffffc02012d0 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	2bc50513          	addi	a0,a0,700 # ffffffffc02013b8 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	36b000ef          	jal	ra,ffffffffc0200c76 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	57b000ef          	jal	ra,ffffffffc0200eba <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	545000ef          	jal	ra,ffffffffc0200eba <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	f0630313          	addi	t1,t1,-250 # ffffffffc02050c8 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	1e650513          	addi	a0,a0,486 # ffffffffc02013d8 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	74850513          	addi	a0,a0,1864 # ffffffffc0201950 <etext+0x66e>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	0200106f          	j	ffffffffc020123c <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	1d650513          	addi	a0,a0,470 # ffffffffc02013f8 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	1b850513          	addi	a0,a0,440 # ffffffffc0201408 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00005417          	auipc	s0,0x5
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0205008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	1b250513          	addi	a0,a0,434 # ffffffffc0201418 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	1ba50513          	addi	a0,a0,442 # ffffffffc0201430 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedadcd>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	15090913          	addi	s2,s2,336 # ffffffffc0201480 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	13a48493          	addi	s1,s1,314 # ffffffffc0201478 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	16650513          	addi	a0,a0,358 # ffffffffc02014f8 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	19250513          	addi	a0,a0,402 # ffffffffc0201530 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	07250513          	addi	a0,a0,114 # ffffffffc0201450 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	66b000ef          	jal	ra,ffffffffc0201256 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	6b1000ef          	jal	ra,ffffffffc02012aa <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	5fd000ef          	jal	ra,ffffffffc020128c <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	fe450513          	addi	a0,a0,-28 # ffffffffc0201488 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	f3650513          	addi	a0,a0,-202 # ffffffffc02014a8 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	f3c50513          	addi	a0,a0,-196 # ffffffffc02014c0 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	f4a50513          	addi	a0,a0,-182 # ffffffffc02014e0 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	f8e50513          	addi	a0,a0,-114 # ffffffffc0201530 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00005797          	auipc	a5,0x5
ffffffffc02005ae:	b287b323          	sd	s0,-1242(a5) # ffffffffc02050d0 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00005797          	auipc	a5,0x5
ffffffffc02005b6:	b367b323          	sd	s6,-1242(a5) # ffffffffc02050d8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	b1453503          	ld	a0,-1260(a0) # ffffffffc02050d0 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00005517          	auipc	a0,0x5
ffffffffc02005ca:	b1253503          	ld	a0,-1262(a0) # ffffffffc02050d8 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:
// 当前总空闲页
static inline size_t nrfree(void) { return free_nr_pages; }

//重置初始化
static void buddy_init(void) {
    for (int i = 0; i < BUDDY_MAX_ORDER; i++) {
ffffffffc02005d0:	00005797          	auipc	a5,0x5
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0205018 <free_area>
ffffffffc02005d8:	00005717          	auipc	a4,0x5
ffffffffc02005dc:	af070713          	addi	a4,a4,-1296 # ffffffffc02050c8 <is_panic>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005e0:	e79c                	sd	a5,8(a5)
ffffffffc02005e2:	e39c                	sd	a5,0(a5)
ffffffffc02005e4:	07c1                	addi	a5,a5,16
ffffffffc02005e6:	fee79de3          	bne	a5,a4,ffffffffc02005e0 <buddy_init+0x10>
        list_init(&free_area[i]);
    }
    free_nr_pages = 0;
ffffffffc02005ea:	00005797          	auipc	a5,0x5
ffffffffc02005ee:	ae07bf23          	sd	zero,-1282(a5) # ffffffffc02050e8 <free_nr_pages>
    buddy_base = NULL;
ffffffffc02005f2:	00005797          	auipc	a5,0x5
ffffffffc02005f6:	ae07b723          	sd	zero,-1298(a5) # ffffffffc02050e0 <buddy_base>
    buddy_npages = 0;
}
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <buddy_nr_free_pages>:
    }
}

static size_t buddy_nr_free_pages(void) {
    return free_nr_pages;
}
ffffffffc02005fc:	00005517          	auipc	a0,0x5
ffffffffc0200600:	aec53503          	ld	a0,-1300(a0) # ffffffffc02050e8 <free_nr_pages>
ffffffffc0200604:	8082                	ret

ffffffffc0200606 <buddy_check>:

static void buddy_check(void) {
ffffffffc0200606:	1101                	addi	sp,sp,-32
    #define POW2(o) (1u << (o))

    cprintf("\n[buddy] 1024 页示范\n");
ffffffffc0200608:	00001517          	auipc	a0,0x1
ffffffffc020060c:	f4050513          	addi	a0,a0,-192 # ffffffffc0201548 <etext+0x266>
static void buddy_check(void) {
ffffffffc0200610:	ec06                	sd	ra,24(sp)
    cprintf("\n[buddy] 1024 页示范\n");
ffffffffc0200612:	b3bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("[buddy] 初始：一个大块 [0,1024) (order=%u, 大小=%u)\n\n", 10u, 1024u);
ffffffffc0200616:	40000613          	li	a2,1024
ffffffffc020061a:	45a9                	li	a1,10
ffffffffc020061c:	00001517          	auipc	a0,0x1
ffffffffc0200620:	f4c50513          	addi	a0,a0,-180 # ffffffffc0201568 <etext+0x286>
ffffffffc0200624:	b29ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct demo { const char* name; unsigned req, ord, size, st, ed; } A,B,C,D,E,F;

    // A: 32
    A.name="A"; A.req=32u;  A.ord=ceil_order(A.req); A.size=POW2(A.ord);
    A.st=0u; A.ed=A.st+A.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u)\n",
ffffffffc0200628:	02000813          	li	a6,32
ffffffffc020062c:	4781                	li	a5,0
ffffffffc020062e:	4715                	li	a4,5
ffffffffc0200630:	02000693          	li	a3,32
ffffffffc0200634:	02000613          	li	a2,32
ffffffffc0200638:	00001597          	auipc	a1,0x1
ffffffffc020063c:	f7058593          	addi	a1,a1,-144 # ffffffffc02015a8 <etext+0x2c6>
ffffffffc0200640:	00001517          	auipc	a0,0x1
ffffffffc0200644:	f7050513          	addi	a0,a0,-144 # ffffffffc02015b0 <etext+0x2ce>
ffffffffc0200648:	b05ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            A.name, A.req, A.size, A.ord, A.st, A.ed);

    // B: 64  —— 直接用 64..128
    B.name="B"; B.req=64u;  B.ord=ceil_order(B.req); B.size=POW2(B.ord);
    B.st=64u; B.ed=B.st+B.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u)\n",
ffffffffc020064c:	08000813          	li	a6,128
ffffffffc0200650:	04000793          	li	a5,64
ffffffffc0200654:	4719                	li	a4,6
ffffffffc0200656:	04000693          	li	a3,64
ffffffffc020065a:	04000613          	li	a2,64
ffffffffc020065e:	00001597          	auipc	a1,0x1
ffffffffc0200662:	f9258593          	addi	a1,a1,-110 # ffffffffc02015f0 <etext+0x30e>
ffffffffc0200666:	00001517          	auipc	a0,0x1
ffffffffc020066a:	f4a50513          	addi	a0,a0,-182 # ffffffffc02015b0 <etext+0x2ce>
ffffffffc020066e:	adfff0ef          	jal	ra,ffffffffc020014c <cprintf>
            B.name, B.req, B.size, B.ord, B.st, B.ed);

    // C: 60 -> 向上取 64，用 128..192
    C.name="C"; C.req=60u;  C.ord=ceil_order(C.req); C.size=POW2(C.ord);
    C.st=128u; C.ed=C.st+C.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：60 向上取 64\n",
ffffffffc0200672:	0c000813          	li	a6,192
ffffffffc0200676:	08000793          	li	a5,128
ffffffffc020067a:	4719                	li	a4,6
ffffffffc020067c:	04000693          	li	a3,64
ffffffffc0200680:	03c00613          	li	a2,60
ffffffffc0200684:	00001597          	auipc	a1,0x1
ffffffffc0200688:	f7458593          	addi	a1,a1,-140 # ffffffffc02015f8 <etext+0x316>
ffffffffc020068c:	00001517          	auipc	a0,0x1
ffffffffc0200690:	f7450513          	addi	a0,a0,-140 # ffffffffc0201600 <etext+0x31e>
ffffffffc0200694:	ab9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            C.name, C.req, C.size, C.ord, C.st, C.ed);

    // D: 150 -> 向上取 256，用 256..512
    D.name="D"; D.req=150u; D.ord=ceil_order(D.req); D.size=POW2(D.ord);
    D.st=256u; D.ed=D.st+D.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：150 向上取 256\n\n",
ffffffffc0200698:	20000813          	li	a6,512
ffffffffc020069c:	10000793          	li	a5,256
ffffffffc02006a0:	4721                	li	a4,8
ffffffffc02006a2:	10000693          	li	a3,256
ffffffffc02006a6:	09600613          	li	a2,150
ffffffffc02006aa:	00001597          	auipc	a1,0x1
ffffffffc02006ae:	fb658593          	addi	a1,a1,-74 # ffffffffc0201660 <etext+0x37e>
ffffffffc02006b2:	00001517          	auipc	a0,0x1
ffffffffc02006b6:	fb650513          	addi	a0,a0,-74 # ffffffffc0201668 <etext+0x386>
ffffffffc02006ba:	a93ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            D.name, D.req, D.size, D.ord, D.st, D.ed);

    // 释放 B
    cprintf("[buddy] 释放 %s：区间 [%u,%u)\n", B.name, B.st, B.ed);
ffffffffc02006be:	08000693          	li	a3,128
ffffffffc02006c2:	04000613          	li	a2,64
ffffffffc02006c6:	00001597          	auipc	a1,0x1
ffffffffc02006ca:	f2a58593          	addi	a1,a1,-214 # ffffffffc02015f0 <etext+0x30e>
ffffffffc02006ce:	00001517          	auipc	a0,0x1
ffffffffc02006d2:	ffa50513          	addi	a0,a0,-6 # ffffffffc02016c8 <etext+0x3e6>
ffffffffc02006d6:	a77ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("        检查伙伴：%s(order=%u) 的伙伴是 [0,64) —— 因 %s 占用 [0,32)，暂不能合并\n",
ffffffffc02006da:	00001697          	auipc	a3,0x1
ffffffffc02006de:	ece68693          	addi	a3,a3,-306 # ffffffffc02015a8 <etext+0x2c6>
ffffffffc02006e2:	4619                	li	a2,6
ffffffffc02006e4:	00001597          	auipc	a1,0x1
ffffffffc02006e8:	f0c58593          	addi	a1,a1,-244 # ffffffffc02015f0 <etext+0x30e>
ffffffffc02006ec:	00001517          	auipc	a0,0x1
ffffffffc02006f0:	00450513          	addi	a0,a0,4 # ffffffffc02016f0 <etext+0x40e>
ffffffffc02006f4:	a59ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            B.name, B.ord, A.name);

    // 释放 A：先与 [32,64) 合并 -> [0,64)，再与 B 的 [64,128) 合并 -> [0,128)
    cprintf("[buddy] 释放 %s：区间 [%u,%u)\n", A.name, A.st, A.ed);
ffffffffc02006f8:	02000693          	li	a3,32
ffffffffc02006fc:	4601                	li	a2,0
ffffffffc02006fe:	00001597          	auipc	a1,0x1
ffffffffc0200702:	eaa58593          	addi	a1,a1,-342 # ffffffffc02015a8 <etext+0x2c6>
ffffffffc0200706:	00001517          	auipc	a0,0x1
ffffffffc020070a:	fc250513          	addi	a0,a0,-62 # ffffffffc02016c8 <etext+0x3e6>
ffffffffc020070e:	a3fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("        先与 [32,64) 合并 -> [0,64)；再与 %s 的 [64,128) 合并 -> [0,128)\n\n", B.name);
ffffffffc0200712:	00001597          	auipc	a1,0x1
ffffffffc0200716:	ede58593          	addi	a1,a1,-290 # ffffffffc02015f0 <etext+0x30e>
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	03e50513          	addi	a0,a0,62 # ffffffffc0201758 <etext+0x476>
ffffffffc0200722:	a2bff0ef          	jal	ra,ffffffffc020014c <cprintf>

    // E: 100 -> 128，用刚合并出的 [0,128)
    E.name="E"; E.req=100u; E.ord=ceil_order(E.req); E.size=POW2(E.ord);
    E.st=0u; E.ed=E.st+E.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：100 向上取 128，使用 [0,128)\n",
ffffffffc0200726:	08000813          	li	a6,128
ffffffffc020072a:	4781                	li	a5,0
ffffffffc020072c:	471d                	li	a4,7
ffffffffc020072e:	08000693          	li	a3,128
ffffffffc0200732:	06400613          	li	a2,100
ffffffffc0200736:	00001597          	auipc	a1,0x1
ffffffffc020073a:	07a58593          	addi	a1,a1,122 # ffffffffc02017b0 <etext+0x4ce>
ffffffffc020073e:	00001517          	auipc	a0,0x1
ffffffffc0200742:	07a50513          	addi	a0,a0,122 # ffffffffc02017b8 <etext+0x4d6>
ffffffffc0200746:	a07ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            E.name, E.req, E.size, E.ord, E.st, E.ed);

    // F: 100 -> 128，从右侧 512..1024 拆出 128，得到 512..640
    F.name="F"; F.req=100u; F.ord=ceil_order(F.req); F.size=POW2(F.ord);
    F.st=512u; F.ed=F.st+F.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：从右侧 512..1024 拆出 128\n\n",
ffffffffc020074a:	28000813          	li	a6,640
ffffffffc020074e:	20000793          	li	a5,512
ffffffffc0200752:	471d                	li	a4,7
ffffffffc0200754:	08000693          	li	a3,128
ffffffffc0200758:	06400613          	li	a2,100
ffffffffc020075c:	00001597          	auipc	a1,0x1
ffffffffc0200760:	0cc58593          	addi	a1,a1,204 # ffffffffc0201828 <etext+0x546>
ffffffffc0200764:	00001517          	auipc	a0,0x1
ffffffffc0200768:	0cc50513          	addi	a0,a0,204 # ffffffffc0201830 <etext+0x54e>
ffffffffc020076c:	9e1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    // 内部碎片
    unsigned waste =
        (A.size-A.req) + (B.size-B.req) + (C.size-C.req) +
        (D.size-D.req) + (E.size-E.req) + (F.size-F.req);

    cprintf("[buddy] 内部碎片：\n");
ffffffffc0200770:	00001517          	auipc	a0,0x1
ffffffffc0200774:	13050513          	addi	a0,a0,304 # ffffffffc02018a0 <etext+0x5be>
ffffffffc0200778:	9d5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("        A:%u->%u(+%u), B:%u->%u(+%u), C:%u->%u(+%u)\n",
ffffffffc020077c:	4511                	li	a0,4
ffffffffc020077e:	e42a                	sd	a0,8(sp)
ffffffffc0200780:	04000513          	li	a0,64
ffffffffc0200784:	e02a                	sd	a0,0(sp)
ffffffffc0200786:	03c00893          	li	a7,60
ffffffffc020078a:	4801                	li	a6,0
ffffffffc020078c:	04000793          	li	a5,64
ffffffffc0200790:	04000713          	li	a4,64
ffffffffc0200794:	4681                	li	a3,0
ffffffffc0200796:	02000613          	li	a2,32
ffffffffc020079a:	02000593          	li	a1,32
ffffffffc020079e:	00001517          	auipc	a0,0x1
ffffffffc02007a2:	12250513          	addi	a0,a0,290 # ffffffffc02018c0 <etext+0x5de>
ffffffffc02007a6:	9a7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        A.req,A.size,(A.size-A.req), B.req,B.size,(B.size-B.req), C.req,C.size,(C.size-C.req));
    cprintf("        D:%u->%u(+%u), E:%u->%u(+%u), F:%u->%u(+%u)\n",
ffffffffc02007aa:	4571                	li	a0,28
ffffffffc02007ac:	e42a                	sd	a0,8(sp)
ffffffffc02007ae:	08000513          	li	a0,128
ffffffffc02007b2:	06400893          	li	a7,100
ffffffffc02007b6:	4871                	li	a6,28
ffffffffc02007b8:	08000793          	li	a5,128
ffffffffc02007bc:	06400713          	li	a4,100
ffffffffc02007c0:	06a00693          	li	a3,106
ffffffffc02007c4:	10000613          	li	a2,256
ffffffffc02007c8:	e02a                	sd	a0,0(sp)
ffffffffc02007ca:	09600593          	li	a1,150
ffffffffc02007ce:	00001517          	auipc	a0,0x1
ffffffffc02007d2:	12a50513          	addi	a0,a0,298 # ffffffffc02018f8 <etext+0x616>
ffffffffc02007d6:	977ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        D.req,D.size,(D.size-D.req), E.req,E.size,(E.size-E.req), F.req,F.size,(F.size-F.req));
    cprintf("        总内部碎片: %u 页\n\n", waste);
ffffffffc02007da:	0a600593          	li	a1,166
ffffffffc02007de:	00001517          	auipc	a0,0x1
ffffffffc02007e2:	15250513          	addi	a0,a0,338 # ffffffffc0201930 <etext+0x64e>
ffffffffc02007e6:	967ff0ef          	jal	ra,ffffffffc020014c <cprintf>

    // 汇总
    cprintf("[buddy] 最终区间总结（单位：页）\n");
ffffffffc02007ea:	00001517          	auipc	a0,0x1
ffffffffc02007ee:	16e50513          	addi	a0,a0,366 # ffffffffc0201958 <etext+0x676>
ffffffffc02007f2:	95bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  A: [%4u,%4u)  请求=%3u 实分=%3u\n", A.st,A.ed,A.req,A.size);
ffffffffc02007f6:	02000713          	li	a4,32
ffffffffc02007fa:	02000693          	li	a3,32
ffffffffc02007fe:	02000613          	li	a2,32
ffffffffc0200802:	4581                	li	a1,0
ffffffffc0200804:	00001517          	auipc	a0,0x1
ffffffffc0200808:	18450513          	addi	a0,a0,388 # ffffffffc0201988 <etext+0x6a6>
ffffffffc020080c:	941ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  B: [%4u,%4u)  请求=%3u 实分=%3u   （随后释放）\n", B.st,B.ed,B.req,B.size);
ffffffffc0200810:	04000713          	li	a4,64
ffffffffc0200814:	04000693          	li	a3,64
ffffffffc0200818:	08000613          	li	a2,128
ffffffffc020081c:	04000593          	li	a1,64
ffffffffc0200820:	00001517          	auipc	a0,0x1
ffffffffc0200824:	19050513          	addi	a0,a0,400 # ffffffffc02019b0 <etext+0x6ce>
ffffffffc0200828:	925ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  C: [%4u,%4u)  请求=%3u 实分=%3u\n", C.st,C.ed,C.req,C.size);
ffffffffc020082c:	04000713          	li	a4,64
ffffffffc0200830:	03c00693          	li	a3,60
ffffffffc0200834:	0c000613          	li	a2,192
ffffffffc0200838:	08000593          	li	a1,128
ffffffffc020083c:	00001517          	auipc	a0,0x1
ffffffffc0200840:	1b450513          	addi	a0,a0,436 # ffffffffc02019f0 <etext+0x70e>
ffffffffc0200844:	909ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  D: [%4u,%4u)  请求=%3u 实分=%3u\n", D.st,D.ed,D.req,D.size);
ffffffffc0200848:	10000713          	li	a4,256
ffffffffc020084c:	09600693          	li	a3,150
ffffffffc0200850:	20000613          	li	a2,512
ffffffffc0200854:	10000593          	li	a1,256
ffffffffc0200858:	00001517          	auipc	a0,0x1
ffffffffc020085c:	1c050513          	addi	a0,a0,448 # ffffffffc0201a18 <etext+0x736>
ffffffffc0200860:	8edff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  E: [%4u,%4u)  请求=%3u 实分=%3u\n", E.st,E.ed,E.req,E.size);
ffffffffc0200864:	08000713          	li	a4,128
ffffffffc0200868:	06400693          	li	a3,100
ffffffffc020086c:	08000613          	li	a2,128
ffffffffc0200870:	4581                	li	a1,0
ffffffffc0200872:	00001517          	auipc	a0,0x1
ffffffffc0200876:	1ce50513          	addi	a0,a0,462 # ffffffffc0201a40 <etext+0x75e>
ffffffffc020087a:	8d3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  F: [%4u,%4u)  请求=%3u 实分=%3u\n", F.st,F.ed,F.req,F.size);
ffffffffc020087e:	08000713          	li	a4,128
ffffffffc0200882:	06400693          	li	a3,100
ffffffffc0200886:	28000613          	li	a2,640
ffffffffc020088a:	20000593          	li	a1,512
ffffffffc020088e:	00001517          	auipc	a0,0x1
ffffffffc0200892:	1da50513          	addi	a0,a0,474 # ffffffffc0201a68 <etext+0x786>
ffffffffc0200896:	8b7ff0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("\n[buddy] 结论: 正确，与预期相同\n");
}
ffffffffc020089a:	60e2                	ld	ra,24(sp)
    cprintf("\n[buddy] 结论: 正确，与预期相同\n");
ffffffffc020089c:	00001517          	auipc	a0,0x1
ffffffffc02008a0:	1f450513          	addi	a0,a0,500 # ffffffffc0201a90 <etext+0x7ae>
}
ffffffffc02008a4:	6105                	addi	sp,sp,32
    cprintf("\n[buddy] 结论: 正确，与预期相同\n");
ffffffffc02008a6:	b05d                	j	ffffffffc020014c <cprintf>

ffffffffc02008a8 <buddy_alloc_pages>:
    if (n == 0) return NULL;
ffffffffc02008a8:	c521                	beqz	a0,ffffffffc02008f0 <buddy_alloc_pages+0x48>
    while (s < n) { s <<= 1; o++; }
ffffffffc02008aa:	4785                	li	a5,1
    unsigned o = 0; size_t s = 1;
ffffffffc02008ac:	4581                	li	a1,0
    while (s < n) { s <<= 1; o++; }
ffffffffc02008ae:	00f50963          	beq	a0,a5,ffffffffc02008c0 <buddy_alloc_pages+0x18>
ffffffffc02008b2:	0786                	slli	a5,a5,0x1
ffffffffc02008b4:	2585                	addiw	a1,a1,1
ffffffffc02008b6:	fea7eee3          	bltu	a5,a0,ffffffffc02008b2 <buddy_alloc_pages+0xa>
    if (need >= BUDDY_MAX_ORDER) return NULL;  // 需求超过最大支持
ffffffffc02008ba:	47a9                	li	a5,10
ffffffffc02008bc:	02b7ea63          	bltu	a5,a1,ffffffffc02008f0 <buddy_alloc_pages+0x48>
ffffffffc02008c0:	02059793          	slli	a5,a1,0x20
ffffffffc02008c4:	00004697          	auipc	a3,0x4
ffffffffc02008c8:	75468693          	addi	a3,a3,1876 # ffffffffc0205018 <free_area>
ffffffffc02008cc:	01c7d613          	srli	a2,a5,0x1c
ffffffffc02008d0:	9636                	add	a2,a2,a3
    unsigned o = 0; size_t s = 1;
ffffffffc02008d2:	872e                	mv	a4,a1
    while (o < BUDDY_MAX_ORDER && list_empty(&free_area[o])) o++;// 先看“正好阶”的空闲链表有没有块；没有就去更大的阶找
ffffffffc02008d4:	452d                	li	a0,11
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
ffffffffc02008d6:	02071813          	slli	a6,a4,0x20
ffffffffc02008da:	01c85793          	srli	a5,a6,0x1c
ffffffffc02008de:	97b6                	add	a5,a5,a3
ffffffffc02008e0:	0087b883          	ld	a7,8(a5)
ffffffffc02008e4:	00c89863          	bne	a7,a2,ffffffffc02008f4 <buddy_alloc_pages+0x4c>
ffffffffc02008e8:	2705                	addiw	a4,a4,1
ffffffffc02008ea:	0641                	addi	a2,a2,16
ffffffffc02008ec:	fea715e3          	bne	a4,a0,ffffffffc02008d6 <buddy_alloc_pages+0x2e>
    if (n == 0) return NULL;
ffffffffc02008f0:	4501                	li	a0,0
}
ffffffffc02008f2:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc02008f4:	0008b303          	ld	t1,0(a7)
ffffffffc02008f8:	0088b803          	ld	a6,8(a7)
    free_nr_pages -= (1U << order);
ffffffffc02008fc:	00004397          	auipc	t2,0x4
ffffffffc0200900:	7ec38393          	addi	t2,t2,2028 # ffffffffc02050e8 <free_nr_pages>
ffffffffc0200904:	4605                	li	a2,1
    ClearPageProperty(p);
ffffffffc0200906:	ff08b783          	ld	a5,-16(a7)
    free_nr_pages -= (1U << order);
ffffffffc020090a:	0003be03          	ld	t3,0(t2)
ffffffffc020090e:	00e6163b          	sllw	a2,a2,a4
ffffffffc0200912:	1602                	slli	a2,a2,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200914:	01033423          	sd	a6,8(t1)
ffffffffc0200918:	9201                	srli	a2,a2,0x20
    struct Page *p = le2page(le, page_link);//取出块头页
ffffffffc020091a:	fe888513          	addi	a0,a7,-24
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc020091e:	00004f17          	auipc	t5,0x4
ffffffffc0200922:	7c2f3f03          	ld	t5,1986(t5) # ffffffffc02050e0 <buddy_base>
    free_nr_pages -= (1U << order);
ffffffffc0200926:	40ce0e33          	sub	t3,t3,a2
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc020092a:	41e50eb3          	sub	t4,a0,t5
    next->prev = prev;
ffffffffc020092e:	00683023          	sd	t1,0(a6)
    ClearPageProperty(p);
ffffffffc0200932:	9bf5                	andi	a5,a5,-3
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200934:	403ede93          	srai	t4,t4,0x3
ffffffffc0200938:	00001617          	auipc	a2,0x1
ffffffffc020093c:	57063603          	ld	a2,1392(a2) # ffffffffc0201ea8 <error_string+0x38>
    ClearPageProperty(p);
ffffffffc0200940:	fef8b823          	sd	a5,-16(a7)
    free_nr_pages -= (1U << order);
ffffffffc0200944:	01c3b023          	sd	t3,0(t2)
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200948:	02ce8eb3          	mul	t4,t4,a2
    while (o > need) {
ffffffffc020094c:	06e5f663          	bgeu	a1,a4,ffffffffc02009b8 <buddy_alloc_pages+0x110>
ffffffffc0200950:	377d                	addiw	a4,a4,-1
ffffffffc0200952:	02071613          	slli	a2,a4,0x20
ffffffffc0200956:	01c65793          	srli	a5,a2,0x1c
ffffffffc020095a:	96be                	add	a3,a3,a5
        size_t right_idx = idx + (1UL << o);
ffffffffc020095c:	4285                	li	t0,1
    p->property = (1U << order);
ffffffffc020095e:	4f85                	li	t6,1
ffffffffc0200960:	a011                	j	ffffffffc0200964 <buddy_alloc_pages+0xbc>
ffffffffc0200962:	377d                	addiw	a4,a4,-1
        size_t right_idx = idx + (1UL << o);
ffffffffc0200964:	00e297b3          	sll	a5,t0,a4
ffffffffc0200968:	01d78633          	add	a2,a5,t4
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }
ffffffffc020096c:	00261793          	slli	a5,a2,0x2
ffffffffc0200970:	97b2                	add	a5,a5,a2
ffffffffc0200972:	078e                	slli	a5,a5,0x3
ffffffffc0200974:	97fa                	add	a5,a5,t5
    SetPageProperty(p);
ffffffffc0200976:	0087b803          	ld	a6,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc020097a:	0086b303          	ld	t1,8(a3)
    p->property = (1U << order);
ffffffffc020097e:	00ef963b          	sllw	a2,t6,a4
    SetPageProperty(p);
ffffffffc0200982:	00286813          	ori	a6,a6,2
    p->property = (1U << order);
ffffffffc0200986:	cb90                	sw	a2,16(a5)
    SetPageProperty(p);
ffffffffc0200988:	0107b423          	sd	a6,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020098c:	0007a023          	sw	zero,0(a5)
    list_add(&free_area[order], &(p->page_link));
ffffffffc0200990:	01878813          	addi	a6,a5,24
    prev->next = next->prev = elm;
ffffffffc0200994:	01033023          	sd	a6,0(t1)
ffffffffc0200998:	0106b423          	sd	a6,8(a3)
    free_nr_pages += (1U << order);
ffffffffc020099c:	1602                	slli	a2,a2,0x20
    elm->prev = prev;
ffffffffc020099e:	ef94                	sd	a3,24(a5)
ffffffffc02009a0:	9201                	srli	a2,a2,0x20
    elm->next = next;
ffffffffc02009a2:	0267b023          	sd	t1,32(a5)
ffffffffc02009a6:	9e32                	add	t3,t3,a2
    while (o > need) {
ffffffffc02009a8:	16c1                	addi	a3,a3,-16
ffffffffc02009aa:	fab71ce3          	bne	a4,a1,ffffffffc0200962 <buddy_alloc_pages+0xba>
    ClearPageProperty(ret);
ffffffffc02009ae:	ff08b783          	ld	a5,-16(a7)
ffffffffc02009b2:	01c3b023          	sd	t3,0(t2)
ffffffffc02009b6:	9bf5                	andi	a5,a5,-3
ffffffffc02009b8:	fef8b823          	sd	a5,-16(a7)
    ret->property = 0;
ffffffffc02009bc:	fe08ac23          	sw	zero,-8(a7)
ffffffffc02009c0:	fe08a423          	sw	zero,-24(a7)
    return ret;
ffffffffc02009c4:	8082                	ret

ffffffffc02009c6 <buddy_init_memmap>:
    buddy_base   = base;
ffffffffc02009c6:	00004797          	auipc	a5,0x4
ffffffffc02009ca:	70a7bd23          	sd	a0,1818(a5) # ffffffffc02050e0 <buddy_base>
    for (size_t i = 0; i < n; i++) {
ffffffffc02009ce:	c5f5                	beqz	a1,ffffffffc0200aba <buddy_init_memmap+0xf4>
ffffffffc02009d0:	00259693          	slli	a3,a1,0x2
ffffffffc02009d4:	96ae                	add	a3,a3,a1
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02009d6:	1101                	addi	sp,sp,-32
ffffffffc02009d8:	068e                	slli	a3,a3,0x3
ffffffffc02009da:	ec22                	sd	s0,24(sp)
ffffffffc02009dc:	e826                	sd	s1,16(sp)
ffffffffc02009de:	e44a                	sd	s2,8(sp)
ffffffffc02009e0:	87aa                	mv	a5,a0
ffffffffc02009e2:	96aa                	add	a3,a3,a0
        ClearPageProperty(p);
ffffffffc02009e4:	6798                	ld	a4,8(a5)
        p->property = 0;
ffffffffc02009e6:	0007a823          	sw	zero,16(a5)
ffffffffc02009ea:	0007a023          	sw	zero,0(a5)
        ClearPageProperty(p);
ffffffffc02009ee:	9b75                	andi	a4,a4,-3
ffffffffc02009f0:	e798                	sd	a4,8(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc02009f2:	02878793          	addi	a5,a5,40
ffffffffc02009f6:	fed797e3          	bne	a5,a3,ffffffffc02009e4 <buddy_init_memmap+0x1e>
ffffffffc02009fa:	00004397          	auipc	t2,0x4
ffffffffc02009fe:	6ee38393          	addi	t2,t2,1774 # ffffffffc02050e8 <free_nr_pages>
ffffffffc0200a02:	0003bf03          	ld	t5,0(t2)
ffffffffc0200a06:	4681                	li	a3,0
ffffffffc0200a08:	00004f97          	auipc	t6,0x4
ffffffffc0200a0c:	610f8f93          	addi	t6,t6,1552 # ffffffffc0205018 <free_area>
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200a10:	4305                	li	t1,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200a12:	5e7d                	li	t3,-1
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200a14:	4ea9                	li	t4,10
    p->property = (1U << order);
ffffffffc0200a16:	4285                	li	t0,1
        size_t remain = n - idx;
ffffffffc0200a18:	40d588b3          	sub	a7,a1,a3
ffffffffc0200a1c:	4781                	li	a5,0
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200a1e:	0007881b          	sext.w	a6,a5
ffffffffc0200a22:	2785                	addiw	a5,a5,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200a24:	00fe1733          	sll	a4,t3,a5
ffffffffc0200a28:	fff74713          	not	a4,a4
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200a2c:	00f31633          	sll	a2,t1,a5
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200a30:	8f75                	and	a4,a4,a3
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200a32:	06c8e663          	bltu	a7,a2,ffffffffc0200a9e <buddy_init_memmap+0xd8>
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200a36:	e725                	bnez	a4,ffffffffc0200a9e <buddy_init_memmap+0xd8>
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200a38:	ffd793e3          	bne	a5,t4,ffffffffc0200a1e <buddy_init_memmap+0x58>
ffffffffc0200a3c:	40000413          	li	s0,1024
ffffffffc0200a40:	40000913          	li	s2,1024
ffffffffc0200a44:	0a000893          	li	a7,160
ffffffffc0200a48:	40000493          	li	s1,1024
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }
ffffffffc0200a4c:	00269713          	slli	a4,a3,0x2
ffffffffc0200a50:	9736                	add	a4,a4,a3
ffffffffc0200a52:	070e                	slli	a4,a4,0x3
ffffffffc0200a54:	972a                	add	a4,a4,a0
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a56:	02079813          	slli	a6,a5,0x20
    SetPageProperty(p);
ffffffffc0200a5a:	6710                	ld	a2,8(a4)
ffffffffc0200a5c:	01c85793          	srli	a5,a6,0x1c
ffffffffc0200a60:	97fe                	add	a5,a5,t6
ffffffffc0200a62:	0087b803          	ld	a6,8(a5)
ffffffffc0200a66:	00266613          	ori	a2,a2,2
ffffffffc0200a6a:	e710                	sd	a2,8(a4)
ffffffffc0200a6c:	00072023          	sw	zero,0(a4)
    p->property = (1U << order);
ffffffffc0200a70:	01272823          	sw	s2,16(a4)
    list_add(&free_area[order], &(p->page_link));
ffffffffc0200a74:	01870613          	addi	a2,a4,24
    prev->next = next->prev = elm;
ffffffffc0200a78:	00c83023          	sd	a2,0(a6)
ffffffffc0200a7c:	e790                	sd	a2,8(a5)
ffffffffc0200a7e:	011f87b3          	add	a5,t6,a7
    elm->next = next;
ffffffffc0200a82:	03073023          	sd	a6,32(a4)
    elm->prev = prev;
ffffffffc0200a86:	ef1c                	sd	a5,24(a4)
        idx += (1UL << o);//跳过刚放进去的这块，继续切下一段
ffffffffc0200a88:	96a6                	add	a3,a3,s1
    free_nr_pages += (1U << order);
ffffffffc0200a8a:	9f22                	add	t5,t5,s0
    while (idx < n) {
ffffffffc0200a8c:	f8b6e6e3          	bltu	a3,a1,ffffffffc0200a18 <buddy_init_memmap+0x52>
}
ffffffffc0200a90:	6462                	ld	s0,24(sp)
ffffffffc0200a92:	01e3b023          	sd	t5,0(t2)
ffffffffc0200a96:	64c2                	ld	s1,16(sp)
ffffffffc0200a98:	6922                	ld	s2,8(sp)
ffffffffc0200a9a:	6105                	addi	sp,sp,32
ffffffffc0200a9c:	8082                	ret
    p->property = (1U << order);
ffffffffc0200a9e:	0102943b          	sllw	s0,t0,a6
ffffffffc0200aa2:	02081793          	slli	a5,a6,0x20
ffffffffc0200aa6:	0004091b          	sext.w	s2,s0
    free_nr_pages += (1U << order);
ffffffffc0200aaa:	1402                	slli	s0,s0,0x20
ffffffffc0200aac:	01c7d893          	srli	a7,a5,0x1c
        idx += (1UL << o);//跳过刚放进去的这块，继续切下一段
ffffffffc0200ab0:	010314b3          	sll	s1,t1,a6
    free_nr_pages += (1U << order);
ffffffffc0200ab4:	9001                	srli	s0,s0,0x20
ffffffffc0200ab6:	87c2                	mv	a5,a6
ffffffffc0200ab8:	bf51                	j	ffffffffc0200a4c <buddy_init_memmap+0x86>
ffffffffc0200aba:	8082                	ret

ffffffffc0200abc <buddy_free_pages>:
    if (n == 0) return;
ffffffffc0200abc:	18058b63          	beqz	a1,ffffffffc0200c52 <buddy_free_pages+0x196>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200ac0:	7139                	addi	sp,sp,-64
ffffffffc0200ac2:	f04e                	sd	s3,32(sp)
ffffffffc0200ac4:	89ae                	mv	s3,a1
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200ac6:	00004597          	auipc	a1,0x4
ffffffffc0200aca:	61a5b583          	ld	a1,1562(a1) # ffffffffc02050e0 <buddy_base>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200ace:	f44a                	sd	s2,40(sp)
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200ad0:	40b50933          	sub	s2,a0,a1
ffffffffc0200ad4:	40395913          	srai	s2,s2,0x3
ffffffffc0200ad8:	00001517          	auipc	a0,0x1
ffffffffc0200adc:	3d053503          	ld	a0,976(a0) # ffffffffc0201ea8 <error_string+0x38>
ffffffffc0200ae0:	02a90933          	mul	s2,s2,a0
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200ae4:	e45a                	sd	s6,8(sp)
ffffffffc0200ae6:	00004b17          	auipc	s6,0x4
ffffffffc0200aea:	602b0b13          	addi	s6,s6,1538 # ffffffffc02050e8 <free_nr_pages>
ffffffffc0200aee:	000b3383          	ld	t2,0(s6)
ffffffffc0200af2:	fc22                	sd	s0,56(sp)
ffffffffc0200af4:	f826                	sd	s1,48(sp)
ffffffffc0200af6:	ec52                	sd	s4,24(sp)
ffffffffc0200af8:	e856                	sd	s5,16(sp)
ffffffffc0200afa:	e05e                	sd	s7,0(sp)
ffffffffc0200afc:	00004497          	auipc	s1,0x4
ffffffffc0200b00:	51c48493          	addi	s1,s1,1308 # ffffffffc0205018 <free_area>
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200b04:	4285                	li	t0,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b06:	5afd                	li	s5,-1
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200b08:	4429                	li	s0,10
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200b0a:	4a05                	li	s4,1
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200b0c:	4801                	li	a6,0
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200b0e:	00080f9b          	sext.w	t6,a6
ffffffffc0200b12:	2805                	addiw	a6,a6,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b14:	010a97b3          	sll	a5,s5,a6
ffffffffc0200b18:	fff7c793          	not	a5,a5
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200b1c:	01029733          	sll	a4,t0,a6
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b20:	0127f7b3          	and	a5,a5,s2
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200b24:	06e9ef63          	bltu	s3,a4,ffffffffc0200ba2 <buddy_free_pages+0xe6>
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b28:	efad                	bnez	a5,ffffffffc0200ba2 <buddy_free_pages+0xe6>
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200b2a:	fe8812e3          	bne	a6,s0,ffffffffc0200b0e <buddy_free_pages+0x52>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b2e:	0a84bb83          	ld	s7,168(s1)
ffffffffc0200b32:	8f4a                	mv	t5,s2
ffffffffc0200b34:	40000693          	li	a3,1024
ffffffffc0200b38:	00004717          	auipc	a4,0x4
ffffffffc0200b3c:	58070713          	addi	a4,a4,1408 # ffffffffc02050b8 <free_area+0xa0>
ffffffffc0200b40:	40000e13          	li	t3,1024
ffffffffc0200b44:	40000f93          	li	t6,1024
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }
ffffffffc0200b48:	002f1793          	slli	a5,t5,0x2
ffffffffc0200b4c:	97fa                	add	a5,a5,t5
ffffffffc0200b4e:	078e                	slli	a5,a5,0x3
ffffffffc0200b50:	97ae                	add	a5,a5,a1
    SetPageProperty(p);
ffffffffc0200b52:	6790                	ld	a2,8(a5)
    prev->next = next->prev = elm;
ffffffffc0200b54:	02081313          	slli	t1,a6,0x20
ffffffffc0200b58:	0007a023          	sw	zero,0(a5)
ffffffffc0200b5c:	00266613          	ori	a2,a2,2
ffffffffc0200b60:	e790                	sd	a2,8(a5)
    p->property = (1U << order);
ffffffffc0200b62:	01c7a823          	sw	t3,16(a5)
    list_add(&free_area[order], &(p->page_link));
ffffffffc0200b66:	01878893          	addi	a7,a5,24
ffffffffc0200b6a:	01c35613          	srli	a2,t1,0x1c
ffffffffc0200b6e:	011bb023          	sd	a7,0(s7)
ffffffffc0200b72:	9626                	add	a2,a2,s1
ffffffffc0200b74:	01163423          	sd	a7,8(a2)
    elm->next = next;
ffffffffc0200b78:	0377b023          	sd	s7,32(a5)
    elm->prev = prev;
ffffffffc0200b7c:	ef98                	sd	a4,24(a5)
        left -= (1UL << o); //left 也相应减去这次处理的片段大小
ffffffffc0200b7e:	41f989b3          	sub	s3,s3,t6
    free_nr_pages += (1U << order);
ffffffffc0200b82:	93b6                	add	t2,t2,a3
        idx  += (1UL << o); //继续往下推荐
ffffffffc0200b84:	997e                	add	s2,s2,t6
    while (left > 0) {
ffffffffc0200b86:	f80993e3          	bnez	s3,ffffffffc0200b0c <buddy_free_pages+0x50>
}
ffffffffc0200b8a:	7462                	ld	s0,56(sp)
ffffffffc0200b8c:	007b3023          	sd	t2,0(s6)
ffffffffc0200b90:	74c2                	ld	s1,48(sp)
ffffffffc0200b92:	7922                	ld	s2,40(sp)
ffffffffc0200b94:	7982                	ld	s3,32(sp)
ffffffffc0200b96:	6a62                	ld	s4,24(sp)
ffffffffc0200b98:	6ac2                	ld	s5,16(sp)
ffffffffc0200b9a:	6b22                	ld	s6,8(sp)
ffffffffc0200b9c:	6b82                	ld	s7,0(sp)
ffffffffc0200b9e:	6121                	addi	sp,sp,64
ffffffffc0200ba0:	8082                	ret
        while ((cur + 1) < BUDDY_MAX_ORDER) {
ffffffffc0200ba2:	020f9793          	slli	a5,t6,0x20
ffffffffc0200ba6:	01c7d613          	srli	a2,a5,0x1c
ffffffffc0200baa:	9626                	add	a2,a2,s1
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200bac:	8ec2                	mv	t4,a6
ffffffffc0200bae:	8f4a                	mv	t5,s2
ffffffffc0200bb0:	fffe881b          	addiw	a6,t4,-1
    return listelm->next;
ffffffffc0200bb4:	02081713          	slli	a4,a6,0x20
ffffffffc0200bb8:	01c75793          	srli	a5,a4,0x1c
ffffffffc0200bbc:	97a6                	add	a5,a5,s1
ffffffffc0200bbe:	0087bb83          	ld	s7,8(a5)
    return idx ^ (1UL << order);// 先把idx转成二进制之后，再按位异或运算翻转对应的对齐位，对称
ffffffffc0200bc2:	010296b3          	sll	a3,t0,a6
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200bc6:	010a133b          	sllw	t1,s4,a6
    return idx ^ (1UL << order);// 先把idx转成二进制之后，再按位异或运算翻转对应的对齐位，对称
ffffffffc0200bca:	01e6c6b3          	xor	a3,a3,t5
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200bce:	00030e1b          	sext.w	t3,t1
    while (cur != le) {
ffffffffc0200bd2:	07760963          	beq	a2,s7,ffffffffc0200c44 <buddy_free_pages+0x188>
ffffffffc0200bd6:	875e                	mv	a4,s7
ffffffffc0200bd8:	a021                	j	ffffffffc0200be0 <buddy_free_pages+0x124>
ffffffffc0200bda:	6718                	ld	a4,8(a4)
ffffffffc0200bdc:	04c70e63          	beq	a4,a2,ffffffffc0200c38 <buddy_free_pages+0x17c>
        struct Page *p = le2page(cur, page_link);
ffffffffc0200be0:	fe870793          	addi	a5,a4,-24
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200be4:	8f8d                	sub	a5,a5,a1
ffffffffc0200be6:	878d                	srai	a5,a5,0x3
ffffffffc0200be8:	02a787b3          	mul	a5,a5,a0
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200bec:	fef697e3          	bne	a3,a5,ffffffffc0200bda <buddy_free_pages+0x11e>
ffffffffc0200bf0:	ff073783          	ld	a5,-16(a4)
ffffffffc0200bf4:	0027f893          	andi	a7,a5,2
ffffffffc0200bf8:	fe0881e3          	beqz	a7,ffffffffc0200bda <buddy_free_pages+0x11e>
ffffffffc0200bfc:	ff872883          	lw	a7,-8(a4)
ffffffffc0200c00:	fdc89de3          	bne	a7,t3,ffffffffc0200bda <buddy_free_pages+0x11e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c04:	00073883          	ld	a7,0(a4)
ffffffffc0200c08:	00873803          	ld	a6,8(a4)
    ClearPageProperty(p);
ffffffffc0200c0c:	9bf5                	andi	a5,a5,-3
    free_nr_pages -= (1U << order);
ffffffffc0200c0e:	1302                	slli	t1,t1,0x20
    prev->next = next;
ffffffffc0200c10:	0108b423          	sd	a6,8(a7)
    next->prev = prev;
ffffffffc0200c14:	01183023          	sd	a7,0(a6)
ffffffffc0200c18:	02035313          	srli	t1,t1,0x20
    ClearPageProperty(p);
ffffffffc0200c1c:	fef73823          	sd	a5,-16(a4)
    free_nr_pages -= (1U << order);
ffffffffc0200c20:	406383b3          	sub	t2,t2,t1
            bidx = (bidx < other) ? bidx : other; //起点取更小的
ffffffffc0200c24:	01e6f363          	bgeu	a3,t5,ffffffffc0200c2a <buddy_free_pages+0x16e>
ffffffffc0200c28:	8f36                	mv	t5,a3
        while ((cur + 1) < BUDDY_MAX_ORDER) {
ffffffffc0200c2a:	001e879b          	addiw	a5,t4,1
ffffffffc0200c2e:	0641                	addi	a2,a2,16
ffffffffc0200c30:	02f46263          	bltu	s0,a5,ffffffffc0200c54 <buddy_free_pages+0x198>
ffffffffc0200c34:	8ebe                	mv	t4,a5
ffffffffc0200c36:	bfad                	j	ffffffffc0200bb0 <buddy_free_pages+0xf4>
    free_nr_pages += (1U << order);
ffffffffc0200c38:	020e1693          	slli	a3,t3,0x20
        idx  += (1UL << o); //继续往下推荐
ffffffffc0200c3c:	01f29fb3          	sll	t6,t0,t6
    free_nr_pages += (1U << order);
ffffffffc0200c40:	9281                	srli	a3,a3,0x20
ffffffffc0200c42:	b719                	j	ffffffffc0200b48 <buddy_free_pages+0x8c>
ffffffffc0200c44:	020e1693          	slli	a3,t3,0x20
        idx  += (1UL << o); //继续往下推荐
ffffffffc0200c48:	01f29fb3          	sll	t6,t0,t6
    free_nr_pages += (1U << order);
ffffffffc0200c4c:	9281                	srli	a3,a3,0x20
    return listelm->next;
ffffffffc0200c4e:	875e                	mv	a4,s7
ffffffffc0200c50:	bde5                	j	ffffffffc0200b48 <buddy_free_pages+0x8c>
ffffffffc0200c52:	8082                	ret
    list_add(&free_area[order], &(p->page_link));
ffffffffc0200c54:	020e9793          	slli	a5,t4,0x20
    p->property = (1U << order);
ffffffffc0200c58:	01da16bb          	sllw	a3,s4,t4
    list_add(&free_area[order], &(p->page_link));
ffffffffc0200c5c:	01c7d713          	srli	a4,a5,0x1c
ffffffffc0200c60:	9726                	add	a4,a4,s1
    p->property = (1U << order);
ffffffffc0200c62:	00068e1b          	sext.w	t3,a3
    free_nr_pages += (1U << order);
ffffffffc0200c66:	1682                	slli	a3,a3,0x20
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c68:	00873b83          	ld	s7,8(a4)
        idx  += (1UL << o); //继续往下推荐
ffffffffc0200c6c:	01f29fb3          	sll	t6,t0,t6
    free_nr_pages += (1U << order);
ffffffffc0200c70:	9281                	srli	a3,a3,0x20
ffffffffc0200c72:	8876                	mv	a6,t4
ffffffffc0200c74:	bdd1                	j	ffffffffc0200b48 <buddy_free_pages+0x8c>

ffffffffc0200c76 <pmm_init>:
static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    // 使用伙伴分配器
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c76:	00001797          	auipc	a5,0x1
ffffffffc0200c7a:	e6a78793          	addi	a5,a5,-406 # ffffffffc0201ae0 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c7e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200c80:	7179                	addi	sp,sp,-48
ffffffffc0200c82:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c84:	00001517          	auipc	a0,0x1
ffffffffc0200c88:	e9450513          	addi	a0,a0,-364 # ffffffffc0201b18 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c8c:	00004417          	auipc	s0,0x4
ffffffffc0200c90:	47440413          	addi	s0,s0,1140 # ffffffffc0205100 <pmm_manager>
void pmm_init(void) {
ffffffffc0200c94:	f406                	sd	ra,40(sp)
ffffffffc0200c96:	ec26                	sd	s1,24(sp)
ffffffffc0200c98:	e44e                	sd	s3,8(sp)
ffffffffc0200c9a:	e84a                	sd	s2,16(sp)
ffffffffc0200c9c:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c9e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ca0:	cacff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200ca4:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ca6:	00004497          	auipc	s1,0x4
ffffffffc0200caa:	47248493          	addi	s1,s1,1138 # ffffffffc0205118 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200cae:	679c                	ld	a5,8(a5)
ffffffffc0200cb0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200cb2:	57f5                	li	a5,-3
ffffffffc0200cb4:	07fa                	slli	a5,a5,0x1e
ffffffffc0200cb6:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200cb8:	905ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200cbc:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200cbe:	909ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200cc2:	14050d63          	beqz	a0,ffffffffc0200e1c <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200cc6:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200cc8:	00001517          	auipc	a0,0x1
ffffffffc0200ccc:	e9850513          	addi	a0,a0,-360 # ffffffffc0201b60 <buddy_pmm_manager+0x80>
ffffffffc0200cd0:	c7cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200cd4:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin, mem_end - 1);
ffffffffc0200cd8:	864e                	mv	a2,s3
ffffffffc0200cda:	fffa0693          	addi	a3,s4,-1
ffffffffc0200cde:	85ca                	mv	a1,s2
ffffffffc0200ce0:	00001517          	auipc	a0,0x1
ffffffffc0200ce4:	e9850513          	addi	a0,a0,-360 # ffffffffc0201b78 <buddy_pmm_manager+0x98>
ffffffffc0200ce8:	c64ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200cec:	c80007b7          	lui	a5,0xc8000
ffffffffc0200cf0:	8652                	mv	a2,s4
ffffffffc0200cf2:	0d47e463          	bltu	a5,s4,ffffffffc0200dba <pmm_init+0x144>
ffffffffc0200cf6:	00005797          	auipc	a5,0x5
ffffffffc0200cfa:	42978793          	addi	a5,a5,1065 # ffffffffc020611f <end+0xfff>
ffffffffc0200cfe:	757d                	lui	a0,0xfffff
ffffffffc0200d00:	8d7d                	and	a0,a0,a5
ffffffffc0200d02:	8231                	srli	a2,a2,0xc
ffffffffc0200d04:	00004797          	auipc	a5,0x4
ffffffffc0200d08:	3ec7b623          	sd	a2,1004(a5) # ffffffffc02050f0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200d0c:	00004797          	auipc	a5,0x4
ffffffffc0200d10:	3ea7b623          	sd	a0,1004(a5) # ffffffffc02050f8 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d14:	000807b7          	lui	a5,0x80
ffffffffc0200d18:	002005b7          	lui	a1,0x200
ffffffffc0200d1c:	02f60563          	beq	a2,a5,ffffffffc0200d46 <pmm_init+0xd0>
ffffffffc0200d20:	00261593          	slli	a1,a2,0x2
ffffffffc0200d24:	00c586b3          	add	a3,a1,a2
ffffffffc0200d28:	fec007b7          	lui	a5,0xfec00
ffffffffc0200d2c:	97aa                	add	a5,a5,a0
ffffffffc0200d2e:	068e                	slli	a3,a3,0x3
ffffffffc0200d30:	96be                	add	a3,a3,a5
ffffffffc0200d32:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200d34:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d36:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9faf08>
        SetPageReserved(pages + i);
ffffffffc0200d3a:	00176713          	ori	a4,a4,1
ffffffffc0200d3e:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d42:	fef699e3          	bne	a3,a5,ffffffffc0200d34 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d46:	95b2                	add	a1,a1,a2
ffffffffc0200d48:	fec006b7          	lui	a3,0xfec00
ffffffffc0200d4c:	96aa                	add	a3,a3,a0
ffffffffc0200d4e:	058e                	slli	a1,a1,0x3
ffffffffc0200d50:	96ae                	add	a3,a3,a1
ffffffffc0200d52:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d56:	0af6e763          	bltu	a3,a5,ffffffffc0200e04 <pmm_init+0x18e>
ffffffffc0200d5a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200d5c:	77fd                	lui	a5,0xfffff
ffffffffc0200d5e:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d62:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200d64:	04b6ee63          	bltu	a3,a1,ffffffffc0200dc0 <pmm_init+0x14a>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
            satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200d68:	601c                	ld	a5,0(s0)
ffffffffc0200d6a:	7b9c                	ld	a5,48(a5)
ffffffffc0200d6c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200d6e:	00001517          	auipc	a0,0x1
ffffffffc0200d72:	e9250513          	addi	a0,a0,-366 # ffffffffc0201c00 <buddy_pmm_manager+0x120>
ffffffffc0200d76:	bd6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200d7a:	00003597          	auipc	a1,0x3
ffffffffc0200d7e:	28658593          	addi	a1,a1,646 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200d82:	00004797          	auipc	a5,0x4
ffffffffc0200d86:	38b7b723          	sd	a1,910(a5) # ffffffffc0205110 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d8a:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d8e:	0af5e363          	bltu	a1,a5,ffffffffc0200e34 <pmm_init+0x1be>
ffffffffc0200d92:	6090                	ld	a2,0(s1)
}
ffffffffc0200d94:	7402                	ld	s0,32(sp)
ffffffffc0200d96:	70a2                	ld	ra,40(sp)
ffffffffc0200d98:	64e2                	ld	s1,24(sp)
ffffffffc0200d9a:	6942                	ld	s2,16(sp)
ffffffffc0200d9c:	69a2                	ld	s3,8(sp)
ffffffffc0200d9e:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200da0:	40c58633          	sub	a2,a1,a2
ffffffffc0200da4:	00004797          	auipc	a5,0x4
ffffffffc0200da8:	36c7b223          	sd	a2,868(a5) # ffffffffc0205108 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
ffffffffc0200dac:	00001517          	auipc	a0,0x1
ffffffffc0200db0:	e7450513          	addi	a0,a0,-396 # ffffffffc0201c20 <buddy_pmm_manager+0x140>
}
ffffffffc0200db4:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
ffffffffc0200db6:	b96ff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200dba:	c8000637          	lui	a2,0xc8000
ffffffffc0200dbe:	bf25                	j	ffffffffc0200cf6 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200dc0:	6705                	lui	a4,0x1
ffffffffc0200dc2:	177d                	addi	a4,a4,-1
ffffffffc0200dc4:	96ba                	add	a3,a3,a4
ffffffffc0200dc6:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200dc8:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200dcc:	02c7f063          	bgeu	a5,a2,ffffffffc0200dec <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0200dd0:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200dd2:	fff80737          	lui	a4,0xfff80
ffffffffc0200dd6:	973e                	add	a4,a4,a5
ffffffffc0200dd8:	00271793          	slli	a5,a4,0x2
ffffffffc0200ddc:	97ba                	add	a5,a5,a4
ffffffffc0200dde:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200de0:	8d95                	sub	a1,a1,a3
ffffffffc0200de2:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200de4:	81b1                	srli	a1,a1,0xc
ffffffffc0200de6:	953e                	add	a0,a0,a5
ffffffffc0200de8:	9702                	jalr	a4
}
ffffffffc0200dea:	bfbd                	j	ffffffffc0200d68 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200dec:	00001617          	auipc	a2,0x1
ffffffffc0200df0:	de460613          	addi	a2,a2,-540 # ffffffffc0201bd0 <buddy_pmm_manager+0xf0>
ffffffffc0200df4:	06a00593          	li	a1,106
ffffffffc0200df8:	00001517          	auipc	a0,0x1
ffffffffc0200dfc:	df850513          	addi	a0,a0,-520 # ffffffffc0201bf0 <buddy_pmm_manager+0x110>
ffffffffc0200e00:	bc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e04:	00001617          	auipc	a2,0x1
ffffffffc0200e08:	da460613          	addi	a2,a2,-604 # ffffffffc0201ba8 <buddy_pmm_manager+0xc8>
ffffffffc0200e0c:	05c00593          	li	a1,92
ffffffffc0200e10:	00001517          	auipc	a0,0x1
ffffffffc0200e14:	d4050513          	addi	a0,a0,-704 # ffffffffc0201b50 <buddy_pmm_manager+0x70>
ffffffffc0200e18:	baaff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200e1c:	00001617          	auipc	a2,0x1
ffffffffc0200e20:	d1460613          	addi	a2,a2,-748 # ffffffffc0201b30 <buddy_pmm_manager+0x50>
ffffffffc0200e24:	04600593          	li	a1,70
ffffffffc0200e28:	00001517          	auipc	a0,0x1
ffffffffc0200e2c:	d2850513          	addi	a0,a0,-728 # ffffffffc0201b50 <buddy_pmm_manager+0x70>
ffffffffc0200e30:	b92ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e34:	86ae                	mv	a3,a1
ffffffffc0200e36:	00001617          	auipc	a2,0x1
ffffffffc0200e3a:	d7260613          	addi	a2,a2,-654 # ffffffffc0201ba8 <buddy_pmm_manager+0xc8>
ffffffffc0200e3e:	07200593          	li	a1,114
ffffffffc0200e42:	00001517          	auipc	a0,0x1
ffffffffc0200e46:	d0e50513          	addi	a0,a0,-754 # ffffffffc0201b50 <buddy_pmm_manager+0x70>
ffffffffc0200e4a:	b78ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200e4e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0200e4e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200e52:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0200e54:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200e58:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200e5a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200e5e:	f022                	sd	s0,32(sp)
ffffffffc0200e60:	ec26                	sd	s1,24(sp)
ffffffffc0200e62:	e84a                	sd	s2,16(sp)
ffffffffc0200e64:	f406                	sd	ra,40(sp)
ffffffffc0200e66:	e44e                	sd	s3,8(sp)
ffffffffc0200e68:	84aa                	mv	s1,a0
ffffffffc0200e6a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0200e6c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0200e70:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0200e72:	03067e63          	bgeu	a2,a6,ffffffffc0200eae <printnum+0x60>
ffffffffc0200e76:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0200e78:	00805763          	blez	s0,ffffffffc0200e86 <printnum+0x38>
ffffffffc0200e7c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0200e7e:	85ca                	mv	a1,s2
ffffffffc0200e80:	854e                	mv	a0,s3
ffffffffc0200e82:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0200e84:	fc65                	bnez	s0,ffffffffc0200e7c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200e86:	1a02                	slli	s4,s4,0x20
ffffffffc0200e88:	00001797          	auipc	a5,0x1
ffffffffc0200e8c:	dd878793          	addi	a5,a5,-552 # ffffffffc0201c60 <buddy_pmm_manager+0x180>
ffffffffc0200e90:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200e94:	9a3e                	add	s4,s4,a5
}
ffffffffc0200e96:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200e98:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0200e9c:	70a2                	ld	ra,40(sp)
ffffffffc0200e9e:	69a2                	ld	s3,8(sp)
ffffffffc0200ea0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200ea2:	85ca                	mv	a1,s2
ffffffffc0200ea4:	87a6                	mv	a5,s1
}
ffffffffc0200ea6:	6942                	ld	s2,16(sp)
ffffffffc0200ea8:	64e2                	ld	s1,24(sp)
ffffffffc0200eaa:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200eac:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0200eae:	03065633          	divu	a2,a2,a6
ffffffffc0200eb2:	8722                	mv	a4,s0
ffffffffc0200eb4:	f9bff0ef          	jal	ra,ffffffffc0200e4e <printnum>
ffffffffc0200eb8:	b7f9                	j	ffffffffc0200e86 <printnum+0x38>

ffffffffc0200eba <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0200eba:	7119                	addi	sp,sp,-128
ffffffffc0200ebc:	f4a6                	sd	s1,104(sp)
ffffffffc0200ebe:	f0ca                	sd	s2,96(sp)
ffffffffc0200ec0:	ecce                	sd	s3,88(sp)
ffffffffc0200ec2:	e8d2                	sd	s4,80(sp)
ffffffffc0200ec4:	e4d6                	sd	s5,72(sp)
ffffffffc0200ec6:	e0da                	sd	s6,64(sp)
ffffffffc0200ec8:	fc5e                	sd	s7,56(sp)
ffffffffc0200eca:	f06a                	sd	s10,32(sp)
ffffffffc0200ecc:	fc86                	sd	ra,120(sp)
ffffffffc0200ece:	f8a2                	sd	s0,112(sp)
ffffffffc0200ed0:	f862                	sd	s8,48(sp)
ffffffffc0200ed2:	f466                	sd	s9,40(sp)
ffffffffc0200ed4:	ec6e                	sd	s11,24(sp)
ffffffffc0200ed6:	892a                	mv	s2,a0
ffffffffc0200ed8:	84ae                	mv	s1,a1
ffffffffc0200eda:	8d32                	mv	s10,a2
ffffffffc0200edc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200ede:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0200ee2:	5b7d                	li	s6,-1
ffffffffc0200ee4:	00001a97          	auipc	s5,0x1
ffffffffc0200ee8:	db0a8a93          	addi	s5,s5,-592 # ffffffffc0201c94 <buddy_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0200eec:	00001b97          	auipc	s7,0x1
ffffffffc0200ef0:	f84b8b93          	addi	s7,s7,-124 # ffffffffc0201e70 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200ef4:	000d4503          	lbu	a0,0(s10)
ffffffffc0200ef8:	001d0413          	addi	s0,s10,1
ffffffffc0200efc:	01350a63          	beq	a0,s3,ffffffffc0200f10 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0200f00:	c121                	beqz	a0,ffffffffc0200f40 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0200f02:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200f04:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0200f06:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200f08:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200f0c:	ff351ae3          	bne	a0,s3,ffffffffc0200f00 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f10:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0200f14:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0200f18:	4c81                	li	s9,0
ffffffffc0200f1a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0200f1c:	5c7d                	li	s8,-1
ffffffffc0200f1e:	5dfd                	li	s11,-1
ffffffffc0200f20:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0200f24:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f26:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0200f2a:	0ff5f593          	zext.b	a1,a1
ffffffffc0200f2e:	00140d13          	addi	s10,s0,1
ffffffffc0200f32:	04b56263          	bltu	a0,a1,ffffffffc0200f76 <vprintfmt+0xbc>
ffffffffc0200f36:	058a                	slli	a1,a1,0x2
ffffffffc0200f38:	95d6                	add	a1,a1,s5
ffffffffc0200f3a:	4194                	lw	a3,0(a1)
ffffffffc0200f3c:	96d6                	add	a3,a3,s5
ffffffffc0200f3e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0200f40:	70e6                	ld	ra,120(sp)
ffffffffc0200f42:	7446                	ld	s0,112(sp)
ffffffffc0200f44:	74a6                	ld	s1,104(sp)
ffffffffc0200f46:	7906                	ld	s2,96(sp)
ffffffffc0200f48:	69e6                	ld	s3,88(sp)
ffffffffc0200f4a:	6a46                	ld	s4,80(sp)
ffffffffc0200f4c:	6aa6                	ld	s5,72(sp)
ffffffffc0200f4e:	6b06                	ld	s6,64(sp)
ffffffffc0200f50:	7be2                	ld	s7,56(sp)
ffffffffc0200f52:	7c42                	ld	s8,48(sp)
ffffffffc0200f54:	7ca2                	ld	s9,40(sp)
ffffffffc0200f56:	7d02                	ld	s10,32(sp)
ffffffffc0200f58:	6de2                	ld	s11,24(sp)
ffffffffc0200f5a:	6109                	addi	sp,sp,128
ffffffffc0200f5c:	8082                	ret
            padc = '0';
ffffffffc0200f5e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0200f60:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f64:	846a                	mv	s0,s10
ffffffffc0200f66:	00140d13          	addi	s10,s0,1
ffffffffc0200f6a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0200f6e:	0ff5f593          	zext.b	a1,a1
ffffffffc0200f72:	fcb572e3          	bgeu	a0,a1,ffffffffc0200f36 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0200f76:	85a6                	mv	a1,s1
ffffffffc0200f78:	02500513          	li	a0,37
ffffffffc0200f7c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0200f7e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0200f82:	8d22                	mv	s10,s0
ffffffffc0200f84:	f73788e3          	beq	a5,s3,ffffffffc0200ef4 <vprintfmt+0x3a>
ffffffffc0200f88:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0200f8c:	1d7d                	addi	s10,s10,-1
ffffffffc0200f8e:	ff379de3          	bne	a5,s3,ffffffffc0200f88 <vprintfmt+0xce>
ffffffffc0200f92:	b78d                	j	ffffffffc0200ef4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0200f94:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0200f98:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f9c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0200f9e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0200fa2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0200fa6:	02d86463          	bltu	a6,a3,ffffffffc0200fce <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0200faa:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0200fae:	002c169b          	slliw	a3,s8,0x2
ffffffffc0200fb2:	0186873b          	addw	a4,a3,s8
ffffffffc0200fb6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200fba:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0200fbc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0200fc0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0200fc2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0200fc6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0200fca:	fed870e3          	bgeu	a6,a3,ffffffffc0200faa <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0200fce:	f40ddce3          	bgez	s11,ffffffffc0200f26 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0200fd2:	8de2                	mv	s11,s8
ffffffffc0200fd4:	5c7d                	li	s8,-1
ffffffffc0200fd6:	bf81                	j	ffffffffc0200f26 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0200fd8:	fffdc693          	not	a3,s11
ffffffffc0200fdc:	96fd                	srai	a3,a3,0x3f
ffffffffc0200fde:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200fe2:	00144603          	lbu	a2,1(s0)
ffffffffc0200fe6:	2d81                	sext.w	s11,s11
ffffffffc0200fe8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0200fea:	bf35                	j	ffffffffc0200f26 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0200fec:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200ff0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0200ff4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200ff6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0200ff8:	bfd9                	j	ffffffffc0200fce <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0200ffa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200ffc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201000:	01174463          	blt	a4,a7,ffffffffc0201008 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201004:	1a088e63          	beqz	a7,ffffffffc02011c0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201008:	000a3603          	ld	a2,0(s4)
ffffffffc020100c:	46c1                	li	a3,16
ffffffffc020100e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201010:	2781                	sext.w	a5,a5
ffffffffc0201012:	876e                	mv	a4,s11
ffffffffc0201014:	85a6                	mv	a1,s1
ffffffffc0201016:	854a                	mv	a0,s2
ffffffffc0201018:	e37ff0ef          	jal	ra,ffffffffc0200e4e <printnum>
            break;
ffffffffc020101c:	bde1                	j	ffffffffc0200ef4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020101e:	000a2503          	lw	a0,0(s4)
ffffffffc0201022:	85a6                	mv	a1,s1
ffffffffc0201024:	0a21                	addi	s4,s4,8
ffffffffc0201026:	9902                	jalr	s2
            break;
ffffffffc0201028:	b5f1                	j	ffffffffc0200ef4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020102a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020102c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201030:	01174463          	blt	a4,a7,ffffffffc0201038 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201034:	18088163          	beqz	a7,ffffffffc02011b6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201038:	000a3603          	ld	a2,0(s4)
ffffffffc020103c:	46a9                	li	a3,10
ffffffffc020103e:	8a2e                	mv	s4,a1
ffffffffc0201040:	bfc1                	j	ffffffffc0201010 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201042:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201046:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201048:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020104a:	bdf1                	j	ffffffffc0200f26 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020104c:	85a6                	mv	a1,s1
ffffffffc020104e:	02500513          	li	a0,37
ffffffffc0201052:	9902                	jalr	s2
            break;
ffffffffc0201054:	b545                	j	ffffffffc0200ef4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201056:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020105a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020105c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020105e:	b5e1                	j	ffffffffc0200f26 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201060:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201062:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201066:	01174463          	blt	a4,a7,ffffffffc020106e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020106a:	14088163          	beqz	a7,ffffffffc02011ac <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020106e:	000a3603          	ld	a2,0(s4)
ffffffffc0201072:	46a1                	li	a3,8
ffffffffc0201074:	8a2e                	mv	s4,a1
ffffffffc0201076:	bf69                	j	ffffffffc0201010 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201078:	03000513          	li	a0,48
ffffffffc020107c:	85a6                	mv	a1,s1
ffffffffc020107e:	e03e                	sd	a5,0(sp)
ffffffffc0201080:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201082:	85a6                	mv	a1,s1
ffffffffc0201084:	07800513          	li	a0,120
ffffffffc0201088:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020108a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020108c:	6782                	ld	a5,0(sp)
ffffffffc020108e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201090:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201094:	bfb5                	j	ffffffffc0201010 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201096:	000a3403          	ld	s0,0(s4)
ffffffffc020109a:	008a0713          	addi	a4,s4,8
ffffffffc020109e:	e03a                	sd	a4,0(sp)
ffffffffc02010a0:	14040263          	beqz	s0,ffffffffc02011e4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02010a4:	0fb05763          	blez	s11,ffffffffc0201192 <vprintfmt+0x2d8>
ffffffffc02010a8:	02d00693          	li	a3,45
ffffffffc02010ac:	0cd79163          	bne	a5,a3,ffffffffc020116e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02010b0:	00044783          	lbu	a5,0(s0)
ffffffffc02010b4:	0007851b          	sext.w	a0,a5
ffffffffc02010b8:	cf85                	beqz	a5,ffffffffc02010f0 <vprintfmt+0x236>
ffffffffc02010ba:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02010be:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02010c2:	000c4563          	bltz	s8,ffffffffc02010cc <vprintfmt+0x212>
ffffffffc02010c6:	3c7d                	addiw	s8,s8,-1
ffffffffc02010c8:	036c0263          	beq	s8,s6,ffffffffc02010ec <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02010cc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02010ce:	0e0c8e63          	beqz	s9,ffffffffc02011ca <vprintfmt+0x310>
ffffffffc02010d2:	3781                	addiw	a5,a5,-32
ffffffffc02010d4:	0ef47b63          	bgeu	s0,a5,ffffffffc02011ca <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02010d8:	03f00513          	li	a0,63
ffffffffc02010dc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02010de:	000a4783          	lbu	a5,0(s4)
ffffffffc02010e2:	3dfd                	addiw	s11,s11,-1
ffffffffc02010e4:	0a05                	addi	s4,s4,1
ffffffffc02010e6:	0007851b          	sext.w	a0,a5
ffffffffc02010ea:	ffe1                	bnez	a5,ffffffffc02010c2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02010ec:	01b05963          	blez	s11,ffffffffc02010fe <vprintfmt+0x244>
ffffffffc02010f0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02010f2:	85a6                	mv	a1,s1
ffffffffc02010f4:	02000513          	li	a0,32
ffffffffc02010f8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02010fa:	fe0d9be3          	bnez	s11,ffffffffc02010f0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02010fe:	6a02                	ld	s4,0(sp)
ffffffffc0201100:	bbd5                	j	ffffffffc0200ef4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201102:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201104:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201108:	01174463          	blt	a4,a7,ffffffffc0201110 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020110c:	08088d63          	beqz	a7,ffffffffc02011a6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201110:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201114:	0a044d63          	bltz	s0,ffffffffc02011ce <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201118:	8622                	mv	a2,s0
ffffffffc020111a:	8a66                	mv	s4,s9
ffffffffc020111c:	46a9                	li	a3,10
ffffffffc020111e:	bdcd                	j	ffffffffc0201010 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201120:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201124:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201126:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201128:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020112c:	8fb5                	xor	a5,a5,a3
ffffffffc020112e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201132:	02d74163          	blt	a4,a3,ffffffffc0201154 <vprintfmt+0x29a>
ffffffffc0201136:	00369793          	slli	a5,a3,0x3
ffffffffc020113a:	97de                	add	a5,a5,s7
ffffffffc020113c:	639c                	ld	a5,0(a5)
ffffffffc020113e:	cb99                	beqz	a5,ffffffffc0201154 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201140:	86be                	mv	a3,a5
ffffffffc0201142:	00001617          	auipc	a2,0x1
ffffffffc0201146:	b4e60613          	addi	a2,a2,-1202 # ffffffffc0201c90 <buddy_pmm_manager+0x1b0>
ffffffffc020114a:	85a6                	mv	a1,s1
ffffffffc020114c:	854a                	mv	a0,s2
ffffffffc020114e:	0ce000ef          	jal	ra,ffffffffc020121c <printfmt>
ffffffffc0201152:	b34d                	j	ffffffffc0200ef4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201154:	00001617          	auipc	a2,0x1
ffffffffc0201158:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0201c80 <buddy_pmm_manager+0x1a0>
ffffffffc020115c:	85a6                	mv	a1,s1
ffffffffc020115e:	854a                	mv	a0,s2
ffffffffc0201160:	0bc000ef          	jal	ra,ffffffffc020121c <printfmt>
ffffffffc0201164:	bb41                	j	ffffffffc0200ef4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201166:	00001417          	auipc	s0,0x1
ffffffffc020116a:	b1240413          	addi	s0,s0,-1262 # ffffffffc0201c78 <buddy_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020116e:	85e2                	mv	a1,s8
ffffffffc0201170:	8522                	mv	a0,s0
ffffffffc0201172:	e43e                	sd	a5,8(sp)
ffffffffc0201174:	0fc000ef          	jal	ra,ffffffffc0201270 <strnlen>
ffffffffc0201178:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020117c:	01b05b63          	blez	s11,ffffffffc0201192 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201180:	67a2                	ld	a5,8(sp)
ffffffffc0201182:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201186:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201188:	85a6                	mv	a1,s1
ffffffffc020118a:	8552                	mv	a0,s4
ffffffffc020118c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020118e:	fe0d9ce3          	bnez	s11,ffffffffc0201186 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201192:	00044783          	lbu	a5,0(s0)
ffffffffc0201196:	00140a13          	addi	s4,s0,1
ffffffffc020119a:	0007851b          	sext.w	a0,a5
ffffffffc020119e:	d3a5                	beqz	a5,ffffffffc02010fe <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02011a0:	05e00413          	li	s0,94
ffffffffc02011a4:	bf39                	j	ffffffffc02010c2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02011a6:	000a2403          	lw	s0,0(s4)
ffffffffc02011aa:	b7ad                	j	ffffffffc0201114 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02011ac:	000a6603          	lwu	a2,0(s4)
ffffffffc02011b0:	46a1                	li	a3,8
ffffffffc02011b2:	8a2e                	mv	s4,a1
ffffffffc02011b4:	bdb1                	j	ffffffffc0201010 <vprintfmt+0x156>
ffffffffc02011b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02011ba:	46a9                	li	a3,10
ffffffffc02011bc:	8a2e                	mv	s4,a1
ffffffffc02011be:	bd89                	j	ffffffffc0201010 <vprintfmt+0x156>
ffffffffc02011c0:	000a6603          	lwu	a2,0(s4)
ffffffffc02011c4:	46c1                	li	a3,16
ffffffffc02011c6:	8a2e                	mv	s4,a1
ffffffffc02011c8:	b5a1                	j	ffffffffc0201010 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02011ca:	9902                	jalr	s2
ffffffffc02011cc:	bf09                	j	ffffffffc02010de <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02011ce:	85a6                	mv	a1,s1
ffffffffc02011d0:	02d00513          	li	a0,45
ffffffffc02011d4:	e03e                	sd	a5,0(sp)
ffffffffc02011d6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02011d8:	6782                	ld	a5,0(sp)
ffffffffc02011da:	8a66                	mv	s4,s9
ffffffffc02011dc:	40800633          	neg	a2,s0
ffffffffc02011e0:	46a9                	li	a3,10
ffffffffc02011e2:	b53d                	j	ffffffffc0201010 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02011e4:	03b05163          	blez	s11,ffffffffc0201206 <vprintfmt+0x34c>
ffffffffc02011e8:	02d00693          	li	a3,45
ffffffffc02011ec:	f6d79de3          	bne	a5,a3,ffffffffc0201166 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02011f0:	00001417          	auipc	s0,0x1
ffffffffc02011f4:	a8840413          	addi	s0,s0,-1400 # ffffffffc0201c78 <buddy_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02011f8:	02800793          	li	a5,40
ffffffffc02011fc:	02800513          	li	a0,40
ffffffffc0201200:	00140a13          	addi	s4,s0,1
ffffffffc0201204:	bd6d                	j	ffffffffc02010be <vprintfmt+0x204>
ffffffffc0201206:	00001a17          	auipc	s4,0x1
ffffffffc020120a:	a73a0a13          	addi	s4,s4,-1421 # ffffffffc0201c79 <buddy_pmm_manager+0x199>
ffffffffc020120e:	02800513          	li	a0,40
ffffffffc0201212:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201216:	05e00413          	li	s0,94
ffffffffc020121a:	b565                	j	ffffffffc02010c2 <vprintfmt+0x208>

ffffffffc020121c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020121c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020121e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201222:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201224:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201226:	ec06                	sd	ra,24(sp)
ffffffffc0201228:	f83a                	sd	a4,48(sp)
ffffffffc020122a:	fc3e                	sd	a5,56(sp)
ffffffffc020122c:	e0c2                	sd	a6,64(sp)
ffffffffc020122e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201230:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201232:	c89ff0ef          	jal	ra,ffffffffc0200eba <vprintfmt>
}
ffffffffc0201236:	60e2                	ld	ra,24(sp)
ffffffffc0201238:	6161                	addi	sp,sp,80
ffffffffc020123a:	8082                	ret

ffffffffc020123c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020123c:	4781                	li	a5,0
ffffffffc020123e:	00004717          	auipc	a4,0x4
ffffffffc0201242:	dd273703          	ld	a4,-558(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201246:	88ba                	mv	a7,a4
ffffffffc0201248:	852a                	mv	a0,a0
ffffffffc020124a:	85be                	mv	a1,a5
ffffffffc020124c:	863e                	mv	a2,a5
ffffffffc020124e:	00000073          	ecall
ffffffffc0201252:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201254:	8082                	ret

ffffffffc0201256 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201256:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020125a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020125c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020125e:	cb81                	beqz	a5,ffffffffc020126e <strlen+0x18>
        cnt ++;
ffffffffc0201260:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201262:	00a707b3          	add	a5,a4,a0
ffffffffc0201266:	0007c783          	lbu	a5,0(a5)
ffffffffc020126a:	fbfd                	bnez	a5,ffffffffc0201260 <strlen+0xa>
ffffffffc020126c:	8082                	ret
    }
    return cnt;
}
ffffffffc020126e:	8082                	ret

ffffffffc0201270 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201270:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201272:	e589                	bnez	a1,ffffffffc020127c <strnlen+0xc>
ffffffffc0201274:	a811                	j	ffffffffc0201288 <strnlen+0x18>
        cnt ++;
ffffffffc0201276:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201278:	00f58863          	beq	a1,a5,ffffffffc0201288 <strnlen+0x18>
ffffffffc020127c:	00f50733          	add	a4,a0,a5
ffffffffc0201280:	00074703          	lbu	a4,0(a4)
ffffffffc0201284:	fb6d                	bnez	a4,ffffffffc0201276 <strnlen+0x6>
ffffffffc0201286:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201288:	852e                	mv	a0,a1
ffffffffc020128a:	8082                	ret

ffffffffc020128c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020128c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201290:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201294:	cb89                	beqz	a5,ffffffffc02012a6 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201296:	0505                	addi	a0,a0,1
ffffffffc0201298:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020129a:	fee789e3          	beq	a5,a4,ffffffffc020128c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020129e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02012a2:	9d19                	subw	a0,a0,a4
ffffffffc02012a4:	8082                	ret
ffffffffc02012a6:	4501                	li	a0,0
ffffffffc02012a8:	bfed                	j	ffffffffc02012a2 <strcmp+0x16>

ffffffffc02012aa <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012aa:	c20d                	beqz	a2,ffffffffc02012cc <strncmp+0x22>
ffffffffc02012ac:	962e                	add	a2,a2,a1
ffffffffc02012ae:	a031                	j	ffffffffc02012ba <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02012b0:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012b2:	00e79a63          	bne	a5,a4,ffffffffc02012c6 <strncmp+0x1c>
ffffffffc02012b6:	00b60b63          	beq	a2,a1,ffffffffc02012cc <strncmp+0x22>
ffffffffc02012ba:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02012be:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012c0:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02012c4:	f7f5                	bnez	a5,ffffffffc02012b0 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02012c6:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02012ca:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02012cc:	4501                	li	a0,0
ffffffffc02012ce:	8082                	ret

ffffffffc02012d0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02012d0:	ca01                	beqz	a2,ffffffffc02012e0 <memset+0x10>
ffffffffc02012d2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02012d4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02012d6:	0785                	addi	a5,a5,1
ffffffffc02012d8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02012dc:	fec79de3          	bne	a5,a2,ffffffffc02012d6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02012e0:	8082                	ret
