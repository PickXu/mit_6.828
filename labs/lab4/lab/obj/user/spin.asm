
obj/user/spin:     file format elf32-i386


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
  80002c:	e8 8e 00 00 00       	call   8000bf <libmain>
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

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	53                   	push   %ebx
  800044:	83 ec 14             	sub    $0x14,%esp
	envid_t env;

	cprintf("I am the parent.  Forking the child...\n");
  800047:	c7 04 24 80 16 80 00 	movl   $0x801680,(%esp)
  80004e:	e8 6b 01 00 00       	call   8001be <cprintf>
	if ((env = fork()) == 0) {
  800053:	e8 2a 10 00 00       	call   801082 <fork>
  800058:	89 c3                	mov    %eax,%ebx
  80005a:	85 c0                	test   %eax,%eax
  80005c:	75 0e                	jne    80006c <umain+0x2c>
		cprintf("I am the child.  Spinning...\n");
  80005e:	c7 04 24 f8 16 80 00 	movl   $0x8016f8,(%esp)
  800065:	e8 54 01 00 00       	call   8001be <cprintf>
  80006a:	eb fe                	jmp    80006a <umain+0x2a>
		while (1)
			/* do nothing */;
	}

	cprintf("I am the parent.  Running the child...\n");
  80006c:	c7 04 24 a8 16 80 00 	movl   $0x8016a8,(%esp)
  800073:	e8 46 01 00 00       	call   8001be <cprintf>
	sys_yield();
  800078:	e8 67 0b 00 00       	call   800be4 <sys_yield>
	sys_yield();
  80007d:	e8 62 0b 00 00       	call   800be4 <sys_yield>
	sys_yield();
  800082:	e8 5d 0b 00 00       	call   800be4 <sys_yield>
	sys_yield();
  800087:	e8 58 0b 00 00       	call   800be4 <sys_yield>
	sys_yield();
  80008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800090:	e8 4f 0b 00 00       	call   800be4 <sys_yield>
	sys_yield();
  800095:	e8 4a 0b 00 00       	call   800be4 <sys_yield>
	sys_yield();
  80009a:	e8 45 0b 00 00       	call   800be4 <sys_yield>
	sys_yield();
  80009f:	90                   	nop
  8000a0:	e8 3f 0b 00 00       	call   800be4 <sys_yield>

	cprintf("I am the parent.  Killing the child...\n");
  8000a5:	c7 04 24 d0 16 80 00 	movl   $0x8016d0,(%esp)
  8000ac:	e8 0d 01 00 00       	call   8001be <cprintf>
	sys_env_destroy(env);
  8000b1:	89 1c 24             	mov    %ebx,(%esp)
  8000b4:	e8 ba 0a 00 00       	call   800b73 <sys_env_destroy>
}
  8000b9:	83 c4 14             	add    $0x14,%esp
  8000bc:	5b                   	pop    %ebx
  8000bd:	5d                   	pop    %ebp
  8000be:	c3                   	ret    

008000bf <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000bf:	55                   	push   %ebp
  8000c0:	89 e5                	mov    %esp,%ebp
  8000c2:	56                   	push   %esi
  8000c3:	53                   	push   %ebx
  8000c4:	83 ec 10             	sub    $0x10,%esp
  8000c7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000ca:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  8000cd:	e8 f3 0a 00 00       	call   800bc5 <sys_getenvid>
	thisenv = envs+ENVX(envid);
  8000d2:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000d7:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8000da:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000df:	a3 04 20 80 00       	mov    %eax,0x802004
	
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000e4:	85 db                	test   %ebx,%ebx
  8000e6:	7e 07                	jle    8000ef <libmain+0x30>
		binaryname = argv[0];
  8000e8:	8b 06                	mov    (%esi),%eax
  8000ea:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000ef:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000f3:	89 1c 24             	mov    %ebx,(%esp)
  8000f6:	e8 45 ff ff ff       	call   800040 <umain>

	// exit gracefully
	exit();
  8000fb:	e8 07 00 00 00       	call   800107 <exit>
}
  800100:	83 c4 10             	add    $0x10,%esp
  800103:	5b                   	pop    %ebx
  800104:	5e                   	pop    %esi
  800105:	5d                   	pop    %ebp
  800106:	c3                   	ret    

00800107 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800107:	55                   	push   %ebp
  800108:	89 e5                	mov    %esp,%ebp
  80010a:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80010d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800114:	e8 5a 0a 00 00       	call   800b73 <sys_env_destroy>
}
  800119:	c9                   	leave  
  80011a:	c3                   	ret    

0080011b <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80011b:	55                   	push   %ebp
  80011c:	89 e5                	mov    %esp,%ebp
  80011e:	53                   	push   %ebx
  80011f:	83 ec 14             	sub    $0x14,%esp
  800122:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800125:	8b 13                	mov    (%ebx),%edx
  800127:	8d 42 01             	lea    0x1(%edx),%eax
  80012a:	89 03                	mov    %eax,(%ebx)
  80012c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80012f:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800133:	3d ff 00 00 00       	cmp    $0xff,%eax
  800138:	75 19                	jne    800153 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80013a:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800141:	00 
  800142:	8d 43 08             	lea    0x8(%ebx),%eax
  800145:	89 04 24             	mov    %eax,(%esp)
  800148:	e8 e9 09 00 00       	call   800b36 <sys_cputs>
		b->idx = 0;
  80014d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800153:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800157:	83 c4 14             	add    $0x14,%esp
  80015a:	5b                   	pop    %ebx
  80015b:	5d                   	pop    %ebp
  80015c:	c3                   	ret    

0080015d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80015d:	55                   	push   %ebp
  80015e:	89 e5                	mov    %esp,%ebp
  800160:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800166:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80016d:	00 00 00 
	b.cnt = 0;
  800170:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800177:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80017a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80017d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800181:	8b 45 08             	mov    0x8(%ebp),%eax
  800184:	89 44 24 08          	mov    %eax,0x8(%esp)
  800188:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80018e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800192:	c7 04 24 1b 01 80 00 	movl   $0x80011b,(%esp)
  800199:	e8 b0 01 00 00       	call   80034e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80019e:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8001a4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001a8:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ae:	89 04 24             	mov    %eax,(%esp)
  8001b1:	e8 80 09 00 00       	call   800b36 <sys_cputs>

	return b.cnt;
}
  8001b6:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001bc:	c9                   	leave  
  8001bd:	c3                   	ret    

008001be <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001be:	55                   	push   %ebp
  8001bf:	89 e5                	mov    %esp,%ebp
  8001c1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001c4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8001ce:	89 04 24             	mov    %eax,(%esp)
  8001d1:	e8 87 ff ff ff       	call   80015d <vcprintf>
	va_end(ap);

	return cnt;
}
  8001d6:	c9                   	leave  
  8001d7:	c3                   	ret    
  8001d8:	66 90                	xchg   %ax,%ax
  8001da:	66 90                	xchg   %ax,%ax
  8001dc:	66 90                	xchg   %ax,%ax
  8001de:	66 90                	xchg   %ax,%ax

008001e0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001e0:	55                   	push   %ebp
  8001e1:	89 e5                	mov    %esp,%ebp
  8001e3:	57                   	push   %edi
  8001e4:	56                   	push   %esi
  8001e5:	53                   	push   %ebx
  8001e6:	83 ec 3c             	sub    $0x3c,%esp
  8001e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8001ec:	89 d7                	mov    %edx,%edi
  8001ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8001f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001f7:	89 c3                	mov    %eax,%ebx
  8001f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8001fc:	8b 45 10             	mov    0x10(%ebp),%eax
  8001ff:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800202:	b9 00 00 00 00       	mov    $0x0,%ecx
  800207:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80020a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80020d:	39 d9                	cmp    %ebx,%ecx
  80020f:	72 05                	jb     800216 <printnum+0x36>
  800211:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800214:	77 69                	ja     80027f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800216:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800219:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80021d:	83 ee 01             	sub    $0x1,%esi
  800220:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800224:	89 44 24 08          	mov    %eax,0x8(%esp)
  800228:	8b 44 24 08          	mov    0x8(%esp),%eax
  80022c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800230:	89 c3                	mov    %eax,%ebx
  800232:	89 d6                	mov    %edx,%esi
  800234:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800237:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80023a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80023e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800242:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800245:	89 04 24             	mov    %eax,(%esp)
  800248:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80024b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024f:	e8 9c 11 00 00       	call   8013f0 <__udivdi3>
  800254:	89 d9                	mov    %ebx,%ecx
  800256:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80025a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80025e:	89 04 24             	mov    %eax,(%esp)
  800261:	89 54 24 04          	mov    %edx,0x4(%esp)
  800265:	89 fa                	mov    %edi,%edx
  800267:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80026a:	e8 71 ff ff ff       	call   8001e0 <printnum>
  80026f:	eb 1b                	jmp    80028c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800271:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800275:	8b 45 18             	mov    0x18(%ebp),%eax
  800278:	89 04 24             	mov    %eax,(%esp)
  80027b:	ff d3                	call   *%ebx
  80027d:	eb 03                	jmp    800282 <printnum+0xa2>
  80027f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800282:	83 ee 01             	sub    $0x1,%esi
  800285:	85 f6                	test   %esi,%esi
  800287:	7f e8                	jg     800271 <printnum+0x91>
  800289:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800290:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800294:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800297:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80029a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80029e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8002a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002a5:	89 04 24             	mov    %eax,(%esp)
  8002a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002af:	e8 6c 12 00 00       	call   801520 <__umoddi3>
  8002b4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002b8:	0f be 80 20 17 80 00 	movsbl 0x801720(%eax),%eax
  8002bf:	89 04 24             	mov    %eax,(%esp)
  8002c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002c5:	ff d0                	call   *%eax
}
  8002c7:	83 c4 3c             	add    $0x3c,%esp
  8002ca:	5b                   	pop    %ebx
  8002cb:	5e                   	pop    %esi
  8002cc:	5f                   	pop    %edi
  8002cd:	5d                   	pop    %ebp
  8002ce:	c3                   	ret    

008002cf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002cf:	55                   	push   %ebp
  8002d0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d2:	83 fa 01             	cmp    $0x1,%edx
  8002d5:	7e 0e                	jle    8002e5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002d7:	8b 10                	mov    (%eax),%edx
  8002d9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002dc:	89 08                	mov    %ecx,(%eax)
  8002de:	8b 02                	mov    (%edx),%eax
  8002e0:	8b 52 04             	mov    0x4(%edx),%edx
  8002e3:	eb 22                	jmp    800307 <getuint+0x38>
	else if (lflag)
  8002e5:	85 d2                	test   %edx,%edx
  8002e7:	74 10                	je     8002f9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002e9:	8b 10                	mov    (%eax),%edx
  8002eb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ee:	89 08                	mov    %ecx,(%eax)
  8002f0:	8b 02                	mov    (%edx),%eax
  8002f2:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f7:	eb 0e                	jmp    800307 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002f9:	8b 10                	mov    (%eax),%edx
  8002fb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002fe:	89 08                	mov    %ecx,(%eax)
  800300:	8b 02                	mov    (%edx),%eax
  800302:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800307:	5d                   	pop    %ebp
  800308:	c3                   	ret    

00800309 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800309:	55                   	push   %ebp
  80030a:	89 e5                	mov    %esp,%ebp
  80030c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80030f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800313:	8b 10                	mov    (%eax),%edx
  800315:	3b 50 04             	cmp    0x4(%eax),%edx
  800318:	73 0a                	jae    800324 <sprintputch+0x1b>
		*b->buf++ = ch;
  80031a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80031d:	89 08                	mov    %ecx,(%eax)
  80031f:	8b 45 08             	mov    0x8(%ebp),%eax
  800322:	88 02                	mov    %al,(%edx)
}
  800324:	5d                   	pop    %ebp
  800325:	c3                   	ret    

00800326 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800326:	55                   	push   %ebp
  800327:	89 e5                	mov    %esp,%ebp
  800329:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80032c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80032f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800333:	8b 45 10             	mov    0x10(%ebp),%eax
  800336:	89 44 24 08          	mov    %eax,0x8(%esp)
  80033a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80033d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800341:	8b 45 08             	mov    0x8(%ebp),%eax
  800344:	89 04 24             	mov    %eax,(%esp)
  800347:	e8 02 00 00 00       	call   80034e <vprintfmt>
	va_end(ap);
}
  80034c:	c9                   	leave  
  80034d:	c3                   	ret    

0080034e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80034e:	55                   	push   %ebp
  80034f:	89 e5                	mov    %esp,%ebp
  800351:	57                   	push   %edi
  800352:	56                   	push   %esi
  800353:	53                   	push   %ebx
  800354:	83 ec 3c             	sub    $0x3c,%esp
  800357:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80035a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80035d:	eb 14                	jmp    800373 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80035f:	85 c0                	test   %eax,%eax
  800361:	0f 84 b3 03 00 00    	je     80071a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800367:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80036b:	89 04 24             	mov    %eax,(%esp)
  80036e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800371:	89 f3                	mov    %esi,%ebx
  800373:	8d 73 01             	lea    0x1(%ebx),%esi
  800376:	0f b6 03             	movzbl (%ebx),%eax
  800379:	83 f8 25             	cmp    $0x25,%eax
  80037c:	75 e1                	jne    80035f <vprintfmt+0x11>
  80037e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800382:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800389:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800390:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800397:	ba 00 00 00 00       	mov    $0x0,%edx
  80039c:	eb 1d                	jmp    8003bb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003a0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  8003a4:	eb 15                	jmp    8003bb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003a8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  8003ac:	eb 0d                	jmp    8003bb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8003ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003b1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8003b4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bb:	8d 5e 01             	lea    0x1(%esi),%ebx
  8003be:	0f b6 0e             	movzbl (%esi),%ecx
  8003c1:	0f b6 c1             	movzbl %cl,%eax
  8003c4:	83 e9 23             	sub    $0x23,%ecx
  8003c7:	80 f9 55             	cmp    $0x55,%cl
  8003ca:	0f 87 2a 03 00 00    	ja     8006fa <vprintfmt+0x3ac>
  8003d0:	0f b6 c9             	movzbl %cl,%ecx
  8003d3:	ff 24 8d e0 17 80 00 	jmp    *0x8017e0(,%ecx,4)
  8003da:	89 de                	mov    %ebx,%esi
  8003dc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003e1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8003e4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8003e8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8003eb:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8003ee:	83 fb 09             	cmp    $0x9,%ebx
  8003f1:	77 36                	ja     800429 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003f3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003f6:	eb e9                	jmp    8003e1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003f8:	8b 45 14             	mov    0x14(%ebp),%eax
  8003fb:	8d 48 04             	lea    0x4(%eax),%ecx
  8003fe:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800401:	8b 00                	mov    (%eax),%eax
  800403:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800406:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800408:	eb 22                	jmp    80042c <vprintfmt+0xde>
  80040a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80040d:	85 c9                	test   %ecx,%ecx
  80040f:	b8 00 00 00 00       	mov    $0x0,%eax
  800414:	0f 49 c1             	cmovns %ecx,%eax
  800417:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041a:	89 de                	mov    %ebx,%esi
  80041c:	eb 9d                	jmp    8003bb <vprintfmt+0x6d>
  80041e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800420:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800427:	eb 92                	jmp    8003bb <vprintfmt+0x6d>
  800429:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80042c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800430:	79 89                	jns    8003bb <vprintfmt+0x6d>
  800432:	e9 77 ff ff ff       	jmp    8003ae <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800437:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80043c:	e9 7a ff ff ff       	jmp    8003bb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800441:	8b 45 14             	mov    0x14(%ebp),%eax
  800444:	8d 50 04             	lea    0x4(%eax),%edx
  800447:	89 55 14             	mov    %edx,0x14(%ebp)
  80044a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80044e:	8b 00                	mov    (%eax),%eax
  800450:	89 04 24             	mov    %eax,(%esp)
  800453:	ff 55 08             	call   *0x8(%ebp)
			break;
  800456:	e9 18 ff ff ff       	jmp    800373 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80045b:	8b 45 14             	mov    0x14(%ebp),%eax
  80045e:	8d 50 04             	lea    0x4(%eax),%edx
  800461:	89 55 14             	mov    %edx,0x14(%ebp)
  800464:	8b 00                	mov    (%eax),%eax
  800466:	99                   	cltd   
  800467:	31 d0                	xor    %edx,%eax
  800469:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80046b:	83 f8 09             	cmp    $0x9,%eax
  80046e:	7f 0b                	jg     80047b <vprintfmt+0x12d>
  800470:	8b 14 85 40 19 80 00 	mov    0x801940(,%eax,4),%edx
  800477:	85 d2                	test   %edx,%edx
  800479:	75 20                	jne    80049b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80047b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80047f:	c7 44 24 08 38 17 80 	movl   $0x801738,0x8(%esp)
  800486:	00 
  800487:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80048b:	8b 45 08             	mov    0x8(%ebp),%eax
  80048e:	89 04 24             	mov    %eax,(%esp)
  800491:	e8 90 fe ff ff       	call   800326 <printfmt>
  800496:	e9 d8 fe ff ff       	jmp    800373 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80049b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80049f:	c7 44 24 08 41 17 80 	movl   $0x801741,0x8(%esp)
  8004a6:	00 
  8004a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004ab:	8b 45 08             	mov    0x8(%ebp),%eax
  8004ae:	89 04 24             	mov    %eax,(%esp)
  8004b1:	e8 70 fe ff ff       	call   800326 <printfmt>
  8004b6:	e9 b8 fe ff ff       	jmp    800373 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8004be:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c7:	8d 50 04             	lea    0x4(%eax),%edx
  8004ca:	89 55 14             	mov    %edx,0x14(%ebp)
  8004cd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8004cf:	85 f6                	test   %esi,%esi
  8004d1:	b8 31 17 80 00       	mov    $0x801731,%eax
  8004d6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  8004d9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8004dd:	0f 84 97 00 00 00    	je     80057a <vprintfmt+0x22c>
  8004e3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8004e7:	0f 8e 9b 00 00 00    	jle    800588 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ed:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004f1:	89 34 24             	mov    %esi,(%esp)
  8004f4:	e8 cf 02 00 00       	call   8007c8 <strnlen>
  8004f9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004fc:	29 c2                	sub    %eax,%edx
  8004fe:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800501:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800505:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800508:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80050b:	8b 75 08             	mov    0x8(%ebp),%esi
  80050e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800511:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800513:	eb 0f                	jmp    800524 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800515:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800519:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80051c:	89 04 24             	mov    %eax,(%esp)
  80051f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800521:	83 eb 01             	sub    $0x1,%ebx
  800524:	85 db                	test   %ebx,%ebx
  800526:	7f ed                	jg     800515 <vprintfmt+0x1c7>
  800528:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80052b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80052e:	85 d2                	test   %edx,%edx
  800530:	b8 00 00 00 00       	mov    $0x0,%eax
  800535:	0f 49 c2             	cmovns %edx,%eax
  800538:	29 c2                	sub    %eax,%edx
  80053a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80053d:	89 d7                	mov    %edx,%edi
  80053f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800542:	eb 50                	jmp    800594 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800544:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800548:	74 1e                	je     800568 <vprintfmt+0x21a>
  80054a:	0f be d2             	movsbl %dl,%edx
  80054d:	83 ea 20             	sub    $0x20,%edx
  800550:	83 fa 5e             	cmp    $0x5e,%edx
  800553:	76 13                	jbe    800568 <vprintfmt+0x21a>
					putch('?', putdat);
  800555:	8b 45 0c             	mov    0xc(%ebp),%eax
  800558:	89 44 24 04          	mov    %eax,0x4(%esp)
  80055c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800563:	ff 55 08             	call   *0x8(%ebp)
  800566:	eb 0d                	jmp    800575 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800568:	8b 55 0c             	mov    0xc(%ebp),%edx
  80056b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80056f:	89 04 24             	mov    %eax,(%esp)
  800572:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800575:	83 ef 01             	sub    $0x1,%edi
  800578:	eb 1a                	jmp    800594 <vprintfmt+0x246>
  80057a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80057d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800580:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800583:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800586:	eb 0c                	jmp    800594 <vprintfmt+0x246>
  800588:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80058b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80058e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800591:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800594:	83 c6 01             	add    $0x1,%esi
  800597:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80059b:	0f be c2             	movsbl %dl,%eax
  80059e:	85 c0                	test   %eax,%eax
  8005a0:	74 27                	je     8005c9 <vprintfmt+0x27b>
  8005a2:	85 db                	test   %ebx,%ebx
  8005a4:	78 9e                	js     800544 <vprintfmt+0x1f6>
  8005a6:	83 eb 01             	sub    $0x1,%ebx
  8005a9:	79 99                	jns    800544 <vprintfmt+0x1f6>
  8005ab:	89 f8                	mov    %edi,%eax
  8005ad:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8005b0:	8b 75 08             	mov    0x8(%ebp),%esi
  8005b3:	89 c3                	mov    %eax,%ebx
  8005b5:	eb 1a                	jmp    8005d1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005bb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8005c2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005c4:	83 eb 01             	sub    $0x1,%ebx
  8005c7:	eb 08                	jmp    8005d1 <vprintfmt+0x283>
  8005c9:	89 fb                	mov    %edi,%ebx
  8005cb:	8b 75 08             	mov    0x8(%ebp),%esi
  8005ce:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8005d1:	85 db                	test   %ebx,%ebx
  8005d3:	7f e2                	jg     8005b7 <vprintfmt+0x269>
  8005d5:	89 75 08             	mov    %esi,0x8(%ebp)
  8005d8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8005db:	e9 93 fd ff ff       	jmp    800373 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005e0:	83 fa 01             	cmp    $0x1,%edx
  8005e3:	7e 16                	jle    8005fb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  8005e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e8:	8d 50 08             	lea    0x8(%eax),%edx
  8005eb:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ee:	8b 50 04             	mov    0x4(%eax),%edx
  8005f1:	8b 00                	mov    (%eax),%eax
  8005f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005f6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8005f9:	eb 32                	jmp    80062d <vprintfmt+0x2df>
	else if (lflag)
  8005fb:	85 d2                	test   %edx,%edx
  8005fd:	74 18                	je     800617 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8005ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800602:	8d 50 04             	lea    0x4(%eax),%edx
  800605:	89 55 14             	mov    %edx,0x14(%ebp)
  800608:	8b 30                	mov    (%eax),%esi
  80060a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80060d:	89 f0                	mov    %esi,%eax
  80060f:	c1 f8 1f             	sar    $0x1f,%eax
  800612:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800615:	eb 16                	jmp    80062d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800617:	8b 45 14             	mov    0x14(%ebp),%eax
  80061a:	8d 50 04             	lea    0x4(%eax),%edx
  80061d:	89 55 14             	mov    %edx,0x14(%ebp)
  800620:	8b 30                	mov    (%eax),%esi
  800622:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800625:	89 f0                	mov    %esi,%eax
  800627:	c1 f8 1f             	sar    $0x1f,%eax
  80062a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80062d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800630:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800633:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800638:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80063c:	0f 89 80 00 00 00    	jns    8006c2 <vprintfmt+0x374>
				putch('-', putdat);
  800642:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800646:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80064d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800650:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800653:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800656:	f7 d8                	neg    %eax
  800658:	83 d2 00             	adc    $0x0,%edx
  80065b:	f7 da                	neg    %edx
			}
			base = 10;
  80065d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800662:	eb 5e                	jmp    8006c2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800664:	8d 45 14             	lea    0x14(%ebp),%eax
  800667:	e8 63 fc ff ff       	call   8002cf <getuint>
			base = 10;
  80066c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800671:	eb 4f                	jmp    8006c2 <vprintfmt+0x374>
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint (&ap, lflag);
  800673:	8d 45 14             	lea    0x14(%ebp),%eax
  800676:	e8 54 fc ff ff       	call   8002cf <getuint>
			base = 8;
  80067b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800680:	eb 40                	jmp    8006c2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800682:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800686:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80068d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800690:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800694:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80069b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80069e:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a1:	8d 50 04             	lea    0x4(%eax),%edx
  8006a4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006a7:	8b 00                	mov    (%eax),%eax
  8006a9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006ae:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006b3:	eb 0d                	jmp    8006c2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006b5:	8d 45 14             	lea    0x14(%ebp),%eax
  8006b8:	e8 12 fc ff ff       	call   8002cf <getuint>
			base = 16;
  8006bd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006c2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8006c6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8006ca:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006cd:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8006d1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8006d5:	89 04 24             	mov    %eax,(%esp)
  8006d8:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006dc:	89 fa                	mov    %edi,%edx
  8006de:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e1:	e8 fa fa ff ff       	call   8001e0 <printnum>
			break;
  8006e6:	e9 88 fc ff ff       	jmp    800373 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006eb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006ef:	89 04 24             	mov    %eax,(%esp)
  8006f2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8006f5:	e9 79 fc ff ff       	jmp    800373 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006fe:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800705:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800708:	89 f3                	mov    %esi,%ebx
  80070a:	eb 03                	jmp    80070f <vprintfmt+0x3c1>
  80070c:	83 eb 01             	sub    $0x1,%ebx
  80070f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800713:	75 f7                	jne    80070c <vprintfmt+0x3be>
  800715:	e9 59 fc ff ff       	jmp    800373 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80071a:	83 c4 3c             	add    $0x3c,%esp
  80071d:	5b                   	pop    %ebx
  80071e:	5e                   	pop    %esi
  80071f:	5f                   	pop    %edi
  800720:	5d                   	pop    %ebp
  800721:	c3                   	ret    

00800722 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800722:	55                   	push   %ebp
  800723:	89 e5                	mov    %esp,%ebp
  800725:	83 ec 28             	sub    $0x28,%esp
  800728:	8b 45 08             	mov    0x8(%ebp),%eax
  80072b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80072e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800731:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800735:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800738:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80073f:	85 c0                	test   %eax,%eax
  800741:	74 30                	je     800773 <vsnprintf+0x51>
  800743:	85 d2                	test   %edx,%edx
  800745:	7e 2c                	jle    800773 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800747:	8b 45 14             	mov    0x14(%ebp),%eax
  80074a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80074e:	8b 45 10             	mov    0x10(%ebp),%eax
  800751:	89 44 24 08          	mov    %eax,0x8(%esp)
  800755:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800758:	89 44 24 04          	mov    %eax,0x4(%esp)
  80075c:	c7 04 24 09 03 80 00 	movl   $0x800309,(%esp)
  800763:	e8 e6 fb ff ff       	call   80034e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800768:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80076b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80076e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800771:	eb 05                	jmp    800778 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800773:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800778:	c9                   	leave  
  800779:	c3                   	ret    

0080077a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80077a:	55                   	push   %ebp
  80077b:	89 e5                	mov    %esp,%ebp
  80077d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800780:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800783:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800787:	8b 45 10             	mov    0x10(%ebp),%eax
  80078a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80078e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800791:	89 44 24 04          	mov    %eax,0x4(%esp)
  800795:	8b 45 08             	mov    0x8(%ebp),%eax
  800798:	89 04 24             	mov    %eax,(%esp)
  80079b:	e8 82 ff ff ff       	call   800722 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007a0:	c9                   	leave  
  8007a1:	c3                   	ret    
  8007a2:	66 90                	xchg   %ax,%ax
  8007a4:	66 90                	xchg   %ax,%ax
  8007a6:	66 90                	xchg   %ax,%ax
  8007a8:	66 90                	xchg   %ax,%ax
  8007aa:	66 90                	xchg   %ax,%ax
  8007ac:	66 90                	xchg   %ax,%ax
  8007ae:	66 90                	xchg   %ax,%ax

008007b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007b0:	55                   	push   %ebp
  8007b1:	89 e5                	mov    %esp,%ebp
  8007b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007b6:	b8 00 00 00 00       	mov    $0x0,%eax
  8007bb:	eb 03                	jmp    8007c0 <strlen+0x10>
		n++;
  8007bd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007c0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007c4:	75 f7                	jne    8007bd <strlen+0xd>
		n++;
	return n;
}
  8007c6:	5d                   	pop    %ebp
  8007c7:	c3                   	ret    

008007c8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007c8:	55                   	push   %ebp
  8007c9:	89 e5                	mov    %esp,%ebp
  8007cb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007ce:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007d1:	b8 00 00 00 00       	mov    $0x0,%eax
  8007d6:	eb 03                	jmp    8007db <strnlen+0x13>
		n++;
  8007d8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007db:	39 d0                	cmp    %edx,%eax
  8007dd:	74 06                	je     8007e5 <strnlen+0x1d>
  8007df:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8007e3:	75 f3                	jne    8007d8 <strnlen+0x10>
		n++;
	return n;
}
  8007e5:	5d                   	pop    %ebp
  8007e6:	c3                   	ret    

008007e7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007e7:	55                   	push   %ebp
  8007e8:	89 e5                	mov    %esp,%ebp
  8007ea:	53                   	push   %ebx
  8007eb:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007f1:	89 c2                	mov    %eax,%edx
  8007f3:	83 c2 01             	add    $0x1,%edx
  8007f6:	83 c1 01             	add    $0x1,%ecx
  8007f9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007fd:	88 5a ff             	mov    %bl,-0x1(%edx)
  800800:	84 db                	test   %bl,%bl
  800802:	75 ef                	jne    8007f3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800804:	5b                   	pop    %ebx
  800805:	5d                   	pop    %ebp
  800806:	c3                   	ret    

00800807 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800807:	55                   	push   %ebp
  800808:	89 e5                	mov    %esp,%ebp
  80080a:	53                   	push   %ebx
  80080b:	83 ec 08             	sub    $0x8,%esp
  80080e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800811:	89 1c 24             	mov    %ebx,(%esp)
  800814:	e8 97 ff ff ff       	call   8007b0 <strlen>
	strcpy(dst + len, src);
  800819:	8b 55 0c             	mov    0xc(%ebp),%edx
  80081c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800820:	01 d8                	add    %ebx,%eax
  800822:	89 04 24             	mov    %eax,(%esp)
  800825:	e8 bd ff ff ff       	call   8007e7 <strcpy>
	return dst;
}
  80082a:	89 d8                	mov    %ebx,%eax
  80082c:	83 c4 08             	add    $0x8,%esp
  80082f:	5b                   	pop    %ebx
  800830:	5d                   	pop    %ebp
  800831:	c3                   	ret    

00800832 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800832:	55                   	push   %ebp
  800833:	89 e5                	mov    %esp,%ebp
  800835:	56                   	push   %esi
  800836:	53                   	push   %ebx
  800837:	8b 75 08             	mov    0x8(%ebp),%esi
  80083a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80083d:	89 f3                	mov    %esi,%ebx
  80083f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800842:	89 f2                	mov    %esi,%edx
  800844:	eb 0f                	jmp    800855 <strncpy+0x23>
		*dst++ = *src;
  800846:	83 c2 01             	add    $0x1,%edx
  800849:	0f b6 01             	movzbl (%ecx),%eax
  80084c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80084f:	80 39 01             	cmpb   $0x1,(%ecx)
  800852:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800855:	39 da                	cmp    %ebx,%edx
  800857:	75 ed                	jne    800846 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800859:	89 f0                	mov    %esi,%eax
  80085b:	5b                   	pop    %ebx
  80085c:	5e                   	pop    %esi
  80085d:	5d                   	pop    %ebp
  80085e:	c3                   	ret    

0080085f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80085f:	55                   	push   %ebp
  800860:	89 e5                	mov    %esp,%ebp
  800862:	56                   	push   %esi
  800863:	53                   	push   %ebx
  800864:	8b 75 08             	mov    0x8(%ebp),%esi
  800867:	8b 55 0c             	mov    0xc(%ebp),%edx
  80086a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80086d:	89 f0                	mov    %esi,%eax
  80086f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800873:	85 c9                	test   %ecx,%ecx
  800875:	75 0b                	jne    800882 <strlcpy+0x23>
  800877:	eb 1d                	jmp    800896 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800879:	83 c0 01             	add    $0x1,%eax
  80087c:	83 c2 01             	add    $0x1,%edx
  80087f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800882:	39 d8                	cmp    %ebx,%eax
  800884:	74 0b                	je     800891 <strlcpy+0x32>
  800886:	0f b6 0a             	movzbl (%edx),%ecx
  800889:	84 c9                	test   %cl,%cl
  80088b:	75 ec                	jne    800879 <strlcpy+0x1a>
  80088d:	89 c2                	mov    %eax,%edx
  80088f:	eb 02                	jmp    800893 <strlcpy+0x34>
  800891:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800893:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800896:	29 f0                	sub    %esi,%eax
}
  800898:	5b                   	pop    %ebx
  800899:	5e                   	pop    %esi
  80089a:	5d                   	pop    %ebp
  80089b:	c3                   	ret    

0080089c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80089c:	55                   	push   %ebp
  80089d:	89 e5                	mov    %esp,%ebp
  80089f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008a2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008a5:	eb 06                	jmp    8008ad <strcmp+0x11>
		p++, q++;
  8008a7:	83 c1 01             	add    $0x1,%ecx
  8008aa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008ad:	0f b6 01             	movzbl (%ecx),%eax
  8008b0:	84 c0                	test   %al,%al
  8008b2:	74 04                	je     8008b8 <strcmp+0x1c>
  8008b4:	3a 02                	cmp    (%edx),%al
  8008b6:	74 ef                	je     8008a7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008b8:	0f b6 c0             	movzbl %al,%eax
  8008bb:	0f b6 12             	movzbl (%edx),%edx
  8008be:	29 d0                	sub    %edx,%eax
}
  8008c0:	5d                   	pop    %ebp
  8008c1:	c3                   	ret    

008008c2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008c2:	55                   	push   %ebp
  8008c3:	89 e5                	mov    %esp,%ebp
  8008c5:	53                   	push   %ebx
  8008c6:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008cc:	89 c3                	mov    %eax,%ebx
  8008ce:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008d1:	eb 06                	jmp    8008d9 <strncmp+0x17>
		n--, p++, q++;
  8008d3:	83 c0 01             	add    $0x1,%eax
  8008d6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008d9:	39 d8                	cmp    %ebx,%eax
  8008db:	74 15                	je     8008f2 <strncmp+0x30>
  8008dd:	0f b6 08             	movzbl (%eax),%ecx
  8008e0:	84 c9                	test   %cl,%cl
  8008e2:	74 04                	je     8008e8 <strncmp+0x26>
  8008e4:	3a 0a                	cmp    (%edx),%cl
  8008e6:	74 eb                	je     8008d3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008e8:	0f b6 00             	movzbl (%eax),%eax
  8008eb:	0f b6 12             	movzbl (%edx),%edx
  8008ee:	29 d0                	sub    %edx,%eax
  8008f0:	eb 05                	jmp    8008f7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008f2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008f7:	5b                   	pop    %ebx
  8008f8:	5d                   	pop    %ebp
  8008f9:	c3                   	ret    

008008fa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008fa:	55                   	push   %ebp
  8008fb:	89 e5                	mov    %esp,%ebp
  8008fd:	8b 45 08             	mov    0x8(%ebp),%eax
  800900:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800904:	eb 07                	jmp    80090d <strchr+0x13>
		if (*s == c)
  800906:	38 ca                	cmp    %cl,%dl
  800908:	74 0f                	je     800919 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80090a:	83 c0 01             	add    $0x1,%eax
  80090d:	0f b6 10             	movzbl (%eax),%edx
  800910:	84 d2                	test   %dl,%dl
  800912:	75 f2                	jne    800906 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800914:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800919:	5d                   	pop    %ebp
  80091a:	c3                   	ret    

0080091b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80091b:	55                   	push   %ebp
  80091c:	89 e5                	mov    %esp,%ebp
  80091e:	8b 45 08             	mov    0x8(%ebp),%eax
  800921:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800925:	eb 07                	jmp    80092e <strfind+0x13>
		if (*s == c)
  800927:	38 ca                	cmp    %cl,%dl
  800929:	74 0a                	je     800935 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80092b:	83 c0 01             	add    $0x1,%eax
  80092e:	0f b6 10             	movzbl (%eax),%edx
  800931:	84 d2                	test   %dl,%dl
  800933:	75 f2                	jne    800927 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800935:	5d                   	pop    %ebp
  800936:	c3                   	ret    

00800937 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800937:	55                   	push   %ebp
  800938:	89 e5                	mov    %esp,%ebp
  80093a:	57                   	push   %edi
  80093b:	56                   	push   %esi
  80093c:	53                   	push   %ebx
  80093d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800940:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800943:	85 c9                	test   %ecx,%ecx
  800945:	74 36                	je     80097d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800947:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80094d:	75 28                	jne    800977 <memset+0x40>
  80094f:	f6 c1 03             	test   $0x3,%cl
  800952:	75 23                	jne    800977 <memset+0x40>
		c &= 0xFF;
  800954:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800958:	89 d3                	mov    %edx,%ebx
  80095a:	c1 e3 08             	shl    $0x8,%ebx
  80095d:	89 d6                	mov    %edx,%esi
  80095f:	c1 e6 18             	shl    $0x18,%esi
  800962:	89 d0                	mov    %edx,%eax
  800964:	c1 e0 10             	shl    $0x10,%eax
  800967:	09 f0                	or     %esi,%eax
  800969:	09 c2                	or     %eax,%edx
  80096b:	89 d0                	mov    %edx,%eax
  80096d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  80096f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800972:	fc                   	cld    
  800973:	f3 ab                	rep stos %eax,%es:(%edi)
  800975:	eb 06                	jmp    80097d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800977:	8b 45 0c             	mov    0xc(%ebp),%eax
  80097a:	fc                   	cld    
  80097b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80097d:	89 f8                	mov    %edi,%eax
  80097f:	5b                   	pop    %ebx
  800980:	5e                   	pop    %esi
  800981:	5f                   	pop    %edi
  800982:	5d                   	pop    %ebp
  800983:	c3                   	ret    

00800984 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800984:	55                   	push   %ebp
  800985:	89 e5                	mov    %esp,%ebp
  800987:	57                   	push   %edi
  800988:	56                   	push   %esi
  800989:	8b 45 08             	mov    0x8(%ebp),%eax
  80098c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80098f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800992:	39 c6                	cmp    %eax,%esi
  800994:	73 35                	jae    8009cb <memmove+0x47>
  800996:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800999:	39 d0                	cmp    %edx,%eax
  80099b:	73 2e                	jae    8009cb <memmove+0x47>
		s += n;
		d += n;
  80099d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  8009a0:	89 d6                	mov    %edx,%esi
  8009a2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009a4:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009aa:	75 13                	jne    8009bf <memmove+0x3b>
  8009ac:	f6 c1 03             	test   $0x3,%cl
  8009af:	75 0e                	jne    8009bf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8009b1:	83 ef 04             	sub    $0x4,%edi
  8009b4:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009b7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  8009ba:	fd                   	std    
  8009bb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009bd:	eb 09                	jmp    8009c8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  8009bf:	83 ef 01             	sub    $0x1,%edi
  8009c2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009c5:	fd                   	std    
  8009c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009c8:	fc                   	cld    
  8009c9:	eb 1d                	jmp    8009e8 <memmove+0x64>
  8009cb:	89 f2                	mov    %esi,%edx
  8009cd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009cf:	f6 c2 03             	test   $0x3,%dl
  8009d2:	75 0f                	jne    8009e3 <memmove+0x5f>
  8009d4:	f6 c1 03             	test   $0x3,%cl
  8009d7:	75 0a                	jne    8009e3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  8009d9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  8009dc:	89 c7                	mov    %eax,%edi
  8009de:	fc                   	cld    
  8009df:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009e1:	eb 05                	jmp    8009e8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009e3:	89 c7                	mov    %eax,%edi
  8009e5:	fc                   	cld    
  8009e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009e8:	5e                   	pop    %esi
  8009e9:	5f                   	pop    %edi
  8009ea:	5d                   	pop    %ebp
  8009eb:	c3                   	ret    

008009ec <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009ec:	55                   	push   %ebp
  8009ed:	89 e5                	mov    %esp,%ebp
  8009ef:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  8009f2:	8b 45 10             	mov    0x10(%ebp),%eax
  8009f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8009f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a00:	8b 45 08             	mov    0x8(%ebp),%eax
  800a03:	89 04 24             	mov    %eax,(%esp)
  800a06:	e8 79 ff ff ff       	call   800984 <memmove>
}
  800a0b:	c9                   	leave  
  800a0c:	c3                   	ret    

00800a0d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a0d:	55                   	push   %ebp
  800a0e:	89 e5                	mov    %esp,%ebp
  800a10:	56                   	push   %esi
  800a11:	53                   	push   %ebx
  800a12:	8b 55 08             	mov    0x8(%ebp),%edx
  800a15:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a18:	89 d6                	mov    %edx,%esi
  800a1a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a1d:	eb 1a                	jmp    800a39 <memcmp+0x2c>
		if (*s1 != *s2)
  800a1f:	0f b6 02             	movzbl (%edx),%eax
  800a22:	0f b6 19             	movzbl (%ecx),%ebx
  800a25:	38 d8                	cmp    %bl,%al
  800a27:	74 0a                	je     800a33 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a29:	0f b6 c0             	movzbl %al,%eax
  800a2c:	0f b6 db             	movzbl %bl,%ebx
  800a2f:	29 d8                	sub    %ebx,%eax
  800a31:	eb 0f                	jmp    800a42 <memcmp+0x35>
		s1++, s2++;
  800a33:	83 c2 01             	add    $0x1,%edx
  800a36:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a39:	39 f2                	cmp    %esi,%edx
  800a3b:	75 e2                	jne    800a1f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a3d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a42:	5b                   	pop    %ebx
  800a43:	5e                   	pop    %esi
  800a44:	5d                   	pop    %ebp
  800a45:	c3                   	ret    

00800a46 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a46:	55                   	push   %ebp
  800a47:	89 e5                	mov    %esp,%ebp
  800a49:	8b 45 08             	mov    0x8(%ebp),%eax
  800a4c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a4f:	89 c2                	mov    %eax,%edx
  800a51:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a54:	eb 07                	jmp    800a5d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a56:	38 08                	cmp    %cl,(%eax)
  800a58:	74 07                	je     800a61 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a5a:	83 c0 01             	add    $0x1,%eax
  800a5d:	39 d0                	cmp    %edx,%eax
  800a5f:	72 f5                	jb     800a56 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a61:	5d                   	pop    %ebp
  800a62:	c3                   	ret    

00800a63 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a63:	55                   	push   %ebp
  800a64:	89 e5                	mov    %esp,%ebp
  800a66:	57                   	push   %edi
  800a67:	56                   	push   %esi
  800a68:	53                   	push   %ebx
  800a69:	8b 55 08             	mov    0x8(%ebp),%edx
  800a6c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a6f:	eb 03                	jmp    800a74 <strtol+0x11>
		s++;
  800a71:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a74:	0f b6 0a             	movzbl (%edx),%ecx
  800a77:	80 f9 09             	cmp    $0x9,%cl
  800a7a:	74 f5                	je     800a71 <strtol+0xe>
  800a7c:	80 f9 20             	cmp    $0x20,%cl
  800a7f:	74 f0                	je     800a71 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a81:	80 f9 2b             	cmp    $0x2b,%cl
  800a84:	75 0a                	jne    800a90 <strtol+0x2d>
		s++;
  800a86:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a89:	bf 00 00 00 00       	mov    $0x0,%edi
  800a8e:	eb 11                	jmp    800aa1 <strtol+0x3e>
  800a90:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a95:	80 f9 2d             	cmp    $0x2d,%cl
  800a98:	75 07                	jne    800aa1 <strtol+0x3e>
		s++, neg = 1;
  800a9a:	8d 52 01             	lea    0x1(%edx),%edx
  800a9d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800aa1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800aa6:	75 15                	jne    800abd <strtol+0x5a>
  800aa8:	80 3a 30             	cmpb   $0x30,(%edx)
  800aab:	75 10                	jne    800abd <strtol+0x5a>
  800aad:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800ab1:	75 0a                	jne    800abd <strtol+0x5a>
		s += 2, base = 16;
  800ab3:	83 c2 02             	add    $0x2,%edx
  800ab6:	b8 10 00 00 00       	mov    $0x10,%eax
  800abb:	eb 10                	jmp    800acd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800abd:	85 c0                	test   %eax,%eax
  800abf:	75 0c                	jne    800acd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ac1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac3:	80 3a 30             	cmpb   $0x30,(%edx)
  800ac6:	75 05                	jne    800acd <strtol+0x6a>
		s++, base = 8;
  800ac8:	83 c2 01             	add    $0x1,%edx
  800acb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800acd:	bb 00 00 00 00       	mov    $0x0,%ebx
  800ad2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ad5:	0f b6 0a             	movzbl (%edx),%ecx
  800ad8:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800adb:	89 f0                	mov    %esi,%eax
  800add:	3c 09                	cmp    $0x9,%al
  800adf:	77 08                	ja     800ae9 <strtol+0x86>
			dig = *s - '0';
  800ae1:	0f be c9             	movsbl %cl,%ecx
  800ae4:	83 e9 30             	sub    $0x30,%ecx
  800ae7:	eb 20                	jmp    800b09 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800ae9:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800aec:	89 f0                	mov    %esi,%eax
  800aee:	3c 19                	cmp    $0x19,%al
  800af0:	77 08                	ja     800afa <strtol+0x97>
			dig = *s - 'a' + 10;
  800af2:	0f be c9             	movsbl %cl,%ecx
  800af5:	83 e9 57             	sub    $0x57,%ecx
  800af8:	eb 0f                	jmp    800b09 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800afa:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800afd:	89 f0                	mov    %esi,%eax
  800aff:	3c 19                	cmp    $0x19,%al
  800b01:	77 16                	ja     800b19 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800b03:	0f be c9             	movsbl %cl,%ecx
  800b06:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b09:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b0c:	7d 0f                	jge    800b1d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800b0e:	83 c2 01             	add    $0x1,%edx
  800b11:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800b15:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800b17:	eb bc                	jmp    800ad5 <strtol+0x72>
  800b19:	89 d8                	mov    %ebx,%eax
  800b1b:	eb 02                	jmp    800b1f <strtol+0xbc>
  800b1d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800b1f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b23:	74 05                	je     800b2a <strtol+0xc7>
		*endptr = (char *) s;
  800b25:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b28:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800b2a:	f7 d8                	neg    %eax
  800b2c:	85 ff                	test   %edi,%edi
  800b2e:	0f 44 c3             	cmove  %ebx,%eax
}
  800b31:	5b                   	pop    %ebx
  800b32:	5e                   	pop    %esi
  800b33:	5f                   	pop    %edi
  800b34:	5d                   	pop    %ebp
  800b35:	c3                   	ret    

00800b36 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b36:	55                   	push   %ebp
  800b37:	89 e5                	mov    %esp,%ebp
  800b39:	57                   	push   %edi
  800b3a:	56                   	push   %esi
  800b3b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b3c:	b8 00 00 00 00       	mov    $0x0,%eax
  800b41:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b44:	8b 55 08             	mov    0x8(%ebp),%edx
  800b47:	89 c3                	mov    %eax,%ebx
  800b49:	89 c7                	mov    %eax,%edi
  800b4b:	89 c6                	mov    %eax,%esi
  800b4d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b4f:	5b                   	pop    %ebx
  800b50:	5e                   	pop    %esi
  800b51:	5f                   	pop    %edi
  800b52:	5d                   	pop    %ebp
  800b53:	c3                   	ret    

00800b54 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b54:	55                   	push   %ebp
  800b55:	89 e5                	mov    %esp,%ebp
  800b57:	57                   	push   %edi
  800b58:	56                   	push   %esi
  800b59:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b5a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b5f:	b8 01 00 00 00       	mov    $0x1,%eax
  800b64:	89 d1                	mov    %edx,%ecx
  800b66:	89 d3                	mov    %edx,%ebx
  800b68:	89 d7                	mov    %edx,%edi
  800b6a:	89 d6                	mov    %edx,%esi
  800b6c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b6e:	5b                   	pop    %ebx
  800b6f:	5e                   	pop    %esi
  800b70:	5f                   	pop    %edi
  800b71:	5d                   	pop    %ebp
  800b72:	c3                   	ret    

00800b73 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b73:	55                   	push   %ebp
  800b74:	89 e5                	mov    %esp,%ebp
  800b76:	57                   	push   %edi
  800b77:	56                   	push   %esi
  800b78:	53                   	push   %ebx
  800b79:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b81:	b8 03 00 00 00       	mov    $0x3,%eax
  800b86:	8b 55 08             	mov    0x8(%ebp),%edx
  800b89:	89 cb                	mov    %ecx,%ebx
  800b8b:	89 cf                	mov    %ecx,%edi
  800b8d:	89 ce                	mov    %ecx,%esi
  800b8f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b91:	85 c0                	test   %eax,%eax
  800b93:	7e 28                	jle    800bbd <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b95:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b99:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800ba0:	00 
  800ba1:	c7 44 24 08 68 19 80 	movl   $0x801968,0x8(%esp)
  800ba8:	00 
  800ba9:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800bb0:	00 
  800bb1:	c7 04 24 85 19 80 00 	movl   $0x801985,(%esp)
  800bb8:	e8 63 07 00 00       	call   801320 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bbd:	83 c4 2c             	add    $0x2c,%esp
  800bc0:	5b                   	pop    %ebx
  800bc1:	5e                   	pop    %esi
  800bc2:	5f                   	pop    %edi
  800bc3:	5d                   	pop    %ebp
  800bc4:	c3                   	ret    

00800bc5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bc5:	55                   	push   %ebp
  800bc6:	89 e5                	mov    %esp,%ebp
  800bc8:	57                   	push   %edi
  800bc9:	56                   	push   %esi
  800bca:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bcb:	ba 00 00 00 00       	mov    $0x0,%edx
  800bd0:	b8 02 00 00 00       	mov    $0x2,%eax
  800bd5:	89 d1                	mov    %edx,%ecx
  800bd7:	89 d3                	mov    %edx,%ebx
  800bd9:	89 d7                	mov    %edx,%edi
  800bdb:	89 d6                	mov    %edx,%esi
  800bdd:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800bdf:	5b                   	pop    %ebx
  800be0:	5e                   	pop    %esi
  800be1:	5f                   	pop    %edi
  800be2:	5d                   	pop    %ebp
  800be3:	c3                   	ret    

00800be4 <sys_yield>:

void
sys_yield(void)
{
  800be4:	55                   	push   %ebp
  800be5:	89 e5                	mov    %esp,%ebp
  800be7:	57                   	push   %edi
  800be8:	56                   	push   %esi
  800be9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bea:	ba 00 00 00 00       	mov    $0x0,%edx
  800bef:	b8 0a 00 00 00       	mov    $0xa,%eax
  800bf4:	89 d1                	mov    %edx,%ecx
  800bf6:	89 d3                	mov    %edx,%ebx
  800bf8:	89 d7                	mov    %edx,%edi
  800bfa:	89 d6                	mov    %edx,%esi
  800bfc:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800bfe:	5b                   	pop    %ebx
  800bff:	5e                   	pop    %esi
  800c00:	5f                   	pop    %edi
  800c01:	5d                   	pop    %ebp
  800c02:	c3                   	ret    

00800c03 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c03:	55                   	push   %ebp
  800c04:	89 e5                	mov    %esp,%ebp
  800c06:	57                   	push   %edi
  800c07:	56                   	push   %esi
  800c08:	53                   	push   %ebx
  800c09:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c0c:	be 00 00 00 00       	mov    $0x0,%esi
  800c11:	b8 04 00 00 00       	mov    $0x4,%eax
  800c16:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c19:	8b 55 08             	mov    0x8(%ebp),%edx
  800c1c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c1f:	89 f7                	mov    %esi,%edi
  800c21:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c23:	85 c0                	test   %eax,%eax
  800c25:	7e 28                	jle    800c4f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c27:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c2b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800c32:	00 
  800c33:	c7 44 24 08 68 19 80 	movl   $0x801968,0x8(%esp)
  800c3a:	00 
  800c3b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c42:	00 
  800c43:	c7 04 24 85 19 80 00 	movl   $0x801985,(%esp)
  800c4a:	e8 d1 06 00 00       	call   801320 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c4f:	83 c4 2c             	add    $0x2c,%esp
  800c52:	5b                   	pop    %ebx
  800c53:	5e                   	pop    %esi
  800c54:	5f                   	pop    %edi
  800c55:	5d                   	pop    %ebp
  800c56:	c3                   	ret    

00800c57 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c57:	55                   	push   %ebp
  800c58:	89 e5                	mov    %esp,%ebp
  800c5a:	57                   	push   %edi
  800c5b:	56                   	push   %esi
  800c5c:	53                   	push   %ebx
  800c5d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c60:	b8 05 00 00 00       	mov    $0x5,%eax
  800c65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c68:	8b 55 08             	mov    0x8(%ebp),%edx
  800c6b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c6e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c71:	8b 75 18             	mov    0x18(%ebp),%esi
  800c74:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c76:	85 c0                	test   %eax,%eax
  800c78:	7e 28                	jle    800ca2 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c7a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c7e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800c85:	00 
  800c86:	c7 44 24 08 68 19 80 	movl   $0x801968,0x8(%esp)
  800c8d:	00 
  800c8e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c95:	00 
  800c96:	c7 04 24 85 19 80 00 	movl   $0x801985,(%esp)
  800c9d:	e8 7e 06 00 00       	call   801320 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800ca2:	83 c4 2c             	add    $0x2c,%esp
  800ca5:	5b                   	pop    %ebx
  800ca6:	5e                   	pop    %esi
  800ca7:	5f                   	pop    %edi
  800ca8:	5d                   	pop    %ebp
  800ca9:	c3                   	ret    

00800caa <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800caa:	55                   	push   %ebp
  800cab:	89 e5                	mov    %esp,%ebp
  800cad:	57                   	push   %edi
  800cae:	56                   	push   %esi
  800caf:	53                   	push   %ebx
  800cb0:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cb3:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cb8:	b8 06 00 00 00       	mov    $0x6,%eax
  800cbd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc0:	8b 55 08             	mov    0x8(%ebp),%edx
  800cc3:	89 df                	mov    %ebx,%edi
  800cc5:	89 de                	mov    %ebx,%esi
  800cc7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cc9:	85 c0                	test   %eax,%eax
  800ccb:	7e 28                	jle    800cf5 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ccd:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cd1:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800cd8:	00 
  800cd9:	c7 44 24 08 68 19 80 	movl   $0x801968,0x8(%esp)
  800ce0:	00 
  800ce1:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ce8:	00 
  800ce9:	c7 04 24 85 19 80 00 	movl   $0x801985,(%esp)
  800cf0:	e8 2b 06 00 00       	call   801320 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800cf5:	83 c4 2c             	add    $0x2c,%esp
  800cf8:	5b                   	pop    %ebx
  800cf9:	5e                   	pop    %esi
  800cfa:	5f                   	pop    %edi
  800cfb:	5d                   	pop    %ebp
  800cfc:	c3                   	ret    

00800cfd <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800cfd:	55                   	push   %ebp
  800cfe:	89 e5                	mov    %esp,%ebp
  800d00:	57                   	push   %edi
  800d01:	56                   	push   %esi
  800d02:	53                   	push   %ebx
  800d03:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d06:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d0b:	b8 08 00 00 00       	mov    $0x8,%eax
  800d10:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d13:	8b 55 08             	mov    0x8(%ebp),%edx
  800d16:	89 df                	mov    %ebx,%edi
  800d18:	89 de                	mov    %ebx,%esi
  800d1a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d1c:	85 c0                	test   %eax,%eax
  800d1e:	7e 28                	jle    800d48 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d20:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d24:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800d2b:	00 
  800d2c:	c7 44 24 08 68 19 80 	movl   $0x801968,0x8(%esp)
  800d33:	00 
  800d34:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d3b:	00 
  800d3c:	c7 04 24 85 19 80 00 	movl   $0x801985,(%esp)
  800d43:	e8 d8 05 00 00       	call   801320 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d48:	83 c4 2c             	add    $0x2c,%esp
  800d4b:	5b                   	pop    %ebx
  800d4c:	5e                   	pop    %esi
  800d4d:	5f                   	pop    %edi
  800d4e:	5d                   	pop    %ebp
  800d4f:	c3                   	ret    

00800d50 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d50:	55                   	push   %ebp
  800d51:	89 e5                	mov    %esp,%ebp
  800d53:	57                   	push   %edi
  800d54:	56                   	push   %esi
  800d55:	53                   	push   %ebx
  800d56:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d59:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d5e:	b8 09 00 00 00       	mov    $0x9,%eax
  800d63:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d66:	8b 55 08             	mov    0x8(%ebp),%edx
  800d69:	89 df                	mov    %ebx,%edi
  800d6b:	89 de                	mov    %ebx,%esi
  800d6d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d6f:	85 c0                	test   %eax,%eax
  800d71:	7e 28                	jle    800d9b <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d73:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d77:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800d7e:	00 
  800d7f:	c7 44 24 08 68 19 80 	movl   $0x801968,0x8(%esp)
  800d86:	00 
  800d87:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d8e:	00 
  800d8f:	c7 04 24 85 19 80 00 	movl   $0x801985,(%esp)
  800d96:	e8 85 05 00 00       	call   801320 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d9b:	83 c4 2c             	add    $0x2c,%esp
  800d9e:	5b                   	pop    %ebx
  800d9f:	5e                   	pop    %esi
  800da0:	5f                   	pop    %edi
  800da1:	5d                   	pop    %ebp
  800da2:	c3                   	ret    

00800da3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800da3:	55                   	push   %ebp
  800da4:	89 e5                	mov    %esp,%ebp
  800da6:	57                   	push   %edi
  800da7:	56                   	push   %esi
  800da8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800da9:	be 00 00 00 00       	mov    $0x0,%esi
  800dae:	b8 0b 00 00 00       	mov    $0xb,%eax
  800db3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800db6:	8b 55 08             	mov    0x8(%ebp),%edx
  800db9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800dbc:	8b 7d 14             	mov    0x14(%ebp),%edi
  800dbf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800dc1:	5b                   	pop    %ebx
  800dc2:	5e                   	pop    %esi
  800dc3:	5f                   	pop    %edi
  800dc4:	5d                   	pop    %ebp
  800dc5:	c3                   	ret    

00800dc6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800dc6:	55                   	push   %ebp
  800dc7:	89 e5                	mov    %esp,%ebp
  800dc9:	57                   	push   %edi
  800dca:	56                   	push   %esi
  800dcb:	53                   	push   %ebx
  800dcc:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dcf:	b9 00 00 00 00       	mov    $0x0,%ecx
  800dd4:	b8 0c 00 00 00       	mov    $0xc,%eax
  800dd9:	8b 55 08             	mov    0x8(%ebp),%edx
  800ddc:	89 cb                	mov    %ecx,%ebx
  800dde:	89 cf                	mov    %ecx,%edi
  800de0:	89 ce                	mov    %ecx,%esi
  800de2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800de4:	85 c0                	test   %eax,%eax
  800de6:	7e 28                	jle    800e10 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800de8:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dec:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800df3:	00 
  800df4:	c7 44 24 08 68 19 80 	movl   $0x801968,0x8(%esp)
  800dfb:	00 
  800dfc:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e03:	00 
  800e04:	c7 04 24 85 19 80 00 	movl   $0x801985,(%esp)
  800e0b:	e8 10 05 00 00       	call   801320 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800e10:	83 c4 2c             	add    $0x2c,%esp
  800e13:	5b                   	pop    %ebx
  800e14:	5e                   	pop    %esi
  800e15:	5f                   	pop    %edi
  800e16:	5d                   	pop    %ebp
  800e17:	c3                   	ret    

00800e18 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800e18:	55                   	push   %ebp
  800e19:	89 e5                	mov    %esp,%ebp
  800e1b:	53                   	push   %ebx
  800e1c:	83 ec 24             	sub    $0x24,%esp
  800e1f:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  800e22:	8b 18                	mov    (%eax),%ebx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) != FEC_WR)
  800e24:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800e28:	75 1c                	jne    800e46 <pgfault+0x2e>
		panic("Invalid page fault access.");
  800e2a:	c7 44 24 08 93 19 80 	movl   $0x801993,0x8(%esp)
  800e31:	00 
  800e32:	c7 44 24 04 1d 00 00 	movl   $0x1d,0x4(%esp)
  800e39:	00 
  800e3a:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  800e41:	e8 da 04 00 00       	call   801320 <_panic>

	if (!(uvpt[(uint32_t)addr>>12] & PTE_COW))
  800e46:	89 d8                	mov    %ebx,%eax
  800e48:	c1 e8 0c             	shr    $0xc,%eax
  800e4b:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800e52:	f6 c4 08             	test   $0x8,%ah
  800e55:	75 1c                	jne    800e73 <pgfault+0x5b>
		panic("Not copy-on-write page.");
  800e57:	c7 44 24 08 b9 19 80 	movl   $0x8019b9,0x8(%esp)
  800e5e:	00 
  800e5f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800e66:	00 
  800e67:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  800e6e:	e8 ad 04 00 00       	call   801320 <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr,PGSIZE);
  800e73:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if ((r=sys_page_alloc(0,(void*)PFTEMP,PTE_P|PTE_U|PTE_W)) < 0)
  800e79:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800e80:	00 
  800e81:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800e88:	00 
  800e89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800e90:	e8 6e fd ff ff       	call   800c03 <sys_page_alloc>
  800e95:	85 c0                	test   %eax,%eax
  800e97:	79 1c                	jns    800eb5 <pgfault+0x9d>
		panic("FGFAULT PAGE ALLOC FAILURE.");
  800e99:	c7 44 24 08 d1 19 80 	movl   $0x8019d1,0x8(%esp)
  800ea0:	00 
  800ea1:	c7 44 24 04 2b 00 00 	movl   $0x2b,0x4(%esp)
  800ea8:	00 
  800ea9:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  800eb0:	e8 6b 04 00 00       	call   801320 <_panic>
	memmove((void*)PFTEMP,addr,PGSIZE);
  800eb5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  800ebc:	00 
  800ebd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ec1:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  800ec8:	e8 b7 fa ff ff       	call   800984 <memmove>
	if ((r=sys_page_unmap(0,addr)) < 0)
  800ecd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ed1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800ed8:	e8 cd fd ff ff       	call   800caa <sys_page_unmap>
  800edd:	85 c0                	test   %eax,%eax
  800edf:	79 1c                	jns    800efd <pgfault+0xe5>
		panic("PGFAULT PAGE UNMAP FAILURE.");
  800ee1:	c7 44 24 08 ed 19 80 	movl   $0x8019ed,0x8(%esp)
  800ee8:	00 
  800ee9:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
  800ef0:	00 
  800ef1:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  800ef8:	e8 23 04 00 00       	call   801320 <_panic>
	if ((r=sys_page_map(0,(void*)PFTEMP,0,addr,PTE_P|PTE_U|PTE_W)) < 0)
  800efd:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  800f04:	00 
  800f05:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800f09:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800f10:	00 
  800f11:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f18:	00 
  800f19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f20:	e8 32 fd ff ff       	call   800c57 <sys_page_map>
  800f25:	85 c0                	test   %eax,%eax
  800f27:	79 1c                	jns    800f45 <pgfault+0x12d>
		panic("PGFAULT PAGE MAP FAILURE.");
  800f29:	c7 44 24 08 09 1a 80 	movl   $0x801a09,0x8(%esp)
  800f30:	00 
  800f31:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  800f38:	00 
  800f39:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  800f40:	e8 db 03 00 00       	call   801320 <_panic>
	if ((r=sys_page_unmap(0,(void*)PFTEMP)) < 0)
  800f45:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f4c:	00 
  800f4d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f54:	e8 51 fd ff ff       	call   800caa <sys_page_unmap>
  800f59:	85 c0                	test   %eax,%eax
  800f5b:	79 1c                	jns    800f79 <pgfault+0x161>
		panic("PGFAULT PAGE UNMAP FAILURE.");
  800f5d:	c7 44 24 08 ed 19 80 	movl   $0x8019ed,0x8(%esp)
  800f64:	00 
  800f65:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  800f6c:	00 
  800f6d:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  800f74:	e8 a7 03 00 00       	call   801320 <_panic>


	//panic("pgfault not implemented");
}
  800f79:	83 c4 24             	add    $0x24,%esp
  800f7c:	5b                   	pop    %ebx
  800f7d:	5d                   	pop    %ebp
  800f7e:	c3                   	ret    

00800f7f <duppage>:
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
  800f7f:	55                   	push   %ebp
  800f80:	89 e5                	mov    %esp,%ebp
  800f82:	53                   	push   %ebx
  800f83:	83 ec 24             	sub    $0x24,%esp
	int r;

	// LAB 4: Your code here.
	//panic("duppage not implemented");
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) {
  800f86:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  800f8d:	f6 c1 02             	test   $0x2,%cl
  800f90:	75 10                	jne    800fa2 <duppage+0x23>
  800f92:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  800f99:	f6 c5 08             	test   $0x8,%ch
  800f9c:	0f 84 89 00 00 00    	je     80102b <duppage+0xac>
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),envid,(void*)(pn*PGSIZE),PTE_P|PTE_U|PTE_COW)) < 0)
  800fa2:	89 d3                	mov    %edx,%ebx
  800fa4:	c1 e3 0c             	shl    $0xc,%ebx
  800fa7:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  800fae:	00 
  800faf:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800fb3:	89 44 24 08          	mov    %eax,0x8(%esp)
  800fb7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800fbb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800fc2:	e8 90 fc ff ff       	call   800c57 <sys_page_map>
  800fc7:	85 c0                	test   %eax,%eax
  800fc9:	79 1c                	jns    800fe7 <duppage+0x68>
			panic("DUPPAGE PAGE MAP FAILURE.");
  800fcb:	c7 44 24 08 23 1a 80 	movl   $0x801a23,0x8(%esp)
  800fd2:	00 
  800fd3:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
  800fda:	00 
  800fdb:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  800fe2:	e8 39 03 00 00       	call   801320 <_panic>
	
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),0,(void*)(pn*PGSIZE),PTE_P|PTE_U|PTE_COW)) < 0)
  800fe7:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  800fee:	00 
  800fef:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800ff3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800ffa:	00 
  800ffb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800fff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801006:	e8 4c fc ff ff       	call   800c57 <sys_page_map>
  80100b:	85 c0                	test   %eax,%eax
  80100d:	79 68                	jns    801077 <duppage+0xf8>
			panic("DUPPAGE PAGE MAP FAILURE.");
  80100f:	c7 44 24 08 23 1a 80 	movl   $0x801a23,0x8(%esp)
  801016:	00 
  801017:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
  80101e:	00 
  80101f:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  801026:	e8 f5 02 00 00       	call   801320 <_panic>

	} else {
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),envid,(void*)(pn*PGSIZE),uvpt[pn]&0xfff)) < 0)
  80102b:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  801032:	c1 e2 0c             	shl    $0xc,%edx
  801035:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
  80103b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80103f:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801043:	89 44 24 08          	mov    %eax,0x8(%esp)
  801047:	89 54 24 04          	mov    %edx,0x4(%esp)
  80104b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801052:	e8 00 fc ff ff       	call   800c57 <sys_page_map>
  801057:	85 c0                	test   %eax,%eax
  801059:	79 1c                	jns    801077 <duppage+0xf8>
			panic("DUPPAGE PAGE MAP FAILURE.");
  80105b:	c7 44 24 08 23 1a 80 	movl   $0x801a23,0x8(%esp)
  801062:	00 
  801063:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  80106a:	00 
  80106b:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  801072:	e8 a9 02 00 00       	call   801320 <_panic>
	}
	return 0;
}
  801077:	b8 00 00 00 00       	mov    $0x0,%eax
  80107c:	83 c4 24             	add    $0x24,%esp
  80107f:	5b                   	pop    %ebx
  801080:	5d                   	pop    %ebp
  801081:	c3                   	ret    

00801082 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  801082:	55                   	push   %ebp
  801083:	89 e5                	mov    %esp,%ebp
  801085:	57                   	push   %edi
  801086:	56                   	push   %esi
  801087:	53                   	push   %ebx
  801088:	83 ec 1c             	sub    $0x1c,%esp
	int r;
	envid_t envid;
	uint32_t n;
	
	//1. Setup pgfault() handler
	set_pgfault_handler(pgfault);
  80108b:	c7 04 24 18 0e 80 00 	movl   $0x800e18,(%esp)
  801092:	e8 df 02 00 00       	call   801376 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  801097:	b8 07 00 00 00       	mov    $0x7,%eax
  80109c:	cd 30                	int    $0x30
  80109e:	89 c6                	mov    %eax,%esi

	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
  8010a0:	85 c0                	test   %eax,%eax
  8010a2:	79 20                	jns    8010c4 <fork+0x42>
		panic("sys_exofork: %e", envid);
  8010a4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8010a8:	c7 44 24 08 3d 1a 80 	movl   $0x801a3d,0x8(%esp)
  8010af:	00 
  8010b0:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  8010b7:	00 
  8010b8:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  8010bf:	e8 5c 02 00 00       	call   801320 <_panic>
  8010c4:	89 c7                	mov    %eax,%edi
	}

	// We're the parent.

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {
  8010c6:	b8 00 00 00 00       	mov    $0x0,%eax
	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
  8010cb:	bb 00 00 00 00       	mov    $0x0,%ebx
  8010d0:	85 f6                	test   %esi,%esi
  8010d2:	75 21                	jne    8010f5 <fork+0x73>
		// We're the child.
		thisenv = &envs[ENVX(sys_getenvid())];
  8010d4:	e8 ec fa ff ff       	call   800bc5 <sys_getenvid>
  8010d9:	25 ff 03 00 00       	and    $0x3ff,%eax
  8010de:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8010e1:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8010e6:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  8010eb:	b8 00 00 00 00       	mov    $0x0,%eax
  8010f0:	e9 ac 00 00 00       	jmp    8011a1 <fork+0x11f>

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {

		//3.1 Copy page mapping using duppage
		if ((uvpd[n>>10] & PTE_P)) {
  8010f5:	89 da                	mov    %ebx,%edx
  8010f7:	c1 ea 0a             	shr    $0xa,%edx
  8010fa:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  801101:	f6 c2 01             	test   $0x1,%dl
  801104:	74 21                	je     801127 <fork+0xa5>
			if ((uvpt[n] & PTE_P))
  801106:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  80110d:	f6 c2 01             	test   $0x1,%dl
  801110:	74 10                	je     801122 <fork+0xa0>
				if (n*PGSIZE != UXSTACKTOP-PGSIZE)
  801112:	3d 00 f0 bf ee       	cmp    $0xeebff000,%eax
  801117:	74 09                	je     801122 <fork+0xa0>
					duppage(envid,n);
  801119:	89 da                	mov    %ebx,%edx
  80111b:	89 f8                	mov    %edi,%eax
  80111d:	e8 5d fe ff ff       	call   800f7f <duppage>
			n++;
  801122:	83 c3 01             	add    $0x1,%ebx
  801125:	eb 0c                	jmp    801133 <fork+0xb1>
		} else {
			n=n+NPDENTRIES-n%NPDENTRIES;
  801127:	81 e3 00 fc ff ff    	and    $0xfffffc00,%ebx
  80112d:	81 c3 00 04 00 00    	add    $0x400,%ebx
	}

	// We're the parent.

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {
  801133:	89 d8                	mov    %ebx,%eax
  801135:	c1 e0 0c             	shl    $0xc,%eax
  801138:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
  80113d:	76 b6                	jbe    8010f5 <fork+0x73>
		}
	 	
	}
	
	//3.2 Copy exception stack page
	sys_page_alloc(envid,(void*)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W);
  80113f:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801146:	00 
  801147:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80114e:	ee 
  80114f:	89 34 24             	mov    %esi,(%esp)
  801152:	e8 ac fa ff ff       	call   800c03 <sys_page_alloc>

	//4. Set the pgfault handler for child
	sys_env_set_pgfault_upcall(envid,thisenv->env_pgfault_upcall);
  801157:	a1 04 20 80 00       	mov    0x802004,%eax
  80115c:	8b 40 64             	mov    0x64(%eax),%eax
  80115f:	89 44 24 04          	mov    %eax,0x4(%esp)
  801163:	89 34 24             	mov    %esi,(%esp)
  801166:	e8 e5 fb ff ff       	call   800d50 <sys_env_set_pgfault_upcall>


	//5. Mark the child as runnable and return
	if ((r=sys_env_set_status(envid,ENV_RUNNABLE))<0) {
  80116b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  801172:	00 
  801173:	89 34 24             	mov    %esi,(%esp)
  801176:	e8 82 fb ff ff       	call   800cfd <sys_env_set_status>
  80117b:	85 c0                	test   %eax,%eax
  80117d:	79 20                	jns    80119f <fork+0x11d>
		panic("sys_env_set_status: %e", r);
  80117f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801183:	c7 44 24 08 4d 1a 80 	movl   $0x801a4d,0x8(%esp)
  80118a:	00 
  80118b:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
  801192:	00 
  801193:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  80119a:	e8 81 01 00 00       	call   801320 <_panic>
	}

	return envid;
  80119f:	89 f0                	mov    %esi,%eax

}
  8011a1:	83 c4 1c             	add    $0x1c,%esp
  8011a4:	5b                   	pop    %ebx
  8011a5:	5e                   	pop    %esi
  8011a6:	5f                   	pop    %edi
  8011a7:	5d                   	pop    %ebp
  8011a8:	c3                   	ret    

008011a9 <sfork>:

// Challenge!
int
sfork(void)
{
  8011a9:	55                   	push   %ebp
  8011aa:	89 e5                	mov    %esp,%ebp
  8011ac:	57                   	push   %edi
  8011ad:	56                   	push   %esi
  8011ae:	53                   	push   %ebx
  8011af:	83 ec 2c             	sub    $0x2c,%esp
	int r;
	envid_t envid;
	uint32_t n;
	
	//1. Setup pgfault() handler
	set_pgfault_handler(pgfault);
  8011b2:	c7 04 24 18 0e 80 00 	movl   $0x800e18,(%esp)
  8011b9:	e8 b8 01 00 00       	call   801376 <set_pgfault_handler>
  8011be:	b8 07 00 00 00       	mov    $0x7,%eax
  8011c3:	cd 30                	int    $0x30
  8011c5:	89 c6                	mov    %eax,%esi

	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
  8011c7:	85 c0                	test   %eax,%eax
  8011c9:	79 20                	jns    8011eb <sfork+0x42>
		panic("sys_exofork: %e", envid);
  8011cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011cf:	c7 44 24 08 3d 1a 80 	movl   $0x801a3d,0x8(%esp)
  8011d6:	00 
  8011d7:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
  8011de:	00 
  8011df:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  8011e6:	e8 35 01 00 00       	call   801320 <_panic>
  8011eb:	89 c7                	mov    %eax,%edi
		return 0;
	}

	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {
  8011ed:	b8 00 00 00 00       	mov    $0x0,%eax
	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
  8011f2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8011f7:	85 f6                	test   %esi,%esi
  8011f9:	75 21                	jne    80121c <sfork+0x73>
		// We're the child.
		thisenv = &envs[ENVX(sys_getenvid())];
  8011fb:	e8 c5 f9 ff ff       	call   800bc5 <sys_getenvid>
  801200:	25 ff 03 00 00       	and    $0x3ff,%eax
  801205:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801208:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80120d:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  801212:	b8 00 00 00 00       	mov    $0x0,%eax
  801217:	e9 fc 00 00 00       	jmp    801318 <sfork+0x16f>
	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {

		//3.1 Copy stack page mapping using duppage
		if ((uvpd[n>>10] & PTE_P)) {
  80121c:	89 da                	mov    %ebx,%edx
  80121e:	c1 ea 0a             	shr    $0xa,%edx
  801221:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  801228:	f6 c2 01             	test   $0x1,%dl
  80122b:	74 6a                	je     801297 <sfork+0xee>
			if ((uvpt[n] & PTE_P)) {
  80122d:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  801234:	f6 c2 01             	test   $0x1,%dl
  801237:	74 59                	je     801292 <sfork+0xe9>
				if (n*PGSIZE == USTACKTOP-PGSIZE)
  801239:	3d 00 d0 bf ee       	cmp    $0xeebfd000,%eax
  80123e:	75 0b                	jne    80124b <sfork+0xa2>
					duppage(envid,n);
  801240:	89 da                	mov    %ebx,%edx
  801242:	89 f8                	mov    %edi,%eax
  801244:	e8 36 fd ff ff       	call   800f7f <duppage>
  801249:	eb 47                	jmp    801292 <sfork+0xe9>
				else if (n*PGSIZE != UXSTACKTOP-PGSIZE) {
  80124b:	3d 00 f0 bf ee       	cmp    $0xeebff000,%eax
  801250:	74 40                	je     801292 <sfork+0xe9>
					//Share-memory copy
					if((r=sys_page_map(0,(void*)(n*PGSIZE),envid,(void*)(n*PGSIZE),PTE_P|PTE_U|PTE_W)) < 0)
  801252:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  801259:	00 
  80125a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80125e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801262:	89 44 24 04          	mov    %eax,0x4(%esp)
  801266:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80126d:	e8 e5 f9 ff ff       	call   800c57 <sys_page_map>
  801272:	85 c0                	test   %eax,%eax
  801274:	79 1c                	jns    801292 <sfork+0xe9>
						panic("Shared-memory mapping failure.");
  801276:	c7 44 24 08 64 1a 80 	movl   $0x801a64,0x8(%esp)
  80127d:	00 
  80127e:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  801285:	00 
  801286:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  80128d:	e8 8e 00 00 00       	call   801320 <_panic>
				}
			}	
			n++;
  801292:	83 c3 01             	add    $0x1,%ebx
  801295:	eb 0c                	jmp    8012a3 <sfork+0xfa>
		} else {
			n=n+NPDENTRIES-n%NPDENTRIES;
  801297:	81 e3 00 fc ff ff    	and    $0xfffffc00,%ebx
  80129d:	81 c3 00 04 00 00    	add    $0x400,%ebx
		return 0;
	}

	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {
  8012a3:	83 c3 01             	add    $0x1,%ebx
  8012a6:	89 d8                	mov    %ebx,%eax
  8012a8:	c1 e0 0c             	shl    $0xc,%eax
  8012ab:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
  8012b0:	0f 86 66 ff ff ff    	jbe    80121c <sfork+0x73>
			n=n+NPDENTRIES-n%NPDENTRIES;
		}
	}
	
	//3.2 Copy exception stack page
	sys_page_alloc(envid,(void*)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W);
  8012b6:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8012bd:	00 
  8012be:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8012c5:	ee 
  8012c6:	89 34 24             	mov    %esi,(%esp)
  8012c9:	e8 35 f9 ff ff       	call   800c03 <sys_page_alloc>

	//4. Set the pgfault handler for child
	sys_env_set_pgfault_upcall(envid,thisenv->env_pgfault_upcall);
  8012ce:	a1 04 20 80 00       	mov    0x802004,%eax
  8012d3:	8b 40 64             	mov    0x64(%eax),%eax
  8012d6:	89 44 24 04          	mov    %eax,0x4(%esp)
  8012da:	89 34 24             	mov    %esi,(%esp)
  8012dd:	e8 6e fa ff ff       	call   800d50 <sys_env_set_pgfault_upcall>

	//5. Mark the child as runnable and return
	if ((r=sys_env_set_status(envid,ENV_RUNNABLE))<0) {
  8012e2:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8012e9:	00 
  8012ea:	89 34 24             	mov    %esi,(%esp)
  8012ed:	e8 0b fa ff ff       	call   800cfd <sys_env_set_status>
  8012f2:	85 c0                	test   %eax,%eax
  8012f4:	79 20                	jns    801316 <sfork+0x16d>
		panic("sys_env_set_status: %e", r);
  8012f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012fa:	c7 44 24 08 4d 1a 80 	movl   $0x801a4d,0x8(%esp)
  801301:	00 
  801302:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  801309:	00 
  80130a:	c7 04 24 ae 19 80 00 	movl   $0x8019ae,(%esp)
  801311:	e8 0a 00 00 00       	call   801320 <_panic>
	}

	//return -E_INVAL;
	return envid;
  801316:	89 f0                	mov    %esi,%eax
}
  801318:	83 c4 2c             	add    $0x2c,%esp
  80131b:	5b                   	pop    %ebx
  80131c:	5e                   	pop    %esi
  80131d:	5f                   	pop    %edi
  80131e:	5d                   	pop    %ebp
  80131f:	c3                   	ret    

00801320 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801320:	55                   	push   %ebp
  801321:	89 e5                	mov    %esp,%ebp
  801323:	56                   	push   %esi
  801324:	53                   	push   %ebx
  801325:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  801328:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80132b:	8b 35 00 20 80 00    	mov    0x802000,%esi
  801331:	e8 8f f8 ff ff       	call   800bc5 <sys_getenvid>
  801336:	8b 55 0c             	mov    0xc(%ebp),%edx
  801339:	89 54 24 10          	mov    %edx,0x10(%esp)
  80133d:	8b 55 08             	mov    0x8(%ebp),%edx
  801340:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801344:	89 74 24 08          	mov    %esi,0x8(%esp)
  801348:	89 44 24 04          	mov    %eax,0x4(%esp)
  80134c:	c7 04 24 84 1a 80 00 	movl   $0x801a84,(%esp)
  801353:	e8 66 ee ff ff       	call   8001be <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801358:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80135c:	8b 45 10             	mov    0x10(%ebp),%eax
  80135f:	89 04 24             	mov    %eax,(%esp)
  801362:	e8 f6 ed ff ff       	call   80015d <vcprintf>
	cprintf("\n");
  801367:	c7 04 24 14 17 80 00 	movl   $0x801714,(%esp)
  80136e:	e8 4b ee ff ff       	call   8001be <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  801373:	cc                   	int3   
  801374:	eb fd                	jmp    801373 <_panic+0x53>

00801376 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801376:	55                   	push   %ebp
  801377:	89 e5                	mov    %esp,%ebp
  801379:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  80137c:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  801383:	75 1d                	jne    8013a2 <set_pgfault_handler+0x2c>
		// First time through!
		// LAB 4: Your code here.
		sys_page_alloc(sys_getenvid(), (void*)(UXSTACKTOP-PGSIZE), PTE_U|PTE_W|PTE_P);
  801385:	e8 3b f8 ff ff       	call   800bc5 <sys_getenvid>
  80138a:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801391:	00 
  801392:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  801399:	ee 
  80139a:	89 04 24             	mov    %eax,(%esp)
  80139d:	e8 61 f8 ff ff       	call   800c03 <sys_page_alloc>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8013a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8013a5:	a3 08 20 80 00       	mov    %eax,0x802008
	//cprintf("UPCALL: %p\n",_pgfault_upcall);
	sys_env_set_pgfault_upcall(sys_getenvid(), _pgfault_upcall);
  8013aa:	e8 16 f8 ff ff       	call   800bc5 <sys_getenvid>
  8013af:	c7 44 24 04 c1 13 80 	movl   $0x8013c1,0x4(%esp)
  8013b6:	00 
  8013b7:	89 04 24             	mov    %eax,(%esp)
  8013ba:	e8 91 f9 ff ff       	call   800d50 <sys_env_set_pgfault_upcall>
}
  8013bf:	c9                   	leave  
  8013c0:	c3                   	ret    

008013c1 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8013c1:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8013c2:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  8013c7:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  8013c9:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	addl $8, %esp
  8013cc:	83 c4 08             	add    $0x8,%esp


	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  8013cf:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	pushl %eax
  8013d0:	50                   	push   %eax
	pushl %ebx
  8013d1:	53                   	push   %ebx
	movl 0x8(%esp), %eax
  8013d2:	8b 44 24 08          	mov    0x8(%esp),%eax
	movl 0x10(%esp), %ebx
  8013d6:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	subl $4, %ebx
  8013da:	83 eb 04             	sub    $0x4,%ebx
	movl %eax, (%ebx)
  8013dd:	89 03                	mov    %eax,(%ebx)
	//Note: you should modify the value before it's popped to %esp
	//      Otherwise, for some reason, the eflags will be wrong!!!
	movl %ebx, 0x10(%esp)
  8013df:	89 5c 24 10          	mov    %ebx,0x10(%esp)
	popl %ebx
  8013e3:	5b                   	pop    %ebx
	popl %eax
  8013e4:	58                   	pop    %eax
	addl $4, %esp
  8013e5:	83 c4 04             	add    $0x4,%esp
	popf
  8013e8:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  8013e9:	5c                   	pop    %esp
	//subl $4, %esp

	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  8013ea:	c3                   	ret    
  8013eb:	66 90                	xchg   %ax,%ax
  8013ed:	66 90                	xchg   %ax,%ax
  8013ef:	90                   	nop

008013f0 <__udivdi3>:
  8013f0:	55                   	push   %ebp
  8013f1:	57                   	push   %edi
  8013f2:	56                   	push   %esi
  8013f3:	83 ec 0c             	sub    $0xc,%esp
  8013f6:	8b 44 24 28          	mov    0x28(%esp),%eax
  8013fa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  8013fe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  801402:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  801406:	85 c0                	test   %eax,%eax
  801408:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80140c:	89 ea                	mov    %ebp,%edx
  80140e:	89 0c 24             	mov    %ecx,(%esp)
  801411:	75 2d                	jne    801440 <__udivdi3+0x50>
  801413:	39 e9                	cmp    %ebp,%ecx
  801415:	77 61                	ja     801478 <__udivdi3+0x88>
  801417:	85 c9                	test   %ecx,%ecx
  801419:	89 ce                	mov    %ecx,%esi
  80141b:	75 0b                	jne    801428 <__udivdi3+0x38>
  80141d:	b8 01 00 00 00       	mov    $0x1,%eax
  801422:	31 d2                	xor    %edx,%edx
  801424:	f7 f1                	div    %ecx
  801426:	89 c6                	mov    %eax,%esi
  801428:	31 d2                	xor    %edx,%edx
  80142a:	89 e8                	mov    %ebp,%eax
  80142c:	f7 f6                	div    %esi
  80142e:	89 c5                	mov    %eax,%ebp
  801430:	89 f8                	mov    %edi,%eax
  801432:	f7 f6                	div    %esi
  801434:	89 ea                	mov    %ebp,%edx
  801436:	83 c4 0c             	add    $0xc,%esp
  801439:	5e                   	pop    %esi
  80143a:	5f                   	pop    %edi
  80143b:	5d                   	pop    %ebp
  80143c:	c3                   	ret    
  80143d:	8d 76 00             	lea    0x0(%esi),%esi
  801440:	39 e8                	cmp    %ebp,%eax
  801442:	77 24                	ja     801468 <__udivdi3+0x78>
  801444:	0f bd e8             	bsr    %eax,%ebp
  801447:	83 f5 1f             	xor    $0x1f,%ebp
  80144a:	75 3c                	jne    801488 <__udivdi3+0x98>
  80144c:	8b 74 24 04          	mov    0x4(%esp),%esi
  801450:	39 34 24             	cmp    %esi,(%esp)
  801453:	0f 86 9f 00 00 00    	jbe    8014f8 <__udivdi3+0x108>
  801459:	39 d0                	cmp    %edx,%eax
  80145b:	0f 82 97 00 00 00    	jb     8014f8 <__udivdi3+0x108>
  801461:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801468:	31 d2                	xor    %edx,%edx
  80146a:	31 c0                	xor    %eax,%eax
  80146c:	83 c4 0c             	add    $0xc,%esp
  80146f:	5e                   	pop    %esi
  801470:	5f                   	pop    %edi
  801471:	5d                   	pop    %ebp
  801472:	c3                   	ret    
  801473:	90                   	nop
  801474:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801478:	89 f8                	mov    %edi,%eax
  80147a:	f7 f1                	div    %ecx
  80147c:	31 d2                	xor    %edx,%edx
  80147e:	83 c4 0c             	add    $0xc,%esp
  801481:	5e                   	pop    %esi
  801482:	5f                   	pop    %edi
  801483:	5d                   	pop    %ebp
  801484:	c3                   	ret    
  801485:	8d 76 00             	lea    0x0(%esi),%esi
  801488:	89 e9                	mov    %ebp,%ecx
  80148a:	8b 3c 24             	mov    (%esp),%edi
  80148d:	d3 e0                	shl    %cl,%eax
  80148f:	89 c6                	mov    %eax,%esi
  801491:	b8 20 00 00 00       	mov    $0x20,%eax
  801496:	29 e8                	sub    %ebp,%eax
  801498:	89 c1                	mov    %eax,%ecx
  80149a:	d3 ef                	shr    %cl,%edi
  80149c:	89 e9                	mov    %ebp,%ecx
  80149e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8014a2:	8b 3c 24             	mov    (%esp),%edi
  8014a5:	09 74 24 08          	or     %esi,0x8(%esp)
  8014a9:	89 d6                	mov    %edx,%esi
  8014ab:	d3 e7                	shl    %cl,%edi
  8014ad:	89 c1                	mov    %eax,%ecx
  8014af:	89 3c 24             	mov    %edi,(%esp)
  8014b2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8014b6:	d3 ee                	shr    %cl,%esi
  8014b8:	89 e9                	mov    %ebp,%ecx
  8014ba:	d3 e2                	shl    %cl,%edx
  8014bc:	89 c1                	mov    %eax,%ecx
  8014be:	d3 ef                	shr    %cl,%edi
  8014c0:	09 d7                	or     %edx,%edi
  8014c2:	89 f2                	mov    %esi,%edx
  8014c4:	89 f8                	mov    %edi,%eax
  8014c6:	f7 74 24 08          	divl   0x8(%esp)
  8014ca:	89 d6                	mov    %edx,%esi
  8014cc:	89 c7                	mov    %eax,%edi
  8014ce:	f7 24 24             	mull   (%esp)
  8014d1:	39 d6                	cmp    %edx,%esi
  8014d3:	89 14 24             	mov    %edx,(%esp)
  8014d6:	72 30                	jb     801508 <__udivdi3+0x118>
  8014d8:	8b 54 24 04          	mov    0x4(%esp),%edx
  8014dc:	89 e9                	mov    %ebp,%ecx
  8014de:	d3 e2                	shl    %cl,%edx
  8014e0:	39 c2                	cmp    %eax,%edx
  8014e2:	73 05                	jae    8014e9 <__udivdi3+0xf9>
  8014e4:	3b 34 24             	cmp    (%esp),%esi
  8014e7:	74 1f                	je     801508 <__udivdi3+0x118>
  8014e9:	89 f8                	mov    %edi,%eax
  8014eb:	31 d2                	xor    %edx,%edx
  8014ed:	e9 7a ff ff ff       	jmp    80146c <__udivdi3+0x7c>
  8014f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8014f8:	31 d2                	xor    %edx,%edx
  8014fa:	b8 01 00 00 00       	mov    $0x1,%eax
  8014ff:	e9 68 ff ff ff       	jmp    80146c <__udivdi3+0x7c>
  801504:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801508:	8d 47 ff             	lea    -0x1(%edi),%eax
  80150b:	31 d2                	xor    %edx,%edx
  80150d:	83 c4 0c             	add    $0xc,%esp
  801510:	5e                   	pop    %esi
  801511:	5f                   	pop    %edi
  801512:	5d                   	pop    %ebp
  801513:	c3                   	ret    
  801514:	66 90                	xchg   %ax,%ax
  801516:	66 90                	xchg   %ax,%ax
  801518:	66 90                	xchg   %ax,%ax
  80151a:	66 90                	xchg   %ax,%ax
  80151c:	66 90                	xchg   %ax,%ax
  80151e:	66 90                	xchg   %ax,%ax

00801520 <__umoddi3>:
  801520:	55                   	push   %ebp
  801521:	57                   	push   %edi
  801522:	56                   	push   %esi
  801523:	83 ec 14             	sub    $0x14,%esp
  801526:	8b 44 24 28          	mov    0x28(%esp),%eax
  80152a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80152e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  801532:	89 c7                	mov    %eax,%edi
  801534:	89 44 24 04          	mov    %eax,0x4(%esp)
  801538:	8b 44 24 30          	mov    0x30(%esp),%eax
  80153c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  801540:	89 34 24             	mov    %esi,(%esp)
  801543:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801547:	85 c0                	test   %eax,%eax
  801549:	89 c2                	mov    %eax,%edx
  80154b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80154f:	75 17                	jne    801568 <__umoddi3+0x48>
  801551:	39 fe                	cmp    %edi,%esi
  801553:	76 4b                	jbe    8015a0 <__umoddi3+0x80>
  801555:	89 c8                	mov    %ecx,%eax
  801557:	89 fa                	mov    %edi,%edx
  801559:	f7 f6                	div    %esi
  80155b:	89 d0                	mov    %edx,%eax
  80155d:	31 d2                	xor    %edx,%edx
  80155f:	83 c4 14             	add    $0x14,%esp
  801562:	5e                   	pop    %esi
  801563:	5f                   	pop    %edi
  801564:	5d                   	pop    %ebp
  801565:	c3                   	ret    
  801566:	66 90                	xchg   %ax,%ax
  801568:	39 f8                	cmp    %edi,%eax
  80156a:	77 54                	ja     8015c0 <__umoddi3+0xa0>
  80156c:	0f bd e8             	bsr    %eax,%ebp
  80156f:	83 f5 1f             	xor    $0x1f,%ebp
  801572:	75 5c                	jne    8015d0 <__umoddi3+0xb0>
  801574:	8b 7c 24 08          	mov    0x8(%esp),%edi
  801578:	39 3c 24             	cmp    %edi,(%esp)
  80157b:	0f 87 e7 00 00 00    	ja     801668 <__umoddi3+0x148>
  801581:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801585:	29 f1                	sub    %esi,%ecx
  801587:	19 c7                	sbb    %eax,%edi
  801589:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80158d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801591:	8b 44 24 08          	mov    0x8(%esp),%eax
  801595:	8b 54 24 0c          	mov    0xc(%esp),%edx
  801599:	83 c4 14             	add    $0x14,%esp
  80159c:	5e                   	pop    %esi
  80159d:	5f                   	pop    %edi
  80159e:	5d                   	pop    %ebp
  80159f:	c3                   	ret    
  8015a0:	85 f6                	test   %esi,%esi
  8015a2:	89 f5                	mov    %esi,%ebp
  8015a4:	75 0b                	jne    8015b1 <__umoddi3+0x91>
  8015a6:	b8 01 00 00 00       	mov    $0x1,%eax
  8015ab:	31 d2                	xor    %edx,%edx
  8015ad:	f7 f6                	div    %esi
  8015af:	89 c5                	mov    %eax,%ebp
  8015b1:	8b 44 24 04          	mov    0x4(%esp),%eax
  8015b5:	31 d2                	xor    %edx,%edx
  8015b7:	f7 f5                	div    %ebp
  8015b9:	89 c8                	mov    %ecx,%eax
  8015bb:	f7 f5                	div    %ebp
  8015bd:	eb 9c                	jmp    80155b <__umoddi3+0x3b>
  8015bf:	90                   	nop
  8015c0:	89 c8                	mov    %ecx,%eax
  8015c2:	89 fa                	mov    %edi,%edx
  8015c4:	83 c4 14             	add    $0x14,%esp
  8015c7:	5e                   	pop    %esi
  8015c8:	5f                   	pop    %edi
  8015c9:	5d                   	pop    %ebp
  8015ca:	c3                   	ret    
  8015cb:	90                   	nop
  8015cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8015d0:	8b 04 24             	mov    (%esp),%eax
  8015d3:	be 20 00 00 00       	mov    $0x20,%esi
  8015d8:	89 e9                	mov    %ebp,%ecx
  8015da:	29 ee                	sub    %ebp,%esi
  8015dc:	d3 e2                	shl    %cl,%edx
  8015de:	89 f1                	mov    %esi,%ecx
  8015e0:	d3 e8                	shr    %cl,%eax
  8015e2:	89 e9                	mov    %ebp,%ecx
  8015e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8015e8:	8b 04 24             	mov    (%esp),%eax
  8015eb:	09 54 24 04          	or     %edx,0x4(%esp)
  8015ef:	89 fa                	mov    %edi,%edx
  8015f1:	d3 e0                	shl    %cl,%eax
  8015f3:	89 f1                	mov    %esi,%ecx
  8015f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8015f9:	8b 44 24 10          	mov    0x10(%esp),%eax
  8015fd:	d3 ea                	shr    %cl,%edx
  8015ff:	89 e9                	mov    %ebp,%ecx
  801601:	d3 e7                	shl    %cl,%edi
  801603:	89 f1                	mov    %esi,%ecx
  801605:	d3 e8                	shr    %cl,%eax
  801607:	89 e9                	mov    %ebp,%ecx
  801609:	09 f8                	or     %edi,%eax
  80160b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80160f:	f7 74 24 04          	divl   0x4(%esp)
  801613:	d3 e7                	shl    %cl,%edi
  801615:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801619:	89 d7                	mov    %edx,%edi
  80161b:	f7 64 24 08          	mull   0x8(%esp)
  80161f:	39 d7                	cmp    %edx,%edi
  801621:	89 c1                	mov    %eax,%ecx
  801623:	89 14 24             	mov    %edx,(%esp)
  801626:	72 2c                	jb     801654 <__umoddi3+0x134>
  801628:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80162c:	72 22                	jb     801650 <__umoddi3+0x130>
  80162e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801632:	29 c8                	sub    %ecx,%eax
  801634:	19 d7                	sbb    %edx,%edi
  801636:	89 e9                	mov    %ebp,%ecx
  801638:	89 fa                	mov    %edi,%edx
  80163a:	d3 e8                	shr    %cl,%eax
  80163c:	89 f1                	mov    %esi,%ecx
  80163e:	d3 e2                	shl    %cl,%edx
  801640:	89 e9                	mov    %ebp,%ecx
  801642:	d3 ef                	shr    %cl,%edi
  801644:	09 d0                	or     %edx,%eax
  801646:	89 fa                	mov    %edi,%edx
  801648:	83 c4 14             	add    $0x14,%esp
  80164b:	5e                   	pop    %esi
  80164c:	5f                   	pop    %edi
  80164d:	5d                   	pop    %ebp
  80164e:	c3                   	ret    
  80164f:	90                   	nop
  801650:	39 d7                	cmp    %edx,%edi
  801652:	75 da                	jne    80162e <__umoddi3+0x10e>
  801654:	8b 14 24             	mov    (%esp),%edx
  801657:	89 c1                	mov    %eax,%ecx
  801659:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80165d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801661:	eb cb                	jmp    80162e <__umoddi3+0x10e>
  801663:	90                   	nop
  801664:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801668:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80166c:	0f 82 0f ff ff ff    	jb     801581 <__umoddi3+0x61>
  801672:	e9 1a ff ff ff       	jmp    801591 <__umoddi3+0x71>
