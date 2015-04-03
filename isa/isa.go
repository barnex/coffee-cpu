// package isa defines the instruction set
package isa

const (
	MAXREG = 255
	MAXINT = 1<<32 - 1
)

const NOP = 0x0

// Opcodes with Register, Address operands
const (
	LOAD   = 0x1
	STORE  = 0x2
	LOADLI = 0x3
	LOADHI = 0x4
	JMPZ   = 0x5
)

// Opcodes with 2 Register operands
const (
	MOV = 0x6
)

// Opcodes with 3 Register operands
const (
	AND = 0x7
	OR  = 0x8
	XOR = 0x9
	ADD = 0xA
)

const (
	FIRST_R2 = MOV // first opcode with 2 register arguments
	FIRST_R3 = AND // first opcode with 3 register arguments
)

func IsRegAddr(opc uint32) bool {
	return opc > NOP && opc < FIRST_R2
}

func IsReg2(opc uint32) bool {
	return opc >= FIRST_R2 && opc < FIRST_R3
}

func IsReg3(opc uint32) bool {
	return opc >= FIRST_R3
}
