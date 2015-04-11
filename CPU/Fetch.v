module Fetch(input [31:0]instructionIn, input clk, input rst,
    output reg Imb,
    output reg [3:0]Ra,
    output reg [3:0]Rb,
    output reg [13:0]Imm,
    output reg [4:0]Opc,
    output reg [3:0]Rc,
    output reg [2:0]Cond,
    output reg Cmp);

always @(posedge clk)
    if(rst) begin
	Imb  <= 0;
	Ra   <= 0;
	Rb   <= 0;
	Imm  <= 0;
	Opc  <= 0;
	Rc   <= 0;
	Cond <= 0;
	Cmp  <= 0;
    end else begin
	Imb  <= instructionIn[31];
	Ra   <= instructionIn[30:27];
	Rb   <= instructionIn[26:23];
	Imm  <= instructionIn[26:13];
	Opc  <= instructionIn[12:8];
	Rc   <= instructionIn[7:4];
	Cond <= instructionIn[3:1];
	Cmp  <= instructionIn[0];
    end

endmodule
