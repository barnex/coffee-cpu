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

LOADLI R1 3   
LOADLI R4 1000
   ADD R3 R2   R3  
   ADD R2 R1   R2
   CMP R2 
JMPZ 
