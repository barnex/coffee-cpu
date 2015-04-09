// package isa defines the instruction set
package isa

import (
//"fmt"
)

// Machine properties
const (
	CODEWORDS    = 1 << 12    // available number of instruction words
	MEMWORDS     = 1 << 12    // available number of data words
	NREG         = 16         // number of registers
	MAXREG       = NREG - 1   // highest register for RA, RC
	MAXREGB      = MAXREG - 2 // highest register for RB
	PCREG        = 14         // register holding program counter
	OVERFLOWREG  = 15         // register holding overflow of mul, div
	PERI_DISPLAY = 0x3FFF     // memory-mapped address of 7-segment display
)

// micro-instruction LSB positions:
//  31  30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13
//  ImmB  --RegA---   --RegB---   ------------ImmL-----------
//
//  12  11 10  9  8  7  6  5  4  3  2  1  0
//   ---ALU OPC----  --RegC----  -Cond--  cmp
const (
	ImmB = 31 // 0: put RB on BValue bus, 1: put bits [26:13] on BValue bus
	RegA = 27 // register A
	RegB = 23 // register B, or 4 MSB's of immediate value when ImmB=1
	ImmL = 13 // 10 LSB's of immediate value
	Opc  = 8  // Opcode selector for ALU/Memory
	RegC = 4  // register C
	Cond = 1  // Writeback condition
	Comp = 0  // 1: Update status register
)

// Values for Writeback condition (µI bits 3:1)
// Writeback condition determines whether the ALU result
// gets written back to register RC, based on status register
// holding the result of a previous comparison to zero.
const (
	ALWAYS  = 0 // write Cbus back to RC
	NEVER   = 1 // don't write back
	ZERO    = 2 // write back if last compare was zero
	NONZERO = 3 // write back if last compare was nonzero
	GREQ    = 4 // write back if last compare was >= 0
	LESS    = 5 // write back if last compare was < 0
)

// ALU Opcodes
const (
	LOAD  = 0x01 //  C <= mem[Ra+BBus]
	STORE = 0x02 //  mem[B] = Ra, C <= Ra-1
	AND   = 0x03 //  C <= Ra & B
	OR    = 0x04 //  C <= Ra | Rb
	XOR   = 0x05 //  C <= Ra ^ Rb
	ADD   = 0x06 //  C <= Ra + Rb
	ADDC  = 0x07 //  C <= Ra + Rb + carry_bit
	SUB   = 0x08 //  C <= Ra - Rb
	MUL   = 0x09 //  C <= (Ra*Rb)[31:0], Roverflow = (Ra*Rb)[63:32]
	DIV   = 0x0A //  C = Ra/Rb, Roverflow = Ra%Rb (unsigned)
	SDIV  = 0x0B //  C = Ra/Rb, Roverflow = Ra%Rb (signed)
)

// Human-readable strings for Conditions
var CondStr = map[uint32]string{
	ALWAYS:  "A",
	NEVER:   "N",
	ZERO:    "Z",
	NONZERO: "NZ",
	GREQ:    "GE",
	LESS:    "LT",
}

// Human-readable strings for Opcodes
var OpcodeStr = map[uint32]string{
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

// Parses opcodes
var Opcodes map[string]uint32

// Parses conditions
var Condcodes map[string]uint32

func init() {
	Opcodes = invert(OpcodeStr)
	Condcodes = invert(CondStr)
}

func invert(m map[uint32]string) map[string]uint32 {
	inv := make(map[string]uint32)
	for k, v := range m {
		inv[v] = k
	}
	return inv
}
