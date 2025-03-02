# Author: Yunus Gunay

.data
	message_size: 	.asciiz "Enter the size of the array: "
	prompt_element:	.asciiz "Enter a positive integer element: "
	prompt_print:	.asciiz "\nARRAY CONTENTS: "
	comma:		.asciiz ", "
	table_title:	.asciiz "\n### FREQUENCY TABLE ###\n"
	freq_message:	.asciiz "Frequency of number "
	colon_is:	.asciiz " is: "
    	other_message:	.asciiz "Frequency of numbers other than 0 to 9 is: "
	newline: 	.asciiz "\n"
	FreqTable:    	.word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
# Call subprograms with jal.
# Use $s registers and Stack.
# For passing arguments, use $a registers. For returning results, use $v registers.
Main:
	# Array Part
	jal CreateArray
	
	# FreqTable
	move $a0, $v1		# a0 = array size
	move $a1, $v0		# a1 = array's base address
	la $a2, FreqTable
	jal FindFreq	
	
	# Display FreqTable
	li $v0, 4
	la $a0, newline
	syscall
	li $v0, 4
	la $a0, table_title
	syscall
	
	la $a2, FreqTable
	jal PrintFreqTable	
Stop:
	li $v0, 10
	syscall


CreateArray:
	# Store Stack
	addi $sp, $sp, -12
	sw $s0, 0($sp)		# s0 = array size
	sw $s1, 4($sp)		# s1 = array's base addres
	sw $ra, 8($sp)
	
	# Ask user to enter the size of the array to be created
	li $v0, 4
	la $a0, message_size
	syscall	
	li $v0, 5
	syscall
	
	move $s0, $v0		# s0 = array size
	
	# Allocate memory
	li $v0, 9		# "syscall 9" for dynamic memory allocation: allocates memory from the heap
	sll $a0, $s0, 2		# array size in bytes (integer * 4)
	syscall
		
	move $s1, $v0		# s1 = base address of allocated memory (array address)
	
	# Call InitializeArray to fill array
	move $a0, $s1		# a0 = base address
	move $a1, $s0		# a1 = array size
	jal InitializeArray
	
	# Call PrintArray to print the contents of the array
	li $v0, 4
    	la $a0, prompt_print
    	syscall
	move $a0, $s1
	move $a1, $s0
	jal PrintArray
	
	# Return array's base address and array size to main
	move $v0, $s1		# v0 = array's base address
	move $v1, $s0		# v1 = array's size
	
	# Restore Stack
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12
	jr $ra

						
# Takes array's base address in $a0 and array size in $a1
InitializeArray:
	# Store stack
	addi $sp, $sp, -8
	sw $s2, 0($sp)		# s2 = current index
	sw $ra, 4($sp)
	
	li $s2, 0
	j InitLoop	
InitLoop:
	bge $s2, $a1, EndInitLoop
	
	# Prompt message
	li $v0, 4
	la $a0, prompt_element
	syscall
	li $v0, 5
	syscall
	
	# Get current element's address and store integer there
	sll $a2, $s2, 2
	add $a2, $a2, $s1
	sw $v0, 0($a2)
	
	addi $s2, $s2, 1
	j InitLoop	
EndInitLoop:
	lw $ra, 4($sp)
	lw $s2, 0($sp)
	addi $sp, $sp, 8
	jr $ra


# Displays the contents of the array
PrintArray:
	# Store stack
	addi $sp, $sp, -8
	sw $s2, 0($sp)		# s2 = current index
	sw $ra, 4($sp)
	
	move $a2, $s1		# a2 = base address of array
	li $s2, 1
	j PrintLoop
PrintLoop:
	bgt $s2, $a1, EndPrintLoop
		
	li $v0, 1
	lw $a0, 0($a2)
	syscall	
	
	beq $s2, $a1, SkipComma
	li $v0, 4
    	la $a0, comma
    	syscall
    	j SkipComma
SkipComma:
    	addi $a2, $a2, 4
    	addi $s2, $s2, 1
    	j PrintLoop 
EndPrintLoop:
	lw $ra, 4($sp)
	lw $s2, 0($sp)
	addi $sp, $sp, 8
	jr $ra


# Receives the array address, array size, and address of FreqTable from Main.
# Finds number of times the numbers 0 to 9 appear in the array and stores this frequency information into FreqTable.
# a0 = array size
# a1 & s1 = array's base address
# a2 = FreqTable's base address
FindFreq:
	# Store stack
	addi $sp, $sp, -20
	sw $s2, 0($sp)		# s2 = current index
	sw $s3, 4($sp)		# s3 = element value
	sw $s4, 8($sp)		# s4 = offset
	sw $s5, 12($sp)		
	sw $ra, 16($sp)
	
	li $s2, 0
	j FreqLoop	
FreqLoop:
	bge $s2, $a0, EndFreqLoop
	
	# s3 = current array element
	sll $s4, $s2, 2
	add $s4, $s4, $a1
	lw $s3, 0($s4)
	
	# Numbers > 9
	bgt $s3, 9, OtherCount
	
	# Numbers between 0-9
	sll $s4, $s3, 2
	add $s4, $s4, $a2	# take its address in FreqTable
	
	lw $s5, 0($s4)
	addi $s5, $s5, 1
	sw $s5, 0($s4)
	j Next
OtherCount:
	lw $s5, 40($a2)		# FreqTable[10]
	addi $s5, $s5, 1
	sw $s5, 40($a2)
Next:
	addi $s2, $s2, 1	# index++
	j FreqLoop
EndFreqLoop:
	lw $ra, 16($sp)	
	lw $s5, 12($sp)
	lw $s4, 8($sp)
	lw $s3, 4($sp)	
	lw $s2, 0($sp)
	addi $sp, $sp, 20
	jr $ra
	

# Displays the FreqTable
# a2 = FreqTable's base address
PrintFreqTable:
	# Store stack
	addi $sp, $sp, -12
	sw $s2, 0($sp)		# s2 = current index
	sw $s3, 4($sp)		# s2 = freq address
	sw $ra, 8($sp)
	
	li $s2, 0
	j PrintFreqLoop
PrintFreqLoop:
	bge $s2, 10, PrintOther
	
	# Prompt
	li $v0, 4
	la $a0, freq_message
	syscall
	li $v0, 1
	move $a0, $s2
	syscall
	li $v0, 4
	la $a0, colon_is
	syscall
	
	sll $s3, $s2, 2
	add $s3, $s3, $a2
	
	# Freq
	lw $a0, 0($s3)
	li $v0, 1
	syscall	
	li $v0, 4
    	la $a0, newline
    	syscall
    	
    	addi $s2, $s2, 1
    	j PrintFreqLoop	
PrintOther:
	# Prompt
	li $v0, 4
    	la $a0, other_message
    	syscall
    	
    	# Other Freq
    	lw $a0, 40($a2)
    	li $v0, 1
    	syscall
    	
    	j EndPrintFreqLoop
EndPrintFreqLoop:
	# Restore stack
	lw $ra, 8($sp)
	lw $s3, 4($sp)
	lw $s2, 0($sp)
	addi $sp, $sp, 12
	jr $ra

