package main

import (
	"../../ihex"
	. "../../isa"
	"bufio"
	"fmt"
	"io"
	"log"
	"strconv"
	"strings"
)

const COMMENT = "//"

var output []Instr

type Instr interface {
	Encode() uint32
}

type Data uint32

func (d Data) Encode() uint32 { return uint32(d) }

type R3 struct {
	opc        uint8
	r1, r2, r3 uint8
}

func (i R3) Encode() uint32 {
	return uint32(i.opc)<<24 |
		uint32(i.r1)<<16 |
		uint32(i.r2)<<8 |
		uint32(i.r3)
}

type RA struct {
	opc   uint8
	r     uint8
	addr  uint16
	label string
}

func (i RA) Encode() uint32 {
	return uint32(i.opc)<<24 |
		uint32(i.r)<<16 |
		uint32(i.addr)
}

func Assemble(in io.Reader, out io.Writer) {
	reader := bufio.NewReader(in)
	var pc uint16
	for words, ok := ParseLine(reader); ok; words, ok = ParseLine(reader) {
		if len(words) == 0 {
			continue
		}

		if strings.HasPrefix(words[0], "#") {
			HandleMacro(words)
			continue
		}

		opc, ok := Opcodes[words[0]]
		if !ok {
			Err("illegal instruction: " + words[0])
		}

		var bits uint32

		switch {
		default:
			panic(words[0])
		case opc == NOP:
			if len(words) > 1 {
				Err("unexpected arguments")
			}
		case IsRegAddr(opc):
			CheckOps(words, 2)
			bits = uint32(opc)<<24 | Reg(0, words)<<16 | uint32(Addr(words))
		case IsReg3(opc):
			CheckOps(words, 3)
			bits = uint32(opc)<<24 | Reg(0, words)<<16 | Reg(1, words)<<8 | Reg(2, words)
		}

		ihex.WriteUint32(out, pc, bits)
		pc++
		//fmt.Fprintf(out, "0x%08X,\n", bits)
	}
	ihex.WriteEOF(out)
}

func Reg(i int, words []string) uint32 {
	words = words[1:]
	r := transl(words[i])
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
	a := transl(words[2])
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

func assemble(words []string) {
	fmt.Println(len(words))
}
