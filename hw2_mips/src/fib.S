main:
    addi $a0, $zero, 10 # n = 10
    jal fib          # call fib(10)
    j exit

fib:
    #--------------------------------------#
    #  \^o^/   Write your code here~  \^o^/
    slti $t0, $a0, 2 #if a0 < 2, t0 = 1
    beq $t0, $zero, ELSE #recursive
    
    add $v0, $zero, $a0 # v0(ans) = a0(n)
    jr $ra
    
ELSE:
    addi $sp, $sp, -12
    sw $ra, 0x0($sp)    # Save $ra register into stack
    
    #fib(n-1)
    sw $a0, 4($sp) #store n(a0) to sp4
    addi $a0, $a0, -1
    jal fib
    
    sw $v0, 8($sp) #sp8 = v0(ans)
    
    #fib(n-2)
    lw $a0, 4($sp) #a0 = sp4()
    addi $a0, $a0, -2
    jal fib
    
    #fib(n-1)+fib(n-2)
    lw $k0, 8($sp) #k0 = sp8
    add $v0, $v0, $k0
    
    #--------------------------------------#

    lw $ra, 0x0($sp)    # Load $ra register from stack
    addi $sp, $sp, 12
    jr $ra

exit:
