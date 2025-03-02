# Author: Yunus Gunay

.data
	prompt_reg:	.asciiz "Enter value for Register (decimal): "
	continue_msg:	.asciiz "Do you want to continue? (y/n): "
	register_msg:	.asciiz "Register's value in hex is: "
	reversed_msg:	.asciiz "Reversed hex number is: "
	newline:	.asciiz "\n"

.text
Main:
Continue_Loop:
	# Register Values
	jal GetRegisterValue		# $vo = Register value

	# Reverse Register
	move $a0, $v0
	jal ReverseRegister	# v0 = Reversed Register
	
	# Display reversed register
	move $t0, $v0
	li $v0, 4
	la $a0, reversed_msg
	syscall
	move $a0, $t0
	li $v0, 34
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	
	# Ask user to continue
	li $v0, 4
	la $a0, continue_msg
	syscall
	li $v0, 12
	syscall	
	beq $v0, 'n', Stop
	beq $v0, 'y', BeforeNewLoop	
	j Continue_Loop
BeforeNewLoop:
	li $v0, 4
	la $a0, newline
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	j Continue_Loop		
Stop:
	li $v0, 10
	syscall
	
# SubProgram 1: Get Register Values
GetRegisterValue:
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $ra, 4($sp)
	  
	# Prompt
	li $v0, 4
	la $a0, prompt_reg
	syscall
	
	# s0 = Register Value
	li $v0, 5
	la $a0, register_msg
	syscall
	move $s0, $v0
	
	# Display Register's value in hex
	li $v0, 4
	la $a0, register_msg
	syscall
	move $a0, $s0
	li $v0, 34
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	
	# v0 = Register
	move $v0, $s0
	
	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra


# SubProgram 2: Reverse Register
# $a0 = Register's value
ReverseRegister:
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $ra, 12($sp)
	
	li $s0, 32	# s0 = loop counter for 32 bits
	li $s1, 0	# s1 = reversed bits
	j ReverseLoop
ReverseLoop:
	beq $s0, $zero, EndReverseLoop
	
	andi $s2, $a0, 0x1	# s2 = LSB of the Register value
	sll $s1, $s1, 1
	add $s1, $s1, $s2
	
	srl $a0, $a0, 1
		
	subi $s0, $s0, 1
	j ReverseLoop
EndReverseLoop:
	move $v0, $s1
	
	lw $ra, 12($sp)
	lw $s2, 8($sp)
    	lw $s1, 4($sp)
    	lw $s0, 0($sp)
    	addi $sp, $sp, 16
    	jr $ra
