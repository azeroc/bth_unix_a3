# FUNCTION LNTWO: Take one argument and return the binary logarithm of that argument.
# For example: lntwo 32 = 5.
    .section data
    .section text
    .globl lntwo
    .type lntwo, @function
# Arguments:
# 1st arg, %rdi: lntwo first operand
lntwo:
    movq    $0, %rax    # Initialize return value
lntwo_exit:
    ret                 # Return with result stored in return register %rax
