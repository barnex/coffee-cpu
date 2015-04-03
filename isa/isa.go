// package isa defines the instruction set
package isa

import (
	"fmt"
)

const (
	MAXREG = 255
	MAXINT = 1<<32 - 1
)

// Opcodes
const (
	NOP    = 0x0
	LOAD   = 0x1
	STORE  = 0x2
	LOADLI = 0x3
	LOADHI = 0x4
	JMPZ   = 0x5
	MOV    = 0x6
	AND    = 0x7
	OR     = 0x8
	XOR    = 0x9
	ADD    = 0xA
)

const (
	FIRST_R2 = MOV // first opcode with 2 register arguments
	FIRST_R3 = AND // first opcode with 3 register arguments
)

// Machine properties
const (
	MEMBITS      = 1 << 13
	MEMBYTES     = MEMBITS / 8
	WORDBYTES    = 4
	MEMWORDS     = MEMBYTES / WORDBYTES
	NREG         = 256
	PERI_DISPLAY = 0xFFFF
)

var opcodeStr = map[uint8]string{
	NOP:    "NOP",
	LOAD:   "LOAD",
	STORE:  "STORE",
	LOADLI: "LOADLI",
	LOADHI: "LOADHI",
	JMPZ:   "JMPZ",
	MOV:    "MOV",
	AND:    "AND",
	OR:     "OR",
	XOR:    "XOR",
	ADD:    "ADD",
}

func OpStr(opc uint8) string {
	if s, ok := opcodeStr[opc]; ok {
		return s
	} else {
		return fmt.Sprintf("ILLEGAL:%2X", opc)
	}
}

// Does this opcode take a register + address operand?
func IsRegAddr(opc uint8) bool {
	return opc > NOP && opc < FIRST_R2
}

// Does this opcode take a 2 register operands?
func IsReg2(opc uint8) bool {
	return opc >= FIRST_R2 && opc < FIRST_R3
}

// Does this opcode take a 3 register operands?
func IsReg3(opc uint8) bool {
	return opc >= FIRST_R3
}
