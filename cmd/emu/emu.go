/*
coffee-cpu emulator. Usage:
 	emu somebinary.ihex
*/
package main

import (
	"../../ihex"
	. "../../isa"
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
)

var (
	flagTrace = flag.Bool("trace", false, "trace execution")
)

// Machine state
var (
	pc        uint16           // program counter
	reg       [NREG]uint32     // registers
	mem       [MEMWORDS]uint32 // memory
	datastart uint16           // memory address of first writable data word (end of instructions)
	disp      uint32           // data register for display peripheral
)

func Run() {
	for {
		// fetch
		instr := fetch(pc)

		// decode
		op := uint8((instr & 0xFF000000) >> 24)
		r1 := uint8((instr & 0x00FF0000) >> 16)
		r2 := uint8((instr & 0x0000FF00) >> 8)
		r3 := uint8((instr & 0x000000FF))
		addr := uint16(instr & 0x0000FFFF)

		// debug
		if *flagTrace {
			switch {
			default:
				debug(pc, op, instr)
			case IsRegAddr(op):
				PrintRA(pc, op, r1, addr)
			case IsReg2(op):
				PrintR2(pc, op, r1, r2)
			case IsReg3(op):
				PrintR3(pc, op, r1, r2, r3)
			}
		}

		// execute
		switch op {
		default:
			Fatalf("SIGILL pc:%08X opcode:%d\n", pc, op)
		case NOP: // nop
		case LOAD:
			reg[r1] = load(addr)
		case STORE:
			if addr == PERI_DISPLAY {
				display(reg[r1])
			} else {
				store(reg[r1], addr)
			}
		case LOADLI:
			v := reg[r1]
			v = (v & 0xFFFF0000) | uint32(addr)
			reg[r1] = v
		case LOADHI:
			v := reg[r1]
			v = (v & 0x0000FFFF) | (uint32(addr) << 16)
			reg[r1] = v
		case JUMPZ:
			if reg[r1] == 0 {
				pc += addr - 1
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

		pc++
	}
}

// load word form data region, prevent access to instructions
func load(addr uint16) uint32 {
	if addr < datastart {
		Fatalf("SIGSEGV: pc%08X: load %08X (<%08X)", pc, addr, datastart)
	}
	return mem[addr]
}

// store word to data region, prevent access to instructions
func store(v uint32, addr uint16) {
	if addr < datastart {
		Fatalf("SIGSEGV: pc%08X: store %08X (<%08X)", pc, addr, datastart)
	}
	mem[addr] = v
}

// load instruction, prevent executing data region
func fetch(addr uint16) uint32 {
	if addr >= datastart {
		Fatalf("SIGSEGV: pc%08X: fetch %08X (>=%08X)", pc, addr, datastart)
	}
	return mem[addr]
}

func debug(pc uint16, op uint8, args ...interface{}) {
	fmt.Fprintf(os.Stdout, "(%08X):% 8s ", pc, OpStr(op))
	for _, a := range args {
		switch a := a.(type) {
		default:
			fmt.Fprint(os.Stdout, " ", a)
		case uint8:
			fmt.Fprint(os.Stdout, " R", a)
		case uint16:
			fmt.Fprintf(os.Stdout, " %08X", a)
		}
	}
	fmt.Fprintln(os.Stdout)
}

func Fatalf(f string, msg ...interface{}) {
	fmt.Printf(f, msg...)
	os.Exit(2)
}

func PrintRA(pc uint16, op uint8, r1 uint8, a uint16) {
	fmt.Printf("(%08X:%08X):% 8s R%d(=%08X) %08X\n", pc, mem[pc], OpStr(op), r1, reg[r1], a)
}

func PrintR2(pc uint16, op uint8, r1, r2 uint8) {
	fmt.Printf("(%08X:%08X):% 8s R%d(=%08X) R%d\n", pc, mem[pc], OpStr(op), r1, reg[r1], r2)
}

func PrintR3(pc uint16, op uint8, r1, r2, r3 uint8) {
	fmt.Printf("(%08X:%08X):% 8s R%d(=%08X) R%d(=%08X) R%d\n", pc, mem[pc], OpStr(op), r1, reg[r1], r2, reg[r2], r3)
}

func display(v uint32) {
	disp = v
	fmt.Printf("%08X\n", v)
}

func main() {
	log.SetFlags(0)
	flag.Parse()

	fname := flag.Arg(0)
	f, err := os.Open(fname)
	Check(err)
	defer f.Close()
	in := bufio.NewReader(f)

	for addr, v, ok := ParseLine(in); ok; addr, v, ok = ParseLine(in) {
		mem[addr] = v
		if addr >= datastart {
			datastart = addr + 1
		}
	}

	Run()
}

// Parses a line of ihex.
// ok=false when EOF is reached.
func ParseLine(in *bufio.Reader) (addr uint16, instruction uint32, ok bool) {
	addr, instr, err := ihex.ReadUint32(in)
	if err == io.EOF {
		return 0, 0, false
	}
	Check(err)
	return addr, instr, true
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
