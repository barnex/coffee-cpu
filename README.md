#coffee-cpu

After drinking too much coffee, we built a CPU.

##CPU
Directory CPU/ has a verilog implementation of the CPU, which works on an FPGA (@mathiashelsen). The CPU currently clocks at 100MHz and issues 1 instruction per cycle (2 cycles for LOAD/STORE). 

##assembler
Command ``ass`` assembles source files into ihex executables, which can be loaded into the FPGA memory (@barnex):
```
ass test.ss
```
The assembler accepts assembly code conform the ISA (below) and ``#def``, ``#undef``, ``#label`` macros.

##emulator
Command ``emu`` emulates ihex execution on a PC (@barnex). It features tracing execution (``-trace`` flag)
```
emu -trace test.ihex
```

##coffee ISA
The coffee CPU currently features:
  * 16 32-bit registers named R0 -- R13, PC and Rx.
  * PC (R14) is the program counter. Writing this register causes a jump in the code.
  * Rx (R15) is an overflow register. It cannot be written directly but will hold a second result value like the remainder of a division or the highest 32 bits of a multiplication.
  * a 14 bit memory space, addressing 12 bit instruction memory, 12 bit program memory and memory-mapped peripherals.
  * memory-mapped peripherals:
```
0x3FFF : 16-bit register displayed on 7-segment LED display
```


##example program
```
// This test program cycles the hex display
// through all 16-bit values

#def display 0x3FFF
#def Rcount R1

#label _start
XOR   R0     R0       A R0     -cmp
STORE Rcount display  N R0     -cmp
ADD   Rcount 1        A Rcount -cmp
ADD   R0     _start   A PC     -cmp
```

output of ``emu -trace``:
```
  XOR   R0(0)   R0(0) A(true)     R0(0) 
STORE   R1(0)   16383 N(false)     R0(0) 
  ADD   R1(0)       1 A(true)     R1(1) 
  ADD   R0(0)       0 A(true)    R14(0) 
  XOR   R0(0)   R0(0) A(true)     R0(0) 
STORE   R1(1)   16383 N(false)     R0(0) 
  ADD   R1(1)       1 A(true)     R1(2) 
  ADD   R0(0)       0 A(true)    R14(0) 
  XOR   R0(0)   R0(0) A(true)     R0(0) 
STORE   R1(2)   16383 N(false)     R0(0) 
  ADD   R1(2)       1 A(true)     R1(3) 
  ADD   R0(0)       0 A(true)    R14(0) 
  XOR   R0(0)   R0(0) A(true)     R0(0) 
...
```

Watch this program running on FPGA: https://youtu.be/CDd83oF9Tog (downclocked to 1Hz for clarity).
