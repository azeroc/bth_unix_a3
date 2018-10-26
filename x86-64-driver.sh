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

