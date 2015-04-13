module Execute(
    input [31:0] instructionExecute,
    input [31:0] Aval, input [31:0] Bval, input [7:0]ALUStatus,
    input clk, input rst, input stall,
    output reg [7:0]ALUStatusOut3, output reg [31:0] ALUOut3, output reg [31:0]ALUOverflow3,
    output reg [13:0] dataAddress, output reg [31:0]dataOut,
    input [31:0] OverwriteData, input [1:0] OverwriteEn,
    output reg[31:0] instructionWriteBack);
`define LOAD	    5'h1
`define STORE	    5'h2
`define AND	    5'h3
`define OR	    5'h4
`define XOR	    5'h5
`define ADD	    5'h6
`define ADDC	    5'h7
`define SUB	    5'h8
`define MUL	    5'h9
`define DIV	    5'hA
`define SDIV	    5'hB

wire Imb;
wire [3:0]Ra;
wire [3:0]Rb;
wire [13:0]Imm;
wire [4:0]Opc;
wire [3:0]Rc;
wire [2:0]Cond;
wire Cmp;

assign {Imb, Ra, Imm, Opc, Rc, Cond, Cmp} = instructionExecute;
assign Rb = instructionExecute[26:23];

wire [31:0] Afinal, Bfinal;

always @(*) begin
    case(OverwriteEn)
	2'b01: begin
	    Afinal = OverwriteData;
	    Bfinal = Bval;
	end
	2'b10: begin
	    Afinal = Aval;
	    Bfinal = OverwriteData;
	end
	default: begin
	    Afinal = Aval;
	    Bfinal = Bval;
	end
    endcase
end

// The data address decoded from Aval and Bval
wire [32:0] targetDataAddress;
assign targetDataAddress = Afinal + Bfinal;

wire [7:0]alustatusouttmp;
wire [31:0]aluouttmp, aluoverflowouttmp;

ALU alu(Afinal, Bfinal, Opc, ALUStatus, alustatusouttmp, aluouttmp, aluoverflowouttmp);

always @(posedge clk)
    if( rst ) begin
	ALUStatusOut3   <= 0;
	ALUOut3		<= 0;
	ALUOverflow3    <= 0;

	instructionWriteBack <= 0;
    end else begin
	ALUStatusOut3   <= alustatusouttmp;
	ALUOut3		<= aluouttmp;
	ALUOverflow3    <= aluoverflowouttmp;

	case (Opc)
	    `LOAD: begin
		// Write out the address (r[Ra]/pc/overflow + r[Rb]/Imm)
		dataAddress <= targetDataAddress[13:0];
		// We will not be writing, but reading in a value
	    end
	    `STORE: begin
		// Write out the address
		dataAddress <= Bfinal[13:0];
		// Write out the data;
		dataOut	    <= Afinal;
		// Enable writing
	    end
	endcase

	if( stall == 1'b0 ) 
	    instructionWriteBack <= instructionExecute;
	else
	    instructionWriteBack <= 0;
    end
endmodule
