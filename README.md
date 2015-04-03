#coffee-cpu

After drinking too much coffee, we built a CPU.

##CPU
Directory CPU/ has a verilog implementation of the CPU (@mathiashelsen). It requires 3 FPGA cycles per CPU instruction.

##ass
Command ``ass`` assembles source files into ihex executables (@barnex):
```
ass test.ss
```

##emu
Command ``emu`` emulates ihex execution on a PC (@barnex). It features:
  * tracing execution (``-trace`` flag)
  * automatic memory protection for debugging your assembly programs (instructions cannot be overwritten and data cannot be executed)
```
emu -trace test.ihex
```

##coffee ISA
The coffee CPU currently has:
  * 256 32-bit registers named R0 - R255
  * a 16 bit address space, addressing 13 bit memory space of 32-bit words, plus peripherals
  * this instruction set:

```
NOP             : no-op
LOAD   RA ADDR  : load from memory address ADDR into register RA
STORE  RA ADDR  : store from register RA into memory address ADDR
LOADLI RA VALUE : load VALUE (16 bit) into the lower half of register RA
LOADHI RA VALUE : load VALUE (16 bit) into the upper half of register RA
JMPZ   RA DELTA : if RA holds zero, make a relative jump of DELTA instructions
MOV    RA RB    : copy RA into RB
AND    RA RB RC : bitwise and: RC = RA & RB
OR     RA RB RC : bitwise or : RC = RA | RB
XOR    RA RB RC : bitwise xor: RC = RA ^ RB
ADD    RA RB RC : integer add: RC = RA + RB
```
