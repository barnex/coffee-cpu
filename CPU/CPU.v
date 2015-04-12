module CPU(
    output	[31:0]dataOut,
    input	[31:0]dataIn,
    output reg	dataWrEn,
    output	[13:0]dataAddress,
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

`define NEVER	    3'h0
`define ALWAYS	    3'h1
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
wire [3:0]Ra, Rb, Rc, Rc2, Rc3;
wire Imb, Cmp, Cmp2, Cmp3; 
wire [13:0] Imm;
wire [4:0] Opc, Opc2, Opc3; 
wire [2:0] Cond, Cond2, Cond3;

reg rst;

Fetch fetch(instructionIn, clk, rst,
    Imb, Ra, Rb, Imm, Opc, Rc, Cond, Cmp);

Decode decode( Ra, Rb, Imb, Imm, Opc, Rc, Cond, Cmp,
    r, overflow, pc,
    clk, rst,
    Aval, Bval, 
    Opc2, Rc2, Cond2, Cmp2 );

Execute execute(
    Aval, Bval, ALUStatus,
    Opc2, Rc2, Cmp2, Cond2,
    clk, rst,
    ALUStatusOut3, ALUOut3, ALUOverflow3,
    dataAddress, dataOut,
    Opc3, Rc3, Cmp3, Cond3);

wire [7:0] ALUStatusOut3;
wire [31:0] ALUOut3;
wire [31:0] ALUOverflow3;

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
wire [31:0] Bval;

// The decoded value of Ra, which can be a register value (r-series)
// or the value of PC or overflow
wire [31:0] Aval;

always @(*) begin
    case(Cond3)
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
	if(Opc2 == `STORE)// && state == `EXECUTE)
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

/*
		state <= `DECODE;
	    end
	    `DECODE: begin
*/

/*
		state <= `EXECUTE;
	    end
	    `EXECUTE: begin
*/

		// Remember that parallel to these LOAD/STORE operations,
		// Aval and Bval are racing through the ALU
/*
		state <= `WRITEBACK;
	    end
	    `WRITEBACK: begin
*/
		if( Cmp3 == 1'b1 ) begin
		    ALUStatus <= ALUStatusOut3;
		end

		// Before writing anything away, we have to check we are not
		// dealing with a NOP
		if( Opc3 == `LOAD && Opc3 != 5'h0 ) begin
		    case(Rc3)
			4'hE: begin
			    pc		<= dataIn[11:0];
			end
			4'hF: begin
			    overflow	<= dataIn;
			    pc		<= pc + 12'h1;
			end
			default: begin
			    r[Rc3]	<= dataIn;
			    pc		<= pc + 12'h1;
			end
		    endcase
		end else if( Opc3 != 5'h0) begin
		    if( writeBackEnable == 1'b1 ) begin
			case(Rc3)
			    4'hE: begin
				pc	    <= ALUOut3[11:0];
			    end
			    4'hF: begin
				overflow    <= ALUOut3;
				pc	    <= pc + 12'h1;
			    end
			    default: begin
				r[Rc3]	    <= ALUOut3;
				pc	    <= pc + 12'h1;
			    end
			endcase
		    end else begin
			pc  <= pc + 12'h1;
		    end
		// NOP's only increase the program counter
		end else begin
		    pc	    <= pc + 12'h1;
		end

		// If we wrote anything to the PC, we need to flush the
		// pipeline
		if(Rc3 == 4'hE && ((Opc3 == `LOAD) || (writeBackEnable == 1'b1))) begin
		    state <= `FLUSH;	
		    rst <= 1'b1;
		end else
		    state <= `FETCH;

	    end
	    // In this state, we simply flush the pipeline, though the correct
	    // new instruction is available, we will not load it, because this
	    // is done with the `FETCH state (`EXECUTE in pipeline mode)
	    `FLUSH: begin
		rst <= 1'b0;
		state	<= `FETCH;
	    end
	    `HALT: begin
		cpuStatus <= 8'h04;
	    end
	endcase
    end
end

endmodule
