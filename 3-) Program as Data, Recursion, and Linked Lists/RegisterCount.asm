# Author: Yunus Gunay

.data
	enter_prompt:	.asciiz "Enter register number (0-31): "
	result_prompt:	.asciiz "The register is used "
	times:		.asciiz " times.\n"
	invalid:	.asciiz "Invalid input!"
#-----------------------------------------------------------------------#
.text
Main:
	li $v0, 4
	la $a0, enter_prompt
	syscall
	li $v0, 5
	syscall
	
	blt $v0, 0, Stop
	bgt $v0, 31, Stop
	
	move $a0, $v0
	jal CountRegister		# returns count in $v0
	move $t0, $v0
	
	# Print Result
	li $v0, 4
	la $a0, result_prompt
	syscall
	move $a0, $t0
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, times
	syscall
	
	j Main
Stop:
	li $v0, 4
	la $a0, invalid
	syscall
	
	li $v0, 10
	syscall
#-----------------------------------------------------------------------#	
	
# $a0 = Register Number
CountRegister:
	# Allocate stack
	addi $sp, $sp, -36
	sw $s0, 32($sp)
	sw $s1, 28($sp)
	sw $s2, 24($sp)
	sw $s3, 20($sp)
	sw $s4, 16($sp)
	sw $s5, 12($sp)
	sw $s6, 8($sp) 
	sw $s7, 4($sp)
	sw $ra, 0($sp)

	la $s0, CountRegister		# s0 = subprogram start address 
	la $s1, Return			# s1 = subprogram end address
	
	addi $s2, $zero, 0		# s2 = counter 
CountLoop:
	beq $s0, $s1, RestoreStack
	
	lw $s3, 0($s0)			# s3 = machine code (R-type, I-Type, J-Type)
	srl $s7, $s3, 26		# s7 = opcode
	
	# If J-type, skip
	beq $s7, 2, IncrementAddress
	beq $s7, 3, IncrementAddress
	
	# Check R-type or I-type
	beq $s7, $zero, RD		# R-Type
	j RS				# I-Type
RD:	
	andi $s6, $s3, 0x0000F800	# s6 = rd
	srl $s6, $s6, 11
	beq $s6, $a0, IncrementRD
	j RS
IncrementRD:
	addi $s2, $s2, 1
RS:
	andi $s4, $s3, 0x03E00000	# s4 = rs
	srl $s4, $s4, 21
	beq $s4, $a0, IncrementRS
	j RT
IncrementRS:
	addi $s2, $s2, 1
RT:
	andi $s5, $s3, 0x001F0000	# s5 = rt
	srl $s5, $s5, 16
	beq $s5, $a0, IncrementRT
	j IncrementAddress
IncrementRT:
	addi $s2, $s2, 1
IncrementAddress:
	addi $s0, $s0, 4
	j CountLoop
RestoreStack:
	move $v0, $s2
	
	lw $ra, 0($sp)
	lw $s7, 4($sp)
	lw $s6, 8($sp)
	lw $s5, 12($sp)
	lw $s4, 16($sp)
	lw $s3, 20($sp)
	lw $s2, 24($sp)
	lw $s1, 28($sp)
	lw $s0, 32($sp)
	addi $sp, $sp, 36
Return:
	jr $ra