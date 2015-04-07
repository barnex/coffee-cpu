#coffee-cpu

After drinking too much coffee, we built a CPU.

##CPU
Directory CPU/ has a verilog implementation of the CPU, which works on an FPGA (@mathiashelsen). The CPU currently clocks at 25MHz and issues 1 instruction per cycle (2 cycles for LOAD/STORE). 

##assembler
Command ``ass`` assembles source files into ihex executables, which can be loaded into the FPGA memory (@barnex):
```
ass test.ss
```
The assembler accepts assembly code conform the ISA (below) and ``#def``, ``#undef`` macros.

##emulator
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
NOP                : no-op
LOAD     Ra Rb Rc  : Rc = mem[Ra+Rb]
STORE    Ra Rb Rc  : mem[Ra+Rb] = Rc
LOADI    Ra addr   : Ra = mem[addr]
STORE    Ra addr   : mem[addr] = Ra
LOADLI   Ra VALUE  : load VALUE (16 bit) into the lower half of register RA
LOADHI   Rb VALUE  : load VALUE (16 bit) into the upper half of register RA
LOADLISE Rb VALUE  : load VALUE into the lower half of Ra, sign extend to upper half
JMPZ     Ra DELTA  : if RA holds zero, make a relative jump of DELTA instructions
JMPNZ    Ra DELTA  : jump if Ra holds nonzero
JMPLT    Ra DELTA  : jump if Ra holds negative number
JMPGTE   Ra DELTA  : jump if Ra holds number >= 0
MOV      Ra Rb     : copy RA into RB  // deprecate?
AND      Ra Rb Rc  : bitwise and: Rc = Ra & Rb
OR       Ra Rb Rc  : bitwise or : Rc = Ra | Rb
XOR      Ra Rb Rc  : bitwise xor: Rc = Ra ^ Rb
ADD      Ra Rb Rc  : integer add: Rc = Ra + Rb
ADD      Ra Rb Rc  : add with carry
SUB      Ra Rb Rc  : Rc = Ra - Rb
MUL      Ra Rb Rc  : Rc = (Ra*Rb)[31:0], R(c+1) = (Ra*Rb)[63:32]
DIV      Ra Rb Rc  : unsigned division Rc = Ra/Rb, R(c+1) = Ra%Rb
SDIV     Ra Rb Rc  : signed division Rc = Ra/Rb, R(c+1) = Ra%Rb
```
  * memory-mapped peripherals:
```
0xFFFF : 16-bit register displayed on 7-segment LED display
```


##example program
```
// This test program cycles the hex display
// through all 16-bit values

#def display 0xFFFF
#def counter R2

LOADLI  R1      1
STORI	counter display 
ADD 	R1      counter counter
JUMPZ 	R0      -2 
```

output of ``emu -trace``:
```
(00000000):     NOP  0
(00000001:03010001):  LOADLI R1(=00000000) 00000001
(00000002:0202FFFF):   STORE R2(=00000000) 0000FFFF
00000000
(00000003:0A010202):     ADD R1(=00000001) R2(=00000000) R2
(00000004:0500FFFE):    JMPZ R0(=00000000) 0000FFFE
(00000002:0202FFFF):   STORE R2(=00000001) 0000FFFF
00000001
(00000003:0A010202):     ADD R1(=00000001) R2(=00000001) R2
(00000004:0500FFFE):    JMPZ R0(=00000000) 0000FFFE
(00000002:0202FFFF):   STORE R2(=00000002) 0000FFFF
00000002
(00000003:0A010202):     ADD R1(=00000001) R2(=00000002) R2
(00000004:0500FFFE):    JMPZ R0(=00000000) 0000FFFE
(00000002:0202FFFF):   STORE R2(=00000003) 0000FFFF
00000003
...
```

Watch this program running on FPGA: https://youtu.be/CDd83oF9Tog (downclocked to 1Hz for clarity).
