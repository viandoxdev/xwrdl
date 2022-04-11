.data
	termios: .space 60, 0
.text
	c_hide: .ascii "\033[?25l"
	c_show: .ascii "\033[?25h"
.globl set_raw
.globl unset_raw
get_termios:
	movq $16, %rax
	movq $0, %rdi
	movq $0x5401, %rsi
	leaq termios(%rip), %rdx
	syscall
	ret
set_termios:
	movq $16, %rax
	movq $0, %rdi
	movq $0x5402, %rsi
	leaq termios(%rip), %rdx
	syscall
	ret
set_raw:
	call get_termios
	leaq termios(%rip), %r8
	andl $0xFFFFFFF5, 12(%r8)
	call set_termios

	# hide cursor
	movq $1, %rax
	movq $1, %rdi
	leaq c_hide(%rip), %rsi
	movq $6, %rdx
	syscall

	ret
unset_raw:
	call get_termios
	leaq termios(%rip), %r8
	orl $0x00000000A, 12(%r8)
	call set_termios

	# show cursor
	movq $1, %rax
	movq $1, %rdi
	leaq c_show(%rip), %rsi
	movq $6, %rdx
	syscall

	ret
