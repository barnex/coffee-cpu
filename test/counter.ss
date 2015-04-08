
// This test program cycles the hex display
// through all 16-bit values

#def display 0x3FFF
#def Rcount R1
#def PC     R15

#label _start
XOR   R0     R2       A R3     +cmp
ADD   R1     R2       N R3     -cmp
ADD   R2     7       GE R3     -cmp
STORE R1     7       LT R3     +cmp
STORE R0     display  A Rcount -cmp
ADD   Rcount 1        A Rcount -cmp
ADD   R0     _start   A PC     -cmp
