# FUNCTION GCD: Take two arguments and return the greatest common divisor between the two arguments.
# For example: 36 gcd 24 = 12.
    .section .data
    .section .text
    .globl gcd
    .type gcd, @function
# Arguments:
# 1st arg, %rdi: gcd first (left) operand
# 2nd arg, %rsi: gcd second (right) operand
gcd:
    movq    $0, %rax    # Initialize return value
gcd_exit:
    ret                 # Return with result stored in return register %rax
