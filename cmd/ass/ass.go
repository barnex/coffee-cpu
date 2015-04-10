package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"strconv"
	"strings"

	"../../ihex"
	"../../isa"
)

const COMMENT = "//"

func Assemble(in io.Reader, out io.Writer) {
	reader := bufio.NewReader(in)
	var pc uint16
	for words, ok := ParseLine(reader); ok; words, ok = ParseLine(reader) {
		if len(words) == 0 {
			continue
		}

		if strings.HasPrefix(words[0], "#") {
			continue
		}

		if pc%4 == 0 {
			fmt.Println("\niaaaabbbbiiiiiiiiiioooooccccwww+")
		}
		var bits uint32

		if words[0] == "DATA" {
			v := ParseInt(words[1], 32)
			bits = uint32(v)
		} else {
			if len(words) != 6 {
				Err("need 5 operands")
			}
			opc := ParseOpcode(words[0])
			ra := ParseReg(transl(words[1]))
			immb, rb, imml := ParseBVal(transl(words[2]))
			cond := ParseCond(words[3])
			rc := ParseReg(transl(words[4]))
			comp := ParseCmp(words[5])

			bits = isa.SetBits(bits, isa.IB, isa.IB, immb)
			bits = isa.SetBits(bits, isa.RAl, isa.RAh, ra)
			bits = isa.SetBits(bits, isa.RBl, isa.RBh, rb)
			bits = isa.SetBits(bits, isa.ILl, isa.ILh, imml)
			bits = isa.SetBits(bits, isa.OPl, isa.OPh, opc)
			bits = isa.SetBits(bits, isa.RCl, isa.RCh, rc)
			bits = isa.SetBits(bits, isa.WCl, isa.WCh, cond)
			bits = isa.SetBits(bits, isa.CMP, isa.CMP, comp)

		}
		fmt.Printf("%032b\n", bits)
		ihex.WriteUint32(out, pc, bits)
		pc++
	}
	ihex.WriteEOF(out)
}

func ParseOpcode(x string) uint32 {
	if op, ok := isa.Opcodes[x]; ok {
		return op
	} else {
		Err("illegal instruction: ", x)
		panic("")
	}
}

func ParseCond(x string) uint32 {
	if c, ok := isa.Condcodes[x]; ok {
		return c
	} else {
		Err("illegal condition: ", x)
		panic("")
	}
}

func ParseReg(x string) uint32 {
	if x == "PC" {
		return isa.PCREG
	}
	if x == "Rx" {
		return isa.OVERFLOWREG
	}

	r := transl(x)
	if !strings.HasPrefix(r, "R") {
		Err("expected register, got: ", r)
	}
	r = r[1:]
	rN, err := strconv.Atoi(r)
	if err != nil {
		Err("malformed register name: R", r)
	}
	if rN == isa.PCREG {
		Err("the program counter is explictly called PC")
	}
	if rN == isa.OVERFLOWREG {
		Err("the overflow register is explictly called Rx")
	}
	if rN > isa.MAXREG || rN < 0 {
		Err("no such register: R", r)
	}
	return uint32(rN)
}

func ParseBVal(x string) (immb, regb, immv uint32) {
	if strings.HasPrefix(x, "R") {
		return 0, ParseReg(x), 0
	} else {
		immv := ParseInt(x, 14)
		regb := (immv & 0xFC00) >> 10
		imml := (immv & 0x03FF)
		assert(regb < isa.NREG)
		return 1, regb, imml
	}
}

func ParseCmp(x string) uint32 {
	switch x {
	default:
		Err("illegal condition: ", x, " (need +cmp or -cmp)")
		panic("")
	case "+cmp":
		return 1
	case "-cmp":
		return 0
	}
}

func ParseInt(x string, bits uint8) uint32 {
	v, err := isa.ParseInt(x, bits)
	if err != nil {
		Err(err)
	}
	return v
}

//func Addr(words []string) uint16 {
//	a := transl(words[2])
//	addr, err := strconv.ParseInt(a, 0, 32)
//	if err != nil {
//		Err("malformed number:", a, err)
//	}
//	if addr > MAXINT {
//		Err("too big:", a)
//	}
//	return uint16(addr)
//}

func Err(msg ...interface{}) {
	str := fmt.Sprint(msg...)
	log.Fatal(filename, ": ", linenumber, ": ", str)
}

func assert(test bool) {
	if !test {
		panic("assertion failed")
	}
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
