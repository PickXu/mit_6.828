#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"

int
sys_alarm(void)
{
	int n;
	void (*fn)();
	if (argint(0,&n) < 0)
		return -1;
	if (argptr(1,(char**)&fn,1) < 0)
		return -1;
	proc->alarmticks = n;
	proc->alarmhandler = fn;

	return 0;
}
