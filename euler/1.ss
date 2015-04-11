// projecteuler.net problem1:
// If we list all the natural numbers below 10 that are multiples of 3 or 5, we get 3, 5, 6 and 9. The sum of these multiples is 23.
// Find the sum of all the multiples of 3 or 5 below 1000.
// Answer: 233168


#def display 0x3FFF
#def i       R1
#def sum     R2
#def max     1000

#label for1
ADD    sum   i  A sum -cmp
ADD    i     3  A   i -cmp
SUB    i   max  N  R0 +cmp
ADD    R0 for1 LT  PC -cmp

XOR i i A i -cmp

#label for2
DIV    i   3 N R0    -cmp
SUB    Rx  0 N R0    +cmp
ADD    sum i NZ sum  -cmp
ADD    i   5 A i     -cmp
SUB    i   max N R0  +cmp
ADD    R0 for2 LT PC -cmp

STORE sum display N R0 -cmp

