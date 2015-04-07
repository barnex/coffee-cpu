package main

import (
	"flag"
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

func Check(err error) {
	if err != nil {
		panic(err)
	}
}
