# Author: Yunus Gunay

.data
    .align 4  # Ensures array alignment at word boundaries
    array: .space 80  # Allocates memory for a maximum of 20 elements (4 bytes each)
    message: .asciiz "Enter the number of elements (0-20): "
    prompt: .asciiz "Enter number: "
    displayMessage: .asciiz "\nArray contents:\n"
    reversedMessage: .asciiz "\nArray is reversed."
    newLine: .asciiz "\n"

.text
main:
    li $v0, 4
    la $a0, message
    syscall

    # Read the number of elements
    li $v0, 5
    syscall
    move $t0, $v0

    # Check bounds (0-20)
    blez $t0, stop
    bgt $t0, 20, stop

    # Initialize index and base address of the array
    addi $t1, $0, 0
    la $t2, array 
    j ask_elements

    # t0 = number of elements
    # t1 = index (i = 0)
    # t2 = array's base address

ask_elements:
    bge $t1, $t0, display  # index >= number of elements, go to display

    # Prompt user to enter a number
    li $v0, 4
    la $a0, prompt
    syscall

    # Read the number
    li $v0, 5
    syscall

    # Store the number in the array
    sll $t3, $t1, 2
    add $t3, $t3, $t2
    sw $v0, 0($t3)

    addi $t1, $t1, 1
    j ask_elements

display:
    li $v0, 4
    la $a0, displayMessage
    syscall

    # Display the array contents
    li $t1, 0  # index (i = 0)
    la $t2, array  # base address
    j display_loop

display_loop:
    bge $t1, $t0, check_reversed  # index >= number of elements, go to check_reversed

    # Display each array element
    li $v0, 1
    lw $a0, 0($t2)
    syscall

    # New line after each element
    li $v0, 4
    la $a0, newLine
    syscall

    addi $t2, $t2, 4
    addi $t1, $t1, 1 
    j display_loop

check_reversed:
    beq $t3, 1, stop
    lui $at, 0x0000  # set 1 for reversed state
    ori $t3, $at, 0x0001  # li $t3, 1
    j reverse

reverse:
    li $v0, 4
    la $a0, reversedMessage
    syscall
    
    li $t1, 0  # start index: 0
    subi $t4, $t0, 1  # end index: array size - 1
    la $t2, array  # array's base address
    j reverse_loop

reverse_loop:
    bge $t1, $t4, display  # start index >= end index, jump back to display reversed array

    # t5 = start element
    # t6 = end element
    sll $t5, $t1, 2
    add $t5, $t5, $t2  # address of the start element

    sll $t6, $t4, 2
    add $t6, $t6, $t2  # address of the end element

    # Swap
    lw $t7, 0($t5)     
    lw $t8, 0($t6)        
    sw $t8, 0($t5)     
    sw $t7, 0($t6)     

    # Move closer to the middle
    addi $t1, $t1, 1
    subi $t4, $t4, 1
    j reverse_loop

stop:
    # Exit program
    li $v0, 10
    syscall
