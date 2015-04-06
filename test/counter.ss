
// This test program cycles the hex display
// through all 16-bit values

NOP               // just test a nop
LOADLI  R1 1
STORI	R2 0xFFFF // write to display
ADD 	R1 R2 R2
JUMPZ 	R0  -2 
