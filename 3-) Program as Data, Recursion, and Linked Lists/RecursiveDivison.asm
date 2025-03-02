# Author: Yunus Gunay

.data
	dividend_msg:	.asciiz "\nEnter dividend: "
	divisor_msg:	.asciiz "Enter divisor: "
	quotient_msg:	.asciiz "The quotient is "
#-------------------------------------------------------#

.text
Main:
	li $v0, 4
	la $a0, dividend_msg
	syscall
	li $v0, 5
	syscall	
	move $a1, $v0		# a1 = dividend
	
	li $v0, 4
	la $a0, divisor_msg
	syscall
	li $v0, 5
	syscall	
	move $a0, $v0		# a0 = divisor
	
	# Check stop conditions
	blez $a1, Stop
	blez $a0, Stop
	
	# Division
	li $a2, 0
	jal Division		# a2 = quotient
	
	li $v0, 4
	la $a0, quotient_msg
	syscall
	move $a0, $a2
	li $v0, 1
	syscall
	
	# Continue
	j Main
Stop:
	li $v0, 10
	syscall
#-------------------------------------------------------#
	
	
# $a1 = Dividend
# $a0 = Divisor
# $a2 = Quotient
Division:		
	addi $sp, $sp, -12
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	# Initialization
	move $s1, $a1		# s1 = dividend
	move $s0, $a0		# s0 = divisor
			
	blt $s1, $s0, Division_End
	sub $s1, $s1, $s0
	addi $a2, $a2, 1
	
	move $a1, $s1		# new dividend = dividend - divisor
	jal Division
Division_End:
	move $v0, $a2
	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

	
