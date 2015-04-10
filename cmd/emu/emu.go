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
	reg   [NREG]uint32        // registers
	instr [INSTR_WORDS]uint32 // memory
	mem   [MEM_WORDS]uint32   // memory
	carry bool                // carry flag
	disp  uint32              // data register for display peripheral
)

func Run() {
	for {

		instr := fetch(reg[PCREG])

		reg[PCREG]++

		ib := GetBits(instr, IB, IB)
		ra := GetBits(instr, RAl, RAh)
		rb := GetBits(instr, RBl, RBh)
		iv := GetBits(instr, ILl, RBh)
		op := GetBits(instr, OPl, OPh)
		rc := GetBits(instr, RCl, RCh)
		wb := GetBits(instr, WCl, WCh)
		c_ := GetBits(instr, CMP, CMP)

		// debug
		if *flagTrace {
			B := fmt.Sprintf("R%v", rb)
			if ib != 0 {
				B = fmt.Sprint(iv)
			}
			B = fmt.Sprintf("% 5s", B)
			fmt.Printf("%032b:% 5s R%v %s %v R%v %v\n", instr, OpcodeStr[op], ra, B, CondStr[wb], rc, c_)
		}

		//// execute
		//switch op {
		//default:
		//	Fatalf("SIGILL pc:%08X opcode:%d\n", pc, op)
		////case NOP: // nop
		//case LOAD:
		//	reg[r3] = mem[reg[r1]+reg[r2]]
		//case STORE:
		//	mem[reg[r1]+reg[r2]] = reg[r3]
		//case LOADI:
		//	reg[r1] = load(addr)
		//case STORI:
		//	if addr == PERI_DISPLAY {
		//		display(reg[r1])
		//	} else {
		//		store(reg[r1], addr)
		//	}
		//case LOADLI:
		//	v := reg[r1]
		//	v = (v & 0xFFFF0000) | uint32(addr)
		//	reg[r1] = v
		//case LOADHI:
		//	v := reg[r1]
		//	v = (v & 0x0000FFFF) | (uint32(addr) << 16)
		//	reg[r1] = v
		//case LOADLISE:
		//	var sign uint32
		//	if (addr & 0x8000) != 0 {
		//		sign = 0xFFFF0000
		//	}
		//	reg[r1] = sign | uint32(addr)
		//case JUMPZ:
		//	if reg[r1] == 0 {
		//		pc = addr - 1
		//	}
		//case JUMPNZ:
		//	if reg[r1] != 0 {
		//		pc = addr - 1
		//	}
		//case JUMPLT:
		//	if int32(reg[r1]) < 0 {
		//		pc = addr - 1
		//	}
		//case JUMPGTE:
		//	if int32(reg[r1]) >= 0 {
		//		pc = addr - 1
		//	}
		//case MOV: // deprecated
		//	reg[r2] = reg[r1]
		//case AND:
		//	reg[r3] = reg[r1] & reg[r2]
		//case OR:
		//	reg[r3] = reg[r1] | reg[r2]
		//case XOR:
		//	reg[r3] = reg[r1] ^ reg[r2]
		//case ADD:
		//	sum := uint64(reg[r1]) + uint64(reg[r2])
		//	carry = (sum > 0xFFFFFFFF)
		//	reg[r3] = uint32(sum)
		//case ADDC:
		//	var C uint64
		//	if carry {
		//		C = 1
		//	}
		//	sum := uint64(reg[r1]) + uint64(reg[r2]) + C
		//	carry = (sum > 0xFFFFFFFF)
		//	reg[r3] = uint32(sum)
		//case SUB:
		//	reg[r3] = reg[r1] - reg[r2]
		//case MUL:
		//	prod := uint64(reg[r1]) * uint64(reg[r2])
		//	reg[r3] = uint32(prod & 0x00000000FFFFFFFF)
		//	reg[(r3+1)%MAXREG] = uint32((prod & 0xFFFFFFFF00000000) >> 32)
		//case DIV:
		//	reg[r3] = reg[r1] / reg[r2]
		//	reg[(r3+1)%MAXREG] = reg[r1] % reg[r2]
		//case SDIV:
		//	reg[r3] = uint32(int32(reg[r1]) / int32(reg[r2]))
		//	reg[(r3+1)%MAXREG] = uint32(int32(reg[r1]) % int32(reg[r2]))
		//case HALT:
		//	os.Exit(0)
		//}

		//pc++
		//if pc == MEMWORDS {
		//	Fatalf("SIGSEGV: pc = %08X", pc)
		//}
	}
}

// load word form data region, prevent access to instructions
func load(addr uint16) uint32 {
	//if addr < datastart {
	//	Fatalf("SIGSEGV: attempt to load code as data: pc%08X: load %08X (<%08X)", pc, addr, datastart)
	//}
	return mem[addr]
}

// store word to data region, prevent access to instructions
func store(v uint32, addr uint16) {
	//if addr < datastart {
	//	Fatalf("SIGSEGV: attempt to overwrite code: pc%08X: store %08X (<%08X)", pc, addr, datastart)
	//}
	mem[addr] = v
}

// load instruction, prevent executing data region
func fetch(addr uint32) uint32 {
	//if addr >= datastart {
	//	Fatalf("SIGSEGV: control enters data region: pc%08X: fetch %08X (>=%08X)", pc, addr, datastart)
	//}
	return mem[addr]
}

//func debug(pc uint16, op uint8, args ...interface{}) {
//	fmt.Fprintf(os.Stdout, "(%08X):% 8s ", pc, OpStr(op))
//	for _, a := range args {
//		switch a := a.(type) {
//		default:
//			fmt.Fprint(os.Stdout, " ", a)
//		case uint8:
//			fmt.Fprint(os.Stdout, " R", a)
//		case uint16:
//			fmt.Fprintf(os.Stdout, " %08X", a)
//		}
//	}
//	fmt.Fprintln(os.Stdout)
//}

func Fatalf(f string, msg ...interface{}) {
	panic(fmt.Sprintf(f, msg...))
	//os.Exit(2)
}

//func PrintRA(pc uint16, op uint8, r1 uint8, a uint16) {
//	fmt.Printf("(%08X:%08X):% 8s R%d(=%08X) %08X\n", pc, mem[pc], OpStr(op), r1, reg[r1], a)
//}
//
//func PrintR2(pc uint16, op uint8, r1, r2 uint8) {
//	fmt.Printf("(%08X:%08X):% 8s R%d(=%08X) R%d\n", pc, mem[pc], OpStr(op), r1, reg[r1], r2)
//}
//
//func PrintR3(pc uint16, op uint8, r1, r2, r3 uint8) {
//	fmt.Printf("(%08X:%08X):% 8s R%d(=%08X) R%d(=%08X) R%d\n", pc, mem[pc], OpStr(op), r1, reg[r1], r2, reg[r2], r3)
//}

func display(v uint32) {
	disp = v
	fmt.Printf("%08X (=%v unsigned, %v signed)\n", v, v, int32(v))
}

func main() {
	log.SetFlags(0)
	flag.Parse()

	fname := flag.Arg(0)
	f, err := os.Open(fname)
	Check(err)
	defer f.Close()
	in := bufio.NewReader(f)

	//fmt.Println("memory: ", MEMWORDS, " words")

	for addr, v, ok := ParseLine(in); ok; addr, v, ok = ParseLine(in) {
		mem[addr] = v
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
	log.Fatal(m)
}

func Check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
