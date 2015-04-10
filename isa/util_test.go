package isa

import (
	"fmt"
)

func ExampleSetBits() {
	var x uint32
	x = SetBits(x, 3, 5, 0x3)
	fmt.Println(BinStr(x))
	x = SetBits(x, 16, 32, 0xFFFF)
	fmt.Println(BinStr(x))

	//Output:
	// 00000000000000000000000000011000
	// 11111111111111110000000000011000
}

func ExampleGetBits() {
	var x uint32
	x = 0xFF1234F
	fmt.Printf("%x", GetBits(x, 4, 21))

	//Output:
	// 1234
}
