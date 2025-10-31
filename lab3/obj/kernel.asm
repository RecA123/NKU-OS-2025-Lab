
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
ffffffffc0200034:	18029073          	csrw	satp,t0
ffffffffc0200038:	12000073          	sfence.vma
ffffffffc020003c:	c0206137          	lui	sp,0xc0206
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
ffffffffc0200044:	00030313          	mv	t1,t1
ffffffffc0200048:	811a                	mv	sp,t1
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
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
ffffffffc020006c:	70b010ef          	jal	ra,ffffffffc0201f76 <memset>
    dtb_init();
ffffffffc0200070:	41e000ef          	jal	ra,ffffffffc020048e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	40c000ef          	jal	ra,ffffffffc0200480 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f3050513          	addi	a0,a0,-208 # ffffffffc0201fa8 <etext+0x20>
ffffffffc0200080:	0a0000ef          	jal	ra,ffffffffc0200120 <cputs>

    print_kerninfo();
ffffffffc0200084:	0ec000ef          	jal	ra,ffffffffc0200170 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7c2000ef          	jal	ra,ffffffffc020084a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	76e010ef          	jal	ra,ffffffffc02017fa <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7ba000ef          	jal	ra,ffffffffc020084a <idt_init>

    cprintf("非法指令异常测试...\n");
ffffffffc0200094:	00002517          	auipc	a0,0x2
ffffffffc0200098:	ef450513          	addi	a0,a0,-268 # ffffffffc0201f88 <etext>
ffffffffc020009c:	04c000ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02000a0:	0000                	unimp
ffffffffc02000a2:	0000                	unimp
    __asm__ volatile(".word 0x00000000"); 

    // cprintf("断点异常测试...\n");
    // __asm__ volatile("ebreak"); 

    clock_init();   // init clock interrupt
ffffffffc02000a4:	39a000ef          	jal	ra,ffffffffc020043e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc02000a8:	796000ef          	jal	ra,ffffffffc020083e <intr_enable>

    /* do nothing */
    while (1)
ffffffffc02000ac:	a001                	j	ffffffffc02000ac <kern_init+0x58>

ffffffffc02000ae <cputch>:
ffffffffc02000ae:	1141                	addi	sp,sp,-16
ffffffffc02000b0:	e022                	sd	s0,0(sp)
ffffffffc02000b2:	e406                	sd	ra,8(sp)
ffffffffc02000b4:	842e                	mv	s0,a1
ffffffffc02000b6:	3cc000ef          	jal	ra,ffffffffc0200482 <cons_putc>
ffffffffc02000ba:	401c                	lw	a5,0(s0)
ffffffffc02000bc:	60a2                	ld	ra,8(sp)
ffffffffc02000be:	2785                	addiw	a5,a5,1
ffffffffc02000c0:	c01c                	sw	a5,0(s0)
ffffffffc02000c2:	6402                	ld	s0,0(sp)
ffffffffc02000c4:	0141                	addi	sp,sp,16
ffffffffc02000c6:	8082                	ret

ffffffffc02000c8 <vcprintf>:
ffffffffc02000c8:	1101                	addi	sp,sp,-32
ffffffffc02000ca:	862a                	mv	a2,a0
ffffffffc02000cc:	86ae                	mv	a3,a1
ffffffffc02000ce:	00000517          	auipc	a0,0x0
ffffffffc02000d2:	fe050513          	addi	a0,a0,-32 # ffffffffc02000ae <cputch>
ffffffffc02000d6:	006c                	addi	a1,sp,12
ffffffffc02000d8:	ec06                	sd	ra,24(sp)
ffffffffc02000da:	c602                	sw	zero,12(sp)
ffffffffc02000dc:	16b010ef          	jal	ra,ffffffffc0201a46 <vprintfmt>
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4532                	lw	a0,12(sp)
ffffffffc02000e4:	6105                	addi	sp,sp,32
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cprintf>:
ffffffffc02000e8:	711d                	addi	sp,sp,-96
ffffffffc02000ea:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
ffffffffc02000ee:	8e2a                	mv	t3,a0
ffffffffc02000f0:	f42e                	sd	a1,40(sp)
ffffffffc02000f2:	f832                	sd	a2,48(sp)
ffffffffc02000f4:	fc36                	sd	a3,56(sp)
ffffffffc02000f6:	00000517          	auipc	a0,0x0
ffffffffc02000fa:	fb850513          	addi	a0,a0,-72 # ffffffffc02000ae <cputch>
ffffffffc02000fe:	004c                	addi	a1,sp,4
ffffffffc0200100:	869a                	mv	a3,t1
ffffffffc0200102:	8672                	mv	a2,t3
ffffffffc0200104:	ec06                	sd	ra,24(sp)
ffffffffc0200106:	e0ba                	sd	a4,64(sp)
ffffffffc0200108:	e4be                	sd	a5,72(sp)
ffffffffc020010a:	e8c2                	sd	a6,80(sp)
ffffffffc020010c:	ecc6                	sd	a7,88(sp)
ffffffffc020010e:	e41a                	sd	t1,8(sp)
ffffffffc0200110:	c202                	sw	zero,4(sp)
ffffffffc0200112:	135010ef          	jal	ra,ffffffffc0201a46 <vprintfmt>
ffffffffc0200116:	60e2                	ld	ra,24(sp)
ffffffffc0200118:	4512                	lw	a0,4(sp)
ffffffffc020011a:	6125                	addi	sp,sp,96
ffffffffc020011c:	8082                	ret

ffffffffc020011e <cputchar>:
ffffffffc020011e:	a695                	j	ffffffffc0200482 <cons_putc>

ffffffffc0200120 <cputs>:
ffffffffc0200120:	1101                	addi	sp,sp,-32
ffffffffc0200122:	e822                	sd	s0,16(sp)
ffffffffc0200124:	ec06                	sd	ra,24(sp)
ffffffffc0200126:	e426                	sd	s1,8(sp)
ffffffffc0200128:	842a                	mv	s0,a0
ffffffffc020012a:	00054503          	lbu	a0,0(a0)
ffffffffc020012e:	c51d                	beqz	a0,ffffffffc020015c <cputs+0x3c>
ffffffffc0200130:	0405                	addi	s0,s0,1
ffffffffc0200132:	4485                	li	s1,1
ffffffffc0200134:	9c81                	subw	s1,s1,s0
ffffffffc0200136:	34c000ef          	jal	ra,ffffffffc0200482 <cons_putc>
ffffffffc020013a:	00044503          	lbu	a0,0(s0)
ffffffffc020013e:	008487bb          	addw	a5,s1,s0
ffffffffc0200142:	0405                	addi	s0,s0,1
ffffffffc0200144:	f96d                	bnez	a0,ffffffffc0200136 <cputs+0x16>
ffffffffc0200146:	0017841b          	addiw	s0,a5,1
ffffffffc020014a:	4529                	li	a0,10
ffffffffc020014c:	336000ef          	jal	ra,ffffffffc0200482 <cons_putc>
ffffffffc0200150:	60e2                	ld	ra,24(sp)
ffffffffc0200152:	8522                	mv	a0,s0
ffffffffc0200154:	6442                	ld	s0,16(sp)
ffffffffc0200156:	64a2                	ld	s1,8(sp)
ffffffffc0200158:	6105                	addi	sp,sp,32
ffffffffc020015a:	8082                	ret
ffffffffc020015c:	4405                	li	s0,1
ffffffffc020015e:	b7f5                	j	ffffffffc020014a <cputs+0x2a>

ffffffffc0200160 <getchar>:
ffffffffc0200160:	1141                	addi	sp,sp,-16
ffffffffc0200162:	e406                	sd	ra,8(sp)
ffffffffc0200164:	326000ef          	jal	ra,ffffffffc020048a <cons_getc>
ffffffffc0200168:	dd75                	beqz	a0,ffffffffc0200164 <getchar+0x4>
ffffffffc020016a:	60a2                	ld	ra,8(sp)
ffffffffc020016c:	0141                	addi	sp,sp,16
ffffffffc020016e:	8082                	ret

ffffffffc0200170 <print_kerninfo>:
ffffffffc0200170:	1141                	addi	sp,sp,-16
ffffffffc0200172:	00002517          	auipc	a0,0x2
ffffffffc0200176:	e5650513          	addi	a0,a0,-426 # ffffffffc0201fc8 <etext+0x40>
ffffffffc020017a:	e406                	sd	ra,8(sp)
ffffffffc020017c:	f6dff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0200180:	00000597          	auipc	a1,0x0
ffffffffc0200184:	ed458593          	addi	a1,a1,-300 # ffffffffc0200054 <kern_init>
ffffffffc0200188:	00002517          	auipc	a0,0x2
ffffffffc020018c:	e6050513          	addi	a0,a0,-416 # ffffffffc0201fe8 <etext+0x60>
ffffffffc0200190:	f59ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0200194:	00002597          	auipc	a1,0x2
ffffffffc0200198:	df458593          	addi	a1,a1,-524 # ffffffffc0201f88 <etext>
ffffffffc020019c:	00002517          	auipc	a0,0x2
ffffffffc02001a0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0202008 <etext+0x80>
ffffffffc02001a4:	f45ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02001a8:	00007597          	auipc	a1,0x7
ffffffffc02001ac:	e8058593          	addi	a1,a1,-384 # ffffffffc0207028 <free_area>
ffffffffc02001b0:	00002517          	auipc	a0,0x2
ffffffffc02001b4:	e7850513          	addi	a0,a0,-392 # ffffffffc0202028 <etext+0xa0>
ffffffffc02001b8:	f31ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02001bc:	00007597          	auipc	a1,0x7
ffffffffc02001c0:	2e458593          	addi	a1,a1,740 # ffffffffc02074a0 <end>
ffffffffc02001c4:	00002517          	auipc	a0,0x2
ffffffffc02001c8:	e8450513          	addi	a0,a0,-380 # ffffffffc0202048 <etext+0xc0>
ffffffffc02001cc:	f1dff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02001d0:	00007597          	auipc	a1,0x7
ffffffffc02001d4:	6cf58593          	addi	a1,a1,1743 # ffffffffc020789f <end+0x3ff>
ffffffffc02001d8:	00000797          	auipc	a5,0x0
ffffffffc02001dc:	e7c78793          	addi	a5,a5,-388 # ffffffffc0200054 <kern_init>
ffffffffc02001e0:	40f587b3          	sub	a5,a1,a5
ffffffffc02001e4:	43f7d593          	srai	a1,a5,0x3f
ffffffffc02001e8:	60a2                	ld	ra,8(sp)
ffffffffc02001ea:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001ee:	95be                	add	a1,a1,a5
ffffffffc02001f0:	85a9                	srai	a1,a1,0xa
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	e7650513          	addi	a0,a0,-394 # ffffffffc0202068 <etext+0xe0>
ffffffffc02001fa:	0141                	addi	sp,sp,16
ffffffffc02001fc:	b5f5                	j	ffffffffc02000e8 <cprintf>

ffffffffc02001fe <print_stackframe>:
ffffffffc02001fe:	1141                	addi	sp,sp,-16
ffffffffc0200200:	00002617          	auipc	a2,0x2
ffffffffc0200204:	e9860613          	addi	a2,a2,-360 # ffffffffc0202098 <etext+0x110>
ffffffffc0200208:	04d00593          	li	a1,77
ffffffffc020020c:	00002517          	auipc	a0,0x2
ffffffffc0200210:	ea450513          	addi	a0,a0,-348 # ffffffffc02020b0 <etext+0x128>
ffffffffc0200214:	e406                	sd	ra,8(sp)
ffffffffc0200216:	1cc000ef          	jal	ra,ffffffffc02003e2 <__panic>

ffffffffc020021a <mon_help>:
ffffffffc020021a:	1141                	addi	sp,sp,-16
ffffffffc020021c:	00002617          	auipc	a2,0x2
ffffffffc0200220:	eac60613          	addi	a2,a2,-340 # ffffffffc02020c8 <etext+0x140>
ffffffffc0200224:	00002597          	auipc	a1,0x2
ffffffffc0200228:	ec458593          	addi	a1,a1,-316 # ffffffffc02020e8 <etext+0x160>
ffffffffc020022c:	00002517          	auipc	a0,0x2
ffffffffc0200230:	ec450513          	addi	a0,a0,-316 # ffffffffc02020f0 <etext+0x168>
ffffffffc0200234:	e406                	sd	ra,8(sp)
ffffffffc0200236:	eb3ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc020023a:	00002617          	auipc	a2,0x2
ffffffffc020023e:	ec660613          	addi	a2,a2,-314 # ffffffffc0202100 <etext+0x178>
ffffffffc0200242:	00002597          	auipc	a1,0x2
ffffffffc0200246:	ee658593          	addi	a1,a1,-282 # ffffffffc0202128 <etext+0x1a0>
ffffffffc020024a:	00002517          	auipc	a0,0x2
ffffffffc020024e:	ea650513          	addi	a0,a0,-346 # ffffffffc02020f0 <etext+0x168>
ffffffffc0200252:	e97ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0200256:	00002617          	auipc	a2,0x2
ffffffffc020025a:	ee260613          	addi	a2,a2,-286 # ffffffffc0202138 <etext+0x1b0>
ffffffffc020025e:	00002597          	auipc	a1,0x2
ffffffffc0200262:	efa58593          	addi	a1,a1,-262 # ffffffffc0202158 <etext+0x1d0>
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	e8a50513          	addi	a0,a0,-374 # ffffffffc02020f0 <etext+0x168>
ffffffffc020026e:	e7bff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_kerninfo>:
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
ffffffffc020027e:	ef3ff0ef          	jal	ra,ffffffffc0200170 <print_kerninfo>
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <mon_backtrace>:
ffffffffc020028a:	1141                	addi	sp,sp,-16
ffffffffc020028c:	e406                	sd	ra,8(sp)
ffffffffc020028e:	f71ff0ef          	jal	ra,ffffffffc02001fe <print_stackframe>
ffffffffc0200292:	60a2                	ld	ra,8(sp)
ffffffffc0200294:	4501                	li	a0,0
ffffffffc0200296:	0141                	addi	sp,sp,16
ffffffffc0200298:	8082                	ret

ffffffffc020029a <kmonitor>:
ffffffffc020029a:	7115                	addi	sp,sp,-224
ffffffffc020029c:	ed5e                	sd	s7,152(sp)
ffffffffc020029e:	8baa                	mv	s7,a0
ffffffffc02002a0:	00002517          	auipc	a0,0x2
ffffffffc02002a4:	ec850513          	addi	a0,a0,-312 # ffffffffc0202168 <etext+0x1e0>
ffffffffc02002a8:	ed86                	sd	ra,216(sp)
ffffffffc02002aa:	e9a2                	sd	s0,208(sp)
ffffffffc02002ac:	e5a6                	sd	s1,200(sp)
ffffffffc02002ae:	e1ca                	sd	s2,192(sp)
ffffffffc02002b0:	fd4e                	sd	s3,184(sp)
ffffffffc02002b2:	f952                	sd	s4,176(sp)
ffffffffc02002b4:	f556                	sd	s5,168(sp)
ffffffffc02002b6:	f15a                	sd	s6,160(sp)
ffffffffc02002b8:	e962                	sd	s8,144(sp)
ffffffffc02002ba:	e566                	sd	s9,136(sp)
ffffffffc02002bc:	e16a                	sd	s10,128(sp)
ffffffffc02002be:	e2bff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02002c2:	00002517          	auipc	a0,0x2
ffffffffc02002c6:	ece50513          	addi	a0,a0,-306 # ffffffffc0202190 <etext+0x208>
ffffffffc02002ca:	e1fff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02002ce:	000b8563          	beqz	s7,ffffffffc02002d8 <kmonitor+0x3e>
ffffffffc02002d2:	855e                	mv	a0,s7
ffffffffc02002d4:	756000ef          	jal	ra,ffffffffc0200a2a <print_trapframe>
ffffffffc02002d8:	00002c17          	auipc	s8,0x2
ffffffffc02002dc:	f28c0c13          	addi	s8,s8,-216 # ffffffffc0202200 <commands>
ffffffffc02002e0:	00002917          	auipc	s2,0x2
ffffffffc02002e4:	ed890913          	addi	s2,s2,-296 # ffffffffc02021b8 <etext+0x230>
ffffffffc02002e8:	00002497          	auipc	s1,0x2
ffffffffc02002ec:	ed848493          	addi	s1,s1,-296 # ffffffffc02021c0 <etext+0x238>
ffffffffc02002f0:	49bd                	li	s3,15
ffffffffc02002f2:	00002b17          	auipc	s6,0x2
ffffffffc02002f6:	ed6b0b13          	addi	s6,s6,-298 # ffffffffc02021c8 <etext+0x240>
ffffffffc02002fa:	00002a17          	auipc	s4,0x2
ffffffffc02002fe:	deea0a13          	addi	s4,s4,-530 # ffffffffc02020e8 <etext+0x160>
ffffffffc0200302:	4a8d                	li	s5,3
ffffffffc0200304:	854a                	mv	a0,s2
ffffffffc0200306:	2c3010ef          	jal	ra,ffffffffc0201dc8 <readline>
ffffffffc020030a:	842a                	mv	s0,a0
ffffffffc020030c:	dd65                	beqz	a0,ffffffffc0200304 <kmonitor+0x6a>
ffffffffc020030e:	00054583          	lbu	a1,0(a0)
ffffffffc0200312:	4c81                	li	s9,0
ffffffffc0200314:	e1bd                	bnez	a1,ffffffffc020037a <kmonitor+0xe0>
ffffffffc0200316:	fe0c87e3          	beqz	s9,ffffffffc0200304 <kmonitor+0x6a>
ffffffffc020031a:	6582                	ld	a1,0(sp)
ffffffffc020031c:	00002d17          	auipc	s10,0x2
ffffffffc0200320:	ee4d0d13          	addi	s10,s10,-284 # ffffffffc0202200 <commands>
ffffffffc0200324:	8552                	mv	a0,s4
ffffffffc0200326:	4401                	li	s0,0
ffffffffc0200328:	0d61                	addi	s10,s10,24
ffffffffc020032a:	3f3010ef          	jal	ra,ffffffffc0201f1c <strcmp>
ffffffffc020032e:	c919                	beqz	a0,ffffffffc0200344 <kmonitor+0xaa>
ffffffffc0200330:	2405                	addiw	s0,s0,1
ffffffffc0200332:	0b540063          	beq	s0,s5,ffffffffc02003d2 <kmonitor+0x138>
ffffffffc0200336:	000d3503          	ld	a0,0(s10)
ffffffffc020033a:	6582                	ld	a1,0(sp)
ffffffffc020033c:	0d61                	addi	s10,s10,24
ffffffffc020033e:	3df010ef          	jal	ra,ffffffffc0201f1c <strcmp>
ffffffffc0200342:	f57d                	bnez	a0,ffffffffc0200330 <kmonitor+0x96>
ffffffffc0200344:	00141793          	slli	a5,s0,0x1
ffffffffc0200348:	97a2                	add	a5,a5,s0
ffffffffc020034a:	078e                	slli	a5,a5,0x3
ffffffffc020034c:	97e2                	add	a5,a5,s8
ffffffffc020034e:	6b9c                	ld	a5,16(a5)
ffffffffc0200350:	865e                	mv	a2,s7
ffffffffc0200352:	002c                	addi	a1,sp,8
ffffffffc0200354:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200358:	9782                	jalr	a5
ffffffffc020035a:	fa0555e3          	bgez	a0,ffffffffc0200304 <kmonitor+0x6a>
ffffffffc020035e:	60ee                	ld	ra,216(sp)
ffffffffc0200360:	644e                	ld	s0,208(sp)
ffffffffc0200362:	64ae                	ld	s1,200(sp)
ffffffffc0200364:	690e                	ld	s2,192(sp)
ffffffffc0200366:	79ea                	ld	s3,184(sp)
ffffffffc0200368:	7a4a                	ld	s4,176(sp)
ffffffffc020036a:	7aaa                	ld	s5,168(sp)
ffffffffc020036c:	7b0a                	ld	s6,160(sp)
ffffffffc020036e:	6bea                	ld	s7,152(sp)
ffffffffc0200370:	6c4a                	ld	s8,144(sp)
ffffffffc0200372:	6caa                	ld	s9,136(sp)
ffffffffc0200374:	6d0a                	ld	s10,128(sp)
ffffffffc0200376:	612d                	addi	sp,sp,224
ffffffffc0200378:	8082                	ret
ffffffffc020037a:	8526                	mv	a0,s1
ffffffffc020037c:	3e5010ef          	jal	ra,ffffffffc0201f60 <strchr>
ffffffffc0200380:	c901                	beqz	a0,ffffffffc0200390 <kmonitor+0xf6>
ffffffffc0200382:	00144583          	lbu	a1,1(s0)
ffffffffc0200386:	00040023          	sb	zero,0(s0)
ffffffffc020038a:	0405                	addi	s0,s0,1
ffffffffc020038c:	d5c9                	beqz	a1,ffffffffc0200316 <kmonitor+0x7c>
ffffffffc020038e:	b7f5                	j	ffffffffc020037a <kmonitor+0xe0>
ffffffffc0200390:	00044783          	lbu	a5,0(s0)
ffffffffc0200394:	d3c9                	beqz	a5,ffffffffc0200316 <kmonitor+0x7c>
ffffffffc0200396:	033c8963          	beq	s9,s3,ffffffffc02003c8 <kmonitor+0x12e>
ffffffffc020039a:	003c9793          	slli	a5,s9,0x3
ffffffffc020039e:	0118                	addi	a4,sp,128
ffffffffc02003a0:	97ba                	add	a5,a5,a4
ffffffffc02003a2:	f887b023          	sd	s0,-128(a5)
ffffffffc02003a6:	00044583          	lbu	a1,0(s0)
ffffffffc02003aa:	2c85                	addiw	s9,s9,1
ffffffffc02003ac:	e591                	bnez	a1,ffffffffc02003b8 <kmonitor+0x11e>
ffffffffc02003ae:	b7b5                	j	ffffffffc020031a <kmonitor+0x80>
ffffffffc02003b0:	00144583          	lbu	a1,1(s0)
ffffffffc02003b4:	0405                	addi	s0,s0,1
ffffffffc02003b6:	d1a5                	beqz	a1,ffffffffc0200316 <kmonitor+0x7c>
ffffffffc02003b8:	8526                	mv	a0,s1
ffffffffc02003ba:	3a7010ef          	jal	ra,ffffffffc0201f60 <strchr>
ffffffffc02003be:	d96d                	beqz	a0,ffffffffc02003b0 <kmonitor+0x116>
ffffffffc02003c0:	00044583          	lbu	a1,0(s0)
ffffffffc02003c4:	d9a9                	beqz	a1,ffffffffc0200316 <kmonitor+0x7c>
ffffffffc02003c6:	bf55                	j	ffffffffc020037a <kmonitor+0xe0>
ffffffffc02003c8:	45c1                	li	a1,16
ffffffffc02003ca:	855a                	mv	a0,s6
ffffffffc02003cc:	d1dff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02003d0:	b7e9                	j	ffffffffc020039a <kmonitor+0x100>
ffffffffc02003d2:	6582                	ld	a1,0(sp)
ffffffffc02003d4:	00002517          	auipc	a0,0x2
ffffffffc02003d8:	e1450513          	addi	a0,a0,-492 # ffffffffc02021e8 <etext+0x260>
ffffffffc02003dc:	d0dff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02003e0:	b715                	j	ffffffffc0200304 <kmonitor+0x6a>

ffffffffc02003e2 <__panic>:
ffffffffc02003e2:	00007317          	auipc	t1,0x7
ffffffffc02003e6:	05e30313          	addi	t1,t1,94 # ffffffffc0207440 <is_panic>
ffffffffc02003ea:	00032e03          	lw	t3,0(t1)
ffffffffc02003ee:	715d                	addi	sp,sp,-80
ffffffffc02003f0:	ec06                	sd	ra,24(sp)
ffffffffc02003f2:	e822                	sd	s0,16(sp)
ffffffffc02003f4:	f436                	sd	a3,40(sp)
ffffffffc02003f6:	f83a                	sd	a4,48(sp)
ffffffffc02003f8:	fc3e                	sd	a5,56(sp)
ffffffffc02003fa:	e0c2                	sd	a6,64(sp)
ffffffffc02003fc:	e4c6                	sd	a7,72(sp)
ffffffffc02003fe:	020e1a63          	bnez	t3,ffffffffc0200432 <__panic+0x50>
ffffffffc0200402:	4785                	li	a5,1
ffffffffc0200404:	00f32023          	sw	a5,0(t1)
ffffffffc0200408:	8432                	mv	s0,a2
ffffffffc020040a:	103c                	addi	a5,sp,40
ffffffffc020040c:	862e                	mv	a2,a1
ffffffffc020040e:	85aa                	mv	a1,a0
ffffffffc0200410:	00002517          	auipc	a0,0x2
ffffffffc0200414:	e3850513          	addi	a0,a0,-456 # ffffffffc0202248 <commands+0x48>
ffffffffc0200418:	e43e                	sd	a5,8(sp)
ffffffffc020041a:	ccfff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc020041e:	65a2                	ld	a1,8(sp)
ffffffffc0200420:	8522                	mv	a0,s0
ffffffffc0200422:	ca7ff0ef          	jal	ra,ffffffffc02000c8 <vcprintf>
ffffffffc0200426:	00002517          	auipc	a0,0x2
ffffffffc020042a:	3e250513          	addi	a0,a0,994 # ffffffffc0202808 <commands+0x608>
ffffffffc020042e:	cbbff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0200432:	412000ef          	jal	ra,ffffffffc0200844 <intr_disable>
ffffffffc0200436:	4501                	li	a0,0
ffffffffc0200438:	e63ff0ef          	jal	ra,ffffffffc020029a <kmonitor>
ffffffffc020043c:	bfed                	j	ffffffffc0200436 <__panic+0x54>

ffffffffc020043e <clock_init>:
ffffffffc020043e:	1141                	addi	sp,sp,-16
ffffffffc0200440:	e406                	sd	ra,8(sp)
ffffffffc0200442:	02000793          	li	a5,32
ffffffffc0200446:	1047a7f3          	csrrs	a5,sie,a5
ffffffffc020044a:	c0102573          	rdtime	a0
ffffffffc020044e:	67e1                	lui	a5,0x18
ffffffffc0200450:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200454:	953e                	add	a0,a0,a5
ffffffffc0200456:	241010ef          	jal	ra,ffffffffc0201e96 <sbi_set_timer>
ffffffffc020045a:	60a2                	ld	ra,8(sp)
ffffffffc020045c:	00007797          	auipc	a5,0x7
ffffffffc0200460:	fe07b623          	sd	zero,-20(a5) # ffffffffc0207448 <ticks>
ffffffffc0200464:	00002517          	auipc	a0,0x2
ffffffffc0200468:	e0450513          	addi	a0,a0,-508 # ffffffffc0202268 <commands+0x68>
ffffffffc020046c:	0141                	addi	sp,sp,16
ffffffffc020046e:	b9ad                	j	ffffffffc02000e8 <cprintf>

ffffffffc0200470 <clock_set_next_event>:
ffffffffc0200470:	c0102573          	rdtime	a0
ffffffffc0200474:	67e1                	lui	a5,0x18
ffffffffc0200476:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020047a:	953e                	add	a0,a0,a5
ffffffffc020047c:	21b0106f          	j	ffffffffc0201e96 <sbi_set_timer>

ffffffffc0200480 <cons_init>:
ffffffffc0200480:	8082                	ret

ffffffffc0200482 <cons_putc>:
ffffffffc0200482:	0ff57513          	zext.b	a0,a0
ffffffffc0200486:	1f70106f          	j	ffffffffc0201e7c <sbi_console_putchar>

ffffffffc020048a <cons_getc>:
ffffffffc020048a:	2270106f          	j	ffffffffc0201eb0 <sbi_console_getchar>

ffffffffc020048e <dtb_init>:
ffffffffc020048e:	7119                	addi	sp,sp,-128
ffffffffc0200490:	00002517          	auipc	a0,0x2
ffffffffc0200494:	df850513          	addi	a0,a0,-520 # ffffffffc0202288 <commands+0x88>
ffffffffc0200498:	fc86                	sd	ra,120(sp)
ffffffffc020049a:	f8a2                	sd	s0,112(sp)
ffffffffc020049c:	e8d2                	sd	s4,80(sp)
ffffffffc020049e:	f4a6                	sd	s1,104(sp)
ffffffffc02004a0:	f0ca                	sd	s2,96(sp)
ffffffffc02004a2:	ecce                	sd	s3,88(sp)
ffffffffc02004a4:	e4d6                	sd	s5,72(sp)
ffffffffc02004a6:	e0da                	sd	s6,64(sp)
ffffffffc02004a8:	fc5e                	sd	s7,56(sp)
ffffffffc02004aa:	f862                	sd	s8,48(sp)
ffffffffc02004ac:	f466                	sd	s9,40(sp)
ffffffffc02004ae:	f06a                	sd	s10,32(sp)
ffffffffc02004b0:	ec6e                	sd	s11,24(sp)
ffffffffc02004b2:	c37ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02004b6:	00007597          	auipc	a1,0x7
ffffffffc02004ba:	b4a5b583          	ld	a1,-1206(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	dda50513          	addi	a0,a0,-550 # ffffffffc0202298 <commands+0x98>
ffffffffc02004c6:	c23ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02004ca:	00007417          	auipc	s0,0x7
ffffffffc02004ce:	b3e40413          	addi	s0,s0,-1218 # ffffffffc0207008 <boot_dtb>
ffffffffc02004d2:	600c                	ld	a1,0(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	dd450513          	addi	a0,a0,-556 # ffffffffc02022a8 <commands+0xa8>
ffffffffc02004dc:	c0dff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02004e0:	00043a03          	ld	s4,0(s0)
ffffffffc02004e4:	00002517          	auipc	a0,0x2
ffffffffc02004e8:	ddc50513          	addi	a0,a0,-548 # ffffffffc02022c0 <commands+0xc0>
ffffffffc02004ec:	120a0463          	beqz	s4,ffffffffc0200614 <dtb_init+0x186>
ffffffffc02004f0:	57f5                	li	a5,-3
ffffffffc02004f2:	07fa                	slli	a5,a5,0x1e
ffffffffc02004f4:	00fa0733          	add	a4,s4,a5
ffffffffc02004f8:	431c                	lw	a5,0(a4)
ffffffffc02004fa:	00ff0637          	lui	a2,0xff0
ffffffffc02004fe:	6b41                	lui	s6,0x10
ffffffffc0200500:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200504:	0187969b          	slliw	a3,a5,0x18
ffffffffc0200508:	0187d51b          	srliw	a0,a5,0x18
ffffffffc020050c:	0105959b          	slliw	a1,a1,0x10
ffffffffc0200510:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200514:	8df1                	and	a1,a1,a2
ffffffffc0200516:	8ec9                	or	a3,a3,a0
ffffffffc0200518:	0087979b          	slliw	a5,a5,0x8
ffffffffc020051c:	1b7d                	addi	s6,s6,-1
ffffffffc020051e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200522:	8dd5                	or	a1,a1,a3
ffffffffc0200524:	8ddd                	or	a1,a1,a5
ffffffffc0200526:	d00e07b7          	lui	a5,0xd00e0
ffffffffc020052a:	2581                	sext.w	a1,a1
ffffffffc020052c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200530:	10f59163          	bne	a1,a5,ffffffffc0200632 <dtb_init+0x1a4>
ffffffffc0200534:	471c                	lw	a5,8(a4)
ffffffffc0200536:	4754                	lw	a3,12(a4)
ffffffffc0200538:	4c81                	li	s9,0
ffffffffc020053a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020053e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200542:	0186941b          	slliw	s0,a3,0x18
ffffffffc0200546:	0186d89b          	srliw	a7,a3,0x18
ffffffffc020054a:	01879a1b          	slliw	s4,a5,0x18
ffffffffc020054e:	0187d81b          	srliw	a6,a5,0x18
ffffffffc0200552:	0105151b          	slliw	a0,a0,0x10
ffffffffc0200556:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020055a:	0105959b          	slliw	a1,a1,0x10
ffffffffc020055e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200562:	8d71                	and	a0,a0,a2
ffffffffc0200564:	01146433          	or	s0,s0,a7
ffffffffc0200568:	0086969b          	slliw	a3,a3,0x8
ffffffffc020056c:	010a6a33          	or	s4,s4,a6
ffffffffc0200570:	8e6d                	and	a2,a2,a1
ffffffffc0200572:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200576:	8c49                	or	s0,s0,a0
ffffffffc0200578:	0166f6b3          	and	a3,a3,s6
ffffffffc020057c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200580:	0167f7b3          	and	a5,a5,s6
ffffffffc0200584:	8c55                	or	s0,s0,a3
ffffffffc0200586:	00fa6a33          	or	s4,s4,a5
ffffffffc020058a:	1402                	slli	s0,s0,0x20
ffffffffc020058c:	1a02                	slli	s4,s4,0x20
ffffffffc020058e:	9001                	srli	s0,s0,0x20
ffffffffc0200590:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200594:	943a                	add	s0,s0,a4
ffffffffc0200596:	9a3a                	add	s4,s4,a4
ffffffffc0200598:	00ff0c37          	lui	s8,0xff0
ffffffffc020059c:	4b8d                	li	s7,3
ffffffffc020059e:	00002917          	auipc	s2,0x2
ffffffffc02005a2:	d7290913          	addi	s2,s2,-654 # ffffffffc0202310 <commands+0x110>
ffffffffc02005a6:	49bd                	li	s3,15
ffffffffc02005a8:	4d91                	li	s11,4
ffffffffc02005aa:	4d05                	li	s10,1
ffffffffc02005ac:	00002497          	auipc	s1,0x2
ffffffffc02005b0:	d5c48493          	addi	s1,s1,-676 # ffffffffc0202308 <commands+0x108>
ffffffffc02005b4:	000a2703          	lw	a4,0(s4)
ffffffffc02005b8:	004a0a93          	addi	s5,s4,4
ffffffffc02005bc:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005c0:	0187179b          	slliw	a5,a4,0x18
ffffffffc02005c4:	0187561b          	srliw	a2,a4,0x18
ffffffffc02005c8:	0106969b          	slliw	a3,a3,0x10
ffffffffc02005cc:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005d0:	8fd1                	or	a5,a5,a2
ffffffffc02005d2:	0186f6b3          	and	a3,a3,s8
ffffffffc02005d6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005da:	8fd5                	or	a5,a5,a3
ffffffffc02005dc:	00eb7733          	and	a4,s6,a4
ffffffffc02005e0:	8fd9                	or	a5,a5,a4
ffffffffc02005e2:	2781                	sext.w	a5,a5
ffffffffc02005e4:	09778c63          	beq	a5,s7,ffffffffc020067c <dtb_init+0x1ee>
ffffffffc02005e8:	00fbea63          	bltu	s7,a5,ffffffffc02005fc <dtb_init+0x16e>
ffffffffc02005ec:	07a78663          	beq	a5,s10,ffffffffc0200658 <dtb_init+0x1ca>
ffffffffc02005f0:	4709                	li	a4,2
ffffffffc02005f2:	00e79763          	bne	a5,a4,ffffffffc0200600 <dtb_init+0x172>
ffffffffc02005f6:	4c81                	li	s9,0
ffffffffc02005f8:	8a56                	mv	s4,s5
ffffffffc02005fa:	bf6d                	j	ffffffffc02005b4 <dtb_init+0x126>
ffffffffc02005fc:	ffb78ee3          	beq	a5,s11,ffffffffc02005f8 <dtb_init+0x16a>
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	d8850513          	addi	a0,a0,-632 # ffffffffc0202388 <commands+0x188>
ffffffffc0200608:	ae1ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc020060c:	00002517          	auipc	a0,0x2
ffffffffc0200610:	db450513          	addi	a0,a0,-588 # ffffffffc02023c0 <commands+0x1c0>
ffffffffc0200614:	7446                	ld	s0,112(sp)
ffffffffc0200616:	70e6                	ld	ra,120(sp)
ffffffffc0200618:	74a6                	ld	s1,104(sp)
ffffffffc020061a:	7906                	ld	s2,96(sp)
ffffffffc020061c:	69e6                	ld	s3,88(sp)
ffffffffc020061e:	6a46                	ld	s4,80(sp)
ffffffffc0200620:	6aa6                	ld	s5,72(sp)
ffffffffc0200622:	6b06                	ld	s6,64(sp)
ffffffffc0200624:	7be2                	ld	s7,56(sp)
ffffffffc0200626:	7c42                	ld	s8,48(sp)
ffffffffc0200628:	7ca2                	ld	s9,40(sp)
ffffffffc020062a:	7d02                	ld	s10,32(sp)
ffffffffc020062c:	6de2                	ld	s11,24(sp)
ffffffffc020062e:	6109                	addi	sp,sp,128
ffffffffc0200630:	bc65                	j	ffffffffc02000e8 <cprintf>
ffffffffc0200632:	7446                	ld	s0,112(sp)
ffffffffc0200634:	70e6                	ld	ra,120(sp)
ffffffffc0200636:	74a6                	ld	s1,104(sp)
ffffffffc0200638:	7906                	ld	s2,96(sp)
ffffffffc020063a:	69e6                	ld	s3,88(sp)
ffffffffc020063c:	6a46                	ld	s4,80(sp)
ffffffffc020063e:	6aa6                	ld	s5,72(sp)
ffffffffc0200640:	6b06                	ld	s6,64(sp)
ffffffffc0200642:	7be2                	ld	s7,56(sp)
ffffffffc0200644:	7c42                	ld	s8,48(sp)
ffffffffc0200646:	7ca2                	ld	s9,40(sp)
ffffffffc0200648:	7d02                	ld	s10,32(sp)
ffffffffc020064a:	6de2                	ld	s11,24(sp)
ffffffffc020064c:	00002517          	auipc	a0,0x2
ffffffffc0200650:	c9450513          	addi	a0,a0,-876 # ffffffffc02022e0 <commands+0xe0>
ffffffffc0200654:	6109                	addi	sp,sp,128
ffffffffc0200656:	bc49                	j	ffffffffc02000e8 <cprintf>
ffffffffc0200658:	8556                	mv	a0,s5
ffffffffc020065a:	08d010ef          	jal	ra,ffffffffc0201ee6 <strlen>
ffffffffc020065e:	8a2a                	mv	s4,a0
ffffffffc0200660:	4619                	li	a2,6
ffffffffc0200662:	85a6                	mv	a1,s1
ffffffffc0200664:	8556                	mv	a0,s5
ffffffffc0200666:	2a01                	sext.w	s4,s4
ffffffffc0200668:	0d3010ef          	jal	ra,ffffffffc0201f3a <strncmp>
ffffffffc020066c:	e111                	bnez	a0,ffffffffc0200670 <dtb_init+0x1e2>
ffffffffc020066e:	4c85                	li	s9,1
ffffffffc0200670:	0a91                	addi	s5,s5,4
ffffffffc0200672:	9ad2                	add	s5,s5,s4
ffffffffc0200674:	ffcafa93          	andi	s5,s5,-4
ffffffffc0200678:	8a56                	mv	s4,s5
ffffffffc020067a:	bf2d                	j	ffffffffc02005b4 <dtb_init+0x126>
ffffffffc020067c:	004a2783          	lw	a5,4(s4)
ffffffffc0200680:	00ca0693          	addi	a3,s4,12
ffffffffc0200684:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200688:	01879a9b          	slliw	s5,a5,0x18
ffffffffc020068c:	0187d61b          	srliw	a2,a5,0x18
ffffffffc0200690:	0107171b          	slliw	a4,a4,0x10
ffffffffc0200694:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200698:	00caeab3          	or	s5,s5,a2
ffffffffc020069c:	01877733          	and	a4,a4,s8
ffffffffc02006a0:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006a4:	00eaeab3          	or	s5,s5,a4
ffffffffc02006a8:	00fb77b3          	and	a5,s6,a5
ffffffffc02006ac:	00faeab3          	or	s5,s5,a5
ffffffffc02006b0:	2a81                	sext.w	s5,s5
ffffffffc02006b2:	000c9c63          	bnez	s9,ffffffffc02006ca <dtb_init+0x23c>
ffffffffc02006b6:	1a82                	slli	s5,s5,0x20
ffffffffc02006b8:	00368793          	addi	a5,a3,3
ffffffffc02006bc:	020ada93          	srli	s5,s5,0x20
ffffffffc02006c0:	9abe                	add	s5,s5,a5
ffffffffc02006c2:	ffcafa93          	andi	s5,s5,-4
ffffffffc02006c6:	8a56                	mv	s4,s5
ffffffffc02006c8:	b5f5                	j	ffffffffc02005b4 <dtb_init+0x126>
ffffffffc02006ca:	008a2783          	lw	a5,8(s4)
ffffffffc02006ce:	85ca                	mv	a1,s2
ffffffffc02006d0:	e436                	sd	a3,8(sp)
ffffffffc02006d2:	0087d51b          	srliw	a0,a5,0x8
ffffffffc02006d6:	0187d61b          	srliw	a2,a5,0x18
ffffffffc02006da:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006de:	0105151b          	slliw	a0,a0,0x10
ffffffffc02006e2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006e6:	8f51                	or	a4,a4,a2
ffffffffc02006e8:	01857533          	and	a0,a0,s8
ffffffffc02006ec:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006f0:	8d59                	or	a0,a0,a4
ffffffffc02006f2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006f6:	8d5d                	or	a0,a0,a5
ffffffffc02006f8:	1502                	slli	a0,a0,0x20
ffffffffc02006fa:	9101                	srli	a0,a0,0x20
ffffffffc02006fc:	9522                	add	a0,a0,s0
ffffffffc02006fe:	01f010ef          	jal	ra,ffffffffc0201f1c <strcmp>
ffffffffc0200702:	66a2                	ld	a3,8(sp)
ffffffffc0200704:	f94d                	bnez	a0,ffffffffc02006b6 <dtb_init+0x228>
ffffffffc0200706:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006b6 <dtb_init+0x228>
ffffffffc020070a:	00ca3783          	ld	a5,12(s4)
ffffffffc020070e:	014a3703          	ld	a4,20(s4)
ffffffffc0200712:	00002517          	auipc	a0,0x2
ffffffffc0200716:	c0650513          	addi	a0,a0,-1018 # ffffffffc0202318 <commands+0x118>
ffffffffc020071a:	4207d613          	srai	a2,a5,0x20
ffffffffc020071e:	0087d31b          	srliw	t1,a5,0x8
ffffffffc0200722:	42075593          	srai	a1,a4,0x20
ffffffffc0200726:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020072a:	0186581b          	srliw	a6,a2,0x18
ffffffffc020072e:	0187941b          	slliw	s0,a5,0x18
ffffffffc0200732:	0107d89b          	srliw	a7,a5,0x10
ffffffffc0200736:	0187d693          	srli	a3,a5,0x18
ffffffffc020073a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020073e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200742:	0103131b          	slliw	t1,t1,0x10
ffffffffc0200746:	0106561b          	srliw	a2,a2,0x10
ffffffffc020074a:	010f6f33          	or	t5,t5,a6
ffffffffc020074e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200752:	0185df9b          	srliw	t6,a1,0x18
ffffffffc0200756:	01837333          	and	t1,t1,s8
ffffffffc020075a:	01c46433          	or	s0,s0,t3
ffffffffc020075e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200762:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200766:	01871e9b          	slliw	t4,a4,0x18
ffffffffc020076a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020076e:	0086161b          	slliw	a2,a2,0x8
ffffffffc0200772:	8361                	srli	a4,a4,0x18
ffffffffc0200774:	0107979b          	slliw	a5,a5,0x10
ffffffffc0200778:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020077c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200780:	00cb7633          	and	a2,s6,a2
ffffffffc0200784:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200788:	0085959b          	slliw	a1,a1,0x8
ffffffffc020078c:	00646433          	or	s0,s0,t1
ffffffffc0200790:	0187f7b3          	and	a5,a5,s8
ffffffffc0200794:	01fe6333          	or	t1,t3,t6
ffffffffc0200798:	01877c33          	and	s8,a4,s8
ffffffffc020079c:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007a0:	011b78b3          	and	a7,s6,a7
ffffffffc02007a4:	005eeeb3          	or	t4,t4,t0
ffffffffc02007a8:	00c6e733          	or	a4,a3,a2
ffffffffc02007ac:	006c6c33          	or	s8,s8,t1
ffffffffc02007b0:	010b76b3          	and	a3,s6,a6
ffffffffc02007b4:	00bb7b33          	and	s6,s6,a1
ffffffffc02007b8:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007bc:	016c6b33          	or	s6,s8,s6
ffffffffc02007c0:	01146433          	or	s0,s0,a7
ffffffffc02007c4:	8fd5                	or	a5,a5,a3
ffffffffc02007c6:	1702                	slli	a4,a4,0x20
ffffffffc02007c8:	1b02                	slli	s6,s6,0x20
ffffffffc02007ca:	1782                	slli	a5,a5,0x20
ffffffffc02007cc:	9301                	srli	a4,a4,0x20
ffffffffc02007ce:	1402                	slli	s0,s0,0x20
ffffffffc02007d0:	020b5b13          	srli	s6,s6,0x20
ffffffffc02007d4:	0167eb33          	or	s6,a5,s6
ffffffffc02007d8:	8c59                	or	s0,s0,a4
ffffffffc02007da:	90fff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02007de:	85a2                	mv	a1,s0
ffffffffc02007e0:	00002517          	auipc	a0,0x2
ffffffffc02007e4:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202338 <commands+0x138>
ffffffffc02007e8:	901ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02007ec:	014b5613          	srli	a2,s6,0x14
ffffffffc02007f0:	85da                	mv	a1,s6
ffffffffc02007f2:	00002517          	auipc	a0,0x2
ffffffffc02007f6:	b5e50513          	addi	a0,a0,-1186 # ffffffffc0202350 <commands+0x150>
ffffffffc02007fa:	8efff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc02007fe:	008b05b3          	add	a1,s6,s0
ffffffffc0200802:	15fd                	addi	a1,a1,-1
ffffffffc0200804:	00002517          	auipc	a0,0x2
ffffffffc0200808:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0202370 <commands+0x170>
ffffffffc020080c:	8ddff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0200810:	00002517          	auipc	a0,0x2
ffffffffc0200814:	bb050513          	addi	a0,a0,-1104 # ffffffffc02023c0 <commands+0x1c0>
ffffffffc0200818:	00007797          	auipc	a5,0x7
ffffffffc020081c:	c287bc23          	sd	s0,-968(a5) # ffffffffc0207450 <memory_base>
ffffffffc0200820:	00007797          	auipc	a5,0x7
ffffffffc0200824:	c367bc23          	sd	s6,-968(a5) # ffffffffc0207458 <memory_size>
ffffffffc0200828:	b3f5                	j	ffffffffc0200614 <dtb_init+0x186>

ffffffffc020082a <get_memory_base>:
ffffffffc020082a:	00007517          	auipc	a0,0x7
ffffffffc020082e:	c2653503          	ld	a0,-986(a0) # ffffffffc0207450 <memory_base>
ffffffffc0200832:	8082                	ret

ffffffffc0200834 <get_memory_size>:
ffffffffc0200834:	00007517          	auipc	a0,0x7
ffffffffc0200838:	c2453503          	ld	a0,-988(a0) # ffffffffc0207458 <memory_size>
ffffffffc020083c:	8082                	ret

ffffffffc020083e <intr_enable>:
ffffffffc020083e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200842:	8082                	ret

ffffffffc0200844 <intr_disable>:
ffffffffc0200844:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200848:	8082                	ret

ffffffffc020084a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020084a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020084e:	00000797          	auipc	a5,0x0
ffffffffc0200852:	36678793          	addi	a5,a5,870 # ffffffffc0200bb4 <__alltraps>
ffffffffc0200856:	10579073          	csrw	stvec,a5
}
ffffffffc020085a:	8082                	ret

ffffffffc020085c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020085c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020085e:	1141                	addi	sp,sp,-16
ffffffffc0200860:	e022                	sd	s0,0(sp)
ffffffffc0200862:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	b7450513          	addi	a0,a0,-1164 # ffffffffc02023d8 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc020086c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020086e:	87bff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200872:	640c                	ld	a1,8(s0)
ffffffffc0200874:	00002517          	auipc	a0,0x2
ffffffffc0200878:	b7c50513          	addi	a0,a0,-1156 # ffffffffc02023f0 <commands+0x1f0>
ffffffffc020087c:	86dff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200880:	680c                	ld	a1,16(s0)
ffffffffc0200882:	00002517          	auipc	a0,0x2
ffffffffc0200886:	b8650513          	addi	a0,a0,-1146 # ffffffffc0202408 <commands+0x208>
ffffffffc020088a:	85fff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020088e:	6c0c                	ld	a1,24(s0)
ffffffffc0200890:	00002517          	auipc	a0,0x2
ffffffffc0200894:	b9050513          	addi	a0,a0,-1136 # ffffffffc0202420 <commands+0x220>
ffffffffc0200898:	851ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020089c:	700c                	ld	a1,32(s0)
ffffffffc020089e:	00002517          	auipc	a0,0x2
ffffffffc02008a2:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0202438 <commands+0x238>
ffffffffc02008a6:	843ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008aa:	740c                	ld	a1,40(s0)
ffffffffc02008ac:	00002517          	auipc	a0,0x2
ffffffffc02008b0:	ba450513          	addi	a0,a0,-1116 # ffffffffc0202450 <commands+0x250>
ffffffffc02008b4:	835ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008b8:	780c                	ld	a1,48(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	bae50513          	addi	a0,a0,-1106 # ffffffffc0202468 <commands+0x268>
ffffffffc02008c2:	827ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008c6:	7c0c                	ld	a1,56(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	bb850513          	addi	a0,a0,-1096 # ffffffffc0202480 <commands+0x280>
ffffffffc02008d0:	819ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008d4:	602c                	ld	a1,64(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	bc250513          	addi	a0,a0,-1086 # ffffffffc0202498 <commands+0x298>
ffffffffc02008de:	80bff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008e2:	642c                	ld	a1,72(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	bcc50513          	addi	a0,a0,-1076 # ffffffffc02024b0 <commands+0x2b0>
ffffffffc02008ec:	ffcff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008f0:	682c                	ld	a1,80(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	bd650513          	addi	a0,a0,-1066 # ffffffffc02024c8 <commands+0x2c8>
ffffffffc02008fa:	feeff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008fe:	6c2c                	ld	a1,88(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	be050513          	addi	a0,a0,-1056 # ffffffffc02024e0 <commands+0x2e0>
ffffffffc0200908:	fe0ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020090c:	702c                	ld	a1,96(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	bea50513          	addi	a0,a0,-1046 # ffffffffc02024f8 <commands+0x2f8>
ffffffffc0200916:	fd2ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020091a:	742c                	ld	a1,104(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	bf450513          	addi	a0,a0,-1036 # ffffffffc0202510 <commands+0x310>
ffffffffc0200924:	fc4ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200928:	782c                	ld	a1,112(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0202528 <commands+0x328>
ffffffffc0200932:	fb6ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200936:	7c2c                	ld	a1,120(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	c0850513          	addi	a0,a0,-1016 # ffffffffc0202540 <commands+0x340>
ffffffffc0200940:	fa8ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200944:	604c                	ld	a1,128(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0202558 <commands+0x358>
ffffffffc020094e:	f9aff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200952:	644c                	ld	a1,136(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	c1c50513          	addi	a0,a0,-996 # ffffffffc0202570 <commands+0x370>
ffffffffc020095c:	f8cff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200960:	684c                	ld	a1,144(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	c2650513          	addi	a0,a0,-986 # ffffffffc0202588 <commands+0x388>
ffffffffc020096a:	f7eff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020096e:	6c4c                	ld	a1,152(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	c3050513          	addi	a0,a0,-976 # ffffffffc02025a0 <commands+0x3a0>
ffffffffc0200978:	f70ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020097c:	704c                	ld	a1,160(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	c3a50513          	addi	a0,a0,-966 # ffffffffc02025b8 <commands+0x3b8>
ffffffffc0200986:	f62ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020098a:	744c                	ld	a1,168(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	c4450513          	addi	a0,a0,-956 # ffffffffc02025d0 <commands+0x3d0>
ffffffffc0200994:	f54ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200998:	784c                	ld	a1,176(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	c4e50513          	addi	a0,a0,-946 # ffffffffc02025e8 <commands+0x3e8>
ffffffffc02009a2:	f46ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009a6:	7c4c                	ld	a1,184(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	c5850513          	addi	a0,a0,-936 # ffffffffc0202600 <commands+0x400>
ffffffffc02009b0:	f38ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009b4:	606c                	ld	a1,192(s0)
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	c6250513          	addi	a0,a0,-926 # ffffffffc0202618 <commands+0x418>
ffffffffc02009be:	f2aff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009c2:	646c                	ld	a1,200(s0)
ffffffffc02009c4:	00002517          	auipc	a0,0x2
ffffffffc02009c8:	c6c50513          	addi	a0,a0,-916 # ffffffffc0202630 <commands+0x430>
ffffffffc02009cc:	f1cff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009d0:	686c                	ld	a1,208(s0)
ffffffffc02009d2:	00002517          	auipc	a0,0x2
ffffffffc02009d6:	c7650513          	addi	a0,a0,-906 # ffffffffc0202648 <commands+0x448>
ffffffffc02009da:	f0eff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009de:	6c6c                	ld	a1,216(s0)
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	c8050513          	addi	a0,a0,-896 # ffffffffc0202660 <commands+0x460>
ffffffffc02009e8:	f00ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009ec:	706c                	ld	a1,224(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	c8a50513          	addi	a0,a0,-886 # ffffffffc0202678 <commands+0x478>
ffffffffc02009f6:	ef2ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009fa:	746c                	ld	a1,232(s0)
ffffffffc02009fc:	00002517          	auipc	a0,0x2
ffffffffc0200a00:	c9450513          	addi	a0,a0,-876 # ffffffffc0202690 <commands+0x490>
ffffffffc0200a04:	ee4ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a08:	786c                	ld	a1,240(s0)
ffffffffc0200a0a:	00002517          	auipc	a0,0x2
ffffffffc0200a0e:	c9e50513          	addi	a0,a0,-866 # ffffffffc02026a8 <commands+0x4a8>
ffffffffc0200a12:	ed6ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a16:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a18:	6402                	ld	s0,0(sp)
ffffffffc0200a1a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a1c:	00002517          	auipc	a0,0x2
ffffffffc0200a20:	ca450513          	addi	a0,a0,-860 # ffffffffc02026c0 <commands+0x4c0>
}
ffffffffc0200a24:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a26:	ec2ff06f          	j	ffffffffc02000e8 <cprintf>

ffffffffc0200a2a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2a:	1141                	addi	sp,sp,-16
ffffffffc0200a2c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a30:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a32:	00002517          	auipc	a0,0x2
ffffffffc0200a36:	ca650513          	addi	a0,a0,-858 # ffffffffc02026d8 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a3a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a3c:	eacff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a40:	8522                	mv	a0,s0
ffffffffc0200a42:	e1bff0ef          	jal	ra,ffffffffc020085c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a46:	10043583          	ld	a1,256(s0)
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	ca650513          	addi	a0,a0,-858 # ffffffffc02026f0 <commands+0x4f0>
ffffffffc0200a52:	e96ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a56:	10843583          	ld	a1,264(s0)
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	cae50513          	addi	a0,a0,-850 # ffffffffc0202708 <commands+0x508>
ffffffffc0200a62:	e86ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a66:	11043583          	ld	a1,272(s0)
ffffffffc0200a6a:	00002517          	auipc	a0,0x2
ffffffffc0200a6e:	cb650513          	addi	a0,a0,-842 # ffffffffc0202720 <commands+0x520>
ffffffffc0200a72:	e76ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a76:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a7a:	6402                	ld	s0,0(sp)
ffffffffc0200a7c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a7e:	00002517          	auipc	a0,0x2
ffffffffc0200a82:	cba50513          	addi	a0,a0,-838 # ffffffffc0202738 <commands+0x538>
}
ffffffffc0200a86:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a88:	e60ff06f          	j	ffffffffc02000e8 <cprintf>

ffffffffc0200a8c <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a8c:	11853783          	ld	a5,280(a0)
ffffffffc0200a90:	472d                	li	a4,11
ffffffffc0200a92:	0786                	slli	a5,a5,0x1
ffffffffc0200a94:	8385                	srli	a5,a5,0x1
ffffffffc0200a96:	08f76363          	bltu	a4,a5,ffffffffc0200b1c <interrupt_handler+0x90>
ffffffffc0200a9a:	00002717          	auipc	a4,0x2
ffffffffc0200a9e:	d9670713          	addi	a4,a4,-618 # ffffffffc0202830 <commands+0x630>
ffffffffc0200aa2:	078a                	slli	a5,a5,0x2
ffffffffc0200aa4:	97ba                	add	a5,a5,a4
ffffffffc0200aa6:	439c                	lw	a5,0(a5)
ffffffffc0200aa8:	97ba                	add	a5,a5,a4
ffffffffc0200aaa:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200aac:	00002517          	auipc	a0,0x2
ffffffffc0200ab0:	d0450513          	addi	a0,a0,-764 # ffffffffc02027b0 <commands+0x5b0>
ffffffffc0200ab4:	e34ff06f          	j	ffffffffc02000e8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200ab8:	00002517          	auipc	a0,0x2
ffffffffc0200abc:	cd850513          	addi	a0,a0,-808 # ffffffffc0202790 <commands+0x590>
ffffffffc0200ac0:	e28ff06f          	j	ffffffffc02000e8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ac4:	00002517          	auipc	a0,0x2
ffffffffc0200ac8:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202750 <commands+0x550>
ffffffffc0200acc:	e1cff06f          	j	ffffffffc02000e8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ad0:	00002517          	auipc	a0,0x2
ffffffffc0200ad4:	d0050513          	addi	a0,a0,-768 # ffffffffc02027d0 <commands+0x5d0>
ffffffffc0200ad8:	e10ff06f          	j	ffffffffc02000e8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200adc:	1141                	addi	sp,sp,-16
ffffffffc0200ade:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200ae0:	991ff0ef          	jal	ra,ffffffffc0200470 <clock_set_next_event>
            ticks++;
ffffffffc0200ae4:	00007797          	auipc	a5,0x7
ffffffffc0200ae8:	96478793          	addi	a5,a5,-1692 # ffffffffc0207448 <ticks>
ffffffffc0200aec:	6398                	ld	a4,0(a5)
ffffffffc0200aee:	0705                	addi	a4,a4,1
ffffffffc0200af0:	e398                	sd	a4,0(a5)
            if(ticks%TICK_NUM == 0){
ffffffffc0200af2:	639c                	ld	a5,0(a5)
ffffffffc0200af4:	06400713          	li	a4,100
ffffffffc0200af8:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200afc:	c38d                	beqz	a5,ffffffffc0200b1e <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200afe:	60a2                	ld	ra,8(sp)
ffffffffc0200b00:	0141                	addi	sp,sp,16
ffffffffc0200b02:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b04:	00002517          	auipc	a0,0x2
ffffffffc0200b08:	d0c50513          	addi	a0,a0,-756 # ffffffffc0202810 <commands+0x610>
ffffffffc0200b0c:	ddcff06f          	j	ffffffffc02000e8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b10:	00002517          	auipc	a0,0x2
ffffffffc0200b14:	c6050513          	addi	a0,a0,-928 # ffffffffc0202770 <commands+0x570>
ffffffffc0200b18:	dd0ff06f          	j	ffffffffc02000e8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b1c:	b739                	j	ffffffffc0200a2a <print_trapframe>
                cprintf("100ticks\n");
ffffffffc0200b1e:	00002517          	auipc	a0,0x2
ffffffffc0200b22:	cca50513          	addi	a0,a0,-822 # ffffffffc02027e8 <commands+0x5e8>
ffffffffc0200b26:	dc2ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
                num++;
ffffffffc0200b2a:	00007797          	auipc	a5,0x7
ffffffffc0200b2e:	93678793          	addi	a5,a5,-1738 # ffffffffc0207460 <num>
ffffffffc0200b32:	6398                	ld	a4,0(a5)
                if(num == 10){
ffffffffc0200b34:	46a9                	li	a3,10
                num++;
ffffffffc0200b36:	0705                	addi	a4,a4,1
ffffffffc0200b38:	e398                	sd	a4,0(a5)
                if(num == 10){
ffffffffc0200b3a:	639c                	ld	a5,0(a5)
ffffffffc0200b3c:	fcd791e3          	bne	a5,a3,ffffffffc0200afe <interrupt_handler+0x72>
                    cprintf("shutting down...\n");
ffffffffc0200b40:	00002517          	auipc	a0,0x2
ffffffffc0200b44:	cb850513          	addi	a0,a0,-840 # ffffffffc02027f8 <commands+0x5f8>
ffffffffc0200b48:	da0ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
}
ffffffffc0200b4c:	60a2                	ld	ra,8(sp)
ffffffffc0200b4e:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b50:	37c0106f          	j	ffffffffc0201ecc <sbi_shutdown>

ffffffffc0200b54 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b54:	11853783          	ld	a5,280(a0)
ffffffffc0200b58:	4709                	li	a4,2
ffffffffc0200b5a:	00e78b63          	beq	a5,a4,ffffffffc0200b70 <exception_handler+0x1c>
ffffffffc0200b5e:	00f77863          	bgeu	a4,a5,ffffffffc0200b6e <exception_handler+0x1a>
ffffffffc0200b62:	17f5                	addi	a5,a5,-3
ffffffffc0200b64:	4721                	li	a4,8
ffffffffc0200b66:	00f77363          	bgeu	a4,a5,ffffffffc0200b6c <exception_handler+0x18>
        case CAUSE_HYPERVISOR_ECALL:
            break;
        case CAUSE_MACHINE_ECALL:
            break;
        default:
            print_trapframe(tf);
ffffffffc0200b6a:	b5c1                	j	ffffffffc0200a2a <print_trapframe>
ffffffffc0200b6c:	8082                	ret
ffffffffc0200b6e:	8082                	ret
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b70:	10853583          	ld	a1,264(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b74:	1141                	addi	sp,sp,-16
ffffffffc0200b76:	e022                	sd	s0,0(sp)
ffffffffc0200b78:	842a                	mv	s0,a0
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b7a:	00002517          	auipc	a0,0x2
ffffffffc0200b7e:	ce650513          	addi	a0,a0,-794 # ffffffffc0202860 <commands+0x660>
void exception_handler(struct trapframe *tf) {
ffffffffc0200b82:	e406                	sd	ra,8(sp)
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b84:	d64ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b88:	00002517          	auipc	a0,0x2
ffffffffc0200b8c:	d0050513          	addi	a0,a0,-768 # ffffffffc0202888 <commands+0x688>
ffffffffc0200b90:	d58ff0ef          	jal	ra,ffffffffc02000e8 <cprintf>
            tf->epc += 4;
ffffffffc0200b94:	10843783          	ld	a5,264(s0)
            break;
    }
}
ffffffffc0200b98:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
ffffffffc0200b9a:	0791                	addi	a5,a5,4
ffffffffc0200b9c:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ba0:	6402                	ld	s0,0(sp)
ffffffffc0200ba2:	0141                	addi	sp,sp,16
ffffffffc0200ba4:	8082                	ret

ffffffffc0200ba6 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ba6:	11853783          	ld	a5,280(a0)
ffffffffc0200baa:	0007c363          	bltz	a5,ffffffffc0200bb0 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bae:	b75d                	j	ffffffffc0200b54 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bb0:	bdf1                	j	ffffffffc0200a8c <interrupt_handler>
	...

ffffffffc0200bb4 <__alltraps>:
ffffffffc0200bb4:	14011073          	csrw	sscratch,sp
ffffffffc0200bb8:	712d                	addi	sp,sp,-288
ffffffffc0200bba:	e002                	sd	zero,0(sp)
ffffffffc0200bbc:	e406                	sd	ra,8(sp)
ffffffffc0200bbe:	ec0e                	sd	gp,24(sp)
ffffffffc0200bc0:	f012                	sd	tp,32(sp)
ffffffffc0200bc2:	f416                	sd	t0,40(sp)
ffffffffc0200bc4:	f81a                	sd	t1,48(sp)
ffffffffc0200bc6:	fc1e                	sd	t2,56(sp)
ffffffffc0200bc8:	e0a2                	sd	s0,64(sp)
ffffffffc0200bca:	e4a6                	sd	s1,72(sp)
ffffffffc0200bcc:	e8aa                	sd	a0,80(sp)
ffffffffc0200bce:	ecae                	sd	a1,88(sp)
ffffffffc0200bd0:	f0b2                	sd	a2,96(sp)
ffffffffc0200bd2:	f4b6                	sd	a3,104(sp)
ffffffffc0200bd4:	f8ba                	sd	a4,112(sp)
ffffffffc0200bd6:	fcbe                	sd	a5,120(sp)
ffffffffc0200bd8:	e142                	sd	a6,128(sp)
ffffffffc0200bda:	e546                	sd	a7,136(sp)
ffffffffc0200bdc:	e94a                	sd	s2,144(sp)
ffffffffc0200bde:	ed4e                	sd	s3,152(sp)
ffffffffc0200be0:	f152                	sd	s4,160(sp)
ffffffffc0200be2:	f556                	sd	s5,168(sp)
ffffffffc0200be4:	f95a                	sd	s6,176(sp)
ffffffffc0200be6:	fd5e                	sd	s7,184(sp)
ffffffffc0200be8:	e1e2                	sd	s8,192(sp)
ffffffffc0200bea:	e5e6                	sd	s9,200(sp)
ffffffffc0200bec:	e9ea                	sd	s10,208(sp)
ffffffffc0200bee:	edee                	sd	s11,216(sp)
ffffffffc0200bf0:	f1f2                	sd	t3,224(sp)
ffffffffc0200bf2:	f5f6                	sd	t4,232(sp)
ffffffffc0200bf4:	f9fa                	sd	t5,240(sp)
ffffffffc0200bf6:	fdfe                	sd	t6,248(sp)
ffffffffc0200bf8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200bfc:	100024f3          	csrr	s1,sstatus
ffffffffc0200c00:	14102973          	csrr	s2,sepc
ffffffffc0200c04:	143029f3          	csrr	s3,stval
ffffffffc0200c08:	14202a73          	csrr	s4,scause
ffffffffc0200c0c:	e822                	sd	s0,16(sp)
ffffffffc0200c0e:	e226                	sd	s1,256(sp)
ffffffffc0200c10:	e64a                	sd	s2,264(sp)
ffffffffc0200c12:	ea4e                	sd	s3,272(sp)
ffffffffc0200c14:	ee52                	sd	s4,280(sp)
ffffffffc0200c16:	850a                	mv	a0,sp
ffffffffc0200c18:	f8fff0ef          	jal	ra,ffffffffc0200ba6 <trap>

ffffffffc0200c1c <__trapret>:
ffffffffc0200c1c:	6492                	ld	s1,256(sp)
ffffffffc0200c1e:	6932                	ld	s2,264(sp)
ffffffffc0200c20:	10049073          	csrw	sstatus,s1
ffffffffc0200c24:	14191073          	csrw	sepc,s2
ffffffffc0200c28:	60a2                	ld	ra,8(sp)
ffffffffc0200c2a:	61e2                	ld	gp,24(sp)
ffffffffc0200c2c:	7202                	ld	tp,32(sp)
ffffffffc0200c2e:	72a2                	ld	t0,40(sp)
ffffffffc0200c30:	7342                	ld	t1,48(sp)
ffffffffc0200c32:	73e2                	ld	t2,56(sp)
ffffffffc0200c34:	6406                	ld	s0,64(sp)
ffffffffc0200c36:	64a6                	ld	s1,72(sp)
ffffffffc0200c38:	6546                	ld	a0,80(sp)
ffffffffc0200c3a:	65e6                	ld	a1,88(sp)
ffffffffc0200c3c:	7606                	ld	a2,96(sp)
ffffffffc0200c3e:	76a6                	ld	a3,104(sp)
ffffffffc0200c40:	7746                	ld	a4,112(sp)
ffffffffc0200c42:	77e6                	ld	a5,120(sp)
ffffffffc0200c44:	680a                	ld	a6,128(sp)
ffffffffc0200c46:	68aa                	ld	a7,136(sp)
ffffffffc0200c48:	694a                	ld	s2,144(sp)
ffffffffc0200c4a:	69ea                	ld	s3,152(sp)
ffffffffc0200c4c:	7a0a                	ld	s4,160(sp)
ffffffffc0200c4e:	7aaa                	ld	s5,168(sp)
ffffffffc0200c50:	7b4a                	ld	s6,176(sp)
ffffffffc0200c52:	7bea                	ld	s7,184(sp)
ffffffffc0200c54:	6c0e                	ld	s8,192(sp)
ffffffffc0200c56:	6cae                	ld	s9,200(sp)
ffffffffc0200c58:	6d4e                	ld	s10,208(sp)
ffffffffc0200c5a:	6dee                	ld	s11,216(sp)
ffffffffc0200c5c:	7e0e                	ld	t3,224(sp)
ffffffffc0200c5e:	7eae                	ld	t4,232(sp)
ffffffffc0200c60:	7f4e                	ld	t5,240(sp)
ffffffffc0200c62:	7fee                	ld	t6,248(sp)
ffffffffc0200c64:	6142                	ld	sp,16(sp)
ffffffffc0200c66:	10200073          	sret

ffffffffc0200c6a <default_init>:
ffffffffc0200c6a:	00006797          	auipc	a5,0x6
ffffffffc0200c6e:	3be78793          	addi	a5,a5,958 # ffffffffc0207028 <free_area>
ffffffffc0200c72:	e79c                	sd	a5,8(a5)
ffffffffc0200c74:	e39c                	sd	a5,0(a5)
ffffffffc0200c76:	0007a823          	sw	zero,16(a5)
ffffffffc0200c7a:	8082                	ret

ffffffffc0200c7c <default_nr_free_pages>:
ffffffffc0200c7c:	00006517          	auipc	a0,0x6
ffffffffc0200c80:	3bc56503          	lwu	a0,956(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200c84:	8082                	ret

ffffffffc0200c86 <default_check>:
ffffffffc0200c86:	715d                	addi	sp,sp,-80
ffffffffc0200c88:	e0a2                	sd	s0,64(sp)
ffffffffc0200c8a:	00006417          	auipc	s0,0x6
ffffffffc0200c8e:	39e40413          	addi	s0,s0,926 # ffffffffc0207028 <free_area>
ffffffffc0200c92:	641c                	ld	a5,8(s0)
ffffffffc0200c94:	e486                	sd	ra,72(sp)
ffffffffc0200c96:	fc26                	sd	s1,56(sp)
ffffffffc0200c98:	f84a                	sd	s2,48(sp)
ffffffffc0200c9a:	f44e                	sd	s3,40(sp)
ffffffffc0200c9c:	f052                	sd	s4,32(sp)
ffffffffc0200c9e:	ec56                	sd	s5,24(sp)
ffffffffc0200ca0:	e85a                	sd	s6,16(sp)
ffffffffc0200ca2:	e45e                	sd	s7,8(sp)
ffffffffc0200ca4:	e062                	sd	s8,0(sp)
ffffffffc0200ca6:	2c878763          	beq	a5,s0,ffffffffc0200f74 <default_check+0x2ee>
ffffffffc0200caa:	4481                	li	s1,0
ffffffffc0200cac:	4901                	li	s2,0
ffffffffc0200cae:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200cb2:	8b09                	andi	a4,a4,2
ffffffffc0200cb4:	2c070463          	beqz	a4,ffffffffc0200f7c <default_check+0x2f6>
ffffffffc0200cb8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200cbc:	679c                	ld	a5,8(a5)
ffffffffc0200cbe:	2905                	addiw	s2,s2,1
ffffffffc0200cc0:	9cb9                	addw	s1,s1,a4
ffffffffc0200cc2:	fe8796e3          	bne	a5,s0,ffffffffc0200cae <default_check+0x28>
ffffffffc0200cc6:	89a6                	mv	s3,s1
ffffffffc0200cc8:	2f9000ef          	jal	ra,ffffffffc02017c0 <nr_free_pages>
ffffffffc0200ccc:	71351863          	bne	a0,s3,ffffffffc02013dc <default_check+0x756>
ffffffffc0200cd0:	4505                	li	a0,1
ffffffffc0200cd2:	271000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200cd6:	8a2a                	mv	s4,a0
ffffffffc0200cd8:	44050263          	beqz	a0,ffffffffc020111c <default_check+0x496>
ffffffffc0200cdc:	4505                	li	a0,1
ffffffffc0200cde:	265000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200ce2:	89aa                	mv	s3,a0
ffffffffc0200ce4:	70050c63          	beqz	a0,ffffffffc02013fc <default_check+0x776>
ffffffffc0200ce8:	4505                	li	a0,1
ffffffffc0200cea:	259000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200cee:	8aaa                	mv	s5,a0
ffffffffc0200cf0:	4a050663          	beqz	a0,ffffffffc020119c <default_check+0x516>
ffffffffc0200cf4:	2b3a0463          	beq	s4,s3,ffffffffc0200f9c <default_check+0x316>
ffffffffc0200cf8:	2aaa0263          	beq	s4,a0,ffffffffc0200f9c <default_check+0x316>
ffffffffc0200cfc:	2aa98063          	beq	s3,a0,ffffffffc0200f9c <default_check+0x316>
ffffffffc0200d00:	000a2783          	lw	a5,0(s4)
ffffffffc0200d04:	2a079c63          	bnez	a5,ffffffffc0200fbc <default_check+0x336>
ffffffffc0200d08:	0009a783          	lw	a5,0(s3)
ffffffffc0200d0c:	2a079863          	bnez	a5,ffffffffc0200fbc <default_check+0x336>
ffffffffc0200d10:	411c                	lw	a5,0(a0)
ffffffffc0200d12:	2a079563          	bnez	a5,ffffffffc0200fbc <default_check+0x336>
ffffffffc0200d16:	00006797          	auipc	a5,0x6
ffffffffc0200d1a:	75a7b783          	ld	a5,1882(a5) # ffffffffc0207470 <pages>
ffffffffc0200d1e:	40fa0733          	sub	a4,s4,a5
ffffffffc0200d22:	870d                	srai	a4,a4,0x3
ffffffffc0200d24:	00002597          	auipc	a1,0x2
ffffffffc0200d28:	3145b583          	ld	a1,788(a1) # ffffffffc0203038 <error_string+0x38>
ffffffffc0200d2c:	02b70733          	mul	a4,a4,a1
ffffffffc0200d30:	00002617          	auipc	a2,0x2
ffffffffc0200d34:	31063603          	ld	a2,784(a2) # ffffffffc0203040 <nbase>
ffffffffc0200d38:	00006697          	auipc	a3,0x6
ffffffffc0200d3c:	7306b683          	ld	a3,1840(a3) # ffffffffc0207468 <npage>
ffffffffc0200d40:	06b2                	slli	a3,a3,0xc
ffffffffc0200d42:	9732                	add	a4,a4,a2
ffffffffc0200d44:	0732                	slli	a4,a4,0xc
ffffffffc0200d46:	28d77b63          	bgeu	a4,a3,ffffffffc0200fdc <default_check+0x356>
ffffffffc0200d4a:	40f98733          	sub	a4,s3,a5
ffffffffc0200d4e:	870d                	srai	a4,a4,0x3
ffffffffc0200d50:	02b70733          	mul	a4,a4,a1
ffffffffc0200d54:	9732                	add	a4,a4,a2
ffffffffc0200d56:	0732                	slli	a4,a4,0xc
ffffffffc0200d58:	4cd77263          	bgeu	a4,a3,ffffffffc020121c <default_check+0x596>
ffffffffc0200d5c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d60:	878d                	srai	a5,a5,0x3
ffffffffc0200d62:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d66:	97b2                	add	a5,a5,a2
ffffffffc0200d68:	07b2                	slli	a5,a5,0xc
ffffffffc0200d6a:	30d7f963          	bgeu	a5,a3,ffffffffc020107c <default_check+0x3f6>
ffffffffc0200d6e:	4505                	li	a0,1
ffffffffc0200d70:	00043c03          	ld	s8,0(s0)
ffffffffc0200d74:	00843b83          	ld	s7,8(s0)
ffffffffc0200d78:	01042b03          	lw	s6,16(s0)
ffffffffc0200d7c:	e400                	sd	s0,8(s0)
ffffffffc0200d7e:	e000                	sd	s0,0(s0)
ffffffffc0200d80:	00006797          	auipc	a5,0x6
ffffffffc0200d84:	2a07ac23          	sw	zero,696(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200d88:	1bb000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200d8c:	2c051863          	bnez	a0,ffffffffc020105c <default_check+0x3d6>
ffffffffc0200d90:	4585                	li	a1,1
ffffffffc0200d92:	8552                	mv	a0,s4
ffffffffc0200d94:	1ed000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200d98:	4585                	li	a1,1
ffffffffc0200d9a:	854e                	mv	a0,s3
ffffffffc0200d9c:	1e5000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200da0:	4585                	li	a1,1
ffffffffc0200da2:	8556                	mv	a0,s5
ffffffffc0200da4:	1dd000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200da8:	4818                	lw	a4,16(s0)
ffffffffc0200daa:	478d                	li	a5,3
ffffffffc0200dac:	28f71863          	bne	a4,a5,ffffffffc020103c <default_check+0x3b6>
ffffffffc0200db0:	4505                	li	a0,1
ffffffffc0200db2:	191000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200db6:	89aa                	mv	s3,a0
ffffffffc0200db8:	26050263          	beqz	a0,ffffffffc020101c <default_check+0x396>
ffffffffc0200dbc:	4505                	li	a0,1
ffffffffc0200dbe:	185000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200dc2:	8aaa                	mv	s5,a0
ffffffffc0200dc4:	3a050c63          	beqz	a0,ffffffffc020117c <default_check+0x4f6>
ffffffffc0200dc8:	4505                	li	a0,1
ffffffffc0200dca:	179000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200dce:	8a2a                	mv	s4,a0
ffffffffc0200dd0:	38050663          	beqz	a0,ffffffffc020115c <default_check+0x4d6>
ffffffffc0200dd4:	4505                	li	a0,1
ffffffffc0200dd6:	16d000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200dda:	36051163          	bnez	a0,ffffffffc020113c <default_check+0x4b6>
ffffffffc0200dde:	4585                	li	a1,1
ffffffffc0200de0:	854e                	mv	a0,s3
ffffffffc0200de2:	19f000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200de6:	641c                	ld	a5,8(s0)
ffffffffc0200de8:	20878a63          	beq	a5,s0,ffffffffc0200ffc <default_check+0x376>
ffffffffc0200dec:	4505                	li	a0,1
ffffffffc0200dee:	155000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200df2:	30a99563          	bne	s3,a0,ffffffffc02010fc <default_check+0x476>
ffffffffc0200df6:	4505                	li	a0,1
ffffffffc0200df8:	14b000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200dfc:	2e051063          	bnez	a0,ffffffffc02010dc <default_check+0x456>
ffffffffc0200e00:	481c                	lw	a5,16(s0)
ffffffffc0200e02:	2a079d63          	bnez	a5,ffffffffc02010bc <default_check+0x436>
ffffffffc0200e06:	854e                	mv	a0,s3
ffffffffc0200e08:	4585                	li	a1,1
ffffffffc0200e0a:	01843023          	sd	s8,0(s0)
ffffffffc0200e0e:	01743423          	sd	s7,8(s0)
ffffffffc0200e12:	01642823          	sw	s6,16(s0)
ffffffffc0200e16:	16b000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200e1a:	4585                	li	a1,1
ffffffffc0200e1c:	8556                	mv	a0,s5
ffffffffc0200e1e:	163000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200e22:	4585                	li	a1,1
ffffffffc0200e24:	8552                	mv	a0,s4
ffffffffc0200e26:	15b000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200e2a:	4515                	li	a0,5
ffffffffc0200e2c:	117000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200e30:	89aa                	mv	s3,a0
ffffffffc0200e32:	26050563          	beqz	a0,ffffffffc020109c <default_check+0x416>
ffffffffc0200e36:	651c                	ld	a5,8(a0)
ffffffffc0200e38:	8385                	srli	a5,a5,0x1
ffffffffc0200e3a:	8b85                	andi	a5,a5,1
ffffffffc0200e3c:	54079063          	bnez	a5,ffffffffc020137c <default_check+0x6f6>
ffffffffc0200e40:	4505                	li	a0,1
ffffffffc0200e42:	00043b03          	ld	s6,0(s0)
ffffffffc0200e46:	00843a83          	ld	s5,8(s0)
ffffffffc0200e4a:	e000                	sd	s0,0(s0)
ffffffffc0200e4c:	e400                	sd	s0,8(s0)
ffffffffc0200e4e:	0f5000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200e52:	50051563          	bnez	a0,ffffffffc020135c <default_check+0x6d6>
ffffffffc0200e56:	05098a13          	addi	s4,s3,80
ffffffffc0200e5a:	8552                	mv	a0,s4
ffffffffc0200e5c:	458d                	li	a1,3
ffffffffc0200e5e:	01042b83          	lw	s7,16(s0)
ffffffffc0200e62:	00006797          	auipc	a5,0x6
ffffffffc0200e66:	1c07ab23          	sw	zero,470(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200e6a:	117000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200e6e:	4511                	li	a0,4
ffffffffc0200e70:	0d3000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200e74:	4c051463          	bnez	a0,ffffffffc020133c <default_check+0x6b6>
ffffffffc0200e78:	0589b783          	ld	a5,88(s3)
ffffffffc0200e7c:	8385                	srli	a5,a5,0x1
ffffffffc0200e7e:	8b85                	andi	a5,a5,1
ffffffffc0200e80:	48078e63          	beqz	a5,ffffffffc020131c <default_check+0x696>
ffffffffc0200e84:	0609a703          	lw	a4,96(s3)
ffffffffc0200e88:	478d                	li	a5,3
ffffffffc0200e8a:	48f71963          	bne	a4,a5,ffffffffc020131c <default_check+0x696>
ffffffffc0200e8e:	450d                	li	a0,3
ffffffffc0200e90:	0b3000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200e94:	8c2a                	mv	s8,a0
ffffffffc0200e96:	46050363          	beqz	a0,ffffffffc02012fc <default_check+0x676>
ffffffffc0200e9a:	4505                	li	a0,1
ffffffffc0200e9c:	0a7000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200ea0:	42051e63          	bnez	a0,ffffffffc02012dc <default_check+0x656>
ffffffffc0200ea4:	418a1c63          	bne	s4,s8,ffffffffc02012bc <default_check+0x636>
ffffffffc0200ea8:	4585                	li	a1,1
ffffffffc0200eaa:	854e                	mv	a0,s3
ffffffffc0200eac:	0d5000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200eb0:	458d                	li	a1,3
ffffffffc0200eb2:	8552                	mv	a0,s4
ffffffffc0200eb4:	0cd000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200eb8:	0089b783          	ld	a5,8(s3)
ffffffffc0200ebc:	02898c13          	addi	s8,s3,40
ffffffffc0200ec0:	8385                	srli	a5,a5,0x1
ffffffffc0200ec2:	8b85                	andi	a5,a5,1
ffffffffc0200ec4:	3c078c63          	beqz	a5,ffffffffc020129c <default_check+0x616>
ffffffffc0200ec8:	0109a703          	lw	a4,16(s3)
ffffffffc0200ecc:	4785                	li	a5,1
ffffffffc0200ece:	3cf71763          	bne	a4,a5,ffffffffc020129c <default_check+0x616>
ffffffffc0200ed2:	008a3783          	ld	a5,8(s4)
ffffffffc0200ed6:	8385                	srli	a5,a5,0x1
ffffffffc0200ed8:	8b85                	andi	a5,a5,1
ffffffffc0200eda:	3a078163          	beqz	a5,ffffffffc020127c <default_check+0x5f6>
ffffffffc0200ede:	010a2703          	lw	a4,16(s4)
ffffffffc0200ee2:	478d                	li	a5,3
ffffffffc0200ee4:	38f71c63          	bne	a4,a5,ffffffffc020127c <default_check+0x5f6>
ffffffffc0200ee8:	4505                	li	a0,1
ffffffffc0200eea:	059000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200eee:	36a99763          	bne	s3,a0,ffffffffc020125c <default_check+0x5d6>
ffffffffc0200ef2:	4585                	li	a1,1
ffffffffc0200ef4:	08d000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200ef8:	4509                	li	a0,2
ffffffffc0200efa:	049000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200efe:	32aa1f63          	bne	s4,a0,ffffffffc020123c <default_check+0x5b6>
ffffffffc0200f02:	4589                	li	a1,2
ffffffffc0200f04:	07d000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200f08:	4585                	li	a1,1
ffffffffc0200f0a:	8562                	mv	a0,s8
ffffffffc0200f0c:	075000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200f10:	4515                	li	a0,5
ffffffffc0200f12:	031000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200f16:	89aa                	mv	s3,a0
ffffffffc0200f18:	48050263          	beqz	a0,ffffffffc020139c <default_check+0x716>
ffffffffc0200f1c:	4505                	li	a0,1
ffffffffc0200f1e:	025000ef          	jal	ra,ffffffffc0201742 <alloc_pages>
ffffffffc0200f22:	2c051d63          	bnez	a0,ffffffffc02011fc <default_check+0x576>
ffffffffc0200f26:	481c                	lw	a5,16(s0)
ffffffffc0200f28:	2a079a63          	bnez	a5,ffffffffc02011dc <default_check+0x556>
ffffffffc0200f2c:	4595                	li	a1,5
ffffffffc0200f2e:	854e                	mv	a0,s3
ffffffffc0200f30:	01742823          	sw	s7,16(s0)
ffffffffc0200f34:	01643023          	sd	s6,0(s0)
ffffffffc0200f38:	01543423          	sd	s5,8(s0)
ffffffffc0200f3c:	045000ef          	jal	ra,ffffffffc0201780 <free_pages>
ffffffffc0200f40:	641c                	ld	a5,8(s0)
ffffffffc0200f42:	00878963          	beq	a5,s0,ffffffffc0200f54 <default_check+0x2ce>
ffffffffc0200f46:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f4a:	679c                	ld	a5,8(a5)
ffffffffc0200f4c:	397d                	addiw	s2,s2,-1
ffffffffc0200f4e:	9c99                	subw	s1,s1,a4
ffffffffc0200f50:	fe879be3          	bne	a5,s0,ffffffffc0200f46 <default_check+0x2c0>
ffffffffc0200f54:	26091463          	bnez	s2,ffffffffc02011bc <default_check+0x536>
ffffffffc0200f58:	46049263          	bnez	s1,ffffffffc02013bc <default_check+0x736>
ffffffffc0200f5c:	60a6                	ld	ra,72(sp)
ffffffffc0200f5e:	6406                	ld	s0,64(sp)
ffffffffc0200f60:	74e2                	ld	s1,56(sp)
ffffffffc0200f62:	7942                	ld	s2,48(sp)
ffffffffc0200f64:	79a2                	ld	s3,40(sp)
ffffffffc0200f66:	7a02                	ld	s4,32(sp)
ffffffffc0200f68:	6ae2                	ld	s5,24(sp)
ffffffffc0200f6a:	6b42                	ld	s6,16(sp)
ffffffffc0200f6c:	6ba2                	ld	s7,8(sp)
ffffffffc0200f6e:	6c02                	ld	s8,0(sp)
ffffffffc0200f70:	6161                	addi	sp,sp,80
ffffffffc0200f72:	8082                	ret
ffffffffc0200f74:	4981                	li	s3,0
ffffffffc0200f76:	4481                	li	s1,0
ffffffffc0200f78:	4901                	li	s2,0
ffffffffc0200f7a:	b3b9                	j	ffffffffc0200cc8 <default_check+0x42>
ffffffffc0200f7c:	00002697          	auipc	a3,0x2
ffffffffc0200f80:	93468693          	addi	a3,a3,-1740 # ffffffffc02028b0 <commands+0x6b0>
ffffffffc0200f84:	00002617          	auipc	a2,0x2
ffffffffc0200f88:	93c60613          	addi	a2,a2,-1732 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0200f8c:	0f000593          	li	a1,240
ffffffffc0200f90:	00002517          	auipc	a0,0x2
ffffffffc0200f94:	94850513          	addi	a0,a0,-1720 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0200f98:	c4aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc0200f9c:	00002697          	auipc	a3,0x2
ffffffffc0200fa0:	9d468693          	addi	a3,a3,-1580 # ffffffffc0202970 <commands+0x770>
ffffffffc0200fa4:	00002617          	auipc	a2,0x2
ffffffffc0200fa8:	91c60613          	addi	a2,a2,-1764 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0200fac:	0bd00593          	li	a1,189
ffffffffc0200fb0:	00002517          	auipc	a0,0x2
ffffffffc0200fb4:	92850513          	addi	a0,a0,-1752 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0200fb8:	c2aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc0200fbc:	00002697          	auipc	a3,0x2
ffffffffc0200fc0:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0202998 <commands+0x798>
ffffffffc0200fc4:	00002617          	auipc	a2,0x2
ffffffffc0200fc8:	8fc60613          	addi	a2,a2,-1796 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0200fcc:	0be00593          	li	a1,190
ffffffffc0200fd0:	00002517          	auipc	a0,0x2
ffffffffc0200fd4:	90850513          	addi	a0,a0,-1784 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0200fd8:	c0aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc0200fdc:	00002697          	auipc	a3,0x2
ffffffffc0200fe0:	9fc68693          	addi	a3,a3,-1540 # ffffffffc02029d8 <commands+0x7d8>
ffffffffc0200fe4:	00002617          	auipc	a2,0x2
ffffffffc0200fe8:	8dc60613          	addi	a2,a2,-1828 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0200fec:	0c000593          	li	a1,192
ffffffffc0200ff0:	00002517          	auipc	a0,0x2
ffffffffc0200ff4:	8e850513          	addi	a0,a0,-1816 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0200ff8:	beaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc0200ffc:	00002697          	auipc	a3,0x2
ffffffffc0201000:	a6468693          	addi	a3,a3,-1436 # ffffffffc0202a60 <commands+0x860>
ffffffffc0201004:	00002617          	auipc	a2,0x2
ffffffffc0201008:	8bc60613          	addi	a2,a2,-1860 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020100c:	0d900593          	li	a1,217
ffffffffc0201010:	00002517          	auipc	a0,0x2
ffffffffc0201014:	8c850513          	addi	a0,a0,-1848 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201018:	bcaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020101c:	00002697          	auipc	a3,0x2
ffffffffc0201020:	8f468693          	addi	a3,a3,-1804 # ffffffffc0202910 <commands+0x710>
ffffffffc0201024:	00002617          	auipc	a2,0x2
ffffffffc0201028:	89c60613          	addi	a2,a2,-1892 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020102c:	0d200593          	li	a1,210
ffffffffc0201030:	00002517          	auipc	a0,0x2
ffffffffc0201034:	8a850513          	addi	a0,a0,-1880 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201038:	baaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020103c:	00002697          	auipc	a3,0x2
ffffffffc0201040:	a1468693          	addi	a3,a3,-1516 # ffffffffc0202a50 <commands+0x850>
ffffffffc0201044:	00002617          	auipc	a2,0x2
ffffffffc0201048:	87c60613          	addi	a2,a2,-1924 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020104c:	0d000593          	li	a1,208
ffffffffc0201050:	00002517          	auipc	a0,0x2
ffffffffc0201054:	88850513          	addi	a0,a0,-1912 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201058:	b8aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020105c:	00002697          	auipc	a3,0x2
ffffffffc0201060:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0202a38 <commands+0x838>
ffffffffc0201064:	00002617          	auipc	a2,0x2
ffffffffc0201068:	85c60613          	addi	a2,a2,-1956 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020106c:	0cb00593          	li	a1,203
ffffffffc0201070:	00002517          	auipc	a0,0x2
ffffffffc0201074:	86850513          	addi	a0,a0,-1944 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201078:	b6aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020107c:	00002697          	auipc	a3,0x2
ffffffffc0201080:	99c68693          	addi	a3,a3,-1636 # ffffffffc0202a18 <commands+0x818>
ffffffffc0201084:	00002617          	auipc	a2,0x2
ffffffffc0201088:	83c60613          	addi	a2,a2,-1988 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020108c:	0c200593          	li	a1,194
ffffffffc0201090:	00002517          	auipc	a0,0x2
ffffffffc0201094:	84850513          	addi	a0,a0,-1976 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201098:	b4aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020109c:	00002697          	auipc	a3,0x2
ffffffffc02010a0:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0202aa8 <commands+0x8a8>
ffffffffc02010a4:	00002617          	auipc	a2,0x2
ffffffffc02010a8:	81c60613          	addi	a2,a2,-2020 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02010ac:	0f800593          	li	a1,248
ffffffffc02010b0:	00002517          	auipc	a0,0x2
ffffffffc02010b4:	82850513          	addi	a0,a0,-2008 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02010b8:	b2aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02010bc:	00002697          	auipc	a3,0x2
ffffffffc02010c0:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0202a98 <commands+0x898>
ffffffffc02010c4:	00001617          	auipc	a2,0x1
ffffffffc02010c8:	7fc60613          	addi	a2,a2,2044 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02010cc:	0df00593          	li	a1,223
ffffffffc02010d0:	00002517          	auipc	a0,0x2
ffffffffc02010d4:	80850513          	addi	a0,a0,-2040 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02010d8:	b0aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02010dc:	00002697          	auipc	a3,0x2
ffffffffc02010e0:	95c68693          	addi	a3,a3,-1700 # ffffffffc0202a38 <commands+0x838>
ffffffffc02010e4:	00001617          	auipc	a2,0x1
ffffffffc02010e8:	7dc60613          	addi	a2,a2,2012 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02010ec:	0dd00593          	li	a1,221
ffffffffc02010f0:	00001517          	auipc	a0,0x1
ffffffffc02010f4:	7e850513          	addi	a0,a0,2024 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02010f8:	aeaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02010fc:	00002697          	auipc	a3,0x2
ffffffffc0201100:	97c68693          	addi	a3,a3,-1668 # ffffffffc0202a78 <commands+0x878>
ffffffffc0201104:	00001617          	auipc	a2,0x1
ffffffffc0201108:	7bc60613          	addi	a2,a2,1980 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020110c:	0dc00593          	li	a1,220
ffffffffc0201110:	00001517          	auipc	a0,0x1
ffffffffc0201114:	7c850513          	addi	a0,a0,1992 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201118:	acaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020111c:	00001697          	auipc	a3,0x1
ffffffffc0201120:	7f468693          	addi	a3,a3,2036 # ffffffffc0202910 <commands+0x710>
ffffffffc0201124:	00001617          	auipc	a2,0x1
ffffffffc0201128:	79c60613          	addi	a2,a2,1948 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020112c:	0b900593          	li	a1,185
ffffffffc0201130:	00001517          	auipc	a0,0x1
ffffffffc0201134:	7a850513          	addi	a0,a0,1960 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201138:	aaaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020113c:	00002697          	auipc	a3,0x2
ffffffffc0201140:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0202a38 <commands+0x838>
ffffffffc0201144:	00001617          	auipc	a2,0x1
ffffffffc0201148:	77c60613          	addi	a2,a2,1916 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020114c:	0d600593          	li	a1,214
ffffffffc0201150:	00001517          	auipc	a0,0x1
ffffffffc0201154:	78850513          	addi	a0,a0,1928 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201158:	a8aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020115c:	00001697          	auipc	a3,0x1
ffffffffc0201160:	7f468693          	addi	a3,a3,2036 # ffffffffc0202950 <commands+0x750>
ffffffffc0201164:	00001617          	auipc	a2,0x1
ffffffffc0201168:	75c60613          	addi	a2,a2,1884 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020116c:	0d400593          	li	a1,212
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	76850513          	addi	a0,a0,1896 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201178:	a6aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020117c:	00001697          	auipc	a3,0x1
ffffffffc0201180:	7b468693          	addi	a3,a3,1972 # ffffffffc0202930 <commands+0x730>
ffffffffc0201184:	00001617          	auipc	a2,0x1
ffffffffc0201188:	73c60613          	addi	a2,a2,1852 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020118c:	0d300593          	li	a1,211
ffffffffc0201190:	00001517          	auipc	a0,0x1
ffffffffc0201194:	74850513          	addi	a0,a0,1864 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201198:	a4aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020119c:	00001697          	auipc	a3,0x1
ffffffffc02011a0:	7b468693          	addi	a3,a3,1972 # ffffffffc0202950 <commands+0x750>
ffffffffc02011a4:	00001617          	auipc	a2,0x1
ffffffffc02011a8:	71c60613          	addi	a2,a2,1820 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02011ac:	0bb00593          	li	a1,187
ffffffffc02011b0:	00001517          	auipc	a0,0x1
ffffffffc02011b4:	72850513          	addi	a0,a0,1832 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02011b8:	a2aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02011bc:	00002697          	auipc	a3,0x2
ffffffffc02011c0:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0202bf8 <commands+0x9f8>
ffffffffc02011c4:	00001617          	auipc	a2,0x1
ffffffffc02011c8:	6fc60613          	addi	a2,a2,1788 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02011cc:	12500593          	li	a1,293
ffffffffc02011d0:	00001517          	auipc	a0,0x1
ffffffffc02011d4:	70850513          	addi	a0,a0,1800 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02011d8:	a0aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02011dc:	00002697          	auipc	a3,0x2
ffffffffc02011e0:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0202a98 <commands+0x898>
ffffffffc02011e4:	00001617          	auipc	a2,0x1
ffffffffc02011e8:	6dc60613          	addi	a2,a2,1756 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02011ec:	11a00593          	li	a1,282
ffffffffc02011f0:	00001517          	auipc	a0,0x1
ffffffffc02011f4:	6e850513          	addi	a0,a0,1768 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02011f8:	9eaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02011fc:	00002697          	auipc	a3,0x2
ffffffffc0201200:	83c68693          	addi	a3,a3,-1988 # ffffffffc0202a38 <commands+0x838>
ffffffffc0201204:	00001617          	auipc	a2,0x1
ffffffffc0201208:	6bc60613          	addi	a2,a2,1724 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020120c:	11800593          	li	a1,280
ffffffffc0201210:	00001517          	auipc	a0,0x1
ffffffffc0201214:	6c850513          	addi	a0,a0,1736 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201218:	9caff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020121c:	00001697          	auipc	a3,0x1
ffffffffc0201220:	7dc68693          	addi	a3,a3,2012 # ffffffffc02029f8 <commands+0x7f8>
ffffffffc0201224:	00001617          	auipc	a2,0x1
ffffffffc0201228:	69c60613          	addi	a2,a2,1692 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020122c:	0c100593          	li	a1,193
ffffffffc0201230:	00001517          	auipc	a0,0x1
ffffffffc0201234:	6a850513          	addi	a0,a0,1704 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201238:	9aaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020123c:	00002697          	auipc	a3,0x2
ffffffffc0201240:	97c68693          	addi	a3,a3,-1668 # ffffffffc0202bb8 <commands+0x9b8>
ffffffffc0201244:	00001617          	auipc	a2,0x1
ffffffffc0201248:	67c60613          	addi	a2,a2,1660 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020124c:	11200593          	li	a1,274
ffffffffc0201250:	00001517          	auipc	a0,0x1
ffffffffc0201254:	68850513          	addi	a0,a0,1672 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201258:	98aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020125c:	00002697          	auipc	a3,0x2
ffffffffc0201260:	93c68693          	addi	a3,a3,-1732 # ffffffffc0202b98 <commands+0x998>
ffffffffc0201264:	00001617          	auipc	a2,0x1
ffffffffc0201268:	65c60613          	addi	a2,a2,1628 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020126c:	11000593          	li	a1,272
ffffffffc0201270:	00001517          	auipc	a0,0x1
ffffffffc0201274:	66850513          	addi	a0,a0,1640 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201278:	96aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020127c:	00002697          	auipc	a3,0x2
ffffffffc0201280:	8f468693          	addi	a3,a3,-1804 # ffffffffc0202b70 <commands+0x970>
ffffffffc0201284:	00001617          	auipc	a2,0x1
ffffffffc0201288:	63c60613          	addi	a2,a2,1596 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020128c:	10e00593          	li	a1,270
ffffffffc0201290:	00001517          	auipc	a0,0x1
ffffffffc0201294:	64850513          	addi	a0,a0,1608 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201298:	94aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020129c:	00002697          	auipc	a3,0x2
ffffffffc02012a0:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0202b48 <commands+0x948>
ffffffffc02012a4:	00001617          	auipc	a2,0x1
ffffffffc02012a8:	61c60613          	addi	a2,a2,1564 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02012ac:	10d00593          	li	a1,269
ffffffffc02012b0:	00001517          	auipc	a0,0x1
ffffffffc02012b4:	62850513          	addi	a0,a0,1576 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02012b8:	92aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02012bc:	00002697          	auipc	a3,0x2
ffffffffc02012c0:	87c68693          	addi	a3,a3,-1924 # ffffffffc0202b38 <commands+0x938>
ffffffffc02012c4:	00001617          	auipc	a2,0x1
ffffffffc02012c8:	5fc60613          	addi	a2,a2,1532 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02012cc:	10800593          	li	a1,264
ffffffffc02012d0:	00001517          	auipc	a0,0x1
ffffffffc02012d4:	60850513          	addi	a0,a0,1544 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02012d8:	90aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02012dc:	00001697          	auipc	a3,0x1
ffffffffc02012e0:	75c68693          	addi	a3,a3,1884 # ffffffffc0202a38 <commands+0x838>
ffffffffc02012e4:	00001617          	auipc	a2,0x1
ffffffffc02012e8:	5dc60613          	addi	a2,a2,1500 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02012ec:	10700593          	li	a1,263
ffffffffc02012f0:	00001517          	auipc	a0,0x1
ffffffffc02012f4:	5e850513          	addi	a0,a0,1512 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02012f8:	8eaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02012fc:	00002697          	auipc	a3,0x2
ffffffffc0201300:	81c68693          	addi	a3,a3,-2020 # ffffffffc0202b18 <commands+0x918>
ffffffffc0201304:	00001617          	auipc	a2,0x1
ffffffffc0201308:	5bc60613          	addi	a2,a2,1468 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020130c:	10600593          	li	a1,262
ffffffffc0201310:	00001517          	auipc	a0,0x1
ffffffffc0201314:	5c850513          	addi	a0,a0,1480 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201318:	8caff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020131c:	00001697          	auipc	a3,0x1
ffffffffc0201320:	7cc68693          	addi	a3,a3,1996 # ffffffffc0202ae8 <commands+0x8e8>
ffffffffc0201324:	00001617          	auipc	a2,0x1
ffffffffc0201328:	59c60613          	addi	a2,a2,1436 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020132c:	10500593          	li	a1,261
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	5a850513          	addi	a0,a0,1448 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201338:	8aaff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020133c:	00001697          	auipc	a3,0x1
ffffffffc0201340:	79468693          	addi	a3,a3,1940 # ffffffffc0202ad0 <commands+0x8d0>
ffffffffc0201344:	00001617          	auipc	a2,0x1
ffffffffc0201348:	57c60613          	addi	a2,a2,1404 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020134c:	10400593          	li	a1,260
ffffffffc0201350:	00001517          	auipc	a0,0x1
ffffffffc0201354:	58850513          	addi	a0,a0,1416 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201358:	88aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020135c:	00001697          	auipc	a3,0x1
ffffffffc0201360:	6dc68693          	addi	a3,a3,1756 # ffffffffc0202a38 <commands+0x838>
ffffffffc0201364:	00001617          	auipc	a2,0x1
ffffffffc0201368:	55c60613          	addi	a2,a2,1372 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020136c:	0fe00593          	li	a1,254
ffffffffc0201370:	00001517          	auipc	a0,0x1
ffffffffc0201374:	56850513          	addi	a0,a0,1384 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201378:	86aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020137c:	00001697          	auipc	a3,0x1
ffffffffc0201380:	73c68693          	addi	a3,a3,1852 # ffffffffc0202ab8 <commands+0x8b8>
ffffffffc0201384:	00001617          	auipc	a2,0x1
ffffffffc0201388:	53c60613          	addi	a2,a2,1340 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020138c:	0f900593          	li	a1,249
ffffffffc0201390:	00001517          	auipc	a0,0x1
ffffffffc0201394:	54850513          	addi	a0,a0,1352 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201398:	84aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc020139c:	00002697          	auipc	a3,0x2
ffffffffc02013a0:	83c68693          	addi	a3,a3,-1988 # ffffffffc0202bd8 <commands+0x9d8>
ffffffffc02013a4:	00001617          	auipc	a2,0x1
ffffffffc02013a8:	51c60613          	addi	a2,a2,1308 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02013ac:	11700593          	li	a1,279
ffffffffc02013b0:	00001517          	auipc	a0,0x1
ffffffffc02013b4:	52850513          	addi	a0,a0,1320 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02013b8:	82aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02013bc:	00002697          	auipc	a3,0x2
ffffffffc02013c0:	84c68693          	addi	a3,a3,-1972 # ffffffffc0202c08 <commands+0xa08>
ffffffffc02013c4:	00001617          	auipc	a2,0x1
ffffffffc02013c8:	4fc60613          	addi	a2,a2,1276 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02013cc:	12600593          	li	a1,294
ffffffffc02013d0:	00001517          	auipc	a0,0x1
ffffffffc02013d4:	50850513          	addi	a0,a0,1288 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02013d8:	80aff0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02013dc:	00001697          	auipc	a3,0x1
ffffffffc02013e0:	51468693          	addi	a3,a3,1300 # ffffffffc02028f0 <commands+0x6f0>
ffffffffc02013e4:	00001617          	auipc	a2,0x1
ffffffffc02013e8:	4dc60613          	addi	a2,a2,1244 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc02013ec:	0f300593          	li	a1,243
ffffffffc02013f0:	00001517          	auipc	a0,0x1
ffffffffc02013f4:	4e850513          	addi	a0,a0,1256 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02013f8:	febfe0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02013fc:	00001697          	auipc	a3,0x1
ffffffffc0201400:	53468693          	addi	a3,a3,1332 # ffffffffc0202930 <commands+0x730>
ffffffffc0201404:	00001617          	auipc	a2,0x1
ffffffffc0201408:	4bc60613          	addi	a2,a2,1212 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020140c:	0ba00593          	li	a1,186
ffffffffc0201410:	00001517          	auipc	a0,0x1
ffffffffc0201414:	4c850513          	addi	a0,a0,1224 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201418:	fcbfe0ef          	jal	ra,ffffffffc02003e2 <__panic>

ffffffffc020141c <default_free_pages>:
ffffffffc020141c:	1141                	addi	sp,sp,-16
ffffffffc020141e:	e406                	sd	ra,8(sp)
ffffffffc0201420:	14058a63          	beqz	a1,ffffffffc0201574 <default_free_pages+0x158>
ffffffffc0201424:	00259693          	slli	a3,a1,0x2
ffffffffc0201428:	96ae                	add	a3,a3,a1
ffffffffc020142a:	068e                	slli	a3,a3,0x3
ffffffffc020142c:	96aa                	add	a3,a3,a0
ffffffffc020142e:	87aa                	mv	a5,a0
ffffffffc0201430:	02d50263          	beq	a0,a3,ffffffffc0201454 <default_free_pages+0x38>
ffffffffc0201434:	6798                	ld	a4,8(a5)
ffffffffc0201436:	8b05                	andi	a4,a4,1
ffffffffc0201438:	10071e63          	bnez	a4,ffffffffc0201554 <default_free_pages+0x138>
ffffffffc020143c:	6798                	ld	a4,8(a5)
ffffffffc020143e:	8b09                	andi	a4,a4,2
ffffffffc0201440:	10071a63          	bnez	a4,ffffffffc0201554 <default_free_pages+0x138>
ffffffffc0201444:	0007b423          	sd	zero,8(a5)
ffffffffc0201448:	0007a023          	sw	zero,0(a5)
ffffffffc020144c:	02878793          	addi	a5,a5,40
ffffffffc0201450:	fed792e3          	bne	a5,a3,ffffffffc0201434 <default_free_pages+0x18>
ffffffffc0201454:	2581                	sext.w	a1,a1
ffffffffc0201456:	c90c                	sw	a1,16(a0)
ffffffffc0201458:	00850893          	addi	a7,a0,8
ffffffffc020145c:	4789                	li	a5,2
ffffffffc020145e:	40f8b02f          	amoor.d	zero,a5,(a7)
ffffffffc0201462:	00006697          	auipc	a3,0x6
ffffffffc0201466:	bc668693          	addi	a3,a3,-1082 # ffffffffc0207028 <free_area>
ffffffffc020146a:	4a98                	lw	a4,16(a3)
ffffffffc020146c:	669c                	ld	a5,8(a3)
ffffffffc020146e:	01850613          	addi	a2,a0,24
ffffffffc0201472:	9db9                	addw	a1,a1,a4
ffffffffc0201474:	ca8c                	sw	a1,16(a3)
ffffffffc0201476:	0ad78863          	beq	a5,a3,ffffffffc0201526 <default_free_pages+0x10a>
ffffffffc020147a:	fe878713          	addi	a4,a5,-24
ffffffffc020147e:	0006b803          	ld	a6,0(a3)
ffffffffc0201482:	4581                	li	a1,0
ffffffffc0201484:	00e56a63          	bltu	a0,a4,ffffffffc0201498 <default_free_pages+0x7c>
ffffffffc0201488:	6798                	ld	a4,8(a5)
ffffffffc020148a:	06d70263          	beq	a4,a3,ffffffffc02014ee <default_free_pages+0xd2>
ffffffffc020148e:	87ba                	mv	a5,a4
ffffffffc0201490:	fe878713          	addi	a4,a5,-24
ffffffffc0201494:	fee57ae3          	bgeu	a0,a4,ffffffffc0201488 <default_free_pages+0x6c>
ffffffffc0201498:	c199                	beqz	a1,ffffffffc020149e <default_free_pages+0x82>
ffffffffc020149a:	0106b023          	sd	a6,0(a3)
ffffffffc020149e:	6398                	ld	a4,0(a5)
ffffffffc02014a0:	e390                	sd	a2,0(a5)
ffffffffc02014a2:	e710                	sd	a2,8(a4)
ffffffffc02014a4:	f11c                	sd	a5,32(a0)
ffffffffc02014a6:	ed18                	sd	a4,24(a0)
ffffffffc02014a8:	02d70063          	beq	a4,a3,ffffffffc02014c8 <default_free_pages+0xac>
ffffffffc02014ac:	ff872803          	lw	a6,-8(a4)
ffffffffc02014b0:	fe870593          	addi	a1,a4,-24
ffffffffc02014b4:	02081613          	slli	a2,a6,0x20
ffffffffc02014b8:	9201                	srli	a2,a2,0x20
ffffffffc02014ba:	00261793          	slli	a5,a2,0x2
ffffffffc02014be:	97b2                	add	a5,a5,a2
ffffffffc02014c0:	078e                	slli	a5,a5,0x3
ffffffffc02014c2:	97ae                	add	a5,a5,a1
ffffffffc02014c4:	02f50f63          	beq	a0,a5,ffffffffc0201502 <default_free_pages+0xe6>
ffffffffc02014c8:	7118                	ld	a4,32(a0)
ffffffffc02014ca:	00d70f63          	beq	a4,a3,ffffffffc02014e8 <default_free_pages+0xcc>
ffffffffc02014ce:	490c                	lw	a1,16(a0)
ffffffffc02014d0:	fe870693          	addi	a3,a4,-24
ffffffffc02014d4:	02059613          	slli	a2,a1,0x20
ffffffffc02014d8:	9201                	srli	a2,a2,0x20
ffffffffc02014da:	00261793          	slli	a5,a2,0x2
ffffffffc02014de:	97b2                	add	a5,a5,a2
ffffffffc02014e0:	078e                	slli	a5,a5,0x3
ffffffffc02014e2:	97aa                	add	a5,a5,a0
ffffffffc02014e4:	04f68863          	beq	a3,a5,ffffffffc0201534 <default_free_pages+0x118>
ffffffffc02014e8:	60a2                	ld	ra,8(sp)
ffffffffc02014ea:	0141                	addi	sp,sp,16
ffffffffc02014ec:	8082                	ret
ffffffffc02014ee:	e790                	sd	a2,8(a5)
ffffffffc02014f0:	f114                	sd	a3,32(a0)
ffffffffc02014f2:	6798                	ld	a4,8(a5)
ffffffffc02014f4:	ed1c                	sd	a5,24(a0)
ffffffffc02014f6:	02d70563          	beq	a4,a3,ffffffffc0201520 <default_free_pages+0x104>
ffffffffc02014fa:	8832                	mv	a6,a2
ffffffffc02014fc:	4585                	li	a1,1
ffffffffc02014fe:	87ba                	mv	a5,a4
ffffffffc0201500:	bf41                	j	ffffffffc0201490 <default_free_pages+0x74>
ffffffffc0201502:	491c                	lw	a5,16(a0)
ffffffffc0201504:	0107883b          	addw	a6,a5,a6
ffffffffc0201508:	ff072c23          	sw	a6,-8(a4)
ffffffffc020150c:	57f5                	li	a5,-3
ffffffffc020150e:	60f8b02f          	amoand.d	zero,a5,(a7)
ffffffffc0201512:	6d10                	ld	a2,24(a0)
ffffffffc0201514:	711c                	ld	a5,32(a0)
ffffffffc0201516:	852e                	mv	a0,a1
ffffffffc0201518:	e61c                	sd	a5,8(a2)
ffffffffc020151a:	6718                	ld	a4,8(a4)
ffffffffc020151c:	e390                	sd	a2,0(a5)
ffffffffc020151e:	b775                	j	ffffffffc02014ca <default_free_pages+0xae>
ffffffffc0201520:	e290                	sd	a2,0(a3)
ffffffffc0201522:	873e                	mv	a4,a5
ffffffffc0201524:	b761                	j	ffffffffc02014ac <default_free_pages+0x90>
ffffffffc0201526:	60a2                	ld	ra,8(sp)
ffffffffc0201528:	e390                	sd	a2,0(a5)
ffffffffc020152a:	e790                	sd	a2,8(a5)
ffffffffc020152c:	f11c                	sd	a5,32(a0)
ffffffffc020152e:	ed1c                	sd	a5,24(a0)
ffffffffc0201530:	0141                	addi	sp,sp,16
ffffffffc0201532:	8082                	ret
ffffffffc0201534:	ff872783          	lw	a5,-8(a4)
ffffffffc0201538:	ff070693          	addi	a3,a4,-16
ffffffffc020153c:	9dbd                	addw	a1,a1,a5
ffffffffc020153e:	c90c                	sw	a1,16(a0)
ffffffffc0201540:	57f5                	li	a5,-3
ffffffffc0201542:	60f6b02f          	amoand.d	zero,a5,(a3)
ffffffffc0201546:	6314                	ld	a3,0(a4)
ffffffffc0201548:	671c                	ld	a5,8(a4)
ffffffffc020154a:	60a2                	ld	ra,8(sp)
ffffffffc020154c:	e69c                	sd	a5,8(a3)
ffffffffc020154e:	e394                	sd	a3,0(a5)
ffffffffc0201550:	0141                	addi	sp,sp,16
ffffffffc0201552:	8082                	ret
ffffffffc0201554:	00001697          	auipc	a3,0x1
ffffffffc0201558:	6cc68693          	addi	a3,a3,1740 # ffffffffc0202c20 <commands+0xa20>
ffffffffc020155c:	00001617          	auipc	a2,0x1
ffffffffc0201560:	36460613          	addi	a2,a2,868 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0201564:	08300593          	li	a1,131
ffffffffc0201568:	00001517          	auipc	a0,0x1
ffffffffc020156c:	37050513          	addi	a0,a0,880 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201570:	e73fe0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc0201574:	00001697          	auipc	a3,0x1
ffffffffc0201578:	6a468693          	addi	a3,a3,1700 # ffffffffc0202c18 <commands+0xa18>
ffffffffc020157c:	00001617          	auipc	a2,0x1
ffffffffc0201580:	34460613          	addi	a2,a2,836 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0201584:	08000593          	li	a1,128
ffffffffc0201588:	00001517          	auipc	a0,0x1
ffffffffc020158c:	35050513          	addi	a0,a0,848 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201590:	e53fe0ef          	jal	ra,ffffffffc02003e2 <__panic>

ffffffffc0201594 <default_alloc_pages>:
ffffffffc0201594:	c959                	beqz	a0,ffffffffc020162a <default_alloc_pages+0x96>
ffffffffc0201596:	00006597          	auipc	a1,0x6
ffffffffc020159a:	a9258593          	addi	a1,a1,-1390 # ffffffffc0207028 <free_area>
ffffffffc020159e:	0105a803          	lw	a6,16(a1)
ffffffffc02015a2:	862a                	mv	a2,a0
ffffffffc02015a4:	02081793          	slli	a5,a6,0x20
ffffffffc02015a8:	9381                	srli	a5,a5,0x20
ffffffffc02015aa:	00a7ee63          	bltu	a5,a0,ffffffffc02015c6 <default_alloc_pages+0x32>
ffffffffc02015ae:	87ae                	mv	a5,a1
ffffffffc02015b0:	a801                	j	ffffffffc02015c0 <default_alloc_pages+0x2c>
ffffffffc02015b2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02015b6:	02071693          	slli	a3,a4,0x20
ffffffffc02015ba:	9281                	srli	a3,a3,0x20
ffffffffc02015bc:	00c6f763          	bgeu	a3,a2,ffffffffc02015ca <default_alloc_pages+0x36>
ffffffffc02015c0:	679c                	ld	a5,8(a5)
ffffffffc02015c2:	feb798e3          	bne	a5,a1,ffffffffc02015b2 <default_alloc_pages+0x1e>
ffffffffc02015c6:	4501                	li	a0,0
ffffffffc02015c8:	8082                	ret
ffffffffc02015ca:	0007b883          	ld	a7,0(a5)
ffffffffc02015ce:	0087b303          	ld	t1,8(a5)
ffffffffc02015d2:	fe878513          	addi	a0,a5,-24
ffffffffc02015d6:	00060e1b          	sext.w	t3,a2
ffffffffc02015da:	0068b423          	sd	t1,8(a7)
ffffffffc02015de:	01133023          	sd	a7,0(t1)
ffffffffc02015e2:	02d67b63          	bgeu	a2,a3,ffffffffc0201618 <default_alloc_pages+0x84>
ffffffffc02015e6:	00261693          	slli	a3,a2,0x2
ffffffffc02015ea:	96b2                	add	a3,a3,a2
ffffffffc02015ec:	068e                	slli	a3,a3,0x3
ffffffffc02015ee:	96aa                	add	a3,a3,a0
ffffffffc02015f0:	41c7073b          	subw	a4,a4,t3
ffffffffc02015f4:	ca98                	sw	a4,16(a3)
ffffffffc02015f6:	00868613          	addi	a2,a3,8
ffffffffc02015fa:	4709                	li	a4,2
ffffffffc02015fc:	40e6302f          	amoor.d	zero,a4,(a2)
ffffffffc0201600:	0088b703          	ld	a4,8(a7)
ffffffffc0201604:	01868613          	addi	a2,a3,24
ffffffffc0201608:	0105a803          	lw	a6,16(a1)
ffffffffc020160c:	e310                	sd	a2,0(a4)
ffffffffc020160e:	00c8b423          	sd	a2,8(a7)
ffffffffc0201612:	f298                	sd	a4,32(a3)
ffffffffc0201614:	0116bc23          	sd	a7,24(a3)
ffffffffc0201618:	41c8083b          	subw	a6,a6,t3
ffffffffc020161c:	0105a823          	sw	a6,16(a1)
ffffffffc0201620:	5775                	li	a4,-3
ffffffffc0201622:	17c1                	addi	a5,a5,-16
ffffffffc0201624:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201628:	8082                	ret
ffffffffc020162a:	1141                	addi	sp,sp,-16
ffffffffc020162c:	00001697          	auipc	a3,0x1
ffffffffc0201630:	5ec68693          	addi	a3,a3,1516 # ffffffffc0202c18 <commands+0xa18>
ffffffffc0201634:	00001617          	auipc	a2,0x1
ffffffffc0201638:	28c60613          	addi	a2,a2,652 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc020163c:	06200593          	li	a1,98
ffffffffc0201640:	00001517          	auipc	a0,0x1
ffffffffc0201644:	29850513          	addi	a0,a0,664 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0201648:	e406                	sd	ra,8(sp)
ffffffffc020164a:	d99fe0ef          	jal	ra,ffffffffc02003e2 <__panic>

ffffffffc020164e <default_init_memmap>:
ffffffffc020164e:	1141                	addi	sp,sp,-16
ffffffffc0201650:	e406                	sd	ra,8(sp)
ffffffffc0201652:	c9e1                	beqz	a1,ffffffffc0201722 <default_init_memmap+0xd4>
ffffffffc0201654:	00259693          	slli	a3,a1,0x2
ffffffffc0201658:	96ae                	add	a3,a3,a1
ffffffffc020165a:	068e                	slli	a3,a3,0x3
ffffffffc020165c:	96aa                	add	a3,a3,a0
ffffffffc020165e:	87aa                	mv	a5,a0
ffffffffc0201660:	00d50f63          	beq	a0,a3,ffffffffc020167e <default_init_memmap+0x30>
ffffffffc0201664:	6798                	ld	a4,8(a5)
ffffffffc0201666:	8b05                	andi	a4,a4,1
ffffffffc0201668:	cf49                	beqz	a4,ffffffffc0201702 <default_init_memmap+0xb4>
ffffffffc020166a:	0007a823          	sw	zero,16(a5)
ffffffffc020166e:	0007b423          	sd	zero,8(a5)
ffffffffc0201672:	0007a023          	sw	zero,0(a5)
ffffffffc0201676:	02878793          	addi	a5,a5,40
ffffffffc020167a:	fed795e3          	bne	a5,a3,ffffffffc0201664 <default_init_memmap+0x16>
ffffffffc020167e:	2581                	sext.w	a1,a1
ffffffffc0201680:	c90c                	sw	a1,16(a0)
ffffffffc0201682:	4789                	li	a5,2
ffffffffc0201684:	00850713          	addi	a4,a0,8
ffffffffc0201688:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc020168c:	00006697          	auipc	a3,0x6
ffffffffc0201690:	99c68693          	addi	a3,a3,-1636 # ffffffffc0207028 <free_area>
ffffffffc0201694:	4a98                	lw	a4,16(a3)
ffffffffc0201696:	669c                	ld	a5,8(a3)
ffffffffc0201698:	01850613          	addi	a2,a0,24
ffffffffc020169c:	9db9                	addw	a1,a1,a4
ffffffffc020169e:	ca8c                	sw	a1,16(a3)
ffffffffc02016a0:	04d78a63          	beq	a5,a3,ffffffffc02016f4 <default_init_memmap+0xa6>
ffffffffc02016a4:	fe878713          	addi	a4,a5,-24
ffffffffc02016a8:	0006b803          	ld	a6,0(a3)
ffffffffc02016ac:	4581                	li	a1,0
ffffffffc02016ae:	00e56a63          	bltu	a0,a4,ffffffffc02016c2 <default_init_memmap+0x74>
ffffffffc02016b2:	6798                	ld	a4,8(a5)
ffffffffc02016b4:	02d70263          	beq	a4,a3,ffffffffc02016d8 <default_init_memmap+0x8a>
ffffffffc02016b8:	87ba                	mv	a5,a4
ffffffffc02016ba:	fe878713          	addi	a4,a5,-24
ffffffffc02016be:	fee57ae3          	bgeu	a0,a4,ffffffffc02016b2 <default_init_memmap+0x64>
ffffffffc02016c2:	c199                	beqz	a1,ffffffffc02016c8 <default_init_memmap+0x7a>
ffffffffc02016c4:	0106b023          	sd	a6,0(a3)
ffffffffc02016c8:	6398                	ld	a4,0(a5)
ffffffffc02016ca:	60a2                	ld	ra,8(sp)
ffffffffc02016cc:	e390                	sd	a2,0(a5)
ffffffffc02016ce:	e710                	sd	a2,8(a4)
ffffffffc02016d0:	f11c                	sd	a5,32(a0)
ffffffffc02016d2:	ed18                	sd	a4,24(a0)
ffffffffc02016d4:	0141                	addi	sp,sp,16
ffffffffc02016d6:	8082                	ret
ffffffffc02016d8:	e790                	sd	a2,8(a5)
ffffffffc02016da:	f114                	sd	a3,32(a0)
ffffffffc02016dc:	6798                	ld	a4,8(a5)
ffffffffc02016de:	ed1c                	sd	a5,24(a0)
ffffffffc02016e0:	00d70663          	beq	a4,a3,ffffffffc02016ec <default_init_memmap+0x9e>
ffffffffc02016e4:	8832                	mv	a6,a2
ffffffffc02016e6:	4585                	li	a1,1
ffffffffc02016e8:	87ba                	mv	a5,a4
ffffffffc02016ea:	bfc1                	j	ffffffffc02016ba <default_init_memmap+0x6c>
ffffffffc02016ec:	60a2                	ld	ra,8(sp)
ffffffffc02016ee:	e290                	sd	a2,0(a3)
ffffffffc02016f0:	0141                	addi	sp,sp,16
ffffffffc02016f2:	8082                	ret
ffffffffc02016f4:	60a2                	ld	ra,8(sp)
ffffffffc02016f6:	e390                	sd	a2,0(a5)
ffffffffc02016f8:	e790                	sd	a2,8(a5)
ffffffffc02016fa:	f11c                	sd	a5,32(a0)
ffffffffc02016fc:	ed1c                	sd	a5,24(a0)
ffffffffc02016fe:	0141                	addi	sp,sp,16
ffffffffc0201700:	8082                	ret
ffffffffc0201702:	00001697          	auipc	a3,0x1
ffffffffc0201706:	54668693          	addi	a3,a3,1350 # ffffffffc0202c48 <commands+0xa48>
ffffffffc020170a:	00001617          	auipc	a2,0x1
ffffffffc020170e:	1b660613          	addi	a2,a2,438 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0201712:	04900593          	li	a1,73
ffffffffc0201716:	00001517          	auipc	a0,0x1
ffffffffc020171a:	1c250513          	addi	a0,a0,450 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc020171e:	cc5fe0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc0201722:	00001697          	auipc	a3,0x1
ffffffffc0201726:	4f668693          	addi	a3,a3,1270 # ffffffffc0202c18 <commands+0xa18>
ffffffffc020172a:	00001617          	auipc	a2,0x1
ffffffffc020172e:	19660613          	addi	a2,a2,406 # ffffffffc02028c0 <commands+0x6c0>
ffffffffc0201732:	04600593          	li	a1,70
ffffffffc0201736:	00001517          	auipc	a0,0x1
ffffffffc020173a:	1a250513          	addi	a0,a0,418 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc020173e:	ca5fe0ef          	jal	ra,ffffffffc02003e2 <__panic>

ffffffffc0201742 <alloc_pages>:
ffffffffc0201742:	100027f3          	csrr	a5,sstatus
ffffffffc0201746:	8b89                	andi	a5,a5,2
ffffffffc0201748:	e799                	bnez	a5,ffffffffc0201756 <alloc_pages+0x14>
ffffffffc020174a:	00006797          	auipc	a5,0x6
ffffffffc020174e:	d2e7b783          	ld	a5,-722(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201752:	6f9c                	ld	a5,24(a5)
ffffffffc0201754:	8782                	jr	a5
ffffffffc0201756:	1141                	addi	sp,sp,-16
ffffffffc0201758:	e406                	sd	ra,8(sp)
ffffffffc020175a:	e022                	sd	s0,0(sp)
ffffffffc020175c:	842a                	mv	s0,a0
ffffffffc020175e:	8e6ff0ef          	jal	ra,ffffffffc0200844 <intr_disable>
ffffffffc0201762:	00006797          	auipc	a5,0x6
ffffffffc0201766:	d167b783          	ld	a5,-746(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020176a:	6f9c                	ld	a5,24(a5)
ffffffffc020176c:	8522                	mv	a0,s0
ffffffffc020176e:	9782                	jalr	a5
ffffffffc0201770:	842a                	mv	s0,a0
ffffffffc0201772:	8ccff0ef          	jal	ra,ffffffffc020083e <intr_enable>
ffffffffc0201776:	60a2                	ld	ra,8(sp)
ffffffffc0201778:	8522                	mv	a0,s0
ffffffffc020177a:	6402                	ld	s0,0(sp)
ffffffffc020177c:	0141                	addi	sp,sp,16
ffffffffc020177e:	8082                	ret

ffffffffc0201780 <free_pages>:
ffffffffc0201780:	100027f3          	csrr	a5,sstatus
ffffffffc0201784:	8b89                	andi	a5,a5,2
ffffffffc0201786:	e799                	bnez	a5,ffffffffc0201794 <free_pages+0x14>
ffffffffc0201788:	00006797          	auipc	a5,0x6
ffffffffc020178c:	cf07b783          	ld	a5,-784(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201790:	739c                	ld	a5,32(a5)
ffffffffc0201792:	8782                	jr	a5
ffffffffc0201794:	1101                	addi	sp,sp,-32
ffffffffc0201796:	ec06                	sd	ra,24(sp)
ffffffffc0201798:	e822                	sd	s0,16(sp)
ffffffffc020179a:	e426                	sd	s1,8(sp)
ffffffffc020179c:	842a                	mv	s0,a0
ffffffffc020179e:	84ae                	mv	s1,a1
ffffffffc02017a0:	8a4ff0ef          	jal	ra,ffffffffc0200844 <intr_disable>
ffffffffc02017a4:	00006797          	auipc	a5,0x6
ffffffffc02017a8:	cd47b783          	ld	a5,-812(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017ac:	739c                	ld	a5,32(a5)
ffffffffc02017ae:	85a6                	mv	a1,s1
ffffffffc02017b0:	8522                	mv	a0,s0
ffffffffc02017b2:	9782                	jalr	a5
ffffffffc02017b4:	6442                	ld	s0,16(sp)
ffffffffc02017b6:	60e2                	ld	ra,24(sp)
ffffffffc02017b8:	64a2                	ld	s1,8(sp)
ffffffffc02017ba:	6105                	addi	sp,sp,32
ffffffffc02017bc:	882ff06f          	j	ffffffffc020083e <intr_enable>

ffffffffc02017c0 <nr_free_pages>:
ffffffffc02017c0:	100027f3          	csrr	a5,sstatus
ffffffffc02017c4:	8b89                	andi	a5,a5,2
ffffffffc02017c6:	e799                	bnez	a5,ffffffffc02017d4 <nr_free_pages+0x14>
ffffffffc02017c8:	00006797          	auipc	a5,0x6
ffffffffc02017cc:	cb07b783          	ld	a5,-848(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017d0:	779c                	ld	a5,40(a5)
ffffffffc02017d2:	8782                	jr	a5
ffffffffc02017d4:	1141                	addi	sp,sp,-16
ffffffffc02017d6:	e406                	sd	ra,8(sp)
ffffffffc02017d8:	e022                	sd	s0,0(sp)
ffffffffc02017da:	86aff0ef          	jal	ra,ffffffffc0200844 <intr_disable>
ffffffffc02017de:	00006797          	auipc	a5,0x6
ffffffffc02017e2:	c9a7b783          	ld	a5,-870(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017e6:	779c                	ld	a5,40(a5)
ffffffffc02017e8:	9782                	jalr	a5
ffffffffc02017ea:	842a                	mv	s0,a0
ffffffffc02017ec:	852ff0ef          	jal	ra,ffffffffc020083e <intr_enable>
ffffffffc02017f0:	60a2                	ld	ra,8(sp)
ffffffffc02017f2:	8522                	mv	a0,s0
ffffffffc02017f4:	6402                	ld	s0,0(sp)
ffffffffc02017f6:	0141                	addi	sp,sp,16
ffffffffc02017f8:	8082                	ret

ffffffffc02017fa <pmm_init>:
ffffffffc02017fa:	00001797          	auipc	a5,0x1
ffffffffc02017fe:	47678793          	addi	a5,a5,1142 # ffffffffc0202c70 <default_pmm_manager>
ffffffffc0201802:	638c                	ld	a1,0(a5)
ffffffffc0201804:	7179                	addi	sp,sp,-48
ffffffffc0201806:	f022                	sd	s0,32(sp)
ffffffffc0201808:	00001517          	auipc	a0,0x1
ffffffffc020180c:	4a050513          	addi	a0,a0,1184 # ffffffffc0202ca8 <default_pmm_manager+0x38>
ffffffffc0201810:	00006417          	auipc	s0,0x6
ffffffffc0201814:	c6840413          	addi	s0,s0,-920 # ffffffffc0207478 <pmm_manager>
ffffffffc0201818:	f406                	sd	ra,40(sp)
ffffffffc020181a:	ec26                	sd	s1,24(sp)
ffffffffc020181c:	e44e                	sd	s3,8(sp)
ffffffffc020181e:	e84a                	sd	s2,16(sp)
ffffffffc0201820:	e052                	sd	s4,0(sp)
ffffffffc0201822:	e01c                	sd	a5,0(s0)
ffffffffc0201824:	8c5fe0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0201828:	601c                	ld	a5,0(s0)
ffffffffc020182a:	00006497          	auipc	s1,0x6
ffffffffc020182e:	c6648493          	addi	s1,s1,-922 # ffffffffc0207490 <va_pa_offset>
ffffffffc0201832:	679c                	ld	a5,8(a5)
ffffffffc0201834:	9782                	jalr	a5
ffffffffc0201836:	57f5                	li	a5,-3
ffffffffc0201838:	07fa                	slli	a5,a5,0x1e
ffffffffc020183a:	e09c                	sd	a5,0(s1)
ffffffffc020183c:	feffe0ef          	jal	ra,ffffffffc020082a <get_memory_base>
ffffffffc0201840:	89aa                	mv	s3,a0
ffffffffc0201842:	ff3fe0ef          	jal	ra,ffffffffc0200834 <get_memory_size>
ffffffffc0201846:	16050163          	beqz	a0,ffffffffc02019a8 <pmm_init+0x1ae>
ffffffffc020184a:	892a                	mv	s2,a0
ffffffffc020184c:	00001517          	auipc	a0,0x1
ffffffffc0201850:	4a450513          	addi	a0,a0,1188 # ffffffffc0202cf0 <default_pmm_manager+0x80>
ffffffffc0201854:	895fe0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0201858:	01298a33          	add	s4,s3,s2
ffffffffc020185c:	864e                	mv	a2,s3
ffffffffc020185e:	fffa0693          	addi	a3,s4,-1
ffffffffc0201862:	85ca                	mv	a1,s2
ffffffffc0201864:	00001517          	auipc	a0,0x1
ffffffffc0201868:	4a450513          	addi	a0,a0,1188 # ffffffffc0202d08 <default_pmm_manager+0x98>
ffffffffc020186c:	87dfe0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0201870:	c80007b7          	lui	a5,0xc8000
ffffffffc0201874:	8652                	mv	a2,s4
ffffffffc0201876:	0d47e863          	bltu	a5,s4,ffffffffc0201946 <pmm_init+0x14c>
ffffffffc020187a:	00007797          	auipc	a5,0x7
ffffffffc020187e:	c2578793          	addi	a5,a5,-987 # ffffffffc020849f <end+0xfff>
ffffffffc0201882:	757d                	lui	a0,0xfffff
ffffffffc0201884:	8d7d                	and	a0,a0,a5
ffffffffc0201886:	8231                	srli	a2,a2,0xc
ffffffffc0201888:	00006597          	auipc	a1,0x6
ffffffffc020188c:	be058593          	addi	a1,a1,-1056 # ffffffffc0207468 <npage>
ffffffffc0201890:	00006817          	auipc	a6,0x6
ffffffffc0201894:	be080813          	addi	a6,a6,-1056 # ffffffffc0207470 <pages>
ffffffffc0201898:	e190                	sd	a2,0(a1)
ffffffffc020189a:	00a83023          	sd	a0,0(a6)
ffffffffc020189e:	000807b7          	lui	a5,0x80
ffffffffc02018a2:	02f60663          	beq	a2,a5,ffffffffc02018ce <pmm_init+0xd4>
ffffffffc02018a6:	4701                	li	a4,0
ffffffffc02018a8:	4781                	li	a5,0
ffffffffc02018aa:	4305                	li	t1,1
ffffffffc02018ac:	fff808b7          	lui	a7,0xfff80
ffffffffc02018b0:	953a                	add	a0,a0,a4
ffffffffc02018b2:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc02018b6:	4066b02f          	amoor.d	zero,t1,(a3)
ffffffffc02018ba:	6190                	ld	a2,0(a1)
ffffffffc02018bc:	0785                	addi	a5,a5,1
ffffffffc02018be:	00083503          	ld	a0,0(a6)
ffffffffc02018c2:	011606b3          	add	a3,a2,a7
ffffffffc02018c6:	02870713          	addi	a4,a4,40
ffffffffc02018ca:	fed7e3e3          	bltu	a5,a3,ffffffffc02018b0 <pmm_init+0xb6>
ffffffffc02018ce:	00261693          	slli	a3,a2,0x2
ffffffffc02018d2:	96b2                	add	a3,a3,a2
ffffffffc02018d4:	fec007b7          	lui	a5,0xfec00
ffffffffc02018d8:	97aa                	add	a5,a5,a0
ffffffffc02018da:	068e                	slli	a3,a3,0x3
ffffffffc02018dc:	96be                	add	a3,a3,a5
ffffffffc02018de:	c02007b7          	lui	a5,0xc0200
ffffffffc02018e2:	0af6e763          	bltu	a3,a5,ffffffffc0201990 <pmm_init+0x196>
ffffffffc02018e6:	6098                	ld	a4,0(s1)
ffffffffc02018e8:	77fd                	lui	a5,0xfffff
ffffffffc02018ea:	00fa75b3          	and	a1,s4,a5
ffffffffc02018ee:	8e99                	sub	a3,a3,a4
ffffffffc02018f0:	04b6ee63          	bltu	a3,a1,ffffffffc020194c <pmm_init+0x152>
ffffffffc02018f4:	601c                	ld	a5,0(s0)
ffffffffc02018f6:	7b9c                	ld	a5,48(a5)
ffffffffc02018f8:	9782                	jalr	a5
ffffffffc02018fa:	00001517          	auipc	a0,0x1
ffffffffc02018fe:	49650513          	addi	a0,a0,1174 # ffffffffc0202d90 <default_pmm_manager+0x120>
ffffffffc0201902:	fe6fe0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0201906:	00004597          	auipc	a1,0x4
ffffffffc020190a:	6fa58593          	addi	a1,a1,1786 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc020190e:	00006797          	auipc	a5,0x6
ffffffffc0201912:	b6b7bd23          	sd	a1,-1158(a5) # ffffffffc0207488 <satp_virtual>
ffffffffc0201916:	c02007b7          	lui	a5,0xc0200
ffffffffc020191a:	0af5e363          	bltu	a1,a5,ffffffffc02019c0 <pmm_init+0x1c6>
ffffffffc020191e:	6090                	ld	a2,0(s1)
ffffffffc0201920:	7402                	ld	s0,32(sp)
ffffffffc0201922:	70a2                	ld	ra,40(sp)
ffffffffc0201924:	64e2                	ld	s1,24(sp)
ffffffffc0201926:	6942                	ld	s2,16(sp)
ffffffffc0201928:	69a2                	ld	s3,8(sp)
ffffffffc020192a:	6a02                	ld	s4,0(sp)
ffffffffc020192c:	40c58633          	sub	a2,a1,a2
ffffffffc0201930:	00006797          	auipc	a5,0x6
ffffffffc0201934:	b4c7b823          	sd	a2,-1200(a5) # ffffffffc0207480 <satp_physical>
ffffffffc0201938:	00001517          	auipc	a0,0x1
ffffffffc020193c:	47850513          	addi	a0,a0,1144 # ffffffffc0202db0 <default_pmm_manager+0x140>
ffffffffc0201940:	6145                	addi	sp,sp,48
ffffffffc0201942:	fa6fe06f          	j	ffffffffc02000e8 <cprintf>
ffffffffc0201946:	c8000637          	lui	a2,0xc8000
ffffffffc020194a:	bf05                	j	ffffffffc020187a <pmm_init+0x80>
ffffffffc020194c:	6705                	lui	a4,0x1
ffffffffc020194e:	177d                	addi	a4,a4,-1
ffffffffc0201950:	96ba                	add	a3,a3,a4
ffffffffc0201952:	8efd                	and	a3,a3,a5
ffffffffc0201954:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201958:	02c7f063          	bgeu	a5,a2,ffffffffc0201978 <pmm_init+0x17e>
ffffffffc020195c:	6010                	ld	a2,0(s0)
ffffffffc020195e:	fff80737          	lui	a4,0xfff80
ffffffffc0201962:	973e                	add	a4,a4,a5
ffffffffc0201964:	00271793          	slli	a5,a4,0x2
ffffffffc0201968:	97ba                	add	a5,a5,a4
ffffffffc020196a:	6a18                	ld	a4,16(a2)
ffffffffc020196c:	8d95                	sub	a1,a1,a3
ffffffffc020196e:	078e                	slli	a5,a5,0x3
ffffffffc0201970:	81b1                	srli	a1,a1,0xc
ffffffffc0201972:	953e                	add	a0,a0,a5
ffffffffc0201974:	9702                	jalr	a4
ffffffffc0201976:	bfbd                	j	ffffffffc02018f4 <pmm_init+0xfa>
ffffffffc0201978:	00001617          	auipc	a2,0x1
ffffffffc020197c:	3e860613          	addi	a2,a2,1000 # ffffffffc0202d60 <default_pmm_manager+0xf0>
ffffffffc0201980:	06b00593          	li	a1,107
ffffffffc0201984:	00001517          	auipc	a0,0x1
ffffffffc0201988:	3fc50513          	addi	a0,a0,1020 # ffffffffc0202d80 <default_pmm_manager+0x110>
ffffffffc020198c:	a57fe0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc0201990:	00001617          	auipc	a2,0x1
ffffffffc0201994:	3a860613          	addi	a2,a2,936 # ffffffffc0202d38 <default_pmm_manager+0xc8>
ffffffffc0201998:	07100593          	li	a1,113
ffffffffc020199c:	00001517          	auipc	a0,0x1
ffffffffc02019a0:	34450513          	addi	a0,a0,836 # ffffffffc0202ce0 <default_pmm_manager+0x70>
ffffffffc02019a4:	a3ffe0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02019a8:	00001617          	auipc	a2,0x1
ffffffffc02019ac:	31860613          	addi	a2,a2,792 # ffffffffc0202cc0 <default_pmm_manager+0x50>
ffffffffc02019b0:	05a00593          	li	a1,90
ffffffffc02019b4:	00001517          	auipc	a0,0x1
ffffffffc02019b8:	32c50513          	addi	a0,a0,812 # ffffffffc0202ce0 <default_pmm_manager+0x70>
ffffffffc02019bc:	a27fe0ef          	jal	ra,ffffffffc02003e2 <__panic>
ffffffffc02019c0:	86ae                	mv	a3,a1
ffffffffc02019c2:	00001617          	auipc	a2,0x1
ffffffffc02019c6:	37660613          	addi	a2,a2,886 # ffffffffc0202d38 <default_pmm_manager+0xc8>
ffffffffc02019ca:	08c00593          	li	a1,140
ffffffffc02019ce:	00001517          	auipc	a0,0x1
ffffffffc02019d2:	31250513          	addi	a0,a0,786 # ffffffffc0202ce0 <default_pmm_manager+0x70>
ffffffffc02019d6:	a0dfe0ef          	jal	ra,ffffffffc02003e2 <__panic>

ffffffffc02019da <printnum>:
ffffffffc02019da:	02069813          	slli	a6,a3,0x20
ffffffffc02019de:	7179                	addi	sp,sp,-48
ffffffffc02019e0:	02085813          	srli	a6,a6,0x20
ffffffffc02019e4:	e052                	sd	s4,0(sp)
ffffffffc02019e6:	03067a33          	remu	s4,a2,a6
ffffffffc02019ea:	f022                	sd	s0,32(sp)
ffffffffc02019ec:	ec26                	sd	s1,24(sp)
ffffffffc02019ee:	e84a                	sd	s2,16(sp)
ffffffffc02019f0:	f406                	sd	ra,40(sp)
ffffffffc02019f2:	e44e                	sd	s3,8(sp)
ffffffffc02019f4:	84aa                	mv	s1,a0
ffffffffc02019f6:	892e                	mv	s2,a1
ffffffffc02019f8:	fff7041b          	addiw	s0,a4,-1
ffffffffc02019fc:	2a01                	sext.w	s4,s4
ffffffffc02019fe:	03067e63          	bgeu	a2,a6,ffffffffc0201a3a <printnum+0x60>
ffffffffc0201a02:	89be                	mv	s3,a5
ffffffffc0201a04:	00805763          	blez	s0,ffffffffc0201a12 <printnum+0x38>
ffffffffc0201a08:	347d                	addiw	s0,s0,-1
ffffffffc0201a0a:	85ca                	mv	a1,s2
ffffffffc0201a0c:	854e                	mv	a0,s3
ffffffffc0201a0e:	9482                	jalr	s1
ffffffffc0201a10:	fc65                	bnez	s0,ffffffffc0201a08 <printnum+0x2e>
ffffffffc0201a12:	1a02                	slli	s4,s4,0x20
ffffffffc0201a14:	00001797          	auipc	a5,0x1
ffffffffc0201a18:	3dc78793          	addi	a5,a5,988 # ffffffffc0202df0 <default_pmm_manager+0x180>
ffffffffc0201a1c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a20:	9a3e                	add	s4,s4,a5
ffffffffc0201a22:	7402                	ld	s0,32(sp)
ffffffffc0201a24:	000a4503          	lbu	a0,0(s4)
ffffffffc0201a28:	70a2                	ld	ra,40(sp)
ffffffffc0201a2a:	69a2                	ld	s3,8(sp)
ffffffffc0201a2c:	6a02                	ld	s4,0(sp)
ffffffffc0201a2e:	85ca                	mv	a1,s2
ffffffffc0201a30:	87a6                	mv	a5,s1
ffffffffc0201a32:	6942                	ld	s2,16(sp)
ffffffffc0201a34:	64e2                	ld	s1,24(sp)
ffffffffc0201a36:	6145                	addi	sp,sp,48
ffffffffc0201a38:	8782                	jr	a5
ffffffffc0201a3a:	03065633          	divu	a2,a2,a6
ffffffffc0201a3e:	8722                	mv	a4,s0
ffffffffc0201a40:	f9bff0ef          	jal	ra,ffffffffc02019da <printnum>
ffffffffc0201a44:	b7f9                	j	ffffffffc0201a12 <printnum+0x38>

ffffffffc0201a46 <vprintfmt>:
ffffffffc0201a46:	7119                	addi	sp,sp,-128
ffffffffc0201a48:	f4a6                	sd	s1,104(sp)
ffffffffc0201a4a:	f0ca                	sd	s2,96(sp)
ffffffffc0201a4c:	ecce                	sd	s3,88(sp)
ffffffffc0201a4e:	e8d2                	sd	s4,80(sp)
ffffffffc0201a50:	e4d6                	sd	s5,72(sp)
ffffffffc0201a52:	e0da                	sd	s6,64(sp)
ffffffffc0201a54:	fc5e                	sd	s7,56(sp)
ffffffffc0201a56:	f06a                	sd	s10,32(sp)
ffffffffc0201a58:	fc86                	sd	ra,120(sp)
ffffffffc0201a5a:	f8a2                	sd	s0,112(sp)
ffffffffc0201a5c:	f862                	sd	s8,48(sp)
ffffffffc0201a5e:	f466                	sd	s9,40(sp)
ffffffffc0201a60:	ec6e                	sd	s11,24(sp)
ffffffffc0201a62:	892a                	mv	s2,a0
ffffffffc0201a64:	84ae                	mv	s1,a1
ffffffffc0201a66:	8d32                	mv	s10,a2
ffffffffc0201a68:	8a36                	mv	s4,a3
ffffffffc0201a6a:	02500993          	li	s3,37
ffffffffc0201a6e:	5b7d                	li	s6,-1
ffffffffc0201a70:	00001a97          	auipc	s5,0x1
ffffffffc0201a74:	3b4a8a93          	addi	s5,s5,948 # ffffffffc0202e24 <default_pmm_manager+0x1b4>
ffffffffc0201a78:	00001b97          	auipc	s7,0x1
ffffffffc0201a7c:	588b8b93          	addi	s7,s7,1416 # ffffffffc0203000 <error_string>
ffffffffc0201a80:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a84:	001d0413          	addi	s0,s10,1
ffffffffc0201a88:	01350a63          	beq	a0,s3,ffffffffc0201a9c <vprintfmt+0x56>
ffffffffc0201a8c:	c121                	beqz	a0,ffffffffc0201acc <vprintfmt+0x86>
ffffffffc0201a8e:	85a6                	mv	a1,s1
ffffffffc0201a90:	0405                	addi	s0,s0,1
ffffffffc0201a92:	9902                	jalr	s2
ffffffffc0201a94:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a98:	ff351ae3          	bne	a0,s3,ffffffffc0201a8c <vprintfmt+0x46>
ffffffffc0201a9c:	00044603          	lbu	a2,0(s0)
ffffffffc0201aa0:	02000793          	li	a5,32
ffffffffc0201aa4:	4c81                	li	s9,0
ffffffffc0201aa6:	4881                	li	a7,0
ffffffffc0201aa8:	5c7d                	li	s8,-1
ffffffffc0201aaa:	5dfd                	li	s11,-1
ffffffffc0201aac:	05500513          	li	a0,85
ffffffffc0201ab0:	4825                	li	a6,9
ffffffffc0201ab2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201ab6:	0ff5f593          	zext.b	a1,a1
ffffffffc0201aba:	00140d13          	addi	s10,s0,1
ffffffffc0201abe:	04b56263          	bltu	a0,a1,ffffffffc0201b02 <vprintfmt+0xbc>
ffffffffc0201ac2:	058a                	slli	a1,a1,0x2
ffffffffc0201ac4:	95d6                	add	a1,a1,s5
ffffffffc0201ac6:	4194                	lw	a3,0(a1)
ffffffffc0201ac8:	96d6                	add	a3,a3,s5
ffffffffc0201aca:	8682                	jr	a3
ffffffffc0201acc:	70e6                	ld	ra,120(sp)
ffffffffc0201ace:	7446                	ld	s0,112(sp)
ffffffffc0201ad0:	74a6                	ld	s1,104(sp)
ffffffffc0201ad2:	7906                	ld	s2,96(sp)
ffffffffc0201ad4:	69e6                	ld	s3,88(sp)
ffffffffc0201ad6:	6a46                	ld	s4,80(sp)
ffffffffc0201ad8:	6aa6                	ld	s5,72(sp)
ffffffffc0201ada:	6b06                	ld	s6,64(sp)
ffffffffc0201adc:	7be2                	ld	s7,56(sp)
ffffffffc0201ade:	7c42                	ld	s8,48(sp)
ffffffffc0201ae0:	7ca2                	ld	s9,40(sp)
ffffffffc0201ae2:	7d02                	ld	s10,32(sp)
ffffffffc0201ae4:	6de2                	ld	s11,24(sp)
ffffffffc0201ae6:	6109                	addi	sp,sp,128
ffffffffc0201ae8:	8082                	ret
ffffffffc0201aea:	87b2                	mv	a5,a2
ffffffffc0201aec:	00144603          	lbu	a2,1(s0)
ffffffffc0201af0:	846a                	mv	s0,s10
ffffffffc0201af2:	00140d13          	addi	s10,s0,1
ffffffffc0201af6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201afa:	0ff5f593          	zext.b	a1,a1
ffffffffc0201afe:	fcb572e3          	bgeu	a0,a1,ffffffffc0201ac2 <vprintfmt+0x7c>
ffffffffc0201b02:	85a6                	mv	a1,s1
ffffffffc0201b04:	02500513          	li	a0,37
ffffffffc0201b08:	9902                	jalr	s2
ffffffffc0201b0a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b0e:	8d22                	mv	s10,s0
ffffffffc0201b10:	f73788e3          	beq	a5,s3,ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201b14:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b18:	1d7d                	addi	s10,s10,-1
ffffffffc0201b1a:	ff379de3          	bne	a5,s3,ffffffffc0201b14 <vprintfmt+0xce>
ffffffffc0201b1e:	b78d                	j	ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201b20:	fd060c1b          	addiw	s8,a2,-48
ffffffffc0201b24:	00144603          	lbu	a2,1(s0)
ffffffffc0201b28:	846a                	mv	s0,s10
ffffffffc0201b2a:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201b2e:	0006059b          	sext.w	a1,a2
ffffffffc0201b32:	02d86463          	bltu	a6,a3,ffffffffc0201b5a <vprintfmt+0x114>
ffffffffc0201b36:	00144603          	lbu	a2,1(s0)
ffffffffc0201b3a:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b3e:	0186873b          	addw	a4,a3,s8
ffffffffc0201b42:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b46:	9f2d                	addw	a4,a4,a1
ffffffffc0201b48:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201b4c:	0405                	addi	s0,s0,1
ffffffffc0201b4e:	fd070c1b          	addiw	s8,a4,-48
ffffffffc0201b52:	0006059b          	sext.w	a1,a2
ffffffffc0201b56:	fed870e3          	bgeu	a6,a3,ffffffffc0201b36 <vprintfmt+0xf0>
ffffffffc0201b5a:	f40ddce3          	bgez	s11,ffffffffc0201ab2 <vprintfmt+0x6c>
ffffffffc0201b5e:	8de2                	mv	s11,s8
ffffffffc0201b60:	5c7d                	li	s8,-1
ffffffffc0201b62:	bf81                	j	ffffffffc0201ab2 <vprintfmt+0x6c>
ffffffffc0201b64:	fffdc693          	not	a3,s11
ffffffffc0201b68:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b6a:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201b6e:	00144603          	lbu	a2,1(s0)
ffffffffc0201b72:	2d81                	sext.w	s11,s11
ffffffffc0201b74:	846a                	mv	s0,s10
ffffffffc0201b76:	bf35                	j	ffffffffc0201ab2 <vprintfmt+0x6c>
ffffffffc0201b78:	000a2c03          	lw	s8,0(s4)
ffffffffc0201b7c:	00144603          	lbu	a2,1(s0)
ffffffffc0201b80:	0a21                	addi	s4,s4,8
ffffffffc0201b82:	846a                	mv	s0,s10
ffffffffc0201b84:	bfd9                	j	ffffffffc0201b5a <vprintfmt+0x114>
ffffffffc0201b86:	4705                	li	a4,1
ffffffffc0201b88:	008a0593          	addi	a1,s4,8
ffffffffc0201b8c:	01174463          	blt	a4,a7,ffffffffc0201b94 <vprintfmt+0x14e>
ffffffffc0201b90:	1a088e63          	beqz	a7,ffffffffc0201d4c <vprintfmt+0x306>
ffffffffc0201b94:	000a3603          	ld	a2,0(s4)
ffffffffc0201b98:	46c1                	li	a3,16
ffffffffc0201b9a:	8a2e                	mv	s4,a1
ffffffffc0201b9c:	2781                	sext.w	a5,a5
ffffffffc0201b9e:	876e                	mv	a4,s11
ffffffffc0201ba0:	85a6                	mv	a1,s1
ffffffffc0201ba2:	854a                	mv	a0,s2
ffffffffc0201ba4:	e37ff0ef          	jal	ra,ffffffffc02019da <printnum>
ffffffffc0201ba8:	bde1                	j	ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201baa:	000a2503          	lw	a0,0(s4)
ffffffffc0201bae:	85a6                	mv	a1,s1
ffffffffc0201bb0:	0a21                	addi	s4,s4,8
ffffffffc0201bb2:	9902                	jalr	s2
ffffffffc0201bb4:	b5f1                	j	ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201bb6:	4705                	li	a4,1
ffffffffc0201bb8:	008a0593          	addi	a1,s4,8
ffffffffc0201bbc:	01174463          	blt	a4,a7,ffffffffc0201bc4 <vprintfmt+0x17e>
ffffffffc0201bc0:	18088163          	beqz	a7,ffffffffc0201d42 <vprintfmt+0x2fc>
ffffffffc0201bc4:	000a3603          	ld	a2,0(s4)
ffffffffc0201bc8:	46a9                	li	a3,10
ffffffffc0201bca:	8a2e                	mv	s4,a1
ffffffffc0201bcc:	bfc1                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201bce:	00144603          	lbu	a2,1(s0)
ffffffffc0201bd2:	4c85                	li	s9,1
ffffffffc0201bd4:	846a                	mv	s0,s10
ffffffffc0201bd6:	bdf1                	j	ffffffffc0201ab2 <vprintfmt+0x6c>
ffffffffc0201bd8:	85a6                	mv	a1,s1
ffffffffc0201bda:	02500513          	li	a0,37
ffffffffc0201bde:	9902                	jalr	s2
ffffffffc0201be0:	b545                	j	ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201be2:	00144603          	lbu	a2,1(s0)
ffffffffc0201be6:	2885                	addiw	a7,a7,1
ffffffffc0201be8:	846a                	mv	s0,s10
ffffffffc0201bea:	b5e1                	j	ffffffffc0201ab2 <vprintfmt+0x6c>
ffffffffc0201bec:	4705                	li	a4,1
ffffffffc0201bee:	008a0593          	addi	a1,s4,8
ffffffffc0201bf2:	01174463          	blt	a4,a7,ffffffffc0201bfa <vprintfmt+0x1b4>
ffffffffc0201bf6:	14088163          	beqz	a7,ffffffffc0201d38 <vprintfmt+0x2f2>
ffffffffc0201bfa:	000a3603          	ld	a2,0(s4)
ffffffffc0201bfe:	46a1                	li	a3,8
ffffffffc0201c00:	8a2e                	mv	s4,a1
ffffffffc0201c02:	bf69                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201c04:	03000513          	li	a0,48
ffffffffc0201c08:	85a6                	mv	a1,s1
ffffffffc0201c0a:	e03e                	sd	a5,0(sp)
ffffffffc0201c0c:	9902                	jalr	s2
ffffffffc0201c0e:	85a6                	mv	a1,s1
ffffffffc0201c10:	07800513          	li	a0,120
ffffffffc0201c14:	9902                	jalr	s2
ffffffffc0201c16:	0a21                	addi	s4,s4,8
ffffffffc0201c18:	6782                	ld	a5,0(sp)
ffffffffc0201c1a:	46c1                	li	a3,16
ffffffffc0201c1c:	ff8a3603          	ld	a2,-8(s4)
ffffffffc0201c20:	bfb5                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201c22:	000a3403          	ld	s0,0(s4)
ffffffffc0201c26:	008a0713          	addi	a4,s4,8
ffffffffc0201c2a:	e03a                	sd	a4,0(sp)
ffffffffc0201c2c:	14040263          	beqz	s0,ffffffffc0201d70 <vprintfmt+0x32a>
ffffffffc0201c30:	0fb05763          	blez	s11,ffffffffc0201d1e <vprintfmt+0x2d8>
ffffffffc0201c34:	02d00693          	li	a3,45
ffffffffc0201c38:	0cd79163          	bne	a5,a3,ffffffffc0201cfa <vprintfmt+0x2b4>
ffffffffc0201c3c:	00044783          	lbu	a5,0(s0)
ffffffffc0201c40:	0007851b          	sext.w	a0,a5
ffffffffc0201c44:	cf85                	beqz	a5,ffffffffc0201c7c <vprintfmt+0x236>
ffffffffc0201c46:	00140a13          	addi	s4,s0,1
ffffffffc0201c4a:	05e00413          	li	s0,94
ffffffffc0201c4e:	000c4563          	bltz	s8,ffffffffc0201c58 <vprintfmt+0x212>
ffffffffc0201c52:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c54:	036c0263          	beq	s8,s6,ffffffffc0201c78 <vprintfmt+0x232>
ffffffffc0201c58:	85a6                	mv	a1,s1
ffffffffc0201c5a:	0e0c8e63          	beqz	s9,ffffffffc0201d56 <vprintfmt+0x310>
ffffffffc0201c5e:	3781                	addiw	a5,a5,-32
ffffffffc0201c60:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d56 <vprintfmt+0x310>
ffffffffc0201c64:	03f00513          	li	a0,63
ffffffffc0201c68:	9902                	jalr	s2
ffffffffc0201c6a:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c6e:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c70:	0a05                	addi	s4,s4,1
ffffffffc0201c72:	0007851b          	sext.w	a0,a5
ffffffffc0201c76:	ffe1                	bnez	a5,ffffffffc0201c4e <vprintfmt+0x208>
ffffffffc0201c78:	01b05963          	blez	s11,ffffffffc0201c8a <vprintfmt+0x244>
ffffffffc0201c7c:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c7e:	85a6                	mv	a1,s1
ffffffffc0201c80:	02000513          	li	a0,32
ffffffffc0201c84:	9902                	jalr	s2
ffffffffc0201c86:	fe0d9be3          	bnez	s11,ffffffffc0201c7c <vprintfmt+0x236>
ffffffffc0201c8a:	6a02                	ld	s4,0(sp)
ffffffffc0201c8c:	bbd5                	j	ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201c8e:	4705                	li	a4,1
ffffffffc0201c90:	008a0c93          	addi	s9,s4,8
ffffffffc0201c94:	01174463          	blt	a4,a7,ffffffffc0201c9c <vprintfmt+0x256>
ffffffffc0201c98:	08088d63          	beqz	a7,ffffffffc0201d32 <vprintfmt+0x2ec>
ffffffffc0201c9c:	000a3403          	ld	s0,0(s4)
ffffffffc0201ca0:	0a044d63          	bltz	s0,ffffffffc0201d5a <vprintfmt+0x314>
ffffffffc0201ca4:	8622                	mv	a2,s0
ffffffffc0201ca6:	8a66                	mv	s4,s9
ffffffffc0201ca8:	46a9                	li	a3,10
ffffffffc0201caa:	bdcd                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201cac:	000a2783          	lw	a5,0(s4)
ffffffffc0201cb0:	4719                	li	a4,6
ffffffffc0201cb2:	0a21                	addi	s4,s4,8
ffffffffc0201cb4:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201cb8:	8fb5                	xor	a5,a5,a3
ffffffffc0201cba:	40d786bb          	subw	a3,a5,a3
ffffffffc0201cbe:	02d74163          	blt	a4,a3,ffffffffc0201ce0 <vprintfmt+0x29a>
ffffffffc0201cc2:	00369793          	slli	a5,a3,0x3
ffffffffc0201cc6:	97de                	add	a5,a5,s7
ffffffffc0201cc8:	639c                	ld	a5,0(a5)
ffffffffc0201cca:	cb99                	beqz	a5,ffffffffc0201ce0 <vprintfmt+0x29a>
ffffffffc0201ccc:	86be                	mv	a3,a5
ffffffffc0201cce:	00001617          	auipc	a2,0x1
ffffffffc0201cd2:	15260613          	addi	a2,a2,338 # ffffffffc0202e20 <default_pmm_manager+0x1b0>
ffffffffc0201cd6:	85a6                	mv	a1,s1
ffffffffc0201cd8:	854a                	mv	a0,s2
ffffffffc0201cda:	0ce000ef          	jal	ra,ffffffffc0201da8 <printfmt>
ffffffffc0201cde:	b34d                	j	ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201ce0:	00001617          	auipc	a2,0x1
ffffffffc0201ce4:	13060613          	addi	a2,a2,304 # ffffffffc0202e10 <default_pmm_manager+0x1a0>
ffffffffc0201ce8:	85a6                	mv	a1,s1
ffffffffc0201cea:	854a                	mv	a0,s2
ffffffffc0201cec:	0bc000ef          	jal	ra,ffffffffc0201da8 <printfmt>
ffffffffc0201cf0:	bb41                	j	ffffffffc0201a80 <vprintfmt+0x3a>
ffffffffc0201cf2:	00001417          	auipc	s0,0x1
ffffffffc0201cf6:	11640413          	addi	s0,s0,278 # ffffffffc0202e08 <default_pmm_manager+0x198>
ffffffffc0201cfa:	85e2                	mv	a1,s8
ffffffffc0201cfc:	8522                	mv	a0,s0
ffffffffc0201cfe:	e43e                	sd	a5,8(sp)
ffffffffc0201d00:	200000ef          	jal	ra,ffffffffc0201f00 <strnlen>
ffffffffc0201d04:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d08:	01b05b63          	blez	s11,ffffffffc0201d1e <vprintfmt+0x2d8>
ffffffffc0201d0c:	67a2                	ld	a5,8(sp)
ffffffffc0201d0e:	00078a1b          	sext.w	s4,a5
ffffffffc0201d12:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d14:	85a6                	mv	a1,s1
ffffffffc0201d16:	8552                	mv	a0,s4
ffffffffc0201d18:	9902                	jalr	s2
ffffffffc0201d1a:	fe0d9ce3          	bnez	s11,ffffffffc0201d12 <vprintfmt+0x2cc>
ffffffffc0201d1e:	00044783          	lbu	a5,0(s0)
ffffffffc0201d22:	00140a13          	addi	s4,s0,1
ffffffffc0201d26:	0007851b          	sext.w	a0,a5
ffffffffc0201d2a:	d3a5                	beqz	a5,ffffffffc0201c8a <vprintfmt+0x244>
ffffffffc0201d2c:	05e00413          	li	s0,94
ffffffffc0201d30:	bf39                	j	ffffffffc0201c4e <vprintfmt+0x208>
ffffffffc0201d32:	000a2403          	lw	s0,0(s4)
ffffffffc0201d36:	b7ad                	j	ffffffffc0201ca0 <vprintfmt+0x25a>
ffffffffc0201d38:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d3c:	46a1                	li	a3,8
ffffffffc0201d3e:	8a2e                	mv	s4,a1
ffffffffc0201d40:	bdb1                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201d42:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d46:	46a9                	li	a3,10
ffffffffc0201d48:	8a2e                	mv	s4,a1
ffffffffc0201d4a:	bd89                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201d4c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d50:	46c1                	li	a3,16
ffffffffc0201d52:	8a2e                	mv	s4,a1
ffffffffc0201d54:	b5a1                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201d56:	9902                	jalr	s2
ffffffffc0201d58:	bf09                	j	ffffffffc0201c6a <vprintfmt+0x224>
ffffffffc0201d5a:	85a6                	mv	a1,s1
ffffffffc0201d5c:	02d00513          	li	a0,45
ffffffffc0201d60:	e03e                	sd	a5,0(sp)
ffffffffc0201d62:	9902                	jalr	s2
ffffffffc0201d64:	6782                	ld	a5,0(sp)
ffffffffc0201d66:	8a66                	mv	s4,s9
ffffffffc0201d68:	40800633          	neg	a2,s0
ffffffffc0201d6c:	46a9                	li	a3,10
ffffffffc0201d6e:	b53d                	j	ffffffffc0201b9c <vprintfmt+0x156>
ffffffffc0201d70:	03b05163          	blez	s11,ffffffffc0201d92 <vprintfmt+0x34c>
ffffffffc0201d74:	02d00693          	li	a3,45
ffffffffc0201d78:	f6d79de3          	bne	a5,a3,ffffffffc0201cf2 <vprintfmt+0x2ac>
ffffffffc0201d7c:	00001417          	auipc	s0,0x1
ffffffffc0201d80:	08c40413          	addi	s0,s0,140 # ffffffffc0202e08 <default_pmm_manager+0x198>
ffffffffc0201d84:	02800793          	li	a5,40
ffffffffc0201d88:	02800513          	li	a0,40
ffffffffc0201d8c:	00140a13          	addi	s4,s0,1
ffffffffc0201d90:	bd6d                	j	ffffffffc0201c4a <vprintfmt+0x204>
ffffffffc0201d92:	00001a17          	auipc	s4,0x1
ffffffffc0201d96:	077a0a13          	addi	s4,s4,119 # ffffffffc0202e09 <default_pmm_manager+0x199>
ffffffffc0201d9a:	02800513          	li	a0,40
ffffffffc0201d9e:	02800793          	li	a5,40
ffffffffc0201da2:	05e00413          	li	s0,94
ffffffffc0201da6:	b565                	j	ffffffffc0201c4e <vprintfmt+0x208>

ffffffffc0201da8 <printfmt>:
ffffffffc0201da8:	715d                	addi	sp,sp,-80
ffffffffc0201daa:	02810313          	addi	t1,sp,40
ffffffffc0201dae:	f436                	sd	a3,40(sp)
ffffffffc0201db0:	869a                	mv	a3,t1
ffffffffc0201db2:	ec06                	sd	ra,24(sp)
ffffffffc0201db4:	f83a                	sd	a4,48(sp)
ffffffffc0201db6:	fc3e                	sd	a5,56(sp)
ffffffffc0201db8:	e0c2                	sd	a6,64(sp)
ffffffffc0201dba:	e4c6                	sd	a7,72(sp)
ffffffffc0201dbc:	e41a                	sd	t1,8(sp)
ffffffffc0201dbe:	c89ff0ef          	jal	ra,ffffffffc0201a46 <vprintfmt>
ffffffffc0201dc2:	60e2                	ld	ra,24(sp)
ffffffffc0201dc4:	6161                	addi	sp,sp,80
ffffffffc0201dc6:	8082                	ret

ffffffffc0201dc8 <readline>:
ffffffffc0201dc8:	715d                	addi	sp,sp,-80
ffffffffc0201dca:	e486                	sd	ra,72(sp)
ffffffffc0201dcc:	e0a6                	sd	s1,64(sp)
ffffffffc0201dce:	fc4a                	sd	s2,56(sp)
ffffffffc0201dd0:	f84e                	sd	s3,48(sp)
ffffffffc0201dd2:	f452                	sd	s4,40(sp)
ffffffffc0201dd4:	f056                	sd	s5,32(sp)
ffffffffc0201dd6:	ec5a                	sd	s6,24(sp)
ffffffffc0201dd8:	e85e                	sd	s7,16(sp)
ffffffffc0201dda:	c901                	beqz	a0,ffffffffc0201dea <readline+0x22>
ffffffffc0201ddc:	85aa                	mv	a1,a0
ffffffffc0201dde:	00001517          	auipc	a0,0x1
ffffffffc0201de2:	04250513          	addi	a0,a0,66 # ffffffffc0202e20 <default_pmm_manager+0x1b0>
ffffffffc0201de6:	b02fe0ef          	jal	ra,ffffffffc02000e8 <cprintf>
ffffffffc0201dea:	4481                	li	s1,0
ffffffffc0201dec:	497d                	li	s2,31
ffffffffc0201dee:	49a1                	li	s3,8
ffffffffc0201df0:	4aa9                	li	s5,10
ffffffffc0201df2:	4b35                	li	s6,13
ffffffffc0201df4:	00005b97          	auipc	s7,0x5
ffffffffc0201df8:	24cb8b93          	addi	s7,s7,588 # ffffffffc0207040 <buf>
ffffffffc0201dfc:	3fe00a13          	li	s4,1022
ffffffffc0201e00:	b60fe0ef          	jal	ra,ffffffffc0200160 <getchar>
ffffffffc0201e04:	00054a63          	bltz	a0,ffffffffc0201e18 <readline+0x50>
ffffffffc0201e08:	00a95a63          	bge	s2,a0,ffffffffc0201e1c <readline+0x54>
ffffffffc0201e0c:	029a5263          	bge	s4,s1,ffffffffc0201e30 <readline+0x68>
ffffffffc0201e10:	b50fe0ef          	jal	ra,ffffffffc0200160 <getchar>
ffffffffc0201e14:	fe055ae3          	bgez	a0,ffffffffc0201e08 <readline+0x40>
ffffffffc0201e18:	4501                	li	a0,0
ffffffffc0201e1a:	a091                	j	ffffffffc0201e5e <readline+0x96>
ffffffffc0201e1c:	03351463          	bne	a0,s3,ffffffffc0201e44 <readline+0x7c>
ffffffffc0201e20:	e8a9                	bnez	s1,ffffffffc0201e72 <readline+0xaa>
ffffffffc0201e22:	b3efe0ef          	jal	ra,ffffffffc0200160 <getchar>
ffffffffc0201e26:	fe0549e3          	bltz	a0,ffffffffc0201e18 <readline+0x50>
ffffffffc0201e2a:	fea959e3          	bge	s2,a0,ffffffffc0201e1c <readline+0x54>
ffffffffc0201e2e:	4481                	li	s1,0
ffffffffc0201e30:	e42a                	sd	a0,8(sp)
ffffffffc0201e32:	aecfe0ef          	jal	ra,ffffffffc020011e <cputchar>
ffffffffc0201e36:	6522                	ld	a0,8(sp)
ffffffffc0201e38:	009b87b3          	add	a5,s7,s1
ffffffffc0201e3c:	2485                	addiw	s1,s1,1
ffffffffc0201e3e:	00a78023          	sb	a0,0(a5)
ffffffffc0201e42:	bf7d                	j	ffffffffc0201e00 <readline+0x38>
ffffffffc0201e44:	01550463          	beq	a0,s5,ffffffffc0201e4c <readline+0x84>
ffffffffc0201e48:	fb651ce3          	bne	a0,s6,ffffffffc0201e00 <readline+0x38>
ffffffffc0201e4c:	ad2fe0ef          	jal	ra,ffffffffc020011e <cputchar>
ffffffffc0201e50:	00005517          	auipc	a0,0x5
ffffffffc0201e54:	1f050513          	addi	a0,a0,496 # ffffffffc0207040 <buf>
ffffffffc0201e58:	94aa                	add	s1,s1,a0
ffffffffc0201e5a:	00048023          	sb	zero,0(s1)
ffffffffc0201e5e:	60a6                	ld	ra,72(sp)
ffffffffc0201e60:	6486                	ld	s1,64(sp)
ffffffffc0201e62:	7962                	ld	s2,56(sp)
ffffffffc0201e64:	79c2                	ld	s3,48(sp)
ffffffffc0201e66:	7a22                	ld	s4,40(sp)
ffffffffc0201e68:	7a82                	ld	s5,32(sp)
ffffffffc0201e6a:	6b62                	ld	s6,24(sp)
ffffffffc0201e6c:	6bc2                	ld	s7,16(sp)
ffffffffc0201e6e:	6161                	addi	sp,sp,80
ffffffffc0201e70:	8082                	ret
ffffffffc0201e72:	4521                	li	a0,8
ffffffffc0201e74:	aaafe0ef          	jal	ra,ffffffffc020011e <cputchar>
ffffffffc0201e78:	34fd                	addiw	s1,s1,-1
ffffffffc0201e7a:	b759                	j	ffffffffc0201e00 <readline+0x38>

ffffffffc0201e7c <sbi_console_putchar>:
ffffffffc0201e7c:	4781                	li	a5,0
ffffffffc0201e7e:	00005717          	auipc	a4,0x5
ffffffffc0201e82:	19a73703          	ld	a4,410(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e86:	88ba                	mv	a7,a4
ffffffffc0201e88:	852a                	mv	a0,a0
ffffffffc0201e8a:	85be                	mv	a1,a5
ffffffffc0201e8c:	863e                	mv	a2,a5
ffffffffc0201e8e:	00000073          	ecall
ffffffffc0201e92:	87aa                	mv	a5,a0
ffffffffc0201e94:	8082                	ret

ffffffffc0201e96 <sbi_set_timer>:
ffffffffc0201e96:	4781                	li	a5,0
ffffffffc0201e98:	00005717          	auipc	a4,0x5
ffffffffc0201e9c:	60073703          	ld	a4,1536(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201ea0:	88ba                	mv	a7,a4
ffffffffc0201ea2:	852a                	mv	a0,a0
ffffffffc0201ea4:	85be                	mv	a1,a5
ffffffffc0201ea6:	863e                	mv	a2,a5
ffffffffc0201ea8:	00000073          	ecall
ffffffffc0201eac:	87aa                	mv	a5,a0
ffffffffc0201eae:	8082                	ret

ffffffffc0201eb0 <sbi_console_getchar>:
ffffffffc0201eb0:	4501                	li	a0,0
ffffffffc0201eb2:	00005797          	auipc	a5,0x5
ffffffffc0201eb6:	15e7b783          	ld	a5,350(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201eba:	88be                	mv	a7,a5
ffffffffc0201ebc:	852a                	mv	a0,a0
ffffffffc0201ebe:	85aa                	mv	a1,a0
ffffffffc0201ec0:	862a                	mv	a2,a0
ffffffffc0201ec2:	00000073          	ecall
ffffffffc0201ec6:	852a                	mv	a0,a0
ffffffffc0201ec8:	2501                	sext.w	a0,a0
ffffffffc0201eca:	8082                	ret

ffffffffc0201ecc <sbi_shutdown>:
ffffffffc0201ecc:	4781                	li	a5,0
ffffffffc0201ece:	00005717          	auipc	a4,0x5
ffffffffc0201ed2:	15273703          	ld	a4,338(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201ed6:	88ba                	mv	a7,a4
ffffffffc0201ed8:	853e                	mv	a0,a5
ffffffffc0201eda:	85be                	mv	a1,a5
ffffffffc0201edc:	863e                	mv	a2,a5
ffffffffc0201ede:	00000073          	ecall
ffffffffc0201ee2:	87aa                	mv	a5,a0
ffffffffc0201ee4:	8082                	ret

ffffffffc0201ee6 <strlen>:
ffffffffc0201ee6:	00054783          	lbu	a5,0(a0)
ffffffffc0201eea:	872a                	mv	a4,a0
ffffffffc0201eec:	4501                	li	a0,0
ffffffffc0201eee:	cb81                	beqz	a5,ffffffffc0201efe <strlen+0x18>
ffffffffc0201ef0:	0505                	addi	a0,a0,1
ffffffffc0201ef2:	00a707b3          	add	a5,a4,a0
ffffffffc0201ef6:	0007c783          	lbu	a5,0(a5)
ffffffffc0201efa:	fbfd                	bnez	a5,ffffffffc0201ef0 <strlen+0xa>
ffffffffc0201efc:	8082                	ret
ffffffffc0201efe:	8082                	ret

ffffffffc0201f00 <strnlen>:
ffffffffc0201f00:	4781                	li	a5,0
ffffffffc0201f02:	e589                	bnez	a1,ffffffffc0201f0c <strnlen+0xc>
ffffffffc0201f04:	a811                	j	ffffffffc0201f18 <strnlen+0x18>
ffffffffc0201f06:	0785                	addi	a5,a5,1
ffffffffc0201f08:	00f58863          	beq	a1,a5,ffffffffc0201f18 <strnlen+0x18>
ffffffffc0201f0c:	00f50733          	add	a4,a0,a5
ffffffffc0201f10:	00074703          	lbu	a4,0(a4)
ffffffffc0201f14:	fb6d                	bnez	a4,ffffffffc0201f06 <strnlen+0x6>
ffffffffc0201f16:	85be                	mv	a1,a5
ffffffffc0201f18:	852e                	mv	a0,a1
ffffffffc0201f1a:	8082                	ret

ffffffffc0201f1c <strcmp>:
ffffffffc0201f1c:	00054783          	lbu	a5,0(a0)
ffffffffc0201f20:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f24:	cb89                	beqz	a5,ffffffffc0201f36 <strcmp+0x1a>
ffffffffc0201f26:	0505                	addi	a0,a0,1
ffffffffc0201f28:	0585                	addi	a1,a1,1
ffffffffc0201f2a:	fee789e3          	beq	a5,a4,ffffffffc0201f1c <strcmp>
ffffffffc0201f2e:	0007851b          	sext.w	a0,a5
ffffffffc0201f32:	9d19                	subw	a0,a0,a4
ffffffffc0201f34:	8082                	ret
ffffffffc0201f36:	4501                	li	a0,0
ffffffffc0201f38:	bfed                	j	ffffffffc0201f32 <strcmp+0x16>

ffffffffc0201f3a <strncmp>:
ffffffffc0201f3a:	c20d                	beqz	a2,ffffffffc0201f5c <strncmp+0x22>
ffffffffc0201f3c:	962e                	add	a2,a2,a1
ffffffffc0201f3e:	a031                	j	ffffffffc0201f4a <strncmp+0x10>
ffffffffc0201f40:	0505                	addi	a0,a0,1
ffffffffc0201f42:	00e79a63          	bne	a5,a4,ffffffffc0201f56 <strncmp+0x1c>
ffffffffc0201f46:	00b60b63          	beq	a2,a1,ffffffffc0201f5c <strncmp+0x22>
ffffffffc0201f4a:	00054783          	lbu	a5,0(a0)
ffffffffc0201f4e:	0585                	addi	a1,a1,1
ffffffffc0201f50:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201f54:	f7f5                	bnez	a5,ffffffffc0201f40 <strncmp+0x6>
ffffffffc0201f56:	40e7853b          	subw	a0,a5,a4
ffffffffc0201f5a:	8082                	ret
ffffffffc0201f5c:	4501                	li	a0,0
ffffffffc0201f5e:	8082                	ret

ffffffffc0201f60 <strchr>:
ffffffffc0201f60:	00054783          	lbu	a5,0(a0)
ffffffffc0201f64:	c799                	beqz	a5,ffffffffc0201f72 <strchr+0x12>
ffffffffc0201f66:	00f58763          	beq	a1,a5,ffffffffc0201f74 <strchr+0x14>
ffffffffc0201f6a:	00154783          	lbu	a5,1(a0)
ffffffffc0201f6e:	0505                	addi	a0,a0,1
ffffffffc0201f70:	fbfd                	bnez	a5,ffffffffc0201f66 <strchr+0x6>
ffffffffc0201f72:	4501                	li	a0,0
ffffffffc0201f74:	8082                	ret

ffffffffc0201f76 <memset>:
ffffffffc0201f76:	ca01                	beqz	a2,ffffffffc0201f86 <memset+0x10>
ffffffffc0201f78:	962a                	add	a2,a2,a0
ffffffffc0201f7a:	87aa                	mv	a5,a0
ffffffffc0201f7c:	0785                	addi	a5,a5,1
ffffffffc0201f7e:	feb78fa3          	sb	a1,-1(a5)
ffffffffc0201f82:	fec79de3          	bne	a5,a2,ffffffffc0201f7c <memset+0x6>
ffffffffc0201f86:	8082                	ret
