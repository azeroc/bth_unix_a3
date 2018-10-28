# FUNCTION GCD: Take two arguments and return the greatest common divisor between the two arguments.
# For example: 36 gcd 24 = 12.
    .section .data
    .section .text
    .globl gcd
    .type gcd, @function
# Arguments:
# 1st arg, %rdi: gcd first  (left)  operand X
# 2nd arg, %rsi: gcd second (right) operand Y
gcd:
    movq    $0, %rax    # Initialize return value
gcd_abs_rdi:            # Make sure RDI (1st gcd operand X) is absolute value
    cmpq    $0, %rdi
    jge     gcd_abs_rsi
    neg     %rdi
gcd_abs_rsi:            # Make sure RSI (2nd gcd operand Y) is absolute value
    cmpq    $0, %rsi
    jge     gcd_loop
    neg     %rsi
gcd_loop:    
    movq    %rdi, %rax  # %rax is dividend before division and quotient after division
    xorq    %rdx, %rdx  # Zero out %rdx register before division 
                        # (because dividend is combination of %rdx:%rax and we want top 64 bits / %rdx zeroed, otherwise we get floating point exception)
    divq    %rsi        # Unsigned divide X by %rsi Y, quotient Q stored in %rax, remainder R in %rdx
    movq    %rsi, %rdi  # X = Y
    movq    %rdx, %rsi  # Y = R
    cmpq    $0, %rsi    # While Y > 0, keep looping
    jg      gcd_loop
gcd_exit:
    movq    %rdi, %rax  # Store result in RAX return register
    ret                 # Return with result stored in return register %rax
