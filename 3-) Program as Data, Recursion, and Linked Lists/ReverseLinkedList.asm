# Author: Yunus Gunay

.data
	key_prompt:			.asciiz "\nEnter Key value of the Node: "
	data_prompt:			.asciiz "Enter Data value of the Node: "
	node_count_prompt:		.asciiz "Enter Number of Nodes: "
	linked_list_msg:		.asciiz "\n### LINKED LIST ###\n"
	reverse_list_msg:		.asciiz "\n\n### REVERSE LINKED LIST ###\n"
	
	format_arrow:			.asciiz "-->"
	format_comma:			.asciiz ","
	format_open_bracket:		.asciiz "("
	format_close_bracket:		.asciiz ")"
#=========================================================

.text
Main:
	# Prompt user for the number of nodes
	li $v0, 4
	la $a0, node_count_prompt
	syscall
	
	li $v0, 5
	syscall
	move $a0, $v0		# a0 = number of nodes		
	
	# Create linked list
	jal createLinkedList
	
	move $a0, $v0		# a0 = linked list address
	jal printLinkedList
	move $t0, $v0
	
	# Print link list as reversed
	li $v0, 4
	la $a0, reverse_list_msg
	syscall	
	move $a0, $t0
	jal printReverseLinkedList	
Stop:
	li $v0, 10
	syscall
#=========================================================


# $a0: number of nodes to be created ($a0 >= 1)
# $v0: returns list head
createLinkedList:
	addi $sp, $sp, -24
	sw $s0, 20($sp)	# number of nodes
	sw $s1, 16($sp)	# node counter
	sw $s2, 12($sp)	# points to the first node
	sw $s3, 8($sp)	# points to the head node
	sw $s4, 4($sp)
	sw $ra, 0($sp)
	
	move $s0, $a0		# s0 = number of nodes
	li $s1, 1		# s1 = node counter
	
	# Create Head Node
	li $a0, 12		# allocate space for node (12 bytes)
	li $v0, 9
	syscall
	move $s2, $v0		# s2 = points to the current node
	move $s3, $v0		# s3 = header
	
	# Get Key and Data values for Head Node
	jal getNodeValues	# v0 = Data & v1 = Key
				
	sw $v1, 0($s2)		# store the Key value.
	sw $v0, 4($s2)		# store the Data value.
addNode:
	beq $s1, $s0, allDone
	
	# Allocate space for the next code
	li $a0, 12
	li $v0, 9
	syscall
	sw $v0, 8($s2)		# connect current node to the new node
	move $s2, $v0		# move s2 to point to the new node

	jal getNodeValues
	
	sw $v1, 0($s2)		# store the Key value.
	sw $v0, 4($s2)		# store the Data value.
	
	addi $s1, $s1, 1
	j addNode
allDone:
	# Title Prompt
	li $v0, 4
	la $a0, linked_list_msg
	syscall
	
	# Terminate the list by setting the last node's next pointer to 0
	sw $zero, 8($s2)
	move $v0, $s3		# v0 = list head
	
	# Restore stack
	lw $ra, 0($sp)
	lw $s4, 4($sp)
	lw $s3, 8($sp)
	lw $s2, 12($sp)
	lw $s1, 16($sp)
	lw $s0, 20($sp)
	addi $sp, $sp, 24	
	jr $ra		
# Subprogram to prompt for Key and Data values
# v1 = Key & v0 = Data
getNodeValues:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Key value
	li $v0, 4
	la $a0, key_prompt
	syscall
	li $v0, 5
	syscall
	move $v1, $v0
	
	# Data value
	li $v0, 4
	la $a0, data_prompt
	syscall
	li $v0, 5
	syscall
	move $v0, $v0
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
#=========================================================

# $a0: address of the original linked list
printReverseLinkedList:
	# Recursion #
	beq $a0, $zero, doneReversePrint
		
	addi $sp, $sp, -16
    	sw $s0, 12($sp)               
    	sw $s2, 8($sp)             
    	sw $s3, 4($sp)              
    	sw $ra, 0($sp)          
	
	move $s0, $a0		# s0 = current node
	lw $s1, 8($s0)		# s1 = next node
	
	move $a0, $s1
	jal printReverseLinkedList
	
	# Printing in recursion	
	lw $s2, 4($s0)		# s2 = DATA
	lw $s3, 0($s0)		# s3 = KEY
	
	lw $s1, 8($s0)
	beq $s1, $zero, printNode
	
	# Print nodes as "-->(a, b)"
	li $v0, 4
    	la $a0, format_arrow
    	syscall	
printNode:	
	# Print "(Key,"
	li $v0, 4
	la $a0, format_open_bracket
	syscall
	move $a0, $s3
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, format_comma
	syscall
	
	# Print " Data)"	
	move $a0, $s2
	li $v0, 1		
	syscall	
	li $v0, 4
	la $a0, format_close_bracket
	syscall

	# Restore stack
	lw $ra, 0($sp)
    	lw $s3, 4($sp)           
    	lw $s2, 8($sp)                    
    	lw $s0, 12($sp)                
    	addi $sp, $sp, 16              

    	jr $ra              	# returns when recursion ends
doneReversePrint:
	jr $ra
#=========================================================


printLinkedList:
	# Stack
	addi $sp, $sp, -24
	sw $s0, 20($sp)
	sw $s1, 16($sp)
	sw $s2, 12($sp)
	sw $s4, 8($sp)
	sw $s5, 4($sp)
	sw $ra, 0($sp)

	move $s0, $a0		# s0 = points to the current node
	move $s5, $a0		# s5 = points to the current node for return
printNextNode:
	beq $s0, $zero, printedAll

	lw $s1, 8($s0)		# s1 = next node
	lw $s2, 4($s0)		# s2 = DATA
	lw $s4, 0($s0)		# s4 = KEY

	# Print "(Key,"
	li $v0, 4
	la $a0, format_open_bracket
	syscall
	move $a0, $s4
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, format_comma
	syscall
	
	# Print " Data)"	
	move $a0, $s2
	li $v0, 1		
	syscall	
	li $v0, 4
	la $a0, format_close_bracket
	syscall

	# Move to next node
	move $s0, $s1	
	beq $s0, $zero, printedAll
	
	li $v0, 4
	la $a0, format_arrow
	syscall
	j printNextNode
printedAll:
	move $v0, $s5
	# Restore stack
	lw $ra, 0($sp)
	lw $s5, 4($sp)
	lw $s4, 8($sp)
	lw $s2, 12($sp)
	lw $s1, 16($sp)
	lw $s0, 20($sp)
	addi $sp, $sp, 24
	jr $ra
