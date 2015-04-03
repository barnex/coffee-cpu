#coffee-cpu

After drinking too much coffee, we built a CPU.

##CPU
Directory CPU/ has a verilog implementation of a CPU (@mathiashelsen). It requires 3 FPGA cycles per CPU instruction.

##ass
Command ``ass`` assembles source files into ihex executables (@barnex)

##emu
Command ``emu`` emulates ihex execution on a PC (@barnex). It features:
  * tracing execution (``-trace`` flag)
  * automatic memory protection for debugging your assembly programs (instructions cannot be overwritten and data cannot be executed)

##ISA
The coffee CPU currently has:
  * 256 32-bit registers named R0 - R255
  * a 16 bit address space, addressing 13 bit memory space of 32-bit words, plus peripherals
  * this instruction set:

```
NOP    do nothing
```
