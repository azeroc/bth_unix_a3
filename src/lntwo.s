# FUNCTION LNTWO: Take one argument and return the binary logarithm of that argument.
# For example: lntwo 32 = 5.
    .section .data
    .section .text
    .globl lntwo
    .type lntwo, @function
# Arguments:
# 1st arg, %rdi: lntwo first operand
lntwo:
    movq    $0, %rsi    # Initialize result (divide-by-2 counter)
lntwo_loop:
    cmpq    $0, %rdi    # If RDI <= 0, jump to exit, otherwise, continue loop
    jle     lntwo_exit
    shrq    $1, %rdi    # rdi = rdi >> 1 (logical shift right by 1 on rdi register, same thing as rdi div by 2)
    inc     %rsi        # result = result + 1, count how many times we managed to shift rdi before its value goes to 0
    jmp     lntwo_loop
lntwo_exit:
    movq    %rsi, %rax  # Assign result to RAX return-register
    ret                 # Return with result stored in return register %rax
