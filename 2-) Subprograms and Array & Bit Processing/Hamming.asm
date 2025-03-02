# Author: Yunus Gunay

.data
	prompt_1:	.asciiz "Enter value for Register 1 (decimal): "
	prompt_2:	.asciiz "Enter value for Register 2 (decimal): "
	continue_msg:	.asciiz "Do you want to continue? (y/n): "
	register1_msg:	.asciiz "Register 1's value in hex is: "
	register2_msg:	.asciiz "Register 2's value in hex is: "
	hamming_msg:	.asciiz "Hamming Distance is: "			# Hamming Distance = number of different bits
	newline:	.asciiz "\n"

.text
Main:
Continue_Loop:
	# Register Values
	jal GetRegisterValues		# $vo = Register1 & $v1 = Register 2

	# Hamming Distance
	move $a0, $v0
	move $a1, $v1
	jal CalculateHammingDistance	# v0 = Hamming Distance
	
	# Display Hamming Distance
	move $t0, $v0
	li $v0, 4
	la $a0, hamming_msg
	syscall
	move $a0, $t0
	li $v0, 1
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
GetRegisterValues:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	  
	# Register 1
	li $v0, 4
	la $a0, prompt_1
	syscall
	
	# s0 = Register 1
	li $v0, 5
	syscall
	move $s0, $v0
	
	# Register 2
	li $v0, 4
	la $a0, prompt_2
	syscall
	
	# s1 = Register 2
	li $v0, 5
	syscall
	move $s1, $v0
	
	# Display Register 1 in hex
	li $v0, 4
	la $a0, register1_msg
	syscall
	move $a0, $s0
	li $v0, 34
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	
	# Display Register 2 in hex
	li $v0, 4
	la $a0, register2_msg
	syscall
	move $a0, $s1
	li $v0, 34
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	
	# v0 = Register 1 & v1 = Register 2
	move $v0, $s0
	move $v1, $s1
	
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12
	jr $ra


# SubProgram 2: Calculate Hamming Distance
# $a0 = Register 1
# $a1 = Register 2
CalculateHammingDistance:
	addi $sp, $sp, -20
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $ra, 16($sp)
	
	li $s0, 0		# s0 = Hamming Distance count
	li $s1, 32		# s1 = loop counter for 32 bits
	j CompareBits
CompareBits:
	beq $s1, $zero, EndCount
	
	# Find LSB	
	andi $s2, $a0, 0x1	# s2 = LSB of Register 1
	andi $s3, $a1, 0x1	# s3 = LSB of Register 2
	
	beq $s2, $s3, ShiftBit
	addi $s0, $s0, 1
	j ShiftBit
ShiftBit:
	srl $a0, $a0, 1
	srl $a1, $a1, 1
	subi $s1, $s1, 1
	j CompareBits
EndCount:
	move $v0, $s0
	
	lw $ra, 16($sp)
	lw $s3, 12($sp)
    	lw $s2, 8($sp)
    	lw $s1, 4($sp)
    	lw $s0, 0($sp)
    	addi $sp, $sp, 20
    	jr $ra
	
