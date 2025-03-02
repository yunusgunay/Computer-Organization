# Author: Yunus Gunay

.data
	b: .asciiz "Enter value b: "
	c: .asciiz "Enter value c: "
	result: .asciiz "The result of a = (b / (c mod b)) * c) is: "
	newLine: .asciiz "\n"

.text
main:
	# Prompt for number b
	li $v0, 4
	la $a0, b
	syscall
	
	li $v0, 5
	syscall	
	move $t0, $v0  	# t0 = b
	
	# Prompt for number c
	li $v0, 4
	la $a0, c
	syscall
	
	li $v0, 5
	syscall	
	move $t1, $v0  	# t1 = c
	
	# c mod b
	div $t1, $t0
	mfhi $t2 	# t2 = remainder

	# b / t2
	div $t0, $t2
	mflo $t3	# t3 = b / (c mod b)
	
	# t3 * c
	mul $t4, $t3, $t1
	
	# Print the result
	li $v0, 4
	la $a0, result
	syscall
	
	li $v0, 1
	move $a0, $t4
	syscall
		
stop:
	li $v0, 10
	syscall
	
	
