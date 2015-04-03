/*
coffee-cpu emulator. Usage:
 	emu somebinary.ihex
*/
package main

import (
	"bufio"
	"flag"
	"fmt"
	. "github.com/barnex/coffee-cpu/isa"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
)

var (
	flagTrace = flag.Bool("trace", true, "trace output")
)

var (
	pc   uint16           // program counter
	reg  [NREG]uint32     // registers
	mem  [MEMWORDS]uint32 // memory
	disp uint32           // data register for display peripheral
)

func Run() {
	for {
		instr := mem[pc]

		op := uint8((instr & 0xFF000000) >> 24)
		r1 := uint8((instr & 0x00FF0000) >> 16)
		r2 := uint8((instr & 0x0000FF00) >> 8)
		r3 := uint8((instr & 0x000000FF))
		addr := uint16(instr & 0x0000FFFF)

		if *flagTrace {
			switch {
			default:
				debug(pc, op, instr)
			case IsRegAddr(op):
				debug(pc, op, r1, addr)
			case IsReg2(op):
				debug(pc, op, r1, r2)
			case IsReg3(op):
				debug(pc, op, r1, r2, r3)
			}
		}

		pc++
		switch op {
		default:
			Fatal("SIGILL opcode=", op)
		case NOP: // nop
		case LOAD:
			reg[r1] = mem[addr]
		case STORE:
			if addr == PERI_DISPLAY {
				display(reg[r1])
			} else {
				mem[addr] = reg[r1]
			}
		case LOADLI:
			v := mem[addr]
			v = (v & 0xFFFF0000) | uint32(addr)
			mem[addr] = v
		case LOADHI:
			v := mem[addr]
			v = (v & 0x0000FFFF) | (uint32(addr) << 16)
			mem[addr] = v
		case JMPZ:
			if reg[r1] == 0 {
				pc--
				pc += addr
			}
		case MOV:
			reg[r2] = reg[r1]
		case AND:
			reg[r3] = reg[r1] & reg[r2]
		case OR:
			reg[r3] = reg[r1] | reg[r2]
		case XOR:
			reg[r3] = reg[r1] ^ reg[r2]
		case ADD:
			reg[r3] = reg[r1] + reg[r2]
		}
	}
}

func debug(pc uint16, op uint8, args ...interface{}) {
	fmt.Fprint(os.Stderr, pc, OpStr(op))
	fmt.Fprintln(os.Stderr, args...)
}

func display(v uint32) {
	disp = v
	fmt.Printf("PC%06d: %08X\n", pc-1, v)
}

func main() {
	log.SetFlags(0)
	flag.Parse()

	fname := flag.Arg(0)
	f, err := os.Open(fname)
	Check(err)
	defer f.Close()
	in := bufio.NewReader(f)

	pc := 0
	for v, ok := ParseLine(in); ok; v, ok = ParseLine(in) {
		mem[pc] = v
		pc++
	}

	Run()
}

// Parses a line of ihex.
// ok=false when EOF is reached.
func ParseLine(in *bufio.Reader) (instruction uint32, ok bool) {
	line, err := in.ReadString('\n')
	if err == io.EOF {
		return 0, false
	}
	Check(err)
	line = strings.Trim(line, ",\n\r")
	v, err := strconv.ParseInt(line, 0, 64)
	Check(err)
	return uint32(v), true
}

func Fatal(msg ...interface{}) {
	m := fmt.Sprint(msg...)
	log.Fatal(m, " pc=", pc-1)
}

func Check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
