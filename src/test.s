/*
        push    100
        pop     i
L000:
        push    i
        push    0
        compGE
        jz      L001
        push    i
        print
        push    i
        push    1
        sub
        pop     i
        jmp     L000
L001:
*/
# PREPENDED "PROLOGUE" PART
    .section .data
fmt: .asciz "%d\n"
a: .quad 0x0
b: .quad 0x0
c: .quad 0x0
d: .quad 0x0
e: .quad 0x0
f: .quad 0x0
g: .quad 0x0
h: .quad 0x0
i: .quad 0x0
j: .quad 0x0
k: .quad 0x0
l: .quad 0x0
m: .quad 0x0
n: .quad 0x0
o: .quad 0x0
p: .quad 0x0
q: .quad 0x0
r: .quad 0x0
s: .quad 0x0
t: .quad 0x0
u: .quad 0x0
v: .quad 0x0
w: .quad 0x0
x: .quad 0x0
y: .quad 0x0
z: .quad 0x0
    .section .text
    .globl main
    .type main, @function
main:
# .CALC ASSEMBLY INSTRUCTION PROGRAM PART
    pushq $100
    popq i(%rip)
L000:
    pushq i(%rip)
    pushq $0

    # 'GE' start
    popq %rdx
    popq %rax
    movq $1, %r8
    movq $0, %r9
    cmpq %rdx, %rax # GAS/AT&T syntax swaps order around, example: "cmp $0, %rax" followed by "jl" branch will branch if "%rax < 0"
    cmovlq %r8, %r9
    cmpq %r8, %r9
    # 'GE' end
    jz L001

    pushq i(%rip)    
    # Printf start
    popq %rax
    pushq %rbp # Save old call frame
    movq %rsp, %rbp # Init new call frame
    leaq fmt(%rip), %rdi # Set format arg
    movq %rax, %rsi # Set 1st arg
    callq printf@PLT # Call printf    
    leave # Leave function call (restores old call frame)
    # Printf end

    pushq i(%rip)
    pushq $1
    popq %rdx
    popq %rax
    subq %rdx, %rax
    pushq %rax
    popq i(%rip)
    jmp L000
L001:
# APPENDED "EPILOGUE" PART
end:    
    ret

