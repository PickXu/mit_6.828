
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 12 00       	mov    $0x120000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 12 f0       	mov    $0xf0120000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 6a 00 00 00       	call   f01000a8 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 3e 23 f0 00 	cmpl   $0x0,0xf0233e80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 3e 23 f0    	mov    %esi,0xf0233e80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 75 68 00 00       	call   f01068d9 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 c0 6f 10 f0 	movl   $0xf0106fc0,(%esp)
f010007d:	e8 88 42 00 00       	call   f010430a <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 49 42 00 00       	call   f01042d7 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 a2 85 10 f0 	movl   $0xf01085a2,(%esp)
f0100095:	e8 70 42 00 00       	call   f010430a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 74 09 00 00       	call   f0100a1a <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	53                   	push   %ebx
f01000ac:	83 ec 14             	sub    $0x14,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000af:	b8 08 50 27 f0       	mov    $0xf0275008,%eax
f01000b4:	2d 50 22 23 f0       	sub    $0xf0232250,%eax
f01000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c4:	00 
f01000c5:	c7 04 24 50 22 23 f0 	movl   $0xf0232250,(%esp)
f01000cc:	e8 b6 61 00 00       	call   f0106287 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000d1:	e8 b4 05 00 00       	call   f010068a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 2c 70 10 f0 	movl   $0xf010702c,(%esp)
f01000e5:	e8 20 42 00 00       	call   f010430a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000ea:	e8 39 17 00 00       	call   f0101828 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000ef:	e8 d8 39 00 00       	call   f0103acc <env_init>
	trap_init();
f01000f4:	e8 07 43 00 00       	call   f0104400 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000f9:	e8 cc 64 00 00       	call   f01065ca <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 ef 67 00 00       	call   f01068f4 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100105:	e8 30 41 00 00       	call   f010423a <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010010a:	c7 04 24 80 24 12 f0 	movl   $0xf0122480,(%esp)
f0100111:	e8 41 6a 00 00       	call   f0106b57 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100116:	83 3d 88 3e 23 f0 07 	cmpl   $0x7,0xf0233e88
f010011d:	77 24                	ja     f0100143 <i386_init+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100126:	00 
f0100127:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f010012e:	f0 
f010012f:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100136:	00 
f0100137:	c7 04 24 47 70 10 f0 	movl   $0xf0107047,(%esp)
f010013e:	e8 fd fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100143:	b8 02 65 10 f0       	mov    $0xf0106502,%eax
f0100148:	2d 88 64 10 f0       	sub    $0xf0106488,%eax
f010014d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100151:	c7 44 24 04 88 64 10 	movl   $0xf0106488,0x4(%esp)
f0100158:	f0 
f0100159:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100160:	e8 6f 61 00 00       	call   f01062d4 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100165:	bb 20 40 23 f0       	mov    $0xf0234020,%ebx
f010016a:	eb 4d                	jmp    f01001b9 <i386_init+0x111>
		if (c == cpus + cpunum())  // We've started already.
f010016c:	e8 68 67 00 00       	call   f01068d9 <cpunum>
f0100171:	6b c0 74             	imul   $0x74,%eax,%eax
f0100174:	05 20 40 23 f0       	add    $0xf0234020,%eax
f0100179:	39 c3                	cmp    %eax,%ebx
f010017b:	74 39                	je     f01001b6 <i386_init+0x10e>
f010017d:	89 d8                	mov    %ebx,%eax
f010017f:	2d 20 40 23 f0       	sub    $0xf0234020,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100184:	c1 f8 02             	sar    $0x2,%eax
f0100187:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010018d:	c1 e0 0f             	shl    $0xf,%eax
f0100190:	8d 80 00 d0 23 f0    	lea    -0xfdc3000(%eax),%eax
f0100196:	a3 84 3e 23 f0       	mov    %eax,0xf0233e84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010019b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f01001a2:	00 
f01001a3:	0f b6 03             	movzbl (%ebx),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 96 68 00 00       	call   f0106a44 <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f01001ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01001b1:	83 f8 01             	cmp    $0x1,%eax
f01001b4:	75 f8                	jne    f01001ae <i386_init+0x106>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001b6:	83 c3 74             	add    $0x74,%ebx
f01001b9:	6b 05 c4 43 23 f0 74 	imul   $0x74,0xf02343c4,%eax
f01001c0:	05 20 40 23 f0       	add    $0xf0234020,%eax
f01001c5:	39 c3                	cmp    %eax,%ebx
f01001c7:	72 a3                	jb     f010016c <i386_init+0xc4>
	// Starting non-boot CPUs
	boot_aps();
	
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001d0:	00 
f01001d1:	c7 04 24 94 87 22 f0 	movl   $0xf0228794,(%esp)
f01001d8:	e8 ee 3a 00 00       	call   f0103ccb <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001dd:	e8 0e 4d 00 00       	call   f0104ef0 <sched_yield>

f01001e2 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001e2:	55                   	push   %ebp
f01001e3:	89 e5                	mov    %esp,%ebp
f01001e5:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001e8:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f2:	77 20                	ja     f0100214 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001f8:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f01001ff:	f0 
f0100200:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f0100207:	00 
f0100208:	c7 04 24 47 70 10 f0 	movl   $0xf0107047,(%esp)
f010020f:	e8 2c fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100214:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0100219:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f010021c:	e8 b8 66 00 00       	call   f01068d9 <cpunum>
f0100221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100225:	c7 04 24 53 70 10 f0 	movl   $0xf0107053,(%esp)
f010022c:	e8 d9 40 00 00       	call   f010430a <cprintf>

	lapic_init();
f0100231:	e8 be 66 00 00       	call   f01068f4 <lapic_init>
	env_init_percpu();
f0100236:	e8 67 38 00 00       	call   f0103aa2 <env_init_percpu>
	trap_init_percpu();
f010023b:	90                   	nop
f010023c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100240:	e8 eb 40 00 00       	call   f0104330 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100245:	e8 8f 66 00 00       	call   f01068d9 <cpunum>
f010024a:	6b d0 74             	imul   $0x74,%eax,%edx
f010024d:	81 c2 20 40 23 f0    	add    $0xf0234020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100253:	b8 01 00 00 00       	mov    $0x1,%eax
f0100258:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010025c:	c7 04 24 80 24 12 f0 	movl   $0xf0122480,(%esp)
f0100263:	e8 ef 68 00 00       	call   f0106b57 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100268:	e8 83 4c 00 00       	call   f0104ef0 <sched_yield>

f010026d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010026d:	55                   	push   %ebp
f010026e:	89 e5                	mov    %esp,%ebp
f0100270:	53                   	push   %ebx
f0100271:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100274:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100277:	8b 45 0c             	mov    0xc(%ebp),%eax
f010027a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010027e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100281:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100285:	c7 04 24 69 70 10 f0 	movl   $0xf0107069,(%esp)
f010028c:	e8 79 40 00 00       	call   f010430a <cprintf>
	vcprintf(fmt, ap);
f0100291:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100295:	8b 45 10             	mov    0x10(%ebp),%eax
f0100298:	89 04 24             	mov    %eax,(%esp)
f010029b:	e8 37 40 00 00       	call   f01042d7 <vcprintf>
	cprintf("\n");
f01002a0:	c7 04 24 a2 85 10 f0 	movl   $0xf01085a2,(%esp)
f01002a7:	e8 5e 40 00 00       	call   f010430a <cprintf>
	va_end(ap);
}
f01002ac:	83 c4 14             	add    $0x14,%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5d                   	pop    %ebp
f01002b1:	c3                   	ret    
f01002b2:	66 90                	xchg   %ax,%ax
f01002b4:	66 90                	xchg   %ax,%ax
f01002b6:	66 90                	xchg   %ax,%ax
f01002b8:	66 90                	xchg   %ax,%ax
f01002ba:	66 90                	xchg   %ax,%ax
f01002bc:	66 90                	xchg   %ax,%ax
f01002be:	66 90                	xchg   %ax,%ax

f01002c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002c0:	55                   	push   %ebp
f01002c1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002c9:	a8 01                	test   $0x1,%al
f01002cb:	74 08                	je     f01002d5 <serial_proc_data+0x15>
f01002cd:	b2 f8                	mov    $0xf8,%dl
f01002cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002d0:	0f b6 c0             	movzbl %al,%eax
f01002d3:	eb 05                	jmp    f01002da <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002da:	5d                   	pop    %ebp
f01002db:	c3                   	ret    

f01002dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002dc:	55                   	push   %ebp
f01002dd:	89 e5                	mov    %esp,%ebp
f01002df:	53                   	push   %ebx
f01002e0:	83 ec 04             	sub    $0x4,%esp
f01002e3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002e5:	eb 2a                	jmp    f0100311 <cons_intr+0x35>
		if (c == 0)
f01002e7:	85 d2                	test   %edx,%edx
f01002e9:	74 26                	je     f0100311 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002eb:	a1 24 32 23 f0       	mov    0xf0233224,%eax
f01002f0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002f3:	89 0d 24 32 23 f0    	mov    %ecx,0xf0233224
f01002f9:	88 90 20 30 23 f0    	mov    %dl,-0xfdccfe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002ff:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100305:	75 0a                	jne    f0100311 <cons_intr+0x35>
			cons.wpos = 0;
f0100307:	c7 05 24 32 23 f0 00 	movl   $0x0,0xf0233224
f010030e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100311:	ff d3                	call   *%ebx
f0100313:	89 c2                	mov    %eax,%edx
f0100315:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100318:	75 cd                	jne    f01002e7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010031a:	83 c4 04             	add    $0x4,%esp
f010031d:	5b                   	pop    %ebx
f010031e:	5d                   	pop    %ebp
f010031f:	c3                   	ret    

f0100320 <kbd_proc_data>:
f0100320:	ba 64 00 00 00       	mov    $0x64,%edx
f0100325:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100326:	a8 01                	test   $0x1,%al
f0100328:	0f 84 ef 00 00 00    	je     f010041d <kbd_proc_data+0xfd>
f010032e:	b2 60                	mov    $0x60,%dl
f0100330:	ec                   	in     (%dx),%al
f0100331:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100333:	3c e0                	cmp    $0xe0,%al
f0100335:	75 0d                	jne    f0100344 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100337:	83 0d 00 30 23 f0 40 	orl    $0x40,0xf0233000
		return 0;
f010033e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100343:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100344:	55                   	push   %ebp
f0100345:	89 e5                	mov    %esp,%ebp
f0100347:	53                   	push   %ebx
f0100348:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010034b:	84 c0                	test   %al,%al
f010034d:	79 37                	jns    f0100386 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010034f:	8b 0d 00 30 23 f0    	mov    0xf0233000,%ecx
f0100355:	89 cb                	mov    %ecx,%ebx
f0100357:	83 e3 40             	and    $0x40,%ebx
f010035a:	83 e0 7f             	and    $0x7f,%eax
f010035d:	85 db                	test   %ebx,%ebx
f010035f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100362:	0f b6 d2             	movzbl %dl,%edx
f0100365:	0f b6 82 e0 71 10 f0 	movzbl -0xfef8e20(%edx),%eax
f010036c:	83 c8 40             	or     $0x40,%eax
f010036f:	0f b6 c0             	movzbl %al,%eax
f0100372:	f7 d0                	not    %eax
f0100374:	21 c1                	and    %eax,%ecx
f0100376:	89 0d 00 30 23 f0    	mov    %ecx,0xf0233000
		return 0;
f010037c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100381:	e9 9d 00 00 00       	jmp    f0100423 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100386:	8b 0d 00 30 23 f0    	mov    0xf0233000,%ecx
f010038c:	f6 c1 40             	test   $0x40,%cl
f010038f:	74 0e                	je     f010039f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100391:	83 c8 80             	or     $0xffffff80,%eax
f0100394:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100396:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100399:	89 0d 00 30 23 f0    	mov    %ecx,0xf0233000
	}

	shift |= shiftcode[data];
f010039f:	0f b6 d2             	movzbl %dl,%edx
f01003a2:	0f b6 82 e0 71 10 f0 	movzbl -0xfef8e20(%edx),%eax
f01003a9:	0b 05 00 30 23 f0    	or     0xf0233000,%eax
	shift ^= togglecode[data];
f01003af:	0f b6 8a e0 70 10 f0 	movzbl -0xfef8f20(%edx),%ecx
f01003b6:	31 c8                	xor    %ecx,%eax
f01003b8:	a3 00 30 23 f0       	mov    %eax,0xf0233000

	c = charcode[shift & (CTL | SHIFT)][data];
f01003bd:	89 c1                	mov    %eax,%ecx
f01003bf:	83 e1 03             	and    $0x3,%ecx
f01003c2:	8b 0c 8d c0 70 10 f0 	mov    -0xfef8f40(,%ecx,4),%ecx
f01003c9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003cd:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003d0:	a8 08                	test   $0x8,%al
f01003d2:	74 1b                	je     f01003ef <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003d9:	83 f9 19             	cmp    $0x19,%ecx
f01003dc:	77 05                	ja     f01003e3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01003de:	83 eb 20             	sub    $0x20,%ebx
f01003e1:	eb 0c                	jmp    f01003ef <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01003e3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003e6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003e9:	83 fa 19             	cmp    $0x19,%edx
f01003ec:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003ef:	f7 d0                	not    %eax
f01003f1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003f5:	f6 c2 06             	test   $0x6,%dl
f01003f8:	75 29                	jne    f0100423 <kbd_proc_data+0x103>
f01003fa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100400:	75 21                	jne    f0100423 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100402:	c7 04 24 83 70 10 f0 	movl   $0xf0107083,(%esp)
f0100409:	e8 fc 3e 00 00       	call   f010430a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100413:	b8 03 00 00 00       	mov    $0x3,%eax
f0100418:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100419:	89 d8                	mov    %ebx,%eax
f010041b:	eb 06                	jmp    f0100423 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010041d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100422:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100423:	83 c4 14             	add    $0x14,%esp
f0100426:	5b                   	pop    %ebx
f0100427:	5d                   	pop    %ebp
f0100428:	c3                   	ret    

f0100429 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100429:	55                   	push   %ebp
f010042a:	89 e5                	mov    %esp,%ebp
f010042c:	57                   	push   %edi
f010042d:	56                   	push   %esi
f010042e:	53                   	push   %ebx
f010042f:	83 ec 1c             	sub    $0x1c,%esp
f0100432:	89 c7                	mov    %eax,%edi
f0100434:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100439:	be fd 03 00 00       	mov    $0x3fd,%esi
f010043e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100443:	eb 0c                	jmp    f0100451 <cons_putc+0x28>
f0100445:	89 ca                	mov    %ecx,%edx
f0100447:	ec                   	in     (%dx),%al
f0100448:	89 ca                	mov    %ecx,%edx
f010044a:	ec                   	in     (%dx),%al
f010044b:	89 ca                	mov    %ecx,%edx
f010044d:	ec                   	in     (%dx),%al
f010044e:	89 ca                	mov    %ecx,%edx
f0100450:	ec                   	in     (%dx),%al
f0100451:	89 f2                	mov    %esi,%edx
f0100453:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100454:	a8 20                	test   $0x20,%al
f0100456:	75 05                	jne    f010045d <cons_putc+0x34>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100458:	83 eb 01             	sub    $0x1,%ebx
f010045b:	75 e8                	jne    f0100445 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010045d:	89 f8                	mov    %edi,%eax
f010045f:	0f b6 c0             	movzbl %al,%eax
f0100462:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100465:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100470:	be 79 03 00 00       	mov    $0x379,%esi
f0100475:	b9 84 00 00 00       	mov    $0x84,%ecx
f010047a:	eb 0c                	jmp    f0100488 <cons_putc+0x5f>
f010047c:	89 ca                	mov    %ecx,%edx
f010047e:	ec                   	in     (%dx),%al
f010047f:	89 ca                	mov    %ecx,%edx
f0100481:	ec                   	in     (%dx),%al
f0100482:	89 ca                	mov    %ecx,%edx
f0100484:	ec                   	in     (%dx),%al
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ec                   	in     (%dx),%al
f0100488:	89 f2                	mov    %esi,%edx
f010048a:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010048b:	84 c0                	test   %al,%al
f010048d:	78 05                	js     f0100494 <cons_putc+0x6b>
f010048f:	83 eb 01             	sub    $0x1,%ebx
f0100492:	75 e8                	jne    f010047c <cons_putc+0x53>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100494:	ba 78 03 00 00       	mov    $0x378,%edx
f0100499:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010049d:	ee                   	out    %al,(%dx)
f010049e:	b2 7a                	mov    $0x7a,%dl
f01004a0:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004a5:	ee                   	out    %al,(%dx)
f01004a6:	b8 08 00 00 00       	mov    $0x8,%eax
f01004ab:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004ac:	89 fa                	mov    %edi,%edx
f01004ae:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004b4:	89 f8                	mov    %edi,%eax
f01004b6:	80 cc 07             	or     $0x7,%ah
f01004b9:	85 d2                	test   %edx,%edx
f01004bb:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004be:	89 f8                	mov    %edi,%eax
f01004c0:	0f b6 c0             	movzbl %al,%eax
f01004c3:	83 f8 09             	cmp    $0x9,%eax
f01004c6:	74 75                	je     f010053d <cons_putc+0x114>
f01004c8:	83 f8 09             	cmp    $0x9,%eax
f01004cb:	7f 0a                	jg     f01004d7 <cons_putc+0xae>
f01004cd:	83 f8 08             	cmp    $0x8,%eax
f01004d0:	74 15                	je     f01004e7 <cons_putc+0xbe>
f01004d2:	e9 9a 00 00 00       	jmp    f0100571 <cons_putc+0x148>
f01004d7:	83 f8 0a             	cmp    $0xa,%eax
f01004da:	74 3b                	je     f0100517 <cons_putc+0xee>
f01004dc:	83 f8 0d             	cmp    $0xd,%eax
f01004df:	90                   	nop
f01004e0:	74 3d                	je     f010051f <cons_putc+0xf6>
f01004e2:	e9 8a 00 00 00       	jmp    f0100571 <cons_putc+0x148>
	case '\b':
		if (crt_pos > 0) {
f01004e7:	0f b7 05 28 32 23 f0 	movzwl 0xf0233228,%eax
f01004ee:	66 85 c0             	test   %ax,%ax
f01004f1:	0f 84 e5 00 00 00    	je     f01005dc <cons_putc+0x1b3>
			crt_pos--;
f01004f7:	83 e8 01             	sub    $0x1,%eax
f01004fa:	66 a3 28 32 23 f0    	mov    %ax,0xf0233228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100500:	0f b7 c0             	movzwl %ax,%eax
f0100503:	66 81 e7 00 ff       	and    $0xff00,%di
f0100508:	83 cf 20             	or     $0x20,%edi
f010050b:	8b 15 2c 32 23 f0    	mov    0xf023322c,%edx
f0100511:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100515:	eb 78                	jmp    f010058f <cons_putc+0x166>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100517:	66 83 05 28 32 23 f0 	addw   $0x50,0xf0233228
f010051e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010051f:	0f b7 05 28 32 23 f0 	movzwl 0xf0233228,%eax
f0100526:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010052c:	c1 e8 16             	shr    $0x16,%eax
f010052f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100532:	c1 e0 04             	shl    $0x4,%eax
f0100535:	66 a3 28 32 23 f0    	mov    %ax,0xf0233228
f010053b:	eb 52                	jmp    f010058f <cons_putc+0x166>
		break;
	case '\t':
		cons_putc(' ');
f010053d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100542:	e8 e2 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100547:	b8 20 00 00 00       	mov    $0x20,%eax
f010054c:	e8 d8 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100551:	b8 20 00 00 00       	mov    $0x20,%eax
f0100556:	e8 ce fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f010055b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100560:	e8 c4 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100565:	b8 20 00 00 00       	mov    $0x20,%eax
f010056a:	e8 ba fe ff ff       	call   f0100429 <cons_putc>
f010056f:	eb 1e                	jmp    f010058f <cons_putc+0x166>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100571:	0f b7 05 28 32 23 f0 	movzwl 0xf0233228,%eax
f0100578:	8d 50 01             	lea    0x1(%eax),%edx
f010057b:	66 89 15 28 32 23 f0 	mov    %dx,0xf0233228
f0100582:	0f b7 c0             	movzwl %ax,%eax
f0100585:	8b 15 2c 32 23 f0    	mov    0xf023322c,%edx
f010058b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	}

	// What is the purpose of this?
	// shift the tail from the CRT_COLS-th word
	// forward, to the start of the buffer 
	if (crt_pos >= CRT_SIZE) {
f010058f:	66 81 3d 28 32 23 f0 	cmpw   $0x7cf,0xf0233228
f0100596:	cf 07 
f0100598:	76 42                	jbe    f01005dc <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010059a:	a1 2c 32 23 f0       	mov    0xf023322c,%eax
f010059f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005a6:	00 
f01005a7:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005ad:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005b1:	89 04 24             	mov    %eax,(%esp)
f01005b4:	e8 1b 5d 00 00       	call   f01062d4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005b9:	8b 15 2c 32 23 f0    	mov    0xf023322c,%edx
	// forward, to the start of the buffer 
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005bf:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005c4:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// forward, to the start of the buffer 
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005ca:	83 c0 01             	add    $0x1,%eax
f01005cd:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005d2:	75 f0                	jne    f01005c4 <cons_putc+0x19b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005d4:	66 83 2d 28 32 23 f0 	subw   $0x50,0xf0233228
f01005db:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005dc:	8b 0d 30 32 23 f0    	mov    0xf0233230,%ecx
f01005e2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005e7:	89 ca                	mov    %ecx,%edx
f01005e9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005ea:	0f b7 1d 28 32 23 f0 	movzwl 0xf0233228,%ebx
f01005f1:	8d 71 01             	lea    0x1(%ecx),%esi
f01005f4:	89 d8                	mov    %ebx,%eax
f01005f6:	66 c1 e8 08          	shr    $0x8,%ax
f01005fa:	89 f2                	mov    %esi,%edx
f01005fc:	ee                   	out    %al,(%dx)
f01005fd:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100602:	89 ca                	mov    %ecx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	89 d8                	mov    %ebx,%eax
f0100607:	89 f2                	mov    %esi,%edx
f0100609:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010060a:	83 c4 1c             	add    $0x1c,%esp
f010060d:	5b                   	pop    %ebx
f010060e:	5e                   	pop    %esi
f010060f:	5f                   	pop    %edi
f0100610:	5d                   	pop    %ebp
f0100611:	c3                   	ret    

f0100612 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100612:	80 3d 34 32 23 f0 00 	cmpb   $0x0,0xf0233234
f0100619:	74 11                	je     f010062c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010061b:	55                   	push   %ebp
f010061c:	89 e5                	mov    %esp,%ebp
f010061e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100621:	b8 c0 02 10 f0       	mov    $0xf01002c0,%eax
f0100626:	e8 b1 fc ff ff       	call   f01002dc <cons_intr>
}
f010062b:	c9                   	leave  
f010062c:	f3 c3                	repz ret 

f010062e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010062e:	55                   	push   %ebp
f010062f:	89 e5                	mov    %esp,%ebp
f0100631:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100634:	b8 20 03 10 f0       	mov    $0xf0100320,%eax
f0100639:	e8 9e fc ff ff       	call   f01002dc <cons_intr>
}
f010063e:	c9                   	leave  
f010063f:	c3                   	ret    

f0100640 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100646:	e8 c7 ff ff ff       	call   f0100612 <serial_intr>
	kbd_intr();
f010064b:	e8 de ff ff ff       	call   f010062e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100650:	a1 20 32 23 f0       	mov    0xf0233220,%eax
f0100655:	3b 05 24 32 23 f0    	cmp    0xf0233224,%eax
f010065b:	74 26                	je     f0100683 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010065d:	8d 50 01             	lea    0x1(%eax),%edx
f0100660:	89 15 20 32 23 f0    	mov    %edx,0xf0233220
f0100666:	0f b6 88 20 30 23 f0 	movzbl -0xfdccfe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010066d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010066f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100675:	75 11                	jne    f0100688 <cons_getc+0x48>
			cons.rpos = 0;
f0100677:	c7 05 20 32 23 f0 00 	movl   $0x0,0xf0233220
f010067e:	00 00 00 
f0100681:	eb 05                	jmp    f0100688 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100683:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100688:	c9                   	leave  
f0100689:	c3                   	ret    

f010068a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010068a:	55                   	push   %ebp
f010068b:	89 e5                	mov    %esp,%ebp
f010068d:	57                   	push   %edi
f010068e:	56                   	push   %esi
f010068f:	53                   	push   %ebx
f0100690:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100693:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010069a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01006a1:	5a a5 
	if (*cp != 0xA55A) {
f01006a3:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01006aa:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006ae:	74 11                	je     f01006c1 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01006b0:	c7 05 30 32 23 f0 b4 	movl   $0x3b4,0xf0233230
f01006b7:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006ba:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006bf:	eb 16                	jmp    f01006d7 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006c1:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006c8:	c7 05 30 32 23 f0 d4 	movl   $0x3d4,0xf0233230
f01006cf:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006d2:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006d7:	8b 0d 30 32 23 f0    	mov    0xf0233230,%ecx
f01006dd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006e2:	89 ca                	mov    %ecx,%edx
f01006e4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006e5:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006e8:	89 da                	mov    %ebx,%edx
f01006ea:	ec                   	in     (%dx),%al
f01006eb:	0f b6 f0             	movzbl %al,%esi
f01006ee:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006f1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006f6:	89 ca                	mov    %ecx,%edx
f01006f8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006f9:	89 da                	mov    %ebx,%edx
f01006fb:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006fc:	89 3d 2c 32 23 f0    	mov    %edi,0xf023322c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100702:	0f b6 d8             	movzbl %al,%ebx
f0100705:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100707:	66 89 35 28 32 23 f0 	mov    %si,0xf0233228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f010070e:	e8 1b ff ff ff       	call   f010062e <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f0100713:	0f b7 05 a8 23 12 f0 	movzwl 0xf01223a8,%eax
f010071a:	25 fd ff 00 00       	and    $0xfffd,%eax
f010071f:	89 04 24             	mov    %eax,(%esp)
f0100722:	e8 a4 3a 00 00       	call   f01041cb <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100727:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010072c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100731:	ee                   	out    %al,(%dx)
f0100732:	b2 fb                	mov    $0xfb,%dl
f0100734:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100739:	ee                   	out    %al,(%dx)
f010073a:	b2 f8                	mov    $0xf8,%dl
f010073c:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100741:	ee                   	out    %al,(%dx)
f0100742:	b2 f9                	mov    $0xf9,%dl
f0100744:	b8 00 00 00 00       	mov    $0x0,%eax
f0100749:	ee                   	out    %al,(%dx)
f010074a:	b2 fb                	mov    $0xfb,%dl
f010074c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100751:	ee                   	out    %al,(%dx)
f0100752:	b2 fc                	mov    $0xfc,%dl
f0100754:	b8 00 00 00 00       	mov    $0x0,%eax
f0100759:	ee                   	out    %al,(%dx)
f010075a:	b2 f9                	mov    $0xf9,%dl
f010075c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100761:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100762:	b2 fd                	mov    $0xfd,%dl
f0100764:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100765:	3c ff                	cmp    $0xff,%al
f0100767:	0f 95 c1             	setne  %cl
f010076a:	88 0d 34 32 23 f0    	mov    %cl,0xf0233234
f0100770:	b2 fa                	mov    $0xfa,%dl
f0100772:	ec                   	in     (%dx),%al
f0100773:	b2 f8                	mov    $0xf8,%dl
f0100775:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100776:	84 c9                	test   %cl,%cl
f0100778:	75 0c                	jne    f0100786 <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
f010077a:	c7 04 24 8f 70 10 f0 	movl   $0xf010708f,(%esp)
f0100781:	e8 84 3b 00 00       	call   f010430a <cprintf>
}
f0100786:	83 c4 1c             	add    $0x1c,%esp
f0100789:	5b                   	pop    %ebx
f010078a:	5e                   	pop    %esi
f010078b:	5f                   	pop    %edi
f010078c:	5d                   	pop    %ebp
f010078d:	c3                   	ret    

f010078e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010078e:	55                   	push   %ebp
f010078f:	89 e5                	mov    %esp,%ebp
f0100791:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100794:	8b 45 08             	mov    0x8(%ebp),%eax
f0100797:	e8 8d fc ff ff       	call   f0100429 <cons_putc>
}
f010079c:	c9                   	leave  
f010079d:	c3                   	ret    

f010079e <getchar>:

int
getchar(void)
{
f010079e:	55                   	push   %ebp
f010079f:	89 e5                	mov    %esp,%ebp
f01007a1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007a4:	e8 97 fe ff ff       	call   f0100640 <cons_getc>
f01007a9:	85 c0                	test   %eax,%eax
f01007ab:	74 f7                	je     f01007a4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007ad:	c9                   	leave  
f01007ae:	c3                   	ret    

f01007af <iscons>:

int
iscons(int fdnum)
{
f01007af:	55                   	push   %ebp
f01007b0:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01007b7:	5d                   	pop    %ebp
f01007b8:	c3                   	ret    
f01007b9:	66 90                	xchg   %ax,%ax
f01007bb:	66 90                	xchg   %ax,%ax
f01007bd:	66 90                	xchg   %ax,%ax
f01007bf:	90                   	nop

f01007c0 <mon_setmp>:
	return 0;
}

int
mon_setmp(int argc, char **argv, struct Trapframe *tf) 
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
	return 0;
}
f01007c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c8:	5d                   	pop    %ebp
f01007c9:	c3                   	ret    

f01007ca <mon_clrmp>:

int 
mon_clrmp(int argc, char **argv, struct Trapframe *tf) 
{
f01007ca:	55                   	push   %ebp
f01007cb:	89 e5                	mov    %esp,%ebp
	return 0;
}
f01007cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d2:	5d                   	pop    %ebp
f01007d3:	c3                   	ret    

f01007d4 <mon_chgmp>:

int
mon_chgmp(int argc, char **argv, struct Trapframe *tf)
{
f01007d4:	55                   	push   %ebp
f01007d5:	89 e5                	mov    %esp,%ebp
	return 0;
}
f01007d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dc:	5d                   	pop    %ebp
f01007dd:	c3                   	ret    

f01007de <mon_dumpregion>:

int
mon_dumpregion(int argc, char **argv, struct Trapframe *tf) 
{
f01007de:	55                   	push   %ebp
f01007df:	89 e5                	mov    %esp,%ebp
	return 0;
}
f01007e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e6:	5d                   	pop    %ebp
f01007e7:	c3                   	ret    

f01007e8 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007e8:	55                   	push   %ebp
f01007e9:	89 e5                	mov    %esp,%ebp
f01007eb:	56                   	push   %esi
f01007ec:	53                   	push   %ebx
f01007ed:	83 ec 10             	sub    $0x10,%esp
f01007f0:	bb 44 76 10 f0       	mov    $0xf0107644,%ebx
f01007f5:	be a4 76 10 f0       	mov    $0xf01076a4,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007fa:	8b 03                	mov    (%ebx),%eax
f01007fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100800:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100803:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100807:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f010080e:	e8 f7 3a 00 00       	call   f010430a <cprintf>
f0100813:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100816:	39 f3                	cmp    %esi,%ebx
f0100818:	75 e0                	jne    f01007fa <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010081a:	b8 00 00 00 00       	mov    $0x0,%eax
f010081f:	83 c4 10             	add    $0x10,%esp
f0100822:	5b                   	pop    %ebx
f0100823:	5e                   	pop    %esi
f0100824:	5d                   	pop    %ebp
f0100825:	c3                   	ret    

f0100826 <mon_kerninfo>:

	int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100826:	55                   	push   %ebp
f0100827:	89 e5                	mov    %esp,%ebp
f0100829:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010082c:	c7 04 24 e9 72 10 f0 	movl   $0xf01072e9,(%esp)
f0100833:	e8 d2 3a 00 00       	call   f010430a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100838:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010083f:	00 
f0100840:	c7 04 24 4c 74 10 f0 	movl   $0xf010744c,(%esp)
f0100847:	e8 be 3a 00 00       	call   f010430a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010084c:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100853:	00 
f0100854:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010085b:	f0 
f010085c:	c7 04 24 74 74 10 f0 	movl   $0xf0107474,(%esp)
f0100863:	e8 a2 3a 00 00       	call   f010430a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100868:	c7 44 24 08 a7 6f 10 	movl   $0x106fa7,0x8(%esp)
f010086f:	00 
f0100870:	c7 44 24 04 a7 6f 10 	movl   $0xf0106fa7,0x4(%esp)
f0100877:	f0 
f0100878:	c7 04 24 98 74 10 f0 	movl   $0xf0107498,(%esp)
f010087f:	e8 86 3a 00 00       	call   f010430a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100884:	c7 44 24 08 50 22 23 	movl   $0x232250,0x8(%esp)
f010088b:	00 
f010088c:	c7 44 24 04 50 22 23 	movl   $0xf0232250,0x4(%esp)
f0100893:	f0 
f0100894:	c7 04 24 bc 74 10 f0 	movl   $0xf01074bc,(%esp)
f010089b:	e8 6a 3a 00 00       	call   f010430a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01008a0:	c7 44 24 08 08 50 27 	movl   $0x275008,0x8(%esp)
f01008a7:	00 
f01008a8:	c7 44 24 04 08 50 27 	movl   $0xf0275008,0x4(%esp)
f01008af:	f0 
f01008b0:	c7 04 24 e0 74 10 f0 	movl   $0xf01074e0,(%esp)
f01008b7:	e8 4e 3a 00 00       	call   f010430a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008bc:	b8 07 54 27 f0       	mov    $0xf0275407,%eax
f01008c1:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008c6:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008cb:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008d1:	85 c0                	test   %eax,%eax
f01008d3:	0f 48 c2             	cmovs  %edx,%eax
f01008d6:	c1 f8 0a             	sar    $0xa,%eax
f01008d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008dd:	c7 04 24 04 75 10 f0 	movl   $0xf0107504,(%esp)
f01008e4:	e8 21 3a 00 00       	call   f010430a <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ee:	c9                   	leave  
f01008ef:	c3                   	ret    

f01008f0 <mon_backtrace>:

	int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008f0:	55                   	push   %ebp
f01008f1:	89 e5                	mov    %esp,%ebp
f01008f3:	57                   	push   %edi
f01008f4:	56                   	push   %esi
f01008f5:	53                   	push   %ebx
f01008f6:	83 ec 5c             	sub    $0x5c,%esp
	// Your code here.
	uint32_t ebp,eip,arg[5];
	struct Eipdebuginfo dinfo;	
	int i,ret;
	cprintf("Stack backtrace:\n");
f01008f9:	c7 04 24 02 73 10 f0 	movl   $0xf0107302,(%esp)
f0100900:	e8 05 3a 00 00       	call   f010430a <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100905:	89 eb                	mov    %ebp,%ebx
	ebp = read_ebp();
	while (ebp != 0x0) {
f0100907:	e9 ae 00 00 00       	jmp    f01009ba <mon_backtrace+0xca>
		cprintf("  ebp %08x",ebp);
f010090c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100910:	c7 04 24 14 73 10 f0 	movl   $0xf0107314,(%esp)
f0100917:	e8 ee 39 00 00       	call   f010430a <cprintf>
		eip = *((uint32_t*)ebp+1);
f010091c:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  eip %08x",eip);
f010091f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100923:	c7 04 24 1f 73 10 f0 	movl   $0xf010731f,(%esp)
f010092a:	e8 db 39 00 00       	call   f010430a <cprintf>
f010092f:	8d 43 08             	lea    0x8(%ebx),%eax
f0100932:	8d 4b 1c             	lea    0x1c(%ebx),%ecx
f0100935:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100938:	29 da                	sub    %ebx,%edx
		for (i=0;i<5;i++) 
			arg[i] = *((uint32_t*)ebp+i+2);
f010093a:	8b 38                	mov    (%eax),%edi
f010093c:	89 7c 02 f8          	mov    %edi,-0x8(%edx,%eax,1)
f0100940:	83 c0 04             	add    $0x4,%eax
	ebp = read_ebp();
	while (ebp != 0x0) {
		cprintf("  ebp %08x",ebp);
		eip = *((uint32_t*)ebp+1);
		cprintf("  eip %08x",eip);
		for (i=0;i<5;i++) 
f0100943:	39 c8                	cmp    %ecx,%eax
f0100945:	75 f3                	jne    f010093a <mon_backtrace+0x4a>
			arg[i] = *((uint32_t*)ebp+i+2);
		cprintf("  args %08x %08x %08x %08x %08x\n",
f0100947:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010094a:	89 44 24 14          	mov    %eax,0x14(%esp)
f010094e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100951:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100955:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100958:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010095c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010095f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100963:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100966:	89 44 24 04          	mov    %eax,0x4(%esp)
f010096a:	c7 04 24 30 75 10 f0 	movl   $0xf0107530,(%esp)
f0100971:	e8 94 39 00 00       	call   f010430a <cprintf>
			arg[0],arg[1],arg[2],arg[3],arg[4]);
		ret = debuginfo_eip((uintptr_t)eip,&dinfo);
f0100976:	8d 45 bc             	lea    -0x44(%ebp),%eax
f0100979:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097d:	89 34 24             	mov    %esi,(%esp)
f0100980:	e8 e4 4d 00 00       	call   f0105769 <debuginfo_eip>
		if (ret == 0) {
f0100985:	85 c0                	test   %eax,%eax
f0100987:	75 2f                	jne    f01009b8 <mon_backtrace+0xc8>
			cprintf("         %s:%d: %.*s+%d\n",dinfo.eip_file,dinfo.eip_line,
f0100989:	2b 75 cc             	sub    -0x34(%ebp),%esi
f010098c:	89 74 24 14          	mov    %esi,0x14(%esp)
f0100990:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100993:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100997:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010099a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010099e:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01009a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009a5:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01009a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ac:	c7 04 24 2a 73 10 f0 	movl   $0xf010732a,(%esp)
f01009b3:	e8 52 39 00 00       	call   f010430a <cprintf>
				dinfo.eip_fn_namelen, dinfo.eip_fn_name, eip-dinfo.eip_fn_addr);
		}
		ebp = *((uint32_t*)ebp);
f01009b8:	8b 1b                	mov    (%ebx),%ebx
	uint32_t ebp,eip,arg[5];
	struct Eipdebuginfo dinfo;	
	int i,ret;
	cprintf("Stack backtrace:\n");
	ebp = read_ebp();
	while (ebp != 0x0) {
f01009ba:	85 db                	test   %ebx,%ebx
f01009bc:	0f 85 4a ff ff ff    	jne    f010090c <mon_backtrace+0x1c>
				dinfo.eip_fn_namelen, dinfo.eip_fn_name, eip-dinfo.eip_fn_addr);
		}
		ebp = *((uint32_t*)ebp);
	}
	return 0;
}
f01009c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01009c7:	83 c4 5c             	add    $0x5c,%esp
f01009ca:	5b                   	pop    %ebx
f01009cb:	5e                   	pop    %esi
f01009cc:	5f                   	pop    %edi
f01009cd:	5d                   	pop    %ebp
f01009ce:	c3                   	ret    

f01009cf <mon_showmappings>:

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f01009cf:	55                   	push   %ebp
f01009d0:	89 e5                	mov    %esp,%ebp
f01009d2:	53                   	push   %ebx
f01009d3:	83 ec 14             	sub    $0x14,%esp
f01009d6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t vstart,vend;	
	vstart = (uint32_t)strtol(argv[1],NULL,16);
f01009d9:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01009e0:	00 
f01009e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01009e8:	00 
f01009e9:	8b 43 04             	mov    0x4(%ebx),%eax
f01009ec:	89 04 24             	mov    %eax,(%esp)
f01009ef:	e8 bf 59 00 00       	call   f01063b3 <strtol>
	vend = (uint32_t)strtol(argv[2],NULL,16);
f01009f4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01009fb:	00 
f01009fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100a03:	00 
f0100a04:	8b 43 08             	mov    0x8(%ebx),%eax
f0100a07:	89 04 24             	mov    %eax,(%esp)
f0100a0a:	e8 a4 59 00 00       	call   f01063b3 <strtol>
	//print_region_map(kern_pgdir,(const void*)vstart,(const void*)vend);
	return 0;
}
f0100a0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a14:	83 c4 14             	add    $0x14,%esp
f0100a17:	5b                   	pop    %ebx
f0100a18:	5d                   	pop    %ebp
f0100a19:	c3                   	ret    

f0100a1a <monitor>:
	return 0;
}

	void
monitor(struct Trapframe *tf)
{
f0100a1a:	55                   	push   %ebp
f0100a1b:	89 e5                	mov    %esp,%ebp
f0100a1d:	57                   	push   %edi
f0100a1e:	56                   	push   %esi
f0100a1f:	53                   	push   %ebx
f0100a20:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a23:	c7 04 24 54 75 10 f0 	movl   $0xf0107554,(%esp)
f0100a2a:	e8 db 38 00 00       	call   f010430a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a2f:	c7 04 24 78 75 10 f0 	movl   $0xf0107578,(%esp)
f0100a36:	e8 cf 38 00 00       	call   f010430a <cprintf>

	if (tf != NULL)
f0100a3b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100a3f:	74 0b                	je     f0100a4c <monitor+0x32>
		print_trapframe(tf);
f0100a41:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a44:	89 04 24             	mov    %eax,(%esp)
f0100a47:	e8 ff 3a 00 00       	call   f010454b <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a4c:	c7 04 24 43 73 10 f0 	movl   $0xf0107343,(%esp)
f0100a53:	e8 d8 55 00 00       	call   f0106030 <readline>
f0100a58:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100a5a:	85 c0                	test   %eax,%eax
f0100a5c:	74 ee                	je     f0100a4c <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100a5e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100a65:	be 00 00 00 00       	mov    $0x0,%esi
f0100a6a:	eb 0a                	jmp    f0100a76 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100a6c:	c6 03 00             	movb   $0x0,(%ebx)
f0100a6f:	89 f7                	mov    %esi,%edi
f0100a71:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a74:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a76:	0f b6 03             	movzbl (%ebx),%eax
f0100a79:	84 c0                	test   %al,%al
f0100a7b:	74 63                	je     f0100ae0 <monitor+0xc6>
f0100a7d:	0f be c0             	movsbl %al,%eax
f0100a80:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a84:	c7 04 24 47 73 10 f0 	movl   $0xf0107347,(%esp)
f0100a8b:	e8 ba 57 00 00       	call   f010624a <strchr>
f0100a90:	85 c0                	test   %eax,%eax
f0100a92:	75 d8                	jne    f0100a6c <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100a94:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a97:	74 47                	je     f0100ae0 <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a99:	83 fe 0f             	cmp    $0xf,%esi
f0100a9c:	75 16                	jne    f0100ab4 <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a9e:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100aa5:	00 
f0100aa6:	c7 04 24 4c 73 10 f0 	movl   $0xf010734c,(%esp)
f0100aad:	e8 58 38 00 00       	call   f010430a <cprintf>
f0100ab2:	eb 98                	jmp    f0100a4c <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100ab4:	8d 7e 01             	lea    0x1(%esi),%edi
f0100ab7:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100abb:	eb 03                	jmp    f0100ac0 <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100abd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100ac0:	0f b6 03             	movzbl (%ebx),%eax
f0100ac3:	84 c0                	test   %al,%al
f0100ac5:	74 ad                	je     f0100a74 <monitor+0x5a>
f0100ac7:	0f be c0             	movsbl %al,%eax
f0100aca:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ace:	c7 04 24 47 73 10 f0 	movl   $0xf0107347,(%esp)
f0100ad5:	e8 70 57 00 00       	call   f010624a <strchr>
f0100ada:	85 c0                	test   %eax,%eax
f0100adc:	74 df                	je     f0100abd <monitor+0xa3>
f0100ade:	eb 94                	jmp    f0100a74 <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100ae0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100ae7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100ae8:	85 f6                	test   %esi,%esi
f0100aea:	0f 84 5c ff ff ff    	je     f0100a4c <monitor+0x32>
f0100af0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100af5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100af8:	8b 04 85 40 76 10 f0 	mov    -0xfef89c0(,%eax,4),%eax
f0100aff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b03:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b06:	89 04 24             	mov    %eax,(%esp)
f0100b09:	e8 de 56 00 00       	call   f01061ec <strcmp>
f0100b0e:	85 c0                	test   %eax,%eax
f0100b10:	75 24                	jne    f0100b36 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100b12:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b15:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b18:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b1c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100b1f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100b23:	89 34 24             	mov    %esi,(%esp)
f0100b26:	ff 14 85 48 76 10 f0 	call   *-0xfef89b8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100b2d:	85 c0                	test   %eax,%eax
f0100b2f:	78 25                	js     f0100b56 <monitor+0x13c>
f0100b31:	e9 16 ff ff ff       	jmp    f0100a4c <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100b36:	83 c3 01             	add    $0x1,%ebx
f0100b39:	83 fb 08             	cmp    $0x8,%ebx
f0100b3c:	75 b7                	jne    f0100af5 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b3e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b41:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b45:	c7 04 24 69 73 10 f0 	movl   $0xf0107369,(%esp)
f0100b4c:	e8 b9 37 00 00       	call   f010430a <cprintf>
f0100b51:	e9 f6 fe ff ff       	jmp    f0100a4c <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100b56:	83 c4 5c             	add    $0x5c,%esp
f0100b59:	5b                   	pop    %ebx
f0100b5a:	5e                   	pop    %esi
f0100b5b:	5f                   	pop    %edi
f0100b5c:	5d                   	pop    %ebp
f0100b5d:	c3                   	ret    
f0100b5e:	66 90                	xchg   %ax,%ax

f0100b60 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b60:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f0100b66:	c1 f8 03             	sar    $0x3,%eax
f0100b69:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b6c:	89 c2                	mov    %eax,%edx
f0100b6e:	c1 ea 0c             	shr    $0xc,%edx
f0100b71:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f0100b77:	72 26                	jb     f0100b9f <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b79:	55                   	push   %ebp
f0100b7a:	89 e5                	mov    %esp,%ebp
f0100b7c:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b7f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b83:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0100b8a:	f0 
f0100b8b:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0100b92:	00 
f0100b93:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0100b9a:	e8 a1 f4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100b9f:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100ba4:	c3                   	ret    

f0100ba5 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100ba5:	89 d1                	mov    %edx,%ecx
f0100ba7:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100baa:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100bad:	a8 01                	test   $0x1,%al
f0100baf:	74 5d                	je     f0100c0e <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bb1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb6:	89 c1                	mov    %eax,%ecx
f0100bb8:	c1 e9 0c             	shr    $0xc,%ecx
f0100bbb:	3b 0d 88 3e 23 f0    	cmp    0xf0233e88,%ecx
f0100bc1:	72 26                	jb     f0100be9 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100bc3:	55                   	push   %ebp
f0100bc4:	89 e5                	mov    %esp,%ebp
f0100bc6:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bcd:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0100bd4:	f0 
f0100bd5:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f0100bdc:	00 
f0100bdd:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100be4:	e8 57 f4 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100be9:	c1 ea 0c             	shr    $0xc,%edx
f0100bec:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bf2:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100bf9:	89 c2                	mov    %eax,%edx
f0100bfb:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bfe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c03:	85 d2                	test   %edx,%edx
f0100c05:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c0a:	0f 44 c2             	cmove  %edx,%eax
f0100c0d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100c0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100c13:	c3                   	ret    

f0100c14 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100c14:	55                   	push   %ebp
f0100c15:	89 e5                	mov    %esp,%ebp
f0100c17:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100c1a:	83 3d 38 32 23 f0 00 	cmpl   $0x0,0xf0233238
f0100c21:	75 11                	jne    f0100c34 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c23:	ba 07 60 27 f0       	mov    $0xf0276007,%edx
f0100c28:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c2e:	89 15 38 32 23 f0    	mov    %edx,0xf0233238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f0100c34:	85 c0                	test   %eax,%eax
f0100c36:	0f 84 96 00 00 00    	je     f0100cd2 <boot_alloc+0xbe>
		if (page_free_list)
f0100c3c:	83 3d 40 32 23 f0 00 	cmpl   $0x0,0xf0233240
f0100c43:	74 1c                	je     f0100c61 <boot_alloc+0x4d>
			panic("Can ONLY used before page_free_list has been set up.\n");
f0100c45:	c7 44 24 08 a0 76 10 	movl   $0xf01076a0,0x8(%esp)
f0100c4c:	f0 
f0100c4d:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
f0100c54:	00 
f0100c55:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100c5c:	e8 df f3 ff ff       	call   f0100040 <_panic>
		if (((uint32_t)PADDR(nextfree)+n)/PGSIZE > npages)
f0100c61:	8b 15 38 32 23 f0    	mov    0xf0233238,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c67:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100c6d:	77 20                	ja     f0100c8f <boot_alloc+0x7b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c6f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100c73:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0100c7a:	f0 
f0100c7b:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0100c82:	00 
f0100c83:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100c8a:	e8 b1 f3 ff ff       	call   f0100040 <_panic>
f0100c8f:	8d 8c 02 00 00 00 10 	lea    0x10000000(%edx,%eax,1),%ecx
f0100c96:	c1 e9 0c             	shr    $0xc,%ecx
f0100c99:	3b 0d 88 3e 23 f0    	cmp    0xf0233e88,%ecx
f0100c9f:	76 1c                	jbe    f0100cbd <boot_alloc+0xa9>
			panic("Out of memory!\n");
f0100ca1:	c7 44 24 08 3f 80 10 	movl   $0xf010803f,0x8(%esp)
f0100ca8:	f0 
f0100ca9:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f0100cb0:	00 
f0100cb1:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100cb8:	e8 83 f3 ff ff       	call   f0100040 <_panic>
		result = nextfree;
		nextfree = ROUNDUP((char*)nextfree+n,PGSIZE);
f0100cbd:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100cc4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cc9:	a3 38 32 23 f0       	mov    %eax,0xf0233238
		return (void*) result;
f0100cce:	89 d0                	mov    %edx,%eax
f0100cd0:	eb 05                	jmp    f0100cd7 <boot_alloc+0xc3>
	} else {
		return nextfree;
f0100cd2:	a1 38 32 23 f0       	mov    0xf0233238,%eax
	}

	return NULL;
}
f0100cd7:	c9                   	leave  
f0100cd8:	c3                   	ret    

f0100cd9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100cd9:	55                   	push   %ebp
f0100cda:	89 e5                	mov    %esp,%ebp
f0100cdc:	57                   	push   %edi
f0100cdd:	56                   	push   %esi
f0100cde:	53                   	push   %ebx
f0100cdf:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ce2:	84 c0                	test   %al,%al
f0100ce4:	0f 85 3f 03 00 00    	jne    f0101029 <check_page_free_list+0x350>
f0100cea:	e9 4c 03 00 00       	jmp    f010103b <check_page_free_list+0x362>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100cef:	c7 44 24 08 d8 76 10 	movl   $0xf01076d8,0x8(%esp)
f0100cf6:	f0 
f0100cf7:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0100cfe:	00 
f0100cff:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100d06:	e8 35 f3 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100d0b:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100d0e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100d11:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d14:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d17:	89 c2                	mov    %eax,%edx
f0100d19:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d1f:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100d25:	0f 95 c2             	setne  %dl
f0100d28:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100d2b:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100d2f:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100d31:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d35:	8b 00                	mov    (%eax),%eax
f0100d37:	85 c0                	test   %eax,%eax
f0100d39:	75 dc                	jne    f0100d17 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100d3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d3e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d44:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d47:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d4a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d4c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d4f:	a3 40 32 23 f0       	mov    %eax,0xf0233240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d54:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d59:	8b 1d 40 32 23 f0    	mov    0xf0233240,%ebx
f0100d5f:	eb 63                	jmp    f0100dc4 <check_page_free_list+0xeb>
f0100d61:	89 d8                	mov    %ebx,%eax
f0100d63:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f0100d69:	c1 f8 03             	sar    $0x3,%eax
f0100d6c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d6f:	89 c2                	mov    %eax,%edx
f0100d71:	c1 ea 16             	shr    $0x16,%edx
f0100d74:	39 f2                	cmp    %esi,%edx
f0100d76:	73 4a                	jae    f0100dc2 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d78:	89 c2                	mov    %eax,%edx
f0100d7a:	c1 ea 0c             	shr    $0xc,%edx
f0100d7d:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f0100d83:	72 20                	jb     f0100da5 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d85:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d89:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0100d90:	f0 
f0100d91:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0100d98:	00 
f0100d99:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0100da0:	e8 9b f2 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100da5:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100dac:	00 
f0100dad:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100db4:	00 
	return (void *)(pa + KERNBASE);
f0100db5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dba:	89 04 24             	mov    %eax,(%esp)
f0100dbd:	e8 c5 54 00 00       	call   f0106287 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dc2:	8b 1b                	mov    (%ebx),%ebx
f0100dc4:	85 db                	test   %ebx,%ebx
f0100dc6:	75 99                	jne    f0100d61 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100dc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dcd:	e8 42 fe ff ff       	call   f0100c14 <boot_alloc>
f0100dd2:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dd5:	8b 15 40 32 23 f0    	mov    0xf0233240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ddb:	8b 0d 90 3e 23 f0    	mov    0xf0233e90,%ecx
		assert(pp < pages + npages);
f0100de1:	a1 88 3e 23 f0       	mov    0xf0233e88,%eax
f0100de6:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100de9:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100dec:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100def:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100df2:	bf 00 00 00 00       	mov    $0x0,%edi
f0100df7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dfa:	e9 c4 01 00 00       	jmp    f0100fc3 <check_page_free_list+0x2ea>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100dff:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100e02:	73 24                	jae    f0100e28 <check_page_free_list+0x14f>
f0100e04:	c7 44 24 0c 4f 80 10 	movl   $0xf010804f,0xc(%esp)
f0100e0b:	f0 
f0100e0c:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100e13:	f0 
f0100e14:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0100e1b:	00 
f0100e1c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100e23:	e8 18 f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100e28:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100e2b:	72 24                	jb     f0100e51 <check_page_free_list+0x178>
f0100e2d:	c7 44 24 0c 70 80 10 	movl   $0xf0108070,0xc(%esp)
f0100e34:	f0 
f0100e35:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100e3c:	f0 
f0100e3d:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0100e44:	00 
f0100e45:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100e4c:	e8 ef f1 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e51:	89 d0                	mov    %edx,%eax
f0100e53:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100e56:	a8 07                	test   $0x7,%al
f0100e58:	74 24                	je     f0100e7e <check_page_free_list+0x1a5>
f0100e5a:	c7 44 24 0c fc 76 10 	movl   $0xf01076fc,0xc(%esp)
f0100e61:	f0 
f0100e62:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100e69:	f0 
f0100e6a:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0100e71:	00 
f0100e72:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100e79:	e8 c2 f1 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e7e:	c1 f8 03             	sar    $0x3,%eax
f0100e81:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e84:	85 c0                	test   %eax,%eax
f0100e86:	75 24                	jne    f0100eac <check_page_free_list+0x1d3>
f0100e88:	c7 44 24 0c 84 80 10 	movl   $0xf0108084,0xc(%esp)
f0100e8f:	f0 
f0100e90:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100e97:	f0 
f0100e98:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0100e9f:	00 
f0100ea0:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100ea7:	e8 94 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100eac:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100eb1:	75 24                	jne    f0100ed7 <check_page_free_list+0x1fe>
f0100eb3:	c7 44 24 0c 95 80 10 	movl   $0xf0108095,0xc(%esp)
f0100eba:	f0 
f0100ebb:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100ec2:	f0 
f0100ec3:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0100eca:	00 
f0100ecb:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100ed2:	e8 69 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ed7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100edc:	75 24                	jne    f0100f02 <check_page_free_list+0x229>
f0100ede:	c7 44 24 0c 30 77 10 	movl   $0xf0107730,0xc(%esp)
f0100ee5:	f0 
f0100ee6:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100eed:	f0 
f0100eee:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0100ef5:	00 
f0100ef6:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100efd:	e8 3e f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f02:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f07:	75 24                	jne    f0100f2d <check_page_free_list+0x254>
f0100f09:	c7 44 24 0c ae 80 10 	movl   $0xf01080ae,0xc(%esp)
f0100f10:	f0 
f0100f11:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100f18:	f0 
f0100f19:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0100f20:	00 
f0100f21:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100f28:	e8 13 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f2d:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f32:	0f 86 2a 01 00 00    	jbe    f0101062 <check_page_free_list+0x389>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f38:	89 c1                	mov    %eax,%ecx
f0100f3a:	c1 e9 0c             	shr    $0xc,%ecx
f0100f3d:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100f40:	77 20                	ja     f0100f62 <check_page_free_list+0x289>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f42:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f46:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0100f4d:	f0 
f0100f4e:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0100f55:	00 
f0100f56:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0100f5d:	e8 de f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100f62:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100f68:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100f6b:	0f 86 e1 00 00 00    	jbe    f0101052 <check_page_free_list+0x379>
f0100f71:	c7 44 24 0c 54 77 10 	movl   $0xf0107754,0xc(%esp)
f0100f78:	f0 
f0100f79:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100f80:	f0 
f0100f81:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0100f88:	00 
f0100f89:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100f90:	e8 ab f0 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100f95:	c7 44 24 0c c8 80 10 	movl   $0xf01080c8,0xc(%esp)
f0100f9c:	f0 
f0100f9d:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100fa4:	f0 
f0100fa5:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0100fac:	00 
f0100fad:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100fb4:	e8 87 f0 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100fb9:	83 c3 01             	add    $0x1,%ebx
f0100fbc:	eb 03                	jmp    f0100fc1 <check_page_free_list+0x2e8>
		else
			++nfree_extmem;
f0100fbe:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fc1:	8b 12                	mov    (%edx),%edx
f0100fc3:	85 d2                	test   %edx,%edx
f0100fc5:	0f 85 34 fe ff ff    	jne    f0100dff <check_page_free_list+0x126>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100fcb:	85 db                	test   %ebx,%ebx
f0100fcd:	7f 24                	jg     f0100ff3 <check_page_free_list+0x31a>
f0100fcf:	c7 44 24 0c e5 80 10 	movl   $0xf01080e5,0xc(%esp)
f0100fd6:	f0 
f0100fd7:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0100fde:	f0 
f0100fdf:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0100fe6:	00 
f0100fe7:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0100fee:	e8 4d f0 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100ff3:	85 ff                	test   %edi,%edi
f0100ff5:	7f 24                	jg     f010101b <check_page_free_list+0x342>
f0100ff7:	c7 44 24 0c f7 80 10 	movl   $0xf01080f7,0xc(%esp)
f0100ffe:	f0 
f0100fff:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101006:	f0 
f0101007:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f010100e:	00 
f010100f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101016:	e8 25 f0 ff ff       	call   f0100040 <_panic>
	
	cprintf("check_page_free_list() succeeded!\n");
f010101b:	c7 04 24 9c 77 10 f0 	movl   $0xf010779c,(%esp)
f0101022:	e8 e3 32 00 00       	call   f010430a <cprintf>
f0101027:	eb 4c                	jmp    f0101075 <check_page_free_list+0x39c>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101029:	a1 40 32 23 f0       	mov    0xf0233240,%eax
f010102e:	85 c0                	test   %eax,%eax
f0101030:	0f 85 d5 fc ff ff    	jne    f0100d0b <check_page_free_list+0x32>
f0101036:	e9 b4 fc ff ff       	jmp    f0100cef <check_page_free_list+0x16>
f010103b:	83 3d 40 32 23 f0 00 	cmpl   $0x0,0xf0233240
f0101042:	0f 84 a7 fc ff ff    	je     f0100cef <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101048:	be 00 04 00 00       	mov    $0x400,%esi
f010104d:	e9 07 fd ff ff       	jmp    f0100d59 <check_page_free_list+0x80>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0101052:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0101057:	0f 85 61 ff ff ff    	jne    f0100fbe <check_page_free_list+0x2e5>
f010105d:	e9 33 ff ff ff       	jmp    f0100f95 <check_page_free_list+0x2bc>
f0101062:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0101067:	0f 85 4c ff ff ff    	jne    f0100fb9 <check_page_free_list+0x2e0>
f010106d:	8d 76 00             	lea    0x0(%esi),%esi
f0101070:	e9 20 ff ff ff       	jmp    f0100f95 <check_page_free_list+0x2bc>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	
	cprintf("check_page_free_list() succeeded!\n");
}
f0101075:	83 c4 4c             	add    $0x4c,%esp
f0101078:	5b                   	pop    %ebx
f0101079:	5e                   	pop    %esi
f010107a:	5f                   	pop    %edi
f010107b:	5d                   	pop    %ebp
f010107c:	c3                   	ret    

f010107d <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010107d:	55                   	push   %ebp
f010107e:	89 e5                	mov    %esp,%ebp
f0101080:	57                   	push   %edi
f0101081:	56                   	push   %esi
f0101082:	53                   	push   %ebx
f0101083:	83 ec 2c             	sub    $0x2c,%esp
		//pages[i].pp_link = page_free_list;
		//page_free_list = &pages[i];
		if(i==0){
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		} else if (i*PGSIZE >= PGSIZE && i*PGSIZE < npages_basemem * PGSIZE){
f0101086:	a1 44 32 23 f0       	mov    0xf0233244,%eax
f010108b:	c1 e0 0c             	shl    $0xc,%eax
f010108e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101091:	a1 40 32 23 f0       	mov    0xf0233240,%eax
f0101096:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0101099:	ba 00 00 00 00       	mov    $0x0,%edx
f010109e:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a8:	e9 ac 01 00 00       	jmp    f0101259 <page_init+0x1dc>
		//pages[i].pp_ref = 0;
		//pages[i].pp_link = page_free_list;
		//page_free_list = &pages[i];
		if(i==0){
f01010ad:	85 c0                	test   %eax,%eax
f01010af:	75 17                	jne    f01010c8 <page_init+0x4b>
			pages[i].pp_ref = 1;
f01010b1:	8b 1d 90 3e 23 f0    	mov    0xf0233e90,%ebx
f01010b7:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
			pages[i].pp_link = NULL;
f01010bd:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
f01010c3:	e9 85 01 00 00       	jmp    f010124d <page_init+0x1d0>
		} else if (i*PGSIZE >= PGSIZE && i*PGSIZE < npages_basemem * PGSIZE){
f01010c8:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f01010ce:	76 49                	jbe    f0101119 <page_init+0x9c>
f01010d0:	39 55 e0             	cmp    %edx,-0x20(%ebp)
f01010d3:	76 44                	jbe    f0101119 <page_init+0x9c>
			if (i*PGSIZE == MPENTRY_PADDR) {
f01010d5:	81 fa 00 70 00 00    	cmp    $0x7000,%edx
f01010db:	75 19                	jne    f01010f6 <page_init+0x79>
				pages[i].pp_ref = 1;
f01010dd:	89 cb                	mov    %ecx,%ebx
f01010df:	03 1d 90 3e 23 f0    	add    0xf0233e90,%ebx
f01010e5:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
				pages[i].pp_link = NULL;
f01010eb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
f01010f1:	e9 57 01 00 00       	jmp    f010124d <page_init+0x1d0>
			} else {
				pages[i].pp_ref = 0;
f01010f6:	89 cb                	mov    %ecx,%ebx
f01010f8:	03 1d 90 3e 23 f0    	add    0xf0233e90,%ebx
f01010fe:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
				pages[i].pp_link = page_free_list;
f0101104:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101107:	89 3b                	mov    %edi,(%ebx)
				page_free_list = &pages[i];
f0101109:	89 cf                	mov    %ecx,%edi
f010110b:	03 3d 90 3e 23 f0    	add    0xf0233e90,%edi
f0101111:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0101114:	e9 34 01 00 00       	jmp    f010124d <page_init+0x1d0>
			}
		} else if (i*PGSIZE >= EXTPHYSMEM) {
f0101119:	81 fa ff ff 0f 00    	cmp    $0xfffff,%edx
f010111f:	0f 86 14 01 00 00    	jbe    f0101239 <page_init+0x1bc>
			if (i*PGSIZE == PADDR(kern_pgdir) || (i*PGSIZE >=  (uint32_t)ROUNDDOWN(PADDR(pages),PGSIZE) && i*PGSIZE < (uint32_t)ROUNDDOWN(PADDR(pages+npages),PGSIZE))){
f0101125:	8b 35 8c 3e 23 f0    	mov    0xf0233e8c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010112b:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0101131:	77 28                	ja     f010115b <page_init+0xde>
f0101133:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101136:	a3 40 32 23 f0       	mov    %eax,0xf0233240
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010113b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010113f:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0101146:	f0 
f0101147:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f010114e:	00 
f010114f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101156:	e8 e5 ee ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010115b:	81 c6 00 00 00 10    	add    $0x10000000,%esi
f0101161:	39 d6                	cmp    %edx,%esi
f0101163:	0f 84 89 00 00 00    	je     f01011f2 <page_init+0x175>
f0101169:	8b 35 90 3e 23 f0    	mov    0xf0233e90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010116f:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0101175:	77 28                	ja     f010119f <page_init+0x122>
f0101177:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010117a:	a3 40 32 23 f0       	mov    %eax,0xf0233240
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010117f:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101183:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f010118a:	f0 
f010118b:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f0101192:	00 
f0101193:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010119a:	e8 a1 ee ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010119f:	8d be 00 00 00 10    	lea    0x10000000(%esi),%edi
f01011a5:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f01011ab:	39 d7                	cmp    %edx,%edi
f01011ad:	77 59                	ja     f0101208 <page_init+0x18b>
f01011af:	8d 1c de             	lea    (%esi,%ebx,8),%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01011b2:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01011b8:	77 28                	ja     f01011e2 <page_init+0x165>
f01011ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011bd:	a3 40 32 23 f0       	mov    %eax,0xf0233240
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01011c2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01011c6:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f01011cd:	f0 
f01011ce:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f01011d5:	00 
f01011d6:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01011dd:	e8 5e ee ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01011e2:	81 c3 00 00 00 10    	add    $0x10000000,%ebx
f01011e8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01011ee:	39 d3                	cmp    %edx,%ebx
f01011f0:	76 16                	jbe    f0101208 <page_init+0x18b>
				pages[i].pp_ref = 1;
f01011f2:	89 cb                	mov    %ecx,%ebx
f01011f4:	03 1d 90 3e 23 f0    	add    0xf0233e90,%ebx
f01011fa:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
				pages[i].pp_link = NULL;
f0101200:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
				continue;
f0101206:	eb 45                	jmp    f010124d <page_init+0x1d0>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101208:	8d 1c 0e             	lea    (%esi,%ecx,1),%ebx
			}
			if (PDX(page2pa(pages+i)) < 1) {
f010120b:	f7 c1 00 e0 7f 00    	test   $0x7fe000,%ecx
f0101211:	75 0e                	jne    f0101221 <page_init+0x1a4>
				pages[i].pp_ref = 1;
f0101213:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
				pages[i].pp_link = NULL;
f0101219:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
				continue;
f010121f:	eb 2c                	jmp    f010124d <page_init+0x1d0>
			}
			pages[i].pp_ref = 0;
f0101221:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
			pages[i].pp_link = page_free_list;
f0101227:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010122a:	89 3b                	mov    %edi,(%ebx)
			page_free_list = &pages[i];
f010122c:	89 cf                	mov    %ecx,%edi
f010122e:	03 3d 90 3e 23 f0    	add    0xf0233e90,%edi
f0101234:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0101237:	eb 14                	jmp    f010124d <page_init+0x1d0>
		} else {
			pages[i].pp_ref = 1;
f0101239:	89 cb                	mov    %ecx,%ebx
f010123b:	03 1d 90 3e 23 f0    	add    0xf0233e90,%ebx
f0101241:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
			pages[i].pp_link = NULL;
f0101247:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f010124d:	83 c0 01             	add    $0x1,%eax
f0101250:	83 c1 08             	add    $0x8,%ecx
f0101253:	81 c2 00 10 00 00    	add    $0x1000,%edx
f0101259:	8b 1d 88 3e 23 f0    	mov    0xf0233e88,%ebx
f010125f:	39 d8                	cmp    %ebx,%eax
f0101261:	0f 82 46 fe ff ff    	jb     f01010ad <page_init+0x30>
f0101267:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010126a:	a3 40 32 23 f0       	mov    %eax,0xf0233240
		} else {
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}
	}
}
f010126f:	83 c4 2c             	add    $0x2c,%esp
f0101272:	5b                   	pop    %ebx
f0101273:	5e                   	pop    %esi
f0101274:	5f                   	pop    %edi
f0101275:	5d                   	pop    %ebp
f0101276:	c3                   	ret    

f0101277 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0101277:	55                   	push   %ebp
f0101278:	89 e5                	mov    %esp,%ebp
f010127a:	53                   	push   %ebx
f010127b:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list == 0) return NULL;
f010127e:	8b 1d 40 32 23 f0    	mov    0xf0233240,%ebx
f0101284:	85 db                	test   %ebx,%ebx
f0101286:	74 6f                	je     f01012f7 <page_alloc+0x80>
	struct PageInfo *free = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101288:	8b 03                	mov    (%ebx),%eax
f010128a:	a3 40 32 23 f0       	mov    %eax,0xf0233240
	free->pp_link = NULL;
f010128f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) {
		memset(page2kva(free),0,PGSIZE);
	}
	return free;
f0101295:	89 d8                	mov    %ebx,%eax
	// Fill this function in
	if (page_free_list == 0) return NULL;
	struct PageInfo *free = page_free_list;
	page_free_list = page_free_list->pp_link;
	free->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) {
f0101297:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010129b:	74 5f                	je     f01012fc <page_alloc+0x85>
f010129d:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f01012a3:	c1 f8 03             	sar    $0x3,%eax
f01012a6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012a9:	89 c2                	mov    %eax,%edx
f01012ab:	c1 ea 0c             	shr    $0xc,%edx
f01012ae:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f01012b4:	72 20                	jb     f01012d6 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012b6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012ba:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f01012c1:	f0 
f01012c2:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f01012c9:	00 
f01012ca:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f01012d1:	e8 6a ed ff ff       	call   f0100040 <_panic>
		memset(page2kva(free),0,PGSIZE);
f01012d6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012dd:	00 
f01012de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012e5:	00 
	return (void *)(pa + KERNBASE);
f01012e6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012eb:	89 04 24             	mov    %eax,(%esp)
f01012ee:	e8 94 4f 00 00       	call   f0106287 <memset>
	}
	return free;
f01012f3:	89 d8                	mov    %ebx,%eax
f01012f5:	eb 05                	jmp    f01012fc <page_alloc+0x85>
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if (page_free_list == 0) return NULL;
f01012f7:	b8 00 00 00 00       	mov    $0x0,%eax
	if (alloc_flags & ALLOC_ZERO) {
		memset(page2kva(free),0,PGSIZE);
	}
	return free;
	
}
f01012fc:	83 c4 14             	add    $0x14,%esp
f01012ff:	5b                   	pop    %ebx
f0101300:	5d                   	pop    %ebp
f0101301:	c3                   	ret    

f0101302 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101302:	55                   	push   %ebp
f0101303:	89 e5                	mov    %esp,%ebp
f0101305:	83 ec 18             	sub    $0x18,%esp
f0101308:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref > 0 || pp->pp_link != NULL) {
f010130b:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101310:	75 05                	jne    f0101317 <page_free+0x15>
f0101312:	83 38 00             	cmpl   $0x0,(%eax)
f0101315:	74 1c                	je     f0101333 <page_free+0x31>
		panic("Free used page!\n");
f0101317:	c7 44 24 08 08 81 10 	movl   $0xf0108108,0x8(%esp)
f010131e:	f0 
f010131f:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
f0101326:	00 
f0101327:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010132e:	e8 0d ed ff ff       	call   f0100040 <_panic>
	}
	pp->pp_link = page_free_list;
f0101333:	8b 15 40 32 23 f0    	mov    0xf0233240,%edx
f0101339:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010133b:	a3 40 32 23 f0       	mov    %eax,0xf0233240
}
f0101340:	c9                   	leave  
f0101341:	c3                   	ret    

f0101342 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101342:	55                   	push   %ebp
f0101343:	89 e5                	mov    %esp,%ebp
f0101345:	83 ec 18             	sub    $0x18,%esp
f0101348:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010134b:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f010134f:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101352:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101356:	66 85 d2             	test   %dx,%dx
f0101359:	75 08                	jne    f0101363 <page_decref+0x21>
		page_free(pp);
f010135b:	89 04 24             	mov    %eax,(%esp)
f010135e:	e8 9f ff ff ff       	call   f0101302 <page_free>
}
f0101363:	c9                   	leave  
f0101364:	c3                   	ret    

f0101365 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101365:	55                   	push   %ebp
f0101366:	89 e5                	mov    %esp,%ebp
f0101368:	56                   	push   %esi
f0101369:	53                   	push   %ebx
f010136a:	83 ec 10             	sub    $0x10,%esp
f010136d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pde_t pde = pgdir[PDX(va)];
f0101370:	89 de                	mov    %ebx,%esi
f0101372:	c1 ee 16             	shr    $0x16,%esi
f0101375:	c1 e6 02             	shl    $0x2,%esi
f0101378:	03 75 08             	add    0x8(%ebp),%esi
f010137b:	8b 06                	mov    (%esi),%eax
	if (pde & PTE_P) {
f010137d:	a8 01                	test   $0x1,%al
f010137f:	74 47                	je     f01013c8 <pgdir_walk+0x63>
		pte_t *pt = (pte_t*)(pde&0xFFFFF000);
f0101381:	25 00 f0 ff ff       	and    $0xfffff000,%eax
		return (pte_t*)KADDR((uint32_t)(pt+PTX(va)));
f0101386:	c1 eb 0a             	shr    $0xa,%ebx
f0101389:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f010138f:	01 d8                	add    %ebx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101391:	89 c2                	mov    %eax,%edx
f0101393:	c1 ea 0c             	shr    $0xc,%edx
f0101396:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f010139c:	72 20                	jb     f01013be <pgdir_walk+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010139e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013a2:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f01013a9:	f0 
f01013aa:	c7 44 24 04 da 01 00 	movl   $0x1da,0x4(%esp)
f01013b1:	00 
f01013b2:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01013b9:	e8 82 ec ff ff       	call   f0100040 <_panic>
f01013be:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013c3:	e9 de 00 00 00       	jmp    f01014a6 <pgdir_walk+0x141>
	} else {
		if (create == false) return NULL;
f01013c8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01013cc:	0f 84 c8 00 00 00    	je     f010149a <pgdir_walk+0x135>
		else {
			struct PageInfo *free = page_alloc(1);
f01013d2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01013d9:	e8 99 fe ff ff       	call   f0101277 <page_alloc>
			if (free == NULL) return NULL;
f01013de:	85 c0                	test   %eax,%eax
f01013e0:	0f 84 bb 00 00 00    	je     f01014a1 <pgdir_walk+0x13c>
			else {
				free->pp_ref++;
f01013e6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013eb:	89 c2                	mov    %eax,%edx
f01013ed:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f01013f3:	c1 fa 03             	sar    $0x3,%edx
				pgdir[PDX(va)] = (page2pa(free)&0xFFFFF000)|PTE_W|PTE_P;
f01013f6:	c1 e2 0c             	shl    $0xc,%edx
f01013f9:	83 ca 03             	or     $0x3,%edx
f01013fc:	89 16                	mov    %edx,(%esi)
f01013fe:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f0101404:	c1 f8 03             	sar    $0x3,%eax
f0101407:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010140a:	89 c2                	mov    %eax,%edx
f010140c:	c1 ea 0c             	shr    $0xc,%edx
f010140f:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f0101415:	72 20                	jb     f0101437 <pgdir_walk+0xd2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101417:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010141b:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0101422:	f0 
f0101423:	c7 44 24 04 e3 01 00 	movl   $0x1e3,0x4(%esp)
f010142a:	00 
f010142b:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101432:	e8 09 ec ff ff       	call   f0100040 <_panic>
				memset(KADDR(page2pa(free)),0,PGSIZE);
f0101437:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010143e:	00 
f010143f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101446:	00 
	return (void *)(pa + KERNBASE);
f0101447:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010144c:	89 04 24             	mov    %eax,(%esp)
f010144f:	e8 33 4e 00 00       	call   f0106287 <memset>
				pde = pgdir[PDX(va)];
				pte_t* pt = (pte_t*)KADDR(pde&0xFFFFF000);
f0101454:	8b 06                	mov    (%esi),%eax
f0101456:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010145b:	89 c2                	mov    %eax,%edx
f010145d:	c1 ea 0c             	shr    $0xc,%edx
f0101460:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f0101466:	72 20                	jb     f0101488 <pgdir_walk+0x123>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101468:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010146c:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0101473:	f0 
f0101474:	c7 44 24 04 e5 01 00 	movl   $0x1e5,0x4(%esp)
f010147b:	00 
f010147c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101483:	e8 b8 eb ff ff       	call   f0100040 <_panic>
				return (pt+PTX(va));
f0101488:	c1 eb 0a             	shr    $0xa,%ebx
f010148b:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101491:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0101498:	eb 0c                	jmp    f01014a6 <pgdir_walk+0x141>
	pde_t pde = pgdir[PDX(va)];
	if (pde & PTE_P) {
		pte_t *pt = (pte_t*)(pde&0xFFFFF000);
		return (pte_t*)KADDR((uint32_t)(pt+PTX(va)));
	} else {
		if (create == false) return NULL;
f010149a:	b8 00 00 00 00       	mov    $0x0,%eax
f010149f:	eb 05                	jmp    f01014a6 <pgdir_walk+0x141>
		else {
			struct PageInfo *free = page_alloc(1);
			if (free == NULL) return NULL;
f01014a1:	b8 00 00 00 00       	mov    $0x0,%eax
				pte_t* pt = (pte_t*)KADDR(pde&0xFFFFF000);
				return (pt+PTX(va));
			}
		}
	}
}
f01014a6:	83 c4 10             	add    $0x10,%esp
f01014a9:	5b                   	pop    %ebx
f01014aa:	5e                   	pop    %esi
f01014ab:	5d                   	pop    %ebp
f01014ac:	c3                   	ret    

f01014ad <print_region_map>:
static void check_page(void);
static void check_page_installed_pgdir(void);

void 
print_region_map(pde_t *pgdir, const void *vas, const void *vae)
{
f01014ad:	55                   	push   %ebp
f01014ae:	89 e5                	mov    %esp,%ebp
f01014b0:	57                   	push   %edi
f01014b1:	56                   	push   %esi
f01014b2:	53                   	push   %ebx
f01014b3:	83 ec 2c             	sub    $0x2c,%esp
f01014b6:	8b 75 08             	mov    0x8(%ebp),%esi
	const void *cur;
	vas = ROUNDDOWN(vas,PGSIZE);
f01014b9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014bc:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	vae = ROUNDDOWN(vae,PGSIZE);
f01014c2:	8b 7d 10             	mov    0x10(%ebp),%edi
f01014c5:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for (cur=vas;cur<=vae;cur+=PGSIZE) {
f01014cb:	e9 9a 00 00 00       	jmp    f010156a <print_region_map+0xbd>
		pde_t pde = pgdir[PDX(cur)];
f01014d0:	89 d8                	mov    %ebx,%eax
f01014d2:	c1 e8 16             	shr    $0x16,%eax
		if ((pde&PTE_P) == 0) {
f01014d5:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01014d9:	75 12                	jne    f01014ed <print_region_map+0x40>
			cprintf("%p: Not mapped.\n",cur);
f01014db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014df:	c7 04 24 29 81 10 f0 	movl   $0xf0108129,(%esp)
f01014e6:	e8 1f 2e 00 00       	call   f010430a <cprintf>
			continue;
f01014eb:	eb 77                	jmp    f0101564 <print_region_map+0xb7>
		} else {
			pte_t *pte = pgdir_walk(pgdir,cur,0);
f01014ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01014f4:	00 
f01014f5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014f9:	89 34 24             	mov    %esi,(%esp)
f01014fc:	e8 64 fe ff ff       	call   f0101365 <pgdir_walk>
			if (((*pte)&PTE_P) == 0) {
f0101501:	8b 00                	mov    (%eax),%eax
f0101503:	a8 01                	test   $0x1,%al
f0101505:	75 12                	jne    f0101519 <print_region_map+0x6c>
				cprintf("%p: Not mapped.\n",cur);
f0101507:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010150b:	c7 04 24 29 81 10 f0 	movl   $0xf0108129,(%esp)
f0101512:	e8 f3 2d 00 00       	call   f010430a <cprintf>
				continue;
f0101517:	eb 4b                	jmp    f0101564 <print_region_map+0xb7>
			}
			cprintf("%p: mapped to physical address %p (%s,%s).\n",cur,(*pte)&0xFFFFF000,(*pte&PTE_U)?"SYS/USER":"SYS",((*pte)&PTE_W)?"RW":"R");
f0101519:	89 c2                	mov    %eax,%edx
f010151b:	83 e2 02             	and    $0x2,%edx
f010151e:	b9 19 81 10 f0       	mov    $0xf0108119,%ecx
f0101523:	ba e3 80 10 f0       	mov    $0xf01080e3,%edx
f0101528:	0f 44 ca             	cmove  %edx,%ecx
f010152b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010152e:	89 c2                	mov    %eax,%edx
f0101530:	83 e2 04             	and    $0x4,%edx
f0101533:	ba 1c 81 10 f0       	mov    $0xf010811c,%edx
f0101538:	b9 25 81 10 f0       	mov    $0xf0108125,%ecx
f010153d:	0f 44 d1             	cmove  %ecx,%edx
f0101540:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101543:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101547:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010154b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101550:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101554:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101558:	c7 04 24 c0 77 10 f0 	movl   $0xf01077c0,(%esp)
f010155f:	e8 a6 2d 00 00       	call   f010430a <cprintf>
print_region_map(pde_t *pgdir, const void *vas, const void *vae)
{
	const void *cur;
	vas = ROUNDDOWN(vas,PGSIZE);
	vae = ROUNDDOWN(vae,PGSIZE);
	for (cur=vas;cur<=vae;cur+=PGSIZE) {
f0101564:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010156a:	39 fb                	cmp    %edi,%ebx
f010156c:	0f 86 5e ff ff ff    	jbe    f01014d0 <print_region_map+0x23>
				continue;
			}
			cprintf("%p: mapped to physical address %p (%s,%s).\n",cur,(*pte)&0xFFFFF000,(*pte&PTE_U)?"SYS/USER":"SYS",((*pte)&PTE_W)?"RW":"R");
		}
	}
}
f0101572:	83 c4 2c             	add    $0x2c,%esp
f0101575:	5b                   	pop    %ebx
f0101576:	5e                   	pop    %esi
f0101577:	5f                   	pop    %edi
f0101578:	5d                   	pop    %ebp
f0101579:	c3                   	ret    

f010157a <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010157a:	55                   	push   %ebp
f010157b:	89 e5                	mov    %esp,%ebp
f010157d:	57                   	push   %edi
f010157e:	56                   	push   %esi
f010157f:	53                   	push   %ebx
f0101580:	83 ec 2c             	sub    $0x2c,%esp
f0101583:	89 c7                	mov    %eax,%edi
f0101585:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	uintptr_t cur;
	for(cur=0;cur<size;cur+=PGSIZE) {
f0101588:	89 d6                	mov    %edx,%esi
f010158a:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte_t *pt = pgdir_walk(pgdir,(const void*)va+cur,1);
		pgdir[PDX(va+cur)] |= perm;
		*pt = ((pa+cur)&0xFFFFF000)|(perm|PTE_P);
f010158f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101592:	83 c8 01             	or     $0x1,%eax
f0101595:	89 45 e0             	mov    %eax,-0x20(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	uintptr_t cur;
	for(cur=0;cur<size;cur+=PGSIZE) {
f0101598:	eb 3b                	jmp    f01015d5 <boot_map_region+0x5b>
		pte_t *pt = pgdir_walk(pgdir,(const void*)va+cur,1);
f010159a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01015a1:	00 
f01015a2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01015a6:	89 3c 24             	mov    %edi,(%esp)
f01015a9:	e8 b7 fd ff ff       	call   f0101365 <pgdir_walk>
		pgdir[PDX(va+cur)] |= perm;
f01015ae:	89 f2                	mov    %esi,%edx
f01015b0:	c1 ea 16             	shr    $0x16,%edx
f01015b3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015b6:	09 0c 97             	or     %ecx,(%edi,%edx,4)
f01015b9:	89 da                	mov    %ebx,%edx
f01015bb:	03 55 08             	add    0x8(%ebp),%edx
		*pt = ((pa+cur)&0xFFFFF000)|(perm|PTE_P);
f01015be:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01015c4:	0b 55 e0             	or     -0x20(%ebp),%edx
f01015c7:	89 10                	mov    %edx,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	uintptr_t cur;
	for(cur=0;cur<size;cur+=PGSIZE) {
f01015c9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01015cf:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01015d5:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01015d8:	72 c0                	jb     f010159a <boot_map_region+0x20>
		pte_t *pt = pgdir_walk(pgdir,(const void*)va+cur,1);
		pgdir[PDX(va+cur)] |= perm;
		*pt = ((pa+cur)&0xFFFFF000)|(perm|PTE_P);
	}
}
f01015da:	83 c4 2c             	add    $0x2c,%esp
f01015dd:	5b                   	pop    %ebx
f01015de:	5e                   	pop    %esi
f01015df:	5f                   	pop    %edi
f01015e0:	5d                   	pop    %ebp
f01015e1:	c3                   	ret    

f01015e2 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01015e2:	55                   	push   %ebp
f01015e3:	89 e5                	mov    %esp,%ebp
f01015e5:	53                   	push   %ebx
f01015e6:	83 ec 14             	sub    $0x14,%esp
f01015e9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pt = pgdir_walk(pgdir,va,0);
f01015ec:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01015f3:	00 
f01015f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01015fe:	89 04 24             	mov    %eax,(%esp)
f0101601:	e8 5f fd ff ff       	call   f0101365 <pgdir_walk>
	if (pt == NULL || ((*pt)&PTE_P) == 0) return NULL;
f0101606:	85 c0                	test   %eax,%eax
f0101608:	74 3f                	je     f0101649 <page_lookup+0x67>
f010160a:	f6 00 01             	testb  $0x1,(%eax)
f010160d:	74 41                	je     f0101650 <page_lookup+0x6e>
	if (pte_store != 0) *pte_store = pt;
f010160f:	85 db                	test   %ebx,%ebx
f0101611:	74 02                	je     f0101615 <page_lookup+0x33>
f0101613:	89 03                	mov    %eax,(%ebx)
	return pa2page(((*pt)&0xFFFFF000)|((uint32_t)va&0x00000FFF));
f0101615:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101617:	c1 e8 0c             	shr    $0xc,%eax
f010161a:	3b 05 88 3e 23 f0    	cmp    0xf0233e88,%eax
f0101620:	72 1c                	jb     f010163e <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f0101622:	c7 44 24 08 ec 77 10 	movl   $0xf01077ec,0x8(%esp)
f0101629:	f0 
f010162a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101631:	00 
f0101632:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0101639:	e8 02 ea ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010163e:	8b 15 90 3e 23 f0    	mov    0xf0233e90,%edx
f0101644:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101647:	eb 0c                	jmp    f0101655 <page_lookup+0x73>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pt = pgdir_walk(pgdir,va,0);
	if (pt == NULL || ((*pt)&PTE_P) == 0) return NULL;
f0101649:	b8 00 00 00 00       	mov    $0x0,%eax
f010164e:	eb 05                	jmp    f0101655 <page_lookup+0x73>
f0101650:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store != 0) *pte_store = pt;
	return pa2page(((*pt)&0xFFFFF000)|((uint32_t)va&0x00000FFF));
}
f0101655:	83 c4 14             	add    $0x14,%esp
f0101658:	5b                   	pop    %ebx
f0101659:	5d                   	pop    %ebp
f010165a:	c3                   	ret    

f010165b <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010165b:	55                   	push   %ebp
f010165c:	89 e5                	mov    %esp,%ebp
f010165e:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101661:	e8 73 52 00 00       	call   f01068d9 <cpunum>
f0101666:	6b c0 74             	imul   $0x74,%eax,%eax
f0101669:	83 b8 28 40 23 f0 00 	cmpl   $0x0,-0xfdcbfd8(%eax)
f0101670:	74 16                	je     f0101688 <tlb_invalidate+0x2d>
f0101672:	e8 62 52 00 00       	call   f01068d9 <cpunum>
f0101677:	6b c0 74             	imul   $0x74,%eax,%eax
f010167a:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0101680:	8b 55 08             	mov    0x8(%ebp),%edx
f0101683:	39 50 60             	cmp    %edx,0x60(%eax)
f0101686:	75 06                	jne    f010168e <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101688:	8b 45 0c             	mov    0xc(%ebp),%eax
f010168b:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f010168e:	c9                   	leave  
f010168f:	c3                   	ret    

f0101690 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101690:	55                   	push   %ebp
f0101691:	89 e5                	mov    %esp,%ebp
f0101693:	56                   	push   %esi
f0101694:	53                   	push   %ebx
f0101695:	83 ec 20             	sub    $0x20,%esp
f0101698:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010169b:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pg = page_lookup(pgdir,va,&pte);
f010169e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01016a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016a5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01016a9:	89 1c 24             	mov    %ebx,(%esp)
f01016ac:	e8 31 ff ff ff       	call   f01015e2 <page_lookup>
	if (pg != NULL) {
f01016b1:	85 c0                	test   %eax,%eax
f01016b3:	74 2f                	je     f01016e4 <page_remove+0x54>
		page_decref(pg);
f01016b5:	89 04 24             	mov    %eax,(%esp)
f01016b8:	e8 85 fc ff ff       	call   f0101342 <page_decref>
		memset(pte,0,sizeof(pte_t));
f01016bd:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f01016c4:	00 
f01016c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016cc:	00 
f01016cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016d0:	89 04 24             	mov    %eax,(%esp)
f01016d3:	e8 af 4b 00 00       	call   f0106287 <memset>
		tlb_invalidate(pgdir,va);
f01016d8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01016dc:	89 1c 24             	mov    %ebx,(%esp)
f01016df:	e8 77 ff ff ff       	call   f010165b <tlb_invalidate>
	}
}
f01016e4:	83 c4 20             	add    $0x20,%esp
f01016e7:	5b                   	pop    %ebx
f01016e8:	5e                   	pop    %esi
f01016e9:	5d                   	pop    %ebp
f01016ea:	c3                   	ret    

f01016eb <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01016eb:	55                   	push   %ebp
f01016ec:	89 e5                	mov    %esp,%ebp
f01016ee:	57                   	push   %edi
f01016ef:	56                   	push   %esi
f01016f0:	53                   	push   %ebx
f01016f1:	83 ec 1c             	sub    $0x1c,%esp
f01016f4:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016f7:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pt = pgdir_walk(pgdir,va,1);
f01016fa:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101701:	00 
f0101702:	8b 45 10             	mov    0x10(%ebp),%eax
f0101705:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101709:	89 1c 24             	mov    %ebx,(%esp)
f010170c:	e8 54 fc ff ff       	call   f0101365 <pgdir_walk>
f0101711:	89 c7                	mov    %eax,%edi
	if (pt == NULL) return -1;
f0101713:	85 c0                	test   %eax,%eax
f0101715:	0f 84 92 00 00 00    	je     f01017ad <page_insert+0xc2>
	if (((*pt)&PTE_P) == 0){
f010171b:	f6 00 01             	testb  $0x1,(%eax)
f010171e:	75 30                	jne    f0101750 <page_insert+0x65>
		*pt = (page2pa(pp)&0xFFFFF000)|(perm|PTE_P);
f0101720:	8b 55 14             	mov    0x14(%ebp),%edx
f0101723:	83 ca 01             	or     $0x1,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101726:	89 f0                	mov    %esi,%eax
f0101728:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f010172e:	c1 f8 03             	sar    $0x3,%eax
f0101731:	c1 e0 0c             	shl    $0xc,%eax
f0101734:	09 d0                	or     %edx,%eax
f0101736:	89 07                	mov    %eax,(%edi)
		pgdir[PDX(va)] |= perm;
f0101738:	8b 45 10             	mov    0x10(%ebp),%eax
f010173b:	c1 e8 16             	shr    $0x16,%eax
f010173e:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101741:	09 0c 83             	or     %ecx,(%ebx,%eax,4)
		pp->pp_ref++;
f0101744:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		return 0;
f0101749:	b8 00 00 00 00       	mov    $0x0,%eax
f010174e:	eb 62                	jmp    f01017b2 <page_insert+0xc7>
	} else {
		page_remove(pgdir,va);
f0101750:	8b 45 10             	mov    0x10(%ebp),%eax
f0101753:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101757:	89 1c 24             	mov    %ebx,(%esp)
f010175a:	e8 31 ff ff ff       	call   f0101690 <page_remove>
		*pt = (page2pa(pp)&0xFFFFF000)|(perm|PTE_P);
f010175f:	8b 55 14             	mov    0x14(%ebp),%edx
f0101762:	83 ca 01             	or     $0x1,%edx
f0101765:	89 f0                	mov    %esi,%eax
f0101767:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f010176d:	c1 f8 03             	sar    $0x3,%eax
f0101770:	c1 e0 0c             	shl    $0xc,%eax
f0101773:	09 d0                	or     %edx,%eax
f0101775:	89 07                	mov    %eax,(%edi)
		pgdir[PDX(va)] |= perm;
f0101777:	8b 45 10             	mov    0x10(%ebp),%eax
f010177a:	c1 e8 16             	shr    $0x16,%eax
f010177d:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101780:	09 0c 83             	or     %ecx,(%ebx,%eax,4)
		pp->pp_ref++;
f0101783:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		if (pp == page_free_list) page_free_list = pp->pp_link;
f0101788:	3b 35 40 32 23 f0    	cmp    0xf0233240,%esi
f010178e:	75 07                	jne    f0101797 <page_insert+0xac>
f0101790:	8b 06                	mov    (%esi),%eax
f0101792:	a3 40 32 23 f0       	mov    %eax,0xf0233240
		tlb_invalidate(pgdir,va);		
f0101797:	8b 45 10             	mov    0x10(%ebp),%eax
f010179a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010179e:	89 1c 24             	mov    %ebx,(%esp)
f01017a1:	e8 b5 fe ff ff       	call   f010165b <tlb_invalidate>
		return 0;
f01017a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01017ab:	eb 05                	jmp    f01017b2 <page_insert+0xc7>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pt = pgdir_walk(pgdir,va,1);
	if (pt == NULL) return -1;
f01017ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		pp->pp_ref++;
		if (pp == page_free_list) page_free_list = pp->pp_link;
		tlb_invalidate(pgdir,va);		
		return 0;
	}
}
f01017b2:	83 c4 1c             	add    $0x1c,%esp
f01017b5:	5b                   	pop    %ebx
f01017b6:	5e                   	pop    %esi
f01017b7:	5f                   	pop    %edi
f01017b8:	5d                   	pop    %ebp
f01017b9:	c3                   	ret    

f01017ba <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01017ba:	55                   	push   %ebp
f01017bb:	89 e5                	mov    %esp,%ebp
f01017bd:	53                   	push   %ebx
f01017be:	83 ec 14             	sub    $0x14,%esp
f01017c1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD|PTE_PWT|PTE_W|PTE_P);
f01017c4:	c7 44 24 04 1b 00 00 	movl   $0x1b,0x4(%esp)
f01017cb:	00 
f01017cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01017cf:	89 04 24             	mov    %eax,(%esp)
f01017d2:	89 d9                	mov    %ebx,%ecx
f01017d4:	8b 15 00 23 12 f0    	mov    0xf0122300,%edx
f01017da:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01017df:	e8 96 fd ff ff       	call   f010157a <boot_map_region>
	void* ret = (void*)base;
f01017e4:	a1 00 23 12 f0       	mov    0xf0122300,%eax
	base += (uintptr_t)ROUNDUP(size,PGSIZE);
f01017e9:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
f01017ef:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01017f5:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f01017f8:	89 15 00 23 12 f0    	mov    %edx,0xf0122300
	if (base > MMIOLIM) {
f01017fe:	81 fa 00 00 c0 ef    	cmp    $0xefc00000,%edx
f0101804:	76 1c                	jbe    f0101822 <mmio_map_region+0x68>
		panic("MMIO OVERFLOW");
f0101806:	c7 44 24 08 3a 81 10 	movl   $0xf010813a,0x8(%esp)
f010180d:	f0 
f010180e:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0101815:	00 
f0101816:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010181d:	e8 1e e8 ff ff       	call   f0100040 <_panic>
	}
	return ret;
	//panic("mmio_map_region not implemented");
}
f0101822:	83 c4 14             	add    $0x14,%esp
f0101825:	5b                   	pop    %ebx
f0101826:	5d                   	pop    %ebp
f0101827:	c3                   	ret    

f0101828 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101828:	55                   	push   %ebp
f0101829:	89 e5                	mov    %esp,%ebp
f010182b:	57                   	push   %edi
f010182c:	56                   	push   %esi
f010182d:	53                   	push   %ebx
f010182e:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101831:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101838:	e8 64 29 00 00       	call   f01041a1 <mc146818_read>
f010183d:	89 c3                	mov    %eax,%ebx
f010183f:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101846:	e8 56 29 00 00       	call   f01041a1 <mc146818_read>
f010184b:	c1 e0 08             	shl    $0x8,%eax
f010184e:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101850:	89 d8                	mov    %ebx,%eax
f0101852:	c1 e0 0a             	shl    $0xa,%eax
f0101855:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010185b:	85 c0                	test   %eax,%eax
f010185d:	0f 48 c2             	cmovs  %edx,%eax
f0101860:	c1 f8 0c             	sar    $0xc,%eax
f0101863:	a3 44 32 23 f0       	mov    %eax,0xf0233244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101868:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010186f:	e8 2d 29 00 00       	call   f01041a1 <mc146818_read>
f0101874:	89 c3                	mov    %eax,%ebx
f0101876:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010187d:	e8 1f 29 00 00       	call   f01041a1 <mc146818_read>
f0101882:	c1 e0 08             	shl    $0x8,%eax
f0101885:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101887:	89 d8                	mov    %ebx,%eax
f0101889:	c1 e0 0a             	shl    $0xa,%eax
f010188c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101892:	85 c0                	test   %eax,%eax
f0101894:	0f 48 c2             	cmovs  %edx,%eax
f0101897:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010189a:	85 c0                	test   %eax,%eax
f010189c:	74 0e                	je     f01018ac <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010189e:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01018a4:	89 15 88 3e 23 f0    	mov    %edx,0xf0233e88
f01018aa:	eb 0c                	jmp    f01018b8 <mem_init+0x90>
	else
		npages = npages_basemem;
f01018ac:	8b 15 44 32 23 f0    	mov    0xf0233244,%edx
f01018b2:	89 15 88 3e 23 f0    	mov    %edx,0xf0233e88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01018b8:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01018bb:	c1 e8 0a             	shr    $0xa,%eax
f01018be:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01018c2:	a1 44 32 23 f0       	mov    0xf0233244,%eax
f01018c7:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01018ca:	c1 e8 0a             	shr    $0xa,%eax
f01018cd:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01018d1:	a1 88 3e 23 f0       	mov    0xf0233e88,%eax
f01018d6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01018d9:	c1 e8 0a             	shr    $0xa,%eax
f01018dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018e0:	c7 04 24 0c 78 10 f0 	movl   $0xf010780c,(%esp)
f01018e7:	e8 1e 2a 00 00       	call   f010430a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01018ec:	b8 00 10 00 00       	mov    $0x1000,%eax
f01018f1:	e8 1e f3 ff ff       	call   f0100c14 <boot_alloc>
f01018f6:	a3 8c 3e 23 f0       	mov    %eax,0xf0233e8c
	memset(kern_pgdir, 0, PGSIZE);
f01018fb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101902:	00 
f0101903:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010190a:	00 
f010190b:	89 04 24             	mov    %eax,(%esp)
f010190e:	e8 74 49 00 00       	call   f0106287 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101913:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101918:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010191d:	77 20                	ja     f010193f <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010191f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101923:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f010192a:	f0 
f010192b:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
f0101932:	00 
f0101933:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010193a:	e8 01 e7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010193f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101945:	83 ca 05             	or     $0x5,%edx
f0101948:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	size_t i;
	pages = (struct PageInfo*)boot_alloc(sizeof(struct PageInfo)*npages);
f010194e:	a1 88 3e 23 f0       	mov    0xf0233e88,%eax
f0101953:	c1 e0 03             	shl    $0x3,%eax
f0101956:	e8 b9 f2 ff ff       	call   f0100c14 <boot_alloc>
f010195b:	a3 90 3e 23 f0       	mov    %eax,0xf0233e90
	for(i=0;i<npages;i++) {
f0101960:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101965:	eb 23                	jmp    f010198a <mem_init+0x162>
		memset(pages+i,0,sizeof(struct PageInfo));
f0101967:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
f010196e:	00 
f010196f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101976:	00 
f0101977:	a1 90 3e 23 f0       	mov    0xf0233e90,%eax
f010197c:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f010197f:	89 04 24             	mov    %eax,(%esp)
f0101982:	e8 00 49 00 00       	call   f0106287 <memset>
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	size_t i;
	pages = (struct PageInfo*)boot_alloc(sizeof(struct PageInfo)*npages);
	for(i=0;i<npages;i++) {
f0101987:	83 c3 01             	add    $0x1,%ebx
f010198a:	3b 1d 88 3e 23 f0    	cmp    0xf0233e88,%ebx
f0101990:	72 d5                	jb     f0101967 <mem_init+0x13f>


	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(sizeof(struct Env)*NENV);
f0101992:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101997:	e8 78 f2 ff ff       	call   f0100c14 <boot_alloc>
f010199c:	a3 48 32 23 f0       	mov    %eax,0xf0233248
f01019a1:	bb 00 00 00 00       	mov    $0x0,%ebx
	for (i=0;i<NENV;i++) {
		memset(envs+i,0,sizeof(struct Env));
f01019a6:	c7 44 24 08 7c 00 00 	movl   $0x7c,0x8(%esp)
f01019ad:	00 
f01019ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019b5:	00 
f01019b6:	89 d8                	mov    %ebx,%eax
f01019b8:	03 05 48 32 23 f0    	add    0xf0233248,%eax
f01019be:	89 04 24             	mov    %eax,(%esp)
f01019c1:	e8 c1 48 00 00       	call   f0106287 <memset>
f01019c6:	83 c3 7c             	add    $0x7c,%ebx

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(sizeof(struct Env)*NENV);
	for (i=0;i<NENV;i++) {
f01019c9:	81 fb 00 f0 01 00    	cmp    $0x1f000,%ebx
f01019cf:	75 d5                	jne    f01019a6 <mem_init+0x17e>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01019d1:	e8 a7 f6 ff ff       	call   f010107d <page_init>

	check_page_free_list(1);
f01019d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01019db:	e8 f9 f2 ff ff       	call   f0100cd9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01019e0:	83 3d 90 3e 23 f0 00 	cmpl   $0x0,0xf0233e90
f01019e7:	75 1c                	jne    f0101a05 <mem_init+0x1dd>
		panic("'pages' is a null pointer!");
f01019e9:	c7 44 24 08 48 81 10 	movl   $0xf0108148,0x8(%esp)
f01019f0:	f0 
f01019f1:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f01019f8:	00 
f01019f9:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101a00:	e8 3b e6 ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101a05:	a1 40 32 23 f0       	mov    0xf0233240,%eax
f0101a0a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101a0f:	eb 05                	jmp    f0101a16 <mem_init+0x1ee>
		++nfree;
f0101a11:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101a14:	8b 00                	mov    (%eax),%eax
f0101a16:	85 c0                	test   %eax,%eax
f0101a18:	75 f7                	jne    f0101a11 <mem_init+0x1e9>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a1a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a21:	e8 51 f8 ff ff       	call   f0101277 <page_alloc>
f0101a26:	89 c7                	mov    %eax,%edi
f0101a28:	85 c0                	test   %eax,%eax
f0101a2a:	75 24                	jne    f0101a50 <mem_init+0x228>
f0101a2c:	c7 44 24 0c 63 81 10 	movl   $0xf0108163,0xc(%esp)
f0101a33:	f0 
f0101a34:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101a3b:	f0 
f0101a3c:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101a43:	00 
f0101a44:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101a4b:	e8 f0 e5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a50:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a57:	e8 1b f8 ff ff       	call   f0101277 <page_alloc>
f0101a5c:	89 c6                	mov    %eax,%esi
f0101a5e:	85 c0                	test   %eax,%eax
f0101a60:	75 24                	jne    f0101a86 <mem_init+0x25e>
f0101a62:	c7 44 24 0c 79 81 10 	movl   $0xf0108179,0xc(%esp)
f0101a69:	f0 
f0101a6a:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101a71:	f0 
f0101a72:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101a79:	00 
f0101a7a:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101a81:	e8 ba e5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a86:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a8d:	e8 e5 f7 ff ff       	call   f0101277 <page_alloc>
f0101a92:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a95:	85 c0                	test   %eax,%eax
f0101a97:	75 24                	jne    f0101abd <mem_init+0x295>
f0101a99:	c7 44 24 0c 8f 81 10 	movl   $0xf010818f,0xc(%esp)
f0101aa0:	f0 
f0101aa1:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101aa8:	f0 
f0101aa9:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101ab0:	00 
f0101ab1:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101ab8:	e8 83 e5 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101abd:	39 f7                	cmp    %esi,%edi
f0101abf:	75 24                	jne    f0101ae5 <mem_init+0x2bd>
f0101ac1:	c7 44 24 0c a5 81 10 	movl   $0xf01081a5,0xc(%esp)
f0101ac8:	f0 
f0101ac9:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101ad0:	f0 
f0101ad1:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101ad8:	00 
f0101ad9:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101ae0:	e8 5b e5 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ae5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ae8:	39 c6                	cmp    %eax,%esi
f0101aea:	74 04                	je     f0101af0 <mem_init+0x2c8>
f0101aec:	39 c7                	cmp    %eax,%edi
f0101aee:	75 24                	jne    f0101b14 <mem_init+0x2ec>
f0101af0:	c7 44 24 0c 48 78 10 	movl   $0xf0107848,0xc(%esp)
f0101af7:	f0 
f0101af8:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101aff:	f0 
f0101b00:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101b07:	00 
f0101b08:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101b0f:	e8 2c e5 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b14:	8b 15 90 3e 23 f0    	mov    0xf0233e90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101b1a:	a1 88 3e 23 f0       	mov    0xf0233e88,%eax
f0101b1f:	c1 e0 0c             	shl    $0xc,%eax
f0101b22:	89 f9                	mov    %edi,%ecx
f0101b24:	29 d1                	sub    %edx,%ecx
f0101b26:	c1 f9 03             	sar    $0x3,%ecx
f0101b29:	c1 e1 0c             	shl    $0xc,%ecx
f0101b2c:	39 c1                	cmp    %eax,%ecx
f0101b2e:	72 24                	jb     f0101b54 <mem_init+0x32c>
f0101b30:	c7 44 24 0c b7 81 10 	movl   $0xf01081b7,0xc(%esp)
f0101b37:	f0 
f0101b38:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101b3f:	f0 
f0101b40:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101b47:	00 
f0101b48:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101b4f:	e8 ec e4 ff ff       	call   f0100040 <_panic>
f0101b54:	89 f1                	mov    %esi,%ecx
f0101b56:	29 d1                	sub    %edx,%ecx
f0101b58:	c1 f9 03             	sar    $0x3,%ecx
f0101b5b:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101b5e:	39 c8                	cmp    %ecx,%eax
f0101b60:	77 24                	ja     f0101b86 <mem_init+0x35e>
f0101b62:	c7 44 24 0c d4 81 10 	movl   $0xf01081d4,0xc(%esp)
f0101b69:	f0 
f0101b6a:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101b71:	f0 
f0101b72:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101b79:	00 
f0101b7a:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101b81:	e8 ba e4 ff ff       	call   f0100040 <_panic>
f0101b86:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b89:	29 d1                	sub    %edx,%ecx
f0101b8b:	89 ca                	mov    %ecx,%edx
f0101b8d:	c1 fa 03             	sar    $0x3,%edx
f0101b90:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101b93:	39 d0                	cmp    %edx,%eax
f0101b95:	77 24                	ja     f0101bbb <mem_init+0x393>
f0101b97:	c7 44 24 0c f1 81 10 	movl   $0xf01081f1,0xc(%esp)
f0101b9e:	f0 
f0101b9f:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101ba6:	f0 
f0101ba7:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101bae:	00 
f0101baf:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101bb6:	e8 85 e4 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101bbb:	a1 40 32 23 f0       	mov    0xf0233240,%eax
f0101bc0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101bc3:	c7 05 40 32 23 f0 00 	movl   $0x0,0xf0233240
f0101bca:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101bcd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bd4:	e8 9e f6 ff ff       	call   f0101277 <page_alloc>
f0101bd9:	85 c0                	test   %eax,%eax
f0101bdb:	74 24                	je     f0101c01 <mem_init+0x3d9>
f0101bdd:	c7 44 24 0c 0e 82 10 	movl   $0xf010820e,0xc(%esp)
f0101be4:	f0 
f0101be5:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101bec:	f0 
f0101bed:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101bf4:	00 
f0101bf5:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101bfc:	e8 3f e4 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101c01:	89 3c 24             	mov    %edi,(%esp)
f0101c04:	e8 f9 f6 ff ff       	call   f0101302 <page_free>
	page_free(pp1);
f0101c09:	89 34 24             	mov    %esi,(%esp)
f0101c0c:	e8 f1 f6 ff ff       	call   f0101302 <page_free>
	page_free(pp2);
f0101c11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c14:	89 04 24             	mov    %eax,(%esp)
f0101c17:	e8 e6 f6 ff ff       	call   f0101302 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c1c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c23:	e8 4f f6 ff ff       	call   f0101277 <page_alloc>
f0101c28:	89 c6                	mov    %eax,%esi
f0101c2a:	85 c0                	test   %eax,%eax
f0101c2c:	75 24                	jne    f0101c52 <mem_init+0x42a>
f0101c2e:	c7 44 24 0c 63 81 10 	movl   $0xf0108163,0xc(%esp)
f0101c35:	f0 
f0101c36:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101c3d:	f0 
f0101c3e:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101c45:	00 
f0101c46:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101c4d:	e8 ee e3 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c59:	e8 19 f6 ff ff       	call   f0101277 <page_alloc>
f0101c5e:	89 c7                	mov    %eax,%edi
f0101c60:	85 c0                	test   %eax,%eax
f0101c62:	75 24                	jne    f0101c88 <mem_init+0x460>
f0101c64:	c7 44 24 0c 79 81 10 	movl   $0xf0108179,0xc(%esp)
f0101c6b:	f0 
f0101c6c:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101c73:	f0 
f0101c74:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101c7b:	00 
f0101c7c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101c83:	e8 b8 e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c8f:	e8 e3 f5 ff ff       	call   f0101277 <page_alloc>
f0101c94:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c97:	85 c0                	test   %eax,%eax
f0101c99:	75 24                	jne    f0101cbf <mem_init+0x497>
f0101c9b:	c7 44 24 0c 8f 81 10 	movl   $0xf010818f,0xc(%esp)
f0101ca2:	f0 
f0101ca3:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101caa:	f0 
f0101cab:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101cb2:	00 
f0101cb3:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101cba:	e8 81 e3 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101cbf:	39 fe                	cmp    %edi,%esi
f0101cc1:	75 24                	jne    f0101ce7 <mem_init+0x4bf>
f0101cc3:	c7 44 24 0c a5 81 10 	movl   $0xf01081a5,0xc(%esp)
f0101cca:	f0 
f0101ccb:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101cd2:	f0 
f0101cd3:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101cda:	00 
f0101cdb:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101ce2:	e8 59 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ce7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cea:	39 c7                	cmp    %eax,%edi
f0101cec:	74 04                	je     f0101cf2 <mem_init+0x4ca>
f0101cee:	39 c6                	cmp    %eax,%esi
f0101cf0:	75 24                	jne    f0101d16 <mem_init+0x4ee>
f0101cf2:	c7 44 24 0c 48 78 10 	movl   $0xf0107848,0xc(%esp)
f0101cf9:	f0 
f0101cfa:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101d01:	f0 
f0101d02:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101d09:	00 
f0101d0a:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101d11:	e8 2a e3 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101d16:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d1d:	e8 55 f5 ff ff       	call   f0101277 <page_alloc>
f0101d22:	85 c0                	test   %eax,%eax
f0101d24:	74 24                	je     f0101d4a <mem_init+0x522>
f0101d26:	c7 44 24 0c 0e 82 10 	movl   $0xf010820e,0xc(%esp)
f0101d2d:	f0 
f0101d2e:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101d35:	f0 
f0101d36:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101d3d:	00 
f0101d3e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101d45:	e8 f6 e2 ff ff       	call   f0100040 <_panic>
f0101d4a:	89 f0                	mov    %esi,%eax
f0101d4c:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f0101d52:	c1 f8 03             	sar    $0x3,%eax
f0101d55:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d58:	89 c2                	mov    %eax,%edx
f0101d5a:	c1 ea 0c             	shr    $0xc,%edx
f0101d5d:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f0101d63:	72 20                	jb     f0101d85 <mem_init+0x55d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d69:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0101d70:	f0 
f0101d71:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0101d78:	00 
f0101d79:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0101d80:	e8 bb e2 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101d85:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d8c:	00 
f0101d8d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101d94:	00 
	return (void *)(pa + KERNBASE);
f0101d95:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d9a:	89 04 24             	mov    %eax,(%esp)
f0101d9d:	e8 e5 44 00 00       	call   f0106287 <memset>
	page_free(pp0);
f0101da2:	89 34 24             	mov    %esi,(%esp)
f0101da5:	e8 58 f5 ff ff       	call   f0101302 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101daa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101db1:	e8 c1 f4 ff ff       	call   f0101277 <page_alloc>
f0101db6:	85 c0                	test   %eax,%eax
f0101db8:	75 24                	jne    f0101dde <mem_init+0x5b6>
f0101dba:	c7 44 24 0c 1d 82 10 	movl   $0xf010821d,0xc(%esp)
f0101dc1:	f0 
f0101dc2:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101dc9:	f0 
f0101dca:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101dd1:	00 
f0101dd2:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101dd9:	e8 62 e2 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101dde:	39 c6                	cmp    %eax,%esi
f0101de0:	74 24                	je     f0101e06 <mem_init+0x5de>
f0101de2:	c7 44 24 0c 3b 82 10 	movl   $0xf010823b,0xc(%esp)
f0101de9:	f0 
f0101dea:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101df1:	f0 
f0101df2:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101df9:	00 
f0101dfa:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101e01:	e8 3a e2 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e06:	89 f0                	mov    %esi,%eax
f0101e08:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f0101e0e:	c1 f8 03             	sar    $0x3,%eax
f0101e11:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e14:	89 c2                	mov    %eax,%edx
f0101e16:	c1 ea 0c             	shr    $0xc,%edx
f0101e19:	3b 15 88 3e 23 f0    	cmp    0xf0233e88,%edx
f0101e1f:	72 20                	jb     f0101e41 <mem_init+0x619>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e21:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e25:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0101e2c:	f0 
f0101e2d:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0101e34:	00 
f0101e35:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0101e3c:	e8 ff e1 ff ff       	call   f0100040 <_panic>
f0101e41:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101e47:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101e4d:	80 38 00             	cmpb   $0x0,(%eax)
f0101e50:	74 24                	je     f0101e76 <mem_init+0x64e>
f0101e52:	c7 44 24 0c 4b 82 10 	movl   $0xf010824b,0xc(%esp)
f0101e59:	f0 
f0101e5a:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101e61:	f0 
f0101e62:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101e69:	00 
f0101e6a:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101e71:	e8 ca e1 ff ff       	call   f0100040 <_panic>
f0101e76:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101e79:	39 d0                	cmp    %edx,%eax
f0101e7b:	75 d0                	jne    f0101e4d <mem_init+0x625>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101e7d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e80:	a3 40 32 23 f0       	mov    %eax,0xf0233240

	// free the pages we took
	page_free(pp0);
f0101e85:	89 34 24             	mov    %esi,(%esp)
f0101e88:	e8 75 f4 ff ff       	call   f0101302 <page_free>
	page_free(pp1);
f0101e8d:	89 3c 24             	mov    %edi,(%esp)
f0101e90:	e8 6d f4 ff ff       	call   f0101302 <page_free>
	page_free(pp2);
f0101e95:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e98:	89 04 24             	mov    %eax,(%esp)
f0101e9b:	e8 62 f4 ff ff       	call   f0101302 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ea0:	a1 40 32 23 f0       	mov    0xf0233240,%eax
f0101ea5:	eb 05                	jmp    f0101eac <mem_init+0x684>
		--nfree;
f0101ea7:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101eaa:	8b 00                	mov    (%eax),%eax
f0101eac:	85 c0                	test   %eax,%eax
f0101eae:	75 f7                	jne    f0101ea7 <mem_init+0x67f>
		--nfree;
	assert(nfree == 0);
f0101eb0:	85 db                	test   %ebx,%ebx
f0101eb2:	74 24                	je     f0101ed8 <mem_init+0x6b0>
f0101eb4:	c7 44 24 0c 55 82 10 	movl   $0xf0108255,0xc(%esp)
f0101ebb:	f0 
f0101ebc:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101ec3:	f0 
f0101ec4:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101ecb:	00 
f0101ecc:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101ed3:	e8 68 e1 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101ed8:	c7 04 24 68 78 10 f0 	movl   $0xf0107868,(%esp)
f0101edf:	e8 26 24 00 00       	call   f010430a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101ee4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101eeb:	e8 87 f3 ff ff       	call   f0101277 <page_alloc>
f0101ef0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101ef3:	85 c0                	test   %eax,%eax
f0101ef5:	75 24                	jne    f0101f1b <mem_init+0x6f3>
f0101ef7:	c7 44 24 0c 63 81 10 	movl   $0xf0108163,0xc(%esp)
f0101efe:	f0 
f0101eff:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101f06:	f0 
f0101f07:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0101f0e:	00 
f0101f0f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101f16:	e8 25 e1 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101f1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f22:	e8 50 f3 ff ff       	call   f0101277 <page_alloc>
f0101f27:	89 c6                	mov    %eax,%esi
f0101f29:	85 c0                	test   %eax,%eax
f0101f2b:	75 24                	jne    f0101f51 <mem_init+0x729>
f0101f2d:	c7 44 24 0c 79 81 10 	movl   $0xf0108179,0xc(%esp)
f0101f34:	f0 
f0101f35:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101f3c:	f0 
f0101f3d:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0101f44:	00 
f0101f45:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101f4c:	e8 ef e0 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101f51:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f58:	e8 1a f3 ff ff       	call   f0101277 <page_alloc>
f0101f5d:	89 c3                	mov    %eax,%ebx
f0101f5f:	85 c0                	test   %eax,%eax
f0101f61:	75 24                	jne    f0101f87 <mem_init+0x75f>
f0101f63:	c7 44 24 0c 8f 81 10 	movl   $0xf010818f,0xc(%esp)
f0101f6a:	f0 
f0101f6b:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101f72:	f0 
f0101f73:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0101f7a:	00 
f0101f7b:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101f82:	e8 b9 e0 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101f87:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101f8a:	75 24                	jne    f0101fb0 <mem_init+0x788>
f0101f8c:	c7 44 24 0c a5 81 10 	movl   $0xf01081a5,0xc(%esp)
f0101f93:	f0 
f0101f94:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101f9b:	f0 
f0101f9c:	c7 44 24 04 d5 03 00 	movl   $0x3d5,0x4(%esp)
f0101fa3:	00 
f0101fa4:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101fab:	e8 90 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101fb0:	39 c6                	cmp    %eax,%esi
f0101fb2:	74 05                	je     f0101fb9 <mem_init+0x791>
f0101fb4:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101fb7:	75 24                	jne    f0101fdd <mem_init+0x7b5>
f0101fb9:	c7 44 24 0c 48 78 10 	movl   $0xf0107848,0xc(%esp)
f0101fc0:	f0 
f0101fc1:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0101fc8:	f0 
f0101fc9:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0101fd0:	00 
f0101fd1:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0101fd8:	e8 63 e0 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101fdd:	a1 40 32 23 f0       	mov    0xf0233240,%eax
f0101fe2:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101fe5:	c7 05 40 32 23 f0 00 	movl   $0x0,0xf0233240
f0101fec:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101fef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ff6:	e8 7c f2 ff ff       	call   f0101277 <page_alloc>
f0101ffb:	85 c0                	test   %eax,%eax
f0101ffd:	74 24                	je     f0102023 <mem_init+0x7fb>
f0101fff:	c7 44 24 0c 0e 82 10 	movl   $0xf010820e,0xc(%esp)
f0102006:	f0 
f0102007:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010200e:	f0 
f010200f:	c7 44 24 04 dd 03 00 	movl   $0x3dd,0x4(%esp)
f0102016:	00 
f0102017:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010201e:	e8 1d e0 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102023:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102026:	89 44 24 08          	mov    %eax,0x8(%esp)
f010202a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102031:	00 
f0102032:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102037:	89 04 24             	mov    %eax,(%esp)
f010203a:	e8 a3 f5 ff ff       	call   f01015e2 <page_lookup>
f010203f:	85 c0                	test   %eax,%eax
f0102041:	74 24                	je     f0102067 <mem_init+0x83f>
f0102043:	c7 44 24 0c 88 78 10 	movl   $0xf0107888,0xc(%esp)
f010204a:	f0 
f010204b:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102052:	f0 
f0102053:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f010205a:	00 
f010205b:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102062:	e8 d9 df ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102067:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010206e:	00 
f010206f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102076:	00 
f0102077:	89 74 24 04          	mov    %esi,0x4(%esp)
f010207b:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102080:	89 04 24             	mov    %eax,(%esp)
f0102083:	e8 63 f6 ff ff       	call   f01016eb <page_insert>
f0102088:	85 c0                	test   %eax,%eax
f010208a:	78 24                	js     f01020b0 <mem_init+0x888>
f010208c:	c7 44 24 0c c0 78 10 	movl   $0xf01078c0,0xc(%esp)
f0102093:	f0 
f0102094:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010209b:	f0 
f010209c:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f01020a3:	00 
f01020a4:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01020ab:	e8 90 df ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01020b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b3:	89 04 24             	mov    %eax,(%esp)
f01020b6:	e8 47 f2 ff ff       	call   f0101302 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01020bb:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020c2:	00 
f01020c3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020ca:	00 
f01020cb:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020cf:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01020d4:	89 04 24             	mov    %eax,(%esp)
f01020d7:	e8 0f f6 ff ff       	call   f01016eb <page_insert>
f01020dc:	85 c0                	test   %eax,%eax
f01020de:	74 24                	je     f0102104 <mem_init+0x8dc>
f01020e0:	c7 44 24 0c f0 78 10 	movl   $0xf01078f0,0xc(%esp)
f01020e7:	f0 
f01020e8:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f01020f7:	00 
f01020f8:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01020ff:	e8 3c df ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102104:	8b 3d 8c 3e 23 f0    	mov    0xf0233e8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010210a:	a1 90 3e 23 f0       	mov    0xf0233e90,%eax
f010210f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102112:	8b 17                	mov    (%edi),%edx
f0102114:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010211a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010211d:	29 c1                	sub    %eax,%ecx
f010211f:	89 c8                	mov    %ecx,%eax
f0102121:	c1 f8 03             	sar    $0x3,%eax
f0102124:	c1 e0 0c             	shl    $0xc,%eax
f0102127:	39 c2                	cmp    %eax,%edx
f0102129:	74 24                	je     f010214f <mem_init+0x927>
f010212b:	c7 44 24 0c 20 79 10 	movl   $0xf0107920,0xc(%esp)
f0102132:	f0 
f0102133:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010213a:	f0 
f010213b:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f0102142:	00 
f0102143:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010214a:	e8 f1 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010214f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102154:	89 f8                	mov    %edi,%eax
f0102156:	e8 4a ea ff ff       	call   f0100ba5 <check_va2pa>
f010215b:	89 f2                	mov    %esi,%edx
f010215d:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0102160:	c1 fa 03             	sar    $0x3,%edx
f0102163:	c1 e2 0c             	shl    $0xc,%edx
f0102166:	39 d0                	cmp    %edx,%eax
f0102168:	74 24                	je     f010218e <mem_init+0x966>
f010216a:	c7 44 24 0c 48 79 10 	movl   $0xf0107948,0xc(%esp)
f0102171:	f0 
f0102172:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102179:	f0 
f010217a:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102181:	00 
f0102182:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102189:	e8 b2 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010218e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102193:	74 24                	je     f01021b9 <mem_init+0x991>
f0102195:	c7 44 24 0c 60 82 10 	movl   $0xf0108260,0xc(%esp)
f010219c:	f0 
f010219d:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01021a4:	f0 
f01021a5:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f01021ac:	00 
f01021ad:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01021b4:	e8 87 de ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01021b9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021bc:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021c1:	74 24                	je     f01021e7 <mem_init+0x9bf>
f01021c3:	c7 44 24 0c 71 82 10 	movl   $0xf0108271,0xc(%esp)
f01021ca:	f0 
f01021cb:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01021d2:	f0 
f01021d3:	c7 44 24 04 eb 03 00 	movl   $0x3eb,0x4(%esp)
f01021da:	00 
f01021db:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01021e2:	e8 59 de ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01021e7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021ee:	00 
f01021ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021f6:	00 
f01021f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021fb:	89 3c 24             	mov    %edi,(%esp)
f01021fe:	e8 e8 f4 ff ff       	call   f01016eb <page_insert>
f0102203:	85 c0                	test   %eax,%eax
f0102205:	74 24                	je     f010222b <mem_init+0xa03>
f0102207:	c7 44 24 0c 78 79 10 	movl   $0xf0107978,0xc(%esp)
f010220e:	f0 
f010220f:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102216:	f0 
f0102217:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f010221e:	00 
f010221f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102226:	e8 15 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010222b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102230:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102235:	e8 6b e9 ff ff       	call   f0100ba5 <check_va2pa>
f010223a:	89 da                	mov    %ebx,%edx
f010223c:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f0102242:	c1 fa 03             	sar    $0x3,%edx
f0102245:	c1 e2 0c             	shl    $0xc,%edx
f0102248:	39 d0                	cmp    %edx,%eax
f010224a:	74 24                	je     f0102270 <mem_init+0xa48>
f010224c:	c7 44 24 0c b4 79 10 	movl   $0xf01079b4,0xc(%esp)
f0102253:	f0 
f0102254:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010225b:	f0 
f010225c:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0102263:	00 
f0102264:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010226b:	e8 d0 dd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102270:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102275:	74 24                	je     f010229b <mem_init+0xa73>
f0102277:	c7 44 24 0c 82 82 10 	movl   $0xf0108282,0xc(%esp)
f010227e:	f0 
f010227f:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102286:	f0 
f0102287:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f010228e:	00 
f010228f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102296:	e8 a5 dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010229b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022a2:	e8 d0 ef ff ff       	call   f0101277 <page_alloc>
f01022a7:	85 c0                	test   %eax,%eax
f01022a9:	74 24                	je     f01022cf <mem_init+0xaa7>
f01022ab:	c7 44 24 0c 0e 82 10 	movl   $0xf010820e,0xc(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 04 f3 03 00 	movl   $0x3f3,0x4(%esp)
f01022c2:	00 
f01022c3:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01022ca:	e8 71 dd ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022cf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022d6:	00 
f01022d7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022de:	00 
f01022df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022e3:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01022e8:	89 04 24             	mov    %eax,(%esp)
f01022eb:	e8 fb f3 ff ff       	call   f01016eb <page_insert>
f01022f0:	85 c0                	test   %eax,%eax
f01022f2:	74 24                	je     f0102318 <mem_init+0xaf0>
f01022f4:	c7 44 24 0c 78 79 10 	movl   $0xf0107978,0xc(%esp)
f01022fb:	f0 
f01022fc:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102303:	f0 
f0102304:	c7 44 24 04 f6 03 00 	movl   $0x3f6,0x4(%esp)
f010230b:	00 
f010230c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102313:	e8 28 dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102318:	ba 00 10 00 00       	mov    $0x1000,%edx
f010231d:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102322:	e8 7e e8 ff ff       	call   f0100ba5 <check_va2pa>
f0102327:	89 da                	mov    %ebx,%edx
f0102329:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f010232f:	c1 fa 03             	sar    $0x3,%edx
f0102332:	c1 e2 0c             	shl    $0xc,%edx
f0102335:	39 d0                	cmp    %edx,%eax
f0102337:	74 24                	je     f010235d <mem_init+0xb35>
f0102339:	c7 44 24 0c b4 79 10 	movl   $0xf01079b4,0xc(%esp)
f0102340:	f0 
f0102341:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102348:	f0 
f0102349:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f0102350:	00 
f0102351:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102358:	e8 e3 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010235d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102362:	74 24                	je     f0102388 <mem_init+0xb60>
f0102364:	c7 44 24 0c 82 82 10 	movl   $0xf0108282,0xc(%esp)
f010236b:	f0 
f010236c:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102373:	f0 
f0102374:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f010237b:	00 
f010237c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102383:	e8 b8 dc ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102388:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010238f:	e8 e3 ee ff ff       	call   f0101277 <page_alloc>
f0102394:	85 c0                	test   %eax,%eax
f0102396:	74 24                	je     f01023bc <mem_init+0xb94>
f0102398:	c7 44 24 0c 0e 82 10 	movl   $0xf010820e,0xc(%esp)
f010239f:	f0 
f01023a0:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01023a7:	f0 
f01023a8:	c7 44 24 04 fc 03 00 	movl   $0x3fc,0x4(%esp)
f01023af:	00 
f01023b0:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01023b7:	e8 84 dc ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01023bc:	8b 15 8c 3e 23 f0    	mov    0xf0233e8c,%edx
f01023c2:	8b 02                	mov    (%edx),%eax
f01023c4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023c9:	89 c1                	mov    %eax,%ecx
f01023cb:	c1 e9 0c             	shr    $0xc,%ecx
f01023ce:	3b 0d 88 3e 23 f0    	cmp    0xf0233e88,%ecx
f01023d4:	72 20                	jb     f01023f6 <mem_init+0xbce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01023da:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f01023e1:	f0 
f01023e2:	c7 44 24 04 ff 03 00 	movl   $0x3ff,0x4(%esp)
f01023e9:	00 
f01023ea:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01023f1:	e8 4a dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01023f6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023fb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01023fe:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102405:	00 
f0102406:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010240d:	00 
f010240e:	89 14 24             	mov    %edx,(%esp)
f0102411:	e8 4f ef ff ff       	call   f0101365 <pgdir_walk>
f0102416:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102419:	8d 51 04             	lea    0x4(%ecx),%edx
f010241c:	39 d0                	cmp    %edx,%eax
f010241e:	74 24                	je     f0102444 <mem_init+0xc1c>
f0102420:	c7 44 24 0c e4 79 10 	movl   $0xf01079e4,0xc(%esp)
f0102427:	f0 
f0102428:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010242f:	f0 
f0102430:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
f0102437:	00 
f0102438:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010243f:	e8 fc db ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102444:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010244b:	00 
f010244c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102453:	00 
f0102454:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102458:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f010245d:	89 04 24             	mov    %eax,(%esp)
f0102460:	e8 86 f2 ff ff       	call   f01016eb <page_insert>
f0102465:	85 c0                	test   %eax,%eax
f0102467:	74 24                	je     f010248d <mem_init+0xc65>
f0102469:	c7 44 24 0c 24 7a 10 	movl   $0xf0107a24,0xc(%esp)
f0102470:	f0 
f0102471:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102478:	f0 
f0102479:	c7 44 24 04 03 04 00 	movl   $0x403,0x4(%esp)
f0102480:	00 
f0102481:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102488:	e8 b3 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010248d:	8b 3d 8c 3e 23 f0    	mov    0xf0233e8c,%edi
f0102493:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102498:	89 f8                	mov    %edi,%eax
f010249a:	e8 06 e7 ff ff       	call   f0100ba5 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010249f:	89 da                	mov    %ebx,%edx
f01024a1:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f01024a7:	c1 fa 03             	sar    $0x3,%edx
f01024aa:	c1 e2 0c             	shl    $0xc,%edx
f01024ad:	39 d0                	cmp    %edx,%eax
f01024af:	74 24                	je     f01024d5 <mem_init+0xcad>
f01024b1:	c7 44 24 0c b4 79 10 	movl   $0xf01079b4,0xc(%esp)
f01024b8:	f0 
f01024b9:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01024c0:	f0 
f01024c1:	c7 44 24 04 04 04 00 	movl   $0x404,0x4(%esp)
f01024c8:	00 
f01024c9:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01024d0:	e8 6b db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01024d5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024da:	74 24                	je     f0102500 <mem_init+0xcd8>
f01024dc:	c7 44 24 0c 82 82 10 	movl   $0xf0108282,0xc(%esp)
f01024e3:	f0 
f01024e4:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01024eb:	f0 
f01024ec:	c7 44 24 04 05 04 00 	movl   $0x405,0x4(%esp)
f01024f3:	00 
f01024f4:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01024fb:	e8 40 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102500:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102507:	00 
f0102508:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010250f:	00 
f0102510:	89 3c 24             	mov    %edi,(%esp)
f0102513:	e8 4d ee ff ff       	call   f0101365 <pgdir_walk>
f0102518:	f6 00 04             	testb  $0x4,(%eax)
f010251b:	75 24                	jne    f0102541 <mem_init+0xd19>
f010251d:	c7 44 24 0c 64 7a 10 	movl   $0xf0107a64,0xc(%esp)
f0102524:	f0 
f0102525:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010252c:	f0 
f010252d:	c7 44 24 04 06 04 00 	movl   $0x406,0x4(%esp)
f0102534:	00 
f0102535:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010253c:	e8 ff da ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102541:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102546:	f6 00 04             	testb  $0x4,(%eax)
f0102549:	75 24                	jne    f010256f <mem_init+0xd47>
f010254b:	c7 44 24 0c 93 82 10 	movl   $0xf0108293,0xc(%esp)
f0102552:	f0 
f0102553:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010255a:	f0 
f010255b:	c7 44 24 04 07 04 00 	movl   $0x407,0x4(%esp)
f0102562:	00 
f0102563:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010256a:	e8 d1 da ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010256f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102576:	00 
f0102577:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010257e:	00 
f010257f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102583:	89 04 24             	mov    %eax,(%esp)
f0102586:	e8 60 f1 ff ff       	call   f01016eb <page_insert>
f010258b:	85 c0                	test   %eax,%eax
f010258d:	74 24                	je     f01025b3 <mem_init+0xd8b>
f010258f:	c7 44 24 0c 78 79 10 	movl   $0xf0107978,0xc(%esp)
f0102596:	f0 
f0102597:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010259e:	f0 
f010259f:	c7 44 24 04 0a 04 00 	movl   $0x40a,0x4(%esp)
f01025a6:	00 
f01025a7:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01025ae:	e8 8d da ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01025b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01025ba:	00 
f01025bb:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025c2:	00 
f01025c3:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01025c8:	89 04 24             	mov    %eax,(%esp)
f01025cb:	e8 95 ed ff ff       	call   f0101365 <pgdir_walk>
f01025d0:	f6 00 02             	testb  $0x2,(%eax)
f01025d3:	75 24                	jne    f01025f9 <mem_init+0xdd1>
f01025d5:	c7 44 24 0c 98 7a 10 	movl   $0xf0107a98,0xc(%esp)
f01025dc:	f0 
f01025dd:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01025e4:	f0 
f01025e5:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f01025ec:	00 
f01025ed:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01025f4:	e8 47 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102600:	00 
f0102601:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102608:	00 
f0102609:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f010260e:	89 04 24             	mov    %eax,(%esp)
f0102611:	e8 4f ed ff ff       	call   f0101365 <pgdir_walk>
f0102616:	f6 00 04             	testb  $0x4,(%eax)
f0102619:	74 24                	je     f010263f <mem_init+0xe17>
f010261b:	c7 44 24 0c cc 7a 10 	movl   $0xf0107acc,0xc(%esp)
f0102622:	f0 
f0102623:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010262a:	f0 
f010262b:	c7 44 24 04 0c 04 00 	movl   $0x40c,0x4(%esp)
f0102632:	00 
f0102633:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010263a:	e8 01 da ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010263f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102646:	00 
f0102647:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f010264e:	00 
f010264f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102652:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102656:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f010265b:	89 04 24             	mov    %eax,(%esp)
f010265e:	e8 88 f0 ff ff       	call   f01016eb <page_insert>
f0102663:	85 c0                	test   %eax,%eax
f0102665:	78 24                	js     f010268b <mem_init+0xe63>
f0102667:	c7 44 24 0c 04 7b 10 	movl   $0xf0107b04,0xc(%esp)
f010266e:	f0 
f010266f:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102676:	f0 
f0102677:	c7 44 24 04 0f 04 00 	movl   $0x40f,0x4(%esp)
f010267e:	00 
f010267f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102686:	e8 b5 d9 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010268b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102692:	00 
f0102693:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010269a:	00 
f010269b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010269f:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01026a4:	89 04 24             	mov    %eax,(%esp)
f01026a7:	e8 3f f0 ff ff       	call   f01016eb <page_insert>
f01026ac:	85 c0                	test   %eax,%eax
f01026ae:	74 24                	je     f01026d4 <mem_init+0xeac>
f01026b0:	c7 44 24 0c 3c 7b 10 	movl   $0xf0107b3c,0xc(%esp)
f01026b7:	f0 
f01026b8:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01026bf:	f0 
f01026c0:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f01026c7:	00 
f01026c8:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01026cf:	e8 6c d9 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026d4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01026db:	00 
f01026dc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026e3:	00 
f01026e4:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01026e9:	89 04 24             	mov    %eax,(%esp)
f01026ec:	e8 74 ec ff ff       	call   f0101365 <pgdir_walk>
f01026f1:	f6 00 04             	testb  $0x4,(%eax)
f01026f4:	74 24                	je     f010271a <mem_init+0xef2>
f01026f6:	c7 44 24 0c cc 7a 10 	movl   $0xf0107acc,0xc(%esp)
f01026fd:	f0 
f01026fe:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102705:	f0 
f0102706:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f010270d:	00 
f010270e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102715:	e8 26 d9 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010271a:	8b 3d 8c 3e 23 f0    	mov    0xf0233e8c,%edi
f0102720:	ba 00 00 00 00       	mov    $0x0,%edx
f0102725:	89 f8                	mov    %edi,%eax
f0102727:	e8 79 e4 ff ff       	call   f0100ba5 <check_va2pa>
f010272c:	89 c1                	mov    %eax,%ecx
f010272e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102731:	89 f0                	mov    %esi,%eax
f0102733:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f0102739:	c1 f8 03             	sar    $0x3,%eax
f010273c:	c1 e0 0c             	shl    $0xc,%eax
f010273f:	39 c1                	cmp    %eax,%ecx
f0102741:	74 24                	je     f0102767 <mem_init+0xf3f>
f0102743:	c7 44 24 0c 78 7b 10 	movl   $0xf0107b78,0xc(%esp)
f010274a:	f0 
f010274b:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102752:	f0 
f0102753:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f010275a:	00 
f010275b:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102762:	e8 d9 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102767:	ba 00 10 00 00       	mov    $0x1000,%edx
f010276c:	89 f8                	mov    %edi,%eax
f010276e:	e8 32 e4 ff ff       	call   f0100ba5 <check_va2pa>
f0102773:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102776:	74 24                	je     f010279c <mem_init+0xf74>
f0102778:	c7 44 24 0c a4 7b 10 	movl   $0xf0107ba4,0xc(%esp)
f010277f:	f0 
f0102780:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102787:	f0 
f0102788:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f010278f:	00 
f0102790:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102797:	e8 a4 d8 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010279c:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f01027a1:	74 24                	je     f01027c7 <mem_init+0xf9f>
f01027a3:	c7 44 24 0c a9 82 10 	movl   $0xf01082a9,0xc(%esp)
f01027aa:	f0 
f01027ab:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01027b2:	f0 
f01027b3:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f01027ba:	00 
f01027bb:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01027c2:	e8 79 d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01027c7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01027cc:	74 24                	je     f01027f2 <mem_init+0xfca>
f01027ce:	c7 44 24 0c ba 82 10 	movl   $0xf01082ba,0xc(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01027dd:	f0 
f01027de:	c7 44 24 04 1a 04 00 	movl   $0x41a,0x4(%esp)
f01027e5:	00 
f01027e6:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01027ed:	e8 4e d8 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01027f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027f9:	e8 79 ea ff ff       	call   f0101277 <page_alloc>
f01027fe:	85 c0                	test   %eax,%eax
f0102800:	74 04                	je     f0102806 <mem_init+0xfde>
f0102802:	39 c3                	cmp    %eax,%ebx
f0102804:	74 24                	je     f010282a <mem_init+0x1002>
f0102806:	c7 44 24 0c d4 7b 10 	movl   $0xf0107bd4,0xc(%esp)
f010280d:	f0 
f010280e:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102815:	f0 
f0102816:	c7 44 24 04 1d 04 00 	movl   $0x41d,0x4(%esp)
f010281d:	00 
f010281e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102825:	e8 16 d8 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010282a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102831:	00 
f0102832:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102837:	89 04 24             	mov    %eax,(%esp)
f010283a:	e8 51 ee ff ff       	call   f0101690 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010283f:	8b 3d 8c 3e 23 f0    	mov    0xf0233e8c,%edi
f0102845:	ba 00 00 00 00       	mov    $0x0,%edx
f010284a:	89 f8                	mov    %edi,%eax
f010284c:	e8 54 e3 ff ff       	call   f0100ba5 <check_va2pa>
f0102851:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102854:	74 24                	je     f010287a <mem_init+0x1052>
f0102856:	c7 44 24 0c f8 7b 10 	movl   $0xf0107bf8,0xc(%esp)
f010285d:	f0 
f010285e:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102865:	f0 
f0102866:	c7 44 24 04 21 04 00 	movl   $0x421,0x4(%esp)
f010286d:	00 
f010286e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102875:	e8 c6 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010287a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010287f:	89 f8                	mov    %edi,%eax
f0102881:	e8 1f e3 ff ff       	call   f0100ba5 <check_va2pa>
f0102886:	89 f2                	mov    %esi,%edx
f0102888:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f010288e:	c1 fa 03             	sar    $0x3,%edx
f0102891:	c1 e2 0c             	shl    $0xc,%edx
f0102894:	39 d0                	cmp    %edx,%eax
f0102896:	74 24                	je     f01028bc <mem_init+0x1094>
f0102898:	c7 44 24 0c a4 7b 10 	movl   $0xf0107ba4,0xc(%esp)
f010289f:	f0 
f01028a0:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01028a7:	f0 
f01028a8:	c7 44 24 04 22 04 00 	movl   $0x422,0x4(%esp)
f01028af:	00 
f01028b0:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01028b7:	e8 84 d7 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01028bc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01028c1:	74 24                	je     f01028e7 <mem_init+0x10bf>
f01028c3:	c7 44 24 0c 60 82 10 	movl   $0xf0108260,0xc(%esp)
f01028ca:	f0 
f01028cb:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01028d2:	f0 
f01028d3:	c7 44 24 04 23 04 00 	movl   $0x423,0x4(%esp)
f01028da:	00 
f01028db:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01028e2:	e8 59 d7 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01028e7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01028ec:	74 24                	je     f0102912 <mem_init+0x10ea>
f01028ee:	c7 44 24 0c ba 82 10 	movl   $0xf01082ba,0xc(%esp)
f01028f5:	f0 
f01028f6:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01028fd:	f0 
f01028fe:	c7 44 24 04 24 04 00 	movl   $0x424,0x4(%esp)
f0102905:	00 
f0102906:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010290d:	e8 2e d7 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102912:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102919:	00 
f010291a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102921:	00 
f0102922:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102926:	89 3c 24             	mov    %edi,(%esp)
f0102929:	e8 bd ed ff ff       	call   f01016eb <page_insert>
f010292e:	85 c0                	test   %eax,%eax
f0102930:	74 24                	je     f0102956 <mem_init+0x112e>
f0102932:	c7 44 24 0c 1c 7c 10 	movl   $0xf0107c1c,0xc(%esp)
f0102939:	f0 
f010293a:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102941:	f0 
f0102942:	c7 44 24 04 27 04 00 	movl   $0x427,0x4(%esp)
f0102949:	00 
f010294a:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102951:	e8 ea d6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102956:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010295b:	75 24                	jne    f0102981 <mem_init+0x1159>
f010295d:	c7 44 24 0c cb 82 10 	movl   $0xf01082cb,0xc(%esp)
f0102964:	f0 
f0102965:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010296c:	f0 
f010296d:	c7 44 24 04 28 04 00 	movl   $0x428,0x4(%esp)
f0102974:	00 
f0102975:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010297c:	e8 bf d6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102981:	83 3e 00             	cmpl   $0x0,(%esi)
f0102984:	74 24                	je     f01029aa <mem_init+0x1182>
f0102986:	c7 44 24 0c d7 82 10 	movl   $0xf01082d7,0xc(%esp)
f010298d:	f0 
f010298e:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102995:	f0 
f0102996:	c7 44 24 04 29 04 00 	movl   $0x429,0x4(%esp)
f010299d:	00 
f010299e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01029a5:	e8 96 d6 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01029aa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01029b1:	00 
f01029b2:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01029b7:	89 04 24             	mov    %eax,(%esp)
f01029ba:	e8 d1 ec ff ff       	call   f0101690 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01029bf:	8b 3d 8c 3e 23 f0    	mov    0xf0233e8c,%edi
f01029c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01029ca:	89 f8                	mov    %edi,%eax
f01029cc:	e8 d4 e1 ff ff       	call   f0100ba5 <check_va2pa>
f01029d1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029d4:	74 24                	je     f01029fa <mem_init+0x11d2>
f01029d6:	c7 44 24 0c f8 7b 10 	movl   $0xf0107bf8,0xc(%esp)
f01029dd:	f0 
f01029de:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01029e5:	f0 
f01029e6:	c7 44 24 04 2d 04 00 	movl   $0x42d,0x4(%esp)
f01029ed:	00 
f01029ee:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01029f5:	e8 46 d6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01029fa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029ff:	89 f8                	mov    %edi,%eax
f0102a01:	e8 9f e1 ff ff       	call   f0100ba5 <check_va2pa>
f0102a06:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a09:	74 24                	je     f0102a2f <mem_init+0x1207>
f0102a0b:	c7 44 24 0c 54 7c 10 	movl   $0xf0107c54,0xc(%esp)
f0102a12:	f0 
f0102a13:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102a1a:	f0 
f0102a1b:	c7 44 24 04 2e 04 00 	movl   $0x42e,0x4(%esp)
f0102a22:	00 
f0102a23:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102a2a:	e8 11 d6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102a2f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102a34:	74 24                	je     f0102a5a <mem_init+0x1232>
f0102a36:	c7 44 24 0c ec 82 10 	movl   $0xf01082ec,0xc(%esp)
f0102a3d:	f0 
f0102a3e:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102a45:	f0 
f0102a46:	c7 44 24 04 2f 04 00 	movl   $0x42f,0x4(%esp)
f0102a4d:	00 
f0102a4e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102a55:	e8 e6 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102a5a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102a5f:	74 24                	je     f0102a85 <mem_init+0x125d>
f0102a61:	c7 44 24 0c ba 82 10 	movl   $0xf01082ba,0xc(%esp)
f0102a68:	f0 
f0102a69:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102a70:	f0 
f0102a71:	c7 44 24 04 30 04 00 	movl   $0x430,0x4(%esp)
f0102a78:	00 
f0102a79:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102a80:	e8 bb d5 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102a85:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a8c:	e8 e6 e7 ff ff       	call   f0101277 <page_alloc>
f0102a91:	85 c0                	test   %eax,%eax
f0102a93:	74 04                	je     f0102a99 <mem_init+0x1271>
f0102a95:	39 c6                	cmp    %eax,%esi
f0102a97:	74 24                	je     f0102abd <mem_init+0x1295>
f0102a99:	c7 44 24 0c 7c 7c 10 	movl   $0xf0107c7c,0xc(%esp)
f0102aa0:	f0 
f0102aa1:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102aa8:	f0 
f0102aa9:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f0102ab0:	00 
f0102ab1:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102ab8:	e8 83 d5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102abd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ac4:	e8 ae e7 ff ff       	call   f0101277 <page_alloc>
f0102ac9:	85 c0                	test   %eax,%eax
f0102acb:	74 24                	je     f0102af1 <mem_init+0x12c9>
f0102acd:	c7 44 24 0c 0e 82 10 	movl   $0xf010820e,0xc(%esp)
f0102ad4:	f0 
f0102ad5:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102adc:	f0 
f0102add:	c7 44 24 04 36 04 00 	movl   $0x436,0x4(%esp)
f0102ae4:	00 
f0102ae5:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102aec:	e8 4f d5 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102af1:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102af6:	8b 08                	mov    (%eax),%ecx
f0102af8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102afe:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102b01:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f0102b07:	c1 fa 03             	sar    $0x3,%edx
f0102b0a:	c1 e2 0c             	shl    $0xc,%edx
f0102b0d:	39 d1                	cmp    %edx,%ecx
f0102b0f:	74 24                	je     f0102b35 <mem_init+0x130d>
f0102b11:	c7 44 24 0c 20 79 10 	movl   $0xf0107920,0xc(%esp)
f0102b18:	f0 
f0102b19:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102b20:	f0 
f0102b21:	c7 44 24 04 39 04 00 	movl   $0x439,0x4(%esp)
f0102b28:	00 
f0102b29:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102b30:	e8 0b d5 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102b35:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102b3b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b3e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102b43:	74 24                	je     f0102b69 <mem_init+0x1341>
f0102b45:	c7 44 24 0c 71 82 10 	movl   $0xf0108271,0xc(%esp)
f0102b4c:	f0 
f0102b4d:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102b54:	f0 
f0102b55:	c7 44 24 04 3b 04 00 	movl   $0x43b,0x4(%esp)
f0102b5c:	00 
f0102b5d:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102b64:	e8 d7 d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102b69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b6c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102b72:	89 04 24             	mov    %eax,(%esp)
f0102b75:	e8 88 e7 ff ff       	call   f0101302 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102b7a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102b81:	00 
f0102b82:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102b89:	00 
f0102b8a:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102b8f:	89 04 24             	mov    %eax,(%esp)
f0102b92:	e8 ce e7 ff ff       	call   f0101365 <pgdir_walk>
f0102b97:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102b9d:	8b 15 8c 3e 23 f0    	mov    0xf0233e8c,%edx
f0102ba3:	8b 7a 04             	mov    0x4(%edx),%edi
f0102ba6:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bac:	8b 0d 88 3e 23 f0    	mov    0xf0233e88,%ecx
f0102bb2:	89 f8                	mov    %edi,%eax
f0102bb4:	c1 e8 0c             	shr    $0xc,%eax
f0102bb7:	39 c8                	cmp    %ecx,%eax
f0102bb9:	72 20                	jb     f0102bdb <mem_init+0x13b3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bbb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102bbf:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0102bc6:	f0 
f0102bc7:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f0102bce:	00 
f0102bcf:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102bd6:	e8 65 d4 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102bdb:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102be1:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0102be4:	74 24                	je     f0102c0a <mem_init+0x13e2>
f0102be6:	c7 44 24 0c fd 82 10 	movl   $0xf01082fd,0xc(%esp)
f0102bed:	f0 
f0102bee:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102bf5:	f0 
f0102bf6:	c7 44 24 04 43 04 00 	movl   $0x443,0x4(%esp)
f0102bfd:	00 
f0102bfe:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102c05:	e8 36 d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102c0a:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102c11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c14:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c1a:	2b 05 90 3e 23 f0    	sub    0xf0233e90,%eax
f0102c20:	c1 f8 03             	sar    $0x3,%eax
f0102c23:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c26:	89 c2                	mov    %eax,%edx
f0102c28:	c1 ea 0c             	shr    $0xc,%edx
f0102c2b:	39 d1                	cmp    %edx,%ecx
f0102c2d:	77 20                	ja     f0102c4f <mem_init+0x1427>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c33:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0102c3a:	f0 
f0102c3b:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0102c42:	00 
f0102c43:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0102c4a:	e8 f1 d3 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102c4f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c56:	00 
f0102c57:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102c5e:	00 
	return (void *)(pa + KERNBASE);
f0102c5f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c64:	89 04 24             	mov    %eax,(%esp)
f0102c67:	e8 1b 36 00 00       	call   f0106287 <memset>
	page_free(pp0);
f0102c6c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c6f:	89 3c 24             	mov    %edi,(%esp)
f0102c72:	e8 8b e6 ff ff       	call   f0101302 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102c77:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102c7e:	00 
f0102c7f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c86:	00 
f0102c87:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102c8c:	89 04 24             	mov    %eax,(%esp)
f0102c8f:	e8 d1 e6 ff ff       	call   f0101365 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c94:	89 fa                	mov    %edi,%edx
f0102c96:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f0102c9c:	c1 fa 03             	sar    $0x3,%edx
f0102c9f:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ca2:	89 d0                	mov    %edx,%eax
f0102ca4:	c1 e8 0c             	shr    $0xc,%eax
f0102ca7:	3b 05 88 3e 23 f0    	cmp    0xf0233e88,%eax
f0102cad:	72 20                	jb     f0102ccf <mem_init+0x14a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102caf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102cb3:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0102cba:	f0 
f0102cbb:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0102cc2:	00 
f0102cc3:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0102cca:	e8 71 d3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102ccf:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102cd5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102cd8:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102cde:	f6 00 01             	testb  $0x1,(%eax)
f0102ce1:	74 24                	je     f0102d07 <mem_init+0x14df>
f0102ce3:	c7 44 24 0c 15 83 10 	movl   $0xf0108315,0xc(%esp)
f0102cea:	f0 
f0102ceb:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102cf2:	f0 
f0102cf3:	c7 44 24 04 4d 04 00 	movl   $0x44d,0x4(%esp)
f0102cfa:	00 
f0102cfb:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102d02:	e8 39 d3 ff ff       	call   f0100040 <_panic>
f0102d07:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102d0a:	39 d0                	cmp    %edx,%eax
f0102d0c:	75 d0                	jne    f0102cde <mem_init+0x14b6>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102d0e:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102d13:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102d19:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d1c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102d22:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d25:	89 0d 40 32 23 f0    	mov    %ecx,0xf0233240

	// free the pages we took
	page_free(pp0);
f0102d2b:	89 04 24             	mov    %eax,(%esp)
f0102d2e:	e8 cf e5 ff ff       	call   f0101302 <page_free>
	page_free(pp1);
f0102d33:	89 34 24             	mov    %esi,(%esp)
f0102d36:	e8 c7 e5 ff ff       	call   f0101302 <page_free>
	page_free(pp2);
f0102d3b:	89 1c 24             	mov    %ebx,(%esp)
f0102d3e:	e8 bf e5 ff ff       	call   f0101302 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102d43:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102d4a:	00 
f0102d4b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d52:	e8 63 ea ff ff       	call   f01017ba <mmio_map_region>
f0102d57:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102d59:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102d60:	00 
f0102d61:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d68:	e8 4d ea ff ff       	call   f01017ba <mmio_map_region>
f0102d6d:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102d6f:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102d75:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102d7a:	77 08                	ja     f0102d84 <mem_init+0x155c>
f0102d7c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102d82:	77 24                	ja     f0102da8 <mem_init+0x1580>
f0102d84:	c7 44 24 0c a0 7c 10 	movl   $0xf0107ca0,0xc(%esp)
f0102d8b:	f0 
f0102d8c:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102d93:	f0 
f0102d94:	c7 44 24 04 5d 04 00 	movl   $0x45d,0x4(%esp)
f0102d9b:	00 
f0102d9c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102da3:	e8 98 d2 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102da8:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102dae:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102db4:	77 08                	ja     f0102dbe <mem_init+0x1596>
f0102db6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102dbc:	77 24                	ja     f0102de2 <mem_init+0x15ba>
f0102dbe:	c7 44 24 0c c8 7c 10 	movl   $0xf0107cc8,0xc(%esp)
f0102dc5:	f0 
f0102dc6:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102dcd:	f0 
f0102dce:	c7 44 24 04 5e 04 00 	movl   $0x45e,0x4(%esp)
f0102dd5:	00 
f0102dd6:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102ddd:	e8 5e d2 ff ff       	call   f0100040 <_panic>
f0102de2:	89 da                	mov    %ebx,%edx
f0102de4:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102de6:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102dec:	74 24                	je     f0102e12 <mem_init+0x15ea>
f0102dee:	c7 44 24 0c f0 7c 10 	movl   $0xf0107cf0,0xc(%esp)
f0102df5:	f0 
f0102df6:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102dfd:	f0 
f0102dfe:	c7 44 24 04 60 04 00 	movl   $0x460,0x4(%esp)
f0102e05:	00 
f0102e06:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102e0d:	e8 2e d2 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102e12:	39 c6                	cmp    %eax,%esi
f0102e14:	73 24                	jae    f0102e3a <mem_init+0x1612>
f0102e16:	c7 44 24 0c 2c 83 10 	movl   $0xf010832c,0xc(%esp)
f0102e1d:	f0 
f0102e1e:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102e25:	f0 
f0102e26:	c7 44 24 04 62 04 00 	movl   $0x462,0x4(%esp)
f0102e2d:	00 
f0102e2e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102e35:	e8 06 d2 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102e3a:	8b 3d 8c 3e 23 f0    	mov    0xf0233e8c,%edi
f0102e40:	89 da                	mov    %ebx,%edx
f0102e42:	89 f8                	mov    %edi,%eax
f0102e44:	e8 5c dd ff ff       	call   f0100ba5 <check_va2pa>
f0102e49:	85 c0                	test   %eax,%eax
f0102e4b:	74 24                	je     f0102e71 <mem_init+0x1649>
f0102e4d:	c7 44 24 0c 18 7d 10 	movl   $0xf0107d18,0xc(%esp)
f0102e54:	f0 
f0102e55:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102e5c:	f0 
f0102e5d:	c7 44 24 04 64 04 00 	movl   $0x464,0x4(%esp)
f0102e64:	00 
f0102e65:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102e6c:	e8 cf d1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102e71:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102e77:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102e7a:	89 c2                	mov    %eax,%edx
f0102e7c:	89 f8                	mov    %edi,%eax
f0102e7e:	e8 22 dd ff ff       	call   f0100ba5 <check_va2pa>
f0102e83:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102e88:	74 24                	je     f0102eae <mem_init+0x1686>
f0102e8a:	c7 44 24 0c 3c 7d 10 	movl   $0xf0107d3c,0xc(%esp)
f0102e91:	f0 
f0102e92:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102e99:	f0 
f0102e9a:	c7 44 24 04 65 04 00 	movl   $0x465,0x4(%esp)
f0102ea1:	00 
f0102ea2:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102ea9:	e8 92 d1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102eae:	89 f2                	mov    %esi,%edx
f0102eb0:	89 f8                	mov    %edi,%eax
f0102eb2:	e8 ee dc ff ff       	call   f0100ba5 <check_va2pa>
f0102eb7:	85 c0                	test   %eax,%eax
f0102eb9:	74 24                	je     f0102edf <mem_init+0x16b7>
f0102ebb:	c7 44 24 0c 6c 7d 10 	movl   $0xf0107d6c,0xc(%esp)
f0102ec2:	f0 
f0102ec3:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102eca:	f0 
f0102ecb:	c7 44 24 04 66 04 00 	movl   $0x466,0x4(%esp)
f0102ed2:	00 
f0102ed3:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102eda:	e8 61 d1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102edf:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102ee5:	89 f8                	mov    %edi,%eax
f0102ee7:	e8 b9 dc ff ff       	call   f0100ba5 <check_va2pa>
f0102eec:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102eef:	74 24                	je     f0102f15 <mem_init+0x16ed>
f0102ef1:	c7 44 24 0c 90 7d 10 	movl   $0xf0107d90,0xc(%esp)
f0102ef8:	f0 
f0102ef9:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102f00:	f0 
f0102f01:	c7 44 24 04 67 04 00 	movl   $0x467,0x4(%esp)
f0102f08:	00 
f0102f09:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102f10:	e8 2b d1 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102f15:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102f1c:	00 
f0102f1d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102f21:	89 3c 24             	mov    %edi,(%esp)
f0102f24:	e8 3c e4 ff ff       	call   f0101365 <pgdir_walk>
f0102f29:	f6 00 1a             	testb  $0x1a,(%eax)
f0102f2c:	75 24                	jne    f0102f52 <mem_init+0x172a>
f0102f2e:	c7 44 24 0c bc 7d 10 	movl   $0xf0107dbc,0xc(%esp)
f0102f35:	f0 
f0102f36:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102f3d:	f0 
f0102f3e:	c7 44 24 04 69 04 00 	movl   $0x469,0x4(%esp)
f0102f45:	00 
f0102f46:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102f4d:	e8 ee d0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102f52:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102f59:	00 
f0102f5a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102f5e:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102f63:	89 04 24             	mov    %eax,(%esp)
f0102f66:	e8 fa e3 ff ff       	call   f0101365 <pgdir_walk>
f0102f6b:	f6 00 04             	testb  $0x4,(%eax)
f0102f6e:	74 24                	je     f0102f94 <mem_init+0x176c>
f0102f70:	c7 44 24 0c 00 7e 10 	movl   $0xf0107e00,0xc(%esp)
f0102f77:	f0 
f0102f78:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0102f7f:	f0 
f0102f80:	c7 44 24 04 6a 04 00 	movl   $0x46a,0x4(%esp)
f0102f87:	00 
f0102f88:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0102f8f:	e8 ac d0 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102f94:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102f9b:	00 
f0102f9c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102fa0:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102fa5:	89 04 24             	mov    %eax,(%esp)
f0102fa8:	e8 b8 e3 ff ff       	call   f0101365 <pgdir_walk>
f0102fad:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102fb3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102fba:	00 
f0102fbb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fbe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fc2:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102fc7:	89 04 24             	mov    %eax,(%esp)
f0102fca:	e8 96 e3 ff ff       	call   f0101365 <pgdir_walk>
f0102fcf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102fd5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102fdc:	00 
f0102fdd:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fe1:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0102fe6:	89 04 24             	mov    %eax,(%esp)
f0102fe9:	e8 77 e3 ff ff       	call   f0101365 <pgdir_walk>
f0102fee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102ff4:	c7 04 24 3e 83 10 f0 	movl   $0xf010833e,(%esp)
f0102ffb:	e8 0a 13 00 00       	call   f010430a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,(uintptr_t)UPAGES,(size_t)ROUNDUP(sizeof(pages[0])*npages,PGSIZE),(physaddr_t)PADDR(pages),PTE_U|PTE_P);
f0103000:	a1 90 3e 23 f0       	mov    0xf0233e90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103005:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010300a:	77 20                	ja     f010302c <mem_init+0x1804>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010300c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103010:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103017:	f0 
f0103018:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
f010301f:	00 
f0103020:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103027:	e8 14 d0 ff ff       	call   f0100040 <_panic>
f010302c:	8b 15 88 3e 23 f0    	mov    0xf0233e88,%edx
f0103032:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0103039:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010303f:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0103046:	00 
	return (physaddr_t)kva - KERNBASE;
f0103047:	05 00 00 00 10       	add    $0x10000000,%eax
f010304c:	89 04 24             	mov    %eax,(%esp)
f010304f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0103054:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0103059:	e8 1c e5 ff ff       	call   f010157a <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, (uintptr_t)UENVS, (size_t)ROUNDUP(sizeof(envs[0])*NENV,PGSIZE), (physaddr_t)PADDR(envs), PTE_U|PTE_P);
f010305e:	a1 48 32 23 f0       	mov    0xf0233248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103063:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103068:	77 20                	ja     f010308a <mem_init+0x1862>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010306a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010306e:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103075:	f0 
f0103076:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f010307d:	00 
f010307e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103085:	e8 b6 cf ff ff       	call   f0100040 <_panic>
f010308a:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0103091:	00 
	return (physaddr_t)kva - KERNBASE;
f0103092:	05 00 00 00 10       	add    $0x10000000,%eax
f0103097:	89 04 24             	mov    %eax,(%esp)
f010309a:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f010309f:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01030a4:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01030a9:	e8 cc e4 ff ff       	call   f010157a <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ae:	b8 00 80 11 f0       	mov    $0xf0118000,%eax
f01030b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030b8:	77 20                	ja     f01030da <mem_init+0x18b2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030be:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f01030c5:	f0 
f01030c6:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
f01030cd:	00 
f01030ce:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01030d5:	e8 66 cf ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,(uintptr_t)KSTACKTOP-KSTKSIZE,(size_t)ROUNDUP(KSTKSIZE,PGSIZE),(physaddr_t)PADDR(bootstack),PTE_W);
f01030da:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01030e1:	00 
f01030e2:	c7 04 24 00 80 11 00 	movl   $0x118000,(%esp)
f01030e9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01030ee:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01030f3:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01030f8:	e8 7d e4 ff ff       	call   f010157a <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,(uintptr_t)KERNBASE,(size_t)ROUNDUP(0xFFFFFFFF-KERNBASE,PGSIZE),(physaddr_t)0,PTE_W);	
f01030fd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103104:	00 
f0103105:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010310c:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0103111:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103116:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f010311b:	e8 5a e4 ff ff       	call   f010157a <boot_map_region>
f0103120:	bf 00 50 27 f0       	mov    $0xf0275000,%edi
f0103125:	bb 00 50 23 f0       	mov    $0xf0235000,%ebx
f010312a:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010312f:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0103135:	77 20                	ja     f0103157 <mem_init+0x192f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103137:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010313b:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103142:	f0 
f0103143:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
f010314a:	00 
f010314b:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103152:	e8 e9 ce ff ff       	call   f0100040 <_panic>
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	int i;
	for(i=0;i<NCPU;i++) {
		boot_map_region(kern_pgdir,(uintptr_t)(KSTACKTOP-i*(KSTKSIZE+KSTKGAP)-KSTKSIZE),KSTKSIZE,(physaddr_t)PADDR(percpu_kstacks[i]),PTE_W);
f0103157:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010315e:	00 
f010315f:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0103165:	89 04 24             	mov    %eax,(%esp)
f0103168:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010316d:	89 f2                	mov    %esi,%edx
f010316f:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0103174:	e8 01 e4 ff ff       	call   f010157a <boot_map_region>
f0103179:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f010317f:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	int i;
	for(i=0;i<NCPU;i++) {
f0103185:	39 fb                	cmp    %edi,%ebx
f0103187:	75 a6                	jne    f010312f <mem_init+0x1907>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0103189:	8b 3d 8c 3e 23 f0    	mov    0xf0233e8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010318f:	a1 88 3e 23 f0       	mov    0xf0233e88,%eax
f0103194:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103197:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010319e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01031a3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE) {
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01031a6:	8b 35 90 3e 23 f0    	mov    0xf0233e90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031ac:	89 75 cc             	mov    %esi,-0x34(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f01031af:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01031b5:	89 45 c8             	mov    %eax,-0x38(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f01031b8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01031bd:	eb 6a                	jmp    f0103229 <mem_init+0x1a01>
f01031bf:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01031c5:	89 f8                	mov    %edi,%eax
f01031c7:	e8 d9 d9 ff ff       	call   f0100ba5 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031cc:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01031d3:	77 20                	ja     f01031f5 <mem_init+0x19cd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031d5:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01031d9:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f01031e0:	f0 
f01031e1:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f01031e8:	00 
f01031e9:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01031f0:	e8 4b ce ff ff       	call   f0100040 <_panic>
f01031f5:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01031f8:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f01031fb:	39 d0                	cmp    %edx,%eax
f01031fd:	74 24                	je     f0103223 <mem_init+0x19fb>
f01031ff:	c7 44 24 0c 34 7e 10 	movl   $0xf0107e34,0xc(%esp)
f0103206:	f0 
f0103207:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010320e:	f0 
f010320f:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0103216:	00 
f0103217:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010321e:	e8 1d ce ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f0103223:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103229:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f010322c:	77 91                	ja     f01031bf <mem_init+0x1997>
	}

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010322e:	8b 1d 48 32 23 f0    	mov    0xf0233248,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103234:	89 de                	mov    %ebx,%esi
f0103236:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010323b:	89 f8                	mov    %edi,%eax
f010323d:	e8 63 d9 ff ff       	call   f0100ba5 <check_va2pa>
f0103242:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0103248:	77 20                	ja     f010326a <mem_init+0x1a42>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010324a:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010324e:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103255:	f0 
f0103256:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010325d:	00 
f010325e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103265:	e8 d6 cd ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010326a:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f010326f:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0103275:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0103278:	39 d0                	cmp    %edx,%eax
f010327a:	74 24                	je     f01032a0 <mem_init+0x1a78>
f010327c:	c7 44 24 0c 68 7e 10 	movl   $0xf0107e68,0xc(%esp)
f0103283:	f0 
f0103284:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010328b:	f0 
f010328c:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0103293:	00 
f0103294:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010329b:	e8 a0 cd ff ff       	call   f0100040 <_panic>
f01032a0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01032a6:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01032ac:	0f 85 a8 05 00 00    	jne    f010385a <mem_init+0x2032>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE){
f01032b2:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01032b5:	c1 e6 0c             	shl    $0xc,%esi
f01032b8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01032bd:	eb 3b                	jmp    f01032fa <mem_init+0x1ad2>
f01032bf:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01032c5:	89 f8                	mov    %edi,%eax
f01032c7:	e8 d9 d8 ff ff       	call   f0100ba5 <check_va2pa>
f01032cc:	39 c3                	cmp    %eax,%ebx
f01032ce:	74 24                	je     f01032f4 <mem_init+0x1acc>
f01032d0:	c7 44 24 0c 9c 7e 10 	movl   $0xf0107e9c,0xc(%esp)
f01032d7:	f0 
f01032d8:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01032df:	f0 
f01032e0:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f01032e7:	00 
f01032e8:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01032ef:	e8 4c cd ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE){
f01032f4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01032fa:	39 f3                	cmp    %esi,%ebx
f01032fc:	72 c1                	jb     f01032bf <mem_init+0x1a97>
f01032fe:	c7 45 d0 00 50 23 f0 	movl   $0xf0235000,-0x30(%ebp)
f0103305:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f010330c:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0103311:	b8 00 50 23 f0       	mov    $0xf0235000,%eax
f0103316:	05 00 80 00 20       	add    $0x20008000,%eax
f010331b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010331e:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0103324:	89 45 cc             	mov    %eax,-0x34(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE) {
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0103327:	89 f2                	mov    %esi,%edx
f0103329:	89 f8                	mov    %edi,%eax
f010332b:	e8 75 d8 ff ff       	call   f0100ba5 <check_va2pa>
f0103330:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103333:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0103339:	77 20                	ja     f010335b <mem_init+0x1b33>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010333b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010333f:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103346:	f0 
f0103347:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f010334e:	00 
f010334f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103356:	e8 e5 cc ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010335b:	89 f3                	mov    %esi,%ebx
f010335d:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103360:	03 4d d4             	add    -0x2c(%ebp),%ecx
f0103363:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103366:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103369:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f010336c:	39 d0                	cmp    %edx,%eax
f010336e:	74 24                	je     f0103394 <mem_init+0x1b6c>
f0103370:	c7 44 24 0c c4 7e 10 	movl   $0xf0107ec4,0xc(%esp)
f0103377:	f0 
f0103378:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010337f:	f0 
f0103380:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0103387:	00 
f0103388:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010338f:	e8 ac cc ff ff       	call   f0100040 <_panic>
f0103394:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE) {
f010339a:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f010339d:	0f 85 a9 04 00 00    	jne    f010384c <mem_init+0x2024>
f01033a3:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		}
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01033a9:	89 da                	mov    %ebx,%edx
f01033ab:	89 f8                	mov    %edi,%eax
f01033ad:	e8 f3 d7 ff ff       	call   f0100ba5 <check_va2pa>
f01033b2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01033b5:	74 24                	je     f01033db <mem_init+0x1bb3>
f01033b7:	c7 44 24 0c 0c 7f 10 	movl   $0xf0107f0c,0xc(%esp)
f01033be:	f0 
f01033bf:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01033c6:	f0 
f01033c7:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f01033ce:	00 
f01033cf:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01033d6:	e8 65 cc ff ff       	call   f0100040 <_panic>
f01033db:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE) {
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		}
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01033e1:	39 de                	cmp    %ebx,%esi
f01033e3:	75 c4                	jne    f01033a9 <mem_init+0x1b81>
f01033e5:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f01033eb:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f01033f2:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
	}

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f01033f9:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f01033ff:	0f 85 19 ff ff ff    	jne    f010331e <mem_init+0x1af6>
f0103405:	b8 00 00 00 00       	mov    $0x0,%eax
f010340a:	e9 c2 00 00 00       	jmp    f01034d1 <mem_init+0x1ca9>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010340f:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0103415:	83 fa 04             	cmp    $0x4,%edx
f0103418:	77 2e                	ja     f0103448 <mem_init+0x1c20>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010341a:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010341e:	0f 85 aa 00 00 00    	jne    f01034ce <mem_init+0x1ca6>
f0103424:	c7 44 24 0c 57 83 10 	movl   $0xf0108357,0xc(%esp)
f010342b:	f0 
f010342c:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0103433:	f0 
f0103434:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f010343b:	00 
f010343c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103443:	e8 f8 cb ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0103448:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010344d:	76 55                	jbe    f01034a4 <mem_init+0x1c7c>
				assert(pgdir[i] & PTE_P);
f010344f:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103452:	f6 c2 01             	test   $0x1,%dl
f0103455:	75 24                	jne    f010347b <mem_init+0x1c53>
f0103457:	c7 44 24 0c 57 83 10 	movl   $0xf0108357,0xc(%esp)
f010345e:	f0 
f010345f:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0103466:	f0 
f0103467:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f010346e:	00 
f010346f:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103476:	e8 c5 cb ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010347b:	f6 c2 02             	test   $0x2,%dl
f010347e:	75 4e                	jne    f01034ce <mem_init+0x1ca6>
f0103480:	c7 44 24 0c 68 83 10 	movl   $0xf0108368,0xc(%esp)
f0103487:	f0 
f0103488:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010348f:	f0 
f0103490:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0103497:	00 
f0103498:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010349f:	e8 9c cb ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01034a4:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01034a8:	74 24                	je     f01034ce <mem_init+0x1ca6>
f01034aa:	c7 44 24 0c 79 83 10 	movl   $0xf0108379,0xc(%esp)
f01034b1:	f0 
f01034b2:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01034b9:	f0 
f01034ba:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f01034c1:	00 
f01034c2:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01034c9:	e8 72 cb ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01034ce:	83 c0 01             	add    $0x1,%eax
f01034d1:	3d 00 04 00 00       	cmp    $0x400,%eax
f01034d6:	0f 85 33 ff ff ff    	jne    f010340f <mem_init+0x1be7>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01034dc:	c7 04 24 30 7f 10 f0 	movl   $0xf0107f30,(%esp)
f01034e3:	e8 22 0e 00 00       	call   f010430a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01034e8:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01034ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034f2:	77 20                	ja     f0103514 <mem_init+0x1cec>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034f8:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f01034ff:	f0 
f0103500:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
f0103507:	00 
f0103508:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010350f:	e8 2c cb ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103514:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103519:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010351c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103521:	e8 b3 d7 ff ff       	call   f0100cd9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0103526:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0103529:	83 e0 f3             	and    $0xfffffff3,%eax
f010352c:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0103531:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0103534:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010353b:	e8 37 dd ff ff       	call   f0101277 <page_alloc>
f0103540:	89 c3                	mov    %eax,%ebx
f0103542:	85 c0                	test   %eax,%eax
f0103544:	75 24                	jne    f010356a <mem_init+0x1d42>
f0103546:	c7 44 24 0c 63 81 10 	movl   $0xf0108163,0xc(%esp)
f010354d:	f0 
f010354e:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0103555:	f0 
f0103556:	c7 44 24 04 7f 04 00 	movl   $0x47f,0x4(%esp)
f010355d:	00 
f010355e:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103565:	e8 d6 ca ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010356a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103571:	e8 01 dd ff ff       	call   f0101277 <page_alloc>
f0103576:	89 c7                	mov    %eax,%edi
f0103578:	85 c0                	test   %eax,%eax
f010357a:	75 24                	jne    f01035a0 <mem_init+0x1d78>
f010357c:	c7 44 24 0c 79 81 10 	movl   $0xf0108179,0xc(%esp)
f0103583:	f0 
f0103584:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010358b:	f0 
f010358c:	c7 44 24 04 80 04 00 	movl   $0x480,0x4(%esp)
f0103593:	00 
f0103594:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010359b:	e8 a0 ca ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01035a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01035a7:	e8 cb dc ff ff       	call   f0101277 <page_alloc>
f01035ac:	89 c6                	mov    %eax,%esi
f01035ae:	85 c0                	test   %eax,%eax
f01035b0:	75 24                	jne    f01035d6 <mem_init+0x1dae>
f01035b2:	c7 44 24 0c 8f 81 10 	movl   $0xf010818f,0xc(%esp)
f01035b9:	f0 
f01035ba:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01035c1:	f0 
f01035c2:	c7 44 24 04 81 04 00 	movl   $0x481,0x4(%esp)
f01035c9:	00 
f01035ca:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01035d1:	e8 6a ca ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01035d6:	89 1c 24             	mov    %ebx,(%esp)
f01035d9:	e8 24 dd ff ff       	call   f0101302 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01035de:	89 f8                	mov    %edi,%eax
f01035e0:	e8 7b d5 ff ff       	call   f0100b60 <page2kva>
f01035e5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01035ec:	00 
f01035ed:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01035f4:	00 
f01035f5:	89 04 24             	mov    %eax,(%esp)
f01035f8:	e8 8a 2c 00 00       	call   f0106287 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01035fd:	89 f0                	mov    %esi,%eax
f01035ff:	e8 5c d5 ff ff       	call   f0100b60 <page2kva>
f0103604:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010360b:	00 
f010360c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103613:	00 
f0103614:	89 04 24             	mov    %eax,(%esp)
f0103617:	e8 6b 2c 00 00       	call   f0106287 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010361c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103623:	00 
f0103624:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010362b:	00 
f010362c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103630:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0103635:	89 04 24             	mov    %eax,(%esp)
f0103638:	e8 ae e0 ff ff       	call   f01016eb <page_insert>
	assert(pp1->pp_ref == 1);
f010363d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103642:	74 24                	je     f0103668 <mem_init+0x1e40>
f0103644:	c7 44 24 0c 60 82 10 	movl   $0xf0108260,0xc(%esp)
f010364b:	f0 
f010364c:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0103653:	f0 
f0103654:	c7 44 24 04 86 04 00 	movl   $0x486,0x4(%esp)
f010365b:	00 
f010365c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103663:	e8 d8 c9 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103668:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010366f:	01 01 01 
f0103672:	74 24                	je     f0103698 <mem_init+0x1e70>
f0103674:	c7 44 24 0c 50 7f 10 	movl   $0xf0107f50,0xc(%esp)
f010367b:	f0 
f010367c:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0103683:	f0 
f0103684:	c7 44 24 04 87 04 00 	movl   $0x487,0x4(%esp)
f010368b:	00 
f010368c:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103693:	e8 a8 c9 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103698:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010369f:	00 
f01036a0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01036a7:	00 
f01036a8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036ac:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01036b1:	89 04 24             	mov    %eax,(%esp)
f01036b4:	e8 32 e0 ff ff       	call   f01016eb <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01036b9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01036c0:	02 02 02 
f01036c3:	74 24                	je     f01036e9 <mem_init+0x1ec1>
f01036c5:	c7 44 24 0c 74 7f 10 	movl   $0xf0107f74,0xc(%esp)
f01036cc:	f0 
f01036cd:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01036d4:	f0 
f01036d5:	c7 44 24 04 89 04 00 	movl   $0x489,0x4(%esp)
f01036dc:	00 
f01036dd:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01036e4:	e8 57 c9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01036e9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01036ee:	74 24                	je     f0103714 <mem_init+0x1eec>
f01036f0:	c7 44 24 0c 82 82 10 	movl   $0xf0108282,0xc(%esp)
f01036f7:	f0 
f01036f8:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01036ff:	f0 
f0103700:	c7 44 24 04 8a 04 00 	movl   $0x48a,0x4(%esp)
f0103707:	00 
f0103708:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010370f:	e8 2c c9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103714:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103719:	74 24                	je     f010373f <mem_init+0x1f17>
f010371b:	c7 44 24 0c ec 82 10 	movl   $0xf01082ec,0xc(%esp)
f0103722:	f0 
f0103723:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010372a:	f0 
f010372b:	c7 44 24 04 8b 04 00 	movl   $0x48b,0x4(%esp)
f0103732:	00 
f0103733:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010373a:	e8 01 c9 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010373f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0103746:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103749:	89 f0                	mov    %esi,%eax
f010374b:	e8 10 d4 ff ff       	call   f0100b60 <page2kva>
f0103750:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0103756:	74 24                	je     f010377c <mem_init+0x1f54>
f0103758:	c7 44 24 0c 98 7f 10 	movl   $0xf0107f98,0xc(%esp)
f010375f:	f0 
f0103760:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0103767:	f0 
f0103768:	c7 44 24 04 8d 04 00 	movl   $0x48d,0x4(%esp)
f010376f:	00 
f0103770:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f0103777:	e8 c4 c8 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010377c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103783:	00 
f0103784:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0103789:	89 04 24             	mov    %eax,(%esp)
f010378c:	e8 ff de ff ff       	call   f0101690 <page_remove>
	assert(pp2->pp_ref == 0);
f0103791:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0103796:	74 24                	je     f01037bc <mem_init+0x1f94>
f0103798:	c7 44 24 0c ba 82 10 	movl   $0xf01082ba,0xc(%esp)
f010379f:	f0 
f01037a0:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01037a7:	f0 
f01037a8:	c7 44 24 04 8f 04 00 	movl   $0x48f,0x4(%esp)
f01037af:	00 
f01037b0:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01037b7:	e8 84 c8 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01037bc:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f01037c1:	8b 08                	mov    (%eax),%ecx
f01037c3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01037c9:	89 da                	mov    %ebx,%edx
f01037cb:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f01037d1:	c1 fa 03             	sar    $0x3,%edx
f01037d4:	c1 e2 0c             	shl    $0xc,%edx
f01037d7:	39 d1                	cmp    %edx,%ecx
f01037d9:	74 24                	je     f01037ff <mem_init+0x1fd7>
f01037db:	c7 44 24 0c 20 79 10 	movl   $0xf0107920,0xc(%esp)
f01037e2:	f0 
f01037e3:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01037ea:	f0 
f01037eb:	c7 44 24 04 92 04 00 	movl   $0x492,0x4(%esp)
f01037f2:	00 
f01037f3:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f01037fa:	e8 41 c8 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01037ff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103805:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010380a:	74 24                	je     f0103830 <mem_init+0x2008>
f010380c:	c7 44 24 0c 71 82 10 	movl   $0xf0108271,0xc(%esp)
f0103813:	f0 
f0103814:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f010381b:	f0 
f010381c:	c7 44 24 04 94 04 00 	movl   $0x494,0x4(%esp)
f0103823:	00 
f0103824:	c7 04 24 33 80 10 f0 	movl   $0xf0108033,(%esp)
f010382b:	e8 10 c8 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0103830:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103836:	89 1c 24             	mov    %ebx,(%esp)
f0103839:	e8 c4 da ff ff       	call   f0101302 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010383e:	c7 04 24 c4 7f 10 f0 	movl   $0xf0107fc4,(%esp)
f0103845:	e8 c0 0a 00 00       	call   f010430a <cprintf>
f010384a:	eb 1c                	jmp    f0103868 <mem_init+0x2040>
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE) {
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010384c:	89 da                	mov    %ebx,%edx
f010384e:	89 f8                	mov    %edi,%eax
f0103850:	e8 50 d3 ff ff       	call   f0100ba5 <check_va2pa>
f0103855:	e9 0c fb ff ff       	jmp    f0103366 <mem_init+0x1b3e>
	}

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010385a:	89 da                	mov    %ebx,%edx
f010385c:	89 f8                	mov    %edi,%eax
f010385e:	e8 42 d3 ff ff       	call   f0100ba5 <check_va2pa>
f0103863:	e9 0d fa ff ff       	jmp    f0103275 <mem_init+0x1a4d>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0103868:	83 c4 4c             	add    $0x4c,%esp
f010386b:	5b                   	pop    %ebx
f010386c:	5e                   	pop    %esi
f010386d:	5f                   	pop    %edi
f010386e:	5d                   	pop    %ebp
f010386f:	c3                   	ret    

f0103870 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0103870:	55                   	push   %ebp
f0103871:	89 e5                	mov    %esp,%ebp
f0103873:	57                   	push   %edi
f0103874:	56                   	push   %esi
f0103875:	53                   	push   %ebx
f0103876:	83 ec 2c             	sub    $0x2c,%esp
f0103879:	8b 7d 08             	mov    0x8(%ebp),%edi
f010387c:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t la = (uint32_t)ROUNDDOWN(va,PGSIZE);
f010387f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103882:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103887:	89 c3                	mov    %eax,%ebx
f0103889:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t ela = (uint32_t)ROUNDUP(va+len,PGSIZE);
f010388c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010388f:	03 45 10             	add    0x10(%ebp),%eax
f0103892:	05 ff 0f 00 00       	add    $0xfff,%eax
f0103897:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010389c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(;la<ela;la+=PGSIZE) {
f010389f:	eb 77                	jmp    f0103918 <user_mem_check+0xa8>
		if (la >= ULIM) {
f01038a1:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01038a7:	76 14                	jbe    f01038bd <user_mem_check+0x4d>
			//cprintf("la: %p beyond ULIM: %p",la,ULIM);
			user_mem_check_addr = (la == (uint32_t)ROUNDDOWN(va,PGSIZE))?(uint32_t)va:la;
f01038a9:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f01038ac:	0f 44 5d 0c          	cmove  0xc(%ebp),%ebx
f01038b0:	89 1d 3c 32 23 f0    	mov    %ebx,0xf023323c
			return -E_FAULT;
f01038b6:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01038bb:	eb 65                	jmp    f0103922 <user_mem_check+0xb2>
		}
		pde_t pde = env->env_pgdir[PDX(la)];
f01038bd:	8b 47 60             	mov    0x60(%edi),%eax
f01038c0:	89 da                	mov    %ebx,%edx
f01038c2:	c1 ea 16             	shr    $0x16,%edx
		if ((pde&perm) != perm) {
f01038c5:	89 f1                	mov    %esi,%ecx
f01038c7:	23 0c 90             	and    (%eax,%edx,4),%ecx
f01038ca:	39 ce                	cmp    %ecx,%esi
f01038cc:	74 14                	je     f01038e2 <user_mem_check+0x72>
			//cprintf("PD protected.%s,%s",(pde&PTE_U)?"User":"Kernel",(pde&PTE_P)?"Present":"Not present");
			user_mem_check_addr = (la == (uint32_t)ROUNDDOWN(va,PGSIZE))?(uint32_t)va:la;
f01038ce:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f01038d1:	0f 44 5d 0c          	cmove  0xc(%ebp),%ebx
f01038d5:	89 1d 3c 32 23 f0    	mov    %ebx,0xf023323c
			return -E_FAULT;
f01038db:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01038e0:	eb 40                	jmp    f0103922 <user_mem_check+0xb2>
		}
		pte_t *pte = pgdir_walk(env->env_pgdir,(const void*)la,0);
f01038e2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01038e9:	00 
f01038ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01038ee:	89 04 24             	mov    %eax,(%esp)
f01038f1:	e8 6f da ff ff       	call   f0101365 <pgdir_walk>
		if (((*pte)&perm) != perm) {
f01038f6:	89 f1                	mov    %esi,%ecx
f01038f8:	23 08                	and    (%eax),%ecx
f01038fa:	39 ce                	cmp    %ecx,%esi
f01038fc:	74 14                	je     f0103912 <user_mem_check+0xa2>
			//cprintf("PT protected:%p,%p,%p\n",*pte,perm,PTE_U|PTE_P);
			user_mem_check_addr = (la == (uint32_t)ROUNDDOWN(va,PGSIZE))?(uint32_t)va:la;
f01038fe:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0103901:	0f 44 5d 0c          	cmove  0xc(%ebp),%ebx
f0103905:	89 1d 3c 32 23 f0    	mov    %ebx,0xf023323c
			return -E_FAULT;
f010390b:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103910:	eb 10                	jmp    f0103922 <user_mem_check+0xb2>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t la = (uint32_t)ROUNDDOWN(va,PGSIZE);
	uint32_t ela = (uint32_t)ROUNDUP(va+len,PGSIZE);
	for(;la<ela;la+=PGSIZE) {
f0103912:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103918:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010391b:	72 84                	jb     f01038a1 <user_mem_check+0x31>
			//cprintf("PT protected:%p,%p,%p\n",*pte,perm,PTE_U|PTE_P);
			user_mem_check_addr = (la == (uint32_t)ROUNDDOWN(va,PGSIZE))?(uint32_t)va:la;
			return -E_FAULT;
		}
	}
	return 0;
f010391d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103922:	83 c4 2c             	add    $0x2c,%esp
f0103925:	5b                   	pop    %ebx
f0103926:	5e                   	pop    %esi
f0103927:	5f                   	pop    %edi
f0103928:	5d                   	pop    %ebp
f0103929:	c3                   	ret    

f010392a <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010392a:	55                   	push   %ebp
f010392b:	89 e5                	mov    %esp,%ebp
f010392d:	53                   	push   %ebx
f010392e:	83 ec 14             	sub    $0x14,%esp
f0103931:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U | PTE_P) < 0) {
f0103934:	8b 45 14             	mov    0x14(%ebp),%eax
f0103937:	83 c8 05             	or     $0x5,%eax
f010393a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010393e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103941:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103945:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103948:	89 44 24 04          	mov    %eax,0x4(%esp)
f010394c:	89 1c 24             	mov    %ebx,(%esp)
f010394f:	e8 1c ff ff ff       	call   f0103870 <user_mem_check>
f0103954:	85 c0                	test   %eax,%eax
f0103956:	79 24                	jns    f010397c <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0103958:	a1 3c 32 23 f0       	mov    0xf023323c,%eax
f010395d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103961:	8b 43 48             	mov    0x48(%ebx),%eax
f0103964:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103968:	c7 04 24 f0 7f 10 f0 	movl   $0xf0107ff0,(%esp)
f010396f:	e8 96 09 00 00       	call   f010430a <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0103974:	89 1c 24             	mov    %ebx,(%esp)
f0103977:	e8 91 06 00 00       	call   f010400d <env_destroy>
	}
}
f010397c:	83 c4 14             	add    $0x14,%esp
f010397f:	5b                   	pop    %ebx
f0103980:	5d                   	pop    %ebp
f0103981:	c3                   	ret    

f0103982 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103982:	55                   	push   %ebp
f0103983:	89 e5                	mov    %esp,%ebp
f0103985:	57                   	push   %edi
f0103986:	56                   	push   %esi
f0103987:	53                   	push   %ebx
f0103988:	83 ec 1c             	sub    $0x1c,%esp
f010398b:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *la=ROUNDDOWN(va,PGSIZE);
f010398d:	89 d3                	mov    %edx,%ebx
f010398f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *ela=ROUNDUP(va+len,PGSIZE);
f0103995:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010399c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(;la<ela;la+=PGSIZE) {
f01039a2:	eb 55                	jmp    f01039f9 <region_alloc+0x77>
		struct PageInfo *pp = page_alloc(0);
f01039a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01039ab:	e8 c7 d8 ff ff       	call   f0101277 <page_alloc>
		assert(pp);
f01039b0:	85 c0                	test   %eax,%eax
f01039b2:	75 24                	jne    f01039d8 <region_alloc+0x56>
f01039b4:	c7 44 24 0c 48 82 10 	movl   $0xf0108248,0xc(%esp)
f01039bb:	f0 
f01039bc:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f01039c3:	f0 
f01039c4:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
f01039cb:	00 
f01039cc:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f01039d3:	e8 68 c6 ff ff       	call   f0100040 <_panic>
		page_insert(e->env_pgdir,pp,la,PTE_U|PTE_W|PTE_P);
f01039d8:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f01039df:	00 
f01039e0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01039e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039e8:	8b 47 60             	mov    0x60(%edi),%eax
f01039eb:	89 04 24             	mov    %eax,(%esp)
f01039ee:	e8 f8 dc ff ff       	call   f01016eb <page_insert>
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *la=ROUNDDOWN(va,PGSIZE);
	void *ela=ROUNDUP(va+len,PGSIZE);
	for(;la<ela;la+=PGSIZE) {
f01039f3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01039f9:	39 f3                	cmp    %esi,%ebx
f01039fb:	72 a7                	jb     f01039a4 <region_alloc+0x22>
		struct PageInfo *pp = page_alloc(0);
		assert(pp);
		page_insert(e->env_pgdir,pp,la,PTE_U|PTE_W|PTE_P);
	}
}
f01039fd:	83 c4 1c             	add    $0x1c,%esp
f0103a00:	5b                   	pop    %ebx
f0103a01:	5e                   	pop    %esi
f0103a02:	5f                   	pop    %edi
f0103a03:	5d                   	pop    %ebp
f0103a04:	c3                   	ret    

f0103a05 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103a05:	55                   	push   %ebp
f0103a06:	89 e5                	mov    %esp,%ebp
f0103a08:	56                   	push   %esi
f0103a09:	53                   	push   %ebx
f0103a0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a0d:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103a10:	85 c0                	test   %eax,%eax
f0103a12:	75 1a                	jne    f0103a2e <envid2env+0x29>
		*env_store = curenv;
f0103a14:	e8 c0 2e 00 00       	call   f01068d9 <cpunum>
f0103a19:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a1c:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0103a22:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a25:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103a27:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a2c:	eb 70                	jmp    f0103a9e <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103a2e:	89 c3                	mov    %eax,%ebx
f0103a30:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0103a36:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103a39:	03 1d 48 32 23 f0    	add    0xf0233248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103a3f:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103a43:	74 05                	je     f0103a4a <envid2env+0x45>
f0103a45:	39 43 48             	cmp    %eax,0x48(%ebx)
f0103a48:	74 10                	je     f0103a5a <envid2env+0x55>
		*env_store = 0;
f0103a4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a4d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103a53:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103a58:	eb 44                	jmp    f0103a9e <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103a5a:	84 d2                	test   %dl,%dl
f0103a5c:	74 36                	je     f0103a94 <envid2env+0x8f>
f0103a5e:	e8 76 2e 00 00       	call   f01068d9 <cpunum>
f0103a63:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a66:	39 98 28 40 23 f0    	cmp    %ebx,-0xfdcbfd8(%eax)
f0103a6c:	74 26                	je     f0103a94 <envid2env+0x8f>
f0103a6e:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103a71:	e8 63 2e 00 00       	call   f01068d9 <cpunum>
f0103a76:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a79:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0103a7f:	3b 70 48             	cmp    0x48(%eax),%esi
f0103a82:	74 10                	je     f0103a94 <envid2env+0x8f>
		*env_store = 0;
f0103a84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a87:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103a8d:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103a92:	eb 0a                	jmp    f0103a9e <envid2env+0x99>
	}

	*env_store = e;
f0103a94:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a97:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103a99:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a9e:	5b                   	pop    %ebx
f0103a9f:	5e                   	pop    %esi
f0103aa0:	5d                   	pop    %ebp
f0103aa1:	c3                   	ret    

f0103aa2 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103aa2:	55                   	push   %ebp
f0103aa3:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103aa5:	b8 20 23 12 f0       	mov    $0xf0122320,%eax
f0103aaa:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103aad:	b8 23 00 00 00       	mov    $0x23,%eax
f0103ab2:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103ab4:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103ab6:	b0 10                	mov    $0x10,%al
f0103ab8:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103aba:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103abc:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0103abe:	ea c5 3a 10 f0 08 00 	ljmp   $0x8,$0xf0103ac5
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0103ac5:	b0 00                	mov    $0x0,%al
f0103ac7:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103aca:	5d                   	pop    %ebp
f0103acb:	c3                   	ret    

f0103acc <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103acc:	55                   	push   %ebp
f0103acd:	89 e5                	mov    %esp,%ebp
f0103acf:	56                   	push   %esi
f0103ad0:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i=NENV-1;i>=0;i--) {
		envs[i].env_link = env_free_list;
f0103ad1:	8b 35 48 32 23 f0    	mov    0xf0233248,%esi
f0103ad7:	8b 0d 4c 32 23 f0    	mov    0xf023324c,%ecx
f0103add:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0103ae3:	ba 00 04 00 00       	mov    $0x400,%edx
f0103ae8:	89 c3                	mov    %eax,%ebx
f0103aea:	89 48 44             	mov    %ecx,0x44(%eax)
f0103aed:	83 e8 7c             	sub    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i=NENV-1;i>=0;i--) {
f0103af0:	83 ea 01             	sub    $0x1,%edx
f0103af3:	74 04                	je     f0103af9 <env_init+0x2d>
		envs[i].env_link = env_free_list;
		env_free_list = (envs+i);
f0103af5:	89 d9                	mov    %ebx,%ecx
f0103af7:	eb ef                	jmp    f0103ae8 <env_init+0x1c>
f0103af9:	89 35 4c 32 23 f0    	mov    %esi,0xf023324c
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0103aff:	e8 9e ff ff ff       	call   f0103aa2 <env_init_percpu>
}
f0103b04:	5b                   	pop    %ebx
f0103b05:	5e                   	pop    %esi
f0103b06:	5d                   	pop    %ebp
f0103b07:	c3                   	ret    

f0103b08 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103b08:	55                   	push   %ebp
f0103b09:	89 e5                	mov    %esp,%ebp
f0103b0b:	56                   	push   %esi
f0103b0c:	53                   	push   %ebx
f0103b0d:	83 ec 10             	sub    $0x10,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103b10:	8b 1d 4c 32 23 f0    	mov    0xf023324c,%ebx
f0103b16:	85 db                	test   %ebx,%ebx
f0103b18:	0f 84 9a 01 00 00    	je     f0103cb8 <env_alloc+0x1b0>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103b1e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103b25:	e8 4d d7 ff ff       	call   f0101277 <page_alloc>
f0103b2a:	85 c0                	test   %eax,%eax
f0103b2c:	0f 84 8d 01 00 00    	je     f0103cbf <env_alloc+0x1b7>
f0103b32:	89 c2                	mov    %eax,%edx
f0103b34:	2b 15 90 3e 23 f0    	sub    0xf0233e90,%edx
f0103b3a:	c1 fa 03             	sar    $0x3,%edx
f0103b3d:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103b40:	89 d1                	mov    %edx,%ecx
f0103b42:	c1 e9 0c             	shr    $0xc,%ecx
f0103b45:	3b 0d 88 3e 23 f0    	cmp    0xf0233e88,%ecx
f0103b4b:	72 20                	jb     f0103b6d <env_alloc+0x65>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103b4d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b51:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0103b58:	f0 
f0103b59:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
f0103b60:	00 
f0103b61:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0103b68:	e8 d3 c4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103b6d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103b73:	89 53 60             	mov    %edx,0x60(%ebx)
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t*)page2kva(p);
	p->pp_ref += 1;
f0103b76:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memmove(e->env_pgdir,kern_pgdir,PGSIZE);
f0103b7b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103b82:	00 
f0103b83:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
f0103b88:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b8c:	8b 43 60             	mov    0x60(%ebx),%eax
f0103b8f:	89 04 24             	mov    %eax,(%esp)
f0103b92:	e8 3d 27 00 00       	call   f01062d4 <memmove>
	

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103b97:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b9a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b9f:	77 20                	ja     f0103bc1 <env_alloc+0xb9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103ba1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ba5:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103bac:	f0 
f0103bad:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f0103bb4:	00 
f0103bb5:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f0103bbc:	e8 7f c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103bc1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103bc7:	83 ca 05             	or     $0x5,%edx
f0103bca:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103bd0:	8b 43 48             	mov    0x48(%ebx),%eax
f0103bd3:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103bd8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103bdd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103be2:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103be5:	89 da                	mov    %ebx,%edx
f0103be7:	2b 15 48 32 23 f0    	sub    0xf0233248,%edx
f0103bed:	c1 fa 02             	sar    $0x2,%edx
f0103bf0:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103bf6:	09 d0                	or     %edx,%eax
f0103bf8:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103bfb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bfe:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103c01:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103c08:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103c0f:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103c16:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103c1d:	00 
f0103c1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103c25:	00 
f0103c26:	89 1c 24             	mov    %ebx,(%esp)
f0103c29:	e8 59 26 00 00       	call   f0106287 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103c2e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103c34:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103c3a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103c40:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103c47:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;
f0103c4d:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103c54:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103c5b:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103c5f:	8b 43 44             	mov    0x44(%ebx),%eax
f0103c62:	a3 4c 32 23 f0       	mov    %eax,0xf023324c
	*newenv_store = e;
f0103c67:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c6a:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x,%08x\n", curenv ? curenv->env_id : 0, e->env_id,e->env_pgdir);
f0103c6c:	8b 73 60             	mov    0x60(%ebx),%esi
f0103c6f:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103c72:	e8 62 2c 00 00       	call   f01068d9 <cpunum>
f0103c77:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c7a:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c7f:	83 b8 28 40 23 f0 00 	cmpl   $0x0,-0xfdcbfd8(%eax)
f0103c86:	74 11                	je     f0103c99 <env_alloc+0x191>
f0103c88:	e8 4c 2c 00 00       	call   f01068d9 <cpunum>
f0103c8d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c90:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0103c96:	8b 50 48             	mov    0x48(%eax),%edx
f0103c99:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103c9d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103ca1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103ca5:	c7 04 24 92 83 10 f0 	movl   $0xf0108392,(%esp)
f0103cac:	e8 59 06 00 00       	call   f010430a <cprintf>
	return 0;
f0103cb1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cb6:	eb 0c                	jmp    f0103cc4 <env_alloc+0x1bc>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103cb8:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103cbd:	eb 05                	jmp    f0103cc4 <env_alloc+0x1bc>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103cbf:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x,%08x\n", curenv ? curenv->env_id : 0, e->env_id,e->env_pgdir);
	return 0;
}
f0103cc4:	83 c4 10             	add    $0x10,%esp
f0103cc7:	5b                   	pop    %ebx
f0103cc8:	5e                   	pop    %esi
f0103cc9:	5d                   	pop    %ebp
f0103cca:	c3                   	ret    

f0103ccb <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103ccb:	55                   	push   %ebp
f0103ccc:	89 e5                	mov    %esp,%ebp
f0103cce:	57                   	push   %edi
f0103ccf:	56                   	push   %esi
f0103cd0:	53                   	push   %ebx
f0103cd1:	83 ec 3c             	sub    $0x3c,%esp
f0103cd4:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* env;
	env_alloc(&env,0);
f0103cd7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103cde:	00 
f0103cdf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103ce2:	89 04 24             	mov    %eax,(%esp)
f0103ce5:	e8 1e fe ff ff       	call   f0103b08 <env_alloc>
	env->env_type = type;
f0103cea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103ced:	89 c1                	mov    %eax,%ecx
f0103cef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103cf2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cf5:	89 41 50             	mov    %eax,0x50(%ecx)
	// Load environment's page directory
	// Q:Then how can binary and env still be accessed ???
	// A: The reason is that the arguments exist in kernel stack, 
	//    which are accessed via stack operations, regardless of 
	//    virtual memory mapping!
	lcr3(PADDR(e->env_pgdir));
f0103cf8:	8b 41 60             	mov    0x60(%ecx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103cfb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103d00:	77 20                	ja     f0103d22 <env_create+0x57>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103d02:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d06:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103d0d:	f0 
f0103d0e:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0103d15:	00 
f0103d16:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f0103d1d:	e8 1e c3 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103d22:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103d27:	0f 22 d8             	mov    %eax,%cr3

	struct Proghdr *ph, *eph;
	struct Elf *elf = (struct Elf*)binary;
	if(elf->e_magic != ELF_MAGIC)
f0103d2a:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103d30:	74 1c                	je     f0103d4e <env_create+0x83>
		panic("Binary Format Invalid!\n");
f0103d32:	c7 44 24 08 ac 83 10 	movl   $0xf01083ac,0x8(%esp)
f0103d39:	f0 
f0103d3a:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f0103d41:	00 
f0103d42:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f0103d49:	e8 f2 c2 ff ff       	call   f0100040 <_panic>
	ph = (struct Proghdr*)(binary+elf->e_phoff);
f0103d4e:	89 fb                	mov    %edi,%ebx
f0103d50:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0103d53:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103d57:	c1 e6 05             	shl    $0x5,%esi
f0103d5a:	01 de                	add    %ebx,%esi
f0103d5c:	eb 50                	jmp    f0103dae <env_create+0xe3>
	for(;ph<eph;ph++) {
		if (ph->p_type == ELF_PROG_LOAD) {
f0103d5e:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103d61:	75 48                	jne    f0103dab <env_create+0xe0>
			region_alloc(e,(void*)(ph->p_va),ph->p_memsz);
f0103d63:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103d66:	8b 53 08             	mov    0x8(%ebx),%edx
f0103d69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103d6c:	e8 11 fc ff ff       	call   f0103982 <region_alloc>
			memmove((void*)ph->p_va,(const void *)binary+ph->p_offset,ph->p_filesz);
f0103d71:	8b 43 10             	mov    0x10(%ebx),%eax
f0103d74:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d78:	89 f8                	mov    %edi,%eax
f0103d7a:	03 43 04             	add    0x4(%ebx),%eax
f0103d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d81:	8b 43 08             	mov    0x8(%ebx),%eax
f0103d84:	89 04 24             	mov    %eax,(%esp)
f0103d87:	e8 48 25 00 00       	call   f01062d4 <memmove>
			memset((void*)ph->p_va+ph->p_filesz,0,ph->p_memsz-ph->p_filesz);
f0103d8c:	8b 43 10             	mov    0x10(%ebx),%eax
f0103d8f:	8b 53 14             	mov    0x14(%ebx),%edx
f0103d92:	29 c2                	sub    %eax,%edx
f0103d94:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103d98:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103d9f:	00 
f0103da0:	03 43 08             	add    0x8(%ebx),%eax
f0103da3:	89 04 24             	mov    %eax,(%esp)
f0103da6:	e8 dc 24 00 00       	call   f0106287 <memset>
	struct Elf *elf = (struct Elf*)binary;
	if(elf->e_magic != ELF_MAGIC)
		panic("Binary Format Invalid!\n");
	ph = (struct Proghdr*)(binary+elf->e_phoff);
	eph = ph + elf->e_phnum;
	for(;ph<eph;ph++) {
f0103dab:	83 c3 20             	add    $0x20,%ebx
f0103dae:	39 de                	cmp    %ebx,%esi
f0103db0:	77 ac                	ja     f0103d5e <env_create+0x93>

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f0103db2:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103db7:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103dbc:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103dbf:	89 f0                	mov    %esi,%eax
f0103dc1:	e8 bc fb ff ff       	call   f0103982 <region_alloc>

	// Set the environment's entry point
	e->env_tf.tf_eip = elf->e_entry;
f0103dc6:	8b 47 18             	mov    0x18(%edi),%eax
f0103dc9:	89 46 30             	mov    %eax,0x30(%esi)
	
	// Restore kernel page directory
	lcr3(PADDR(kern_pgdir));
f0103dcc:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103dd1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103dd6:	77 20                	ja     f0103df8 <env_create+0x12d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103dd8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ddc:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103de3:	f0 
f0103de4:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0103deb:	00 
f0103dec:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f0103df3:	e8 48 c2 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103df8:	05 00 00 00 10       	add    $0x10000000,%eax
f0103dfd:	0f 22 d8             	mov    %eax,%cr3
	// LAB 3: Your code here.
	struct Env* env;
	env_alloc(&env,0);
	env->env_type = type;
	load_icode(env,binary);
}
f0103e00:	83 c4 3c             	add    $0x3c,%esp
f0103e03:	5b                   	pop    %ebx
f0103e04:	5e                   	pop    %esi
f0103e05:	5f                   	pop    %edi
f0103e06:	5d                   	pop    %ebp
f0103e07:	c3                   	ret    

f0103e08 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103e08:	55                   	push   %ebp
f0103e09:	89 e5                	mov    %esp,%ebp
f0103e0b:	57                   	push   %edi
f0103e0c:	56                   	push   %esi
f0103e0d:	53                   	push   %ebx
f0103e0e:	83 ec 2c             	sub    $0x2c,%esp
f0103e11:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103e14:	e8 c0 2a 00 00       	call   f01068d9 <cpunum>
f0103e19:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e1c:	39 b8 28 40 23 f0    	cmp    %edi,-0xfdcbfd8(%eax)
f0103e22:	75 34                	jne    f0103e58 <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103e24:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103e29:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103e2e:	77 20                	ja     f0103e50 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103e30:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e34:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103e3b:	f0 
f0103e3c:	c7 44 24 04 a5 01 00 	movl   $0x1a5,0x4(%esp)
f0103e43:	00 
f0103e44:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f0103e4b:	e8 f0 c1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103e50:	05 00 00 00 10       	add    $0x10000000,%eax
f0103e55:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103e58:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103e5b:	e8 79 2a 00 00       	call   f01068d9 <cpunum>
f0103e60:	6b d0 74             	imul   $0x74,%eax,%edx
f0103e63:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e68:	83 ba 28 40 23 f0 00 	cmpl   $0x0,-0xfdcbfd8(%edx)
f0103e6f:	74 11                	je     f0103e82 <env_free+0x7a>
f0103e71:	e8 63 2a 00 00       	call   f01068d9 <cpunum>
f0103e76:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e79:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0103e7f:	8b 40 48             	mov    0x48(%eax),%eax
f0103e82:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103e86:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e8a:	c7 04 24 c4 83 10 f0 	movl   $0xf01083c4,(%esp)
f0103e91:	e8 74 04 00 00       	call   f010430a <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103e96:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103e9d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ea0:	89 c8                	mov    %ecx,%eax
f0103ea2:	c1 e0 02             	shl    $0x2,%eax
f0103ea5:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103ea8:	8b 47 60             	mov    0x60(%edi),%eax
f0103eab:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103eae:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103eb4:	0f 84 b7 00 00 00    	je     f0103f71 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103eba:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103ec0:	89 f0                	mov    %esi,%eax
f0103ec2:	c1 e8 0c             	shr    $0xc,%eax
f0103ec5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ec8:	3b 05 88 3e 23 f0    	cmp    0xf0233e88,%eax
f0103ece:	72 20                	jb     f0103ef0 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103ed0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103ed4:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0103edb:	f0 
f0103edc:	c7 44 24 04 b4 01 00 	movl   $0x1b4,0x4(%esp)
f0103ee3:	00 
f0103ee4:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f0103eeb:	e8 50 c1 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103ef0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103ef3:	c1 e0 16             	shl    $0x16,%eax
f0103ef6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103ef9:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103efe:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103f05:	01 
f0103f06:	74 17                	je     f0103f1f <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103f08:	89 d8                	mov    %ebx,%eax
f0103f0a:	c1 e0 0c             	shl    $0xc,%eax
f0103f0d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103f10:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f14:	8b 47 60             	mov    0x60(%edi),%eax
f0103f17:	89 04 24             	mov    %eax,(%esp)
f0103f1a:	e8 71 d7 ff ff       	call   f0101690 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103f1f:	83 c3 01             	add    $0x1,%ebx
f0103f22:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103f28:	75 d4                	jne    f0103efe <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103f2a:	8b 47 60             	mov    0x60(%edi),%eax
f0103f2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f30:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103f37:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f3a:	3b 05 88 3e 23 f0    	cmp    0xf0233e88,%eax
f0103f40:	72 1c                	jb     f0103f5e <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103f42:	c7 44 24 08 ec 77 10 	movl   $0xf01077ec,0x8(%esp)
f0103f49:	f0 
f0103f4a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103f51:	00 
f0103f52:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0103f59:	e8 e2 c0 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103f5e:	a1 90 3e 23 f0       	mov    0xf0233e90,%eax
f0103f63:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103f66:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103f69:	89 04 24             	mov    %eax,(%esp)
f0103f6c:	e8 d1 d3 ff ff       	call   f0101342 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103f71:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103f75:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103f7c:	0f 85 1b ff ff ff    	jne    f0103e9d <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103f82:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103f85:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103f8a:	77 20                	ja     f0103fac <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103f8c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f90:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0103f97:	f0 
f0103f98:	c7 44 24 04 c2 01 00 	movl   $0x1c2,0x4(%esp)
f0103f9f:	00 
f0103fa0:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f0103fa7:	e8 94 c0 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103fac:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103fb3:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103fb8:	c1 e8 0c             	shr    $0xc,%eax
f0103fbb:	3b 05 88 3e 23 f0    	cmp    0xf0233e88,%eax
f0103fc1:	72 1c                	jb     f0103fdf <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103fc3:	c7 44 24 08 ec 77 10 	movl   $0xf01077ec,0x8(%esp)
f0103fca:	f0 
f0103fcb:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103fd2:	00 
f0103fd3:	c7 04 24 25 80 10 f0 	movl   $0xf0108025,(%esp)
f0103fda:	e8 61 c0 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103fdf:	8b 15 90 3e 23 f0    	mov    0xf0233e90,%edx
f0103fe5:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103fe8:	89 04 24             	mov    %eax,(%esp)
f0103feb:	e8 52 d3 ff ff       	call   f0101342 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103ff0:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103ff7:	a1 4c 32 23 f0       	mov    0xf023324c,%eax
f0103ffc:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103fff:	89 3d 4c 32 23 f0    	mov    %edi,0xf023324c
}
f0104005:	83 c4 2c             	add    $0x2c,%esp
f0104008:	5b                   	pop    %ebx
f0104009:	5e                   	pop    %esi
f010400a:	5f                   	pop    %edi
f010400b:	5d                   	pop    %ebp
f010400c:	c3                   	ret    

f010400d <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010400d:	55                   	push   %ebp
f010400e:	89 e5                	mov    %esp,%ebp
f0104010:	53                   	push   %ebx
f0104011:	83 ec 14             	sub    $0x14,%esp
f0104014:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0104017:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f010401b:	75 19                	jne    f0104036 <env_destroy+0x29>
f010401d:	e8 b7 28 00 00       	call   f01068d9 <cpunum>
f0104022:	6b c0 74             	imul   $0x74,%eax,%eax
f0104025:	39 98 28 40 23 f0    	cmp    %ebx,-0xfdcbfd8(%eax)
f010402b:	74 09                	je     f0104036 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f010402d:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0104034:	eb 2f                	jmp    f0104065 <env_destroy+0x58>
	}

	env_free(e);
f0104036:	89 1c 24             	mov    %ebx,(%esp)
f0104039:	e8 ca fd ff ff       	call   f0103e08 <env_free>

	if (curenv == e) {
f010403e:	e8 96 28 00 00       	call   f01068d9 <cpunum>
f0104043:	6b c0 74             	imul   $0x74,%eax,%eax
f0104046:	39 98 28 40 23 f0    	cmp    %ebx,-0xfdcbfd8(%eax)
f010404c:	75 17                	jne    f0104065 <env_destroy+0x58>
		curenv = NULL;
f010404e:	e8 86 28 00 00       	call   f01068d9 <cpunum>
f0104053:	6b c0 74             	imul   $0x74,%eax,%eax
f0104056:	c7 80 28 40 23 f0 00 	movl   $0x0,-0xfdcbfd8(%eax)
f010405d:	00 00 00 
		sched_yield();
f0104060:	e8 8b 0e 00 00       	call   f0104ef0 <sched_yield>
	}
}
f0104065:	83 c4 14             	add    $0x14,%esp
f0104068:	5b                   	pop    %ebx
f0104069:	5d                   	pop    %ebp
f010406a:	c3                   	ret    

f010406b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010406b:	55                   	push   %ebp
f010406c:	89 e5                	mov    %esp,%ebp
f010406e:	53                   	push   %ebx
f010406f:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0104072:	e8 62 28 00 00       	call   f01068d9 <cpunum>
f0104077:	6b c0 74             	imul   $0x74,%eax,%eax
f010407a:	8b 98 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%ebx
f0104080:	e8 54 28 00 00       	call   f01068d9 <cpunum>
f0104085:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0104088:	8b 65 08             	mov    0x8(%ebp),%esp
f010408b:	61                   	popa   
f010408c:	07                   	pop    %es
f010408d:	1f                   	pop    %ds
f010408e:	83 c4 08             	add    $0x8,%esp
f0104091:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0104092:	c7 44 24 08 da 83 10 	movl   $0xf01083da,0x8(%esp)
f0104099:	f0 
f010409a:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
f01040a1:	00 
f01040a2:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f01040a9:	e8 92 bf ff ff       	call   f0100040 <_panic>

f01040ae <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01040ae:	55                   	push   %ebp
f01040af:	89 e5                	mov    %esp,%ebp
f01040b1:	53                   	push   %ebx
f01040b2:	83 ec 14             	sub    $0x14,%esp
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv && curenv->env_status != ENV_NOT_RUNNABLE ){
f01040b5:	e8 1f 28 00 00       	call   f01068d9 <cpunum>
f01040ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01040bd:	83 b8 28 40 23 f0 00 	cmpl   $0x0,-0xfdcbfd8(%eax)
f01040c4:	74 29                	je     f01040ef <env_run+0x41>
f01040c6:	e8 0e 28 00 00       	call   f01068d9 <cpunum>
f01040cb:	6b c0 74             	imul   $0x74,%eax,%eax
f01040ce:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01040d4:	83 78 54 04          	cmpl   $0x4,0x54(%eax)
f01040d8:	74 15                	je     f01040ef <env_run+0x41>
		curenv->env_status = ENV_RUNNABLE;	
f01040da:	e8 fa 27 00 00       	call   f01068d9 <cpunum>
f01040df:	6b c0 74             	imul   $0x74,%eax,%eax
f01040e2:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01040e8:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f01040ef:	e8 e5 27 00 00       	call   f01068d9 <cpunum>
f01040f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01040f7:	8b 55 08             	mov    0x8(%ebp),%edx
f01040fa:	89 90 28 40 23 f0    	mov    %edx,-0xfdcbfd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0104100:	e8 d4 27 00 00       	call   f01068d9 <cpunum>
f0104105:	6b c0 74             	imul   $0x74,%eax,%eax
f0104108:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010410e:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0104115:	e8 bf 27 00 00       	call   f01068d9 <cpunum>
f010411a:	6b c0 74             	imul   $0x74,%eax,%eax
f010411d:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104123:	83 40 58 01          	addl   $0x1,0x58(%eax)
	curenv->env_cpunum = cpunum();
f0104127:	e8 ad 27 00 00       	call   f01068d9 <cpunum>
f010412c:	6b c0 74             	imul   $0x74,%eax,%eax
f010412f:	8b 98 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%ebx
f0104135:	e8 9f 27 00 00       	call   f01068d9 <cpunum>
f010413a:	89 43 5c             	mov    %eax,0x5c(%ebx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010413d:	c7 04 24 80 24 12 f0 	movl   $0xf0122480,(%esp)
f0104144:	e8 ba 2a 00 00       	call   f0106c03 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104149:	f3 90                	pause  
	
	unlock_kernel();
	lcr3(PADDR(curenv->env_pgdir));
f010414b:	e8 89 27 00 00       	call   f01068d9 <cpunum>
f0104150:	6b c0 74             	imul   $0x74,%eax,%eax
f0104153:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104159:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010415c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104161:	77 20                	ja     f0104183 <env_run+0xd5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104163:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104167:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f010416e:	f0 
f010416f:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
f0104176:	00 
f0104177:	c7 04 24 87 83 10 f0 	movl   $0xf0108387,(%esp)
f010417e:	e8 bd be ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104183:	05 00 00 00 10       	add    $0x10000000,%eax
f0104188:	0f 22 d8             	mov    %eax,%cr3
	//if ((curenv->env_tf.tf_cs & 3) == 3)
	env_pop_tf(&(curenv->env_tf));
f010418b:	e8 49 27 00 00       	call   f01068d9 <cpunum>
f0104190:	6b c0 74             	imul   $0x74,%eax,%eax
f0104193:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104199:	89 04 24             	mov    %eax,(%esp)
f010419c:	e8 ca fe ff ff       	call   f010406b <env_pop_tf>

f01041a1 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01041a1:	55                   	push   %ebp
f01041a2:	89 e5                	mov    %esp,%ebp
f01041a4:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01041a8:	ba 70 00 00 00       	mov    $0x70,%edx
f01041ad:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01041ae:	b2 71                	mov    $0x71,%dl
f01041b0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01041b1:	0f b6 c0             	movzbl %al,%eax
}
f01041b4:	5d                   	pop    %ebp
f01041b5:	c3                   	ret    

f01041b6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01041b6:	55                   	push   %ebp
f01041b7:	89 e5                	mov    %esp,%ebp
f01041b9:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01041bd:	ba 70 00 00 00       	mov    $0x70,%edx
f01041c2:	ee                   	out    %al,(%dx)
f01041c3:	b2 71                	mov    $0x71,%dl
f01041c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041c8:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01041c9:	5d                   	pop    %ebp
f01041ca:	c3                   	ret    

f01041cb <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01041cb:	55                   	push   %ebp
f01041cc:	89 e5                	mov    %esp,%ebp
f01041ce:	56                   	push   %esi
f01041cf:	53                   	push   %ebx
f01041d0:	83 ec 10             	sub    $0x10,%esp
f01041d3:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01041d6:	66 a3 a8 23 12 f0    	mov    %ax,0xf01223a8
	if (!didinit)
f01041dc:	80 3d 50 32 23 f0 00 	cmpb   $0x0,0xf0233250
f01041e3:	74 4e                	je     f0104233 <irq_setmask_8259A+0x68>
f01041e5:	89 c6                	mov    %eax,%esi
f01041e7:	ba 21 00 00 00       	mov    $0x21,%edx
f01041ec:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f01041ed:	66 c1 e8 08          	shr    $0x8,%ax
f01041f1:	b2 a1                	mov    $0xa1,%dl
f01041f3:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f01041f4:	c7 04 24 e6 83 10 f0 	movl   $0xf01083e6,(%esp)
f01041fb:	e8 0a 01 00 00       	call   f010430a <cprintf>
	for (i = 0; i < 16; i++)
f0104200:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0104205:	0f b7 f6             	movzwl %si,%esi
f0104208:	f7 d6                	not    %esi
f010420a:	0f a3 de             	bt     %ebx,%esi
f010420d:	73 10                	jae    f010421f <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f010420f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104213:	c7 04 24 c7 88 10 f0 	movl   $0xf01088c7,(%esp)
f010421a:	e8 eb 00 00 00       	call   f010430a <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010421f:	83 c3 01             	add    $0x1,%ebx
f0104222:	83 fb 10             	cmp    $0x10,%ebx
f0104225:	75 e3                	jne    f010420a <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0104227:	c7 04 24 a2 85 10 f0 	movl   $0xf01085a2,(%esp)
f010422e:	e8 d7 00 00 00       	call   f010430a <cprintf>
}
f0104233:	83 c4 10             	add    $0x10,%esp
f0104236:	5b                   	pop    %ebx
f0104237:	5e                   	pop    %esi
f0104238:	5d                   	pop    %ebp
f0104239:	c3                   	ret    

f010423a <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010423a:	c6 05 50 32 23 f0 01 	movb   $0x1,0xf0233250
f0104241:	ba 21 00 00 00       	mov    $0x21,%edx
f0104246:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010424b:	ee                   	out    %al,(%dx)
f010424c:	b2 a1                	mov    $0xa1,%dl
f010424e:	ee                   	out    %al,(%dx)
f010424f:	b2 20                	mov    $0x20,%dl
f0104251:	b8 11 00 00 00       	mov    $0x11,%eax
f0104256:	ee                   	out    %al,(%dx)
f0104257:	b2 21                	mov    $0x21,%dl
f0104259:	b8 20 00 00 00       	mov    $0x20,%eax
f010425e:	ee                   	out    %al,(%dx)
f010425f:	b8 04 00 00 00       	mov    $0x4,%eax
f0104264:	ee                   	out    %al,(%dx)
f0104265:	b8 03 00 00 00       	mov    $0x3,%eax
f010426a:	ee                   	out    %al,(%dx)
f010426b:	b2 a0                	mov    $0xa0,%dl
f010426d:	b8 11 00 00 00       	mov    $0x11,%eax
f0104272:	ee                   	out    %al,(%dx)
f0104273:	b2 a1                	mov    $0xa1,%dl
f0104275:	b8 28 00 00 00       	mov    $0x28,%eax
f010427a:	ee                   	out    %al,(%dx)
f010427b:	b8 02 00 00 00       	mov    $0x2,%eax
f0104280:	ee                   	out    %al,(%dx)
f0104281:	b8 01 00 00 00       	mov    $0x1,%eax
f0104286:	ee                   	out    %al,(%dx)
f0104287:	b2 20                	mov    $0x20,%dl
f0104289:	b8 68 00 00 00       	mov    $0x68,%eax
f010428e:	ee                   	out    %al,(%dx)
f010428f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104294:	ee                   	out    %al,(%dx)
f0104295:	b2 a0                	mov    $0xa0,%dl
f0104297:	b8 68 00 00 00       	mov    $0x68,%eax
f010429c:	ee                   	out    %al,(%dx)
f010429d:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042a2:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01042a3:	0f b7 05 a8 23 12 f0 	movzwl 0xf01223a8,%eax
f01042aa:	66 83 f8 ff          	cmp    $0xffff,%ax
f01042ae:	74 12                	je     f01042c2 <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01042b0:	55                   	push   %ebp
f01042b1:	89 e5                	mov    %esp,%ebp
f01042b3:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01042b6:	0f b7 c0             	movzwl %ax,%eax
f01042b9:	89 04 24             	mov    %eax,(%esp)
f01042bc:	e8 0a ff ff ff       	call   f01041cb <irq_setmask_8259A>
}
f01042c1:	c9                   	leave  
f01042c2:	f3 c3                	repz ret 

f01042c4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01042c4:	55                   	push   %ebp
f01042c5:	89 e5                	mov    %esp,%ebp
f01042c7:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01042ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01042cd:	89 04 24             	mov    %eax,(%esp)
f01042d0:	e8 b9 c4 ff ff       	call   f010078e <cputchar>
	*cnt++;
}
f01042d5:	c9                   	leave  
f01042d6:	c3                   	ret    

f01042d7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01042d7:	55                   	push   %ebp
f01042d8:	89 e5                	mov    %esp,%ebp
f01042da:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01042dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01042e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01042eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01042ee:	89 44 24 08          	mov    %eax,0x8(%esp)
f01042f2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01042f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042f9:	c7 04 24 c4 42 10 f0 	movl   $0xf01042c4,(%esp)
f0104300:	e8 c9 18 00 00       	call   f0105bce <vprintfmt>
	return cnt;
}
f0104305:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104308:	c9                   	leave  
f0104309:	c3                   	ret    

f010430a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010430a:	55                   	push   %ebp
f010430b:	89 e5                	mov    %esp,%ebp
f010430d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0104310:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0104313:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104317:	8b 45 08             	mov    0x8(%ebp),%eax
f010431a:	89 04 24             	mov    %eax,(%esp)
f010431d:	e8 b5 ff ff ff       	call   f01042d7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0104322:	c9                   	leave  
f0104323:	c3                   	ret    
f0104324:	66 90                	xchg   %ax,%ax
f0104326:	66 90                	xchg   %ax,%ax
f0104328:	66 90                	xchg   %ax,%ax
f010432a:	66 90                	xchg   %ax,%ax
f010432c:	66 90                	xchg   %ax,%ax
f010432e:	66 90                	xchg   %ax,%ax

f0104330 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0104330:	55                   	push   %ebp
f0104331:	89 e5                	mov    %esp,%ebp
f0104333:	57                   	push   %edi
f0104334:	56                   	push   %esi
f0104335:	53                   	push   %ebx
f0104336:	83 ec 0c             	sub    $0xc,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-cpunum()*(KSTKSIZE+KSTKGAP);
f0104339:	e8 9b 25 00 00       	call   f01068d9 <cpunum>
f010433e:	89 c3                	mov    %eax,%ebx
f0104340:	e8 94 25 00 00       	call   f01068d9 <cpunum>
f0104345:	6b db 74             	imul   $0x74,%ebx,%ebx
f0104348:	f7 d8                	neg    %eax
f010434a:	c1 e0 10             	shl    $0x10,%eax
f010434d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0104352:	89 83 30 40 23 f0    	mov    %eax,-0xfdcbfd0(%ebx)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0104358:	e8 7c 25 00 00       	call   f01068d9 <cpunum>
f010435d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104360:	66 c7 80 34 40 23 f0 	movw   $0x10,-0xfdcbfcc(%eax)
f0104367:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f0104369:	e8 6b 25 00 00       	call   f01068d9 <cpunum>
f010436e:	8d 58 05             	lea    0x5(%eax),%ebx
f0104371:	e8 63 25 00 00       	call   f01068d9 <cpunum>
f0104376:	89 c7                	mov    %eax,%edi
f0104378:	e8 5c 25 00 00       	call   f01068d9 <cpunum>
f010437d:	89 c6                	mov    %eax,%esi
f010437f:	e8 55 25 00 00       	call   f01068d9 <cpunum>
f0104384:	66 c7 04 dd 40 23 12 	movw   $0x68,-0xfeddcc0(,%ebx,8)
f010438b:	f0 68 00 
f010438e:	6b ff 74             	imul   $0x74,%edi,%edi
f0104391:	81 c7 2c 40 23 f0    	add    $0xf023402c,%edi
f0104397:	66 89 3c dd 42 23 12 	mov    %di,-0xfeddcbe(,%ebx,8)
f010439e:	f0 
f010439f:	6b d6 74             	imul   $0x74,%esi,%edx
f01043a2:	81 c2 2c 40 23 f0    	add    $0xf023402c,%edx
f01043a8:	c1 ea 10             	shr    $0x10,%edx
f01043ab:	88 14 dd 44 23 12 f0 	mov    %dl,-0xfeddcbc(,%ebx,8)
f01043b2:	c6 04 dd 45 23 12 f0 	movb   $0x99,-0xfeddcbb(,%ebx,8)
f01043b9:	99 
f01043ba:	c6 04 dd 46 23 12 f0 	movb   $0x40,-0xfeddcba(,%ebx,8)
f01043c1:	40 
f01043c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01043c5:	05 2c 40 23 f0       	add    $0xf023402c,%eax
f01043ca:	c1 e8 18             	shr    $0x18,%eax
f01043cd:	88 04 dd 47 23 12 f0 	mov    %al,-0xfeddcb9(,%ebx,8)
					sizeof(struct Taskstate), 0);
	gdt[(GD_TSS0 >> 3)+cpunum()].sd_s = 0;
f01043d4:	e8 00 25 00 00       	call   f01068d9 <cpunum>
f01043d9:	80 24 c5 6d 23 12 f0 	andb   $0xef,-0xfeddc93(,%eax,8)
f01043e0:	ef 


	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3)+cpunum())<<3);
f01043e1:	e8 f3 24 00 00       	call   f01068d9 <cpunum>
f01043e6:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01043ed:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01043f0:	b8 aa 23 12 f0       	mov    $0xf01223aa,%eax
f01043f5:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f01043f8:	83 c4 0c             	add    $0xc,%esp
f01043fb:	5b                   	pop    %ebx
f01043fc:	5e                   	pop    %esi
f01043fd:	5f                   	pop    %edi
f01043fe:	5d                   	pop    %ebp
f01043ff:	c3                   	ret    

f0104400 <trap_init>:
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i;
	for(i=0;i<48;i++)
f0104400:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,vectors[i],0);
f0104405:	8b 14 85 b0 23 12 f0 	mov    -0xfeddc50(,%eax,4),%edx
f010440c:	66 89 14 c5 60 32 23 	mov    %dx,-0xfdccda0(,%eax,8)
f0104413:	f0 
f0104414:	66 c7 04 c5 62 32 23 	movw   $0x8,-0xfdccd9e(,%eax,8)
f010441b:	f0 08 00 
f010441e:	c6 04 c5 64 32 23 f0 	movb   $0x0,-0xfdccd9c(,%eax,8)
f0104425:	00 
f0104426:	c6 04 c5 65 32 23 f0 	movb   $0x8e,-0xfdccd9b(,%eax,8)
f010442d:	8e 
f010442e:	c1 ea 10             	shr    $0x10,%edx
f0104431:	66 89 14 c5 66 32 23 	mov    %dx,-0xfdccd9a(,%eax,8)
f0104438:	f0 
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i;
	for(i=0;i<48;i++)
f0104439:	83 c0 01             	add    $0x1,%eax
f010443c:	83 f8 30             	cmp    $0x30,%eax
f010443f:	75 c4                	jne    f0104405 <trap_init+0x5>
}


void
trap_init(void)
{
f0104441:	55                   	push   %ebp
f0104442:	89 e5                	mov    %esp,%ebp
f0104444:	83 ec 08             	sub    $0x8,%esp

	// LAB 3: Your code here.
	int i;
	for(i=0;i<48;i++)
		SETGATE(idt[i],0,GD_KT,vectors[i],0);
	SETGATE(idt[3],0,GD_KT,vectors[3],3);
f0104447:	a1 bc 23 12 f0       	mov    0xf01223bc,%eax
f010444c:	66 a3 78 32 23 f0    	mov    %ax,0xf0233278
f0104452:	66 c7 05 7a 32 23 f0 	movw   $0x8,0xf023327a
f0104459:	08 00 
f010445b:	c6 05 7c 32 23 f0 00 	movb   $0x0,0xf023327c
f0104462:	c6 05 7d 32 23 f0 ee 	movb   $0xee,0xf023327d
f0104469:	c1 e8 10             	shr    $0x10,%eax
f010446c:	66 a3 7e 32 23 f0    	mov    %ax,0xf023327e
	SETGATE(idt[48],0,GD_KT,vectors[48],3);
f0104472:	a1 70 24 12 f0       	mov    0xf0122470,%eax
f0104477:	66 a3 e0 33 23 f0    	mov    %ax,0xf02333e0
f010447d:	66 c7 05 e2 33 23 f0 	movw   $0x8,0xf02333e2
f0104484:	08 00 
f0104486:	c6 05 e4 33 23 f0 00 	movb   $0x0,0xf02333e4
f010448d:	c6 05 e5 33 23 f0 ee 	movb   $0xee,0xf02333e5
f0104494:	c1 e8 10             	shr    $0x10,%eax
f0104497:	66 a3 e6 33 23 f0    	mov    %ax,0xf02333e6

	// Per-CPU setup 
	trap_init_percpu();
f010449d:	e8 8e fe ff ff       	call   f0104330 <trap_init_percpu>
}
f01044a2:	c9                   	leave  
f01044a3:	c3                   	ret    

f01044a4 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01044a4:	55                   	push   %ebp
f01044a5:	89 e5                	mov    %esp,%ebp
f01044a7:	53                   	push   %ebx
f01044a8:	83 ec 14             	sub    $0x14,%esp
f01044ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01044ae:	8b 03                	mov    (%ebx),%eax
f01044b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044b4:	c7 04 24 fa 83 10 f0 	movl   $0xf01083fa,(%esp)
f01044bb:	e8 4a fe ff ff       	call   f010430a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01044c0:	8b 43 04             	mov    0x4(%ebx),%eax
f01044c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044c7:	c7 04 24 09 84 10 f0 	movl   $0xf0108409,(%esp)
f01044ce:	e8 37 fe ff ff       	call   f010430a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01044d3:	8b 43 08             	mov    0x8(%ebx),%eax
f01044d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044da:	c7 04 24 18 84 10 f0 	movl   $0xf0108418,(%esp)
f01044e1:	e8 24 fe ff ff       	call   f010430a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01044e6:	8b 43 0c             	mov    0xc(%ebx),%eax
f01044e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044ed:	c7 04 24 27 84 10 f0 	movl   $0xf0108427,(%esp)
f01044f4:	e8 11 fe ff ff       	call   f010430a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01044f9:	8b 43 10             	mov    0x10(%ebx),%eax
f01044fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104500:	c7 04 24 36 84 10 f0 	movl   $0xf0108436,(%esp)
f0104507:	e8 fe fd ff ff       	call   f010430a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010450c:	8b 43 14             	mov    0x14(%ebx),%eax
f010450f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104513:	c7 04 24 45 84 10 f0 	movl   $0xf0108445,(%esp)
f010451a:	e8 eb fd ff ff       	call   f010430a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010451f:	8b 43 18             	mov    0x18(%ebx),%eax
f0104522:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104526:	c7 04 24 54 84 10 f0 	movl   $0xf0108454,(%esp)
f010452d:	e8 d8 fd ff ff       	call   f010430a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104532:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0104535:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104539:	c7 04 24 63 84 10 f0 	movl   $0xf0108463,(%esp)
f0104540:	e8 c5 fd ff ff       	call   f010430a <cprintf>
}
f0104545:	83 c4 14             	add    $0x14,%esp
f0104548:	5b                   	pop    %ebx
f0104549:	5d                   	pop    %ebp
f010454a:	c3                   	ret    

f010454b <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010454b:	55                   	push   %ebp
f010454c:	89 e5                	mov    %esp,%ebp
f010454e:	56                   	push   %esi
f010454f:	53                   	push   %ebx
f0104550:	83 ec 10             	sub    $0x10,%esp
f0104553:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0104556:	e8 7e 23 00 00       	call   f01068d9 <cpunum>
f010455b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010455f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104563:	c7 04 24 c7 84 10 f0 	movl   $0xf01084c7,(%esp)
f010456a:	e8 9b fd ff ff       	call   f010430a <cprintf>
	print_regs(&tf->tf_regs);
f010456f:	89 1c 24             	mov    %ebx,(%esp)
f0104572:	e8 2d ff ff ff       	call   f01044a4 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0104577:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010457b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010457f:	c7 04 24 e5 84 10 f0 	movl   $0xf01084e5,(%esp)
f0104586:	e8 7f fd ff ff       	call   f010430a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010458b:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010458f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104593:	c7 04 24 f8 84 10 f0 	movl   $0xf01084f8,(%esp)
f010459a:	e8 6b fd ff ff       	call   f010430a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010459f:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01045a2:	83 f8 13             	cmp    $0x13,%eax
f01045a5:	77 09                	ja     f01045b0 <print_trapframe+0x65>
		return excnames[trapno];
f01045a7:	8b 14 85 a0 87 10 f0 	mov    -0xfef7860(,%eax,4),%edx
f01045ae:	eb 1f                	jmp    f01045cf <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f01045b0:	83 f8 30             	cmp    $0x30,%eax
f01045b3:	74 15                	je     f01045ca <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01045b5:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01045b8:	83 fa 0f             	cmp    $0xf,%edx
f01045bb:	ba 7e 84 10 f0       	mov    $0xf010847e,%edx
f01045c0:	b9 91 84 10 f0       	mov    $0xf0108491,%ecx
f01045c5:	0f 47 d1             	cmova  %ecx,%edx
f01045c8:	eb 05                	jmp    f01045cf <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f01045ca:	ba 72 84 10 f0       	mov    $0xf0108472,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01045cf:	89 54 24 08          	mov    %edx,0x8(%esp)
f01045d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045d7:	c7 04 24 0b 85 10 f0 	movl   $0xf010850b,(%esp)
f01045de:	e8 27 fd ff ff       	call   f010430a <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01045e3:	3b 1d 60 3a 23 f0    	cmp    0xf0233a60,%ebx
f01045e9:	75 19                	jne    f0104604 <print_trapframe+0xb9>
f01045eb:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01045ef:	75 13                	jne    f0104604 <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01045f1:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01045f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045f8:	c7 04 24 1d 85 10 f0 	movl   $0xf010851d,(%esp)
f01045ff:	e8 06 fd ff ff       	call   f010430a <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0104604:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0104607:	89 44 24 04          	mov    %eax,0x4(%esp)
f010460b:	c7 04 24 2c 85 10 f0 	movl   $0xf010852c,(%esp)
f0104612:	e8 f3 fc ff ff       	call   f010430a <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0104617:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010461b:	75 51                	jne    f010466e <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010461d:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0104620:	89 c2                	mov    %eax,%edx
f0104622:	83 e2 01             	and    $0x1,%edx
f0104625:	ba a0 84 10 f0       	mov    $0xf01084a0,%edx
f010462a:	b9 ab 84 10 f0       	mov    $0xf01084ab,%ecx
f010462f:	0f 45 ca             	cmovne %edx,%ecx
f0104632:	89 c2                	mov    %eax,%edx
f0104634:	83 e2 02             	and    $0x2,%edx
f0104637:	ba b7 84 10 f0       	mov    $0xf01084b7,%edx
f010463c:	be bd 84 10 f0       	mov    $0xf01084bd,%esi
f0104641:	0f 44 d6             	cmove  %esi,%edx
f0104644:	83 e0 04             	and    $0x4,%eax
f0104647:	b8 c2 84 10 f0       	mov    $0xf01084c2,%eax
f010464c:	be 18 86 10 f0       	mov    $0xf0108618,%esi
f0104651:	0f 44 c6             	cmove  %esi,%eax
f0104654:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104658:	89 54 24 08          	mov    %edx,0x8(%esp)
f010465c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104660:	c7 04 24 3a 85 10 f0 	movl   $0xf010853a,(%esp)
f0104667:	e8 9e fc ff ff       	call   f010430a <cprintf>
f010466c:	eb 0c                	jmp    f010467a <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010466e:	c7 04 24 a2 85 10 f0 	movl   $0xf01085a2,(%esp)
f0104675:	e8 90 fc ff ff       	call   f010430a <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010467a:	8b 43 30             	mov    0x30(%ebx),%eax
f010467d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104681:	c7 04 24 49 85 10 f0 	movl   $0xf0108549,(%esp)
f0104688:	e8 7d fc ff ff       	call   f010430a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010468d:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104691:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104695:	c7 04 24 58 85 10 f0 	movl   $0xf0108558,(%esp)
f010469c:	e8 69 fc ff ff       	call   f010430a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01046a1:	8b 43 38             	mov    0x38(%ebx),%eax
f01046a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046a8:	c7 04 24 6b 85 10 f0 	movl   $0xf010856b,(%esp)
f01046af:	e8 56 fc ff ff       	call   f010430a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01046b4:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01046b8:	74 27                	je     f01046e1 <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01046ba:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01046bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046c1:	c7 04 24 7a 85 10 f0 	movl   $0xf010857a,(%esp)
f01046c8:	e8 3d fc ff ff       	call   f010430a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01046cd:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01046d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046d5:	c7 04 24 89 85 10 f0 	movl   $0xf0108589,(%esp)
f01046dc:	e8 29 fc ff ff       	call   f010430a <cprintf>
	}
}
f01046e1:	83 c4 10             	add    $0x10,%esp
f01046e4:	5b                   	pop    %ebx
f01046e5:	5e                   	pop    %esi
f01046e6:	5d                   	pop    %ebp
f01046e7:	c3                   	ret    

f01046e8 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01046e8:	55                   	push   %ebp
f01046e9:	89 e5                	mov    %esp,%ebp
f01046eb:	57                   	push   %edi
f01046ec:	56                   	push   %esi
f01046ed:	53                   	push   %ebx
f01046ee:	83 ec 1c             	sub    $0x1c,%esp
f01046f1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01046f4:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) != 3) {
f01046f7:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01046fb:	83 e0 03             	and    $0x3,%eax
f01046fe:	66 83 f8 03          	cmp    $0x3,%ax
f0104702:	74 2c                	je     f0104730 <page_fault_handler+0x48>
		cprintf("%08x: \n",fault_va);
f0104704:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104708:	c7 04 24 9c 85 10 f0 	movl   $0xf010859c,(%esp)
f010470f:	e8 f6 fb ff ff       	call   f010430a <cprintf>
		panic("Kernel level page fault!");
f0104714:	c7 44 24 08 a4 85 10 	movl   $0xf01085a4,0x8(%esp)
f010471b:	f0 
f010471c:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
f0104723:	00 
f0104724:	c7 04 24 bd 85 10 f0 	movl   $0xf01085bd,(%esp)
f010472b:	e8 10 b9 ff ff       	call   f0100040 <_panic>
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if (curenv->env_pgfault_upcall != NULL) {
f0104730:	e8 a4 21 00 00       	call   f01068d9 <cpunum>
f0104735:	6b c0 74             	imul   $0x74,%eax,%eax
f0104738:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010473e:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0104742:	0f 84 5c 02 00 00    	je     f01049a4 <page_fault_handler+0x2bc>
		if (curenv->env_tf.tf_esp < UXSTACKTOP && curenv->env_tf.tf_esp >= UXSTACKTOP-PGSIZE) {
f0104748:	e8 8c 21 00 00       	call   f01068d9 <cpunum>
f010474d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104750:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104756:	81 78 3c ff ff bf ee 	cmpl   $0xeebfffff,0x3c(%eax)
f010475d:	0f 87 42 01 00 00    	ja     f01048a5 <page_fault_handler+0x1bd>
f0104763:	e8 71 21 00 00       	call   f01068d9 <cpunum>
f0104768:	6b c0 74             	imul   $0x74,%eax,%eax
f010476b:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104771:	81 78 3c ff ef bf ee 	cmpl   $0xeebfefff,0x3c(%eax)
f0104778:	0f 86 27 01 00 00    	jbe    f01048a5 <page_fault_handler+0x1bd>
			// Recursive page fault at user exceptional stack
			uint32_t uxaddr = UXSTACKTOP-(uint32_t)ROUNDUP((UXSTACKTOP-curenv->env_tf.tf_esp), sizeof(struct UTrapframe));
f010477e:	e8 56 21 00 00       	call   f01068d9 <cpunum>
f0104783:	6b c0 74             	imul   $0x74,%eax,%eax
f0104786:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010478c:	b9 33 00 c0 ee       	mov    $0xeec00033,%ecx
f0104791:	2b 48 3c             	sub    0x3c(%eax),%ecx
f0104794:	bb 34 00 00 00       	mov    $0x34,%ebx
f0104799:	89 c8                	mov    %ecx,%eax
f010479b:	ba 00 00 00 00       	mov    $0x0,%edx
f01047a0:	f7 f3                	div    %ebx
f01047a2:	29 d1                	sub    %edx,%ecx
f01047a4:	89 cf                	mov    %ecx,%edi
			user_mem_assert(curenv,(void*)(uxaddr-4-sizeof(struct UTrapframe)),1,PTE_U|PTE_W);
f01047a6:	bb c8 ff bf ee       	mov    $0xeebfffc8,%ebx
f01047ab:	29 cb                	sub    %ecx,%ebx
f01047ad:	e8 27 21 00 00       	call   f01068d9 <cpunum>
f01047b2:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01047b9:	00 
f01047ba:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01047c1:	00 
f01047c2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01047c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01047c9:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01047cf:	89 04 24             	mov    %eax,(%esp)
f01047d2:	e8 53 f1 ff ff       	call   f010392a <user_mem_assert>
			//cprintf("%p: uxaddr:%p, UTrapframe size: %d\n",fault_va,uxaddr,sizeof(struct UTrapframe));
			memset((void*)(uxaddr-4),0,4);
f01047d7:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f01047de:	00 
f01047df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01047e6:	00 
f01047e7:	b8 fc ff bf ee       	mov    $0xeebffffc,%eax
f01047ec:	29 f8                	sub    %edi,%eax
f01047ee:	89 04 24             	mov    %eax,(%esp)
f01047f1:	e8 91 1a 00 00       	call   f0106287 <memset>
			struct UTrapframe *uxtf = (struct UTrapframe*)(uxaddr-4-sizeof(struct UTrapframe));
			uxtf->utf_esp = curenv->env_tf.tf_esp;
f01047f6:	e8 de 20 00 00       	call   f01068d9 <cpunum>
f01047fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01047fe:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104804:	8b 40 3c             	mov    0x3c(%eax),%eax
f0104807:	89 43 30             	mov    %eax,0x30(%ebx)
	                uxtf->utf_eflags = curenv->env_tf.tf_eflags;
f010480a:	e8 ca 20 00 00       	call   f01068d9 <cpunum>
f010480f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104812:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104818:	8b 40 38             	mov    0x38(%eax),%eax
f010481b:	89 43 2c             	mov    %eax,0x2c(%ebx)
			uxtf->utf_eip = curenv->env_tf.tf_eip;
f010481e:	e8 b6 20 00 00       	call   f01068d9 <cpunum>
f0104823:	6b c0 74             	imul   $0x74,%eax,%eax
f0104826:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010482c:	8b 40 30             	mov    0x30(%eax),%eax
f010482f:	89 43 28             	mov    %eax,0x28(%ebx)
        	        memmove(&uxtf->utf_regs,&curenv->env_tf.tf_regs, sizeof(struct PushRegs));
f0104832:	e8 a2 20 00 00       	call   f01068d9 <cpunum>
f0104837:	c7 44 24 08 20 00 00 	movl   $0x20,0x8(%esp)
f010483e:	00 
f010483f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104842:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104848:	89 44 24 04          	mov    %eax,0x4(%esp)
f010484c:	8d 43 08             	lea    0x8(%ebx),%eax
f010484f:	89 04 24             	mov    %eax,(%esp)
f0104852:	e8 7d 1a 00 00       	call   f01062d4 <memmove>
                	uxtf->utf_err = curenv->env_tf.tf_err;
f0104857:	e8 7d 20 00 00       	call   f01068d9 <cpunum>
f010485c:	6b c0 74             	imul   $0x74,%eax,%eax
f010485f:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104865:	8b 40 2c             	mov    0x2c(%eax),%eax
f0104868:	89 43 04             	mov    %eax,0x4(%ebx)
	                uxtf->utf_fault_va = fault_va;
f010486b:	89 33                	mov    %esi,(%ebx)
			
			//Modify the trapframe to redirect to user handler
			curenv->env_tf.tf_esp = uxaddr-4-sizeof(struct UTrapframe);
f010486d:	e8 67 20 00 00       	call   f01068d9 <cpunum>
f0104872:	6b c0 74             	imul   $0x74,%eax,%eax
f0104875:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010487b:	89 58 3c             	mov    %ebx,0x3c(%eax)
			curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
f010487e:	e8 56 20 00 00       	call   f01068d9 <cpunum>
f0104883:	6b c0 74             	imul   $0x74,%eax,%eax
f0104886:	8b 98 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%ebx
f010488c:	e8 48 20 00 00       	call   f01068d9 <cpunum>
f0104891:	6b c0 74             	imul   $0x74,%eax,%eax
f0104894:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010489a:	8b 40 64             	mov    0x64(%eax),%eax
f010489d:	89 43 30             	mov    %eax,0x30(%ebx)
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if (curenv->env_pgfault_upcall != NULL) {
		if (curenv->env_tf.tf_esp < UXSTACKTOP && curenv->env_tf.tf_esp >= UXSTACKTOP-PGSIZE) {
f01048a0:	e9 e9 00 00 00       	jmp    f010498e <page_fault_handler+0x2a6>
			
			//Modify the trapframe to redirect to user handler
			curenv->env_tf.tf_esp = uxaddr-4-sizeof(struct UTrapframe);
			curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
		} else {
			user_mem_assert(curenv,(void*)(UXSTACKTOP-sizeof(struct UTrapframe)),1,PTE_U|PTE_W);
f01048a5:	e8 2f 20 00 00       	call   f01068d9 <cpunum>
f01048aa:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01048b1:	00 
f01048b2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01048b9:	00 
f01048ba:	c7 44 24 04 cc ff bf 	movl   $0xeebfffcc,0x4(%esp)
f01048c1:	ee 
f01048c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01048c5:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01048cb:	89 04 24             	mov    %eax,(%esp)
f01048ce:	e8 57 f0 ff ff       	call   f010392a <user_mem_assert>
			// Page fault at user normal stack
			struct UTrapframe *uxtf = (struct UTrapframe*)(UXSTACKTOP-sizeof(struct UTrapframe));
			uxtf->utf_esp = curenv->env_tf.tf_esp;
f01048d3:	e8 01 20 00 00       	call   f01068d9 <cpunum>
f01048d8:	6b c0 74             	imul   $0x74,%eax,%eax
f01048db:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01048e1:	8b 40 3c             	mov    0x3c(%eax),%eax
f01048e4:	a3 fc ff bf ee       	mov    %eax,0xeebffffc
			uxtf->utf_eflags = curenv->env_tf.tf_eflags;
f01048e9:	e8 eb 1f 00 00       	call   f01068d9 <cpunum>
f01048ee:	6b c0 74             	imul   $0x74,%eax,%eax
f01048f1:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01048f7:	8b 40 38             	mov    0x38(%eax),%eax
f01048fa:	a3 f8 ff bf ee       	mov    %eax,0xeebffff8
			uxtf->utf_eip = curenv->env_tf.tf_eip;
f01048ff:	e8 d5 1f 00 00       	call   f01068d9 <cpunum>
f0104904:	6b c0 74             	imul   $0x74,%eax,%eax
f0104907:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010490d:	8b 40 30             	mov    0x30(%eax),%eax
f0104910:	a3 f4 ff bf ee       	mov    %eax,0xeebffff4
			memmove(&uxtf->utf_regs,&curenv->env_tf.tf_regs, sizeof(struct PushRegs));
f0104915:	e8 bf 1f 00 00       	call   f01068d9 <cpunum>
f010491a:	c7 44 24 08 20 00 00 	movl   $0x20,0x8(%esp)
f0104921:	00 
f0104922:	6b c0 74             	imul   $0x74,%eax,%eax
f0104925:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010492b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010492f:	c7 04 24 d4 ff bf ee 	movl   $0xeebfffd4,(%esp)
f0104936:	e8 99 19 00 00       	call   f01062d4 <memmove>
			uxtf->utf_err = curenv->env_tf.tf_err;
f010493b:	e8 99 1f 00 00       	call   f01068d9 <cpunum>
f0104940:	6b c0 74             	imul   $0x74,%eax,%eax
f0104943:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104949:	8b 40 2c             	mov    0x2c(%eax),%eax
f010494c:	a3 d0 ff bf ee       	mov    %eax,0xeebfffd0
			uxtf->utf_fault_va = fault_va;
f0104951:	89 35 cc ff bf ee    	mov    %esi,0xeebfffcc
	
			//Modify the trapframe to redirect to user handler
			curenv->env_tf.tf_esp = UXSTACKTOP-sizeof(struct UTrapframe);
f0104957:	e8 7d 1f 00 00       	call   f01068d9 <cpunum>
f010495c:	6b c0 74             	imul   $0x74,%eax,%eax
f010495f:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104965:	c7 40 3c cc ff bf ee 	movl   $0xeebfffcc,0x3c(%eax)
			curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
f010496c:	e8 68 1f 00 00       	call   f01068d9 <cpunum>
f0104971:	6b c0 74             	imul   $0x74,%eax,%eax
f0104974:	8b 98 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%ebx
f010497a:	e8 5a 1f 00 00       	call   f01068d9 <cpunum>
f010497f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104982:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104988:	8b 40 64             	mov    0x64(%eax),%eax
f010498b:	89 43 30             	mov    %eax,0x30(%ebx)
		}
		env_run(curenv);
f010498e:	e8 46 1f 00 00       	call   f01068d9 <cpunum>
f0104993:	6b c0 74             	imul   $0x74,%eax,%eax
f0104996:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010499c:	89 04 24             	mov    %eax,(%esp)
f010499f:	e8 0a f7 ff ff       	call   f01040ae <env_run>
	} else {
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01049a4:	8b 7b 30             	mov    0x30(%ebx),%edi
			curenv->env_id, fault_va, tf->tf_eip);
f01049a7:	e8 2d 1f 00 00       	call   f01068d9 <cpunum>
			curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
		}
		env_run(curenv);
	} else {
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01049ac:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01049b0:	89 74 24 08          	mov    %esi,0x8(%esp)
			curenv->env_id, fault_va, tf->tf_eip);
f01049b4:	6b c0 74             	imul   $0x74,%eax,%eax
			curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
		}
		env_run(curenv);
	} else {
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01049b7:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01049bd:	8b 40 48             	mov    0x48(%eax),%eax
f01049c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049c4:	c7 04 24 64 87 10 f0 	movl   $0xf0108764,(%esp)
f01049cb:	e8 3a f9 ff ff       	call   f010430a <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f01049d0:	89 1c 24             	mov    %ebx,(%esp)
f01049d3:	e8 73 fb ff ff       	call   f010454b <print_trapframe>
		env_destroy(curenv);
f01049d8:	e8 fc 1e 00 00       	call   f01068d9 <cpunum>
f01049dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01049e0:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01049e6:	89 04 24             	mov    %eax,(%esp)
f01049e9:	e8 1f f6 ff ff       	call   f010400d <env_destroy>
	}
}
f01049ee:	83 c4 1c             	add    $0x1c,%esp
f01049f1:	5b                   	pop    %ebx
f01049f2:	5e                   	pop    %esi
f01049f3:	5f                   	pop    %edi
f01049f4:	5d                   	pop    %ebp
f01049f5:	c3                   	ret    

f01049f6 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01049f6:	55                   	push   %ebp
f01049f7:	89 e5                	mov    %esp,%ebp
f01049f9:	57                   	push   %edi
f01049fa:	56                   	push   %esi
f01049fb:	83 ec 20             	sub    $0x20,%esp
f01049fe:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0104a01:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0104a02:	83 3d 80 3e 23 f0 00 	cmpl   $0x0,0xf0233e80
f0104a09:	74 01                	je     f0104a0c <trap+0x16>
		asm volatile("hlt");
f0104a0b:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104a0c:	e8 c8 1e 00 00       	call   f01068d9 <cpunum>
f0104a11:	6b d0 74             	imul   $0x74,%eax,%edx
f0104a14:	81 c2 20 40 23 f0    	add    $0xf0234020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104a1a:	b8 01 00 00 00       	mov    $0x1,%eax
f0104a1f:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104a23:	83 f8 02             	cmp    $0x2,%eax
f0104a26:	75 0c                	jne    f0104a34 <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104a28:	c7 04 24 80 24 12 f0 	movl   $0xf0122480,(%esp)
f0104a2f:	e8 23 21 00 00       	call   f0106b57 <spin_lock>

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104a34:	9c                   	pushf  
f0104a35:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104a36:	f6 c4 02             	test   $0x2,%ah
f0104a39:	74 24                	je     f0104a5f <trap+0x69>
f0104a3b:	c7 44 24 0c c9 85 10 	movl   $0xf01085c9,0xc(%esp)
f0104a42:	f0 
f0104a43:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0104a4a:	f0 
f0104a4b:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
f0104a52:	00 
f0104a53:	c7 04 24 bd 85 10 f0 	movl   $0xf01085bd,(%esp)
f0104a5a:	e8 e1 b5 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0104a5f:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104a63:	83 e0 03             	and    $0x3,%eax
f0104a66:	66 83 f8 03          	cmp    $0x3,%ax
f0104a6a:	0f 85 a7 00 00 00    	jne    f0104b17 <trap+0x121>
f0104a70:	c7 04 24 80 24 12 f0 	movl   $0xf0122480,(%esp)
f0104a77:	e8 db 20 00 00       	call   f0106b57 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0104a7c:	e8 58 1e 00 00       	call   f01068d9 <cpunum>
f0104a81:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a84:	83 b8 28 40 23 f0 00 	cmpl   $0x0,-0xfdcbfd8(%eax)
f0104a8b:	75 24                	jne    f0104ab1 <trap+0xbb>
f0104a8d:	c7 44 24 0c e2 85 10 	movl   $0xf01085e2,0xc(%esp)
f0104a94:	f0 
f0104a95:	c7 44 24 08 5b 80 10 	movl   $0xf010805b,0x8(%esp)
f0104a9c:	f0 
f0104a9d:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
f0104aa4:	00 
f0104aa5:	c7 04 24 bd 85 10 f0 	movl   $0xf01085bd,(%esp)
f0104aac:	e8 8f b5 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0104ab1:	e8 23 1e 00 00       	call   f01068d9 <cpunum>
f0104ab6:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ab9:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104abf:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0104ac3:	75 2d                	jne    f0104af2 <trap+0xfc>
			env_free(curenv);
f0104ac5:	e8 0f 1e 00 00       	call   f01068d9 <cpunum>
f0104aca:	6b c0 74             	imul   $0x74,%eax,%eax
f0104acd:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104ad3:	89 04 24             	mov    %eax,(%esp)
f0104ad6:	e8 2d f3 ff ff       	call   f0103e08 <env_free>
			curenv = NULL;
f0104adb:	e8 f9 1d 00 00       	call   f01068d9 <cpunum>
f0104ae0:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ae3:	c7 80 28 40 23 f0 00 	movl   $0x0,-0xfdcbfd8(%eax)
f0104aea:	00 00 00 
			sched_yield();
f0104aed:	e8 fe 03 00 00       	call   f0104ef0 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0104af2:	e8 e2 1d 00 00       	call   f01068d9 <cpunum>
f0104af7:	6b c0 74             	imul   $0x74,%eax,%eax
f0104afa:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104b00:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104b05:	89 c7                	mov    %eax,%edi
f0104b07:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0104b09:	e8 cb 1d 00 00       	call   f01068d9 <cpunum>
f0104b0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b11:	8b b0 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104b17:	89 35 60 3a 23 f0    	mov    %esi,0xf0233a60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) {
f0104b1d:	8b 46 28             	mov    0x28(%esi),%eax
f0104b20:	83 f8 0e             	cmp    $0xe,%eax
f0104b23:	75 0d                	jne    f0104b32 <trap+0x13c>
		page_fault_handler(tf);
f0104b25:	89 34 24             	mov    %esi,(%esp)
f0104b28:	e8 bb fb ff ff       	call   f01046e8 <page_fault_handler>
f0104b2d:	e9 b9 00 00 00       	jmp    f0104beb <trap+0x1f5>
		return;
	}
	if (tf->tf_trapno == T_BRKPT)
f0104b32:	83 f8 03             	cmp    $0x3,%eax
f0104b35:	75 08                	jne    f0104b3f <trap+0x149>
		monitor(tf);
f0104b37:	89 34 24             	mov    %esi,(%esp)
f0104b3a:	e8 db be ff ff       	call   f0100a1a <monitor>
	uint32_t ret=0;
	if (tf->tf_trapno == T_SYSCALL) {
f0104b3f:	8b 46 28             	mov    0x28(%esi),%eax
f0104b42:	83 f8 30             	cmp    $0x30,%eax
f0104b45:	75 32                	jne    f0104b79 <trap+0x183>
		ret = syscall(tf->tf_regs.reg_eax, 
f0104b47:	8b 46 04             	mov    0x4(%esi),%eax
f0104b4a:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104b4e:	8b 06                	mov    (%esi),%eax
f0104b50:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104b54:	8b 46 10             	mov    0x10(%esi),%eax
f0104b57:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104b5b:	8b 46 18             	mov    0x18(%esi),%eax
f0104b5e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104b62:	8b 46 14             	mov    0x14(%esi),%eax
f0104b65:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b69:	8b 46 1c             	mov    0x1c(%esi),%eax
f0104b6c:	89 04 24             	mov    %eax,(%esp)
f0104b6f:	e8 9c 04 00 00       	call   f0105010 <syscall>
				tf->tf_regs.reg_edx,
				tf->tf_regs.reg_ecx,
				tf->tf_regs.reg_ebx,
				tf->tf_regs.reg_edi,
				tf->tf_regs.reg_esi);
		tf->tf_regs.reg_eax = ret;
f0104b74:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104b77:	eb 72                	jmp    f0104beb <trap+0x1f5>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104b79:	83 f8 27             	cmp    $0x27,%eax
f0104b7c:	75 16                	jne    f0104b94 <trap+0x19e>
		cprintf("Spurious interrupt on irq 7\n");
f0104b7e:	c7 04 24 e9 85 10 f0 	movl   $0xf01085e9,(%esp)
f0104b85:	e8 80 f7 ff ff       	call   f010430a <cprintf>
		print_trapframe(tf);
f0104b8a:	89 34 24             	mov    %esi,(%esp)
f0104b8d:	e8 b9 f9 ff ff       	call   f010454b <print_trapframe>
f0104b92:	eb 57                	jmp    f0104beb <trap+0x1f5>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if (tf->tf_trapno == IRQ_OFFSET+IRQ_TIMER) {
f0104b94:	83 f8 20             	cmp    $0x20,%eax
f0104b97:	75 11                	jne    f0104baa <trap+0x1b4>
		lapic_eoi();
f0104b99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104ba0:	e8 81 1e 00 00       	call   f0106a26 <lapic_eoi>
		sched_yield();
f0104ba5:	e8 46 03 00 00       	call   f0104ef0 <sched_yield>
		return;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0104baa:	89 34 24             	mov    %esi,(%esp)
f0104bad:	e8 99 f9 ff ff       	call   f010454b <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104bb2:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104bb7:	75 1c                	jne    f0104bd5 <trap+0x1df>
		panic("unhandled trap in kernel");
f0104bb9:	c7 44 24 08 06 86 10 	movl   $0xf0108606,0x8(%esp)
f0104bc0:	f0 
f0104bc1:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
f0104bc8:	00 
f0104bc9:	c7 04 24 bd 85 10 f0 	movl   $0xf01085bd,(%esp)
f0104bd0:	e8 6b b4 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0104bd5:	e8 ff 1c 00 00       	call   f01068d9 <cpunum>
f0104bda:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bdd:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104be3:	89 04 24             	mov    %eax,(%esp)
f0104be6:	e8 22 f4 ff ff       	call   f010400d <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104beb:	e8 e9 1c 00 00       	call   f01068d9 <cpunum>
f0104bf0:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bf3:	83 b8 28 40 23 f0 00 	cmpl   $0x0,-0xfdcbfd8(%eax)
f0104bfa:	74 2a                	je     f0104c26 <trap+0x230>
f0104bfc:	e8 d8 1c 00 00       	call   f01068d9 <cpunum>
f0104c01:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c04:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104c0a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104c0e:	75 16                	jne    f0104c26 <trap+0x230>
		env_run(curenv);
f0104c10:	e8 c4 1c 00 00       	call   f01068d9 <cpunum>
f0104c15:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c18:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104c1e:	89 04 24             	mov    %eax,(%esp)
f0104c21:	e8 88 f4 ff ff       	call   f01040ae <env_run>
	else
		sched_yield();
f0104c26:	e8 c5 02 00 00       	call   f0104ef0 <sched_yield>
f0104c2b:	90                   	nop

f0104c2c <vector0>:

.globl vector0
.type vector0, @function
.align 2
vector0:
  pushl $0
f0104c2c:	6a 00                	push   $0x0
  push $0
f0104c2e:	6a 00                	push   $0x0
  jmp _alltraps
f0104c30:	e9 d4 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c35:	90                   	nop

f0104c36 <vector1>:
.globl vector1
.type vector1, @function
.align 2
vector1:
  pushl $0
f0104c36:	6a 00                	push   $0x0
  push $1
f0104c38:	6a 01                	push   $0x1
  jmp _alltraps
f0104c3a:	e9 ca 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c3f:	90                   	nop

f0104c40 <vector2>:
.globl vector2
.type vector2, @function
.align 2
vector2:
  pushl $0
f0104c40:	6a 00                	push   $0x0
  push $2
f0104c42:	6a 02                	push   $0x2
  jmp _alltraps
f0104c44:	e9 c0 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c49:	90                   	nop

f0104c4a <vector3>:
.globl vector3
.type vector3, @function
.align 2
vector3:
  pushl $0
f0104c4a:	6a 00                	push   $0x0
  push $3
f0104c4c:	6a 03                	push   $0x3
  jmp _alltraps
f0104c4e:	e9 b6 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c53:	90                   	nop

f0104c54 <vector4>:
.globl vector4
.type vector4, @function
.align 2
vector4:
  pushl $0
f0104c54:	6a 00                	push   $0x0
  push $4
f0104c56:	6a 04                	push   $0x4
  jmp _alltraps
f0104c58:	e9 ac 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c5d:	90                   	nop

f0104c5e <vector5>:
.globl vector5
.type vector5, @function
.align 2
vector5:
  pushl $0
f0104c5e:	6a 00                	push   $0x0
  push $5
f0104c60:	6a 05                	push   $0x5
  jmp _alltraps
f0104c62:	e9 a2 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c67:	90                   	nop

f0104c68 <vector6>:
.globl vector6
.type vector6, @function
.align 2
vector6:
  pushl $0
f0104c68:	6a 00                	push   $0x0
  push $6
f0104c6a:	6a 06                	push   $0x6
  jmp _alltraps
f0104c6c:	e9 98 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c71:	90                   	nop

f0104c72 <vector7>:
.globl vector7
.type vector7, @function
.align 2
vector7:
  pushl $0
f0104c72:	6a 00                	push   $0x0
  push $7
f0104c74:	6a 07                	push   $0x7
  jmp _alltraps
f0104c76:	e9 8e 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c7b:	90                   	nop

f0104c7c <vector8>:
.globl vector8
.type vector8, @function
.align 2
vector8:
  push $8
f0104c7c:	6a 08                	push   $0x8
  jmp _alltraps
f0104c7e:	e9 86 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c83:	90                   	nop

f0104c84 <vector9>:
.globl vector9
.type vector9, @function
.align 2
vector9:
  pushl $0
f0104c84:	6a 00                	push   $0x0
  push $9
f0104c86:	6a 09                	push   $0x9
  jmp _alltraps
f0104c88:	e9 7c 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c8d:	90                   	nop

f0104c8e <vector10>:
.globl vector10
.type vector10, @function
.align 2
vector10:
  push $10
f0104c8e:	6a 0a                	push   $0xa
  jmp _alltraps
f0104c90:	e9 74 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c95:	90                   	nop

f0104c96 <vector11>:
.globl vector11
.type vector11, @function
.align 2
vector11:
  push $11
f0104c96:	6a 0b                	push   $0xb
  jmp _alltraps
f0104c98:	e9 6c 01 00 00       	jmp    f0104e09 <_alltraps>
f0104c9d:	90                   	nop

f0104c9e <vector12>:
.globl vector12
.type vector12, @function
.align 2
vector12:
  push $12
f0104c9e:	6a 0c                	push   $0xc
  jmp _alltraps
f0104ca0:	e9 64 01 00 00       	jmp    f0104e09 <_alltraps>
f0104ca5:	90                   	nop

f0104ca6 <vector13>:
.globl vector13
.type vector13, @function
.align 2
vector13:
  push $13
f0104ca6:	6a 0d                	push   $0xd
  jmp _alltraps
f0104ca8:	e9 5c 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cad:	90                   	nop

f0104cae <vector14>:
.globl vector14
.type vector14, @function
.align 2
vector14:
  push $14
f0104cae:	6a 0e                	push   $0xe
  jmp _alltraps
f0104cb0:	e9 54 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cb5:	90                   	nop

f0104cb6 <vector15>:
.globl vector15
.type vector15, @function
.align 2
vector15:
  pushl $0
f0104cb6:	6a 00                	push   $0x0
  push $15
f0104cb8:	6a 0f                	push   $0xf
  jmp _alltraps
f0104cba:	e9 4a 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cbf:	90                   	nop

f0104cc0 <vector16>:
.globl vector16
.type vector16, @function
.align 2
vector16:
  pushl $0
f0104cc0:	6a 00                	push   $0x0
  push $16
f0104cc2:	6a 10                	push   $0x10
  jmp _alltraps
f0104cc4:	e9 40 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cc9:	90                   	nop

f0104cca <vector17>:
.globl vector17
.type vector17, @function
.align 2
vector17:
  pushl $0
f0104cca:	6a 00                	push   $0x0
  push $17
f0104ccc:	6a 11                	push   $0x11
  jmp _alltraps
f0104cce:	e9 36 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cd3:	90                   	nop

f0104cd4 <vector18>:
.globl vector18
.type vector18, @function
.align 2
vector18:
  pushl $0
f0104cd4:	6a 00                	push   $0x0
  push $18
f0104cd6:	6a 12                	push   $0x12
  jmp _alltraps
f0104cd8:	e9 2c 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cdd:	90                   	nop

f0104cde <vector19>:
.globl vector19
.type vector19, @function
.align 2
vector19:
  pushl $0
f0104cde:	6a 00                	push   $0x0
  push $19
f0104ce0:	6a 13                	push   $0x13
  jmp _alltraps
f0104ce2:	e9 22 01 00 00       	jmp    f0104e09 <_alltraps>
f0104ce7:	90                   	nop

f0104ce8 <vector20>:
.globl vector20
.type vector20, @function
.align 2
vector20:
  pushl $0
f0104ce8:	6a 00                	push   $0x0
  push $20
f0104cea:	6a 14                	push   $0x14
  jmp _alltraps
f0104cec:	e9 18 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cf1:	90                   	nop

f0104cf2 <vector21>:
.globl vector21
.type vector21, @function
.align 2
vector21:
  pushl $0
f0104cf2:	6a 00                	push   $0x0
  push $21
f0104cf4:	6a 15                	push   $0x15
  jmp _alltraps
f0104cf6:	e9 0e 01 00 00       	jmp    f0104e09 <_alltraps>
f0104cfb:	90                   	nop

f0104cfc <vector22>:
.globl vector22
.type vector22, @function
.align 2
vector22:
  pushl $0
f0104cfc:	6a 00                	push   $0x0
  push $22
f0104cfe:	6a 16                	push   $0x16
  jmp _alltraps
f0104d00:	e9 04 01 00 00       	jmp    f0104e09 <_alltraps>
f0104d05:	90                   	nop

f0104d06 <vector23>:
.globl vector23
.type vector23, @function
.align 2
vector23:
  pushl $0
f0104d06:	6a 00                	push   $0x0
  push $23
f0104d08:	6a 17                	push   $0x17
  jmp _alltraps
f0104d0a:	e9 fa 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d0f:	90                   	nop

f0104d10 <vector24>:
.globl vector24
.type vector24, @function
.align 2
vector24:
  pushl $0
f0104d10:	6a 00                	push   $0x0
  push $24
f0104d12:	6a 18                	push   $0x18
  jmp _alltraps
f0104d14:	e9 f0 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d19:	90                   	nop

f0104d1a <vector25>:
.globl vector25
.type vector25, @function
.align 2
vector25:
  pushl $0
f0104d1a:	6a 00                	push   $0x0
  push $25
f0104d1c:	6a 19                	push   $0x19
  jmp _alltraps
f0104d1e:	e9 e6 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d23:	90                   	nop

f0104d24 <vector26>:
.globl vector26
.type vector26, @function
.align 2
vector26:
  pushl $0
f0104d24:	6a 00                	push   $0x0
  push $26
f0104d26:	6a 1a                	push   $0x1a
  jmp _alltraps
f0104d28:	e9 dc 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d2d:	90                   	nop

f0104d2e <vector27>:
.globl vector27
.type vector27, @function
.align 2
vector27:
  pushl $0
f0104d2e:	6a 00                	push   $0x0
  push $27
f0104d30:	6a 1b                	push   $0x1b
  jmp _alltraps
f0104d32:	e9 d2 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d37:	90                   	nop

f0104d38 <vector28>:
.globl vector28
.type vector28, @function
.align 2
vector28:
  pushl $0
f0104d38:	6a 00                	push   $0x0
  push $28
f0104d3a:	6a 1c                	push   $0x1c
  jmp _alltraps
f0104d3c:	e9 c8 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d41:	90                   	nop

f0104d42 <vector29>:
.globl vector29
.type vector29, @function
.align 2
vector29:
  pushl $0
f0104d42:	6a 00                	push   $0x0
  push $29
f0104d44:	6a 1d                	push   $0x1d
  jmp _alltraps
f0104d46:	e9 be 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d4b:	90                   	nop

f0104d4c <vector30>:
.globl vector30
.type vector30, @function
.align 2
vector30:
  pushl $0
f0104d4c:	6a 00                	push   $0x0
  push $30
f0104d4e:	6a 1e                	push   $0x1e
  jmp _alltraps
f0104d50:	e9 b4 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d55:	90                   	nop

f0104d56 <vector31>:
.globl vector31
.type vector31, @function
.align 2
vector31:
  pushl $0
f0104d56:	6a 00                	push   $0x0
  push $31
f0104d58:	6a 1f                	push   $0x1f
  jmp _alltraps
f0104d5a:	e9 aa 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d5f:	90                   	nop

f0104d60 <vector32>:
.globl vector32
.type vector32, @function
.align 2
vector32:
  pushl $0
f0104d60:	6a 00                	push   $0x0
  push $32
f0104d62:	6a 20                	push   $0x20
  jmp _alltraps
f0104d64:	e9 a0 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d69:	90                   	nop

f0104d6a <vector33>:
.globl vector33
.type vector33, @function
.align 2
vector33:
  pushl $0
f0104d6a:	6a 00                	push   $0x0
  push $33
f0104d6c:	6a 21                	push   $0x21
  jmp _alltraps
f0104d6e:	e9 96 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d73:	90                   	nop

f0104d74 <vector34>:
.globl vector34
.type vector34, @function
.align 2
vector34:
  pushl $0
f0104d74:	6a 00                	push   $0x0
  push $34
f0104d76:	6a 22                	push   $0x22
  jmp _alltraps
f0104d78:	e9 8c 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d7d:	90                   	nop

f0104d7e <vector35>:
.globl vector35
.type vector35, @function
.align 2
vector35:
  pushl $0
f0104d7e:	6a 00                	push   $0x0
  push $35
f0104d80:	6a 23                	push   $0x23
  jmp _alltraps
f0104d82:	e9 82 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d87:	90                   	nop

f0104d88 <vector36>:
.globl vector36
.type vector36, @function
.align 2
vector36:
  pushl $0
f0104d88:	6a 00                	push   $0x0
  push $36
f0104d8a:	6a 24                	push   $0x24
  jmp _alltraps
f0104d8c:	e9 78 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d91:	90                   	nop

f0104d92 <vector37>:
.globl vector37
.type vector37, @function
.align 2
vector37:
  pushl $0
f0104d92:	6a 00                	push   $0x0
  push $37
f0104d94:	6a 25                	push   $0x25
  jmp _alltraps
f0104d96:	e9 6e 00 00 00       	jmp    f0104e09 <_alltraps>
f0104d9b:	90                   	nop

f0104d9c <vector38>:
.globl vector38
.type vector38, @function
.align 2
vector38:
  pushl $0
f0104d9c:	6a 00                	push   $0x0
  push $38
f0104d9e:	6a 26                	push   $0x26
  jmp _alltraps
f0104da0:	e9 64 00 00 00       	jmp    f0104e09 <_alltraps>
f0104da5:	90                   	nop

f0104da6 <vector39>:
.globl vector39
.type vector39, @function
.align 2
vector39:
  pushl $0
f0104da6:	6a 00                	push   $0x0
  push $39
f0104da8:	6a 27                	push   $0x27
  jmp _alltraps
f0104daa:	e9 5a 00 00 00       	jmp    f0104e09 <_alltraps>
f0104daf:	90                   	nop

f0104db0 <vector40>:
.globl vector40
.type vector40, @function
.align 2
vector40:
  pushl $0
f0104db0:	6a 00                	push   $0x0
  push $40
f0104db2:	6a 28                	push   $0x28
  jmp _alltraps
f0104db4:	e9 50 00 00 00       	jmp    f0104e09 <_alltraps>
f0104db9:	90                   	nop

f0104dba <vector41>:
.globl vector41
.type vector41, @function
.align 2
vector41:
  pushl $0
f0104dba:	6a 00                	push   $0x0
  push $41
f0104dbc:	6a 29                	push   $0x29
  jmp _alltraps
f0104dbe:	e9 46 00 00 00       	jmp    f0104e09 <_alltraps>
f0104dc3:	90                   	nop

f0104dc4 <vector42>:
.globl vector42
.type vector42, @function
.align 2
vector42:
  pushl $0
f0104dc4:	6a 00                	push   $0x0
  push $42
f0104dc6:	6a 2a                	push   $0x2a
  jmp _alltraps
f0104dc8:	e9 3c 00 00 00       	jmp    f0104e09 <_alltraps>
f0104dcd:	90                   	nop

f0104dce <vector43>:
.globl vector43
.type vector43, @function
.align 2
vector43:
  pushl $0
f0104dce:	6a 00                	push   $0x0
  push $43
f0104dd0:	6a 2b                	push   $0x2b
  jmp _alltraps
f0104dd2:	e9 32 00 00 00       	jmp    f0104e09 <_alltraps>
f0104dd7:	90                   	nop

f0104dd8 <vector44>:
.globl vector44
.type vector44, @function
.align 2
vector44:
  pushl $0
f0104dd8:	6a 00                	push   $0x0
  push $44
f0104dda:	6a 2c                	push   $0x2c
  jmp _alltraps
f0104ddc:	e9 28 00 00 00       	jmp    f0104e09 <_alltraps>
f0104de1:	90                   	nop

f0104de2 <vector45>:
.globl vector45
.type vector45, @function
.align 2
vector45:
  pushl $0
f0104de2:	6a 00                	push   $0x0
  push $45
f0104de4:	6a 2d                	push   $0x2d
  jmp _alltraps
f0104de6:	e9 1e 00 00 00       	jmp    f0104e09 <_alltraps>
f0104deb:	90                   	nop

f0104dec <vector46>:
.globl vector46
.type vector46, @function
.align 2
vector46:
  pushl $0
f0104dec:	6a 00                	push   $0x0
  push $46
f0104dee:	6a 2e                	push   $0x2e
  jmp _alltraps
f0104df0:	e9 14 00 00 00       	jmp    f0104e09 <_alltraps>
f0104df5:	90                   	nop

f0104df6 <vector47>:
.globl vector47
.type vector47, @function
.align 2
vector47:
  pushl $0
f0104df6:	6a 00                	push   $0x0
  push $47
f0104df8:	6a 2f                	push   $0x2f
  jmp _alltraps
f0104dfa:	e9 0a 00 00 00       	jmp    f0104e09 <_alltraps>
f0104dff:	90                   	nop

f0104e00 <vector48>:
.globl vector48
.type vector48, @function
.align 2
vector48:
  pushl $0
f0104e00:	6a 00                	push   $0x0
  push $48
f0104e02:	6a 30                	push   $0x30
  jmp _alltraps
f0104e04:	e9 00 00 00 00       	jmp    f0104e09 <_alltraps>

f0104e09 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.globl _alltraps
_alltraps:
  pushl %ds
f0104e09:	1e                   	push   %ds
  pushl %es
f0104e0a:	06                   	push   %es
  pushal
f0104e0b:	60                   	pusha  

  movw $(GD_KD), %ax
f0104e0c:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
f0104e10:	8e d8                	mov    %eax,%ds
  movw %ax, %es
f0104e12:	8e c0                	mov    %eax,%es

  pushl %esp
f0104e14:	54                   	push   %esp
  call trap
f0104e15:	e8 dc fb ff ff       	call   f01049f6 <trap>

f0104e1a <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104e1a:	55                   	push   %ebp
f0104e1b:	89 e5                	mov    %esp,%ebp
f0104e1d:	83 ec 18             	sub    $0x18,%esp
f0104e20:	8b 15 48 32 23 f0    	mov    0xf0233248,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104e26:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104e2b:	8b 4a 54             	mov    0x54(%edx),%ecx
f0104e2e:	83 e9 01             	sub    $0x1,%ecx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104e31:	83 f9 02             	cmp    $0x2,%ecx
f0104e34:	76 0f                	jbe    f0104e45 <sched_halt+0x2b>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104e36:	83 c0 01             	add    $0x1,%eax
f0104e39:	83 c2 7c             	add    $0x7c,%edx
f0104e3c:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104e41:	75 e8                	jne    f0104e2b <sched_halt+0x11>
f0104e43:	eb 07                	jmp    f0104e4c <sched_halt+0x32>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104e45:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104e4a:	75 1a                	jne    f0104e66 <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f0104e4c:	c7 04 24 f0 87 10 f0 	movl   $0xf01087f0,(%esp)
f0104e53:	e8 b2 f4 ff ff       	call   f010430a <cprintf>
		while (1)
			monitor(NULL);
f0104e58:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104e5f:	e8 b6 bb ff ff       	call   f0100a1a <monitor>
f0104e64:	eb f2                	jmp    f0104e58 <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104e66:	e8 6e 1a 00 00       	call   f01068d9 <cpunum>
f0104e6b:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e6e:	c7 80 28 40 23 f0 00 	movl   $0x0,-0xfdcbfd8(%eax)
f0104e75:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104e78:	a1 8c 3e 23 f0       	mov    0xf0233e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104e7d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104e82:	77 20                	ja     f0104ea4 <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104e84:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104e88:	c7 44 24 08 08 70 10 	movl   $0xf0107008,0x8(%esp)
f0104e8f:	f0 
f0104e90:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0104e97:	00 
f0104e98:	c7 04 24 19 88 10 f0 	movl   $0xf0108819,(%esp)
f0104e9f:	e8 9c b1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104ea4:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104ea9:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104eac:	e8 28 1a 00 00       	call   f01068d9 <cpunum>
f0104eb1:	6b d0 74             	imul   $0x74,%eax,%edx
f0104eb4:	81 c2 20 40 23 f0    	add    $0xf0234020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104eba:	b8 02 00 00 00       	mov    $0x2,%eax
f0104ebf:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104ec3:	c7 04 24 80 24 12 f0 	movl   $0xf0122480,(%esp)
f0104eca:	e8 34 1d 00 00       	call   f0106c03 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104ecf:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104ed1:	e8 03 1a 00 00       	call   f01068d9 <cpunum>
f0104ed6:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104ed9:	8b 80 30 40 23 f0    	mov    -0xfdcbfd0(%eax),%eax
f0104edf:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104ee4:	89 c4                	mov    %eax,%esp
f0104ee6:	6a 00                	push   $0x0
f0104ee8:	6a 00                	push   $0x0
f0104eea:	fb                   	sti    
f0104eeb:	f4                   	hlt    
f0104eec:	eb fd                	jmp    f0104eeb <sched_halt+0xd1>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104eee:	c9                   	leave  
f0104eef:	c3                   	ret    

f0104ef0 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104ef0:	55                   	push   %ebp
f0104ef1:	89 e5                	mov    %esp,%ebp
f0104ef3:	57                   	push   %edi
f0104ef4:	56                   	push   %esi
f0104ef5:	53                   	push   %ebx
f0104ef6:	83 ec 1c             	sub    $0x1c,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
		
	int i=0;
	if (curenv) {
f0104ef9:	e8 db 19 00 00       	call   f01068d9 <cpunum>
f0104efe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f01:	83 b8 28 40 23 f0 00 	cmpl   $0x0,-0xfdcbfd8(%eax)
f0104f08:	0f 84 c3 00 00 00    	je     f0104fd1 <sched_yield+0xe1>
		for (idle=envs+(curenv-envs+1)%NENV;idle!=curenv;) {
f0104f0e:	e8 c6 19 00 00       	call   f01068d9 <cpunum>
f0104f13:	8b 15 48 32 23 f0    	mov    0xf0233248,%edx
f0104f19:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f1c:	8b 88 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%ecx
f0104f22:	29 d1                	sub    %edx,%ecx
f0104f24:	c1 f9 02             	sar    $0x2,%ecx
f0104f27:	69 c9 df 7b ef bd    	imul   $0xbdef7bdf,%ecx,%ecx
f0104f2d:	83 c1 01             	add    $0x1,%ecx
f0104f30:	89 c8                	mov    %ecx,%eax
f0104f32:	c1 f8 1f             	sar    $0x1f,%eax
f0104f35:	c1 e8 16             	shr    $0x16,%eax
f0104f38:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
f0104f3b:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0104f41:	29 c3                	sub    %eax,%ebx
f0104f43:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0104f46:	01 d3                	add    %edx,%ebx
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
		
	int i=0;
f0104f48:	be 00 00 00 00       	mov    $0x0,%esi
	if (curenv) {
		for (idle=envs+(curenv-envs+1)%NENV;idle!=curenv;) {
f0104f4d:	eb 4c                	jmp    f0104f9b <sched_yield+0xab>
			if (idle->env_status == ENV_RUNNABLE) {
f0104f4f:	83 7b 54 02          	cmpl   $0x2,0x54(%ebx)
f0104f53:	75 08                	jne    f0104f5d <sched_yield+0x6d>
				env_run(idle);
f0104f55:	89 1c 24             	mov    %ebx,(%esp)
f0104f58:	e8 51 f1 ff ff       	call   f01040ae <env_run>
			}
			i++;
f0104f5d:	83 c6 01             	add    $0x1,%esi
			idle = envs+(curenv-envs+1+i)%NENV;
f0104f60:	e8 74 19 00 00       	call   f01068d9 <cpunum>
f0104f65:	8b 15 48 32 23 f0    	mov    0xf0233248,%edx
f0104f6b:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f6e:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0104f74:	29 d0                	sub    %edx,%eax
f0104f76:	c1 f8 02             	sar    $0x2,%eax
f0104f79:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f0104f7f:	8d 4c 06 01          	lea    0x1(%esi,%eax,1),%ecx
f0104f83:	89 c8                	mov    %ecx,%eax
f0104f85:	c1 f8 1f             	sar    $0x1f,%eax
f0104f88:	c1 e8 16             	shr    $0x16,%eax
f0104f8b:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
f0104f8e:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0104f94:	29 c3                	sub    %eax,%ebx
f0104f96:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0104f99:	01 d3                	add    %edx,%ebx

	// LAB 4: Your code here.
		
	int i=0;
	if (curenv) {
		for (idle=envs+(curenv-envs+1)%NENV;idle!=curenv;) {
f0104f9b:	e8 39 19 00 00       	call   f01068d9 <cpunum>
f0104fa0:	6b c0 74             	imul   $0x74,%eax,%eax
f0104fa3:	8b b8 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%edi
f0104fa9:	39 df                	cmp    %ebx,%edi
f0104fab:	75 a2                	jne    f0104f4f <sched_yield+0x5f>
				env_run(idle);
			}
			i++;
			idle = envs+(curenv-envs+1+i)%NENV;
		}
		if (idle->env_status == ENV_RUNNING && idle->env_cpunum == thiscpu->cpu_id)
f0104fad:	83 7f 54 03          	cmpl   $0x3,0x54(%edi)
f0104fb1:	75 44                	jne    f0104ff7 <sched_yield+0x107>
f0104fb3:	8b 5f 5c             	mov    0x5c(%edi),%ebx
f0104fb6:	e8 1e 19 00 00       	call   f01068d9 <cpunum>
f0104fbb:	6b c0 74             	imul   $0x74,%eax,%eax
f0104fbe:	0f b6 80 20 40 23 f0 	movzbl -0xfdcbfe0(%eax),%eax
f0104fc5:	39 c3                	cmp    %eax,%ebx
f0104fc7:	75 2e                	jne    f0104ff7 <sched_yield+0x107>
			env_run(idle);
f0104fc9:	89 3c 24             	mov    %edi,(%esp)
f0104fcc:	e8 dd f0 ff ff       	call   f01040ae <env_run>
	} else {
		for (idle=envs;i<NENV;) {
f0104fd1:	8b 15 48 32 23 f0    	mov    0xf0233248,%edx
f0104fd7:	8d 42 7c             	lea    0x7c(%edx),%eax
f0104fda:	8d 8a 7c f0 01 00    	lea    0x1f07c(%edx),%ecx
                        if (idle->env_status == ENV_RUNNABLE) {
f0104fe0:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104fe4:	75 08                	jne    f0104fee <sched_yield+0xfe>
                                env_run(idle);
f0104fe6:	89 14 24             	mov    %edx,(%esp)
f0104fe9:	e8 c0 f0 ff ff       	call   f01040ae <env_run>
                        }
                        i++;
			idle=envs+i;
f0104fee:	89 c2                	mov    %eax,%edx
f0104ff0:	83 c0 7c             	add    $0x7c,%eax
			idle = envs+(curenv-envs+1+i)%NENV;
		}
		if (idle->env_status == ENV_RUNNING && idle->env_cpunum == thiscpu->cpu_id)
			env_run(idle);
	} else {
		for (idle=envs;i<NENV;) {
f0104ff3:	39 c8                	cmp    %ecx,%eax
f0104ff5:	75 e9                	jne    f0104fe0 <sched_yield+0xf0>
                        i++;
			idle=envs+i;
                }
	}
	// sched_halt never returns
	sched_halt();
f0104ff7:	e8 1e fe ff ff       	call   f0104e1a <sched_halt>
}
f0104ffc:	83 c4 1c             	add    $0x1c,%esp
f0104fff:	5b                   	pop    %ebx
f0105000:	5e                   	pop    %esi
f0105001:	5f                   	pop    %edi
f0105002:	5d                   	pop    %ebp
f0105003:	c3                   	ret    
f0105004:	66 90                	xchg   %ax,%ax
f0105006:	66 90                	xchg   %ax,%ax
f0105008:	66 90                	xchg   %ax,%ax
f010500a:	66 90                	xchg   %ax,%ax
f010500c:	66 90                	xchg   %ax,%ax
f010500e:	66 90                	xchg   %ax,%ax

f0105010 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0105010:	55                   	push   %ebp
f0105011:	89 e5                	mov    %esp,%ebp
f0105013:	56                   	push   %esi
f0105014:	53                   	push   %ebx
f0105015:	83 ec 20             	sub    $0x20,%esp
f0105018:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f010501b:	83 f8 0c             	cmp    $0xc,%eax
f010501e:	0f 87 d1 05 00 00    	ja     f01055f5 <syscall+0x5e5>
f0105024:	ff 24 85 6c 88 10 f0 	jmp    *-0xfef7794(,%eax,4)
	case 0:	user_mem_assert(curenv,(const void*)a1,a2,PTE_U|PTE_P);
f010502b:	e8 a9 18 00 00       	call   f01068d9 <cpunum>
f0105030:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0105037:	00 
f0105038:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010503b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010503f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105042:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105046:	6b c0 74             	imul   $0x74,%eax,%eax
f0105049:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010504f:	89 04 24             	mov    %eax,(%esp)
f0105052:	e8 d3 e8 ff ff       	call   f010392a <user_mem_assert>
	// Destroy the environment if not.

	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0105057:	8b 45 0c             	mov    0xc(%ebp),%eax
f010505a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010505e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105061:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105065:	c7 04 24 26 88 10 f0 	movl   $0xf0108826,(%esp)
f010506c:	e8 99 f2 ff ff       	call   f010430a <cprintf>

	switch (syscallno) {
	case 0:	user_mem_assert(curenv,(const void*)a1,a2,PTE_U|PTE_P);
		//cprintf("Addr: %p, len: %d\n",a1,a2);
		sys_cputs((const char*)a1,a2);
		return 0;
f0105071:	b8 00 00 00 00       	mov    $0x0,%eax
f0105076:	e9 e5 05 00 00       	jmp    f0105660 <syscall+0x650>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010507b:	e8 c0 b5 ff ff       	call   f0100640 <cons_getc>
	switch (syscallno) {
	case 0:	user_mem_assert(curenv,(const void*)a1,a2,PTE_U|PTE_P);
		//cprintf("Addr: %p, len: %d\n",a1,a2);
		sys_cputs((const char*)a1,a2);
		return 0;
	case 1: return sys_cgetc();
f0105080:	e9 db 05 00 00       	jmp    f0105660 <syscall+0x650>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0105085:	e8 4f 18 00 00       	call   f01068d9 <cpunum>
f010508a:	6b c0 74             	imul   $0x74,%eax,%eax
f010508d:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0105093:	8b 40 48             	mov    0x48(%eax),%eax
	case 0:	user_mem_assert(curenv,(const void*)a1,a2,PTE_U|PTE_P);
		//cprintf("Addr: %p, len: %d\n",a1,a2);
		sys_cputs((const char*)a1,a2);
		return 0;
	case 1: return sys_cgetc();
	case 2: return sys_getenvid();
f0105096:	e9 c5 05 00 00       	jmp    f0105660 <syscall+0x650>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010509b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01050a2:	00 
f01050a3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01050a6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01050aa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01050ad:	89 04 24             	mov    %eax,(%esp)
f01050b0:	e8 50 e9 ff ff       	call   f0103a05 <envid2env>
		return r;
f01050b5:	89 c2                	mov    %eax,%edx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01050b7:	85 c0                	test   %eax,%eax
f01050b9:	78 6e                	js     f0105129 <syscall+0x119>
		return r;
	if (e == curenv)
f01050bb:	e8 19 18 00 00       	call   f01068d9 <cpunum>
f01050c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01050c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01050c6:	39 90 28 40 23 f0    	cmp    %edx,-0xfdcbfd8(%eax)
f01050cc:	75 23                	jne    f01050f1 <syscall+0xe1>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01050ce:	e8 06 18 00 00       	call   f01068d9 <cpunum>
f01050d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01050d6:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01050dc:	8b 40 48             	mov    0x48(%eax),%eax
f01050df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01050e3:	c7 04 24 2b 88 10 f0 	movl   $0xf010882b,(%esp)
f01050ea:	e8 1b f2 ff ff       	call   f010430a <cprintf>
f01050ef:	eb 28                	jmp    f0105119 <syscall+0x109>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01050f1:	8b 5a 48             	mov    0x48(%edx),%ebx
f01050f4:	e8 e0 17 00 00       	call   f01068d9 <cpunum>
f01050f9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01050fd:	6b c0 74             	imul   $0x74,%eax,%eax
f0105100:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0105106:	8b 40 48             	mov    0x48(%eax),%eax
f0105109:	89 44 24 04          	mov    %eax,0x4(%esp)
f010510d:	c7 04 24 46 88 10 f0 	movl   $0xf0108846,(%esp)
f0105114:	e8 f1 f1 ff ff       	call   f010430a <cprintf>
	env_destroy(e);
f0105119:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010511c:	89 04 24             	mov    %eax,(%esp)
f010511f:	e8 e9 ee ff ff       	call   f010400d <env_destroy>
	return 0;
f0105124:	ba 00 00 00 00       	mov    $0x0,%edx
		//cprintf("Addr: %p, len: %d\n",a1,a2);
		sys_cputs((const char*)a1,a2);
		return 0;
	case 1: return sys_cgetc();
	case 2: return sys_getenvid();
	case 3: return sys_env_destroy(a1);
f0105129:	89 d0                	mov    %edx,%eax
f010512b:	e9 30 05 00 00       	jmp    f0105660 <syscall+0x650>
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	if ((uint32_t)va >= UTOP || (uint32_t)va%PGSIZE != 0) return -E_INVAL;
f0105130:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0105137:	77 7b                	ja     f01051b4 <syscall+0x1a4>
f0105139:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0105140:	75 79                	jne    f01051bb <syscall+0x1ab>
	if ((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0) return -E_INVAL;
f0105142:	8b 45 14             	mov    0x14(%ebp),%eax
f0105145:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f010514a:	83 f8 05             	cmp    $0x5,%eax
f010514d:	75 73                	jne    f01051c2 <syscall+0x1b2>
	struct Env *env;
	int ret;
	//cprintf("ENV: %d, %p\n",envid,va);
	if ((ret=envid2env(envid,&env,1)) < 0) return ret;
f010514f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0105156:	00 
f0105157:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010515a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010515e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105161:	89 04 24             	mov    %eax,(%esp)
f0105164:	e8 9c e8 ff ff       	call   f0103a05 <envid2env>
f0105169:	89 c2                	mov    %eax,%edx
f010516b:	85 c0                	test   %eax,%eax
f010516d:	78 66                	js     f01051d5 <syscall+0x1c5>
	struct PageInfo* pi = page_alloc(ALLOC_ZERO);
f010516f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0105176:	e8 fc c0 ff ff       	call   f0101277 <page_alloc>
f010517b:	89 c3                	mov    %eax,%ebx
	if (pi == NULL) return -E_NO_MEM;
f010517d:	85 c0                	test   %eax,%eax
f010517f:	74 48                	je     f01051c9 <syscall+0x1b9>
	if (page_insert(env->env_pgdir,pi, va, perm) < 0) {
f0105181:	8b 45 14             	mov    0x14(%ebp),%eax
f0105184:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105188:	8b 45 10             	mov    0x10(%ebp),%eax
f010518b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010518f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105193:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105196:	8b 40 60             	mov    0x60(%eax),%eax
f0105199:	89 04 24             	mov    %eax,(%esp)
f010519c:	e8 4a c5 ff ff       	call   f01016eb <page_insert>
f01051a1:	85 c0                	test   %eax,%eax
f01051a3:	79 2b                	jns    f01051d0 <syscall+0x1c0>
		page_free(pi);
f01051a5:	89 1c 24             	mov    %ebx,(%esp)
f01051a8:	e8 55 c1 ff ff       	call   f0101302 <page_free>
		return -E_NO_MEM;
f01051ad:	ba fc ff ff ff       	mov    $0xfffffffc,%edx
f01051b2:	eb 21                	jmp    f01051d5 <syscall+0x1c5>
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	if ((uint32_t)va >= UTOP || (uint32_t)va%PGSIZE != 0) return -E_INVAL;
f01051b4:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f01051b9:	eb 1a                	jmp    f01051d5 <syscall+0x1c5>
f01051bb:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f01051c0:	eb 13                	jmp    f01051d5 <syscall+0x1c5>
	if ((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0) return -E_INVAL;
f01051c2:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f01051c7:	eb 0c                	jmp    f01051d5 <syscall+0x1c5>
	struct Env *env;
	int ret;
	//cprintf("ENV: %d, %p\n",envid,va);
	if ((ret=envid2env(envid,&env,1)) < 0) return ret;
	struct PageInfo* pi = page_alloc(ALLOC_ZERO);
	if (pi == NULL) return -E_NO_MEM;
f01051c9:	ba fc ff ff ff       	mov    $0xfffffffc,%edx
f01051ce:	eb 05                	jmp    f01051d5 <syscall+0x1c5>
	if (page_insert(env->env_pgdir,pi, va, perm) < 0) {
		page_free(pi);
		return -E_NO_MEM;
	} else {
		return 0;
f01051d0:	ba 00 00 00 00       	mov    $0x0,%edx
		sys_cputs((const char*)a1,a2);
		return 0;
	case 1: return sys_cgetc();
	case 2: return sys_getenvid();
	case 3: return sys_env_destroy(a1);
	case 4: return sys_page_alloc(a1,(void*)a2,(int)a3);
f01051d5:	89 d0                	mov    %edx,%eax
f01051d7:	e9 84 04 00 00       	jmp    f0105660 <syscall+0x650>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	if ((uint32_t)srcva >= UTOP || (uint32_t)srcva%PGSIZE != 0) return -E_INVAL;
f01051dc:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01051e3:	0f 87 cf 00 00 00    	ja     f01052b8 <syscall+0x2a8>
f01051e9:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01051f0:	0f 85 cc 00 00 00    	jne    f01052c2 <syscall+0x2b2>
	if ((uint32_t)dstva >= UTOP || (uint32_t)dstva%PGSIZE != 0) return -E_INVAL;
f01051f6:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f01051fd:	0f 87 c9 00 00 00    	ja     f01052cc <syscall+0x2bc>
f0105203:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f010520a:	0f 85 c6 00 00 00    	jne    f01052d6 <syscall+0x2c6>
	if ((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0) return -E_INVAL;
f0105210:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0105213:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f0105218:	83 f8 05             	cmp    $0x5,%eax
f010521b:	0f 85 bf 00 00 00    	jne    f01052e0 <syscall+0x2d0>
	struct Env *src, *dst;
	if (envid2env(srcenvid,&src,1) < 0 || envid2env(dstenvid,&dst,1) < 0)
f0105221:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0105228:	00 
f0105229:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010522c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105230:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105233:	89 04 24             	mov    %eax,(%esp)
f0105236:	e8 ca e7 ff ff       	call   f0103a05 <envid2env>
f010523b:	85 c0                	test   %eax,%eax
f010523d:	0f 88 a7 00 00 00    	js     f01052ea <syscall+0x2da>
f0105243:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010524a:	00 
f010524b:	8d 45 f0             	lea    -0x10(%ebp),%eax
f010524e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105252:	8b 45 14             	mov    0x14(%ebp),%eax
f0105255:	89 04 24             	mov    %eax,(%esp)
f0105258:	e8 a8 e7 ff ff       	call   f0103a05 <envid2env>
f010525d:	85 c0                	test   %eax,%eax
f010525f:	0f 88 8f 00 00 00    	js     f01052f4 <syscall+0x2e4>
		return -E_BAD_ENV;
	pte_t *pte;
	struct PageInfo *pi = page_lookup(src->env_pgdir,srcva, &pte);
f0105265:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0105268:	89 44 24 08          	mov    %eax,0x8(%esp)
f010526c:	8b 45 10             	mov    0x10(%ebp),%eax
f010526f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105273:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105276:	8b 40 60             	mov    0x60(%eax),%eax
f0105279:	89 04 24             	mov    %eax,(%esp)
f010527c:	e8 61 c3 ff ff       	call   f01015e2 <page_lookup>
	if (pi == NULL) return -E_INVAL;
f0105281:	85 c0                	test   %eax,%eax
f0105283:	74 79                	je     f01052fe <syscall+0x2ee>
	if (perm & PTE_W && !(*pte&PTE_W)) return -E_INVAL;
f0105285:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0105289:	74 08                	je     f0105293 <syscall+0x283>
f010528b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010528e:	f6 02 02             	testb  $0x2,(%edx)
f0105291:	74 75                	je     f0105308 <syscall+0x2f8>
	return page_insert(dst->env_pgdir, pi, dstva, perm);
f0105293:	8b 4d 1c             	mov    0x1c(%ebp),%ecx
f0105296:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010529a:	8b 75 18             	mov    0x18(%ebp),%esi
f010529d:	89 74 24 08          	mov    %esi,0x8(%esp)
f01052a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01052a8:	8b 40 60             	mov    0x60(%eax),%eax
f01052ab:	89 04 24             	mov    %eax,(%esp)
f01052ae:	e8 38 c4 ff ff       	call   f01016eb <page_insert>
f01052b3:	e9 a8 03 00 00       	jmp    f0105660 <syscall+0x650>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	if ((uint32_t)srcva >= UTOP || (uint32_t)srcva%PGSIZE != 0) return -E_INVAL;
f01052b8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01052bd:	e9 9e 03 00 00       	jmp    f0105660 <syscall+0x650>
f01052c2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01052c7:	e9 94 03 00 00       	jmp    f0105660 <syscall+0x650>
	if ((uint32_t)dstva >= UTOP || (uint32_t)dstva%PGSIZE != 0) return -E_INVAL;
f01052cc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01052d1:	e9 8a 03 00 00       	jmp    f0105660 <syscall+0x650>
f01052d6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01052db:	e9 80 03 00 00       	jmp    f0105660 <syscall+0x650>
	if ((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0) return -E_INVAL;
f01052e0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01052e5:	e9 76 03 00 00       	jmp    f0105660 <syscall+0x650>
	struct Env *src, *dst;
	if (envid2env(srcenvid,&src,1) < 0 || envid2env(dstenvid,&dst,1) < 0)
		return -E_BAD_ENV;
f01052ea:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01052ef:	e9 6c 03 00 00       	jmp    f0105660 <syscall+0x650>
f01052f4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01052f9:	e9 62 03 00 00       	jmp    f0105660 <syscall+0x650>
	pte_t *pte;
	struct PageInfo *pi = page_lookup(src->env_pgdir,srcva, &pte);
	if (pi == NULL) return -E_INVAL;
f01052fe:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105303:	e9 58 03 00 00       	jmp    f0105660 <syscall+0x650>
	if (perm & PTE_W && !(*pte&PTE_W)) return -E_INVAL;
f0105308:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		return 0;
	case 1: return sys_cgetc();
	case 2: return sys_getenvid();
	case 3: return sys_env_destroy(a1);
	case 4: return sys_page_alloc(a1,(void*)a2,(int)a3);
	case 5: return sys_page_map(a1,(void*)a2,a3,(void*)a4,(int)a5);
f010530d:	e9 4e 03 00 00       	jmp    f0105660 <syscall+0x650>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if ((uint32_t)va >= UTOP || (uint32_t)va%PGSIZE != 0) return -E_INVAL;
f0105312:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0105319:	77 45                	ja     f0105360 <syscall+0x350>
f010531b:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0105322:	75 43                	jne    f0105367 <syscall+0x357>
	struct Env *env;
	int ret;
	if ((ret=envid2env(envid,&env,1)) < 0) return ret;
f0105324:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010532b:	00 
f010532c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010532f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105333:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105336:	89 04 24             	mov    %eax,(%esp)
f0105339:	e8 c7 e6 ff ff       	call   f0103a05 <envid2env>
f010533e:	89 c2                	mov    %eax,%edx
f0105340:	85 c0                	test   %eax,%eax
f0105342:	78 28                	js     f010536c <syscall+0x35c>
	page_remove(env->env_pgdir,va);
f0105344:	8b 45 10             	mov    0x10(%ebp),%eax
f0105347:	89 44 24 04          	mov    %eax,0x4(%esp)
f010534b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010534e:	8b 40 60             	mov    0x60(%eax),%eax
f0105351:	89 04 24             	mov    %eax,(%esp)
f0105354:	e8 37 c3 ff ff       	call   f0101690 <page_remove>
	return 0;
f0105359:	ba 00 00 00 00       	mov    $0x0,%edx
f010535e:	eb 0c                	jmp    f010536c <syscall+0x35c>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if ((uint32_t)va >= UTOP || (uint32_t)va%PGSIZE != 0) return -E_INVAL;
f0105360:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f0105365:	eb 05                	jmp    f010536c <syscall+0x35c>
f0105367:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
	case 1: return sys_cgetc();
	case 2: return sys_getenvid();
	case 3: return sys_env_destroy(a1);
	case 4: return sys_page_alloc(a1,(void*)a2,(int)a3);
	case 5: return sys_page_map(a1,(void*)a2,a3,(void*)a4,(int)a5);
	case 6: return sys_page_unmap(a1,(void*)a2);
f010536c:	89 d0                	mov    %edx,%eax
f010536e:	e9 ed 02 00 00       	jmp    f0105660 <syscall+0x650>
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *newenv;
	int err;
	if ((err=env_alloc(&newenv, curenv->env_id)) < 0) {
f0105373:	e8 61 15 00 00       	call   f01068d9 <cpunum>
f0105378:	6b c0 74             	imul   $0x74,%eax,%eax
f010537b:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0105381:	8b 40 48             	mov    0x48(%eax),%eax
f0105384:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105388:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010538b:	89 04 24             	mov    %eax,(%esp)
f010538e:	e8 75 e7 ff ff       	call   f0103b08 <env_alloc>
f0105393:	89 c3                	mov    %eax,%ebx
f0105395:	85 c0                	test   %eax,%eax
f0105397:	79 13                	jns    f01053ac <syscall+0x39c>
		cprintf("EXO error\n");
f0105399:	c7 04 24 5e 88 10 f0 	movl   $0xf010885e,(%esp)
f01053a0:	e8 65 ef ff ff       	call   f010430a <cprintf>
		return err;
f01053a5:	89 d8                	mov    %ebx,%eax
f01053a7:	e9 b4 02 00 00       	jmp    f0105660 <syscall+0x650>
	} else {
		newenv->env_status =  ENV_NOT_RUNNABLE;
f01053ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01053af:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
		//Set the new environment register state same as its parent
		memmove(&newenv->env_tf, &curenv->env_tf,sizeof(newenv->env_tf));
f01053b6:	e8 1e 15 00 00       	call   f01068d9 <cpunum>
f01053bb:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01053c2:	00 
f01053c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01053c6:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01053cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01053d3:	89 04 24             	mov    %eax,(%esp)
f01053d6:	e8 f9 0e 00 00       	call   f01062d4 <memmove>
		newenv->env_tf.tf_regs.reg_eax = 0;
f01053db:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01053de:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
		return newenv->env_id;
f01053e5:	8b 40 48             	mov    0x48(%eax),%eax
	case 2: return sys_getenvid();
	case 3: return sys_env_destroy(a1);
	case 4: return sys_page_alloc(a1,(void*)a2,(int)a3);
	case 5: return sys_page_map(a1,(void*)a2,a3,(void*)a4,(int)a5);
	case 6: return sys_page_unmap(a1,(void*)a2);
	case 7: return sys_exofork();
f01053e8:	e9 73 02 00 00       	jmp    f0105660 <syscall+0x650>
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	if (status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE) return -E_INVAL;
f01053ed:	83 7d 10 04          	cmpl   $0x4,0x10(%ebp)
f01053f1:	74 06                	je     f01053f9 <syscall+0x3e9>
f01053f3:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
f01053f7:	75 35                	jne    f010542e <syscall+0x41e>
	struct Env *cur;
	int ret;
	if ((ret=envid2env(envid,&cur,1)) < 0) return ret;
f01053f9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0105400:	00 
f0105401:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0105404:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105408:	8b 45 0c             	mov    0xc(%ebp),%eax
f010540b:	89 04 24             	mov    %eax,(%esp)
f010540e:	e8 f2 e5 ff ff       	call   f0103a05 <envid2env>
f0105413:	85 c0                	test   %eax,%eax
f0105415:	0f 88 45 02 00 00    	js     f0105660 <syscall+0x650>
	cur->env_status = status;
f010541b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010541e:	8b 75 10             	mov    0x10(%ebp),%esi
f0105421:	89 70 54             	mov    %esi,0x54(%eax)
	return 0;
f0105424:	b8 00 00 00 00       	mov    $0x0,%eax
f0105429:	e9 32 02 00 00       	jmp    f0105660 <syscall+0x650>
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	if (status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE) return -E_INVAL;
f010542e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105433:	e9 28 02 00 00       	jmp    f0105660 <syscall+0x650>
{
	// LAB 4: Your code here.
	struct Env *env;
	int ret;
	//cprintf("Set pgfault handler\n");
	if ((ret=envid2env(envid,&env,1)) < 0)
f0105438:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010543f:	00 
f0105440:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0105443:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105447:	8b 45 0c             	mov    0xc(%ebp),%eax
f010544a:	89 04 24             	mov    %eax,(%esp)
f010544d:	e8 b3 e5 ff ff       	call   f0103a05 <envid2env>
f0105452:	85 c0                	test   %eax,%eax
f0105454:	0f 88 06 02 00 00    	js     f0105660 <syscall+0x650>
		return ret;
	env->env_pgfault_upcall = func;
f010545a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010545d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105460:	89 48 64             	mov    %ecx,0x64(%eax)
	return 0;
f0105463:	b8 00 00 00 00       	mov    $0x0,%eax
f0105468:	e9 f3 01 00 00       	jmp    f0105660 <syscall+0x650>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f010546d:	e8 7e fa ff ff       	call   f0104ef0 <sched_yield>
	// Find the target environment. Return -E_BAD_ENV if not found
	struct Env *env;
	int ret;
	pte_t *pte;
	struct PageInfo *pi;
	if ((ret=envid2env(envid,&env,0)) < 0) return ret;
f0105472:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0105479:	00 
f010547a:	8d 45 f0             	lea    -0x10(%ebp),%eax
f010547d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105481:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105484:	89 04 24             	mov    %eax,(%esp)
f0105487:	e8 79 e5 ff ff       	call   f0103a05 <envid2env>
f010548c:	85 c0                	test   %eax,%eax
f010548e:	0f 88 cc 01 00 00    	js     f0105660 <syscall+0x650>

	if (env->env_ipc_recving == 0) return -E_IPC_NOT_RECV;
f0105494:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0105497:	80 7b 68 00          	cmpb   $0x0,0x68(%ebx)
f010549b:	0f 84 d0 00 00 00    	je     f0105571 <syscall+0x561>
	if ((uint32_t)srcva < UTOP && ((uint32_t)srcva%PGSIZE != 0
f01054a1:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01054a8:	0f 87 8c 01 00 00    	ja     f010563a <syscall+0x62a>
f01054ae:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f01054b5:	0f 85 c0 00 00 00    	jne    f010557b <syscall+0x56b>
		|| (perm & PTE_U) == 0 || (perm & PTE_P) == 0 
		|| (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0
f01054bb:	8b 45 18             	mov    0x18(%ebp),%eax
f01054be:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f01054c3:	83 f8 05             	cmp    $0x5,%eax
f01054c6:	0f 85 b9 00 00 00    	jne    f0105585 <syscall+0x575>
		|| (pi=page_lookup(curenv->env_pgdir,srcva,&pte)) == NULL
f01054cc:	e8 08 14 00 00       	call   f01068d9 <cpunum>
f01054d1:	8d 55 f4             	lea    -0xc(%ebp),%edx
f01054d4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01054d8:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01054db:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01054df:	6b c0 74             	imul   $0x74,%eax,%eax
f01054e2:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01054e8:	8b 40 60             	mov    0x60(%eax),%eax
f01054eb:	89 04 24             	mov    %eax,(%esp)
f01054ee:	e8 ef c0 ff ff       	call   f01015e2 <page_lookup>
f01054f3:	89 c6                	mov    %eax,%esi
f01054f5:	85 c0                	test   %eax,%eax
f01054f7:	0f 84 92 00 00 00    	je     f010558f <syscall+0x57f>
		|| ((perm&PTE_W) && !(*pte&PTE_W)))) 
f01054fd:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0105501:	0f 84 fc 00 00 00    	je     f0105603 <syscall+0x5f3>
f0105507:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010550a:	f6 00 02             	testb  $0x2,(%eax)
f010550d:	0f 85 f0 00 00 00    	jne    f0105603 <syscall+0x5f3>
f0105513:	e9 81 00 00 00       	jmp    f0105599 <syscall+0x589>

	env->env_ipc_recving = 0;
	env->env_ipc_from = curenv->env_id;
	env->env_ipc_value = value;
	if ((uint32_t)srcva < UTOP && (uint32_t)env->env_ipc_dstva < UTOP) {
		env->env_ipc_perm = perm;
f0105518:	8b 4d 18             	mov    0x18(%ebp),%ecx
f010551b:	89 4a 78             	mov    %ecx,0x78(%edx)
		page_remove(env->env_pgdir,env->env_ipc_dstva);
f010551e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105522:	8b 42 60             	mov    0x60(%edx),%eax
f0105525:	89 04 24             	mov    %eax,(%esp)
f0105528:	e8 63 c1 ff ff       	call   f0101690 <page_remove>
		page_insert(env->env_pgdir, pi, env->env_ipc_dstva, perm);
f010552d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105530:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105533:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105537:	8b 50 6c             	mov    0x6c(%eax),%edx
f010553a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010553e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105542:	8b 40 60             	mov    0x60(%eax),%eax
f0105545:	89 04 24             	mov    %eax,(%esp)
f0105548:	e8 9e c1 ff ff       	call   f01016eb <page_insert>
f010554d:	eb 07                	jmp    f0105556 <syscall+0x546>
	} else {
		env->env_ipc_perm = 0;
f010554f:	c7 42 78 00 00 00 00 	movl   $0x0,0x78(%edx)
	}
	env->env_tf.tf_regs.reg_eax = 0;
f0105556:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105559:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	env->env_status = ENV_RUNNABLE;
f0105560:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)

	
	return 0;
f0105567:	b8 00 00 00 00       	mov    $0x0,%eax
f010556c:	e9 ef 00 00 00       	jmp    f0105660 <syscall+0x650>
	int ret;
	pte_t *pte;
	struct PageInfo *pi;
	if ((ret=envid2env(envid,&env,0)) < 0) return ret;

	if (env->env_ipc_recving == 0) return -E_IPC_NOT_RECV;
f0105571:	b8 f8 ff ff ff       	mov    $0xfffffff8,%eax
f0105576:	e9 e5 00 00 00       	jmp    f0105660 <syscall+0x650>
	if ((uint32_t)srcva < UTOP && ((uint32_t)srcva%PGSIZE != 0
		|| (perm & PTE_U) == 0 || (perm & PTE_P) == 0 
		|| (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0
		|| (pi=page_lookup(curenv->env_pgdir,srcva,&pte)) == NULL
		|| ((perm&PTE_W) && !(*pte&PTE_W)))) 
		return -E_INVAL;
f010557b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105580:	e9 db 00 00 00       	jmp    f0105660 <syscall+0x650>
f0105585:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010558a:	e9 d1 00 00 00       	jmp    f0105660 <syscall+0x650>
f010558f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105594:	e9 c7 00 00 00       	jmp    f0105660 <syscall+0x650>
f0105599:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case 6: return sys_page_unmap(a1,(void*)a2);
	case 7: return sys_exofork();
	case 8: return sys_env_set_status(a1,a2);
	case 9: return sys_env_set_pgfault_upcall(a1,(void*)a2);
	case 10: sys_yield();
	case 11: return sys_ipc_try_send((envid_t)a1,a2,(void*)a3,(unsigned)a4);
f010559e:	e9 bd 00 00 00       	jmp    f0105660 <syscall+0x650>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	if ((uint32_t)dstva < UTOP && (uint32_t)dstva%PGSIZE != 0) return -E_INVAL;
f01055a3:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f01055aa:	77 09                	ja     f01055b5 <syscall+0x5a5>
f01055ac:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f01055b3:	75 47                	jne    f01055fc <syscall+0x5ec>
	
	curenv->env_status = ENV_NOT_RUNNABLE;
f01055b5:	e8 1f 13 00 00       	call   f01068d9 <cpunum>
f01055ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01055bd:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01055c3:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	curenv->env_ipc_dstva = dstva;
f01055ca:	e8 0a 13 00 00       	call   f01068d9 <cpunum>
f01055cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01055d2:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01055d8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01055db:	89 70 6c             	mov    %esi,0x6c(%eax)
	curenv->env_ipc_recving = 1;
f01055de:	e8 f6 12 00 00       	call   f01068d9 <cpunum>
f01055e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01055e6:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01055ec:	c6 40 68 01          	movb   $0x1,0x68(%eax)

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01055f0:	e8 fb f8 ff ff       	call   f0104ef0 <sched_yield>
	case 9: return sys_env_set_pgfault_upcall(a1,(void*)a2);
	case 10: sys_yield();
	case 11: return sys_ipc_try_send((envid_t)a1,a2,(void*)a3,(unsigned)a4);
	case 12: return sys_ipc_recv((void*)a1);
	default:
		return -E_NO_SYS;
f01055f5:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
f01055fa:	eb 64                	jmp    f0105660 <syscall+0x650>
	case 7: return sys_exofork();
	case 8: return sys_env_set_status(a1,a2);
	case 9: return sys_env_set_pgfault_upcall(a1,(void*)a2);
	case 10: sys_yield();
	case 11: return sys_ipc_try_send((envid_t)a1,a2,(void*)a3,(unsigned)a4);
	case 12: return sys_ipc_recv((void*)a1);
f01055fc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105601:	eb 5d                	jmp    f0105660 <syscall+0x650>
		|| (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0
		|| (pi=page_lookup(curenv->env_pgdir,srcva,&pte)) == NULL
		|| ((perm&PTE_W) && !(*pte&PTE_W)))) 
		return -E_INVAL;

	env->env_ipc_recving = 0;
f0105603:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0105606:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env->env_ipc_from = curenv->env_id;
f010560a:	e8 ca 12 00 00       	call   f01068d9 <cpunum>
f010560f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105612:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0105618:	8b 40 48             	mov    0x48(%eax),%eax
f010561b:	89 43 74             	mov    %eax,0x74(%ebx)
	env->env_ipc_value = value;
f010561e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105621:	8b 45 10             	mov    0x10(%ebp),%eax
f0105624:	89 42 70             	mov    %eax,0x70(%edx)
	if ((uint32_t)srcva < UTOP && (uint32_t)env->env_ipc_dstva < UTOP) {
f0105627:	8b 42 6c             	mov    0x6c(%edx),%eax
f010562a:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
f010562f:	0f 87 1a ff ff ff    	ja     f010554f <syscall+0x53f>
f0105635:	e9 de fe ff ff       	jmp    f0105518 <syscall+0x508>
		|| (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) != 0
		|| (pi=page_lookup(curenv->env_pgdir,srcva,&pte)) == NULL
		|| ((perm&PTE_W) && !(*pte&PTE_W)))) 
		return -E_INVAL;

	env->env_ipc_recving = 0;
f010563a:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env->env_ipc_from = curenv->env_id;
f010563e:	e8 96 12 00 00       	call   f01068d9 <cpunum>
f0105643:	6b c0 74             	imul   $0x74,%eax,%eax
f0105646:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010564c:	8b 40 48             	mov    0x48(%eax),%eax
f010564f:	89 43 74             	mov    %eax,0x74(%ebx)
	env->env_ipc_value = value;
f0105652:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105655:	8b 45 10             	mov    0x10(%ebp),%eax
f0105658:	89 42 70             	mov    %eax,0x70(%edx)
f010565b:	e9 ef fe ff ff       	jmp    f010554f <syscall+0x53f>
	case 11: return sys_ipc_try_send((envid_t)a1,a2,(void*)a3,(unsigned)a4);
	case 12: return sys_ipc_recv((void*)a1);
	default:
		return -E_NO_SYS;
	}
}
f0105660:	83 c4 20             	add    $0x20,%esp
f0105663:	5b                   	pop    %ebx
f0105664:	5e                   	pop    %esi
f0105665:	5d                   	pop    %ebp
f0105666:	c3                   	ret    

f0105667 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0105667:	55                   	push   %ebp
f0105668:	89 e5                	mov    %esp,%ebp
f010566a:	57                   	push   %edi
f010566b:	56                   	push   %esi
f010566c:	53                   	push   %ebx
f010566d:	83 ec 14             	sub    $0x14,%esp
f0105670:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105673:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105676:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0105679:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010567c:	8b 1a                	mov    (%edx),%ebx
f010567e:	8b 01                	mov    (%ecx),%eax
f0105680:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105683:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010568a:	e9 88 00 00 00       	jmp    f0105717 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f010568f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105692:	01 d8                	add    %ebx,%eax
f0105694:	89 c7                	mov    %eax,%edi
f0105696:	c1 ef 1f             	shr    $0x1f,%edi
f0105699:	01 c7                	add    %eax,%edi
f010569b:	d1 ff                	sar    %edi
f010569d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01056a0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01056a3:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01056a6:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01056a8:	eb 03                	jmp    f01056ad <stab_binsearch+0x46>
			m--;
f01056aa:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01056ad:	39 c3                	cmp    %eax,%ebx
f01056af:	7f 1f                	jg     f01056d0 <stab_binsearch+0x69>
f01056b1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01056b5:	83 ea 0c             	sub    $0xc,%edx
f01056b8:	39 f1                	cmp    %esi,%ecx
f01056ba:	75 ee                	jne    f01056aa <stab_binsearch+0x43>
f01056bc:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01056bf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01056c2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01056c5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01056c9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01056cc:	76 18                	jbe    f01056e6 <stab_binsearch+0x7f>
f01056ce:	eb 05                	jmp    f01056d5 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01056d0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01056d3:	eb 42                	jmp    f0105717 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01056d5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01056d8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01056da:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01056dd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01056e4:	eb 31                	jmp    f0105717 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01056e6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01056e9:	73 17                	jae    f0105702 <stab_binsearch+0x9b>
			*region_right = m - 1;
f01056eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01056ee:	83 e8 01             	sub    $0x1,%eax
f01056f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01056f4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01056f7:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01056f9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0105700:	eb 15                	jmp    f0105717 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0105702:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105705:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0105708:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f010570a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010570e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0105710:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0105717:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010571a:	0f 8e 6f ff ff ff    	jle    f010568f <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0105720:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0105724:	75 0f                	jne    f0105735 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0105726:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105729:	8b 00                	mov    (%eax),%eax
f010572b:	83 e8 01             	sub    $0x1,%eax
f010572e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105731:	89 07                	mov    %eax,(%edi)
f0105733:	eb 2c                	jmp    f0105761 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105735:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105738:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010573a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010573d:	8b 0f                	mov    (%edi),%ecx
f010573f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105742:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0105745:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105748:	eb 03                	jmp    f010574d <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010574a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010574d:	39 c8                	cmp    %ecx,%eax
f010574f:	7e 0b                	jle    f010575c <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0105751:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0105755:	83 ea 0c             	sub    $0xc,%edx
f0105758:	39 f3                	cmp    %esi,%ebx
f010575a:	75 ee                	jne    f010574a <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f010575c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010575f:	89 07                	mov    %eax,(%edi)
	}
}
f0105761:	83 c4 14             	add    $0x14,%esp
f0105764:	5b                   	pop    %ebx
f0105765:	5e                   	pop    %esi
f0105766:	5f                   	pop    %edi
f0105767:	5d                   	pop    %ebp
f0105768:	c3                   	ret    

f0105769 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0105769:	55                   	push   %ebp
f010576a:	89 e5                	mov    %esp,%ebp
f010576c:	57                   	push   %edi
f010576d:	56                   	push   %esi
f010576e:	53                   	push   %ebx
f010576f:	83 ec 4c             	sub    $0x4c,%esp
f0105772:	8b 75 08             	mov    0x8(%ebp),%esi
f0105775:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0105778:	c7 07 a0 88 10 f0    	movl   $0xf01088a0,(%edi)
	info->eip_line = 0;
f010577e:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0105785:	c7 47 08 a0 88 10 f0 	movl   $0xf01088a0,0x8(%edi)
	info->eip_fn_namelen = 9;
f010578c:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0105793:	89 77 10             	mov    %esi,0x10(%edi)
	info->eip_fn_narg = 0;
f0105796:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010579d:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01057a3:	0f 87 c5 00 00 00    	ja     f010586e <debuginfo_eip+0x105>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		int ret;
		if ((ret=user_mem_check(curenv,(const void*)usd, sizeof(usd[0]),PTE_U|PTE_P)) < 0)
f01057a9:	e8 2b 11 00 00       	call   f01068d9 <cpunum>
f01057ae:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f01057b5:	00 
f01057b6:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01057bd:	00 
f01057be:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f01057c5:	00 
f01057c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01057c9:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f01057cf:	89 04 24             	mov    %eax,(%esp)
f01057d2:	e8 99 e0 ff ff       	call   f0103870 <user_mem_check>
f01057d7:	89 c2                	mov    %eax,%edx
f01057d9:	85 d2                	test   %edx,%edx
f01057db:	0f 88 76 02 00 00    	js     f0105a57 <debuginfo_eip+0x2ee>
			return ret;

		stabs = usd->stabs;
f01057e1:	a1 00 00 20 00       	mov    0x200000,%eax
f01057e6:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01057e9:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01057ef:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01057f5:	89 55 c0             	mov    %edx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01057f8:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01057fd:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if ((ret=user_mem_check(curenv,(const void*)stabs,sizeof(stabs[0])*(stab_end-stabs),PTE_U|PTE_P)) < 0)
f0105800:	e8 d4 10 00 00       	call   f01068d9 <cpunum>
f0105805:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f010580c:	00 
f010580d:	89 da                	mov    %ebx,%edx
f010580f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0105812:	29 ca                	sub    %ecx,%edx
f0105814:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105818:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010581c:	6b c0 74             	imul   $0x74,%eax,%eax
f010581f:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f0105825:	89 04 24             	mov    %eax,(%esp)
f0105828:	e8 43 e0 ff ff       	call   f0103870 <user_mem_check>
f010582d:	89 c2                	mov    %eax,%edx
f010582f:	85 d2                	test   %edx,%edx
f0105831:	0f 88 20 02 00 00    	js     f0105a57 <debuginfo_eip+0x2ee>
			return ret;
		if ((ret=user_mem_check(curenv,(const void*)stabstr,sizeof(stabstr[0])*(stabstr_end-stabstr),PTE_U|PTE_P)) < 0)
f0105837:	e8 9d 10 00 00       	call   f01068d9 <cpunum>
f010583c:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0105843:	00 
f0105844:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0105847:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f010584a:	29 ca                	sub    %ecx,%edx
f010584c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105850:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105854:	6b c0 74             	imul   $0x74,%eax,%eax
f0105857:	8b 80 28 40 23 f0    	mov    -0xfdcbfd8(%eax),%eax
f010585d:	89 04 24             	mov    %eax,(%esp)
f0105860:	e8 0b e0 ff ff       	call   f0103870 <user_mem_check>
f0105865:	85 c0                	test   %eax,%eax
f0105867:	79 1f                	jns    f0105888 <debuginfo_eip+0x11f>
f0105869:	e9 e9 01 00 00       	jmp    f0105a57 <debuginfo_eip+0x2ee>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010586e:	c7 45 bc b5 74 11 f0 	movl   $0xf01174b5,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0105875:	c7 45 c0 65 3d 11 f0 	movl   $0xf0113d65,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010587c:	bb 64 3d 11 f0       	mov    $0xf0113d64,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0105881:	c7 45 c4 78 8d 10 f0 	movl   $0xf0108d78,-0x3c(%ebp)
			return ret;
		
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105888:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010588b:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f010588e:	0f 83 a2 01 00 00    	jae    f0105a36 <debuginfo_eip+0x2cd>
f0105894:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0105898:	0f 85 9f 01 00 00    	jne    f0105a3d <debuginfo_eip+0x2d4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010589e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01058a5:	2b 5d c4             	sub    -0x3c(%ebp),%ebx
f01058a8:	c1 fb 02             	sar    $0x2,%ebx
f01058ab:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01058b1:	83 e8 01             	sub    $0x1,%eax
f01058b4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01058b7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01058bb:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01058c2:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01058c5:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01058c8:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01058cb:	89 d8                	mov    %ebx,%eax
f01058cd:	e8 95 fd ff ff       	call   f0105667 <stab_binsearch>
	if (lfile == 0)
f01058d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01058d5:	85 c0                	test   %eax,%eax
f01058d7:	0f 84 67 01 00 00    	je     f0105a44 <debuginfo_eip+0x2db>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01058dd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01058e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01058e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01058e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01058ea:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01058f1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01058f4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01058f7:	89 d8                	mov    %ebx,%eax
f01058f9:	e8 69 fd ff ff       	call   f0105667 <stab_binsearch>

	if (lfun <= rfun) {
f01058fe:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105901:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105904:	39 d0                	cmp    %edx,%eax
f0105906:	7f 32                	jg     f010593a <debuginfo_eip+0x1d1>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0105908:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010590b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010590e:	8d 0c 8b             	lea    (%ebx,%ecx,4),%ecx
f0105911:	8b 19                	mov    (%ecx),%ebx
f0105913:	89 5d b8             	mov    %ebx,-0x48(%ebp)
f0105916:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0105919:	2b 5d c0             	sub    -0x40(%ebp),%ebx
f010591c:	39 5d b8             	cmp    %ebx,-0x48(%ebp)
f010591f:	73 09                	jae    f010592a <debuginfo_eip+0x1c1>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0105921:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f0105924:	03 5d c0             	add    -0x40(%ebp),%ebx
f0105927:	89 5f 08             	mov    %ebx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010592a:	8b 49 08             	mov    0x8(%ecx),%ecx
f010592d:	89 4f 10             	mov    %ecx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0105930:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0105932:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0105935:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0105938:	eb 0f                	jmp    f0105949 <debuginfo_eip+0x1e0>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010593a:	89 77 10             	mov    %esi,0x10(%edi)
		lline = lfile;
f010593d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105940:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105943:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105946:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105949:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0105950:	00 
f0105951:	8b 47 08             	mov    0x8(%edi),%eax
f0105954:	89 04 24             	mov    %eax,(%esp)
f0105957:	e8 0f 09 00 00       	call   f010626b <strfind>
f010595c:	2b 47 08             	sub    0x8(%edi),%eax
f010595f:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0105962:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105966:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010596d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105970:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105973:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0105976:	89 f0                	mov    %esi,%eax
f0105978:	e8 ea fc ff ff       	call   f0105667 <stab_binsearch>
	if (lline <= rline) {
f010597d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105980:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0105983:	0f 8f c2 00 00 00    	jg     f0105a4b <debuginfo_eip+0x2e2>
		info->eip_line = stabs[lline].n_value-22;
f0105989:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010598c:	8b 44 86 08          	mov    0x8(%esi,%eax,4),%eax
f0105990:	83 e8 16             	sub    $0x16,%eax
f0105993:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105996:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105999:	89 c3                	mov    %eax,%ebx
f010599b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010599e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01059a1:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01059a4:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01059a7:	89 df                	mov    %ebx,%edi
f01059a9:	eb 06                	jmp    f01059b1 <debuginfo_eip+0x248>
f01059ab:	83 e8 01             	sub    $0x1,%eax
f01059ae:	83 ea 0c             	sub    $0xc,%edx
f01059b1:	89 c6                	mov    %eax,%esi
f01059b3:	39 c7                	cmp    %eax,%edi
f01059b5:	7f 3c                	jg     f01059f3 <debuginfo_eip+0x28a>
	       && stabs[lline].n_type != N_SOL
f01059b7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01059bb:	80 f9 84             	cmp    $0x84,%cl
f01059be:	75 08                	jne    f01059c8 <debuginfo_eip+0x25f>
f01059c0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01059c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01059c6:	eb 11                	jmp    f01059d9 <debuginfo_eip+0x270>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01059c8:	80 f9 64             	cmp    $0x64,%cl
f01059cb:	75 de                	jne    f01059ab <debuginfo_eip+0x242>
f01059cd:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01059d1:	74 d8                	je     f01059ab <debuginfo_eip+0x242>
f01059d3:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01059d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01059d9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01059dc:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01059df:	8b 04 86             	mov    (%esi,%eax,4),%eax
f01059e2:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01059e5:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01059e8:	39 d0                	cmp    %edx,%eax
f01059ea:	73 0a                	jae    f01059f6 <debuginfo_eip+0x28d>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01059ec:	03 45 c0             	add    -0x40(%ebp),%eax
f01059ef:	89 07                	mov    %eax,(%edi)
f01059f1:	eb 03                	jmp    f01059f6 <debuginfo_eip+0x28d>
f01059f3:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01059f6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01059f9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01059fc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105a01:	39 da                	cmp    %ebx,%edx
f0105a03:	7d 52                	jge    f0105a57 <debuginfo_eip+0x2ee>
		for (lline = lfun + 1;
f0105a05:	83 c2 01             	add    $0x1,%edx
f0105a08:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0105a0b:	89 d0                	mov    %edx,%eax
f0105a0d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105a10:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0105a13:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0105a16:	eb 04                	jmp    f0105a1c <debuginfo_eip+0x2b3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0105a18:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0105a1c:	39 c3                	cmp    %eax,%ebx
f0105a1e:	7e 32                	jle    f0105a52 <debuginfo_eip+0x2e9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105a20:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0105a24:	83 c0 01             	add    $0x1,%eax
f0105a27:	83 c2 0c             	add    $0xc,%edx
f0105a2a:	80 f9 a0             	cmp    $0xa0,%cl
f0105a2d:	74 e9                	je     f0105a18 <debuginfo_eip+0x2af>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105a2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a34:	eb 21                	jmp    f0105a57 <debuginfo_eip+0x2ee>
		
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0105a36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105a3b:	eb 1a                	jmp    f0105a57 <debuginfo_eip+0x2ee>
f0105a3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105a42:	eb 13                	jmp    f0105a57 <debuginfo_eip+0x2ee>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0105a44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105a49:	eb 0c                	jmp    f0105a57 <debuginfo_eip+0x2ee>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline) {
		info->eip_line = stabs[lline].n_value-22;
	} else {
		return -1;
f0105a4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105a50:	eb 05                	jmp    f0105a57 <debuginfo_eip+0x2ee>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105a52:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a57:	83 c4 4c             	add    $0x4c,%esp
f0105a5a:	5b                   	pop    %ebx
f0105a5b:	5e                   	pop    %esi
f0105a5c:	5f                   	pop    %edi
f0105a5d:	5d                   	pop    %ebp
f0105a5e:	c3                   	ret    
f0105a5f:	90                   	nop

f0105a60 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105a60:	55                   	push   %ebp
f0105a61:	89 e5                	mov    %esp,%ebp
f0105a63:	57                   	push   %edi
f0105a64:	56                   	push   %esi
f0105a65:	53                   	push   %ebx
f0105a66:	83 ec 3c             	sub    $0x3c,%esp
f0105a69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105a6c:	89 d7                	mov    %edx,%edi
f0105a6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105a74:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105a77:	89 c3                	mov    %eax,%ebx
f0105a79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0105a7c:	8b 45 10             	mov    0x10(%ebp),%eax
f0105a7f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105a82:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105a87:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105a8a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0105a8d:	39 d9                	cmp    %ebx,%ecx
f0105a8f:	72 05                	jb     f0105a96 <printnum+0x36>
f0105a91:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0105a94:	77 69                	ja     f0105aff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105a96:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105a99:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105a9d:	83 ee 01             	sub    $0x1,%esi
f0105aa0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105aa4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105aa8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105aac:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105ab0:	89 c3                	mov    %eax,%ebx
f0105ab2:	89 d6                	mov    %edx,%esi
f0105ab4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105ab7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105aba:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105abe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105ac2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105ac5:	89 04 24             	mov    %eax,(%esp)
f0105ac8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105acb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105acf:	e8 4c 12 00 00       	call   f0106d20 <__udivdi3>
f0105ad4:	89 d9                	mov    %ebx,%ecx
f0105ad6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105ada:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105ade:	89 04 24             	mov    %eax,(%esp)
f0105ae1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105ae5:	89 fa                	mov    %edi,%edx
f0105ae7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105aea:	e8 71 ff ff ff       	call   f0105a60 <printnum>
f0105aef:	eb 1b                	jmp    f0105b0c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105af1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105af5:	8b 45 18             	mov    0x18(%ebp),%eax
f0105af8:	89 04 24             	mov    %eax,(%esp)
f0105afb:	ff d3                	call   *%ebx
f0105afd:	eb 03                	jmp    f0105b02 <printnum+0xa2>
f0105aff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0105b02:	83 ee 01             	sub    $0x1,%esi
f0105b05:	85 f6                	test   %esi,%esi
f0105b07:	7f e8                	jg     f0105af1 <printnum+0x91>
f0105b09:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0105b0c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105b10:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105b14:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105b17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105b1a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105b1e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105b22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105b25:	89 04 24             	mov    %eax,(%esp)
f0105b28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105b2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105b2f:	e8 1c 13 00 00       	call   f0106e50 <__umoddi3>
f0105b34:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105b38:	0f be 80 aa 88 10 f0 	movsbl -0xfef7756(%eax),%eax
f0105b3f:	89 04 24             	mov    %eax,(%esp)
f0105b42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105b45:	ff d0                	call   *%eax
}
f0105b47:	83 c4 3c             	add    $0x3c,%esp
f0105b4a:	5b                   	pop    %ebx
f0105b4b:	5e                   	pop    %esi
f0105b4c:	5f                   	pop    %edi
f0105b4d:	5d                   	pop    %ebp
f0105b4e:	c3                   	ret    

f0105b4f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0105b4f:	55                   	push   %ebp
f0105b50:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105b52:	83 fa 01             	cmp    $0x1,%edx
f0105b55:	7e 0e                	jle    f0105b65 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0105b57:	8b 10                	mov    (%eax),%edx
f0105b59:	8d 4a 08             	lea    0x8(%edx),%ecx
f0105b5c:	89 08                	mov    %ecx,(%eax)
f0105b5e:	8b 02                	mov    (%edx),%eax
f0105b60:	8b 52 04             	mov    0x4(%edx),%edx
f0105b63:	eb 22                	jmp    f0105b87 <getuint+0x38>
	else if (lflag)
f0105b65:	85 d2                	test   %edx,%edx
f0105b67:	74 10                	je     f0105b79 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0105b69:	8b 10                	mov    (%eax),%edx
f0105b6b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0105b6e:	89 08                	mov    %ecx,(%eax)
f0105b70:	8b 02                	mov    (%edx),%eax
f0105b72:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b77:	eb 0e                	jmp    f0105b87 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0105b79:	8b 10                	mov    (%eax),%edx
f0105b7b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0105b7e:	89 08                	mov    %ecx,(%eax)
f0105b80:	8b 02                	mov    (%edx),%eax
f0105b82:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105b87:	5d                   	pop    %ebp
f0105b88:	c3                   	ret    

f0105b89 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105b89:	55                   	push   %ebp
f0105b8a:	89 e5                	mov    %esp,%ebp
f0105b8c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0105b8f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105b93:	8b 10                	mov    (%eax),%edx
f0105b95:	3b 50 04             	cmp    0x4(%eax),%edx
f0105b98:	73 0a                	jae    f0105ba4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0105b9a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0105b9d:	89 08                	mov    %ecx,(%eax)
f0105b9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ba2:	88 02                	mov    %al,(%edx)
}
f0105ba4:	5d                   	pop    %ebp
f0105ba5:	c3                   	ret    

f0105ba6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0105ba6:	55                   	push   %ebp
f0105ba7:	89 e5                	mov    %esp,%ebp
f0105ba9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0105bac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0105baf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105bb3:	8b 45 10             	mov    0x10(%ebp),%eax
f0105bb6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105bba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105bbd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105bc1:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bc4:	89 04 24             	mov    %eax,(%esp)
f0105bc7:	e8 02 00 00 00       	call   f0105bce <vprintfmt>
	va_end(ap);
}
f0105bcc:	c9                   	leave  
f0105bcd:	c3                   	ret    

f0105bce <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0105bce:	55                   	push   %ebp
f0105bcf:	89 e5                	mov    %esp,%ebp
f0105bd1:	57                   	push   %edi
f0105bd2:	56                   	push   %esi
f0105bd3:	53                   	push   %ebx
f0105bd4:	83 ec 3c             	sub    $0x3c,%esp
f0105bd7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105bda:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0105bdd:	eb 14                	jmp    f0105bf3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0105bdf:	85 c0                	test   %eax,%eax
f0105be1:	0f 84 b3 03 00 00    	je     f0105f9a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0105be7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105beb:	89 04 24             	mov    %eax,(%esp)
f0105bee:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105bf1:	89 f3                	mov    %esi,%ebx
f0105bf3:	8d 73 01             	lea    0x1(%ebx),%esi
f0105bf6:	0f b6 03             	movzbl (%ebx),%eax
f0105bf9:	83 f8 25             	cmp    $0x25,%eax
f0105bfc:	75 e1                	jne    f0105bdf <vprintfmt+0x11>
f0105bfe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0105c02:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0105c09:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105c10:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105c17:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c1c:	eb 1d                	jmp    f0105c3b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105c1e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105c20:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0105c24:	eb 15                	jmp    f0105c3b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105c26:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105c28:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0105c2c:	eb 0d                	jmp    f0105c3b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0105c2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105c31:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105c34:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105c3b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0105c3e:	0f b6 0e             	movzbl (%esi),%ecx
f0105c41:	0f b6 c1             	movzbl %cl,%eax
f0105c44:	83 e9 23             	sub    $0x23,%ecx
f0105c47:	80 f9 55             	cmp    $0x55,%cl
f0105c4a:	0f 87 2a 03 00 00    	ja     f0105f7a <vprintfmt+0x3ac>
f0105c50:	0f b6 c9             	movzbl %cl,%ecx
f0105c53:	ff 24 8d 60 89 10 f0 	jmp    *-0xfef76a0(,%ecx,4)
f0105c5a:	89 de                	mov    %ebx,%esi
f0105c5c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0105c61:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0105c64:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0105c68:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0105c6b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0105c6e:	83 fb 09             	cmp    $0x9,%ebx
f0105c71:	77 36                	ja     f0105ca9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105c73:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105c76:	eb e9                	jmp    f0105c61 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105c78:	8b 45 14             	mov    0x14(%ebp),%eax
f0105c7b:	8d 48 04             	lea    0x4(%eax),%ecx
f0105c7e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105c81:	8b 00                	mov    (%eax),%eax
f0105c83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105c86:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0105c88:	eb 22                	jmp    f0105cac <vprintfmt+0xde>
f0105c8a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105c8d:	85 c9                	test   %ecx,%ecx
f0105c8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c94:	0f 49 c1             	cmovns %ecx,%eax
f0105c97:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105c9a:	89 de                	mov    %ebx,%esi
f0105c9c:	eb 9d                	jmp    f0105c3b <vprintfmt+0x6d>
f0105c9e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0105ca0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0105ca7:	eb 92                	jmp    f0105c3b <vprintfmt+0x6d>
f0105ca9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0105cac:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105cb0:	79 89                	jns    f0105c3b <vprintfmt+0x6d>
f0105cb2:	e9 77 ff ff ff       	jmp    f0105c2e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0105cb7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105cba:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0105cbc:	e9 7a ff ff ff       	jmp    f0105c3b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105cc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0105cc4:	8d 50 04             	lea    0x4(%eax),%edx
f0105cc7:	89 55 14             	mov    %edx,0x14(%ebp)
f0105cca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105cce:	8b 00                	mov    (%eax),%eax
f0105cd0:	89 04 24             	mov    %eax,(%esp)
f0105cd3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105cd6:	e9 18 ff ff ff       	jmp    f0105bf3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105cdb:	8b 45 14             	mov    0x14(%ebp),%eax
f0105cde:	8d 50 04             	lea    0x4(%eax),%edx
f0105ce1:	89 55 14             	mov    %edx,0x14(%ebp)
f0105ce4:	8b 00                	mov    (%eax),%eax
f0105ce6:	99                   	cltd   
f0105ce7:	31 d0                	xor    %edx,%eax
f0105ce9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0105ceb:	83 f8 09             	cmp    $0x9,%eax
f0105cee:	7f 0b                	jg     f0105cfb <vprintfmt+0x12d>
f0105cf0:	8b 14 85 c0 8a 10 f0 	mov    -0xfef7540(,%eax,4),%edx
f0105cf7:	85 d2                	test   %edx,%edx
f0105cf9:	75 20                	jne    f0105d1b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0105cfb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105cff:	c7 44 24 08 c2 88 10 	movl   $0xf01088c2,0x8(%esp)
f0105d06:	f0 
f0105d07:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105d0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d0e:	89 04 24             	mov    %eax,(%esp)
f0105d11:	e8 90 fe ff ff       	call   f0105ba6 <printfmt>
f0105d16:	e9 d8 fe ff ff       	jmp    f0105bf3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0105d1b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105d1f:	c7 44 24 08 6d 80 10 	movl   $0xf010806d,0x8(%esp)
f0105d26:	f0 
f0105d27:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105d2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d2e:	89 04 24             	mov    %eax,(%esp)
f0105d31:	e8 70 fe ff ff       	call   f0105ba6 <printfmt>
f0105d36:	e9 b8 fe ff ff       	jmp    f0105bf3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105d3b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0105d3e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105d41:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105d44:	8b 45 14             	mov    0x14(%ebp),%eax
f0105d47:	8d 50 04             	lea    0x4(%eax),%edx
f0105d4a:	89 55 14             	mov    %edx,0x14(%ebp)
f0105d4d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0105d4f:	85 f6                	test   %esi,%esi
f0105d51:	b8 bb 88 10 f0       	mov    $0xf01088bb,%eax
f0105d56:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0105d59:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0105d5d:	0f 84 97 00 00 00    	je     f0105dfa <vprintfmt+0x22c>
f0105d63:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105d67:	0f 8e 9b 00 00 00    	jle    f0105e08 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0105d6d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105d71:	89 34 24             	mov    %esi,(%esp)
f0105d74:	e8 9f 03 00 00       	call   f0106118 <strnlen>
f0105d79:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0105d7c:	29 c2                	sub    %eax,%edx
f0105d7e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105d81:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105d85:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105d88:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0105d8b:	8b 75 08             	mov    0x8(%ebp),%esi
f0105d8e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105d91:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105d93:	eb 0f                	jmp    f0105da4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105d95:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105d99:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105d9c:	89 04 24             	mov    %eax,(%esp)
f0105d9f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105da1:	83 eb 01             	sub    $0x1,%ebx
f0105da4:	85 db                	test   %ebx,%ebx
f0105da6:	7f ed                	jg     f0105d95 <vprintfmt+0x1c7>
f0105da8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0105dab:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0105dae:	85 d2                	test   %edx,%edx
f0105db0:	b8 00 00 00 00       	mov    $0x0,%eax
f0105db5:	0f 49 c2             	cmovns %edx,%eax
f0105db8:	29 c2                	sub    %eax,%edx
f0105dba:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105dbd:	89 d7                	mov    %edx,%edi
f0105dbf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105dc2:	eb 50                	jmp    f0105e14 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0105dc4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105dc8:	74 1e                	je     f0105de8 <vprintfmt+0x21a>
f0105dca:	0f be d2             	movsbl %dl,%edx
f0105dcd:	83 ea 20             	sub    $0x20,%edx
f0105dd0:	83 fa 5e             	cmp    $0x5e,%edx
f0105dd3:	76 13                	jbe    f0105de8 <vprintfmt+0x21a>
					putch('?', putdat);
f0105dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105dd8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105ddc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0105de3:	ff 55 08             	call   *0x8(%ebp)
f0105de6:	eb 0d                	jmp    f0105df5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0105de8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105deb:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105def:	89 04 24             	mov    %eax,(%esp)
f0105df2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105df5:	83 ef 01             	sub    $0x1,%edi
f0105df8:	eb 1a                	jmp    f0105e14 <vprintfmt+0x246>
f0105dfa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105dfd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105e00:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105e03:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105e06:	eb 0c                	jmp    f0105e14 <vprintfmt+0x246>
f0105e08:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105e0b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105e0e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105e11:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105e14:	83 c6 01             	add    $0x1,%esi
f0105e17:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0105e1b:	0f be c2             	movsbl %dl,%eax
f0105e1e:	85 c0                	test   %eax,%eax
f0105e20:	74 27                	je     f0105e49 <vprintfmt+0x27b>
f0105e22:	85 db                	test   %ebx,%ebx
f0105e24:	78 9e                	js     f0105dc4 <vprintfmt+0x1f6>
f0105e26:	83 eb 01             	sub    $0x1,%ebx
f0105e29:	79 99                	jns    f0105dc4 <vprintfmt+0x1f6>
f0105e2b:	89 f8                	mov    %edi,%eax
f0105e2d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105e30:	8b 75 08             	mov    0x8(%ebp),%esi
f0105e33:	89 c3                	mov    %eax,%ebx
f0105e35:	eb 1a                	jmp    f0105e51 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105e37:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105e3b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0105e42:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105e44:	83 eb 01             	sub    $0x1,%ebx
f0105e47:	eb 08                	jmp    f0105e51 <vprintfmt+0x283>
f0105e49:	89 fb                	mov    %edi,%ebx
f0105e4b:	8b 75 08             	mov    0x8(%ebp),%esi
f0105e4e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105e51:	85 db                	test   %ebx,%ebx
f0105e53:	7f e2                	jg     f0105e37 <vprintfmt+0x269>
f0105e55:	89 75 08             	mov    %esi,0x8(%ebp)
f0105e58:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0105e5b:	e9 93 fd ff ff       	jmp    f0105bf3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105e60:	83 fa 01             	cmp    $0x1,%edx
f0105e63:	7e 16                	jle    f0105e7b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105e65:	8b 45 14             	mov    0x14(%ebp),%eax
f0105e68:	8d 50 08             	lea    0x8(%eax),%edx
f0105e6b:	89 55 14             	mov    %edx,0x14(%ebp)
f0105e6e:	8b 50 04             	mov    0x4(%eax),%edx
f0105e71:	8b 00                	mov    (%eax),%eax
f0105e73:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105e76:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105e79:	eb 32                	jmp    f0105ead <vprintfmt+0x2df>
	else if (lflag)
f0105e7b:	85 d2                	test   %edx,%edx
f0105e7d:	74 18                	je     f0105e97 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f0105e7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105e82:	8d 50 04             	lea    0x4(%eax),%edx
f0105e85:	89 55 14             	mov    %edx,0x14(%ebp)
f0105e88:	8b 30                	mov    (%eax),%esi
f0105e8a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105e8d:	89 f0                	mov    %esi,%eax
f0105e8f:	c1 f8 1f             	sar    $0x1f,%eax
f0105e92:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105e95:	eb 16                	jmp    f0105ead <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0105e97:	8b 45 14             	mov    0x14(%ebp),%eax
f0105e9a:	8d 50 04             	lea    0x4(%eax),%edx
f0105e9d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105ea0:	8b 30                	mov    (%eax),%esi
f0105ea2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105ea5:	89 f0                	mov    %esi,%eax
f0105ea7:	c1 f8 1f             	sar    $0x1f,%eax
f0105eaa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105ead:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105eb0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105eb3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105eb8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105ebc:	0f 89 80 00 00 00    	jns    f0105f42 <vprintfmt+0x374>
				putch('-', putdat);
f0105ec2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105ec6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0105ecd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0105ed0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105ed3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105ed6:	f7 d8                	neg    %eax
f0105ed8:	83 d2 00             	adc    $0x0,%edx
f0105edb:	f7 da                	neg    %edx
			}
			base = 10;
f0105edd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105ee2:	eb 5e                	jmp    f0105f42 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105ee4:	8d 45 14             	lea    0x14(%ebp),%eax
f0105ee7:	e8 63 fc ff ff       	call   f0105b4f <getuint>
			base = 10;
f0105eec:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105ef1:	eb 4f                	jmp    f0105f42 <vprintfmt+0x374>
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint (&ap, lflag);
f0105ef3:	8d 45 14             	lea    0x14(%ebp),%eax
f0105ef6:	e8 54 fc ff ff       	call   f0105b4f <getuint>
			base = 8;
f0105efb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105f00:	eb 40                	jmp    f0105f42 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0105f02:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105f06:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0105f0d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105f10:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105f14:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0105f1b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0105f1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105f21:	8d 50 04             	lea    0x4(%eax),%edx
f0105f24:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105f27:	8b 00                	mov    (%eax),%eax
f0105f29:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0105f2e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105f33:	eb 0d                	jmp    f0105f42 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105f35:	8d 45 14             	lea    0x14(%ebp),%eax
f0105f38:	e8 12 fc ff ff       	call   f0105b4f <getuint>
			base = 16;
f0105f3d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105f42:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0105f46:	89 74 24 10          	mov    %esi,0x10(%esp)
f0105f4a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0105f4d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105f51:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105f55:	89 04 24             	mov    %eax,(%esp)
f0105f58:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105f5c:	89 fa                	mov    %edi,%edx
f0105f5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f61:	e8 fa fa ff ff       	call   f0105a60 <printnum>
			break;
f0105f66:	e9 88 fc ff ff       	jmp    f0105bf3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105f6b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105f6f:	89 04 24             	mov    %eax,(%esp)
f0105f72:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105f75:	e9 79 fc ff ff       	jmp    f0105bf3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105f7a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105f7e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105f85:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105f88:	89 f3                	mov    %esi,%ebx
f0105f8a:	eb 03                	jmp    f0105f8f <vprintfmt+0x3c1>
f0105f8c:	83 eb 01             	sub    $0x1,%ebx
f0105f8f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105f93:	75 f7                	jne    f0105f8c <vprintfmt+0x3be>
f0105f95:	e9 59 fc ff ff       	jmp    f0105bf3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0105f9a:	83 c4 3c             	add    $0x3c,%esp
f0105f9d:	5b                   	pop    %ebx
f0105f9e:	5e                   	pop    %esi
f0105f9f:	5f                   	pop    %edi
f0105fa0:	5d                   	pop    %ebp
f0105fa1:	c3                   	ret    

f0105fa2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105fa2:	55                   	push   %ebp
f0105fa3:	89 e5                	mov    %esp,%ebp
f0105fa5:	83 ec 28             	sub    $0x28,%esp
f0105fa8:	8b 45 08             	mov    0x8(%ebp),%eax
f0105fab:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105fae:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105fb1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105fb5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105fb8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105fbf:	85 c0                	test   %eax,%eax
f0105fc1:	74 30                	je     f0105ff3 <vsnprintf+0x51>
f0105fc3:	85 d2                	test   %edx,%edx
f0105fc5:	7e 2c                	jle    f0105ff3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105fc7:	8b 45 14             	mov    0x14(%ebp),%eax
f0105fca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105fce:	8b 45 10             	mov    0x10(%ebp),%eax
f0105fd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105fd5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105fd8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105fdc:	c7 04 24 89 5b 10 f0 	movl   $0xf0105b89,(%esp)
f0105fe3:	e8 e6 fb ff ff       	call   f0105bce <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105fe8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105feb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105fee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105ff1:	eb 05                	jmp    f0105ff8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105ff3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105ff8:	c9                   	leave  
f0105ff9:	c3                   	ret    

f0105ffa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105ffa:	55                   	push   %ebp
f0105ffb:	89 e5                	mov    %esp,%ebp
f0105ffd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0106000:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0106003:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106007:	8b 45 10             	mov    0x10(%ebp),%eax
f010600a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010600e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106011:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106015:	8b 45 08             	mov    0x8(%ebp),%eax
f0106018:	89 04 24             	mov    %eax,(%esp)
f010601b:	e8 82 ff ff ff       	call   f0105fa2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0106020:	c9                   	leave  
f0106021:	c3                   	ret    
f0106022:	66 90                	xchg   %ax,%ax
f0106024:	66 90                	xchg   %ax,%ax
f0106026:	66 90                	xchg   %ax,%ax
f0106028:	66 90                	xchg   %ax,%ax
f010602a:	66 90                	xchg   %ax,%ax
f010602c:	66 90                	xchg   %ax,%ax
f010602e:	66 90                	xchg   %ax,%ax

f0106030 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0106030:	55                   	push   %ebp
f0106031:	89 e5                	mov    %esp,%ebp
f0106033:	57                   	push   %edi
f0106034:	56                   	push   %esi
f0106035:	53                   	push   %ebx
f0106036:	83 ec 1c             	sub    $0x1c,%esp
f0106039:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010603c:	85 c0                	test   %eax,%eax
f010603e:	74 10                	je     f0106050 <readline+0x20>
		cprintf("%s", prompt);
f0106040:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106044:	c7 04 24 6d 80 10 f0 	movl   $0xf010806d,(%esp)
f010604b:	e8 ba e2 ff ff       	call   f010430a <cprintf>

	i = 0;
	echoing = iscons(0);
f0106050:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0106057:	e8 53 a7 ff ff       	call   f01007af <iscons>
f010605c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010605e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0106063:	e8 36 a7 ff ff       	call   f010079e <getchar>
f0106068:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010606a:	85 c0                	test   %eax,%eax
f010606c:	79 17                	jns    f0106085 <readline+0x55>
			cprintf("read error: %e\n", c);
f010606e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106072:	c7 04 24 e8 8a 10 f0 	movl   $0xf0108ae8,(%esp)
f0106079:	e8 8c e2 ff ff       	call   f010430a <cprintf>
			return NULL;
f010607e:	b8 00 00 00 00       	mov    $0x0,%eax
f0106083:	eb 6d                	jmp    f01060f2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0106085:	83 f8 7f             	cmp    $0x7f,%eax
f0106088:	74 05                	je     f010608f <readline+0x5f>
f010608a:	83 f8 08             	cmp    $0x8,%eax
f010608d:	75 19                	jne    f01060a8 <readline+0x78>
f010608f:	85 f6                	test   %esi,%esi
f0106091:	7e 15                	jle    f01060a8 <readline+0x78>
			if (echoing)
f0106093:	85 ff                	test   %edi,%edi
f0106095:	74 0c                	je     f01060a3 <readline+0x73>
				cputchar('\b');
f0106097:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010609e:	e8 eb a6 ff ff       	call   f010078e <cputchar>
			i--;
f01060a3:	83 ee 01             	sub    $0x1,%esi
f01060a6:	eb bb                	jmp    f0106063 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01060a8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01060ae:	7f 1c                	jg     f01060cc <readline+0x9c>
f01060b0:	83 fb 1f             	cmp    $0x1f,%ebx
f01060b3:	7e 17                	jle    f01060cc <readline+0x9c>
			if (echoing)
f01060b5:	85 ff                	test   %edi,%edi
f01060b7:	74 08                	je     f01060c1 <readline+0x91>
				cputchar(c);
f01060b9:	89 1c 24             	mov    %ebx,(%esp)
f01060bc:	e8 cd a6 ff ff       	call   f010078e <cputchar>
			buf[i++] = c;
f01060c1:	88 9e 80 3a 23 f0    	mov    %bl,-0xfdcc580(%esi)
f01060c7:	8d 76 01             	lea    0x1(%esi),%esi
f01060ca:	eb 97                	jmp    f0106063 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01060cc:	83 fb 0d             	cmp    $0xd,%ebx
f01060cf:	74 05                	je     f01060d6 <readline+0xa6>
f01060d1:	83 fb 0a             	cmp    $0xa,%ebx
f01060d4:	75 8d                	jne    f0106063 <readline+0x33>
			if (echoing)
f01060d6:	85 ff                	test   %edi,%edi
f01060d8:	74 0c                	je     f01060e6 <readline+0xb6>
				cputchar('\n');
f01060da:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01060e1:	e8 a8 a6 ff ff       	call   f010078e <cputchar>
			buf[i] = 0;
f01060e6:	c6 86 80 3a 23 f0 00 	movb   $0x0,-0xfdcc580(%esi)
			return buf;
f01060ed:	b8 80 3a 23 f0       	mov    $0xf0233a80,%eax
		}
	}
}
f01060f2:	83 c4 1c             	add    $0x1c,%esp
f01060f5:	5b                   	pop    %ebx
f01060f6:	5e                   	pop    %esi
f01060f7:	5f                   	pop    %edi
f01060f8:	5d                   	pop    %ebp
f01060f9:	c3                   	ret    
f01060fa:	66 90                	xchg   %ax,%ax
f01060fc:	66 90                	xchg   %ax,%ax
f01060fe:	66 90                	xchg   %ax,%ax

f0106100 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0106100:	55                   	push   %ebp
f0106101:	89 e5                	mov    %esp,%ebp
f0106103:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0106106:	b8 00 00 00 00       	mov    $0x0,%eax
f010610b:	eb 03                	jmp    f0106110 <strlen+0x10>
		n++;
f010610d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0106110:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0106114:	75 f7                	jne    f010610d <strlen+0xd>
		n++;
	return n;
}
f0106116:	5d                   	pop    %ebp
f0106117:	c3                   	ret    

f0106118 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0106118:	55                   	push   %ebp
f0106119:	89 e5                	mov    %esp,%ebp
f010611b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010611e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0106121:	b8 00 00 00 00       	mov    $0x0,%eax
f0106126:	eb 03                	jmp    f010612b <strnlen+0x13>
		n++;
f0106128:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010612b:	39 d0                	cmp    %edx,%eax
f010612d:	74 06                	je     f0106135 <strnlen+0x1d>
f010612f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0106133:	75 f3                	jne    f0106128 <strnlen+0x10>
		n++;
	return n;
}
f0106135:	5d                   	pop    %ebp
f0106136:	c3                   	ret    

f0106137 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0106137:	55                   	push   %ebp
f0106138:	89 e5                	mov    %esp,%ebp
f010613a:	53                   	push   %ebx
f010613b:	8b 45 08             	mov    0x8(%ebp),%eax
f010613e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0106141:	89 c2                	mov    %eax,%edx
f0106143:	83 c2 01             	add    $0x1,%edx
f0106146:	83 c1 01             	add    $0x1,%ecx
f0106149:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010614d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0106150:	84 db                	test   %bl,%bl
f0106152:	75 ef                	jne    f0106143 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0106154:	5b                   	pop    %ebx
f0106155:	5d                   	pop    %ebp
f0106156:	c3                   	ret    

f0106157 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0106157:	55                   	push   %ebp
f0106158:	89 e5                	mov    %esp,%ebp
f010615a:	53                   	push   %ebx
f010615b:	83 ec 08             	sub    $0x8,%esp
f010615e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0106161:	89 1c 24             	mov    %ebx,(%esp)
f0106164:	e8 97 ff ff ff       	call   f0106100 <strlen>
	strcpy(dst + len, src);
f0106169:	8b 55 0c             	mov    0xc(%ebp),%edx
f010616c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106170:	01 d8                	add    %ebx,%eax
f0106172:	89 04 24             	mov    %eax,(%esp)
f0106175:	e8 bd ff ff ff       	call   f0106137 <strcpy>
	return dst;
}
f010617a:	89 d8                	mov    %ebx,%eax
f010617c:	83 c4 08             	add    $0x8,%esp
f010617f:	5b                   	pop    %ebx
f0106180:	5d                   	pop    %ebp
f0106181:	c3                   	ret    

f0106182 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0106182:	55                   	push   %ebp
f0106183:	89 e5                	mov    %esp,%ebp
f0106185:	56                   	push   %esi
f0106186:	53                   	push   %ebx
f0106187:	8b 75 08             	mov    0x8(%ebp),%esi
f010618a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010618d:	89 f3                	mov    %esi,%ebx
f010618f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0106192:	89 f2                	mov    %esi,%edx
f0106194:	eb 0f                	jmp    f01061a5 <strncpy+0x23>
		*dst++ = *src;
f0106196:	83 c2 01             	add    $0x1,%edx
f0106199:	0f b6 01             	movzbl (%ecx),%eax
f010619c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010619f:	80 39 01             	cmpb   $0x1,(%ecx)
f01061a2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01061a5:	39 da                	cmp    %ebx,%edx
f01061a7:	75 ed                	jne    f0106196 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01061a9:	89 f0                	mov    %esi,%eax
f01061ab:	5b                   	pop    %ebx
f01061ac:	5e                   	pop    %esi
f01061ad:	5d                   	pop    %ebp
f01061ae:	c3                   	ret    

f01061af <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01061af:	55                   	push   %ebp
f01061b0:	89 e5                	mov    %esp,%ebp
f01061b2:	56                   	push   %esi
f01061b3:	53                   	push   %ebx
f01061b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01061b7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01061ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01061bd:	89 f0                	mov    %esi,%eax
f01061bf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01061c3:	85 c9                	test   %ecx,%ecx
f01061c5:	75 0b                	jne    f01061d2 <strlcpy+0x23>
f01061c7:	eb 1d                	jmp    f01061e6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01061c9:	83 c0 01             	add    $0x1,%eax
f01061cc:	83 c2 01             	add    $0x1,%edx
f01061cf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01061d2:	39 d8                	cmp    %ebx,%eax
f01061d4:	74 0b                	je     f01061e1 <strlcpy+0x32>
f01061d6:	0f b6 0a             	movzbl (%edx),%ecx
f01061d9:	84 c9                	test   %cl,%cl
f01061db:	75 ec                	jne    f01061c9 <strlcpy+0x1a>
f01061dd:	89 c2                	mov    %eax,%edx
f01061df:	eb 02                	jmp    f01061e3 <strlcpy+0x34>
f01061e1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01061e3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01061e6:	29 f0                	sub    %esi,%eax
}
f01061e8:	5b                   	pop    %ebx
f01061e9:	5e                   	pop    %esi
f01061ea:	5d                   	pop    %ebp
f01061eb:	c3                   	ret    

f01061ec <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01061ec:	55                   	push   %ebp
f01061ed:	89 e5                	mov    %esp,%ebp
f01061ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01061f2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01061f5:	eb 06                	jmp    f01061fd <strcmp+0x11>
		p++, q++;
f01061f7:	83 c1 01             	add    $0x1,%ecx
f01061fa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01061fd:	0f b6 01             	movzbl (%ecx),%eax
f0106200:	84 c0                	test   %al,%al
f0106202:	74 04                	je     f0106208 <strcmp+0x1c>
f0106204:	3a 02                	cmp    (%edx),%al
f0106206:	74 ef                	je     f01061f7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0106208:	0f b6 c0             	movzbl %al,%eax
f010620b:	0f b6 12             	movzbl (%edx),%edx
f010620e:	29 d0                	sub    %edx,%eax
}
f0106210:	5d                   	pop    %ebp
f0106211:	c3                   	ret    

f0106212 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0106212:	55                   	push   %ebp
f0106213:	89 e5                	mov    %esp,%ebp
f0106215:	53                   	push   %ebx
f0106216:	8b 45 08             	mov    0x8(%ebp),%eax
f0106219:	8b 55 0c             	mov    0xc(%ebp),%edx
f010621c:	89 c3                	mov    %eax,%ebx
f010621e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0106221:	eb 06                	jmp    f0106229 <strncmp+0x17>
		n--, p++, q++;
f0106223:	83 c0 01             	add    $0x1,%eax
f0106226:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0106229:	39 d8                	cmp    %ebx,%eax
f010622b:	74 15                	je     f0106242 <strncmp+0x30>
f010622d:	0f b6 08             	movzbl (%eax),%ecx
f0106230:	84 c9                	test   %cl,%cl
f0106232:	74 04                	je     f0106238 <strncmp+0x26>
f0106234:	3a 0a                	cmp    (%edx),%cl
f0106236:	74 eb                	je     f0106223 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0106238:	0f b6 00             	movzbl (%eax),%eax
f010623b:	0f b6 12             	movzbl (%edx),%edx
f010623e:	29 d0                	sub    %edx,%eax
f0106240:	eb 05                	jmp    f0106247 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0106242:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0106247:	5b                   	pop    %ebx
f0106248:	5d                   	pop    %ebp
f0106249:	c3                   	ret    

f010624a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010624a:	55                   	push   %ebp
f010624b:	89 e5                	mov    %esp,%ebp
f010624d:	8b 45 08             	mov    0x8(%ebp),%eax
f0106250:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0106254:	eb 07                	jmp    f010625d <strchr+0x13>
		if (*s == c)
f0106256:	38 ca                	cmp    %cl,%dl
f0106258:	74 0f                	je     f0106269 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010625a:	83 c0 01             	add    $0x1,%eax
f010625d:	0f b6 10             	movzbl (%eax),%edx
f0106260:	84 d2                	test   %dl,%dl
f0106262:	75 f2                	jne    f0106256 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0106264:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106269:	5d                   	pop    %ebp
f010626a:	c3                   	ret    

f010626b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010626b:	55                   	push   %ebp
f010626c:	89 e5                	mov    %esp,%ebp
f010626e:	8b 45 08             	mov    0x8(%ebp),%eax
f0106271:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0106275:	eb 07                	jmp    f010627e <strfind+0x13>
		if (*s == c)
f0106277:	38 ca                	cmp    %cl,%dl
f0106279:	74 0a                	je     f0106285 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010627b:	83 c0 01             	add    $0x1,%eax
f010627e:	0f b6 10             	movzbl (%eax),%edx
f0106281:	84 d2                	test   %dl,%dl
f0106283:	75 f2                	jne    f0106277 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0106285:	5d                   	pop    %ebp
f0106286:	c3                   	ret    

f0106287 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0106287:	55                   	push   %ebp
f0106288:	89 e5                	mov    %esp,%ebp
f010628a:	57                   	push   %edi
f010628b:	56                   	push   %esi
f010628c:	53                   	push   %ebx
f010628d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0106290:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0106293:	85 c9                	test   %ecx,%ecx
f0106295:	74 36                	je     f01062cd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0106297:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010629d:	75 28                	jne    f01062c7 <memset+0x40>
f010629f:	f6 c1 03             	test   $0x3,%cl
f01062a2:	75 23                	jne    f01062c7 <memset+0x40>
		c &= 0xFF;
f01062a4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01062a8:	89 d3                	mov    %edx,%ebx
f01062aa:	c1 e3 08             	shl    $0x8,%ebx
f01062ad:	89 d6                	mov    %edx,%esi
f01062af:	c1 e6 18             	shl    $0x18,%esi
f01062b2:	89 d0                	mov    %edx,%eax
f01062b4:	c1 e0 10             	shl    $0x10,%eax
f01062b7:	09 f0                	or     %esi,%eax
f01062b9:	09 c2                	or     %eax,%edx
f01062bb:	89 d0                	mov    %edx,%eax
f01062bd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01062bf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01062c2:	fc                   	cld    
f01062c3:	f3 ab                	rep stos %eax,%es:(%edi)
f01062c5:	eb 06                	jmp    f01062cd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01062c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01062ca:	fc                   	cld    
f01062cb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01062cd:	89 f8                	mov    %edi,%eax
f01062cf:	5b                   	pop    %ebx
f01062d0:	5e                   	pop    %esi
f01062d1:	5f                   	pop    %edi
f01062d2:	5d                   	pop    %ebp
f01062d3:	c3                   	ret    

f01062d4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01062d4:	55                   	push   %ebp
f01062d5:	89 e5                	mov    %esp,%ebp
f01062d7:	57                   	push   %edi
f01062d8:	56                   	push   %esi
f01062d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01062dc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01062df:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01062e2:	39 c6                	cmp    %eax,%esi
f01062e4:	73 35                	jae    f010631b <memmove+0x47>
f01062e6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01062e9:	39 d0                	cmp    %edx,%eax
f01062eb:	73 2e                	jae    f010631b <memmove+0x47>
		s += n;
		d += n;
f01062ed:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01062f0:	89 d6                	mov    %edx,%esi
f01062f2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01062f4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01062fa:	75 13                	jne    f010630f <memmove+0x3b>
f01062fc:	f6 c1 03             	test   $0x3,%cl
f01062ff:	75 0e                	jne    f010630f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0106301:	83 ef 04             	sub    $0x4,%edi
f0106304:	8d 72 fc             	lea    -0x4(%edx),%esi
f0106307:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010630a:	fd                   	std    
f010630b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010630d:	eb 09                	jmp    f0106318 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010630f:	83 ef 01             	sub    $0x1,%edi
f0106312:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0106315:	fd                   	std    
f0106316:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0106318:	fc                   	cld    
f0106319:	eb 1d                	jmp    f0106338 <memmove+0x64>
f010631b:	89 f2                	mov    %esi,%edx
f010631d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010631f:	f6 c2 03             	test   $0x3,%dl
f0106322:	75 0f                	jne    f0106333 <memmove+0x5f>
f0106324:	f6 c1 03             	test   $0x3,%cl
f0106327:	75 0a                	jne    f0106333 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0106329:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010632c:	89 c7                	mov    %eax,%edi
f010632e:	fc                   	cld    
f010632f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0106331:	eb 05                	jmp    f0106338 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0106333:	89 c7                	mov    %eax,%edi
f0106335:	fc                   	cld    
f0106336:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0106338:	5e                   	pop    %esi
f0106339:	5f                   	pop    %edi
f010633a:	5d                   	pop    %ebp
f010633b:	c3                   	ret    

f010633c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010633c:	55                   	push   %ebp
f010633d:	89 e5                	mov    %esp,%ebp
f010633f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0106342:	8b 45 10             	mov    0x10(%ebp),%eax
f0106345:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106349:	8b 45 0c             	mov    0xc(%ebp),%eax
f010634c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106350:	8b 45 08             	mov    0x8(%ebp),%eax
f0106353:	89 04 24             	mov    %eax,(%esp)
f0106356:	e8 79 ff ff ff       	call   f01062d4 <memmove>
}
f010635b:	c9                   	leave  
f010635c:	c3                   	ret    

f010635d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010635d:	55                   	push   %ebp
f010635e:	89 e5                	mov    %esp,%ebp
f0106360:	56                   	push   %esi
f0106361:	53                   	push   %ebx
f0106362:	8b 55 08             	mov    0x8(%ebp),%edx
f0106365:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0106368:	89 d6                	mov    %edx,%esi
f010636a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010636d:	eb 1a                	jmp    f0106389 <memcmp+0x2c>
		if (*s1 != *s2)
f010636f:	0f b6 02             	movzbl (%edx),%eax
f0106372:	0f b6 19             	movzbl (%ecx),%ebx
f0106375:	38 d8                	cmp    %bl,%al
f0106377:	74 0a                	je     f0106383 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0106379:	0f b6 c0             	movzbl %al,%eax
f010637c:	0f b6 db             	movzbl %bl,%ebx
f010637f:	29 d8                	sub    %ebx,%eax
f0106381:	eb 0f                	jmp    f0106392 <memcmp+0x35>
		s1++, s2++;
f0106383:	83 c2 01             	add    $0x1,%edx
f0106386:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0106389:	39 f2                	cmp    %esi,%edx
f010638b:	75 e2                	jne    f010636f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010638d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106392:	5b                   	pop    %ebx
f0106393:	5e                   	pop    %esi
f0106394:	5d                   	pop    %ebp
f0106395:	c3                   	ret    

f0106396 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0106396:	55                   	push   %ebp
f0106397:	89 e5                	mov    %esp,%ebp
f0106399:	8b 45 08             	mov    0x8(%ebp),%eax
f010639c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010639f:	89 c2                	mov    %eax,%edx
f01063a1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01063a4:	eb 07                	jmp    f01063ad <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01063a6:	38 08                	cmp    %cl,(%eax)
f01063a8:	74 07                	je     f01063b1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01063aa:	83 c0 01             	add    $0x1,%eax
f01063ad:	39 d0                	cmp    %edx,%eax
f01063af:	72 f5                	jb     f01063a6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01063b1:	5d                   	pop    %ebp
f01063b2:	c3                   	ret    

f01063b3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01063b3:	55                   	push   %ebp
f01063b4:	89 e5                	mov    %esp,%ebp
f01063b6:	57                   	push   %edi
f01063b7:	56                   	push   %esi
f01063b8:	53                   	push   %ebx
f01063b9:	8b 55 08             	mov    0x8(%ebp),%edx
f01063bc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01063bf:	eb 03                	jmp    f01063c4 <strtol+0x11>
		s++;
f01063c1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01063c4:	0f b6 0a             	movzbl (%edx),%ecx
f01063c7:	80 f9 09             	cmp    $0x9,%cl
f01063ca:	74 f5                	je     f01063c1 <strtol+0xe>
f01063cc:	80 f9 20             	cmp    $0x20,%cl
f01063cf:	74 f0                	je     f01063c1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01063d1:	80 f9 2b             	cmp    $0x2b,%cl
f01063d4:	75 0a                	jne    f01063e0 <strtol+0x2d>
		s++;
f01063d6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01063d9:	bf 00 00 00 00       	mov    $0x0,%edi
f01063de:	eb 11                	jmp    f01063f1 <strtol+0x3e>
f01063e0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01063e5:	80 f9 2d             	cmp    $0x2d,%cl
f01063e8:	75 07                	jne    f01063f1 <strtol+0x3e>
		s++, neg = 1;
f01063ea:	8d 52 01             	lea    0x1(%edx),%edx
f01063ed:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01063f1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01063f6:	75 15                	jne    f010640d <strtol+0x5a>
f01063f8:	80 3a 30             	cmpb   $0x30,(%edx)
f01063fb:	75 10                	jne    f010640d <strtol+0x5a>
f01063fd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0106401:	75 0a                	jne    f010640d <strtol+0x5a>
		s += 2, base = 16;
f0106403:	83 c2 02             	add    $0x2,%edx
f0106406:	b8 10 00 00 00       	mov    $0x10,%eax
f010640b:	eb 10                	jmp    f010641d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010640d:	85 c0                	test   %eax,%eax
f010640f:	75 0c                	jne    f010641d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0106411:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0106413:	80 3a 30             	cmpb   $0x30,(%edx)
f0106416:	75 05                	jne    f010641d <strtol+0x6a>
		s++, base = 8;
f0106418:	83 c2 01             	add    $0x1,%edx
f010641b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010641d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0106422:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0106425:	0f b6 0a             	movzbl (%edx),%ecx
f0106428:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010642b:	89 f0                	mov    %esi,%eax
f010642d:	3c 09                	cmp    $0x9,%al
f010642f:	77 08                	ja     f0106439 <strtol+0x86>
			dig = *s - '0';
f0106431:	0f be c9             	movsbl %cl,%ecx
f0106434:	83 e9 30             	sub    $0x30,%ecx
f0106437:	eb 20                	jmp    f0106459 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0106439:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010643c:	89 f0                	mov    %esi,%eax
f010643e:	3c 19                	cmp    $0x19,%al
f0106440:	77 08                	ja     f010644a <strtol+0x97>
			dig = *s - 'a' + 10;
f0106442:	0f be c9             	movsbl %cl,%ecx
f0106445:	83 e9 57             	sub    $0x57,%ecx
f0106448:	eb 0f                	jmp    f0106459 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010644a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010644d:	89 f0                	mov    %esi,%eax
f010644f:	3c 19                	cmp    $0x19,%al
f0106451:	77 16                	ja     f0106469 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0106453:	0f be c9             	movsbl %cl,%ecx
f0106456:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0106459:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010645c:	7d 0f                	jge    f010646d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010645e:	83 c2 01             	add    $0x1,%edx
f0106461:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0106465:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0106467:	eb bc                	jmp    f0106425 <strtol+0x72>
f0106469:	89 d8                	mov    %ebx,%eax
f010646b:	eb 02                	jmp    f010646f <strtol+0xbc>
f010646d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010646f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0106473:	74 05                	je     f010647a <strtol+0xc7>
		*endptr = (char *) s;
f0106475:	8b 75 0c             	mov    0xc(%ebp),%esi
f0106478:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010647a:	f7 d8                	neg    %eax
f010647c:	85 ff                	test   %edi,%edi
f010647e:	0f 44 c3             	cmove  %ebx,%eax
}
f0106481:	5b                   	pop    %ebx
f0106482:	5e                   	pop    %esi
f0106483:	5f                   	pop    %edi
f0106484:	5d                   	pop    %ebp
f0106485:	c3                   	ret    
f0106486:	66 90                	xchg   %ax,%ax

f0106488 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0106488:	fa                   	cli    

	xorw    %ax, %ax
f0106489:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010648b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010648d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f010648f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0106491:	0f 01 16             	lgdtl  (%esi)
f0106494:	74 70                	je     f0106506 <mpentry_end+0x4>
	movl    %cr0, %eax
f0106496:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0106499:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f010649d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01064a0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01064a6:	08 00                	or     %al,(%eax)

f01064a8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01064a8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01064ac:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01064ae:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01064b0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01064b2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01064b6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01064b8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01064ba:	b8 00 00 12 00       	mov    $0x120000,%eax
	movl    %eax, %cr3
f01064bf:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01064c2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01064c5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01064ca:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01064cd:	8b 25 84 3e 23 f0    	mov    0xf0233e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01064d3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01064d8:	b8 e2 01 10 f0       	mov    $0xf01001e2,%eax
	call    *%eax
f01064dd:	ff d0                	call   *%eax

f01064df <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01064df:	eb fe                	jmp    f01064df <spin>
f01064e1:	8d 76 00             	lea    0x0(%esi),%esi

f01064e4 <gdt>:
	...
f01064ec:	ff                   	(bad)  
f01064ed:	ff 00                	incl   (%eax)
f01064ef:	00 00                	add    %al,(%eax)
f01064f1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01064f8:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f01064fc <gdtdesc>:
f01064fc:	17                   	pop    %ss
f01064fd:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0106502 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0106502:	90                   	nop
f0106503:	66 90                	xchg   %ax,%ax
f0106505:	66 90                	xchg   %ax,%ax
f0106507:	66 90                	xchg   %ax,%ax
f0106509:	66 90                	xchg   %ax,%ax
f010650b:	66 90                	xchg   %ax,%ax
f010650d:	66 90                	xchg   %ax,%ax
f010650f:	90                   	nop

f0106510 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0106510:	55                   	push   %ebp
f0106511:	89 e5                	mov    %esp,%ebp
f0106513:	56                   	push   %esi
f0106514:	53                   	push   %ebx
f0106515:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106518:	8b 0d 88 3e 23 f0    	mov    0xf0233e88,%ecx
f010651e:	89 c3                	mov    %eax,%ebx
f0106520:	c1 eb 0c             	shr    $0xc,%ebx
f0106523:	39 cb                	cmp    %ecx,%ebx
f0106525:	72 20                	jb     f0106547 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106527:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010652b:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0106532:	f0 
f0106533:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f010653a:	00 
f010653b:	c7 04 24 85 8c 10 f0 	movl   $0xf0108c85,(%esp)
f0106542:	e8 f9 9a ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0106547:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f010654d:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010654f:	89 c2                	mov    %eax,%edx
f0106551:	c1 ea 0c             	shr    $0xc,%edx
f0106554:	39 d1                	cmp    %edx,%ecx
f0106556:	77 20                	ja     f0106578 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106558:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010655c:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0106563:	f0 
f0106564:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f010656b:	00 
f010656c:	c7 04 24 85 8c 10 f0 	movl   $0xf0108c85,(%esp)
f0106573:	e8 c8 9a ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0106578:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010657e:	eb 36                	jmp    f01065b6 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0106580:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0106587:	00 
f0106588:	c7 44 24 04 95 8c 10 	movl   $0xf0108c95,0x4(%esp)
f010658f:	f0 
f0106590:	89 1c 24             	mov    %ebx,(%esp)
f0106593:	e8 c5 fd ff ff       	call   f010635d <memcmp>
f0106598:	85 c0                	test   %eax,%eax
f010659a:	75 17                	jne    f01065b3 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010659c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f01065a1:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01065a5:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01065a7:	83 c2 01             	add    $0x1,%edx
f01065aa:	83 fa 10             	cmp    $0x10,%edx
f01065ad:	75 f2                	jne    f01065a1 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01065af:	84 c0                	test   %al,%al
f01065b1:	74 0e                	je     f01065c1 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01065b3:	83 c3 10             	add    $0x10,%ebx
f01065b6:	39 f3                	cmp    %esi,%ebx
f01065b8:	72 c6                	jb     f0106580 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01065ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01065bf:	eb 02                	jmp    f01065c3 <mpsearch1+0xb3>
f01065c1:	89 d8                	mov    %ebx,%eax
}
f01065c3:	83 c4 10             	add    $0x10,%esp
f01065c6:	5b                   	pop    %ebx
f01065c7:	5e                   	pop    %esi
f01065c8:	5d                   	pop    %ebp
f01065c9:	c3                   	ret    

f01065ca <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01065ca:	55                   	push   %ebp
f01065cb:	89 e5                	mov    %esp,%ebp
f01065cd:	57                   	push   %edi
f01065ce:	56                   	push   %esi
f01065cf:	53                   	push   %ebx
f01065d0:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01065d3:	c7 05 c0 43 23 f0 20 	movl   $0xf0234020,0xf02343c0
f01065da:	40 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01065dd:	83 3d 88 3e 23 f0 00 	cmpl   $0x0,0xf0233e88
f01065e4:	75 24                	jne    f010660a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01065e6:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f01065ed:	00 
f01065ee:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f01065f5:	f0 
f01065f6:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f01065fd:	00 
f01065fe:	c7 04 24 85 8c 10 f0 	movl   $0xf0108c85,(%esp)
f0106605:	e8 36 9a ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010660a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0106611:	85 c0                	test   %eax,%eax
f0106613:	74 16                	je     f010662b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0106615:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0106618:	ba 00 04 00 00       	mov    $0x400,%edx
f010661d:	e8 ee fe ff ff       	call   f0106510 <mpsearch1>
f0106622:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0106625:	85 c0                	test   %eax,%eax
f0106627:	75 3c                	jne    f0106665 <mp_init+0x9b>
f0106629:	eb 20                	jmp    f010664b <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f010662b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0106632:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0106635:	2d 00 04 00 00       	sub    $0x400,%eax
f010663a:	ba 00 04 00 00       	mov    $0x400,%edx
f010663f:	e8 cc fe ff ff       	call   f0106510 <mpsearch1>
f0106644:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0106647:	85 c0                	test   %eax,%eax
f0106649:	75 1a                	jne    f0106665 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010664b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106650:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0106655:	e8 b6 fe ff ff       	call   f0106510 <mpsearch1>
f010665a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f010665d:	85 c0                	test   %eax,%eax
f010665f:	0f 84 54 02 00 00    	je     f01068b9 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0106665:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106668:	8b 70 04             	mov    0x4(%eax),%esi
f010666b:	85 f6                	test   %esi,%esi
f010666d:	74 06                	je     f0106675 <mp_init+0xab>
f010666f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0106673:	74 11                	je     f0106686 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0106675:	c7 04 24 f8 8a 10 f0 	movl   $0xf0108af8,(%esp)
f010667c:	e8 89 dc ff ff       	call   f010430a <cprintf>
f0106681:	e9 33 02 00 00       	jmp    f01068b9 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106686:	89 f0                	mov    %esi,%eax
f0106688:	c1 e8 0c             	shr    $0xc,%eax
f010668b:	3b 05 88 3e 23 f0    	cmp    0xf0233e88,%eax
f0106691:	72 20                	jb     f01066b3 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106693:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0106697:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f010669e:	f0 
f010669f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f01066a6:	00 
f01066a7:	c7 04 24 85 8c 10 f0 	movl   $0xf0108c85,(%esp)
f01066ae:	e8 8d 99 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01066b3:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01066b9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f01066c0:	00 
f01066c1:	c7 44 24 04 9a 8c 10 	movl   $0xf0108c9a,0x4(%esp)
f01066c8:	f0 
f01066c9:	89 1c 24             	mov    %ebx,(%esp)
f01066cc:	e8 8c fc ff ff       	call   f010635d <memcmp>
f01066d1:	85 c0                	test   %eax,%eax
f01066d3:	74 11                	je     f01066e6 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01066d5:	c7 04 24 28 8b 10 f0 	movl   $0xf0108b28,(%esp)
f01066dc:	e8 29 dc ff ff       	call   f010430a <cprintf>
f01066e1:	e9 d3 01 00 00       	jmp    f01068b9 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01066e6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01066ea:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01066ee:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01066f1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01066f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01066fb:	eb 0d                	jmp    f010670a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f01066fd:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0106704:	f0 
f0106705:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106707:	83 c0 01             	add    $0x1,%eax
f010670a:	39 c7                	cmp    %eax,%edi
f010670c:	7f ef                	jg     f01066fd <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010670e:	84 d2                	test   %dl,%dl
f0106710:	74 11                	je     f0106723 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0106712:	c7 04 24 5c 8b 10 f0 	movl   $0xf0108b5c,(%esp)
f0106719:	e8 ec db ff ff       	call   f010430a <cprintf>
f010671e:	e9 96 01 00 00       	jmp    f01068b9 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0106723:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0106727:	3c 04                	cmp    $0x4,%al
f0106729:	74 1f                	je     f010674a <mp_init+0x180>
f010672b:	3c 01                	cmp    $0x1,%al
f010672d:	8d 76 00             	lea    0x0(%esi),%esi
f0106730:	74 18                	je     f010674a <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0106732:	0f b6 c0             	movzbl %al,%eax
f0106735:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106739:	c7 04 24 80 8b 10 f0 	movl   $0xf0108b80,(%esp)
f0106740:	e8 c5 db ff ff       	call   f010430a <cprintf>
f0106745:	e9 6f 01 00 00       	jmp    f01068b9 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010674a:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f010674e:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0106752:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0106754:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0106759:	b8 00 00 00 00       	mov    $0x0,%eax
f010675e:	eb 09                	jmp    f0106769 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0106760:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0106764:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106766:	83 c0 01             	add    $0x1,%eax
f0106769:	39 c6                	cmp    %eax,%esi
f010676b:	7f f3                	jg     f0106760 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010676d:	02 53 2a             	add    0x2a(%ebx),%dl
f0106770:	84 d2                	test   %dl,%dl
f0106772:	74 11                	je     f0106785 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0106774:	c7 04 24 a0 8b 10 f0 	movl   $0xf0108ba0,(%esp)
f010677b:	e8 8a db ff ff       	call   f010430a <cprintf>
f0106780:	e9 34 01 00 00       	jmp    f01068b9 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0106785:	85 db                	test   %ebx,%ebx
f0106787:	0f 84 2c 01 00 00    	je     f01068b9 <mp_init+0x2ef>
		return;
	ismp = 1;
f010678d:	c7 05 00 40 23 f0 01 	movl   $0x1,0xf0234000
f0106794:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0106797:	8b 43 24             	mov    0x24(%ebx),%eax
f010679a:	a3 00 50 27 f0       	mov    %eax,0xf0275000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010679f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01067a2:	be 00 00 00 00       	mov    $0x0,%esi
f01067a7:	e9 86 00 00 00       	jmp    f0106832 <mp_init+0x268>
		switch (*p) {
f01067ac:	0f b6 07             	movzbl (%edi),%eax
f01067af:	84 c0                	test   %al,%al
f01067b1:	74 06                	je     f01067b9 <mp_init+0x1ef>
f01067b3:	3c 04                	cmp    $0x4,%al
f01067b5:	77 57                	ja     f010680e <mp_init+0x244>
f01067b7:	eb 50                	jmp    f0106809 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01067b9:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01067bd:	8d 76 00             	lea    0x0(%esi),%esi
f01067c0:	74 11                	je     f01067d3 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f01067c2:	6b 05 c4 43 23 f0 74 	imul   $0x74,0xf02343c4,%eax
f01067c9:	05 20 40 23 f0       	add    $0xf0234020,%eax
f01067ce:	a3 c0 43 23 f0       	mov    %eax,0xf02343c0
			if (ncpu < NCPU) {
f01067d3:	a1 c4 43 23 f0       	mov    0xf02343c4,%eax
f01067d8:	83 f8 07             	cmp    $0x7,%eax
f01067db:	7f 13                	jg     f01067f0 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f01067dd:	6b d0 74             	imul   $0x74,%eax,%edx
f01067e0:	88 82 20 40 23 f0    	mov    %al,-0xfdcbfe0(%edx)
				ncpu++;
f01067e6:	83 c0 01             	add    $0x1,%eax
f01067e9:	a3 c4 43 23 f0       	mov    %eax,0xf02343c4
f01067ee:	eb 14                	jmp    f0106804 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01067f0:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01067f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01067f8:	c7 04 24 d0 8b 10 f0 	movl   $0xf0108bd0,(%esp)
f01067ff:	e8 06 db ff ff       	call   f010430a <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106804:	83 c7 14             	add    $0x14,%edi
			continue;
f0106807:	eb 26                	jmp    f010682f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0106809:	83 c7 08             	add    $0x8,%edi
			continue;
f010680c:	eb 21                	jmp    f010682f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010680e:	0f b6 c0             	movzbl %al,%eax
f0106811:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106815:	c7 04 24 f8 8b 10 f0 	movl   $0xf0108bf8,(%esp)
f010681c:	e8 e9 da ff ff       	call   f010430a <cprintf>
			ismp = 0;
f0106821:	c7 05 00 40 23 f0 00 	movl   $0x0,0xf0234000
f0106828:	00 00 00 
			i = conf->entry;
f010682b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010682f:	83 c6 01             	add    $0x1,%esi
f0106832:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0106836:	39 c6                	cmp    %eax,%esi
f0106838:	0f 82 6e ff ff ff    	jb     f01067ac <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010683e:	a1 c0 43 23 f0       	mov    0xf02343c0,%eax
f0106843:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010684a:	83 3d 00 40 23 f0 00 	cmpl   $0x0,0xf0234000
f0106851:	75 22                	jne    f0106875 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0106853:	c7 05 c4 43 23 f0 01 	movl   $0x1,0xf02343c4
f010685a:	00 00 00 
		lapicaddr = 0;
f010685d:	c7 05 00 50 27 f0 00 	movl   $0x0,0xf0275000
f0106864:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106867:	c7 04 24 18 8c 10 f0 	movl   $0xf0108c18,(%esp)
f010686e:	e8 97 da ff ff       	call   f010430a <cprintf>
		return;
f0106873:	eb 44                	jmp    f01068b9 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0106875:	8b 15 c4 43 23 f0    	mov    0xf02343c4,%edx
f010687b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010687f:	0f b6 00             	movzbl (%eax),%eax
f0106882:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106886:	c7 04 24 9f 8c 10 f0 	movl   $0xf0108c9f,(%esp)
f010688d:	e8 78 da ff ff       	call   f010430a <cprintf>

	if (mp->imcrp) {
f0106892:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106895:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106899:	74 1e                	je     f01068b9 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010689b:	c7 04 24 44 8c 10 f0 	movl   $0xf0108c44,(%esp)
f01068a2:	e8 63 da ff ff       	call   f010430a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01068a7:	ba 22 00 00 00       	mov    $0x22,%edx
f01068ac:	b8 70 00 00 00       	mov    $0x70,%eax
f01068b1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01068b2:	b2 23                	mov    $0x23,%dl
f01068b4:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01068b5:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01068b8:	ee                   	out    %al,(%dx)
	}
}
f01068b9:	83 c4 2c             	add    $0x2c,%esp
f01068bc:	5b                   	pop    %ebx
f01068bd:	5e                   	pop    %esi
f01068be:	5f                   	pop    %edi
f01068bf:	5d                   	pop    %ebp
f01068c0:	c3                   	ret    

f01068c1 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01068c1:	55                   	push   %ebp
f01068c2:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01068c4:	8b 0d 04 50 27 f0    	mov    0xf0275004,%ecx
f01068ca:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01068cd:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01068cf:	a1 04 50 27 f0       	mov    0xf0275004,%eax
f01068d4:	8b 40 20             	mov    0x20(%eax),%eax
}
f01068d7:	5d                   	pop    %ebp
f01068d8:	c3                   	ret    

f01068d9 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01068d9:	55                   	push   %ebp
f01068da:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01068dc:	a1 04 50 27 f0       	mov    0xf0275004,%eax
f01068e1:	85 c0                	test   %eax,%eax
f01068e3:	74 08                	je     f01068ed <cpunum+0x14>
		return lapic[ID] >> 24;
f01068e5:	8b 40 20             	mov    0x20(%eax),%eax
f01068e8:	c1 e8 18             	shr    $0x18,%eax
f01068eb:	eb 05                	jmp    f01068f2 <cpunum+0x19>
	return 0;
f01068ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01068f2:	5d                   	pop    %ebp
f01068f3:	c3                   	ret    

f01068f4 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01068f4:	a1 00 50 27 f0       	mov    0xf0275000,%eax
f01068f9:	85 c0                	test   %eax,%eax
f01068fb:	0f 84 23 01 00 00    	je     f0106a24 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0106901:	55                   	push   %ebp
f0106902:	89 e5                	mov    %esp,%ebp
f0106904:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0106907:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010690e:	00 
f010690f:	89 04 24             	mov    %eax,(%esp)
f0106912:	e8 a3 ae ff ff       	call   f01017ba <mmio_map_region>
f0106917:	a3 04 50 27 f0       	mov    %eax,0xf0275004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010691c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106921:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106926:	e8 96 ff ff ff       	call   f01068c1 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010692b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0106930:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106935:	e8 87 ff ff ff       	call   f01068c1 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010693a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010693f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0106944:	e8 78 ff ff ff       	call   f01068c1 <lapicw>
	lapicw(TICR, 10000000); 
f0106949:	ba 80 96 98 00       	mov    $0x989680,%edx
f010694e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0106953:	e8 69 ff ff ff       	call   f01068c1 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0106958:	e8 7c ff ff ff       	call   f01068d9 <cpunum>
f010695d:	6b c0 74             	imul   $0x74,%eax,%eax
f0106960:	05 20 40 23 f0       	add    $0xf0234020,%eax
f0106965:	39 05 c0 43 23 f0    	cmp    %eax,0xf02343c0
f010696b:	74 0f                	je     f010697c <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f010696d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106972:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0106977:	e8 45 ff ff ff       	call   f01068c1 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f010697c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106981:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0106986:	e8 36 ff ff ff       	call   f01068c1 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010698b:	a1 04 50 27 f0       	mov    0xf0275004,%eax
f0106990:	8b 40 30             	mov    0x30(%eax),%eax
f0106993:	c1 e8 10             	shr    $0x10,%eax
f0106996:	3c 03                	cmp    $0x3,%al
f0106998:	76 0f                	jbe    f01069a9 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f010699a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010699f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01069a4:	e8 18 ff ff ff       	call   f01068c1 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01069a9:	ba 33 00 00 00       	mov    $0x33,%edx
f01069ae:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01069b3:	e8 09 ff ff ff       	call   f01068c1 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01069b8:	ba 00 00 00 00       	mov    $0x0,%edx
f01069bd:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01069c2:	e8 fa fe ff ff       	call   f01068c1 <lapicw>
	lapicw(ESR, 0);
f01069c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01069cc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01069d1:	e8 eb fe ff ff       	call   f01068c1 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01069d6:	ba 00 00 00 00       	mov    $0x0,%edx
f01069db:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01069e0:	e8 dc fe ff ff       	call   f01068c1 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01069e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01069ea:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01069ef:	e8 cd fe ff ff       	call   f01068c1 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01069f4:	ba 00 85 08 00       	mov    $0x88500,%edx
f01069f9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01069fe:	e8 be fe ff ff       	call   f01068c1 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106a03:	8b 15 04 50 27 f0    	mov    0xf0275004,%edx
f0106a09:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106a0f:	f6 c4 10             	test   $0x10,%ah
f0106a12:	75 f5                	jne    f0106a09 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0106a14:	ba 00 00 00 00       	mov    $0x0,%edx
f0106a19:	b8 20 00 00 00       	mov    $0x20,%eax
f0106a1e:	e8 9e fe ff ff       	call   f01068c1 <lapicw>
}
f0106a23:	c9                   	leave  
f0106a24:	f3 c3                	repz ret 

f0106a26 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0106a26:	83 3d 04 50 27 f0 00 	cmpl   $0x0,0xf0275004
f0106a2d:	74 13                	je     f0106a42 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0106a2f:	55                   	push   %ebp
f0106a30:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0106a32:	ba 00 00 00 00       	mov    $0x0,%edx
f0106a37:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106a3c:	e8 80 fe ff ff       	call   f01068c1 <lapicw>
}
f0106a41:	5d                   	pop    %ebp
f0106a42:	f3 c3                	repz ret 

f0106a44 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0106a44:	55                   	push   %ebp
f0106a45:	89 e5                	mov    %esp,%ebp
f0106a47:	56                   	push   %esi
f0106a48:	53                   	push   %ebx
f0106a49:	83 ec 10             	sub    $0x10,%esp
f0106a4c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0106a4f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0106a52:	ba 70 00 00 00       	mov    $0x70,%edx
f0106a57:	b8 0f 00 00 00       	mov    $0xf,%eax
f0106a5c:	ee                   	out    %al,(%dx)
f0106a5d:	b2 71                	mov    $0x71,%dl
f0106a5f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0106a64:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106a65:	83 3d 88 3e 23 f0 00 	cmpl   $0x0,0xf0233e88
f0106a6c:	75 24                	jne    f0106a92 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106a6e:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0106a75:	00 
f0106a76:	c7 44 24 08 e4 6f 10 	movl   $0xf0106fe4,0x8(%esp)
f0106a7d:	f0 
f0106a7e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0106a85:	00 
f0106a86:	c7 04 24 bc 8c 10 f0 	movl   $0xf0108cbc,(%esp)
f0106a8d:	e8 ae 95 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106a92:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106a99:	00 00 
	wrv[1] = addr >> 4;
f0106a9b:	89 f0                	mov    %esi,%eax
f0106a9d:	c1 e8 04             	shr    $0x4,%eax
f0106aa0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106aa6:	c1 e3 18             	shl    $0x18,%ebx
f0106aa9:	89 da                	mov    %ebx,%edx
f0106aab:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106ab0:	e8 0c fe ff ff       	call   f01068c1 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106ab5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0106aba:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106abf:	e8 fd fd ff ff       	call   f01068c1 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106ac4:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106ac9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106ace:	e8 ee fd ff ff       	call   f01068c1 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106ad3:	c1 ee 0c             	shr    $0xc,%esi
f0106ad6:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0106adc:	89 da                	mov    %ebx,%edx
f0106ade:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106ae3:	e8 d9 fd ff ff       	call   f01068c1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106ae8:	89 f2                	mov    %esi,%edx
f0106aea:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106aef:	e8 cd fd ff ff       	call   f01068c1 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0106af4:	89 da                	mov    %ebx,%edx
f0106af6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106afb:	e8 c1 fd ff ff       	call   f01068c1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106b00:	89 f2                	mov    %esi,%edx
f0106b02:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106b07:	e8 b5 fd ff ff       	call   f01068c1 <lapicw>
		microdelay(200);
	}
}
f0106b0c:	83 c4 10             	add    $0x10,%esp
f0106b0f:	5b                   	pop    %ebx
f0106b10:	5e                   	pop    %esi
f0106b11:	5d                   	pop    %ebp
f0106b12:	c3                   	ret    

f0106b13 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106b13:	55                   	push   %ebp
f0106b14:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106b16:	8b 55 08             	mov    0x8(%ebp),%edx
f0106b19:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0106b1f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106b24:	e8 98 fd ff ff       	call   f01068c1 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106b29:	8b 15 04 50 27 f0    	mov    0xf0275004,%edx
f0106b2f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106b35:	f6 c4 10             	test   $0x10,%ah
f0106b38:	75 f5                	jne    f0106b2f <lapic_ipi+0x1c>
		;
}
f0106b3a:	5d                   	pop    %ebp
f0106b3b:	c3                   	ret    

f0106b3c <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0106b3c:	55                   	push   %ebp
f0106b3d:	89 e5                	mov    %esp,%ebp
f0106b3f:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0106b42:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0106b48:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106b4b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0106b4e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0106b55:	5d                   	pop    %ebp
f0106b56:	c3                   	ret    

f0106b57 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0106b57:	55                   	push   %ebp
f0106b58:	89 e5                	mov    %esp,%ebp
f0106b5a:	56                   	push   %esi
f0106b5b:	53                   	push   %ebx
f0106b5c:	83 ec 20             	sub    $0x20,%esp
f0106b5f:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106b62:	83 3b 00             	cmpl   $0x0,(%ebx)
f0106b65:	75 07                	jne    f0106b6e <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106b67:	ba 01 00 00 00       	mov    $0x1,%edx
f0106b6c:	eb 42                	jmp    f0106bb0 <spin_lock+0x59>
f0106b6e:	8b 73 08             	mov    0x8(%ebx),%esi
f0106b71:	e8 63 fd ff ff       	call   f01068d9 <cpunum>
f0106b76:	6b c0 74             	imul   $0x74,%eax,%eax
f0106b79:	05 20 40 23 f0       	add    $0xf0234020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0106b7e:	39 c6                	cmp    %eax,%esi
f0106b80:	75 e5                	jne    f0106b67 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106b82:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106b85:	e8 4f fd ff ff       	call   f01068d9 <cpunum>
f0106b8a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0106b8e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106b92:	c7 44 24 08 cc 8c 10 	movl   $0xf0108ccc,0x8(%esp)
f0106b99:	f0 
f0106b9a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f0106ba1:	00 
f0106ba2:	c7 04 24 30 8d 10 f0 	movl   $0xf0108d30,(%esp)
f0106ba9:	e8 92 94 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0106bae:	f3 90                	pause  
f0106bb0:	89 d0                	mov    %edx,%eax
f0106bb2:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0106bb5:	85 c0                	test   %eax,%eax
f0106bb7:	75 f5                	jne    f0106bae <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0106bb9:	e8 1b fd ff ff       	call   f01068d9 <cpunum>
f0106bbe:	6b c0 74             	imul   $0x74,%eax,%eax
f0106bc1:	05 20 40 23 f0       	add    $0xf0234020,%eax
f0106bc6:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0106bc9:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0106bcc:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0106bce:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106bd3:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0106bd9:	76 12                	jbe    f0106bed <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f0106bdb:	8b 4a 04             	mov    0x4(%edx),%ecx
f0106bde:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106be1:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106be3:	83 c0 01             	add    $0x1,%eax
f0106be6:	83 f8 0a             	cmp    $0xa,%eax
f0106be9:	75 e8                	jne    f0106bd3 <spin_lock+0x7c>
f0106beb:	eb 0f                	jmp    f0106bfc <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0106bed:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0106bf4:	83 c0 01             	add    $0x1,%eax
f0106bf7:	83 f8 09             	cmp    $0x9,%eax
f0106bfa:	7e f1                	jle    f0106bed <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0106bfc:	83 c4 20             	add    $0x20,%esp
f0106bff:	5b                   	pop    %ebx
f0106c00:	5e                   	pop    %esi
f0106c01:	5d                   	pop    %ebp
f0106c02:	c3                   	ret    

f0106c03 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106c03:	55                   	push   %ebp
f0106c04:	89 e5                	mov    %esp,%ebp
f0106c06:	57                   	push   %edi
f0106c07:	56                   	push   %esi
f0106c08:	53                   	push   %ebx
f0106c09:	83 ec 6c             	sub    $0x6c,%esp
f0106c0c:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106c0f:	83 3e 00             	cmpl   $0x0,(%esi)
f0106c12:	74 18                	je     f0106c2c <spin_unlock+0x29>
f0106c14:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106c17:	e8 bd fc ff ff       	call   f01068d9 <cpunum>
f0106c1c:	6b c0 74             	imul   $0x74,%eax,%eax
f0106c1f:	05 20 40 23 f0       	add    $0xf0234020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106c24:	39 c3                	cmp    %eax,%ebx
f0106c26:	0f 84 ce 00 00 00    	je     f0106cfa <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0106c2c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f0106c33:	00 
f0106c34:	8d 46 0c             	lea    0xc(%esi),%eax
f0106c37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106c3b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0106c3e:	89 1c 24             	mov    %ebx,(%esp)
f0106c41:	e8 8e f6 ff ff       	call   f01062d4 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106c46:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0106c49:	0f b6 38             	movzbl (%eax),%edi
f0106c4c:	8b 76 04             	mov    0x4(%esi),%esi
f0106c4f:	e8 85 fc ff ff       	call   f01068d9 <cpunum>
f0106c54:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106c58:	89 74 24 08          	mov    %esi,0x8(%esp)
f0106c5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106c60:	c7 04 24 f8 8c 10 f0 	movl   $0xf0108cf8,(%esp)
f0106c67:	e8 9e d6 ff ff       	call   f010430a <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0106c6c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0106c6f:	eb 65                	jmp    f0106cd6 <spin_unlock+0xd3>
f0106c71:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106c75:	89 04 24             	mov    %eax,(%esp)
f0106c78:	e8 ec ea ff ff       	call   f0105769 <debuginfo_eip>
f0106c7d:	85 c0                	test   %eax,%eax
f0106c7f:	78 39                	js     f0106cba <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106c81:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106c83:	89 c2                	mov    %eax,%edx
f0106c85:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106c88:	89 54 24 18          	mov    %edx,0x18(%esp)
f0106c8c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f0106c8f:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106c93:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106c96:	89 54 24 10          	mov    %edx,0x10(%esp)
f0106c9a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f0106c9d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0106ca1:	8b 55 a8             	mov    -0x58(%ebp),%edx
f0106ca4:	89 54 24 08          	mov    %edx,0x8(%esp)
f0106ca8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106cac:	c7 04 24 40 8d 10 f0 	movl   $0xf0108d40,(%esp)
f0106cb3:	e8 52 d6 ff ff       	call   f010430a <cprintf>
f0106cb8:	eb 12                	jmp    f0106ccc <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0106cba:	8b 06                	mov    (%esi),%eax
f0106cbc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106cc0:	c7 04 24 57 8d 10 f0 	movl   $0xf0108d57,(%esp)
f0106cc7:	e8 3e d6 ff ff       	call   f010430a <cprintf>
f0106ccc:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106ccf:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106cd2:	39 c3                	cmp    %eax,%ebx
f0106cd4:	74 08                	je     f0106cde <spin_unlock+0xdb>
f0106cd6:	89 de                	mov    %ebx,%esi
f0106cd8:	8b 03                	mov    (%ebx),%eax
f0106cda:	85 c0                	test   %eax,%eax
f0106cdc:	75 93                	jne    f0106c71 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0106cde:	c7 44 24 08 5f 8d 10 	movl   $0xf0108d5f,0x8(%esp)
f0106ce5:	f0 
f0106ce6:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f0106ced:	00 
f0106cee:	c7 04 24 30 8d 10 f0 	movl   $0xf0108d30,(%esp)
f0106cf5:	e8 46 93 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0106cfa:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106d01:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0106d08:	b8 00 00 00 00       	mov    $0x0,%eax
f0106d0d:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106d10:	83 c4 6c             	add    $0x6c,%esp
f0106d13:	5b                   	pop    %ebx
f0106d14:	5e                   	pop    %esi
f0106d15:	5f                   	pop    %edi
f0106d16:	5d                   	pop    %ebp
f0106d17:	c3                   	ret    
f0106d18:	66 90                	xchg   %ax,%ax
f0106d1a:	66 90                	xchg   %ax,%ax
f0106d1c:	66 90                	xchg   %ax,%ax
f0106d1e:	66 90                	xchg   %ax,%ax

f0106d20 <__udivdi3>:
f0106d20:	55                   	push   %ebp
f0106d21:	57                   	push   %edi
f0106d22:	56                   	push   %esi
f0106d23:	83 ec 0c             	sub    $0xc,%esp
f0106d26:	8b 44 24 28          	mov    0x28(%esp),%eax
f0106d2a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0106d2e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0106d32:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106d36:	85 c0                	test   %eax,%eax
f0106d38:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106d3c:	89 ea                	mov    %ebp,%edx
f0106d3e:	89 0c 24             	mov    %ecx,(%esp)
f0106d41:	75 2d                	jne    f0106d70 <__udivdi3+0x50>
f0106d43:	39 e9                	cmp    %ebp,%ecx
f0106d45:	77 61                	ja     f0106da8 <__udivdi3+0x88>
f0106d47:	85 c9                	test   %ecx,%ecx
f0106d49:	89 ce                	mov    %ecx,%esi
f0106d4b:	75 0b                	jne    f0106d58 <__udivdi3+0x38>
f0106d4d:	b8 01 00 00 00       	mov    $0x1,%eax
f0106d52:	31 d2                	xor    %edx,%edx
f0106d54:	f7 f1                	div    %ecx
f0106d56:	89 c6                	mov    %eax,%esi
f0106d58:	31 d2                	xor    %edx,%edx
f0106d5a:	89 e8                	mov    %ebp,%eax
f0106d5c:	f7 f6                	div    %esi
f0106d5e:	89 c5                	mov    %eax,%ebp
f0106d60:	89 f8                	mov    %edi,%eax
f0106d62:	f7 f6                	div    %esi
f0106d64:	89 ea                	mov    %ebp,%edx
f0106d66:	83 c4 0c             	add    $0xc,%esp
f0106d69:	5e                   	pop    %esi
f0106d6a:	5f                   	pop    %edi
f0106d6b:	5d                   	pop    %ebp
f0106d6c:	c3                   	ret    
f0106d6d:	8d 76 00             	lea    0x0(%esi),%esi
f0106d70:	39 e8                	cmp    %ebp,%eax
f0106d72:	77 24                	ja     f0106d98 <__udivdi3+0x78>
f0106d74:	0f bd e8             	bsr    %eax,%ebp
f0106d77:	83 f5 1f             	xor    $0x1f,%ebp
f0106d7a:	75 3c                	jne    f0106db8 <__udivdi3+0x98>
f0106d7c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106d80:	39 34 24             	cmp    %esi,(%esp)
f0106d83:	0f 86 9f 00 00 00    	jbe    f0106e28 <__udivdi3+0x108>
f0106d89:	39 d0                	cmp    %edx,%eax
f0106d8b:	0f 82 97 00 00 00    	jb     f0106e28 <__udivdi3+0x108>
f0106d91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106d98:	31 d2                	xor    %edx,%edx
f0106d9a:	31 c0                	xor    %eax,%eax
f0106d9c:	83 c4 0c             	add    $0xc,%esp
f0106d9f:	5e                   	pop    %esi
f0106da0:	5f                   	pop    %edi
f0106da1:	5d                   	pop    %ebp
f0106da2:	c3                   	ret    
f0106da3:	90                   	nop
f0106da4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106da8:	89 f8                	mov    %edi,%eax
f0106daa:	f7 f1                	div    %ecx
f0106dac:	31 d2                	xor    %edx,%edx
f0106dae:	83 c4 0c             	add    $0xc,%esp
f0106db1:	5e                   	pop    %esi
f0106db2:	5f                   	pop    %edi
f0106db3:	5d                   	pop    %ebp
f0106db4:	c3                   	ret    
f0106db5:	8d 76 00             	lea    0x0(%esi),%esi
f0106db8:	89 e9                	mov    %ebp,%ecx
f0106dba:	8b 3c 24             	mov    (%esp),%edi
f0106dbd:	d3 e0                	shl    %cl,%eax
f0106dbf:	89 c6                	mov    %eax,%esi
f0106dc1:	b8 20 00 00 00       	mov    $0x20,%eax
f0106dc6:	29 e8                	sub    %ebp,%eax
f0106dc8:	89 c1                	mov    %eax,%ecx
f0106dca:	d3 ef                	shr    %cl,%edi
f0106dcc:	89 e9                	mov    %ebp,%ecx
f0106dce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0106dd2:	8b 3c 24             	mov    (%esp),%edi
f0106dd5:	09 74 24 08          	or     %esi,0x8(%esp)
f0106dd9:	89 d6                	mov    %edx,%esi
f0106ddb:	d3 e7                	shl    %cl,%edi
f0106ddd:	89 c1                	mov    %eax,%ecx
f0106ddf:	89 3c 24             	mov    %edi,(%esp)
f0106de2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106de6:	d3 ee                	shr    %cl,%esi
f0106de8:	89 e9                	mov    %ebp,%ecx
f0106dea:	d3 e2                	shl    %cl,%edx
f0106dec:	89 c1                	mov    %eax,%ecx
f0106dee:	d3 ef                	shr    %cl,%edi
f0106df0:	09 d7                	or     %edx,%edi
f0106df2:	89 f2                	mov    %esi,%edx
f0106df4:	89 f8                	mov    %edi,%eax
f0106df6:	f7 74 24 08          	divl   0x8(%esp)
f0106dfa:	89 d6                	mov    %edx,%esi
f0106dfc:	89 c7                	mov    %eax,%edi
f0106dfe:	f7 24 24             	mull   (%esp)
f0106e01:	39 d6                	cmp    %edx,%esi
f0106e03:	89 14 24             	mov    %edx,(%esp)
f0106e06:	72 30                	jb     f0106e38 <__udivdi3+0x118>
f0106e08:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106e0c:	89 e9                	mov    %ebp,%ecx
f0106e0e:	d3 e2                	shl    %cl,%edx
f0106e10:	39 c2                	cmp    %eax,%edx
f0106e12:	73 05                	jae    f0106e19 <__udivdi3+0xf9>
f0106e14:	3b 34 24             	cmp    (%esp),%esi
f0106e17:	74 1f                	je     f0106e38 <__udivdi3+0x118>
f0106e19:	89 f8                	mov    %edi,%eax
f0106e1b:	31 d2                	xor    %edx,%edx
f0106e1d:	e9 7a ff ff ff       	jmp    f0106d9c <__udivdi3+0x7c>
f0106e22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106e28:	31 d2                	xor    %edx,%edx
f0106e2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0106e2f:	e9 68 ff ff ff       	jmp    f0106d9c <__udivdi3+0x7c>
f0106e34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106e38:	8d 47 ff             	lea    -0x1(%edi),%eax
f0106e3b:	31 d2                	xor    %edx,%edx
f0106e3d:	83 c4 0c             	add    $0xc,%esp
f0106e40:	5e                   	pop    %esi
f0106e41:	5f                   	pop    %edi
f0106e42:	5d                   	pop    %ebp
f0106e43:	c3                   	ret    
f0106e44:	66 90                	xchg   %ax,%ax
f0106e46:	66 90                	xchg   %ax,%ax
f0106e48:	66 90                	xchg   %ax,%ax
f0106e4a:	66 90                	xchg   %ax,%ax
f0106e4c:	66 90                	xchg   %ax,%ax
f0106e4e:	66 90                	xchg   %ax,%ax

f0106e50 <__umoddi3>:
f0106e50:	55                   	push   %ebp
f0106e51:	57                   	push   %edi
f0106e52:	56                   	push   %esi
f0106e53:	83 ec 14             	sub    $0x14,%esp
f0106e56:	8b 44 24 28          	mov    0x28(%esp),%eax
f0106e5a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106e5e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0106e62:	89 c7                	mov    %eax,%edi
f0106e64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106e68:	8b 44 24 30          	mov    0x30(%esp),%eax
f0106e6c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106e70:	89 34 24             	mov    %esi,(%esp)
f0106e73:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106e77:	85 c0                	test   %eax,%eax
f0106e79:	89 c2                	mov    %eax,%edx
f0106e7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106e7f:	75 17                	jne    f0106e98 <__umoddi3+0x48>
f0106e81:	39 fe                	cmp    %edi,%esi
f0106e83:	76 4b                	jbe    f0106ed0 <__umoddi3+0x80>
f0106e85:	89 c8                	mov    %ecx,%eax
f0106e87:	89 fa                	mov    %edi,%edx
f0106e89:	f7 f6                	div    %esi
f0106e8b:	89 d0                	mov    %edx,%eax
f0106e8d:	31 d2                	xor    %edx,%edx
f0106e8f:	83 c4 14             	add    $0x14,%esp
f0106e92:	5e                   	pop    %esi
f0106e93:	5f                   	pop    %edi
f0106e94:	5d                   	pop    %ebp
f0106e95:	c3                   	ret    
f0106e96:	66 90                	xchg   %ax,%ax
f0106e98:	39 f8                	cmp    %edi,%eax
f0106e9a:	77 54                	ja     f0106ef0 <__umoddi3+0xa0>
f0106e9c:	0f bd e8             	bsr    %eax,%ebp
f0106e9f:	83 f5 1f             	xor    $0x1f,%ebp
f0106ea2:	75 5c                	jne    f0106f00 <__umoddi3+0xb0>
f0106ea4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0106ea8:	39 3c 24             	cmp    %edi,(%esp)
f0106eab:	0f 87 e7 00 00 00    	ja     f0106f98 <__umoddi3+0x148>
f0106eb1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106eb5:	29 f1                	sub    %esi,%ecx
f0106eb7:	19 c7                	sbb    %eax,%edi
f0106eb9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106ebd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106ec1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0106ec5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0106ec9:	83 c4 14             	add    $0x14,%esp
f0106ecc:	5e                   	pop    %esi
f0106ecd:	5f                   	pop    %edi
f0106ece:	5d                   	pop    %ebp
f0106ecf:	c3                   	ret    
f0106ed0:	85 f6                	test   %esi,%esi
f0106ed2:	89 f5                	mov    %esi,%ebp
f0106ed4:	75 0b                	jne    f0106ee1 <__umoddi3+0x91>
f0106ed6:	b8 01 00 00 00       	mov    $0x1,%eax
f0106edb:	31 d2                	xor    %edx,%edx
f0106edd:	f7 f6                	div    %esi
f0106edf:	89 c5                	mov    %eax,%ebp
f0106ee1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106ee5:	31 d2                	xor    %edx,%edx
f0106ee7:	f7 f5                	div    %ebp
f0106ee9:	89 c8                	mov    %ecx,%eax
f0106eeb:	f7 f5                	div    %ebp
f0106eed:	eb 9c                	jmp    f0106e8b <__umoddi3+0x3b>
f0106eef:	90                   	nop
f0106ef0:	89 c8                	mov    %ecx,%eax
f0106ef2:	89 fa                	mov    %edi,%edx
f0106ef4:	83 c4 14             	add    $0x14,%esp
f0106ef7:	5e                   	pop    %esi
f0106ef8:	5f                   	pop    %edi
f0106ef9:	5d                   	pop    %ebp
f0106efa:	c3                   	ret    
f0106efb:	90                   	nop
f0106efc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106f00:	8b 04 24             	mov    (%esp),%eax
f0106f03:	be 20 00 00 00       	mov    $0x20,%esi
f0106f08:	89 e9                	mov    %ebp,%ecx
f0106f0a:	29 ee                	sub    %ebp,%esi
f0106f0c:	d3 e2                	shl    %cl,%edx
f0106f0e:	89 f1                	mov    %esi,%ecx
f0106f10:	d3 e8                	shr    %cl,%eax
f0106f12:	89 e9                	mov    %ebp,%ecx
f0106f14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106f18:	8b 04 24             	mov    (%esp),%eax
f0106f1b:	09 54 24 04          	or     %edx,0x4(%esp)
f0106f1f:	89 fa                	mov    %edi,%edx
f0106f21:	d3 e0                	shl    %cl,%eax
f0106f23:	89 f1                	mov    %esi,%ecx
f0106f25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106f29:	8b 44 24 10          	mov    0x10(%esp),%eax
f0106f2d:	d3 ea                	shr    %cl,%edx
f0106f2f:	89 e9                	mov    %ebp,%ecx
f0106f31:	d3 e7                	shl    %cl,%edi
f0106f33:	89 f1                	mov    %esi,%ecx
f0106f35:	d3 e8                	shr    %cl,%eax
f0106f37:	89 e9                	mov    %ebp,%ecx
f0106f39:	09 f8                	or     %edi,%eax
f0106f3b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0106f3f:	f7 74 24 04          	divl   0x4(%esp)
f0106f43:	d3 e7                	shl    %cl,%edi
f0106f45:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106f49:	89 d7                	mov    %edx,%edi
f0106f4b:	f7 64 24 08          	mull   0x8(%esp)
f0106f4f:	39 d7                	cmp    %edx,%edi
f0106f51:	89 c1                	mov    %eax,%ecx
f0106f53:	89 14 24             	mov    %edx,(%esp)
f0106f56:	72 2c                	jb     f0106f84 <__umoddi3+0x134>
f0106f58:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0106f5c:	72 22                	jb     f0106f80 <__umoddi3+0x130>
f0106f5e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106f62:	29 c8                	sub    %ecx,%eax
f0106f64:	19 d7                	sbb    %edx,%edi
f0106f66:	89 e9                	mov    %ebp,%ecx
f0106f68:	89 fa                	mov    %edi,%edx
f0106f6a:	d3 e8                	shr    %cl,%eax
f0106f6c:	89 f1                	mov    %esi,%ecx
f0106f6e:	d3 e2                	shl    %cl,%edx
f0106f70:	89 e9                	mov    %ebp,%ecx
f0106f72:	d3 ef                	shr    %cl,%edi
f0106f74:	09 d0                	or     %edx,%eax
f0106f76:	89 fa                	mov    %edi,%edx
f0106f78:	83 c4 14             	add    $0x14,%esp
f0106f7b:	5e                   	pop    %esi
f0106f7c:	5f                   	pop    %edi
f0106f7d:	5d                   	pop    %ebp
f0106f7e:	c3                   	ret    
f0106f7f:	90                   	nop
f0106f80:	39 d7                	cmp    %edx,%edi
f0106f82:	75 da                	jne    f0106f5e <__umoddi3+0x10e>
f0106f84:	8b 14 24             	mov    (%esp),%edx
f0106f87:	89 c1                	mov    %eax,%ecx
f0106f89:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0106f8d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0106f91:	eb cb                	jmp    f0106f5e <__umoddi3+0x10e>
f0106f93:	90                   	nop
f0106f94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106f98:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0106f9c:	0f 82 0f ff ff ff    	jb     f0106eb1 <__umoddi3+0x61>
f0106fa2:	e9 1a ff ff ff       	jmp    f0106ec1 <__umoddi3+0x71>
