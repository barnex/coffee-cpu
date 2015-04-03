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
	MEMBYTES  = 64 * 1024
	WORDBYTES = 4
	MEMWORDS  = MEMBYTES / WORDBYTES
)

var mem [MEMWORDS]uint32

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

	for i := 0; i < pc; i++ {
		fmt.Printf("%08X\n", mem[i])
	}
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
	line = strings.Trim(line, ",")
	line = strings.Trim(line, "\n")
	line = strings.Trim(line, "\r")
	v, err := strconv.Atoi(line)
	Check(err)
	return uint32(v), true
}
