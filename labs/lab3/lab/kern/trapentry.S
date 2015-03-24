/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

.globl vector0
.type vector0, @function
.align 2
vector0:
  pushl $0
  push $0
  jmp _alltraps
.globl vector1
.type vector1, @function
.align 2
vector1:
  pushl $0
  push $1
  jmp _alltraps
.globl vector2
.type vector2, @function
.align 2
vector2:
  pushl $0
  push $2
  jmp _alltraps
.globl vector3
.type vector3, @function
.align 2
vector3:
  pushl $0
  push $3
  jmp _alltraps
.globl vector4
.type vector4, @function
.align 2
vector4:
  pushl $0
  push $4
  jmp _alltraps
.globl vector5
.type vector5, @function
.align 2
vector5:
  pushl $0
  push $5
  jmp _alltraps
.globl vector6
.type vector6, @function
.align 2
vector6:
  pushl $0
  push $6
  jmp _alltraps
.globl vector7
.type vector7, @function
.align 2
vector7:
  pushl $0
  push $7
  jmp _alltraps
.globl vector8
.type vector8, @function
.align 2
vector8:
  push $8
  jmp _alltraps
.globl vector9
.type vector9, @function
.align 2
vector9:
  pushl $0
  push $9
  jmp _alltraps
.globl vector10
.type vector10, @function
.align 2
vector10:
  push $10
  jmp _alltraps
.globl vector11
.type vector11, @function
.align 2
vector11:
  push $11
  jmp _alltraps
.globl vector12
.type vector12, @function
.align 2
vector12:
  push $12
  jmp _alltraps
.globl vector13
.type vector13, @function
.align 2
vector13:
  push $13
  jmp _alltraps
.globl vector14
.type vector14, @function
.align 2
vector14:
  push $14
  jmp _alltraps
.globl vector15
.type vector15, @function
.align 2
vector15:
  pushl $0
  push $15
  jmp _alltraps
.globl vector16
.type vector16, @function
.align 2
vector16:
  pushl $0
  push $16
  jmp _alltraps
.globl vector17
.type vector17, @function
.align 2
vector17:
  pushl $0
  push $17
  jmp _alltraps
.globl vector18
.type vector18, @function
.align 2
vector18:
  pushl $0
  push $18
  jmp _alltraps
.globl vector19
.type vector19, @function
.align 2
vector19:
  pushl $0
  push $19
  jmp _alltraps
.globl vector20
.type vector20, @function
.align 2
vector20:
  pushl $0
  push $20
  jmp _alltraps
.globl vector21
.type vector21, @function
.align 2
vector21:
  pushl $0
  push $21
  jmp _alltraps
.globl vector22
.type vector22, @function
.align 2
vector22:
  pushl $0
  push $22
  jmp _alltraps
.globl vector23
.type vector23, @function
.align 2
vector23:
  pushl $0
  push $23
  jmp _alltraps
.globl vector24
.type vector24, @function
.align 2
vector24:
  pushl $0
  push $24
  jmp _alltraps
.globl vector25
.type vector25, @function
.align 2
vector25:
  pushl $0
  push $25
  jmp _alltraps
.globl vector26
.type vector26, @function
.align 2
vector26:
  pushl $0
  push $26
  jmp _alltraps
.globl vector27
.type vector27, @function
.align 2
vector27:
  pushl $0
  push $27
  jmp _alltraps
.globl vector28
.type vector28, @function
.align 2
vector28:
  pushl $0
  push $28
  jmp _alltraps
.globl vector29
.type vector29, @function
.align 2
vector29:
  pushl $0
  push $29
  jmp _alltraps
.globl vector30
.type vector30, @function
.align 2
vector30:
  pushl $0
  push $30
  jmp _alltraps
.globl vector31
.type vector31, @function
.align 2
vector31:
  pushl $0
  push $31
  jmp _alltraps
.globl vector32
.type vector32, @function
.align 2
vector32:
  pushl $0
  push $32
  jmp _alltraps
.globl vector33
.type vector33, @function
.align 2
vector33:
  pushl $0
  push $33
  jmp _alltraps
.globl vector34
.type vector34, @function
.align 2
vector34:
  pushl $0
  push $34
  jmp _alltraps
.globl vector35
.type vector35, @function
.align 2
vector35:
  pushl $0
  push $35
  jmp _alltraps
.globl vector36
.type vector36, @function
.align 2
vector36:
  pushl $0
  push $36
  jmp _alltraps
.globl vector37
.type vector37, @function
.align 2
vector37:
  pushl $0
  push $37
  jmp _alltraps
.globl vector38
.type vector38, @function
.align 2
vector38:
  pushl $0
  push $38
  jmp _alltraps
.globl vector39
.type vector39, @function
.align 2
vector39:
  pushl $0
  push $39
  jmp _alltraps
.globl vector40
.type vector40, @function
.align 2
vector40:
  pushl $0
  push $40
  jmp _alltraps
.globl vector41
.type vector41, @function
.align 2
vector41:
  pushl $0
  push $41
  jmp _alltraps
.globl vector42
.type vector42, @function
.align 2
vector42:
  pushl $0
  push $42
  jmp _alltraps
.globl vector43
.type vector43, @function
.align 2
vector43:
  pushl $0
  push $43
  jmp _alltraps
.globl vector44
.type vector44, @function
.align 2
vector44:
  pushl $0
  push $44
  jmp _alltraps
.globl vector45
.type vector45, @function
.align 2
vector45:
  pushl $0
  push $45
  jmp _alltraps
.globl vector46
.type vector46, @function
.align 2
vector46:
  pushl $0
  push $46
  jmp _alltraps
.globl vector47
.type vector47, @function
.align 2
vector47:
  pushl $0
  push $47
  jmp _alltraps
.globl vector48
.type vector48, @function
.align 2
vector48:
  pushl $0
  push $48
  jmp _alltraps


/*
 * Lab 3: Your code here for _alltraps
 */

.globl _alltraps
_alltraps:
  pushl %ds
  pushl %es
  pushal

  movw $(GD_KD), %ax
  movw %ax, %ds
  movw %ax, %es

  pushl %esp
  call trap

# vector table
.data
.globl vectors
vectors:
  .long vector0
  .long vector1
  .long vector2
  .long vector3
  .long vector4
  .long vector5
  .long vector6
  .long vector7
  .long vector8
  .long vector9
  .long vector10
  .long vector11
  .long vector12
  .long vector13
  .long vector14
  .long vector15
  .long vector16
  .long vector17
  .long vector18
  .long vector19
  .long vector20
  .long vector21
  .long vector22
  .long vector23
  .long vector24
  .long vector25
  .long vector26
  .long vector27
  .long vector28
  .long vector29
  .long vector30
  .long vector31
  .long vector32
  .long vector33
  .long vector34
  .long vector35
  .long vector36
  .long vector37
  .long vector38
  .long vector39
  .long vector40
  .long vector41
  .long vector42
  .long vector43
  .long vector44
  .long vector45
  .long vector46
  .long vector47
  .long vector48

