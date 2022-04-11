.data
	answer: .quad 0
	input: .ascii " "
	game: .space 30, 32
	win_msg: .ascii "Well done ! you won in _ attempts"
.text
	header: .ascii "\033[1mxwrdl \033[0m\033[2mv0.1 \033[0m(\033[32m\033[1mESC \033[0mto exit)\n\n"
	loss_msg: .ascii "You lost, the word was:\n"
	newline: .byte '\n'
	clear: .byte '\r'
	sep: .ascii " "
	style_green: .ascii "\033[42m\033[30m"
	style_yellow: .ascii "\033[103m\033[30m"
	style_gray: .ascii "\033[100m\033[97m"
	style_reset: .ascii "\033[0m"

# compare two 5 letters strings
# %rax - pointer to first string
# %rdi - pointer to second string
# => sets ZF if equal or not
strcmp:
	# compare 4 first bytes
	movl (%rax), %esi
	cmpl (%rdi), %esi
	jne strcmp_ret
	# compare last byte
	addq $4, %rax
	addq $4, %rdi
	movb (%rax), %sil
	cmpb (%rdi), %sil
	ret
strcmp_ret:
	ret

# prints a newline
ln:
	movq $1, %rax
	movq $1, %rdi
	leaq newline(%rip), %rsi
	movq $1, %rdx
	syscall
	ret
# prints a carriage return
cr:
	movq $1, %rax
	movq $1, %rdi
	leaq clear(%rip), %rsi
	movq $1, %rdx
	syscall
	ret
# draw current line uncolored
# r15 is a pointer to the current line
draw_uncolored:
	xorq %r8, %r8
uloop:
	movq $1, %rax
	movq $1, %rdi
	leaq (%r15, %r8, 1), %rsi
	movq $1, %rdx
	syscall

	movq $1, %rax
	movq $1, %rdi
	leaq sep(%rip), %rsi
	movq $1, %rdx
	syscall

	incq %r8
	cmpq $5, %r8
	jb uloop
	
	ret
# draw current line colored
# r15 is a pointer to the current line
draw_colored:
	# r8 holds the char index
	movq $0, %r8
	leaq answer(%rip), %r10
	# r9 holds the pointer to the answer
	movq (%r10), %r9

dloop:
	movb (%r9, %r8, 1), %r10b
	cmpb (%r15, %r8, 1), %r10b
	je dgreen

	# rdx holds the number of unmatched occurence of the current char and in answer
	# occurences are matched first by the green matches.
	xorq %rdx, %rdx

	# rdi holds 0 to be conditionally moved
	xorq %rdi, %rdi

	xorq %rax, %rax

cloop:
	xorq %r11, %r11
	movb (%r9, %rax, 1), %r10b
	# compare char %rax of answer with current char
	cmpb (%r15, %r8, 1), %r10b
	# set r11 to 1 if there's a match
	sete %r11b
	# compare char %rax of answer with char %rax of current
	cmpb (%r15, %rax, 1), %r10b
	# if they're equal, overwrite %r11 with 0.
	cmove %rdi, %r11
	xorq %rsi, %rsi
	movb (%r15, %rax, 1), %r10b
	cmpb (%r15, %r8, 1), %r10b
	# if match set %rsi to 1, otherwise to 0
	sete %sil
	movb (%r9, %rax, 1), %r10b
	cmpb (%r15, %r8, 1), %r10b
	# if match set rsi to 0
	cmove %rdi, %rsi
	cmpq %rax, %r8
	# zero rsi if were ahead of the char index
	cmovbe %rdi, %rsi
	addq %r11, %rdx
	subq %rsi, %rdx

	incq %rax
	cmpq $5, %rax
	jb cloop

	cmpq $0, %rdx
	jg dyellow

	jmp dgray
dgreen:
	movq $1, %rax
	movq $1, %rdi
	leaq style_green(%rip), %rsi
	movq $10, %rdx
	syscall

	movq $1, %rax
	movq $1, %rdi
	leaq (%r15, %r8, 1), %rsi
	movq $1, %rdx
	syscall

	jmp dcont
dyellow:
	movq $1, %rax
	movq $1, %rdi
	leaq style_yellow(%rip), %rsi
	movq $11, %rdx
	syscall

	movq $1, %rax
	movq $1, %rdi
	leaq (%r15, %r8, 1), %rsi
	movq $1, %rdx
	syscall

	jmp dcont
dgray:
	movq $1, %rax
	movq $1, %rdi
	leaq style_gray(%rip), %rsi
	movq $11, %rdx
	syscall

	movq $1, %rax
	movq $1, %rdi
	leaq (%r15, %r8, 1), %rsi
	movq $1, %rdx
	syscall

	jmp dcont
dcont:
	movq $1, %rax
	movq $1, %rdi
	leaq sep(%rip), %rsi
	movq $1, %rdx
	syscall

	incq %r8
	cmpq $5, %r8
	jb dloop

	movq $1, %rax
	movq $1, %rdi
	leaq style_reset(%rip), %rsi
	movq $4, %rdx
	syscall

	ret
.globl _start
_start:
# print header
	movq $1, %rax
	movq $1, %rdi
	leaq header(%rip), %rsi
	movq $55, %rdx
	syscall

# choose answer
	# read clock to %rax:%rdx
	rdtsc
	lfence

	leaq pool(%rip), %r10
	leaq pool_len(%rip), %r8

	xorq %rdx, %rdx

	# force clock to be in range 0 -> pool_len (result goes into %rdx)
	divq (%r8)

	# multiply by five (5 letters in each word)
	movq %rdx, %rax
	xorq %rdx, %rdx
	movq $5, %r8
	mulq %r8

	# put resulting pointer into answer
	leaq answer(%rip), %r15
	movq %r10, (%r15)
	addq %rax, (%r15)

	call set_raw

	# r12 is current char index
	# r13 is current line index
	# r14 is pointer to game buffer
	# r15 is pointer to line buffer
	movq $0, %r12 
	movq $0, %r13
	leaq game(%rip), %r14
	movq %r14, %r15
# input loop
loop:
	# get input
	movq $0, %rax
	movq $0, %rdi
	leaq input(%rip), %rsi
	movq $1, %rdx
	syscall

	leaq input(%rip), %r8
	movb (%r8), %al

# inputs
	# check if input is escape, and exit if it is
	cmpb $27, %al
	je out
	
	# check if input is enter
	cmpb $10, %al
	je enter

	# check if input is 8 or 127 (del or backspace)
	cmpb $8, %al
	je backspace
	cmpb $127, %al
	je backspace

	# if letter is under 65 'A', its garbage
	cmpb $65, %al
	jb continue

	# letter is in 65-90 range, its an uppercase letter
	cmpb $90, %al
	jbe uppercase

	# letter is in range 91-96, its garbage
	cmpb $97, %al
	jb continue

	# letter is in range 97-122, its a lowercase letter
	cmpb $122, %al
	jbe lowercase

	# input is garbage
	jmp continue
enter:
	# skip if were not at the end of the line
	cmpq $5, %r12
	jne continue

	# check word
	leaq check_len(%rip), %r9
	leaq check(%rip), %r10
	movq (%r9), %r8
	check_loop:
		movq %r10, %rax
		movq %r15, %rdi
		call strcmp
		je checked

		addq $5, %r10
		decq %r8
		test %r8, %r8
		jnz check_loop
		
		# word hasn't been verified
		jmp continue
	checked:
		call cr
		call draw_colored
		call ln

		# compare entered word with answer and exit to win if equal
		leaq answer(%rip), %r8
		movq (%r8), %rax
		movq %r15, %rdi
		call strcmp
		je won

		incq %r13
		addq $5, %r15
		movq $0, %r12

	jmp continue
backspace:
	# do nothing if we're already at index 0
	testq %r12, %r12
	jz continue

	decq %r12
	movb $32, (%r15, %r12, 1)
	jmp continue
lowercase:
	# make upper case
	subb $32, %al
	# we could fall trough but this is to really have each part split
	jmp uppercase
uppercase:
	# if we're already at the end of the line, skip
	cmpq $5, %r12
	jae continue
	
	movb %al, (%r15, %r12,1)
	incq %r12
	jmp continue
continue:
	# exit out if we're at the last line
	cmpq $6, %r13
	je lost

	call cr
	call draw_uncolored

	jmp loop

	jmp out

won:
	call ln

	xorq %r8, %r8
	# 33 is the length of the full string (last 's' included)
	movq $33, %rdx
	# set %r8 to 1 if the player won in 1 attempt
	test %r13, %r13
	setz %r8b
	# remove 1 char from string (the 's' of attempts) if the player won in 1 attempt.
	subq %r8, %rdx

	movq $23, %r8
	# convert from number to string (0 is 48 in ascii, +1 because r13 is 0 based)
	addq $49, %r13
	leaq win_msg(%rip), %rsi
	movb %r13b, (%rsi, %r8, 1)

	movq $1, %rax
	movq $1, %rdi
	syscall

	call ln

	jmp out
lost:
	call ln

	movq $1, %rax
	movq $1, %rdi
	leaq loss_msg(%rip), %rsi
	movq $24, %rdx
	syscall


	movq $1, %rax
	movq $1, %rdi
	leaq answer(%rip), %rsi
	movq (%rsi), %rsi
	movq $5, %rdx
	syscall

	call ln

	jmp out
out:

# exit
	call unset_raw
	movq $60, %rax
	movq $0, %rdi
	syscall
