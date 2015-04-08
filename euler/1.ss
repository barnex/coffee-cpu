// projecteuler.net problem1:
// If we list all the natural numbers below 10 that are multiples of 3 or 5, we get 3, 5, 6 and 9. The sum of these multiples is 23.
// Find the sum of all the multiples of 3 or 5 below 1000.


#def display 0xFFFF
#def $3      R1
#def $1000   R2
#def i       R3
#def sum     R4
#def cmp     R5
#def mod     R6
#def $5      R7
LOADLI $3    3   
LOADLI $5    5
LOADLI $1000 1000

#label for1
	ADD    sum i       sum
	ADD    i   $3      i
SUB    i   $1000   cmp
JUMPLT cmp for1

XOR i i i
#label for2
	DIV    i   $3    cmp // i%3 -> mod
	JUMPZ  mod cont
		ADD    sum i     sum
	#label cont
	ADD    i   $5    i
	SUB    i   $1000 cmp
JUMPLT cmp for2

STORI sum display

