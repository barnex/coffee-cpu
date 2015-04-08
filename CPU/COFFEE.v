module COFFEE(input CLOCK_50, 
    output [9:0]LEDG, 
    output [6:0]HEX0_D, 
    output [6:0]HEX1_D,
    output [6:0]HEX2_D,
    output [6:0]HEX3_D,
    input [2:0]BUTTON);

wire [11:0] instructionAddress;
wire [31:0] instruction;
wire [15:0] dataAddress;
wire [31:0] writeData;
wire [31:0] readData;
wire dataWrEn;

wire cpuClk; 
wire mmuClk;

wire [7:0] status;
assign LEDG[7:0] = status;

reg nRst;

always @(posedge cpuClk) begin
    if( BUTTON[0] == 1'b0 ) begin
	nRst <= 1'b1;
    end else if( BUTTON[1] == 1'b0) begin
	nRst <= 1'b0;
    end
end

MMU mmu(instructionAddress, 
    instruction,
    dataAddress,
    writeData,
    readData,
    dataWrEn,
    HEX0_D, HEX1_D, HEX2_D, HEX3_D,
    nRst, mmuClk);

CPU cpu(
    writeData,
    readData,
    dataWrEn,
    dataAddress,
    instruction,
    instructionAddress,
    status,
    nRst,
    cpuClk);

masterpll mainPLL(
    CLOCK_50,
    cpuClk,
    mmuClk);

endmodule
