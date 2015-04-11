/*
The CPU has three states of operation and one reset state;
The first state of operation if FETCH/EXECUTE which is the active state and will be described in great detail below.
The second state is FLUSH, which flushes all registers after a write to PC
The third state is the HALT state, which locks up the CPU in a NOP cycle. This state is currently unused.


The FETCH/EXECUTE state are four cycles which are pipelined:
    - FETCH: Data on the instruction bus is copied into Ra, Rb, Opc, ... registers
    - DECODE: Ra, Rb are decoded. The immediate value (for Bval) is also zero padded at this stage.
	! If Ra=PC, the value of PC is stored into Aval at this stage.
    - EXECUTE: Addresses and data for STORE/LOAD is put unto the bus. The output of the ALU
	is stored as well.
	! The ALU depends on Aval and Bval of the previous stage, as well as the value of ALUStatus
	at the previous state.
    - WRITEBACK: Updates the ALUStatus (using the ALUstatus that was saved the previous cycle) depending in the Cmp-bit.
	Also writes to PC or updates PC -> PC+1. Data is read from memory as well.

In pipelined mode, the CPU flushes all its intermediate registers after a write to PC, by jumping to the FLUSH state.
Operations directly following a PC write are executed, but can never write, due to this jump to the FLUSH state.
When using relative jumps, take into account that reading from Ra=PC is off by 2 when the jump will take place, i.e. the time
difference between DECODE and WRITEBACK.
*/
package isa
