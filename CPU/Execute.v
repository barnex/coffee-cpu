module Execute(
    input [31:0] Aval, input [31:0] Bval, input [7:0]ALUStatus,
    input [4:0]Opc2, input [3:0]Rc2, input Cmp2, input [2:0]Cond2,
    input clk, input rst,
    output reg [7:0]ALUStatusOut3, output reg [31:0] ALUOut3, output reg [31:0]ALUOverflow3,
    output reg [13:0] dataAddress, output reg [31:0]dataOut,
    output reg [4:0] Opc3, output reg [3:0]Rc3, output reg Cmp3, output reg [2:0] Cond3);

// The data address decoded from Aval and Bval
wire [32:0] targetDataAddress;
assign targetDataAddress = Aval + Bval;

wire [7:0]alustatusouttmp;
wire [31:0]aluouttmp, aluoverflowouttmp;

ALU alu(Aval, Bval, Opc2, ALUStatus, alustatusouttmp, aluouttmp, aluoverflowouttmp);

always @(posedge clk)
    if( rst ) begin
	ALUStatusOut3   <= 0;
	ALUOut3		<= 0;
	ALUOverflow3    <= 0;

	Opc3		<= 0;
	Rc3		<= 0;
	Cmp3		<= 0;
	Cond3		<= 0;
    end else begin
	ALUStatusOut3   <= alustatusouttmp;
	ALUOut3		<= aluouttmp;
	ALUOverflow3    <= aluoverflowouttmp;

	Opc3		<= Opc2;
	Rc3		<= Rc2;
	Cmp3		<= Cmp2;
	Cond3		<= Cond2;

	case (Opc2)
	    `LOAD: begin
		// Write out the address (r[Ra]/pc/overflow + r[Rb]/Imm)
		dataAddress <= targetDataAddress[13:0];
		// We will not be writing, but reading in a value
	    end
	    `STORE: begin
		// Write out the address
		dataAddress <= Bval[13:0];
		// Write out the data;
		dataOut	    <= Aval;
		// Enable writing
	    end
	endcase
    end
endmodule
