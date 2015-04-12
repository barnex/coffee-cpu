module Execute(
    input [31:0] Aval, input [31:0] Bval, input [7:0]ALUStatus,
    input [31:0] instructionExecute,
    input clk, input rst, input stall,
    output reg [7:0]ALUStatusOut3, output reg [31:0] ALUOut3, output reg [31:0]ALUOverflow3,
    output reg [13:0] dataAddress, output reg [31:0]dataOut,
    output reg[31:0] instructionWriteBack);

wire Imb;
wire [3:0]Ra,
wire [3:0]Rb,
wire [13:0]Imm,
wire [4:0]Opc,
wire [3:0]Rc,
wire [2:0]Cond,
wire Cmp;

assign {Imb, Ra, Imm, Opc, Rc, Cond, Cmp} = instructionDecode;
assign Rb = instructionDecode[26:23];

// The data address decoded from Aval and Bval
wire [32:0] targetDataAddress;
assign targetDataAddress = Aval + Bval;

wire [7:0]alustatusouttmp;
wire [31:0]aluouttmp, aluoverflowouttmp;

ALU alu(Aval, Bval, Opc, ALUStatus, alustatusouttmp, aluouttmp, aluoverflowouttmp);

always @(posedge clk)
    if( rst ) begin
	ALUStatusOut3   <= 0;
	ALUOut3		<= 0;
	ALUOverflow3    <= 0;

	instructionWriteBack <= 0;
    end else if (!stall) begin
	ALUStatusOut3   <= alustatusouttmp;
	ALUOut3		<= aluouttmp;
	ALUOverflow3    <= aluoverflowouttmp;

	instructionWriteBack <= instructionExecute;

	case (Opc)
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
    end else begin
	instructionWriteBack <= 0;
    end
endmodule
