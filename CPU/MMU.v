module MMU(input [15:0]addressCPU, input [31:0]dataCPU, output [31:0]qCPU, input wrenCPU, output reg stallCPU,
    output [6:0]HEX0_D, output [6:0]HEX1_D, output [6:0]HEX2_D, output [6:0]HEX3_D,
    input nRst, input clk);

reg [3:0]Digit0;
reg [3:0]Digit1;
reg [3:0]Digit2;
reg [3:0]Digit3;

wire wrenMem;
assign wrenMem = (addressCPU[15:13] == 0) ? wrenCPU : 1'b0;

segdriver hex0(Digit0, HEX0_D);
segdriver hex1(Digit1, HEX1_D);
segdriver hex2(Digit2, HEX2_D);
segdriver hex3(Digit3, HEX3_D);

memory mem (
	addressCPU[12:0],
	clk,
	dataCPU,
	wrenMem,
	qCPU);

always @(posedge clk) begin
    stallCPU <= 1'b0;
    if( (addressCPU == 16'hFFFF) & wrenCPU ) begin
	Digit0 <= dataCPU[3:0];
	Digit1 <= dataCPU[7:4];
	Digit2 <= dataCPU[11:8];
	Digit3 <= dataCPU[15:12];
    end
end

endmodule
