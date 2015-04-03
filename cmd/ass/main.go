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

func main() {
	log.SetFlags(0)
	flag.Parse()
	for _, fname := range flag.Args() {
		f, err := os.Open(fname)
		filename = fname
		Check(err)
		Assemble(f)
		f.Close()
	}
}

var opcodes = map[string]uint32{
	"NOP":    NOP,
	"LOAD":   LOAD,
	"STORE":  STORE,
	"LOADLI": LOADLI,
	"LOADHI": LOADHI,
	"JMPZ":   JMPZ,
	"MOV":    MOV,
	"AND":    AND,
	"OR":     OR,
	"XOR":    XOR,
	"ADD":    ADD,
}

var (
	filename   string
	linenumber int
)

func Check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func Assemble(in io.Reader) {
	reader := bufio.NewReader(in)
	for words, ok := ParseLine(reader); ok; words, ok = ParseLine(reader) {
		if len(words) == 0 {
			continue
		}
		opc, ok := opcodes[words[0]]
		if !ok {
			Err("illegal instruction: " + words[0])
		}

		var bits uint32

		if IsRegAddr(opc) {
			CheckOps(words, 2)
			bits = opc<<24 | Reg(0, words)<<16 | uint32(Addr(words))
		}

		if IsReg3(opc) {
			CheckOps(words, 3)
			bits = opc<<24 | Reg(0, words)<<16 | Reg(1, words)<<8 | Reg(2, words)
		}

		fmt.Printf("0x%08X,\n", bits)
	}
}

func Reg(i int, words []string) uint32 {
	words = words[1:]
	r := words[i]
	if !strings.HasPrefix(r, "R") {
		Err("expected register, got: ", r)
	}
	r = r[1:]
	rN, err := strconv.Atoi(r)
	if err != nil {
		Err("malformed register name: R", r)
	}
	if rN > MAXREG || rN < 0 {
		Err("no such register: R", r)
	}
	return uint32(rN)
}

func Addr(words []string) uint16 {
	a := words[2]
	addr, err := strconv.ParseInt(a, 0, 32)
	if err != nil {
		Err("malformed number:", a, err)
	}
	if addr > MAXINT {
		Err("too big:", a)
	}
	return uint16(addr)
}

func CheckOps(words []string, nOps int) {
	if len(words) != nOps+1 {
		Err("need ", nOps, " operands")
	}
}

func Err(msg ...interface{}) {
	str := fmt.Sprint(msg...)
	log.Fatal(filename, ": ", linenumber, ": ", str)
}

func ParseLine(in *bufio.Reader) ([]string, bool) {
	linenumber++
	line, err := in.ReadString('\n')
	if err == io.EOF {
		return nil, false
	}
	if err != nil {
		log.Fatal(err)
	}
	line = strings.Replace(line, "\t", " ", -1)
	words := strings.Split(line, " ")
	tokens := make([]string, 0, 3)
	for _, w := range words {
		if strings.HasPrefix(w, COMMENT) {
			break
		}
		w = strings.Trim(w, "\n")
		if w != "" {
			tokens = append(tokens, w)
		}
	}
	return tokens, true
}

const COMMENT = "//"

func assemble(words []string) {
	fmt.Println(len(words))
}
