#include <stdio.h>
#include "calc3.h"
#include "y.tab.h"

static int lbl;

// printf instruction set
void instrSetPrint()
{
    /*  EXAMPLE:
        popq    %rax            # Load previously pushed arg into %rax
        pushq   %rbp            # Save old call frame
        movq    %rsp, %rbp      # Init new call frame
        leaq    fmt(%rip), %rdi # Set format arg
        movq    %rax, %rsi      # Set 1st arg (%rsi) from %rax
        callq   printf@PLT      # Call printf (PLT address table)
        leave                   # Leave function call (restores old call frame)
    */

    // Printf function boilerplate
    printf("\tpopq\t%%rax\n");
    printf("\tpushq\t%%rbp\n");
    printf("\tmovq\t%%rsp, %%rbp\n");
    printf("\tleaq\tfmt(%%rip), %%rdi\n");
    printf("\tmovq\t%%rax, %%rsi\n");
    printf("\tcallq\tprintf@PLT\n");
    printf("\tleave\n");
}

// 2-parameter arithmetic instruction set
void instrSetArithmetic(int oper)
{
    /*  'SUB' / subtraction example:
        <2 pushq instrs for preparing 2 parameters for arithmetic op>
        popq    %rdx        # Get <2nd operand>
        popq    %rax        # Get <1st operand>
        subq    %rdx, %rax  # <1st operand> minus <2nd operand>, result stored in %rax
        pushq   %rax        # Store result on stack (will be popq into symbol variable)
        <popq instr for storing %rax result in variable>
    */
    // Common boilerplate starting part
    printf("\tpopq\t%%rdx\n");
    printf("\tpopq\t%%rax\n");

    // Main arithmetic op part
    switch (oper) {
    case '+': // Addition
        printf("\taddq\t%%rdx, %%rax\n"); 
        break;
    case '-': // Subtraction
        printf("\tsubq\t%%rdx, %%rax\n"); 
        break; 
    case '*': // Multiplication (I am assuming signed multiplication - imulq)
        printf("\timulq\t%%rdx, %%rax\n"); 
        break;
    case '/': // Division (I am assuming signed division - idivq)
        printf("\tidivq\t%%rdx, %%rax\n"); 
        break;
    }

    // Common boilerplate ending part
    printf("\tpushq\t%%rax\n");
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

    // Common boilerplate starting part
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
    
    // Common boilerplate ending part
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
            printf("\tneg\n");
            break;
        case FACT:
            ex(p->opr.op[0]);
            printf("\tfact\n");
            break;
        case LNTWO:
            ex(p->opr.op[0]);
            printf("\tlntwo\n");
            break;
        default:
            ex(p->opr.op[0]);
            ex(p->opr.op[1]);
            switch(p->opr.oper) {
                case GCD:   
                    printf("\tgcd\n"); 
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
