module Decode( input [3:0]Ra, input [3:0]Rb, input Imb, input [13:0]Imm, input [4:0]Opc, input [3:0]Rc, input [2:0]Cond, input Cmp,
    input [31:0]r[13:0], input [31:0]overflow, input [31:0] pc,
    input clk, input rst,
    output reg [31:0]Aval, output reg [31:0]Bval, 
    output reg [4:0]Opc2, output reg [3:0]Rc2, output reg [2:0]Cond2, output reg Cmp2 );

always@(posedge clk) begin
    if( rst ) begin
	Aval	<= 0;
	Bval	<= 0;
	Opc2	<= 0;
	Rc2	<= 0;
	Cond2	<= 0;
	Cmp2	<= 0;
    end else begin
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

	Opc2	<= Opc;
	Rc2	<= Rc;
	Cmp2	<= Cmp;
	Cond2	<= Cond;
    end
end

endmodule
