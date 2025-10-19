
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
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	fa450513          	addi	a0,a0,-92 # ffffffffc0201ff0 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	fae50513          	addi	a0,a0,-82 # ffffffffc0202010 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	f8058593          	addi	a1,a1,-128 # ffffffffc0201fee <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	fba50513          	addi	a0,a0,-70 # ffffffffc0202030 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <page_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	fc650513          	addi	a0,a0,-58 # ffffffffc0202050 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	a3258593          	addi	a1,a1,-1486 # ffffffffc0206ac8 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	fd250513          	addi	a0,a0,-46 # ffffffffc0202070 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	e1d58593          	addi	a1,a1,-483 # ffffffffc0206ec7 <end+0x3ff>
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
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	fc450513          	addi	a0,a0,-60 # ffffffffc0202090 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <page_area>
ffffffffc02000e0:	00007617          	auipc	a2,0x7
ffffffffc02000e4:	9e860613          	addi	a2,a2,-1560 # ffffffffc0206ac8 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	6ed010ef          	jal	ra,ffffffffc0201fdc <memset>
    dtb_init();
ffffffffc02000f4:	122000ef          	jal	ra,ffffffffc0200216 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	4ce000ef          	jal	ra,ffffffffc02005c6 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	fc450513          	addi	a0,a0,-60 # ffffffffc02020c0 <etext+0xd2>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4c4000ef          	jal	ra,ffffffffc02005d0 <pmm_init>

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
ffffffffc0200140:	241010ef          	jal	ra,ffffffffc0201b80 <vprintfmt>
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
ffffffffc0200176:	20b010ef          	jal	ra,ffffffffc0201b80 <vprintfmt>
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
ffffffffc02001c2:	00007317          	auipc	t1,0x7
ffffffffc02001c6:	8be30313          	addi	t1,t1,-1858 # ffffffffc0206a80 <is_panic>
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
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	eee50513          	addi	a0,a0,-274 # ffffffffc02020e0 <etext+0xf2>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	eb050513          	addi	a0,a0,-336 # ffffffffc02020b8 <etext+0xca>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200216:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200218:	00002517          	auipc	a0,0x2
ffffffffc020021c:	ee850513          	addi	a0,a0,-280 # ffffffffc0202100 <etext+0x112>
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
ffffffffc0200246:	00002517          	auipc	a0,0x2
ffffffffc020024a:	eca50513          	addi	a0,a0,-310 # ffffffffc0202110 <etext+0x122>
ffffffffc020024e:	effff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00006417          	auipc	s0,0x6
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0206008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	ec450513          	addi	a0,a0,-316 # ffffffffc0202120 <etext+0x132>
ffffffffc0200264:	ee9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026c:	00002517          	auipc	a0,0x2
ffffffffc0200270:	ecc50513          	addi	a0,a0,-308 # ffffffffc0202138 <etext+0x14a>
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
ffffffffc02002b4:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9425>
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
ffffffffc0200326:	00002917          	auipc	s2,0x2
ffffffffc020032a:	e6290913          	addi	s2,s2,-414 # ffffffffc0202188 <etext+0x19a>
ffffffffc020032e:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200330:	4d91                	li	s11,4
ffffffffc0200332:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200334:	00002497          	auipc	s1,0x2
ffffffffc0200338:	e4c48493          	addi	s1,s1,-436 # ffffffffc0202180 <etext+0x192>
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
ffffffffc0200388:	00002517          	auipc	a0,0x2
ffffffffc020038c:	e7850513          	addi	a0,a0,-392 # ffffffffc0202200 <etext+0x212>
ffffffffc0200390:	dbdff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200394:	00002517          	auipc	a0,0x2
ffffffffc0200398:	ea450513          	addi	a0,a0,-348 # ffffffffc0202238 <etext+0x24a>
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
ffffffffc02003d4:	00002517          	auipc	a0,0x2
ffffffffc02003d8:	d8450513          	addi	a0,a0,-636 # ffffffffc0202158 <etext+0x16a>
}
ffffffffc02003dc:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	b3bd                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003e0:	8556                	mv	a0,s5
ffffffffc02003e2:	381010ef          	jal	ra,ffffffffc0201f62 <strlen>
ffffffffc02003e6:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	4619                	li	a2,6
ffffffffc02003ea:	85a6                	mv	a1,s1
ffffffffc02003ec:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003ee:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f0:	3c7010ef          	jal	ra,ffffffffc0201fb6 <strncmp>
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
ffffffffc0200486:	313010ef          	jal	ra,ffffffffc0201f98 <strcmp>
ffffffffc020048a:	66a2                	ld	a3,8(sp)
ffffffffc020048c:	f94d                	bnez	a0,ffffffffc020043e <dtb_init+0x228>
ffffffffc020048e:	fb59f8e3          	bgeu	s3,s5,ffffffffc020043e <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200492:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200496:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020049a:	00002517          	auipc	a0,0x2
ffffffffc020049e:	cf650513          	addi	a0,a0,-778 # ffffffffc0202190 <etext+0x1a2>
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
ffffffffc0200568:	00002517          	auipc	a0,0x2
ffffffffc020056c:	c4850513          	addi	a0,a0,-952 # ffffffffc02021b0 <etext+0x1c2>
ffffffffc0200570:	bddff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200574:	014b5613          	srli	a2,s6,0x14
ffffffffc0200578:	85da                	mv	a1,s6
ffffffffc020057a:	00002517          	auipc	a0,0x2
ffffffffc020057e:	c4e50513          	addi	a0,a0,-946 # ffffffffc02021c8 <etext+0x1da>
ffffffffc0200582:	bcbff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200586:	008b05b3          	add	a1,s6,s0
ffffffffc020058a:	15fd                	addi	a1,a1,-1
ffffffffc020058c:	00002517          	auipc	a0,0x2
ffffffffc0200590:	c5c50513          	addi	a0,a0,-932 # ffffffffc02021e8 <etext+0x1fa>
ffffffffc0200594:	bb9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	ca050513          	addi	a0,a0,-864 # ffffffffc0202238 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005a0:	00006797          	auipc	a5,0x6
ffffffffc02005a4:	4e87b423          	sd	s0,1256(a5) # ffffffffc0206a88 <memory_base>
        memory_size = mem_size;
ffffffffc02005a8:	00006797          	auipc	a5,0x6
ffffffffc02005ac:	4f67b423          	sd	s6,1256(a5) # ffffffffc0206a90 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005b0:	b3f5                	j	ffffffffc020039c <dtb_init+0x186>

ffffffffc02005b2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005b2:	00006517          	auipc	a0,0x6
ffffffffc02005b6:	4d653503          	ld	a0,1238(a0) # ffffffffc0206a88 <memory_base>
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	4d453503          	ld	a0,1236(a0) # ffffffffc0206a90 <memory_size>
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
ffffffffc02005cc:	17d0106f          	j	ffffffffc0201f48 <sbi_console_putchar>

ffffffffc02005d0 <pmm_init>:
static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    // 使用伙伴分配器
    pmm_manager = &slub_pmm_manager;
ffffffffc02005d0:	00002797          	auipc	a5,0x2
ffffffffc02005d4:	32878793          	addi	a5,a5,808 # ffffffffc02028f8 <slub_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005d8:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02005da:	7179                	addi	sp,sp,-48
ffffffffc02005dc:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	c7250513          	addi	a0,a0,-910 # ffffffffc0202250 <etext+0x262>
    pmm_manager = &slub_pmm_manager;
ffffffffc02005e6:	00006417          	auipc	s0,0x6
ffffffffc02005ea:	4c240413          	addi	s0,s0,1218 # ffffffffc0206aa8 <pmm_manager>
void pmm_init(void) {
ffffffffc02005ee:	f406                	sd	ra,40(sp)
ffffffffc02005f0:	ec26                	sd	s1,24(sp)
ffffffffc02005f2:	e44e                	sd	s3,8(sp)
ffffffffc02005f4:	e84a                	sd	s2,16(sp)
ffffffffc02005f6:	e052                	sd	s4,0(sp)
    pmm_manager = &slub_pmm_manager;
ffffffffc02005f8:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005fa:	b53ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc02005fe:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200600:	00006497          	auipc	s1,0x6
ffffffffc0200604:	4c048493          	addi	s1,s1,1216 # ffffffffc0206ac0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200608:	679c                	ld	a5,8(a5)
ffffffffc020060a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020060c:	57f5                	li	a5,-3
ffffffffc020060e:	07fa                	slli	a5,a5,0x1e
ffffffffc0200610:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200612:	fa1ff0ef          	jal	ra,ffffffffc02005b2 <get_memory_base>
ffffffffc0200616:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200618:	fa5ff0ef          	jal	ra,ffffffffc02005bc <get_memory_size>
    if (mem_size == 0) {
ffffffffc020061c:	14050c63          	beqz	a0,ffffffffc0200774 <pmm_init+0x1a4>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200620:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200622:	00002517          	auipc	a0,0x2
ffffffffc0200626:	c7650513          	addi	a0,a0,-906 # ffffffffc0202298 <etext+0x2aa>
ffffffffc020062a:	b23ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020062e:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin, mem_end - 1);
ffffffffc0200632:	864e                	mv	a2,s3
ffffffffc0200634:	fffa0693          	addi	a3,s4,-1
ffffffffc0200638:	85ca                	mv	a1,s2
ffffffffc020063a:	00002517          	auipc	a0,0x2
ffffffffc020063e:	c7650513          	addi	a0,a0,-906 # ffffffffc02022b0 <etext+0x2c2>
ffffffffc0200642:	b0bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200646:	c80007b7          	lui	a5,0xc8000
ffffffffc020064a:	8652                	mv	a2,s4
ffffffffc020064c:	0d47e363          	bltu	a5,s4,ffffffffc0200712 <pmm_init+0x142>
ffffffffc0200650:	00007797          	auipc	a5,0x7
ffffffffc0200654:	47778793          	addi	a5,a5,1143 # ffffffffc0207ac7 <end+0xfff>
ffffffffc0200658:	757d                	lui	a0,0xfffff
ffffffffc020065a:	8d7d                	and	a0,a0,a5
ffffffffc020065c:	8231                	srli	a2,a2,0xc
ffffffffc020065e:	00006797          	auipc	a5,0x6
ffffffffc0200662:	42c7bd23          	sd	a2,1082(a5) # ffffffffc0206a98 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200666:	00006797          	auipc	a5,0x6
ffffffffc020066a:	42a7bd23          	sd	a0,1082(a5) # ffffffffc0206aa0 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020066e:	000807b7          	lui	a5,0x80
ffffffffc0200672:	002005b7          	lui	a1,0x200
ffffffffc0200676:	02f60563          	beq	a2,a5,ffffffffc02006a0 <pmm_init+0xd0>
ffffffffc020067a:	00261593          	slli	a1,a2,0x2
ffffffffc020067e:	00c586b3          	add	a3,a1,a2
ffffffffc0200682:	fec007b7          	lui	a5,0xfec00
ffffffffc0200686:	97aa                	add	a5,a5,a0
ffffffffc0200688:	068e                	slli	a3,a3,0x3
ffffffffc020068a:	96be                	add	a3,a3,a5
ffffffffc020068c:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc020068e:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200690:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9560>
        SetPageReserved(pages + i);
ffffffffc0200694:	00176713          	ori	a4,a4,1
ffffffffc0200698:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020069c:	fef699e3          	bne	a3,a5,ffffffffc020068e <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006a0:	95b2                	add	a1,a1,a2
ffffffffc02006a2:	fec006b7          	lui	a3,0xfec00
ffffffffc02006a6:	96aa                	add	a3,a3,a0
ffffffffc02006a8:	058e                	slli	a1,a1,0x3
ffffffffc02006aa:	96ae                	add	a3,a3,a1
ffffffffc02006ac:	c02007b7          	lui	a5,0xc0200
ffffffffc02006b0:	0af6e663          	bltu	a3,a5,ffffffffc020075c <pmm_init+0x18c>
ffffffffc02006b4:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02006b6:	77fd                	lui	a5,0xfffff
ffffffffc02006b8:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006bc:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02006be:	04b6ed63          	bltu	a3,a1,ffffffffc0200718 <pmm_init+0x148>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
            satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02006c2:	601c                	ld	a5,0(s0)
ffffffffc02006c4:	7b9c                	ld	a5,48(a5)
ffffffffc02006c6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02006c8:	00002517          	auipc	a0,0x2
ffffffffc02006cc:	c7050513          	addi	a0,a0,-912 # ffffffffc0202338 <etext+0x34a>
ffffffffc02006d0:	a7dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02006d4:	00005597          	auipc	a1,0x5
ffffffffc02006d8:	92c58593          	addi	a1,a1,-1748 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02006dc:	00006797          	auipc	a5,0x6
ffffffffc02006e0:	3cb7be23          	sd	a1,988(a5) # ffffffffc0206ab8 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02006e4:	c02007b7          	lui	a5,0xc0200
ffffffffc02006e8:	0af5e263          	bltu	a1,a5,ffffffffc020078c <pmm_init+0x1bc>
ffffffffc02006ec:	6090                	ld	a2,0(s1)
}
ffffffffc02006ee:	7402                	ld	s0,32(sp)
ffffffffc02006f0:	70a2                	ld	ra,40(sp)
ffffffffc02006f2:	64e2                	ld	s1,24(sp)
ffffffffc02006f4:	6942                	ld	s2,16(sp)
ffffffffc02006f6:	69a2                	ld	s3,8(sp)
ffffffffc02006f8:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02006fa:	40c58633          	sub	a2,a1,a2
ffffffffc02006fe:	00006797          	auipc	a5,0x6
ffffffffc0200702:	3ac7b923          	sd	a2,946(a5) # ffffffffc0206ab0 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
ffffffffc0200706:	00002517          	auipc	a0,0x2
ffffffffc020070a:	c5250513          	addi	a0,a0,-942 # ffffffffc0202358 <etext+0x36a>
}
ffffffffc020070e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n",
ffffffffc0200710:	bc35                	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200712:	c8000637          	lui	a2,0xc8000
ffffffffc0200716:	bf2d                	j	ffffffffc0200650 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200718:	6705                	lui	a4,0x1
ffffffffc020071a:	177d                	addi	a4,a4,-1
ffffffffc020071c:	96ba                	add	a3,a3,a4
ffffffffc020071e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200720:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200724:	02c7f063          	bgeu	a5,a2,ffffffffc0200744 <pmm_init+0x174>
    pmm_manager->init_memmap(base, n);
ffffffffc0200728:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020072a:	fff80737          	lui	a4,0xfff80
ffffffffc020072e:	973e                	add	a4,a4,a5
ffffffffc0200730:	00271793          	slli	a5,a4,0x2
ffffffffc0200734:	97ba                	add	a5,a5,a4
ffffffffc0200736:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200738:	8d95                	sub	a1,a1,a3
ffffffffc020073a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020073c:	81b1                	srli	a1,a1,0xc
ffffffffc020073e:	953e                	add	a0,a0,a5
ffffffffc0200740:	9702                	jalr	a4
}
ffffffffc0200742:	b741                	j	ffffffffc02006c2 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200744:	00002617          	auipc	a2,0x2
ffffffffc0200748:	bc460613          	addi	a2,a2,-1084 # ffffffffc0202308 <etext+0x31a>
ffffffffc020074c:	06a00593          	li	a1,106
ffffffffc0200750:	00002517          	auipc	a0,0x2
ffffffffc0200754:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202328 <etext+0x33a>
ffffffffc0200758:	a6bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020075c:	00002617          	auipc	a2,0x2
ffffffffc0200760:	b8460613          	addi	a2,a2,-1148 # ffffffffc02022e0 <etext+0x2f2>
ffffffffc0200764:	05c00593          	li	a1,92
ffffffffc0200768:	00002517          	auipc	a0,0x2
ffffffffc020076c:	b2050513          	addi	a0,a0,-1248 # ffffffffc0202288 <etext+0x29a>
ffffffffc0200770:	a53ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200774:	00002617          	auipc	a2,0x2
ffffffffc0200778:	af460613          	addi	a2,a2,-1292 # ffffffffc0202268 <etext+0x27a>
ffffffffc020077c:	04600593          	li	a1,70
ffffffffc0200780:	00002517          	auipc	a0,0x2
ffffffffc0200784:	b0850513          	addi	a0,a0,-1272 # ffffffffc0202288 <etext+0x29a>
ffffffffc0200788:	a3bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020078c:	86ae                	mv	a3,a1
ffffffffc020078e:	00002617          	auipc	a2,0x2
ffffffffc0200792:	b5260613          	addi	a2,a2,-1198 # ffffffffc02022e0 <etext+0x2f2>
ffffffffc0200796:	07200593          	li	a1,114
ffffffffc020079a:	00002517          	auipc	a0,0x2
ffffffffc020079e:	aee50513          	addi	a0,a0,-1298 # ffffffffc0202288 <etext+0x29a>
ffffffffc02007a2:	a21ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007a6 <page_try_merge>:
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02007a6:	6d18                	ld	a4,24(a0)
 * page_try_merge - 尝试与前后相邻空闲块合并，避免碎片。
 * 约定：base 已经插入到空闲链表。
 */
static void page_try_merge(struct Page *base) {
    list_entry_t *prev = list_prev(&(base->page_link));
    if (prev != &page_free_list) {
ffffffffc02007a8:	00006697          	auipc	a3,0x6
ffffffffc02007ac:	87068693          	addi	a3,a3,-1936 # ffffffffc0206018 <page_area>
    __list_del(listelm->prev, listelm->next);
ffffffffc02007b0:	710c                	ld	a1,32(a0)
ffffffffc02007b2:	02d70063          	beq	a4,a3,ffffffffc02007d2 <page_try_merge+0x2c>
        struct Page *p = le2page(prev, page_link);
        if (p + p->property == base) {
ffffffffc02007b6:	ff872883          	lw	a7,-8(a4) # fffffffffff7fff8 <end+0x3fd79530>
        struct Page *p = le2page(prev, page_link);
ffffffffc02007ba:	fe870813          	addi	a6,a4,-24
        if (p + p->property == base) {
ffffffffc02007be:	02089613          	slli	a2,a7,0x20
ffffffffc02007c2:	9201                	srli	a2,a2,0x20
ffffffffc02007c4:	00261793          	slli	a5,a2,0x2
ffffffffc02007c8:	97b2                	add	a5,a5,a2
ffffffffc02007ca:	078e                	slli	a5,a5,0x3
ffffffffc02007cc:	97c2                	add	a5,a5,a6
ffffffffc02007ce:	04f50363          	beq	a0,a5,ffffffffc0200814 <page_try_merge+0x6e>
            list_del(&(base->page_link));
            base = p;
        }
    }
    list_entry_t *next = list_next(&(base->page_link));
    if (next != &page_free_list) {
ffffffffc02007d2:	00d58f63          	beq	a1,a3,ffffffffc02007f0 <page_try_merge+0x4a>
        struct Page *p = le2page(next, page_link);
        if (base + base->property == p) {
ffffffffc02007d6:	4910                	lw	a2,16(a0)
        struct Page *p = le2page(next, page_link);
ffffffffc02007d8:	fe858713          	addi	a4,a1,-24
        if (base + base->property == p) {
ffffffffc02007dc:	02061693          	slli	a3,a2,0x20
ffffffffc02007e0:	9281                	srli	a3,a3,0x20
ffffffffc02007e2:	00269793          	slli	a5,a3,0x2
ffffffffc02007e6:	97b6                	add	a5,a5,a3
ffffffffc02007e8:	078e                	slli	a5,a5,0x3
ffffffffc02007ea:	97aa                	add	a5,a5,a0
ffffffffc02007ec:	00e78363          	beq	a5,a4,ffffffffc02007f2 <page_try_merge+0x4c>
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
ffffffffc02007f0:	8082                	ret
            base->property += p->property;
ffffffffc02007f2:	ff85a703          	lw	a4,-8(a1)
            ClearPageProperty(p);
ffffffffc02007f6:	ff05b783          	ld	a5,-16(a1)
ffffffffc02007fa:	0005b803          	ld	a6,0(a1)
ffffffffc02007fe:	6594                	ld	a3,8(a1)
            base->property += p->property;
ffffffffc0200800:	9e39                	addw	a2,a2,a4
ffffffffc0200802:	c910                	sw	a2,16(a0)
            ClearPageProperty(p);
ffffffffc0200804:	9bf5                	andi	a5,a5,-3
ffffffffc0200806:	fef5b823          	sd	a5,-16(a1)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020080a:	00d83423          	sd	a3,8(a6)
    next->prev = prev;
ffffffffc020080e:	0106b023          	sd	a6,0(a3)
}
ffffffffc0200812:	8082                	ret
            p->property += base->property;
ffffffffc0200814:	4910                	lw	a2,16(a0)
            ClearPageProperty(base);
ffffffffc0200816:	651c                	ld	a5,8(a0)
            p->property += base->property;
ffffffffc0200818:	011608bb          	addw	a7,a2,a7
ffffffffc020081c:	ff172c23          	sw	a7,-8(a4)
            ClearPageProperty(base);
ffffffffc0200820:	9bf5                	andi	a5,a5,-3
ffffffffc0200822:	e51c                	sd	a5,8(a0)
    prev->next = next;
ffffffffc0200824:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200826:	e198                	sd	a4,0(a1)
            base = p;
ffffffffc0200828:	8542                	mv	a0,a6
ffffffffc020082a:	b765                	j	ffffffffc02007d2 <page_try_merge+0x2c>

ffffffffc020082c <slub_nr_free_pages_iface>:
    slub_page_free(base, n);
}

static size_t slub_nr_free_pages_iface(void) {
    return slub_page_nr_free();
}
ffffffffc020082c:	00005517          	auipc	a0,0x5
ffffffffc0200830:	7fc56503          	lwu	a0,2044(a0) # ffffffffc0206028 <page_area+0x10>
ffffffffc0200834:	8082                	ret

ffffffffc0200836 <slub_cache_setup>:
                             size_t obj_size, size_t align, bool is_default) {
ffffffffc0200836:	7179                	addi	sp,sp,-48
ffffffffc0200838:	f022                	sd	s0,32(sp)
ffffffffc020083a:	ec26                	sd	s1,24(sp)
ffffffffc020083c:	842a                	mv	s0,a0
ffffffffc020083e:	e052                	sd	s4,0(sp)
ffffffffc0200840:	84b2                	mv	s1,a2
ffffffffc0200842:	8a2e                	mv	s4,a1
    memset(cache, 0, sizeof(*cache));
ffffffffc0200844:	07800613          	li	a2,120
ffffffffc0200848:	4581                	li	a1,0
                             size_t obj_size, size_t align, bool is_default) {
ffffffffc020084a:	e84a                	sd	s2,16(sp)
ffffffffc020084c:	e44e                	sd	s3,8(sp)
ffffffffc020084e:	f406                	sd	ra,40(sp)
ffffffffc0200850:	8936                	mv	s2,a3
ffffffffc0200852:	89ba                	mv	s3,a4
    memset(cache, 0, sizeof(*cache));
ffffffffc0200854:	788010ef          	jal	ra,ffffffffc0201fdc <memset>
    cache->name = name;
ffffffffc0200858:	01443023          	sd	s4,0(s0)
    cache->obj_size = obj_size;
ffffffffc020085c:	e404                	sd	s1,8(s0)
    cache->align = (align == 0 ? SLUB_MIN_ALIGN : align);
ffffffffc020085e:	08091663          	bnez	s2,ffffffffc02008ea <slub_cache_setup+0xb4>
ffffffffc0200862:	47a1                	li	a5,8
ffffffffc0200864:	ec1c                	sd	a5,24(s0)
ffffffffc0200866:	4921                	li	s2,8
    stride = ROUNDUP(stride, cache->align);
ffffffffc0200868:	4789                	li	a5,2
ffffffffc020086a:	8626                	mv	a2,s1
ffffffffc020086c:	00f4f363          	bgeu	s1,a5,ffffffffc0200872 <slub_cache_setup+0x3c>
ffffffffc0200870:	4609                	li	a2,2
ffffffffc0200872:	167d                	addi	a2,a2,-1
ffffffffc0200874:	964a                	add	a2,a2,s2
ffffffffc0200876:	032676b3          	remu	a3,a2,s2
    cache->objs_per_slab = (usable >= stride)
ffffffffc020087a:	6785                	lui	a5,0x1
ffffffffc020087c:	fd078793          	addi	a5,a5,-48 # fd0 <kern_entry-0xffffffffc01ff030>
ffffffffc0200880:	4881                	li	a7,0
    stride = ROUNDUP(stride, cache->align);
ffffffffc0200882:	40d606b3          	sub	a3,a2,a3
    cache->obj_stride = stride;
ffffffffc0200886:	e814                	sd	a3,16(s0)
    cache->objs_per_slab = (usable >= stride)
ffffffffc0200888:	00d7e863          	bltu	a5,a3,ffffffffc0200898 <slub_cache_setup+0x62>
                               ? (uint16_t)(usable / stride)
ffffffffc020088c:	02d7d6b3          	divu	a3,a5,a3
    cache->objs_per_slab = (usable >= stride)
ffffffffc0200890:	03069893          	slli	a7,a3,0x30
ffffffffc0200894:	0308d893          	srli	a7,a7,0x30
    __list_add(elm, listelm, listelm->next);
ffffffffc0200898:	00005617          	auipc	a2,0x5
ffffffffc020089c:	79860613          	addi	a2,a2,1944 # ffffffffc0206030 <slub_cache_list>
ffffffffc02008a0:	6618                	ld	a4,8(a2)
    list_init(&cache->partial);
ffffffffc02008a2:	05840813          	addi	a6,s0,88
    list_init(&cache->full);
ffffffffc02008a6:	06840513          	addi	a0,s0,104
    cache->active = 1;
ffffffffc02008aa:	4785                	li	a5,1
    cache->is_default = is_default;
ffffffffc02008ac:	05342023          	sw	s3,64(s0)
    list_init(&cache->node);
ffffffffc02008b0:	04840593          	addi	a1,s0,72
    cache->objs_per_slab = (usable >= stride)
ffffffffc02008b4:	03141023          	sh	a7,32(s0)
    cache->slabs_total = 0;
ffffffffc02008b8:	02043423          	sd	zero,40(s0)
    cache->slabs_partial = 0;
ffffffffc02008bc:	02043823          	sd	zero,48(s0)
    cache->inuse_objs = 0;
ffffffffc02008c0:	02043c23          	sd	zero,56(s0)
    cache->active = 1;
ffffffffc02008c4:	c07c                	sw	a5,68(s0)
    elm->prev = elm->next = elm;
ffffffffc02008c6:	07043023          	sd	a6,96(s0)
ffffffffc02008ca:	05043c23          	sd	a6,88(s0)
ffffffffc02008ce:	f828                	sd	a0,112(s0)
ffffffffc02008d0:	f428                	sd	a0,104(s0)
    prev->next = next->prev = elm;
ffffffffc02008d2:	e30c                	sd	a1,0(a4)
}
ffffffffc02008d4:	70a2                	ld	ra,40(sp)
    elm->next = next;
ffffffffc02008d6:	e838                	sd	a4,80(s0)
    elm->prev = prev;
ffffffffc02008d8:	e430                	sd	a2,72(s0)
ffffffffc02008da:	7402                	ld	s0,32(sp)
    prev->next = next->prev = elm;
ffffffffc02008dc:	e60c                	sd	a1,8(a2)
ffffffffc02008de:	64e2                	ld	s1,24(sp)
ffffffffc02008e0:	6942                	ld	s2,16(sp)
ffffffffc02008e2:	69a2                	ld	s3,8(sp)
ffffffffc02008e4:	6a02                	ld	s4,0(sp)
ffffffffc02008e6:	6145                	addi	sp,sp,48
ffffffffc02008e8:	8082                	ret
    if (cache->align < sizeof(uint16_t)) {
ffffffffc02008ea:	4785                	li	a5,1
ffffffffc02008ec:	00f91663          	bne	s2,a5,ffffffffc02008f8 <slub_cache_setup+0xc2>
        cache->align = sizeof(uint16_t);
ffffffffc02008f0:	4789                	li	a5,2
ffffffffc02008f2:	ec1c                	sd	a5,24(s0)
ffffffffc02008f4:	4909                	li	s2,2
ffffffffc02008f6:	bf8d                	j	ffffffffc0200868 <slub_cache_setup+0x32>
    cache->align = (align == 0 ? SLUB_MIN_ALIGN : align);
ffffffffc02008f8:	01243c23          	sd	s2,24(s0)
ffffffffc02008fc:	b7b5                	j	ffffffffc0200868 <slub_cache_setup+0x32>

ffffffffc02008fe <slub_init>:
static void slub_init(void) {
ffffffffc02008fe:	7139                	addi	sp,sp,-64
ffffffffc0200900:	f822                	sd	s0,48(sp)
ffffffffc0200902:	f426                	sd	s1,40(sp)
ffffffffc0200904:	f04a                	sd	s2,32(sp)
ffffffffc0200906:	ec4e                	sd	s3,24(sp)
ffffffffc0200908:	e852                	sd	s4,16(sp)
ffffffffc020090a:	e456                	sd	s5,8(sp)
ffffffffc020090c:	fc06                	sd	ra,56(sp)
    elm->prev = elm->next = elm;
ffffffffc020090e:	00005717          	auipc	a4,0x5
ffffffffc0200912:	70a70713          	addi	a4,a4,1802 # ffffffffc0206018 <page_area>
ffffffffc0200916:	00005797          	auipc	a5,0x5
ffffffffc020091a:	71a78793          	addi	a5,a5,1818 # ffffffffc0206030 <slub_cache_list>
ffffffffc020091e:	e718                	sd	a4,8(a4)
ffffffffc0200920:	e318                	sd	a4,0(a4)
    memset(slub_custom_used, 0, sizeof(slub_custom_used));
ffffffffc0200922:	02000613          	li	a2,32
ffffffffc0200926:	4581                	li	a1,0
ffffffffc0200928:	00006517          	auipc	a0,0x6
ffffffffc020092c:	ad850513          	addi	a0,a0,-1320 # ffffffffc0206400 <slub_custom_used>
    page_nr_free = 0;
ffffffffc0200930:	00005717          	auipc	a4,0x5
ffffffffc0200934:	6e072c23          	sw	zero,1784(a4) # ffffffffc0206028 <page_area+0x10>
ffffffffc0200938:	e79c                	sd	a5,8(a5)
ffffffffc020093a:	e39c                	sd	a5,0(a5)
    memset(slub_custom_used, 0, sizeof(slub_custom_used));
ffffffffc020093c:	00006497          	auipc	s1,0x6
ffffffffc0200940:	08448493          	addi	s1,s1,132 # ffffffffc02069c0 <slub_default_names>
ffffffffc0200944:	698010ef          	jal	ra,ffffffffc0201fdc <memset>
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc0200948:	00006417          	auipc	s0,0x6
ffffffffc020094c:	ad840413          	addi	s0,s0,-1320 # ffffffffc0206420 <slub_default_caches>
ffffffffc0200950:	00002997          	auipc	s3,0x2
ffffffffc0200954:	f5098993          	addi	s3,s3,-176 # ffffffffc02028a0 <slub_default_sizes+0x8>
ffffffffc0200958:	00006a97          	auipc	s5,0x6
ffffffffc020095c:	068a8a93          	addi	s5,s5,104 # ffffffffc02069c0 <slub_default_names>
    memset(slub_custom_used, 0, sizeof(slub_custom_used));
ffffffffc0200960:	4921                	li	s2,8
        snprintf(slub_default_names[i],
ffffffffc0200962:	00002a17          	auipc	s4,0x2
ffffffffc0200966:	a36a0a13          	addi	s4,s4,-1482 # ffffffffc0202398 <etext+0x3aa>
ffffffffc020096a:	a021                	j	ffffffffc0200972 <slub_init+0x74>
                 "slub-%u", (unsigned)slub_default_sizes[i]);
ffffffffc020096c:	0009b903          	ld	s2,0(s3)
ffffffffc0200970:	09a1                	addi	s3,s3,8
        snprintf(slub_default_names[i],
ffffffffc0200972:	0009069b          	sext.w	a3,s2
ffffffffc0200976:	8652                	mv	a2,s4
ffffffffc0200978:	45c1                	li	a1,16
ffffffffc020097a:	8526                	mv	a0,s1
ffffffffc020097c:	586010ef          	jal	ra,ffffffffc0201f02 <snprintf>
        slub_cache_setup(cache, slub_default_names[i],
ffffffffc0200980:	85a6                	mv	a1,s1
ffffffffc0200982:	8522                	mv	a0,s0
ffffffffc0200984:	864a                	mv	a2,s2
ffffffffc0200986:	4705                	li	a4,1
ffffffffc0200988:	46a1                	li	a3,8
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc020098a:	07840413          	addi	s0,s0,120
        slub_cache_setup(cache, slub_default_names[i],
ffffffffc020098e:	ea9ff0ef          	jal	ra,ffffffffc0200836 <slub_cache_setup>
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc0200992:	04c1                	addi	s1,s1,16
ffffffffc0200994:	fd541ce3          	bne	s0,s5,ffffffffc020096c <slub_init+0x6e>
}
ffffffffc0200998:	70e2                	ld	ra,56(sp)
ffffffffc020099a:	7442                	ld	s0,48(sp)
ffffffffc020099c:	74a2                	ld	s1,40(sp)
ffffffffc020099e:	7902                	ld	s2,32(sp)
ffffffffc02009a0:	69e2                	ld	s3,24(sp)
ffffffffc02009a2:	6a42                	ld	s4,16(sp)
ffffffffc02009a4:	6aa2                	ld	s5,8(sp)
ffffffffc02009a6:	6121                	addi	sp,sp,64
ffffffffc02009a8:	8082                	ret

ffffffffc02009aa <slub_page_alloc.part.0>:
    return listelm->next;
ffffffffc02009aa:	00005617          	auipc	a2,0x5
ffffffffc02009ae:	66e60613          	addi	a2,a2,1646 # ffffffffc0206018 <page_area>
ffffffffc02009b2:	661c                	ld	a5,8(a2)
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc02009b4:	06c78663          	beq	a5,a2,ffffffffc0200a20 <slub_page_alloc.part.0+0x76>
ffffffffc02009b8:	86aa                	mv	a3,a0
    size_t best_size = 0;
ffffffffc02009ba:	4801                	li	a6,0
    struct Page *best = NULL;
ffffffffc02009bc:	4501                	li	a0,0
        SLUB_ASSERT(PageProperty(p));
ffffffffc02009be:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02009c2:	fe878593          	addi	a1,a5,-24
        SLUB_ASSERT(PageProperty(p));
ffffffffc02009c6:	8b09                	andi	a4,a4,2
ffffffffc02009c8:	c34d                	beqz	a4,ffffffffc0200a6a <slub_page_alloc.part.0+0xc0>
        if (p->property >= n &&
ffffffffc02009ca:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02009ce:	00d76763          	bltu	a4,a3,ffffffffc02009dc <slub_page_alloc.part.0+0x32>
ffffffffc02009d2:	c119                	beqz	a0,ffffffffc02009d8 <slub_page_alloc.part.0+0x2e>
            (best == NULL || p->property < best_size)) {
ffffffffc02009d4:	01077463          	bgeu	a4,a6,ffffffffc02009dc <slub_page_alloc.part.0+0x32>
ffffffffc02009d8:	883a                	mv	a6,a4
            best = p;
ffffffffc02009da:	852e                	mv	a0,a1
ffffffffc02009dc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc02009de:	fec790e3          	bne	a5,a2,ffffffffc02009be <slub_page_alloc.part.0+0x14>
    if (best == NULL) {
ffffffffc02009e2:	c121                	beqz	a0,ffffffffc0200a22 <slub_page_alloc.part.0+0x78>
    __list_del(listelm->prev, listelm->next);
ffffffffc02009e4:	6d0c                	ld	a1,24(a0)
ffffffffc02009e6:	7118                	ld	a4,32(a0)
        remain->property = best_size - n;
ffffffffc02009e8:	0006889b          	sext.w	a7,a3
    prev->next = next;
ffffffffc02009ec:	e598                	sd	a4,8(a1)
    next->prev = prev;
ffffffffc02009ee:	e30c                	sd	a1,0(a4)
    if (best_size > n) {
ffffffffc02009f0:	0306ea63          	bltu	a3,a6,ffffffffc0200a24 <slub_page_alloc.part.0+0x7a>
    for (size_t i = 0; i < n; i++) {
ffffffffc02009f4:	c28d                	beqz	a3,ffffffffc0200a16 <slub_page_alloc.part.0+0x6c>
ffffffffc02009f6:	00269793          	slli	a5,a3,0x2
ffffffffc02009fa:	96be                	add	a3,a3,a5
ffffffffc02009fc:	068e                	slli	a3,a3,0x3
ffffffffc02009fe:	87aa                	mv	a5,a0
ffffffffc0200a00:	96aa                	add	a3,a3,a0
        ClearPageProperty(p);
ffffffffc0200a02:	6798                	ld	a4,8(a5)
        p->property = 0;
ffffffffc0200a04:	0007a823          	sw	zero,16(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc0200a08:	02878793          	addi	a5,a5,40
        ClearPageProperty(p);
ffffffffc0200a0c:	9b75                	andi	a4,a4,-3
ffffffffc0200a0e:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc0200a12:	fef698e3          	bne	a3,a5,ffffffffc0200a02 <slub_page_alloc.part.0+0x58>
    page_nr_free -= n;
ffffffffc0200a16:	4a1c                	lw	a5,16(a2)
ffffffffc0200a18:	411787bb          	subw	a5,a5,a7
ffffffffc0200a1c:	ca1c                	sw	a5,16(a2)
    return best;
ffffffffc0200a1e:	8082                	ret
        return NULL;
ffffffffc0200a20:	4501                	li	a0,0
}
ffffffffc0200a22:	8082                	ret
        struct Page *remain = best + n;
ffffffffc0200a24:	00269713          	slli	a4,a3,0x2
ffffffffc0200a28:	9736                	add	a4,a4,a3
ffffffffc0200a2a:	070e                	slli	a4,a4,0x3
ffffffffc0200a2c:	972a                	add	a4,a4,a0
        SetPageProperty(remain);
ffffffffc0200a2e:	670c                	ld	a1,8(a4)
        list_init(&(remain->page_link));
ffffffffc0200a30:	01870313          	addi	t1,a4,24
        remain->property = best_size - n;
ffffffffc0200a34:	4118083b          	subw	a6,a6,a7
        SetPageProperty(remain);
ffffffffc0200a38:	0025e593          	ori	a1,a1,2
        remain->property = best_size - n;
ffffffffc0200a3c:	01072823          	sw	a6,16(a4)
        SetPageProperty(remain);
ffffffffc0200a40:	e70c                	sd	a1,8(a4)
    elm->prev = elm->next = elm;
ffffffffc0200a42:	02673023          	sd	t1,32(a4)
ffffffffc0200a46:	00673c23          	sd	t1,24(a4)
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc0200a4a:	a029                	j	ffffffffc0200a54 <slub_page_alloc.part.0+0xaa>
        if (base < le2page(le, page_link)) {
ffffffffc0200a4c:	fe878593          	addi	a1,a5,-24
ffffffffc0200a50:	00b76563          	bltu	a4,a1,ffffffffc0200a5a <slub_page_alloc.part.0+0xb0>
    return listelm->next;
ffffffffc0200a54:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc0200a56:	fec79be3          	bne	a5,a2,ffffffffc0200a4c <slub_page_alloc.part.0+0xa2>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200a5a:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200a5c:	0067b023          	sd	t1,0(a5)
ffffffffc0200a60:	0065b423          	sd	t1,8(a1)
    elm->next = next;
ffffffffc0200a64:	f31c                	sd	a5,32(a4)
    elm->prev = prev;
ffffffffc0200a66:	ef0c                	sd	a1,24(a4)
}
ffffffffc0200a68:	b771                	j	ffffffffc02009f4 <slub_page_alloc.part.0+0x4a>
static struct Page *slub_page_alloc(size_t n) {
ffffffffc0200a6a:	1141                	addi	sp,sp,-16
        SLUB_ASSERT(PageProperty(p));
ffffffffc0200a6c:	0cb00613          	li	a2,203
ffffffffc0200a70:	00002597          	auipc	a1,0x2
ffffffffc0200a74:	94058593          	addi	a1,a1,-1728 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200a78:	00002697          	auipc	a3,0x2
ffffffffc0200a7c:	92868693          	addi	a3,a3,-1752 # ffffffffc02023a0 <etext+0x3b2>
ffffffffc0200a80:	00002517          	auipc	a0,0x2
ffffffffc0200a84:	94850513          	addi	a0,a0,-1720 # ffffffffc02023c8 <etext+0x3da>
static struct Page *slub_page_alloc(size_t n) {
ffffffffc0200a88:	e406                	sd	ra,8(sp)
        SLUB_ASSERT(PageProperty(p));
ffffffffc0200a8a:	ec2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200a8e:	00002617          	auipc	a2,0x2
ffffffffc0200a92:	96260613          	addi	a2,a2,-1694 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200a96:	0cb00593          	li	a1,203
ffffffffc0200a9a:	00002517          	auipc	a0,0x2
ffffffffc0200a9e:	91650513          	addi	a0,a0,-1770 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200aa2:	f20ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200aa6 <kva2page_local.part.0>:
static inline struct Page *kva2page_local(const void *kva) {
ffffffffc0200aa6:	1141                	addi	sp,sp,-16
    SLUB_ASSERT(kva_val >= va_pa_offset);
ffffffffc0200aa8:	06900613          	li	a2,105
ffffffffc0200aac:	00002597          	auipc	a1,0x2
ffffffffc0200ab0:	90458593          	addi	a1,a1,-1788 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200ab4:	00002697          	auipc	a3,0x2
ffffffffc0200ab8:	94c68693          	addi	a3,a3,-1716 # ffffffffc0202400 <etext+0x412>
ffffffffc0200abc:	00002517          	auipc	a0,0x2
ffffffffc0200ac0:	90c50513          	addi	a0,a0,-1780 # ffffffffc02023c8 <etext+0x3da>
static inline struct Page *kva2page_local(const void *kva) {
ffffffffc0200ac4:	e406                	sd	ra,8(sp)
    SLUB_ASSERT(kva_val >= va_pa_offset);
ffffffffc0200ac6:	e86ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200aca:	00002617          	auipc	a2,0x2
ffffffffc0200ace:	92660613          	addi	a2,a2,-1754 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200ad2:	06900593          	li	a1,105
ffffffffc0200ad6:	00002517          	auipc	a0,0x2
ffffffffc0200ada:	8da50513          	addi	a0,a0,-1830 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200ade:	ee4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200ae2 <slub_cache_do_alloc>:
    if (cache->objs_per_slab == 0) {
ffffffffc0200ae2:	02055783          	lhu	a5,32(a0)
static void *slub_cache_do_alloc(struct slub_cache *cache) {
ffffffffc0200ae6:	7179                	addi	sp,sp,-48
ffffffffc0200ae8:	f406                	sd	ra,40(sp)
ffffffffc0200aea:	f022                	sd	s0,32(sp)
ffffffffc0200aec:	ec26                	sd	s1,24(sp)
ffffffffc0200aee:	e84a                	sd	s2,16(sp)
ffffffffc0200af0:	e44e                	sd	s3,8(sp)
    if (cache->objs_per_slab == 0) {
ffffffffc0200af2:	cfb5                	beqz	a5,ffffffffc0200b6e <slub_cache_do_alloc+0x8c>
    return list->next == list;
ffffffffc0200af4:	7124                	ld	s1,96(a0)
    if (list_empty(&cache->partial)) {
ffffffffc0200af6:	05850793          	addi	a5,a0,88
ffffffffc0200afa:	842a                	mv	s0,a0
ffffffffc0200afc:	08f48263          	beq	s1,a5,ffffffffc0200b80 <slub_cache_do_alloc+0x9e>
    SLUB_ASSERT(slab->free_count > 0);
ffffffffc0200b00:	ff84d783          	lhu	a5,-8(s1)
ffffffffc0200b04:	16078063          	beqz	a5,ffffffffc0200c64 <slub_cache_do_alloc+0x182>
    uint8_t *slot = slab_obj_base(slab) + obj_index * slab->obj_stride;
ffffffffc0200b08:	ffc4d683          	lhu	a3,-4(s1)
ffffffffc0200b0c:	ffe4d603          	lhu	a2,-2(s1)
    return (uint8_t *)(slab + 1);
ffffffffc0200b10:	01048913          	addi	s2,s1,16
    cache->inuse_objs++;
ffffffffc0200b14:	7c18                	ld	a4,56(s0)
    uint8_t *slot = slab_obj_base(slab) + obj_index * slab->obj_stride;
ffffffffc0200b16:	02c686bb          	mulw	a3,a3,a2
    slab->free_count--;
ffffffffc0200b1a:	37fd                	addiw	a5,a5,-1
ffffffffc0200b1c:	17c2                	slli	a5,a5,0x30
ffffffffc0200b1e:	93c1                	srli	a5,a5,0x30
    cache->inuse_objs++;
ffffffffc0200b20:	0705                	addi	a4,a4,1
    uint8_t *slot = slab_obj_base(slab) + obj_index * slab->obj_stride;
ffffffffc0200b22:	9936                	add	s2,s2,a3
    slab->free_head = *((uint16_t *)slot);
ffffffffc0200b24:	00095683          	lhu	a3,0(s2)
    slab->free_count--;
ffffffffc0200b28:	fef49c23          	sh	a5,-8(s1)
    slab->free_head = *((uint16_t *)slot);
ffffffffc0200b2c:	fed49e23          	sh	a3,-4(s1)
    cache->inuse_objs++;
ffffffffc0200b30:	fc18                	sd	a4,56(s0)
    if (slab->free_count == 0) {
ffffffffc0200b32:	e38d                	bnez	a5,ffffffffc0200b54 <slub_cache_do_alloc+0x72>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b34:	608c                	ld	a1,0(s1)
ffffffffc0200b36:	6490                	ld	a2,8(s1)
        SLUB_ASSERT(cache->slabs_partial > 0);
ffffffffc0200b38:	781c                	ld	a5,48(s0)
        list_add(&cache->full, &slab->link);
ffffffffc0200b3a:	06840713          	addi	a4,s0,104
    prev->next = next;
ffffffffc0200b3e:	e590                	sd	a2,8(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b40:	7834                	ld	a3,112(s0)
    next->prev = prev;
ffffffffc0200b42:	e20c                	sd	a1,0(a2)
    prev->next = next->prev = elm;
ffffffffc0200b44:	e284                	sd	s1,0(a3)
ffffffffc0200b46:	f824                	sd	s1,112(s0)
    elm->next = next;
ffffffffc0200b48:	e494                	sd	a3,8(s1)
    elm->prev = prev;
ffffffffc0200b4a:	e098                	sd	a4,0(s1)
        SLUB_ASSERT(cache->slabs_partial > 0);
ffffffffc0200b4c:	14078863          	beqz	a5,ffffffffc0200c9c <slub_cache_do_alloc+0x1ba>
        cache->slabs_partial--;
ffffffffc0200b50:	17fd                	addi	a5,a5,-1
ffffffffc0200b52:	f81c                	sd	a5,48(s0)
    memset(slot, 0, cache->obj_size);
ffffffffc0200b54:	6410                	ld	a2,8(s0)
ffffffffc0200b56:	854a                	mv	a0,s2
ffffffffc0200b58:	4581                	li	a1,0
ffffffffc0200b5a:	482010ef          	jal	ra,ffffffffc0201fdc <memset>
}
ffffffffc0200b5e:	70a2                	ld	ra,40(sp)
ffffffffc0200b60:	7402                	ld	s0,32(sp)
ffffffffc0200b62:	64e2                	ld	s1,24(sp)
ffffffffc0200b64:	69a2                	ld	s3,8(sp)
ffffffffc0200b66:	854a                	mv	a0,s2
ffffffffc0200b68:	6942                	ld	s2,16(sp)
ffffffffc0200b6a:	6145                	addi	sp,sp,48
ffffffffc0200b6c:	8082                	ret
ffffffffc0200b6e:	70a2                	ld	ra,40(sp)
ffffffffc0200b70:	7402                	ld	s0,32(sp)
        return NULL;
ffffffffc0200b72:	4901                	li	s2,0
}
ffffffffc0200b74:	64e2                	ld	s1,24(sp)
ffffffffc0200b76:	69a2                	ld	s3,8(sp)
ffffffffc0200b78:	854a                	mv	a0,s2
ffffffffc0200b7a:	6942                	ld	s2,16(sp)
ffffffffc0200b7c:	6145                	addi	sp,sp,48
ffffffffc0200b7e:	8082                	ret
    if (n > page_nr_free) {
ffffffffc0200b80:	00005797          	auipc	a5,0x5
ffffffffc0200b84:	4a87a783          	lw	a5,1192(a5) # ffffffffc0206028 <page_area+0x10>
ffffffffc0200b88:	d3fd                	beqz	a5,ffffffffc0200b6e <slub_cache_do_alloc+0x8c>
ffffffffc0200b8a:	4505                	li	a0,1
ffffffffc0200b8c:	e1fff0ef          	jal	ra,ffffffffc02009aa <slub_page_alloc.part.0>
ffffffffc0200b90:	89aa                	mv	s3,a0
    if (page == NULL) {
ffffffffc0200b92:	dd71                	beqz	a0,ffffffffc0200b6e <slub_cache_do_alloc+0x8c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b94:	00006917          	auipc	s2,0x6
ffffffffc0200b98:	f0c93903          	ld	s2,-244(s2) # ffffffffc0206aa0 <pages>
ffffffffc0200b9c:	41250933          	sub	s2,a0,s2
ffffffffc0200ba0:	00002797          	auipc	a5,0x2
ffffffffc0200ba4:	fe07b783          	ld	a5,-32(a5) # ffffffffc0202b80 <nbase+0x8>
ffffffffc0200ba8:	40395913          	srai	s2,s2,0x3
ffffffffc0200bac:	02f90933          	mul	s2,s2,a5
ffffffffc0200bb0:	00002797          	auipc	a5,0x2
ffffffffc0200bb4:	fc87b783          	ld	a5,-56(a5) # ffffffffc0202b78 <nbase>
    memset(slab, 0, sizeof(*slab));
ffffffffc0200bb8:	03000613          	li	a2,48
ffffffffc0200bbc:	4581                	li	a1,0
ffffffffc0200bbe:	993e                	add	s2,s2,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bc0:	0932                	slli	s2,s2,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc0200bc2:	00006797          	auipc	a5,0x6
ffffffffc0200bc6:	efe7b783          	ld	a5,-258(a5) # ffffffffc0206ac0 <va_pa_offset>
ffffffffc0200bca:	993e                	add	s2,s2,a5
    memset(slab, 0, sizeof(*slab));
ffffffffc0200bcc:	854a                	mv	a0,s2
ffffffffc0200bce:	40e010ef          	jal	ra,ffffffffc0201fdc <memset>
    slab->capacity = cache->objs_per_slab;
ffffffffc0200bd2:	02045703          	lhu	a4,32(s0)
    slab->obj_stride = (uint16_t)cache->obj_stride;
ffffffffc0200bd6:	01045783          	lhu	a5,16(s0)
    list_init(&slab->link);
ffffffffc0200bda:	02090813          	addi	a6,s2,32
    slab->free_head = (slab->capacity == 0) ? SLUB_FREELIST_END : 0;
ffffffffc0200bde:	00173693          	seqz	a3,a4
ffffffffc0200be2:	40d006bb          	negw	a3,a3
    slab->magic = SLUB_SLAB_MAGIC;
ffffffffc0200be6:	567d                	li	a2,-1
    slab->free_head = (slab->capacity == 0) ? SLUB_FREELIST_END : 0;
ffffffffc0200be8:	00d91e23          	sh	a3,28(s2)
    slab->magic = SLUB_SLAB_MAGIC;
ffffffffc0200bec:	00c92023          	sw	a2,0(s2)
    slab->cache = cache;
ffffffffc0200bf0:	00893423          	sd	s0,8(s2)
    slab->page = page;
ffffffffc0200bf4:	01393823          	sd	s3,16(s2)
    slab->capacity = cache->objs_per_slab;
ffffffffc0200bf8:	00e91d23          	sh	a4,26(s2)
    slab->free_count = slab->capacity;
ffffffffc0200bfc:	00e91c23          	sh	a4,24(s2)
    slab->obj_stride = (uint16_t)cache->obj_stride;
ffffffffc0200c00:	00f91f23          	sh	a5,30(s2)
    elm->prev = elm->next = elm;
ffffffffc0200c04:	03093423          	sd	a6,40(s2)
    slab->free_head = (slab->capacity == 0) ? SLUB_FREELIST_END : 0;
ffffffffc0200c08:	0007069b          	sext.w	a3,a4
    for (uint16_t i = 0; i < slab->capacity; i++) {
ffffffffc0200c0c:	cb1d                	beqz	a4,ffffffffc0200c42 <slub_cache_do_alloc+0x160>
        uint16_t next = (i + 1 < slab->capacity) ? (i + 1) : SLUB_FREELIST_END;
ffffffffc0200c0e:	6541                	lui	a0,0x10
    for (uint16_t i = 0; i < slab->capacity; i++) {
ffffffffc0200c10:	4701                	li	a4,0
        uint16_t next = (i + 1 < slab->capacity) ? (i + 1) : SLUB_FREELIST_END;
ffffffffc0200c12:	157d                	addi	a0,a0,-1
ffffffffc0200c14:	a019                	j	ffffffffc0200c1a <slub_cache_do_alloc+0x138>
        uint8_t *slot = base + i * slab->obj_stride;
ffffffffc0200c16:	01e95783          	lhu	a5,30(s2)
ffffffffc0200c1a:	02f707bb          	mulw	a5,a4,a5
ffffffffc0200c1e:	2705                	addiw	a4,a4,1
ffffffffc0200c20:	1742                	slli	a4,a4,0x30
ffffffffc0200c22:	9341                	srli	a4,a4,0x30
        uint16_t next = (i + 1 < slab->capacity) ? (i + 1) : SLUB_FREELIST_END;
ffffffffc0200c24:	0007059b          	sext.w	a1,a4
ffffffffc0200c28:	862a                	mv	a2,a0
        uint8_t *slot = base + i * slab->obj_stride;
ffffffffc0200c2a:	03078793          	addi	a5,a5,48
ffffffffc0200c2e:	97ca                	add	a5,a5,s2
        uint16_t next = (i + 1 < slab->capacity) ? (i + 1) : SLUB_FREELIST_END;
ffffffffc0200c30:	00d77363          	bgeu	a4,a3,ffffffffc0200c36 <slub_cache_do_alloc+0x154>
ffffffffc0200c34:	863a                	mv	a2,a4
        *((uint16_t *)slot) = next;
ffffffffc0200c36:	00c79023          	sh	a2,0(a5)
    for (uint16_t i = 0; i < slab->capacity; i++) {
ffffffffc0200c3a:	01a95683          	lhu	a3,26(s2)
ffffffffc0200c3e:	fcd5ece3          	bltu	a1,a3,ffffffffc0200c16 <slub_cache_do_alloc+0x134>
    cache->slabs_total++;
ffffffffc0200c42:	7418                	ld	a4,40(s0)
    cache->slabs_partial++;
ffffffffc0200c44:	781c                	ld	a5,48(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c46:	7034                	ld	a3,96(s0)
    cache->slabs_total++;
ffffffffc0200c48:	0705                	addi	a4,a4,1
    cache->slabs_partial++;
ffffffffc0200c4a:	0785                	addi	a5,a5,1
    cache->slabs_total++;
ffffffffc0200c4c:	f418                	sd	a4,40(s0)
    cache->slabs_partial++;
ffffffffc0200c4e:	f81c                	sd	a5,48(s0)
    prev->next = next->prev = elm;
ffffffffc0200c50:	0106b023          	sd	a6,0(a3)
ffffffffc0200c54:	07043023          	sd	a6,96(s0)
    elm->next = next;
ffffffffc0200c58:	02d93423          	sd	a3,40(s2)
    elm->prev = prev;
ffffffffc0200c5c:	02993023          	sd	s1,32(s2)
    return listelm->next;
ffffffffc0200c60:	7024                	ld	s1,96(s0)
ffffffffc0200c62:	bd79                	j	ffffffffc0200b00 <slub_cache_do_alloc+0x1e>
    SLUB_ASSERT(slab->free_count > 0);
ffffffffc0200c64:	18e00613          	li	a2,398
ffffffffc0200c68:	00001597          	auipc	a1,0x1
ffffffffc0200c6c:	74858593          	addi	a1,a1,1864 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200c70:	00001697          	auipc	a3,0x1
ffffffffc0200c74:	7a868693          	addi	a3,a3,1960 # ffffffffc0202418 <etext+0x42a>
ffffffffc0200c78:	00001517          	auipc	a0,0x1
ffffffffc0200c7c:	75050513          	addi	a0,a0,1872 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200c80:	cccff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200c84:	00001617          	auipc	a2,0x1
ffffffffc0200c88:	76c60613          	addi	a2,a2,1900 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200c8c:	18e00593          	li	a1,398
ffffffffc0200c90:	00001517          	auipc	a0,0x1
ffffffffc0200c94:	72050513          	addi	a0,a0,1824 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200c98:	d2aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        SLUB_ASSERT(cache->slabs_partial > 0);
ffffffffc0200c9c:	19700613          	li	a2,407
ffffffffc0200ca0:	00001597          	auipc	a1,0x1
ffffffffc0200ca4:	71058593          	addi	a1,a1,1808 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200ca8:	00001697          	auipc	a3,0x1
ffffffffc0200cac:	78868693          	addi	a3,a3,1928 # ffffffffc0202430 <etext+0x442>
ffffffffc0200cb0:	00001517          	auipc	a0,0x1
ffffffffc0200cb4:	71850513          	addi	a0,a0,1816 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200cb8:	c94ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200cbc:	00001617          	auipc	a2,0x1
ffffffffc0200cc0:	73460613          	addi	a2,a2,1844 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200cc4:	19700593          	li	a1,407
ffffffffc0200cc8:	00001517          	auipc	a0,0x1
ffffffffc0200ccc:	6e850513          	addi	a0,a0,1768 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200cd0:	cf2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200cd4 <slub_page_free.part.0>:
    for (size_t i = 0; i < n; i++) {
ffffffffc0200cd4:	c18d                	beqz	a1,ffffffffc0200cf6 <slub_page_free.part.0+0x22>
ffffffffc0200cd6:	87aa                	mv	a5,a0
ffffffffc0200cd8:	4681                	li	a3,0
        SLUB_ASSERT(!PageReserved(p) && !PageProperty(p));
ffffffffc0200cda:	6798                	ld	a4,8(a5)
ffffffffc0200cdc:	8b0d                	andi	a4,a4,3
ffffffffc0200cde:	ef21                	bnez	a4,ffffffffc0200d36 <slub_page_free.part.0+0x62>
        p->flags = 0;
ffffffffc0200ce0:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0200ce4:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200ce8:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc0200cec:	0685                	addi	a3,a3,1
ffffffffc0200cee:	02878793          	addi	a5,a5,40
ffffffffc0200cf2:	feb694e3          	bne	a3,a1,ffffffffc0200cda <slub_page_free.part.0+0x6>
    SetPageProperty(base);
ffffffffc0200cf6:	6518                	ld	a4,8(a0)
    page_nr_free += n;
ffffffffc0200cf8:	00005697          	auipc	a3,0x5
ffffffffc0200cfc:	32068693          	addi	a3,a3,800 # ffffffffc0206018 <page_area>
ffffffffc0200d00:	4a9c                	lw	a5,16(a3)
    base->property = n;
ffffffffc0200d02:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200d04:	00276713          	ori	a4,a4,2
    list_init(&(base->page_link));
ffffffffc0200d08:	01850613          	addi	a2,a0,24
    base->property = n;
ffffffffc0200d0c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200d0e:	e518                	sd	a4,8(a0)
    page_nr_free += n;
ffffffffc0200d10:	9dbd                	addw	a1,a1,a5
ffffffffc0200d12:	ca8c                	sw	a1,16(a3)
    elm->prev = elm->next = elm;
ffffffffc0200d14:	f110                	sd	a2,32(a0)
ffffffffc0200d16:	ed10                	sd	a2,24(a0)
    list_entry_t *le = &page_free_list;
ffffffffc0200d18:	87b6                	mv	a5,a3
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc0200d1a:	a029                	j	ffffffffc0200d24 <slub_page_free.part.0+0x50>
        if (base < le2page(le, page_link)) {
ffffffffc0200d1c:	fe878713          	addi	a4,a5,-24
ffffffffc0200d20:	00e56563          	bltu	a0,a4,ffffffffc0200d2a <slub_page_free.part.0+0x56>
    return listelm->next;
ffffffffc0200d24:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc0200d26:	fed79be3          	bne	a5,a3,ffffffffc0200d1c <slub_page_free.part.0+0x48>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200d2a:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200d2c:	e390                	sd	a2,0(a5)
ffffffffc0200d2e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200d30:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200d32:	ed18                	sd	a4,24(a0)
    page_try_merge(base);
ffffffffc0200d34:	bc8d                	j	ffffffffc02007a6 <page_try_merge>
static void slub_page_free(struct Page *base, size_t n) {
ffffffffc0200d36:	1141                	addi	sp,sp,-16
        SLUB_ASSERT(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d38:	0ed00613          	li	a2,237
ffffffffc0200d3c:	00001597          	auipc	a1,0x1
ffffffffc0200d40:	67458593          	addi	a1,a1,1652 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200d44:	00001697          	auipc	a3,0x1
ffffffffc0200d48:	70c68693          	addi	a3,a3,1804 # ffffffffc0202450 <etext+0x462>
ffffffffc0200d4c:	00001517          	auipc	a0,0x1
ffffffffc0200d50:	67c50513          	addi	a0,a0,1660 # ffffffffc02023c8 <etext+0x3da>
static void slub_page_free(struct Page *base, size_t n) {
ffffffffc0200d54:	e406                	sd	ra,8(sp)
        SLUB_ASSERT(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d56:	bf6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200d5a:	00001617          	auipc	a2,0x1
ffffffffc0200d5e:	69660613          	addi	a2,a2,1686 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200d62:	0ed00593          	li	a1,237
ffffffffc0200d66:	00001517          	auipc	a0,0x1
ffffffffc0200d6a:	64a50513          	addi	a0,a0,1610 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200d6e:	c54ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d72 <slub_free_pages_iface>:
    SLUB_ASSERT(n > 0);
ffffffffc0200d72:	c191                	beqz	a1,ffffffffc0200d76 <slub_free_pages_iface+0x4>
ffffffffc0200d74:	b785                	j	ffffffffc0200cd4 <slub_page_free.part.0>
static void slub_free_pages_iface(struct Page *base, size_t n) {
ffffffffc0200d76:	1141                	addi	sp,sp,-16
    SLUB_ASSERT(n > 0);
ffffffffc0200d78:	0ea00613          	li	a2,234
ffffffffc0200d7c:	00001597          	auipc	a1,0x1
ffffffffc0200d80:	63458593          	addi	a1,a1,1588 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200d84:	00001697          	auipc	a3,0x1
ffffffffc0200d88:	6f468693          	addi	a3,a3,1780 # ffffffffc0202478 <etext+0x48a>
ffffffffc0200d8c:	00001517          	auipc	a0,0x1
ffffffffc0200d90:	63c50513          	addi	a0,a0,1596 # ffffffffc02023c8 <etext+0x3da>
static void slub_free_pages_iface(struct Page *base, size_t n) {
ffffffffc0200d94:	e406                	sd	ra,8(sp)
    SLUB_ASSERT(n > 0);
ffffffffc0200d96:	bb6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200d9a:	00001617          	auipc	a2,0x1
ffffffffc0200d9e:	65660613          	addi	a2,a2,1622 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200da2:	0ea00593          	li	a1,234
ffffffffc0200da6:	00001517          	auipc	a0,0x1
ffffffffc0200daa:	60a50513          	addi	a0,a0,1546 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200dae:	c14ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200db2 <slub_release_slab>:
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
ffffffffc0200db2:	4118                	lw	a4,0(a0)
static void slub_release_slab(struct slub_slab *slab) {
ffffffffc0200db4:	1141                	addi	sp,sp,-16
ffffffffc0200db6:	e406                	sd	ra,8(sp)
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
ffffffffc0200db8:	57fd                	li	a5,-1
ffffffffc0200dba:	02f71463          	bne	a4,a5,ffffffffc0200de2 <slub_release_slab+0x30>
    SLUB_ASSERT(slab->free_count == slab->capacity);
ffffffffc0200dbe:	01855683          	lhu	a3,24(a0)
ffffffffc0200dc2:	01a55783          	lhu	a5,26(a0)
    slab->magic = 0;
ffffffffc0200dc6:	00052023          	sw	zero,0(a0)
    struct slub_cache *cache = slab->cache;
ffffffffc0200dca:	6518                	ld	a4,8(a0)
    SLUB_ASSERT(slab->free_count == slab->capacity);
ffffffffc0200dcc:	08f69363          	bne	a3,a5,ffffffffc0200e52 <slub_release_slab+0xa0>
    SLUB_ASSERT(cache->slabs_total > 0);
ffffffffc0200dd0:	771c                	ld	a5,40(a4)
ffffffffc0200dd2:	c7a1                	beqz	a5,ffffffffc0200e1a <slub_release_slab+0x68>
    cache->slabs_total--;
ffffffffc0200dd4:	6908                	ld	a0,16(a0)
}
ffffffffc0200dd6:	60a2                	ld	ra,8(sp)
    cache->slabs_total--;
ffffffffc0200dd8:	17fd                	addi	a5,a5,-1
ffffffffc0200dda:	f71c                	sd	a5,40(a4)
}
ffffffffc0200ddc:	4585                	li	a1,1
ffffffffc0200dde:	0141                	addi	sp,sp,16
ffffffffc0200de0:	bdd5                	j	ffffffffc0200cd4 <slub_page_free.part.0>
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
ffffffffc0200de2:	17600613          	li	a2,374
ffffffffc0200de6:	00001597          	auipc	a1,0x1
ffffffffc0200dea:	5ca58593          	addi	a1,a1,1482 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200dee:	00001697          	auipc	a3,0x1
ffffffffc0200df2:	69268693          	addi	a3,a3,1682 # ffffffffc0202480 <etext+0x492>
ffffffffc0200df6:	00001517          	auipc	a0,0x1
ffffffffc0200dfa:	5d250513          	addi	a0,a0,1490 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200dfe:	b4eff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e02:	00001617          	auipc	a2,0x1
ffffffffc0200e06:	5ee60613          	addi	a2,a2,1518 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200e0a:	17600593          	li	a1,374
ffffffffc0200e0e:	00001517          	auipc	a0,0x1
ffffffffc0200e12:	5a250513          	addi	a0,a0,1442 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200e16:	bacff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(cache->slabs_total > 0);
ffffffffc0200e1a:	17a00613          	li	a2,378
ffffffffc0200e1e:	00001597          	auipc	a1,0x1
ffffffffc0200e22:	59258593          	addi	a1,a1,1426 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200e26:	00001697          	auipc	a3,0x1
ffffffffc0200e2a:	6a268693          	addi	a3,a3,1698 # ffffffffc02024c8 <etext+0x4da>
ffffffffc0200e2e:	00001517          	auipc	a0,0x1
ffffffffc0200e32:	59a50513          	addi	a0,a0,1434 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200e36:	b16ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e3a:	00001617          	auipc	a2,0x1
ffffffffc0200e3e:	5b660613          	addi	a2,a2,1462 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200e42:	17a00593          	li	a1,378
ffffffffc0200e46:	00001517          	auipc	a0,0x1
ffffffffc0200e4a:	56a50513          	addi	a0,a0,1386 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200e4e:	b74ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(slab->free_count == slab->capacity);
ffffffffc0200e52:	17900613          	li	a2,377
ffffffffc0200e56:	00001597          	auipc	a1,0x1
ffffffffc0200e5a:	55a58593          	addi	a1,a1,1370 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200e5e:	00001697          	auipc	a3,0x1
ffffffffc0200e62:	64268693          	addi	a3,a3,1602 # ffffffffc02024a0 <etext+0x4b2>
ffffffffc0200e66:	00001517          	auipc	a0,0x1
ffffffffc0200e6a:	56250513          	addi	a0,a0,1378 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200e6e:	adeff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e72:	00001617          	auipc	a2,0x1
ffffffffc0200e76:	57e60613          	addi	a2,a2,1406 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200e7a:	17900593          	li	a1,377
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	53250513          	addi	a0,a0,1330 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200e86:	b3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200e8a <slub_cache_cleanup>:
static void slub_cache_cleanup(struct slub_cache *cache) {
ffffffffc0200e8a:	1101                	addi	sp,sp,-32
ffffffffc0200e8c:	ec06                	sd	ra,24(sp)
ffffffffc0200e8e:	e822                	sd	s0,16(sp)
ffffffffc0200e90:	e426                	sd	s1,8(sp)
    SLUB_ASSERT(cache != NULL);
ffffffffc0200e92:	14050363          	beqz	a0,ffffffffc0200fd8 <slub_cache_cleanup+0x14e>
    SLUB_ASSERT(cache->inuse_objs == 0);
ffffffffc0200e96:	7d1c                	ld	a5,56(a0)
ffffffffc0200e98:	842a                	mv	s0,a0
ffffffffc0200e9a:	10079363          	bnez	a5,ffffffffc0200fa0 <slub_cache_cleanup+0x116>
    return list->next == list;
ffffffffc0200e9e:	7128                	ld	a0,96(a0)
    while (!list_empty(&cache->partial)) {
ffffffffc0200ea0:	05840493          	addi	s1,s0,88
ffffffffc0200ea4:	02950663          	beq	a0,s1,ffffffffc0200ed0 <slub_cache_cleanup+0x46>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ea8:	6118                	ld	a4,0(a0)
ffffffffc0200eaa:	651c                	ld	a5,8(a0)
        SLUB_ASSERT(slab->free_count == slab->capacity);
ffffffffc0200eac:	ff855603          	lhu	a2,-8(a0)
ffffffffc0200eb0:	ffa55683          	lhu	a3,-6(a0)
    prev->next = next;
ffffffffc0200eb4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200eb6:	e398                	sd	a4,0(a5)
    return to_struct(le, struct slub_slab, link);
ffffffffc0200eb8:	1501                	addi	a0,a0,-32
        SLUB_ASSERT(slab->free_count == slab->capacity);
ffffffffc0200eba:	02d61f63          	bne	a2,a3,ffffffffc0200ef8 <slub_cache_cleanup+0x6e>
        SLUB_ASSERT(cache->slabs_partial > 0);
ffffffffc0200ebe:	781c                	ld	a5,48(s0)
ffffffffc0200ec0:	cba5                	beqz	a5,ffffffffc0200f30 <slub_cache_cleanup+0xa6>
        cache->slabs_partial--;
ffffffffc0200ec2:	17fd                	addi	a5,a5,-1
ffffffffc0200ec4:	f81c                	sd	a5,48(s0)
        slub_release_slab(slab);
ffffffffc0200ec6:	eedff0ef          	jal	ra,ffffffffc0200db2 <slub_release_slab>
    return list->next == list;
ffffffffc0200eca:	7028                	ld	a0,96(s0)
    while (!list_empty(&cache->partial)) {
ffffffffc0200ecc:	fc951ee3          	bne	a0,s1,ffffffffc0200ea8 <slub_cache_cleanup+0x1e>
    SLUB_ASSERT(list_empty(&cache->full));
ffffffffc0200ed0:	7838                	ld	a4,112(s0)
ffffffffc0200ed2:	06840793          	addi	a5,s0,104
ffffffffc0200ed6:	08f71963          	bne	a4,a5,ffffffffc0200f68 <slub_cache_cleanup+0xde>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200eda:	6434                	ld	a3,72(s0)
ffffffffc0200edc:	6838                	ld	a4,80(s0)
    list_del_init(&cache->node);
ffffffffc0200ede:	04840793          	addi	a5,s0,72
}
ffffffffc0200ee2:	60e2                	ld	ra,24(sp)
    prev->next = next;
ffffffffc0200ee4:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200ee6:	e314                	sd	a3,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0200ee8:	e83c                	sd	a5,80(s0)
ffffffffc0200eea:	e43c                	sd	a5,72(s0)
    cache->active = 0;
ffffffffc0200eec:	04042223          	sw	zero,68(s0)
}
ffffffffc0200ef0:	6442                	ld	s0,16(sp)
ffffffffc0200ef2:	64a2                	ld	s1,8(sp)
ffffffffc0200ef4:	6105                	addi	sp,sp,32
ffffffffc0200ef6:	8082                	ret
        SLUB_ASSERT(slab->free_count == slab->capacity);
ffffffffc0200ef8:	1d000613          	li	a2,464
ffffffffc0200efc:	00001597          	auipc	a1,0x1
ffffffffc0200f00:	4b458593          	addi	a1,a1,1204 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200f04:	00001697          	auipc	a3,0x1
ffffffffc0200f08:	59c68693          	addi	a3,a3,1436 # ffffffffc02024a0 <etext+0x4b2>
ffffffffc0200f0c:	00001517          	auipc	a0,0x1
ffffffffc0200f10:	4bc50513          	addi	a0,a0,1212 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200f14:	a38ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200f18:	00001617          	auipc	a2,0x1
ffffffffc0200f1c:	4d860613          	addi	a2,a2,1240 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200f20:	1d000593          	li	a1,464
ffffffffc0200f24:	00001517          	auipc	a0,0x1
ffffffffc0200f28:	48c50513          	addi	a0,a0,1164 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200f2c:	a96ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        SLUB_ASSERT(cache->slabs_partial > 0);
ffffffffc0200f30:	1d100613          	li	a2,465
ffffffffc0200f34:	00001597          	auipc	a1,0x1
ffffffffc0200f38:	47c58593          	addi	a1,a1,1148 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200f3c:	00001697          	auipc	a3,0x1
ffffffffc0200f40:	4f468693          	addi	a3,a3,1268 # ffffffffc0202430 <etext+0x442>
ffffffffc0200f44:	00001517          	auipc	a0,0x1
ffffffffc0200f48:	48450513          	addi	a0,a0,1156 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200f4c:	a00ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200f50:	00001617          	auipc	a2,0x1
ffffffffc0200f54:	4a060613          	addi	a2,a2,1184 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200f58:	1d100593          	li	a1,465
ffffffffc0200f5c:	00001517          	auipc	a0,0x1
ffffffffc0200f60:	45450513          	addi	a0,a0,1108 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200f64:	a5eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(list_empty(&cache->full));
ffffffffc0200f68:	1d500613          	li	a2,469
ffffffffc0200f6c:	00001597          	auipc	a1,0x1
ffffffffc0200f70:	44458593          	addi	a1,a1,1092 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200f74:	00001697          	auipc	a3,0x1
ffffffffc0200f78:	59468693          	addi	a3,a3,1428 # ffffffffc0202508 <etext+0x51a>
ffffffffc0200f7c:	00001517          	auipc	a0,0x1
ffffffffc0200f80:	44c50513          	addi	a0,a0,1100 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200f84:	9c8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200f88:	00001617          	auipc	a2,0x1
ffffffffc0200f8c:	46860613          	addi	a2,a2,1128 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200f90:	1d500593          	li	a1,469
ffffffffc0200f94:	00001517          	auipc	a0,0x1
ffffffffc0200f98:	41c50513          	addi	a0,a0,1052 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200f9c:	a26ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(cache->inuse_objs == 0);
ffffffffc0200fa0:	1cb00613          	li	a2,459
ffffffffc0200fa4:	00001597          	auipc	a1,0x1
ffffffffc0200fa8:	40c58593          	addi	a1,a1,1036 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200fac:	00001697          	auipc	a3,0x1
ffffffffc0200fb0:	54468693          	addi	a3,a3,1348 # ffffffffc02024f0 <etext+0x502>
ffffffffc0200fb4:	00001517          	auipc	a0,0x1
ffffffffc0200fb8:	41450513          	addi	a0,a0,1044 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200fbc:	990ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200fc0:	00001617          	auipc	a2,0x1
ffffffffc0200fc4:	43060613          	addi	a2,a2,1072 # ffffffffc02023f0 <etext+0x402>
ffffffffc0200fc8:	1cb00593          	li	a1,459
ffffffffc0200fcc:	00001517          	auipc	a0,0x1
ffffffffc0200fd0:	3e450513          	addi	a0,a0,996 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200fd4:	9eeff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(cache != NULL);
ffffffffc0200fd8:	1ca00613          	li	a2,458
ffffffffc0200fdc:	00001597          	auipc	a1,0x1
ffffffffc0200fe0:	3d458593          	addi	a1,a1,980 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0200fe4:	00001697          	auipc	a3,0x1
ffffffffc0200fe8:	4fc68693          	addi	a3,a3,1276 # ffffffffc02024e0 <etext+0x4f2>
ffffffffc0200fec:	00001517          	auipc	a0,0x1
ffffffffc0200ff0:	3dc50513          	addi	a0,a0,988 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0200ff4:	958ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200ff8:	00001617          	auipc	a2,0x1
ffffffffc0200ffc:	3f860613          	addi	a2,a2,1016 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201000:	1ca00593          	li	a1,458
ffffffffc0201004:	00001517          	auipc	a0,0x1
ffffffffc0201008:	3ac50513          	addi	a0,a0,940 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc020100c:	9b6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201010 <slub_cache_do_free>:
    SLUB_ASSERT(offset % slab->obj_stride == 0);
ffffffffc0201010:	01e5d703          	lhu	a4,30(a1)
    return (uint8_t *)(slab + 1);
ffffffffc0201014:	03058793          	addi	a5,a1,48
    uintptr_t offset = (uint8_t *)obj - base;
ffffffffc0201018:	40f607b3          	sub	a5,a2,a5
    SLUB_ASSERT(offset % slab->obj_stride == 0);
ffffffffc020101c:	02e7f6b3          	remu	a3,a5,a4
                               void *obj) {
ffffffffc0201020:	1141                	addi	sp,sp,-16
ffffffffc0201022:	e406                	sd	ra,8(sp)
    SLUB_ASSERT(offset % slab->obj_stride == 0);
ffffffffc0201024:	eedd                	bnez	a3,ffffffffc02010e2 <slub_cache_do_free+0xd2>
    uint16_t idx = offset / slab->obj_stride;
ffffffffc0201026:	02e7d733          	divu	a4,a5,a4
    *((uint16_t *)obj) = slab->free_head;
ffffffffc020102a:	01c5d783          	lhu	a5,28(a1)
    SLUB_ASSERT(cache->inuse_objs > 0);
ffffffffc020102e:	7d14                	ld	a3,56(a0)
    *((uint16_t *)obj) = slab->free_head;
ffffffffc0201030:	00f61023          	sh	a5,0(a2)
    slab->free_count++;
ffffffffc0201034:	0185d783          	lhu	a5,24(a1)
ffffffffc0201038:	2785                	addiw	a5,a5,1
ffffffffc020103a:	17c2                	slli	a5,a5,0x30
ffffffffc020103c:	93c1                	srli	a5,a5,0x30
ffffffffc020103e:	00f59c23          	sh	a5,24(a1)
    uint16_t idx = offset / slab->obj_stride;
ffffffffc0201042:	00e59e23          	sh	a4,28(a1)
    SLUB_ASSERT(cache->inuse_objs > 0);
ffffffffc0201046:	c2b5                	beqz	a3,ffffffffc02010aa <slub_cache_do_free+0x9a>
    cache->inuse_objs--;
ffffffffc0201048:	16fd                	addi	a3,a3,-1
ffffffffc020104a:	fd14                	sd	a3,56(a0)
    if (slab->free_count == 1) {
ffffffffc020104c:	4685                	li	a3,1
ffffffffc020104e:	0007871b          	sext.w	a4,a5
ffffffffc0201052:	02d79963          	bne	a5,a3,ffffffffc0201084 <slub_cache_do_free+0x74>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201056:	7590                	ld	a2,40(a1)
ffffffffc0201058:	0205b883          	ld	a7,32(a1)
        cache->slabs_partial++;
ffffffffc020105c:	7914                	ld	a3,48(a0)
        list_add(&cache->partial, &slab->link);
ffffffffc020105e:	02058793          	addi	a5,a1,32
    prev->next = next;
ffffffffc0201062:	00c8b423          	sd	a2,8(a7)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201066:	06053803          	ld	a6,96(a0)
    next->prev = prev;
ffffffffc020106a:	01163023          	sd	a7,0(a2)
ffffffffc020106e:	05850613          	addi	a2,a0,88
    prev->next = next->prev = elm;
ffffffffc0201072:	00f83023          	sd	a5,0(a6)
ffffffffc0201076:	f13c                	sd	a5,96(a0)
    elm->next = next;
ffffffffc0201078:	0305b423          	sd	a6,40(a1)
    elm->prev = prev;
ffffffffc020107c:	f190                	sd	a2,32(a1)
        cache->slabs_partial++;
ffffffffc020107e:	00168793          	addi	a5,a3,1
ffffffffc0201082:	f91c                	sd	a5,48(a0)
    if (slab->free_count == slab->capacity) {
ffffffffc0201084:	01a5d783          	lhu	a5,26(a1)
ffffffffc0201088:	00e78563          	beq	a5,a4,ffffffffc0201092 <slub_cache_do_free+0x82>
}
ffffffffc020108c:	60a2                	ld	ra,8(sp)
ffffffffc020108e:	0141                	addi	sp,sp,16
ffffffffc0201090:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201092:	7194                	ld	a3,32(a1)
ffffffffc0201094:	7598                	ld	a4,40(a1)
        SLUB_ASSERT(cache->slabs_partial > 0);
ffffffffc0201096:	791c                	ld	a5,48(a0)
    prev->next = next;
ffffffffc0201098:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020109a:	e314                	sd	a3,0(a4)
ffffffffc020109c:	cfbd                	beqz	a5,ffffffffc020111a <slub_cache_do_free+0x10a>
}
ffffffffc020109e:	60a2                	ld	ra,8(sp)
        cache->slabs_partial--;
ffffffffc02010a0:	17fd                	addi	a5,a5,-1
ffffffffc02010a2:	f91c                	sd	a5,48(a0)
        slub_release_slab(slab);
ffffffffc02010a4:	852e                	mv	a0,a1
}
ffffffffc02010a6:	0141                	addi	sp,sp,16
        slub_release_slab(slab);
ffffffffc02010a8:	b329                	j	ffffffffc0200db2 <slub_release_slab>
    SLUB_ASSERT(cache->inuse_objs > 0);
ffffffffc02010aa:	1ab00613          	li	a2,427
ffffffffc02010ae:	00001597          	auipc	a1,0x1
ffffffffc02010b2:	30258593          	addi	a1,a1,770 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02010b6:	00001697          	auipc	a3,0x1
ffffffffc02010ba:	49268693          	addi	a3,a3,1170 # ffffffffc0202548 <etext+0x55a>
ffffffffc02010be:	00001517          	auipc	a0,0x1
ffffffffc02010c2:	30a50513          	addi	a0,a0,778 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02010c6:	886ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02010ca:	00001617          	auipc	a2,0x1
ffffffffc02010ce:	32660613          	addi	a2,a2,806 # ffffffffc02023f0 <etext+0x402>
ffffffffc02010d2:	1ab00593          	li	a1,427
ffffffffc02010d6:	00001517          	auipc	a0,0x1
ffffffffc02010da:	2da50513          	addi	a0,a0,730 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02010de:	8e4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(offset % slab->obj_stride == 0);
ffffffffc02010e2:	1a600613          	li	a2,422
ffffffffc02010e6:	00001597          	auipc	a1,0x1
ffffffffc02010ea:	2ca58593          	addi	a1,a1,714 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02010ee:	00001697          	auipc	a3,0x1
ffffffffc02010f2:	43a68693          	addi	a3,a3,1082 # ffffffffc0202528 <etext+0x53a>
ffffffffc02010f6:	00001517          	auipc	a0,0x1
ffffffffc02010fa:	2d250513          	addi	a0,a0,722 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02010fe:	84eff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201102:	00001617          	auipc	a2,0x1
ffffffffc0201106:	2ee60613          	addi	a2,a2,750 # ffffffffc02023f0 <etext+0x402>
ffffffffc020110a:	1a600593          	li	a1,422
ffffffffc020110e:	00001517          	auipc	a0,0x1
ffffffffc0201112:	2a250513          	addi	a0,a0,674 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201116:	8acff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        SLUB_ASSERT(cache->slabs_partial > 0);
ffffffffc020111a:	1b400613          	li	a2,436
ffffffffc020111e:	00001597          	auipc	a1,0x1
ffffffffc0201122:	29258593          	addi	a1,a1,658 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201126:	00001697          	auipc	a3,0x1
ffffffffc020112a:	30a68693          	addi	a3,a3,778 # ffffffffc0202430 <etext+0x442>
ffffffffc020112e:	00001517          	auipc	a0,0x1
ffffffffc0201132:	29a50513          	addi	a0,a0,666 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201136:	816ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020113a:	00001617          	auipc	a2,0x1
ffffffffc020113e:	2b660613          	addi	a2,a2,694 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201142:	1b400593          	li	a1,436
ffffffffc0201146:	00001517          	auipc	a0,0x1
ffffffffc020114a:	26a50513          	addi	a0,a0,618 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc020114e:	874ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201152 <slub_cache_free.part.0>:
void slub_cache_free(struct slub_cache *cache, void *obj) {
ffffffffc0201152:	1141                	addi	sp,sp,-16
ffffffffc0201154:	862e                	mv	a2,a1
ffffffffc0201156:	e406                	sd	ra,8(sp)
    SLUB_ASSERT(kva_val >= va_pa_offset);
ffffffffc0201158:	00006597          	auipc	a1,0x6
ffffffffc020115c:	9685b583          	ld	a1,-1688(a1) # ffffffffc0206ac0 <va_pa_offset>
ffffffffc0201160:	04b66963          	bltu	a2,a1,ffffffffc02011b2 <slub_cache_free.part.0+0x60>
    uintptr_t pa = kva_val - va_pa_offset;
ffffffffc0201164:	40b607b3          	sub	a5,a2,a1
    if (PPN(pa) >= npage) {
ffffffffc0201168:	83b1                	srli	a5,a5,0xc
ffffffffc020116a:	00006717          	auipc	a4,0x6
ffffffffc020116e:	92e73703          	ld	a4,-1746(a4) # ffffffffc0206a98 <npage>
ffffffffc0201172:	0ae7fa63          	bgeu	a5,a4,ffffffffc0201226 <slub_cache_free.part.0+0xd4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201176:	00002817          	auipc	a6,0x2
ffffffffc020117a:	a0283803          	ld	a6,-1534(a6) # ffffffffc0202b78 <nbase>
ffffffffc020117e:	41078733          	sub	a4,a5,a6
ffffffffc0201182:	00271793          	slli	a5,a4,0x2
ffffffffc0201186:	97ba                	add	a5,a5,a4
ffffffffc0201188:	078e                	slli	a5,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020118a:	00002717          	auipc	a4,0x2
ffffffffc020118e:	9f673703          	ld	a4,-1546(a4) # ffffffffc0202b80 <nbase+0x8>
ffffffffc0201192:	878d                	srai	a5,a5,0x3
ffffffffc0201194:	02e787b3          	mul	a5,a5,a4
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
ffffffffc0201198:	577d                	li	a4,-1
ffffffffc020119a:	97c2                	add	a5,a5,a6
    return page2ppn(page) << PGSHIFT;
ffffffffc020119c:	07b2                	slli	a5,a5,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc020119e:	95be                	add	a1,a1,a5
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
ffffffffc02011a0:	419c                	lw	a5,0(a1)
ffffffffc02011a2:	04e79663          	bne	a5,a4,ffffffffc02011ee <slub_cache_free.part.0+0x9c>
    SLUB_ASSERT(slab->cache == cache);
ffffffffc02011a6:	659c                	ld	a5,8(a1)
ffffffffc02011a8:	00a79763          	bne	a5,a0,ffffffffc02011b6 <slub_cache_free.part.0+0x64>
}
ffffffffc02011ac:	60a2                	ld	ra,8(sp)
ffffffffc02011ae:	0141                	addi	sp,sp,16
    slub_cache_do_free(cache, slab, obj);
ffffffffc02011b0:	b585                	j	ffffffffc0201010 <slub_cache_do_free>
ffffffffc02011b2:	8f5ff0ef          	jal	ra,ffffffffc0200aa6 <kva2page_local.part.0>
    SLUB_ASSERT(slab->cache == cache);
ffffffffc02011b6:	1fd00613          	li	a2,509
ffffffffc02011ba:	00001597          	auipc	a1,0x1
ffffffffc02011be:	1f658593          	addi	a1,a1,502 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02011c2:	00001697          	auipc	a3,0x1
ffffffffc02011c6:	39e68693          	addi	a3,a3,926 # ffffffffc0202560 <etext+0x572>
ffffffffc02011ca:	00001517          	auipc	a0,0x1
ffffffffc02011ce:	1fe50513          	addi	a0,a0,510 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02011d2:	f7bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02011d6:	00001617          	auipc	a2,0x1
ffffffffc02011da:	21a60613          	addi	a2,a2,538 # ffffffffc02023f0 <etext+0x402>
ffffffffc02011de:	1fd00593          	li	a1,509
ffffffffc02011e2:	00001517          	auipc	a0,0x1
ffffffffc02011e6:	1ce50513          	addi	a0,a0,462 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02011ea:	fd9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(slab->magic == SLUB_SLAB_MAGIC);
ffffffffc02011ee:	1fc00613          	li	a2,508
ffffffffc02011f2:	00001597          	auipc	a1,0x1
ffffffffc02011f6:	1be58593          	addi	a1,a1,446 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02011fa:	00001697          	auipc	a3,0x1
ffffffffc02011fe:	28668693          	addi	a3,a3,646 # ffffffffc0202480 <etext+0x492>
ffffffffc0201202:	00001517          	auipc	a0,0x1
ffffffffc0201206:	1c650513          	addi	a0,a0,454 # ffffffffc02023c8 <etext+0x3da>
ffffffffc020120a:	f43fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020120e:	00001617          	auipc	a2,0x1
ffffffffc0201212:	1e260613          	addi	a2,a2,482 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201216:	1fc00593          	li	a1,508
ffffffffc020121a:	00001517          	auipc	a0,0x1
ffffffffc020121e:	19650513          	addi	a0,a0,406 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201222:	fa1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201226:	00001617          	auipc	a2,0x1
ffffffffc020122a:	0e260613          	addi	a2,a2,226 # ffffffffc0202308 <etext+0x31a>
ffffffffc020122e:	06a00593          	li	a1,106
ffffffffc0201232:	00001517          	auipc	a0,0x1
ffffffffc0201236:	0f650513          	addi	a0,a0,246 # ffffffffc0202328 <etext+0x33a>
ffffffffc020123a:	f89fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020123e <slub_alloc_pages_iface>:
    SLUB_ASSERT(n > 0);
ffffffffc020123e:	c919                	beqz	a0,ffffffffc0201254 <slub_alloc_pages_iface+0x16>
    if (n > page_nr_free) {
ffffffffc0201240:	00005717          	auipc	a4,0x5
ffffffffc0201244:	de876703          	lwu	a4,-536(a4) # ffffffffc0206028 <page_area+0x10>
ffffffffc0201248:	00a76463          	bltu	a4,a0,ffffffffc0201250 <slub_alloc_pages_iface+0x12>
ffffffffc020124c:	f5eff06f          	j	ffffffffc02009aa <slub_page_alloc.part.0>
}
ffffffffc0201250:	4501                	li	a0,0
ffffffffc0201252:	8082                	ret
static struct Page *slub_alloc_pages_iface(size_t n) {
ffffffffc0201254:	1141                	addi	sp,sp,-16
    SLUB_ASSERT(n > 0);
ffffffffc0201256:	0c200613          	li	a2,194
ffffffffc020125a:	00001597          	auipc	a1,0x1
ffffffffc020125e:	15658593          	addi	a1,a1,342 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201262:	00001697          	auipc	a3,0x1
ffffffffc0201266:	21668693          	addi	a3,a3,534 # ffffffffc0202478 <etext+0x48a>
ffffffffc020126a:	00001517          	auipc	a0,0x1
ffffffffc020126e:	15e50513          	addi	a0,a0,350 # ffffffffc02023c8 <etext+0x3da>
static struct Page *slub_alloc_pages_iface(size_t n) {
ffffffffc0201272:	e406                	sd	ra,8(sp)
    SLUB_ASSERT(n > 0);
ffffffffc0201274:	ed9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201278:	00001617          	auipc	a2,0x1
ffffffffc020127c:	17860613          	addi	a2,a2,376 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201280:	0c200593          	li	a1,194
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	12c50513          	addi	a0,a0,300 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc020128c:	f37fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201290 <slub_init_memmap>:
static void slub_init_memmap(struct Page *base, size_t n) {
ffffffffc0201290:	1141                	addi	sp,sp,-16
ffffffffc0201292:	e406                	sd	ra,8(sp)
ffffffffc0201294:	87aa                	mv	a5,a0
ffffffffc0201296:	4681                	li	a3,0
    SLUB_ASSERT(n > 0);
ffffffffc0201298:	cdd1                	beqz	a1,ffffffffc0201334 <slub_init_memmap+0xa4>
        SLUB_ASSERT(PageReserved(p));
ffffffffc020129a:	6798                	ld	a4,8(a5)
ffffffffc020129c:	8b05                	andi	a4,a4,1
ffffffffc020129e:	cf39                	beqz	a4,ffffffffc02012fc <slub_init_memmap+0x6c>
        p->flags = 0;
ffffffffc02012a0:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc02012a4:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02012a8:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc02012ac:	0685                	addi	a3,a3,1
ffffffffc02012ae:	02878793          	addi	a5,a5,40
ffffffffc02012b2:	fed594e3          	bne	a1,a3,ffffffffc020129a <slub_init_memmap+0xa>
    SetPageProperty(base);
ffffffffc02012b6:	6518                	ld	a4,8(a0)
    page_nr_free += n;
ffffffffc02012b8:	00005697          	auipc	a3,0x5
ffffffffc02012bc:	d6068693          	addi	a3,a3,-672 # ffffffffc0206018 <page_area>
ffffffffc02012c0:	4a9c                	lw	a5,16(a3)
    base->property = n;
ffffffffc02012c2:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc02012c4:	00276713          	ori	a4,a4,2
    list_init(&(base->page_link));
ffffffffc02012c8:	01850613          	addi	a2,a0,24
    base->property = n;
ffffffffc02012cc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02012ce:	e518                	sd	a4,8(a0)
    page_nr_free += n;
ffffffffc02012d0:	9dbd                	addw	a1,a1,a5
ffffffffc02012d2:	ca8c                	sw	a1,16(a3)
    elm->prev = elm->next = elm;
ffffffffc02012d4:	f110                	sd	a2,32(a0)
ffffffffc02012d6:	ed10                	sd	a2,24(a0)
    list_entry_t *le = &page_free_list;
ffffffffc02012d8:	87b6                	mv	a5,a3
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc02012da:	a029                	j	ffffffffc02012e4 <slub_init_memmap+0x54>
        if (base < le2page(le, page_link)) {
ffffffffc02012dc:	fe878713          	addi	a4,a5,-24
ffffffffc02012e0:	00e56563          	bltu	a0,a4,ffffffffc02012ea <slub_init_memmap+0x5a>
    return listelm->next;
ffffffffc02012e4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &page_free_list) {
ffffffffc02012e6:	fed79be3          	bne	a5,a3,ffffffffc02012dc <slub_init_memmap+0x4c>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02012ea:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02012ec:	e390                	sd	a2,0(a5)
}
ffffffffc02012ee:	60a2                	ld	ra,8(sp)
ffffffffc02012f0:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02012f2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02012f4:	ed18                	sd	a4,24(a0)
ffffffffc02012f6:	0141                	addi	sp,sp,16
    page_try_merge(base);
ffffffffc02012f8:	caeff06f          	j	ffffffffc02007a6 <page_try_merge>
        SLUB_ASSERT(PageReserved(p));
ffffffffc02012fc:	0b000613          	li	a2,176
ffffffffc0201300:	00001597          	auipc	a1,0x1
ffffffffc0201304:	0b058593          	addi	a1,a1,176 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201308:	00001697          	auipc	a3,0x1
ffffffffc020130c:	27068693          	addi	a3,a3,624 # ffffffffc0202578 <etext+0x58a>
ffffffffc0201310:	00001517          	auipc	a0,0x1
ffffffffc0201314:	0b850513          	addi	a0,a0,184 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201318:	e35fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020131c:	00001617          	auipc	a2,0x1
ffffffffc0201320:	0d460613          	addi	a2,a2,212 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201324:	0b000593          	li	a1,176
ffffffffc0201328:	00001517          	auipc	a0,0x1
ffffffffc020132c:	08850513          	addi	a0,a0,136 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201330:	e93fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(n > 0);
ffffffffc0201334:	0ad00613          	li	a2,173
ffffffffc0201338:	00001597          	auipc	a1,0x1
ffffffffc020133c:	07858593          	addi	a1,a1,120 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201340:	00001697          	auipc	a3,0x1
ffffffffc0201344:	13868693          	addi	a3,a3,312 # ffffffffc0202478 <etext+0x48a>
ffffffffc0201348:	00001517          	auipc	a0,0x1
ffffffffc020134c:	08050513          	addi	a0,a0,128 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201350:	dfdfe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201354:	00001617          	auipc	a2,0x1
ffffffffc0201358:	09c60613          	addi	a2,a2,156 # ffffffffc02023f0 <etext+0x402>
ffffffffc020135c:	0ad00593          	li	a1,173
ffffffffc0201360:	00001517          	auipc	a0,0x1
ffffffffc0201364:	05050513          	addi	a0,a0,80 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201368:	e5bfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020136c <slub_cache_basic_check>:
static void slub_cache_basic_check(void) {
ffffffffc020136c:	7119                	addi	sp,sp,-128
ffffffffc020136e:	e4d6                	sd	s5,72(sp)
ffffffffc0201370:	f466                	sd	s9,40(sp)
ffffffffc0201372:	fc86                	sd	ra,120(sp)
ffffffffc0201374:	f8a2                	sd	s0,112(sp)
ffffffffc0201376:	f4a6                	sd	s1,104(sp)
ffffffffc0201378:	f0ca                	sd	s2,96(sp)
ffffffffc020137a:	ecce                	sd	s3,88(sp)
ffffffffc020137c:	e8d2                	sd	s4,80(sp)
ffffffffc020137e:	e0da                	sd	s6,64(sp)
ffffffffc0201380:	fc5e                	sd	s7,56(sp)
ffffffffc0201382:	f862                	sd	s8,48(sp)
ffffffffc0201384:	f06a                	sd	s10,32(sp)
ffffffffc0201386:	ec6e                	sd	s11,24(sp)
    SLUB_LOG("cache_basic_check begin\n");
ffffffffc0201388:	00001517          	auipc	a0,0x1
ffffffffc020138c:	20050513          	addi	a0,a0,512 # ffffffffc0202588 <etext+0x59a>
static void slub_cache_basic_check(void) {
ffffffffc0201390:	81010113          	addi	sp,sp,-2032
    SLUB_LOG("cache_basic_check begin\n");
ffffffffc0201394:	db9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (size_t i = 0; i < SLUB_MAX_CUSTOM_CACHES; i++) {
ffffffffc0201398:	00005c97          	auipc	s9,0x5
ffffffffc020139c:	068c8c93          	addi	s9,s9,104 # ffffffffc0206400 <slub_custom_used>
ffffffffc02013a0:	4a81                	li	s5,0
ffffffffc02013a2:	87e6                	mv	a5,s9
ffffffffc02013a4:	46a1                	li	a3,8
        if (!slub_custom_used[i]) {
ffffffffc02013a6:	4398                	lw	a4,0(a5)
ffffffffc02013a8:	c329                	beqz	a4,ffffffffc02013ea <slub_cache_basic_check+0x7e>
    for (size_t i = 0; i < SLUB_MAX_CUSTOM_CACHES; i++) {
ffffffffc02013aa:	0a85                	addi	s5,s5,1
ffffffffc02013ac:	0791                	addi	a5,a5,4
ffffffffc02013ae:	feda9ce3          	bne	s5,a3,ffffffffc02013a6 <slub_cache_basic_check+0x3a>
    SLUB_ASSERT(cache != NULL);
ffffffffc02013b2:	24600613          	li	a2,582
ffffffffc02013b6:	00001597          	auipc	a1,0x1
ffffffffc02013ba:	ffa58593          	addi	a1,a1,-6 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02013be:	00001697          	auipc	a3,0x1
ffffffffc02013c2:	12268693          	addi	a3,a3,290 # ffffffffc02024e0 <etext+0x4f2>
ffffffffc02013c6:	00001517          	auipc	a0,0x1
ffffffffc02013ca:	00250513          	addi	a0,a0,2 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02013ce:	d7ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02013d2:	00001617          	auipc	a2,0x1
ffffffffc02013d6:	01e60613          	addi	a2,a2,30 # ffffffffc02023f0 <etext+0x402>
ffffffffc02013da:	24600593          	li	a1,582
ffffffffc02013de:	00001517          	auipc	a0,0x1
ffffffffc02013e2:	fd250513          	addi	a0,a0,-46 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02013e6:	dddfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            return &slub_custom_caches[i];
ffffffffc02013ea:	004a9b93          	slli	s7,s5,0x4
ffffffffc02013ee:	415b8933          	sub	s2,s7,s5
ffffffffc02013f2:	090e                	slli	s2,s2,0x3
ffffffffc02013f4:	00005c17          	auipc	s8,0x5
ffffffffc02013f8:	c4cc0c13          	addi	s8,s8,-948 # ffffffffc0206040 <slub_custom_caches>
            slub_custom_used[i] = 1;
ffffffffc02013fc:	002a9793          	slli	a5,s5,0x2
            return &slub_custom_caches[i];
ffffffffc0201400:	9962                	add	s2,s2,s8
            slub_custom_used[i] = 1;
ffffffffc0201402:	97e6                	add	a5,a5,s9
ffffffffc0201404:	4805                	li	a6,1
    slub_cache_setup(slot, name, obj_size, align, 0);
ffffffffc0201406:	46a1                	li	a3,8
ffffffffc0201408:	04000613          	li	a2,64
ffffffffc020140c:	00001597          	auipc	a1,0x1
ffffffffc0201410:	19c58593          	addi	a1,a1,412 # ffffffffc02025a8 <etext+0x5ba>
ffffffffc0201414:	854a                	mv	a0,s2
            slub_custom_used[i] = 1;
ffffffffc0201416:	0107a023          	sw	a6,0(a5)
    slub_cache_setup(slot, name, obj_size, align, 0);
ffffffffc020141a:	c1cff0ef          	jal	ra,ffffffffc0200836 <slub_cache_setup>
    size_t per = cache->objs_per_slab;
ffffffffc020141e:	02095b03          	lhu	s6,32(s2)
    SLUB_ASSERT(per > 0);
ffffffffc0201422:	160b0263          	beqz	s6,ffffffffc0201586 <slub_cache_basic_check+0x21a>
    size_t total = per * 2;
ffffffffc0201426:	001b1993          	slli	s3,s6,0x1
    SLUB_ASSERT(total <= ARRAY_SIZE(objs));
ffffffffc020142a:	10000793          	li	a5,256
ffffffffc020142e:	1d37e463          	bltu	a5,s3,ffffffffc02015f6 <slub_cache_basic_check+0x28a>
    if (cache == NULL || !cache->active) {
ffffffffc0201432:	04492783          	lw	a5,68(s2)
ffffffffc0201436:	848a                	mv	s1,sp
    SLUB_ASSERT(total <= ARRAY_SIZE(objs));
ffffffffc0201438:	8d26                	mv	s10,s1
ffffffffc020143a:	4d85                	li	s11,1
        for (size_t j = 0; j < i; j++) {
ffffffffc020143c:	4a05                	li	s4,1
    if (cache == NULL || !cache->active) {
ffffffffc020143e:	cf95                	beqz	a5,ffffffffc020147a <slub_cache_basic_check+0x10e>
    void *ptr = slub_cache_do_alloc(cache);
ffffffffc0201440:	854a                	mv	a0,s2
ffffffffc0201442:	ea0ff0ef          	jal	ra,ffffffffc0200ae2 <slub_cache_do_alloc>
        objs[i] = slub_cache_alloc(cache);
ffffffffc0201446:	00ad3023          	sd	a0,0(s10)
    void *ptr = slub_cache_do_alloc(cache);
ffffffffc020144a:	842a                	mv	s0,a0
        SLUB_ASSERT(objs[i] != NULL);
ffffffffc020144c:	c51d                	beqz	a0,ffffffffc020147a <slub_cache_basic_check+0x10e>
        memset(objs[i], 0xA5, 64);
ffffffffc020144e:	04000613          	li	a2,64
ffffffffc0201452:	0a500593          	li	a1,165
ffffffffc0201456:	387000ef          	jal	ra,ffffffffc0201fdc <memset>
        for (size_t j = 0; j < i; j++) {
ffffffffc020145a:	014d8b63          	beq	s11,s4,ffffffffc0201470 <slub_cache_basic_check+0x104>
ffffffffc020145e:	87a6                	mv	a5,s1
            SLUB_ASSERT(objs[i] != objs[j]);
ffffffffc0201460:	6398                	ld	a4,0(a5)
ffffffffc0201462:	0e870163          	beq	a4,s0,ffffffffc0201544 <slub_cache_basic_check+0x1d8>
        for (size_t j = 0; j < i; j++) {
ffffffffc0201466:	07a1                	addi	a5,a5,8
ffffffffc0201468:	fefd1ce3          	bne	s10,a5,ffffffffc0201460 <slub_cache_basic_check+0xf4>
    for (size_t i = 0; i < total; i++) {
ffffffffc020146c:	053df363          	bgeu	s11,s3,ffffffffc02014b2 <slub_cache_basic_check+0x146>
    if (cache == NULL || !cache->active) {
ffffffffc0201470:	04492783          	lw	a5,68(s2)
ffffffffc0201474:	0d85                	addi	s11,s11,1
ffffffffc0201476:	0d21                	addi	s10,s10,8
ffffffffc0201478:	f7e1                	bnez	a5,ffffffffc0201440 <slub_cache_basic_check+0xd4>
        SLUB_ASSERT(objs[i] != NULL);
ffffffffc020147a:	24e00613          	li	a2,590
ffffffffc020147e:	00001597          	auipc	a1,0x1
ffffffffc0201482:	f3258593          	addi	a1,a1,-206 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201486:	00001697          	auipc	a3,0x1
ffffffffc020148a:	15268693          	addi	a3,a3,338 # ffffffffc02025d8 <etext+0x5ea>
ffffffffc020148e:	00001517          	auipc	a0,0x1
ffffffffc0201492:	f3a50513          	addi	a0,a0,-198 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201496:	cb7fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020149a:	00001617          	auipc	a2,0x1
ffffffffc020149e:	f5660613          	addi	a2,a2,-170 # ffffffffc02023f0 <etext+0x402>
ffffffffc02014a2:	24e00593          	li	a1,590
ffffffffc02014a6:	00001517          	auipc	a0,0x1
ffffffffc02014aa:	f0a50513          	addi	a0,a0,-246 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02014ae:	d15fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc02014b2:	098e                	slli	s3,s3,0x3
ffffffffc02014b4:	99a6                	add	s3,s3,s1
    for (size_t i = 0; i < total; i++) {
ffffffffc02014b6:	8426                	mv	s0,s1
        slub_cache_free(cache, objs[i]);
ffffffffc02014b8:	600c                	ld	a1,0(s0)
    if (cache == NULL || obj == NULL) {
ffffffffc02014ba:	c581                	beqz	a1,ffffffffc02014c2 <slub_cache_basic_check+0x156>
ffffffffc02014bc:	854a                	mv	a0,s2
ffffffffc02014be:	c95ff0ef          	jal	ra,ffffffffc0201152 <slub_cache_free.part.0>
        objs[i] = NULL;
ffffffffc02014c2:	00043023          	sd	zero,0(s0)
    for (size_t i = 0; i < total; i += 2) {
ffffffffc02014c6:	0441                	addi	s0,s0,16
ffffffffc02014c8:	fe8998e3          	bne	s3,s0,ffffffffc02014b8 <slub_cache_basic_check+0x14c>
ffffffffc02014cc:	004b1413          	slli	s0,s6,0x4
ffffffffc02014d0:	9426                	add	s0,s0,s1
        if (objs[i] != NULL) {
ffffffffc02014d2:	608c                	ld	a1,0(s1)
ffffffffc02014d4:	c591                	beqz	a1,ffffffffc02014e0 <slub_cache_basic_check+0x174>
    if (cache == NULL || obj == NULL) {
ffffffffc02014d6:	854a                	mv	a0,s2
ffffffffc02014d8:	c7bff0ef          	jal	ra,ffffffffc0201152 <slub_cache_free.part.0>
            objs[i] = NULL;
ffffffffc02014dc:	0004b023          	sd	zero,0(s1)
    for (size_t i = 0; i < total; i++) {
ffffffffc02014e0:	04a1                	addi	s1,s1,8
ffffffffc02014e2:	fe9418e3          	bne	s0,s1,ffffffffc02014d2 <slub_cache_basic_check+0x166>
    SLUB_ASSERT(cache->slabs_total == 0);
ffffffffc02014e6:	415b87b3          	sub	a5,s7,s5
ffffffffc02014ea:	078e                	slli	a5,a5,0x3
ffffffffc02014ec:	9c3e                	add	s8,s8,a5
ffffffffc02014ee:	028c3403          	ld	s0,40(s8)
ffffffffc02014f2:	e471                	bnez	s0,ffffffffc02015be <slub_cache_basic_check+0x252>
    slub_cache_cleanup(cache);
ffffffffc02014f4:	854a                	mv	a0,s2
ffffffffc02014f6:	995ff0ef          	jal	ra,ffffffffc0200e8a <slub_cache_cleanup>
    if (!cache->is_default) {
ffffffffc02014fa:	040c2783          	lw	a5,64(s8)
ffffffffc02014fe:	ef89                	bnez	a5,ffffffffc0201518 <slub_cache_basic_check+0x1ac>
ffffffffc0201500:	00005797          	auipc	a5,0x5
ffffffffc0201504:	b4078793          	addi	a5,a5,-1216 # ffffffffc0206040 <slub_custom_caches>
    for (size_t i = 0; i < SLUB_MAX_CUSTOM_CACHES; i++) {
ffffffffc0201508:	4721                	li	a4,8
        if (&slub_custom_caches[i] == cache) {
ffffffffc020150a:	06f90963          	beq	s2,a5,ffffffffc020157c <slub_cache_basic_check+0x210>
    for (size_t i = 0; i < SLUB_MAX_CUSTOM_CACHES; i++) {
ffffffffc020150e:	0405                	addi	s0,s0,1
ffffffffc0201510:	07878793          	addi	a5,a5,120
ffffffffc0201514:	fee41be3          	bne	s0,a4,ffffffffc020150a <slub_cache_basic_check+0x19e>
}
ffffffffc0201518:	7f010113          	addi	sp,sp,2032
ffffffffc020151c:	70e6                	ld	ra,120(sp)
ffffffffc020151e:	7446                	ld	s0,112(sp)
ffffffffc0201520:	74a6                	ld	s1,104(sp)
ffffffffc0201522:	7906                	ld	s2,96(sp)
ffffffffc0201524:	69e6                	ld	s3,88(sp)
ffffffffc0201526:	6a46                	ld	s4,80(sp)
ffffffffc0201528:	6aa6                	ld	s5,72(sp)
ffffffffc020152a:	6b06                	ld	s6,64(sp)
ffffffffc020152c:	7be2                	ld	s7,56(sp)
ffffffffc020152e:	7c42                	ld	s8,48(sp)
ffffffffc0201530:	7ca2                	ld	s9,40(sp)
ffffffffc0201532:	7d02                	ld	s10,32(sp)
ffffffffc0201534:	6de2                	ld	s11,24(sp)
    SLUB_LOG("cache_basic_check passed\n");
ffffffffc0201536:	00001517          	auipc	a0,0x1
ffffffffc020153a:	0e250513          	addi	a0,a0,226 # ffffffffc0202618 <etext+0x62a>
}
ffffffffc020153e:	6109                	addi	sp,sp,128
    SLUB_LOG("cache_basic_check passed\n");
ffffffffc0201540:	c0dfe06f          	j	ffffffffc020014c <cprintf>
            SLUB_ASSERT(objs[i] != objs[j]);
ffffffffc0201544:	25100613          	li	a2,593
ffffffffc0201548:	00001597          	auipc	a1,0x1
ffffffffc020154c:	e6858593          	addi	a1,a1,-408 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201550:	00001697          	auipc	a3,0x1
ffffffffc0201554:	09868693          	addi	a3,a3,152 # ffffffffc02025e8 <etext+0x5fa>
ffffffffc0201558:	00001517          	auipc	a0,0x1
ffffffffc020155c:	e7050513          	addi	a0,a0,-400 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201560:	bedfe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201564:	00001617          	auipc	a2,0x1
ffffffffc0201568:	e8c60613          	addi	a2,a2,-372 # ffffffffc02023f0 <etext+0x402>
ffffffffc020156c:	25100593          	li	a1,593
ffffffffc0201570:	00001517          	auipc	a0,0x1
ffffffffc0201574:	e4050513          	addi	a0,a0,-448 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201578:	c4bfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            slub_custom_used[i] = 0;
ffffffffc020157c:	040a                	slli	s0,s0,0x2
ffffffffc020157e:	9466                	add	s0,s0,s9
ffffffffc0201580:	00042023          	sw	zero,0(s0)
            return;
ffffffffc0201584:	bf51                	j	ffffffffc0201518 <slub_cache_basic_check+0x1ac>
    SLUB_ASSERT(per > 0);
ffffffffc0201586:	24800613          	li	a2,584
ffffffffc020158a:	00001597          	auipc	a1,0x1
ffffffffc020158e:	e2658593          	addi	a1,a1,-474 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201592:	00001697          	auipc	a3,0x1
ffffffffc0201596:	01e68693          	addi	a3,a3,30 # ffffffffc02025b0 <etext+0x5c2>
ffffffffc020159a:	00001517          	auipc	a0,0x1
ffffffffc020159e:	e2e50513          	addi	a0,a0,-466 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02015a2:	babfe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02015a6:	00001617          	auipc	a2,0x1
ffffffffc02015aa:	e4a60613          	addi	a2,a2,-438 # ffffffffc02023f0 <etext+0x402>
ffffffffc02015ae:	24800593          	li	a1,584
ffffffffc02015b2:	00001517          	auipc	a0,0x1
ffffffffc02015b6:	dfe50513          	addi	a0,a0,-514 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02015ba:	c09fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(cache->slabs_total == 0);
ffffffffc02015be:	25e00613          	li	a2,606
ffffffffc02015c2:	00001597          	auipc	a1,0x1
ffffffffc02015c6:	dee58593          	addi	a1,a1,-530 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02015ca:	00001697          	auipc	a3,0x1
ffffffffc02015ce:	03668693          	addi	a3,a3,54 # ffffffffc0202600 <etext+0x612>
ffffffffc02015d2:	00001517          	auipc	a0,0x1
ffffffffc02015d6:	df650513          	addi	a0,a0,-522 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02015da:	b73fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02015de:	00001617          	auipc	a2,0x1
ffffffffc02015e2:	e1260613          	addi	a2,a2,-494 # ffffffffc02023f0 <etext+0x402>
ffffffffc02015e6:	25e00593          	li	a1,606
ffffffffc02015ea:	00001517          	auipc	a0,0x1
ffffffffc02015ee:	dc650513          	addi	a0,a0,-570 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02015f2:	bd1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(total <= ARRAY_SIZE(objs));
ffffffffc02015f6:	24b00613          	li	a2,587
ffffffffc02015fa:	00001597          	auipc	a1,0x1
ffffffffc02015fe:	db658593          	addi	a1,a1,-586 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201602:	00001697          	auipc	a3,0x1
ffffffffc0201606:	fb668693          	addi	a3,a3,-74 # ffffffffc02025b8 <etext+0x5ca>
ffffffffc020160a:	00001517          	auipc	a0,0x1
ffffffffc020160e:	dbe50513          	addi	a0,a0,-578 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201612:	b3bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201616:	00001617          	auipc	a2,0x1
ffffffffc020161a:	dda60613          	addi	a2,a2,-550 # ffffffffc02023f0 <etext+0x402>
ffffffffc020161e:	24b00593          	li	a1,587
ffffffffc0201622:	00001517          	auipc	a0,0x1
ffffffffc0201626:	d8e50513          	addi	a0,a0,-626 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc020162a:	b99fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020162e <slub_alloc>:
    if (size == 0) {
ffffffffc020162e:	c10d                	beqz	a0,ffffffffc0201650 <slub_alloc+0x22>
ffffffffc0201630:	00005797          	auipc	a5,0x5
ffffffffc0201634:	df878793          	addi	a5,a5,-520 # ffffffffc0206428 <slub_default_caches+0x8>
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc0201638:	4701                	li	a4,0
ffffffffc020163a:	4631                	li	a2,12
        if (!cache->active) {
ffffffffc020163c:	5fd4                	lw	a3,60(a5)
ffffffffc020163e:	c681                	beqz	a3,ffffffffc0201646 <slub_alloc+0x18>
        if (size <= cache->obj_size) {
ffffffffc0201640:	6394                	ld	a3,0(a5)
ffffffffc0201642:	00a6f963          	bgeu	a3,a0,ffffffffc0201654 <slub_alloc+0x26>
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc0201646:	0705                	addi	a4,a4,1
ffffffffc0201648:	07878793          	addi	a5,a5,120
ffffffffc020164c:	fec718e3          	bne	a4,a2,ffffffffc020163c <slub_alloc+0xe>
}
ffffffffc0201650:	4501                	li	a0,0
ffffffffc0201652:	8082                	ret
        struct slub_cache *cache = &slub_default_caches[i];
ffffffffc0201654:	00471513          	slli	a0,a4,0x4
ffffffffc0201658:	40e50733          	sub	a4,a0,a4
ffffffffc020165c:	070e                	slli	a4,a4,0x3
        return slub_cache_do_alloc(cache);
ffffffffc020165e:	00005517          	auipc	a0,0x5
ffffffffc0201662:	dc250513          	addi	a0,a0,-574 # ffffffffc0206420 <slub_default_caches>
ffffffffc0201666:	953a                	add	a0,a0,a4
ffffffffc0201668:	c7aff06f          	j	ffffffffc0200ae2 <slub_cache_do_alloc>

ffffffffc020166c <slub_free>:
    if (ptr == NULL) {
ffffffffc020166c:	cd39                	beqz	a0,ffffffffc02016ca <slub_free+0x5e>
void slub_free(void *ptr) {
ffffffffc020166e:	1141                	addi	sp,sp,-16
ffffffffc0201670:	e406                	sd	ra,8(sp)
    SLUB_ASSERT(kva_val >= va_pa_offset);
ffffffffc0201672:	00005717          	auipc	a4,0x5
ffffffffc0201676:	44e73703          	ld	a4,1102(a4) # ffffffffc0206ac0 <va_pa_offset>
ffffffffc020167a:	862a                	mv	a2,a0
ffffffffc020167c:	0ae56063          	bltu	a0,a4,ffffffffc020171c <slub_free+0xb0>
    uintptr_t pa = kva_val - va_pa_offset;
ffffffffc0201680:	40e507b3          	sub	a5,a0,a4
    if (PPN(pa) >= npage) {
ffffffffc0201684:	83b1                	srli	a5,a5,0xc
ffffffffc0201686:	00005697          	auipc	a3,0x5
ffffffffc020168a:	4126b683          	ld	a3,1042(a3) # ffffffffc0206a98 <npage>
ffffffffc020168e:	06d7fb63          	bgeu	a5,a3,ffffffffc0201704 <slub_free+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201692:	00001697          	auipc	a3,0x1
ffffffffc0201696:	4e66b683          	ld	a3,1254(a3) # ffffffffc0202b78 <nbase>
ffffffffc020169a:	8f95                	sub	a5,a5,a3
ffffffffc020169c:	00279593          	slli	a1,a5,0x2
ffffffffc02016a0:	95be                	add	a1,a1,a5
ffffffffc02016a2:	058e                	slli	a1,a1,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02016a4:	00001797          	auipc	a5,0x1
ffffffffc02016a8:	4dc7b783          	ld	a5,1244(a5) # ffffffffc0202b80 <nbase+0x8>
ffffffffc02016ac:	858d                	srai	a1,a1,0x3
ffffffffc02016ae:	02f585b3          	mul	a1,a1,a5
    SLUB_ASSERT(magic == SLUB_SLAB_MAGIC);
ffffffffc02016b2:	57fd                	li	a5,-1
ffffffffc02016b4:	95b6                	add	a1,a1,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02016b6:	05b2                	slli	a1,a1,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc02016b8:	95ba                	add	a1,a1,a4
    SLUB_ASSERT(magic == SLUB_SLAB_MAGIC);
ffffffffc02016ba:	4198                	lw	a4,0(a1)
ffffffffc02016bc:	00f71863          	bne	a4,a5,ffffffffc02016cc <slub_free+0x60>
}
ffffffffc02016c0:	60a2                	ld	ra,8(sp)
    slub_cache_do_free(slab->cache, slab, ptr);
ffffffffc02016c2:	6588                	ld	a0,8(a1)
}
ffffffffc02016c4:	0141                	addi	sp,sp,16
    slub_cache_do_free(slab->cache, slab, ptr);
ffffffffc02016c6:	94bff06f          	j	ffffffffc0201010 <slub_cache_do_free>
ffffffffc02016ca:	8082                	ret
    SLUB_ASSERT(magic == SLUB_SLAB_MAGIC);
ffffffffc02016cc:	21400613          	li	a2,532
ffffffffc02016d0:	00001597          	auipc	a1,0x1
ffffffffc02016d4:	ce058593          	addi	a1,a1,-800 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02016d8:	00001697          	auipc	a3,0x1
ffffffffc02016dc:	f6868693          	addi	a3,a3,-152 # ffffffffc0202640 <etext+0x652>
ffffffffc02016e0:	00001517          	auipc	a0,0x1
ffffffffc02016e4:	ce850513          	addi	a0,a0,-792 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02016e8:	a65fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02016ec:	00001617          	auipc	a2,0x1
ffffffffc02016f0:	d0460613          	addi	a2,a2,-764 # ffffffffc02023f0 <etext+0x402>
ffffffffc02016f4:	21400593          	li	a1,532
ffffffffc02016f8:	00001517          	auipc	a0,0x1
ffffffffc02016fc:	cb850513          	addi	a0,a0,-840 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201700:	ac3fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201704:	00001617          	auipc	a2,0x1
ffffffffc0201708:	c0460613          	addi	a2,a2,-1020 # ffffffffc0202308 <etext+0x31a>
ffffffffc020170c:	06a00593          	li	a1,106
ffffffffc0201710:	00001517          	auipc	a0,0x1
ffffffffc0201714:	c1850513          	addi	a0,a0,-1000 # ffffffffc0202328 <etext+0x33a>
ffffffffc0201718:	aabfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc020171c:	b8aff0ef          	jal	ra,ffffffffc0200aa6 <kva2page_local.part.0>

ffffffffc0201720 <slub_check>:
static void slub_check(void) {
ffffffffc0201720:	7111                	addi	sp,sp,-256
ffffffffc0201722:	f9a2                	sd	s0,240(sp)
ffffffffc0201724:	e5d6                	sd	s5,200(sp)
ffffffffc0201726:	fd86                	sd	ra,248(sp)
ffffffffc0201728:	f5a6                	sd	s1,232(sp)
ffffffffc020172a:	f1ca                	sd	s2,224(sp)
ffffffffc020172c:	edce                	sd	s3,216(sp)
ffffffffc020172e:	e9d2                	sd	s4,208(sp)
ffffffffc0201730:	e1da                	sd	s6,192(sp)
ffffffffc0201732:	fd5e                	sd	s7,184(sp)
ffffffffc0201734:	f962                	sd	s8,176(sp)
ffffffffc0201736:	f566                	sd	s9,168(sp)
ffffffffc0201738:	0200                	addi	s0,sp,256
    SLUB_LOG("page_basic_check begin\n");
ffffffffc020173a:	00001517          	auipc	a0,0x1
ffffffffc020173e:	f2650513          	addi	a0,a0,-218 # ffffffffc0202660 <etext+0x672>
    if (n > page_nr_free) {
ffffffffc0201742:	00005a97          	auipc	s5,0x5
ffffffffc0201746:	8d6a8a93          	addi	s5,s5,-1834 # ffffffffc0206018 <page_area>
    SLUB_LOG("page_basic_check begin\n");
ffffffffc020174a:	a03fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > page_nr_free) {
ffffffffc020174e:	010aa783          	lw	a5,16(s5)
ffffffffc0201752:	24078c63          	beqz	a5,ffffffffc02019aa <slub_check+0x28a>
ffffffffc0201756:	4505                	li	a0,1
ffffffffc0201758:	a52ff0ef          	jal	ra,ffffffffc02009aa <slub_page_alloc.part.0>
ffffffffc020175c:	010aa783          	lw	a5,16(s5)
ffffffffc0201760:	89aa                	mv	s3,a0
ffffffffc0201762:	24078463          	beqz	a5,ffffffffc02019aa <slub_check+0x28a>
ffffffffc0201766:	4505                	li	a0,1
ffffffffc0201768:	a42ff0ef          	jal	ra,ffffffffc02009aa <slub_page_alloc.part.0>
ffffffffc020176c:	010aa783          	lw	a5,16(s5)
ffffffffc0201770:	892a                	mv	s2,a0
ffffffffc0201772:	22078c63          	beqz	a5,ffffffffc02019aa <slub_check+0x28a>
ffffffffc0201776:	4505                	li	a0,1
ffffffffc0201778:	a32ff0ef          	jal	ra,ffffffffc02009aa <slub_page_alloc.part.0>
ffffffffc020177c:	84aa                	mv	s1,a0
    SLUB_ASSERT(p0 != NULL && p1 != NULL && p2 != NULL);
ffffffffc020177e:	22098663          	beqz	s3,ffffffffc02019aa <slub_check+0x28a>
ffffffffc0201782:	22090463          	beqz	s2,ffffffffc02019aa <slub_check+0x28a>
ffffffffc0201786:	22050263          	beqz	a0,ffffffffc02019aa <slub_check+0x28a>
    SLUB_ASSERT(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020178a:	2d390463          	beq	s2,s3,ffffffffc0201a52 <slub_check+0x332>
ffffffffc020178e:	2d350263          	beq	a0,s3,ffffffffc0201a52 <slub_check+0x332>
ffffffffc0201792:	2d250063          	beq	a0,s2,ffffffffc0201a52 <slub_check+0x332>
    SLUB_ASSERT(n > 0);
ffffffffc0201796:	4585                	li	a1,1
ffffffffc0201798:	854e                	mv	a0,s3
ffffffffc020179a:	d3aff0ef          	jal	ra,ffffffffc0200cd4 <slub_page_free.part.0>
ffffffffc020179e:	4585                	li	a1,1
ffffffffc02017a0:	854a                	mv	a0,s2
ffffffffc02017a2:	d32ff0ef          	jal	ra,ffffffffc0200cd4 <slub_page_free.part.0>
ffffffffc02017a6:	4585                	li	a1,1
ffffffffc02017a8:	8526                	mv	a0,s1
ffffffffc02017aa:	d2aff0ef          	jal	ra,ffffffffc0200cd4 <slub_page_free.part.0>
    SLUB_LOG("page_basic_check passed\n");
ffffffffc02017ae:	00001517          	auipc	a0,0x1
ffffffffc02017b2:	f2250513          	addi	a0,a0,-222 # ffffffffc02026d0 <etext+0x6e2>
ffffffffc02017b6:	997fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    SLUB_LOG("page_fragment_check begin\n");
ffffffffc02017ba:	00001517          	auipc	a0,0x1
ffffffffc02017be:	f3650513          	addi	a0,a0,-202 # ffffffffc02026f0 <etext+0x702>
ffffffffc02017c2:	98bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > page_nr_free) {
ffffffffc02017c6:	010aa703          	lw	a4,16(s5)
ffffffffc02017ca:	479d                	li	a5,7
ffffffffc02017cc:	24e7f763          	bgeu	a5,a4,ffffffffc0201a1a <slub_check+0x2fa>
ffffffffc02017d0:	4521                	li	a0,8
ffffffffc02017d2:	9d8ff0ef          	jal	ra,ffffffffc02009aa <slub_page_alloc.part.0>
ffffffffc02017d6:	84aa                	mv	s1,a0
    SLUB_ASSERT(block != NULL);
ffffffffc02017d8:	24050163          	beqz	a0,ffffffffc0201a1a <slub_check+0x2fa>
    SLUB_ASSERT(n > 0);
ffffffffc02017dc:	458d                	li	a1,3
ffffffffc02017de:	cf6ff0ef          	jal	ra,ffffffffc0200cd4 <slub_page_free.part.0>
ffffffffc02017e2:	4595                	li	a1,5
ffffffffc02017e4:	07848513          	addi	a0,s1,120
ffffffffc02017e8:	cecff0ef          	jal	ra,ffffffffc0200cd4 <slub_page_free.part.0>
    if (n > page_nr_free) {
ffffffffc02017ec:	010aa703          	lw	a4,16(s5)
ffffffffc02017f0:	479d                	li	a5,7
ffffffffc02017f2:	1ee7f863          	bgeu	a5,a4,ffffffffc02019e2 <slub_check+0x2c2>
ffffffffc02017f6:	4521                	li	a0,8
ffffffffc02017f8:	9b2ff0ef          	jal	ra,ffffffffc02009aa <slub_page_alloc.part.0>
    SLUB_ASSERT(all == block);
ffffffffc02017fc:	1ea49363          	bne	s1,a0,ffffffffc02019e2 <slub_check+0x2c2>
    SLUB_ASSERT(n > 0);
ffffffffc0201800:	45a1                	li	a1,8
ffffffffc0201802:	cd2ff0ef          	jal	ra,ffffffffc0200cd4 <slub_page_free.part.0>
    SLUB_LOG("page_fragment_check passed\n");
ffffffffc0201806:	00001517          	auipc	a0,0x1
ffffffffc020180a:	f3250513          	addi	a0,a0,-206 # ffffffffc0202738 <etext+0x74a>
ffffffffc020180e:	93ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    slub_cache_basic_check();
ffffffffc0201812:	b5bff0ef          	jal	ra,ffffffffc020136c <slub_cache_basic_check>
    SLUB_LOG("alloc_general_check begin\n");
ffffffffc0201816:	00001517          	auipc	a0,0x1
ffffffffc020181a:	f4a50513          	addi	a0,a0,-182 # ffffffffc0202760 <etext+0x772>
ffffffffc020181e:	92ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t sizes[] = {1, 7, 15, 23, 63, 117, 191, 255, 383, 511};
ffffffffc0201822:	00001797          	auipc	a5,0x1
ffffffffc0201826:	02678793          	addi	a5,a5,38 # ffffffffc0202848 <etext+0x85a>
ffffffffc020182a:	0007be03          	ld	t3,0(a5)
ffffffffc020182e:	0087b303          	ld	t1,8(a5)
ffffffffc0201832:	0107b883          	ld	a7,16(a5)
ffffffffc0201836:	0187b803          	ld	a6,24(a5)
ffffffffc020183a:	7388                	ld	a0,32(a5)
ffffffffc020183c:	778c                	ld	a1,40(a5)
ffffffffc020183e:	7b90                	ld	a2,48(a5)
ffffffffc0201840:	7f94                	ld	a3,56(a5)
ffffffffc0201842:	63b8                	ld	a4,64(a5)
ffffffffc0201844:	67bc                	ld	a5,72(a5)
    return page_nr_free;
ffffffffc0201846:	010aab03          	lw	s6,16(s5)
    size_t sizes[] = {1, 7, 15, 23, 63, 117, 191, 255, 383, 511};
ffffffffc020184a:	f5040493          	addi	s1,s0,-176
ffffffffc020184e:	f1c43023          	sd	t3,-256(s0)
ffffffffc0201852:	f0643423          	sd	t1,-248(s0)
ffffffffc0201856:	f1143823          	sd	a7,-240(s0)
ffffffffc020185a:	f1043c23          	sd	a6,-232(s0)
ffffffffc020185e:	f2a43023          	sd	a0,-224(s0)
ffffffffc0201862:	f2b43423          	sd	a1,-216(s0)
ffffffffc0201866:	f2c43823          	sd	a2,-208(s0)
ffffffffc020186a:	f2d43c23          	sd	a3,-200(s0)
ffffffffc020186e:	f4e43023          	sd	a4,-192(s0)
ffffffffc0201872:	f4f43423          	sd	a5,-184(s0)
    for (size_t i = 0; i < ARRAY_SIZE(sizes); i++) {
ffffffffc0201876:	f0040913          	addi	s2,s0,-256
    size_t sizes[] = {1, 7, 15, 23, 63, 117, 191, 255, 383, 511};
ffffffffc020187a:	89a6                	mv	s3,s1
        ptrs[i] = slub_alloc(sizes[i]);
ffffffffc020187c:	00093a03          	ld	s4,0(s2)
ffffffffc0201880:	8552                	mv	a0,s4
ffffffffc0201882:	dadff0ef          	jal	ra,ffffffffc020162e <slub_alloc>
ffffffffc0201886:	00a9b023          	sd	a0,0(s3)
        SLUB_ASSERT(ptrs[i] != NULL);
ffffffffc020188a:	22050c63          	beqz	a0,ffffffffc0201ac2 <slub_check+0x3a2>
        memset(ptrs[i], 0x3C, sizes[i]);
ffffffffc020188e:	8652                	mv	a2,s4
ffffffffc0201890:	03c00593          	li	a1,60
    for (size_t i = 0; i < ARRAY_SIZE(sizes); i++) {
ffffffffc0201894:	0921                	addi	s2,s2,8
        memset(ptrs[i], 0x3C, sizes[i]);
ffffffffc0201896:	746000ef          	jal	ra,ffffffffc0201fdc <memset>
    for (size_t i = 0; i < ARRAY_SIZE(sizes); i++) {
ffffffffc020189a:	09a1                	addi	s3,s3,8
ffffffffc020189c:	fe9910e3          	bne	s2,s1,ffffffffc020187c <slub_check+0x15c>
ffffffffc02018a0:	05048913          	addi	s2,s1,80
        slub_free(ptrs[i]);
ffffffffc02018a4:	6088                	ld	a0,0(s1)
    for (size_t i = 0; i < ARRAY_SIZE(sizes); i++) {
ffffffffc02018a6:	04a1                	addi	s1,s1,8
        slub_free(ptrs[i]);
ffffffffc02018a8:	dc5ff0ef          	jal	ra,ffffffffc020166c <slub_free>
    for (size_t i = 0; i < ARRAY_SIZE(sizes); i++) {
ffffffffc02018ac:	ff249ce3          	bne	s1,s2,ffffffffc02018a4 <slub_check+0x184>
    SLUB_ASSERT(before == after);
ffffffffc02018b0:	010aa783          	lw	a5,16(s5)
ffffffffc02018b4:	1d679b63          	bne	a5,s6,ffffffffc0201a8a <slub_check+0x36a>
    SLUB_LOG("alloc_general_check passed\n");
ffffffffc02018b8:	00001517          	auipc	a0,0x1
ffffffffc02018bc:	ef050513          	addi	a0,a0,-272 # ffffffffc02027a8 <etext+0x7ba>
ffffffffc02018c0:	88dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    SLUB_LOG("stress_check begin\n");
ffffffffc02018c4:	00001517          	auipc	a0,0x1
ffffffffc02018c8:	f0c50513          	addi	a0,a0,-244 # ffffffffc02027d0 <etext+0x7e2>
static void slub_stress_check(void) {
ffffffffc02018cc:	8b0a                	mv	s6,sp
    SLUB_LOG("stress_check begin\n");
ffffffffc02018ce:	87ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *ptrs[batch];
ffffffffc02018d2:	d0010113          	addi	sp,sp,-768
ffffffffc02018d6:	8a0a                	mv	s4,sp
ffffffffc02018d8:	4a91                	li	s5,4
ffffffffc02018da:	84da                	mv	s1,s6
        if (size <= cache->obj_size) {
ffffffffc02018dc:	02f00913          	li	s2,47
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc02018e0:	4bb1                	li	s7,12
        struct slub_cache *cache = &slub_default_caches[i];
ffffffffc02018e2:	00005997          	auipc	s3,0x5
ffffffffc02018e6:	b3e98993          	addi	s3,s3,-1218 # ffffffffc0206420 <slub_default_caches>
        for (size_t i = 0; i < batch; i++) {
ffffffffc02018ea:	8c52                	mv	s8,s4
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc02018ec:	8cd2                	mv	s9,s4
ffffffffc02018ee:	00005797          	auipc	a5,0x5
ffffffffc02018f2:	b3a78793          	addi	a5,a5,-1222 # ffffffffc0206428 <slub_default_caches+0x8>
ffffffffc02018f6:	4681                	li	a3,0
        if (!cache->active) {
ffffffffc02018f8:	5fd8                	lw	a4,60(a5)
ffffffffc02018fa:	c701                	beqz	a4,ffffffffc0201902 <slub_check+0x1e2>
        if (size <= cache->obj_size) {
ffffffffc02018fc:	6398                	ld	a4,0(a5)
ffffffffc02018fe:	04e96363          	bltu	s2,a4,ffffffffc0201944 <slub_check+0x224>
    for (size_t i = 0; i < ARRAY_SIZE(slub_default_caches); i++) {
ffffffffc0201902:	0685                	addi	a3,a3,1
ffffffffc0201904:	07878793          	addi	a5,a5,120
ffffffffc0201908:	ff7698e3          	bne	a3,s7,ffffffffc02018f8 <slub_check+0x1d8>
            SLUB_ASSERT(ptrs[i] != NULL);
ffffffffc020190c:	27f00613          	li	a2,639
ffffffffc0201910:	00001597          	auipc	a1,0x1
ffffffffc0201914:	aa058593          	addi	a1,a1,-1376 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201918:	00001697          	auipc	a3,0x1
ffffffffc020191c:	e7068693          	addi	a3,a3,-400 # ffffffffc0202788 <etext+0x79a>
ffffffffc0201920:	00001517          	auipc	a0,0x1
ffffffffc0201924:	aa850513          	addi	a0,a0,-1368 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201928:	825fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020192c:	00001617          	auipc	a2,0x1
ffffffffc0201930:	ac460613          	addi	a2,a2,-1340 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201934:	27f00593          	li	a1,639
ffffffffc0201938:	00001517          	auipc	a0,0x1
ffffffffc020193c:	a7850513          	addi	a0,a0,-1416 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201940:	883fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        struct slub_cache *cache = &slub_default_caches[i];
ffffffffc0201944:	00469513          	slli	a0,a3,0x4
ffffffffc0201948:	8d15                	sub	a0,a0,a3
ffffffffc020194a:	050e                	slli	a0,a0,0x3
        return slub_cache_do_alloc(cache);
ffffffffc020194c:	954e                	add	a0,a0,s3
ffffffffc020194e:	994ff0ef          	jal	ra,ffffffffc0200ae2 <slub_cache_do_alloc>
            ptrs[i] = slub_alloc(48);
ffffffffc0201952:	00acb023          	sd	a0,0(s9)
            SLUB_ASSERT(ptrs[i] != NULL);
ffffffffc0201956:	d95d                	beqz	a0,ffffffffc020190c <slub_check+0x1ec>
        for (size_t i = 0; i < batch; i++) {
ffffffffc0201958:	0ca1                	addi	s9,s9,8
ffffffffc020195a:	f89c9ae3          	bne	s9,s1,ffffffffc02018ee <slub_check+0x1ce>
            slub_free(ptrs[i]);
ffffffffc020195e:	000c3503          	ld	a0,0(s8)
        for (size_t i = 0; i < batch; i++) {
ffffffffc0201962:	0c21                	addi	s8,s8,8
            slub_free(ptrs[i]);
ffffffffc0201964:	d09ff0ef          	jal	ra,ffffffffc020166c <slub_free>
        for (size_t i = 0; i < batch; i++) {
ffffffffc0201968:	fe9c1be3          	bne	s8,s1,ffffffffc020195e <slub_check+0x23e>
    for (size_t r = 0; r < rounds; r++) {
ffffffffc020196c:	1afd                	addi	s5,s5,-1
ffffffffc020196e:	f60a9ee3          	bnez	s5,ffffffffc02018ea <slub_check+0x1ca>
    SLUB_LOG("stress_check passed\n");
ffffffffc0201972:	00001517          	auipc	a0,0x1
ffffffffc0201976:	e7e50513          	addi	a0,a0,-386 # ffffffffc02027f0 <etext+0x802>
ffffffffc020197a:	fd2fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    SLUB_LOG("all checks passed\n");
ffffffffc020197e:	00001517          	auipc	a0,0x1
ffffffffc0201982:	e9250513          	addi	a0,a0,-366 # ffffffffc0202810 <etext+0x822>
ffffffffc0201986:	815a                	mv	sp,s6
ffffffffc0201988:	fc4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc020198c:	f0040113          	addi	sp,s0,-256
ffffffffc0201990:	70ee                	ld	ra,248(sp)
ffffffffc0201992:	744e                	ld	s0,240(sp)
ffffffffc0201994:	74ae                	ld	s1,232(sp)
ffffffffc0201996:	790e                	ld	s2,224(sp)
ffffffffc0201998:	69ee                	ld	s3,216(sp)
ffffffffc020199a:	6a4e                	ld	s4,208(sp)
ffffffffc020199c:	6aae                	ld	s5,200(sp)
ffffffffc020199e:	6b0e                	ld	s6,192(sp)
ffffffffc02019a0:	7bea                	ld	s7,184(sp)
ffffffffc02019a2:	7c4a                	ld	s8,176(sp)
ffffffffc02019a4:	7caa                	ld	s9,168(sp)
ffffffffc02019a6:	6111                	addi	sp,sp,256
ffffffffc02019a8:	8082                	ret
    SLUB_ASSERT(p0 != NULL && p1 != NULL && p2 != NULL);
ffffffffc02019aa:	22c00613          	li	a2,556
ffffffffc02019ae:	00001597          	auipc	a1,0x1
ffffffffc02019b2:	a0258593          	addi	a1,a1,-1534 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02019b6:	00001697          	auipc	a3,0x1
ffffffffc02019ba:	cca68693          	addi	a3,a3,-822 # ffffffffc0202680 <etext+0x692>
ffffffffc02019be:	00001517          	auipc	a0,0x1
ffffffffc02019c2:	a0a50513          	addi	a0,a0,-1526 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02019c6:	f86fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02019ca:	00001617          	auipc	a2,0x1
ffffffffc02019ce:	a2660613          	addi	a2,a2,-1498 # ffffffffc02023f0 <etext+0x402>
ffffffffc02019d2:	22c00593          	li	a1,556
ffffffffc02019d6:	00001517          	auipc	a0,0x1
ffffffffc02019da:	9da50513          	addi	a0,a0,-1574 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02019de:	fe4fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(all == block);
ffffffffc02019e2:	23d00613          	li	a2,573
ffffffffc02019e6:	00001597          	auipc	a1,0x1
ffffffffc02019ea:	9ca58593          	addi	a1,a1,-1590 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc02019ee:	00001697          	auipc	a3,0x1
ffffffffc02019f2:	d3a68693          	addi	a3,a3,-710 # ffffffffc0202728 <etext+0x73a>
ffffffffc02019f6:	00001517          	auipc	a0,0x1
ffffffffc02019fa:	9d250513          	addi	a0,a0,-1582 # ffffffffc02023c8 <etext+0x3da>
ffffffffc02019fe:	f4efe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201a02:	00001617          	auipc	a2,0x1
ffffffffc0201a06:	9ee60613          	addi	a2,a2,-1554 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201a0a:	23d00593          	li	a1,573
ffffffffc0201a0e:	00001517          	auipc	a0,0x1
ffffffffc0201a12:	9a250513          	addi	a0,a0,-1630 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201a16:	facfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(block != NULL);
ffffffffc0201a1a:	23800613          	li	a2,568
ffffffffc0201a1e:	00001597          	auipc	a1,0x1
ffffffffc0201a22:	99258593          	addi	a1,a1,-1646 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201a26:	00001697          	auipc	a3,0x1
ffffffffc0201a2a:	cf268693          	addi	a3,a3,-782 # ffffffffc0202718 <etext+0x72a>
ffffffffc0201a2e:	00001517          	auipc	a0,0x1
ffffffffc0201a32:	99a50513          	addi	a0,a0,-1638 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201a36:	f16fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201a3a:	00001617          	auipc	a2,0x1
ffffffffc0201a3e:	9b660613          	addi	a2,a2,-1610 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201a42:	23800593          	li	a1,568
ffffffffc0201a46:	00001517          	auipc	a0,0x1
ffffffffc0201a4a:	96a50513          	addi	a0,a0,-1686 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201a4e:	f74fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201a52:	22d00613          	li	a2,557
ffffffffc0201a56:	00001597          	auipc	a1,0x1
ffffffffc0201a5a:	95a58593          	addi	a1,a1,-1702 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201a5e:	00001697          	auipc	a3,0x1
ffffffffc0201a62:	c4a68693          	addi	a3,a3,-950 # ffffffffc02026a8 <etext+0x6ba>
ffffffffc0201a66:	00001517          	auipc	a0,0x1
ffffffffc0201a6a:	96250513          	addi	a0,a0,-1694 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201a6e:	edefe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201a72:	00001617          	auipc	a2,0x1
ffffffffc0201a76:	97e60613          	addi	a2,a2,-1666 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201a7a:	22d00593          	li	a1,557
ffffffffc0201a7e:	00001517          	auipc	a0,0x1
ffffffffc0201a82:	93250513          	addi	a0,a0,-1742 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201a86:	f3cfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    SLUB_ASSERT(before == after);
ffffffffc0201a8a:	27200613          	li	a2,626
ffffffffc0201a8e:	00001597          	auipc	a1,0x1
ffffffffc0201a92:	92258593          	addi	a1,a1,-1758 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201a96:	00001697          	auipc	a3,0x1
ffffffffc0201a9a:	d0268693          	addi	a3,a3,-766 # ffffffffc0202798 <etext+0x7aa>
ffffffffc0201a9e:	00001517          	auipc	a0,0x1
ffffffffc0201aa2:	92a50513          	addi	a0,a0,-1750 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201aa6:	ea6fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201aaa:	00001617          	auipc	a2,0x1
ffffffffc0201aae:	94660613          	addi	a2,a2,-1722 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201ab2:	27200593          	li	a1,626
ffffffffc0201ab6:	00001517          	auipc	a0,0x1
ffffffffc0201aba:	8fa50513          	addi	a0,a0,-1798 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201abe:	f04fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        SLUB_ASSERT(ptrs[i] != NULL);
ffffffffc0201ac2:	26b00613          	li	a2,619
ffffffffc0201ac6:	00001597          	auipc	a1,0x1
ffffffffc0201aca:	8ea58593          	addi	a1,a1,-1814 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201ace:	00001697          	auipc	a3,0x1
ffffffffc0201ad2:	cba68693          	addi	a3,a3,-838 # ffffffffc0202788 <etext+0x79a>
ffffffffc0201ad6:	00001517          	auipc	a0,0x1
ffffffffc0201ada:	8f250513          	addi	a0,a0,-1806 # ffffffffc02023c8 <etext+0x3da>
ffffffffc0201ade:	e6efe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201ae2:	00001617          	auipc	a2,0x1
ffffffffc0201ae6:	90e60613          	addi	a2,a2,-1778 # ffffffffc02023f0 <etext+0x402>
ffffffffc0201aea:	26b00593          	li	a1,619
ffffffffc0201aee:	00001517          	auipc	a0,0x1
ffffffffc0201af2:	8c250513          	addi	a0,a0,-1854 # ffffffffc02023b0 <etext+0x3c2>
ffffffffc0201af6:	eccfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201afa <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201afa:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201afe:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201b00:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201b04:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201b06:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201b0a:	f022                	sd	s0,32(sp)
ffffffffc0201b0c:	ec26                	sd	s1,24(sp)
ffffffffc0201b0e:	e84a                	sd	s2,16(sp)
ffffffffc0201b10:	f406                	sd	ra,40(sp)
ffffffffc0201b12:	e44e                	sd	s3,8(sp)
ffffffffc0201b14:	84aa                	mv	s1,a0
ffffffffc0201b16:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201b18:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201b1c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201b1e:	03067e63          	bgeu	a2,a6,ffffffffc0201b5a <printnum+0x60>
ffffffffc0201b22:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201b24:	00805763          	blez	s0,ffffffffc0201b32 <printnum+0x38>
ffffffffc0201b28:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201b2a:	85ca                	mv	a1,s2
ffffffffc0201b2c:	854e                	mv	a0,s3
ffffffffc0201b2e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201b30:	fc65                	bnez	s0,ffffffffc0201b28 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b32:	1a02                	slli	s4,s4,0x20
ffffffffc0201b34:	00001797          	auipc	a5,0x1
ffffffffc0201b38:	dfc78793          	addi	a5,a5,-516 # ffffffffc0202930 <slub_pmm_manager+0x38>
ffffffffc0201b3c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201b40:	9a3e                	add	s4,s4,a5
}
ffffffffc0201b42:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b44:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201b48:	70a2                	ld	ra,40(sp)
ffffffffc0201b4a:	69a2                	ld	s3,8(sp)
ffffffffc0201b4c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b4e:	85ca                	mv	a1,s2
ffffffffc0201b50:	87a6                	mv	a5,s1
}
ffffffffc0201b52:	6942                	ld	s2,16(sp)
ffffffffc0201b54:	64e2                	ld	s1,24(sp)
ffffffffc0201b56:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b58:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201b5a:	03065633          	divu	a2,a2,a6
ffffffffc0201b5e:	8722                	mv	a4,s0
ffffffffc0201b60:	f9bff0ef          	jal	ra,ffffffffc0201afa <printnum>
ffffffffc0201b64:	b7f9                	j	ffffffffc0201b32 <printnum+0x38>

ffffffffc0201b66 <sprintputch>:
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
    b->cnt ++;
ffffffffc0201b66:	499c                	lw	a5,16(a1)
    if (b->buf < b->ebuf) {
ffffffffc0201b68:	6198                	ld	a4,0(a1)
ffffffffc0201b6a:	6594                	ld	a3,8(a1)
    b->cnt ++;
ffffffffc0201b6c:	2785                	addiw	a5,a5,1
ffffffffc0201b6e:	c99c                	sw	a5,16(a1)
    if (b->buf < b->ebuf) {
ffffffffc0201b70:	00d77763          	bgeu	a4,a3,ffffffffc0201b7e <sprintputch+0x18>
        *b->buf ++ = ch;
ffffffffc0201b74:	00170793          	addi	a5,a4,1
ffffffffc0201b78:	e19c                	sd	a5,0(a1)
ffffffffc0201b7a:	00a70023          	sb	a0,0(a4)
    }
}
ffffffffc0201b7e:	8082                	ret

ffffffffc0201b80 <vprintfmt>:
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201b80:	7119                	addi	sp,sp,-128
ffffffffc0201b82:	f4a6                	sd	s1,104(sp)
ffffffffc0201b84:	f0ca                	sd	s2,96(sp)
ffffffffc0201b86:	ecce                	sd	s3,88(sp)
ffffffffc0201b88:	e8d2                	sd	s4,80(sp)
ffffffffc0201b8a:	e4d6                	sd	s5,72(sp)
ffffffffc0201b8c:	e0da                	sd	s6,64(sp)
ffffffffc0201b8e:	fc5e                	sd	s7,56(sp)
ffffffffc0201b90:	f06a                	sd	s10,32(sp)
ffffffffc0201b92:	fc86                	sd	ra,120(sp)
ffffffffc0201b94:	f8a2                	sd	s0,112(sp)
ffffffffc0201b96:	f862                	sd	s8,48(sp)
ffffffffc0201b98:	f466                	sd	s9,40(sp)
ffffffffc0201b9a:	ec6e                	sd	s11,24(sp)
ffffffffc0201b9c:	892a                	mv	s2,a0
ffffffffc0201b9e:	84ae                	mv	s1,a1
ffffffffc0201ba0:	8d32                	mv	s10,a2
ffffffffc0201ba2:	8a36                	mv	s4,a3
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ba4:	02500993          	li	s3,37
        width = precision = -1;
ffffffffc0201ba8:	5b7d                	li	s6,-1
ffffffffc0201baa:	00001a97          	auipc	s5,0x1
ffffffffc0201bae:	dbaa8a93          	addi	s5,s5,-582 # ffffffffc0202964 <slub_pmm_manager+0x6c>
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201bb2:	00001b97          	auipc	s7,0x1
ffffffffc0201bb6:	f8eb8b93          	addi	s7,s7,-114 # ffffffffc0202b40 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201bba:	000d4503          	lbu	a0,0(s10)
ffffffffc0201bbe:	001d0413          	addi	s0,s10,1
ffffffffc0201bc2:	01350a63          	beq	a0,s3,ffffffffc0201bd6 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201bc6:	c121                	beqz	a0,ffffffffc0201c06 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201bc8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201bca:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201bcc:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201bce:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201bd2:	ff351ae3          	bne	a0,s3,ffffffffc0201bc6 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bd6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201bda:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201bde:	4c81                	li	s9,0
ffffffffc0201be0:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201be2:	5c7d                	li	s8,-1
ffffffffc0201be4:	5dfd                	li	s11,-1
ffffffffc0201be6:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201bea:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bec:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201bf0:	0ff5f593          	zext.b	a1,a1
ffffffffc0201bf4:	00140d13          	addi	s10,s0,1
ffffffffc0201bf8:	04b56263          	bltu	a0,a1,ffffffffc0201c3c <vprintfmt+0xbc>
ffffffffc0201bfc:	058a                	slli	a1,a1,0x2
ffffffffc0201bfe:	95d6                	add	a1,a1,s5
ffffffffc0201c00:	4194                	lw	a3,0(a1)
ffffffffc0201c02:	96d6                	add	a3,a3,s5
ffffffffc0201c04:	8682                	jr	a3
}
ffffffffc0201c06:	70e6                	ld	ra,120(sp)
ffffffffc0201c08:	7446                	ld	s0,112(sp)
ffffffffc0201c0a:	74a6                	ld	s1,104(sp)
ffffffffc0201c0c:	7906                	ld	s2,96(sp)
ffffffffc0201c0e:	69e6                	ld	s3,88(sp)
ffffffffc0201c10:	6a46                	ld	s4,80(sp)
ffffffffc0201c12:	6aa6                	ld	s5,72(sp)
ffffffffc0201c14:	6b06                	ld	s6,64(sp)
ffffffffc0201c16:	7be2                	ld	s7,56(sp)
ffffffffc0201c18:	7c42                	ld	s8,48(sp)
ffffffffc0201c1a:	7ca2                	ld	s9,40(sp)
ffffffffc0201c1c:	7d02                	ld	s10,32(sp)
ffffffffc0201c1e:	6de2                	ld	s11,24(sp)
ffffffffc0201c20:	6109                	addi	sp,sp,128
ffffffffc0201c22:	8082                	ret
            padc = '0';
ffffffffc0201c24:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201c26:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c2a:	846a                	mv	s0,s10
ffffffffc0201c2c:	00140d13          	addi	s10,s0,1
ffffffffc0201c30:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201c34:	0ff5f593          	zext.b	a1,a1
ffffffffc0201c38:	fcb572e3          	bgeu	a0,a1,ffffffffc0201bfc <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201c3c:	85a6                	mv	a1,s1
ffffffffc0201c3e:	02500513          	li	a0,37
ffffffffc0201c42:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201c44:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201c48:	8d22                	mv	s10,s0
ffffffffc0201c4a:	f73788e3          	beq	a5,s3,ffffffffc0201bba <vprintfmt+0x3a>
ffffffffc0201c4e:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201c52:	1d7d                	addi	s10,s10,-1
ffffffffc0201c54:	ff379de3          	bne	a5,s3,ffffffffc0201c4e <vprintfmt+0xce>
ffffffffc0201c58:	b78d                	j	ffffffffc0201bba <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201c5a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201c5e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c62:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201c64:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201c68:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201c6c:	02d86463          	bltu	a6,a3,ffffffffc0201c94 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201c70:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201c74:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201c78:	0186873b          	addw	a4,a3,s8
ffffffffc0201c7c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201c80:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201c82:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201c86:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201c88:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201c8c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201c90:	fed870e3          	bgeu	a6,a3,ffffffffc0201c70 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201c94:	f40ddce3          	bgez	s11,ffffffffc0201bec <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201c98:	8de2                	mv	s11,s8
ffffffffc0201c9a:	5c7d                	li	s8,-1
ffffffffc0201c9c:	bf81                	j	ffffffffc0201bec <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201c9e:	fffdc693          	not	a3,s11
ffffffffc0201ca2:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ca4:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ca8:	00144603          	lbu	a2,1(s0)
ffffffffc0201cac:	2d81                	sext.w	s11,s11
ffffffffc0201cae:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201cb0:	bf35                	j	ffffffffc0201bec <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201cb2:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cb6:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201cba:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cbc:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201cbe:	bfd9                	j	ffffffffc0201c94 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201cc0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cc2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201cc6:	01174463          	blt	a4,a7,ffffffffc0201cce <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201cca:	1a088e63          	beqz	a7,ffffffffc0201e86 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201cce:	000a3603          	ld	a2,0(s4)
ffffffffc0201cd2:	46c1                	li	a3,16
ffffffffc0201cd4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201cd6:	2781                	sext.w	a5,a5
ffffffffc0201cd8:	876e                	mv	a4,s11
ffffffffc0201cda:	85a6                	mv	a1,s1
ffffffffc0201cdc:	854a                	mv	a0,s2
ffffffffc0201cde:	e1dff0ef          	jal	ra,ffffffffc0201afa <printnum>
            break;
ffffffffc0201ce2:	bde1                	j	ffffffffc0201bba <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201ce4:	000a2503          	lw	a0,0(s4)
ffffffffc0201ce8:	85a6                	mv	a1,s1
ffffffffc0201cea:	0a21                	addi	s4,s4,8
ffffffffc0201cec:	9902                	jalr	s2
            break;
ffffffffc0201cee:	b5f1                	j	ffffffffc0201bba <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201cf0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cf2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201cf6:	01174463          	blt	a4,a7,ffffffffc0201cfe <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201cfa:	18088163          	beqz	a7,ffffffffc0201e7c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201cfe:	000a3603          	ld	a2,0(s4)
ffffffffc0201d02:	46a9                	li	a3,10
ffffffffc0201d04:	8a2e                	mv	s4,a1
ffffffffc0201d06:	bfc1                	j	ffffffffc0201cd6 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d08:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201d0c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d0e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d10:	bdf1                	j	ffffffffc0201bec <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201d12:	85a6                	mv	a1,s1
ffffffffc0201d14:	02500513          	li	a0,37
ffffffffc0201d18:	9902                	jalr	s2
            break;
ffffffffc0201d1a:	b545                	j	ffffffffc0201bba <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d1c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201d20:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d22:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d24:	b5e1                	j	ffffffffc0201bec <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201d26:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d28:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d2c:	01174463          	blt	a4,a7,ffffffffc0201d34 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201d30:	14088163          	beqz	a7,ffffffffc0201e72 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201d34:	000a3603          	ld	a2,0(s4)
ffffffffc0201d38:	46a1                	li	a3,8
ffffffffc0201d3a:	8a2e                	mv	s4,a1
ffffffffc0201d3c:	bf69                	j	ffffffffc0201cd6 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201d3e:	03000513          	li	a0,48
ffffffffc0201d42:	85a6                	mv	a1,s1
ffffffffc0201d44:	e03e                	sd	a5,0(sp)
ffffffffc0201d46:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201d48:	85a6                	mv	a1,s1
ffffffffc0201d4a:	07800513          	li	a0,120
ffffffffc0201d4e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201d50:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201d52:	6782                	ld	a5,0(sp)
ffffffffc0201d54:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201d56:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201d5a:	bfb5                	j	ffffffffc0201cd6 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d5c:	000a3403          	ld	s0,0(s4)
ffffffffc0201d60:	008a0713          	addi	a4,s4,8
ffffffffc0201d64:	e03a                	sd	a4,0(sp)
ffffffffc0201d66:	14040263          	beqz	s0,ffffffffc0201eaa <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201d6a:	0fb05763          	blez	s11,ffffffffc0201e58 <vprintfmt+0x2d8>
ffffffffc0201d6e:	02d00693          	li	a3,45
ffffffffc0201d72:	0cd79163          	bne	a5,a3,ffffffffc0201e34 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d76:	00044783          	lbu	a5,0(s0)
ffffffffc0201d7a:	0007851b          	sext.w	a0,a5
ffffffffc0201d7e:	cf85                	beqz	a5,ffffffffc0201db6 <vprintfmt+0x236>
ffffffffc0201d80:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d84:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d88:	000c4563          	bltz	s8,ffffffffc0201d92 <vprintfmt+0x212>
ffffffffc0201d8c:	3c7d                	addiw	s8,s8,-1
ffffffffc0201d8e:	036c0263          	beq	s8,s6,ffffffffc0201db2 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201d92:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d94:	0e0c8e63          	beqz	s9,ffffffffc0201e90 <vprintfmt+0x310>
ffffffffc0201d98:	3781                	addiw	a5,a5,-32
ffffffffc0201d9a:	0ef47b63          	bgeu	s0,a5,ffffffffc0201e90 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201d9e:	03f00513          	li	a0,63
ffffffffc0201da2:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201da4:	000a4783          	lbu	a5,0(s4)
ffffffffc0201da8:	3dfd                	addiw	s11,s11,-1
ffffffffc0201daa:	0a05                	addi	s4,s4,1
ffffffffc0201dac:	0007851b          	sext.w	a0,a5
ffffffffc0201db0:	ffe1                	bnez	a5,ffffffffc0201d88 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201db2:	01b05963          	blez	s11,ffffffffc0201dc4 <vprintfmt+0x244>
ffffffffc0201db6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201db8:	85a6                	mv	a1,s1
ffffffffc0201dba:	02000513          	li	a0,32
ffffffffc0201dbe:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201dc0:	fe0d9be3          	bnez	s11,ffffffffc0201db6 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201dc4:	6a02                	ld	s4,0(sp)
ffffffffc0201dc6:	bbd5                	j	ffffffffc0201bba <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201dc8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201dca:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201dce:	01174463          	blt	a4,a7,ffffffffc0201dd6 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201dd2:	08088d63          	beqz	a7,ffffffffc0201e6c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201dd6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201dda:	0a044d63          	bltz	s0,ffffffffc0201e94 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201dde:	8622                	mv	a2,s0
ffffffffc0201de0:	8a66                	mv	s4,s9
ffffffffc0201de2:	46a9                	li	a3,10
ffffffffc0201de4:	bdcd                	j	ffffffffc0201cd6 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201de6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201dea:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201dec:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201dee:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201df2:	8fb5                	xor	a5,a5,a3
ffffffffc0201df4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201df8:	02d74163          	blt	a4,a3,ffffffffc0201e1a <vprintfmt+0x29a>
ffffffffc0201dfc:	00369793          	slli	a5,a3,0x3
ffffffffc0201e00:	97de                	add	a5,a5,s7
ffffffffc0201e02:	639c                	ld	a5,0(a5)
ffffffffc0201e04:	cb99                	beqz	a5,ffffffffc0201e1a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201e06:	86be                	mv	a3,a5
ffffffffc0201e08:	00001617          	auipc	a2,0x1
ffffffffc0201e0c:	b5860613          	addi	a2,a2,-1192 # ffffffffc0202960 <slub_pmm_manager+0x68>
ffffffffc0201e10:	85a6                	mv	a1,s1
ffffffffc0201e12:	854a                	mv	a0,s2
ffffffffc0201e14:	0ce000ef          	jal	ra,ffffffffc0201ee2 <printfmt>
ffffffffc0201e18:	b34d                	j	ffffffffc0201bba <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201e1a:	00001617          	auipc	a2,0x1
ffffffffc0201e1e:	b3660613          	addi	a2,a2,-1226 # ffffffffc0202950 <slub_pmm_manager+0x58>
ffffffffc0201e22:	85a6                	mv	a1,s1
ffffffffc0201e24:	854a                	mv	a0,s2
ffffffffc0201e26:	0bc000ef          	jal	ra,ffffffffc0201ee2 <printfmt>
ffffffffc0201e2a:	bb41                	j	ffffffffc0201bba <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201e2c:	00001417          	auipc	s0,0x1
ffffffffc0201e30:	b1c40413          	addi	s0,s0,-1252 # ffffffffc0202948 <slub_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e34:	85e2                	mv	a1,s8
ffffffffc0201e36:	8522                	mv	a0,s0
ffffffffc0201e38:	e43e                	sd	a5,8(sp)
ffffffffc0201e3a:	142000ef          	jal	ra,ffffffffc0201f7c <strnlen>
ffffffffc0201e3e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201e42:	01b05b63          	blez	s11,ffffffffc0201e58 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201e46:	67a2                	ld	a5,8(sp)
ffffffffc0201e48:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e4c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201e4e:	85a6                	mv	a1,s1
ffffffffc0201e50:	8552                	mv	a0,s4
ffffffffc0201e52:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e54:	fe0d9ce3          	bnez	s11,ffffffffc0201e4c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e58:	00044783          	lbu	a5,0(s0)
ffffffffc0201e5c:	00140a13          	addi	s4,s0,1
ffffffffc0201e60:	0007851b          	sext.w	a0,a5
ffffffffc0201e64:	d3a5                	beqz	a5,ffffffffc0201dc4 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e66:	05e00413          	li	s0,94
ffffffffc0201e6a:	bf39                	j	ffffffffc0201d88 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201e6c:	000a2403          	lw	s0,0(s4)
ffffffffc0201e70:	b7ad                	j	ffffffffc0201dda <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201e72:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e76:	46a1                	li	a3,8
ffffffffc0201e78:	8a2e                	mv	s4,a1
ffffffffc0201e7a:	bdb1                	j	ffffffffc0201cd6 <vprintfmt+0x156>
ffffffffc0201e7c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e80:	46a9                	li	a3,10
ffffffffc0201e82:	8a2e                	mv	s4,a1
ffffffffc0201e84:	bd89                	j	ffffffffc0201cd6 <vprintfmt+0x156>
ffffffffc0201e86:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e8a:	46c1                	li	a3,16
ffffffffc0201e8c:	8a2e                	mv	s4,a1
ffffffffc0201e8e:	b5a1                	j	ffffffffc0201cd6 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201e90:	9902                	jalr	s2
ffffffffc0201e92:	bf09                	j	ffffffffc0201da4 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201e94:	85a6                	mv	a1,s1
ffffffffc0201e96:	02d00513          	li	a0,45
ffffffffc0201e9a:	e03e                	sd	a5,0(sp)
ffffffffc0201e9c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201e9e:	6782                	ld	a5,0(sp)
ffffffffc0201ea0:	8a66                	mv	s4,s9
ffffffffc0201ea2:	40800633          	neg	a2,s0
ffffffffc0201ea6:	46a9                	li	a3,10
ffffffffc0201ea8:	b53d                	j	ffffffffc0201cd6 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201eaa:	03b05163          	blez	s11,ffffffffc0201ecc <vprintfmt+0x34c>
ffffffffc0201eae:	02d00693          	li	a3,45
ffffffffc0201eb2:	f6d79de3          	bne	a5,a3,ffffffffc0201e2c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201eb6:	00001417          	auipc	s0,0x1
ffffffffc0201eba:	a9240413          	addi	s0,s0,-1390 # ffffffffc0202948 <slub_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ebe:	02800793          	li	a5,40
ffffffffc0201ec2:	02800513          	li	a0,40
ffffffffc0201ec6:	00140a13          	addi	s4,s0,1
ffffffffc0201eca:	bd6d                	j	ffffffffc0201d84 <vprintfmt+0x204>
ffffffffc0201ecc:	00001a17          	auipc	s4,0x1
ffffffffc0201ed0:	a7da0a13          	addi	s4,s4,-1411 # ffffffffc0202949 <slub_pmm_manager+0x51>
ffffffffc0201ed4:	02800513          	li	a0,40
ffffffffc0201ed8:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201edc:	05e00413          	li	s0,94
ffffffffc0201ee0:	b565                	j	ffffffffc0201d88 <vprintfmt+0x208>

ffffffffc0201ee2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201ee2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201ee4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201ee8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201eea:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201eec:	ec06                	sd	ra,24(sp)
ffffffffc0201eee:	f83a                	sd	a4,48(sp)
ffffffffc0201ef0:	fc3e                	sd	a5,56(sp)
ffffffffc0201ef2:	e0c2                	sd	a6,64(sp)
ffffffffc0201ef4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201ef6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201ef8:	c89ff0ef          	jal	ra,ffffffffc0201b80 <vprintfmt>
}
ffffffffc0201efc:	60e2                	ld	ra,24(sp)
ffffffffc0201efe:	6161                	addi	sp,sp,80
ffffffffc0201f00:	8082                	ret

ffffffffc0201f02 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
ffffffffc0201f02:	711d                	addi	sp,sp,-96
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
    struct sprintbuf b = {str, str + size - 1, 0};
ffffffffc0201f04:	15fd                	addi	a1,a1,-1
    va_start(ap, fmt);
ffffffffc0201f06:	03810313          	addi	t1,sp,56
    struct sprintbuf b = {str, str + size - 1, 0};
ffffffffc0201f0a:	95aa                	add	a1,a1,a0
snprintf(char *str, size_t size, const char *fmt, ...) {
ffffffffc0201f0c:	f406                	sd	ra,40(sp)
ffffffffc0201f0e:	fc36                	sd	a3,56(sp)
ffffffffc0201f10:	e0ba                	sd	a4,64(sp)
ffffffffc0201f12:	e4be                	sd	a5,72(sp)
ffffffffc0201f14:	e8c2                	sd	a6,80(sp)
ffffffffc0201f16:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0201f18:	e01a                	sd	t1,0(sp)
    struct sprintbuf b = {str, str + size - 1, 0};
ffffffffc0201f1a:	e42a                	sd	a0,8(sp)
ffffffffc0201f1c:	e82e                	sd	a1,16(sp)
ffffffffc0201f1e:	cc02                	sw	zero,24(sp)
    if (str == NULL || b.buf > b.ebuf) {
ffffffffc0201f20:	c115                	beqz	a0,ffffffffc0201f44 <snprintf+0x42>
ffffffffc0201f22:	02a5e163          	bltu	a1,a0,ffffffffc0201f44 <snprintf+0x42>
        return -E_INVAL;
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
ffffffffc0201f26:	00000517          	auipc	a0,0x0
ffffffffc0201f2a:	c4050513          	addi	a0,a0,-960 # ffffffffc0201b66 <sprintputch>
ffffffffc0201f2e:	869a                	mv	a3,t1
ffffffffc0201f30:	002c                	addi	a1,sp,8
ffffffffc0201f32:	c4fff0ef          	jal	ra,ffffffffc0201b80 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
ffffffffc0201f36:	67a2                	ld	a5,8(sp)
ffffffffc0201f38:	00078023          	sb	zero,0(a5)
    return b.cnt;
ffffffffc0201f3c:	4562                	lw	a0,24(sp)
}
ffffffffc0201f3e:	70a2                	ld	ra,40(sp)
ffffffffc0201f40:	6125                	addi	sp,sp,96
ffffffffc0201f42:	8082                	ret
        return -E_INVAL;
ffffffffc0201f44:	5575                	li	a0,-3
ffffffffc0201f46:	bfe5                	j	ffffffffc0201f3e <snprintf+0x3c>

ffffffffc0201f48 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201f48:	4781                	li	a5,0
ffffffffc0201f4a:	00004717          	auipc	a4,0x4
ffffffffc0201f4e:	0c673703          	ld	a4,198(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f52:	88ba                	mv	a7,a4
ffffffffc0201f54:	852a                	mv	a0,a0
ffffffffc0201f56:	85be                	mv	a1,a5
ffffffffc0201f58:	863e                	mv	a2,a5
ffffffffc0201f5a:	00000073          	ecall
ffffffffc0201f5e:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201f60:	8082                	ret

ffffffffc0201f62 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f62:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f66:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f68:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f6a:	cb81                	beqz	a5,ffffffffc0201f7a <strlen+0x18>
        cnt ++;
ffffffffc0201f6c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f6e:	00a707b3          	add	a5,a4,a0
ffffffffc0201f72:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f76:	fbfd                	bnez	a5,ffffffffc0201f6c <strlen+0xa>
ffffffffc0201f78:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f7a:	8082                	ret

ffffffffc0201f7c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f7c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f7e:	e589                	bnez	a1,ffffffffc0201f88 <strnlen+0xc>
ffffffffc0201f80:	a811                	j	ffffffffc0201f94 <strnlen+0x18>
        cnt ++;
ffffffffc0201f82:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f84:	00f58863          	beq	a1,a5,ffffffffc0201f94 <strnlen+0x18>
ffffffffc0201f88:	00f50733          	add	a4,a0,a5
ffffffffc0201f8c:	00074703          	lbu	a4,0(a4)
ffffffffc0201f90:	fb6d                	bnez	a4,ffffffffc0201f82 <strnlen+0x6>
ffffffffc0201f92:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f94:	852e                	mv	a0,a1
ffffffffc0201f96:	8082                	ret

ffffffffc0201f98 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f98:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f9c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fa0:	cb89                	beqz	a5,ffffffffc0201fb2 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201fa2:	0505                	addi	a0,a0,1
ffffffffc0201fa4:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fa6:	fee789e3          	beq	a5,a4,ffffffffc0201f98 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201faa:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201fae:	9d19                	subw	a0,a0,a4
ffffffffc0201fb0:	8082                	ret
ffffffffc0201fb2:	4501                	li	a0,0
ffffffffc0201fb4:	bfed                	j	ffffffffc0201fae <strcmp+0x16>

ffffffffc0201fb6 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fb6:	c20d                	beqz	a2,ffffffffc0201fd8 <strncmp+0x22>
ffffffffc0201fb8:	962e                	add	a2,a2,a1
ffffffffc0201fba:	a031                	j	ffffffffc0201fc6 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201fbc:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fbe:	00e79a63          	bne	a5,a4,ffffffffc0201fd2 <strncmp+0x1c>
ffffffffc0201fc2:	00b60b63          	beq	a2,a1,ffffffffc0201fd8 <strncmp+0x22>
ffffffffc0201fc6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201fca:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fcc:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201fd0:	f7f5                	bnez	a5,ffffffffc0201fbc <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fd2:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201fd6:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fd8:	4501                	li	a0,0
ffffffffc0201fda:	8082                	ret

ffffffffc0201fdc <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201fdc:	ca01                	beqz	a2,ffffffffc0201fec <memset+0x10>
ffffffffc0201fde:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201fe0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fe2:	0785                	addi	a5,a5,1
ffffffffc0201fe4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fe8:	fec79de3          	bne	a5,a2,ffffffffc0201fe2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201fec:	8082                	ret
