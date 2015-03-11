// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display backtrace", mon_backtrace},
	{ "showmappings", "Display physical page mappings as well as permission bits of given virtual address range", mon_showmappings},
	{ "setmp", "Set mapping permission", mon_setmp},
	{ "clrmp", "Clear mapping permission", mon_clrmp},
	{ "chgmp", "Change mapping permission", mon_chgmp},
	{ "dumpregion", "Dump memory at the region", mon_dumpregion},
};

#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

	int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

	int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t ebp,eip,arg[5];
	struct Eipdebuginfo dinfo;	
	int i,ret;
	cprintf("Stack backtrace:\n");
	ebp = read_ebp();
	while (ebp != 0x0) {
		cprintf("  ebp %08x",ebp);
		eip = *((uint32_t*)ebp+1);
		cprintf("  eip %08x",eip);
		for (i=0;i<5;i++) 
			arg[i] = *((uint32_t*)ebp+i+2);
		cprintf("  args %08x %08x %08x %08x %08x\n",
			arg[0],arg[1],arg[2],arg[3],arg[4]);
		ret = debuginfo_eip((uintptr_t)eip,&dinfo);
		if (ret == 0) {
			cprintf("         %s:%d: %.*s+%d\n",dinfo.eip_file,dinfo.eip_line,
				dinfo.eip_fn_namelen, dinfo.eip_fn_name, eip-dinfo.eip_fn_addr);
		}
		ebp = *((uint32_t*)ebp);
	}
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t vstart,vend;	
	vstart = (uint32_t)strtol(argv[1],NULL,16);
	vend = (uint32_t)strtol(argv[2],NULL,16);
	print_region_map(kern_pgdir,(const void*)vstart,(const void*)vend);
	return 0;
}

int
mon_setmp(int argc, char **argv, struct Trapframe *tf) 
{
	return 0;
}

int 
mon_clrmp(int argc, char **argv, struct Trapframe *tf) 
{
	return 0;
}

int
mon_chgmp(int argc, char **argv, struct Trapframe *tf)
{
	return 0;
}

int
mon_dumpregion(int argc, char **argv, struct Trapframe *tf) 
{
	return 0;
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

	static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

	void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
