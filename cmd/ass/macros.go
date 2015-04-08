package main

import (
	"bufio"
	"fmt"
	"io"
	"strings"
)

var defs = make(map[string]string)

func Preprocess(in io.Reader) {
	reader := bufio.NewReader(in)
	var pc uint16 = 0
	for words, ok := ParseLine(reader); ok; words, ok = ParseLine(reader) {
		if len(words) == 0 {
			continue
		}

		if strings.HasPrefix(words[0], "#") {
			HandleMacro(words, pc)
			continue
		}
		pc++
	}
}

func HandleMacro(words []string, pc uint16) {
	switch words[0] {
	default:
		Err("bad macro: ", words[0])
	case "#def":
		handleDef(words[1:])
	case "#undef":
		handleUndef(words[1:])
	case "#label":
		handleLabel(words[1:], pc)
	}
}

func handleDef(args []string) {
	if len(args) != 2 {
		Err("#def needs 2 arguments, have: ", args)
	}
	k, v := args[0], args[1]
	if _, ok := defs[k]; ok {
		Err("already defined:", k)
	}
	defs[k] = v
}

func handleUndef(args []string) {
	for _, k := range args {
		if _, ok := defs[k]; !ok {
			Err("not defined:", k)
		}
		delete(defs, k)
	}
}

func handleLabel(args []string, pc uint16) {
	if len(args) != 1 {
		Err("#label needs 1 argument, have: ", args)
	}
	handleDef([]string{args[0], fmt.Sprint(pc)})
}

func transl(x string) string {
	if t, ok := defs[x]; ok {
		return t
	} else {
		return x
	}
}
