module CPU(
    output reg	[31:0]dataOut,
    input	[31:0]dataIn,
    output reg	dataWrEn,
    output reg	[15:0]dataAddress,
    input	[31:0]instructionIn,
    output wire [11:0]instructionAddress,
    output reg	[7:0]cpuStatus,
    input nRst,
    input clk);

`define LOAD	    8'h01
`define STORE	    8'h02
`define AND	    8'h0D
`define OR	    8'h0E
`define XOR	    8'h0F
`define ADD	    8'h10
`define ADDC	    8'h11
`define SUB	    8'h12
`define MUL	    8'h13
`define DIV	    8'h14
`define SDIV	    8'h14

`define ALWAYS	    3'h0
`define NEVER	    3'h1
`define ZERO	    3'h2
`define NOTZERO	    3'h3
`define GE	    3'h4
`define LT	    3'h5

// Decode/demux of the instruction 
wire [3:0]Ra, Rb, Rc;
wire Imb, Cmp;
wire [13:0] Imm;
wire [4:0] Opc;
wire [2:0] Cond;

// Possible levels of the CPU, currently only LEVEL1 & LEVEL2 is in use
`define LEVEL1	8'h0
`define LEVEL2	8'h1
`define LEVEL3	8'h2

// Following are registers used by the CPU
// PC is the program counter, mapped to the instruction address
reg [11:0] pc;
// The usual (14) working registers
reg [31:0]r[13:0];
// The current state of the CPU, only accessible by the CPU state machine
reg [7:0] state;
// The resultant status following an operation
reg [7:0] status;
wire zero;
wire ge;
assign zero	= status[0];
assign ge	= status[2];
// The overflow register, for DIV and MUL
reg [31:0] overflow;
// Moehahahaha!
reg [31:0] devNull;
// Map pc -> instruction address
assign instructionAddress = pc;

assign Imb  = instructionIn[31];
assign Ra   = instructionIn[30:27];
assign Rb   = instructionIn[26:23];
assign Imm  = instructionIn[26:13];
assign Opc  = instructionIn[12:8];
assign Rc   = instructionIn[7:4];
assign Cond = instructionIn[3:1];
assign Cmp  = instructionIn[0];

wire [31:0] Bval;
assign Bval = (Imb == 1'b1) ? { {18{Imm[11]}}, Imm} : r[Rb];
reg writeBackEnable;
reg [31:0] Aval;
wire [32:0] AddressTmp;
assign AddressTmp = Aval+Bval;

wire [31:0] ALUInA, ALUInB, ALUOut, ALUOverflow; 
wire [7:0] ALUStatusOut;
ALU alu(ALUInA, ALUInB, Opc, status, ALUStatusOut, ALUOut, ALUOverflow);
assign ALUInA = r[Ra];
assign ALUInB = Bval;

always @(*)
begin
    case(Ra)
	4'hE: begin
	    Aval = pc;
	end
	4'hF: begin
	    Aval = overflow;
	end
	default: begin
	    Aval = r[Ra];
	end
    endcase
end

/*
always @(*)
*/
always @(*)
begin
    case(Cond)
	`ALWAYS: begin
	    writeBackEnable = 1'b1;
	end
	`NEVER: begin
	    writeBackEnable = 1'b0;
	end
	`ZERO: begin
	    if( zero == 1'b1 )
		writeBackEnable = 1'b1;
	    else
		writeBackEnable = 1'b0;
	end
	`NOTZERO: begin
	    if( zero == 1'b0 )
		writeBackEnable = 1'b1;
	    else
		writeBackEnable = 1'b0;
	end
	`GE: begin
	    if( ge == 1'b1 )
		writeBackEnable = 1'b1;
	    else
		writeBackEnable = 1'b0;
	end
	`LT: begin
	    if( ge == 1'b0 )
		writeBackEnable = 1'b1;
	    else
		writeBackEnable = 1'b0;
	end
	default: begin
	    writeBackEnable = 1'b1;
	end
    endcase
end

always @(posedge clk) begin
    if(Cmp)
	status <= ALUStatusOut;
end

always @(posedge clk) begin
    if( !nRst ) begin
	state	    <= `LEVEL1;
	pc	    <= 12'h000;
	dataWrEn    <= 1'b0;
	cpuStatus   <= 8'hA0;
	r[0]	    <= 32'h0;
	r[1]	    <= 32'h0;
	r[2]	    <= 32'h0;
	r[3]	    <= 32'h0;
	r[4]	    <= 32'h0;
	r[5]	    <= 32'h0;
	r[6]	    <= 32'h0;
	r[7]	    <= 32'h0;
	r[8]	    <= 32'h0;
	r[9]	    <= 32'h0;
	r[10]	    <= 32'h0;
	r[11]	    <= 32'h0;
	r[12]	    <= 32'h0;
	r[13]	    <= 32'h0;
    end else begin
	case(state)
	    `LEVEL1: begin
		// Let know that the CPU is running as normal
		cpuStatus <= 8'h00;
		// Decode and process the current command
		case (Opc)
		    `LOAD: begin
			dataAddress <= AddressTmp[15:0];
			dataWrEn    <= 1'b0;
			state	    <= `LEVEL2;
		    end
		    `STORE: begin
			dataAddress <= AddressTmp[15:0];
			dataOut	    <= r[Rc];
			dataWrEn    <= 1'b1;
		    end
		endcase
		if( (Opc != `LOAD) && (writeBackEnable == 1'b1) ) begin
		    case(Rc)
			4'hE: begin
			    pc	<= ALUOut[11:0];
			end
			4'hF: begin
			    overflow <= ALUOut;
			end
			default: begin
			    r[Rc] <= ALUOut;
			    overflow <= ALUOverflow;
			end	
		    endcase
		end
		if( (Opc != `LOAD) && (Rc != 4'hE)) begin
		    pc <= pc + 12'h1;
		end
	    end
	    `LEVEL2: begin
		case(Rc)
		    4'hE: begin
			pc	<= dataIn[11:0];
		    end
		    4'hF: begin
			overflow <= dataIn;
			pc	<= pc + 12'h1;
		    end
		    default: begin
			r[Rc] <= dataIn;
			pc	<= pc + 12'h1;
		    end	
		endcase
		state	<= `LEVEL1;
	    end
	endcase
    end
end

endmodule
