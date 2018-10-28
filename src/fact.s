# FUNCTION FACT: Take one argument and return the factorial of that argument. 
# For example: 0! = 1.
    .section .data
    .section .text
    .globl fact
    .type fact, @function
# Arguments:
# 1st arg, %rdi: factorial argument 'n'
fact:
    movq    $1, %rax    # Initialize return value
fact_loop:
    cmpq    $1, %rdi    # Jump to fact_exit if %rdi <= 1 (n <= 1)
    jle     fact_exit
    imulq   %rdi, %rax  # Multiply n * (n-1) * (n-2) ... * 2
    subq    $1, %rdi    # n = n-1
    jmp     fact_loop   # Keep looping
fact_exit:
    ret                 # Return with result stored in return register %rax
