
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
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0203ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	29450513          	addi	a0,a0,660 # ffffffffc02012e0 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	29e50513          	addi	a0,a0,670 # ffffffffc0201300 <etext+0x24>
ffffffffc020006a:	0e0000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	26e58593          	addi	a1,a1,622 # ffffffffc02012dc <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	2aa50513          	addi	a0,a0,682 # ffffffffc0201320 <etext+0x44>
ffffffffc020007e:	0cc000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	2b650513          	addi	a0,a0,694 # ffffffffc0201340 <etext+0x64>
ffffffffc0200092:	0b8000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	08a58593          	addi	a1,a1,138 # ffffffffc0205120 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	2c250513          	addi	a0,a0,706 # ffffffffc0201360 <etext+0x84>
ffffffffc02000a6:	0a4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005797          	auipc	a5,0x5
ffffffffc02000ae:	47578793          	addi	a5,a5,1141 # ffffffffc020551f <end+0x3ff>
ffffffffc02000b2:	00000717          	auipc	a4,0x0
ffffffffc02000b6:	02470713          	addi	a4,a4,36 # ffffffffc02000d6 <kern_init>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	2b650513          	addi	a0,a0,694 # ffffffffc0201380 <etext+0xa4>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a89d                	j	ffffffffc020014a <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00005517          	auipc	a0,0x5
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0205018 <free_area>
ffffffffc02000de:	00005617          	auipc	a2,0x5
ffffffffc02000e2:	04260613          	addi	a2,a2,66 # ffffffffc0205120 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	1dc010ef          	jal	ffffffffc02012ca <memset>
    dtb_init();
ffffffffc02000f2:	13a000ef          	jal	ffffffffc020022c <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	12c000ef          	jal	ffffffffc0200222 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	bc650513          	addi	a0,a0,-1082 # ffffffffc0201cc0 <etext+0x9e4>
ffffffffc0200102:	07c000ef          	jal	ffffffffc020017e <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	34d000ef          	jal	ffffffffc0200c56 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1141                	addi	sp,sp,-16
ffffffffc0200112:	e022                	sd	s0,0(sp)
ffffffffc0200114:	e406                	sd	ra,8(sp)
ffffffffc0200116:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200118:	10c000ef          	jal	ffffffffc0200224 <cons_putc>
    (*cnt) ++;
ffffffffc020011c:	401c                	lw	a5,0(s0)
}
ffffffffc020011e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c01c                	sw	a5,0(s0)
}
ffffffffc0200124:	6402                	ld	s0,0(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012a:	1101                	addi	sp,sp,-32
ffffffffc020012c:	862a                	mv	a2,a0
ffffffffc020012e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200130:	00000517          	auipc	a0,0x0
ffffffffc0200134:	fe050513          	addi	a0,a0,-32 # ffffffffc0200110 <cputch>
ffffffffc0200138:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013a:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013c:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013e:	563000ef          	jal	ffffffffc0200ea0 <vprintfmt>
    return cnt;
}
ffffffffc0200142:	60e2                	ld	ra,24(sp)
ffffffffc0200144:	4532                	lw	a0,12(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret

ffffffffc020014a <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014c:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200150:	f42e                	sd	a1,40(sp)
ffffffffc0200152:	f832                	sd	a2,48(sp)
ffffffffc0200154:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200156:	862a                	mv	a2,a0
ffffffffc0200158:	004c                	addi	a1,sp,4
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb650513          	addi	a0,a0,-74 # ffffffffc0200110 <cputch>
ffffffffc0200162:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200164:	ec06                	sd	ra,24(sp)
ffffffffc0200166:	e0ba                	sd	a4,64(sp)
ffffffffc0200168:	e4be                	sd	a5,72(sp)
ffffffffc020016a:	e8c2                	sd	a6,80(sp)
ffffffffc020016c:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200170:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200172:	52f000ef          	jal	ffffffffc0200ea0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200176:	60e2                	ld	ra,24(sp)
ffffffffc0200178:	4512                	lw	a0,4(sp)
ffffffffc020017a:	6125                	addi	sp,sp,96
ffffffffc020017c:	8082                	ret

ffffffffc020017e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017e:	1101                	addi	sp,sp,-32
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	e822                	sd	s0,16(sp)
ffffffffc0200184:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200186:	00054503          	lbu	a0,0(a0)
ffffffffc020018a:	c905                	beqz	a0,ffffffffc02001ba <cputs+0x3c>
ffffffffc020018c:	e426                	sd	s1,8(sp)
ffffffffc020018e:	00178493          	addi	s1,a5,1
ffffffffc0200192:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200194:	090000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200198:	00044503          	lbu	a0,0(s0)
ffffffffc020019c:	87a2                	mv	a5,s0
ffffffffc020019e:	0405                	addi	s0,s0,1
ffffffffc02001a0:	f975                	bnez	a0,ffffffffc0200194 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a2:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc02001a4:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a6:	0027841b          	addiw	s0,a5,2
ffffffffc02001aa:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001ac:	078000ef          	jal	ffffffffc0200224 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
ffffffffc02001b2:	8522                	mv	a0,s0
ffffffffc02001b4:	6442                	ld	s0,16(sp)
ffffffffc02001b6:	6105                	addi	sp,sp,32
ffffffffc02001b8:	8082                	ret
    cons_putc(c);
ffffffffc02001ba:	4529                	li	a0,10
ffffffffc02001bc:	068000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001cc:	00005317          	auipc	t1,0x5
ffffffffc02001d0:	efc30313          	addi	t1,t1,-260 # ffffffffc02050c8 <is_panic>
ffffffffc02001d4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d8:	715d                	addi	sp,sp,-80
ffffffffc02001da:	ec06                	sd	ra,24(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x20>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x1e>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	e822                	sd	s0,16(sp)
ffffffffc02001f4:	103c                	addi	a5,sp,40
ffffffffc02001f6:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	862e                	mv	a2,a1
ffffffffc02001fa:	85aa                	mv	a1,a0
ffffffffc02001fc:	00001517          	auipc	a0,0x1
ffffffffc0200200:	1b450513          	addi	a0,a0,436 # ffffffffc02013b0 <etext+0xd4>
    va_start(ap, fmt);
ffffffffc0200204:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200206:	f45ff0ef          	jal	ffffffffc020014a <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020a:	65a2                	ld	a1,8(sp)
ffffffffc020020c:	8522                	mv	a0,s0
ffffffffc020020e:	f1dff0ef          	jal	ffffffffc020012a <vcprintf>
    cprintf("\n");
ffffffffc0200212:	00001517          	auipc	a0,0x1
ffffffffc0200216:	1be50513          	addi	a0,a0,446 # ffffffffc02013d0 <etext+0xf4>
ffffffffc020021a:	f31ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc020021e:	6442                	ld	s0,16(sp)
ffffffffc0200220:	b7e9                	j	ffffffffc02001ea <__panic+0x1e>

ffffffffc0200222 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200222:	8082                	ret

ffffffffc0200224 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200224:	0ff57513          	zext.b	a0,a0
ffffffffc0200228:	7f30006f          	j	ffffffffc020121a <sbi_console_putchar>

ffffffffc020022c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020022c:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020022e:	00001517          	auipc	a0,0x1
ffffffffc0200232:	1aa50513          	addi	a0,a0,426 # ffffffffc02013d8 <etext+0xfc>
void dtb_init(void) {
ffffffffc0200236:	ec86                	sd	ra,88(sp)
ffffffffc0200238:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f11ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00005597          	auipc	a1,0x5
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200246:	00001517          	auipc	a0,0x1
ffffffffc020024a:	1a250513          	addi	a0,a0,418 # ffffffffc02013e8 <etext+0x10c>
ffffffffc020024e:	efdff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00005417          	auipc	s0,0x5
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0205008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00001517          	auipc	a0,0x1
ffffffffc0200260:	19c50513          	addi	a0,a0,412 # ffffffffc02013f8 <etext+0x11c>
ffffffffc0200264:	ee7ff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026a:	00001517          	auipc	a0,0x1
ffffffffc020026e:	1a650513          	addi	a0,a0,422 # ffffffffc0201410 <etext+0x134>
    if (boot_dtb == 0) {
ffffffffc0200272:	12070d63          	beqz	a4,ffffffffc02003ac <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200276:	57f5                	li	a5,-3
ffffffffc0200278:	07fa                	slli	a5,a5,0x1e
ffffffffc020027a:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020027c:	431c                	lw	a5,0(a4)
ffffffffc020027e:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200280:	00ff0637          	lui	a2,0xff0
ffffffffc0200284:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200288:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028c:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200290:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200294:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200298:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029c:	8ec9                	or	a3,a3,a0
ffffffffc020029e:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002a2:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02002a4:	0157f7b3          	and	a5,a5,s5
ffffffffc02002a8:	8dd5                	or	a1,a1,a3
ffffffffc02002aa:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002ac:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002b2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedadcd>
ffffffffc02002b6:	0ef59f63          	bne	a1,a5,ffffffffc02003b4 <dtb_init+0x188>
ffffffffc02002ba:	471c                	lw	a5,8(a4)
ffffffffc02002bc:	4754                	lw	a3,12(a4)
ffffffffc02002be:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c0:	0087d99b          	srliw	s3,a5,0x8
ffffffffc02002c4:	0086d41b          	srliw	s0,a3,0x8
ffffffffc02002c8:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002cc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d0:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d4:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002dc:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e0:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e4:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e8:	8c71                	and	s0,s0,a2
ffffffffc02002ea:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	01156533          	or	a0,a0,a7
ffffffffc02002f2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002f6:	0105e633          	or	a2,a1,a6
ffffffffc02002fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002fe:	8c49                	or	s0,s0,a0
ffffffffc0200300:	0156f6b3          	and	a3,a3,s5
ffffffffc0200304:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200308:	0157f7b3          	and	a5,a5,s5
ffffffffc020030c:	8c55                	or	s0,s0,a3
ffffffffc020030e:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200318:	0209d993          	srli	s3,s3,0x20
ffffffffc020031c:	e4a6                	sd	s1,72(sp)
ffffffffc020031e:	e0ca                	sd	s2,64(sp)
ffffffffc0200320:	ec5e                	sd	s7,24(sp)
ffffffffc0200322:	e862                	sd	s8,16(sp)
ffffffffc0200324:	e466                	sd	s9,8(sp)
ffffffffc0200326:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc020032a:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032e:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200330:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200334:	4c0d                	li	s8,3
ffffffffc0200336:	4911                	li	s2,4
ffffffffc0200338:	4d05                	li	s10,1
ffffffffc020033a:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033c:	0009a703          	lw	a4,0(s3)
ffffffffc0200340:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200344:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200348:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200350:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200354:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200358:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200362:	8fd5                	or	a5,a5,a3
ffffffffc0200364:	00eaf733          	and	a4,s5,a4
ffffffffc0200368:	8fd9                	or	a5,a5,a4
ffffffffc020036a:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020036c:	09878263          	beq	a5,s8,ffffffffc02003f0 <dtb_init+0x1c4>
ffffffffc0200370:	00fc6963          	bltu	s8,a5,ffffffffc0200382 <dtb_init+0x156>
ffffffffc0200374:	05a78963          	beq	a5,s10,ffffffffc02003c6 <dtb_init+0x19a>
ffffffffc0200378:	00979763          	bne	a5,s1,ffffffffc0200386 <dtb_init+0x15a>
ffffffffc020037c:	4b81                	li	s7,0
ffffffffc020037e:	89d2                	mv	s3,s4
ffffffffc0200380:	bf75                	j	ffffffffc020033c <dtb_init+0x110>
ffffffffc0200382:	ff278ee3          	beq	a5,s2,ffffffffc020037e <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200386:	00001517          	auipc	a0,0x1
ffffffffc020038a:	15250513          	addi	a0,a0,338 # ffffffffc02014d8 <etext+0x1fc>
ffffffffc020038e:	dbdff0ef          	jal	ffffffffc020014a <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200392:	64a6                	ld	s1,72(sp)
ffffffffc0200394:	6906                	ld	s2,64(sp)
ffffffffc0200396:	79e2                	ld	s3,56(sp)
ffffffffc0200398:	7a42                	ld	s4,48(sp)
ffffffffc020039a:	7aa2                	ld	s5,40(sp)
ffffffffc020039c:	6be2                	ld	s7,24(sp)
ffffffffc020039e:	6c42                	ld	s8,16(sp)
ffffffffc02003a0:	6ca2                	ld	s9,8(sp)
ffffffffc02003a2:	6d02                	ld	s10,0(sp)
ffffffffc02003a4:	00001517          	auipc	a0,0x1
ffffffffc02003a8:	16c50513          	addi	a0,a0,364 # ffffffffc0201510 <etext+0x234>
}
ffffffffc02003ac:	6446                	ld	s0,80(sp)
ffffffffc02003ae:	60e6                	ld	ra,88(sp)
ffffffffc02003b0:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc02003b2:	bb61                	j	ffffffffc020014a <cprintf>
}
ffffffffc02003b4:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003b6:	7aa2                	ld	s5,40(sp)
}
ffffffffc02003b8:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003ba:	00001517          	auipc	a0,0x1
ffffffffc02003be:	07650513          	addi	a0,a0,118 # ffffffffc0201430 <etext+0x154>
}
ffffffffc02003c2:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003c4:	b359                	j	ffffffffc020014a <cprintf>
                int name_len = strlen(name);
ffffffffc02003c6:	8552                	mv	a0,s4
ffffffffc02003c8:	66d000ef          	jal	ffffffffc0201234 <strlen>
ffffffffc02003cc:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ce:	4619                	li	a2,6
ffffffffc02003d0:	00001597          	auipc	a1,0x1
ffffffffc02003d4:	08858593          	addi	a1,a1,136 # ffffffffc0201458 <etext+0x17c>
ffffffffc02003d8:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc02003da:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003dc:	6c7000ef          	jal	ffffffffc02012a2 <strncmp>
ffffffffc02003e0:	e111                	bnez	a0,ffffffffc02003e4 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc02003e2:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e4:	0a11                	addi	s4,s4,4
ffffffffc02003e6:	9a4e                	add	s4,s4,s3
ffffffffc02003e8:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc02003ec:	89d2                	mv	s3,s4
ffffffffc02003ee:	b7b9                	j	ffffffffc020033c <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f0:	0049a783          	lw	a5,4(s3)
ffffffffc02003f4:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003fa:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02003fe:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200402:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200406:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020040e:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200412:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200416:	0087979b          	slliw	a5,a5,0x8
ffffffffc020041a:	00eb6b33          	or	s6,s6,a4
ffffffffc020041e:	00faf7b3          	and	a5,s5,a5
ffffffffc0200422:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200426:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042a:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042c:	000b9c63          	bnez	s7,ffffffffc0200444 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200430:	1b02                	slli	s6,s6,0x20
ffffffffc0200432:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200436:	0a0d                	addi	s4,s4,3
ffffffffc0200438:	9a5a                	add	s4,s4,s6
ffffffffc020043a:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020043e:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc0200440:	89d2                	mv	s3,s4
ffffffffc0200442:	bded                	j	ffffffffc020033c <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200444:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200448:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020044c:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200450:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200454:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200458:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045c:	8fd9                	or	a5,a5,a4
ffffffffc020045e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200462:	8d5d                	or	a0,a0,a5
ffffffffc0200464:	00daf6b3          	and	a3,s5,a3
ffffffffc0200468:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020046a:	1502                	slli	a0,a0,0x20
ffffffffc020046c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020046e:	00001597          	auipc	a1,0x1
ffffffffc0200472:	ff258593          	addi	a1,a1,-14 # ffffffffc0201460 <etext+0x184>
ffffffffc0200476:	9522                	add	a0,a0,s0
ffffffffc0200478:	5f3000ef          	jal	ffffffffc020126a <strcmp>
ffffffffc020047c:	f955                	bnez	a0,ffffffffc0200430 <dtb_init+0x204>
ffffffffc020047e:	47bd                	li	a5,15
ffffffffc0200480:	fb67f8e3          	bgeu	a5,s6,ffffffffc0200430 <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200484:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200488:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020048c:	00001517          	auipc	a0,0x1
ffffffffc0200490:	fdc50513          	addi	a0,a0,-36 # ffffffffc0201468 <etext+0x18c>
           fdt32_to_cpu(x >> 32);
ffffffffc0200494:	4207d693          	srai	a3,a5,0x20
ffffffffc0200498:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049c:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02004a0:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02004a4:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02004a8:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ac:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02004b0:	0087541b          	srliw	s0,a4,0x8
ffffffffc02004b4:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004bc:	01869e1b          	slliw	t3,a3,0x18
ffffffffc02004c0:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0188189b          	slliw	a7,a6,0x18
ffffffffc02004cc:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d4:	0108581b          	srliw	a6,a6,0x10
ffffffffc02004d8:	005e6e33          	or	t3,t3,t0
ffffffffc02004dc:	01e8e8b3          	or	a7,a7,t5
ffffffffc02004e0:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e4:	0104949b          	slliw	s1,s1,0x10
ffffffffc02004e8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	0086969b          	slliw	a3,a3,0x8
ffffffffc02004f8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	00daf6b3          	and	a3,s5,a3
ffffffffc0200504:	007eeeb3          	or	t4,t4,t2
ffffffffc0200508:	01f36333          	or	t1,t1,t6
ffffffffc020050c:	01c7e7b3          	or	a5,a5,t3
ffffffffc0200510:	00caf633          	and	a2,s5,a2
ffffffffc0200514:	01176733          	or	a4,a4,a7
ffffffffc0200518:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051c:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200520:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	01d4e4b3          	or	s1,s1,t4
ffffffffc020052c:	00646433          	or	s0,s0,t1
ffffffffc0200530:	8fd5                	or	a5,a5,a3
ffffffffc0200532:	01576733          	or	a4,a4,s5
ffffffffc0200536:	8c51                	or	s0,s0,a2
ffffffffc0200538:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc020053a:	1782                	slli	a5,a5,0x20
ffffffffc020053c:	1702                	slli	a4,a4,0x20
ffffffffc020053e:	9381                	srli	a5,a5,0x20
ffffffffc0200540:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200542:	1482                	slli	s1,s1,0x20
ffffffffc0200544:	1402                	slli	s0,s0,0x20
ffffffffc0200546:	8cdd                	or	s1,s1,a5
ffffffffc0200548:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020054a:	c01ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020054e:	85a6                	mv	a1,s1
ffffffffc0200550:	00001517          	auipc	a0,0x1
ffffffffc0200554:	f3850513          	addi	a0,a0,-200 # ffffffffc0201488 <etext+0x1ac>
ffffffffc0200558:	bf3ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020055c:	01445613          	srli	a2,s0,0x14
ffffffffc0200560:	85a2                	mv	a1,s0
ffffffffc0200562:	00001517          	auipc	a0,0x1
ffffffffc0200566:	f3e50513          	addi	a0,a0,-194 # ffffffffc02014a0 <etext+0x1c4>
ffffffffc020056a:	be1ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020056e:	009405b3          	add	a1,s0,s1
ffffffffc0200572:	15fd                	addi	a1,a1,-1
ffffffffc0200574:	00001517          	auipc	a0,0x1
ffffffffc0200578:	f4c50513          	addi	a0,a0,-180 # ffffffffc02014c0 <etext+0x1e4>
ffffffffc020057c:	bcfff0ef          	jal	ffffffffc020014a <cprintf>
        memory_base = mem_base;
ffffffffc0200580:	7b02                	ld	s6,32(sp)
ffffffffc0200582:	00005797          	auipc	a5,0x5
ffffffffc0200586:	b497bb23          	sd	s1,-1194(a5) # ffffffffc02050d8 <memory_base>
        memory_size = mem_size;
ffffffffc020058a:	00005797          	auipc	a5,0x5
ffffffffc020058e:	b487b323          	sd	s0,-1210(a5) # ffffffffc02050d0 <memory_size>
ffffffffc0200592:	b501                	j	ffffffffc0200392 <dtb_init+0x166>

ffffffffc0200594 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200594:	00005517          	auipc	a0,0x5
ffffffffc0200598:	b4453503          	ld	a0,-1212(a0) # ffffffffc02050d8 <memory_base>
ffffffffc020059c:	8082                	ret

ffffffffc020059e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020059e:	00005517          	auipc	a0,0x5
ffffffffc02005a2:	b3253503          	ld	a0,-1230(a0) # ffffffffc02050d0 <memory_size>
ffffffffc02005a6:	8082                	ret

ffffffffc02005a8 <buddy_init>:
// 当前总空闲页
static inline size_t nrfree(void) { return free_nr_pages; }

//重置初始化
static void buddy_init(void) {
    for (int i = 0; i < BUDDY_MAX_ORDER; i++) {
ffffffffc02005a8:	00005797          	auipc	a5,0x5
ffffffffc02005ac:	a7078793          	addi	a5,a5,-1424 # ffffffffc0205018 <free_area>
ffffffffc02005b0:	00005717          	auipc	a4,0x5
ffffffffc02005b4:	b1870713          	addi	a4,a4,-1256 # ffffffffc02050c8 <is_panic>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005b8:	e79c                	sd	a5,8(a5)
ffffffffc02005ba:	e39c                	sd	a5,0(a5)
ffffffffc02005bc:	07c1                	addi	a5,a5,16
ffffffffc02005be:	fee79de3          	bne	a5,a4,ffffffffc02005b8 <buddy_init+0x10>
        list_init(&free_area[i]);
    }
    free_nr_pages = 0;
ffffffffc02005c2:	00005797          	auipc	a5,0x5
ffffffffc02005c6:	b207b323          	sd	zero,-1242(a5) # ffffffffc02050e8 <free_nr_pages>
    buddy_base = NULL;
ffffffffc02005ca:	00005797          	auipc	a5,0x5
ffffffffc02005ce:	b007bb23          	sd	zero,-1258(a5) # ffffffffc02050e0 <buddy_base>
    buddy_npages = 0;
}
ffffffffc02005d2:	8082                	ret

ffffffffc02005d4 <buddy_alloc_pages>:
        idx += (1UL << o);//跳过刚放进去的这块，继续切下一段
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0) return NULL;
ffffffffc02005d4:	12050863          	beqz	a0,ffffffffc0200704 <buddy_alloc_pages+0x130>
    while (s < n) { s <<= 1; o++; }
ffffffffc02005d8:	4785                	li	a5,1
    unsigned o = 0; size_t s = 1;
ffffffffc02005da:	4581                	li	a1,0
    while (s < n) { s <<= 1; o++; }
ffffffffc02005dc:	00f50963          	beq	a0,a5,ffffffffc02005ee <buddy_alloc_pages+0x1a>
ffffffffc02005e0:	0786                	slli	a5,a5,0x1
ffffffffc02005e2:	2585                	addiw	a1,a1,1
ffffffffc02005e4:	fea7eee3          	bltu	a5,a0,ffffffffc02005e0 <buddy_alloc_pages+0xc>
    unsigned need = ceil_order(n);
    if (need >= BUDDY_MAX_ORDER) return NULL;  // 需求超过最大支持
ffffffffc02005e8:	47a9                	li	a5,10
ffffffffc02005ea:	10b7ed63          	bltu	a5,a1,ffffffffc0200704 <buddy_alloc_pages+0x130>
ffffffffc02005ee:	02059713          	slli	a4,a1,0x20
ffffffffc02005f2:	01c75793          	srli	a5,a4,0x1c
ffffffffc02005f6:	00005817          	auipc	a6,0x5
ffffffffc02005fa:	a2280813          	addi	a6,a6,-1502 # ffffffffc0205018 <free_area>
ffffffffc02005fe:	97c2                	add	a5,a5,a6

    // 从 need 阶开始向上找一个非空阶
    unsigned o = need;
ffffffffc0200600:	872e                	mv	a4,a1
    while (o < BUDDY_MAX_ORDER && list_empty(&free_area[o])) o++;// 先看“正好阶”的空闲链表有没有块；没有就去更大的阶找
ffffffffc0200602:	462d                	li	a2,11
ffffffffc0200604:	a029                	j	ffffffffc020060e <buddy_alloc_pages+0x3a>
ffffffffc0200606:	2705                	addiw	a4,a4,1
ffffffffc0200608:	07c1                	addi	a5,a5,16
ffffffffc020060a:	0ec70d63          	beq	a4,a2,ffffffffc0200704 <buddy_alloc_pages+0x130>
ffffffffc020060e:	6794                	ld	a3,8(a5)
ffffffffc0200610:	fef68be3          	beq	a3,a5,ffffffffc0200606 <buddy_alloc_pages+0x32>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200614:	02071693          	slli	a3,a4,0x20
ffffffffc0200618:	01c6d793          	srli	a5,a3,0x1c
ffffffffc020061c:	97c2                	add	a5,a5,a6
ffffffffc020061e:	0087bf03          	ld	t5,8(a5)
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200622:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200626:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac7bad>
    __list_del(listelm->prev, listelm->next);
ffffffffc020062a:	000f3f83          	ld	t6,0(t5)
ffffffffc020062e:	008f3883          	ld	a7,8(t5)
    free_nr_pages -= (1U << order);
ffffffffc0200632:	00005397          	auipc	t2,0x5
ffffffffc0200636:	ab638393          	addi	t2,t2,-1354 # ffffffffc02050e8 <free_nr_pages>
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc020063a:	07b2                	slli	a5,a5,0xc
    free_nr_pages -= (1U << order);
ffffffffc020063c:	4605                	li	a2,1
    ClearPageProperty(p);
ffffffffc020063e:	ff0f3683          	ld	a3,-16(t5)
    free_nr_pages -= (1U << order);
ffffffffc0200642:	0003b303          	ld	t1,0(t2)
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200646:	ccd78793          	addi	a5,a5,-819
    free_nr_pages -= (1U << order);
ffffffffc020064a:	00e6163b          	sllw	a2,a2,a4
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc020064e:	07b2                	slli	a5,a5,0xc
    free_nr_pages -= (1U << order);
ffffffffc0200650:	1602                	slli	a2,a2,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200652:	011fb423          	sd	a7,8(t6)
    if (o >= BUDDY_MAX_ORDER) return NULL;     // 无可用块

    // 取一个阶为 o 的块
    list_entry_t *le = list_next(&free_area[o]);
    struct Page *p = le2page(le, page_link);//取出块头页
ffffffffc0200656:	fe8f0513          	addi	a0,t5,-24
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc020065a:	00005e97          	auipc	t4,0x5
ffffffffc020065e:	a86ebe83          	ld	t4,-1402(t4) # ffffffffc02050e0 <buddy_base>
ffffffffc0200662:	ccd78793          	addi	a5,a5,-819
    free_nr_pages -= (1U << order);
ffffffffc0200666:	9201                	srli	a2,a2,0x20
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200668:	41d50e33          	sub	t3,a0,t4
ffffffffc020066c:	07b2                	slli	a5,a5,0xc
    next->prev = prev;
ffffffffc020066e:	01f8b023          	sd	t6,0(a7)
    ClearPageProperty(p);
ffffffffc0200672:	9af5                	andi	a3,a3,-3
    free_nr_pages -= (1U << order);
ffffffffc0200674:	40c30333          	sub	t1,t1,a2
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200678:	403e5e13          	srai	t3,t3,0x3
ffffffffc020067c:	ccd78793          	addi	a5,a5,-819
    ClearPageProperty(p);
ffffffffc0200680:	fedf3823          	sd	a3,-16(t5)
    free_nr_pages -= (1U << order);
ffffffffc0200684:	0063b023          	sd	t1,0(t2)
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200688:	02fe0e33          	mul	t3,t3,a5
    size_t idx = page_idx(p);//计算块头页的索引
    del_block(o, p);

    // 自顶向下拆分，右半块放回更低阶，左半块继续拆
    while (o > need) {
ffffffffc020068c:	06e5f563          	bgeu	a1,a4,ffffffffc02006f6 <buddy_alloc_pages+0x122>
ffffffffc0200690:	377d                	addiw	a4,a4,-1
ffffffffc0200692:	02071793          	slli	a5,a4,0x20
ffffffffc0200696:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020069a:	96c2                	add	a3,a3,a6
        o--;
        size_t right_idx = idx + (1UL << o);
ffffffffc020069c:	4285                	li	t0,1
    p->property = (1U << order);
ffffffffc020069e:	4f85                	li	t6,1
ffffffffc02006a0:	a011                	j	ffffffffc02006a4 <buddy_alloc_pages+0xd0>
ffffffffc02006a2:	377d                	addiw	a4,a4,-1
        size_t right_idx = idx + (1UL << o);
ffffffffc02006a4:	00e29633          	sll	a2,t0,a4
ffffffffc02006a8:	9672                	add	a2,a2,t3
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }
ffffffffc02006aa:	00261793          	slli	a5,a2,0x2
ffffffffc02006ae:	97b2                	add	a5,a5,a2
ffffffffc02006b0:	078e                	slli	a5,a5,0x3
ffffffffc02006b2:	97f6                	add	a5,a5,t4
    SetPageProperty(p);
ffffffffc02006b4:	0087b803          	ld	a6,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc02006b8:	0086b883          	ld	a7,8(a3)
    p->property = (1U << order);
ffffffffc02006bc:	00ef963b          	sllw	a2,t6,a4
    SetPageProperty(p);
ffffffffc02006c0:	00286813          	ori	a6,a6,2
    p->property = (1U << order);
ffffffffc02006c4:	cb90                	sw	a2,16(a5)
    SetPageProperty(p);
ffffffffc02006c6:	0107b423          	sd	a6,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02006ca:	0007a023          	sw	zero,0(a5)
    list_add(&free_area[order], &(p->page_link));
ffffffffc02006ce:	01878813          	addi	a6,a5,24
    prev->next = next->prev = elm;
ffffffffc02006d2:	0108b023          	sd	a6,0(a7)
ffffffffc02006d6:	0106b423          	sd	a6,8(a3)
    free_nr_pages += (1U << order);
ffffffffc02006da:	1602                	slli	a2,a2,0x20
    elm->prev = prev;
ffffffffc02006dc:	ef94                	sd	a3,24(a5)
ffffffffc02006de:	9201                	srli	a2,a2,0x20
    elm->next = next;
ffffffffc02006e0:	0317b023          	sd	a7,32(a5)
ffffffffc02006e4:	9332                	add	t1,t1,a2
    while (o > need) {
ffffffffc02006e6:	16c1                	addi	a3,a3,-16
ffffffffc02006e8:	fae59de3          	bne	a1,a4,ffffffffc02006a2 <buddy_alloc_pages+0xce>
        // 左半块（idx 不变）继续下一轮
    }

    // 返回左半块：分配出去的头页不保留 PageProperty
    struct Page *ret = page_at(idx);
    ClearPageProperty(ret);
ffffffffc02006ec:	ff0f3683          	ld	a3,-16(t5)
ffffffffc02006f0:	0063b023          	sd	t1,0(t2)
ffffffffc02006f4:	9af5                	andi	a3,a3,-3
ffffffffc02006f6:	fedf3823          	sd	a3,-16(t5)
    ret->property = 0;
ffffffffc02006fa:	fe0f2c23          	sw	zero,-8(t5)
ffffffffc02006fe:	fe0f2423          	sw	zero,-24(t5)
    set_page_ref(ret, 0);
    return ret;
ffffffffc0200702:	8082                	ret
    if (n == 0) return NULL;
ffffffffc0200704:	4501                	li	a0,0
}
ffffffffc0200706:	8082                	ret

ffffffffc0200708 <buddy_nr_free_pages>:
    }
}

static size_t buddy_nr_free_pages(void) {
    return free_nr_pages;
}
ffffffffc0200708:	00005517          	auipc	a0,0x5
ffffffffc020070c:	9e053503          	ld	a0,-1568(a0) # ffffffffc02050e8 <free_nr_pages>
ffffffffc0200710:	8082                	ret

ffffffffc0200712 <buddy_check>:

static void buddy_check(void) {
ffffffffc0200712:	1101                	addi	sp,sp,-32
    #define POW2(o) (1u << (o))

    cprintf("\n[buddy] 1024 页示范\n");
ffffffffc0200714:	00001517          	auipc	a0,0x1
ffffffffc0200718:	e1450513          	addi	a0,a0,-492 # ffffffffc0201528 <etext+0x24c>
static void buddy_check(void) {
ffffffffc020071c:	ec06                	sd	ra,24(sp)
    cprintf("\n[buddy] 1024 页示范\n");
ffffffffc020071e:	a2dff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("[buddy] 初始：一个大块 [0,1024) (order=%u, 大小=%u)\n\n", 10u, 1024u);
ffffffffc0200722:	40000613          	li	a2,1024
ffffffffc0200726:	45a9                	li	a1,10
ffffffffc0200728:	00001517          	auipc	a0,0x1
ffffffffc020072c:	e2050513          	addi	a0,a0,-480 # ffffffffc0201548 <etext+0x26c>
ffffffffc0200730:	a1bff0ef          	jal	ffffffffc020014a <cprintf>
    struct demo { const char* name; unsigned req, ord, size, st, ed; } A,B,C,D,E,F;

    // A: 32
    A.name="A"; A.req=32u;  A.ord=ceil_order(A.req); A.size=POW2(A.ord);
    A.st=0u; A.ed=A.st+A.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u)\n",
ffffffffc0200734:	02000813          	li	a6,32
ffffffffc0200738:	4781                	li	a5,0
ffffffffc020073a:	4715                	li	a4,5
ffffffffc020073c:	02000693          	li	a3,32
ffffffffc0200740:	02000613          	li	a2,32
ffffffffc0200744:	00001597          	auipc	a1,0x1
ffffffffc0200748:	e4458593          	addi	a1,a1,-444 # ffffffffc0201588 <etext+0x2ac>
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	e4450513          	addi	a0,a0,-444 # ffffffffc0201590 <etext+0x2b4>
ffffffffc0200754:	9f7ff0ef          	jal	ffffffffc020014a <cprintf>
            A.name, A.req, A.size, A.ord, A.st, A.ed);

    // B: 64  —— 直接用 64..128
    B.name="B"; B.req=64u;  B.ord=ceil_order(B.req); B.size=POW2(B.ord);
    B.st=64u; B.ed=B.st+B.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u)\n",
ffffffffc0200758:	08000813          	li	a6,128
ffffffffc020075c:	04000793          	li	a5,64
ffffffffc0200760:	4719                	li	a4,6
ffffffffc0200762:	04000693          	li	a3,64
ffffffffc0200766:	04000613          	li	a2,64
ffffffffc020076a:	00001597          	auipc	a1,0x1
ffffffffc020076e:	e6658593          	addi	a1,a1,-410 # ffffffffc02015d0 <etext+0x2f4>
ffffffffc0200772:	00001517          	auipc	a0,0x1
ffffffffc0200776:	e1e50513          	addi	a0,a0,-482 # ffffffffc0201590 <etext+0x2b4>
ffffffffc020077a:	9d1ff0ef          	jal	ffffffffc020014a <cprintf>
            B.name, B.req, B.size, B.ord, B.st, B.ed);

    // C: 60 -> 向上取 64，用 128..192
    C.name="C"; C.req=60u;  C.ord=ceil_order(C.req); C.size=POW2(C.ord);
    C.st=128u; C.ed=C.st+C.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：60 向上取 64\n",
ffffffffc020077e:	0c000813          	li	a6,192
ffffffffc0200782:	08000793          	li	a5,128
ffffffffc0200786:	4719                	li	a4,6
ffffffffc0200788:	04000693          	li	a3,64
ffffffffc020078c:	03c00613          	li	a2,60
ffffffffc0200790:	00001597          	auipc	a1,0x1
ffffffffc0200794:	e4858593          	addi	a1,a1,-440 # ffffffffc02015d8 <etext+0x2fc>
ffffffffc0200798:	00001517          	auipc	a0,0x1
ffffffffc020079c:	e4850513          	addi	a0,a0,-440 # ffffffffc02015e0 <etext+0x304>
ffffffffc02007a0:	9abff0ef          	jal	ffffffffc020014a <cprintf>
            C.name, C.req, C.size, C.ord, C.st, C.ed);

    // D: 150 -> 向上取 256，用 256..512
    D.name="D"; D.req=150u; D.ord=ceil_order(D.req); D.size=POW2(D.ord);
    D.st=256u; D.ed=D.st+D.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：150 向上取 256\n\n",
ffffffffc02007a4:	20000813          	li	a6,512
ffffffffc02007a8:	10000793          	li	a5,256
ffffffffc02007ac:	4721                	li	a4,8
ffffffffc02007ae:	10000693          	li	a3,256
ffffffffc02007b2:	09600613          	li	a2,150
ffffffffc02007b6:	00001597          	auipc	a1,0x1
ffffffffc02007ba:	e8a58593          	addi	a1,a1,-374 # ffffffffc0201640 <etext+0x364>
ffffffffc02007be:	00001517          	auipc	a0,0x1
ffffffffc02007c2:	e8a50513          	addi	a0,a0,-374 # ffffffffc0201648 <etext+0x36c>
ffffffffc02007c6:	985ff0ef          	jal	ffffffffc020014a <cprintf>
            D.name, D.req, D.size, D.ord, D.st, D.ed);

    // 释放 B
    cprintf("[buddy] 释放 %s：区间 [%u,%u)\n", B.name, B.st, B.ed);
ffffffffc02007ca:	08000693          	li	a3,128
ffffffffc02007ce:	04000613          	li	a2,64
ffffffffc02007d2:	00001597          	auipc	a1,0x1
ffffffffc02007d6:	dfe58593          	addi	a1,a1,-514 # ffffffffc02015d0 <etext+0x2f4>
ffffffffc02007da:	00001517          	auipc	a0,0x1
ffffffffc02007de:	ece50513          	addi	a0,a0,-306 # ffffffffc02016a8 <etext+0x3cc>
ffffffffc02007e2:	969ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("        检查伙伴：%s(order=%u) 的伙伴是 [0,64) —— 因 %s 占用 [0,32)，暂不能合并\n",
ffffffffc02007e6:	00001697          	auipc	a3,0x1
ffffffffc02007ea:	da268693          	addi	a3,a3,-606 # ffffffffc0201588 <etext+0x2ac>
ffffffffc02007ee:	4619                	li	a2,6
ffffffffc02007f0:	00001597          	auipc	a1,0x1
ffffffffc02007f4:	de058593          	addi	a1,a1,-544 # ffffffffc02015d0 <etext+0x2f4>
ffffffffc02007f8:	00001517          	auipc	a0,0x1
ffffffffc02007fc:	ed850513          	addi	a0,a0,-296 # ffffffffc02016d0 <etext+0x3f4>
ffffffffc0200800:	94bff0ef          	jal	ffffffffc020014a <cprintf>
            B.name, B.ord, A.name);

    // 释放 A：先与 [32,64) 合并 -> [0,64)，再与 B 的 [64,128) 合并 -> [0,128)
    cprintf("[buddy] 释放 %s：区间 [%u,%u)\n", A.name, A.st, A.ed);
ffffffffc0200804:	02000693          	li	a3,32
ffffffffc0200808:	4601                	li	a2,0
ffffffffc020080a:	00001597          	auipc	a1,0x1
ffffffffc020080e:	d7e58593          	addi	a1,a1,-642 # ffffffffc0201588 <etext+0x2ac>
ffffffffc0200812:	00001517          	auipc	a0,0x1
ffffffffc0200816:	e9650513          	addi	a0,a0,-362 # ffffffffc02016a8 <etext+0x3cc>
ffffffffc020081a:	931ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("        先与 [32,64) 合并 -> [0,64)；再与 %s 的 [64,128) 合并 -> [0,128)\n\n", B.name);
ffffffffc020081e:	00001597          	auipc	a1,0x1
ffffffffc0200822:	db258593          	addi	a1,a1,-590 # ffffffffc02015d0 <etext+0x2f4>
ffffffffc0200826:	00001517          	auipc	a0,0x1
ffffffffc020082a:	f1250513          	addi	a0,a0,-238 # ffffffffc0201738 <etext+0x45c>
ffffffffc020082e:	91dff0ef          	jal	ffffffffc020014a <cprintf>

    // E: 100 -> 128，用刚合并出的 [0,128)
    E.name="E"; E.req=100u; E.ord=ceil_order(E.req); E.size=POW2(E.ord);
    E.st=0u; E.ed=E.st+E.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：100 向上取 128，使用 [0,128)\n",
ffffffffc0200832:	08000813          	li	a6,128
ffffffffc0200836:	4781                	li	a5,0
ffffffffc0200838:	471d                	li	a4,7
ffffffffc020083a:	08000693          	li	a3,128
ffffffffc020083e:	06400613          	li	a2,100
ffffffffc0200842:	00001597          	auipc	a1,0x1
ffffffffc0200846:	f4e58593          	addi	a1,a1,-178 # ffffffffc0201790 <etext+0x4b4>
ffffffffc020084a:	00001517          	auipc	a0,0x1
ffffffffc020084e:	f4e50513          	addi	a0,a0,-178 # ffffffffc0201798 <etext+0x4bc>
ffffffffc0200852:	8f9ff0ef          	jal	ffffffffc020014a <cprintf>
            E.name, E.req, E.size, E.ord, E.st, E.ed);

    // F: 100 -> 128，从右侧 512..1024 拆出 128，得到 512..640
    F.name="F"; F.req=100u; F.ord=ceil_order(F.req); F.size=POW2(F.ord);
    F.st=512u; F.ed=F.st+F.size;
    cprintf("[buddy] %s 请求 %u -> 分配 %u (order=%u)，区间 [%u,%u) ；说明：从右侧 512..1024 拆出 128\n\n",
ffffffffc0200856:	28000813          	li	a6,640
ffffffffc020085a:	20000793          	li	a5,512
ffffffffc020085e:	471d                	li	a4,7
ffffffffc0200860:	08000693          	li	a3,128
ffffffffc0200864:	06400613          	li	a2,100
ffffffffc0200868:	00001597          	auipc	a1,0x1
ffffffffc020086c:	fa058593          	addi	a1,a1,-96 # ffffffffc0201808 <etext+0x52c>
ffffffffc0200870:	00001517          	auipc	a0,0x1
ffffffffc0200874:	fa050513          	addi	a0,a0,-96 # ffffffffc0201810 <etext+0x534>
ffffffffc0200878:	8d3ff0ef          	jal	ffffffffc020014a <cprintf>
    // 内部碎片
    unsigned waste =
        (A.size-A.req) + (B.size-B.req) + (C.size-C.req) +
        (D.size-D.req) + (E.size-E.req) + (F.size-F.req);

    cprintf("[buddy] 内部碎片：\n");
ffffffffc020087c:	00001517          	auipc	a0,0x1
ffffffffc0200880:	00450513          	addi	a0,a0,4 # ffffffffc0201880 <etext+0x5a4>
ffffffffc0200884:	8c7ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("        A:%u->%u(+%u), B:%u->%u(+%u), C:%u->%u(+%u)\n",
ffffffffc0200888:	4791                	li	a5,4
ffffffffc020088a:	e43e                	sd	a5,8(sp)
ffffffffc020088c:	04000793          	li	a5,64
ffffffffc0200890:	e03e                	sd	a5,0(sp)
ffffffffc0200892:	03c00893          	li	a7,60
ffffffffc0200896:	4801                	li	a6,0
ffffffffc0200898:	04000713          	li	a4,64
ffffffffc020089c:	4681                	li	a3,0
ffffffffc020089e:	02000613          	li	a2,32
ffffffffc02008a2:	02000593          	li	a1,32
ffffffffc02008a6:	00001517          	auipc	a0,0x1
ffffffffc02008aa:	ffa50513          	addi	a0,a0,-6 # ffffffffc02018a0 <etext+0x5c4>
ffffffffc02008ae:	89dff0ef          	jal	ffffffffc020014a <cprintf>
        A.req,A.size,(A.size-A.req), B.req,B.size,(B.size-B.req), C.req,C.size,(C.size-C.req));
    cprintf("        D:%u->%u(+%u), E:%u->%u(+%u), F:%u->%u(+%u)\n",
ffffffffc02008b2:	47f1                	li	a5,28
ffffffffc02008b4:	e43e                	sd	a5,8(sp)
ffffffffc02008b6:	08000793          	li	a5,128
ffffffffc02008ba:	e03e                	sd	a5,0(sp)
ffffffffc02008bc:	06400893          	li	a7,100
ffffffffc02008c0:	4871                	li	a6,28
ffffffffc02008c2:	06400713          	li	a4,100
ffffffffc02008c6:	06a00693          	li	a3,106
ffffffffc02008ca:	10000613          	li	a2,256
ffffffffc02008ce:	09600593          	li	a1,150
ffffffffc02008d2:	00001517          	auipc	a0,0x1
ffffffffc02008d6:	00650513          	addi	a0,a0,6 # ffffffffc02018d8 <etext+0x5fc>
ffffffffc02008da:	871ff0ef          	jal	ffffffffc020014a <cprintf>
        D.req,D.size,(D.size-D.req), E.req,E.size,(E.size-E.req), F.req,F.size,(F.size-F.req));
    cprintf("        总内部碎片: %u 页\n\n", waste);
ffffffffc02008de:	0a600593          	li	a1,166
ffffffffc02008e2:	00001517          	auipc	a0,0x1
ffffffffc02008e6:	02e50513          	addi	a0,a0,46 # ffffffffc0201910 <etext+0x634>
ffffffffc02008ea:	861ff0ef          	jal	ffffffffc020014a <cprintf>

    // 汇总
    cprintf("[buddy] 最终区间总结（单位：页）\n");
ffffffffc02008ee:	00001517          	auipc	a0,0x1
ffffffffc02008f2:	04a50513          	addi	a0,a0,74 # ffffffffc0201938 <etext+0x65c>
ffffffffc02008f6:	855ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  A: [%4u,%4u)  请求=%3u 实分=%3u\n", A.st,A.ed,A.req,A.size);
ffffffffc02008fa:	02000713          	li	a4,32
ffffffffc02008fe:	02000693          	li	a3,32
ffffffffc0200902:	02000613          	li	a2,32
ffffffffc0200906:	4581                	li	a1,0
ffffffffc0200908:	00001517          	auipc	a0,0x1
ffffffffc020090c:	06050513          	addi	a0,a0,96 # ffffffffc0201968 <etext+0x68c>
ffffffffc0200910:	83bff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  B: [%4u,%4u)  请求=%3u 实分=%3u   （随后释放）\n", B.st,B.ed,B.req,B.size);
ffffffffc0200914:	04000713          	li	a4,64
ffffffffc0200918:	04000693          	li	a3,64
ffffffffc020091c:	08000613          	li	a2,128
ffffffffc0200920:	04000593          	li	a1,64
ffffffffc0200924:	00001517          	auipc	a0,0x1
ffffffffc0200928:	06c50513          	addi	a0,a0,108 # ffffffffc0201990 <etext+0x6b4>
ffffffffc020092c:	81fff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  C: [%4u,%4u)  请求=%3u 实分=%3u\n", C.st,C.ed,C.req,C.size);
ffffffffc0200930:	04000713          	li	a4,64
ffffffffc0200934:	03c00693          	li	a3,60
ffffffffc0200938:	0c000613          	li	a2,192
ffffffffc020093c:	08000593          	li	a1,128
ffffffffc0200940:	00001517          	auipc	a0,0x1
ffffffffc0200944:	09050513          	addi	a0,a0,144 # ffffffffc02019d0 <etext+0x6f4>
ffffffffc0200948:	803ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  D: [%4u,%4u)  请求=%3u 实分=%3u\n", D.st,D.ed,D.req,D.size);
ffffffffc020094c:	10000713          	li	a4,256
ffffffffc0200950:	09600693          	li	a3,150
ffffffffc0200954:	20000613          	li	a2,512
ffffffffc0200958:	10000593          	li	a1,256
ffffffffc020095c:	00001517          	auipc	a0,0x1
ffffffffc0200960:	09c50513          	addi	a0,a0,156 # ffffffffc02019f8 <etext+0x71c>
ffffffffc0200964:	fe6ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  E: [%4u,%4u)  请求=%3u 实分=%3u\n", E.st,E.ed,E.req,E.size);
ffffffffc0200968:	08000713          	li	a4,128
ffffffffc020096c:	06400693          	li	a3,100
ffffffffc0200970:	08000613          	li	a2,128
ffffffffc0200974:	4581                	li	a1,0
ffffffffc0200976:	00001517          	auipc	a0,0x1
ffffffffc020097a:	0aa50513          	addi	a0,a0,170 # ffffffffc0201a20 <etext+0x744>
ffffffffc020097e:	fccff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  F: [%4u,%4u)  请求=%3u 实分=%3u\n", F.st,F.ed,F.req,F.size);
ffffffffc0200982:	08000713          	li	a4,128
ffffffffc0200986:	06400693          	li	a3,100
ffffffffc020098a:	28000613          	li	a2,640
ffffffffc020098e:	20000593          	li	a1,512
ffffffffc0200992:	00001517          	auipc	a0,0x1
ffffffffc0200996:	0b650513          	addi	a0,a0,182 # ffffffffc0201a48 <etext+0x76c>
ffffffffc020099a:	fb0ff0ef          	jal	ffffffffc020014a <cprintf>

    cprintf("\n[buddy] 结论: 正确，与预期相同\n");
}
ffffffffc020099e:	60e2                	ld	ra,24(sp)
    cprintf("\n[buddy] 结论: 正确，与预期相同\n");
ffffffffc02009a0:	00001517          	auipc	a0,0x1
ffffffffc02009a4:	0d050513          	addi	a0,a0,208 # ffffffffc0201a70 <etext+0x794>
}
ffffffffc02009a8:	6105                	addi	sp,sp,32
    cprintf("\n[buddy] 结论: 正确，与预期相同\n");
ffffffffc02009aa:	fa0ff06f          	j	ffffffffc020014a <cprintf>

ffffffffc02009ae <buddy_init_memmap>:
    buddy_base   = base;
ffffffffc02009ae:	00004797          	auipc	a5,0x4
ffffffffc02009b2:	72a7b923          	sd	a0,1842(a5) # ffffffffc02050e0 <buddy_base>
    for (size_t i = 0; i < n; i++) {
ffffffffc02009b6:	c9e5                	beqz	a1,ffffffffc0200aa6 <buddy_init_memmap+0xf8>
ffffffffc02009b8:	00259693          	slli	a3,a1,0x2
ffffffffc02009bc:	96ae                	add	a3,a3,a1
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02009be:	1101                	addi	sp,sp,-32
ffffffffc02009c0:	068e                	slli	a3,a3,0x3
ffffffffc02009c2:	ec22                	sd	s0,24(sp)
ffffffffc02009c4:	e826                	sd	s1,16(sp)
ffffffffc02009c6:	e44a                	sd	s2,8(sp)
ffffffffc02009c8:	e04e                	sd	s3,0(sp)
ffffffffc02009ca:	87aa                	mv	a5,a0
ffffffffc02009cc:	96aa                	add	a3,a3,a0
        ClearPageProperty(p);
ffffffffc02009ce:	6798                	ld	a4,8(a5)
        p->property = 0;
ffffffffc02009d0:	0007a823          	sw	zero,16(a5)
ffffffffc02009d4:	0007a023          	sw	zero,0(a5)
        ClearPageProperty(p);
ffffffffc02009d8:	9b75                	andi	a4,a4,-3
ffffffffc02009da:	e798                	sd	a4,8(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc02009dc:	02878793          	addi	a5,a5,40
ffffffffc02009e0:	fef697e3          	bne	a3,a5,ffffffffc02009ce <buddy_init_memmap+0x20>
ffffffffc02009e4:	00004417          	auipc	s0,0x4
ffffffffc02009e8:	70440413          	addi	s0,s0,1796 # ffffffffc02050e8 <free_nr_pages>
ffffffffc02009ec:	00043f03          	ld	t5,0(s0)
    size_t idx = 0;
ffffffffc02009f0:	4681                	li	a3,0
ffffffffc02009f2:	00004f97          	auipc	t6,0x4
ffffffffc02009f6:	626f8f93          	addi	t6,t6,1574 # ffffffffc0205018 <free_area>
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc02009fa:	4ead                	li	t4,11
        && ((1UL << (o + 1)) <= remain)
ffffffffc02009fc:	4e05                	li	t3,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc02009fe:	537d                	li	t1,-1
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200a00:	4385                	li	t2,1
    p->property = (1U << order);
ffffffffc0200a02:	4285                	li	t0,1
        size_t remain = n - idx;
ffffffffc0200a04:	40d588b3          	sub	a7,a1,a3
    unsigned o = 0;
ffffffffc0200a08:	4781                	li	a5,0
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200a0a:	a021                	j	ffffffffc0200a12 <buddy_init_memmap+0x64>
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200a0c:	06c8ef63          	bltu	a7,a2,ffffffffc0200a8a <buddy_init_memmap+0xdc>
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200a10:	ef2d                	bnez	a4,ffffffffc0200a8a <buddy_init_memmap+0xdc>
ffffffffc0200a12:	0007881b          	sext.w	a6,a5
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200a16:	2785                	addiw	a5,a5,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200a18:	00f31733          	sll	a4,t1,a5
ffffffffc0200a1c:	fff74713          	not	a4,a4
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200a20:	00fe1633          	sll	a2,t3,a5
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200a24:	8f75                	and	a4,a4,a3
ffffffffc0200a26:	ffd793e3          	bne	a5,t4,ffffffffc0200a0c <buddy_init_memmap+0x5e>
ffffffffc0200a2a:	40000493          	li	s1,1024
ffffffffc0200a2e:	40000993          	li	s3,1024
ffffffffc0200a32:	0a000893          	li	a7,160
ffffffffc0200a36:	40000813          	li	a6,1024
ffffffffc0200a3a:	4729                	li	a4,10
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }
ffffffffc0200a3c:	00269793          	slli	a5,a3,0x2
ffffffffc0200a40:	97b6                	add	a5,a5,a3
ffffffffc0200a42:	078e                	slli	a5,a5,0x3
ffffffffc0200a44:	97aa                	add	a5,a5,a0
    SetPageProperty(p);
ffffffffc0200a46:	6790                	ld	a2,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a48:	0712                	slli	a4,a4,0x4
ffffffffc0200a4a:	977e                	add	a4,a4,t6
ffffffffc0200a4c:	00873903          	ld	s2,8(a4)
ffffffffc0200a50:	00266613          	ori	a2,a2,2
ffffffffc0200a54:	e790                	sd	a2,8(a5)
ffffffffc0200a56:	0007a023          	sw	zero,0(a5)
    p->property = (1U << order);
ffffffffc0200a5a:	0137a823          	sw	s3,16(a5)
    list_add(&free_area[order], &(p->page_link));
ffffffffc0200a5e:	01878613          	addi	a2,a5,24
    prev->next = next->prev = elm;
ffffffffc0200a62:	00c93023          	sd	a2,0(s2)
ffffffffc0200a66:	e710                	sd	a2,8(a4)
ffffffffc0200a68:	011f8733          	add	a4,t6,a7
    elm->next = next;
ffffffffc0200a6c:	0327b023          	sd	s2,32(a5)
    elm->prev = prev;
ffffffffc0200a70:	ef98                	sd	a4,24(a5)
        idx += (1UL << o);//跳过刚放进去的这块，继续切下一段
ffffffffc0200a72:	96c2                	add	a3,a3,a6
    free_nr_pages += (1U << order);
ffffffffc0200a74:	9f26                	add	t5,t5,s1
    while (idx < n) {
ffffffffc0200a76:	f8b6e7e3          	bltu	a3,a1,ffffffffc0200a04 <buddy_init_memmap+0x56>
ffffffffc0200a7a:	01e43023          	sd	t5,0(s0)
}
ffffffffc0200a7e:	6462                	ld	s0,24(sp)
ffffffffc0200a80:	64c2                	ld	s1,16(sp)
ffffffffc0200a82:	6922                	ld	s2,8(sp)
ffffffffc0200a84:	6982                	ld	s3,0(sp)
ffffffffc0200a86:	6105                	addi	sp,sp,32
ffffffffc0200a88:	8082                	ret
    p->property = (1U << order);
ffffffffc0200a8a:	010294bb          	sllw	s1,t0,a6
ffffffffc0200a8e:	02081713          	slli	a4,a6,0x20
ffffffffc0200a92:	9301                	srli	a4,a4,0x20
ffffffffc0200a94:	0004899b          	sext.w	s3,s1
    free_nr_pages += (1U << order);
ffffffffc0200a98:	1482                	slli	s1,s1,0x20
        idx += (1UL << o);//跳过刚放进去的这块，继续切下一段
ffffffffc0200a9a:	01039833          	sll	a6,t2,a6
ffffffffc0200a9e:	00471893          	slli	a7,a4,0x4
    free_nr_pages += (1U << order);
ffffffffc0200aa2:	9081                	srli	s1,s1,0x20
ffffffffc0200aa4:	bf61                	j	ffffffffc0200a3c <buddy_init_memmap+0x8e>
ffffffffc0200aa6:	8082                	ret

ffffffffc0200aa8 <buddy_free_pages>:
    if (n == 0) return;
ffffffffc0200aa8:	1a058663          	beqz	a1,ffffffffc0200c54 <buddy_free_pages+0x1ac>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200aac:	715d                	addi	sp,sp,-80
ffffffffc0200aae:	fc4a                	sd	s2,56(sp)
ffffffffc0200ab0:	892e                	mv	s2,a1
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200ab2:	fcccd5b7          	lui	a1,0xfcccd
ffffffffc0200ab6:	ccd58593          	addi	a1,a1,-819 # fffffffffccccccd <end+0x3cac7bad>
ffffffffc0200aba:	05b2                	slli	a1,a1,0xc
ffffffffc0200abc:	ccd58593          	addi	a1,a1,-819
ffffffffc0200ac0:	05b2                	slli	a1,a1,0xc
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200ac2:	e4a2                	sd	s0,72(sp)
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200ac4:	ccd58593          	addi	a1,a1,-819
ffffffffc0200ac8:	842a                	mv	s0,a0
ffffffffc0200aca:	00004517          	auipc	a0,0x4
ffffffffc0200ace:	61653503          	ld	a0,1558(a0) # ffffffffc02050e0 <buddy_base>
ffffffffc0200ad2:	8c09                	sub	s0,s0,a0
ffffffffc0200ad4:	05b2                	slli	a1,a1,0xc
ffffffffc0200ad6:	840d                	srai	s0,s0,0x3
ffffffffc0200ad8:	ccd58593          	addi	a1,a1,-819
ffffffffc0200adc:	02b40433          	mul	s0,s0,a1
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200ae0:	e85e                	sd	s7,16(sp)
ffffffffc0200ae2:	00004b97          	auipc	s7,0x4
ffffffffc0200ae6:	606b8b93          	addi	s7,s7,1542 # ffffffffc02050e8 <free_nr_pages>
ffffffffc0200aea:	000bbf83          	ld	t6,0(s7)
ffffffffc0200aee:	e0a6                	sd	s1,64(sp)
ffffffffc0200af0:	f84e                	sd	s3,48(sp)
ffffffffc0200af2:	f452                	sd	s4,40(sp)
ffffffffc0200af4:	ec5a                	sd	s6,24(sp)
ffffffffc0200af6:	e462                	sd	s8,8(sp)
ffffffffc0200af8:	f056                	sd	s5,32(sp)
ffffffffc0200afa:	e066                	sd	s9,0(sp)
ffffffffc0200afc:	00004497          	auipc	s1,0x4
ffffffffc0200b00:	51c48493          	addi	s1,s1,1308 # ffffffffc0205018 <free_area>
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b04:	43ad                	li	t2,11
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200b06:	4285                	li	t0,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b08:	5a7d                	li	s4,-1
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200b0a:	4c05                	li	s8,1
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200b0c:	4985                	li	s3,1
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b0e:	00004b17          	auipc	s6,0x4
ffffffffc0200b12:	5aab0b13          	addi	s6,s6,1450 # ffffffffc02050b8 <free_area+0xa0>
    unsigned o = 0;
ffffffffc0200b16:	4881                	li	a7,0
ffffffffc0200b18:	a021                	j	ffffffffc0200b20 <buddy_free_pages+0x78>
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200b1a:	02e96e63          	bltu	s2,a4,ffffffffc0200b56 <buddy_free_pages+0xae>
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b1e:	ef85                	bnez	a5,ffffffffc0200b56 <buddy_free_pages+0xae>
ffffffffc0200b20:	0008881b          	sext.w	a6,a7
    while ((o + 1) < BUDDY_MAX_ORDER
ffffffffc0200b24:	2885                	addiw	a7,a7,1
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b26:	011a17b3          	sll	a5,s4,a7
ffffffffc0200b2a:	fff7c793          	not	a5,a5
        && ((1UL << (o + 1)) <= remain)
ffffffffc0200b2e:	01129733          	sll	a4,t0,a7
        && ((idx & ((1UL << (o + 1)) - 1)) == 0)) {
ffffffffc0200b32:	8fe1                	and	a5,a5,s0
ffffffffc0200b34:	fe7893e3          	bne	a7,t2,ffffffffc0200b1a <buddy_free_pages+0x72>
ffffffffc0200b38:	0a84be03          	ld	t3,168(s1)
        size_t bidx = idx;
ffffffffc0200b3c:	8ea2                	mv	t4,s0
ffffffffc0200b3e:	40000a93          	li	s5,1024
ffffffffc0200b42:	40000813          	li	a6,1024
ffffffffc0200b46:	00004697          	auipc	a3,0x4
ffffffffc0200b4a:	57268693          	addi	a3,a3,1394 # ffffffffc02050b8 <free_area+0xa0>
ffffffffc0200b4e:	40000313          	li	t1,1024
ffffffffc0200b52:	4f29                	li	t5,10
ffffffffc0200b54:	a859                	j	ffffffffc0200bea <buddy_free_pages+0x142>
        idx  += (1UL << o); //继续往下推荐
ffffffffc0200b56:	010c1ab3          	sll	s5,s8,a6
    unsigned o = 0;
ffffffffc0200b5a:	8ea2                	mv	t4,s0
    list_entry_t *le = &free_area[order];
ffffffffc0200b5c:	02081f13          	slli	t5,a6,0x20
ffffffffc0200b60:	020f5f13          	srli	t5,t5,0x20
ffffffffc0200b64:	004f1693          	slli	a3,t5,0x4
ffffffffc0200b68:	96a6                	add	a3,a3,s1
    return listelm->next;
ffffffffc0200b6a:	0086be03          	ld	t3,8(a3)
    return idx ^ (1UL << order);// 先把idx转成二进制之后，再按位异或运算翻转对应的对齐位，对称
ffffffffc0200b6e:	01029633          	sll	a2,t0,a6
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200b72:	0109983b          	sllw	a6,s3,a6
    return idx ^ (1UL << order);// 先把idx转成二进制之后，再按位异或运算翻转对应的对齐位，对称
ffffffffc0200b76:	01d64633          	xor	a2,a2,t4
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200b7a:	0008031b          	sext.w	t1,a6
    while (cur != le) {
ffffffffc0200b7e:	07c68363          	beq	a3,t3,ffffffffc0200be4 <buddy_free_pages+0x13c>
    list_entry_t *cur = list_next(le);
ffffffffc0200b82:	8772                	mv	a4,t3
ffffffffc0200b84:	a021                	j	ffffffffc0200b8c <buddy_free_pages+0xe4>
ffffffffc0200b86:	6718                	ld	a4,8(a4)
    while (cur != le) {
ffffffffc0200b88:	04e68e63          	beq	a3,a4,ffffffffc0200be4 <buddy_free_pages+0x13c>
        struct Page *p = le2page(cur, page_link);
ffffffffc0200b8c:	fe870793          	addi	a5,a4,-24
static inline size_t page_idx(struct Page *p) { return (size_t)(p - buddy_base); }
ffffffffc0200b90:	8f89                	sub	a5,a5,a0
ffffffffc0200b92:	878d                	srai	a5,a5,0x3
ffffffffc0200b94:	02b787b3          	mul	a5,a5,a1
        if (page_idx(p) == want_idx && PageProperty(p) && p->property == (1U << order))
ffffffffc0200b98:	fef617e3          	bne	a2,a5,ffffffffc0200b86 <buddy_free_pages+0xde>
ffffffffc0200b9c:	ff073783          	ld	a5,-16(a4)
ffffffffc0200ba0:	0027fc93          	andi	s9,a5,2
ffffffffc0200ba4:	fe0c81e3          	beqz	s9,ffffffffc0200b86 <buddy_free_pages+0xde>
ffffffffc0200ba8:	ff872c83          	lw	s9,-8(a4)
ffffffffc0200bac:	fc6c9de3          	bne	s9,t1,ffffffffc0200b86 <buddy_free_pages+0xde>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bb0:	00073303          	ld	t1,0(a4)
ffffffffc0200bb4:	6714                	ld	a3,8(a4)
    ClearPageProperty(p);
ffffffffc0200bb6:	9bf5                	andi	a5,a5,-3
    free_nr_pages -= (1U << order);
ffffffffc0200bb8:	1802                	slli	a6,a6,0x20
    prev->next = next;
ffffffffc0200bba:	00d33423          	sd	a3,8(t1)
    next->prev = prev;
ffffffffc0200bbe:	0066b023          	sd	t1,0(a3)
ffffffffc0200bc2:	02085813          	srli	a6,a6,0x20
    ClearPageProperty(p);
ffffffffc0200bc6:	fef73823          	sd	a5,-16(a4)
    free_nr_pages -= (1U << order);
ffffffffc0200bca:	410f8fb3          	sub	t6,t6,a6
            bidx = (bidx < other) ? bidx : other; //起点取更小的
ffffffffc0200bce:	01d67363          	bgeu	a2,t4,ffffffffc0200bd4 <buddy_free_pages+0x12c>
ffffffffc0200bd2:	8eb2                	mv	t4,a2
        while ((cur + 1) < BUDDY_MAX_ORDER) {
ffffffffc0200bd4:	0018879b          	addiw	a5,a7,1
ffffffffc0200bd8:	0008881b          	sext.w	a6,a7
ffffffffc0200bdc:	06778363          	beq	a5,t2,ffffffffc0200c42 <buddy_free_pages+0x19a>
ffffffffc0200be0:	88be                	mv	a7,a5
ffffffffc0200be2:	bfad                	j	ffffffffc0200b5c <buddy_free_pages+0xb4>
    free_nr_pages += (1U << order);
ffffffffc0200be4:	1802                	slli	a6,a6,0x20
ffffffffc0200be6:	02085813          	srli	a6,a6,0x20
static inline struct Page *page_at(size_t idx) { return buddy_base + idx; }
ffffffffc0200bea:	002e9793          	slli	a5,t4,0x2
ffffffffc0200bee:	97f6                	add	a5,a5,t4
ffffffffc0200bf0:	078e                	slli	a5,a5,0x3
ffffffffc0200bf2:	97aa                	add	a5,a5,a0
    SetPageProperty(p);
ffffffffc0200bf4:	6798                	ld	a4,8(a5)
ffffffffc0200bf6:	0007a023          	sw	zero,0(a5)
    p->property = (1U << order);
ffffffffc0200bfa:	0067a823          	sw	t1,16(a5)
    SetPageProperty(p);
ffffffffc0200bfe:	00276713          	ori	a4,a4,2
ffffffffc0200c02:	e798                	sd	a4,8(a5)
    list_add(&free_area[order], &(p->page_link));
ffffffffc0200c04:	01878613          	addi	a2,a5,24
    prev->next = next->prev = elm;
ffffffffc0200c08:	004f1713          	slli	a4,t5,0x4
ffffffffc0200c0c:	00ce3023          	sd	a2,0(t3)
ffffffffc0200c10:	9726                	add	a4,a4,s1
ffffffffc0200c12:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200c14:	03c7b023          	sd	t3,32(a5)
    elm->prev = prev;
ffffffffc0200c18:	ef94                	sd	a3,24(a5)
        left -= (1UL << o); //left 也相应减去这次处理的片段大小
ffffffffc0200c1a:	41590933          	sub	s2,s2,s5
    free_nr_pages += (1U << order);
ffffffffc0200c1e:	9fc2                	add	t6,t6,a6
        idx  += (1UL << o); //继续往下推荐
ffffffffc0200c20:	9456                	add	s0,s0,s5
    while (left > 0) {
ffffffffc0200c22:	ee091ae3          	bnez	s2,ffffffffc0200b16 <buddy_free_pages+0x6e>
}
ffffffffc0200c26:	6426                	ld	s0,72(sp)
ffffffffc0200c28:	01fbb023          	sd	t6,0(s7)
ffffffffc0200c2c:	6486                	ld	s1,64(sp)
ffffffffc0200c2e:	7962                	ld	s2,56(sp)
ffffffffc0200c30:	79c2                	ld	s3,48(sp)
ffffffffc0200c32:	7a22                	ld	s4,40(sp)
ffffffffc0200c34:	7a82                	ld	s5,32(sp)
ffffffffc0200c36:	6b62                	ld	s6,24(sp)
ffffffffc0200c38:	6bc2                	ld	s7,16(sp)
ffffffffc0200c3a:	6c22                	ld	s8,8(sp)
ffffffffc0200c3c:	6c82                	ld	s9,0(sp)
ffffffffc0200c3e:	6161                	addi	sp,sp,80
ffffffffc0200c40:	8082                	ret
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c42:	0a84be03          	ld	t3,168(s1)
ffffffffc0200c46:	40000813          	li	a6,1024
ffffffffc0200c4a:	86da                	mv	a3,s6
ffffffffc0200c4c:	40000313          	li	t1,1024
ffffffffc0200c50:	4f29                	li	t5,10
ffffffffc0200c52:	bf61                	j	ffffffffc0200bea <buddy_free_pages+0x142>
ffffffffc0200c54:	8082                	ret

ffffffffc0200c56 <pmm_init>:
static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    // 使用伙伴分配器
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c56:	00001797          	auipc	a5,0x1
ffffffffc0200c5a:	08a78793          	addi	a5,a5,138 # ffffffffc0201ce0 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c5e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200c60:	7179                	addi	sp,sp,-48
ffffffffc0200c62:	f406                	sd	ra,40(sp)
ffffffffc0200c64:	f022                	sd	s0,32(sp)
ffffffffc0200c66:	ec26                	sd	s1,24(sp)
ffffffffc0200c68:	e44e                	sd	s3,8(sp)
ffffffffc0200c6a:	e84a                	sd	s2,16(sp)
ffffffffc0200c6c:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c6e:	00004417          	auipc	s0,0x4
ffffffffc0200c72:	48240413          	addi	s0,s0,1154 # ffffffffc02050f0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c76:	00001517          	auipc	a0,0x1
ffffffffc0200c7a:	e4a50513          	addi	a0,a0,-438 # ffffffffc0201ac0 <etext+0x7e4>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c7e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c80:	ccaff0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc0200c84:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200c86:	00004497          	auipc	s1,0x4
ffffffffc0200c8a:	48248493          	addi	s1,s1,1154 # ffffffffc0205108 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200c8e:	679c                	ld	a5,8(a5)
ffffffffc0200c90:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200c92:	57f5                	li	a5,-3
ffffffffc0200c94:	07fa                	slli	a5,a5,0x1e
ffffffffc0200c96:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200c98:	8fdff0ef          	jal	ffffffffc0200594 <get_memory_base>
ffffffffc0200c9c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200c9e:	901ff0ef          	jal	ffffffffc020059e <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200ca2:	14050f63          	beqz	a0,ffffffffc0200e00 <pmm_init+0x1aa>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200ca6:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200ca8:	00001517          	auipc	a0,0x1
ffffffffc0200cac:	e6050513          	addi	a0,a0,-416 # ffffffffc0201b08 <etext+0x82c>
ffffffffc0200cb0:	c9aff0ef          	jal	ffffffffc020014a <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200cb4:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin, mem_end - 1);
ffffffffc0200cb8:	864e                	mv	a2,s3
ffffffffc0200cba:	fffa0693          	addi	a3,s4,-1
ffffffffc0200cbe:	85ca                	mv	a1,s2
ffffffffc0200cc0:	00001517          	auipc	a0,0x1
ffffffffc0200cc4:	e6050513          	addi	a0,a0,-416 # ffffffffc0201b20 <etext+0x844>
ffffffffc0200cc8:	c82ff0ef          	jal	ffffffffc020014a <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0200ccc:	c80007b7          	lui	a5,0xc8000
ffffffffc0200cd0:	8652                	mv	a2,s4
ffffffffc0200cd2:	0d47e663          	bltu	a5,s4,ffffffffc0200d9e <pmm_init+0x148>
ffffffffc0200cd6:	77fd                	lui	a5,0xfffff
ffffffffc0200cd8:	00005817          	auipc	a6,0x5
ffffffffc0200cdc:	44780813          	addi	a6,a6,1095 # ffffffffc020611f <end+0xfff>
ffffffffc0200ce0:	00f87833          	and	a6,a6,a5
    npage = maxpa / PGSIZE;
ffffffffc0200ce4:	8231                	srli	a2,a2,0xc
ffffffffc0200ce6:	00004797          	auipc	a5,0x4
ffffffffc0200cea:	42c7b523          	sd	a2,1066(a5) # ffffffffc0205110 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200cee:	00004797          	auipc	a5,0x4
ffffffffc0200cf2:	4307b523          	sd	a6,1066(a5) # ffffffffc0205118 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200cf6:	000807b7          	lui	a5,0x80
ffffffffc0200cfa:	002005b7          	lui	a1,0x200
ffffffffc0200cfe:	02f60563          	beq	a2,a5,ffffffffc0200d28 <pmm_init+0xd2>
ffffffffc0200d02:	00261593          	slli	a1,a2,0x2
ffffffffc0200d06:	00c587b3          	add	a5,a1,a2
ffffffffc0200d0a:	fec006b7          	lui	a3,0xfec00
ffffffffc0200d0e:	078e                	slli	a5,a5,0x3
ffffffffc0200d10:	96c2                	add	a3,a3,a6
ffffffffc0200d12:	96be                	add	a3,a3,a5
ffffffffc0200d14:	87c2                	mv	a5,a6
        SetPageReserved(pages + i);
ffffffffc0200d16:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d18:	02878793          	addi	a5,a5,40 # 80028 <kern_entry-0xffffffffc017ffd8>
        SetPageReserved(pages + i);
ffffffffc0200d1c:	00176713          	ori	a4,a4,1
ffffffffc0200d20:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200d24:	fed799e3          	bne	a5,a3,ffffffffc0200d16 <pmm_init+0xc0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d28:	95b2                	add	a1,a1,a2
ffffffffc0200d2a:	fec006b7          	lui	a3,0xfec00
ffffffffc0200d2e:	96c2                	add	a3,a3,a6
ffffffffc0200d30:	058e                	slli	a1,a1,0x3
ffffffffc0200d32:	96ae                	add	a3,a3,a1
ffffffffc0200d34:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d38:	0af6e863          	bltu	a3,a5,ffffffffc0200de8 <pmm_init+0x192>
ffffffffc0200d3c:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200d3e:	77fd                	lui	a5,0xfffff
ffffffffc0200d40:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d44:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200d46:	04b6ef63          	bltu	a3,a1,ffffffffc0200da4 <pmm_init+0x14e>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
            satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200d4a:	601c                	ld	a5,0(s0)
ffffffffc0200d4c:	7b9c                	ld	a5,48(a5)
ffffffffc0200d4e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200d50:	00001517          	auipc	a0,0x1
ffffffffc0200d54:	e5850513          	addi	a0,a0,-424 # ffffffffc0201ba8 <etext+0x8cc>
ffffffffc0200d58:	bf2ff0ef          	jal	ffffffffc020014a <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200d5c:	00003597          	auipc	a1,0x3
ffffffffc0200d60:	2a458593          	addi	a1,a1,676 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200d64:	00004797          	auipc	a5,0x4
ffffffffc0200d68:	38b7be23          	sd	a1,924(a5) # ffffffffc0205100 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d6c:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d70:	0af5e463          	bltu	a1,a5,ffffffffc0200e18 <pmm_init+0x1c2>
ffffffffc0200d74:	609c                	ld	a5,0(s1)
}
ffffffffc0200d76:	7402                	ld	s0,32(sp)
ffffffffc0200d78:	70a2                	ld	ra,40(sp)
ffffffffc0200d7a:	64e2                	ld	s1,24(sp)
ffffffffc0200d7c:	6942                	ld	s2,16(sp)
ffffffffc0200d7e:	69a2                	ld	s3,8(sp)
ffffffffc0200d80:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d82:	40f586b3          	sub	a3,a1,a5
ffffffffc0200d86:	00004797          	auipc	a5,0x4
ffffffffc0200d8a:	36d7b923          	sd	a3,882(a5) # ffffffffc02050f8 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
ffffffffc0200d8e:	00001517          	auipc	a0,0x1
ffffffffc0200d92:	e3a50513          	addi	a0,a0,-454 # ffffffffc0201bc8 <etext+0x8ec>
ffffffffc0200d96:	8636                	mv	a2,a3
}
ffffffffc0200d98:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
ffffffffc0200d9a:	bb0ff06f          	j	ffffffffc020014a <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0200d9e:	c8000637          	lui	a2,0xc8000
ffffffffc0200da2:	bf15                	j	ffffffffc0200cd6 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200da4:	6705                	lui	a4,0x1
ffffffffc0200da6:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0200da8:	96ba                	add	a3,a3,a4
ffffffffc0200daa:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200dac:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200db0:	02c7f063          	bgeu	a5,a2,ffffffffc0200dd0 <pmm_init+0x17a>
    pmm_manager->init_memmap(base, n);
ffffffffc0200db4:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200db6:	fff80637          	lui	a2,0xfff80
ffffffffc0200dba:	97b2                	add	a5,a5,a2
ffffffffc0200dbc:	00279513          	slli	a0,a5,0x2
ffffffffc0200dc0:	953e                	add	a0,a0,a5
ffffffffc0200dc2:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200dc4:	8d95                	sub	a1,a1,a3
ffffffffc0200dc6:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200dc8:	81b1                	srli	a1,a1,0xc
ffffffffc0200dca:	9542                	add	a0,a0,a6
ffffffffc0200dcc:	9782                	jalr	a5
}
ffffffffc0200dce:	bfb5                	j	ffffffffc0200d4a <pmm_init+0xf4>
        panic("pa2page called with invalid pa");
ffffffffc0200dd0:	00001617          	auipc	a2,0x1
ffffffffc0200dd4:	da860613          	addi	a2,a2,-600 # ffffffffc0201b78 <etext+0x89c>
ffffffffc0200dd8:	06a00593          	li	a1,106
ffffffffc0200ddc:	00001517          	auipc	a0,0x1
ffffffffc0200de0:	dbc50513          	addi	a0,a0,-580 # ffffffffc0201b98 <etext+0x8bc>
ffffffffc0200de4:	be8ff0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200de8:	00001617          	auipc	a2,0x1
ffffffffc0200dec:	d6860613          	addi	a2,a2,-664 # ffffffffc0201b50 <etext+0x874>
ffffffffc0200df0:	05c00593          	li	a1,92
ffffffffc0200df4:	00001517          	auipc	a0,0x1
ffffffffc0200df8:	d0450513          	addi	a0,a0,-764 # ffffffffc0201af8 <etext+0x81c>
ffffffffc0200dfc:	bd0ff0ef          	jal	ffffffffc02001cc <__panic>
        panic("DTB memory info not available");
ffffffffc0200e00:	00001617          	auipc	a2,0x1
ffffffffc0200e04:	cd860613          	addi	a2,a2,-808 # ffffffffc0201ad8 <etext+0x7fc>
ffffffffc0200e08:	04600593          	li	a1,70
ffffffffc0200e0c:	00001517          	auipc	a0,0x1
ffffffffc0200e10:	cec50513          	addi	a0,a0,-788 # ffffffffc0201af8 <etext+0x81c>
ffffffffc0200e14:	bb8ff0ef          	jal	ffffffffc02001cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e18:	86ae                	mv	a3,a1
ffffffffc0200e1a:	00001617          	auipc	a2,0x1
ffffffffc0200e1e:	d3660613          	addi	a2,a2,-714 # ffffffffc0201b50 <etext+0x874>
ffffffffc0200e22:	07200593          	li	a1,114
ffffffffc0200e26:	00001517          	auipc	a0,0x1
ffffffffc0200e2a:	cd250513          	addi	a0,a0,-814 # ffffffffc0201af8 <etext+0x81c>
ffffffffc0200e2e:	b9eff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200e32 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0200e32:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200e36:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0200e38:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200e3c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200e3e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200e42:	f022                	sd	s0,32(sp)
ffffffffc0200e44:	ec26                	sd	s1,24(sp)
ffffffffc0200e46:	e84a                	sd	s2,16(sp)
ffffffffc0200e48:	f406                	sd	ra,40(sp)
ffffffffc0200e4a:	84aa                	mv	s1,a0
ffffffffc0200e4c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0200e4e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0200e52:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0200e54:	05067063          	bgeu	a2,a6,ffffffffc0200e94 <printnum+0x62>
ffffffffc0200e58:	e44e                	sd	s3,8(sp)
ffffffffc0200e5a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0200e5c:	4785                	li	a5,1
ffffffffc0200e5e:	00e7d763          	bge	a5,a4,ffffffffc0200e6c <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0200e62:	85ca                	mv	a1,s2
ffffffffc0200e64:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0200e66:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0200e68:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0200e6a:	fc65                	bnez	s0,ffffffffc0200e62 <printnum+0x30>
ffffffffc0200e6c:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200e6e:	1a02                	slli	s4,s4,0x20
ffffffffc0200e70:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200e74:	00001797          	auipc	a5,0x1
ffffffffc0200e78:	d9478793          	addi	a5,a5,-620 # ffffffffc0201c08 <etext+0x92c>
ffffffffc0200e7c:	97d2                	add	a5,a5,s4
}
ffffffffc0200e7e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200e80:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0200e84:	70a2                	ld	ra,40(sp)
ffffffffc0200e86:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200e88:	85ca                	mv	a1,s2
ffffffffc0200e8a:	87a6                	mv	a5,s1
}
ffffffffc0200e8c:	6942                	ld	s2,16(sp)
ffffffffc0200e8e:	64e2                	ld	s1,24(sp)
ffffffffc0200e90:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200e92:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0200e94:	03065633          	divu	a2,a2,a6
ffffffffc0200e98:	8722                	mv	a4,s0
ffffffffc0200e9a:	f99ff0ef          	jal	ffffffffc0200e32 <printnum>
ffffffffc0200e9e:	bfc1                	j	ffffffffc0200e6e <printnum+0x3c>

ffffffffc0200ea0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0200ea0:	7119                	addi	sp,sp,-128
ffffffffc0200ea2:	f4a6                	sd	s1,104(sp)
ffffffffc0200ea4:	f0ca                	sd	s2,96(sp)
ffffffffc0200ea6:	ecce                	sd	s3,88(sp)
ffffffffc0200ea8:	e8d2                	sd	s4,80(sp)
ffffffffc0200eaa:	e4d6                	sd	s5,72(sp)
ffffffffc0200eac:	e0da                	sd	s6,64(sp)
ffffffffc0200eae:	f862                	sd	s8,48(sp)
ffffffffc0200eb0:	fc86                	sd	ra,120(sp)
ffffffffc0200eb2:	f8a2                	sd	s0,112(sp)
ffffffffc0200eb4:	fc5e                	sd	s7,56(sp)
ffffffffc0200eb6:	f466                	sd	s9,40(sp)
ffffffffc0200eb8:	f06a                	sd	s10,32(sp)
ffffffffc0200eba:	ec6e                	sd	s11,24(sp)
ffffffffc0200ebc:	892a                	mv	s2,a0
ffffffffc0200ebe:	84ae                	mv	s1,a1
ffffffffc0200ec0:	8c32                	mv	s8,a2
ffffffffc0200ec2:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200ec4:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200ec8:	05500b13          	li	s6,85
ffffffffc0200ecc:	00001a97          	auipc	s5,0x1
ffffffffc0200ed0:	e4ca8a93          	addi	s5,s5,-436 # ffffffffc0201d18 <buddy_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200ed4:	000c4503          	lbu	a0,0(s8)
ffffffffc0200ed8:	001c0413          	addi	s0,s8,1
ffffffffc0200edc:	01350a63          	beq	a0,s3,ffffffffc0200ef0 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0200ee0:	cd0d                	beqz	a0,ffffffffc0200f1a <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0200ee2:	85a6                	mv	a1,s1
ffffffffc0200ee4:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200ee6:	00044503          	lbu	a0,0(s0)
ffffffffc0200eea:	0405                	addi	s0,s0,1
ffffffffc0200eec:	ff351ae3          	bne	a0,s3,ffffffffc0200ee0 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0200ef0:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0200ef4:	4b81                	li	s7,0
ffffffffc0200ef6:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0200ef8:	5d7d                	li	s10,-1
ffffffffc0200efa:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200efc:	00044683          	lbu	a3,0(s0)
ffffffffc0200f00:	00140c13          	addi	s8,s0,1
ffffffffc0200f04:	fdd6859b          	addiw	a1,a3,-35 # fffffffffebfffdd <end+0x3e9faebd>
ffffffffc0200f08:	0ff5f593          	zext.b	a1,a1
ffffffffc0200f0c:	02bb6663          	bltu	s6,a1,ffffffffc0200f38 <vprintfmt+0x98>
ffffffffc0200f10:	058a                	slli	a1,a1,0x2
ffffffffc0200f12:	95d6                	add	a1,a1,s5
ffffffffc0200f14:	4198                	lw	a4,0(a1)
ffffffffc0200f16:	9756                	add	a4,a4,s5
ffffffffc0200f18:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0200f1a:	70e6                	ld	ra,120(sp)
ffffffffc0200f1c:	7446                	ld	s0,112(sp)
ffffffffc0200f1e:	74a6                	ld	s1,104(sp)
ffffffffc0200f20:	7906                	ld	s2,96(sp)
ffffffffc0200f22:	69e6                	ld	s3,88(sp)
ffffffffc0200f24:	6a46                	ld	s4,80(sp)
ffffffffc0200f26:	6aa6                	ld	s5,72(sp)
ffffffffc0200f28:	6b06                	ld	s6,64(sp)
ffffffffc0200f2a:	7be2                	ld	s7,56(sp)
ffffffffc0200f2c:	7c42                	ld	s8,48(sp)
ffffffffc0200f2e:	7ca2                	ld	s9,40(sp)
ffffffffc0200f30:	7d02                	ld	s10,32(sp)
ffffffffc0200f32:	6de2                	ld	s11,24(sp)
ffffffffc0200f34:	6109                	addi	sp,sp,128
ffffffffc0200f36:	8082                	ret
            putch('%', putdat);
ffffffffc0200f38:	85a6                	mv	a1,s1
ffffffffc0200f3a:	02500513          	li	a0,37
ffffffffc0200f3e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0200f40:	fff44703          	lbu	a4,-1(s0)
ffffffffc0200f44:	02500793          	li	a5,37
ffffffffc0200f48:	8c22                	mv	s8,s0
ffffffffc0200f4a:	f8f705e3          	beq	a4,a5,ffffffffc0200ed4 <vprintfmt+0x34>
ffffffffc0200f4e:	02500713          	li	a4,37
ffffffffc0200f52:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0200f56:	1c7d                	addi	s8,s8,-1
ffffffffc0200f58:	fee79de3          	bne	a5,a4,ffffffffc0200f52 <vprintfmt+0xb2>
ffffffffc0200f5c:	bfa5                	j	ffffffffc0200ed4 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0200f5e:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0200f62:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0200f64:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0200f68:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc0200f6c:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f70:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0200f72:	02b76563          	bltu	a4,a1,ffffffffc0200f9c <vprintfmt+0xfc>
ffffffffc0200f76:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0200f78:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0200f7c:	002d171b          	slliw	a4,s10,0x2
ffffffffc0200f80:	01a7073b          	addw	a4,a4,s10
ffffffffc0200f84:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200f88:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0200f8a:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0200f8e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0200f90:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0200f94:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0200f98:	feb570e3          	bgeu	a0,a1,ffffffffc0200f78 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0200f9c:	f60cd0e3          	bgez	s9,ffffffffc0200efc <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0200fa0:	8cea                	mv	s9,s10
ffffffffc0200fa2:	5d7d                	li	s10,-1
ffffffffc0200fa4:	bfa1                	j	ffffffffc0200efc <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200fa6:	8db6                	mv	s11,a3
ffffffffc0200fa8:	8462                	mv	s0,s8
ffffffffc0200faa:	bf89                	j	ffffffffc0200efc <vprintfmt+0x5c>
ffffffffc0200fac:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0200fae:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0200fb0:	b7b1                	j	ffffffffc0200efc <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0200fb2:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0200fb4:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0200fb8:	00c7c463          	blt	a5,a2,ffffffffc0200fc0 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0200fbc:	1a060163          	beqz	a2,ffffffffc020115e <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0200fc0:	000a3603          	ld	a2,0(s4)
ffffffffc0200fc4:	46c1                	li	a3,16
ffffffffc0200fc6:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0200fc8:	000d879b          	sext.w	a5,s11
ffffffffc0200fcc:	8766                	mv	a4,s9
ffffffffc0200fce:	85a6                	mv	a1,s1
ffffffffc0200fd0:	854a                	mv	a0,s2
ffffffffc0200fd2:	e61ff0ef          	jal	ffffffffc0200e32 <printnum>
            break;
ffffffffc0200fd6:	bdfd                	j	ffffffffc0200ed4 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0200fd8:	000a2503          	lw	a0,0(s4)
ffffffffc0200fdc:	85a6                	mv	a1,s1
ffffffffc0200fde:	0a21                	addi	s4,s4,8
ffffffffc0200fe0:	9902                	jalr	s2
            break;
ffffffffc0200fe2:	bdcd                	j	ffffffffc0200ed4 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0200fe4:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0200fe6:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0200fea:	00c7c463          	blt	a5,a2,ffffffffc0200ff2 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0200fee:	16060363          	beqz	a2,ffffffffc0201154 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0200ff2:	000a3603          	ld	a2,0(s4)
ffffffffc0200ff6:	46a9                	li	a3,10
ffffffffc0200ff8:	8a3a                	mv	s4,a4
ffffffffc0200ffa:	b7f9                	j	ffffffffc0200fc8 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0200ffc:	85a6                	mv	a1,s1
ffffffffc0200ffe:	03000513          	li	a0,48
ffffffffc0201002:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201004:	85a6                	mv	a1,s1
ffffffffc0201006:	07800513          	li	a0,120
ffffffffc020100a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020100c:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201010:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201012:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201014:	bf55                	j	ffffffffc0200fc8 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201016:	85a6                	mv	a1,s1
ffffffffc0201018:	02500513          	li	a0,37
ffffffffc020101c:	9902                	jalr	s2
            break;
ffffffffc020101e:	bd5d                	j	ffffffffc0200ed4 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201020:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201024:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201026:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201028:	bf95                	j	ffffffffc0200f9c <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc020102a:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020102c:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201030:	00c7c463          	blt	a5,a2,ffffffffc0201038 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201034:	10060b63          	beqz	a2,ffffffffc020114a <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201038:	000a3603          	ld	a2,0(s4)
ffffffffc020103c:	46a1                	li	a3,8
ffffffffc020103e:	8a3a                	mv	s4,a4
ffffffffc0201040:	b761                	j	ffffffffc0200fc8 <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201042:	fffcc793          	not	a5,s9
ffffffffc0201046:	97fd                	srai	a5,a5,0x3f
ffffffffc0201048:	00fcf7b3          	and	a5,s9,a5
ffffffffc020104c:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201050:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201052:	b56d                	j	ffffffffc0200efc <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201054:	000a3403          	ld	s0,0(s4)
ffffffffc0201058:	008a0793          	addi	a5,s4,8
ffffffffc020105c:	e43e                	sd	a5,8(sp)
ffffffffc020105e:	12040063          	beqz	s0,ffffffffc020117e <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201062:	0d905963          	blez	s9,ffffffffc0201134 <vprintfmt+0x294>
ffffffffc0201066:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020106a:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc020106e:	12fd9763          	bne	s11,a5,ffffffffc020119c <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201072:	00044783          	lbu	a5,0(s0)
ffffffffc0201076:	0007851b          	sext.w	a0,a5
ffffffffc020107a:	cb9d                	beqz	a5,ffffffffc02010b0 <vprintfmt+0x210>
ffffffffc020107c:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020107e:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201082:	000d4563          	bltz	s10,ffffffffc020108c <vprintfmt+0x1ec>
ffffffffc0201086:	3d7d                	addiw	s10,s10,-1
ffffffffc0201088:	028d0263          	beq	s10,s0,ffffffffc02010ac <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc020108c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020108e:	0c0b8d63          	beqz	s7,ffffffffc0201168 <vprintfmt+0x2c8>
ffffffffc0201092:	3781                	addiw	a5,a5,-32
ffffffffc0201094:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201168 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201098:	03f00513          	li	a0,63
ffffffffc020109c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020109e:	000a4783          	lbu	a5,0(s4)
ffffffffc02010a2:	3cfd                	addiw	s9,s9,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc02010a4:	0a05                	addi	s4,s4,1
ffffffffc02010a6:	0007851b          	sext.w	a0,a5
ffffffffc02010aa:	ffe1                	bnez	a5,ffffffffc0201082 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc02010ac:	01905963          	blez	s9,ffffffffc02010be <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc02010b0:	85a6                	mv	a1,s1
ffffffffc02010b2:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02010b6:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc02010b8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02010ba:	fe0c9be3          	bnez	s9,ffffffffc02010b0 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02010be:	6a22                	ld	s4,8(sp)
ffffffffc02010c0:	bd11                	j	ffffffffc0200ed4 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02010c2:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02010c4:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02010c8:	00c7c363          	blt	a5,a2,ffffffffc02010ce <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc02010cc:	ce25                	beqz	a2,ffffffffc0201144 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc02010ce:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02010d2:	08044d63          	bltz	s0,ffffffffc020116c <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02010d6:	8622                	mv	a2,s0
ffffffffc02010d8:	8a5e                	mv	s4,s7
ffffffffc02010da:	46a9                	li	a3,10
ffffffffc02010dc:	b5f5                	j	ffffffffc0200fc8 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc02010de:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02010e2:	4619                	li	a2,6
            if (err < 0) {
ffffffffc02010e4:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02010e8:	8fb9                	xor	a5,a5,a4
ffffffffc02010ea:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02010ee:	02d64663          	blt	a2,a3,ffffffffc020111a <vprintfmt+0x27a>
ffffffffc02010f2:	00369713          	slli	a4,a3,0x3
ffffffffc02010f6:	00001797          	auipc	a5,0x1
ffffffffc02010fa:	d7a78793          	addi	a5,a5,-646 # ffffffffc0201e70 <error_string>
ffffffffc02010fe:	97ba                	add	a5,a5,a4
ffffffffc0201100:	639c                	ld	a5,0(a5)
ffffffffc0201102:	cf81                	beqz	a5,ffffffffc020111a <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201104:	86be                	mv	a3,a5
ffffffffc0201106:	00001617          	auipc	a2,0x1
ffffffffc020110a:	b3260613          	addi	a2,a2,-1230 # ffffffffc0201c38 <etext+0x95c>
ffffffffc020110e:	85a6                	mv	a1,s1
ffffffffc0201110:	854a                	mv	a0,s2
ffffffffc0201112:	0e8000ef          	jal	ffffffffc02011fa <printfmt>
            err = va_arg(ap, int);
ffffffffc0201116:	0a21                	addi	s4,s4,8
ffffffffc0201118:	bb75                	j	ffffffffc0200ed4 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020111a:	00001617          	auipc	a2,0x1
ffffffffc020111e:	b0e60613          	addi	a2,a2,-1266 # ffffffffc0201c28 <etext+0x94c>
ffffffffc0201122:	85a6                	mv	a1,s1
ffffffffc0201124:	854a                	mv	a0,s2
ffffffffc0201126:	0d4000ef          	jal	ffffffffc02011fa <printfmt>
            err = va_arg(ap, int);
ffffffffc020112a:	0a21                	addi	s4,s4,8
ffffffffc020112c:	b365                	j	ffffffffc0200ed4 <vprintfmt+0x34>
            lflag ++;
ffffffffc020112e:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201130:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201132:	b3e9                	j	ffffffffc0200efc <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201134:	00044783          	lbu	a5,0(s0)
ffffffffc0201138:	0007851b          	sext.w	a0,a5
ffffffffc020113c:	d3c9                	beqz	a5,ffffffffc02010be <vprintfmt+0x21e>
ffffffffc020113e:	00140a13          	addi	s4,s0,1
ffffffffc0201142:	bf2d                	j	ffffffffc020107c <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201144:	000a2403          	lw	s0,0(s4)
ffffffffc0201148:	b769                	j	ffffffffc02010d2 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc020114a:	000a6603          	lwu	a2,0(s4)
ffffffffc020114e:	46a1                	li	a3,8
ffffffffc0201150:	8a3a                	mv	s4,a4
ffffffffc0201152:	bd9d                	j	ffffffffc0200fc8 <vprintfmt+0x128>
ffffffffc0201154:	000a6603          	lwu	a2,0(s4)
ffffffffc0201158:	46a9                	li	a3,10
ffffffffc020115a:	8a3a                	mv	s4,a4
ffffffffc020115c:	b5b5                	j	ffffffffc0200fc8 <vprintfmt+0x128>
ffffffffc020115e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201162:	46c1                	li	a3,16
ffffffffc0201164:	8a3a                	mv	s4,a4
ffffffffc0201166:	b58d                	j	ffffffffc0200fc8 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201168:	9902                	jalr	s2
ffffffffc020116a:	bf15                	j	ffffffffc020109e <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc020116c:	85a6                	mv	a1,s1
ffffffffc020116e:	02d00513          	li	a0,45
ffffffffc0201172:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201174:	40800633          	neg	a2,s0
ffffffffc0201178:	8a5e                	mv	s4,s7
ffffffffc020117a:	46a9                	li	a3,10
ffffffffc020117c:	b5b1                	j	ffffffffc0200fc8 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc020117e:	01905663          	blez	s9,ffffffffc020118a <vprintfmt+0x2ea>
ffffffffc0201182:	02d00793          	li	a5,45
ffffffffc0201186:	04fd9263          	bne	s11,a5,ffffffffc02011ca <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020118a:	02800793          	li	a5,40
ffffffffc020118e:	00001a17          	auipc	s4,0x1
ffffffffc0201192:	a93a0a13          	addi	s4,s4,-1389 # ffffffffc0201c21 <etext+0x945>
ffffffffc0201196:	02800513          	li	a0,40
ffffffffc020119a:	b5cd                	j	ffffffffc020107c <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020119c:	85ea                	mv	a1,s10
ffffffffc020119e:	8522                	mv	a0,s0
ffffffffc02011a0:	0ae000ef          	jal	ffffffffc020124e <strnlen>
ffffffffc02011a4:	40ac8cbb          	subw	s9,s9,a0
ffffffffc02011a8:	01905963          	blez	s9,ffffffffc02011ba <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc02011ac:	2d81                	sext.w	s11,s11
ffffffffc02011ae:	85a6                	mv	a1,s1
ffffffffc02011b0:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02011b2:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc02011b4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02011b6:	fe0c9ce3          	bnez	s9,ffffffffc02011ae <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02011ba:	00044783          	lbu	a5,0(s0)
ffffffffc02011be:	0007851b          	sext.w	a0,a5
ffffffffc02011c2:	ea079de3          	bnez	a5,ffffffffc020107c <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02011c6:	6a22                	ld	s4,8(sp)
ffffffffc02011c8:	b331                	j	ffffffffc0200ed4 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02011ca:	85ea                	mv	a1,s10
ffffffffc02011cc:	00001517          	auipc	a0,0x1
ffffffffc02011d0:	a5450513          	addi	a0,a0,-1452 # ffffffffc0201c20 <etext+0x944>
ffffffffc02011d4:	07a000ef          	jal	ffffffffc020124e <strnlen>
ffffffffc02011d8:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc02011dc:	00001417          	auipc	s0,0x1
ffffffffc02011e0:	a4440413          	addi	s0,s0,-1468 # ffffffffc0201c20 <etext+0x944>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02011e4:	00001a17          	auipc	s4,0x1
ffffffffc02011e8:	a3da0a13          	addi	s4,s4,-1475 # ffffffffc0201c21 <etext+0x945>
ffffffffc02011ec:	02800793          	li	a5,40
ffffffffc02011f0:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02011f4:	fb904ce3          	bgtz	s9,ffffffffc02011ac <vprintfmt+0x30c>
ffffffffc02011f8:	b551                	j	ffffffffc020107c <vprintfmt+0x1dc>

ffffffffc02011fa <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02011fa:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02011fc:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201200:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201202:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201204:	ec06                	sd	ra,24(sp)
ffffffffc0201206:	f83a                	sd	a4,48(sp)
ffffffffc0201208:	fc3e                	sd	a5,56(sp)
ffffffffc020120a:	e0c2                	sd	a6,64(sp)
ffffffffc020120c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020120e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201210:	c91ff0ef          	jal	ffffffffc0200ea0 <vprintfmt>
}
ffffffffc0201214:	60e2                	ld	ra,24(sp)
ffffffffc0201216:	6161                	addi	sp,sp,80
ffffffffc0201218:	8082                	ret

ffffffffc020121a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020121a:	4781                	li	a5,0
ffffffffc020121c:	00004717          	auipc	a4,0x4
ffffffffc0201220:	df473703          	ld	a4,-524(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201224:	88ba                	mv	a7,a4
ffffffffc0201226:	852a                	mv	a0,a0
ffffffffc0201228:	85be                	mv	a1,a5
ffffffffc020122a:	863e                	mv	a2,a5
ffffffffc020122c:	00000073          	ecall
ffffffffc0201230:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201232:	8082                	ret

ffffffffc0201234 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201234:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201238:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020123a:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020123c:	cb81                	beqz	a5,ffffffffc020124c <strlen+0x18>
        cnt ++;
ffffffffc020123e:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201240:	00a707b3          	add	a5,a4,a0
ffffffffc0201244:	0007c783          	lbu	a5,0(a5)
ffffffffc0201248:	fbfd                	bnez	a5,ffffffffc020123e <strlen+0xa>
ffffffffc020124a:	8082                	ret
    }
    return cnt;
}
ffffffffc020124c:	8082                	ret

ffffffffc020124e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020124e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201250:	e589                	bnez	a1,ffffffffc020125a <strnlen+0xc>
ffffffffc0201252:	a811                	j	ffffffffc0201266 <strnlen+0x18>
        cnt ++;
ffffffffc0201254:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201256:	00f58863          	beq	a1,a5,ffffffffc0201266 <strnlen+0x18>
ffffffffc020125a:	00f50733          	add	a4,a0,a5
ffffffffc020125e:	00074703          	lbu	a4,0(a4)
ffffffffc0201262:	fb6d                	bnez	a4,ffffffffc0201254 <strnlen+0x6>
ffffffffc0201264:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201266:	852e                	mv	a0,a1
ffffffffc0201268:	8082                	ret

ffffffffc020126a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020126a:	00054783          	lbu	a5,0(a0)
ffffffffc020126e:	e791                	bnez	a5,ffffffffc020127a <strcmp+0x10>
ffffffffc0201270:	a02d                	j	ffffffffc020129a <strcmp+0x30>
ffffffffc0201272:	00054783          	lbu	a5,0(a0)
ffffffffc0201276:	cf89                	beqz	a5,ffffffffc0201290 <strcmp+0x26>
ffffffffc0201278:	85b6                	mv	a1,a3
ffffffffc020127a:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020127e:	0505                	addi	a0,a0,1
ffffffffc0201280:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201284:	fef707e3          	beq	a4,a5,ffffffffc0201272 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201288:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020128c:	9d19                	subw	a0,a0,a4
ffffffffc020128e:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201290:	0015c703          	lbu	a4,1(a1)
ffffffffc0201294:	4501                	li	a0,0
}
ffffffffc0201296:	9d19                	subw	a0,a0,a4
ffffffffc0201298:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020129a:	0005c703          	lbu	a4,0(a1)
ffffffffc020129e:	4501                	li	a0,0
ffffffffc02012a0:	b7f5                	j	ffffffffc020128c <strcmp+0x22>

ffffffffc02012a2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012a2:	ce01                	beqz	a2,ffffffffc02012ba <strncmp+0x18>
ffffffffc02012a4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02012a8:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012aa:	cb91                	beqz	a5,ffffffffc02012be <strncmp+0x1c>
ffffffffc02012ac:	0005c703          	lbu	a4,0(a1)
ffffffffc02012b0:	00f71763          	bne	a4,a5,ffffffffc02012be <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02012b4:	0505                	addi	a0,a0,1
ffffffffc02012b6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012b8:	f675                	bnez	a2,ffffffffc02012a4 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02012ba:	4501                	li	a0,0
ffffffffc02012bc:	8082                	ret
ffffffffc02012be:	00054503          	lbu	a0,0(a0)
ffffffffc02012c2:	0005c783          	lbu	a5,0(a1)
ffffffffc02012c6:	9d1d                	subw	a0,a0,a5
}
ffffffffc02012c8:	8082                	ret

ffffffffc02012ca <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02012ca:	ca01                	beqz	a2,ffffffffc02012da <memset+0x10>
ffffffffc02012cc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02012ce:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02012d0:	0785                	addi	a5,a5,1
ffffffffc02012d2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02012d6:	fef61de3          	bne	a2,a5,ffffffffc02012d0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02012da:	8082                	ret
