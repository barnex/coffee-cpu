module MMU(input [11:0]instructionAddress, 
    output [31:0]instructionOut,
    input [13:0]dataAddress,
    input [31:0]writeDataIn,
    output [31:0]readDataOut,
    input dataWrEn,
    output [6:0]HEX0_D, output [6:0]HEX1_D, output [6:0]HEX2_D, output [6:0]HEX3_D,
    input nRst, input clk);

reg [3:0]Digit0;
reg [3:0]Digit1;
reg [3:0]Digit2;
reg [3:0]Digit3;

wire RAMEnable;
assign RAMEnable = (dataAddress < 14'h1000);

segdriver hex0(Digit0, HEX0_D);
segdriver hex1(Digit1, HEX1_D);
segdriver hex2(Digit2, HEX2_D);
segdriver hex3(Digit3, HEX3_D);

instructionROM ROM(
	instructionAddress,
	clk,
	instructionOut);

dataRAM RAM(
	dataAddress,
	clk & RAMEnable,
	writeDataIn,
	dataWrEn,
	readDataOut);

always @(posedge clk) begin
    if( (dataAddress == 14'h3FFF) & dataWrEn ) begin
	Digit0 <= writeDataIn[3:0];
	Digit1 <= writeDataIn[7:4];
	Digit2 <= writeDataIn[11:8];
	Digit3 <= writeDataIn[15:12];
    end
end

endmodule
