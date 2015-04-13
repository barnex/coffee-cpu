module Decode(
    input [31:0] instructionDecode, input [31:0]r[13:0], input [31:0]overflow, input [31:0] pc,
    input clk, input rst, input stall,
    output reg [31:0]Aval, output reg [31:0]Bval, 
    output reg [31:0]instructionExecute);


wire Imb;
wire [3:0]Ra;
wire [3:0]Rb;
wire [13:0]Imm;
wire [4:0]Opc;
wire [3:0]Rc;
wire [2:0]Cond;
wire Cmp;

assign {Imb, Ra, Imm, Opc, Rc, Cond, Cmp} = instructionDecode;
assign Rb = instructionDecode[26:23];

always@(posedge clk) begin
    if( rst ) begin
	Aval	<= 0;
	Bval	<= 0;
	instructionExecute <= 0;
    end else if( stall == 1'b0 ) begin
	case(Ra)
	    4'hE: begin
		Aval <= pc;
	    end
	    4'hF: begin
		Aval <= overflow;
	    end
	    default: begin
		Aval <= r[Ra];
	    end
	endcase

	if(Imb == 1'b1)
	    Bval <= { {18{Imm[13]}}, Imm};
	else begin
	    if( Rb < 4'hE )
		Bval <= r[Rb];
	    else
		Bval <= 32'h0;
	end

	instructionExecute <= instructionDecode;
    end
end

endmodule
