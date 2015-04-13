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

reg rst;
reg stallFetch, stallDecode, stallExecute;
reg [31:0] OverwriteData;
reg [1:0] OverwriteEn;
wire stallReq /* synthesis keep */;

wire pcIncEn /* synthesis keep */;

// Decode/demux of the instruction 
wire [31:0] instructionWriteBack;
wire Imb;
wire [3:0]Ra;
wire [3:0]Rb;
wire [13:0]Imm;
wire [4:0]Opc;
wire [3:0]Rc /* synthesis keep*/;
wire [2:0]Cond /* synthesis keep */;
wire Cmp;

assign {Imb, Ra, Imm, Opc, Rc, Cond, Cmp} = instructionWriteBack;
assign Rb = instructionWriteBack[26:23];

wire [31:0] instructionDecode;
wire [31:0] instructionExecute;
wire [4:0] OpcExecute;
assign OpcExecute   = instructionExecute[12:8];

wire [3:0] RaExecute, RbExecute;
wire ImbExecute;
assign RaExecute    = instructionExecute[30:27];
assign RbExecute    = instructionExecute[26:23];
assign ImbExecute   = instructionExecute[31];

// The decoded value of Rb, which can be an immediate value or a register
// (r-series only, not PC or overflow)
wire [31:0] Bval;

// The decoded value of Ra, which can be a register value (r-series)
// or the value of PC or overflow
wire [31:0] Aval;

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
wire lt;
assign zero	= ALUStatus[0];
assign lt	= ALUStatus[2];
// Depending on the ALUstatus, write back the final result
reg writeBackEnable /*synthesis keep*/; 
// The overflow register, for DIV and MUL
reg [31:0] overflow /* synthesis keep*/;
// Map pc -> instruction address
assign instructionAddress = pc;

wire [7:0] ALUStatusOut3;
wire [31:0] ALUOut3;
wire [31:0] ALUOverflow3;

Fetch fetch(instructionIn, clk, rst, stallReq, instructionDecode);

Decode decode( instructionDecode, 
    r, overflow, pc,
    clk, rst, stallReq,
    Aval, Bval, 
    instructionExecute);

Execute execute(
    instructionExecute,
    Aval, Bval, ALUStatus,
    clk, rst, stallReq,
    ALUStatusOut3, ALUOut3, ALUOverflow3,
    dataAddress, dataOut,
    OverwriteData, OverwriteEn,
    instructionWriteBack);

always_comb begin
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
	    if( lt == 1'b0 )
		writeBackEnable = 1'b1;
	    else
		writeBackEnable = 1'b0;
	end
	`LT: begin
	    if( lt == 1'b1 )
		writeBackEnable = 1'b1;
	    else
		writeBackEnable = 1'b0;
	end
	default: begin
	    writeBackEnable = 1'b0;
	end
    endcase
end

always_comb begin
    if( writeBackEnable == 1'b1 || Opc == `LOAD || Cmp == 1'b1 ) begin	
	if( RaExecute == Rc )
	    stallReq = 1'b1;
	else if( ImbExecute == 1'b0 && RbExecute == Rc )
	    stallReq = 1'b1;
	else if( Cmp == 1'b1 )
	    stallReq = 1'b1;
	else if( RaExecute == 4'hF || RbExecute == 4'hF)
	    stallReq = 1'b1;
	else
	    stallReq = 1'b0;
    end else begin
	if( (RaExecute == 4'hF || RbExecute == 4'hF) && (Opc != 0))
	    stallReq = 1'b1;
	else
	    stallReq = 1'b0;
    end
end

always_comb begin
    // If we load from memory into PC, don't increase
    if( Opc == `LOAD && Rc == 4'hE )
	pcIncEn = 1'b0;
    // If we save a result into PC, don't increase
    else if( Opc != 5'h0 && writeBackEnable == 1'b1 && Rc == 4'hE )
	pcIncEn = 1'b0;
    // If we aren't saving anything into PC (i.e. no branch), but a stall has
    // been requested, don't increase
    else if( stallReq == 1'b1 )
	pcIncEn = 1'b0;
    // In all other cases, increase
    else
	pcIncEn = 1'b1;
end

always @(posedge clk) begin
    if(nRst) begin
	if(OpcExecute == `STORE)// && state == `EXECUTE)
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
	cpuStatus   <= 8'h02;
	rst	    <= 1'b1;
	stallFetch  <= 1'b0;
	stallDecode <= 1'b0;
	stallExecute<= 1'b0;
	OverwriteEn <= 2'b00;
    end else begin
	case(state)
	    `FETCH: begin
		rst <= 1'b0;
		cpuStatus <= 8'h01;

		if( Cmp == 1'b1 ) begin
		    ALUStatus <= ALUStatusOut3;
		end

		// Before writing anything away, we have to check we are not
		// dealing with a NOP
		if( Opc == `LOAD && Opc != 5'h0 ) begin
		    case(Rc)
			4'hE: begin
			    pc		<= dataIn[11:0];
			end
			4'hF: begin
			    overflow	<= dataIn;
			end
			default: begin
			    r[Rc]	<= dataIn;
			end
		    endcase
		end else if( Opc != 5'h0) begin
		    if( writeBackEnable == 1'b1 ) begin
			case(Rc)
			    4'hE: begin
				pc	    <= ALUOut3[11:0];
			    end
			    4'hF: begin
				overflow    <= ALUOut3;
			    end
			    default: begin
				r[Rc]	    <= ALUOut3;
			    end
			endcase
		    end
		end
		if( Opc != `LOAD && Rc != 4'hF ) begin
		    overflow	<= ALUOverflow3;
		end

		if( pcIncEn == 1'b1 )
		    pc	<= pc + 12'h1;

		// If we wrote anything to the PC, we need to flush the
		// pipeline
		if(Rc == 4'hE && ((Opc == `LOAD) || (writeBackEnable == 1'b1))) begin
		    state <= `FLUSH;	
		    rst <= 1'b1;
		end else
		    state <= `FETCH;

		/*
		 * PIPELINE HAZARD MANAGER
		 */
		if( stallReq == 1'b1 ) begin
		    stallFetch	    <= 1'b1;
		    stallDecode	    <= 1'b1;
		    stallExecute    <= 1'b1;
		end else begin
		    stallFetch	    <= 1'b0;
		    stallDecode	    <= 1'b0;
		    stallExecute    <= 1'b0;
		end
		     
	
		if( (writeBackEnable == 1'b1 || Opc == `LOAD) && (RaExecute != 4'hF) && (RbExecute != 4'hF) ) begin	
		    if( RaExecute == Rc ) begin
			if( Opc == `LOAD )
			    OverwriteData   <= dataIn;
			else
			    OverwriteData	<= ALUOut3;

			OverwriteEn		<= 2'b01;
		    end else begin
			if(ImbExecute == 1'b0 && RbExecute == Rc) begin
			    if( Opc == `LOAD )
				OverwriteData   <= dataIn;
			    else
				OverwriteData   <= ALUOut3;

			    OverwriteEn	    <= 2'b10;
			end else begin
			    OverwriteEn	<= 2'b00;
			end
		    end
		end else if(RaExecute == 4'hF) begin
		    OverwriteData   <= ALUOverflow3;
		    OverwriteEn <= 2'b01;
		end else if(RbExecute == 4'hF) begin
		    OverwriteData   <= ALUOverflow3;
		    OverwriteEn <= 2'b10;
		end else begin
		    OverwriteEn <= 2'b00;
		end
	

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
