package main

import (
	"bytes"
	"flag"
	"io/ioutil"
	"log"
	"os"
	"path"
)

var (
	filename   string
	linenumber int
)

func main() {
	log.SetFlags(0)
	flag.Parse()
	for _, fname := range flag.Args() {
		input, err := ioutil.ReadFile(fname)
		Check(err)
		filename = fname

		outfname := fname[:len(fname)-len(path.Ext(fname))] + ".hex"
		out, err := os.Create(outfname)
		Check(err)

		Preprocess(bytes.NewReader(input))
		linenumber = 0
		Assemble(bytes.NewReader(input), out)

		out.Close()
	}
}

func Check(err error) {
	if err != nil {
		panic(err)
	}
}
