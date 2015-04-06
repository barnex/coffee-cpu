// projecteuler.net problem1:
// If we list all the natural numbers below 10 that are multiples of 3 or 5, we get 3, 5, 6 and 9. The sum of these multiples is 23.
// Find the sum of all the multiples of 3 or 5 below 1000.

// 	sum := 0
// 	for i:=3; i<1000; i+=3{
// 		sum += i
// 	}
// 	for i:=5; i<1000; i+=5{
// 		if i % 3 != 0{
// 			sum += i
// 		}
// 	}
// 	println(sum)

// R1: 3
// R2: i  
// R3: sum
// R4: 1000


#def display 0xFFFF
#def $3      R1
#def $1000   R2
#def i       R3
#def sum     R4
#def cmp     R5
LOADLI $3    3   
LOADLI $1000 10

ADD    i   $3    i
SUB    i   $1000 cmp
JUMPLT cmp -2
STORI i display

