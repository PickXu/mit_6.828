
obj/user/pingpong:     file format elf32-i386


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
  80002c:	e8 ca 00 00 00       	call   8000fb <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 2c             	sub    $0x2c,%esp
	envid_t who;

	if ((who = fork()) != 0) {
  80003c:	e8 81 10 00 00       	call   8010c2 <fork>
  800041:	89 c3                	mov    %eax,%ebx
  800043:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800046:	85 c0                	test   %eax,%eax
  800048:	75 05                	jne    80004f <umain+0x1c>
		cprintf("send 0 from %x to %x\n", sys_getenvid(), who);
		ipc_send(who, 0, 0, 0);
	}

	while (1) {
		uint32_t i = ipc_recv(&who, 0, 0);
  80004a:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  80004d:	eb 3e                	jmp    80008d <umain+0x5a>
{
	envid_t who;

	if ((who = fork()) != 0) {
		// get the ball rolling
		cprintf("send 0 from %x to %x\n", sys_getenvid(), who);
  80004f:	e8 b1 0b 00 00       	call   800c05 <sys_getenvid>
  800054:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800058:	89 44 24 04          	mov    %eax,0x4(%esp)
  80005c:	c7 04 24 e0 17 80 00 	movl   $0x8017e0,(%esp)
  800063:	e8 92 01 00 00       	call   8001fa <cprintf>
		ipc_send(who, 0, 0, 0);
  800068:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80006f:	00 
  800070:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800077:	00 
  800078:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80007f:	00 
  800080:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800083:	89 04 24             	mov    %eax,(%esp)
  800086:	e8 3d 13 00 00       	call   8013c8 <ipc_send>
  80008b:	eb bd                	jmp    80004a <umain+0x17>
	}

	while (1) {
		uint32_t i = ipc_recv(&who, 0, 0);
  80008d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800094:	00 
  800095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80009c:	00 
  80009d:	89 34 24             	mov    %esi,(%esp)
  8000a0:	e8 bb 12 00 00       	call   801360 <ipc_recv>
  8000a5:	89 c3                	mov    %eax,%ebx
		cprintf("%x got %d from %x\n", sys_getenvid(), i, who);
  8000a7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8000aa:	e8 56 0b 00 00       	call   800c05 <sys_getenvid>
  8000af:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8000b3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8000b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8000bb:	c7 04 24 f6 17 80 00 	movl   $0x8017f6,(%esp)
  8000c2:	e8 33 01 00 00       	call   8001fa <cprintf>
		if (i == 10)
  8000c7:	83 fb 0a             	cmp    $0xa,%ebx
  8000ca:	74 27                	je     8000f3 <umain+0xc0>
			return;
		i++;
  8000cc:	83 c3 01             	add    $0x1,%ebx
		ipc_send(who, i, 0, 0);
  8000cf:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8000d6:	00 
  8000d7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8000de:	00 
  8000df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8000e6:	89 04 24             	mov    %eax,(%esp)
  8000e9:	e8 da 12 00 00       	call   8013c8 <ipc_send>
		if (i == 10)
  8000ee:	83 fb 0a             	cmp    $0xa,%ebx
  8000f1:	75 9a                	jne    80008d <umain+0x5a>
			return;
	}

}
  8000f3:	83 c4 2c             	add    $0x2c,%esp
  8000f6:	5b                   	pop    %ebx
  8000f7:	5e                   	pop    %esi
  8000f8:	5f                   	pop    %edi
  8000f9:	5d                   	pop    %ebp
  8000fa:	c3                   	ret    

008000fb <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000fb:	55                   	push   %ebp
  8000fc:	89 e5                	mov    %esp,%ebp
  8000fe:	56                   	push   %esi
  8000ff:	53                   	push   %ebx
  800100:	83 ec 10             	sub    $0x10,%esp
  800103:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800106:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  800109:	e8 f7 0a 00 00       	call   800c05 <sys_getenvid>
	thisenv = envs+ENVX(envid);
  80010e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800113:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800116:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80011b:	a3 04 20 80 00       	mov    %eax,0x802004
	
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800120:	85 db                	test   %ebx,%ebx
  800122:	7e 07                	jle    80012b <libmain+0x30>
		binaryname = argv[0];
  800124:	8b 06                	mov    (%esi),%eax
  800126:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80012b:	89 74 24 04          	mov    %esi,0x4(%esp)
  80012f:	89 1c 24             	mov    %ebx,(%esp)
  800132:	e8 fc fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800137:	e8 07 00 00 00       	call   800143 <exit>
}
  80013c:	83 c4 10             	add    $0x10,%esp
  80013f:	5b                   	pop    %ebx
  800140:	5e                   	pop    %esi
  800141:	5d                   	pop    %ebp
  800142:	c3                   	ret    

00800143 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800143:	55                   	push   %ebp
  800144:	89 e5                	mov    %esp,%ebp
  800146:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800150:	e8 5e 0a 00 00       	call   800bb3 <sys_env_destroy>
}
  800155:	c9                   	leave  
  800156:	c3                   	ret    

00800157 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800157:	55                   	push   %ebp
  800158:	89 e5                	mov    %esp,%ebp
  80015a:	53                   	push   %ebx
  80015b:	83 ec 14             	sub    $0x14,%esp
  80015e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800161:	8b 13                	mov    (%ebx),%edx
  800163:	8d 42 01             	lea    0x1(%edx),%eax
  800166:	89 03                	mov    %eax,(%ebx)
  800168:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80016b:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80016f:	3d ff 00 00 00       	cmp    $0xff,%eax
  800174:	75 19                	jne    80018f <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800176:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80017d:	00 
  80017e:	8d 43 08             	lea    0x8(%ebx),%eax
  800181:	89 04 24             	mov    %eax,(%esp)
  800184:	e8 ed 09 00 00       	call   800b76 <sys_cputs>
		b->idx = 0;
  800189:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80018f:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800193:	83 c4 14             	add    $0x14,%esp
  800196:	5b                   	pop    %ebx
  800197:	5d                   	pop    %ebp
  800198:	c3                   	ret    

00800199 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800199:	55                   	push   %ebp
  80019a:	89 e5                	mov    %esp,%ebp
  80019c:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8001a2:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001a9:	00 00 00 
	b.cnt = 0;
  8001ac:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001b3:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001b6:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001bd:	8b 45 08             	mov    0x8(%ebp),%eax
  8001c0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001c4:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001ce:	c7 04 24 57 01 80 00 	movl   $0x800157,(%esp)
  8001d5:	e8 b4 01 00 00       	call   80038e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001da:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8001e0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001e4:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ea:	89 04 24             	mov    %eax,(%esp)
  8001ed:	e8 84 09 00 00       	call   800b76 <sys_cputs>

	return b.cnt;
}
  8001f2:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001f8:	c9                   	leave  
  8001f9:	c3                   	ret    

008001fa <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001fa:	55                   	push   %ebp
  8001fb:	89 e5                	mov    %esp,%ebp
  8001fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800200:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800203:	89 44 24 04          	mov    %eax,0x4(%esp)
  800207:	8b 45 08             	mov    0x8(%ebp),%eax
  80020a:	89 04 24             	mov    %eax,(%esp)
  80020d:	e8 87 ff ff ff       	call   800199 <vcprintf>
	va_end(ap);

	return cnt;
}
  800212:	c9                   	leave  
  800213:	c3                   	ret    
  800214:	66 90                	xchg   %ax,%ax
  800216:	66 90                	xchg   %ax,%ax
  800218:	66 90                	xchg   %ax,%ax
  80021a:	66 90                	xchg   %ax,%ax
  80021c:	66 90                	xchg   %ax,%ax
  80021e:	66 90                	xchg   %ax,%ax

00800220 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800220:	55                   	push   %ebp
  800221:	89 e5                	mov    %esp,%ebp
  800223:	57                   	push   %edi
  800224:	56                   	push   %esi
  800225:	53                   	push   %ebx
  800226:	83 ec 3c             	sub    $0x3c,%esp
  800229:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80022c:	89 d7                	mov    %edx,%edi
  80022e:	8b 45 08             	mov    0x8(%ebp),%eax
  800231:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800234:	8b 45 0c             	mov    0xc(%ebp),%eax
  800237:	89 c3                	mov    %eax,%ebx
  800239:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80023c:	8b 45 10             	mov    0x10(%ebp),%eax
  80023f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800242:	b9 00 00 00 00       	mov    $0x0,%ecx
  800247:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80024a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80024d:	39 d9                	cmp    %ebx,%ecx
  80024f:	72 05                	jb     800256 <printnum+0x36>
  800251:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800254:	77 69                	ja     8002bf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800256:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800259:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80025d:	83 ee 01             	sub    $0x1,%esi
  800260:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800264:	89 44 24 08          	mov    %eax,0x8(%esp)
  800268:	8b 44 24 08          	mov    0x8(%esp),%eax
  80026c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800270:	89 c3                	mov    %eax,%ebx
  800272:	89 d6                	mov    %edx,%esi
  800274:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800277:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80027a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80027e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800282:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800285:	89 04 24             	mov    %eax,(%esp)
  800288:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80028b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80028f:	e8 ac 12 00 00       	call   801540 <__udivdi3>
  800294:	89 d9                	mov    %ebx,%ecx
  800296:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80029a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80029e:	89 04 24             	mov    %eax,(%esp)
  8002a1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002a5:	89 fa                	mov    %edi,%edx
  8002a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002aa:	e8 71 ff ff ff       	call   800220 <printnum>
  8002af:	eb 1b                	jmp    8002cc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002b1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002b5:	8b 45 18             	mov    0x18(%ebp),%eax
  8002b8:	89 04 24             	mov    %eax,(%esp)
  8002bb:	ff d3                	call   *%ebx
  8002bd:	eb 03                	jmp    8002c2 <printnum+0xa2>
  8002bf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002c2:	83 ee 01             	sub    $0x1,%esi
  8002c5:	85 f6                	test   %esi,%esi
  8002c7:	7f e8                	jg     8002b1 <printnum+0x91>
  8002c9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002cc:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002d0:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8002d4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8002d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8002da:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002de:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8002e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002e5:	89 04 24             	mov    %eax,(%esp)
  8002e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002ef:	e8 7c 13 00 00       	call   801670 <__umoddi3>
  8002f4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002f8:	0f be 80 13 18 80 00 	movsbl 0x801813(%eax),%eax
  8002ff:	89 04 24             	mov    %eax,(%esp)
  800302:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800305:	ff d0                	call   *%eax
}
  800307:	83 c4 3c             	add    $0x3c,%esp
  80030a:	5b                   	pop    %ebx
  80030b:	5e                   	pop    %esi
  80030c:	5f                   	pop    %edi
  80030d:	5d                   	pop    %ebp
  80030e:	c3                   	ret    

0080030f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80030f:	55                   	push   %ebp
  800310:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800312:	83 fa 01             	cmp    $0x1,%edx
  800315:	7e 0e                	jle    800325 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800317:	8b 10                	mov    (%eax),%edx
  800319:	8d 4a 08             	lea    0x8(%edx),%ecx
  80031c:	89 08                	mov    %ecx,(%eax)
  80031e:	8b 02                	mov    (%edx),%eax
  800320:	8b 52 04             	mov    0x4(%edx),%edx
  800323:	eb 22                	jmp    800347 <getuint+0x38>
	else if (lflag)
  800325:	85 d2                	test   %edx,%edx
  800327:	74 10                	je     800339 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800329:	8b 10                	mov    (%eax),%edx
  80032b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80032e:	89 08                	mov    %ecx,(%eax)
  800330:	8b 02                	mov    (%edx),%eax
  800332:	ba 00 00 00 00       	mov    $0x0,%edx
  800337:	eb 0e                	jmp    800347 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800339:	8b 10                	mov    (%eax),%edx
  80033b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80033e:	89 08                	mov    %ecx,(%eax)
  800340:	8b 02                	mov    (%edx),%eax
  800342:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800347:	5d                   	pop    %ebp
  800348:	c3                   	ret    

00800349 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800349:	55                   	push   %ebp
  80034a:	89 e5                	mov    %esp,%ebp
  80034c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80034f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800353:	8b 10                	mov    (%eax),%edx
  800355:	3b 50 04             	cmp    0x4(%eax),%edx
  800358:	73 0a                	jae    800364 <sprintputch+0x1b>
		*b->buf++ = ch;
  80035a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80035d:	89 08                	mov    %ecx,(%eax)
  80035f:	8b 45 08             	mov    0x8(%ebp),%eax
  800362:	88 02                	mov    %al,(%edx)
}
  800364:	5d                   	pop    %ebp
  800365:	c3                   	ret    

00800366 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800366:	55                   	push   %ebp
  800367:	89 e5                	mov    %esp,%ebp
  800369:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80036c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80036f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800373:	8b 45 10             	mov    0x10(%ebp),%eax
  800376:	89 44 24 08          	mov    %eax,0x8(%esp)
  80037a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80037d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800381:	8b 45 08             	mov    0x8(%ebp),%eax
  800384:	89 04 24             	mov    %eax,(%esp)
  800387:	e8 02 00 00 00       	call   80038e <vprintfmt>
	va_end(ap);
}
  80038c:	c9                   	leave  
  80038d:	c3                   	ret    

0080038e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80038e:	55                   	push   %ebp
  80038f:	89 e5                	mov    %esp,%ebp
  800391:	57                   	push   %edi
  800392:	56                   	push   %esi
  800393:	53                   	push   %ebx
  800394:	83 ec 3c             	sub    $0x3c,%esp
  800397:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80039a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80039d:	eb 14                	jmp    8003b3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80039f:	85 c0                	test   %eax,%eax
  8003a1:	0f 84 b3 03 00 00    	je     80075a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  8003a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003ab:	89 04 24             	mov    %eax,(%esp)
  8003ae:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003b1:	89 f3                	mov    %esi,%ebx
  8003b3:	8d 73 01             	lea    0x1(%ebx),%esi
  8003b6:	0f b6 03             	movzbl (%ebx),%eax
  8003b9:	83 f8 25             	cmp    $0x25,%eax
  8003bc:	75 e1                	jne    80039f <vprintfmt+0x11>
  8003be:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8003c2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  8003c9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  8003d0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8003d7:	ba 00 00 00 00       	mov    $0x0,%edx
  8003dc:	eb 1d                	jmp    8003fb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003de:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003e0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  8003e4:	eb 15                	jmp    8003fb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003e8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  8003ec:	eb 0d                	jmp    8003fb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8003ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003f1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8003f4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fb:	8d 5e 01             	lea    0x1(%esi),%ebx
  8003fe:	0f b6 0e             	movzbl (%esi),%ecx
  800401:	0f b6 c1             	movzbl %cl,%eax
  800404:	83 e9 23             	sub    $0x23,%ecx
  800407:	80 f9 55             	cmp    $0x55,%cl
  80040a:	0f 87 2a 03 00 00    	ja     80073a <vprintfmt+0x3ac>
  800410:	0f b6 c9             	movzbl %cl,%ecx
  800413:	ff 24 8d e0 18 80 00 	jmp    *0x8018e0(,%ecx,4)
  80041a:	89 de                	mov    %ebx,%esi
  80041c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800421:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800424:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800428:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80042b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80042e:	83 fb 09             	cmp    $0x9,%ebx
  800431:	77 36                	ja     800469 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800433:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800436:	eb e9                	jmp    800421 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800438:	8b 45 14             	mov    0x14(%ebp),%eax
  80043b:	8d 48 04             	lea    0x4(%eax),%ecx
  80043e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800441:	8b 00                	mov    (%eax),%eax
  800443:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800446:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800448:	eb 22                	jmp    80046c <vprintfmt+0xde>
  80044a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80044d:	85 c9                	test   %ecx,%ecx
  80044f:	b8 00 00 00 00       	mov    $0x0,%eax
  800454:	0f 49 c1             	cmovns %ecx,%eax
  800457:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045a:	89 de                	mov    %ebx,%esi
  80045c:	eb 9d                	jmp    8003fb <vprintfmt+0x6d>
  80045e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800460:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800467:	eb 92                	jmp    8003fb <vprintfmt+0x6d>
  800469:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80046c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800470:	79 89                	jns    8003fb <vprintfmt+0x6d>
  800472:	e9 77 ff ff ff       	jmp    8003ee <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800477:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80047a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80047c:	e9 7a ff ff ff       	jmp    8003fb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800481:	8b 45 14             	mov    0x14(%ebp),%eax
  800484:	8d 50 04             	lea    0x4(%eax),%edx
  800487:	89 55 14             	mov    %edx,0x14(%ebp)
  80048a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80048e:	8b 00                	mov    (%eax),%eax
  800490:	89 04 24             	mov    %eax,(%esp)
  800493:	ff 55 08             	call   *0x8(%ebp)
			break;
  800496:	e9 18 ff ff ff       	jmp    8003b3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80049b:	8b 45 14             	mov    0x14(%ebp),%eax
  80049e:	8d 50 04             	lea    0x4(%eax),%edx
  8004a1:	89 55 14             	mov    %edx,0x14(%ebp)
  8004a4:	8b 00                	mov    (%eax),%eax
  8004a6:	99                   	cltd   
  8004a7:	31 d0                	xor    %edx,%eax
  8004a9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004ab:	83 f8 09             	cmp    $0x9,%eax
  8004ae:	7f 0b                	jg     8004bb <vprintfmt+0x12d>
  8004b0:	8b 14 85 40 1a 80 00 	mov    0x801a40(,%eax,4),%edx
  8004b7:	85 d2                	test   %edx,%edx
  8004b9:	75 20                	jne    8004db <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8004bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8004bf:	c7 44 24 08 2b 18 80 	movl   $0x80182b,0x8(%esp)
  8004c6:	00 
  8004c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8004ce:	89 04 24             	mov    %eax,(%esp)
  8004d1:	e8 90 fe ff ff       	call   800366 <printfmt>
  8004d6:	e9 d8 fe ff ff       	jmp    8003b3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8004db:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8004df:	c7 44 24 08 34 18 80 	movl   $0x801834,0x8(%esp)
  8004e6:	00 
  8004e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004eb:	8b 45 08             	mov    0x8(%ebp),%eax
  8004ee:	89 04 24             	mov    %eax,(%esp)
  8004f1:	e8 70 fe ff ff       	call   800366 <printfmt>
  8004f6:	e9 b8 fe ff ff       	jmp    8003b3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004fb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8004fe:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800501:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800504:	8b 45 14             	mov    0x14(%ebp),%eax
  800507:	8d 50 04             	lea    0x4(%eax),%edx
  80050a:	89 55 14             	mov    %edx,0x14(%ebp)
  80050d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80050f:	85 f6                	test   %esi,%esi
  800511:	b8 24 18 80 00       	mov    $0x801824,%eax
  800516:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800519:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80051d:	0f 84 97 00 00 00    	je     8005ba <vprintfmt+0x22c>
  800523:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800527:	0f 8e 9b 00 00 00    	jle    8005c8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80052d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800531:	89 34 24             	mov    %esi,(%esp)
  800534:	e8 cf 02 00 00       	call   800808 <strnlen>
  800539:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80053c:	29 c2                	sub    %eax,%edx
  80053e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800541:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800545:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800548:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80054b:	8b 75 08             	mov    0x8(%ebp),%esi
  80054e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800551:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800553:	eb 0f                	jmp    800564 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800555:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800559:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80055c:	89 04 24             	mov    %eax,(%esp)
  80055f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800561:	83 eb 01             	sub    $0x1,%ebx
  800564:	85 db                	test   %ebx,%ebx
  800566:	7f ed                	jg     800555 <vprintfmt+0x1c7>
  800568:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80056b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80056e:	85 d2                	test   %edx,%edx
  800570:	b8 00 00 00 00       	mov    $0x0,%eax
  800575:	0f 49 c2             	cmovns %edx,%eax
  800578:	29 c2                	sub    %eax,%edx
  80057a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80057d:	89 d7                	mov    %edx,%edi
  80057f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800582:	eb 50                	jmp    8005d4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800584:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800588:	74 1e                	je     8005a8 <vprintfmt+0x21a>
  80058a:	0f be d2             	movsbl %dl,%edx
  80058d:	83 ea 20             	sub    $0x20,%edx
  800590:	83 fa 5e             	cmp    $0x5e,%edx
  800593:	76 13                	jbe    8005a8 <vprintfmt+0x21a>
					putch('?', putdat);
  800595:	8b 45 0c             	mov    0xc(%ebp),%eax
  800598:	89 44 24 04          	mov    %eax,0x4(%esp)
  80059c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8005a3:	ff 55 08             	call   *0x8(%ebp)
  8005a6:	eb 0d                	jmp    8005b5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  8005a8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8005ab:	89 54 24 04          	mov    %edx,0x4(%esp)
  8005af:	89 04 24             	mov    %eax,(%esp)
  8005b2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005b5:	83 ef 01             	sub    $0x1,%edi
  8005b8:	eb 1a                	jmp    8005d4 <vprintfmt+0x246>
  8005ba:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005bd:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8005c0:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005c6:	eb 0c                	jmp    8005d4 <vprintfmt+0x246>
  8005c8:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005cb:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8005ce:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005d4:	83 c6 01             	add    $0x1,%esi
  8005d7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  8005db:	0f be c2             	movsbl %dl,%eax
  8005de:	85 c0                	test   %eax,%eax
  8005e0:	74 27                	je     800609 <vprintfmt+0x27b>
  8005e2:	85 db                	test   %ebx,%ebx
  8005e4:	78 9e                	js     800584 <vprintfmt+0x1f6>
  8005e6:	83 eb 01             	sub    $0x1,%ebx
  8005e9:	79 99                	jns    800584 <vprintfmt+0x1f6>
  8005eb:	89 f8                	mov    %edi,%eax
  8005ed:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8005f0:	8b 75 08             	mov    0x8(%ebp),%esi
  8005f3:	89 c3                	mov    %eax,%ebx
  8005f5:	eb 1a                	jmp    800611 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005fb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800602:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800604:	83 eb 01             	sub    $0x1,%ebx
  800607:	eb 08                	jmp    800611 <vprintfmt+0x283>
  800609:	89 fb                	mov    %edi,%ebx
  80060b:	8b 75 08             	mov    0x8(%ebp),%esi
  80060e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800611:	85 db                	test   %ebx,%ebx
  800613:	7f e2                	jg     8005f7 <vprintfmt+0x269>
  800615:	89 75 08             	mov    %esi,0x8(%ebp)
  800618:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80061b:	e9 93 fd ff ff       	jmp    8003b3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800620:	83 fa 01             	cmp    $0x1,%edx
  800623:	7e 16                	jle    80063b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800625:	8b 45 14             	mov    0x14(%ebp),%eax
  800628:	8d 50 08             	lea    0x8(%eax),%edx
  80062b:	89 55 14             	mov    %edx,0x14(%ebp)
  80062e:	8b 50 04             	mov    0x4(%eax),%edx
  800631:	8b 00                	mov    (%eax),%eax
  800633:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800636:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800639:	eb 32                	jmp    80066d <vprintfmt+0x2df>
	else if (lflag)
  80063b:	85 d2                	test   %edx,%edx
  80063d:	74 18                	je     800657 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80063f:	8b 45 14             	mov    0x14(%ebp),%eax
  800642:	8d 50 04             	lea    0x4(%eax),%edx
  800645:	89 55 14             	mov    %edx,0x14(%ebp)
  800648:	8b 30                	mov    (%eax),%esi
  80064a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80064d:	89 f0                	mov    %esi,%eax
  80064f:	c1 f8 1f             	sar    $0x1f,%eax
  800652:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800655:	eb 16                	jmp    80066d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800657:	8b 45 14             	mov    0x14(%ebp),%eax
  80065a:	8d 50 04             	lea    0x4(%eax),%edx
  80065d:	89 55 14             	mov    %edx,0x14(%ebp)
  800660:	8b 30                	mov    (%eax),%esi
  800662:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800665:	89 f0                	mov    %esi,%eax
  800667:	c1 f8 1f             	sar    $0x1f,%eax
  80066a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80066d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800670:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800673:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800678:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80067c:	0f 89 80 00 00 00    	jns    800702 <vprintfmt+0x374>
				putch('-', putdat);
  800682:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800686:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80068d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800690:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800693:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800696:	f7 d8                	neg    %eax
  800698:	83 d2 00             	adc    $0x0,%edx
  80069b:	f7 da                	neg    %edx
			}
			base = 10;
  80069d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8006a2:	eb 5e                	jmp    800702 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006a4:	8d 45 14             	lea    0x14(%ebp),%eax
  8006a7:	e8 63 fc ff ff       	call   80030f <getuint>
			base = 10;
  8006ac:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8006b1:	eb 4f                	jmp    800702 <vprintfmt+0x374>
			// Replace this with your code.
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint (&ap, lflag);
  8006b3:	8d 45 14             	lea    0x14(%ebp),%eax
  8006b6:	e8 54 fc ff ff       	call   80030f <getuint>
			base = 8;
  8006bb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8006c0:	eb 40                	jmp    800702 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  8006c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006c6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006cd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8006d0:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006d4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8006db:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006de:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e1:	8d 50 04             	lea    0x4(%eax),%edx
  8006e4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006e7:	8b 00                	mov    (%eax),%eax
  8006e9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006ee:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006f3:	eb 0d                	jmp    800702 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006f5:	8d 45 14             	lea    0x14(%ebp),%eax
  8006f8:	e8 12 fc ff ff       	call   80030f <getuint>
			base = 16;
  8006fd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800702:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800706:	89 74 24 10          	mov    %esi,0x10(%esp)
  80070a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80070d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800711:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800715:	89 04 24             	mov    %eax,(%esp)
  800718:	89 54 24 04          	mov    %edx,0x4(%esp)
  80071c:	89 fa                	mov    %edi,%edx
  80071e:	8b 45 08             	mov    0x8(%ebp),%eax
  800721:	e8 fa fa ff ff       	call   800220 <printnum>
			break;
  800726:	e9 88 fc ff ff       	jmp    8003b3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80072b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80072f:	89 04 24             	mov    %eax,(%esp)
  800732:	ff 55 08             	call   *0x8(%ebp)
			break;
  800735:	e9 79 fc ff ff       	jmp    8003b3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80073a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80073e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800745:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800748:	89 f3                	mov    %esi,%ebx
  80074a:	eb 03                	jmp    80074f <vprintfmt+0x3c1>
  80074c:	83 eb 01             	sub    $0x1,%ebx
  80074f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800753:	75 f7                	jne    80074c <vprintfmt+0x3be>
  800755:	e9 59 fc ff ff       	jmp    8003b3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80075a:	83 c4 3c             	add    $0x3c,%esp
  80075d:	5b                   	pop    %ebx
  80075e:	5e                   	pop    %esi
  80075f:	5f                   	pop    %edi
  800760:	5d                   	pop    %ebp
  800761:	c3                   	ret    

00800762 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800762:	55                   	push   %ebp
  800763:	89 e5                	mov    %esp,%ebp
  800765:	83 ec 28             	sub    $0x28,%esp
  800768:	8b 45 08             	mov    0x8(%ebp),%eax
  80076b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80076e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800771:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800775:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800778:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80077f:	85 c0                	test   %eax,%eax
  800781:	74 30                	je     8007b3 <vsnprintf+0x51>
  800783:	85 d2                	test   %edx,%edx
  800785:	7e 2c                	jle    8007b3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800787:	8b 45 14             	mov    0x14(%ebp),%eax
  80078a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80078e:	8b 45 10             	mov    0x10(%ebp),%eax
  800791:	89 44 24 08          	mov    %eax,0x8(%esp)
  800795:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800798:	89 44 24 04          	mov    %eax,0x4(%esp)
  80079c:	c7 04 24 49 03 80 00 	movl   $0x800349,(%esp)
  8007a3:	e8 e6 fb ff ff       	call   80038e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007ab:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007b1:	eb 05                	jmp    8007b8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007b3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007b8:	c9                   	leave  
  8007b9:	c3                   	ret    

008007ba <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007ba:	55                   	push   %ebp
  8007bb:	89 e5                	mov    %esp,%ebp
  8007bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007c0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007c7:	8b 45 10             	mov    0x10(%ebp),%eax
  8007ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007d5:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d8:	89 04 24             	mov    %eax,(%esp)
  8007db:	e8 82 ff ff ff       	call   800762 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007e0:	c9                   	leave  
  8007e1:	c3                   	ret    
  8007e2:	66 90                	xchg   %ax,%ax
  8007e4:	66 90                	xchg   %ax,%ax
  8007e6:	66 90                	xchg   %ax,%ax
  8007e8:	66 90                	xchg   %ax,%ax
  8007ea:	66 90                	xchg   %ax,%ax
  8007ec:	66 90                	xchg   %ax,%ax
  8007ee:	66 90                	xchg   %ax,%ax

008007f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007f0:	55                   	push   %ebp
  8007f1:	89 e5                	mov    %esp,%ebp
  8007f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f6:	b8 00 00 00 00       	mov    $0x0,%eax
  8007fb:	eb 03                	jmp    800800 <strlen+0x10>
		n++;
  8007fd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800800:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800804:	75 f7                	jne    8007fd <strlen+0xd>
		n++;
	return n;
}
  800806:	5d                   	pop    %ebp
  800807:	c3                   	ret    

00800808 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800808:	55                   	push   %ebp
  800809:	89 e5                	mov    %esp,%ebp
  80080b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80080e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800811:	b8 00 00 00 00       	mov    $0x0,%eax
  800816:	eb 03                	jmp    80081b <strnlen+0x13>
		n++;
  800818:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80081b:	39 d0                	cmp    %edx,%eax
  80081d:	74 06                	je     800825 <strnlen+0x1d>
  80081f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800823:	75 f3                	jne    800818 <strnlen+0x10>
		n++;
	return n;
}
  800825:	5d                   	pop    %ebp
  800826:	c3                   	ret    

00800827 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800827:	55                   	push   %ebp
  800828:	89 e5                	mov    %esp,%ebp
  80082a:	53                   	push   %ebx
  80082b:	8b 45 08             	mov    0x8(%ebp),%eax
  80082e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800831:	89 c2                	mov    %eax,%edx
  800833:	83 c2 01             	add    $0x1,%edx
  800836:	83 c1 01             	add    $0x1,%ecx
  800839:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80083d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800840:	84 db                	test   %bl,%bl
  800842:	75 ef                	jne    800833 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800844:	5b                   	pop    %ebx
  800845:	5d                   	pop    %ebp
  800846:	c3                   	ret    

00800847 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800847:	55                   	push   %ebp
  800848:	89 e5                	mov    %esp,%ebp
  80084a:	53                   	push   %ebx
  80084b:	83 ec 08             	sub    $0x8,%esp
  80084e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800851:	89 1c 24             	mov    %ebx,(%esp)
  800854:	e8 97 ff ff ff       	call   8007f0 <strlen>
	strcpy(dst + len, src);
  800859:	8b 55 0c             	mov    0xc(%ebp),%edx
  80085c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800860:	01 d8                	add    %ebx,%eax
  800862:	89 04 24             	mov    %eax,(%esp)
  800865:	e8 bd ff ff ff       	call   800827 <strcpy>
	return dst;
}
  80086a:	89 d8                	mov    %ebx,%eax
  80086c:	83 c4 08             	add    $0x8,%esp
  80086f:	5b                   	pop    %ebx
  800870:	5d                   	pop    %ebp
  800871:	c3                   	ret    

00800872 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800872:	55                   	push   %ebp
  800873:	89 e5                	mov    %esp,%ebp
  800875:	56                   	push   %esi
  800876:	53                   	push   %ebx
  800877:	8b 75 08             	mov    0x8(%ebp),%esi
  80087a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80087d:	89 f3                	mov    %esi,%ebx
  80087f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800882:	89 f2                	mov    %esi,%edx
  800884:	eb 0f                	jmp    800895 <strncpy+0x23>
		*dst++ = *src;
  800886:	83 c2 01             	add    $0x1,%edx
  800889:	0f b6 01             	movzbl (%ecx),%eax
  80088c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80088f:	80 39 01             	cmpb   $0x1,(%ecx)
  800892:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800895:	39 da                	cmp    %ebx,%edx
  800897:	75 ed                	jne    800886 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800899:	89 f0                	mov    %esi,%eax
  80089b:	5b                   	pop    %ebx
  80089c:	5e                   	pop    %esi
  80089d:	5d                   	pop    %ebp
  80089e:	c3                   	ret    

0080089f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80089f:	55                   	push   %ebp
  8008a0:	89 e5                	mov    %esp,%ebp
  8008a2:	56                   	push   %esi
  8008a3:	53                   	push   %ebx
  8008a4:	8b 75 08             	mov    0x8(%ebp),%esi
  8008a7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8008ad:	89 f0                	mov    %esi,%eax
  8008af:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008b3:	85 c9                	test   %ecx,%ecx
  8008b5:	75 0b                	jne    8008c2 <strlcpy+0x23>
  8008b7:	eb 1d                	jmp    8008d6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008b9:	83 c0 01             	add    $0x1,%eax
  8008bc:	83 c2 01             	add    $0x1,%edx
  8008bf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008c2:	39 d8                	cmp    %ebx,%eax
  8008c4:	74 0b                	je     8008d1 <strlcpy+0x32>
  8008c6:	0f b6 0a             	movzbl (%edx),%ecx
  8008c9:	84 c9                	test   %cl,%cl
  8008cb:	75 ec                	jne    8008b9 <strlcpy+0x1a>
  8008cd:	89 c2                	mov    %eax,%edx
  8008cf:	eb 02                	jmp    8008d3 <strlcpy+0x34>
  8008d1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8008d3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8008d6:	29 f0                	sub    %esi,%eax
}
  8008d8:	5b                   	pop    %ebx
  8008d9:	5e                   	pop    %esi
  8008da:	5d                   	pop    %ebp
  8008db:	c3                   	ret    

008008dc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008dc:	55                   	push   %ebp
  8008dd:	89 e5                	mov    %esp,%ebp
  8008df:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008e2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008e5:	eb 06                	jmp    8008ed <strcmp+0x11>
		p++, q++;
  8008e7:	83 c1 01             	add    $0x1,%ecx
  8008ea:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008ed:	0f b6 01             	movzbl (%ecx),%eax
  8008f0:	84 c0                	test   %al,%al
  8008f2:	74 04                	je     8008f8 <strcmp+0x1c>
  8008f4:	3a 02                	cmp    (%edx),%al
  8008f6:	74 ef                	je     8008e7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008f8:	0f b6 c0             	movzbl %al,%eax
  8008fb:	0f b6 12             	movzbl (%edx),%edx
  8008fe:	29 d0                	sub    %edx,%eax
}
  800900:	5d                   	pop    %ebp
  800901:	c3                   	ret    

00800902 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800902:	55                   	push   %ebp
  800903:	89 e5                	mov    %esp,%ebp
  800905:	53                   	push   %ebx
  800906:	8b 45 08             	mov    0x8(%ebp),%eax
  800909:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090c:	89 c3                	mov    %eax,%ebx
  80090e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800911:	eb 06                	jmp    800919 <strncmp+0x17>
		n--, p++, q++;
  800913:	83 c0 01             	add    $0x1,%eax
  800916:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800919:	39 d8                	cmp    %ebx,%eax
  80091b:	74 15                	je     800932 <strncmp+0x30>
  80091d:	0f b6 08             	movzbl (%eax),%ecx
  800920:	84 c9                	test   %cl,%cl
  800922:	74 04                	je     800928 <strncmp+0x26>
  800924:	3a 0a                	cmp    (%edx),%cl
  800926:	74 eb                	je     800913 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800928:	0f b6 00             	movzbl (%eax),%eax
  80092b:	0f b6 12             	movzbl (%edx),%edx
  80092e:	29 d0                	sub    %edx,%eax
  800930:	eb 05                	jmp    800937 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800932:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800937:	5b                   	pop    %ebx
  800938:	5d                   	pop    %ebp
  800939:	c3                   	ret    

0080093a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80093a:	55                   	push   %ebp
  80093b:	89 e5                	mov    %esp,%ebp
  80093d:	8b 45 08             	mov    0x8(%ebp),%eax
  800940:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800944:	eb 07                	jmp    80094d <strchr+0x13>
		if (*s == c)
  800946:	38 ca                	cmp    %cl,%dl
  800948:	74 0f                	je     800959 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80094a:	83 c0 01             	add    $0x1,%eax
  80094d:	0f b6 10             	movzbl (%eax),%edx
  800950:	84 d2                	test   %dl,%dl
  800952:	75 f2                	jne    800946 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800954:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800959:	5d                   	pop    %ebp
  80095a:	c3                   	ret    

0080095b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80095b:	55                   	push   %ebp
  80095c:	89 e5                	mov    %esp,%ebp
  80095e:	8b 45 08             	mov    0x8(%ebp),%eax
  800961:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800965:	eb 07                	jmp    80096e <strfind+0x13>
		if (*s == c)
  800967:	38 ca                	cmp    %cl,%dl
  800969:	74 0a                	je     800975 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80096b:	83 c0 01             	add    $0x1,%eax
  80096e:	0f b6 10             	movzbl (%eax),%edx
  800971:	84 d2                	test   %dl,%dl
  800973:	75 f2                	jne    800967 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800975:	5d                   	pop    %ebp
  800976:	c3                   	ret    

00800977 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800977:	55                   	push   %ebp
  800978:	89 e5                	mov    %esp,%ebp
  80097a:	57                   	push   %edi
  80097b:	56                   	push   %esi
  80097c:	53                   	push   %ebx
  80097d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800980:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800983:	85 c9                	test   %ecx,%ecx
  800985:	74 36                	je     8009bd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800987:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80098d:	75 28                	jne    8009b7 <memset+0x40>
  80098f:	f6 c1 03             	test   $0x3,%cl
  800992:	75 23                	jne    8009b7 <memset+0x40>
		c &= 0xFF;
  800994:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800998:	89 d3                	mov    %edx,%ebx
  80099a:	c1 e3 08             	shl    $0x8,%ebx
  80099d:	89 d6                	mov    %edx,%esi
  80099f:	c1 e6 18             	shl    $0x18,%esi
  8009a2:	89 d0                	mov    %edx,%eax
  8009a4:	c1 e0 10             	shl    $0x10,%eax
  8009a7:	09 f0                	or     %esi,%eax
  8009a9:	09 c2                	or     %eax,%edx
  8009ab:	89 d0                	mov    %edx,%eax
  8009ad:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009af:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009b2:	fc                   	cld    
  8009b3:	f3 ab                	rep stos %eax,%es:(%edi)
  8009b5:	eb 06                	jmp    8009bd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ba:	fc                   	cld    
  8009bb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009bd:	89 f8                	mov    %edi,%eax
  8009bf:	5b                   	pop    %ebx
  8009c0:	5e                   	pop    %esi
  8009c1:	5f                   	pop    %edi
  8009c2:	5d                   	pop    %ebp
  8009c3:	c3                   	ret    

008009c4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009c4:	55                   	push   %ebp
  8009c5:	89 e5                	mov    %esp,%ebp
  8009c7:	57                   	push   %edi
  8009c8:	56                   	push   %esi
  8009c9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cc:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009d2:	39 c6                	cmp    %eax,%esi
  8009d4:	73 35                	jae    800a0b <memmove+0x47>
  8009d6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009d9:	39 d0                	cmp    %edx,%eax
  8009db:	73 2e                	jae    800a0b <memmove+0x47>
		s += n;
		d += n;
  8009dd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  8009e0:	89 d6                	mov    %edx,%esi
  8009e2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009e4:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009ea:	75 13                	jne    8009ff <memmove+0x3b>
  8009ec:	f6 c1 03             	test   $0x3,%cl
  8009ef:	75 0e                	jne    8009ff <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8009f1:	83 ef 04             	sub    $0x4,%edi
  8009f4:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009f7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  8009fa:	fd                   	std    
  8009fb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009fd:	eb 09                	jmp    800a08 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  8009ff:	83 ef 01             	sub    $0x1,%edi
  800a02:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a05:	fd                   	std    
  800a06:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a08:	fc                   	cld    
  800a09:	eb 1d                	jmp    800a28 <memmove+0x64>
  800a0b:	89 f2                	mov    %esi,%edx
  800a0d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a0f:	f6 c2 03             	test   $0x3,%dl
  800a12:	75 0f                	jne    800a23 <memmove+0x5f>
  800a14:	f6 c1 03             	test   $0x3,%cl
  800a17:	75 0a                	jne    800a23 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a19:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a1c:	89 c7                	mov    %eax,%edi
  800a1e:	fc                   	cld    
  800a1f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a21:	eb 05                	jmp    800a28 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a23:	89 c7                	mov    %eax,%edi
  800a25:	fc                   	cld    
  800a26:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a28:	5e                   	pop    %esi
  800a29:	5f                   	pop    %edi
  800a2a:	5d                   	pop    %ebp
  800a2b:	c3                   	ret    

00800a2c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a2c:	55                   	push   %ebp
  800a2d:	89 e5                	mov    %esp,%ebp
  800a2f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a32:	8b 45 10             	mov    0x10(%ebp),%eax
  800a35:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a39:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a3c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a40:	8b 45 08             	mov    0x8(%ebp),%eax
  800a43:	89 04 24             	mov    %eax,(%esp)
  800a46:	e8 79 ff ff ff       	call   8009c4 <memmove>
}
  800a4b:	c9                   	leave  
  800a4c:	c3                   	ret    

00800a4d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a4d:	55                   	push   %ebp
  800a4e:	89 e5                	mov    %esp,%ebp
  800a50:	56                   	push   %esi
  800a51:	53                   	push   %ebx
  800a52:	8b 55 08             	mov    0x8(%ebp),%edx
  800a55:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a58:	89 d6                	mov    %edx,%esi
  800a5a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a5d:	eb 1a                	jmp    800a79 <memcmp+0x2c>
		if (*s1 != *s2)
  800a5f:	0f b6 02             	movzbl (%edx),%eax
  800a62:	0f b6 19             	movzbl (%ecx),%ebx
  800a65:	38 d8                	cmp    %bl,%al
  800a67:	74 0a                	je     800a73 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a69:	0f b6 c0             	movzbl %al,%eax
  800a6c:	0f b6 db             	movzbl %bl,%ebx
  800a6f:	29 d8                	sub    %ebx,%eax
  800a71:	eb 0f                	jmp    800a82 <memcmp+0x35>
		s1++, s2++;
  800a73:	83 c2 01             	add    $0x1,%edx
  800a76:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a79:	39 f2                	cmp    %esi,%edx
  800a7b:	75 e2                	jne    800a5f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a82:	5b                   	pop    %ebx
  800a83:	5e                   	pop    %esi
  800a84:	5d                   	pop    %ebp
  800a85:	c3                   	ret    

00800a86 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a86:	55                   	push   %ebp
  800a87:	89 e5                	mov    %esp,%ebp
  800a89:	8b 45 08             	mov    0x8(%ebp),%eax
  800a8c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a8f:	89 c2                	mov    %eax,%edx
  800a91:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a94:	eb 07                	jmp    800a9d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a96:	38 08                	cmp    %cl,(%eax)
  800a98:	74 07                	je     800aa1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a9a:	83 c0 01             	add    $0x1,%eax
  800a9d:	39 d0                	cmp    %edx,%eax
  800a9f:	72 f5                	jb     800a96 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800aa1:	5d                   	pop    %ebp
  800aa2:	c3                   	ret    

00800aa3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800aa3:	55                   	push   %ebp
  800aa4:	89 e5                	mov    %esp,%ebp
  800aa6:	57                   	push   %edi
  800aa7:	56                   	push   %esi
  800aa8:	53                   	push   %ebx
  800aa9:	8b 55 08             	mov    0x8(%ebp),%edx
  800aac:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aaf:	eb 03                	jmp    800ab4 <strtol+0x11>
		s++;
  800ab1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ab4:	0f b6 0a             	movzbl (%edx),%ecx
  800ab7:	80 f9 09             	cmp    $0x9,%cl
  800aba:	74 f5                	je     800ab1 <strtol+0xe>
  800abc:	80 f9 20             	cmp    $0x20,%cl
  800abf:	74 f0                	je     800ab1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ac1:	80 f9 2b             	cmp    $0x2b,%cl
  800ac4:	75 0a                	jne    800ad0 <strtol+0x2d>
		s++;
  800ac6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ac9:	bf 00 00 00 00       	mov    $0x0,%edi
  800ace:	eb 11                	jmp    800ae1 <strtol+0x3e>
  800ad0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ad5:	80 f9 2d             	cmp    $0x2d,%cl
  800ad8:	75 07                	jne    800ae1 <strtol+0x3e>
		s++, neg = 1;
  800ada:	8d 52 01             	lea    0x1(%edx),%edx
  800add:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ae1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800ae6:	75 15                	jne    800afd <strtol+0x5a>
  800ae8:	80 3a 30             	cmpb   $0x30,(%edx)
  800aeb:	75 10                	jne    800afd <strtol+0x5a>
  800aed:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800af1:	75 0a                	jne    800afd <strtol+0x5a>
		s += 2, base = 16;
  800af3:	83 c2 02             	add    $0x2,%edx
  800af6:	b8 10 00 00 00       	mov    $0x10,%eax
  800afb:	eb 10                	jmp    800b0d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800afd:	85 c0                	test   %eax,%eax
  800aff:	75 0c                	jne    800b0d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b01:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b03:	80 3a 30             	cmpb   $0x30,(%edx)
  800b06:	75 05                	jne    800b0d <strtol+0x6a>
		s++, base = 8;
  800b08:	83 c2 01             	add    $0x1,%edx
  800b0b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b0d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b12:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b15:	0f b6 0a             	movzbl (%edx),%ecx
  800b18:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b1b:	89 f0                	mov    %esi,%eax
  800b1d:	3c 09                	cmp    $0x9,%al
  800b1f:	77 08                	ja     800b29 <strtol+0x86>
			dig = *s - '0';
  800b21:	0f be c9             	movsbl %cl,%ecx
  800b24:	83 e9 30             	sub    $0x30,%ecx
  800b27:	eb 20                	jmp    800b49 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b29:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b2c:	89 f0                	mov    %esi,%eax
  800b2e:	3c 19                	cmp    $0x19,%al
  800b30:	77 08                	ja     800b3a <strtol+0x97>
			dig = *s - 'a' + 10;
  800b32:	0f be c9             	movsbl %cl,%ecx
  800b35:	83 e9 57             	sub    $0x57,%ecx
  800b38:	eb 0f                	jmp    800b49 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b3a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b3d:	89 f0                	mov    %esi,%eax
  800b3f:	3c 19                	cmp    $0x19,%al
  800b41:	77 16                	ja     800b59 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800b43:	0f be c9             	movsbl %cl,%ecx
  800b46:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b49:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b4c:	7d 0f                	jge    800b5d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800b4e:	83 c2 01             	add    $0x1,%edx
  800b51:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800b55:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800b57:	eb bc                	jmp    800b15 <strtol+0x72>
  800b59:	89 d8                	mov    %ebx,%eax
  800b5b:	eb 02                	jmp    800b5f <strtol+0xbc>
  800b5d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800b5f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b63:	74 05                	je     800b6a <strtol+0xc7>
		*endptr = (char *) s;
  800b65:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b68:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800b6a:	f7 d8                	neg    %eax
  800b6c:	85 ff                	test   %edi,%edi
  800b6e:	0f 44 c3             	cmove  %ebx,%eax
}
  800b71:	5b                   	pop    %ebx
  800b72:	5e                   	pop    %esi
  800b73:	5f                   	pop    %edi
  800b74:	5d                   	pop    %ebp
  800b75:	c3                   	ret    

00800b76 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b76:	55                   	push   %ebp
  800b77:	89 e5                	mov    %esp,%ebp
  800b79:	57                   	push   %edi
  800b7a:	56                   	push   %esi
  800b7b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7c:	b8 00 00 00 00       	mov    $0x0,%eax
  800b81:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b84:	8b 55 08             	mov    0x8(%ebp),%edx
  800b87:	89 c3                	mov    %eax,%ebx
  800b89:	89 c7                	mov    %eax,%edi
  800b8b:	89 c6                	mov    %eax,%esi
  800b8d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b8f:	5b                   	pop    %ebx
  800b90:	5e                   	pop    %esi
  800b91:	5f                   	pop    %edi
  800b92:	5d                   	pop    %ebp
  800b93:	c3                   	ret    

00800b94 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b94:	55                   	push   %ebp
  800b95:	89 e5                	mov    %esp,%ebp
  800b97:	57                   	push   %edi
  800b98:	56                   	push   %esi
  800b99:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b9a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b9f:	b8 01 00 00 00       	mov    $0x1,%eax
  800ba4:	89 d1                	mov    %edx,%ecx
  800ba6:	89 d3                	mov    %edx,%ebx
  800ba8:	89 d7                	mov    %edx,%edi
  800baa:	89 d6                	mov    %edx,%esi
  800bac:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800bae:	5b                   	pop    %ebx
  800baf:	5e                   	pop    %esi
  800bb0:	5f                   	pop    %edi
  800bb1:	5d                   	pop    %ebp
  800bb2:	c3                   	ret    

00800bb3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800bb3:	55                   	push   %ebp
  800bb4:	89 e5                	mov    %esp,%ebp
  800bb6:	57                   	push   %edi
  800bb7:	56                   	push   %esi
  800bb8:	53                   	push   %ebx
  800bb9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bbc:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bc1:	b8 03 00 00 00       	mov    $0x3,%eax
  800bc6:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc9:	89 cb                	mov    %ecx,%ebx
  800bcb:	89 cf                	mov    %ecx,%edi
  800bcd:	89 ce                	mov    %ecx,%esi
  800bcf:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bd1:	85 c0                	test   %eax,%eax
  800bd3:	7e 28                	jle    800bfd <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bd5:	89 44 24 10          	mov    %eax,0x10(%esp)
  800bd9:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800be0:	00 
  800be1:	c7 44 24 08 68 1a 80 	movl   $0x801a68,0x8(%esp)
  800be8:	00 
  800be9:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800bf0:	00 
  800bf1:	c7 04 24 85 1a 80 00 	movl   $0x801a85,(%esp)
  800bf8:	e8 6a 08 00 00       	call   801467 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bfd:	83 c4 2c             	add    $0x2c,%esp
  800c00:	5b                   	pop    %ebx
  800c01:	5e                   	pop    %esi
  800c02:	5f                   	pop    %edi
  800c03:	5d                   	pop    %ebp
  800c04:	c3                   	ret    

00800c05 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c05:	55                   	push   %ebp
  800c06:	89 e5                	mov    %esp,%ebp
  800c08:	57                   	push   %edi
  800c09:	56                   	push   %esi
  800c0a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c0b:	ba 00 00 00 00       	mov    $0x0,%edx
  800c10:	b8 02 00 00 00       	mov    $0x2,%eax
  800c15:	89 d1                	mov    %edx,%ecx
  800c17:	89 d3                	mov    %edx,%ebx
  800c19:	89 d7                	mov    %edx,%edi
  800c1b:	89 d6                	mov    %edx,%esi
  800c1d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c1f:	5b                   	pop    %ebx
  800c20:	5e                   	pop    %esi
  800c21:	5f                   	pop    %edi
  800c22:	5d                   	pop    %ebp
  800c23:	c3                   	ret    

00800c24 <sys_yield>:

void
sys_yield(void)
{
  800c24:	55                   	push   %ebp
  800c25:	89 e5                	mov    %esp,%ebp
  800c27:	57                   	push   %edi
  800c28:	56                   	push   %esi
  800c29:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c2a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c2f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c34:	89 d1                	mov    %edx,%ecx
  800c36:	89 d3                	mov    %edx,%ebx
  800c38:	89 d7                	mov    %edx,%edi
  800c3a:	89 d6                	mov    %edx,%esi
  800c3c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c3e:	5b                   	pop    %ebx
  800c3f:	5e                   	pop    %esi
  800c40:	5f                   	pop    %edi
  800c41:	5d                   	pop    %ebp
  800c42:	c3                   	ret    

00800c43 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c43:	55                   	push   %ebp
  800c44:	89 e5                	mov    %esp,%ebp
  800c46:	57                   	push   %edi
  800c47:	56                   	push   %esi
  800c48:	53                   	push   %ebx
  800c49:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c4c:	be 00 00 00 00       	mov    $0x0,%esi
  800c51:	b8 04 00 00 00       	mov    $0x4,%eax
  800c56:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c59:	8b 55 08             	mov    0x8(%ebp),%edx
  800c5c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c5f:	89 f7                	mov    %esi,%edi
  800c61:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c63:	85 c0                	test   %eax,%eax
  800c65:	7e 28                	jle    800c8f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c67:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c6b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800c72:	00 
  800c73:	c7 44 24 08 68 1a 80 	movl   $0x801a68,0x8(%esp)
  800c7a:	00 
  800c7b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c82:	00 
  800c83:	c7 04 24 85 1a 80 00 	movl   $0x801a85,(%esp)
  800c8a:	e8 d8 07 00 00       	call   801467 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c8f:	83 c4 2c             	add    $0x2c,%esp
  800c92:	5b                   	pop    %ebx
  800c93:	5e                   	pop    %esi
  800c94:	5f                   	pop    %edi
  800c95:	5d                   	pop    %ebp
  800c96:	c3                   	ret    

00800c97 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c97:	55                   	push   %ebp
  800c98:	89 e5                	mov    %esp,%ebp
  800c9a:	57                   	push   %edi
  800c9b:	56                   	push   %esi
  800c9c:	53                   	push   %ebx
  800c9d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ca0:	b8 05 00 00 00       	mov    $0x5,%eax
  800ca5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ca8:	8b 55 08             	mov    0x8(%ebp),%edx
  800cab:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800cae:	8b 7d 14             	mov    0x14(%ebp),%edi
  800cb1:	8b 75 18             	mov    0x18(%ebp),%esi
  800cb4:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cb6:	85 c0                	test   %eax,%eax
  800cb8:	7e 28                	jle    800ce2 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cba:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cbe:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800cc5:	00 
  800cc6:	c7 44 24 08 68 1a 80 	movl   $0x801a68,0x8(%esp)
  800ccd:	00 
  800cce:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cd5:	00 
  800cd6:	c7 04 24 85 1a 80 00 	movl   $0x801a85,(%esp)
  800cdd:	e8 85 07 00 00       	call   801467 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800ce2:	83 c4 2c             	add    $0x2c,%esp
  800ce5:	5b                   	pop    %ebx
  800ce6:	5e                   	pop    %esi
  800ce7:	5f                   	pop    %edi
  800ce8:	5d                   	pop    %ebp
  800ce9:	c3                   	ret    

00800cea <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800cea:	55                   	push   %ebp
  800ceb:	89 e5                	mov    %esp,%ebp
  800ced:	57                   	push   %edi
  800cee:	56                   	push   %esi
  800cef:	53                   	push   %ebx
  800cf0:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cf3:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cf8:	b8 06 00 00 00       	mov    $0x6,%eax
  800cfd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d00:	8b 55 08             	mov    0x8(%ebp),%edx
  800d03:	89 df                	mov    %ebx,%edi
  800d05:	89 de                	mov    %ebx,%esi
  800d07:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d09:	85 c0                	test   %eax,%eax
  800d0b:	7e 28                	jle    800d35 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d0d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d11:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800d18:	00 
  800d19:	c7 44 24 08 68 1a 80 	movl   $0x801a68,0x8(%esp)
  800d20:	00 
  800d21:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d28:	00 
  800d29:	c7 04 24 85 1a 80 00 	movl   $0x801a85,(%esp)
  800d30:	e8 32 07 00 00       	call   801467 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800d35:	83 c4 2c             	add    $0x2c,%esp
  800d38:	5b                   	pop    %ebx
  800d39:	5e                   	pop    %esi
  800d3a:	5f                   	pop    %edi
  800d3b:	5d                   	pop    %ebp
  800d3c:	c3                   	ret    

00800d3d <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800d3d:	55                   	push   %ebp
  800d3e:	89 e5                	mov    %esp,%ebp
  800d40:	57                   	push   %edi
  800d41:	56                   	push   %esi
  800d42:	53                   	push   %ebx
  800d43:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d46:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d4b:	b8 08 00 00 00       	mov    $0x8,%eax
  800d50:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d53:	8b 55 08             	mov    0x8(%ebp),%edx
  800d56:	89 df                	mov    %ebx,%edi
  800d58:	89 de                	mov    %ebx,%esi
  800d5a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d5c:	85 c0                	test   %eax,%eax
  800d5e:	7e 28                	jle    800d88 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d60:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d64:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800d6b:	00 
  800d6c:	c7 44 24 08 68 1a 80 	movl   $0x801a68,0x8(%esp)
  800d73:	00 
  800d74:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d7b:	00 
  800d7c:	c7 04 24 85 1a 80 00 	movl   $0x801a85,(%esp)
  800d83:	e8 df 06 00 00       	call   801467 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d88:	83 c4 2c             	add    $0x2c,%esp
  800d8b:	5b                   	pop    %ebx
  800d8c:	5e                   	pop    %esi
  800d8d:	5f                   	pop    %edi
  800d8e:	5d                   	pop    %ebp
  800d8f:	c3                   	ret    

00800d90 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d90:	55                   	push   %ebp
  800d91:	89 e5                	mov    %esp,%ebp
  800d93:	57                   	push   %edi
  800d94:	56                   	push   %esi
  800d95:	53                   	push   %ebx
  800d96:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d99:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d9e:	b8 09 00 00 00       	mov    $0x9,%eax
  800da3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800da6:	8b 55 08             	mov    0x8(%ebp),%edx
  800da9:	89 df                	mov    %ebx,%edi
  800dab:	89 de                	mov    %ebx,%esi
  800dad:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800daf:	85 c0                	test   %eax,%eax
  800db1:	7e 28                	jle    800ddb <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800db3:	89 44 24 10          	mov    %eax,0x10(%esp)
  800db7:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800dbe:	00 
  800dbf:	c7 44 24 08 68 1a 80 	movl   $0x801a68,0x8(%esp)
  800dc6:	00 
  800dc7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800dce:	00 
  800dcf:	c7 04 24 85 1a 80 00 	movl   $0x801a85,(%esp)
  800dd6:	e8 8c 06 00 00       	call   801467 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800ddb:	83 c4 2c             	add    $0x2c,%esp
  800dde:	5b                   	pop    %ebx
  800ddf:	5e                   	pop    %esi
  800de0:	5f                   	pop    %edi
  800de1:	5d                   	pop    %ebp
  800de2:	c3                   	ret    

00800de3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800de3:	55                   	push   %ebp
  800de4:	89 e5                	mov    %esp,%ebp
  800de6:	57                   	push   %edi
  800de7:	56                   	push   %esi
  800de8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800de9:	be 00 00 00 00       	mov    $0x0,%esi
  800dee:	b8 0b 00 00 00       	mov    $0xb,%eax
  800df3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800df6:	8b 55 08             	mov    0x8(%ebp),%edx
  800df9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800dfc:	8b 7d 14             	mov    0x14(%ebp),%edi
  800dff:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800e01:	5b                   	pop    %ebx
  800e02:	5e                   	pop    %esi
  800e03:	5f                   	pop    %edi
  800e04:	5d                   	pop    %ebp
  800e05:	c3                   	ret    

00800e06 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800e06:	55                   	push   %ebp
  800e07:	89 e5                	mov    %esp,%ebp
  800e09:	57                   	push   %edi
  800e0a:	56                   	push   %esi
  800e0b:	53                   	push   %ebx
  800e0c:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e0f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800e14:	b8 0c 00 00 00       	mov    $0xc,%eax
  800e19:	8b 55 08             	mov    0x8(%ebp),%edx
  800e1c:	89 cb                	mov    %ecx,%ebx
  800e1e:	89 cf                	mov    %ecx,%edi
  800e20:	89 ce                	mov    %ecx,%esi
  800e22:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e24:	85 c0                	test   %eax,%eax
  800e26:	7e 28                	jle    800e50 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e28:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e2c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800e33:	00 
  800e34:	c7 44 24 08 68 1a 80 	movl   $0x801a68,0x8(%esp)
  800e3b:	00 
  800e3c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e43:	00 
  800e44:	c7 04 24 85 1a 80 00 	movl   $0x801a85,(%esp)
  800e4b:	e8 17 06 00 00       	call   801467 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800e50:	83 c4 2c             	add    $0x2c,%esp
  800e53:	5b                   	pop    %ebx
  800e54:	5e                   	pop    %esi
  800e55:	5f                   	pop    %edi
  800e56:	5d                   	pop    %ebp
  800e57:	c3                   	ret    

00800e58 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800e58:	55                   	push   %ebp
  800e59:	89 e5                	mov    %esp,%ebp
  800e5b:	53                   	push   %ebx
  800e5c:	83 ec 24             	sub    $0x24,%esp
  800e5f:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  800e62:	8b 18                	mov    (%eax),%ebx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) != FEC_WR)
  800e64:	f6 40 04 02          	testb  $0x2,0x4(%eax)
  800e68:	75 1c                	jne    800e86 <pgfault+0x2e>
		panic("Invalid page fault access.");
  800e6a:	c7 44 24 08 93 1a 80 	movl   $0x801a93,0x8(%esp)
  800e71:	00 
  800e72:	c7 44 24 04 1d 00 00 	movl   $0x1d,0x4(%esp)
  800e79:	00 
  800e7a:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  800e81:	e8 e1 05 00 00       	call   801467 <_panic>

	if (!(uvpt[(uint32_t)addr>>12] & PTE_COW))
  800e86:	89 d8                	mov    %ebx,%eax
  800e88:	c1 e8 0c             	shr    $0xc,%eax
  800e8b:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800e92:	f6 c4 08             	test   $0x8,%ah
  800e95:	75 1c                	jne    800eb3 <pgfault+0x5b>
		panic("Not copy-on-write page.");
  800e97:	c7 44 24 08 b9 1a 80 	movl   $0x801ab9,0x8(%esp)
  800e9e:	00 
  800e9f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800ea6:	00 
  800ea7:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  800eae:	e8 b4 05 00 00       	call   801467 <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr,PGSIZE);
  800eb3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if ((r=sys_page_alloc(0,(void*)PFTEMP,PTE_P|PTE_U|PTE_W)) < 0)
  800eb9:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800ec0:	00 
  800ec1:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800ec8:	00 
  800ec9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800ed0:	e8 6e fd ff ff       	call   800c43 <sys_page_alloc>
  800ed5:	85 c0                	test   %eax,%eax
  800ed7:	79 1c                	jns    800ef5 <pgfault+0x9d>
		panic("FGFAULT PAGE ALLOC FAILURE.");
  800ed9:	c7 44 24 08 d1 1a 80 	movl   $0x801ad1,0x8(%esp)
  800ee0:	00 
  800ee1:	c7 44 24 04 2b 00 00 	movl   $0x2b,0x4(%esp)
  800ee8:	00 
  800ee9:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  800ef0:	e8 72 05 00 00       	call   801467 <_panic>
	memmove((void*)PFTEMP,addr,PGSIZE);
  800ef5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  800efc:	00 
  800efd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800f01:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  800f08:	e8 b7 fa ff ff       	call   8009c4 <memmove>
	if ((r=sys_page_unmap(0,addr)) < 0)
  800f0d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800f11:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f18:	e8 cd fd ff ff       	call   800cea <sys_page_unmap>
  800f1d:	85 c0                	test   %eax,%eax
  800f1f:	79 1c                	jns    800f3d <pgfault+0xe5>
		panic("PGFAULT PAGE UNMAP FAILURE.");
  800f21:	c7 44 24 08 ed 1a 80 	movl   $0x801aed,0x8(%esp)
  800f28:	00 
  800f29:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
  800f30:	00 
  800f31:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  800f38:	e8 2a 05 00 00       	call   801467 <_panic>
	if ((r=sys_page_map(0,(void*)PFTEMP,0,addr,PTE_P|PTE_U|PTE_W)) < 0)
  800f3d:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  800f44:	00 
  800f45:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800f49:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800f50:	00 
  800f51:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f58:	00 
  800f59:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f60:	e8 32 fd ff ff       	call   800c97 <sys_page_map>
  800f65:	85 c0                	test   %eax,%eax
  800f67:	79 1c                	jns    800f85 <pgfault+0x12d>
		panic("PGFAULT PAGE MAP FAILURE.");
  800f69:	c7 44 24 08 09 1b 80 	movl   $0x801b09,0x8(%esp)
  800f70:	00 
  800f71:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  800f78:	00 
  800f79:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  800f80:	e8 e2 04 00 00       	call   801467 <_panic>
	if ((r=sys_page_unmap(0,(void*)PFTEMP)) < 0)
  800f85:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f8c:	00 
  800f8d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f94:	e8 51 fd ff ff       	call   800cea <sys_page_unmap>
  800f99:	85 c0                	test   %eax,%eax
  800f9b:	79 1c                	jns    800fb9 <pgfault+0x161>
		panic("PGFAULT PAGE UNMAP FAILURE.");
  800f9d:	c7 44 24 08 ed 1a 80 	movl   $0x801aed,0x8(%esp)
  800fa4:	00 
  800fa5:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  800fac:	00 
  800fad:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  800fb4:	e8 ae 04 00 00       	call   801467 <_panic>


	//panic("pgfault not implemented");
}
  800fb9:	83 c4 24             	add    $0x24,%esp
  800fbc:	5b                   	pop    %ebx
  800fbd:	5d                   	pop    %ebp
  800fbe:	c3                   	ret    

00800fbf <duppage>:
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
  800fbf:	55                   	push   %ebp
  800fc0:	89 e5                	mov    %esp,%ebp
  800fc2:	53                   	push   %ebx
  800fc3:	83 ec 24             	sub    $0x24,%esp
	int r;

	// LAB 4: Your code here.
	//panic("duppage not implemented");
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) {
  800fc6:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  800fcd:	f6 c1 02             	test   $0x2,%cl
  800fd0:	75 10                	jne    800fe2 <duppage+0x23>
  800fd2:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  800fd9:	f6 c5 08             	test   $0x8,%ch
  800fdc:	0f 84 89 00 00 00    	je     80106b <duppage+0xac>
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),envid,(void*)(pn*PGSIZE),PTE_P|PTE_U|PTE_COW)) < 0)
  800fe2:	89 d3                	mov    %edx,%ebx
  800fe4:	c1 e3 0c             	shl    $0xc,%ebx
  800fe7:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  800fee:	00 
  800fef:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800ff3:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ff7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ffb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801002:	e8 90 fc ff ff       	call   800c97 <sys_page_map>
  801007:	85 c0                	test   %eax,%eax
  801009:	79 1c                	jns    801027 <duppage+0x68>
			panic("DUPPAGE PAGE MAP FAILURE.");
  80100b:	c7 44 24 08 23 1b 80 	movl   $0x801b23,0x8(%esp)
  801012:	00 
  801013:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
  80101a:	00 
  80101b:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  801022:	e8 40 04 00 00       	call   801467 <_panic>
	
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),0,(void*)(pn*PGSIZE),PTE_P|PTE_U|PTE_COW)) < 0)
  801027:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  80102e:	00 
  80102f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  801033:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80103a:	00 
  80103b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80103f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801046:	e8 4c fc ff ff       	call   800c97 <sys_page_map>
  80104b:	85 c0                	test   %eax,%eax
  80104d:	79 68                	jns    8010b7 <duppage+0xf8>
			panic("DUPPAGE PAGE MAP FAILURE.");
  80104f:	c7 44 24 08 23 1b 80 	movl   $0x801b23,0x8(%esp)
  801056:	00 
  801057:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
  80105e:	00 
  80105f:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  801066:	e8 fc 03 00 00       	call   801467 <_panic>

	} else {
		if ((r=sys_page_map(0,(void*)(pn*PGSIZE),envid,(void*)(pn*PGSIZE),uvpt[pn]&0xfff)) < 0)
  80106b:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
  801072:	c1 e2 0c             	shl    $0xc,%edx
  801075:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
  80107b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80107f:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801083:	89 44 24 08          	mov    %eax,0x8(%esp)
  801087:	89 54 24 04          	mov    %edx,0x4(%esp)
  80108b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801092:	e8 00 fc ff ff       	call   800c97 <sys_page_map>
  801097:	85 c0                	test   %eax,%eax
  801099:	79 1c                	jns    8010b7 <duppage+0xf8>
			panic("DUPPAGE PAGE MAP FAILURE.");
  80109b:	c7 44 24 08 23 1b 80 	movl   $0x801b23,0x8(%esp)
  8010a2:	00 
  8010a3:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  8010aa:	00 
  8010ab:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  8010b2:	e8 b0 03 00 00       	call   801467 <_panic>
	}
	return 0;
}
  8010b7:	b8 00 00 00 00       	mov    $0x0,%eax
  8010bc:	83 c4 24             	add    $0x24,%esp
  8010bf:	5b                   	pop    %ebx
  8010c0:	5d                   	pop    %ebp
  8010c1:	c3                   	ret    

008010c2 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  8010c2:	55                   	push   %ebp
  8010c3:	89 e5                	mov    %esp,%ebp
  8010c5:	57                   	push   %edi
  8010c6:	56                   	push   %esi
  8010c7:	53                   	push   %ebx
  8010c8:	83 ec 1c             	sub    $0x1c,%esp
	int r;
	envid_t envid;
	uint32_t n;
	
	//1. Setup pgfault() handler
	set_pgfault_handler(pgfault);
  8010cb:	c7 04 24 58 0e 80 00 	movl   $0x800e58,(%esp)
  8010d2:	e8 e6 03 00 00       	call   8014bd <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  8010d7:	b8 07 00 00 00       	mov    $0x7,%eax
  8010dc:	cd 30                	int    $0x30
  8010de:	89 c6                	mov    %eax,%esi

	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
  8010e0:	85 c0                	test   %eax,%eax
  8010e2:	79 20                	jns    801104 <fork+0x42>
		panic("sys_exofork: %e", envid);
  8010e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8010e8:	c7 44 24 08 3d 1b 80 	movl   $0x801b3d,0x8(%esp)
  8010ef:	00 
  8010f0:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  8010f7:	00 
  8010f8:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  8010ff:	e8 63 03 00 00       	call   801467 <_panic>
  801104:	89 c7                	mov    %eax,%edi
	}

	// We're the parent.

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {
  801106:	b8 00 00 00 00       	mov    $0x0,%eax
	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
  80110b:	bb 00 00 00 00       	mov    $0x0,%ebx
  801110:	85 f6                	test   %esi,%esi
  801112:	75 21                	jne    801135 <fork+0x73>
		// We're the child.
		thisenv = &envs[ENVX(sys_getenvid())];
  801114:	e8 ec fa ff ff       	call   800c05 <sys_getenvid>
  801119:	25 ff 03 00 00       	and    $0x3ff,%eax
  80111e:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801121:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801126:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  80112b:	b8 00 00 00 00       	mov    $0x0,%eax
  801130:	e9 ac 00 00 00       	jmp    8011e1 <fork+0x11f>

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {

		//3.1 Copy page mapping using duppage
		if ((uvpd[n>>10] & PTE_P)) {
  801135:	89 da                	mov    %ebx,%edx
  801137:	c1 ea 0a             	shr    $0xa,%edx
  80113a:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  801141:	f6 c2 01             	test   $0x1,%dl
  801144:	74 21                	je     801167 <fork+0xa5>
			if ((uvpt[n] & PTE_P))
  801146:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  80114d:	f6 c2 01             	test   $0x1,%dl
  801150:	74 10                	je     801162 <fork+0xa0>
				if (n*PGSIZE != UXSTACKTOP-PGSIZE)
  801152:	3d 00 f0 bf ee       	cmp    $0xeebff000,%eax
  801157:	74 09                	je     801162 <fork+0xa0>
					duppage(envid,n);
  801159:	89 da                	mov    %ebx,%edx
  80115b:	89 f8                	mov    %edi,%eax
  80115d:	e8 5d fe ff ff       	call   800fbf <duppage>
			n++;
  801162:	83 c3 01             	add    $0x1,%ebx
  801165:	eb 0c                	jmp    801173 <fork+0xb1>
		} else {
			n=n+NPDENTRIES-n%NPDENTRIES;
  801167:	81 e3 00 fc ff ff    	and    $0xfffffc00,%ebx
  80116d:	81 c3 00 04 00 00    	add    $0x400,%ebx
	}

	// We're the parent.

	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; ) {
  801173:	89 d8                	mov    %ebx,%eax
  801175:	c1 e0 0c             	shl    $0xc,%eax
  801178:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
  80117d:	76 b6                	jbe    801135 <fork+0x73>
		}
	 	
	}
	
	//3.2 Copy exception stack page
	sys_page_alloc(envid,(void*)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W);
  80117f:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801186:	00 
  801187:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80118e:	ee 
  80118f:	89 34 24             	mov    %esi,(%esp)
  801192:	e8 ac fa ff ff       	call   800c43 <sys_page_alloc>

	//4. Set the pgfault handler for child
	sys_env_set_pgfault_upcall(envid,thisenv->env_pgfault_upcall);
  801197:	a1 04 20 80 00       	mov    0x802004,%eax
  80119c:	8b 40 64             	mov    0x64(%eax),%eax
  80119f:	89 44 24 04          	mov    %eax,0x4(%esp)
  8011a3:	89 34 24             	mov    %esi,(%esp)
  8011a6:	e8 e5 fb ff ff       	call   800d90 <sys_env_set_pgfault_upcall>


	//5. Mark the child as runnable and return
	if ((r=sys_env_set_status(envid,ENV_RUNNABLE))<0) {
  8011ab:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8011b2:	00 
  8011b3:	89 34 24             	mov    %esi,(%esp)
  8011b6:	e8 82 fb ff ff       	call   800d3d <sys_env_set_status>
  8011bb:	85 c0                	test   %eax,%eax
  8011bd:	79 20                	jns    8011df <fork+0x11d>
		panic("sys_env_set_status: %e", r);
  8011bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011c3:	c7 44 24 08 4d 1b 80 	movl   $0x801b4d,0x8(%esp)
  8011ca:	00 
  8011cb:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
  8011d2:	00 
  8011d3:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  8011da:	e8 88 02 00 00       	call   801467 <_panic>
	}

	return envid;
  8011df:	89 f0                	mov    %esi,%eax

}
  8011e1:	83 c4 1c             	add    $0x1c,%esp
  8011e4:	5b                   	pop    %ebx
  8011e5:	5e                   	pop    %esi
  8011e6:	5f                   	pop    %edi
  8011e7:	5d                   	pop    %ebp
  8011e8:	c3                   	ret    

008011e9 <sfork>:

// Challenge!
int
sfork(void)
{
  8011e9:	55                   	push   %ebp
  8011ea:	89 e5                	mov    %esp,%ebp
  8011ec:	57                   	push   %edi
  8011ed:	56                   	push   %esi
  8011ee:	53                   	push   %ebx
  8011ef:	83 ec 2c             	sub    $0x2c,%esp
	int r;
	envid_t envid;
	uint32_t n;
	
	//1. Setup pgfault() handler
	set_pgfault_handler(pgfault);
  8011f2:	c7 04 24 58 0e 80 00 	movl   $0x800e58,(%esp)
  8011f9:	e8 bf 02 00 00       	call   8014bd <set_pgfault_handler>
  8011fe:	b8 07 00 00 00       	mov    $0x7,%eax
  801203:	cd 30                	int    $0x30
  801205:	89 c6                	mov    %eax,%esi

	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
  801207:	85 c0                	test   %eax,%eax
  801209:	79 20                	jns    80122b <sfork+0x42>
		panic("sys_exofork: %e", envid);
  80120b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80120f:	c7 44 24 08 3d 1b 80 	movl   $0x801b3d,0x8(%esp)
  801216:	00 
  801217:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
  80121e:	00 
  80121f:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  801226:	e8 3c 02 00 00       	call   801467 <_panic>
  80122b:	89 c7                	mov    %eax,%edi
		return 0;
	}

	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {
  80122d:	b8 00 00 00 00       	mov    $0x0,%eax
	//2. Create a child environment
	envid = sys_exofork();

	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
  801232:	bb 00 00 00 00       	mov    $0x0,%ebx
  801237:	85 f6                	test   %esi,%esi
  801239:	75 21                	jne    80125c <sfork+0x73>
		// We're the child.
		thisenv = &envs[ENVX(sys_getenvid())];
  80123b:	e8 c5 f9 ff ff       	call   800c05 <sys_getenvid>
  801240:	25 ff 03 00 00       	and    $0x3ff,%eax
  801245:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801248:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80124d:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  801252:	b8 00 00 00 00       	mov    $0x0,%eax
  801257:	e9 fc 00 00 00       	jmp    801358 <sfork+0x16f>
	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {

		//3.1 Copy stack page mapping using duppage
		if ((uvpd[n>>10] & PTE_P)) {
  80125c:	89 da                	mov    %ebx,%edx
  80125e:	c1 ea 0a             	shr    $0xa,%edx
  801261:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  801268:	f6 c2 01             	test   $0x1,%dl
  80126b:	74 6a                	je     8012d7 <sfork+0xee>
			if ((uvpt[n] & PTE_P)) {
  80126d:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  801274:	f6 c2 01             	test   $0x1,%dl
  801277:	74 59                	je     8012d2 <sfork+0xe9>
				if (n*PGSIZE == USTACKTOP-PGSIZE)
  801279:	3d 00 d0 bf ee       	cmp    $0xeebfd000,%eax
  80127e:	75 0b                	jne    80128b <sfork+0xa2>
					duppage(envid,n);
  801280:	89 da                	mov    %ebx,%edx
  801282:	89 f8                	mov    %edi,%eax
  801284:	e8 36 fd ff ff       	call   800fbf <duppage>
  801289:	eb 47                	jmp    8012d2 <sfork+0xe9>
				else if (n*PGSIZE != UXSTACKTOP-PGSIZE) {
  80128b:	3d 00 f0 bf ee       	cmp    $0xeebff000,%eax
  801290:	74 40                	je     8012d2 <sfork+0xe9>
					//Share-memory copy
					if((r=sys_page_map(0,(void*)(n*PGSIZE),envid,(void*)(n*PGSIZE),PTE_P|PTE_U|PTE_W)) < 0)
  801292:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  801299:	00 
  80129a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80129e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8012a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8012a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8012ad:	e8 e5 f9 ff ff       	call   800c97 <sys_page_map>
  8012b2:	85 c0                	test   %eax,%eax
  8012b4:	79 1c                	jns    8012d2 <sfork+0xe9>
						panic("Shared-memory mapping failure.");
  8012b6:	c7 44 24 08 64 1b 80 	movl   $0x801b64,0x8(%esp)
  8012bd:	00 
  8012be:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  8012c5:	00 
  8012c6:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  8012cd:	e8 95 01 00 00       	call   801467 <_panic>
				}
			}	
			n++;
  8012d2:	83 c3 01             	add    $0x1,%ebx
  8012d5:	eb 0c                	jmp    8012e3 <sfork+0xfa>
		} else {
			n=n+NPDENTRIES-n%NPDENTRIES;
  8012d7:	81 e3 00 fc ff ff    	and    $0xfffffc00,%ebx
  8012dd:	81 c3 00 04 00 00    	add    $0x400,%ebx
		return 0;
	}

	// We're the parent.
	//3. Copy address space of current environment to child's address space
	for (n = 0; n*PGSIZE < UTOP; n++) {
  8012e3:	83 c3 01             	add    $0x1,%ebx
  8012e6:	89 d8                	mov    %ebx,%eax
  8012e8:	c1 e0 0c             	shl    $0xc,%eax
  8012eb:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
  8012f0:	0f 86 66 ff ff ff    	jbe    80125c <sfork+0x73>
			n=n+NPDENTRIES-n%NPDENTRIES;
		}
	}
	
	//3.2 Copy exception stack page
	sys_page_alloc(envid,(void*)(UXSTACKTOP-PGSIZE),PTE_P|PTE_U|PTE_W);
  8012f6:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8012fd:	00 
  8012fe:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  801305:	ee 
  801306:	89 34 24             	mov    %esi,(%esp)
  801309:	e8 35 f9 ff ff       	call   800c43 <sys_page_alloc>

	//4. Set the pgfault handler for child
	sys_env_set_pgfault_upcall(envid,thisenv->env_pgfault_upcall);
  80130e:	a1 04 20 80 00       	mov    0x802004,%eax
  801313:	8b 40 64             	mov    0x64(%eax),%eax
  801316:	89 44 24 04          	mov    %eax,0x4(%esp)
  80131a:	89 34 24             	mov    %esi,(%esp)
  80131d:	e8 6e fa ff ff       	call   800d90 <sys_env_set_pgfault_upcall>

	//5. Mark the child as runnable and return
	if ((r=sys_env_set_status(envid,ENV_RUNNABLE))<0) {
  801322:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  801329:	00 
  80132a:	89 34 24             	mov    %esi,(%esp)
  80132d:	e8 0b fa ff ff       	call   800d3d <sys_env_set_status>
  801332:	85 c0                	test   %eax,%eax
  801334:	79 20                	jns    801356 <sfork+0x16d>
		panic("sys_env_set_status: %e", r);
  801336:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80133a:	c7 44 24 08 4d 1b 80 	movl   $0x801b4d,0x8(%esp)
  801341:	00 
  801342:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  801349:	00 
  80134a:	c7 04 24 ae 1a 80 00 	movl   $0x801aae,(%esp)
  801351:	e8 11 01 00 00       	call   801467 <_panic>
	}

	//return -E_INVAL;
	return envid;
  801356:	89 f0                	mov    %esi,%eax
}
  801358:	83 c4 2c             	add    $0x2c,%esp
  80135b:	5b                   	pop    %ebx
  80135c:	5e                   	pop    %esi
  80135d:	5f                   	pop    %edi
  80135e:	5d                   	pop    %ebp
  80135f:	c3                   	ret    

00801360 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801360:	55                   	push   %ebp
  801361:	89 e5                	mov    %esp,%ebp
  801363:	56                   	push   %esi
  801364:	53                   	push   %ebx
  801365:	83 ec 10             	sub    $0x10,%esp
  801368:	8b 75 08             	mov    0x8(%ebp),%esi
  80136b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80136e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	if (pg == NULL) pg = (void*)0xffffffff;
  801371:	85 c0                	test   %eax,%eax
  801373:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  801378:	0f 44 c2             	cmove  %edx,%eax
	int r = sys_ipc_recv(pg);
  80137b:	89 04 24             	mov    %eax,(%esp)
  80137e:	e8 83 fa ff ff       	call   800e06 <sys_ipc_recv>
	if (r >= 0) {
  801383:	85 c0                	test   %eax,%eax
  801385:	78 26                	js     8013ad <ipc_recv+0x4d>
	if (from_env_store != NULL) *from_env_store = thisenv->env_ipc_from;
  801387:	85 f6                	test   %esi,%esi
  801389:	74 0a                	je     801395 <ipc_recv+0x35>
  80138b:	a1 04 20 80 00       	mov    0x802004,%eax
  801390:	8b 40 74             	mov    0x74(%eax),%eax
  801393:	89 06                	mov    %eax,(%esi)
	if (perm_store != NULL) *perm_store = thisenv->env_ipc_perm;
  801395:	85 db                	test   %ebx,%ebx
  801397:	74 0a                	je     8013a3 <ipc_recv+0x43>
  801399:	a1 04 20 80 00       	mov    0x802004,%eax
  80139e:	8b 40 78             	mov    0x78(%eax),%eax
  8013a1:	89 03                	mov    %eax,(%ebx)
	return thisenv->env_ipc_value;
  8013a3:	a1 04 20 80 00       	mov    0x802004,%eax
  8013a8:	8b 40 70             	mov    0x70(%eax),%eax
  8013ab:	eb 14                	jmp    8013c1 <ipc_recv+0x61>
	} else {
	if (from_env_store != NULL) *from_env_store = 0;
  8013ad:	85 f6                	test   %esi,%esi
  8013af:	74 06                	je     8013b7 <ipc_recv+0x57>
  8013b1:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (perm_store != NULL) *perm_store = 0;
  8013b7:	85 db                	test   %ebx,%ebx
  8013b9:	74 06                	je     8013c1 <ipc_recv+0x61>
  8013bb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	return r;
	}
	//return 0;
}
  8013c1:	83 c4 10             	add    $0x10,%esp
  8013c4:	5b                   	pop    %ebx
  8013c5:	5e                   	pop    %esi
  8013c6:	5d                   	pop    %ebp
  8013c7:	c3                   	ret    

008013c8 <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  8013c8:	55                   	push   %ebp
  8013c9:	89 e5                	mov    %esp,%ebp
  8013cb:	57                   	push   %edi
  8013cc:	56                   	push   %esi
  8013cd:	53                   	push   %ebx
  8013ce:	83 ec 1c             	sub    $0x1c,%esp
  8013d1:	8b 7d 08             	mov    0x8(%ebp),%edi
  8013d4:	8b 75 0c             	mov    0xc(%ebp),%esi
  8013d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	//panic("ipc_send not implemented");
	if (pg == NULL) pg = (void*)0xffffffff;
  8013da:	85 db                	test   %ebx,%ebx
  8013dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8013e1:	0f 44 d8             	cmove  %eax,%ebx
  8013e4:	eb 05                	jmp    8013eb <ipc_send+0x23>
	int r;
	while((r=sys_ipc_try_send(to_env,val,pg,perm)) == -E_IPC_NOT_RECV) {
		sys_yield();
  8013e6:	e8 39 f8 ff ff       	call   800c24 <sys_yield>
{
	// LAB 4: Your code here.
	//panic("ipc_send not implemented");
	if (pg == NULL) pg = (void*)0xffffffff;
	int r;
	while((r=sys_ipc_try_send(to_env,val,pg,perm)) == -E_IPC_NOT_RECV) {
  8013eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8013ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8013f2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8013f6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8013fa:	89 3c 24             	mov    %edi,(%esp)
  8013fd:	e8 e1 f9 ff ff       	call   800de3 <sys_ipc_try_send>
  801402:	83 f8 f8             	cmp    $0xfffffff8,%eax
  801405:	74 df                	je     8013e6 <ipc_send+0x1e>
		sys_yield();
	}
	if (r<0) panic("IPC Send Failure.");
  801407:	85 c0                	test   %eax,%eax
  801409:	79 1c                	jns    801427 <ipc_send+0x5f>
  80140b:	c7 44 24 08 83 1b 80 	movl   $0x801b83,0x8(%esp)
  801412:	00 
  801413:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
  80141a:	00 
  80141b:	c7 04 24 95 1b 80 00 	movl   $0x801b95,(%esp)
  801422:	e8 40 00 00 00       	call   801467 <_panic>
	return;
}
  801427:	83 c4 1c             	add    $0x1c,%esp
  80142a:	5b                   	pop    %ebx
  80142b:	5e                   	pop    %esi
  80142c:	5f                   	pop    %edi
  80142d:	5d                   	pop    %ebp
  80142e:	c3                   	ret    

0080142f <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  80142f:	55                   	push   %ebp
  801430:	89 e5                	mov    %esp,%ebp
  801432:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  801435:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  80143a:	6b d0 7c             	imul   $0x7c,%eax,%edx
  80143d:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  801443:	8b 52 50             	mov    0x50(%edx),%edx
  801446:	39 ca                	cmp    %ecx,%edx
  801448:	75 0d                	jne    801457 <ipc_find_env+0x28>
			return envs[i].env_id;
  80144a:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80144d:	05 08 00 c0 ee       	add    $0xeec00008,%eax
  801452:	8b 40 40             	mov    0x40(%eax),%eax
  801455:	eb 0e                	jmp    801465 <ipc_find_env+0x36>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  801457:	83 c0 01             	add    $0x1,%eax
  80145a:	3d 00 04 00 00       	cmp    $0x400,%eax
  80145f:	75 d9                	jne    80143a <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  801461:	66 b8 00 00          	mov    $0x0,%ax
}
  801465:	5d                   	pop    %ebp
  801466:	c3                   	ret    

00801467 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801467:	55                   	push   %ebp
  801468:	89 e5                	mov    %esp,%ebp
  80146a:	56                   	push   %esi
  80146b:	53                   	push   %ebx
  80146c:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  80146f:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801472:	8b 35 00 20 80 00    	mov    0x802000,%esi
  801478:	e8 88 f7 ff ff       	call   800c05 <sys_getenvid>
  80147d:	8b 55 0c             	mov    0xc(%ebp),%edx
  801480:	89 54 24 10          	mov    %edx,0x10(%esp)
  801484:	8b 55 08             	mov    0x8(%ebp),%edx
  801487:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80148b:	89 74 24 08          	mov    %esi,0x8(%esp)
  80148f:	89 44 24 04          	mov    %eax,0x4(%esp)
  801493:	c7 04 24 a0 1b 80 00 	movl   $0x801ba0,(%esp)
  80149a:	e8 5b ed ff ff       	call   8001fa <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80149f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8014a3:	8b 45 10             	mov    0x10(%ebp),%eax
  8014a6:	89 04 24             	mov    %eax,(%esp)
  8014a9:	e8 eb ec ff ff       	call   800199 <vcprintf>
	cprintf("\n");
  8014ae:	c7 04 24 07 18 80 00 	movl   $0x801807,(%esp)
  8014b5:	e8 40 ed ff ff       	call   8001fa <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8014ba:	cc                   	int3   
  8014bb:	eb fd                	jmp    8014ba <_panic+0x53>

008014bd <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8014bd:	55                   	push   %ebp
  8014be:	89 e5                	mov    %esp,%ebp
  8014c0:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  8014c3:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  8014ca:	75 1d                	jne    8014e9 <set_pgfault_handler+0x2c>
		// First time through!
		// LAB 4: Your code here.
		sys_page_alloc(sys_getenvid(), (void*)(UXSTACKTOP-PGSIZE), PTE_U|PTE_W|PTE_P);
  8014cc:	e8 34 f7 ff ff       	call   800c05 <sys_getenvid>
  8014d1:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8014d8:	00 
  8014d9:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8014e0:	ee 
  8014e1:	89 04 24             	mov    %eax,(%esp)
  8014e4:	e8 5a f7 ff ff       	call   800c43 <sys_page_alloc>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8014e9:	8b 45 08             	mov    0x8(%ebp),%eax
  8014ec:	a3 08 20 80 00       	mov    %eax,0x802008
	//cprintf("UPCALL: %p\n",_pgfault_upcall);
	sys_env_set_pgfault_upcall(sys_getenvid(), _pgfault_upcall);
  8014f1:	e8 0f f7 ff ff       	call   800c05 <sys_getenvid>
  8014f6:	c7 44 24 04 08 15 80 	movl   $0x801508,0x4(%esp)
  8014fd:	00 
  8014fe:	89 04 24             	mov    %eax,(%esp)
  801501:	e8 8a f8 ff ff       	call   800d90 <sys_env_set_pgfault_upcall>
}
  801506:	c9                   	leave  
  801507:	c3                   	ret    

00801508 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801508:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801509:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80150e:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801510:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	addl $8, %esp
  801513:	83 c4 08             	add    $0x8,%esp


	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  801516:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	pushl %eax
  801517:	50                   	push   %eax
	pushl %ebx
  801518:	53                   	push   %ebx
	movl 0x8(%esp), %eax
  801519:	8b 44 24 08          	mov    0x8(%esp),%eax
	movl 0x10(%esp), %ebx
  80151d:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	subl $4, %ebx
  801521:	83 eb 04             	sub    $0x4,%ebx
	movl %eax, (%ebx)
  801524:	89 03                	mov    %eax,(%ebx)
	//Note: you should modify the value before it's popped to %esp
	//      Otherwise, for some reason, the eflags will be wrong!!!
	movl %ebx, 0x10(%esp)
  801526:	89 5c 24 10          	mov    %ebx,0x10(%esp)
	popl %ebx
  80152a:	5b                   	pop    %ebx
	popl %eax
  80152b:	58                   	pop    %eax
	addl $4, %esp
  80152c:	83 c4 04             	add    $0x4,%esp
	popf
  80152f:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  801530:	5c                   	pop    %esp
	//subl $4, %esp

	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  801531:	c3                   	ret    
  801532:	66 90                	xchg   %ax,%ax
  801534:	66 90                	xchg   %ax,%ax
  801536:	66 90                	xchg   %ax,%ax
  801538:	66 90                	xchg   %ax,%ax
  80153a:	66 90                	xchg   %ax,%ax
  80153c:	66 90                	xchg   %ax,%ax
  80153e:	66 90                	xchg   %ax,%ax

00801540 <__udivdi3>:
  801540:	55                   	push   %ebp
  801541:	57                   	push   %edi
  801542:	56                   	push   %esi
  801543:	83 ec 0c             	sub    $0xc,%esp
  801546:	8b 44 24 28          	mov    0x28(%esp),%eax
  80154a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  80154e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  801552:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  801556:	85 c0                	test   %eax,%eax
  801558:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80155c:	89 ea                	mov    %ebp,%edx
  80155e:	89 0c 24             	mov    %ecx,(%esp)
  801561:	75 2d                	jne    801590 <__udivdi3+0x50>
  801563:	39 e9                	cmp    %ebp,%ecx
  801565:	77 61                	ja     8015c8 <__udivdi3+0x88>
  801567:	85 c9                	test   %ecx,%ecx
  801569:	89 ce                	mov    %ecx,%esi
  80156b:	75 0b                	jne    801578 <__udivdi3+0x38>
  80156d:	b8 01 00 00 00       	mov    $0x1,%eax
  801572:	31 d2                	xor    %edx,%edx
  801574:	f7 f1                	div    %ecx
  801576:	89 c6                	mov    %eax,%esi
  801578:	31 d2                	xor    %edx,%edx
  80157a:	89 e8                	mov    %ebp,%eax
  80157c:	f7 f6                	div    %esi
  80157e:	89 c5                	mov    %eax,%ebp
  801580:	89 f8                	mov    %edi,%eax
  801582:	f7 f6                	div    %esi
  801584:	89 ea                	mov    %ebp,%edx
  801586:	83 c4 0c             	add    $0xc,%esp
  801589:	5e                   	pop    %esi
  80158a:	5f                   	pop    %edi
  80158b:	5d                   	pop    %ebp
  80158c:	c3                   	ret    
  80158d:	8d 76 00             	lea    0x0(%esi),%esi
  801590:	39 e8                	cmp    %ebp,%eax
  801592:	77 24                	ja     8015b8 <__udivdi3+0x78>
  801594:	0f bd e8             	bsr    %eax,%ebp
  801597:	83 f5 1f             	xor    $0x1f,%ebp
  80159a:	75 3c                	jne    8015d8 <__udivdi3+0x98>
  80159c:	8b 74 24 04          	mov    0x4(%esp),%esi
  8015a0:	39 34 24             	cmp    %esi,(%esp)
  8015a3:	0f 86 9f 00 00 00    	jbe    801648 <__udivdi3+0x108>
  8015a9:	39 d0                	cmp    %edx,%eax
  8015ab:	0f 82 97 00 00 00    	jb     801648 <__udivdi3+0x108>
  8015b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8015b8:	31 d2                	xor    %edx,%edx
  8015ba:	31 c0                	xor    %eax,%eax
  8015bc:	83 c4 0c             	add    $0xc,%esp
  8015bf:	5e                   	pop    %esi
  8015c0:	5f                   	pop    %edi
  8015c1:	5d                   	pop    %ebp
  8015c2:	c3                   	ret    
  8015c3:	90                   	nop
  8015c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8015c8:	89 f8                	mov    %edi,%eax
  8015ca:	f7 f1                	div    %ecx
  8015cc:	31 d2                	xor    %edx,%edx
  8015ce:	83 c4 0c             	add    $0xc,%esp
  8015d1:	5e                   	pop    %esi
  8015d2:	5f                   	pop    %edi
  8015d3:	5d                   	pop    %ebp
  8015d4:	c3                   	ret    
  8015d5:	8d 76 00             	lea    0x0(%esi),%esi
  8015d8:	89 e9                	mov    %ebp,%ecx
  8015da:	8b 3c 24             	mov    (%esp),%edi
  8015dd:	d3 e0                	shl    %cl,%eax
  8015df:	89 c6                	mov    %eax,%esi
  8015e1:	b8 20 00 00 00       	mov    $0x20,%eax
  8015e6:	29 e8                	sub    %ebp,%eax
  8015e8:	89 c1                	mov    %eax,%ecx
  8015ea:	d3 ef                	shr    %cl,%edi
  8015ec:	89 e9                	mov    %ebp,%ecx
  8015ee:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8015f2:	8b 3c 24             	mov    (%esp),%edi
  8015f5:	09 74 24 08          	or     %esi,0x8(%esp)
  8015f9:	89 d6                	mov    %edx,%esi
  8015fb:	d3 e7                	shl    %cl,%edi
  8015fd:	89 c1                	mov    %eax,%ecx
  8015ff:	89 3c 24             	mov    %edi,(%esp)
  801602:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801606:	d3 ee                	shr    %cl,%esi
  801608:	89 e9                	mov    %ebp,%ecx
  80160a:	d3 e2                	shl    %cl,%edx
  80160c:	89 c1                	mov    %eax,%ecx
  80160e:	d3 ef                	shr    %cl,%edi
  801610:	09 d7                	or     %edx,%edi
  801612:	89 f2                	mov    %esi,%edx
  801614:	89 f8                	mov    %edi,%eax
  801616:	f7 74 24 08          	divl   0x8(%esp)
  80161a:	89 d6                	mov    %edx,%esi
  80161c:	89 c7                	mov    %eax,%edi
  80161e:	f7 24 24             	mull   (%esp)
  801621:	39 d6                	cmp    %edx,%esi
  801623:	89 14 24             	mov    %edx,(%esp)
  801626:	72 30                	jb     801658 <__udivdi3+0x118>
  801628:	8b 54 24 04          	mov    0x4(%esp),%edx
  80162c:	89 e9                	mov    %ebp,%ecx
  80162e:	d3 e2                	shl    %cl,%edx
  801630:	39 c2                	cmp    %eax,%edx
  801632:	73 05                	jae    801639 <__udivdi3+0xf9>
  801634:	3b 34 24             	cmp    (%esp),%esi
  801637:	74 1f                	je     801658 <__udivdi3+0x118>
  801639:	89 f8                	mov    %edi,%eax
  80163b:	31 d2                	xor    %edx,%edx
  80163d:	e9 7a ff ff ff       	jmp    8015bc <__udivdi3+0x7c>
  801642:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801648:	31 d2                	xor    %edx,%edx
  80164a:	b8 01 00 00 00       	mov    $0x1,%eax
  80164f:	e9 68 ff ff ff       	jmp    8015bc <__udivdi3+0x7c>
  801654:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801658:	8d 47 ff             	lea    -0x1(%edi),%eax
  80165b:	31 d2                	xor    %edx,%edx
  80165d:	83 c4 0c             	add    $0xc,%esp
  801660:	5e                   	pop    %esi
  801661:	5f                   	pop    %edi
  801662:	5d                   	pop    %ebp
  801663:	c3                   	ret    
  801664:	66 90                	xchg   %ax,%ax
  801666:	66 90                	xchg   %ax,%ax
  801668:	66 90                	xchg   %ax,%ax
  80166a:	66 90                	xchg   %ax,%ax
  80166c:	66 90                	xchg   %ax,%ax
  80166e:	66 90                	xchg   %ax,%ax

00801670 <__umoddi3>:
  801670:	55                   	push   %ebp
  801671:	57                   	push   %edi
  801672:	56                   	push   %esi
  801673:	83 ec 14             	sub    $0x14,%esp
  801676:	8b 44 24 28          	mov    0x28(%esp),%eax
  80167a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80167e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  801682:	89 c7                	mov    %eax,%edi
  801684:	89 44 24 04          	mov    %eax,0x4(%esp)
  801688:	8b 44 24 30          	mov    0x30(%esp),%eax
  80168c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  801690:	89 34 24             	mov    %esi,(%esp)
  801693:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801697:	85 c0                	test   %eax,%eax
  801699:	89 c2                	mov    %eax,%edx
  80169b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80169f:	75 17                	jne    8016b8 <__umoddi3+0x48>
  8016a1:	39 fe                	cmp    %edi,%esi
  8016a3:	76 4b                	jbe    8016f0 <__umoddi3+0x80>
  8016a5:	89 c8                	mov    %ecx,%eax
  8016a7:	89 fa                	mov    %edi,%edx
  8016a9:	f7 f6                	div    %esi
  8016ab:	89 d0                	mov    %edx,%eax
  8016ad:	31 d2                	xor    %edx,%edx
  8016af:	83 c4 14             	add    $0x14,%esp
  8016b2:	5e                   	pop    %esi
  8016b3:	5f                   	pop    %edi
  8016b4:	5d                   	pop    %ebp
  8016b5:	c3                   	ret    
  8016b6:	66 90                	xchg   %ax,%ax
  8016b8:	39 f8                	cmp    %edi,%eax
  8016ba:	77 54                	ja     801710 <__umoddi3+0xa0>
  8016bc:	0f bd e8             	bsr    %eax,%ebp
  8016bf:	83 f5 1f             	xor    $0x1f,%ebp
  8016c2:	75 5c                	jne    801720 <__umoddi3+0xb0>
  8016c4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8016c8:	39 3c 24             	cmp    %edi,(%esp)
  8016cb:	0f 87 e7 00 00 00    	ja     8017b8 <__umoddi3+0x148>
  8016d1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8016d5:	29 f1                	sub    %esi,%ecx
  8016d7:	19 c7                	sbb    %eax,%edi
  8016d9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8016dd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8016e1:	8b 44 24 08          	mov    0x8(%esp),%eax
  8016e5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8016e9:	83 c4 14             	add    $0x14,%esp
  8016ec:	5e                   	pop    %esi
  8016ed:	5f                   	pop    %edi
  8016ee:	5d                   	pop    %ebp
  8016ef:	c3                   	ret    
  8016f0:	85 f6                	test   %esi,%esi
  8016f2:	89 f5                	mov    %esi,%ebp
  8016f4:	75 0b                	jne    801701 <__umoddi3+0x91>
  8016f6:	b8 01 00 00 00       	mov    $0x1,%eax
  8016fb:	31 d2                	xor    %edx,%edx
  8016fd:	f7 f6                	div    %esi
  8016ff:	89 c5                	mov    %eax,%ebp
  801701:	8b 44 24 04          	mov    0x4(%esp),%eax
  801705:	31 d2                	xor    %edx,%edx
  801707:	f7 f5                	div    %ebp
  801709:	89 c8                	mov    %ecx,%eax
  80170b:	f7 f5                	div    %ebp
  80170d:	eb 9c                	jmp    8016ab <__umoddi3+0x3b>
  80170f:	90                   	nop
  801710:	89 c8                	mov    %ecx,%eax
  801712:	89 fa                	mov    %edi,%edx
  801714:	83 c4 14             	add    $0x14,%esp
  801717:	5e                   	pop    %esi
  801718:	5f                   	pop    %edi
  801719:	5d                   	pop    %ebp
  80171a:	c3                   	ret    
  80171b:	90                   	nop
  80171c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801720:	8b 04 24             	mov    (%esp),%eax
  801723:	be 20 00 00 00       	mov    $0x20,%esi
  801728:	89 e9                	mov    %ebp,%ecx
  80172a:	29 ee                	sub    %ebp,%esi
  80172c:	d3 e2                	shl    %cl,%edx
  80172e:	89 f1                	mov    %esi,%ecx
  801730:	d3 e8                	shr    %cl,%eax
  801732:	89 e9                	mov    %ebp,%ecx
  801734:	89 44 24 04          	mov    %eax,0x4(%esp)
  801738:	8b 04 24             	mov    (%esp),%eax
  80173b:	09 54 24 04          	or     %edx,0x4(%esp)
  80173f:	89 fa                	mov    %edi,%edx
  801741:	d3 e0                	shl    %cl,%eax
  801743:	89 f1                	mov    %esi,%ecx
  801745:	89 44 24 08          	mov    %eax,0x8(%esp)
  801749:	8b 44 24 10          	mov    0x10(%esp),%eax
  80174d:	d3 ea                	shr    %cl,%edx
  80174f:	89 e9                	mov    %ebp,%ecx
  801751:	d3 e7                	shl    %cl,%edi
  801753:	89 f1                	mov    %esi,%ecx
  801755:	d3 e8                	shr    %cl,%eax
  801757:	89 e9                	mov    %ebp,%ecx
  801759:	09 f8                	or     %edi,%eax
  80175b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80175f:	f7 74 24 04          	divl   0x4(%esp)
  801763:	d3 e7                	shl    %cl,%edi
  801765:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801769:	89 d7                	mov    %edx,%edi
  80176b:	f7 64 24 08          	mull   0x8(%esp)
  80176f:	39 d7                	cmp    %edx,%edi
  801771:	89 c1                	mov    %eax,%ecx
  801773:	89 14 24             	mov    %edx,(%esp)
  801776:	72 2c                	jb     8017a4 <__umoddi3+0x134>
  801778:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80177c:	72 22                	jb     8017a0 <__umoddi3+0x130>
  80177e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801782:	29 c8                	sub    %ecx,%eax
  801784:	19 d7                	sbb    %edx,%edi
  801786:	89 e9                	mov    %ebp,%ecx
  801788:	89 fa                	mov    %edi,%edx
  80178a:	d3 e8                	shr    %cl,%eax
  80178c:	89 f1                	mov    %esi,%ecx
  80178e:	d3 e2                	shl    %cl,%edx
  801790:	89 e9                	mov    %ebp,%ecx
  801792:	d3 ef                	shr    %cl,%edi
  801794:	09 d0                	or     %edx,%eax
  801796:	89 fa                	mov    %edi,%edx
  801798:	83 c4 14             	add    $0x14,%esp
  80179b:	5e                   	pop    %esi
  80179c:	5f                   	pop    %edi
  80179d:	5d                   	pop    %ebp
  80179e:	c3                   	ret    
  80179f:	90                   	nop
  8017a0:	39 d7                	cmp    %edx,%edi
  8017a2:	75 da                	jne    80177e <__umoddi3+0x10e>
  8017a4:	8b 14 24             	mov    (%esp),%edx
  8017a7:	89 c1                	mov    %eax,%ecx
  8017a9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  8017ad:	1b 54 24 04          	sbb    0x4(%esp),%edx
  8017b1:	eb cb                	jmp    80177e <__umoddi3+0x10e>
  8017b3:	90                   	nop
  8017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8017b8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  8017bc:	0f 82 0f ff ff ff    	jb     8016d1 <__umoddi3+0x61>
  8017c2:	e9 1a ff ff ff       	jmp    8016e1 <__umoddi3+0x71>
