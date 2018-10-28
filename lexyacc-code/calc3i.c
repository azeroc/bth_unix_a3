#include <stdio.h>
#include "calc3.h"
#include "y.tab.h"

static int lbl;

// Register usage: https://i.stack.imgur.com/WgcQv.png 
// Get n-th scratch register for function argument usage
// Supports up to 6 registers (index 0..5)
const char* get_arg_register(int index)
{
    switch (index) {
    case 0: // 1st arg
        return "rdi";
    case 1: // 2nd arg
        return "rsi";
    case 2: // 3rd arg
        return "rdx";
    case 3: // 4th arg
        return "rcx";
    case 4: // 5th arg
        return "r8";
    case 5: // 6th arg
        return "r9";
    default:
        return "7th_arg_reg_doesnt_exist";
    }
}

// generalized instruction (up to 6 arguments) set for function calls
void instrSetFunction(int argc, const char* funcName, int hasReturnValue) 
{
    /*  Function with 2 params example:
        popq    %rsi            # Load 2st arg
        popq    %rdi            # Load 1st arg
        pushq   %rbp            # Save old call frame
        movq    %rsp, %rbp      # Init new call frame
        callq   myfunction      # Call myfunction
        leave                   # Leave function call (restores old call frame)
    */

    // Make popq statements for loading arguments (in reverse due to stack's order)
    for (int i = (argc - 1); i >= 0; i--) {
        const char* arg_reg = get_arg_register(i);
        printf("\tpopq\t%%%s\n", arg_reg);
    }

    // Preserve old and setup new call-frame
    printf("\tpushq\t%%rbp\n");
    printf("\tmovq\t%%rsp, %%rbp\t\n");

    // Function call
    printf("\tcall\t%s\n", funcName);

    // Leave op for restoring call frame
    printf("\tleave\n");

    // Push return value if function makes it
    if (hasReturnValue == 1) {
        printf("\tpushq\t%%rax\n");
    }
}

// printf instruction set
void instrSetPrint()
{
    /*  EXAMPLE:
        leaq    fmt(%rip), %rdi # 1st arg: printf's format string pointer fmt (fmt = "%d\n" in calc3_prologue.s)
        popq    %rsi            # 2nd arg: previously pushed number
        pushq   %rbp            # Save old call frame
        movq    %rsp, %rbp      # Init new call frame        
        callq   printf@PLT      # Call printf (PLT address table)
        leave                   # Leave function call (restores old call frame)
    */

    printf("\tleaq\tfmt(%%rip), %%rdi\n");
    printf("\tpopq\t%%rsi\n");
    printf("\tpushq\t%%rbp\n");
    printf("\tmovq\t%%rsp, %%rbp\n");
    printf("\tcall\tprintf@PLT\n");
    printf("\tleave\n");
}

// binary-arithmetic instruction set
void instrSetArithmetic(int oper)
{
    /*  'SUB' / subtraction example:
        <2 pushq instrs for preparing 2 parameters for arithmetic op>
        popq    %rsi        # Get <2nd operand>
        popq    %rdi        # Get <1st operand>
        subq    %rdx, %rax  # <1st operand> minus <2nd operand>, result stored in %rax
        pushq   %rax        # Store result on stack (will be popq into symbol variable)
        <popq instr for storing %rax result in variable>
    */
    // Load operands
    printf("\tpopq\t%%rsi\n");
    printf("\tpopq\t%%rdi\n");

    // Main arithmetic op part
    switch (oper) {
    case '+': // Addition
        printf("\taddq\t%%rsi, %%rdi\n"); 
        break;
    case '-': // Subtraction
        printf("\tsubq\t%%rsi, %%rdi\n"); 
        break; 
    case '*': // Multiplication (I am assuming signed multiplication - imulq)
        printf("\timulq\t%%rsi, %%rdi\n"); 
        break;
    case '/': // Division (I am assuming signed division - idivq)
        // This gets bit more complicated since division operator uses temp registers for additional stuff like quotient and remainder
        // See more: https://cs.brown.edu/courses/cs033/docs/guides/x64_cheatsheet.pdf (page #4)
        printf("\tmovq\t%%rdi, %%rax\n"); // Store dividend value in RAX from RDI (1st arg)
        printf("\txorq\t%%rdx, %%rdx\n"); // Zero out RDX due to RDX:RAX dividend structure for div instruction
                                          // Otherwise we get Floating point exceptions (because RDX is dirty and not zeroed out)
        printf("\tidivq\t%%rsi\n");       // RDI div by RSI, after division: RDX = remainder, RAX = quotient
        printf("\tmovq\t%%rax, %%rdi\n"); // Store RAX (quotient) as result in RDI
        break;
    }

    // Store/push result from RDI
    printf("\tpushq\t%%rdi\n");
}

// comparison instruction set
void instrSetComparison(int oper)
{
    /*  'GE' / Greater-than-or-equal-to example:
        popq    %rdx        # cmpq left arg
        popq    %rax        # cmpq right arg
        movq    $1, %r8     # r8 = 1
        movq    $0, %r9     # r9 = 0, will be changed to r9 = 1 if main condition (below op) succeeds
        cmpq    %rdx, %rax  # GAS/AT&T syntax swaps order around, example: "cmp $0, %rax" followed by "jl" branch will branch if "%rax < 0"
        cmovlq  %r8, %r9    # CMOVcc instruction with appended 'q' to indicate that we are dealing with 64-bit (see: https://www.felixcloutier.com/x86/CMOVcc.html)
                            # This is the only instruction what will change depending on requested comparison operation
        cmpq    %r8, %r9    # We end with simple %r8 == %r9 cmp op, if main comparison op succeeded, then r9 = r8 = 1, otherwise r8 != r9
        <jz instr>          # We know that WHILE or IF-ELSE will append "jz" (jump if zero/equal) instruction after comparison instruction set
    */

    printf("\tpopq\t%%rdx\n");
    printf("\tpopq\t%%rax\n");
    printf("\tmovq\t$1, %%r8\n");
    printf("\tmovq\t$0, %%r9\n");
    printf("\tcmpq\t%%rdx, %%rax \n");

    // Main comparison op part
    // Note: WHILE and IF-ELSE want to continue while condition is true
    //       ELSE they want to execute jz (jump if zero/equal) operation
    //       So we want to use inversed logic for main comparison cmpq operations to activate jump condition
    switch (oper) {
    case '<': // Less-than
        // Inverse: greater-than or equal-to
        printf("\tcmovgeq\t%%r8, %%r9\n");
        break;
    case '>': // Greater-than
        // Inverse: less-than or equal-to
        printf("\tcmovleq\t%%r8, %%r9\n");
        break;
    case GE: // Greater-than or equal-to
        // Inverse: less-than
        printf("\tcmovlq\t%%r8, %%r9\n");
        break;
    case LE: // Less-than or equal-to
        // Inverse: Greater-than
        printf("\tcmovgq\t%%r8, %%r9\n");
        break;
    case NE: // Not-equal
        // Inverse: equal
        printf("\tcmoveq\t%%r8, %%r9\n");
        break;
    case EQ: // Equal
        // Inverse: not-equal
        printf("\tcmovneq\t%%r8, %%r9\n");
        break;
    }
    
    printf("\tcmpq\t%%r8, %%r9\n");
}

int ex(nodeType *p) {
    int lbl1, lbl2;

    if (!p) return 0;
    switch(p->type) {
    case typeCon:       
        printf("\tpushq\t$%d\n", p->con.value); 
        break;
    case typeId:        
        printf("\tpushq\t%c(%%rip)\n", p->id.i + 'a'); 
        break;
    case typeOpr:
        switch(p->opr.oper) {
        case WHILE:
            printf("L%03d:\n", lbl1 = lbl++);
            ex(p->opr.op[0]);
            printf("\tjz\tL%03d\n", lbl2 = lbl++);
            ex(p->opr.op[1]);
            printf("\tjmp\tL%03d\n", lbl1);
            printf("L%03d:\n", lbl2);
            break;
        case IF:
            ex(p->opr.op[0]);
            if (p->opr.nops > 2) {
                /* if else */
                printf("\tjz\tL%03d\n", lbl1 = lbl++);
                ex(p->opr.op[1]);
                printf("\tjmp\tL%03d\n", lbl2 = lbl++);
                printf("L%03d:\n", lbl1);
                ex(p->opr.op[2]);
                printf("L%03d:\n", lbl2);
            } else {
                /* if */
                printf("\tjz\tL%03d\n", lbl1 = lbl++);
                ex(p->opr.op[1]);
                printf("L%03d:\n", lbl1);
            }
            break;
        case PRINT:     
            ex(p->opr.op[0]);
            instrSetPrint();
            break;
        case '=':
            ex(p->opr.op[1]);
            printf("\tpopq\t%c(%%rip)\n", p->opr.op[0]->id.i + 'a');
            break;
        case UMINUS:
            ex(p->opr.op[0]);
            printf("\tpopq\t%%rax\n");  // Pop argument for negation
            printf("\tnegq\t%%rax\n");  // Negate argument value
            printf("\tpushq\t%%rax\n"); // Push negated value
            break;
        case FACT:
            ex(p->opr.op[0]);
            instrSetFunction(1, "fact", 1);
            break;
        case LNTWO:
            ex(p->opr.op[0]);
            instrSetFunction(1, "lntwo", 1);
            break;
        default:
            ex(p->opr.op[0]);
            ex(p->opr.op[1]);
            switch(p->opr.oper) {
                case GCD:   
                    instrSetFunction(2, "gcd", 1);
                    break;
                case '+':
                case '-':
                case '*':
                case '/':
                    instrSetArithmetic(p->opr.oper); 
                    break;
                case '<':
                case '>':
                case GE:
                case LE:
                case NE:
                case EQ:
                    instrSetComparison(p->opr.oper); 
                    break;
            }
        }
    }
    return 0;
}
