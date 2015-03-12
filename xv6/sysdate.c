#include "types.h"
#include "defs.h"
#include "date.h"

int
sys_date(void)
{       
        int addr;
        if (argint(0, &addr) < 0)
                return -1;
        cmostime((struct rtcdate*)addr);
        return 0;
}
