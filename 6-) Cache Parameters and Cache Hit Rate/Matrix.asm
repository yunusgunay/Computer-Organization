# Author: Yunus Gunay

.data
	promptN:	.asciiz "Enter size N for NxN matrix: "
	menuPrompt:	.asciiz "\nChoose an option:\n1) Display element at (row, col)\n2) Row by row summation\n3) Col by col summation\nOther) Exit\nOption: "
	promptRow:	.asciiz "Enter row number: "
	promptCol:     	.asciiz "Enter column number: "
	resultMsg:     	.asciiz "Summation Result: "
	colMsg:		.asciiz "Col Sum: "
	rowMsg:		.asciiz "Row Sum: "
	elementMsg:    	.asciiz "Element: "
	newline:       	.asciiz "\n"

.text
Main:
	la $a0, promptN
    	li $v0, 4
    	syscall
    	li $v0, 5
    	syscall
    	move $s0, $v0		# $s0 = N

    	# Allocate N*N*4 bytes
    	mul $t0, $s0, $s0   	# $t1 = N^2	
    	mul $a0, $t0, 4  	# $t2 = N^2*4	
    	li $v0, 9
    	syscall
    	
    	move $s1, $v0		# $s1 = base address
    	move $a0, $s0		# $a0 = $s0 = N
    	move $a1, $s1		# $a1 = $s1 = base address 
    	jal InitMatrix   	
Menu_Loop:
	la $a0, menuPrompt
    	li $v0, 4
    	syscall
    	li $v0, 5		# $v0 = user choice
    	syscall
    
    	beq $v0, 1, Desired_Element
    	beq $v0, 2, Row_Major
    	beq $v0, 3, Col_Major
    	j Stop_Program
Desired_Element:
    	move $a0, $s0  
    	move $a1, $s1   
    	jal Get_Desired_Element
    	j Menu_Loop
Row_Major:
    	move $a0, $s0
    	move $a1, $s1
    	jal Row_Major_Sum
    	j Menu_Loop
Col_Major:
    	move $a0, $s0
    	move $a1, $s1
    	jal Col_Major_Sum
    	j Menu_Loop
Stop_Program:
    	li $v0, 10
    	syscall

# Initialize Matrix #
InitMatrix:
    	addi $sp, $sp, -16
    	sw $ra, 12($sp)
    	sw $s2, 8($sp)
    	sw $s3, 4($sp)
    	sw $s4, 0($sp)

    	addi $s2, $zero, 1  	# $s2 = value to be stored
    	addi $s3, $zero, 1     # $s3 = column (j)
    	addi $s4, $zero, 1     # $s4 = row (i)
	j Fill_Loop
Fill_Loop:
    	# offset = ((col-1) * N + (row-1)) * 4
    	addi $t6, $s3, -1	
    	mul $t6, $t6, $s0	
    	addi $t7, $s4, -1	
    	add $t6, $t6, $t7	
	mul $t6, $t6, 4		# $t6 = offset
    	add $t8, $s1, $t6	# $t8 = offset + base address
    	sw $s2, 0($t8)		# $s2 = value to be stored

	# initialize column
    	addi $s2, $s2, 1	# increment value
    	addi $s4, $s4, 1	# increment row by "row + 1"
    	ble $s4, $s0, Fill_Loop	

    	# next column	
    	addi $s4, $zero, 1	# increment row by "1"
    	addi $s3, $s3, 1	# increment column
    	ble $s3, $s0, Fill_Loop	
Done_Init:
	# Restore stack
    	lw $s4, 0($sp)
    	lw $s3, 4($sp)
    	lw $s2, 8($sp)
    	lw $ra, 12($sp)
    	addi $sp, $sp, 16
    	jr $ra

############
# OPTION 1 #
############
Get_Desired_Element:
    	addi $sp, $sp, -24
    	sw $ra, 20($sp)
    	sw $s2, 16($sp)
    	sw $s3, 12($sp)
    	sw $s4, 8($sp)
    	sw $s5, 4($sp)
    	sw $s6, 0($sp)

    	li $v0, 4
    	la $a0, promptRow
    	syscall
    	li $v0, 5
    	syscall
    	move $s2, $v0	# $s2 = desired row (i)
    	
    	li $v0, 4
    	la $a0, promptCol
    	syscall
    	li $v0, 5
    	syscall
    	move $s3, $v0  	# $s3 = desired col (j)

    	# Offset Calculation
    	addi $s4, $s3, -1
    	mul $s4, $s4, $s0
    	addi $s5, $s2, -1
    	add $s4, $s4, $s5
    	mul $s4, $s4, 4
    	add $s6, $s1, $s4
    	lw $s4, 0($s6)

    	# Print the element
    	la $a0, elementMsg
    	li $v0, 4
    	syscall
    	move $a0, $s4
    	li $v0, 1
    	syscall
    	la $a0, newline
    	li $v0, 4
    	syscall

	# Restore stack
    	lw $s6, 0($sp)
    	lw $s5, 4($sp)
    	lw $s4, 8($sp)
    	lw $s3, 12($sp)
    	lw $s2, 16($sp)
    	lw $ra, 20($sp)
    	addi $sp, $sp, 24
    	jr $ra

############
# OPTION 2 #
############
Row_Major_Sum:
    	addi $sp, $sp, -28
    	sw $ra, 24($sp)
    	sw $s2, 20($sp)
    	sw $s3, 16($sp)
    	sw $s4, 12($sp)
    	sw $s5, 8($sp)
    	sw $s6, 4($sp)
    	sw $s7, 0($sp)

    	add $s2, $zero, $a1 	# $s2 = base address of the matrix
    	add $s5, $zero, $a0   	# $s5 = N (matrix size)

    	add $s3, $zero, $zero 	# $s3 = row index
    	add $s6, $zero, $zero	# $s6 = sum
Row_Major_Loop:
    	bge $s3, $s5, Done_Row     
    	add $s4, $zero, $zero 	# $s4 = column index
Row_Major_Inner_Loop:
    	bge $s4, $s5, Next_Row # all columns in the current row are processed

    	# Offset: (j * N + i) * 4 
    	mul $t0, $s4, $s5           
    	add $t0, $t0, $s3          
    	mul $t0, $t0, 4             
    	add $t0, $t0, $s2            
    	lw $t1, 0($t0)               

    	add $s6, $s6, $t1
    	addi $s4, $s4, 1
    	j Row_Major_Inner_Loop
Next_Row:
    	# Print current result
    	la $a0, rowMsg
    	li $v0, 4
    	syscall
    	move $a0, $s6
    	li $v0, 1
    	syscall
    	la $a0, newline
    	li $v0, 4
    	syscall

    	addi $s3, $s3, 1
    	j Row_Major_Loop
Done_Row:
    	lw $s7, 0($sp)
    	lw $s6, 4($sp)
    	lw $s5, 8($sp)
    	lw $s4, 12($sp)
    	lw $s3, 16($sp)
    	lw $s2, 20($sp)
    	lw $ra, 24($sp)
    	addi $sp, $sp, 28
    	jr $ra

############
# OPTION 3 #
############
Col_Major_Sum:
    	addi $sp, $sp, -28
    	sw $ra, 24($sp)
    	sw $s2, 20($sp)
    	sw $s3, 16($sp)
    	sw $s4, 12($sp)
    	sw $s5, 8($sp)
    	sw $s6, 4($sp)
    	sw $s7, 0($sp)

    	add $s2, $zero, $a1  	# $s2 = base address of the matrix
    	add $s5, $zero, $a0   	# $s5 = N (matrix size)

    	add $s4, $0, $0 	# $s4 = column index
    	add $s6, $0, $0      	# $s6 = sum
Col_Major_Loop:
    	bge $s4, $s5, Done_Col  
    	add $s3, $zero, $zero 	# $s3 = row index
Col_Major_Inner_Loop:
    	bge $s3, $s5, Next_Col 	# all rows in the current column are processed

    	# Offset: (j * N + i) * 4
    	mul $t0, $s4, $s5           
    	add $t0, $t0, $s3          
    	mul $t0, $t0, 4              
    	add $t0, $t0, $s2          
    	lw $t1, 0($t0)              

    	add $s6, $s6, $t1
    	addi $s3, $s3, 1
    	j Col_Major_Inner_Loop
Next_Col:
    	# Print current result
    	la $a0, colMsg
    	li $v0, 4
    	syscall
    	move $a0, $s6
    	li $v0, 1
    	syscall
    	la $a0, newline
    	li $v0, 4
    	syscall

    	addi $s4, $s4, 1
    	j Col_Major_Loop
Done_Col:
    	lw $s7, 0($sp)
    	lw $s6, 4($sp)
    	lw $s5, 8($sp)
    	lw $s4, 12($sp)
    	lw $s3, 16($sp)
    	lw $s2, 20($sp)
    	lw $ra, 24($sp)
    	addi $sp, $sp, 28
    	jr $ra


