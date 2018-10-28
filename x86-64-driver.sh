#!/bin/bash

# Usage as per specification is just single argument - calc program:
# x86-64-driver.sh $1
# Where $1: .calc file

# What to do:
# 1. Create initial assembly file named $1.s with general header or "start" code
# 2. Generate Assembly code from calc3i.c program and append it to the $1.s file
# 2.1. How-to: ./bin/calc3i.exe < $1 >> $1.s
# 3. Append general assembly "end" code
# 4. Use GCC to link and assemble $1.s file into executable (dont forget to link 3.3 "Additional functions" library)
# 4.1. Confusion: Should end result assembly file $1.s be left as is or should it be recreated with injected library assembly?

CALC_EXT=".calc"
CALC_PATH="$1"
GCC_FLAGS="-Llib"
GCC_EXTRA_FLAGS=""
GCC_LIBS="-lfact -llntwo -lgcd -lmyprint"

usage() 
{
    echo "Usage: $0 <.calc program> [optional gcc compile flags]"
    echo "Example: $0 calc/looptest.calc"
    echo "Note #1: First parameter must be a valid file path with .calc extension"
    echo "Note #2: Program will generate executable named the same as <.calc program>, but without extension"
    echo "Note #3: Program will also generate .s assembly file (excluding code from external libraries)"
}

# Check if we got .calc prog parameter
if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi
shift
GCC_EXTRA_FLAGS="$*"

# Check if parameter ends in .calc extension
if [[ ${CALC_PATH: -5} != ".calc" ]]; then
    usage
    exit 1
fi

# Check if .calc file itself exists
if [[ ! -f ${CALC_PATH} ]]; then
    echo "File ${CALC_PATH} not found"
    exit 1
fi
CALC_PROG_NAME=`basename ${CALC_PATH}`
CALC_PROG=${CALC_PROG_NAME%.*}
CALC_PROG_ASM=${CALC_PROG}.s

# Create assembly instructions for calc prog (combined from prologue, calc3i calc prog parsing result and epilogue)
cat lexyacc-code/calc3_prologue.s > ${CALC_PROG_ASM}
bin/calc3i.exe < ${CALC_PATH} >> ${CALC_PROG_ASM}
cat lexyacc-code/calc3_epilogue.s >> ${CALC_PROG_ASM}

# Compile with GCC
gcc ${GCC_FLAGS} ${GCC_EXTRA_FLAGS} ${CALC_PROG_ASM} ${GCC_LIBS} -o ${CALC_PROG}

# Check if build succeeded
if [[ $? -ne 0 ]]; then
    echo "[GCC compile failed, leaving files as is ...]"
    exit $?
fi
