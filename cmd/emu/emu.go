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
	reg    [NREG]uint32        // registers
	instr  [INSTR_WORDS]uint32 // memory
	mem    [MEM_WORDS]uint32   // memory
	carry  bool                // carry flag
	status [8]bool
	disp   uint32 // data register for display peripheral
)

func init() {
	status[NEVER] = false
	status[ALWAYS] = true
}

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

		A := reg[ra]

		var B uint32
		if ib == 0 {
			B = reg[rb]
		} else {
			B = iv
		}

		var C uint32
		switch op {
		default:
			Fatalf("SIGILL pc:%08X opcode:%d\n", op)
		case LOAD:
			C = load(A + B)
		case STORE:
			store(B, A)
			C = A - 1
		case AND:
			C = A & B
		case OR:
			C = A | B
		case XOR:
			C = A ^ B
		case ADD:
			sum := uint64(A) + uint64(B)
			carry = (sum > 0xFFFFFFFF)
			C = uint32(sum)
		case ADDC:
			var c uint64
			if carry {
				c = 1
			}
			sum := uint64(A) + uint64(B) + c
			carry = (sum > 0xFFFFFFFF)
			C = uint32(sum)
		case SUB:
			C = A - B
		case MUL:
			prod := uint64(A) * uint64(B)
			C = uint32(prod & 0x00000000FFFFFFFF)
			reg[OVERFLOWREG] = uint32((prod & 0xFFFFFFFF00000000) >> 32)
		case DIV:
			C = A / B
			reg[OVERFLOWREG] = A % B
		case SDIV:
			C = uint32(int32(A) / int32(B))
			reg[OVERFLOWREG] = uint32(int32(A) % int32(B))
		}

		// TODO: check max rc
		if status[wb] {
			reg[rc] = C
		}

		// compare?
		if c_ != 0 {
			status[LT] = (C < 0)
			status[GE] = (C >= 0)
			status[ZERO] = (C == 0)
			status[NZ] = (C != 0)
		}
	}
}

// load word form data region, prevent access to instructions
func load(addr uint32) uint32 {
	//if addr < datastart {
	//	Fatalf("SIGSEGV: attempt to load code as data: pc%08X: load %08X (<%08X)", pc, addr, datastart)
	//}
	return mem[addr]
}

// store word to data region, prevent access to instructions
func store(addr uint32, v uint32) {
	//if addr < datastart {
	//	Fatalf("SIGSEGV: attempt to overwrite code: pc%08X: store %08X (<%08X)", pc, addr, datastart)
	//}
	if addr == PERI_DISPLAY {
		fmt.Println(v)
	} else {
		mem[addr] = v
	}
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
