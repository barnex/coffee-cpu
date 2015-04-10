package isa

import (
	"fmt"
	"strconv"
	"strings"
)

// Set bits x[a:b] to value.
func SetBits(x uint32, a, b uint32, v uint32) uint32 {
	if b <= a {
		panic("setbits: illegal range")
	}
	mask := (uint32(1) << uint32(b-a)) - 1
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
	if b <= a {
		panic("setbits: illegal range")
	}
	mask := (uint32(1) << uint32(b-a)) - 1
	x &= mask
	shift := uint32(a)
	x >>= shift
	return x
}

func BinStr(x uint32) string {
	return fmt.Sprintf("%032b", x)
}

func ParseWord(x string) (uint32, error) {
	base := 0
	if strings.HasPrefix(x, "0b") || strings.HasPrefix(x, "0B") {
		base = 2
		x = x[2:]
	}
	v, err := strconv.ParseInt(x, base, 64)
	return uint32(v), err
}
