# [EPILOGUE START]
# We simply set return register (rax) to 0 (successful return) and return from main
main_end:
    movq $0, %rax
    ret
