
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
ffffffffc0200050:	7cc50513          	addi	a0,a0,1996 # ffffffffc0201818 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	7d650513          	addi	a0,a0,2006 # ffffffffc0201838 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	7a858593          	addi	a1,a1,1960 # ffffffffc0201816 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	7e250513          	addi	a0,a0,2018 # ffffffffc0201858 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <backend_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	7ee50513          	addi	a0,a0,2030 # ffffffffc0201878 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	000ab597          	auipc	a1,0xab
ffffffffc020009a:	60e58593          	addi	a1,a1,1550 # ffffffffc02ab6a4 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	7fa50513          	addi	a0,a0,2042 # ffffffffc0201898 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	000ac597          	auipc	a1,0xac
ffffffffc02000ae:	9f958593          	addi	a1,a1,-1543 # ffffffffc02abaa3 <end+0x3ff>
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
ffffffffc02000d0:	7ec50513          	addi	a0,a0,2028 # ffffffffc02018b8 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <backend_area>
ffffffffc02000e0:	000ab617          	auipc	a2,0xab
ffffffffc02000e4:	5c460613          	addi	a2,a2,1476 # ffffffffc02ab6a4 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	714010ef          	jal	ra,ffffffffc0201804 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	7ec50513          	addi	a0,a0,2028 # ffffffffc02018e8 <etext+0xd2>
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
ffffffffc0200140:	2ae010ef          	jal	ra,ffffffffc02013ee <vprintfmt>
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
ffffffffc0200176:	278010ef          	jal	ra,ffffffffc02013ee <vprintfmt>
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
ffffffffc02001c2:	000ab317          	auipc	t1,0xab
ffffffffc02001c6:	49630313          	addi	t1,t1,1174 # ffffffffc02ab658 <is_panic>
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
ffffffffc02001f6:	71650513          	addi	a0,a0,1814 # ffffffffc0201908 <etext+0xf2>
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
ffffffffc020020c:	6d850513          	addi	a0,a0,1752 # ffffffffc02018e0 <etext+0xca>
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
ffffffffc020021c:	5540106f          	j	ffffffffc0201770 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	70650513          	addi	a0,a0,1798 # ffffffffc0201928 <etext+0x112>
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
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	6e850513          	addi	a0,a0,1768 # ffffffffc0201938 <etext+0x122>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	6e250513          	addi	a0,a0,1762 # ffffffffc0201948 <etext+0x132>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0201960 <etext+0x14a>
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
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe34849>
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
ffffffffc0200334:	68090913          	addi	s2,s2,1664 # ffffffffc02019b0 <etext+0x19a>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	66a48493          	addi	s1,s1,1642 # ffffffffc02019a8 <etext+0x192>
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
ffffffffc0200396:	69650513          	addi	a0,a0,1686 # ffffffffc0201a28 <etext+0x212>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	6c250513          	addi	a0,a0,1730 # ffffffffc0201a60 <etext+0x24a>
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
ffffffffc02003e2:	5a250513          	addi	a0,a0,1442 # ffffffffc0201980 <etext+0x16a>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	39e010ef          	jal	ra,ffffffffc020178a <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	3e4010ef          	jal	ra,ffffffffc02017de <strncmp>
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
ffffffffc0200490:	330010ef          	jal	ra,ffffffffc02017c0 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	51450513          	addi	a0,a0,1300 # ffffffffc02019b8 <etext+0x1a2>
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
ffffffffc0200576:	46650513          	addi	a0,a0,1126 # ffffffffc02019d8 <etext+0x1c2>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	46c50513          	addi	a0,a0,1132 # ffffffffc02019f0 <etext+0x1da>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	47a50513          	addi	a0,a0,1146 # ffffffffc0201a10 <etext+0x1fa>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	4be50513          	addi	a0,a0,1214 # ffffffffc0201a60 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005aa:	000ab797          	auipc	a5,0xab
ffffffffc02005ae:	0a87bb23          	sd	s0,182(a5) # ffffffffc02ab660 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	000ab797          	auipc	a5,0xab
ffffffffc02005b6:	0b67bb23          	sd	s6,182(a5) # ffffffffc02ab668 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	000ab517          	auipc	a0,0xab
ffffffffc02005c0:	0a453503          	ld	a0,164(a0) # ffffffffc02ab660 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	000ab517          	auipc	a0,0xab
ffffffffc02005ca:	0a253503          	ld	a0,162(a0) # ffffffffc02ab668 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <pmm_init>:

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &slub_pmm_manager;
ffffffffc02005d0:	00002797          	auipc	a5,0x2
ffffffffc02005d4:	86078793          	addi	a5,a5,-1952 # ffffffffc0201e30 <slub_pmm_manager>
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
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	49a50513          	addi	a0,a0,1178 # ffffffffc0201a78 <etext+0x262>
    pmm_manager = &slub_pmm_manager;
ffffffffc02005e6:	000ab417          	auipc	s0,0xab
ffffffffc02005ea:	09a40413          	addi	s0,s0,154 # ffffffffc02ab680 <pmm_manager>
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
ffffffffc0200600:	000ab497          	auipc	s1,0xab
ffffffffc0200604:	09848493          	addi	s1,s1,152 # ffffffffc02ab698 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200608:	679c                	ld	a5,8(a5)
ffffffffc020060a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020060c:	57f5                	li	a5,-3
ffffffffc020060e:	07fa                	slli	a5,a5,0x1e
ffffffffc0200610:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200612:	fabff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200616:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200618:	fafff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020061c:	14050c63          	beqz	a0,ffffffffc0200774 <pmm_init+0x1a4>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200620:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200622:	00001517          	auipc	a0,0x1
ffffffffc0200626:	49e50513          	addi	a0,a0,1182 # ffffffffc0201ac0 <etext+0x2aa>
ffffffffc020062a:	b23ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020062e:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200632:	864e                	mv	a2,s3
ffffffffc0200634:	fffa0693          	addi	a3,s4,-1
ffffffffc0200638:	85ca                	mv	a1,s2
ffffffffc020063a:	00001517          	auipc	a0,0x1
ffffffffc020063e:	49e50513          	addi	a0,a0,1182 # ffffffffc0201ad8 <etext+0x2c2>
ffffffffc0200642:	b0bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200646:	c80007b7          	lui	a5,0xc8000
ffffffffc020064a:	8652                	mv	a2,s4
ffffffffc020064c:	0d47e363          	bltu	a5,s4,ffffffffc0200712 <pmm_init+0x142>
ffffffffc0200650:	000ac797          	auipc	a5,0xac
ffffffffc0200654:	05378793          	addi	a5,a5,83 # ffffffffc02ac6a3 <end+0xfff>
ffffffffc0200658:	757d                	lui	a0,0xfffff
ffffffffc020065a:	8d7d                	and	a0,a0,a5
ffffffffc020065c:	8231                	srli	a2,a2,0xc
ffffffffc020065e:	000ab797          	auipc	a5,0xab
ffffffffc0200662:	00c7b923          	sd	a2,18(a5) # ffffffffc02ab670 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200666:	000ab797          	auipc	a5,0xab
ffffffffc020066a:	00a7b923          	sd	a0,18(a5) # ffffffffc02ab678 <pages>
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
ffffffffc0200690:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e954984>
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
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02006c2:	601c                	ld	a5,0(s0)
ffffffffc02006c4:	7b9c                	ld	a5,48(a5)
ffffffffc02006c6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02006c8:	00001517          	auipc	a0,0x1
ffffffffc02006cc:	49850513          	addi	a0,a0,1176 # ffffffffc0201b60 <etext+0x34a>
ffffffffc02006d0:	a7dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02006d4:	00005597          	auipc	a1,0x5
ffffffffc02006d8:	92c58593          	addi	a1,a1,-1748 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02006dc:	000ab797          	auipc	a5,0xab
ffffffffc02006e0:	fab7ba23          	sd	a1,-76(a5) # ffffffffc02ab690 <satp_virtual>
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
ffffffffc02006fe:	000ab797          	auipc	a5,0xab
ffffffffc0200702:	f8c7b523          	sd	a2,-118(a5) # ffffffffc02ab688 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200706:	00001517          	auipc	a0,0x1
ffffffffc020070a:	47a50513          	addi	a0,a0,1146 # ffffffffc0201b80 <etext+0x36a>
}
ffffffffc020070e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
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
ffffffffc0200744:	00001617          	auipc	a2,0x1
ffffffffc0200748:	3ec60613          	addi	a2,a2,1004 # ffffffffc0201b30 <etext+0x31a>
ffffffffc020074c:	06a00593          	li	a1,106
ffffffffc0200750:	00001517          	auipc	a0,0x1
ffffffffc0200754:	40050513          	addi	a0,a0,1024 # ffffffffc0201b50 <etext+0x33a>
ffffffffc0200758:	a6bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020075c:	00001617          	auipc	a2,0x1
ffffffffc0200760:	3ac60613          	addi	a2,a2,940 # ffffffffc0201b08 <etext+0x2f2>
ffffffffc0200764:	05f00593          	li	a1,95
ffffffffc0200768:	00001517          	auipc	a0,0x1
ffffffffc020076c:	34850513          	addi	a0,a0,840 # ffffffffc0201ab0 <etext+0x29a>
ffffffffc0200770:	a53ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200774:	00001617          	auipc	a2,0x1
ffffffffc0200778:	31c60613          	addi	a2,a2,796 # ffffffffc0201a90 <etext+0x27a>
ffffffffc020077c:	04700593          	li	a1,71
ffffffffc0200780:	00001517          	auipc	a0,0x1
ffffffffc0200784:	33050513          	addi	a0,a0,816 # ffffffffc0201ab0 <etext+0x29a>
ffffffffc0200788:	a3bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020078c:	86ae                	mv	a3,a1
ffffffffc020078e:	00001617          	auipc	a2,0x1
ffffffffc0200792:	37a60613          	addi	a2,a2,890 # ffffffffc0201b08 <etext+0x2f2>
ffffffffc0200796:	07a00593          	li	a1,122
ffffffffc020079a:	00001517          	auipc	a0,0x1
ffffffffc020079e:	31650513          	addi	a0,a0,790 # ffffffffc0201ab0 <etext+0x29a>
ffffffffc02007a2:	a21ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007a6 <slub_nr_free_pages_wrapper>:
}

static size_t
slub_nr_free_pages_wrapper(void) {
    return backend_nr_free_pages() + slub_nr_free_objects();
}
ffffffffc02007a6:	00006517          	auipc	a0,0x6
ffffffffc02007aa:	88253503          	ld	a0,-1918(a0) # ffffffffc0206028 <backend_area+0x10>
ffffffffc02007ae:	00064797          	auipc	a5,0x64
ffffffffc02007b2:	0a27b783          	ld	a5,162(a5) # ffffffffc0264850 <slub_cache+0x20>
ffffffffc02007b6:	953e                	add	a0,a0,a5
ffffffffc02007b8:	8082                	ret

ffffffffc02007ba <backend_alloc_pages>:
    assert(n > 0);
ffffffffc02007ba:	c949                	beqz	a0,ffffffffc020084c <backend_alloc_pages+0x92>
    if (n > backend_nr_free) {
ffffffffc02007bc:	00006617          	auipc	a2,0x6
ffffffffc02007c0:	85c60613          	addi	a2,a2,-1956 # ffffffffc0206018 <backend_area>
ffffffffc02007c4:	01063803          	ld	a6,16(a2)
ffffffffc02007c8:	86aa                	mv	a3,a0
ffffffffc02007ca:	06a86f63          	bltu	a6,a0,ffffffffc0200848 <backend_alloc_pages+0x8e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02007ce:	661c                	ld	a5,8(a2)
    size_t best_size = backend_nr_free + 1;
ffffffffc02007d0:	00180593          	addi	a1,a6,1
    struct Page *candidate = NULL;
ffffffffc02007d4:	4501                	li	a0,0
    while ((le = list_next(le)) != &backend_free_list) {
ffffffffc02007d6:	06c78863          	beq	a5,a2,ffffffffc0200846 <backend_alloc_pages+0x8c>
        if (page->property >= n && page->property < best_size) {
ffffffffc02007da:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02007de:	00d76763          	bltu	a4,a3,ffffffffc02007ec <backend_alloc_pages+0x32>
ffffffffc02007e2:	00b77563          	bgeu	a4,a1,ffffffffc02007ec <backend_alloc_pages+0x32>
        struct Page *page = le2page(le, page_link);
ffffffffc02007e6:	fe878513          	addi	a0,a5,-24
ffffffffc02007ea:	85ba                	mv	a1,a4
ffffffffc02007ec:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &backend_free_list) {
ffffffffc02007ee:	fec796e3          	bne	a5,a2,ffffffffc02007da <backend_alloc_pages+0x20>
    if (candidate == NULL) {
ffffffffc02007f2:	c931                	beqz	a0,ffffffffc0200846 <backend_alloc_pages+0x8c>
    if (candidate->property > n) {
ffffffffc02007f4:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02007f8:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02007fa:	710c                	ld	a1,32(a0)
ffffffffc02007fc:	02089793          	slli	a5,a7,0x20
ffffffffc0200800:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200802:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200804:	e198                	sd	a4,0(a1)
ffffffffc0200806:	02f6f963          	bgeu	a3,a5,ffffffffc0200838 <backend_alloc_pages+0x7e>
        struct Page *remain = candidate + n;
ffffffffc020080a:	00269793          	slli	a5,a3,0x2
ffffffffc020080e:	97b6                	add	a5,a5,a3
ffffffffc0200810:	078e                	slli	a5,a5,0x3
ffffffffc0200812:	97aa                	add	a5,a5,a0
        SetPageProperty(remain);
ffffffffc0200814:	0087b303          	ld	t1,8(a5)
        remain->property = candidate->property - n;
ffffffffc0200818:	40d888bb          	subw	a7,a7,a3
ffffffffc020081c:	0117a823          	sw	a7,16(a5)
        SetPageProperty(remain);
ffffffffc0200820:	00236893          	ori	a7,t1,2
ffffffffc0200824:	0117b423          	sd	a7,8(a5)
        list_add(prev, &(remain->page_link));
ffffffffc0200828:	01878893          	addi	a7,a5,24
    prev->next = next->prev = elm;
ffffffffc020082c:	0115b023          	sd	a7,0(a1)
ffffffffc0200830:	01173423          	sd	a7,8(a4) # fffffffffff80008 <end+0x3fcd4964>
    elm->next = next;
ffffffffc0200834:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200836:	ef98                	sd	a4,24(a5)
    ClearPageProperty(candidate);
ffffffffc0200838:	651c                	ld	a5,8(a0)
    backend_nr_free -= n;
ffffffffc020083a:	40d806b3          	sub	a3,a6,a3
ffffffffc020083e:	ea14                	sd	a3,16(a2)
    ClearPageProperty(candidate);
ffffffffc0200840:	9bf5                	andi	a5,a5,-3
ffffffffc0200842:	e51c                	sd	a5,8(a0)
    return candidate;
ffffffffc0200844:	8082                	ret
}
ffffffffc0200846:	8082                	ret
        return NULL;
ffffffffc0200848:	4501                	li	a0,0
ffffffffc020084a:	8082                	ret
backend_alloc_pages(size_t n) {
ffffffffc020084c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020084e:	00001697          	auipc	a3,0x1
ffffffffc0200852:	37268693          	addi	a3,a3,882 # ffffffffc0201bc0 <etext+0x3aa>
ffffffffc0200856:	00001617          	auipc	a2,0x1
ffffffffc020085a:	37260613          	addi	a2,a2,882 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc020085e:	09900593          	li	a1,153
ffffffffc0200862:	00001517          	auipc	a0,0x1
ffffffffc0200866:	37e50513          	addi	a0,a0,894 # ffffffffc0201be0 <etext+0x3ca>
backend_alloc_pages(size_t n) {
ffffffffc020086a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020086c:	957ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200870 <page_to_slab.part.0>:
page_to_slab(struct Page *page) {
ffffffffc0200870:	1141                	addi	sp,sp,-16
    assert(idx < MAX_SLABS);
ffffffffc0200872:	00001697          	auipc	a3,0x1
ffffffffc0200876:	38668693          	addi	a3,a3,902 # ffffffffc0201bf8 <etext+0x3e2>
ffffffffc020087a:	00001617          	auipc	a2,0x1
ffffffffc020087e:	34e60613          	addi	a2,a2,846 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200882:	0f700593          	li	a1,247
ffffffffc0200886:	00001517          	auipc	a0,0x1
ffffffffc020088a:	35a50513          	addi	a0,a0,858 # ffffffffc0201be0 <etext+0x3ca>
page_to_slab(struct Page *page) {
ffffffffc020088e:	e406                	sd	ra,8(sp)
    assert(idx < MAX_SLABS);
ffffffffc0200890:	933ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200894 <backend_insert_block.part.0>:
    for (; p != base + n; ++p) {
ffffffffc0200894:	00259713          	slli	a4,a1,0x2
ffffffffc0200898:	972e                	add	a4,a4,a1
ffffffffc020089a:	070e                	slli	a4,a4,0x3
ffffffffc020089c:	972a                	add	a4,a4,a0
ffffffffc020089e:	87aa                	mv	a5,a0
ffffffffc02008a0:	00e50a63          	beq	a0,a4,ffffffffc02008b4 <backend_insert_block.part.0+0x20>
        p->flags = 0;
ffffffffc02008a4:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008a8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; ++p) {
ffffffffc02008ac:	02878793          	addi	a5,a5,40
ffffffffc02008b0:	fee79ae3          	bne	a5,a4,ffffffffc02008a4 <backend_insert_block.part.0+0x10>
    SetPageProperty(base);
ffffffffc02008b4:	00853883          	ld	a7,8(a0)
    backend_nr_free += n;
ffffffffc02008b8:	00005697          	auipc	a3,0x5
ffffffffc02008bc:	76068693          	addi	a3,a3,1888 # ffffffffc0206018 <backend_area>
ffffffffc02008c0:	6a98                	ld	a4,16(a3)
    base->property = n;
ffffffffc02008c2:	0005881b          	sext.w	a6,a1
    return list->next == list;
ffffffffc02008c6:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc02008c8:	0028e613          	ori	a2,a7,2
    backend_nr_free += n;
ffffffffc02008cc:	95ba                	add	a1,a1,a4
    base->property = n;
ffffffffc02008ce:	01052823          	sw	a6,16(a0)
    SetPageProperty(base);
ffffffffc02008d2:	e510                	sd	a2,8(a0)
    backend_nr_free += n;
ffffffffc02008d4:	ea8c                	sd	a1,16(a3)
        list_add(&backend_free_list, &(base->page_link));
ffffffffc02008d6:	01850593          	addi	a1,a0,24
    if (list_empty(&backend_free_list)) {
ffffffffc02008da:	0ad78463          	beq	a5,a3,ffffffffc0200982 <backend_insert_block.part.0+0xee>
        page = le2page(le, page_link);
ffffffffc02008de:	fe878713          	addi	a4,a5,-24
        if (base < page) {
ffffffffc02008e2:	04e56c63          	bltu	a0,a4,ffffffffc020093a <backend_insert_block.part.0+0xa6>
    return listelm->next;
ffffffffc02008e6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &backend_free_list) {
ffffffffc02008e8:	fed79be3          	bne	a5,a3,ffffffffc02008de <backend_insert_block.part.0+0x4a>
    return listelm->prev;
ffffffffc02008ec:	6390                	ld	a2,0(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008ee:	661c                	ld	a5,8(a2)
    prev->next = next->prev = elm;
ffffffffc02008f0:	e38c                	sd	a1,0(a5)
ffffffffc02008f2:	e60c                	sd	a1,8(a2)
    elm->next = next;
ffffffffc02008f4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02008f6:	ed10                	sd	a2,24(a0)
    if (prev != &backend_free_list) {
ffffffffc02008f8:	02d60063          	beq	a2,a3,ffffffffc0200918 <backend_insert_block.part.0+0x84>
        if (pp + pp->property == base) {
ffffffffc02008fc:	ff862303          	lw	t1,-8(a2)
        pp = le2page(prev, page_link);
ffffffffc0200900:	fe860e13          	addi	t3,a2,-24
        if (pp + pp->property == base) {
ffffffffc0200904:	02031593          	slli	a1,t1,0x20
ffffffffc0200908:	9181                	srli	a1,a1,0x20
ffffffffc020090a:	00259713          	slli	a4,a1,0x2
ffffffffc020090e:	972e                	add	a4,a4,a1
ffffffffc0200910:	070e                	slli	a4,a4,0x3
ffffffffc0200912:	9772                	add	a4,a4,t3
ffffffffc0200914:	04e50b63          	beq	a0,a4,ffffffffc020096a <backend_insert_block.part.0+0xd6>
    if (next != &backend_free_list) {
ffffffffc0200918:	02d78063          	beq	a5,a3,ffffffffc0200938 <backend_insert_block.part.0+0xa4>
        if (base + base->property == np) {
ffffffffc020091c:	01052803          	lw	a6,16(a0)
        np = le2page(next, page_link);
ffffffffc0200920:	fe878713          	addi	a4,a5,-24
        if (base + base->property == np) {
ffffffffc0200924:	02081613          	slli	a2,a6,0x20
ffffffffc0200928:	9201                	srli	a2,a2,0x20
ffffffffc020092a:	00261693          	slli	a3,a2,0x2
ffffffffc020092e:	96b2                	add	a3,a3,a2
ffffffffc0200930:	068e                	slli	a3,a3,0x3
ffffffffc0200932:	96aa                	add	a3,a3,a0
ffffffffc0200934:	00d70b63          	beq	a4,a3,ffffffffc020094a <backend_insert_block.part.0+0xb6>
}
ffffffffc0200938:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc020093a:	6390                	ld	a2,0(a5)
    prev->next = next->prev = elm;
ffffffffc020093c:	e38c                	sd	a1,0(a5)
ffffffffc020093e:	e60c                	sd	a1,8(a2)
    elm->next = next;
ffffffffc0200940:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200942:	ed10                	sd	a2,24(a0)
    if (prev != &backend_free_list) {
ffffffffc0200944:	fad61ce3          	bne	a2,a3,ffffffffc02008fc <backend_insert_block.part.0+0x68>
ffffffffc0200948:	bff1                	j	ffffffffc0200924 <backend_insert_block.part.0+0x90>
            base->property += np->property;
ffffffffc020094a:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(np);
ffffffffc020094e:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200952:	638c                	ld	a1,0(a5)
ffffffffc0200954:	6790                	ld	a2,8(a5)
            base->property += np->property;
ffffffffc0200956:	0106883b          	addw	a6,a3,a6
ffffffffc020095a:	01052823          	sw	a6,16(a0)
            ClearPageProperty(np);
ffffffffc020095e:	9b75                	andi	a4,a4,-3
ffffffffc0200960:	fee7b823          	sd	a4,-16(a5)
    prev->next = next;
ffffffffc0200964:	e590                	sd	a2,8(a1)
    next->prev = prev;
ffffffffc0200966:	e20c                	sd	a1,0(a2)
}
ffffffffc0200968:	8082                	ret
            pp->property += base->property;
ffffffffc020096a:	0068083b          	addw	a6,a6,t1
ffffffffc020096e:	ff062c23          	sw	a6,-8(a2)
            ClearPageProperty(base);
ffffffffc0200972:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200976:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc020097a:	e61c                	sd	a5,8(a2)
    next->prev = prev;
ffffffffc020097c:	e390                	sd	a2,0(a5)
            base = pp;
ffffffffc020097e:	8572                	mv	a0,t3
ffffffffc0200980:	bf61                	j	ffffffffc0200918 <backend_insert_block.part.0+0x84>
    prev->next = next->prev = elm;
ffffffffc0200982:	e38c                	sd	a1,0(a5)
ffffffffc0200984:	e78c                	sd	a1,8(a5)
    elm->next = next;
ffffffffc0200986:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200988:	ed1c                	sd	a5,24(a0)
        return;
ffffffffc020098a:	8082                	ret

ffffffffc020098c <backend_free_pages>:
backend_free_pages(struct Page *base, size_t n) {
ffffffffc020098c:	1141                	addi	sp,sp,-16
ffffffffc020098e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200990:	c5b9                	beqz	a1,ffffffffc02009de <backend_free_pages+0x52>
    for (; p != base + n; ++p) {
ffffffffc0200992:	00259693          	slli	a3,a1,0x2
ffffffffc0200996:	96ae                	add	a3,a3,a1
ffffffffc0200998:	068e                	slli	a3,a3,0x3
ffffffffc020099a:	96aa                	add	a3,a3,a0
ffffffffc020099c:	87aa                	mv	a5,a0
ffffffffc020099e:	00d50d63          	beq	a0,a3,ffffffffc02009b8 <backend_free_pages+0x2c>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02009a2:	6798                	ld	a4,8(a5)
ffffffffc02009a4:	8b0d                	andi	a4,a4,3
ffffffffc02009a6:	ef01                	bnez	a4,ffffffffc02009be <backend_free_pages+0x32>
        p->flags = 0;
ffffffffc02009a8:	0007b423          	sd	zero,8(a5)
ffffffffc02009ac:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; ++p) {
ffffffffc02009b0:	02878793          	addi	a5,a5,40
ffffffffc02009b4:	fef697e3          	bne	a3,a5,ffffffffc02009a2 <backend_free_pages+0x16>
}
ffffffffc02009b8:	60a2                	ld	ra,8(sp)
ffffffffc02009ba:	0141                	addi	sp,sp,16
ffffffffc02009bc:	bde1                	j	ffffffffc0200894 <backend_insert_block.part.0>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02009be:	00001697          	auipc	a3,0x1
ffffffffc02009c2:	24a68693          	addi	a3,a3,586 # ffffffffc0201c08 <etext+0x3f2>
ffffffffc02009c6:	00001617          	auipc	a2,0x1
ffffffffc02009ca:	20260613          	addi	a2,a2,514 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02009ce:	0c700593          	li	a1,199
ffffffffc02009d2:	00001517          	auipc	a0,0x1
ffffffffc02009d6:	20e50513          	addi	a0,a0,526 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02009da:	fe8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc02009de:	00001697          	auipc	a3,0x1
ffffffffc02009e2:	1e268693          	addi	a3,a3,482 # ffffffffc0201bc0 <etext+0x3aa>
ffffffffc02009e6:	00001617          	auipc	a2,0x1
ffffffffc02009ea:	1e260613          	addi	a2,a2,482 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02009ee:	0c300593          	li	a1,195
ffffffffc02009f2:	00001517          	auipc	a0,0x1
ffffffffc02009f6:	1ee50513          	addi	a0,a0,494 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02009fa:	fc8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02009fe <slub_init>:
slub_init(void) {
ffffffffc02009fe:	1141                	addi	sp,sp,-16
ffffffffc0200a00:	e022                	sd	s0,0(sp)
    if (slub_initialized) {
ffffffffc0200a02:	000ab417          	auipc	s0,0xab
ffffffffc0200a06:	c9e40413          	addi	s0,s0,-866 # ffffffffc02ab6a0 <slub_initialized>
ffffffffc0200a0a:	401c                	lw	a5,0(s0)
slub_init(void) {
ffffffffc0200a0c:	e406                	sd	ra,8(sp)
    if (slub_initialized) {
ffffffffc0200a0e:	ebbd                	bnez	a5,ffffffffc0200a84 <slub_init+0x86>
    elm->prev = elm->next = elm;
ffffffffc0200a10:	00005797          	auipc	a5,0x5
ffffffffc0200a14:	60878793          	addi	a5,a5,1544 # ffffffffc0206018 <backend_area>
    memset(slab_table, 0, sizeof(slab_table));
ffffffffc0200a18:	0005f637          	lui	a2,0x5f
ffffffffc0200a1c:	e79c                	sd	a5,8(a5)
ffffffffc0200a1e:	e39c                	sd	a5,0(a5)
ffffffffc0200a20:	80060613          	addi	a2,a2,-2048 # 5e800 <kern_entry-0xffffffffc01a1800>
ffffffffc0200a24:	4581                	li	a1,0
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	60a50513          	addi	a0,a0,1546 # ffffffffc0206030 <slab_table>
    backend_nr_free = 0;
ffffffffc0200a2e:	00005797          	auipc	a5,0x5
ffffffffc0200a32:	5e07bd23          	sd	zero,1530(a5) # ffffffffc0206028 <backend_area+0x10>
    memset(slab_table, 0, sizeof(slab_table));
ffffffffc0200a36:	5cf000ef          	jal	ra,ffffffffc0201804 <memset>
    memset(slub_page_next, 0, sizeof(slub_page_next));
ffffffffc0200a3a:	0003f637          	lui	a2,0x3f
ffffffffc0200a3e:	4581                	li	a1,0
ffffffffc0200a40:	00064517          	auipc	a0,0x64
ffffffffc0200a44:	e1850513          	addi	a0,a0,-488 # ffffffffc0264858 <slub_page_next>
ffffffffc0200a48:	5bd000ef          	jal	ra,ffffffffc0201804 <memset>
    memset(slub_page_state, 0, sizeof(slub_page_state));
ffffffffc0200a4c:	6621                	lui	a2,0x8
ffffffffc0200a4e:	e0060613          	addi	a2,a2,-512 # 7e00 <kern_entry-0xffffffffc01f8200>
ffffffffc0200a52:	4581                	li	a1,0
ffffffffc0200a54:	000a3517          	auipc	a0,0xa3
ffffffffc0200a58:	e0450513          	addi	a0,a0,-508 # ffffffffc02a3858 <slub_page_state>
ffffffffc0200a5c:	5a9000ef          	jal	ra,ffffffffc0201804 <memset>
ffffffffc0200a60:	00064797          	auipc	a5,0x64
ffffffffc0200a64:	dd078793          	addi	a5,a5,-560 # ffffffffc0264830 <slub_cache>
ffffffffc0200a68:	00064717          	auipc	a4,0x64
ffffffffc0200a6c:	dd870713          	addi	a4,a4,-552 # ffffffffc0264840 <slub_cache+0x10>
ffffffffc0200a70:	e79c                	sd	a5,8(a5)
ffffffffc0200a72:	e39c                	sd	a5,0(a5)
ffffffffc0200a74:	ef98                	sd	a4,24(a5)
ffffffffc0200a76:	eb98                	sd	a4,16(a5)
    slub_cache.free_objects_total = 0;
ffffffffc0200a78:	00064797          	auipc	a5,0x64
ffffffffc0200a7c:	dc07bc23          	sd	zero,-552(a5) # ffffffffc0264850 <slub_cache+0x20>
    slub_initialized = 1;
ffffffffc0200a80:	4785                	li	a5,1
ffffffffc0200a82:	c01c                	sw	a5,0(s0)
}
ffffffffc0200a84:	60a2                	ld	ra,8(sp)
ffffffffc0200a86:	6402                	ld	s0,0(sp)
ffffffffc0200a88:	0141                	addi	sp,sp,16
ffffffffc0200a8a:	8082                	ret

ffffffffc0200a8c <slub_free_pages>:
slub_free_pages(struct Page *base, size_t n) {
ffffffffc0200a8c:	1101                	addi	sp,sp,-32
ffffffffc0200a8e:	ec06                	sd	ra,24(sp)
ffffffffc0200a90:	e822                	sd	s0,16(sp)
ffffffffc0200a92:	e426                	sd	s1,8(sp)
ffffffffc0200a94:	e04a                	sd	s2,0(sp)
    assert(n > 0);
ffffffffc0200a96:	1c058363          	beqz	a1,ffffffffc0200c5c <slub_free_pages+0x1d0>
    if (n == SLUB_OBJECT_PAGES && slub_object_state(base) != SLUB_STATE_UNUSED) {
ffffffffc0200a9a:	4785                	li	a5,1
ffffffffc0200a9c:	02f59963          	bne	a1,a5,ffffffffc0200ace <slub_free_pages+0x42>
    return (size_t)(page - pages);
ffffffffc0200aa0:	000ab617          	auipc	a2,0xab
ffffffffc0200aa4:	bd863603          	ld	a2,-1064(a2) # ffffffffc02ab678 <pages>
ffffffffc0200aa8:	40c50733          	sub	a4,a0,a2
ffffffffc0200aac:	40375793          	srai	a5,a4,0x3
ffffffffc0200ab0:	00001897          	auipc	a7,0x1
ffffffffc0200ab4:	6008b883          	ld	a7,1536(a7) # ffffffffc02020b0 <error_string+0x38>
ffffffffc0200ab8:	031787b3          	mul	a5,a5,a7
    return slub_page_state[page_index(page)];
ffffffffc0200abc:	000a3817          	auipc	a6,0xa3
ffffffffc0200ac0:	d9c80813          	addi	a6,a6,-612 # ffffffffc02a3858 <slub_page_state>
ffffffffc0200ac4:	00f80333          	add	t1,a6,a5
    if (n == SLUB_OBJECT_PAGES && slub_object_state(base) != SLUB_STATE_UNUSED) {
ffffffffc0200ac8:	00034683          	lbu	a3,0(t1)
ffffffffc0200acc:	e699                	bnez	a3,ffffffffc0200ada <slub_free_pages+0x4e>
}
ffffffffc0200ace:	6442                	ld	s0,16(sp)
ffffffffc0200ad0:	60e2                	ld	ra,24(sp)
ffffffffc0200ad2:	64a2                	ld	s1,8(sp)
ffffffffc0200ad4:	6902                	ld	s2,0(sp)
ffffffffc0200ad6:	6105                	addi	sp,sp,32
    backend_free_pages(base, n);
ffffffffc0200ad8:	bd55                	j	ffffffffc020098c <backend_free_pages>
    assert(idx < MAX_SLABS);
ffffffffc0200ada:	0013b6b7          	lui	a3,0x13b
ffffffffc0200ade:	fd868693          	addi	a3,a3,-40 # 13afd8 <kern_entry-0xffffffffc00c5028>
    size_t idx = page_index(page) / SLUB_SLAB_PAGES;
ffffffffc0200ae2:	0027de93          	srli	t4,a5,0x2
    assert(idx < MAX_SLABS);
ffffffffc0200ae6:	18e6eb63          	bltu	a3,a4,ffffffffc0200c7c <slub_free_pages+0x1f0>
    return &slab_table[idx];
ffffffffc0200aea:	001e9f93          	slli	t6,t4,0x1
ffffffffc0200aee:	01df8433          	add	s0,t6,t4
ffffffffc0200af2:	0412                	slli	s0,s0,0x4
ffffffffc0200af4:	00005e17          	auipc	t3,0x5
ffffffffc0200af8:	53ce0e13          	addi	t3,t3,1340 # ffffffffc0206030 <slab_table>
ffffffffc0200afc:	008e0733          	add	a4,t3,s0
    assert(meta->base != NULL);
ffffffffc0200b00:	6314                	ld	a3,0(a4)
ffffffffc0200b02:	16068f63          	beqz	a3,ffffffffc0200c80 <slub_free_pages+0x1f4>
    slub_cache.free_objects_total++;
ffffffffc0200b06:	00064f17          	auipc	t5,0x64
ffffffffc0200b0a:	d2af0f13          	addi	t5,t5,-726 # ffffffffc0264830 <slub_cache>
    meta->free_objects++;
ffffffffc0200b0e:	4b14                	lw	a3,16(a4)
    slub_cache.free_objects_total++;
ffffffffc0200b10:	020f3383          	ld	t2,32(t5)
    slub_page_next[page_index(page)] = next;
ffffffffc0200b14:	00873903          	ld	s2,8(a4)
ffffffffc0200b18:	00064297          	auipc	t0,0x64
ffffffffc0200b1c:	d4028293          	addi	t0,t0,-704 # ffffffffc0264858 <slub_page_next>
ffffffffc0200b20:	078e                	slli	a5,a5,0x3
    if (meta->on_full) {
ffffffffc0200b22:	4f44                	lw	s1,28(a4)
    meta->free_objects++;
ffffffffc0200b24:	2685                	addiw	a3,a3,1
    slub_page_next[page_index(page)] = next;
ffffffffc0200b26:	9796                	add	a5,a5,t0
    slub_cache.free_objects_total++;
ffffffffc0200b28:	0385                	addi	t2,t2,1
    slub_page_next[page_index(page)] = next;
ffffffffc0200b2a:	0127b023          	sd	s2,0(a5)
    slub_page_state[page_index(page)] = state;
ffffffffc0200b2e:	00b30023          	sb	a1,0(t1)
    meta->freelist = page;
ffffffffc0200b32:	e708                	sd	a0,8(a4)
    meta->free_objects++;
ffffffffc0200b34:	cb14                	sw	a3,16(a4)
    slub_cache.free_objects_total++;
ffffffffc0200b36:	027f3023          	sd	t2,32(t5)
    page->flags = 0;
ffffffffc0200b3a:	00053423          	sd	zero,8(a0)
ffffffffc0200b3e:	00052023          	sw	zero,0(a0)
    meta->free_objects++;
ffffffffc0200b42:	0006879b          	sext.w	a5,a3
    if (meta->on_full) {
ffffffffc0200b46:	cc89                	beqz	s1,ffffffffc0200b60 <slub_free_pages+0xd4>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b48:	771c                	ld	a5,40(a4)
ffffffffc0200b4a:	730c                	ld	a1,32(a4)
        list_init(&(meta->link));
ffffffffc0200b4c:	02040693          	addi	a3,s0,32
ffffffffc0200b50:	96f2                	add	a3,a3,t3
    prev->next = next;
ffffffffc0200b52:	e59c                	sd	a5,8(a1)
    next->prev = prev;
ffffffffc0200b54:	e38c                	sd	a1,0(a5)
    if (meta->free_objects == 1) {
ffffffffc0200b56:	4b1c                	lw	a5,16(a4)
    elm->prev = elm->next = elm;
ffffffffc0200b58:	f714                	sd	a3,40(a4)
ffffffffc0200b5a:	f314                	sd	a3,32(a4)
        meta->on_full = 0;
ffffffffc0200b5c:	00072e23          	sw	zero,28(a4)
    if (meta->free_objects == 1) {
ffffffffc0200b60:	4685                	li	a3,1
ffffffffc0200b62:	00d78f63          	beq	a5,a3,ffffffffc0200b80 <slub_free_pages+0xf4>
    if (meta->free_objects == meta->total_objects) {
ffffffffc0200b66:	01df86b3          	add	a3,t6,t4
ffffffffc0200b6a:	0692                	slli	a3,a3,0x4
ffffffffc0200b6c:	96f2                	add	a3,a3,t3
ffffffffc0200b6e:	4acc                	lw	a1,20(a3)
ffffffffc0200b70:	02f58c63          	beq	a1,a5,ffffffffc0200ba8 <slub_free_pages+0x11c>
}
ffffffffc0200b74:	60e2                	ld	ra,24(sp)
ffffffffc0200b76:	6442                	ld	s0,16(sp)
ffffffffc0200b78:	64a2                	ld	s1,8(sp)
ffffffffc0200b7a:	6902                	ld	s2,0(sp)
ffffffffc0200b7c:	6105                	addi	sp,sp,32
ffffffffc0200b7e:	8082                	ret
    if (!meta->on_partial) {
ffffffffc0200b80:	01df86b3          	add	a3,t6,t4
ffffffffc0200b84:	0692                	slli	a3,a3,0x4
ffffffffc0200b86:	96f2                	add	a3,a3,t3
ffffffffc0200b88:	4e8c                	lw	a1,24(a3)
ffffffffc0200b8a:	fdf1                	bnez	a1,ffffffffc0200b66 <slub_free_pages+0xda>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b8c:	008f3503          	ld	a0,8(t5)
        list_add(&slub_cache.partial, &(meta->link));
ffffffffc0200b90:	02040593          	addi	a1,s0,32
ffffffffc0200b94:	95f2                	add	a1,a1,t3
    prev->next = next->prev = elm;
ffffffffc0200b96:	e10c                	sd	a1,0(a0)
    elm->next = next;
ffffffffc0200b98:	f708                	sd	a0,40(a4)
    elm->prev = prev;
ffffffffc0200b9a:	03e73023          	sd	t5,32(a4)
        meta->on_partial = 1;
ffffffffc0200b9e:	ce9c                	sw	a5,24(a3)
    prev->next = next->prev = elm;
ffffffffc0200ba0:	00bf3423          	sd	a1,8(t5)
    if (meta->free_objects == meta->total_objects) {
ffffffffc0200ba4:	4a9c                	lw	a5,16(a3)
}
ffffffffc0200ba6:	b7c1                	j	ffffffffc0200b66 <slub_free_pages+0xda>
    assert(meta->base != NULL);
ffffffffc0200ba8:	629c                	ld	a5,0(a3)
ffffffffc0200baa:	0e078b63          	beqz	a5,ffffffffc0200ca0 <slub_free_pages+0x214>
    if (meta->on_partial) {
ffffffffc0200bae:	4e9c                	lw	a5,24(a3)
ffffffffc0200bb0:	cf81                	beqz	a5,ffffffffc0200bc8 <slub_free_pages+0x13c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bb2:	7308                	ld	a0,32(a4)
ffffffffc0200bb4:	770c                	ld	a1,40(a4)
        list_init(&(meta->link));
ffffffffc0200bb6:	02040793          	addi	a5,s0,32
ffffffffc0200bba:	97f2                	add	a5,a5,t3
    prev->next = next;
ffffffffc0200bbc:	e50c                	sd	a1,8(a0)
    next->prev = prev;
ffffffffc0200bbe:	e188                	sd	a0,0(a1)
        meta->on_partial = 0;
ffffffffc0200bc0:	0006ac23          	sw	zero,24(a3)
    elm->prev = elm->next = elm;
ffffffffc0200bc4:	f71c                	sd	a5,40(a4)
ffffffffc0200bc6:	f31c                	sd	a5,32(a4)
    if (meta->on_full) {
ffffffffc0200bc8:	01df87b3          	add	a5,t6,t4
ffffffffc0200bcc:	0792                	slli	a5,a5,0x4
ffffffffc0200bce:	97f2                	add	a5,a5,t3
ffffffffc0200bd0:	4fd4                	lw	a3,28(a5)
ffffffffc0200bd2:	ce81                	beqz	a3,ffffffffc0200bea <slub_free_pages+0x15e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bd4:	730c                	ld	a1,32(a4)
ffffffffc0200bd6:	7714                	ld	a3,40(a4)
        list_init(&(meta->link));
ffffffffc0200bd8:	02040413          	addi	s0,s0,32
ffffffffc0200bdc:	9472                	add	s0,s0,t3
    prev->next = next;
ffffffffc0200bde:	e594                	sd	a3,8(a1)
    next->prev = prev;
ffffffffc0200be0:	e28c                	sd	a1,0(a3)
    elm->prev = elm->next = elm;
ffffffffc0200be2:	f700                	sd	s0,40(a4)
ffffffffc0200be4:	f300                	sd	s0,32(a4)
        meta->on_full = 0;
ffffffffc0200be6:	0007ae23          	sw	zero,28(a5)
    for (unsigned int i = 0; i < meta->total_objects; ++i) {
ffffffffc0200bea:	01df87b3          	add	a5,t6,t4
ffffffffc0200bee:	0792                	slli	a5,a5,0x4
ffffffffc0200bf0:	97f2                	add	a5,a5,t3
ffffffffc0200bf2:	4bcc                	lw	a1,20(a5)
    struct Page *base = meta->base;
ffffffffc0200bf4:	6388                	ld	a0,0(a5)
    for (unsigned int i = 0; i < meta->total_objects; ++i) {
ffffffffc0200bf6:	c1ad                	beqz	a1,ffffffffc0200c58 <slub_free_pages+0x1cc>
ffffffffc0200bf8:	fff5879b          	addiw	a5,a1,-1
ffffffffc0200bfc:	1782                	slli	a5,a5,0x20
ffffffffc0200bfe:	9381                	srli	a5,a5,0x20
ffffffffc0200c00:	00279313          	slli	t1,a5,0x2
ffffffffc0200c04:	933e                	add	t1,t1,a5
ffffffffc0200c06:	00331793          	slli	a5,t1,0x3
ffffffffc0200c0a:	02850313          	addi	t1,a0,40
ffffffffc0200c0e:	872a                	mv	a4,a0
ffffffffc0200c10:	933e                	add	t1,t1,a5
    return (size_t)(page - pages);
ffffffffc0200c12:	40c707b3          	sub	a5,a4,a2
ffffffffc0200c16:	878d                	srai	a5,a5,0x3
ffffffffc0200c18:	031787b3          	mul	a5,a5,a7
    for (unsigned int i = 0; i < meta->total_objects; ++i) {
ffffffffc0200c1c:	02870713          	addi	a4,a4,40
    slub_page_next[page_index(page)] = next;
ffffffffc0200c20:	00379693          	slli	a3,a5,0x3
ffffffffc0200c24:	9696                	add	a3,a3,t0
    slub_page_state[page_index(page)] = state;
ffffffffc0200c26:	97c2                	add	a5,a5,a6
ffffffffc0200c28:	00078023          	sb	zero,0(a5)
    slub_page_next[page_index(page)] = next;
ffffffffc0200c2c:	0006b023          	sd	zero,0(a3)
    for (unsigned int i = 0; i < meta->total_objects; ++i) {
ffffffffc0200c30:	fee311e3          	bne	t1,a4,ffffffffc0200c12 <slub_free_pages+0x186>
    size_t pages = meta->total_objects * SLUB_OBJECT_PAGES;
ffffffffc0200c34:	1582                	slli	a1,a1,0x20
ffffffffc0200c36:	9181                	srli	a1,a1,0x20
    slub_cache.free_objects_total -= meta->total_objects;
ffffffffc0200c38:	40b383b3          	sub	t2,t2,a1
    meta->base = NULL;
ffffffffc0200c3c:	9efe                	add	t4,t4,t6
ffffffffc0200c3e:	0e92                	slli	t4,t4,0x4
ffffffffc0200c40:	9e76                	add	t3,t3,t4
    slub_cache.free_objects_total -= meta->total_objects;
ffffffffc0200c42:	027f3023          	sd	t2,32(t5)
    meta->base = NULL;
ffffffffc0200c46:	000e3023          	sd	zero,0(t3)
    meta->freelist = NULL;
ffffffffc0200c4a:	000e3423          	sd	zero,8(t3)
    meta->free_objects = 0;
ffffffffc0200c4e:	000e3823          	sd	zero,16(t3)
    meta->on_full = 0;
ffffffffc0200c52:	000e2e23          	sw	zero,28(t3)
    backend_free_pages(base, pages);
ffffffffc0200c56:	bda5                	j	ffffffffc0200ace <slub_free_pages+0x42>
    for (unsigned int i = 0; i < meta->total_objects; ++i) {
ffffffffc0200c58:	4581                	li	a1,0
ffffffffc0200c5a:	b7cd                	j	ffffffffc0200c3c <slub_free_pages+0x1b0>
    assert(n > 0);
ffffffffc0200c5c:	00001697          	auipc	a3,0x1
ffffffffc0200c60:	f6468693          	addi	a3,a3,-156 # ffffffffc0201bc0 <etext+0x3aa>
ffffffffc0200c64:	00001617          	auipc	a2,0x1
ffffffffc0200c68:	f6460613          	addi	a2,a2,-156 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200c6c:	1df00593          	li	a1,479
ffffffffc0200c70:	00001517          	auipc	a0,0x1
ffffffffc0200c74:	f7050513          	addi	a0,a0,-144 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc0200c78:	d4aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc0200c7c:	bf5ff0ef          	jal	ra,ffffffffc0200870 <page_to_slab.part.0>
    assert(meta->base != NULL);
ffffffffc0200c80:	00001697          	auipc	a3,0x1
ffffffffc0200c84:	fb068693          	addi	a3,a3,-80 # ffffffffc0201c30 <etext+0x41a>
ffffffffc0200c88:	00001617          	auipc	a2,0x1
ffffffffc0200c8c:	f4060613          	addi	a2,a2,-192 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200c90:	1d400593          	li	a1,468
ffffffffc0200c94:	00001517          	auipc	a0,0x1
ffffffffc0200c98:	f4c50513          	addi	a0,a0,-180 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc0200c9c:	d26ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta->base != NULL);
ffffffffc0200ca0:	00001697          	auipc	a3,0x1
ffffffffc0200ca4:	f9068693          	addi	a3,a3,-112 # ffffffffc0201c30 <etext+0x41a>
ffffffffc0200ca8:	00001617          	auipc	a2,0x1
ffffffffc0200cac:	f2060613          	addi	a2,a2,-224 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200cb0:	14f00593          	li	a1,335
ffffffffc0200cb4:	00001517          	auipc	a0,0x1
ffffffffc0200cb8:	f2c50513          	addi	a0,a0,-212 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc0200cbc:	d06ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200cc0 <slub_init_memmap>:
slub_init_memmap(struct Page *base, size_t n) {
ffffffffc0200cc0:	1141                	addi	sp,sp,-16
ffffffffc0200cc2:	e406                	sd	ra,8(sp)
    assert(slub_initialized);
ffffffffc0200cc4:	000ab717          	auipc	a4,0xab
ffffffffc0200cc8:	9dc72703          	lw	a4,-1572(a4) # ffffffffc02ab6a0 <slub_initialized>
ffffffffc0200ccc:	c709                	beqz	a4,ffffffffc0200cd6 <slub_init_memmap+0x16>
    assert(n > 0);
ffffffffc0200cce:	c585                	beqz	a1,ffffffffc0200cf6 <slub_init_memmap+0x36>
}
ffffffffc0200cd0:	60a2                	ld	ra,8(sp)
ffffffffc0200cd2:	0141                	addi	sp,sp,16
ffffffffc0200cd4:	b6c1                	j	ffffffffc0200894 <backend_insert_block.part.0>
    assert(slub_initialized);
ffffffffc0200cd6:	00001697          	auipc	a3,0x1
ffffffffc0200cda:	f7268693          	addi	a3,a3,-142 # ffffffffc0201c48 <etext+0x432>
ffffffffc0200cde:	00001617          	auipc	a2,0x1
ffffffffc0200ce2:	eea60613          	addi	a2,a2,-278 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200ce6:	1b000593          	li	a1,432
ffffffffc0200cea:	00001517          	auipc	a0,0x1
ffffffffc0200cee:	ef650513          	addi	a0,a0,-266 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc0200cf2:	cd0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200cf6:	00001697          	auipc	a3,0x1
ffffffffc0200cfa:	eca68693          	addi	a3,a3,-310 # ffffffffc0201bc0 <etext+0x3aa>
ffffffffc0200cfe:	00001617          	auipc	a2,0x1
ffffffffc0200d02:	eca60613          	addi	a2,a2,-310 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200d06:	05100593          	li	a1,81
ffffffffc0200d0a:	00001517          	auipc	a0,0x1
ffffffffc0200d0e:	ed650513          	addi	a0,a0,-298 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc0200d12:	cb0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d16 <slub_alloc_small>:
slub_alloc_small(void) {
ffffffffc0200d16:	1141                	addi	sp,sp,-16
ffffffffc0200d18:	e022                	sd	s0,0(sp)
    return list->next == list;
ffffffffc0200d1a:	00064417          	auipc	s0,0x64
ffffffffc0200d1e:	b1640413          	addi	s0,s0,-1258 # ffffffffc0264830 <slub_cache>
ffffffffc0200d22:	641c                	ld	a5,8(s0)
ffffffffc0200d24:	e406                	sd	ra,8(sp)
    if (list_empty(&slub_cache.partial)) {
ffffffffc0200d26:	0a878163          	beq	a5,s0,ffffffffc0200dc8 <slub_alloc_small+0xb2>
    assert(meta->freelist != NULL);
ffffffffc0200d2a:	fe87b503          	ld	a0,-24(a5)
ffffffffc0200d2e:	18050663          	beqz	a0,ffffffffc0200eba <slub_alloc_small+0x1a4>
    return (size_t)(page - pages);
ffffffffc0200d32:	000ab717          	auipc	a4,0xab
ffffffffc0200d36:	94673703          	ld	a4,-1722(a4) # ffffffffc02ab678 <pages>
ffffffffc0200d3a:	40e50733          	sub	a4,a0,a4
ffffffffc0200d3e:	00001697          	auipc	a3,0x1
ffffffffc0200d42:	3726b683          	ld	a3,882(a3) # ffffffffc02020b0 <error_string+0x38>
ffffffffc0200d46:	870d                	srai	a4,a4,0x3
ffffffffc0200d48:	02d70733          	mul	a4,a4,a3
    return slub_page_next[page_index(page)];
ffffffffc0200d4c:	00064697          	auipc	a3,0x64
ffffffffc0200d50:	b0c68693          	addi	a3,a3,-1268 # ffffffffc0264858 <slub_page_next>
    meta->free_objects--;
ffffffffc0200d54:	ff07a803          	lw	a6,-16(a5)
    slub_cache.free_objects_total--;
ffffffffc0200d58:	7010                	ld	a2,32(s0)
    meta->free_objects--;
ffffffffc0200d5a:	387d                	addiw	a6,a6,-1
    slub_cache.free_objects_total--;
ffffffffc0200d5c:	167d                	addi	a2,a2,-1
    return slub_page_next[page_index(page)];
ffffffffc0200d5e:	00371593          	slli	a1,a4,0x3
ffffffffc0200d62:	96ae                	add	a3,a3,a1
ffffffffc0200d64:	0006b883          	ld	a7,0(a3)
    slub_page_state[page_index(page)] = state;
ffffffffc0200d68:	000a3597          	auipc	a1,0xa3
ffffffffc0200d6c:	af058593          	addi	a1,a1,-1296 # ffffffffc02a3858 <slub_page_state>
    meta->free_objects--;
ffffffffc0200d70:	ff07a823          	sw	a6,-16(a5)
    slub_page_state[page_index(page)] = state;
ffffffffc0200d74:	972e                	add	a4,a4,a1
    meta->freelist = next;
ffffffffc0200d76:	ff17b423          	sd	a7,-24(a5)
    slub_page_state[page_index(page)] = state;
ffffffffc0200d7a:	4589                	li	a1,2
ffffffffc0200d7c:	00b70023          	sb	a1,0(a4)
    if (meta->free_objects == 0) {
ffffffffc0200d80:	ff07a703          	lw	a4,-16(a5)
    slub_cache.free_objects_total--;
ffffffffc0200d84:	f010                	sd	a2,32(s0)
    slub_page_next[page_index(page)] = next;
ffffffffc0200d86:	0006b023          	sd	zero,0(a3)
    if (meta->free_objects == 0) {
ffffffffc0200d8a:	cb01                	beqz	a4,ffffffffc0200d9a <slub_alloc_small+0x84>
    ClearPageProperty(page);
ffffffffc0200d8c:	651c                	ld	a5,8(a0)
ffffffffc0200d8e:	9bf5                	andi	a5,a5,-3
ffffffffc0200d90:	e51c                	sd	a5,8(a0)
}
ffffffffc0200d92:	60a2                	ld	ra,8(sp)
ffffffffc0200d94:	6402                	ld	s0,0(sp)
ffffffffc0200d96:	0141                	addi	sp,sp,16
ffffffffc0200d98:	8082                	ret
    if (meta->on_partial) {
ffffffffc0200d9a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d9e:	cb01                	beqz	a4,ffffffffc0200dae <slub_alloc_small+0x98>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200da0:	6798                	ld	a4,8(a5)
ffffffffc0200da2:	6394                	ld	a3,0(a5)
    prev->next = next;
ffffffffc0200da4:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200da6:	e314                	sd	a3,0(a4)
        meta->on_partial = 0;
ffffffffc0200da8:	fe07ac23          	sw	zero,-8(a5)
    elm->prev = elm->next = elm;
ffffffffc0200dac:	e79c                	sd	a5,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200dae:	6c18                	ld	a4,24(s0)
    prev->next = next->prev = elm;
ffffffffc0200db0:	e31c                	sd	a5,0(a4)
ffffffffc0200db2:	ec1c                	sd	a5,24(s0)
    elm->next = next;
ffffffffc0200db4:	e798                	sd	a4,8(a5)
    elm->prev = prev;
ffffffffc0200db6:	00064717          	auipc	a4,0x64
ffffffffc0200dba:	a8a70713          	addi	a4,a4,-1398 # ffffffffc0264840 <slub_cache+0x10>
ffffffffc0200dbe:	e398                	sd	a4,0(a5)
    meta->on_full = 1;
ffffffffc0200dc0:	4705                	li	a4,1
ffffffffc0200dc2:	fee7ae23          	sw	a4,-4(a5)
}
ffffffffc0200dc6:	b7d9                	j	ffffffffc0200d8c <slub_alloc_small+0x76>
        struct Page *slab_base = backend_alloc_pages(SLUB_SLAB_PAGES);
ffffffffc0200dc8:	4511                	li	a0,4
ffffffffc0200dca:	9f1ff0ef          	jal	ra,ffffffffc02007ba <backend_alloc_pages>
        if (slab_base == NULL) {
ffffffffc0200dce:	d171                	beqz	a0,ffffffffc0200d92 <slub_alloc_small+0x7c>
    return (size_t)(page - pages);
ffffffffc0200dd0:	000ab597          	auipc	a1,0xab
ffffffffc0200dd4:	8a85b583          	ld	a1,-1880(a1) # ffffffffc02ab678 <pages>
ffffffffc0200dd8:	40b50733          	sub	a4,a0,a1
ffffffffc0200ddc:	40375813          	srai	a6,a4,0x3
ffffffffc0200de0:	00001397          	auipc	t2,0x1
ffffffffc0200de4:	2d03b383          	ld	t2,720(t2) # ffffffffc02020b0 <error_string+0x38>
ffffffffc0200de8:	02780833          	mul	a6,a6,t2
    assert(idx < MAX_SLABS);
ffffffffc0200dec:	0013b7b7          	lui	a5,0x13b
ffffffffc0200df0:	fd878793          	addi	a5,a5,-40 # 13afd8 <kern_entry-0xffffffffc00c5028>
    size_t idx = page_index(page) / SLUB_SLAB_PAGES;
ffffffffc0200df4:	00285813          	srli	a6,a6,0x2
    assert(idx < MAX_SLABS);
ffffffffc0200df8:	0ee7e163          	bltu	a5,a4,ffffffffc0200eda <slub_alloc_small+0x1c4>
    return &slab_table[idx];
ffffffffc0200dfc:	00181f13          	slli	t5,a6,0x1
ffffffffc0200e00:	010f0733          	add	a4,t5,a6
ffffffffc0200e04:	0712                	slli	a4,a4,0x4
    meta->free_objects = SLUB_OBJECTS_PER_SLAB;
ffffffffc0200e06:	4791                	li	a5,4
    return &slab_table[idx];
ffffffffc0200e08:	00005f97          	auipc	t6,0x5
ffffffffc0200e0c:	228f8f93          	addi	t6,t6,552 # ffffffffc0206030 <slab_table>
    list_init(&(meta->link));
ffffffffc0200e10:	02070e93          	addi	t4,a4,32
    meta->free_objects = SLUB_OBJECTS_PER_SLAB;
ffffffffc0200e14:	1782                	slli	a5,a5,0x20
    return &slab_table[idx];
ffffffffc0200e16:	977e                	add	a4,a4,t6
    list_init(&(meta->link));
ffffffffc0200e18:	9efe                	add	t4,t4,t6
    meta->free_objects = SLUB_OBJECTS_PER_SLAB;
ffffffffc0200e1a:	0791                	addi	a5,a5,4
    meta->base = base;
ffffffffc0200e1c:	e308                	sd	a0,0(a4)
    meta->freelist = base;
ffffffffc0200e1e:	e708                	sd	a0,8(a4)
    meta->free_objects = SLUB_OBJECTS_PER_SLAB;
ffffffffc0200e20:	eb1c                	sd	a5,16(a4)
    meta->on_partial = 0;
ffffffffc0200e22:	00073c23          	sd	zero,24(a4)
    elm->prev = elm->next = elm;
ffffffffc0200e26:	03d73423          	sd	t4,40(a4)
ffffffffc0200e2a:	03d73023          	sd	t4,32(a4)
        struct Page *next = (i + 1 < SLUB_OBJECTS_PER_SLAB)
ffffffffc0200e2e:	07850893          	addi	a7,a0,120
ffffffffc0200e32:	00064e17          	auipc	t3,0x64
ffffffffc0200e36:	a26e0e13          	addi	t3,t3,-1498 # ffffffffc0264858 <slub_page_next>
ffffffffc0200e3a:	000a3317          	auipc	t1,0xa3
ffffffffc0200e3e:	a1e30313          	addi	t1,t1,-1506 # ffffffffc02a3858 <slub_page_state>
    slub_page_state[page_index(page)] = state;
ffffffffc0200e42:	4285                	li	t0,1
    return (size_t)(page - pages);
ffffffffc0200e44:	40b507b3          	sub	a5,a0,a1
ffffffffc0200e48:	878d                	srai	a5,a5,0x3
ffffffffc0200e4a:	027787b3          	mul	a5,a5,t2
ffffffffc0200e4e:	86aa                	mv	a3,a0
ffffffffc0200e50:	02850513          	addi	a0,a0,40
    slub_page_next[page_index(page)] = next;
ffffffffc0200e54:	00379613          	slli	a2,a5,0x3
ffffffffc0200e58:	9672                	add	a2,a2,t3
    slub_page_state[page_index(page)] = state;
ffffffffc0200e5a:	979a                	add	a5,a5,t1
    slub_page_next[page_index(page)] = next;
ffffffffc0200e5c:	e208                	sd	a0,0(a2)
    slub_page_state[page_index(page)] = state;
ffffffffc0200e5e:	00578023          	sb	t0,0(a5)
        page->flags = 0;
ffffffffc0200e62:	0006b423          	sd	zero,8(a3)
ffffffffc0200e66:	0006a023          	sw	zero,0(a3)
                                : NULL;
ffffffffc0200e6a:	fca89de3          	bne	a7,a0,ffffffffc0200e44 <slub_alloc_small+0x12e>
    return (size_t)(page - pages);
ffffffffc0200e6e:	40b885b3          	sub	a1,a7,a1
ffffffffc0200e72:	858d                	srai	a1,a1,0x3
ffffffffc0200e74:	027585b3          	mul	a1,a1,t2
    if (!meta->on_partial) {
ffffffffc0200e78:	987a                	add	a6,a6,t5
    slub_cache.free_objects_total += SLUB_OBJECTS_PER_SLAB;
ffffffffc0200e7a:	7014                	ld	a3,32(s0)
    if (!meta->on_partial) {
ffffffffc0200e7c:	0812                	slli	a6,a6,0x4
ffffffffc0200e7e:	987e                	add	a6,a6,t6
ffffffffc0200e80:	01882603          	lw	a2,24(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e84:	641c                	ld	a5,8(s0)
    slub_cache.free_objects_total += SLUB_OBJECTS_PER_SLAB;
ffffffffc0200e86:	0691                	addi	a3,a3,4
    slub_page_next[page_index(page)] = next;
ffffffffc0200e88:	00359513          	slli	a0,a1,0x3
ffffffffc0200e8c:	9e2a                	add	t3,t3,a0
    slub_page_state[page_index(page)] = state;
ffffffffc0200e8e:	959a                	add	a1,a1,t1
    slub_page_next[page_index(page)] = next;
ffffffffc0200e90:	000e3023          	sd	zero,0(t3)
    slub_page_state[page_index(page)] = state;
ffffffffc0200e94:	00558023          	sb	t0,0(a1)
        page->flags = 0;
ffffffffc0200e98:	0008b423          	sd	zero,8(a7)
ffffffffc0200e9c:	0008a023          	sw	zero,0(a7)
    slub_cache.free_objects_total += SLUB_OBJECTS_PER_SLAB;
ffffffffc0200ea0:	f014                	sd	a3,32(s0)
    if (!meta->on_partial) {
ffffffffc0200ea2:	e80614e3          	bnez	a2,ffffffffc0200d2a <slub_alloc_small+0x14>
    prev->next = next->prev = elm;
ffffffffc0200ea6:	01d7b023          	sd	t4,0(a5)
    elm->next = next;
ffffffffc0200eaa:	f71c                	sd	a5,40(a4)
    elm->prev = prev;
ffffffffc0200eac:	f300                	sd	s0,32(a4)
    prev->next = next->prev = elm;
ffffffffc0200eae:	01d43423          	sd	t4,8(s0)
        meta->on_partial = 1;
ffffffffc0200eb2:	00582c23          	sw	t0,24(a6)
}
ffffffffc0200eb6:	87f6                	mv	a5,t4
ffffffffc0200eb8:	bd8d                	j	ffffffffc0200d2a <slub_alloc_small+0x14>
    assert(meta->freelist != NULL);
ffffffffc0200eba:	00001697          	auipc	a3,0x1
ffffffffc0200ebe:	da668693          	addi	a3,a3,-602 # ffffffffc0201c60 <etext+0x44a>
ffffffffc0200ec2:	00001617          	auipc	a2,0x1
ffffffffc0200ec6:	d0660613          	addi	a2,a2,-762 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200eca:	16900593          	li	a1,361
ffffffffc0200ece:	00001517          	auipc	a0,0x1
ffffffffc0200ed2:	d1250513          	addi	a0,a0,-750 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc0200ed6:	aecff0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc0200eda:	997ff0ef          	jal	ra,ffffffffc0200870 <page_to_slab.part.0>

ffffffffc0200ede <slub_alloc_pages>:
    assert(n > 0);
ffffffffc0200ede:	c519                	beqz	a0,ffffffffc0200eec <slub_alloc_pages+0xe>
    if (n == SLUB_OBJECT_PAGES) {
ffffffffc0200ee0:	4705                	li	a4,1
ffffffffc0200ee2:	00e50463          	beq	a0,a4,ffffffffc0200eea <slub_alloc_pages+0xc>
    struct Page *page = backend_alloc_pages(n);
ffffffffc0200ee6:	8d5ff06f          	j	ffffffffc02007ba <backend_alloc_pages>
        return slub_alloc_small();
ffffffffc0200eea:	b535                	j	ffffffffc0200d16 <slub_alloc_small>
slub_alloc_pages(size_t n) {
ffffffffc0200eec:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200eee:	00001697          	auipc	a3,0x1
ffffffffc0200ef2:	cd268693          	addi	a3,a3,-814 # ffffffffc0201bc0 <etext+0x3aa>
ffffffffc0200ef6:	00001617          	auipc	a2,0x1
ffffffffc0200efa:	cd260613          	addi	a2,a2,-814 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0200efe:	1ca00593          	li	a1,458
ffffffffc0200f02:	00001517          	auipc	a0,0x1
ffffffffc0200f06:	cde50513          	addi	a0,a0,-802 # ffffffffc0201be0 <etext+0x3ca>
slub_alloc_pages(size_t n) {
ffffffffc0200f0a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f0c:	ab6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200f10 <slub_check>:
        slub_free_pages(pages_local[i], 1);
    }
}

static void
slub_check(void) {
ffffffffc0200f10:	7119                	addi	sp,sp,-128
ffffffffc0200f12:	f8a2                	sd	s0,112(sp)
ffffffffc0200f14:	f4a6                	sd	s1,104(sp)
ffffffffc0200f16:	0100                	addi	s0,sp,128
ffffffffc0200f18:	f0ca                	sd	s2,96(sp)
ffffffffc0200f1a:	ecce                	sd	s3,88(sp)
ffffffffc0200f1c:	e8d2                	sd	s4,80(sp)
ffffffffc0200f1e:	e4d6                	sd	s5,72(sp)
ffffffffc0200f20:	e0da                	sd	s6,64(sp)
ffffffffc0200f22:	fc5e                	sd	s7,56(sp)
ffffffffc0200f24:	fc86                	sd	ra,120(sp)
ffffffffc0200f26:	f862                	sd	s8,48(sp)
ffffffffc0200f28:	f466                	sd	s9,40(sp)
ffffffffc0200f2a:	f06a                	sd	s10,32(sp)
ffffffffc0200f2c:	f8040493          	addi	s1,s0,-128
ffffffffc0200f30:	fa040a13          	addi	s4,s0,-96
ffffffffc0200f34:	8ba6                	mv	s7,s1
    return slub_page_state[page_index(page)];
ffffffffc0200f36:	000a3a97          	auipc	s5,0xa3
ffffffffc0200f3a:	922a8a93          	addi	s5,s5,-1758 # ffffffffc02a3858 <slub_page_state>
    return (size_t)(page - pages);
ffffffffc0200f3e:	000aa997          	auipc	s3,0xaa
ffffffffc0200f42:	73a98993          	addi	s3,s3,1850 # ffffffffc02ab678 <pages>
ffffffffc0200f46:	00001917          	auipc	s2,0x1
ffffffffc0200f4a:	16a93903          	ld	s2,362(s2) # ffffffffc02020b0 <error_string+0x38>
        assert(slub_object_state(p) == SLUB_STATE_ALLOCATED);
ffffffffc0200f4e:	4b09                	li	s6,2
        return slub_alloc_small();
ffffffffc0200f50:	dc7ff0ef          	jal	ra,ffffffffc0200d16 <slub_alloc_small>
        assert(p != NULL);
ffffffffc0200f54:	26050763          	beqz	a0,ffffffffc02011c2 <slub_check+0x2b2>
    return (size_t)(page - pages);
ffffffffc0200f58:	0009b783          	ld	a5,0(s3)
        pages_buf[i] = p;
ffffffffc0200f5c:	00abb023          	sd	a0,0(s7)
    return (size_t)(page - pages);
ffffffffc0200f60:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f64:	878d                	srai	a5,a5,0x3
ffffffffc0200f66:	032787b3          	mul	a5,a5,s2
    return slub_page_state[page_index(page)];
ffffffffc0200f6a:	97d6                	add	a5,a5,s5
        assert(slub_object_state(p) == SLUB_STATE_ALLOCATED);
ffffffffc0200f6c:	0007c783          	lbu	a5,0(a5)
ffffffffc0200f70:	23679963          	bne	a5,s6,ffffffffc02011a2 <slub_check+0x292>
    for (unsigned int i = 0; i < SLUB_OBJECTS_PER_SLAB; ++i) {
ffffffffc0200f74:	0ba1                	addi	s7,s7,8
ffffffffc0200f76:	fd4b9de3          	bne	s7,s4,ffffffffc0200f50 <slub_check+0x40>
        return slub_alloc_small();
ffffffffc0200f7a:	d9dff0ef          	jal	ra,ffffffffc0200d16 <slub_alloc_small>
ffffffffc0200f7e:	8c2a                	mv	s8,a0
    assert(p_extra != NULL);
ffffffffc0200f80:	28050163          	beqz	a0,ffffffffc0201202 <slub_check+0x2f2>
    struct slub_slab_meta *meta0 = page_to_slab(pages_buf[0]);
ffffffffc0200f84:	f8043d03          	ld	s10,-128(s0)
    return (size_t)(page - pages);
ffffffffc0200f88:	0009b703          	ld	a4,0(s3)
    assert(idx < MAX_SLABS);
ffffffffc0200f8c:	0013b6b7          	lui	a3,0x13b
ffffffffc0200f90:	fd868693          	addi	a3,a3,-40 # 13afd8 <kern_entry-0xffffffffc00c5028>
    return (size_t)(page - pages);
ffffffffc0200f94:	40ed07b3          	sub	a5,s10,a4
ffffffffc0200f98:	4037db93          	srai	s7,a5,0x3
ffffffffc0200f9c:	032b8bb3          	mul	s7,s7,s2
    size_t idx = page_index(page) / SLUB_SLAB_PAGES;
ffffffffc0200fa0:	002bdb93          	srli	s7,s7,0x2
    assert(idx < MAX_SLABS);
ffffffffc0200fa4:	1ef6ed63          	bltu	a3,a5,ffffffffc020119e <slub_check+0x28e>
    return (size_t)(page - pages);
ffffffffc0200fa8:	40e50733          	sub	a4,a0,a4
ffffffffc0200fac:	40375793          	srai	a5,a4,0x3
ffffffffc0200fb0:	032787b3          	mul	a5,a5,s2
ffffffffc0200fb4:	001b9b13          	slli	s6,s7,0x1
ffffffffc0200fb8:	017b0633          	add	a2,s6,s7
ffffffffc0200fbc:	0612                	slli	a2,a2,0x4
    size_t idx = page_index(page) / SLUB_SLAB_PAGES;
ffffffffc0200fbe:	8389                	srli	a5,a5,0x2
    assert(idx < MAX_SLABS);
ffffffffc0200fc0:	1ce6ef63          	bltu	a3,a4,ffffffffc020119e <slub_check+0x28e>
    assert(meta0 != meta_extra);
ffffffffc0200fc4:	00179713          	slli	a4,a5,0x1
ffffffffc0200fc8:	97ba                	add	a5,a5,a4
ffffffffc0200fca:	0792                	slli	a5,a5,0x4
        assert(slub_object_state(pages_buf[i]) != SLUB_STATE_ALLOCATED);
ffffffffc0200fcc:	4c89                	li	s9,2
    assert(meta0 != meta_extra);
ffffffffc0200fce:	38c78a63          	beq	a5,a2,ffffffffc0201362 <slub_check+0x452>
        slub_free_pages(pages_buf[i], 1);
ffffffffc0200fd2:	4585                	li	a1,1
ffffffffc0200fd4:	856a                	mv	a0,s10
ffffffffc0200fd6:	ab7ff0ef          	jal	ra,ffffffffc0200a8c <slub_free_pages>
    return (size_t)(page - pages);
ffffffffc0200fda:	0009b783          	ld	a5,0(s3)
ffffffffc0200fde:	40fd07b3          	sub	a5,s10,a5
ffffffffc0200fe2:	878d                	srai	a5,a5,0x3
ffffffffc0200fe4:	032787b3          	mul	a5,a5,s2
    return slub_page_state[page_index(page)];
ffffffffc0200fe8:	97d6                	add	a5,a5,s5
        assert(slub_object_state(pages_buf[i]) != SLUB_STATE_ALLOCATED);
ffffffffc0200fea:	0007c783          	lbu	a5,0(a5)
ffffffffc0200fee:	19978863          	beq	a5,s9,ffffffffc020117e <slub_check+0x26e>
    for (unsigned int i = 0; i < SLUB_OBJECTS_PER_SLAB; ++i) {
ffffffffc0200ff2:	04a1                	addi	s1,s1,8
ffffffffc0200ff4:	01448563          	beq	s1,s4,ffffffffc0200ffe <slub_check+0xee>
        slub_free_pages(pages_buf[i], 1);
ffffffffc0200ff8:	0004bd03          	ld	s10,0(s1)
ffffffffc0200ffc:	bfd9                	j	ffffffffc0200fd2 <slub_check+0xc2>
    assert(meta0->base == NULL);
ffffffffc0200ffe:	017b07b3          	add	a5,s6,s7
ffffffffc0201002:	00005a97          	auipc	s5,0x5
ffffffffc0201006:	02ea8a93          	addi	s5,s5,46 # ffffffffc0206030 <slab_table>
ffffffffc020100a:	0792                	slli	a5,a5,0x4
ffffffffc020100c:	97d6                	add	a5,a5,s5
ffffffffc020100e:	639c                	ld	a5,0(a5)
ffffffffc0201010:	32079963          	bnez	a5,ffffffffc0201342 <slub_check+0x432>
    slub_free_pages(p_extra, 1);
ffffffffc0201014:	4585                	li	a1,1
ffffffffc0201016:	8562                	mv	a0,s8
ffffffffc0201018:	a75ff0ef          	jal	ra,ffffffffc0200a8c <slub_free_pages>
    struct Page *page = backend_alloc_pages(n);
ffffffffc020101c:	4521                	li	a0,8
ffffffffc020101e:	f9cff0ef          	jal	ra,ffffffffc02007ba <backend_alloc_pages>
ffffffffc0201022:	84aa                	mv	s1,a0
    assert(block != NULL);
ffffffffc0201024:	1a050f63          	beqz	a0,ffffffffc02011e2 <slub_check+0x2d2>
    return backend_nr_free;
ffffffffc0201028:	00005b97          	auipc	s7,0x5
ffffffffc020102c:	ff0b8b93          	addi	s7,s7,-16 # ffffffffc0206018 <backend_area>
    return slub_cache.free_objects_total;
ffffffffc0201030:	00064b17          	auipc	s6,0x64
ffffffffc0201034:	800b0b13          	addi	s6,s6,-2048 # ffffffffc0264830 <slub_cache>
    return backend_nr_free_pages() + slub_nr_free_objects();
ffffffffc0201038:	010bba03          	ld	s4,16(s7)
ffffffffc020103c:	020b3783          	ld	a5,32(s6)
ffffffffc0201040:	9a3e                	add	s4,s4,a5
        return slub_alloc_small();
ffffffffc0201042:	cd5ff0ef          	jal	ra,ffffffffc0200d16 <slub_alloc_small>
    assert(p != NULL);
ffffffffc0201046:	26050e63          	beqz	a0,ffffffffc02012c2 <slub_check+0x3b2>
    slub_free_pages(p, 1);
ffffffffc020104a:	4585                	li	a1,1
ffffffffc020104c:	a41ff0ef          	jal	ra,ffffffffc0200a8c <slub_free_pages>
    return backend_nr_free_pages() + slub_nr_free_objects();
ffffffffc0201050:	010bb783          	ld	a5,16(s7)
ffffffffc0201054:	020b3703          	ld	a4,32(s6)
ffffffffc0201058:	97ba                	add	a5,a5,a4
    assert(before == after);
ffffffffc020105a:	24fa1463          	bne	s4,a5,ffffffffc02012a2 <slub_check+0x392>
    for (; p != base + n; ++p) {
ffffffffc020105e:	14048693          	addi	a3,s1,320
ffffffffc0201062:	87a6                	mv	a5,s1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201064:	6798                	ld	a4,8(a5)
ffffffffc0201066:	8b0d                	andi	a4,a4,3
ffffffffc0201068:	eb79                	bnez	a4,ffffffffc020113e <slub_check+0x22e>
        p->flags = 0;
ffffffffc020106a:	0007b423          	sd	zero,8(a5)
ffffffffc020106e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; ++p) {
ffffffffc0201072:	02878793          	addi	a5,a5,40
ffffffffc0201076:	fed797e3          	bne	a5,a3,ffffffffc0201064 <slub_check+0x154>
    assert(n > 0);
ffffffffc020107a:	8526                	mv	a0,s1
ffffffffc020107c:	45a1                	li	a1,8
ffffffffc020107e:	817ff0ef          	jal	ra,ffffffffc0200894 <backend_insert_block.part.0>
    struct Page *pages_local[sample];
ffffffffc0201082:	7179                	addi	sp,sp,-48
ffffffffc0201084:	8b8a                	mv	s7,sp
    for (unsigned int i = 0; i < sample; ++i) {
ffffffffc0201086:	8a5e                	mv	s4,s7
ffffffffc0201088:	030b8b13          	addi	s6,s7,48
    struct Page *pages_local[sample];
ffffffffc020108c:	84de                	mv	s1,s7
        return slub_alloc_small();
ffffffffc020108e:	c89ff0ef          	jal	ra,ffffffffc0200d16 <slub_alloc_small>
        pages_local[i] = slub_alloc_pages(1);
ffffffffc0201092:	e088                	sd	a0,0(s1)
        assert(pages_local[i] != NULL);
ffffffffc0201094:	c569                	beqz	a0,ffffffffc020115e <slub_check+0x24e>
    for (unsigned int i = 0; i < sample; ++i) {
ffffffffc0201096:	04a1                	addi	s1,s1,8
ffffffffc0201098:	fe9b1be3          	bne	s6,s1,ffffffffc020108e <slub_check+0x17e>
    struct Page *candidate = pages_local[SLUB_OBJECTS_PER_SLAB - 1];
ffffffffc020109c:	018bbb83          	ld	s7,24(s7)
    return (size_t)(page - pages);
ffffffffc02010a0:	0009b783          	ld	a5,0(s3)
    assert(idx < MAX_SLABS);
ffffffffc02010a4:	0013b737          	lui	a4,0x13b
ffffffffc02010a8:	fd870713          	addi	a4,a4,-40 # 13afd8 <kern_entry-0xffffffffc00c5028>
    return (size_t)(page - pages);
ffffffffc02010ac:	40fb87b3          	sub	a5,s7,a5
ffffffffc02010b0:	4037d693          	srai	a3,a5,0x3
ffffffffc02010b4:	03268933          	mul	s2,a3,s2
    size_t idx = page_index(page) / SLUB_SLAB_PAGES;
ffffffffc02010b8:	00295913          	srli	s2,s2,0x2
    assert(idx < MAX_SLABS);
ffffffffc02010bc:	0ef76163          	bltu	a4,a5,ffffffffc020119e <slub_check+0x28e>
    assert(meta->free_objects == 0);
ffffffffc02010c0:	00191993          	slli	s3,s2,0x1
ffffffffc02010c4:	012984b3          	add	s1,s3,s2
ffffffffc02010c8:	0492                	slli	s1,s1,0x4
ffffffffc02010ca:	94d6                	add	s1,s1,s5
ffffffffc02010cc:	489c                	lw	a5,16(s1)
ffffffffc02010ce:	16079a63          	bnez	a5,ffffffffc0201242 <slub_check+0x332>
    assert(meta->on_full);
ffffffffc02010d2:	4cdc                	lw	a5,28(s1)
ffffffffc02010d4:	24078763          	beqz	a5,ffffffffc0201322 <slub_check+0x412>
    slub_free_pages(candidate, 1);
ffffffffc02010d8:	4585                	li	a1,1
ffffffffc02010da:	855e                	mv	a0,s7
ffffffffc02010dc:	9b1ff0ef          	jal	ra,ffffffffc0200a8c <slub_free_pages>
    assert(meta->free_objects == 1);
ffffffffc02010e0:	4898                	lw	a4,16(s1)
ffffffffc02010e2:	4785                	li	a5,1
ffffffffc02010e4:	20f71f63          	bne	a4,a5,ffffffffc0201302 <slub_check+0x3f2>
    assert(meta->on_partial);
ffffffffc02010e8:	4c9c                	lw	a5,24(s1)
ffffffffc02010ea:	1e078c63          	beqz	a5,ffffffffc02012e2 <slub_check+0x3d2>
    assert(!meta->on_full);
ffffffffc02010ee:	4cdc                	lw	a5,28(s1)
ffffffffc02010f0:	18079963          	bnez	a5,ffffffffc0201282 <slub_check+0x372>
        return slub_alloc_small();
ffffffffc02010f4:	c23ff0ef          	jal	ra,ffffffffc0200d16 <slub_alloc_small>
    assert(reused == candidate);
ffffffffc02010f8:	12ab9563          	bne	s7,a0,ffffffffc0201222 <slub_check+0x312>
    assert(meta->on_full || meta->free_objects == 0);
ffffffffc02010fc:	4cdc                	lw	a5,28(s1)
ffffffffc02010fe:	eb81                	bnez	a5,ffffffffc020110e <slub_check+0x1fe>
ffffffffc0201100:	994e                	add	s2,s2,s3
ffffffffc0201102:	0912                	slli	s2,s2,0x4
ffffffffc0201104:	9aca                	add	s5,s5,s2
ffffffffc0201106:	010aa783          	lw	a5,16(s5)
ffffffffc020110a:	14079c63          	bnez	a5,ffffffffc0201262 <slub_check+0x352>
        slub_free_pages(pages_local[i], 1);
ffffffffc020110e:	000a3503          	ld	a0,0(s4)
ffffffffc0201112:	4585                	li	a1,1
    for (unsigned int i = 0; i < sample; ++i) {
ffffffffc0201114:	0a21                	addi	s4,s4,8
        slub_free_pages(pages_local[i], 1);
ffffffffc0201116:	977ff0ef          	jal	ra,ffffffffc0200a8c <slub_free_pages>
    for (unsigned int i = 0; i < sample; ++i) {
ffffffffc020111a:	ff4b1ae3          	bne	s6,s4,ffffffffc020110e <slub_check+0x1fe>
    slub_basic_check();
    slub_mixed_size_check();
    slub_partial_reuse_check();
}
ffffffffc020111e:	f8040113          	addi	sp,s0,-128
ffffffffc0201122:	70e6                	ld	ra,120(sp)
ffffffffc0201124:	7446                	ld	s0,112(sp)
ffffffffc0201126:	74a6                	ld	s1,104(sp)
ffffffffc0201128:	7906                	ld	s2,96(sp)
ffffffffc020112a:	69e6                	ld	s3,88(sp)
ffffffffc020112c:	6a46                	ld	s4,80(sp)
ffffffffc020112e:	6aa6                	ld	s5,72(sp)
ffffffffc0201130:	6b06                	ld	s6,64(sp)
ffffffffc0201132:	7be2                	ld	s7,56(sp)
ffffffffc0201134:	7c42                	ld	s8,48(sp)
ffffffffc0201136:	7ca2                	ld	s9,40(sp)
ffffffffc0201138:	7d02                	ld	s10,32(sp)
ffffffffc020113a:	6109                	addi	sp,sp,128
ffffffffc020113c:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020113e:	00001697          	auipc	a3,0x1
ffffffffc0201142:	aca68693          	addi	a3,a3,-1334 # ffffffffc0201c08 <etext+0x3f2>
ffffffffc0201146:	00001617          	auipc	a2,0x1
ffffffffc020114a:	a8260613          	addi	a2,a2,-1406 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc020114e:	0c700593          	li	a1,199
ffffffffc0201152:	00001517          	auipc	a0,0x1
ffffffffc0201156:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020115a:	868ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(pages_local[i] != NULL);
ffffffffc020115e:	00001697          	auipc	a3,0x1
ffffffffc0201162:	bf268693          	addi	a3,a3,-1038 # ffffffffc0201d50 <etext+0x53a>
ffffffffc0201166:	00001617          	auipc	a2,0x1
ffffffffc020116a:	a6260613          	addi	a2,a2,-1438 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc020116e:	22800593          	li	a1,552
ffffffffc0201172:	00001517          	auipc	a0,0x1
ffffffffc0201176:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020117a:	848ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(slub_object_state(pages_buf[i]) != SLUB_STATE_ALLOCATED);
ffffffffc020117e:	00001697          	auipc	a3,0x1
ffffffffc0201182:	b6268693          	addi	a3,a3,-1182 # ffffffffc0201ce0 <etext+0x4ca>
ffffffffc0201186:	00001617          	auipc	a2,0x1
ffffffffc020118a:	a4260613          	addi	a2,a2,-1470 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc020118e:	20600593          	li	a1,518
ffffffffc0201192:	00001517          	auipc	a0,0x1
ffffffffc0201196:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020119a:	828ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc020119e:	ed2ff0ef          	jal	ra,ffffffffc0200870 <page_to_slab.part.0>
        assert(slub_object_state(p) == SLUB_STATE_ALLOCATED);
ffffffffc02011a2:	00001697          	auipc	a3,0x1
ffffffffc02011a6:	ae668693          	addi	a3,a3,-1306 # ffffffffc0201c88 <etext+0x472>
ffffffffc02011aa:	00001617          	auipc	a2,0x1
ffffffffc02011ae:	a1e60613          	addi	a2,a2,-1506 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02011b2:	1f900593          	li	a1,505
ffffffffc02011b6:	00001517          	auipc	a0,0x1
ffffffffc02011ba:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02011be:	804ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(p != NULL);
ffffffffc02011c2:	00001697          	auipc	a3,0x1
ffffffffc02011c6:	ab668693          	addi	a3,a3,-1354 # ffffffffc0201c78 <etext+0x462>
ffffffffc02011ca:	00001617          	auipc	a2,0x1
ffffffffc02011ce:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02011d2:	1f700593          	li	a1,503
ffffffffc02011d6:	00001517          	auipc	a0,0x1
ffffffffc02011da:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02011de:	fe5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(block != NULL);
ffffffffc02011e2:	00001697          	auipc	a3,0x1
ffffffffc02011e6:	b4e68693          	addi	a3,a3,-1202 # ffffffffc0201d30 <etext+0x51a>
ffffffffc02011ea:	00001617          	auipc	a2,0x1
ffffffffc02011ee:	9de60613          	addi	a2,a2,-1570 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02011f2:	21500593          	li	a1,533
ffffffffc02011f6:	00001517          	auipc	a0,0x1
ffffffffc02011fa:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02011fe:	fc5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p_extra != NULL);
ffffffffc0201202:	00001697          	auipc	a3,0x1
ffffffffc0201206:	ab668693          	addi	a3,a3,-1354 # ffffffffc0201cb8 <etext+0x4a2>
ffffffffc020120a:	00001617          	auipc	a2,0x1
ffffffffc020120e:	9be60613          	addi	a2,a2,-1602 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201212:	1fe00593          	li	a1,510
ffffffffc0201216:	00001517          	auipc	a0,0x1
ffffffffc020121a:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020121e:	fa5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(reused == candidate);
ffffffffc0201222:	00001697          	auipc	a3,0x1
ffffffffc0201226:	bae68693          	addi	a3,a3,-1106 # ffffffffc0201dd0 <etext+0x5ba>
ffffffffc020122a:	00001617          	auipc	a2,0x1
ffffffffc020122e:	99e60613          	addi	a2,a2,-1634 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201232:	23600593          	li	a1,566
ffffffffc0201236:	00001517          	auipc	a0,0x1
ffffffffc020123a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020123e:	f85fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta->free_objects == 0);
ffffffffc0201242:	00001697          	auipc	a3,0x1
ffffffffc0201246:	b2668693          	addi	a3,a3,-1242 # ffffffffc0201d68 <etext+0x552>
ffffffffc020124a:	00001617          	auipc	a2,0x1
ffffffffc020124e:	97e60613          	addi	a2,a2,-1666 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201252:	22d00593          	li	a1,557
ffffffffc0201256:	00001517          	auipc	a0,0x1
ffffffffc020125a:	98a50513          	addi	a0,a0,-1654 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020125e:	f65fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta->on_full || meta->free_objects == 0);
ffffffffc0201262:	00001697          	auipc	a3,0x1
ffffffffc0201266:	b8668693          	addi	a3,a3,-1146 # ffffffffc0201de8 <etext+0x5d2>
ffffffffc020126a:	00001617          	auipc	a2,0x1
ffffffffc020126e:	95e60613          	addi	a2,a2,-1698 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201272:	23700593          	li	a1,567
ffffffffc0201276:	00001517          	auipc	a0,0x1
ffffffffc020127a:	96a50513          	addi	a0,a0,-1686 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020127e:	f45fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!meta->on_full);
ffffffffc0201282:	00001697          	auipc	a3,0x1
ffffffffc0201286:	b3e68693          	addi	a3,a3,-1218 # ffffffffc0201dc0 <etext+0x5aa>
ffffffffc020128a:	00001617          	auipc	a2,0x1
ffffffffc020128e:	93e60613          	addi	a2,a2,-1730 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201292:	23300593          	li	a1,563
ffffffffc0201296:	00001517          	auipc	a0,0x1
ffffffffc020129a:	94a50513          	addi	a0,a0,-1718 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020129e:	f25fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(before == after);
ffffffffc02012a2:	00001697          	auipc	a3,0x1
ffffffffc02012a6:	a9e68693          	addi	a3,a3,-1378 # ffffffffc0201d40 <etext+0x52a>
ffffffffc02012aa:	00001617          	auipc	a2,0x1
ffffffffc02012ae:	91e60613          	addi	a2,a2,-1762 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02012b2:	21c00593          	li	a1,540
ffffffffc02012b6:	00001517          	auipc	a0,0x1
ffffffffc02012ba:	92a50513          	addi	a0,a0,-1750 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02012be:	f05fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p != NULL);
ffffffffc02012c2:	00001697          	auipc	a3,0x1
ffffffffc02012c6:	9b668693          	addi	a3,a3,-1610 # ffffffffc0201c78 <etext+0x462>
ffffffffc02012ca:	00001617          	auipc	a2,0x1
ffffffffc02012ce:	8fe60613          	addi	a2,a2,-1794 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02012d2:	21900593          	li	a1,537
ffffffffc02012d6:	00001517          	auipc	a0,0x1
ffffffffc02012da:	90a50513          	addi	a0,a0,-1782 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02012de:	ee5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta->on_partial);
ffffffffc02012e2:	00001697          	auipc	a3,0x1
ffffffffc02012e6:	ac668693          	addi	a3,a3,-1338 # ffffffffc0201da8 <etext+0x592>
ffffffffc02012ea:	00001617          	auipc	a2,0x1
ffffffffc02012ee:	8de60613          	addi	a2,a2,-1826 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc02012f2:	23200593          	li	a1,562
ffffffffc02012f6:	00001517          	auipc	a0,0x1
ffffffffc02012fa:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc02012fe:	ec5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta->free_objects == 1);
ffffffffc0201302:	00001697          	auipc	a3,0x1
ffffffffc0201306:	a8e68693          	addi	a3,a3,-1394 # ffffffffc0201d90 <etext+0x57a>
ffffffffc020130a:	00001617          	auipc	a2,0x1
ffffffffc020130e:	8be60613          	addi	a2,a2,-1858 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201312:	23100593          	li	a1,561
ffffffffc0201316:	00001517          	auipc	a0,0x1
ffffffffc020131a:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020131e:	ea5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta->on_full);
ffffffffc0201322:	00001697          	auipc	a3,0x1
ffffffffc0201326:	a5e68693          	addi	a3,a3,-1442 # ffffffffc0201d80 <etext+0x56a>
ffffffffc020132a:	00001617          	auipc	a2,0x1
ffffffffc020132e:	89e60613          	addi	a2,a2,-1890 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201332:	22e00593          	li	a1,558
ffffffffc0201336:	00001517          	auipc	a0,0x1
ffffffffc020133a:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020133e:	e85fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta0->base == NULL);
ffffffffc0201342:	00001697          	auipc	a3,0x1
ffffffffc0201346:	9d668693          	addi	a3,a3,-1578 # ffffffffc0201d18 <etext+0x502>
ffffffffc020134a:	00001617          	auipc	a2,0x1
ffffffffc020134e:	87e60613          	addi	a2,a2,-1922 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201352:	20a00593          	li	a1,522
ffffffffc0201356:	00001517          	auipc	a0,0x1
ffffffffc020135a:	88a50513          	addi	a0,a0,-1910 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020135e:	e65fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(meta0 != meta_extra);
ffffffffc0201362:	00001697          	auipc	a3,0x1
ffffffffc0201366:	96668693          	addi	a3,a3,-1690 # ffffffffc0201cc8 <etext+0x4b2>
ffffffffc020136a:	00001617          	auipc	a2,0x1
ffffffffc020136e:	85e60613          	addi	a2,a2,-1954 # ffffffffc0201bc8 <etext+0x3b2>
ffffffffc0201372:	20100593          	li	a1,513
ffffffffc0201376:	00001517          	auipc	a0,0x1
ffffffffc020137a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201be0 <etext+0x3ca>
ffffffffc020137e:	e45fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201382 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201382:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201386:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201388:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020138c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020138e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201392:	f022                	sd	s0,32(sp)
ffffffffc0201394:	ec26                	sd	s1,24(sp)
ffffffffc0201396:	e84a                	sd	s2,16(sp)
ffffffffc0201398:	f406                	sd	ra,40(sp)
ffffffffc020139a:	e44e                	sd	s3,8(sp)
ffffffffc020139c:	84aa                	mv	s1,a0
ffffffffc020139e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02013a0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02013a4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02013a6:	03067e63          	bgeu	a2,a6,ffffffffc02013e2 <printnum+0x60>
ffffffffc02013aa:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02013ac:	00805763          	blez	s0,ffffffffc02013ba <printnum+0x38>
ffffffffc02013b0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02013b2:	85ca                	mv	a1,s2
ffffffffc02013b4:	854e                	mv	a0,s3
ffffffffc02013b6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02013b8:	fc65                	bnez	s0,ffffffffc02013b0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02013ba:	1a02                	slli	s4,s4,0x20
ffffffffc02013bc:	00001797          	auipc	a5,0x1
ffffffffc02013c0:	aac78793          	addi	a5,a5,-1364 # ffffffffc0201e68 <slub_pmm_manager+0x38>
ffffffffc02013c4:	020a5a13          	srli	s4,s4,0x20
ffffffffc02013c8:	9a3e                	add	s4,s4,a5
}
ffffffffc02013ca:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02013cc:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02013d0:	70a2                	ld	ra,40(sp)
ffffffffc02013d2:	69a2                	ld	s3,8(sp)
ffffffffc02013d4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02013d6:	85ca                	mv	a1,s2
ffffffffc02013d8:	87a6                	mv	a5,s1
}
ffffffffc02013da:	6942                	ld	s2,16(sp)
ffffffffc02013dc:	64e2                	ld	s1,24(sp)
ffffffffc02013de:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02013e0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02013e2:	03065633          	divu	a2,a2,a6
ffffffffc02013e6:	8722                	mv	a4,s0
ffffffffc02013e8:	f9bff0ef          	jal	ra,ffffffffc0201382 <printnum>
ffffffffc02013ec:	b7f9                	j	ffffffffc02013ba <printnum+0x38>

ffffffffc02013ee <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02013ee:	7119                	addi	sp,sp,-128
ffffffffc02013f0:	f4a6                	sd	s1,104(sp)
ffffffffc02013f2:	f0ca                	sd	s2,96(sp)
ffffffffc02013f4:	ecce                	sd	s3,88(sp)
ffffffffc02013f6:	e8d2                	sd	s4,80(sp)
ffffffffc02013f8:	e4d6                	sd	s5,72(sp)
ffffffffc02013fa:	e0da                	sd	s6,64(sp)
ffffffffc02013fc:	fc5e                	sd	s7,56(sp)
ffffffffc02013fe:	f06a                	sd	s10,32(sp)
ffffffffc0201400:	fc86                	sd	ra,120(sp)
ffffffffc0201402:	f8a2                	sd	s0,112(sp)
ffffffffc0201404:	f862                	sd	s8,48(sp)
ffffffffc0201406:	f466                	sd	s9,40(sp)
ffffffffc0201408:	ec6e                	sd	s11,24(sp)
ffffffffc020140a:	892a                	mv	s2,a0
ffffffffc020140c:	84ae                	mv	s1,a1
ffffffffc020140e:	8d32                	mv	s10,a2
ffffffffc0201410:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201412:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201416:	5b7d                	li	s6,-1
ffffffffc0201418:	00001a97          	auipc	s5,0x1
ffffffffc020141c:	a84a8a93          	addi	s5,s5,-1404 # ffffffffc0201e9c <slub_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201420:	00001b97          	auipc	s7,0x1
ffffffffc0201424:	c58b8b93          	addi	s7,s7,-936 # ffffffffc0202078 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201428:	000d4503          	lbu	a0,0(s10)
ffffffffc020142c:	001d0413          	addi	s0,s10,1
ffffffffc0201430:	01350a63          	beq	a0,s3,ffffffffc0201444 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201434:	c121                	beqz	a0,ffffffffc0201474 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201436:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201438:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020143a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020143c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201440:	ff351ae3          	bne	a0,s3,ffffffffc0201434 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201444:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201448:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020144c:	4c81                	li	s9,0
ffffffffc020144e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201450:	5c7d                	li	s8,-1
ffffffffc0201452:	5dfd                	li	s11,-1
ffffffffc0201454:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201458:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020145a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020145e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201462:	00140d13          	addi	s10,s0,1
ffffffffc0201466:	04b56263          	bltu	a0,a1,ffffffffc02014aa <vprintfmt+0xbc>
ffffffffc020146a:	058a                	slli	a1,a1,0x2
ffffffffc020146c:	95d6                	add	a1,a1,s5
ffffffffc020146e:	4194                	lw	a3,0(a1)
ffffffffc0201470:	96d6                	add	a3,a3,s5
ffffffffc0201472:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201474:	70e6                	ld	ra,120(sp)
ffffffffc0201476:	7446                	ld	s0,112(sp)
ffffffffc0201478:	74a6                	ld	s1,104(sp)
ffffffffc020147a:	7906                	ld	s2,96(sp)
ffffffffc020147c:	69e6                	ld	s3,88(sp)
ffffffffc020147e:	6a46                	ld	s4,80(sp)
ffffffffc0201480:	6aa6                	ld	s5,72(sp)
ffffffffc0201482:	6b06                	ld	s6,64(sp)
ffffffffc0201484:	7be2                	ld	s7,56(sp)
ffffffffc0201486:	7c42                	ld	s8,48(sp)
ffffffffc0201488:	7ca2                	ld	s9,40(sp)
ffffffffc020148a:	7d02                	ld	s10,32(sp)
ffffffffc020148c:	6de2                	ld	s11,24(sp)
ffffffffc020148e:	6109                	addi	sp,sp,128
ffffffffc0201490:	8082                	ret
            padc = '0';
ffffffffc0201492:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201494:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201498:	846a                	mv	s0,s10
ffffffffc020149a:	00140d13          	addi	s10,s0,1
ffffffffc020149e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02014a2:	0ff5f593          	zext.b	a1,a1
ffffffffc02014a6:	fcb572e3          	bgeu	a0,a1,ffffffffc020146a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02014aa:	85a6                	mv	a1,s1
ffffffffc02014ac:	02500513          	li	a0,37
ffffffffc02014b0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02014b2:	fff44783          	lbu	a5,-1(s0)
ffffffffc02014b6:	8d22                	mv	s10,s0
ffffffffc02014b8:	f73788e3          	beq	a5,s3,ffffffffc0201428 <vprintfmt+0x3a>
ffffffffc02014bc:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02014c0:	1d7d                	addi	s10,s10,-1
ffffffffc02014c2:	ff379de3          	bne	a5,s3,ffffffffc02014bc <vprintfmt+0xce>
ffffffffc02014c6:	b78d                	j	ffffffffc0201428 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02014c8:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02014cc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014d0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02014d2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02014d6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02014da:	02d86463          	bltu	a6,a3,ffffffffc0201502 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02014de:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02014e2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02014e6:	0186873b          	addw	a4,a3,s8
ffffffffc02014ea:	0017171b          	slliw	a4,a4,0x1
ffffffffc02014ee:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02014f0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02014f4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02014f6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02014fa:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02014fe:	fed870e3          	bgeu	a6,a3,ffffffffc02014de <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201502:	f40ddce3          	bgez	s11,ffffffffc020145a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201506:	8de2                	mv	s11,s8
ffffffffc0201508:	5c7d                	li	s8,-1
ffffffffc020150a:	bf81                	j	ffffffffc020145a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020150c:	fffdc693          	not	a3,s11
ffffffffc0201510:	96fd                	srai	a3,a3,0x3f
ffffffffc0201512:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201516:	00144603          	lbu	a2,1(s0)
ffffffffc020151a:	2d81                	sext.w	s11,s11
ffffffffc020151c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020151e:	bf35                	j	ffffffffc020145a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201520:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201524:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201528:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020152a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020152c:	bfd9                	j	ffffffffc0201502 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020152e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201530:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201534:	01174463          	blt	a4,a7,ffffffffc020153c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201538:	1a088e63          	beqz	a7,ffffffffc02016f4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020153c:	000a3603          	ld	a2,0(s4)
ffffffffc0201540:	46c1                	li	a3,16
ffffffffc0201542:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201544:	2781                	sext.w	a5,a5
ffffffffc0201546:	876e                	mv	a4,s11
ffffffffc0201548:	85a6                	mv	a1,s1
ffffffffc020154a:	854a                	mv	a0,s2
ffffffffc020154c:	e37ff0ef          	jal	ra,ffffffffc0201382 <printnum>
            break;
ffffffffc0201550:	bde1                	j	ffffffffc0201428 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201552:	000a2503          	lw	a0,0(s4)
ffffffffc0201556:	85a6                	mv	a1,s1
ffffffffc0201558:	0a21                	addi	s4,s4,8
ffffffffc020155a:	9902                	jalr	s2
            break;
ffffffffc020155c:	b5f1                	j	ffffffffc0201428 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020155e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201560:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201564:	01174463          	blt	a4,a7,ffffffffc020156c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201568:	18088163          	beqz	a7,ffffffffc02016ea <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020156c:	000a3603          	ld	a2,0(s4)
ffffffffc0201570:	46a9                	li	a3,10
ffffffffc0201572:	8a2e                	mv	s4,a1
ffffffffc0201574:	bfc1                	j	ffffffffc0201544 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201576:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020157a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020157c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020157e:	bdf1                	j	ffffffffc020145a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201580:	85a6                	mv	a1,s1
ffffffffc0201582:	02500513          	li	a0,37
ffffffffc0201586:	9902                	jalr	s2
            break;
ffffffffc0201588:	b545                	j	ffffffffc0201428 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020158a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020158e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201590:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201592:	b5e1                	j	ffffffffc020145a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201594:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201596:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020159a:	01174463          	blt	a4,a7,ffffffffc02015a2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020159e:	14088163          	beqz	a7,ffffffffc02016e0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02015a2:	000a3603          	ld	a2,0(s4)
ffffffffc02015a6:	46a1                	li	a3,8
ffffffffc02015a8:	8a2e                	mv	s4,a1
ffffffffc02015aa:	bf69                	j	ffffffffc0201544 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02015ac:	03000513          	li	a0,48
ffffffffc02015b0:	85a6                	mv	a1,s1
ffffffffc02015b2:	e03e                	sd	a5,0(sp)
ffffffffc02015b4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02015b6:	85a6                	mv	a1,s1
ffffffffc02015b8:	07800513          	li	a0,120
ffffffffc02015bc:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02015be:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02015c0:	6782                	ld	a5,0(sp)
ffffffffc02015c2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02015c4:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02015c8:	bfb5                	j	ffffffffc0201544 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02015ca:	000a3403          	ld	s0,0(s4)
ffffffffc02015ce:	008a0713          	addi	a4,s4,8
ffffffffc02015d2:	e03a                	sd	a4,0(sp)
ffffffffc02015d4:	14040263          	beqz	s0,ffffffffc0201718 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02015d8:	0fb05763          	blez	s11,ffffffffc02016c6 <vprintfmt+0x2d8>
ffffffffc02015dc:	02d00693          	li	a3,45
ffffffffc02015e0:	0cd79163          	bne	a5,a3,ffffffffc02016a2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015e4:	00044783          	lbu	a5,0(s0)
ffffffffc02015e8:	0007851b          	sext.w	a0,a5
ffffffffc02015ec:	cf85                	beqz	a5,ffffffffc0201624 <vprintfmt+0x236>
ffffffffc02015ee:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015f2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015f6:	000c4563          	bltz	s8,ffffffffc0201600 <vprintfmt+0x212>
ffffffffc02015fa:	3c7d                	addiw	s8,s8,-1
ffffffffc02015fc:	036c0263          	beq	s8,s6,ffffffffc0201620 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201600:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201602:	0e0c8e63          	beqz	s9,ffffffffc02016fe <vprintfmt+0x310>
ffffffffc0201606:	3781                	addiw	a5,a5,-32
ffffffffc0201608:	0ef47b63          	bgeu	s0,a5,ffffffffc02016fe <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020160c:	03f00513          	li	a0,63
ffffffffc0201610:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201612:	000a4783          	lbu	a5,0(s4)
ffffffffc0201616:	3dfd                	addiw	s11,s11,-1
ffffffffc0201618:	0a05                	addi	s4,s4,1
ffffffffc020161a:	0007851b          	sext.w	a0,a5
ffffffffc020161e:	ffe1                	bnez	a5,ffffffffc02015f6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201620:	01b05963          	blez	s11,ffffffffc0201632 <vprintfmt+0x244>
ffffffffc0201624:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201626:	85a6                	mv	a1,s1
ffffffffc0201628:	02000513          	li	a0,32
ffffffffc020162c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020162e:	fe0d9be3          	bnez	s11,ffffffffc0201624 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201632:	6a02                	ld	s4,0(sp)
ffffffffc0201634:	bbd5                	j	ffffffffc0201428 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201636:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201638:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020163c:	01174463          	blt	a4,a7,ffffffffc0201644 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201640:	08088d63          	beqz	a7,ffffffffc02016da <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201644:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201648:	0a044d63          	bltz	s0,ffffffffc0201702 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020164c:	8622                	mv	a2,s0
ffffffffc020164e:	8a66                	mv	s4,s9
ffffffffc0201650:	46a9                	li	a3,10
ffffffffc0201652:	bdcd                	j	ffffffffc0201544 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201654:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201658:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020165a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020165c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201660:	8fb5                	xor	a5,a5,a3
ffffffffc0201662:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201666:	02d74163          	blt	a4,a3,ffffffffc0201688 <vprintfmt+0x29a>
ffffffffc020166a:	00369793          	slli	a5,a3,0x3
ffffffffc020166e:	97de                	add	a5,a5,s7
ffffffffc0201670:	639c                	ld	a5,0(a5)
ffffffffc0201672:	cb99                	beqz	a5,ffffffffc0201688 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201674:	86be                	mv	a3,a5
ffffffffc0201676:	00001617          	auipc	a2,0x1
ffffffffc020167a:	82260613          	addi	a2,a2,-2014 # ffffffffc0201e98 <slub_pmm_manager+0x68>
ffffffffc020167e:	85a6                	mv	a1,s1
ffffffffc0201680:	854a                	mv	a0,s2
ffffffffc0201682:	0ce000ef          	jal	ra,ffffffffc0201750 <printfmt>
ffffffffc0201686:	b34d                	j	ffffffffc0201428 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201688:	00001617          	auipc	a2,0x1
ffffffffc020168c:	80060613          	addi	a2,a2,-2048 # ffffffffc0201e88 <slub_pmm_manager+0x58>
ffffffffc0201690:	85a6                	mv	a1,s1
ffffffffc0201692:	854a                	mv	a0,s2
ffffffffc0201694:	0bc000ef          	jal	ra,ffffffffc0201750 <printfmt>
ffffffffc0201698:	bb41                	j	ffffffffc0201428 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020169a:	00000417          	auipc	s0,0x0
ffffffffc020169e:	7e640413          	addi	s0,s0,2022 # ffffffffc0201e80 <slub_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02016a2:	85e2                	mv	a1,s8
ffffffffc02016a4:	8522                	mv	a0,s0
ffffffffc02016a6:	e43e                	sd	a5,8(sp)
ffffffffc02016a8:	0fc000ef          	jal	ra,ffffffffc02017a4 <strnlen>
ffffffffc02016ac:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02016b0:	01b05b63          	blez	s11,ffffffffc02016c6 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02016b4:	67a2                	ld	a5,8(sp)
ffffffffc02016b6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02016ba:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02016bc:	85a6                	mv	a1,s1
ffffffffc02016be:	8552                	mv	a0,s4
ffffffffc02016c0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02016c2:	fe0d9ce3          	bnez	s11,ffffffffc02016ba <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016c6:	00044783          	lbu	a5,0(s0)
ffffffffc02016ca:	00140a13          	addi	s4,s0,1
ffffffffc02016ce:	0007851b          	sext.w	a0,a5
ffffffffc02016d2:	d3a5                	beqz	a5,ffffffffc0201632 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016d4:	05e00413          	li	s0,94
ffffffffc02016d8:	bf39                	j	ffffffffc02015f6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02016da:	000a2403          	lw	s0,0(s4)
ffffffffc02016de:	b7ad                	j	ffffffffc0201648 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02016e0:	000a6603          	lwu	a2,0(s4)
ffffffffc02016e4:	46a1                	li	a3,8
ffffffffc02016e6:	8a2e                	mv	s4,a1
ffffffffc02016e8:	bdb1                	j	ffffffffc0201544 <vprintfmt+0x156>
ffffffffc02016ea:	000a6603          	lwu	a2,0(s4)
ffffffffc02016ee:	46a9                	li	a3,10
ffffffffc02016f0:	8a2e                	mv	s4,a1
ffffffffc02016f2:	bd89                	j	ffffffffc0201544 <vprintfmt+0x156>
ffffffffc02016f4:	000a6603          	lwu	a2,0(s4)
ffffffffc02016f8:	46c1                	li	a3,16
ffffffffc02016fa:	8a2e                	mv	s4,a1
ffffffffc02016fc:	b5a1                	j	ffffffffc0201544 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02016fe:	9902                	jalr	s2
ffffffffc0201700:	bf09                	j	ffffffffc0201612 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201702:	85a6                	mv	a1,s1
ffffffffc0201704:	02d00513          	li	a0,45
ffffffffc0201708:	e03e                	sd	a5,0(sp)
ffffffffc020170a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020170c:	6782                	ld	a5,0(sp)
ffffffffc020170e:	8a66                	mv	s4,s9
ffffffffc0201710:	40800633          	neg	a2,s0
ffffffffc0201714:	46a9                	li	a3,10
ffffffffc0201716:	b53d                	j	ffffffffc0201544 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201718:	03b05163          	blez	s11,ffffffffc020173a <vprintfmt+0x34c>
ffffffffc020171c:	02d00693          	li	a3,45
ffffffffc0201720:	f6d79de3          	bne	a5,a3,ffffffffc020169a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201724:	00000417          	auipc	s0,0x0
ffffffffc0201728:	75c40413          	addi	s0,s0,1884 # ffffffffc0201e80 <slub_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020172c:	02800793          	li	a5,40
ffffffffc0201730:	02800513          	li	a0,40
ffffffffc0201734:	00140a13          	addi	s4,s0,1
ffffffffc0201738:	bd6d                	j	ffffffffc02015f2 <vprintfmt+0x204>
ffffffffc020173a:	00000a17          	auipc	s4,0x0
ffffffffc020173e:	747a0a13          	addi	s4,s4,1863 # ffffffffc0201e81 <slub_pmm_manager+0x51>
ffffffffc0201742:	02800513          	li	a0,40
ffffffffc0201746:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020174a:	05e00413          	li	s0,94
ffffffffc020174e:	b565                	j	ffffffffc02015f6 <vprintfmt+0x208>

ffffffffc0201750 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201750:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201752:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201756:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201758:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020175a:	ec06                	sd	ra,24(sp)
ffffffffc020175c:	f83a                	sd	a4,48(sp)
ffffffffc020175e:	fc3e                	sd	a5,56(sp)
ffffffffc0201760:	e0c2                	sd	a6,64(sp)
ffffffffc0201762:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201764:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201766:	c89ff0ef          	jal	ra,ffffffffc02013ee <vprintfmt>
}
ffffffffc020176a:	60e2                	ld	ra,24(sp)
ffffffffc020176c:	6161                	addi	sp,sp,80
ffffffffc020176e:	8082                	ret

ffffffffc0201770 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201770:	4781                	li	a5,0
ffffffffc0201772:	00005717          	auipc	a4,0x5
ffffffffc0201776:	89e73703          	ld	a4,-1890(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc020177a:	88ba                	mv	a7,a4
ffffffffc020177c:	852a                	mv	a0,a0
ffffffffc020177e:	85be                	mv	a1,a5
ffffffffc0201780:	863e                	mv	a2,a5
ffffffffc0201782:	00000073          	ecall
ffffffffc0201786:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201788:	8082                	ret

ffffffffc020178a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020178a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020178e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201790:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201792:	cb81                	beqz	a5,ffffffffc02017a2 <strlen+0x18>
        cnt ++;
ffffffffc0201794:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201796:	00a707b3          	add	a5,a4,a0
ffffffffc020179a:	0007c783          	lbu	a5,0(a5)
ffffffffc020179e:	fbfd                	bnez	a5,ffffffffc0201794 <strlen+0xa>
ffffffffc02017a0:	8082                	ret
    }
    return cnt;
}
ffffffffc02017a2:	8082                	ret

ffffffffc02017a4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02017a4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017a6:	e589                	bnez	a1,ffffffffc02017b0 <strnlen+0xc>
ffffffffc02017a8:	a811                	j	ffffffffc02017bc <strnlen+0x18>
        cnt ++;
ffffffffc02017aa:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017ac:	00f58863          	beq	a1,a5,ffffffffc02017bc <strnlen+0x18>
ffffffffc02017b0:	00f50733          	add	a4,a0,a5
ffffffffc02017b4:	00074703          	lbu	a4,0(a4)
ffffffffc02017b8:	fb6d                	bnez	a4,ffffffffc02017aa <strnlen+0x6>
ffffffffc02017ba:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02017bc:	852e                	mv	a0,a1
ffffffffc02017be:	8082                	ret

ffffffffc02017c0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017c0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02017c4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017c8:	cb89                	beqz	a5,ffffffffc02017da <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02017ca:	0505                	addi	a0,a0,1
ffffffffc02017cc:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017ce:	fee789e3          	beq	a5,a4,ffffffffc02017c0 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02017d2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02017d6:	9d19                	subw	a0,a0,a4
ffffffffc02017d8:	8082                	ret
ffffffffc02017da:	4501                	li	a0,0
ffffffffc02017dc:	bfed                	j	ffffffffc02017d6 <strcmp+0x16>

ffffffffc02017de <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02017de:	c20d                	beqz	a2,ffffffffc0201800 <strncmp+0x22>
ffffffffc02017e0:	962e                	add	a2,a2,a1
ffffffffc02017e2:	a031                	j	ffffffffc02017ee <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02017e4:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02017e6:	00e79a63          	bne	a5,a4,ffffffffc02017fa <strncmp+0x1c>
ffffffffc02017ea:	00b60b63          	beq	a2,a1,ffffffffc0201800 <strncmp+0x22>
ffffffffc02017ee:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02017f2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02017f4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02017f8:	f7f5                	bnez	a5,ffffffffc02017e4 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02017fa:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02017fe:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201800:	4501                	li	a0,0
ffffffffc0201802:	8082                	ret

ffffffffc0201804 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201804:	ca01                	beqz	a2,ffffffffc0201814 <memset+0x10>
ffffffffc0201806:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201808:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020180a:	0785                	addi	a5,a5,1
ffffffffc020180c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201810:	fec79de3          	bne	a5,a2,ffffffffc020180a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201814:	8082                	ret
