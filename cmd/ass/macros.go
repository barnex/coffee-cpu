package main

var defs = make(map[string]string)

func HandleMacro(words []string) {
	switch words[0] {
	default:
		Err("bad macro: ", words[0])
	case "#def":
		handleDef(words[1:])
	case "#undef":
		handleUndef(words[1:])
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

func transl(x string) string {
	if t, ok := defs[x]; ok {
		return t
	} else {
		return x
	}
}
