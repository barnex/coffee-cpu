LOADLI  R1 1
STORE 	R1 0xFFFF // write to display
ADD 	R1 R2 R2
STORE 	R2 0xFFFF // write to display
JMPZ 	R0  -2 
