module Fetch(input [31:0]instructionIn, input clk, input rst, input stall,
    output reg [31:0]instructionDecode);

always @(posedge clk)
    if(rst) begin
	instructionDecode <= 0;
    end else begin
	if( stall == 1'b0 ) begin
	    instructionDecode <= instructionIn;
	end else begin
	    instructionDecode <= 0;    
	end
    end
endmodule
