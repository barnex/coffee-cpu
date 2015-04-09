package isa

// set bits x[a:b] to value. E.g.:
// 	SetBits(0b00000000, 1, 4, 0b00000111) // returns 0b00001110
func SetBits(x uint32, a, b int, v uint32) {
	if a < 0 || b < 0 || b <= a {
		panic("setbits: illegal range")
	}
	mask := (1 << uint32(b-a)) - 1
	if v & (~mask)  != 0{
		panic("setbits: value too large")
	}
}

func GetBits(x uint32, a, b int) uint32 {

}
