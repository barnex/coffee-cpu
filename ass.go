package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"
)

func main() {
	flag.Parse()
	for _, fname := range flag.Args() {
		f, err := os.Open(fname)
		Check(err)
		Assemble(f)
		f.Close()
	}
}

func Check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func Assemble(in io.Reader) {
	reader := bufio.NewReader(in)
	for words, ok := ParseLine(reader); ok; words, ok = ParseLine(reader) {
		fmt.Println(words)
	}
}

func ParseLine(in *bufio.Reader) ([]string, bool) {
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
