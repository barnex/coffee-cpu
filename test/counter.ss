
// This test program cycles the hex display
// through all 16-bit values

LOADLI  R1 1
#def one R1

#def display 0xFFFF
#def counter R2

STORI	counter display 
ADD 	one counter counter
JUMPZ 	R0  -2 
