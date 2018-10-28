# FUNCTION MYPRINT: Take one argument (number) and prints it using syscall write to STDOUT. 
# For example: myprint 12345
# Syscall ref: http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/
    .section .data
# Write buffer needs enough space for <sign> + <all signed 64 bit digits> + '\n'
# Max value of 64 bit: https://en.wikipedia.org/wiki/9,223,372,036,854,775,807 
# This results in 1 + 19 + 1 = 21, lets round it to 24 just to be safe
writebuf: .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .section .text
    .globl myprint
    .type myprint, @function
# Arguments:
# 1st arg, %rdi: number argument for printing
# Notes:
# For addressing techniques such as writebuf(%rip, %rcx, 1), see this: https://en.wikibooks.org/wiki/X86_Assembly/GAS_Syntax#Address_operand_syntax
myprint:                        # [Initialization]
    movq    $0, %rcx                    # Initialize writebuf counter
    movq    $0, %r8                     # Initialize digit counter (there will always be at least 1 digit)
    movq    %rdi, %r9                   # Initialize dividend to given parameter
    movq    $1, %r11                    # Initialize size_t counter (+1 for '\n')
    movq    $1, %rax                    # Make sure that digit counter is at least 1 if "0" value was supplied
    cmpq    $0, %r9
    cmoveq  %rax, %r8
    cmpq    $0, %r9                     # Check if supplied value is negative, if it is continue to myprint_arg_negative, otherwise jump to prepare_loop
    jge     myprint_prepare_loop
myprint_arg_negative:           # [Make value absolute if it was negative, set early '-' sign]
    movb    $0x2D, writebuf(%rip)       # Write character '-' (HEX: 0x2D, DEC: 45) at start of writebuf
    incq    %rcx                        # Increment writebuf counter for zeroing
    incq    %r11                        # Increment size_t counter to compensate for extra '-' sign
    negq    %r9                         # Make dividend number positive
myprint_prepare_loop:           # [Loop: Zero out writebuf and also count digits of given number]
    leaq    writebuf(%rip), %rax        # Store *(writebuf + %rip) address into %rax                        
    movb    $0, (%rax, %rcx)            # Assign zero for a byte at addr *(%rax, %rcx)
    incq    %rcx                        # Increment writebuf counter
    cmpq    $24, %rcx                   # If counter >= 24, jump to next phase, otherwise keep going
    jge     myprint_writebuf_ini
    cmpq    $0, %r9                     # Jump to digit increment if quotient is still > 0
    jg      myprint_digit_inc
    jmp     myprint_prepare_loop
myprint_writebuf_ini:           # [Initialization for writebuf digit writing]
    movq    $1, %rax                    # Temporarily store 1 into RAX for cmov instruction
    movq    %rdi, %r9                   # Temporarily store RDI into R9, which will be sign-inversed
    negq    %r9
    addq    %r8, %r11                   # Add counted digits to size_t counter r11
    movq    $0, %rcx                    # Reset RCX which will be used as offset counter for writebuf
    cmpq    $0, %rdi                    # Make sure to start offset counter from 1 if we had to include negative sign
    cmovlq  %rax, %rcx                        
    cmpq    $0, %rdi                    # Also sign-inverse RDI if it is negative
    cmovlq  %r9, %rdi
    addq    %r8, %rcx                   # Add digit count to offset, digits will be written with offset going from right side to left side
myprint_writebuf_write_special: # [Write '\n', no need to write '\0' since array is zeroed]
    leaq    writebuf(%rip), %rax        # Store *(writebuf + %rip) address into %rdx
    movb    $0xA, (%rax, %rcx)          # Write character '\n' at the offset
    decq    %rcx                        # Decrement right-side-offset
myprint_writebuf_write_digits:  # [Loop: Write digits to writebuf]
    xorq    %rdx, %rdx                  # Zero out RDX for division
    movq    %rdi, %rax                  # Copy current quotient to dividend (we can use RDI directly this time since we wont need it anymore after this)
    movq    $10, %r10                   # Move divisor 10 into r10
    divq    %r10                        # Divide by r10 (10)
    movq    %rax, %rdi                  # Store quotient in RDI, replacing prev RDI value  
    movq    %rdx, %r9                   # Store remainder in R9
    addb    $0x30, %dl                  # Add "0x30" '0' to remainder RDX's lower 8 bits - DL
    leaq    writebuf(%rip), %rax        # Store *(writebuf + %rip) address into %rdx    
    movb    %dl, (%rax, %rcx)           # Write remainder digit character at the offset+writebuf_addr
    decq    %rcx                        # Decrement right-side-offset
    decq    %r8                         # Decrement digit counter
    cmpq    $0, %r8                     # Check if we are done writing digits, if we are - jump to syscall section, if not - keep looping
    jle     myprint_syscall_write
    jmp     myprint_writebuf_write_digits
myprint_syscall_write:          # [Syscall: Execute sys_write syscall, see: http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/]
    pushq   %rbp                        # Save old call frame
    movq    %rsp, %rbp                  # Init new call frame
    movq    $1, %rax                    # sys_write syscall opcode is 1
    movq    $1, %rdi                    # fd of STDOUT is 1
    leaq    writebuf(%rip), %rsi        # Store address of writebuf(%rip), this will "const char* buf" for sys_write
    movq    %r11, %rdx                  # size_t of byte array is r11
    syscall                             # Execute system call
    leave                               # Restore old call frame
    jmp     myprint_exit
myprint_digit_inc:                      # [Handle digit counting]
    xorq    %rdx, %rdx                  # Zero out RDX for division
    movq    %r9, %rax                   # Copy prev quotient to dividend
    movq    $10, %r10                   # Move divisor 10 into r10
    divq    %r10                        # Divide by r10 (10)
    movq    %rax, %r9                   # Save new quotient into dividend r9
    incq    %r8                         # Increment digit counter
    jmp     myprint_prepare_loop        # Get back to myprint_prepare_loop
myprint_exit:                   # [Function exit]
    ret                                 # Return, caller shouldn't expect any valid return value in %rax
