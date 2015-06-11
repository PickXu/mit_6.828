
obj/user/stresssched:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 ea 00 00 00       	call   80011b <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <umain>:

volatile int counter;

void
umain(int argc, char **argv)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	56                   	push   %esi
  800044:	53                   	push   %ebx
  800045:	83 ec 10             	sub    $0x10,%esp
	int i, j;
	int seen;
	envid_t parent = sys_getenvid();
  800048:	e8 28 0c 00 00       	call   800c75 <sys_getenvid>
  80004d:	89 c6                	mov    %eax,%esi

	cprintf("Stress!\n");
  80004f:	c7 04 24 e0 16 80 00 	movl   $0x8016e0,(%esp)
  800056:	e8 15 02 00 00       	call   800270 <cprintf>
	// Fork several environments
	for (i = 0; i < 20; i++)
  80005b:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (fork() == 0)
  800060:	e8 cd 10 00 00       	call   801132 <fork>
  800065:	85 c0                	test   %eax,%eax
  800067:	74 0a                	je     800073 <umain+0x33>
	int seen;
	envid_t parent = sys_getenvid();

	cprintf("Stress!\n");
	// Fork several environments
	for (i = 0; i < 20; i++)
  800069:	83 c3 01             	add    $0x1,%ebx
  80006c:	83 fb 14             	cmp    $0x14,%ebx
  80006f:	75 ef                	jne    800060 <umain+0x20>
  800071:	eb 16                	jmp    800089 <umain+0x49>
		if (fork() == 0)
			break;
	if (i == 20) {
  800073:	83 fb 14             	cmp    $0x14,%ebx
  800076:	74 11                	je     800089 <umain+0x49>
		sys_yield();
		return;
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
  800078:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
  80007e:	6b d6 7c             	imul   $0x7c,%esi,%edx
  800081:	81 c2 04 00 c0 ee    	add    $0xeec00004,%edx
  800087:	eb 0c                	jmp    800095 <umain+0x55>
	// Fork several environments
	for (i = 0; i < 20; i++)
		if (fork() == 0)
			break;
	if (i == 20) {
		sys_yield();
  800089:	e8 06 0c 00 00       	call   800c94 <sys_yield>
		return;
  80008e:	e9 81 00 00 00       	jmp    800114 <umain+0xd4>
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
		asm volatile("pause");
  800093:	f3 90                	pause  
		sys_yield();
		return;
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
  800095:	8b 42 50             	mov    0x50(%edx),%eax
  800098:	85 c0                	test   %eax,%eax
  80009a:	75 f7                	jne    800093 <umain+0x53>
  80009c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
		sys_yield();
  8000a1:	e8 ee 0b 00 00       	call   800c94 <sys_yield>
  8000a6:	b8 10 27 00 00       	mov    $0x2710,%eax
		for (j = 0; j < 10000; j++)
			counter++;
  8000ab:	8b 15 04 20 80 00    	mov    0x802004,%edx
  8000b1:	83 c2 01             	add    $0x1,%edx
  8000b4:	89 15 04 20 80 00    	mov    %edx,0x802004
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
		sys_yield();
		for (j = 0; j < 10000; j++)
  8000ba:	83 e8 01             	sub    $0x1,%eax
  8000bd:	75 ec                	jne    8000ab <umain+0x6b>
	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
  8000bf:	83 eb 01             	sub    $0x1,%ebx
  8000c2:	75 dd                	jne    8000a1 <umain+0x61>
		sys_yield();
		for (j = 0; j < 10000; j++)
			counter++;
	}

	if (counter != 10*10000)
  8000c4:	a1 04 20 80 00       	mov    0x802004,%eax
  8000c9:	3d a0 86 01 00       	cmp    $0x186a0,%eax
  8000ce:	74 25                	je     8000f5 <umain+0xb5>
		panic("ran on two CPUs at once (counter is %d)", counter);
  8000d0:	a1 04 20 80 00       	mov    0x802004,%eax
  8000d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000d9:	c7 44 24 08 1c 17 80 	movl   $0x80171c,0x8(%esp)
  8000e0:	00 
  8000e1:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
  8000e8:	00 
  8000e9:	c7 04 24 e9 16 80 00 	movl   $0x8016e9,(%esp)
  8000f0:	e8 82 00 00 00       	call   800177 <_panic>

	// Check that we see environments running on different CPUs
	cprintf("[%08x] stresssched on CPU %d\n", thisenv->env_id, thisenv->env_cpunum);
  8000f5:	a1 08 20 80 00       	mov    0x802008,%eax
  8000fa:	8b 50 5c             	mov    0x5c(%eax),%edx
  8000fd:	8b 40 48             	mov    0x48(%eax),%eax
  800100:	89 54 24 08          	mov    %edx,0x8(%esp)
  800104:	89 44 24 04          	mov    %eax,0x4(%esp)
  800108:	c7 04 24 fc 16 80 00 	movl   $0x8016fc,(%esp)
  80010f:	e8 5c 01 00 00       	call   800270 <cprintf>

}
  800114:	83 c4 10             	add    $0x10,%esp
  800117:	5b                   	pop    %ebx
  800118:	5e                   	pop    %esi
  800119:	5d                   	pop    %ebp
  80011a:	c3                   	ret    

0080011b <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80011b:	55                   	push   %ebp
  80011c:	89 e5                	mov    %esp,%ebp
  80011e:	56                   	push   %esi
  80011f:	53                   	push   %ebx
  800120:	83 ec 10             	sub    $0x10,%esp
  800123:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800126:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  800129:	e8 47 0b 00 00       	call   800c75 <sys_getenvid>
	thisenv = envs+ENVX(envid);
  80012e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800133:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800136:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80013b:	a3 08 20 80 00       	mov    %eax,0x802008
	
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800140:	85 db                	test   %ebx,%ebx
  800142:	7e 07                	jle    80014b <libmain+0x30>
		binaryname = argv[0];
  800144:	8b 06                	mov    (%esi),%eax
  800146:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80014b:	89 74 24 04          	mov    %esi,0x4(%esp)
  80014f:	89 1c 24             	mov    %ebx,(%esp)
  800152:	e8 e9 fe ff ff       	call   800040 <umain>

	// exit gracefully
	exit();
  800157:	e8 07 00 00 00       	call   800163 <exit>
}
  80015c:	83 c4 10             	add    $0x10,%esp
  80015f:	5b                   	pop    %ebx
  800160:	5e                   	pop    %esi
  800161:	5d                   	pop    %ebp
  800162:	c3                   	ret    

00800163 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800163:	55                   	push   %ebp
  800164:	89 e5                	mov    %esp,%ebp
  800166:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800169:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800170:	e8 ae 0a 00 00       	call   800c23 <sys_env_destroy>
}
  800175:	c9                   	leave  
  800176:	c3                   	ret    

00800177 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800177:	55                   	push   %ebp
  800178:	89 e5                	mov    %esp,%ebp
  80017a:	56                   	push   %esi
  80017b:	53                   	push   %ebx
  80017c:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  80017f:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800182:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800188:	e8 e8 0a 00 00       	call   800c75 <sys_getenvid>
  80018d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800190:	89 54 24 10          	mov    %edx,0x10(%esp)
  800194:	8b 55 08             	mov    0x8(%ebp),%edx
  800197:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80019b:	89 74 24 08          	mov    %esi,0x8(%esp)
  80019f:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001a3:	c7 04 24 50 17 80 00 	movl   $0x801750,(%esp)
  8001aa:	e8 c1 00 00 00       	call   800270 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001af:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001b3:	8b 45 10             	mov    0x10(%ebp),%eax
  8001b6:	89 04 24             	mov    %eax,(%esp)
  8001b9:	e8 51 00 00 00       	call   80020f <vcprintf>
	cprintf("\n");
  8001be:	c7 04 24 e7 16 80 00 	movl   $0x8016e7,(%esp)
  8001c5:	e8 a6 00 00 00       	call   800270 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001ca:	cc                   	int3   
  8001cb:	eb fd                	jmp    8001ca <_panic+0x53>

008001cd <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001cd:	55                   	push   %ebp
  8001ce:	89 e5                	mov    %esp,%ebp
  8001d0:	53                   	push   %ebx
  8001d1:	83 ec 14             	sub    $0x14,%esp
  8001d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001d7:	8b 13                	mov    (%ebx),%edx
  8001d9:	8d 42 01             	lea    0x1(%edx),%eax
  8001dc:	89 03                	mov    %eax,(%ebx)
  8001de:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001e1:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001e5:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001ea:	75 19                	jne    800205 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001ec:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001f3:	00 
  8001f4:	8d 43 08             	lea    0x8(%ebx),%eax
  8001f7:	89 04 24             	mov    %eax,(%esp)
  8001fa:	e8 e7 09 00 00       	call   800be6 <sys_cputs>
		b->idx = 0;
  8001ff:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800205:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800209:	83 c4 14             	add    $0x14,%esp
  80020c:	5b                   	pop    %ebx
  80020d:	5d                   	pop    %ebp
  80020e:	c3                   	ret    

0080020f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80020f:	55                   	push   %ebp
  800210:	89 e5                	mov    %esp,%ebp
  800212:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800218:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80021f:	00 00 00 
	b.cnt = 0;
  800222:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800229:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80022c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80022f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800233:	8b 45 08             	mov    0x8(%ebp),%eax
  800236:	89 44 24 08          	mov    %eax,0x8(%esp)
  80023a:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800240:	89 44 24 04          	mov    %eax,0x4(%esp)
  800244:	c7 04 24 cd 01 80 00 	movl   $0x8001cd,(%esp)
  80024b:	e8 ae 01 00 00       	call   8003fe <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800250:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800256:	89 44 24 04          	mov    %eax,0x4(%esp)
  80025a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800260:	89 04 24             	mov    %eax,(%esp)
  800263:	e8 7e 09 00 00       	call   800be6 <sys_cputs>

	return b.cnt;
}
  800268:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80026e:	c9                   	leave  
  80026f:	c3                   	ret    

00800270 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800270:	55                   	push   %ebp
  800271:	89 e5                	mov    %esp,%ebp
  800273:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800276:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800279:	89 44 24 04          	mov    %eax,0x4(%esp)
  80027d:	8b 45 08             	mov    0x8(%ebp),%eax
  800280:	89 04 24             	mov    %eax,(%esp)
  800283:	e8 87 ff ff ff       	call   80020f <vcprintf>
	va_end(ap);

	return cnt;
}
  800288:	c9                   	leave  
  800289:	c3                   	ret    
  80028a:	66 90                	xchg   %ax,%ax
  80028c:	66 90                	xchg   %ax,%ax
  80028e:	66 90                	xchg   %ax,%ax

00800290 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800290:	55                   	push   %ebp
  800291:	89 e5                	mov    %esp,%ebp
  800293:	57                   	push   %edi
  800294:	56                   	push   %esi
  800295:	53                   	push   %ebx
  800296:	83 ec 3c             	sub    $0x3c,%esp
  800299:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80029c:	89 d7                	mov    %edx,%edi
  80029e:	8b 45 08             	mov    0x8(%ebp),%eax
  8002a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002a7:	89 c3                	mov    %eax,%ebx
  8002a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002ac:	8b 45 10             	mov    0x10(%ebp),%eax
  8002af:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002b2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002ba:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8002bd:	39 d9                	cmp    %ebx,%ecx
  8002bf:	72 05                	jb     8002c6 <printnum+0x36>
  8002c1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8002c4:	77 69                	ja     80032f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002c6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8002c9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8002cd:	83 ee 01             	sub    $0x1,%esi
  8002d0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002d4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002d8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002dc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002e0:	89 c3                	mov    %eax,%ebx
  8002e2:	89 d6                	mov    %edx,%esi
  8002e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002e7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002ea:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002ee:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002f5:	89 04 24             	mov    %eax,(%esp)
  8002f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002ff:	e8 4c 11 00 00       	call   801450 <__udivdi3>
  800304:	89 d9                	mov    %ebx,%ecx
  800306:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80030a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80030e:	89 04 24             	mov    %eax,(%esp)
  800311:	89 54 24 04          	mov    %edx,0x4(%esp)
  800315:	89 fa                	mov    %edi,%edx
  800317:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80031a:	e8 71 ff ff ff       	call   800290 <printnum>
  80031f:	eb 1b                	jmp    80033c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800321:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800325:	8b 45 18             	mov    0x18(%ebp),%eax
  800328:	89 04 24             	mov    %eax,(%esp)
  80032b:	ff d3                	call   *%ebx
  80032d:	eb 03                	jmp    800332 <printnum+0xa2>
  80032f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800332:	83 ee 01             	sub    $0x1,%esi
  800335:	85 f6                	test   %esi,%esi
  800337:	7f e8                	jg     800321 <printnum+0x91>
  800339:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80033c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800340:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800344:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800347:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80034a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80034e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800352:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800355:	89 04 24             	mov    %eax,(%esp)
  800358:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80035b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80035f:	e8 1c 12 00 00       	call   801580 <__umoddi3>
  800364:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800368:	0f be 80 73 17 80 00 	movsbl 0x801773(%eax),%eax
  80036f:	89 04 24             	mov    %eax,(%esp)
  800372:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800375:	ff d0                	call   *%eax
}
  800377:	83 c4 3c             	add    $0x3c,%esp
  80037a:	5b                   	pop    %ebx
  80037b:	5e                   	pop    %esi
  80037c:	5f                   	pop    %edi
  80037d:	5d                   	pop    %ebp
  80037e:	c3                   	ret    

0080037f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80037f:	55                   	push   %ebp
  800380:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800382:	83 fa 01             	cmp    $0x1,%edx
  800385:	7e 0e                	jle    800395 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800387:	8b 10                	mov    (%eax),%edx
  800389:	8d 4a 08             	lea    0x8(%edx),%ecx
  80038c:	89 08                	mov    %ecx,(%eax)
  80038e:	8b 02                	mov    (%edx),%eax
  800390:	8b 52 04             	mov    0x4(%edx),%edx
  800393:	eb 22                	jmp    8003b7 <getuint+0x38>
	else if (lflag)
  800395:	85 d2                	test   %edx,%edx
  800397:	74 10                	je     8003a9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800399:	8b 10                	mov    (%eax),%edx
  80039b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80039e:	89 08                	mov    %ecx,(%eax)
  8003a0:	8b 02                	mov    (%edx),%eax
  8003a2:	ba 00 00 00 00       	mov    $0x0,%edx
  8003a7:	eb 0e                	jmp    8003b7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003a9:	8b 10                	mov    (%eax),%edx
  8003ab:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003ae:	89 08                	mov    %ecx,(%eax)
  8003b0:	8b 02                	mov    (%edx),%eax
  8003b2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003b7:	5d                   	pop    %ebp
  8003b8:	c3                   	ret    

008003b9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003b9:	55                   	push   %ebp
  8003ba:	89 e5                	mov    %esp,%ebp
  8003bc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003bf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003c3:	8b 10                	mov    (%eax),%edx
  8003c5:	3b 50 04             	cmp    0x4(%eax),%edx
  8003c8:	73 0a                	jae    8003d4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003ca:	8d 4a 01             	lea    0x1(%edx),%ecx
  8003cd:	89 08                	mov    %ecx,(%eax)
  8003cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8003d2:	88 02                	mov    %al,(%edx)
}
  8003d4:	5d                   	pop    %ebp
  8003d5:	c3                   	ret    

008003d6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003d6:	55                   	push   %ebp
  8003d7:	89 e5                	mov    %esp,%ebp
  8003d9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003dc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003df:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003e3:	8b 45 10             	mov    0x10(%ebp),%eax
  8003e6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003f1:	8b 45 08             	mov    0x8(%ebp),%eax
  8003f4:	89 04 24             	mov    %eax,(%esp)
  8003f7:	e8 02 00 00 00       	call   8003fe <vprintfmt>
	va_end(ap);
}
  8003fc:	c9                   	leave  
  8003fd:	c3                   	ret    

008003fe <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003fe:	55                   	push   %ebp
  8003ff:	89 e5                	mov    %esp,%ebp
  800401:	57                   	push   %edi
  800402:	56                   	push   %esi
  800403:	53                   	push   %ebx
  800404:	83 ec 3c             	sub    $0x3c,%esp
  800407:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80040a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80040d:	eb 14                	jmp    800423 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80040f:	85 c0                	test   %eax,%eax
  800411:	0f 84 b3 03 00 00    	je     8007ca <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800417:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80041b:	89 04 24             	mov    %eax,(%esp)
  80041e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800421:	89 f3                	mov    %esi,%ebx
  800423:	8d 73 01             	lea    0x1(%ebx),%esi
  800426:	0f b6 03             	movzbl (%ebx),%eax
  800429:	83 f8 25             	cmp    $0x25,%eax
  80042c:	75 e1                	jne    80040f <vprintfmt+0x11>
  80042e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800432:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800439:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800440:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800447:	ba 00 00 00 00       	mov    $0x0,%edx
  80044c:	eb 1d                	jmp    80046b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800450:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800454:	eb 15                	jmp    80046b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800456:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800458:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80045c:	eb 0d                	jmp    80046b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80045e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800461:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800464:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80046e:	0f b6 0e             	movzbl (%esi),%ecx
  800471:	0f b6 c1             	movzbl %cl,%eax
  800474:	83 e9 23             	sub    $0x23,%ecx
  800477:	80 f9 55             	cmp    $0x55,%cl
  80047a:	0f 87 2a 03 00 00    	ja     8007aa <vprintfmt+0x3ac>
  800480:	0f b6 c9             	movzbl %cl,%ecx
  800483:	ff 24 8d 40 18 80 00 	jmp    *0x801840(,%ecx,4)
  80048a:	89 de                	mov    %ebx,%esi
  80048c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800491:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800494:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800498:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80049b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80049e:	83 fb 09             	cmp    $0x9,%ebx
  8004a1:	77 36                	ja     8004d9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004a3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8004a6:	eb e9                	jmp    800491 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004a8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ab:	8d 48 04             	lea    0x4(%eax),%ecx
  8004ae:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004b1:	8b 00                	mov    (%eax),%eax
  8004b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004b8:	eb 22                	jmp    8004dc <vprintfmt+0xde>
  8004ba:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8004bd:	85 c9                	test   %ecx,%ecx
  8004bf:	b8 00 00 00 00       	mov    $0x0,%eax
  8004c4:	0f 49 c1             	cmovns %ecx,%eax
  8004c7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ca:	89 de                	mov    %ebx,%esi
  8004cc:	eb 9d                	jmp    80046b <vprintfmt+0x6d>
  8004ce:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004d0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8004d7:	eb 92                	jmp    80046b <vprintfmt+0x6d>
  8004d9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8004dc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004e0:	79 89                	jns    80046b <vprintfmt+0x6d>
  8004e2:	e9 77 ff ff ff       	jmp    80045e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004e7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ea:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004ec:	e9 7a ff ff ff       	jmp    80046b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f4:	8d 50 04             	lea    0x4(%eax),%edx
  8004f7:	89 55 14             	mov    %edx,0x14(%ebp)
  8004fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004fe:	8b 00                	mov    (%eax),%eax
  800500:	89 04 24             	mov    %eax,(%esp)
  800503:	ff 55 08             	call   *0x8(%ebp)
			break;
  800506:	e9 18 ff ff ff       	jmp    800423 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80050b:	8b 45 14             	mov    0x14(%ebp),%eax
  80050e:	8d 50 04             	lea    0x4(%eax),%edx
  800511:	89 55 14             	mov    %edx,0x14(%ebp)
  800514:	8b 00                	mov    (%eax),%eax
  800516:	99                   	cltd   
  800517:	31 d0                	xor    %edx,%eax
  800519:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80051b:	83 f8 09             	cmp    $0x9,%eax
  80051e:	7f 0b                	jg     80052b <vprintfmt+0x12d>
  800520:	8b 14 85 a0 19 80 00 	mov    0x8019a0(,%eax,4),%edx
  800527:	85 d2                	test   %edx,%edx
  800529:	75 20                	jne    80054b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80052b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80052f:	c7 44 24 08 8b 17 80 	movl   $0x80178b,0x8(%esp)
  800536:	00 
  800537:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80053b:	8b 45 08             	mov    0x8(%ebp),%eax
  80053e:	89 04 24             	mov    %eax,(%esp)
  800541:	e8 90 fe ff ff       	call   8003d6 <printfmt>
  800546:	e9 d8 fe ff ff       	jmp    800423 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80054b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80054f:	c7 44 24 08 94 17 80 	movl   $0x801794,0x8(%esp)
  800556:	00 
  800557:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80055b:	8b 45 08             	mov    0x8(%ebp),%eax
  80055e:	89 04 24             	mov    %eax,(%esp)
  800561:	e8 70 fe ff ff       	call   8003d6 <printfmt>
  800566:	e9 b8 fe ff ff       	jmp    800423 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80056e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800571:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800574:	8b 45 14             	mov    0x14(%ebp),%eax
  800577:	8d 50 04             	lea    0x4(%eax),%edx
  80057a:	89 55 14             	mov    %edx,0x14(%ebp)
  80057d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80057f:	85 f6                	test   %esi,%esi
  800581:	b8 84 17 80 00       	mov    $0x801784,%eax
  800586:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800589:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80058d:	0f 84 97 00 00 00    	je     80062a <vprintfmt+0x22c>
  800593:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800597:	0f 8e 9b 00 00 00    	jle    800638 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80059d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005a1:	89 34 24             	mov    %esi,(%esp)
  8005a4:	e8 cf 02 00 00       	call   800878 <strnlen>
  8005a9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8005ac:	29 c2                	sub    %eax,%edx
  8005ae:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8005b1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8005b5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8005b8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8005bb:	8b 75 08             	mov    0x8(%ebp),%esi
  8005be:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005c1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005c3:	eb 0f                	jmp    8005d4 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8005c5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005c9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8005cc:	89 04 24             	mov    %eax,(%esp)
  8005cf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005d1:	83 eb 01             	sub    $0x1,%ebx
  8005d4:	85 db                	test   %ebx,%ebx
  8005d6:	7f ed                	jg     8005c5 <vprintfmt+0x1c7>
  8005d8:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8005db:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8005de:	85 d2                	test   %edx,%edx
  8005e0:	b8 00 00 00 00       	mov    $0x0,%eax
  8005e5:	0f 49 c2             	cmovns %edx,%eax
  8005e8:	29 c2                	sub    %eax,%edx
  8005ea:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005ed:	89 d7                	mov    %edx,%edi
  8005ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005f2:	eb 50                	jmp    800644 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005f4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005f8:	74 1e                	je     800618 <vprintfmt+0x21a>
  8005fa:	0f be d2             	movsbl %dl,%edx
  8005fd:	83 ea 20             	sub    $0x20,%edx
  800600:	83 fa 5e             	cmp    $0x5e,%edx
  800603:	76 13                	jbe    800618 <vprintfmt+0x21a>
					putch('?', putdat);
  800605:	8b 45 0c             	mov    0xc(%ebp),%eax
  800608:	89 44 24 04          	mov    %eax,0x4(%esp)
  80060c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800613:	ff 55 08             	call   *0x8(%ebp)
  800616:	eb 0d                	jmp    800625 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800618:	8b 55 0c             	mov    0xc(%ebp),%edx
  80061b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80061f:	89 04 24             	mov    %eax,(%esp)
  800622:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800625:	83 ef 01             	sub    $0x1,%edi
  800628:	eb 1a                	jmp    800644 <vprintfmt+0x246>
  80062a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80062d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800630:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800633:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800636:	eb 0c                	jmp    800644 <vprintfmt+0x246>
  800638:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80063b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80063e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800641:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800644:	83 c6 01             	add    $0x1,%esi
  800647:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80064b:	0f be c2             	movsbl %dl,%eax
  80064e:	85 c0                	test   %eax,%eax
  800650:	74 27                	je     800679 <vprintfmt+0x27b>
  800652:	85 db                	test   %ebx,%ebx
  800654:	78 9e                	js     8005f4 <vprintfmt+0x1f6>
  800656:	83 eb 01             	sub    $0x1,%ebx
  800659:	79 99                	jns    8005f4 <vprintfmt+0x1f6>
  80065b:	89 f8                	mov    %edi,%eax
  80065d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800660:	8b 75 08             	mov    0x8(%ebp),%esi
  800663:	89 c3                	mov    %eax,%ebx
  800665:	eb 1a                	jmp    800681 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800667:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80066b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800672:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800674:	83 eb 01             	sub    $0x1,%ebx
  800677:	eb 08                	jmp    800681 <vprintfmt+0x283>
  800679:	89 fb                	mov    %edi,%ebx
  80067b:	8b 75 08             	mov    0x8(%ebp),%esi
  80067e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800681:	85 db                	test   %ebx,%ebx
  800683:	7f e2                	jg     800667 <vprintfmt+0x269>
  800685:	89 75 08             	mov    %esi,0x8(%ebp)
  800688:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80068b:	e9 93 fd ff ff       	jmp    800423 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800690:	83 fa 01             	cmp    $0x1,%edx
  800693:	7e 16                	jle    8006ab <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800695:	8b 45 14             	mov    0x14(%ebp),%eax
  800698:	8d 50 08             	lea    0x8(%eax),%edx
  80069b:	89 55 14             	mov    %edx,0x14(%ebp)
  80069e:	8b 50 04             	mov    0x4(%eax),%edx
  8006a1:	8b 00                	mov    (%eax),%eax
  8006a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8006a6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8006a9:	eb 32                	jmp    8006dd <vprintfmt+0x2df>
	else if (lflag)
  8006ab:	85 d2                	test   %edx,%edx
  8006ad:	74 18                	je     8006c7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8006af:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b2:	8d 50 04             	lea    0x4(%eax),%edx
  8006b5:	89 55 14             	mov    %edx,0x14(%ebp)
  8006b8:	8b 30                	mov    (%eax),%esi
  8006ba:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8006bd:	89 f0                	mov    %esi,%eax
  8006bf:	c1 f8 1f             	sar    $0x1f,%eax
  8006c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8006c5:	eb 16                	jmp    8006dd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8006c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ca:	8d 50 04             	lea    0x4(%eax),%edx
  8006cd:	89 55 14             	mov    %edx,0x14(%ebp)
  8006d0:	8b 30                	mov    (%eax),%esi
  8006d2:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8006d5:	89 f0                	mov    %esi,%eax
  8006d7:	c1 f8 1f             	sar    $0x1f,%eax
  8006da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006e0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006e3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006e8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8006ec:	0f 89 80 00 00 00    	jns    800772 <vprintfmt+0x374>
				putch('-', putdat);
  8006f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006f6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006fd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800700:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800703:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800706:	f7 d8                	neg    %eax
  800708:	83 d2 00             	adc    $0x0,%edx
  80070b:	f7 da                	neg    %edx
			}
			base = 10;
  80070d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800712:	eb 5e                	jmp    800772 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800714:	8d 45 14             	lea    0x14(%ebp),%eax
  800717:	e8 63 fc ff ff       	call   80037f <getuint>
			base = 10;
  80071c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800721:	eb 4f                	jmp    800772 <vprintfmt+0x374>
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint (&ap, lflag);
  800723:	8d 45 14             	lea    0x14(%ebp),%eax
  800726:	e8 54 fc ff ff       	call   80037f <getuint>
			base = 8;
  80072b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800730:	eb 40                	jmp    800772 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800732:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800736:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80073d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800740:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800744:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80074b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80074e:	8b 45 14             	mov    0x14(%ebp),%eax
  800751:	8d 50 04             	lea    0x4(%eax),%edx
  800754:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800757:	8b 00                	mov    (%eax),%eax
  800759:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80075e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800763:	eb 0d                	jmp    800772 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800765:	8d 45 14             	lea    0x14(%ebp),%eax
  800768:	e8 12 fc ff ff       	call   80037f <getuint>
			base = 16;
  80076d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800772:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800776:	89 74 24 10          	mov    %esi,0x10(%esp)
  80077a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80077d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800781:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800785:	89 04 24             	mov    %eax,(%esp)
  800788:	89 54 24 04          	mov    %edx,0x4(%esp)
  80078c:	89 fa                	mov    %edi,%edx
  80078e:	8b 45 08             	mov    0x8(%ebp),%eax
  800791:	e8 fa fa ff ff       	call   800290 <printnum>
			break;
  800796:	e9 88 fc ff ff       	jmp    800423 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80079b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80079f:	89 04 24             	mov    %eax,(%esp)
  8007a2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8007a5:	e9 79 fc ff ff       	jmp    800423 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007aa:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007ae:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007b5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007b8:	89 f3                	mov    %esi,%ebx
  8007ba:	eb 03                	jmp    8007bf <vprintfmt+0x3c1>
  8007bc:	83 eb 01             	sub    $0x1,%ebx
  8007bf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8007c3:	75 f7                	jne    8007bc <vprintfmt+0x3be>
  8007c5:	e9 59 fc ff ff       	jmp    800423 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8007ca:	83 c4 3c             	add    $0x3c,%esp
  8007cd:	5b                   	pop    %ebx
  8007ce:	5e                   	pop    %esi
  8007cf:	5f                   	pop    %edi
  8007d0:	5d                   	pop    %ebp
  8007d1:	c3                   	ret    

008007d2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007d2:	55                   	push   %ebp
  8007d3:	89 e5                	mov    %esp,%ebp
  8007d5:	83 ec 28             	sub    $0x28,%esp
  8007d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8007db:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007de:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007e1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007e5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007ef:	85 c0                	test   %eax,%eax
  8007f1:	74 30                	je     800823 <vsnprintf+0x51>
  8007f3:	85 d2                	test   %edx,%edx
  8007f5:	7e 2c                	jle    800823 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8007fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007fe:	8b 45 10             	mov    0x10(%ebp),%eax
  800801:	89 44 24 08          	mov    %eax,0x8(%esp)
  800805:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800808:	89 44 24 04          	mov    %eax,0x4(%esp)
  80080c:	c7 04 24 b9 03 80 00 	movl   $0x8003b9,(%esp)
  800813:	e8 e6 fb ff ff       	call   8003fe <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800818:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80081b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80081e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800821:	eb 05                	jmp    800828 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800823:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800828:	c9                   	leave  
  800829:	c3                   	ret    

0080082a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80082a:	55                   	push   %ebp
  80082b:	89 e5                	mov    %esp,%ebp
  80082d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800830:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800833:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800837:	8b 45 10             	mov    0x10(%ebp),%eax
  80083a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80083e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800841:	89 44 24 04          	mov    %eax,0x4(%esp)
  800845:	8b 45 08             	mov    0x8(%ebp),%eax
  800848:	89 04 24             	mov    %eax,(%esp)
  80084b:	e8 82 ff ff ff       	call   8007d2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800850:	c9                   	leave  
  800851:	c3                   	ret    
  800852:	66 90                	xchg   %ax,%ax
  800854:	66 90                	xchg   %ax,%ax
  800856:	66 90                	xchg   %ax,%ax
  800858:	66 90                	xchg   %ax,%ax
  80085a:	66 90                	xchg   %ax,%ax
  80085c:	66 90                	xchg   %ax,%ax
  80085e:	66 90                	xchg   %ax,%ax

00800860 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800860:	55                   	push   %ebp
  800861:	89 e5                	mov    %esp,%ebp
  800863:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800866:	b8 00 00 00 00       	mov    $0x0,%eax
  80086b:	eb 03                	jmp    800870 <strlen+0x10>
		n++;
  80086d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800870:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800874:	75 f7                	jne    80086d <strlen+0xd>
		n++;
	return n;
}
  800876:	5d                   	pop    %ebp
  800877:	c3                   	ret    

00800878 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800878:	55                   	push   %ebp
  800879:	89 e5                	mov    %esp,%ebp
  80087b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80087e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800881:	b8 00 00 00 00       	mov    $0x0,%eax
  800886:	eb 03                	jmp    80088b <strnlen+0x13>
		n++;
  800888:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80088b:	39 d0                	cmp    %edx,%eax
  80088d:	74 06                	je     800895 <strnlen+0x1d>
  80088f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800893:	75 f3                	jne    800888 <strnlen+0x10>
		n++;
	return n;
}
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	53                   	push   %ebx
  80089b:	8b 45 08             	mov    0x8(%ebp),%eax
  80089e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008a1:	89 c2                	mov    %eax,%edx
  8008a3:	83 c2 01             	add    $0x1,%edx
  8008a6:	83 c1 01             	add    $0x1,%ecx
  8008a9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008ad:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008b0:	84 db                	test   %bl,%bl
  8008b2:	75 ef                	jne    8008a3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008b4:	5b                   	pop    %ebx
  8008b5:	5d                   	pop    %ebp
  8008b6:	c3                   	ret    

008008b7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008b7:	55                   	push   %ebp
  8008b8:	89 e5                	mov    %esp,%ebp
  8008ba:	53                   	push   %ebx
  8008bb:	83 ec 08             	sub    $0x8,%esp
  8008be:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008c1:	89 1c 24             	mov    %ebx,(%esp)
  8008c4:	e8 97 ff ff ff       	call   800860 <strlen>
	strcpy(dst + len, src);
  8008c9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008cc:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008d0:	01 d8                	add    %ebx,%eax
  8008d2:	89 04 24             	mov    %eax,(%esp)
  8008d5:	e8 bd ff ff ff       	call   800897 <strcpy>
	return dst;
}
  8008da:	89 d8                	mov    %ebx,%eax
  8008dc:	83 c4 08             	add    $0x8,%esp
  8008df:	5b                   	pop    %ebx
  8008e0:	5d                   	pop    %ebp
  8008e1:	c3                   	ret    

008008e2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	56                   	push   %esi
  8008e6:	53                   	push   %ebx
  8008e7:	8b 75 08             	mov    0x8(%ebp),%esi
  8008ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008ed:	89 f3                	mov    %esi,%ebx
  8008ef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008f2:	89 f2                	mov    %esi,%edx
  8008f4:	eb 0f                	jmp    800905 <strncpy+0x23>
		*dst++ = *src;
  8008f6:	83 c2 01             	add    $0x1,%edx
  8008f9:	0f b6 01             	movzbl (%ecx),%eax
  8008fc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008ff:	80 39 01             	cmpb   $0x1,(%ecx)
  800902:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800905:	39 da                	cmp    %ebx,%edx
  800907:	75 ed                	jne    8008f6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800909:	89 f0                	mov    %esi,%eax
  80090b:	5b                   	pop    %ebx
  80090c:	5e                   	pop    %esi
  80090d:	5d                   	pop    %ebp
  80090e:	c3                   	ret    

0080090f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80090f:	55                   	push   %ebp
  800910:	89 e5                	mov    %esp,%ebp
  800912:	56                   	push   %esi
  800913:	53                   	push   %ebx
  800914:	8b 75 08             	mov    0x8(%ebp),%esi
  800917:	8b 55 0c             	mov    0xc(%ebp),%edx
  80091a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80091d:	89 f0                	mov    %esi,%eax
  80091f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800923:	85 c9                	test   %ecx,%ecx
  800925:	75 0b                	jne    800932 <strlcpy+0x23>
  800927:	eb 1d                	jmp    800946 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800929:	83 c0 01             	add    $0x1,%eax
  80092c:	83 c2 01             	add    $0x1,%edx
  80092f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800932:	39 d8                	cmp    %ebx,%eax
  800934:	74 0b                	je     800941 <strlcpy+0x32>
  800936:	0f b6 0a             	movzbl (%edx),%ecx
  800939:	84 c9                	test   %cl,%cl
  80093b:	75 ec                	jne    800929 <strlcpy+0x1a>
  80093d:	89 c2                	mov    %eax,%edx
  80093f:	eb 02                	jmp    800943 <strlcpy+0x34>
  800941:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800943:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800946:	29 f0                	sub    %esi,%eax
}
  800948:	5b                   	pop    %ebx
  800949:	5e                   	pop    %esi
  80094a:	5d                   	pop    %ebp
  80094b:	c3                   	ret    

0080094c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80094c:	55                   	push   %ebp
  80094d:	89 e5                	mov    %esp,%ebp
  80094f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800952:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800955:	eb 06                	jmp    80095d <strcmp+0x11>
		p++, q++;
  800957:	83 c1 01             	add    $0x1,%ecx
  80095a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80095d:	0f b6 01             	movzbl (%ecx),%eax
  800960:	84 c0                	test   %al,%al
  800962:	74 04                	je     800968 <strcmp+0x1c>
  800964:	3a 02                	cmp    (%edx),%al
  800966:	74 ef                	je     800957 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800968:	0f b6 c0             	movzbl %al,%eax
  80096b:	0f b6 12             	movzbl (%edx),%edx
  80096e:	29 d0                	sub    %edx,%eax
}
  800970:	5d                   	pop    %ebp
  800971:	c3                   	ret    

00800972 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800972:	55                   	push   %ebp
  800973:	89 e5                	mov    %esp,%ebp
  800975:	53                   	push   %ebx
  800976:	8b 45 08             	mov    0x8(%ebp),%eax
  800979:	8b 55 0c             	mov    0xc(%ebp),%edx
  80097c:	89 c3                	mov    %eax,%ebx
  80097e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800981:	eb 06                	jmp    800989 <strncmp+0x17>
		n--, p++, q++;
  800983:	83 c0 01             	add    $0x1,%eax
  800986:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800989:	39 d8                	cmp    %ebx,%eax
  80098b:	74 15                	je     8009a2 <strncmp+0x30>
  80098d:	0f b6 08             	movzbl (%eax),%ecx
  800990:	84 c9                	test   %cl,%cl
  800992:	74 04                	je     800998 <strncmp+0x26>
  800994:	3a 0a                	cmp    (%edx),%cl
  800996:	74 eb                	je     800983 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800998:	0f b6 00             	movzbl (%eax),%eax
  80099b:	0f b6 12             	movzbl (%edx),%edx
  80099e:	29 d0                	sub    %edx,%eax
  8009a0:	eb 05                	jmp    8009a7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009a2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009a7:	5b                   	pop    %ebx
  8009a8:	5d                   	pop    %ebp
  8009a9:	c3                   	ret    

008009aa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009aa:	55                   	push   %ebp
  8009ab:	89 e5                	mov    %esp,%ebp
  8009ad:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009b4:	eb 07                	jmp    8009bd <strchr+0x13>
		if (*s == c)
  8009b6:	38 ca                	cmp    %cl,%dl
  8009b8:	74 0f                	je     8009c9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009ba:	83 c0 01             	add    $0x1,%eax
  8009bd:	0f b6 10             	movzbl (%eax),%edx
  8009c0:	84 d2                	test   %dl,%dl
  8009c2:	75 f2                	jne    8009b6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c9:	5d                   	pop    %ebp
  8009ca:	c3                   	ret    

008009cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009cb:	55                   	push   %ebp
  8009cc:	89 e5                	mov    %esp,%ebp
  8009ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009d5:	eb 07                	jmp    8009de <strfind+0x13>
		if (*s == c)
  8009d7:	38 ca                	cmp    %cl,%dl
  8009d9:	74 0a                	je     8009e5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009db:	83 c0 01             	add    $0x1,%eax
  8009de:	0f b6 10             	movzbl (%eax),%edx
  8009e1:	84 d2                	test   %dl,%dl
  8009e3:	75 f2                	jne    8009d7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8009e5:	5d                   	pop    %ebp
  8009e6:	c3                   	ret    

008009e7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009e7:	55                   	push   %ebp
  8009e8:	89 e5                	mov    %esp,%ebp
  8009ea:	57                   	push   %edi
  8009eb:	56                   	push   %esi
  8009ec:	53                   	push   %ebx
  8009ed:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009f3:	85 c9                	test   %ecx,%ecx
  8009f5:	74 36                	je     800a2d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009f7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009fd:	75 28                	jne    800a27 <memset+0x40>
  8009ff:	f6 c1 03             	test   $0x3,%cl
  800a02:	75 23                	jne    800a27 <memset+0x40>
		c &= 0xFF;
  800a04:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a08:	89 d3                	mov    %edx,%ebx
  800a0a:	c1 e3 08             	shl    $0x8,%ebx
  800a0d:	89 d6                	mov    %edx,%esi
  800a0f:	c1 e6 18             	shl    $0x18,%esi
  800a12:	89 d0                	mov    %edx,%eax
  800a14:	c1 e0 10             	shl    $0x10,%eax
  800a17:	09 f0                	or     %esi,%eax
  800a19:	09 c2                	or     %eax,%edx
  800a1b:	89 d0                	mov    %edx,%eax
  800a1d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a1f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a22:	fc                   	cld    
  800a23:	f3 ab                	rep stos %eax,%es:(%edi)
  800a25:	eb 06                	jmp    800a2d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a27:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a2a:	fc                   	cld    
  800a2b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a2d:	89 f8                	mov    %edi,%eax
  800a2f:	5b                   	pop    %ebx
  800a30:	5e                   	pop    %esi
  800a31:	5f                   	pop    %edi
  800a32:	5d                   	pop    %ebp
  800a33:	c3                   	ret    

00800a34 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a34:	55                   	push   %ebp
  800a35:	89 e5                	mov    %esp,%ebp
  800a37:	57                   	push   %edi
  800a38:	56                   	push   %esi
  800a39:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a3f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a42:	39 c6                	cmp    %eax,%esi
  800a44:	73 35                	jae    800a7b <memmove+0x47>
  800a46:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a49:	39 d0                	cmp    %edx,%eax
  800a4b:	73 2e                	jae    800a7b <memmove+0x47>
		s += n;
		d += n;
  800a4d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a50:	89 d6                	mov    %edx,%esi
  800a52:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a54:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a5a:	75 13                	jne    800a6f <memmove+0x3b>
  800a5c:	f6 c1 03             	test   $0x3,%cl
  800a5f:	75 0e                	jne    800a6f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a61:	83 ef 04             	sub    $0x4,%edi
  800a64:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a67:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a6a:	fd                   	std    
  800a6b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a6d:	eb 09                	jmp    800a78 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a6f:	83 ef 01             	sub    $0x1,%edi
  800a72:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a75:	fd                   	std    
  800a76:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a78:	fc                   	cld    
  800a79:	eb 1d                	jmp    800a98 <memmove+0x64>
  800a7b:	89 f2                	mov    %esi,%edx
  800a7d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a7f:	f6 c2 03             	test   $0x3,%dl
  800a82:	75 0f                	jne    800a93 <memmove+0x5f>
  800a84:	f6 c1 03             	test   $0x3,%cl
  800a87:	75 0a                	jne    800a93 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a89:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a8c:	89 c7                	mov    %eax,%edi
  800a8e:	fc                   	cld    
  800a8f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a91:	eb 05                	jmp    800a98 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a93:	89 c7                	mov    %eax,%edi
  800a95:	fc                   	cld    
  800a96:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a98:	5e                   	pop    %esi
  800a99:	5f                   	pop    %edi
  800a9a:	5d                   	pop    %ebp
  800a9b:	c3                   	ret    

00800a9c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a9c:	55                   	push   %ebp
  800a9d:	89 e5                	mov    %esp,%ebp
  800a9f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800aa2:	8b 45 10             	mov    0x10(%ebp),%eax
  800aa5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800aa9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aac:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ab0:	8b 45 08             	mov    0x8(%ebp),%eax
  800ab3:	89 04 24             	mov    %eax,(%esp)
  800ab6:	e8 79 ff ff ff       	call   800a34 <memmove>
}
  800abb:	c9                   	leave  
  800abc:	c3                   	ret    

00800abd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800abd:	55                   	push   %ebp
  800abe:	89 e5                	mov    %esp,%ebp
  800ac0:	56                   	push   %esi
  800ac1:	53                   	push   %ebx
  800ac2:	8b 55 08             	mov    0x8(%ebp),%edx
  800ac5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ac8:	89 d6                	mov    %edx,%esi
  800aca:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800acd:	eb 1a                	jmp    800ae9 <memcmp+0x2c>
		if (*s1 != *s2)
  800acf:	0f b6 02             	movzbl (%edx),%eax
  800ad2:	0f b6 19             	movzbl (%ecx),%ebx
  800ad5:	38 d8                	cmp    %bl,%al
  800ad7:	74 0a                	je     800ae3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800ad9:	0f b6 c0             	movzbl %al,%eax
  800adc:	0f b6 db             	movzbl %bl,%ebx
  800adf:	29 d8                	sub    %ebx,%eax
  800ae1:	eb 0f                	jmp    800af2 <memcmp+0x35>
		s1++, s2++;
  800ae3:	83 c2 01             	add    $0x1,%edx
  800ae6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ae9:	39 f2                	cmp    %esi,%edx
  800aeb:	75 e2                	jne    800acf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800aed:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800af2:	5b                   	pop    %ebx
  800af3:	5e                   	pop    %esi
  800af4:	5d                   	pop    %ebp
  800af5:	c3                   	ret    

00800af6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800af6:	55                   	push   %ebp
  800af7:	89 e5                	mov    %esp,%ebp
  800af9:	8b 45 08             	mov    0x8(%ebp),%eax
  800afc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800aff:	89 c2                	mov    %eax,%edx
  800b01:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b04:	eb 07                	jmp    800b0d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b06:	38 08                	cmp    %cl,(%eax)
  800b08:	74 07                	je     800b11 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b0a:	83 c0 01             	add    $0x1,%eax
  800b0d:	39 d0                	cmp    %edx,%eax
  800b0f:	72 f5                	jb     800b06 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b11:	5d                   	pop    %ebp
  800b12:	c3                   	ret    

00800b13 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b13:	55                   	push   %ebp
  800b14:	89 e5                	mov    %esp,%ebp
  800b16:	57                   	push   %edi
  800b17:	56                   	push   %esi
  800b18:	53                   	push   %ebx
  800b19:	8b 55 08             	mov    0x8(%ebp),%edx
  800b1c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b1f:	eb 03                	jmp    800b24 <strtol+0x11>
		s++;
  800b21:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b24:	0f b6 0a             	movzbl (%edx),%ecx
  800b27:	80 f9 09             	cmp    $0x9,%cl
  800b2a:	74 f5                	je     800b21 <strtol+0xe>
  800b2c:	80 f9 20             	cmp    $0x20,%cl
  800b2f:	74 f0                	je     800b21 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b31:	80 f9 2b             	cmp    $0x2b,%cl
  800b34:	75 0a                	jne    800b40 <strtol+0x2d>
		s++;
  800b36:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b39:	bf 00 00 00 00       	mov    $0x0,%edi
  800b3e:	eb 11                	jmp    800b51 <strtol+0x3e>
  800b40:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b45:	80 f9 2d             	cmp    $0x2d,%cl
  800b48:	75 07                	jne    800b51 <strtol+0x3e>
		s++, neg = 1;
  800b4a:	8d 52 01             	lea    0x1(%edx),%edx
  800b4d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b51:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b56:	75 15                	jne    800b6d <strtol+0x5a>
  800b58:	80 3a 30             	cmpb   $0x30,(%edx)
  800b5b:	75 10                	jne    800b6d <strtol+0x5a>
  800b5d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b61:	75 0a                	jne    800b6d <strtol+0x5a>
		s += 2, base = 16;
  800b63:	83 c2 02             	add    $0x2,%edx
  800b66:	b8 10 00 00 00       	mov    $0x10,%eax
  800b6b:	eb 10                	jmp    800b7d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b6d:	85 c0                	test   %eax,%eax
  800b6f:	75 0c                	jne    800b7d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b71:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b73:	80 3a 30             	cmpb   $0x30,(%edx)
  800b76:	75 05                	jne    800b7d <strtol+0x6a>
		s++, base = 8;
  800b78:	83 c2 01             	add    $0x1,%edx
  800b7b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b7d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b82:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b85:	0f b6 0a             	movzbl (%edx),%ecx
  800b88:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b8b:	89 f0                	mov    %esi,%eax
  800b8d:	3c 09                	cmp    $0x9,%al
  800b8f:	77 08                	ja     800b99 <strtol+0x86>
			dig = *s - '0';
  800b91:	0f be c9             	movsbl %cl,%ecx
  800b94:	83 e9 30             	sub    $0x30,%ecx
  800b97:	eb 20                	jmp    800bb9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b99:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b9c:	89 f0                	mov    %esi,%eax
  800b9e:	3c 19                	cmp    $0x19,%al
  800ba0:	77 08                	ja     800baa <strtol+0x97>
			dig = *s - 'a' + 10;
  800ba2:	0f be c9             	movsbl %cl,%ecx
  800ba5:	83 e9 57             	sub    $0x57,%ecx
  800ba8:	eb 0f                	jmp    800bb9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800baa:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800bad:	89 f0                	mov    %esi,%eax
  800baf:	3c 19                	cmp    $0x19,%al
  800bb1:	77 16                	ja     800bc9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800bb3:	0f be c9             	movsbl %cl,%ecx
  800bb6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bb9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800bbc:	7d 0f                	jge    800bcd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800bbe:	83 c2 01             	add    $0x1,%edx
  800bc1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800bc5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800bc7:	eb bc                	jmp    800b85 <strtol+0x72>
  800bc9:	89 d8                	mov    %ebx,%eax
  800bcb:	eb 02                	jmp    800bcf <strtol+0xbc>
  800bcd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800bcf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bd3:	74 05                	je     800bda <strtol+0xc7>
		*endptr = (char *) s;
  800bd5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bd8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800bda:	f7 d8                	neg    %eax
  800bdc:	85 ff                	test   %edi,%edi
  800bde:	0f 44 c3             	cmove  %ebx,%eax
}
  800be1:	5b                   	pop    %ebx
  800be2:	5e                   	pop    %esi
  800be3:	5f                   	pop    %edi
  800be4:	5d                   	pop    %ebp
  800be5:	c3                   	ret    

00800be6 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800be6:	55                   	push   %ebp
  800be7:	89 e5                	mov    %esp,%ebp
  800be9:	57                   	push   %edi
  800bea:	56                   	push   %esi
  800beb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bec:	b8 00 00 00 00       	mov    $0x0,%eax
  800bf1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bf4:	8b 55 08             	mov    0x8(%ebp),%edx
  800bf7:	89 c3                	mov    %eax,%ebx
  800bf9:	89 c7                	mov    %eax,%edi
  800bfb:	89 c6                	mov    %eax,%esi
  800bfd:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800bff:	5b                   	pop    %ebx
  800c00:	5e                   	pop    %esi
  800c01:	5f                   	pop    %edi
  800c02:	5d                   	pop    %ebp
  800c03:	c3                   	ret    

00800c04 <sys_cgetc>:

int
sys_cgetc(void)
{
  800c04:	55                   	push   %ebp
  800c05:	89 e5                	mov    %esp,%ebp
  800c07:	57                   	push   %edi
  800c08:	56                   	push   %esi
  800c09:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c0a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c0f:	b8 01 00 00 00       	mov    $0x1,%eax
  800c14:	89 d1                	mov    %edx,%ecx
  800c16:	89 d3                	mov    %edx,%ebx
  800c18:	89 d7                	mov    %edx,%edi
  800c1a:	89 d6                	mov    %edx,%esi
  800c1c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c1e:	5b                   	pop    %ebx
  800c1f:	5e                   	pop    %esi
  800c20:	5f                   	pop    %edi
  800c21:	5d                   	pop    %ebp
  800c22:	c3                   	ret    

00800c23 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c23:	55                   	push   %ebp
  800c24:	89 e5                	mov    %esp,%ebp
  800c26:	57                   	push   %edi
  800c27:	56                   	push   %esi
  800c28:	53                   	push   %ebx
  800c29:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c2c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c31:	b8 03 00 00 00       	mov    $0x3,%eax
  800c36:	8b 55 08             	mov    0x8(%ebp),%edx
  800c39:	89 cb                	mov    %ecx,%ebx
  800c3b:	89 cf                	mov    %ecx,%edi
  800c3d:	89 ce                	mov    %ecx,%esi
  800c3f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c41:	85 c0                	test   %eax,%eax
  800c43:	7e 28                	jle    800c6d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c45:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c49:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c50:	00 
  800c51:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800c58:	00 
  800c59:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c60:	00 
  800c61:	c7 04 24 e5 19 80 00 	movl   $0x8019e5,(%esp)
  800c68:	e8 0a f5 ff ff       	call   800177 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c6d:	83 c4 2c             	add    $0x2c,%esp
  800c70:	5b                   	pop    %ebx
  800c71:	5e                   	pop    %esi
  800c72:	5f                   	pop    %edi
  800c73:	5d                   	pop    %ebp
  800c74:	c3                   	ret    

00800c75 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c75:	55                   	push   %ebp
  800c76:	89 e5                	mov    %esp,%ebp
  800c78:	57                   	push   %edi
  800c79:	56                   	push   %esi
  800c7a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7b:	ba 00 00 00 00       	mov    $0x0,%edx
  800c80:	b8 02 00 00 00       	mov    $0x2,%eax
  800c85:	89 d1                	mov    %edx,%ecx
  800c87:	89 d3                	mov    %edx,%ebx
  800c89:	89 d7                	mov    %edx,%edi
  800c8b:	89 d6                	mov    %edx,%esi
  800c8d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c8f:	5b                   	pop    %ebx
  800c90:	5e                   	pop    %esi
  800c91:	5f                   	pop    %edi
  800c92:	5d                   	pop    %ebp
  800c93:	c3                   	ret    

00800c94 <sys_yield>:

void
sys_yield(void)
{
  800c94:	55                   	push   %ebp
  800c95:	89 e5                	mov    %esp,%ebp
  800c97:	57                   	push   %edi
  800c98:	56                   	push   %esi
  800c99:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c9a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c9f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800ca4:	89 d1                	mov    %edx,%ecx
  800ca6:	89 d3                	mov    %edx,%ebx
  800ca8:	89 d7                	mov    %edx,%edi
  800caa:	89 d6                	mov    %edx,%esi
  800cac:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800cae:	5b                   	pop    %ebx
  800caf:	5e                   	pop    %esi
  800cb0:	5f                   	pop    %edi
  800cb1:	5d                   	pop    %ebp
  800cb2:	c3                   	ret    

00800cb3 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800cb3:	55                   	push   %ebp
  800cb4:	89 e5                	mov    %esp,%ebp
  800cb6:	57                   	push   %edi
  800cb7:	56                   	push   %esi
  800cb8:	53                   	push   %ebx
  800cb9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cbc:	be 00 00 00 00       	mov    $0x0,%esi
  800cc1:	b8 04 00 00 00       	mov    $0x4,%eax
  800cc6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc9:	8b 55 08             	mov    0x8(%ebp),%edx
  800ccc:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800ccf:	89 f7                	mov    %esi,%edi
  800cd1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cd3:	85 c0                	test   %eax,%eax
  800cd5:	7e 28                	jle    800cff <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cd7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cdb:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800ce2:	00 
  800ce3:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800cea:	00 
  800ceb:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cf2:	00 
  800cf3:	c7 04 24 e5 19 80 00 	movl   $0x8019e5,(%esp)
  800cfa:	e8 78 f4 ff ff       	call   800177 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800cff:	83 c4 2c             	add    $0x2c,%esp
  800d02:	5b                   	pop    %ebx
  800d03:	5e                   	pop    %esi
  800d04:	5f                   	pop    %edi
  800d05:	5d                   	pop    %ebp
  800d06:	c3                   	ret    

00800d07 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800d07:	55                   	push   %ebp
  800d08:	89 e5                	mov    %esp,%ebp
  800d0a:	57                   	push   %edi
  800d0b:	56                   	push   %esi
  800d0c:	53                   	push   %ebx
  800d0d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d10:	b8 05 00 00 00       	mov    $0x5,%eax
  800d15:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d18:	8b 55 08             	mov    0x8(%ebp),%edx
  800d1b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d1e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d21:	8b 75 18             	mov    0x18(%ebp),%esi
  800d24:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d26:	85 c0                	test   %eax,%eax
  800d28:	7e 28                	jle    800d52 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d2a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d2e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800d35:	00 
  800d36:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800d3d:	00 
  800d3e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d45:	00 
  800d46:	c7 04 24 e5 19 80 00 	movl   $0x8019e5,(%esp)
  800d4d:	e8 25 f4 ff ff       	call   800177 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800d52:	83 c4 2c             	add    $0x2c,%esp
  800d55:	5b                   	pop    %ebx
  800d56:	5e                   	pop    %esi
  800d57:	5f                   	pop    %edi
  800d58:	5d                   	pop    %ebp
  800d59:	c3                   	ret    

00800d5a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800d5a:	55                   	push   %ebp
  800d5b:	89 e5                	mov    %esp,%ebp
  800d5d:	57                   	push   %edi
  800d5e:	56                   	push   %esi
  800d5f:	53                   	push   %ebx
  800d60:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d63:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d68:	b8 06 00 00 00       	mov    $0x6,%eax
  800d6d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d70:	8b 55 08             	mov    0x8(%ebp),%edx
  800d73:	89 df                	mov    %ebx,%edi
  800d75:	89 de                	mov    %ebx,%esi
  800d77:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d79:	85 c0                	test   %eax,%eax
  800d7b:	7e 28                	jle    800da5 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d7d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d81:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800d88:	00 
  800d89:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800d90:	00 
  800d91:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d98:	00 
  800d99:	c7 04 24 e5 19 80 00 	movl   $0x8019e5,(%esp)
  800da0:	e8 d2 f3 ff ff       	call   800177 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800da5:	83 c4 2c             	add    $0x2c,%esp
  800da8:	5b                   	pop    %ebx
  800da9:	5e                   	pop    %esi
  800daa:	5f                   	pop    %edi
  800dab:	5d                   	pop    %ebp
  800dac:	c3                   	ret    

00800dad <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800dad:	55                   	push   %ebp
  800dae:	89 e5                	mov    %esp,%ebp
  800db0:	57                   	push   %edi
  800db1:	56                   	push   %esi
  800db2:	53                   	push   %ebx
  800db3:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800db6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800dbb:	b8 08 00 00 00       	mov    $0x8,%eax
  800dc0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800dc3:	8b 55 08             	mov    0x8(%ebp),%edx
  800dc6:	89 df                	mov    %ebx,%edi
  800dc8:	89 de                	mov    %ebx,%esi
  800dca:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800dcc:	85 c0                	test   %eax,%eax
  800dce:	7e 28                	jle    800df8 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dd0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dd4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800ddb:	00 
  800ddc:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800de3:	00 
  800de4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800deb:	00 
  800dec:	c7 04 24 e5 19 80 00 	movl   $0x8019e5,(%esp)
  800df3:	e8 7f f3 ff ff       	call   800177 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800df8:	83 c4 2c             	add    $0x2c,%esp
  800dfb:	5b                   	pop    %ebx
  800dfc:	5e                   	pop    %esi
  800dfd:	5f                   	pop    %edi
  800dfe:	5d                   	pop    %ebp
  800dff:	c3                   	ret    

00800e00 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800e00:	55                   	push   %ebp
  800e01:	89 e5                	mov    %esp,%ebp
  800e03:	57                   	push   %edi
  800e04:	56                   	push   %esi
  800e05:	53                   	push   %ebx
  800e06:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e09:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e0e:	b8 09 00 00 00       	mov    $0x9,%eax
  800e13:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e16:	8b 55 08             	mov    0x8(%ebp),%edx
  800e19:	89 df                	mov    %ebx,%edi
  800e1b:	89 de                	mov    %ebx,%esi
  800e1d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e1f:	85 c0                	test   %eax,%eax
  800e21:	7e 28                	jle    800e4b <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e23:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e27:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800e2e:	00 
  800e2f:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800e36:	00 
  800e37:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e3e:	00 
  800e3f:	c7 04 24 e5 19 80 00 	movl   $0x8019e5,(%esp)
  800e46:	e8 2c f3 ff ff       	call   800177 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800e4b:	83 c4 2c             	add    $0x2c,%esp
  800e4e:	5b                   	pop    %ebx
  800e4f:	5e                   	pop    %esi
  800e50:	5f                   	pop    %edi
  800e51:	5d                   	pop    %ebp
  800e52:	c3                   	ret    

00800e53 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800e53:	55                   	push   %ebp
  800e54:	89 e5                	mov    %esp,%ebp
  800e56:	57                   	push   %edi
  800e57:	56                   	push   %esi
  800e58:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e59:	be 00 00 00 00       	mov    $0x0,%esi
  800e5e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800e63:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e66:	8b 55 08             	mov    0x8(%ebp),%edx
  800e69:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e6c:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e6f:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800e71:	5b                   	pop    %ebx
  800e72:	5e                   	pop    %esi
  800e73:	5f                   	pop    %edi
  800e74:	5d                   	pop    %ebp
  800e75:	c3                   	ret    

00800e76 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800e76:	55                   	push   %ebp
  800e77:	89 e5                	mov    %esp,%ebp
  800e79:	57                   	push   %edi
  800e7a:	56                   	push   %esi
  800e7b:	53                   	push   %ebx
  800e7c:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e7f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800e84:	b8 0c 00 00 00       	mov    $0xc,%eax
  800e89:	8b 55 08             	mov    0x8(%ebp),%edx
  800e8c:	89 cb                	mov    %ecx,%ebx
  800e8e:	89 cf                	mov    %ecx,%edi
  800e90:	89 ce                	mov    %ecx,%esi
  800e92:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e94:	85 c0                	test   %eax,%eax
  800e96:	7e 28                	jle    800ec0 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e98:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e9c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800ea3:	00 
  800ea4:	c7 44 24 08 c8 19 80 	movl   $0x8019c8,0x8(%esp)
  800eab:	00 
  800eac:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800eb3:	00 
  800eb4:	c7 04 24 e5 19 80 00 	movl   $0x8019e5,(%esp)
  800ebb:	e8 b7 f2 ff ff       	call   800177 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800ec0:	83 c4 2c             	add    $0x2c,%esp
  800ec3:	5b                   	pop    %ebx
  800ec4:	5e                   	pop    %esi
  800ec5:	5f                   	pop    %edi
  800ec6:	5d                   	pop    %ebp
  800ec7:	c3                   	ret    

00800ec8 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800ec8:	55                   	push   %ebp
  800ec9:	89 e5                	mov    %esp,%ebp
  800ecb:	53                   	push   %ebx
  800ecc:	83 ec 24             	sub    $0x24,%esp
  800ecf:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  800ed2:	8b 18                	mov    (%eax),%ebx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) != FEC_WR)
  800ed4:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800ed8:	75 1c                	jne    800ef6 <pgfault+0x2e>
		panic("Invalid page fault access.");
  800eda:	c7 44 24 08 f3 19 80 	movl   $0x8019f3,0x8(%esp)
  800ee1:	00 
  800ee2:	c7 44 24 04 1d 00 00 	movl   $0x1d,0x4(%esp)
  800ee9:	00 
  800eea:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  800ef1:	e8 81 f2 ff ff       	call   800177 <_panic>

	if (!(uvpt[(uint32_t)addr>>12] & PTE_COW))
  800ef6:	89 d8                	mov    %ebx,%eax
  800ef8:	c1 e8 0c             	shr    $0xc,%eax
  800efb:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800f02:	f6 c4 08             	test   $0x8,%ah
  800f05:	75 1c                	jne    800f23 <pgfault+0x5b>
		panic("Not copy-on-write page.");
  800f07:	c7 44 24 08 19 1a 80 	movl   $0x801a19,0x8(%esp)
  800f0e:	00 
  800f0f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800f16:	00 
  800f17:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  800f1e:	e8 54 f2 ff ff       	call   800177 <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr,PGSIZE);
  800f23:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if ((r=sys_page_alloc(0,(void*)PFTEMP,PTE_P|PTE_U|PTE_W)) < 0)
  800f29:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800f30:	00 
  800f31:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f38:	00 
  800f39:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f40:	e8 6e fd ff ff       	call   800cb3 <sys_page_alloc>
  800f45:	85 c0                	test   %eax,%eax
  800f47:	79 1c                	jns    800f65 <pgfault+0x9d>
		panic("FGFAULT PAGE ALLOC FAILURE.");
  800f49:	c7 44 24 08 31 1a 80 	movl   $0x801a31,0x8(%esp)
  800f50:	00 
  800f51:	c7 44 24 04 2b 00 00 	movl   $0x2b,0x4(%esp)
  800f58:	00 
  800f59:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  800f60:	e8 12 f2 ff ff       	call   800177 <_panic>
	memmove((void*)PFTEMP,addr,PGSIZE);
  800f65:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  800f6c:	00 
  800f6d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800f71:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  800f78:	e8 b7 fa ff ff       	call   800a34 <memmove>
	if ((r=sys_page_unmap(0,addr)) < 0)
  800f7d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800f81:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f88:	e8 cd fd ff ff       	call   800d5a <sys_page_unmap>
  800f8d:	85 c0                	test   %eax,%eax
  800f8f:	79 1c                	jns    800fad <pgfault+0xe5>
		panic("PGFAULT PAGE UNMAP FAILURE.");
  800f91:	c7 44 24 08 4d 1a 80 	movl   $0x801a4d,0x8(%esp)
  800f98:	00 
  800f99:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
  800fa0:	00 
  800fa1:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  800fa8:	e8 ca f1 ff ff       	call   800177 <_panic>
	if ((r=sys_page_map(0,(void*)PFTEMP,0,addr,PTE_P|PTE_U|PTE_W)) < 0)
  800fad:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  800fb4:	00 
  800fb5:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800fb9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800fc0:	00 
  800fc1:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800fc8:	00 
  800fc9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800fd0:	e8 32 fd ff ff       	call   800d07 <sys_page_map>
  800fd5:	85 c0                	test   %eax,%eax
  800fd7:	79 1c                	jns    800ff5 <pgfault+0x12d>
		panic("PGFAULT PAGE MAP FAILURE.");
  800fd9:	c7 44 24 08 69 1a 80 	movl   $0x801a69,0x8(%esp)
  800fe0:	00 
  800fe1:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  800fe8:	00 
  800fe9:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  800ff0:	e8 82 f1 ff ff       	call   800177 <_panic>
	if ((r=sys_page_unmap(0,(void*)PFTEMP)) < 0)
  800ff5:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800ffc:	00 
  800ffd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801004:	e8 51 fd ff ff       	call   800d5a <sys_page_unmap>
  801009:	85 c0                	test   %eax,%eax
  80100b:	79 1c                	jns    801029 <pgfault+0x161>
		panic("PGFAULT PAGE UNMAP FAILURE.");
  80100d:	c7 44 24 08 4d 1a 80 	movl   $0x801a4d,0x8(%esp)
  801014:	00 
  801015:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  80101c:	00 
  80101d:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  801024:	e8 4e f1 ff ff       	call   800177 <_panic>


	//panic("pgfault not implemented");
}
  801029:	83 c4 24             	add    $0x24,%esp
  80102c:	5b                   	pop    %ebx
  80102d:	5d                   	pop    %ebp
  80102e:	c3                   	ret    

0080102f <duppage>:
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
  80102f:	55                   	push   %ebp
  801030:	89 e5                	mov    %esp,%ebp
  801032:	53                   	push   %ebx
  801033:	83 ec 24             	sub    $0x24,%esp
	int r;

	// LAB 4: Your code here.
	//panic("duppage not implemented");
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) {
  801036:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  80103d:	f6 c1 02             	test   $0x2,%cl
  801040:	75 10                	jne    801052 <duppage+0x23>
  801042:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  801049:	f6 c5 08             	test   $0x8,%ch
  80104c:	0f 84 89 00 00 00    	je     8010db <duppage+0xac>
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),envid,(void*)(pn*PGSIZE),PTE_P|PTE_U|PTE_COW)) < 0)
  801052:	89 d3                	mov    %edx,%ebx
  801054:	c1 e3 0c             	shl    $0xc,%ebx
  801057:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  80105e:	00 
  80105f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  801063:	89 44 24 08          	mov    %eax,0x8(%esp)
  801067:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80106b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801072:	e8 90 fc ff ff       	call   800d07 <sys_page_map>
  801077:	85 c0                	test   %eax,%eax
  801079:	79 1c                	jns    801097 <duppage+0x68>
			panic("DUPPAGE PAGE MAP FAILURE.");
  80107b:	c7 44 24 08 83 1a 80 	movl   $0x801a83,0x8(%esp)
  801082:	00 
  801083:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
  80108a:	00 
  80108b:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  801092:	e8 e0 f0 ff ff       	call   800177 <_panic>
	
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),0,(void*)(pn*PGSIZE),PTE_P|PTE_U|PTE_COW)) < 0)
  801097:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  80109e:	00 
  80109f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8010a3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8010aa:	00 
  8010ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8010af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8010b6:	e8 4c fc ff ff       	call   800d07 <sys_page_map>
  8010bb:	85 c0                	test   %eax,%eax
  8010bd:	79 68                	jns    801127 <duppage+0xf8>
			panic("DUPPAGE PAGE MAP FAILURE.");
  8010bf:	c7 44 24 08 83 1a 80 	movl   $0x801a83,0x8(%esp)
  8010c6:	00 
  8010c7:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
  8010ce:	00 
  8010cf:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  8010d6:	e8 9c f0 ff ff       	call   800177 <_panic>

	} else {
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),envid,(void*)(pn*PGSIZE),uvpt[pn]&0xfff)) < 0)
  8010db:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  8010e2:	c1 e2 0c             	shl    $0xc,%edx
  8010e5:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
  8010eb:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8010ef:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8010f3:	89 44 24 08          	mov    %eax,0x8(%esp)
  8010f7:	89 54 24 04          	mov    %edx,0x4(%esp)
  8010fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801102:	e8 00 fc ff ff       	call   800d07 <sys_page_map>
  801107:	85 c0                	test   %eax,%eax
  801109:	79 1c                	jns    801127 <duppage+0xf8>
			panic("DUPPAGE PAGE MAP FAILURE.");
  80110b:	c7 44 24 08 83 1a 80 	movl   $0x801a83,0x8(%esp)
  801112:	00 
  801113:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  80111a:	00 
  80111b:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  801122:	e8 50 f0 ff ff       	call   800177 <_panic>
	}
	return 0;
}
  801127:	b8 00 00 00 00       	mov    $0x0,%eax
  80112c:	83 c4 24             	add    $0x24,%esp
  80112f:	5b                   	pop    %ebx
  801130:	5d                   	pop    %ebp
  801131:	c3                   	ret    

00801132 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  801132:	55                   	push   %ebp
  801133:	89 e5                	mov    %esp,%ebp
  801135:	57                   	push   %edi
  801136:	56                   	push   %esi
  801137:	53                   	push   %ebx
  801138:	83 ec 1c             	sub    $0x1c,%esp
	int r;
	envid_t envid;
	uint32_t n;
	
	//1. Setup pgfault() handler
	set_pgfault_handler(pgfault);
  80113b:	c7 04 24 c8 0e 80 00 	movl   $0x800ec8,(%esp)
  801142:	e8 89 02 00 00       	call   8013d0 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  801147:	b8 07 00 00 00       	mov    $0x7,%eax
  80114c:	cd 30                	int    $0x30
  80114e:	89 c6                	mov    %eax,%esi

	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
  801150:	85 c0                	test   %eax,%eax
  801152:	79 20                	jns    801174 <fork+0x42>
		panic("sys_exofork: %e", envid);
  801154:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801158:	c7 44 24 08 9d 1a 80 	movl   $0x801a9d,0x8(%esp)
  80115f:	00 
  801160:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  801167:	00 
  801168:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  80116f:	e8 03 f0 ff ff       	call   800177 <_panic>
  801174:	89 c7                	mov    %eax,%edi
	}

	// We're the parent.

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {
  801176:	b8 00 00 00 00       	mov    $0x0,%eax
	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
  80117b:	bb 00 00 00 00       	mov    $0x0,%ebx
  801180:	85 f6                	test   %esi,%esi
  801182:	75 21                	jne    8011a5 <fork+0x73>
		// We're the child.
		thisenv = &envs[ENVX(sys_getenvid())];
  801184:	e8 ec fa ff ff       	call   800c75 <sys_getenvid>
  801189:	25 ff 03 00 00       	and    $0x3ff,%eax
  80118e:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801191:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801196:	a3 08 20 80 00       	mov    %eax,0x802008
		return 0;
  80119b:	b8 00 00 00 00       	mov    $0x0,%eax
  8011a0:	e9 ac 00 00 00       	jmp    801251 <fork+0x11f>

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {

		//3.1 Copy page mapping using duppage
		if ((uvpd[n>>10] & PTE_P)) {
  8011a5:	89 da                	mov    %ebx,%edx
  8011a7:	c1 ea 0a             	shr    $0xa,%edx
  8011aa:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  8011b1:	f6 c2 01             	test   $0x1,%dl
  8011b4:	74 21                	je     8011d7 <fork+0xa5>
			if ((uvpt[n] & PTE_P))
  8011b6:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  8011bd:	f6 c2 01             	test   $0x1,%dl
  8011c0:	74 10                	je     8011d2 <fork+0xa0>
				if (n*PGSIZE != UXSTACKTOP-PGSIZE)
  8011c2:	3d 00 f0 bf ee       	cmp    $0xeebff000,%eax
  8011c7:	74 09                	je     8011d2 <fork+0xa0>
					duppage(envid,n);
  8011c9:	89 da                	mov    %ebx,%edx
  8011cb:	89 f8                	mov    %edi,%eax
  8011cd:	e8 5d fe ff ff       	call   80102f <duppage>
			n++;
  8011d2:	83 c3 01             	add    $0x1,%ebx
  8011d5:	eb 0c                	jmp    8011e3 <fork+0xb1>
		} else {
			n=n+NPDENTRIES-n%NPDENTRIES;
  8011d7:	81 e3 00 fc ff ff    	and    $0xfffffc00,%ebx
  8011dd:	81 c3 00 04 00 00    	add    $0x400,%ebx
	}

	// We're the parent.

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {
  8011e3:	89 d8                	mov    %ebx,%eax
  8011e5:	c1 e0 0c             	shl    $0xc,%eax
  8011e8:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
  8011ed:	76 b6                	jbe    8011a5 <fork+0x73>
		}
	 	
	}
	
	//3.2 Copy exception stack page
	sys_page_alloc(envid,(void*)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W);
  8011ef:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8011f6:	00 
  8011f7:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8011fe:	ee 
  8011ff:	89 34 24             	mov    %esi,(%esp)
  801202:	e8 ac fa ff ff       	call   800cb3 <sys_page_alloc>

	//4. Set the pgfault handler for child
	sys_env_set_pgfault_upcall(envid,thisenv->env_pgfault_upcall);
  801207:	a1 08 20 80 00       	mov    0x802008,%eax
  80120c:	8b 40 64             	mov    0x64(%eax),%eax
  80120f:	89 44 24 04          	mov    %eax,0x4(%esp)
  801213:	89 34 24             	mov    %esi,(%esp)
  801216:	e8 e5 fb ff ff       	call   800e00 <sys_env_set_pgfault_upcall>


	//5. Mark the child as runnable and return
	if ((r=sys_env_set_status(envid,ENV_RUNNABLE))<0) {
  80121b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  801222:	00 
  801223:	89 34 24             	mov    %esi,(%esp)
  801226:	e8 82 fb ff ff       	call   800dad <sys_env_set_status>
  80122b:	85 c0                	test   %eax,%eax
  80122d:	79 20                	jns    80124f <fork+0x11d>
		panic("sys_env_set_status: %e", r);
  80122f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801233:	c7 44 24 08 ad 1a 80 	movl   $0x801aad,0x8(%esp)
  80123a:	00 
  80123b:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
  801242:	00 
  801243:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  80124a:	e8 28 ef ff ff       	call   800177 <_panic>
	}

	return envid;
  80124f:	89 f0                	mov    %esi,%eax

}
  801251:	83 c4 1c             	add    $0x1c,%esp
  801254:	5b                   	pop    %ebx
  801255:	5e                   	pop    %esi
  801256:	5f                   	pop    %edi
  801257:	5d                   	pop    %ebp
  801258:	c3                   	ret    

00801259 <sfork>:

// Challenge!
int
sfork(void)
{
  801259:	55                   	push   %ebp
  80125a:	89 e5                	mov    %esp,%ebp
  80125c:	57                   	push   %edi
  80125d:	56                   	push   %esi
  80125e:	53                   	push   %ebx
  80125f:	83 ec 2c             	sub    $0x2c,%esp
	int r;
	envid_t envid;
	uint32_t n;
	
	//1. Setup pgfault() handler
	set_pgfault_handler(pgfault);
  801262:	c7 04 24 c8 0e 80 00 	movl   $0x800ec8,(%esp)
  801269:	e8 62 01 00 00       	call   8013d0 <set_pgfault_handler>
  80126e:	b8 07 00 00 00       	mov    $0x7,%eax
  801273:	cd 30                	int    $0x30
  801275:	89 c6                	mov    %eax,%esi

	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
  801277:	85 c0                	test   %eax,%eax
  801279:	79 20                	jns    80129b <sfork+0x42>
		panic("sys_exofork: %e", envid);
  80127b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80127f:	c7 44 24 08 9d 1a 80 	movl   $0x801a9d,0x8(%esp)
  801286:	00 
  801287:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
  80128e:	00 
  80128f:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  801296:	e8 dc ee ff ff       	call   800177 <_panic>
  80129b:	89 c7                	mov    %eax,%edi
		return 0;
	}

	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {
  80129d:	b8 00 00 00 00       	mov    $0x0,%eax
	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
  8012a2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8012a7:	85 f6                	test   %esi,%esi
  8012a9:	75 21                	jne    8012cc <sfork+0x73>
		// We're the child.
		thisenv = &envs[ENVX(sys_getenvid())];
  8012ab:	e8 c5 f9 ff ff       	call   800c75 <sys_getenvid>
  8012b0:	25 ff 03 00 00       	and    $0x3ff,%eax
  8012b5:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8012b8:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8012bd:	a3 08 20 80 00       	mov    %eax,0x802008
		return 0;
  8012c2:	b8 00 00 00 00       	mov    $0x0,%eax
  8012c7:	e9 fc 00 00 00       	jmp    8013c8 <sfork+0x16f>
	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {

		//3.1 Copy stack page mapping using duppage
		if ((uvpd[n>>10] & PTE_P)) {
  8012cc:	89 da                	mov    %ebx,%edx
  8012ce:	c1 ea 0a             	shr    $0xa,%edx
  8012d1:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  8012d8:	f6 c2 01             	test   $0x1,%dl
  8012db:	74 6a                	je     801347 <sfork+0xee>
			if ((uvpt[n] & PTE_P)) {
  8012dd:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  8012e4:	f6 c2 01             	test   $0x1,%dl
  8012e7:	74 59                	je     801342 <sfork+0xe9>
				if (n*PGSIZE == USTACKTOP-PGSIZE)
  8012e9:	3d 00 d0 bf ee       	cmp    $0xeebfd000,%eax
  8012ee:	75 0b                	jne    8012fb <sfork+0xa2>
					duppage(envid,n);
  8012f0:	89 da                	mov    %ebx,%edx
  8012f2:	89 f8                	mov    %edi,%eax
  8012f4:	e8 36 fd ff ff       	call   80102f <duppage>
  8012f9:	eb 47                	jmp    801342 <sfork+0xe9>
				else if (n*PGSIZE != UXSTACKTOP-PGSIZE) {
  8012fb:	3d 00 f0 bf ee       	cmp    $0xeebff000,%eax
  801300:	74 40                	je     801342 <sfork+0xe9>
					//Share-memory copy
					if((r=sys_page_map(0,(void*)(n*PGSIZE),envid,(void*)(n*PGSIZE),PTE_P|PTE_U|PTE_W)) < 0)
  801302:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  801309:	00 
  80130a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80130e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801312:	89 44 24 04          	mov    %eax,0x4(%esp)
  801316:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80131d:	e8 e5 f9 ff ff       	call   800d07 <sys_page_map>
  801322:	85 c0                	test   %eax,%eax
  801324:	79 1c                	jns    801342 <sfork+0xe9>
						panic("Shared-memory mapping failure.");
  801326:	c7 44 24 08 c4 1a 80 	movl   $0x801ac4,0x8(%esp)
  80132d:	00 
  80132e:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  801335:	00 
  801336:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  80133d:	e8 35 ee ff ff       	call   800177 <_panic>
				}
			}	
			n++;
  801342:	83 c3 01             	add    $0x1,%ebx
  801345:	eb 0c                	jmp    801353 <sfork+0xfa>
		} else {
			n=n+NPDENTRIES-n%NPDENTRIES;
  801347:	81 e3 00 fc ff ff    	and    $0xfffffc00,%ebx
  80134d:	81 c3 00 04 00 00    	add    $0x400,%ebx
		return 0;
	}

	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {
  801353:	83 c3 01             	add    $0x1,%ebx
  801356:	89 d8                	mov    %ebx,%eax
  801358:	c1 e0 0c             	shl    $0xc,%eax
  80135b:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
  801360:	0f 86 66 ff ff ff    	jbe    8012cc <sfork+0x73>
			n=n+NPDENTRIES-n%NPDENTRIES;
		}
	}
	
	//3.2 Copy exception stack page
	sys_page_alloc(envid,(void*)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W);
  801366:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  80136d:	00 
  80136e:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  801375:	ee 
  801376:	89 34 24             	mov    %esi,(%esp)
  801379:	e8 35 f9 ff ff       	call   800cb3 <sys_page_alloc>

	//4. Set the pgfault handler for child
	sys_env_set_pgfault_upcall(envid,thisenv->env_pgfault_upcall);
  80137e:	a1 08 20 80 00       	mov    0x802008,%eax
  801383:	8b 40 64             	mov    0x64(%eax),%eax
  801386:	89 44 24 04          	mov    %eax,0x4(%esp)
  80138a:	89 34 24             	mov    %esi,(%esp)
  80138d:	e8 6e fa ff ff       	call   800e00 <sys_env_set_pgfault_upcall>

	//5. Mark the child as runnable and return
	if ((r=sys_env_set_status(envid,ENV_RUNNABLE))<0) {
  801392:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  801399:	00 
  80139a:	89 34 24             	mov    %esi,(%esp)
  80139d:	e8 0b fa ff ff       	call   800dad <sys_env_set_status>
  8013a2:	85 c0                	test   %eax,%eax
  8013a4:	79 20                	jns    8013c6 <sfork+0x16d>
		panic("sys_env_set_status: %e", r);
  8013a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8013aa:	c7 44 24 08 ad 1a 80 	movl   $0x801aad,0x8(%esp)
  8013b1:	00 
  8013b2:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  8013b9:	00 
  8013ba:	c7 04 24 0e 1a 80 00 	movl   $0x801a0e,(%esp)
  8013c1:	e8 b1 ed ff ff       	call   800177 <_panic>
	}

	//return -E_INVAL;
	return envid;
  8013c6:	89 f0                	mov    %esi,%eax
}
  8013c8:	83 c4 2c             	add    $0x2c,%esp
  8013cb:	5b                   	pop    %ebx
  8013cc:	5e                   	pop    %esi
  8013cd:	5f                   	pop    %edi
  8013ce:	5d                   	pop    %ebp
  8013cf:	c3                   	ret    

008013d0 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8013d0:	55                   	push   %ebp
  8013d1:	89 e5                	mov    %esp,%ebp
  8013d3:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  8013d6:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  8013dd:	75 1d                	jne    8013fc <set_pgfault_handler+0x2c>
		// First time through!
		// LAB 4: Your code here.
		sys_page_alloc(sys_getenvid(), (void*)(UXSTACKTOP-PGSIZE), PTE_U|PTE_W|PTE_P);
  8013df:	e8 91 f8 ff ff       	call   800c75 <sys_getenvid>
  8013e4:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8013eb:	00 
  8013ec:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8013f3:	ee 
  8013f4:	89 04 24             	mov    %eax,(%esp)
  8013f7:	e8 b7 f8 ff ff       	call   800cb3 <sys_page_alloc>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8013fc:	8b 45 08             	mov    0x8(%ebp),%eax
  8013ff:	a3 0c 20 80 00       	mov    %eax,0x80200c
	//cprintf("UPCALL: %p\n",_pgfault_upcall);
	sys_env_set_pgfault_upcall(sys_getenvid(), _pgfault_upcall);
  801404:	e8 6c f8 ff ff       	call   800c75 <sys_getenvid>
  801409:	c7 44 24 04 1b 14 80 	movl   $0x80141b,0x4(%esp)
  801410:	00 
  801411:	89 04 24             	mov    %eax,(%esp)
  801414:	e8 e7 f9 ff ff       	call   800e00 <sys_env_set_pgfault_upcall>
}
  801419:	c9                   	leave  
  80141a:	c3                   	ret    

0080141b <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  80141b:	54                   	push   %esp
	movl _pgfault_handler, %eax
  80141c:	a1 0c 20 80 00       	mov    0x80200c,%eax
	call *%eax
  801421:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801423:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	addl $8, %esp
  801426:	83 c4 08             	add    $0x8,%esp


	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  801429:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	pushl %eax
  80142a:	50                   	push   %eax
	pushl %ebx
  80142b:	53                   	push   %ebx
	movl 0x8(%esp), %eax
  80142c:	8b 44 24 08          	mov    0x8(%esp),%eax
	movl 0x10(%esp), %ebx
  801430:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	subl $4, %ebx
  801434:	83 eb 04             	sub    $0x4,%ebx
	movl %eax, (%ebx)
  801437:	89 03                	mov    %eax,(%ebx)
	//Note: you should modify the value before it's popped to %esp
	//      Otherwise, for some reason, the eflags will be wrong!!!
	movl %ebx, 0x10(%esp)
  801439:	89 5c 24 10          	mov    %ebx,0x10(%esp)
	popl %ebx
  80143d:	5b                   	pop    %ebx
	popl %eax
  80143e:	58                   	pop    %eax
	addl $4, %esp
  80143f:	83 c4 04             	add    $0x4,%esp
	popf
  801442:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  801443:	5c                   	pop    %esp
	//subl $4, %esp

	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  801444:	c3                   	ret    
  801445:	66 90                	xchg   %ax,%ax
  801447:	66 90                	xchg   %ax,%ax
  801449:	66 90                	xchg   %ax,%ax
  80144b:	66 90                	xchg   %ax,%ax
  80144d:	66 90                	xchg   %ax,%ax
  80144f:	90                   	nop

00801450 <__udivdi3>:
  801450:	55                   	push   %ebp
  801451:	57                   	push   %edi
  801452:	56                   	push   %esi
  801453:	83 ec 0c             	sub    $0xc,%esp
  801456:	8b 44 24 28          	mov    0x28(%esp),%eax
  80145a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  80145e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  801462:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  801466:	85 c0                	test   %eax,%eax
  801468:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80146c:	89 ea                	mov    %ebp,%edx
  80146e:	89 0c 24             	mov    %ecx,(%esp)
  801471:	75 2d                	jne    8014a0 <__udivdi3+0x50>
  801473:	39 e9                	cmp    %ebp,%ecx
  801475:	77 61                	ja     8014d8 <__udivdi3+0x88>
  801477:	85 c9                	test   %ecx,%ecx
  801479:	89 ce                	mov    %ecx,%esi
  80147b:	75 0b                	jne    801488 <__udivdi3+0x38>
  80147d:	b8 01 00 00 00       	mov    $0x1,%eax
  801482:	31 d2                	xor    %edx,%edx
  801484:	f7 f1                	div    %ecx
  801486:	89 c6                	mov    %eax,%esi
  801488:	31 d2                	xor    %edx,%edx
  80148a:	89 e8                	mov    %ebp,%eax
  80148c:	f7 f6                	div    %esi
  80148e:	89 c5                	mov    %eax,%ebp
  801490:	89 f8                	mov    %edi,%eax
  801492:	f7 f6                	div    %esi
  801494:	89 ea                	mov    %ebp,%edx
  801496:	83 c4 0c             	add    $0xc,%esp
  801499:	5e                   	pop    %esi
  80149a:	5f                   	pop    %edi
  80149b:	5d                   	pop    %ebp
  80149c:	c3                   	ret    
  80149d:	8d 76 00             	lea    0x0(%esi),%esi
  8014a0:	39 e8                	cmp    %ebp,%eax
  8014a2:	77 24                	ja     8014c8 <__udivdi3+0x78>
  8014a4:	0f bd e8             	bsr    %eax,%ebp
  8014a7:	83 f5 1f             	xor    $0x1f,%ebp
  8014aa:	75 3c                	jne    8014e8 <__udivdi3+0x98>
  8014ac:	8b 74 24 04          	mov    0x4(%esp),%esi
  8014b0:	39 34 24             	cmp    %esi,(%esp)
  8014b3:	0f 86 9f 00 00 00    	jbe    801558 <__udivdi3+0x108>
  8014b9:	39 d0                	cmp    %edx,%eax
  8014bb:	0f 82 97 00 00 00    	jb     801558 <__udivdi3+0x108>
  8014c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8014c8:	31 d2                	xor    %edx,%edx
  8014ca:	31 c0                	xor    %eax,%eax
  8014cc:	83 c4 0c             	add    $0xc,%esp
  8014cf:	5e                   	pop    %esi
  8014d0:	5f                   	pop    %edi
  8014d1:	5d                   	pop    %ebp
  8014d2:	c3                   	ret    
  8014d3:	90                   	nop
  8014d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8014d8:	89 f8                	mov    %edi,%eax
  8014da:	f7 f1                	div    %ecx
  8014dc:	31 d2                	xor    %edx,%edx
  8014de:	83 c4 0c             	add    $0xc,%esp
  8014e1:	5e                   	pop    %esi
  8014e2:	5f                   	pop    %edi
  8014e3:	5d                   	pop    %ebp
  8014e4:	c3                   	ret    
  8014e5:	8d 76 00             	lea    0x0(%esi),%esi
  8014e8:	89 e9                	mov    %ebp,%ecx
  8014ea:	8b 3c 24             	mov    (%esp),%edi
  8014ed:	d3 e0                	shl    %cl,%eax
  8014ef:	89 c6                	mov    %eax,%esi
  8014f1:	b8 20 00 00 00       	mov    $0x20,%eax
  8014f6:	29 e8                	sub    %ebp,%eax
  8014f8:	89 c1                	mov    %eax,%ecx
  8014fa:	d3 ef                	shr    %cl,%edi
  8014fc:	89 e9                	mov    %ebp,%ecx
  8014fe:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801502:	8b 3c 24             	mov    (%esp),%edi
  801505:	09 74 24 08          	or     %esi,0x8(%esp)
  801509:	89 d6                	mov    %edx,%esi
  80150b:	d3 e7                	shl    %cl,%edi
  80150d:	89 c1                	mov    %eax,%ecx
  80150f:	89 3c 24             	mov    %edi,(%esp)
  801512:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801516:	d3 ee                	shr    %cl,%esi
  801518:	89 e9                	mov    %ebp,%ecx
  80151a:	d3 e2                	shl    %cl,%edx
  80151c:	89 c1                	mov    %eax,%ecx
  80151e:	d3 ef                	shr    %cl,%edi
  801520:	09 d7                	or     %edx,%edi
  801522:	89 f2                	mov    %esi,%edx
  801524:	89 f8                	mov    %edi,%eax
  801526:	f7 74 24 08          	divl   0x8(%esp)
  80152a:	89 d6                	mov    %edx,%esi
  80152c:	89 c7                	mov    %eax,%edi
  80152e:	f7 24 24             	mull   (%esp)
  801531:	39 d6                	cmp    %edx,%esi
  801533:	89 14 24             	mov    %edx,(%esp)
  801536:	72 30                	jb     801568 <__udivdi3+0x118>
  801538:	8b 54 24 04          	mov    0x4(%esp),%edx
  80153c:	89 e9                	mov    %ebp,%ecx
  80153e:	d3 e2                	shl    %cl,%edx
  801540:	39 c2                	cmp    %eax,%edx
  801542:	73 05                	jae    801549 <__udivdi3+0xf9>
  801544:	3b 34 24             	cmp    (%esp),%esi
  801547:	74 1f                	je     801568 <__udivdi3+0x118>
  801549:	89 f8                	mov    %edi,%eax
  80154b:	31 d2                	xor    %edx,%edx
  80154d:	e9 7a ff ff ff       	jmp    8014cc <__udivdi3+0x7c>
  801552:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801558:	31 d2                	xor    %edx,%edx
  80155a:	b8 01 00 00 00       	mov    $0x1,%eax
  80155f:	e9 68 ff ff ff       	jmp    8014cc <__udivdi3+0x7c>
  801564:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801568:	8d 47 ff             	lea    -0x1(%edi),%eax
  80156b:	31 d2                	xor    %edx,%edx
  80156d:	83 c4 0c             	add    $0xc,%esp
  801570:	5e                   	pop    %esi
  801571:	5f                   	pop    %edi
  801572:	5d                   	pop    %ebp
  801573:	c3                   	ret    
  801574:	66 90                	xchg   %ax,%ax
  801576:	66 90                	xchg   %ax,%ax
  801578:	66 90                	xchg   %ax,%ax
  80157a:	66 90                	xchg   %ax,%ax
  80157c:	66 90                	xchg   %ax,%ax
  80157e:	66 90                	xchg   %ax,%ax

00801580 <__umoddi3>:
  801580:	55                   	push   %ebp
  801581:	57                   	push   %edi
  801582:	56                   	push   %esi
  801583:	83 ec 14             	sub    $0x14,%esp
  801586:	8b 44 24 28          	mov    0x28(%esp),%eax
  80158a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80158e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  801592:	89 c7                	mov    %eax,%edi
  801594:	89 44 24 04          	mov    %eax,0x4(%esp)
  801598:	8b 44 24 30          	mov    0x30(%esp),%eax
  80159c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8015a0:	89 34 24             	mov    %esi,(%esp)
  8015a3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8015a7:	85 c0                	test   %eax,%eax
  8015a9:	89 c2                	mov    %eax,%edx
  8015ab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8015af:	75 17                	jne    8015c8 <__umoddi3+0x48>
  8015b1:	39 fe                	cmp    %edi,%esi
  8015b3:	76 4b                	jbe    801600 <__umoddi3+0x80>
  8015b5:	89 c8                	mov    %ecx,%eax
  8015b7:	89 fa                	mov    %edi,%edx
  8015b9:	f7 f6                	div    %esi
  8015bb:	89 d0                	mov    %edx,%eax
  8015bd:	31 d2                	xor    %edx,%edx
  8015bf:	83 c4 14             	add    $0x14,%esp
  8015c2:	5e                   	pop    %esi
  8015c3:	5f                   	pop    %edi
  8015c4:	5d                   	pop    %ebp
  8015c5:	c3                   	ret    
  8015c6:	66 90                	xchg   %ax,%ax
  8015c8:	39 f8                	cmp    %edi,%eax
  8015ca:	77 54                	ja     801620 <__umoddi3+0xa0>
  8015cc:	0f bd e8             	bsr    %eax,%ebp
  8015cf:	83 f5 1f             	xor    $0x1f,%ebp
  8015d2:	75 5c                	jne    801630 <__umoddi3+0xb0>
  8015d4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8015d8:	39 3c 24             	cmp    %edi,(%esp)
  8015db:	0f 87 e7 00 00 00    	ja     8016c8 <__umoddi3+0x148>
  8015e1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8015e5:	29 f1                	sub    %esi,%ecx
  8015e7:	19 c7                	sbb    %eax,%edi
  8015e9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8015ed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8015f1:	8b 44 24 08          	mov    0x8(%esp),%eax
  8015f5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8015f9:	83 c4 14             	add    $0x14,%esp
  8015fc:	5e                   	pop    %esi
  8015fd:	5f                   	pop    %edi
  8015fe:	5d                   	pop    %ebp
  8015ff:	c3                   	ret    
  801600:	85 f6                	test   %esi,%esi
  801602:	89 f5                	mov    %esi,%ebp
  801604:	75 0b                	jne    801611 <__umoddi3+0x91>
  801606:	b8 01 00 00 00       	mov    $0x1,%eax
  80160b:	31 d2                	xor    %edx,%edx
  80160d:	f7 f6                	div    %esi
  80160f:	89 c5                	mov    %eax,%ebp
  801611:	8b 44 24 04          	mov    0x4(%esp),%eax
  801615:	31 d2                	xor    %edx,%edx
  801617:	f7 f5                	div    %ebp
  801619:	89 c8                	mov    %ecx,%eax
  80161b:	f7 f5                	div    %ebp
  80161d:	eb 9c                	jmp    8015bb <__umoddi3+0x3b>
  80161f:	90                   	nop
  801620:	89 c8                	mov    %ecx,%eax
  801622:	89 fa                	mov    %edi,%edx
  801624:	83 c4 14             	add    $0x14,%esp
  801627:	5e                   	pop    %esi
  801628:	5f                   	pop    %edi
  801629:	5d                   	pop    %ebp
  80162a:	c3                   	ret    
  80162b:	90                   	nop
  80162c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801630:	8b 04 24             	mov    (%esp),%eax
  801633:	be 20 00 00 00       	mov    $0x20,%esi
  801638:	89 e9                	mov    %ebp,%ecx
  80163a:	29 ee                	sub    %ebp,%esi
  80163c:	d3 e2                	shl    %cl,%edx
  80163e:	89 f1                	mov    %esi,%ecx
  801640:	d3 e8                	shr    %cl,%eax
  801642:	89 e9                	mov    %ebp,%ecx
  801644:	89 44 24 04          	mov    %eax,0x4(%esp)
  801648:	8b 04 24             	mov    (%esp),%eax
  80164b:	09 54 24 04          	or     %edx,0x4(%esp)
  80164f:	89 fa                	mov    %edi,%edx
  801651:	d3 e0                	shl    %cl,%eax
  801653:	89 f1                	mov    %esi,%ecx
  801655:	89 44 24 08          	mov    %eax,0x8(%esp)
  801659:	8b 44 24 10          	mov    0x10(%esp),%eax
  80165d:	d3 ea                	shr    %cl,%edx
  80165f:	89 e9                	mov    %ebp,%ecx
  801661:	d3 e7                	shl    %cl,%edi
  801663:	89 f1                	mov    %esi,%ecx
  801665:	d3 e8                	shr    %cl,%eax
  801667:	89 e9                	mov    %ebp,%ecx
  801669:	09 f8                	or     %edi,%eax
  80166b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80166f:	f7 74 24 04          	divl   0x4(%esp)
  801673:	d3 e7                	shl    %cl,%edi
  801675:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801679:	89 d7                	mov    %edx,%edi
  80167b:	f7 64 24 08          	mull   0x8(%esp)
  80167f:	39 d7                	cmp    %edx,%edi
  801681:	89 c1                	mov    %eax,%ecx
  801683:	89 14 24             	mov    %edx,(%esp)
  801686:	72 2c                	jb     8016b4 <__umoddi3+0x134>
  801688:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80168c:	72 22                	jb     8016b0 <__umoddi3+0x130>
  80168e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801692:	29 c8                	sub    %ecx,%eax
  801694:	19 d7                	sbb    %edx,%edi
  801696:	89 e9                	mov    %ebp,%ecx
  801698:	89 fa                	mov    %edi,%edx
  80169a:	d3 e8                	shr    %cl,%eax
  80169c:	89 f1                	mov    %esi,%ecx
  80169e:	d3 e2                	shl    %cl,%edx
  8016a0:	89 e9                	mov    %ebp,%ecx
  8016a2:	d3 ef                	shr    %cl,%edi
  8016a4:	09 d0                	or     %edx,%eax
  8016a6:	89 fa                	mov    %edi,%edx
  8016a8:	83 c4 14             	add    $0x14,%esp
  8016ab:	5e                   	pop    %esi
  8016ac:	5f                   	pop    %edi
  8016ad:	5d                   	pop    %ebp
  8016ae:	c3                   	ret    
  8016af:	90                   	nop
  8016b0:	39 d7                	cmp    %edx,%edi
  8016b2:	75 da                	jne    80168e <__umoddi3+0x10e>
  8016b4:	8b 14 24             	mov    (%esp),%edx
  8016b7:	89 c1                	mov    %eax,%ecx
  8016b9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  8016bd:	1b 54 24 04          	sbb    0x4(%esp),%edx
  8016c1:	eb cb                	jmp    80168e <__umoddi3+0x10e>
  8016c3:	90                   	nop
  8016c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8016c8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  8016cc:	0f 82 0f ff ff ff    	jb     8015e1 <__umoddi3+0x61>
  8016d2:	e9 1a ff ff ff       	jmp    8015f1 <__umoddi3+0x71>
