/*
Assembler for coffee-cpu micro-instructions to intel HEX files
 	ass file.ss


Syntax

The instruction syntax closely follows the micro-instruction bit pattern described in package isa:
 	Op  Ra  Rb|value  Cond  Rc  cmp
with:
 	Op    :Opcode: LOAD|STORE|AND|OR|XOR|ADD|ADDC|SUB|MUL|DIV|SDIV
	Ra    :Register A (1st operand): R0 - R15
	Rb    :Register B (2nd operand): R0 - R13
	value :Immediate value (2nd operand): 14 bit number
	Cond  :Writeback condition: A|N|Z|NZ|GE|LT
	cmp   :update status register: +cmp|-cmp

E.g.:

 	ADD R0 R1 A R2 -cmp
R2 = R0 + R1, always executed (A), result not compared to zero


 	ADD R0 42 A R2 +cmp
R2 = R0 + 42, always executed (A), result compared to zero (affects next instruction)

 	ADD R0 R1 A R2 +cmp

*/
package main
