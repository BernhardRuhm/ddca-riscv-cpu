
		.text
		.align  2
		.globl  _start

_start:
		addi x1, x0, 12
		nop
		nop
		nop
		nop
		nop
		sw x1, 4(x0)
		nop
		nop
		nop
		nop
		nop
		lw x2, 4(x0)
		nop
		nop
		nop
		nop
		nop
		beq x2, x1, out
		nop
		nop
		nop
		nop
		nop

out :
		addi x2, x2, 4	
		nop
		nop
		nop
		nop


		.end _start
		.size _start, .-_start
