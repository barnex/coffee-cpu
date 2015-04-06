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
	"path"
	"strconv"
	"strings"
)

var (
	filename   string
	linenumber int
)

func main() {
	log.SetFlags(0)
	flag.Parse()
	for _, fname := range flag.Args() {
		f, err := os.Open(fname)
		Check(err)
		filename = fname

		outfname := fname[:len(fname)-len(path.Ext(fname))] + ".ihex"
		out, err := os.Create(outfname)
		Check(err)

		Assemble(f, out)

		f.Close()
		out.Close()
	}
}

const COMMENT = "//"

func Assemble(in io.Reader, out io.Writer) {
	reader := bufio.NewReader(in)
	var pc uint16
	for words, ok := ParseLine(reader); ok; words, ok = ParseLine(reader) {
		if len(words) == 0 {
			continue
		}
		opc, ok := Opcodes[words[0]]
		if !ok {
			Err("illegal instruction: " + words[0])
		}

		var bits uint32

		if IsRegAddr(opc) {
			CheckOps(words, 2)
			bits = uint32(opc)<<24 | Reg(0, words)<<16 | uint32(Addr(words))
		}

		if IsReg3(opc) {
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

func assemble(words []string) {
	fmt.Println(len(words))
}

func Check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
