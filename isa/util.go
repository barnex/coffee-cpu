package isa

import (
	"fmt"
	"strconv"
	"strings"
)

// Set bits x[a:b] (both inclusive) to value.
func SetBits(x uint32, a, b uint32, v uint32) uint32 {
	if b < a || b >= 32 {
		panic("setbits: illegal range")
	}
	mask := (uint32(1) << uint32(b-a+1)) - 1
	if v&(^mask) != 0 {
		panic("setbits: value too large")
	}
	shift := uint32(a)
	mask <<= shift
	x &= ^mask
	v <<= shift
	x |= v
	return x
}

func GetBits(x uint32, a, b int) uint32 {
	if b < a || b >= 32 {
		panic("setbits: illegal range")
	}
	mask := (uint32(1) << uint32(b-a+1)) - 1
	x &= mask
	shift := uint32(a)
	x >>= shift
	return x
}

func BinStr(x uint32) string {
	return fmt.Sprintf("%032b", x)
}

//func ParseInt(x string, bits int) (uint32, error) {
//	base := 0
//	if strings.HasPrefix(x, "0b") || strings.HasPrefix(x, "0B") {
//		base = 2
//		x = x[2:]
//	}
//	v, err := strconv.ParseInt(x, base, 64)
//	if err != nil{
//		return 0, err
//	}
//	bits := uint32(v)
//	if bits > ...
//	return uint32(v), err
//}
