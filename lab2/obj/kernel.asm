
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
ffffffffc0200050:	6e450513          	addi	a0,a0,1764 # ffffffffc0201730 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	6ee50513          	addi	a0,a0,1774 # ffffffffc0201750 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	6be58593          	addi	a1,a1,1726 # ffffffffc020172c <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	6fa50513          	addi	a0,a0,1786 # ffffffffc0201770 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	70650513          	addi	a0,a0,1798 # ffffffffc0201790 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0206078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	71250513          	addi	a0,a0,1810 # ffffffffc02017b0 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0206477 <end+0x3ff>
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
ffffffffc02000d0:	70450513          	addi	a0,a0,1796 # ffffffffc02017d0 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <free_area>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0206078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	222010ef          	jal	ra,ffffffffc0201312 <memset>
    dtb_init();
ffffffffc02000f4:	122000ef          	jal	ra,ffffffffc0200216 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	4ce000ef          	jal	ra,ffffffffc02005c6 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	70450513          	addi	a0,a0,1796 # ffffffffc0201800 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4e8000ef          	jal	ra,ffffffffc02005f4 <pmm_init>

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
ffffffffc020011a:	4ae000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
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
ffffffffc0200140:	250010ef          	jal	ra,ffffffffc0201390 <vprintfmt>
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
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
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
ffffffffc0200176:	21a010ef          	jal	ra,ffffffffc0201390 <vprintfmt>
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
ffffffffc0200198:	430000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	41a000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
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
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0206030 <is_panic>
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
ffffffffc02001f6:	62e50513          	addi	a0,a0,1582 # ffffffffc0201820 <etext+0xf4>
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
ffffffffc020020c:	5f050513          	addi	a0,a0,1520 # ffffffffc02017f8 <etext+0xcc>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200216:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200218:	00001517          	auipc	a0,0x1
ffffffffc020021c:	62850513          	addi	a0,a0,1576 # ffffffffc0201840 <etext+0x114>
void dtb_init(void) {
ffffffffc0200220:	fc86                	sd	ra,120(sp)
ffffffffc0200222:	f8a2                	sd	s0,112(sp)
ffffffffc0200224:	e8d2                	sd	s4,80(sp)
ffffffffc0200226:	f4a6                	sd	s1,104(sp)
ffffffffc0200228:	f0ca                	sd	s2,96(sp)
ffffffffc020022a:	ecce                	sd	s3,88(sp)
ffffffffc020022c:	e4d6                	sd	s5,72(sp)
ffffffffc020022e:	e0da                	sd	s6,64(sp)
ffffffffc0200230:	fc5e                	sd	s7,56(sp)
ffffffffc0200232:	f862                	sd	s8,48(sp)
ffffffffc0200234:	f466                	sd	s9,40(sp)
ffffffffc0200236:	f06a                	sd	s10,32(sp)
ffffffffc0200238:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f13ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00006597          	auipc	a1,0x6
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200246:	00001517          	auipc	a0,0x1
ffffffffc020024a:	60a50513          	addi	a0,a0,1546 # ffffffffc0201850 <etext+0x124>
ffffffffc020024e:	effff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00006417          	auipc	s0,0x6
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0206008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00001517          	auipc	a0,0x1
ffffffffc0200260:	60450513          	addi	a0,a0,1540 # ffffffffc0201860 <etext+0x134>
ffffffffc0200264:	ee9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026c:	00001517          	auipc	a0,0x1
ffffffffc0200270:	60c50513          	addi	a0,a0,1548 # ffffffffc0201878 <etext+0x14c>
    if (boot_dtb == 0) {
ffffffffc0200274:	120a0463          	beqz	s4,ffffffffc020039c <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200278:	57f5                	li	a5,-3
ffffffffc020027a:	07fa                	slli	a5,a5,0x1e
ffffffffc020027c:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200280:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200286:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200288:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020028c:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029c:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029e:	8ec9                	or	a3,a3,a0
ffffffffc02002a0:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002a4:	1b7d                	addi	s6,s6,-1
ffffffffc02002a6:	0167f7b3          	and	a5,a5,s6
ffffffffc02002aa:	8dd5                	or	a1,a1,a3
ffffffffc02002ac:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002ae:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b2:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002b4:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9e75>
ffffffffc02002b8:	10f59163          	bne	a1,a5,ffffffffc02003ba <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002bc:	471c                	lw	a5,8(a4)
ffffffffc02002be:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002c0:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002c6:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002ca:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002da:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002de:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ec:	01146433          	or	s0,s0,a7
ffffffffc02002f0:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002f4:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f8:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002fe:	8c49                	or	s0,s0,a0
ffffffffc0200300:	0166f6b3          	and	a3,a3,s6
ffffffffc0200304:	00ca6a33          	or	s4,s4,a2
ffffffffc0200308:	0167f7b3          	and	a5,a5,s6
ffffffffc020030c:	8c55                	or	s0,s0,a3
ffffffffc020030e:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200318:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200320:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200324:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200326:	00001917          	auipc	s2,0x1
ffffffffc020032a:	5a290913          	addi	s2,s2,1442 # ffffffffc02018c8 <etext+0x19c>
ffffffffc020032e:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200330:	4d91                	li	s11,4
ffffffffc0200332:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200334:	00001497          	auipc	s1,0x1
ffffffffc0200338:	58c48493          	addi	s1,s1,1420 # ffffffffc02018c0 <etext+0x194>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033c:	000a2703          	lw	a4,0(s4)
ffffffffc0200340:	004a0a93          	addi	s5,s4,4
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
ffffffffc020035a:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200362:	8fd5                	or	a5,a5,a3
ffffffffc0200364:	00eb7733          	and	a4,s6,a4
ffffffffc0200368:	8fd9                	or	a5,a5,a4
ffffffffc020036a:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020036c:	09778c63          	beq	a5,s7,ffffffffc0200404 <dtb_init+0x1ee>
ffffffffc0200370:	00fbea63          	bltu	s7,a5,ffffffffc0200384 <dtb_init+0x16e>
ffffffffc0200374:	07a78663          	beq	a5,s10,ffffffffc02003e0 <dtb_init+0x1ca>
ffffffffc0200378:	4709                	li	a4,2
ffffffffc020037a:	00e79763          	bne	a5,a4,ffffffffc0200388 <dtb_init+0x172>
ffffffffc020037e:	4c81                	li	s9,0
ffffffffc0200380:	8a56                	mv	s4,s5
ffffffffc0200382:	bf6d                	j	ffffffffc020033c <dtb_init+0x126>
ffffffffc0200384:	ffb78ee3          	beq	a5,s11,ffffffffc0200380 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200388:	00001517          	auipc	a0,0x1
ffffffffc020038c:	5b850513          	addi	a0,a0,1464 # ffffffffc0201940 <etext+0x214>
ffffffffc0200390:	dbdff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200394:	00001517          	auipc	a0,0x1
ffffffffc0200398:	5e450513          	addi	a0,a0,1508 # ffffffffc0201978 <etext+0x24c>
}
ffffffffc020039c:	7446                	ld	s0,112(sp)
ffffffffc020039e:	70e6                	ld	ra,120(sp)
ffffffffc02003a0:	74a6                	ld	s1,104(sp)
ffffffffc02003a2:	7906                	ld	s2,96(sp)
ffffffffc02003a4:	69e6                	ld	s3,88(sp)
ffffffffc02003a6:	6a46                	ld	s4,80(sp)
ffffffffc02003a8:	6aa6                	ld	s5,72(sp)
ffffffffc02003aa:	6b06                	ld	s6,64(sp)
ffffffffc02003ac:	7be2                	ld	s7,56(sp)
ffffffffc02003ae:	7c42                	ld	s8,48(sp)
ffffffffc02003b0:	7ca2                	ld	s9,40(sp)
ffffffffc02003b2:	7d02                	ld	s10,32(sp)
ffffffffc02003b4:	6de2                	ld	s11,24(sp)
ffffffffc02003b6:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003b8:	bb51                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003ba:	7446                	ld	s0,112(sp)
ffffffffc02003bc:	70e6                	ld	ra,120(sp)
ffffffffc02003be:	74a6                	ld	s1,104(sp)
ffffffffc02003c0:	7906                	ld	s2,96(sp)
ffffffffc02003c2:	69e6                	ld	s3,88(sp)
ffffffffc02003c4:	6a46                	ld	s4,80(sp)
ffffffffc02003c6:	6aa6                	ld	s5,72(sp)
ffffffffc02003c8:	6b06                	ld	s6,64(sp)
ffffffffc02003ca:	7be2                	ld	s7,56(sp)
ffffffffc02003cc:	7c42                	ld	s8,48(sp)
ffffffffc02003ce:	7ca2                	ld	s9,40(sp)
ffffffffc02003d0:	7d02                	ld	s10,32(sp)
ffffffffc02003d2:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003d4:	00001517          	auipc	a0,0x1
ffffffffc02003d8:	4c450513          	addi	a0,a0,1220 # ffffffffc0201898 <etext+0x16c>
}
ffffffffc02003dc:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	b3bd                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003e0:	8556                	mv	a0,s5
ffffffffc02003e2:	6b7000ef          	jal	ra,ffffffffc0201298 <strlen>
ffffffffc02003e6:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	4619                	li	a2,6
ffffffffc02003ea:	85a6                	mv	a1,s1
ffffffffc02003ec:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003ee:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f0:	6fd000ef          	jal	ra,ffffffffc02012ec <strncmp>
ffffffffc02003f4:	e111                	bnez	a0,ffffffffc02003f8 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02003f6:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003f8:	0a91                	addi	s5,s5,4
ffffffffc02003fa:	9ad2                	add	s5,s5,s4
ffffffffc02003fc:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200400:	8a56                	mv	s4,s5
ffffffffc0200402:	bf2d                	j	ffffffffc020033c <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200404:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200408:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040c:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200410:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200414:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200418:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200420:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200424:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200428:	0087979b          	slliw	a5,a5,0x8
ffffffffc020042c:	00eaeab3          	or	s5,s5,a4
ffffffffc0200430:	00fb77b3          	and	a5,s6,a5
ffffffffc0200434:	00faeab3          	or	s5,s5,a5
ffffffffc0200438:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020043a:	000c9c63          	bnez	s9,ffffffffc0200452 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020043e:	1a82                	slli	s5,s5,0x20
ffffffffc0200440:	00368793          	addi	a5,a3,3
ffffffffc0200444:	020ada93          	srli	s5,s5,0x20
ffffffffc0200448:	9abe                	add	s5,s5,a5
ffffffffc020044a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020044e:	8a56                	mv	s4,s5
ffffffffc0200450:	b5f5                	j	ffffffffc020033c <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200452:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200456:	85ca                	mv	a1,s2
ffffffffc0200458:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200462:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200466:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020046e:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200470:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200478:	8d59                	or	a0,a0,a4
ffffffffc020047a:	00fb77b3          	and	a5,s6,a5
ffffffffc020047e:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200480:	1502                	slli	a0,a0,0x20
ffffffffc0200482:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200484:	9522                	add	a0,a0,s0
ffffffffc0200486:	649000ef          	jal	ra,ffffffffc02012ce <strcmp>
ffffffffc020048a:	66a2                	ld	a3,8(sp)
ffffffffc020048c:	f94d                	bnez	a0,ffffffffc020043e <dtb_init+0x228>
ffffffffc020048e:	fb59f8e3          	bgeu	s3,s5,ffffffffc020043e <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200492:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200496:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020049a:	00001517          	auipc	a0,0x1
ffffffffc020049e:	43650513          	addi	a0,a0,1078 # ffffffffc02018d0 <etext+0x1a4>
           fdt32_to_cpu(x >> 32);
ffffffffc02004a2:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a6:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004aa:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ae:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004b2:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ba:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004be:	0187d693          	srli	a3,a5,0x18
ffffffffc02004c2:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004c6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004ca:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004d2:	010f6f33          	or	t5,t5,a6
ffffffffc02004d6:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004da:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004de:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e2:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e6:	0186f6b3          	and	a3,a3,s8
ffffffffc02004ea:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004ee:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f2:	0107581b          	srliw	a6,a4,0x10
ffffffffc02004f6:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fa:	8361                	srli	a4,a4,0x18
ffffffffc02004fc:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200504:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200508:	00cb7633          	and	a2,s6,a2
ffffffffc020050c:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200510:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200514:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200518:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051c:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200520:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200524:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200528:	011b78b3          	and	a7,s6,a7
ffffffffc020052c:	005eeeb3          	or	t4,t4,t0
ffffffffc0200530:	00c6e733          	or	a4,a3,a2
ffffffffc0200534:	006c6c33          	or	s8,s8,t1
ffffffffc0200538:	010b76b3          	and	a3,s6,a6
ffffffffc020053c:	00bb7b33          	and	s6,s6,a1
ffffffffc0200540:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200544:	016c6b33          	or	s6,s8,s6
ffffffffc0200548:	01146433          	or	s0,s0,a7
ffffffffc020054c:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc020054e:	1702                	slli	a4,a4,0x20
ffffffffc0200550:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200552:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200554:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200556:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	0167eb33          	or	s6,a5,s6
ffffffffc0200560:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200562:	bebff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200566:	85a2                	mv	a1,s0
ffffffffc0200568:	00001517          	auipc	a0,0x1
ffffffffc020056c:	38850513          	addi	a0,a0,904 # ffffffffc02018f0 <etext+0x1c4>
ffffffffc0200570:	bddff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200574:	014b5613          	srli	a2,s6,0x14
ffffffffc0200578:	85da                	mv	a1,s6
ffffffffc020057a:	00001517          	auipc	a0,0x1
ffffffffc020057e:	38e50513          	addi	a0,a0,910 # ffffffffc0201908 <etext+0x1dc>
ffffffffc0200582:	bcbff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200586:	008b05b3          	add	a1,s6,s0
ffffffffc020058a:	15fd                	addi	a1,a1,-1
ffffffffc020058c:	00001517          	auipc	a0,0x1
ffffffffc0200590:	39c50513          	addi	a0,a0,924 # ffffffffc0201928 <etext+0x1fc>
ffffffffc0200594:	bb9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	3e050513          	addi	a0,a0,992 # ffffffffc0201978 <etext+0x24c>
        memory_base = mem_base;
ffffffffc02005a0:	00006797          	auipc	a5,0x6
ffffffffc02005a4:	a887bc23          	sd	s0,-1384(a5) # ffffffffc0206038 <memory_base>
        memory_size = mem_size;
ffffffffc02005a8:	00006797          	auipc	a5,0x6
ffffffffc02005ac:	a967bc23          	sd	s6,-1384(a5) # ffffffffc0206040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005b0:	b3f5                	j	ffffffffc020039c <dtb_init+0x186>

ffffffffc02005b2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005b2:	00006517          	auipc	a0,0x6
ffffffffc02005b6:	a8653503          	ld	a0,-1402(a0) # ffffffffc0206038 <memory_base>
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	a8453503          	ld	a0,-1404(a0) # ffffffffc0206040 <memory_size>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005c6:	8082                	ret

ffffffffc02005c8 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02005c8:	0ff57513          	zext.b	a0,a0
ffffffffc02005cc:	1460106f          	j	ffffffffc0201712 <sbi_console_putchar>

ffffffffc02005d0 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	a887b783          	ld	a5,-1400(a5) # ffffffffc0206058 <pmm_manager>
ffffffffc02005d8:	6f9c                	ld	a5,24(a5)
ffffffffc02005da:	8782                	jr	a5

ffffffffc02005dc <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02005dc:	00006797          	auipc	a5,0x6
ffffffffc02005e0:	a7c7b783          	ld	a5,-1412(a5) # ffffffffc0206058 <pmm_manager>
ffffffffc02005e4:	739c                	ld	a5,32(a5)
ffffffffc02005e6:	8782                	jr	a5

ffffffffc02005e8 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02005e8:	00006797          	auipc	a5,0x6
ffffffffc02005ec:	a707b783          	ld	a5,-1424(a5) # ffffffffc0206058 <pmm_manager>
ffffffffc02005f0:	779c                	ld	a5,40(a5)
ffffffffc02005f2:	8782                	jr	a5

ffffffffc02005f4 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02005f4:	00002797          	auipc	a5,0x2
ffffffffc02005f8:	8a478793          	addi	a5,a5,-1884 # ffffffffc0201e98 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005fc:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02005fe:	7179                	addi	sp,sp,-48
ffffffffc0200600:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200602:	00001517          	auipc	a0,0x1
ffffffffc0200606:	38e50513          	addi	a0,a0,910 # ffffffffc0201990 <etext+0x264>
    pmm_manager = &default_pmm_manager;
ffffffffc020060a:	00006417          	auipc	s0,0x6
ffffffffc020060e:	a4e40413          	addi	s0,s0,-1458 # ffffffffc0206058 <pmm_manager>
void pmm_init(void) {
ffffffffc0200612:	f406                	sd	ra,40(sp)
ffffffffc0200614:	ec26                	sd	s1,24(sp)
ffffffffc0200616:	e44e                	sd	s3,8(sp)
ffffffffc0200618:	e84a                	sd	s2,16(sp)
ffffffffc020061a:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020061c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020061e:	b2fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200622:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200624:	00006497          	auipc	s1,0x6
ffffffffc0200628:	a4c48493          	addi	s1,s1,-1460 # ffffffffc0206070 <va_pa_offset>
    pmm_manager->init();
ffffffffc020062c:	679c                	ld	a5,8(a5)
ffffffffc020062e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200630:	57f5                	li	a5,-3
ffffffffc0200632:	07fa                	slli	a5,a5,0x1e
ffffffffc0200634:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200636:	f7dff0ef          	jal	ra,ffffffffc02005b2 <get_memory_base>
ffffffffc020063a:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020063c:	f81ff0ef          	jal	ra,ffffffffc02005bc <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200640:	14050c63          	beqz	a0,ffffffffc0200798 <pmm_init+0x1a4>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200644:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200646:	00001517          	auipc	a0,0x1
ffffffffc020064a:	39250513          	addi	a0,a0,914 # ffffffffc02019d8 <etext+0x2ac>
ffffffffc020064e:	affff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200652:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200656:	864e                	mv	a2,s3
ffffffffc0200658:	fffa0693          	addi	a3,s4,-1
ffffffffc020065c:	85ca                	mv	a1,s2
ffffffffc020065e:	00001517          	auipc	a0,0x1
ffffffffc0200662:	39250513          	addi	a0,a0,914 # ffffffffc02019f0 <etext+0x2c4>
ffffffffc0200666:	ae7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020066a:	c80007b7          	lui	a5,0xc8000
ffffffffc020066e:	8652                	mv	a2,s4
ffffffffc0200670:	0d47e363          	bltu	a5,s4,ffffffffc0200736 <pmm_init+0x142>
ffffffffc0200674:	00007797          	auipc	a5,0x7
ffffffffc0200678:	a0378793          	addi	a5,a5,-1533 # ffffffffc0207077 <end+0xfff>
ffffffffc020067c:	757d                	lui	a0,0xfffff
ffffffffc020067e:	8d7d                	and	a0,a0,a5
ffffffffc0200680:	8231                	srli	a2,a2,0xc
ffffffffc0200682:	00006797          	auipc	a5,0x6
ffffffffc0200686:	9cc7b323          	sd	a2,-1594(a5) # ffffffffc0206048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020068a:	00006797          	auipc	a5,0x6
ffffffffc020068e:	9ca7b323          	sd	a0,-1594(a5) # ffffffffc0206050 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200692:	000807b7          	lui	a5,0x80
ffffffffc0200696:	002005b7          	lui	a1,0x200
ffffffffc020069a:	02f60563          	beq	a2,a5,ffffffffc02006c4 <pmm_init+0xd0>
ffffffffc020069e:	00261593          	slli	a1,a2,0x2
ffffffffc02006a2:	00c586b3          	add	a3,a1,a2
ffffffffc02006a6:	fec007b7          	lui	a5,0xfec00
ffffffffc02006aa:	97aa                	add	a5,a5,a0
ffffffffc02006ac:	068e                	slli	a3,a3,0x3
ffffffffc02006ae:	96be                	add	a3,a3,a5
ffffffffc02006b0:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc02006b2:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02006b4:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9fb0>
        SetPageReserved(pages + i);
ffffffffc02006b8:	00176713          	ori	a4,a4,1
ffffffffc02006bc:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02006c0:	fef699e3          	bne	a3,a5,ffffffffc02006b2 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006c4:	95b2                	add	a1,a1,a2
ffffffffc02006c6:	fec006b7          	lui	a3,0xfec00
ffffffffc02006ca:	96aa                	add	a3,a3,a0
ffffffffc02006cc:	058e                	slli	a1,a1,0x3
ffffffffc02006ce:	96ae                	add	a3,a3,a1
ffffffffc02006d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02006d4:	0af6e663          	bltu	a3,a5,ffffffffc0200780 <pmm_init+0x18c>
ffffffffc02006d8:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02006da:	77fd                	lui	a5,0xfffff
ffffffffc02006dc:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006e0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02006e2:	04b6ed63          	bltu	a3,a1,ffffffffc020073c <pmm_init+0x148>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02006e6:	601c                	ld	a5,0(s0)
ffffffffc02006e8:	7b9c                	ld	a5,48(a5)
ffffffffc02006ea:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02006ec:	00001517          	auipc	a0,0x1
ffffffffc02006f0:	38c50513          	addi	a0,a0,908 # ffffffffc0201a78 <etext+0x34c>
ffffffffc02006f4:	a59ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02006f8:	00005597          	auipc	a1,0x5
ffffffffc02006fc:	90858593          	addi	a1,a1,-1784 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200700:	00006797          	auipc	a5,0x6
ffffffffc0200704:	96b7b423          	sd	a1,-1688(a5) # ffffffffc0206068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200708:	c02007b7          	lui	a5,0xc0200
ffffffffc020070c:	0af5e263          	bltu	a1,a5,ffffffffc02007b0 <pmm_init+0x1bc>
ffffffffc0200710:	6090                	ld	a2,0(s1)
}
ffffffffc0200712:	7402                	ld	s0,32(sp)
ffffffffc0200714:	70a2                	ld	ra,40(sp)
ffffffffc0200716:	64e2                	ld	s1,24(sp)
ffffffffc0200718:	6942                	ld	s2,16(sp)
ffffffffc020071a:	69a2                	ld	s3,8(sp)
ffffffffc020071c:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020071e:	40c58633          	sub	a2,a1,a2
ffffffffc0200722:	00006797          	auipc	a5,0x6
ffffffffc0200726:	92c7bf23          	sd	a2,-1730(a5) # ffffffffc0206060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020072a:	00001517          	auipc	a0,0x1
ffffffffc020072e:	36e50513          	addi	a0,a0,878 # ffffffffc0201a98 <etext+0x36c>
}
ffffffffc0200732:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200734:	bc21                	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200736:	c8000637          	lui	a2,0xc8000
ffffffffc020073a:	bf2d                	j	ffffffffc0200674 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020073c:	6705                	lui	a4,0x1
ffffffffc020073e:	177d                	addi	a4,a4,-1
ffffffffc0200740:	96ba                	add	a3,a3,a4
ffffffffc0200742:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200744:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200748:	02c7f063          	bgeu	a5,a2,ffffffffc0200768 <pmm_init+0x174>
    pmm_manager->init_memmap(base, n);
ffffffffc020074c:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020074e:	fff80737          	lui	a4,0xfff80
ffffffffc0200752:	973e                	add	a4,a4,a5
ffffffffc0200754:	00271793          	slli	a5,a4,0x2
ffffffffc0200758:	97ba                	add	a5,a5,a4
ffffffffc020075a:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020075c:	8d95                	sub	a1,a1,a3
ffffffffc020075e:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200760:	81b1                	srli	a1,a1,0xc
ffffffffc0200762:	953e                	add	a0,a0,a5
ffffffffc0200764:	9702                	jalr	a4
}
ffffffffc0200766:	b741                	j	ffffffffc02006e6 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200768:	00001617          	auipc	a2,0x1
ffffffffc020076c:	2e060613          	addi	a2,a2,736 # ffffffffc0201a48 <etext+0x31c>
ffffffffc0200770:	06a00593          	li	a1,106
ffffffffc0200774:	00001517          	auipc	a0,0x1
ffffffffc0200778:	2f450513          	addi	a0,a0,756 # ffffffffc0201a68 <etext+0x33c>
ffffffffc020077c:	a47ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200780:	00001617          	auipc	a2,0x1
ffffffffc0200784:	2a060613          	addi	a2,a2,672 # ffffffffc0201a20 <etext+0x2f4>
ffffffffc0200788:	05e00593          	li	a1,94
ffffffffc020078c:	00001517          	auipc	a0,0x1
ffffffffc0200790:	23c50513          	addi	a0,a0,572 # ffffffffc02019c8 <etext+0x29c>
ffffffffc0200794:	a2fff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200798:	00001617          	auipc	a2,0x1
ffffffffc020079c:	21060613          	addi	a2,a2,528 # ffffffffc02019a8 <etext+0x27c>
ffffffffc02007a0:	04600593          	li	a1,70
ffffffffc02007a4:	00001517          	auipc	a0,0x1
ffffffffc02007a8:	22450513          	addi	a0,a0,548 # ffffffffc02019c8 <etext+0x29c>
ffffffffc02007ac:	a17ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02007b0:	86ae                	mv	a3,a1
ffffffffc02007b2:	00001617          	auipc	a2,0x1
ffffffffc02007b6:	26e60613          	addi	a2,a2,622 # ffffffffc0201a20 <etext+0x2f4>
ffffffffc02007ba:	07900593          	li	a1,121
ffffffffc02007be:	00001517          	auipc	a0,0x1
ffffffffc02007c2:	20a50513          	addi	a0,a0,522 # ffffffffc02019c8 <etext+0x29c>
ffffffffc02007c6:	9fdff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007ca <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02007ca:	00006797          	auipc	a5,0x6
ffffffffc02007ce:	84e78793          	addi	a5,a5,-1970 # ffffffffc0206018 <free_area>
ffffffffc02007d2:	e79c                	sd	a5,8(a5)
ffffffffc02007d4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02007d6:	0007a823          	sw	zero,16(a5)
}
ffffffffc02007da:	8082                	ret

ffffffffc02007dc <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02007dc:	00006517          	auipc	a0,0x6
ffffffffc02007e0:	84c56503          	lwu	a0,-1972(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02007e4:	8082                	ret

ffffffffc02007e6 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02007e6:	c949                	beqz	a0,ffffffffc0200878 <default_alloc_pages+0x92>
    if (n > nr_free) {
ffffffffc02007e8:	00006597          	auipc	a1,0x6
ffffffffc02007ec:	83058593          	addi	a1,a1,-2000 # ffffffffc0206018 <free_area>
ffffffffc02007f0:	0105a803          	lw	a6,16(a1)
ffffffffc02007f4:	862a                	mv	a2,a0
ffffffffc02007f6:	02081793          	slli	a5,a6,0x20
ffffffffc02007fa:	9381                	srli	a5,a5,0x20
ffffffffc02007fc:	00a7ee63          	bltu	a5,a0,ffffffffc0200818 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0200800:	87ae                	mv	a5,a1
ffffffffc0200802:	a801                	j	ffffffffc0200812 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0200804:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200808:	02071693          	slli	a3,a4,0x20
ffffffffc020080c:	9281                	srli	a3,a3,0x20
ffffffffc020080e:	00c6f763          	bgeu	a3,a2,ffffffffc020081c <default_alloc_pages+0x36>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200812:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200814:	feb798e3          	bne	a5,a1,ffffffffc0200804 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0200818:	4501                	li	a0,0
}
ffffffffc020081a:	8082                	ret
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020081c:	0007b303          	ld	t1,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200820:	0087b883          	ld	a7,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0200824:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0200828:	00060e1b          	sext.w	t3,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020082c:	01133423          	sd	a7,8(t1)
    next->prev = prev;
ffffffffc0200830:	0068b023          	sd	t1,0(a7)
        if (page->property > n) {
ffffffffc0200834:	02d67863          	bgeu	a2,a3,ffffffffc0200864 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0200838:	00261693          	slli	a3,a2,0x2
ffffffffc020083c:	96b2                	add	a3,a3,a2
ffffffffc020083e:	068e                	slli	a3,a3,0x3
ffffffffc0200840:	96aa                	add	a3,a3,a0
            SetPageProperty(p);
ffffffffc0200842:	6690                	ld	a2,8(a3)
            p->property = page->property - n;
ffffffffc0200844:	41c7073b          	subw	a4,a4,t3
ffffffffc0200848:	ca98                	sw	a4,16(a3)
            SetPageProperty(p);
ffffffffc020084a:	00266713          	ori	a4,a2,2
ffffffffc020084e:	e698                	sd	a4,8(a3)
            list_add(prev, &(p->page_link));
ffffffffc0200850:	01868713          	addi	a4,a3,24 # fffffffffec00018 <end+0x3e9f9fa0>
    prev->next = next->prev = elm;
ffffffffc0200854:	00e8b023          	sd	a4,0(a7)
ffffffffc0200858:	00e33423          	sd	a4,8(t1)
    elm->next = next;
ffffffffc020085c:	0316b023          	sd	a7,32(a3)
    elm->prev = prev;
ffffffffc0200860:	0066bc23          	sd	t1,24(a3)
        ClearPageProperty(page);
ffffffffc0200864:	ff07b703          	ld	a4,-16(a5)
        nr_free -= n;
ffffffffc0200868:	41c8083b          	subw	a6,a6,t3
ffffffffc020086c:	0105a823          	sw	a6,16(a1)
        ClearPageProperty(page);
ffffffffc0200870:	9b75                	andi	a4,a4,-3
ffffffffc0200872:	fee7b823          	sd	a4,-16(a5)
ffffffffc0200876:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0200878:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020087a:	00001697          	auipc	a3,0x1
ffffffffc020087e:	25e68693          	addi	a3,a3,606 # ffffffffc0201ad8 <etext+0x3ac>
ffffffffc0200882:	00001617          	auipc	a2,0x1
ffffffffc0200886:	25e60613          	addi	a2,a2,606 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc020088a:	06200593          	li	a1,98
ffffffffc020088e:	00001517          	auipc	a0,0x1
ffffffffc0200892:	26a50513          	addi	a0,a0,618 # ffffffffc0201af8 <etext+0x3cc>
default_alloc_pages(size_t n) {
ffffffffc0200896:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200898:	92bff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020089c <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc020089c:	715d                	addi	sp,sp,-80
ffffffffc020089e:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008a0:	00005417          	auipc	s0,0x5
ffffffffc02008a4:	77840413          	addi	s0,s0,1912 # ffffffffc0206018 <free_area>
ffffffffc02008a8:	641c                	ld	a5,8(s0)
ffffffffc02008aa:	e486                	sd	ra,72(sp)
ffffffffc02008ac:	fc26                	sd	s1,56(sp)
ffffffffc02008ae:	f84a                	sd	s2,48(sp)
ffffffffc02008b0:	f44e                	sd	s3,40(sp)
ffffffffc02008b2:	f052                	sd	s4,32(sp)
ffffffffc02008b4:	ec56                	sd	s5,24(sp)
ffffffffc02008b6:	e85a                	sd	s6,16(sp)
ffffffffc02008b8:	e45e                	sd	s7,8(sp)
ffffffffc02008ba:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008bc:	2c878363          	beq	a5,s0,ffffffffc0200b82 <default_check+0x2e6>
    int count = 0, total = 0;
ffffffffc02008c0:	4481                	li	s1,0
ffffffffc02008c2:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02008c4:	ff07b703          	ld	a4,-16(a5)
ffffffffc02008c8:	8b09                	andi	a4,a4,2
ffffffffc02008ca:	2c070063          	beqz	a4,ffffffffc0200b8a <default_check+0x2ee>
        count ++, total += p->property;
ffffffffc02008ce:	ff87a703          	lw	a4,-8(a5)
ffffffffc02008d2:	679c                	ld	a5,8(a5)
ffffffffc02008d4:	2905                	addiw	s2,s2,1
ffffffffc02008d6:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008d8:	fe8796e3          	bne	a5,s0,ffffffffc02008c4 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02008dc:	89a6                	mv	s3,s1
ffffffffc02008de:	d0bff0ef          	jal	ra,ffffffffc02005e8 <nr_free_pages>
ffffffffc02008e2:	71351463          	bne	a0,s3,ffffffffc0200fea <default_check+0x74e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02008e6:	4505                	li	a0,1
ffffffffc02008e8:	ce9ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02008ec:	8a2a                	mv	s4,a0
ffffffffc02008ee:	42050e63          	beqz	a0,ffffffffc0200d2a <default_check+0x48e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02008f2:	4505                	li	a0,1
ffffffffc02008f4:	cddff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02008f8:	89aa                	mv	s3,a0
ffffffffc02008fa:	70050863          	beqz	a0,ffffffffc020100a <default_check+0x76e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02008fe:	4505                	li	a0,1
ffffffffc0200900:	cd1ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200904:	8aaa                	mv	s5,a0
ffffffffc0200906:	4a050263          	beqz	a0,ffffffffc0200daa <default_check+0x50e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020090a:	2b3a0063          	beq	s4,s3,ffffffffc0200baa <default_check+0x30e>
ffffffffc020090e:	28aa0e63          	beq	s4,a0,ffffffffc0200baa <default_check+0x30e>
ffffffffc0200912:	28a98c63          	beq	s3,a0,ffffffffc0200baa <default_check+0x30e>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200916:	000a2783          	lw	a5,0(s4)
ffffffffc020091a:	2a079863          	bnez	a5,ffffffffc0200bca <default_check+0x32e>
ffffffffc020091e:	0009a783          	lw	a5,0(s3)
ffffffffc0200922:	2a079463          	bnez	a5,ffffffffc0200bca <default_check+0x32e>
ffffffffc0200926:	411c                	lw	a5,0(a0)
ffffffffc0200928:	2a079163          	bnez	a5,ffffffffc0200bca <default_check+0x32e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020092c:	00005797          	auipc	a5,0x5
ffffffffc0200930:	7247b783          	ld	a5,1828(a5) # ffffffffc0206050 <pages>
ffffffffc0200934:	40fa0733          	sub	a4,s4,a5
ffffffffc0200938:	870d                	srai	a4,a4,0x3
ffffffffc020093a:	00001597          	auipc	a1,0x1
ffffffffc020093e:	7e65b583          	ld	a1,2022(a1) # ffffffffc0202120 <nbase+0x8>
ffffffffc0200942:	02b70733          	mul	a4,a4,a1
ffffffffc0200946:	00001617          	auipc	a2,0x1
ffffffffc020094a:	7d263603          	ld	a2,2002(a2) # ffffffffc0202118 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020094e:	00005697          	auipc	a3,0x5
ffffffffc0200952:	6fa6b683          	ld	a3,1786(a3) # ffffffffc0206048 <npage>
ffffffffc0200956:	06b2                	slli	a3,a3,0xc
ffffffffc0200958:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020095a:	0732                	slli	a4,a4,0xc
ffffffffc020095c:	28d77763          	bgeu	a4,a3,ffffffffc0200bea <default_check+0x34e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200960:	40f98733          	sub	a4,s3,a5
ffffffffc0200964:	870d                	srai	a4,a4,0x3
ffffffffc0200966:	02b70733          	mul	a4,a4,a1
ffffffffc020096a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020096c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020096e:	4ad77e63          	bgeu	a4,a3,ffffffffc0200e2a <default_check+0x58e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200972:	40f507b3          	sub	a5,a0,a5
ffffffffc0200976:	878d                	srai	a5,a5,0x3
ffffffffc0200978:	02b787b3          	mul	a5,a5,a1
ffffffffc020097c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020097e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200980:	30d7f563          	bgeu	a5,a3,ffffffffc0200c8a <default_check+0x3ee>
    assert(alloc_page() == NULL);
ffffffffc0200984:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200986:	00043c03          	ld	s8,0(s0)
ffffffffc020098a:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020098e:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200992:	e400                	sd	s0,8(s0)
ffffffffc0200994:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200996:	00005797          	auipc	a5,0x5
ffffffffc020099a:	6807a923          	sw	zero,1682(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020099e:	c33ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009a2:	2c051463          	bnez	a0,ffffffffc0200c6a <default_check+0x3ce>
    free_page(p0);
ffffffffc02009a6:	4585                	li	a1,1
ffffffffc02009a8:	8552                	mv	a0,s4
ffffffffc02009aa:	c33ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p1);
ffffffffc02009ae:	4585                	li	a1,1
ffffffffc02009b0:	854e                	mv	a0,s3
ffffffffc02009b2:	c2bff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p2);
ffffffffc02009b6:	4585                	li	a1,1
ffffffffc02009b8:	8556                	mv	a0,s5
ffffffffc02009ba:	c23ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(nr_free == 3);
ffffffffc02009be:	4818                	lw	a4,16(s0)
ffffffffc02009c0:	478d                	li	a5,3
ffffffffc02009c2:	28f71463          	bne	a4,a5,ffffffffc0200c4a <default_check+0x3ae>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009c6:	4505                	li	a0,1
ffffffffc02009c8:	c09ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009cc:	89aa                	mv	s3,a0
ffffffffc02009ce:	24050e63          	beqz	a0,ffffffffc0200c2a <default_check+0x38e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009d2:	4505                	li	a0,1
ffffffffc02009d4:	bfdff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009d8:	8aaa                	mv	s5,a0
ffffffffc02009da:	3a050863          	beqz	a0,ffffffffc0200d8a <default_check+0x4ee>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009de:	4505                	li	a0,1
ffffffffc02009e0:	bf1ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009e4:	8a2a                	mv	s4,a0
ffffffffc02009e6:	38050263          	beqz	a0,ffffffffc0200d6a <default_check+0x4ce>
    assert(alloc_page() == NULL);
ffffffffc02009ea:	4505                	li	a0,1
ffffffffc02009ec:	be5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009f0:	34051d63          	bnez	a0,ffffffffc0200d4a <default_check+0x4ae>
    free_page(p0);
ffffffffc02009f4:	4585                	li	a1,1
ffffffffc02009f6:	854e                	mv	a0,s3
ffffffffc02009f8:	be5ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02009fc:	641c                	ld	a5,8(s0)
ffffffffc02009fe:	20878663          	beq	a5,s0,ffffffffc0200c0a <default_check+0x36e>
    assert((p = alloc_page()) == p0);
ffffffffc0200a02:	4505                	li	a0,1
ffffffffc0200a04:	bcdff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a08:	30a99163          	bne	s3,a0,ffffffffc0200d0a <default_check+0x46e>
    assert(alloc_page() == NULL);
ffffffffc0200a0c:	4505                	li	a0,1
ffffffffc0200a0e:	bc3ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a12:	2c051c63          	bnez	a0,ffffffffc0200cea <default_check+0x44e>
    assert(nr_free == 0);
ffffffffc0200a16:	481c                	lw	a5,16(s0)
ffffffffc0200a18:	2a079963          	bnez	a5,ffffffffc0200cca <default_check+0x42e>
    free_page(p);
ffffffffc0200a1c:	854e                	mv	a0,s3
ffffffffc0200a1e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a20:	01843023          	sd	s8,0(s0)
ffffffffc0200a24:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a28:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a2c:	bb1ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p1);
ffffffffc0200a30:	4585                	li	a1,1
ffffffffc0200a32:	8556                	mv	a0,s5
ffffffffc0200a34:	ba9ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p2);
ffffffffc0200a38:	4585                	li	a1,1
ffffffffc0200a3a:	8552                	mv	a0,s4
ffffffffc0200a3c:	ba1ff0ef          	jal	ra,ffffffffc02005dc <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a40:	4515                	li	a0,5
ffffffffc0200a42:	b8fff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a46:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a48:	26050163          	beqz	a0,ffffffffc0200caa <default_check+0x40e>
    assert(!PageProperty(p0));
ffffffffc0200a4c:	651c                	ld	a5,8(a0)
ffffffffc0200a4e:	8b89                	andi	a5,a5,2
ffffffffc0200a50:	52079d63          	bnez	a5,ffffffffc0200f8a <default_check+0x6ee>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200a54:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a56:	00043b83          	ld	s7,0(s0)
ffffffffc0200a5a:	00843b03          	ld	s6,8(s0)
ffffffffc0200a5e:	e000                	sd	s0,0(s0)
ffffffffc0200a60:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200a62:	b6fff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a66:	50051263          	bnez	a0,ffffffffc0200f6a <default_check+0x6ce>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200a6a:	05098a13          	addi	s4,s3,80
ffffffffc0200a6e:	8552                	mv	a0,s4
ffffffffc0200a70:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200a72:	01042c03          	lw	s8,16(s0)
    nr_free = 0;
ffffffffc0200a76:	00005797          	auipc	a5,0x5
ffffffffc0200a7a:	5a07a923          	sw	zero,1458(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200a7e:	b5fff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200a82:	4511                	li	a0,4
ffffffffc0200a84:	b4dff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a88:	4c051163          	bnez	a0,ffffffffc0200f4a <default_check+0x6ae>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200a8c:	0589b783          	ld	a5,88(s3)
ffffffffc0200a90:	8b89                	andi	a5,a5,2
ffffffffc0200a92:	48078c63          	beqz	a5,ffffffffc0200f2a <default_check+0x68e>
ffffffffc0200a96:	0609a703          	lw	a4,96(s3)
ffffffffc0200a9a:	478d                	li	a5,3
ffffffffc0200a9c:	48f71763          	bne	a4,a5,ffffffffc0200f2a <default_check+0x68e>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200aa0:	450d                	li	a0,3
ffffffffc0200aa2:	b2fff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200aa6:	8aaa                	mv	s5,a0
ffffffffc0200aa8:	46050163          	beqz	a0,ffffffffc0200f0a <default_check+0x66e>
    assert(alloc_page() == NULL);
ffffffffc0200aac:	4505                	li	a0,1
ffffffffc0200aae:	b23ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ab2:	42051c63          	bnez	a0,ffffffffc0200eea <default_check+0x64e>
    assert(p0 + 2 == p1);
ffffffffc0200ab6:	415a1a63          	bne	s4,s5,ffffffffc0200eca <default_check+0x62e>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200aba:	4585                	li	a1,1
ffffffffc0200abc:	854e                	mv	a0,s3
ffffffffc0200abe:	b1fff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_pages(p1, 3);
ffffffffc0200ac2:	458d                	li	a1,3
ffffffffc0200ac4:	8552                	mv	a0,s4
ffffffffc0200ac6:	b17ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200aca:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200ace:	02898a93          	addi	s5,s3,40
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200ad2:	8b89                	andi	a5,a5,2
ffffffffc0200ad4:	3c078b63          	beqz	a5,ffffffffc0200eaa <default_check+0x60e>
ffffffffc0200ad8:	0109a703          	lw	a4,16(s3)
ffffffffc0200adc:	4785                	li	a5,1
ffffffffc0200ade:	3cf71663          	bne	a4,a5,ffffffffc0200eaa <default_check+0x60e>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200ae2:	008a3783          	ld	a5,8(s4)
ffffffffc0200ae6:	8b89                	andi	a5,a5,2
ffffffffc0200ae8:	3a078163          	beqz	a5,ffffffffc0200e8a <default_check+0x5ee>
ffffffffc0200aec:	010a2703          	lw	a4,16(s4)
ffffffffc0200af0:	478d                	li	a5,3
ffffffffc0200af2:	38f71c63          	bne	a4,a5,ffffffffc0200e8a <default_check+0x5ee>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200af6:	4505                	li	a0,1
ffffffffc0200af8:	ad9ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200afc:	36a99763          	bne	s3,a0,ffffffffc0200e6a <default_check+0x5ce>
    free_page(p0);
ffffffffc0200b00:	4585                	li	a1,1
ffffffffc0200b02:	adbff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200b06:	4509                	li	a0,2
ffffffffc0200b08:	ac9ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200b0c:	32aa1f63          	bne	s4,a0,ffffffffc0200e4a <default_check+0x5ae>

    free_pages(p0, 2);
ffffffffc0200b10:	4589                	li	a1,2
ffffffffc0200b12:	acbff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p2);
ffffffffc0200b16:	4585                	li	a1,1
ffffffffc0200b18:	8556                	mv	a0,s5
ffffffffc0200b1a:	ac3ff0ef          	jal	ra,ffffffffc02005dc <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b1e:	4515                	li	a0,5
ffffffffc0200b20:	ab1ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200b24:	89aa                	mv	s3,a0
ffffffffc0200b26:	48050263          	beqz	a0,ffffffffc0200faa <default_check+0x70e>
    assert(alloc_page() == NULL);
ffffffffc0200b2a:	4505                	li	a0,1
ffffffffc0200b2c:	aa5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200b30:	2c051d63          	bnez	a0,ffffffffc0200e0a <default_check+0x56e>

    assert(nr_free == 0);
ffffffffc0200b34:	481c                	lw	a5,16(s0)
ffffffffc0200b36:	2a079a63          	bnez	a5,ffffffffc0200dea <default_check+0x54e>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b3a:	4595                	li	a1,5
ffffffffc0200b3c:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200b3e:	01842823          	sw	s8,16(s0)
    free_list = free_list_store;
ffffffffc0200b42:	01743023          	sd	s7,0(s0)
ffffffffc0200b46:	01643423          	sd	s6,8(s0)
    free_pages(p0, 5);
ffffffffc0200b4a:	a93ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    return listelm->next;
ffffffffc0200b4e:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b50:	00878963          	beq	a5,s0,ffffffffc0200b62 <default_check+0x2c6>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b54:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b58:	679c                	ld	a5,8(a5)
ffffffffc0200b5a:	397d                	addiw	s2,s2,-1
ffffffffc0200b5c:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b5e:	fe879be3          	bne	a5,s0,ffffffffc0200b54 <default_check+0x2b8>
    }
    assert(count == 0);
ffffffffc0200b62:	26091463          	bnez	s2,ffffffffc0200dca <default_check+0x52e>
    assert(total == 0);
ffffffffc0200b66:	46049263          	bnez	s1,ffffffffc0200fca <default_check+0x72e>
}
ffffffffc0200b6a:	60a6                	ld	ra,72(sp)
ffffffffc0200b6c:	6406                	ld	s0,64(sp)
ffffffffc0200b6e:	74e2                	ld	s1,56(sp)
ffffffffc0200b70:	7942                	ld	s2,48(sp)
ffffffffc0200b72:	79a2                	ld	s3,40(sp)
ffffffffc0200b74:	7a02                	ld	s4,32(sp)
ffffffffc0200b76:	6ae2                	ld	s5,24(sp)
ffffffffc0200b78:	6b42                	ld	s6,16(sp)
ffffffffc0200b7a:	6ba2                	ld	s7,8(sp)
ffffffffc0200b7c:	6c02                	ld	s8,0(sp)
ffffffffc0200b7e:	6161                	addi	sp,sp,80
ffffffffc0200b80:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b82:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b84:	4481                	li	s1,0
ffffffffc0200b86:	4901                	li	s2,0
ffffffffc0200b88:	bb99                	j	ffffffffc02008de <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b8a:	00001697          	auipc	a3,0x1
ffffffffc0200b8e:	f8668693          	addi	a3,a3,-122 # ffffffffc0201b10 <etext+0x3e4>
ffffffffc0200b92:	00001617          	auipc	a2,0x1
ffffffffc0200b96:	f4e60613          	addi	a2,a2,-178 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200b9a:	0f000593          	li	a1,240
ffffffffc0200b9e:	00001517          	auipc	a0,0x1
ffffffffc0200ba2:	f5a50513          	addi	a0,a0,-166 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200ba6:	e1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200baa:	00001697          	auipc	a3,0x1
ffffffffc0200bae:	ff668693          	addi	a3,a3,-10 # ffffffffc0201ba0 <etext+0x474>
ffffffffc0200bb2:	00001617          	auipc	a2,0x1
ffffffffc0200bb6:	f2e60613          	addi	a2,a2,-210 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200bba:	0bd00593          	li	a1,189
ffffffffc0200bbe:	00001517          	auipc	a0,0x1
ffffffffc0200bc2:	f3a50513          	addi	a0,a0,-198 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200bc6:	dfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bca:	00001697          	auipc	a3,0x1
ffffffffc0200bce:	ffe68693          	addi	a3,a3,-2 # ffffffffc0201bc8 <etext+0x49c>
ffffffffc0200bd2:	00001617          	auipc	a2,0x1
ffffffffc0200bd6:	f0e60613          	addi	a2,a2,-242 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200bda:	0be00593          	li	a1,190
ffffffffc0200bde:	00001517          	auipc	a0,0x1
ffffffffc0200be2:	f1a50513          	addi	a0,a0,-230 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200be6:	ddcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200bea:	00001697          	auipc	a3,0x1
ffffffffc0200bee:	01e68693          	addi	a3,a3,30 # ffffffffc0201c08 <etext+0x4dc>
ffffffffc0200bf2:	00001617          	auipc	a2,0x1
ffffffffc0200bf6:	eee60613          	addi	a2,a2,-274 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200bfa:	0c000593          	li	a1,192
ffffffffc0200bfe:	00001517          	auipc	a0,0x1
ffffffffc0200c02:	efa50513          	addi	a0,a0,-262 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200c06:	dbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c0a:	00001697          	auipc	a3,0x1
ffffffffc0200c0e:	08668693          	addi	a3,a3,134 # ffffffffc0201c90 <etext+0x564>
ffffffffc0200c12:	00001617          	auipc	a2,0x1
ffffffffc0200c16:	ece60613          	addi	a2,a2,-306 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200c1a:	0d900593          	li	a1,217
ffffffffc0200c1e:	00001517          	auipc	a0,0x1
ffffffffc0200c22:	eda50513          	addi	a0,a0,-294 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200c26:	d9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c2a:	00001697          	auipc	a3,0x1
ffffffffc0200c2e:	f1668693          	addi	a3,a3,-234 # ffffffffc0201b40 <etext+0x414>
ffffffffc0200c32:	00001617          	auipc	a2,0x1
ffffffffc0200c36:	eae60613          	addi	a2,a2,-338 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200c3a:	0d200593          	li	a1,210
ffffffffc0200c3e:	00001517          	auipc	a0,0x1
ffffffffc0200c42:	eba50513          	addi	a0,a0,-326 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200c46:	d7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200c4a:	00001697          	auipc	a3,0x1
ffffffffc0200c4e:	03668693          	addi	a3,a3,54 # ffffffffc0201c80 <etext+0x554>
ffffffffc0200c52:	00001617          	auipc	a2,0x1
ffffffffc0200c56:	e8e60613          	addi	a2,a2,-370 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200c5a:	0d000593          	li	a1,208
ffffffffc0200c5e:	00001517          	auipc	a0,0x1
ffffffffc0200c62:	e9a50513          	addi	a0,a0,-358 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200c66:	d5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c6a:	00001697          	auipc	a3,0x1
ffffffffc0200c6e:	ffe68693          	addi	a3,a3,-2 # ffffffffc0201c68 <etext+0x53c>
ffffffffc0200c72:	00001617          	auipc	a2,0x1
ffffffffc0200c76:	e6e60613          	addi	a2,a2,-402 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200c7a:	0cb00593          	li	a1,203
ffffffffc0200c7e:	00001517          	auipc	a0,0x1
ffffffffc0200c82:	e7a50513          	addi	a0,a0,-390 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200c86:	d3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200c8a:	00001697          	auipc	a3,0x1
ffffffffc0200c8e:	fbe68693          	addi	a3,a3,-66 # ffffffffc0201c48 <etext+0x51c>
ffffffffc0200c92:	00001617          	auipc	a2,0x1
ffffffffc0200c96:	e4e60613          	addi	a2,a2,-434 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200c9a:	0c200593          	li	a1,194
ffffffffc0200c9e:	00001517          	auipc	a0,0x1
ffffffffc0200ca2:	e5a50513          	addi	a0,a0,-422 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200ca6:	d1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200caa:	00001697          	auipc	a3,0x1
ffffffffc0200cae:	02e68693          	addi	a3,a3,46 # ffffffffc0201cd8 <etext+0x5ac>
ffffffffc0200cb2:	00001617          	auipc	a2,0x1
ffffffffc0200cb6:	e2e60613          	addi	a2,a2,-466 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200cba:	0f800593          	li	a1,248
ffffffffc0200cbe:	00001517          	auipc	a0,0x1
ffffffffc0200cc2:	e3a50513          	addi	a0,a0,-454 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200cc6:	cfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200cca:	00001697          	auipc	a3,0x1
ffffffffc0200cce:	ffe68693          	addi	a3,a3,-2 # ffffffffc0201cc8 <etext+0x59c>
ffffffffc0200cd2:	00001617          	auipc	a2,0x1
ffffffffc0200cd6:	e0e60613          	addi	a2,a2,-498 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200cda:	0df00593          	li	a1,223
ffffffffc0200cde:	00001517          	auipc	a0,0x1
ffffffffc0200ce2:	e1a50513          	addi	a0,a0,-486 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200ce6:	cdcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cea:	00001697          	auipc	a3,0x1
ffffffffc0200cee:	f7e68693          	addi	a3,a3,-130 # ffffffffc0201c68 <etext+0x53c>
ffffffffc0200cf2:	00001617          	auipc	a2,0x1
ffffffffc0200cf6:	dee60613          	addi	a2,a2,-530 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200cfa:	0dd00593          	li	a1,221
ffffffffc0200cfe:	00001517          	auipc	a0,0x1
ffffffffc0200d02:	dfa50513          	addi	a0,a0,-518 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200d06:	cbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d0a:	00001697          	auipc	a3,0x1
ffffffffc0200d0e:	f9e68693          	addi	a3,a3,-98 # ffffffffc0201ca8 <etext+0x57c>
ffffffffc0200d12:	00001617          	auipc	a2,0x1
ffffffffc0200d16:	dce60613          	addi	a2,a2,-562 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200d1a:	0dc00593          	li	a1,220
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	dda50513          	addi	a0,a0,-550 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200d26:	c9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d2a:	00001697          	auipc	a3,0x1
ffffffffc0200d2e:	e1668693          	addi	a3,a3,-490 # ffffffffc0201b40 <etext+0x414>
ffffffffc0200d32:	00001617          	auipc	a2,0x1
ffffffffc0200d36:	dae60613          	addi	a2,a2,-594 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200d3a:	0b900593          	li	a1,185
ffffffffc0200d3e:	00001517          	auipc	a0,0x1
ffffffffc0200d42:	dba50513          	addi	a0,a0,-582 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200d46:	c7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d4a:	00001697          	auipc	a3,0x1
ffffffffc0200d4e:	f1e68693          	addi	a3,a3,-226 # ffffffffc0201c68 <etext+0x53c>
ffffffffc0200d52:	00001617          	auipc	a2,0x1
ffffffffc0200d56:	d8e60613          	addi	a2,a2,-626 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200d5a:	0d600593          	li	a1,214
ffffffffc0200d5e:	00001517          	auipc	a0,0x1
ffffffffc0200d62:	d9a50513          	addi	a0,a0,-614 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200d66:	c5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d6a:	00001697          	auipc	a3,0x1
ffffffffc0200d6e:	e1668693          	addi	a3,a3,-490 # ffffffffc0201b80 <etext+0x454>
ffffffffc0200d72:	00001617          	auipc	a2,0x1
ffffffffc0200d76:	d6e60613          	addi	a2,a2,-658 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200d7a:	0d400593          	li	a1,212
ffffffffc0200d7e:	00001517          	auipc	a0,0x1
ffffffffc0200d82:	d7a50513          	addi	a0,a0,-646 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200d86:	c3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d8a:	00001697          	auipc	a3,0x1
ffffffffc0200d8e:	dd668693          	addi	a3,a3,-554 # ffffffffc0201b60 <etext+0x434>
ffffffffc0200d92:	00001617          	auipc	a2,0x1
ffffffffc0200d96:	d4e60613          	addi	a2,a2,-690 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200d9a:	0d300593          	li	a1,211
ffffffffc0200d9e:	00001517          	auipc	a0,0x1
ffffffffc0200da2:	d5a50513          	addi	a0,a0,-678 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200da6:	c1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200daa:	00001697          	auipc	a3,0x1
ffffffffc0200dae:	dd668693          	addi	a3,a3,-554 # ffffffffc0201b80 <etext+0x454>
ffffffffc0200db2:	00001617          	auipc	a2,0x1
ffffffffc0200db6:	d2e60613          	addi	a2,a2,-722 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200dba:	0bb00593          	li	a1,187
ffffffffc0200dbe:	00001517          	auipc	a0,0x1
ffffffffc0200dc2:	d3a50513          	addi	a0,a0,-710 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200dc6:	bfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200dca:	00001697          	auipc	a3,0x1
ffffffffc0200dce:	05e68693          	addi	a3,a3,94 # ffffffffc0201e28 <etext+0x6fc>
ffffffffc0200dd2:	00001617          	auipc	a2,0x1
ffffffffc0200dd6:	d0e60613          	addi	a2,a2,-754 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200dda:	12500593          	li	a1,293
ffffffffc0200dde:	00001517          	auipc	a0,0x1
ffffffffc0200de2:	d1a50513          	addi	a0,a0,-742 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200de6:	bdcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200dea:	00001697          	auipc	a3,0x1
ffffffffc0200dee:	ede68693          	addi	a3,a3,-290 # ffffffffc0201cc8 <etext+0x59c>
ffffffffc0200df2:	00001617          	auipc	a2,0x1
ffffffffc0200df6:	cee60613          	addi	a2,a2,-786 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200dfa:	11a00593          	li	a1,282
ffffffffc0200dfe:	00001517          	auipc	a0,0x1
ffffffffc0200e02:	cfa50513          	addi	a0,a0,-774 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200e06:	bbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e0a:	00001697          	auipc	a3,0x1
ffffffffc0200e0e:	e5e68693          	addi	a3,a3,-418 # ffffffffc0201c68 <etext+0x53c>
ffffffffc0200e12:	00001617          	auipc	a2,0x1
ffffffffc0200e16:	cce60613          	addi	a2,a2,-818 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200e1a:	11800593          	li	a1,280
ffffffffc0200e1e:	00001517          	auipc	a0,0x1
ffffffffc0200e22:	cda50513          	addi	a0,a0,-806 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200e26:	b9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e2a:	00001697          	auipc	a3,0x1
ffffffffc0200e2e:	dfe68693          	addi	a3,a3,-514 # ffffffffc0201c28 <etext+0x4fc>
ffffffffc0200e32:	00001617          	auipc	a2,0x1
ffffffffc0200e36:	cae60613          	addi	a2,a2,-850 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200e3a:	0c100593          	li	a1,193
ffffffffc0200e3e:	00001517          	auipc	a0,0x1
ffffffffc0200e42:	cba50513          	addi	a0,a0,-838 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200e46:	b7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200e4a:	00001697          	auipc	a3,0x1
ffffffffc0200e4e:	f9e68693          	addi	a3,a3,-98 # ffffffffc0201de8 <etext+0x6bc>
ffffffffc0200e52:	00001617          	auipc	a2,0x1
ffffffffc0200e56:	c8e60613          	addi	a2,a2,-882 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200e5a:	11200593          	li	a1,274
ffffffffc0200e5e:	00001517          	auipc	a0,0x1
ffffffffc0200e62:	c9a50513          	addi	a0,a0,-870 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200e66:	b5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200e6a:	00001697          	auipc	a3,0x1
ffffffffc0200e6e:	f5e68693          	addi	a3,a3,-162 # ffffffffc0201dc8 <etext+0x69c>
ffffffffc0200e72:	00001617          	auipc	a2,0x1
ffffffffc0200e76:	c6e60613          	addi	a2,a2,-914 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200e7a:	11000593          	li	a1,272
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	c7a50513          	addi	a0,a0,-902 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200e86:	b3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200e8a:	00001697          	auipc	a3,0x1
ffffffffc0200e8e:	f1668693          	addi	a3,a3,-234 # ffffffffc0201da0 <etext+0x674>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	c4e60613          	addi	a2,a2,-946 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200e9a:	10e00593          	li	a1,270
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	c5a50513          	addi	a0,a0,-934 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200ea6:	b1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200eaa:	00001697          	auipc	a3,0x1
ffffffffc0200eae:	ece68693          	addi	a3,a3,-306 # ffffffffc0201d78 <etext+0x64c>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	c2e60613          	addi	a2,a2,-978 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200eba:	10d00593          	li	a1,269
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	c3a50513          	addi	a0,a0,-966 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200ec6:	afcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0200eca:	00001697          	auipc	a3,0x1
ffffffffc0200ece:	e9e68693          	addi	a3,a3,-354 # ffffffffc0201d68 <etext+0x63c>
ffffffffc0200ed2:	00001617          	auipc	a2,0x1
ffffffffc0200ed6:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200eda:	10800593          	li	a1,264
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	c1a50513          	addi	a0,a0,-998 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200ee6:	adcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eea:	00001697          	auipc	a3,0x1
ffffffffc0200eee:	d7e68693          	addi	a3,a3,-642 # ffffffffc0201c68 <etext+0x53c>
ffffffffc0200ef2:	00001617          	auipc	a2,0x1
ffffffffc0200ef6:	bee60613          	addi	a2,a2,-1042 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200efa:	10700593          	li	a1,263
ffffffffc0200efe:	00001517          	auipc	a0,0x1
ffffffffc0200f02:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200f06:	abcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f0a:	00001697          	auipc	a3,0x1
ffffffffc0200f0e:	e3e68693          	addi	a3,a3,-450 # ffffffffc0201d48 <etext+0x61c>
ffffffffc0200f12:	00001617          	auipc	a2,0x1
ffffffffc0200f16:	bce60613          	addi	a2,a2,-1074 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200f1a:	10600593          	li	a1,262
ffffffffc0200f1e:	00001517          	auipc	a0,0x1
ffffffffc0200f22:	bda50513          	addi	a0,a0,-1062 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200f26:	a9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f2a:	00001697          	auipc	a3,0x1
ffffffffc0200f2e:	dee68693          	addi	a3,a3,-530 # ffffffffc0201d18 <etext+0x5ec>
ffffffffc0200f32:	00001617          	auipc	a2,0x1
ffffffffc0200f36:	bae60613          	addi	a2,a2,-1106 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200f3a:	10500593          	li	a1,261
ffffffffc0200f3e:	00001517          	auipc	a0,0x1
ffffffffc0200f42:	bba50513          	addi	a0,a0,-1094 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200f46:	a7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f4a:	00001697          	auipc	a3,0x1
ffffffffc0200f4e:	db668693          	addi	a3,a3,-586 # ffffffffc0201d00 <etext+0x5d4>
ffffffffc0200f52:	00001617          	auipc	a2,0x1
ffffffffc0200f56:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200f5a:	10400593          	li	a1,260
ffffffffc0200f5e:	00001517          	auipc	a0,0x1
ffffffffc0200f62:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200f66:	a5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f6a:	00001697          	auipc	a3,0x1
ffffffffc0200f6e:	cfe68693          	addi	a3,a3,-770 # ffffffffc0201c68 <etext+0x53c>
ffffffffc0200f72:	00001617          	auipc	a2,0x1
ffffffffc0200f76:	b6e60613          	addi	a2,a2,-1170 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200f7a:	0fe00593          	li	a1,254
ffffffffc0200f7e:	00001517          	auipc	a0,0x1
ffffffffc0200f82:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200f86:	a3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f8a:	00001697          	auipc	a3,0x1
ffffffffc0200f8e:	d5e68693          	addi	a3,a3,-674 # ffffffffc0201ce8 <etext+0x5bc>
ffffffffc0200f92:	00001617          	auipc	a2,0x1
ffffffffc0200f96:	b4e60613          	addi	a2,a2,-1202 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200f9a:	0f900593          	li	a1,249
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200fa6:	a1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200faa:	00001697          	auipc	a3,0x1
ffffffffc0200fae:	e5e68693          	addi	a3,a3,-418 # ffffffffc0201e08 <etext+0x6dc>
ffffffffc0200fb2:	00001617          	auipc	a2,0x1
ffffffffc0200fb6:	b2e60613          	addi	a2,a2,-1234 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200fba:	11700593          	li	a1,279
ffffffffc0200fbe:	00001517          	auipc	a0,0x1
ffffffffc0200fc2:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200fc6:	9fcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200fca:	00001697          	auipc	a3,0x1
ffffffffc0200fce:	e6e68693          	addi	a3,a3,-402 # ffffffffc0201e38 <etext+0x70c>
ffffffffc0200fd2:	00001617          	auipc	a2,0x1
ffffffffc0200fd6:	b0e60613          	addi	a2,a2,-1266 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200fda:	12600593          	li	a1,294
ffffffffc0200fde:	00001517          	auipc	a0,0x1
ffffffffc0200fe2:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0200fe6:	9dcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200fea:	00001697          	auipc	a3,0x1
ffffffffc0200fee:	b3668693          	addi	a3,a3,-1226 # ffffffffc0201b20 <etext+0x3f4>
ffffffffc0200ff2:	00001617          	auipc	a2,0x1
ffffffffc0200ff6:	aee60613          	addi	a2,a2,-1298 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0200ffa:	0f300593          	li	a1,243
ffffffffc0200ffe:	00001517          	auipc	a0,0x1
ffffffffc0201002:	afa50513          	addi	a0,a0,-1286 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0201006:	9bcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020100a:	00001697          	auipc	a3,0x1
ffffffffc020100e:	b5668693          	addi	a3,a3,-1194 # ffffffffc0201b60 <etext+0x434>
ffffffffc0201012:	00001617          	auipc	a2,0x1
ffffffffc0201016:	ace60613          	addi	a2,a2,-1330 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc020101a:	0ba00593          	li	a1,186
ffffffffc020101e:	00001517          	auipc	a0,0x1
ffffffffc0201022:	ada50513          	addi	a0,a0,-1318 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0201026:	99cff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020102a <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020102a:	1141                	addi	sp,sp,-16
ffffffffc020102c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020102e:	14058c63          	beqz	a1,ffffffffc0201186 <default_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0201032:	00259693          	slli	a3,a1,0x2
ffffffffc0201036:	96ae                	add	a3,a3,a1
ffffffffc0201038:	068e                	slli	a3,a3,0x3
ffffffffc020103a:	96aa                	add	a3,a3,a0
ffffffffc020103c:	87aa                	mv	a5,a0
ffffffffc020103e:	00d50e63          	beq	a0,a3,ffffffffc020105a <default_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201042:	6798                	ld	a4,8(a5)
ffffffffc0201044:	8b0d                	andi	a4,a4,3
ffffffffc0201046:	12071063          	bnez	a4,ffffffffc0201166 <default_free_pages+0x13c>
        p->flags = 0;
ffffffffc020104a:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020104e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201052:	02878793          	addi	a5,a5,40
ffffffffc0201056:	fed796e3          	bne	a5,a3,ffffffffc0201042 <default_free_pages+0x18>
    SetPageProperty(base);
ffffffffc020105a:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc020105e:	00005697          	auipc	a3,0x5
ffffffffc0201062:	fba68693          	addi	a3,a3,-70 # ffffffffc0206018 <free_area>
ffffffffc0201066:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0201068:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc020106a:	0028e613          	ori	a2,a7,2
    return list->next == list;
ffffffffc020106e:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0201070:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201072:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0201074:	9f2d                	addw	a4,a4,a1
ffffffffc0201076:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201078:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc020107c:	0ad78b63          	beq	a5,a3,ffffffffc0201132 <default_free_pages+0x108>
            struct Page* page = le2page(le, page_link);
ffffffffc0201080:	fe878713          	addi	a4,a5,-24
ffffffffc0201084:	0006b303          	ld	t1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201088:	4801                	li	a6,0
            if (base < page) {
ffffffffc020108a:	00e56a63          	bltu	a0,a4,ffffffffc020109e <default_free_pages+0x74>
    return listelm->next;
ffffffffc020108e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201090:	06d70563          	beq	a4,a3,ffffffffc02010fa <default_free_pages+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0201094:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201096:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020109a:	fee57ae3          	bgeu	a0,a4,ffffffffc020108e <default_free_pages+0x64>
ffffffffc020109e:	00080463          	beqz	a6,ffffffffc02010a6 <default_free_pages+0x7c>
ffffffffc02010a2:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02010a6:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc02010aa:	e390                	sd	a2,0(a5)
ffffffffc02010ac:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc02010b0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010b2:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc02010b6:	02d80463          	beq	a6,a3,ffffffffc02010de <default_free_pages+0xb4>
        if (p + p->property == base) {
ffffffffc02010ba:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc02010be:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc02010c2:	020e1613          	slli	a2,t3,0x20
ffffffffc02010c6:	9201                	srli	a2,a2,0x20
ffffffffc02010c8:	00261713          	slli	a4,a2,0x2
ffffffffc02010cc:	9732                	add	a4,a4,a2
ffffffffc02010ce:	070e                	slli	a4,a4,0x3
ffffffffc02010d0:	971a                	add	a4,a4,t1
ffffffffc02010d2:	02e50e63          	beq	a0,a4,ffffffffc020110e <default_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc02010d6:	00d78f63          	beq	a5,a3,ffffffffc02010f4 <default_free_pages+0xca>
ffffffffc02010da:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc02010de:	490c                	lw	a1,16(a0)
ffffffffc02010e0:	02059613          	slli	a2,a1,0x20
ffffffffc02010e4:	9201                	srli	a2,a2,0x20
ffffffffc02010e6:	00261693          	slli	a3,a2,0x2
ffffffffc02010ea:	96b2                	add	a3,a3,a2
ffffffffc02010ec:	068e                	slli	a3,a3,0x3
ffffffffc02010ee:	96aa                	add	a3,a3,a0
ffffffffc02010f0:	04d70863          	beq	a4,a3,ffffffffc0201140 <default_free_pages+0x116>
}
ffffffffc02010f4:	60a2                	ld	ra,8(sp)
ffffffffc02010f6:	0141                	addi	sp,sp,16
ffffffffc02010f8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02010fa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010fc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02010fe:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201100:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201102:	02d70463          	beq	a4,a3,ffffffffc020112a <default_free_pages+0x100>
    prev->next = next->prev = elm;
ffffffffc0201106:	8332                	mv	t1,a2
ffffffffc0201108:	4805                	li	a6,1
    for (; p != base + n; p ++) {
ffffffffc020110a:	87ba                	mv	a5,a4
ffffffffc020110c:	b769                	j	ffffffffc0201096 <default_free_pages+0x6c>
            p->property += base->property;
ffffffffc020110e:	01c585bb          	addw	a1,a1,t3
ffffffffc0201112:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0201116:	ffd8f893          	andi	a7,a7,-3
ffffffffc020111a:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc020111e:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0201122:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0201126:	851a                	mv	a0,t1
ffffffffc0201128:	b77d                	j	ffffffffc02010d6 <default_free_pages+0xac>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020112a:	883e                	mv	a6,a5
ffffffffc020112c:	e290                	sd	a2,0(a3)
ffffffffc020112e:	87b6                	mv	a5,a3
ffffffffc0201130:	b769                	j	ffffffffc02010ba <default_free_pages+0x90>
}
ffffffffc0201132:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201134:	e390                	sd	a2,0(a5)
ffffffffc0201136:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201138:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020113a:	ed1c                	sd	a5,24(a0)
ffffffffc020113c:	0141                	addi	sp,sp,16
ffffffffc020113e:	8082                	ret
            base->property += p->property;
ffffffffc0201140:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0201144:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201148:	0007b803          	ld	a6,0(a5)
ffffffffc020114c:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc020114e:	9db5                	addw	a1,a1,a3
ffffffffc0201150:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0201152:	9b75                	andi	a4,a4,-3
ffffffffc0201154:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0201158:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020115a:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc020115e:	01063023          	sd	a6,0(a2)
ffffffffc0201162:	0141                	addi	sp,sp,16
ffffffffc0201164:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201166:	00001697          	auipc	a3,0x1
ffffffffc020116a:	ce268693          	addi	a3,a3,-798 # ffffffffc0201e48 <etext+0x71c>
ffffffffc020116e:	00001617          	auipc	a2,0x1
ffffffffc0201172:	97260613          	addi	a2,a2,-1678 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0201176:	08300593          	li	a1,131
ffffffffc020117a:	00001517          	auipc	a0,0x1
ffffffffc020117e:	97e50513          	addi	a0,a0,-1666 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0201182:	840ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0201186:	00001697          	auipc	a3,0x1
ffffffffc020118a:	95268693          	addi	a3,a3,-1710 # ffffffffc0201ad8 <etext+0x3ac>
ffffffffc020118e:	00001617          	auipc	a2,0x1
ffffffffc0201192:	95260613          	addi	a2,a2,-1710 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0201196:	08000593          	li	a1,128
ffffffffc020119a:	00001517          	auipc	a0,0x1
ffffffffc020119e:	95e50513          	addi	a0,a0,-1698 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc02011a2:	820ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02011a6 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02011a6:	1141                	addi	sp,sp,-16
ffffffffc02011a8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02011aa:	c5f9                	beqz	a1,ffffffffc0201278 <default_init_memmap+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02011ac:	00259693          	slli	a3,a1,0x2
ffffffffc02011b0:	96ae                	add	a3,a3,a1
ffffffffc02011b2:	068e                	slli	a3,a3,0x3
ffffffffc02011b4:	96aa                	add	a3,a3,a0
ffffffffc02011b6:	87aa                	mv	a5,a0
ffffffffc02011b8:	00d50f63          	beq	a0,a3,ffffffffc02011d6 <default_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc02011bc:	6798                	ld	a4,8(a5)
ffffffffc02011be:	8b05                	andi	a4,a4,1
ffffffffc02011c0:	cf41                	beqz	a4,ffffffffc0201258 <default_init_memmap+0xb2>
        p->flags = p->property = 0;
ffffffffc02011c2:	0007a823          	sw	zero,16(a5)
ffffffffc02011c6:	0007b423          	sd	zero,8(a5)
ffffffffc02011ca:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02011ce:	02878793          	addi	a5,a5,40
ffffffffc02011d2:	fed795e3          	bne	a5,a3,ffffffffc02011bc <default_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc02011d6:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc02011d8:	00005697          	auipc	a3,0x5
ffffffffc02011dc:	e4068693          	addi	a3,a3,-448 # ffffffffc0206018 <free_area>
ffffffffc02011e0:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc02011e2:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc02011e4:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc02011e8:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc02011ea:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02011ec:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc02011ee:	9db9                	addw	a1,a1,a4
ffffffffc02011f0:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02011f2:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc02011f6:	04d78a63          	beq	a5,a3,ffffffffc020124a <default_init_memmap+0xa4>
            struct Page* page = le2page(le, page_link);
ffffffffc02011fa:	fe878713          	addi	a4,a5,-24
ffffffffc02011fe:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201202:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201204:	00e56a63          	bltu	a0,a4,ffffffffc0201218 <default_init_memmap+0x72>
    return listelm->next;
ffffffffc0201208:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020120a:	02d70263          	beq	a4,a3,ffffffffc020122e <default_init_memmap+0x88>
    for (; p != base + n; p ++) {
ffffffffc020120e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201210:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201214:	fee57ae3          	bgeu	a0,a4,ffffffffc0201208 <default_init_memmap+0x62>
ffffffffc0201218:	c199                	beqz	a1,ffffffffc020121e <default_init_memmap+0x78>
ffffffffc020121a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020121e:	6398                	ld	a4,0(a5)
}
ffffffffc0201220:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201222:	e390                	sd	a2,0(a5)
ffffffffc0201224:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201226:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201228:	ed18                	sd	a4,24(a0)
ffffffffc020122a:	0141                	addi	sp,sp,16
ffffffffc020122c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020122e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201230:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201232:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201234:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201236:	00d70663          	beq	a4,a3,ffffffffc0201242 <default_init_memmap+0x9c>
    prev->next = next->prev = elm;
ffffffffc020123a:	8832                	mv	a6,a2
ffffffffc020123c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020123e:	87ba                	mv	a5,a4
ffffffffc0201240:	bfc1                	j	ffffffffc0201210 <default_init_memmap+0x6a>
}
ffffffffc0201242:	60a2                	ld	ra,8(sp)
ffffffffc0201244:	e290                	sd	a2,0(a3)
ffffffffc0201246:	0141                	addi	sp,sp,16
ffffffffc0201248:	8082                	ret
ffffffffc020124a:	60a2                	ld	ra,8(sp)
ffffffffc020124c:	e390                	sd	a2,0(a5)
ffffffffc020124e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201250:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201252:	ed1c                	sd	a5,24(a0)
ffffffffc0201254:	0141                	addi	sp,sp,16
ffffffffc0201256:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201258:	00001697          	auipc	a3,0x1
ffffffffc020125c:	c1868693          	addi	a3,a3,-1000 # ffffffffc0201e70 <etext+0x744>
ffffffffc0201260:	00001617          	auipc	a2,0x1
ffffffffc0201264:	88060613          	addi	a2,a2,-1920 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0201268:	04900593          	li	a1,73
ffffffffc020126c:	00001517          	auipc	a0,0x1
ffffffffc0201270:	88c50513          	addi	a0,a0,-1908 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0201274:	f4ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0201278:	00001697          	auipc	a3,0x1
ffffffffc020127c:	86068693          	addi	a3,a3,-1952 # ffffffffc0201ad8 <etext+0x3ac>
ffffffffc0201280:	00001617          	auipc	a2,0x1
ffffffffc0201284:	86060613          	addi	a2,a2,-1952 # ffffffffc0201ae0 <etext+0x3b4>
ffffffffc0201288:	04600593          	li	a1,70
ffffffffc020128c:	00001517          	auipc	a0,0x1
ffffffffc0201290:	86c50513          	addi	a0,a0,-1940 # ffffffffc0201af8 <etext+0x3cc>
ffffffffc0201294:	f2ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201298 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201298:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020129c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020129e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02012a0:	cb81                	beqz	a5,ffffffffc02012b0 <strlen+0x18>
        cnt ++;
ffffffffc02012a2:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02012a4:	00a707b3          	add	a5,a4,a0
ffffffffc02012a8:	0007c783          	lbu	a5,0(a5)
ffffffffc02012ac:	fbfd                	bnez	a5,ffffffffc02012a2 <strlen+0xa>
ffffffffc02012ae:	8082                	ret
    }
    return cnt;
}
ffffffffc02012b0:	8082                	ret

ffffffffc02012b2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02012b2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02012b4:	e589                	bnez	a1,ffffffffc02012be <strnlen+0xc>
ffffffffc02012b6:	a811                	j	ffffffffc02012ca <strnlen+0x18>
        cnt ++;
ffffffffc02012b8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02012ba:	00f58863          	beq	a1,a5,ffffffffc02012ca <strnlen+0x18>
ffffffffc02012be:	00f50733          	add	a4,a0,a5
ffffffffc02012c2:	00074703          	lbu	a4,0(a4) # fffffffffff80000 <end+0x3fd79f88>
ffffffffc02012c6:	fb6d                	bnez	a4,ffffffffc02012b8 <strnlen+0x6>
ffffffffc02012c8:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02012ca:	852e                	mv	a0,a1
ffffffffc02012cc:	8082                	ret

ffffffffc02012ce <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02012ce:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02012d2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02012d6:	cb89                	beqz	a5,ffffffffc02012e8 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02012d8:	0505                	addi	a0,a0,1
ffffffffc02012da:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02012dc:	fee789e3          	beq	a5,a4,ffffffffc02012ce <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02012e0:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02012e4:	9d19                	subw	a0,a0,a4
ffffffffc02012e6:	8082                	ret
ffffffffc02012e8:	4501                	li	a0,0
ffffffffc02012ea:	bfed                	j	ffffffffc02012e4 <strcmp+0x16>

ffffffffc02012ec <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012ec:	c20d                	beqz	a2,ffffffffc020130e <strncmp+0x22>
ffffffffc02012ee:	962e                	add	a2,a2,a1
ffffffffc02012f0:	a031                	j	ffffffffc02012fc <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02012f2:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02012f4:	00e79a63          	bne	a5,a4,ffffffffc0201308 <strncmp+0x1c>
ffffffffc02012f8:	00b60b63          	beq	a2,a1,ffffffffc020130e <strncmp+0x22>
ffffffffc02012fc:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201300:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201302:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201306:	f7f5                	bnez	a5,ffffffffc02012f2 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201308:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020130c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020130e:	4501                	li	a0,0
ffffffffc0201310:	8082                	ret

ffffffffc0201312 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201312:	ca01                	beqz	a2,ffffffffc0201322 <memset+0x10>
ffffffffc0201314:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201316:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201318:	0785                	addi	a5,a5,1
ffffffffc020131a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020131e:	fec79de3          	bne	a5,a2,ffffffffc0201318 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201322:	8082                	ret

ffffffffc0201324 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201324:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201328:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020132a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020132e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201330:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201334:	f022                	sd	s0,32(sp)
ffffffffc0201336:	ec26                	sd	s1,24(sp)
ffffffffc0201338:	e84a                	sd	s2,16(sp)
ffffffffc020133a:	f406                	sd	ra,40(sp)
ffffffffc020133c:	e44e                	sd	s3,8(sp)
ffffffffc020133e:	84aa                	mv	s1,a0
ffffffffc0201340:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201342:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201346:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201348:	03067e63          	bgeu	a2,a6,ffffffffc0201384 <printnum+0x60>
ffffffffc020134c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020134e:	00805763          	blez	s0,ffffffffc020135c <printnum+0x38>
ffffffffc0201352:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201354:	85ca                	mv	a1,s2
ffffffffc0201356:	854e                	mv	a0,s3
ffffffffc0201358:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020135a:	fc65                	bnez	s0,ffffffffc0201352 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020135c:	1a02                	slli	s4,s4,0x20
ffffffffc020135e:	00001797          	auipc	a5,0x1
ffffffffc0201362:	b7278793          	addi	a5,a5,-1166 # ffffffffc0201ed0 <default_pmm_manager+0x38>
ffffffffc0201366:	020a5a13          	srli	s4,s4,0x20
ffffffffc020136a:	9a3e                	add	s4,s4,a5
}
ffffffffc020136c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020136e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201372:	70a2                	ld	ra,40(sp)
ffffffffc0201374:	69a2                	ld	s3,8(sp)
ffffffffc0201376:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201378:	85ca                	mv	a1,s2
ffffffffc020137a:	87a6                	mv	a5,s1
}
ffffffffc020137c:	6942                	ld	s2,16(sp)
ffffffffc020137e:	64e2                	ld	s1,24(sp)
ffffffffc0201380:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201382:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201384:	03065633          	divu	a2,a2,a6
ffffffffc0201388:	8722                	mv	a4,s0
ffffffffc020138a:	f9bff0ef          	jal	ra,ffffffffc0201324 <printnum>
ffffffffc020138e:	b7f9                	j	ffffffffc020135c <printnum+0x38>

ffffffffc0201390 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201390:	7119                	addi	sp,sp,-128
ffffffffc0201392:	f4a6                	sd	s1,104(sp)
ffffffffc0201394:	f0ca                	sd	s2,96(sp)
ffffffffc0201396:	ecce                	sd	s3,88(sp)
ffffffffc0201398:	e8d2                	sd	s4,80(sp)
ffffffffc020139a:	e4d6                	sd	s5,72(sp)
ffffffffc020139c:	e0da                	sd	s6,64(sp)
ffffffffc020139e:	fc5e                	sd	s7,56(sp)
ffffffffc02013a0:	f06a                	sd	s10,32(sp)
ffffffffc02013a2:	fc86                	sd	ra,120(sp)
ffffffffc02013a4:	f8a2                	sd	s0,112(sp)
ffffffffc02013a6:	f862                	sd	s8,48(sp)
ffffffffc02013a8:	f466                	sd	s9,40(sp)
ffffffffc02013aa:	ec6e                	sd	s11,24(sp)
ffffffffc02013ac:	892a                	mv	s2,a0
ffffffffc02013ae:	84ae                	mv	s1,a1
ffffffffc02013b0:	8d32                	mv	s10,a2
ffffffffc02013b2:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02013b4:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02013b8:	5b7d                	li	s6,-1
ffffffffc02013ba:	00001a97          	auipc	s5,0x1
ffffffffc02013be:	b4aa8a93          	addi	s5,s5,-1206 # ffffffffc0201f04 <default_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013c2:	00001b97          	auipc	s7,0x1
ffffffffc02013c6:	d1eb8b93          	addi	s7,s7,-738 # ffffffffc02020e0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02013ca:	000d4503          	lbu	a0,0(s10)
ffffffffc02013ce:	001d0413          	addi	s0,s10,1
ffffffffc02013d2:	01350a63          	beq	a0,s3,ffffffffc02013e6 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02013d6:	c121                	beqz	a0,ffffffffc0201416 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02013d8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02013da:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02013dc:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02013de:	fff44503          	lbu	a0,-1(s0)
ffffffffc02013e2:	ff351ae3          	bne	a0,s3,ffffffffc02013d6 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013e6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02013ea:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02013ee:	4c81                	li	s9,0
ffffffffc02013f0:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02013f2:	5c7d                	li	s8,-1
ffffffffc02013f4:	5dfd                	li	s11,-1
ffffffffc02013f6:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02013fa:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013fc:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201400:	0ff5f593          	zext.b	a1,a1
ffffffffc0201404:	00140d13          	addi	s10,s0,1
ffffffffc0201408:	04b56263          	bltu	a0,a1,ffffffffc020144c <vprintfmt+0xbc>
ffffffffc020140c:	058a                	slli	a1,a1,0x2
ffffffffc020140e:	95d6                	add	a1,a1,s5
ffffffffc0201410:	4194                	lw	a3,0(a1)
ffffffffc0201412:	96d6                	add	a3,a3,s5
ffffffffc0201414:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201416:	70e6                	ld	ra,120(sp)
ffffffffc0201418:	7446                	ld	s0,112(sp)
ffffffffc020141a:	74a6                	ld	s1,104(sp)
ffffffffc020141c:	7906                	ld	s2,96(sp)
ffffffffc020141e:	69e6                	ld	s3,88(sp)
ffffffffc0201420:	6a46                	ld	s4,80(sp)
ffffffffc0201422:	6aa6                	ld	s5,72(sp)
ffffffffc0201424:	6b06                	ld	s6,64(sp)
ffffffffc0201426:	7be2                	ld	s7,56(sp)
ffffffffc0201428:	7c42                	ld	s8,48(sp)
ffffffffc020142a:	7ca2                	ld	s9,40(sp)
ffffffffc020142c:	7d02                	ld	s10,32(sp)
ffffffffc020142e:	6de2                	ld	s11,24(sp)
ffffffffc0201430:	6109                	addi	sp,sp,128
ffffffffc0201432:	8082                	ret
            padc = '0';
ffffffffc0201434:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201436:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020143a:	846a                	mv	s0,s10
ffffffffc020143c:	00140d13          	addi	s10,s0,1
ffffffffc0201440:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201444:	0ff5f593          	zext.b	a1,a1
ffffffffc0201448:	fcb572e3          	bgeu	a0,a1,ffffffffc020140c <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020144c:	85a6                	mv	a1,s1
ffffffffc020144e:	02500513          	li	a0,37
ffffffffc0201452:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201454:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201458:	8d22                	mv	s10,s0
ffffffffc020145a:	f73788e3          	beq	a5,s3,ffffffffc02013ca <vprintfmt+0x3a>
ffffffffc020145e:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201462:	1d7d                	addi	s10,s10,-1
ffffffffc0201464:	ff379de3          	bne	a5,s3,ffffffffc020145e <vprintfmt+0xce>
ffffffffc0201468:	b78d                	j	ffffffffc02013ca <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020146a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020146e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201472:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201474:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201478:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020147c:	02d86463          	bltu	a6,a3,ffffffffc02014a4 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201480:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201484:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201488:	0186873b          	addw	a4,a3,s8
ffffffffc020148c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201490:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201492:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201496:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201498:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020149c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02014a0:	fed870e3          	bgeu	a6,a3,ffffffffc0201480 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02014a4:	f40ddce3          	bgez	s11,ffffffffc02013fc <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02014a8:	8de2                	mv	s11,s8
ffffffffc02014aa:	5c7d                	li	s8,-1
ffffffffc02014ac:	bf81                	j	ffffffffc02013fc <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02014ae:	fffdc693          	not	a3,s11
ffffffffc02014b2:	96fd                	srai	a3,a3,0x3f
ffffffffc02014b4:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014b8:	00144603          	lbu	a2,1(s0)
ffffffffc02014bc:	2d81                	sext.w	s11,s11
ffffffffc02014be:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014c0:	bf35                	j	ffffffffc02013fc <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02014c2:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014c6:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02014ca:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014cc:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02014ce:	bfd9                	j	ffffffffc02014a4 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02014d0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02014d2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02014d6:	01174463          	blt	a4,a7,ffffffffc02014de <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02014da:	1a088e63          	beqz	a7,ffffffffc0201696 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02014de:	000a3603          	ld	a2,0(s4)
ffffffffc02014e2:	46c1                	li	a3,16
ffffffffc02014e4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02014e6:	2781                	sext.w	a5,a5
ffffffffc02014e8:	876e                	mv	a4,s11
ffffffffc02014ea:	85a6                	mv	a1,s1
ffffffffc02014ec:	854a                	mv	a0,s2
ffffffffc02014ee:	e37ff0ef          	jal	ra,ffffffffc0201324 <printnum>
            break;
ffffffffc02014f2:	bde1                	j	ffffffffc02013ca <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02014f4:	000a2503          	lw	a0,0(s4)
ffffffffc02014f8:	85a6                	mv	a1,s1
ffffffffc02014fa:	0a21                	addi	s4,s4,8
ffffffffc02014fc:	9902                	jalr	s2
            break;
ffffffffc02014fe:	b5f1                	j	ffffffffc02013ca <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201500:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201502:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201506:	01174463          	blt	a4,a7,ffffffffc020150e <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020150a:	18088163          	beqz	a7,ffffffffc020168c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020150e:	000a3603          	ld	a2,0(s4)
ffffffffc0201512:	46a9                	li	a3,10
ffffffffc0201514:	8a2e                	mv	s4,a1
ffffffffc0201516:	bfc1                	j	ffffffffc02014e6 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201518:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020151c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020151e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201520:	bdf1                	j	ffffffffc02013fc <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201522:	85a6                	mv	a1,s1
ffffffffc0201524:	02500513          	li	a0,37
ffffffffc0201528:	9902                	jalr	s2
            break;
ffffffffc020152a:	b545                	j	ffffffffc02013ca <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020152c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201530:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201532:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201534:	b5e1                	j	ffffffffc02013fc <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201536:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201538:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020153c:	01174463          	blt	a4,a7,ffffffffc0201544 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201540:	14088163          	beqz	a7,ffffffffc0201682 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201544:	000a3603          	ld	a2,0(s4)
ffffffffc0201548:	46a1                	li	a3,8
ffffffffc020154a:	8a2e                	mv	s4,a1
ffffffffc020154c:	bf69                	j	ffffffffc02014e6 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020154e:	03000513          	li	a0,48
ffffffffc0201552:	85a6                	mv	a1,s1
ffffffffc0201554:	e03e                	sd	a5,0(sp)
ffffffffc0201556:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201558:	85a6                	mv	a1,s1
ffffffffc020155a:	07800513          	li	a0,120
ffffffffc020155e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201560:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201562:	6782                	ld	a5,0(sp)
ffffffffc0201564:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201566:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020156a:	bfb5                	j	ffffffffc02014e6 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020156c:	000a3403          	ld	s0,0(s4)
ffffffffc0201570:	008a0713          	addi	a4,s4,8
ffffffffc0201574:	e03a                	sd	a4,0(sp)
ffffffffc0201576:	14040263          	beqz	s0,ffffffffc02016ba <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020157a:	0fb05763          	blez	s11,ffffffffc0201668 <vprintfmt+0x2d8>
ffffffffc020157e:	02d00693          	li	a3,45
ffffffffc0201582:	0cd79163          	bne	a5,a3,ffffffffc0201644 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201586:	00044783          	lbu	a5,0(s0)
ffffffffc020158a:	0007851b          	sext.w	a0,a5
ffffffffc020158e:	cf85                	beqz	a5,ffffffffc02015c6 <vprintfmt+0x236>
ffffffffc0201590:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201594:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201598:	000c4563          	bltz	s8,ffffffffc02015a2 <vprintfmt+0x212>
ffffffffc020159c:	3c7d                	addiw	s8,s8,-1
ffffffffc020159e:	036c0263          	beq	s8,s6,ffffffffc02015c2 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02015a2:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015a4:	0e0c8e63          	beqz	s9,ffffffffc02016a0 <vprintfmt+0x310>
ffffffffc02015a8:	3781                	addiw	a5,a5,-32
ffffffffc02015aa:	0ef47b63          	bgeu	s0,a5,ffffffffc02016a0 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02015ae:	03f00513          	li	a0,63
ffffffffc02015b2:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015b4:	000a4783          	lbu	a5,0(s4)
ffffffffc02015b8:	3dfd                	addiw	s11,s11,-1
ffffffffc02015ba:	0a05                	addi	s4,s4,1
ffffffffc02015bc:	0007851b          	sext.w	a0,a5
ffffffffc02015c0:	ffe1                	bnez	a5,ffffffffc0201598 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02015c2:	01b05963          	blez	s11,ffffffffc02015d4 <vprintfmt+0x244>
ffffffffc02015c6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02015c8:	85a6                	mv	a1,s1
ffffffffc02015ca:	02000513          	li	a0,32
ffffffffc02015ce:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02015d0:	fe0d9be3          	bnez	s11,ffffffffc02015c6 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02015d4:	6a02                	ld	s4,0(sp)
ffffffffc02015d6:	bbd5                	j	ffffffffc02013ca <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02015d8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02015da:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02015de:	01174463          	blt	a4,a7,ffffffffc02015e6 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02015e2:	08088d63          	beqz	a7,ffffffffc020167c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02015e6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02015ea:	0a044d63          	bltz	s0,ffffffffc02016a4 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02015ee:	8622                	mv	a2,s0
ffffffffc02015f0:	8a66                	mv	s4,s9
ffffffffc02015f2:	46a9                	li	a3,10
ffffffffc02015f4:	bdcd                	j	ffffffffc02014e6 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02015f6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02015fa:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02015fc:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02015fe:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201602:	8fb5                	xor	a5,a5,a3
ffffffffc0201604:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201608:	02d74163          	blt	a4,a3,ffffffffc020162a <vprintfmt+0x29a>
ffffffffc020160c:	00369793          	slli	a5,a3,0x3
ffffffffc0201610:	97de                	add	a5,a5,s7
ffffffffc0201612:	639c                	ld	a5,0(a5)
ffffffffc0201614:	cb99                	beqz	a5,ffffffffc020162a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201616:	86be                	mv	a3,a5
ffffffffc0201618:	00001617          	auipc	a2,0x1
ffffffffc020161c:	8e860613          	addi	a2,a2,-1816 # ffffffffc0201f00 <default_pmm_manager+0x68>
ffffffffc0201620:	85a6                	mv	a1,s1
ffffffffc0201622:	854a                	mv	a0,s2
ffffffffc0201624:	0ce000ef          	jal	ra,ffffffffc02016f2 <printfmt>
ffffffffc0201628:	b34d                	j	ffffffffc02013ca <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020162a:	00001617          	auipc	a2,0x1
ffffffffc020162e:	8c660613          	addi	a2,a2,-1850 # ffffffffc0201ef0 <default_pmm_manager+0x58>
ffffffffc0201632:	85a6                	mv	a1,s1
ffffffffc0201634:	854a                	mv	a0,s2
ffffffffc0201636:	0bc000ef          	jal	ra,ffffffffc02016f2 <printfmt>
ffffffffc020163a:	bb41                	j	ffffffffc02013ca <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020163c:	00001417          	auipc	s0,0x1
ffffffffc0201640:	8ac40413          	addi	s0,s0,-1876 # ffffffffc0201ee8 <default_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201644:	85e2                	mv	a1,s8
ffffffffc0201646:	8522                	mv	a0,s0
ffffffffc0201648:	e43e                	sd	a5,8(sp)
ffffffffc020164a:	c69ff0ef          	jal	ra,ffffffffc02012b2 <strnlen>
ffffffffc020164e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201652:	01b05b63          	blez	s11,ffffffffc0201668 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201656:	67a2                	ld	a5,8(sp)
ffffffffc0201658:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020165c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020165e:	85a6                	mv	a1,s1
ffffffffc0201660:	8552                	mv	a0,s4
ffffffffc0201662:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201664:	fe0d9ce3          	bnez	s11,ffffffffc020165c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201668:	00044783          	lbu	a5,0(s0)
ffffffffc020166c:	00140a13          	addi	s4,s0,1
ffffffffc0201670:	0007851b          	sext.w	a0,a5
ffffffffc0201674:	d3a5                	beqz	a5,ffffffffc02015d4 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201676:	05e00413          	li	s0,94
ffffffffc020167a:	bf39                	j	ffffffffc0201598 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020167c:	000a2403          	lw	s0,0(s4)
ffffffffc0201680:	b7ad                	j	ffffffffc02015ea <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201682:	000a6603          	lwu	a2,0(s4)
ffffffffc0201686:	46a1                	li	a3,8
ffffffffc0201688:	8a2e                	mv	s4,a1
ffffffffc020168a:	bdb1                	j	ffffffffc02014e6 <vprintfmt+0x156>
ffffffffc020168c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201690:	46a9                	li	a3,10
ffffffffc0201692:	8a2e                	mv	s4,a1
ffffffffc0201694:	bd89                	j	ffffffffc02014e6 <vprintfmt+0x156>
ffffffffc0201696:	000a6603          	lwu	a2,0(s4)
ffffffffc020169a:	46c1                	li	a3,16
ffffffffc020169c:	8a2e                	mv	s4,a1
ffffffffc020169e:	b5a1                	j	ffffffffc02014e6 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02016a0:	9902                	jalr	s2
ffffffffc02016a2:	bf09                	j	ffffffffc02015b4 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02016a4:	85a6                	mv	a1,s1
ffffffffc02016a6:	02d00513          	li	a0,45
ffffffffc02016aa:	e03e                	sd	a5,0(sp)
ffffffffc02016ac:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02016ae:	6782                	ld	a5,0(sp)
ffffffffc02016b0:	8a66                	mv	s4,s9
ffffffffc02016b2:	40800633          	neg	a2,s0
ffffffffc02016b6:	46a9                	li	a3,10
ffffffffc02016b8:	b53d                	j	ffffffffc02014e6 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02016ba:	03b05163          	blez	s11,ffffffffc02016dc <vprintfmt+0x34c>
ffffffffc02016be:	02d00693          	li	a3,45
ffffffffc02016c2:	f6d79de3          	bne	a5,a3,ffffffffc020163c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02016c6:	00001417          	auipc	s0,0x1
ffffffffc02016ca:	82240413          	addi	s0,s0,-2014 # ffffffffc0201ee8 <default_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016ce:	02800793          	li	a5,40
ffffffffc02016d2:	02800513          	li	a0,40
ffffffffc02016d6:	00140a13          	addi	s4,s0,1
ffffffffc02016da:	bd6d                	j	ffffffffc0201594 <vprintfmt+0x204>
ffffffffc02016dc:	00001a17          	auipc	s4,0x1
ffffffffc02016e0:	80da0a13          	addi	s4,s4,-2035 # ffffffffc0201ee9 <default_pmm_manager+0x51>
ffffffffc02016e4:	02800513          	li	a0,40
ffffffffc02016e8:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016ec:	05e00413          	li	s0,94
ffffffffc02016f0:	b565                	j	ffffffffc0201598 <vprintfmt+0x208>

ffffffffc02016f2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016f2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02016f4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016f8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02016fa:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016fc:	ec06                	sd	ra,24(sp)
ffffffffc02016fe:	f83a                	sd	a4,48(sp)
ffffffffc0201700:	fc3e                	sd	a5,56(sp)
ffffffffc0201702:	e0c2                	sd	a6,64(sp)
ffffffffc0201704:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201706:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201708:	c89ff0ef          	jal	ra,ffffffffc0201390 <vprintfmt>
}
ffffffffc020170c:	60e2                	ld	ra,24(sp)
ffffffffc020170e:	6161                	addi	sp,sp,80
ffffffffc0201710:	8082                	ret

ffffffffc0201712 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201712:	4781                	li	a5,0
ffffffffc0201714:	00005717          	auipc	a4,0x5
ffffffffc0201718:	8fc73703          	ld	a4,-1796(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc020171c:	88ba                	mv	a7,a4
ffffffffc020171e:	852a                	mv	a0,a0
ffffffffc0201720:	85be                	mv	a1,a5
ffffffffc0201722:	863e                	mv	a2,a5
ffffffffc0201724:	00000073          	ecall
ffffffffc0201728:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020172a:	8082                	ret
