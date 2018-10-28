To use:
1. Execute 'make' (this will build calc3x.exe binaries as well as compile fact.a, lntwo.a, gcd.a and myprint.a libraries)
2. Usage: ./x86-64-driver.sh <.calc program path>
2.1. Example: ./x86-64-driver.sh calc/looptest.calc
2.2. Execute compiled .calc prog: ./looptest
2.3. Look at generated assembly source code: less ./looptest.s

Note: Specification wasn't clear if library assembly source must be included in end-result .s file of a compiled calc program. 
      Currently x86-64-driver.sh doesn't include library source code in compiled calc program's .s source.
	  See src/ dir files for library sources.
	  