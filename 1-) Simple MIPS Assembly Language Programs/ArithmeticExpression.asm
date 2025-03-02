# Author: Yunus Gunay

.data
	B: .asciiz "Enter integer value of B: "
	C: .asciiz "Enter integer value of C: "
	D: .asciiz "Enter integer value of D: "
	outputMessage: .asciiz "\nThe result of the expression A = (B / C + D mod B - C) / B is: "

.text
main:
	# Prompt for B
    	li $v0, 4
    	la $a0, B
    	syscall
    	
    	li $v0, 5
    	syscall
    	move $s0, $v0  # $s0 = B
    	
    	# Prompt for C
    	li $v0, 4
    	la $a0, C
    	syscall
    	
    	li $v0, 5
    	syscall
    	move $s1, $v0  # $s1 = C
    	
    	# Prompt for D
    	li $v0, 4
    	la $a0, D
    	syscall
    	
    	li $v0, 5
    	syscall
    	move $s2, $v0  # $s2 = D
    	
    	# B / C
    	move $a0, $s0
    	move $a1, $s1
    	jal divAndMod
    	move $t5, $v0  	
    	
    	# D mod B
    	move $a0, $s2
    	move $a1, $s0
    	jal divAndMod
    	move $t6, $v1
    	
    	# (B / C + D Mod B - C )
    	add $t7, $t5, $t6
    	sub $t7, $t7, $s1
   	   	
    	# t4 / B
    	move $a0, $t7
    	move $a1, $s0
    	jal divAndMod
    	move $t8, $v0
    	   	
    	# Display result
    	li $v0, 4
    	la $a0, outputMessage
    	syscall
    	
    	li $v0, 1
    	move $a0, $t8
    	syscall
    	    	
stop:
	li $v0, 10
	syscall


# a0 = numerator, a1 = denominator => a0 / a1 => t0 / t1
# returns v0: quotient, v1: remainder (mod)
divAndMod:
	move $t0, $a0
	move $t1, $a1
	
	# If numerator is negative, make it positive
	bltz $t0, negate_numerator	
	# Else
	move $t2, $t0	
	
	j check_denominator
negate_numerator:
	mul $t2, $t0, -1  # t2 = abs(numerator)

check_denominator:
	# If denominator is negative, make it positive
	bltz $t1, negate_denominator	
	# Else
	move $t3, $t1  # t3 = abs(denominator)	
	j calculate_division  # t2 / t3
negate_denominator:
	mul $t3, $t1, -1
	
calculate_division:
	li $v0, 0  # quotioent = 0, initially
divAndMod_loop:
	blt $t2, $t3, divAndMod_done
	sub $t2, $t2, $t3
	addi $v0, $v0, 1
	j divAndMod_loop

# Sign of division operation (quotient)
divAndMod_done:
	move $v1, $t2
	
	# Determine the sign of the quotient
	mul $t4, $t0, $t1  # t4 is negative if signs are different
	bltz $t4, negate_quotient
	
	j find_mod
negate_quotient:
	mul $v0, $v0, -1

# Sign of mod operation (mod, remainder)
find_mod:
	bltz $t0, check_denominator_sign 
	bgtz $t1, nPos_dPos  # Numerator positive, denominator positive
	j nPos_dNeg  # Numerator positive, denominator negative
nPos_dPos:
	jr $ra
check_denominator_sign:
	bgtz $t1, nNeg_dPos  # Numerator negative, denominator positive
	mul $v1, $v1, -1  # Numerator negative, denominator negative
	jr $ra
nNeg_dPos: 
	mul $v1, $v1, -1
	add $v1, $v1, $t3	
	jr $ra
nPos_dNeg:
	add $v1, $v1, $t1
	jr $ra
