module CPU(
    output reg	[31:0]dataOut,
    input	[31:0]dataIn,
    output reg	dataWrEn,
    output reg	[13:0]dataAddress,
    input	[31:0]instructionIn,
    output wire [11:0]instructionAddress,
    output reg	[7:0]cpuStatus,
    input nRst,
    input clk);

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

`define ALWAYS	    3'h0
`define NEVER	    3'h1
`define ZERO	    3'h2
`define NOTZERO	    3'h3
`define GE	    3'h4
`define LT	    3'h5

// Possible levels of the CPU
`define FETCH	    8'h0
`define DECODE	    8'h1
`define EXECUTE	    8'h2
`define WRITEBACK   8'h3
`define FLUSH	    8'h4
`define HALT	    8'h5

// Decode/demux of the instruction 
reg [3:0]Ra, Rb, Rc;
reg Imb, Cmp;
reg [13:0] Imm;
reg [4:0] Opc;
reg [2:0] Cond;


// Following are registers used by the CPU
// PC is the program counter, mapped to the instruction address
reg [11:0] pc;
// The usual (14) working registers
reg [31:0]r[13:0];
// The current state of the CPU, only accessible by the CPU state machine
reg [7:0] state;
// The resultant status following an operation
reg [7:0] ALUStatus;
wire zero;
wire ge;
assign zero	= ALUStatus[0];
assign ge	= ALUStatus[2];
// Depending on the ALUstatus, write back the final result
reg writeBackEnable;
// The overflow register, for DIV and MUL
reg [31:0] overflow;
// Map pc -> instruction address
assign instructionAddress = pc;

// The decoded value of Rb, which can be an immediate value or a register
// (r-series only, not PC or overflow)
reg [31:0] Bval;

// The decoded value of Ra, which can be a register value (r-series)
// or the value of PC or overflow
reg [31:0] Aval;

// The data address decoded from Aval and Bval
wire [32:0] targetDataAddress;
assign targetDataAddress = Aval + Bval;

wire [31:0] ALUInA, ALUInB, ALUOut, ALUOverflow; 
wire [7:0] ALUStatusOut;
ALU alu(ALUInA, ALUInB, Opc, ALUStatus, ALUStatusOut, ALUOut, ALUOverflow);
assign ALUInA = Aval;
assign ALUInB = Bval;

always @(*) begin
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
    if(nRst) begin
	if(Opc == `STORE && state == `EXECUTE)
	    dataWrEn <= 1'b1;
	else
	    dataWrEn <= 1'b0;
    end
end

always @(posedge clk) begin
    if( !nRst ) begin
	// Under reset conditions, everything goes to zero and we go to LEVEL
	// 1 execution
	state	    <= `FLUSH;
	pc	    <= 12'h000;
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
	cpuStatus <= 8'h02;
    end else begin
	case(state)
	    `FETCH: begin
		cpuStatus <= 8'h01;
		Imb  <= instructionIn[31];
		Ra   <= instructionIn[30:27];
		Rb   <= instructionIn[26:23];
		Imm  <= instructionIn[26:13];
		Opc  <= instructionIn[12:8];
		Rc   <= instructionIn[7:4];
		Cond <= instructionIn[3:1];
		Cmp  <= instructionIn[0];

		state <= `DECODE;
	    end
	    `DECODE: begin
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
		else
		    if( Rb < 4'hE )
			Bval <= r[Rb];
		    else
			Bval <= 32'h0;

		state <= `EXECUTE;
	    end
	    `EXECUTE: begin
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

		// Remember that parallel to these LOAD/STORE operations,
		// Aval and Bval are racing through the ALU

		state <= `WRITEBACK;
	    end
	    `WRITEBACK: begin
		if( Cmp == 1'b1 ) begin
		    ALUStatus <= ALUStatusOut;
		end

		if( Opc == `LOAD ) begin
		    case(Rc)
			4'hE: begin
			    pc		<= dataIn[11:0];
			end
			4'hF: begin
			    overflow	<= dataIn;
			    pc		<= pc + 12'h1;
			end
			default: begin
			    r[Rc]	<= dataIn;
			    pc		<= pc + 12'h1;
			end
		    endcase
		end else begin
		    if( writeBackEnable == 1'b1 ) begin
			case(Rc)
			    4'hE: begin
				pc	    <= ALUOut[11:0];
			    end
			    4'hF: begin
				overflow    <= ALUOut;
				pc	    <= pc + 12'h1;
			    end
			    default: begin
				r[Rc]	    <= ALUOut;
				pc	    <= pc + 12'h1;
			    end
			endcase
		    end else begin
			pc  <= pc + 12'h1;
		    end
		end

		// If we wrote anything to the PC, we need to flush the
		// pipeline
		if(Rc == 4'hE && ((Opc == `LOAD) || (writeBackEnable == 1'b1)))
		    state <= `FLUSH;	
		else
		    state <= `FETCH;

	    end
	    // In this state, we simply flush the pipeline, though the correct
	    // new instruction is available, we will not load it, because this
	    // is done with the `FETCH state (`EXECUTE in pipeline mode)
	    `FLUSH: begin
		Imb  <= 0;
		Ra   <= 0;
		Rb   <= 0;
		Imm  <= 0;
		Opc  <= 0;
		Rc   <= 0;
		Cond <= 0;
		Cmp  <= 0;
		Aval <= 0;
		Bval <= 0;
		
		state <= `FETCH;
	    end
	    `HALT: begin
		cpuStatus <= 8'h04;
	    end
	endcase
    end
end

endmodule
