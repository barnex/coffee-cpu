// package isa defines the instruction set
package isa

import (
//"fmt"
)

// Machine properties
const (
	MEMBITS      = 1 << 13
	MEMBYTES     = MEMBITS / 8
	WORDBYTES    = 4
	MEMWORDS     = MEMBYTES / WORDBYTES
	NREG         = 256
	MAXREG       = NREG - 1
	PERI_DISPLAY = 0xFFFF
	MAXINT       = 1<<32 - 1
)

// micro-instruction bits
const (
	ImmB = 31
	RegA = 30
	RegB = 26
	ImmV = 22
	Opc  = 14
	RegC = 9
	Cond = 5
	Comp = 2
)

// ALU Opcodes
const (
	LOAD  = 0x01 // LOAD     Ra Rb Rc  : Rc = mem[Ra+Rb]
	STORE = 0x02 // STORE    Ra Rb Rc  : mem[Ra+Rb] = Rc
	AND   = 0x03 // AND      Ra Rb Rc  : bitwise and: Rc = Ra & Rb
	OR    = 0x04 // OR       Ra Rb Rc  : bitwise or : Rc = Ra | Rb
	XOR   = 0x05 // XOR      Ra Rb Rc  : bitwise xor: Rc = Ra ^ Rb
	ADD   = 0x06 // ADD      Ra Rb Rc  : integer add: Rc = Ra + Rb
	ADDC  = 0x07 // ADD      Ra Rb Rc  : add with carry
	SUB   = 0x08 // SUB      Ra Rb Rc  : Rc = Ra - Rb
	MUL   = 0x09 // MUL      Ra Rb Rc  : Rc = (Ra*Rb)[31:0], R(c+1) = (Ra*Rb)[63:32]
	DIV   = 0x0A // DIV      Ra Rb Rc  : unsigned division Rc = Ra/Rb, R(c+1) = Ra%Rb
	SDIV  = 0x0B // SDIV     Ra Rb Rc  : signed division Rc = Ra/Rb, R(c+1) = Ra%Rb
)

var OpcodeStr = map[uint8]string{
	LOAD:  "LOAD",
	STORE: "STORE",
	AND:   "AND",
	OR:    "OR",
	XOR:   "XOR",
	ADD:   "ADD",
	ADDC:  "ADDC",
	SUB:   "SUB",
	MUL:   "MUL",
	DIV:   "DIV",
	SDIV:  "SDIV",
}

var Opcodes map[string]uint8

func init() {
	Opcodes = make(map[string]uint8)
	for k, v := range OpcodeStr {
		Opcodes[v] = k
	}
}

//// Does this opcode take a register + address operand?
//func IsRegAddr(opc uint8) bool {
//	return opc >= LOADI && opc <= JUMPGTE
//}
//
//// Does this opcode take a 2 register operands?
//func IsReg2(opc uint8) bool {
//	return opc == MOV
//}
//
//// Does this opcode take a 3 register operands?
//func IsReg3(opc uint8) bool {
//	return opc == LOAD || opc == STORE || (opc >= AND && opc < HALT)
//}
//
//
//func OpStr(opc uint8) string {
//	if s, ok := OpcodeStr[opc]; ok {
//		return s
//	} else {
//		return fmt.Sprintf("ILLEGAL:%2X", opc)
//	}
//}
