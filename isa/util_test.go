package isa

import (
	"fmt"
)

func ExampleSetBits() {
	var x uint32
	x = SetBits(x, 3, 5, 0x7)
	fmt.Println(BinStr(x))
	x = SetBits(x, 16, 31, 0xFFFF)
	fmt.Println(BinStr(x))
	x = SetBits(x, 31, 31, 0)
	fmt.Println(BinStr(x))

	//Output:
	// 00000000000000000000000000111000
	// 11111111111111110000000000111000
	// 01111111111111110000000000111000
}

func ExampleGetBits() {
	var x uint32
	x, _ = ParseInt("0b000000000000000000000100110000", 32)
	fmt.Printf("%b", GetBits(x, 4, 7))

	//Output:
	// 11
}
