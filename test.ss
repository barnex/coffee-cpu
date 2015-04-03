LOADLI  R1 1
ADD 	R2 R2 R1
STORE 	R2 0xFFFF // write to display
JMPZ 	R0  -2 
