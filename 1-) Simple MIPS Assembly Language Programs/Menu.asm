# Author: Yunus Gunay

.data
	.align 4
    	array: .space 400
    	message_size: .asciiz "Enter the number of elements (0-100): "
	prompt_element: .asciiz "Enter number: "
	prompt_menu: .asciiz "\n\na. Find the maximum number stored in the array and display that number.\nb. Find the number of times the maximum number appears in the array.\nc. Find how many numbers we have (other than the maximum number) that we can divide the maximum number without a remainder.\nd. Quit.\n\n"
	max_num_msg: .asciiz "\nMaximum number stored in the array is: "
    	max_count_msg: .asciiz "\nThe maximum number appears this many times: "
    	divisors_count_msg: .asciiz "\nThe number of elements that divide the maximum number without a remainder is: "
    	quit_msg: .asciiz "\nGood bye!"
    
.text
.globl main
menu_options:
	# Initialization of menu options
	li $s0, 'a'
    	li $s1, 'b'
    	li $s2, 'c'
    	li $s3, 'd'
    	
main:
	# Prompt for entering array size
    	li $v0, 4
    	la $a0, message_size
    	syscall
    	# Read array size
    	li $v0, 5
    	syscall
    	move $t0, $v0  		# t0 = array size
    
    	# Check bounds
    	bltz $t0, quit
    	bgt $t0, 100, quit
    
    	# Initialization
    	li $t1, 1  		# t1 = index
    	la $t2, array  		# t2 = base address

ask_elements:
    	bgt $t1, $t0, calculate
    
    	# Prompt for entering element
    	li $v0, 4
    	la $a0, prompt_element
    	syscall
    	li $v0, 5
    	syscall
    
    	# Store number into the array
    	sw $v0, 0($t2)
    
    	# Increment base address and index
    	addi $t2, $t2, 4
    	addi $t1, $t1, 1
    	j ask_elements


### FIND VALUES ###   
calculate:
	# Initialization
	li $t1, 0
	la $t2, array
	lw $t3, 0($t2)		# t3 = max number	
find_max:
	bge $t1, $t0, find_count
	
	lw $t4, 0($t2)		# t4 = array[index]
	ble $t4, $t3, continue
	move $t3, $t4
continue:
	addi $t1, $t1, 1
	addi $t2, $t2, 4
	j find_max

find_count:
	# Initialization
	li $t1, 0
	la $t2, array
	li $t5, 0    		# t5 = max number's count
	li $t6, 0		# t6 = max number's divisors count
array_loop:
	bge $t1, $t0, menu
	
	lw $t4, 0($t2)		# t4 = array[index]
	beq $t4, $t3, increment_count
	
	div $t3, $t4
	mfhi $t7		# t7 = remainder
	bne $t7, $zero, skip
	addi $t6, $t6, 1
	j skip
increment_count:
	addi $t5, $t5, 1
skip:
	addi $t1, $t1, 1
	addi $t2, $t2, 4
	j array_loop

### MENU ###	
menu:
	# Menu prompt
	li $v0, 4
	la $a0, prompt_menu
	syscall
	# Read user's choice
	li $v0, 12
    	syscall
    	
    	# Check menu option
    	beq $v0, $s0, option_a      	# display max number => $t3
    	beq $v0, $s1, option_b		# display max number's count => $t5
    	beq $v0, $s2, option_c 		# display max number's divisors count => $t6
    	beq $v0, $s3, quit            	# quit
    	j menu
	
option_a:
	# Option a prompt
	li $v0, 4
	la $a0, max_num_msg
	syscall
	
	# Display value
	li $v0, 1
	move $a0, $t3
	syscall
	
	j menu
	
option_b:
	# Option b prompt
	li $v0, 4
	la $a0, max_count_msg
	syscall
	
	# Display value
	li $v0, 1
	move $a0, $t5
	syscall
	
	j menu

option_c:
	# Option c prompt
	li $v0, 4
	la $a0, divisors_count_msg
	syscall
	
	# Display value
	li $v0, 1
	move $a0, $t6
	syscall
	
	j menu

quit:
	# Option d prompt
	li $v0, 4
	la $a0, quit_msg
	syscall
	# Stop program
	li $v0, 10
	syscall
