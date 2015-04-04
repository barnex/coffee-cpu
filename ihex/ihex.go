/*
 Package ihex supports reading/writing Intel's HEX format as specified by:
 	http://en.wikipedia.org/wiki/Intel_HEX
*/
package ihex

import (
	"fmt"
	"io"
)

func WriteUint32(out io.Writer, addr uint16, x uint32) {

	var c uint8
	c += uint8((addr & 0xFF00) >> 8)
	c += uint8((addr & 0x00FF) >> 0)
	c += uint8((x & 0xFF000000) >> 24)
	c += uint8((x & 0x00FF0000) >> 16)
	c += uint8((x & 0x0000FF00) >> 8)
	c += uint8((x & 0x000000FF) >> 0)
	c = -c

	fmt.Fprintf(out, ":04%04X00%08X%02X\n", addr, x, c)
}

func ReadUint32(in io.Reader) (addr uint16, x uint32, err error) {
	var prefix string
	_, err = fmt.Fscanf(in, "%3s", &prefix)
	if err != nil {
		return
	}
	if prefix != ":04" {
		return 0, 0, fmt.Errorf("malformed ihex record, starts with %v", prefix)
	}
	_, err = fmt.Fscanf(in, "%04X", &addr)
	if err != nil {
		return
	}
	_, err = fmt.Fscanf(in, "%2s", &prefix)
	if err != nil {
		return
	}
	if prefix != "00" {
		return 0, 0, fmt.Errorf("bad data type in ihex record: %v", prefix)
	}
	_, err = fmt.Fscanf(in, "%08X", &x)
	if err != nil {
		return
	}
	_, err = fmt.Fscanf(in, "%s\n", &prefix)
	if err != nil {
		return 0, 0, err
	}
	return
}
