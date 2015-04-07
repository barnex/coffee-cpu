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
	NOP      = 0x00 // NOP                : no-op
	LOAD     = 0x01 // LOAD     Ra Rb Rc  : Rc = mem[Ra+Rb]
	STORE    = 0x02 // STORE    Ra Rb Rc  : mem[Ra+Rb] = Rc
	LOADI    = 0x03 // LOADI    Ra addr   : Ra = mem[addr]
	STORI    = 0x04 // STORE    Ra addr   : mem[addr] = Ra
	LOADLI   = 0x05 // LOADLI   Ra VALUE  : load VALUE (16 bit) into the lower half of register RA
	LOADHI   = 0x06 // LOADHI   Rb VALUE  : load VALUE (16 bit) into the upper half of register RA
	LOADLISE = 0x07 // LOADLISE Rb VALUE  : load VALUE into the lower half of Ra, sign extend to upper half
	JUMPZ    = 0x08 // JMPZ     Ra DELTA  : if RA holds zero, make a relative jump of DELTA instructions
	JUMPNZ   = 0x09 // JMPNZ    Ra DELTA  : jump if Ra holds nonzero
	JUMPLT   = 0x0A // JMPLT    Ra DELTA  : jump if Ra holds negative number
	JUMPGTE  = 0x0B // JMPGTE   Ra DELTA  : jump if Ra holds number >= 0
	MOV      = 0x0C // MOV      Ra Rb     : copy RA into RB  // deprecate?
	AND      = 0x0D // AND      Ra Rb Rc  : bitwise and: Rc = Ra & Rb
	OR       = 0x0E // OR       Ra Rb Rc  : bitwise or : Rc = Ra | Rb
	XOR      = 0x0F // XOR      Ra Rb Rc  : bitwise xor: Rc = Ra ^ Rb
	ADD      = 0x10 // ADD      Ra Rb Rc  : integer add: Rc = Ra + Rb
	ADDC     = 0x11 // ADD      Ra Rb Rc  : add with carry
	SUB      = 0x12 // SUB      Ra Rb Rc  : Rc = Ra - Rb
	MUL      = 0x13 // MUL      Ra Rb Rc  : Rc = (Ra*Rb)[31:0], R(c+1) = (Ra*Rb)[63:32]
	DIV      = 0x14 // DIV      Ra Rb Rc  : unsigned division Rc = Ra/Rb, R(c+1) = Ra%Rb
	SDIV     = 0x15 // SDIV     Ra Rb Rc  : signed division Rc = Ra/Rb, R(c+1) = Ra%Rb
)

// Does this opcode take a register + address operand?
func IsRegAddr(opc uint8) bool {
	return opc >= LOADI && opc <= JUMPGTE
}

// Does this opcode take a 2 register operands?
func IsReg2(opc uint8) bool {
	return opc == MOV
}

// Does this opcode take a 3 register operands?
func IsReg3(opc uint8) bool {
	return opc == LOAD || opc == STORE || opc >= AND
}

// Machine properties
const (
	MEMBITS      = 1 << 13
	MEMBYTES     = MEMBITS / 8
	WORDBYTES    = 4
	MEMWORDS     = MEMBYTES / WORDBYTES
	NREG         = 256
	PERI_DISPLAY = 0xFFFF
)

var OpcodeStr = map[uint8]string{
	NOP:      "NOP",
	LOAD:     "LOAD",
	STORE:    "STORE",
	LOADI:    "LOADI",
	STORI:    "STORI",
	LOADLI:   "LOADLI",
	LOADHI:   "LOADHI",
	LOADLISE: "LOADLISE",
	JUMPZ:    "JUMPZ",
	JUMPNZ:   "JUMPNZ",
	JUMPLT:   "JUMPLT",
	JUMPGTE:  "JUMPGTE",
	MOV:      "MOV",
	AND:      "AND",
	OR:       "OR",
	XOR:      "XOR",
	ADD:      "ADD",
	ADDC:     "ADDC",
	SUB:      "SUB",
	MUL:      "MUL",
	DIV:      "DIV",
	SDIV:     "SDIV",
}

var Opcodes map[string]uint8

func init() {
	Opcodes = make(map[string]uint8)
	for k, v := range OpcodeStr {
		Opcodes[v] = k
	}
}

func OpStr(opc uint8) string {
	if s, ok := OpcodeStr[opc]; ok {
		return s
	} else {
		return fmt.Sprintf("ILLEGAL:%2X", opc)
	}
}
