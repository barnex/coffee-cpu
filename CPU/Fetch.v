module Fetch(input [31:0]instructionIn, input clk, input rst, input stall,
    output reg [31:0]instructionDecode);
/*
    output reg Imb,
    output reg [3:0]Ra,
    output reg [3:0]Rb,
    output reg [13:0]Imm,
    output reg [4:0]Opc,
    output reg [3:0]Rc,
    output reg [2:0]Cond,
    output reg Cmp);
*/

always @(posedge clk)
    if(rst) begin
	instructionDecode <= 0;
    end else if( !stall) begin
	instructionDecode <= instructionIn;
    end else begin
	instructionDecode <= 0;    
    end
endmodule
