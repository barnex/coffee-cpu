package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
)

const (
	MEMBITS      = 1 << 13
	MEMBYTES     = MEMBITS * 8
	WORDBYTES    = 4
	MEMWORDS     = MEMBYTES / WORDBYTES
	NREG         = 256
	PERI_DISPLAY = 0xFFFF
)

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

var (
	pc   uint16
	reg  [NREG]uint32
	mem  [MEMWORDS]uint32
	disp uint32
)

func Run() {
	for {
		instr := mem[pc]

		op := (instr & 0xFF000000) >> 24
		r1 := (instr & 0x00FF0000) >> 16
		r2 := (instr & 0x0000FF00) >> 8
		r3 := (instr & 0x000000FF)
		addr := uint16(instr & 0x0000FFFF)

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

func display(v uint32) {
	disp = v
	fmt.Printf("PC%06d: %08X\n", pc-1, v)
}

func Fatal(msg ...interface{}) {
	m := fmt.Sprint(msg...)
	log.Fatal(m, " pc=", pc-1)
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

	//for i := 0; i < pc; i++ {
	//	fmt.Printf("%08X\n", mem[i])
	//}

	Run()
}

func Check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func ParseLine(in *bufio.Reader) (uint32, bool) {
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
