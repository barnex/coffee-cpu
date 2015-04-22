module CPU(
    output	[31:0]dataOut,
    input	[31:0]dataIn,
    output reg	dataWrEn,
    output	[13:0]dataAddress,
    input	[31:0]instructionIn,
    output wire [11:0]instructionAddress,
    output reg	[7:0]cpuStatus,
    input nRst,
    input clk,
    input stall,
    input IRQ,
    input [11:0]IRQn,
    output reg IRQAck);

`default_nettype none

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
reg [31:0] overrideA;
reg [31:0] overrideB;
reg [1:0] overrideEn;
wire stallReq;
wire pcIncEn;

// Decode/demux of the instruction 
wire [31:0] instructionWriteBack;
wire Imb;
wire [3:0]Ra;
wire [3:0]Rb;
wire [13:0]Imm;
wire [4:0]Opc;
wire [3:0]Rc /* synthesis keep */;
wire [2:0]Cond;
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

wire [3:0] RaDecode, RbDecode;
wire ImbDecode;
assign RaDecode	    = instructionDecode[30:27];
assign RbDecode	    = instructionDecode[26:23];
assign ImbDecode    = instructionDecode[31];

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
reg writeBackEnable /* synthesis keep */;
// The overflow register, for DIV and MUL
reg [31:0] overflow;
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
    overrideA, overrideB, overrideEn,
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

/*
 * STALL DETERMINATION MANAGER (is a stall required because of override?)
 */
always_comb begin
    if( Cmp == 1'b1 ) begin
	stallReq = 1'b1;
    // A load or ALU operation with WB has taken place
    end else if( writeBackEnable == 1'b1 || Opc == `LOAD ) begin
	// Source and destination match (A)
	if( RaExecute == Rc )
	    stallReq = 1'b1;
	// Source and destination match (B)
	else if( ImbExecute == 1'b0 && RbExecute == Rc )
	    stallReq = 1'b1;
	// Source and destination match (A)
	else if( RaDecode == Rc )
	    stallReq = 1'b1;
	// Source and destination match (B)
	else if( ImbDecode == 1'b0 && RbDecode == Rc )
	    stallReq = 1'b1;
	// ALU Status has been updated
	else if( Cmp == 1'b1 )
	    stallReq = 1'b1;
	// overflow register is required
	else if( RaExecute == 4'hF || RbExecute == 4'hF)
	    stallReq = 1'b1;
	else
	    stallReq = 1'b0;
    end else begin
	// No WB takes place, but the overflow register is still required
	if( (RaExecute == 4'hF || RbExecute == 4'hF) && (Opc != 0))
	    stallReq = 1'b1;
	else
	    stallReq = 1'b0;
    end
end

/*
 * PC INCREASE MANAGER ( PC + 1 allowed? )
 */
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
	if(OpcExecute == `STORE && (!stallReq) && (state != `FLUSH) )// && state == `EXECUTE)
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
	overrideEn  <= 2'b00;
	IRQAck	    <= 1'b0;
    end else if( !stall && !IRQ ) begin
	case(state)
	    `FETCH: begin
		IRQAck	    <= 1'b0;
		rst	    <= 1'b0;
		cpuStatus   <= 8'h01;

		/*
		 * STATUS UPDATE MANAGER
		 */
		// If the Cmp bit is set, we update that ALU status register
		if( Cmp == 1'b1 ) begin
		    ALUStatus <= ALUStatusOut3;
		end

		/*
		 * WRITEBACK OPERATION MANAGER
		 */

		// LOAD operations are always written
		if( Opc == `LOAD ) begin
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
		// Before writing anything away, we have to check we are not
		// dealing with a NOP
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

		// Only write to the overflow register, if an ALU operation
		// has been performed, and the target designation is not the
		// overflow register
		if( Opc != `LOAD && Rc != 4'hF ) begin
		    overflow	<= ALUOverflow3;
		end

		if( pcIncEn == 1'b1 )
		    pc	<= pc + 12'h1;

		/*
		 * PIPELINE FLUSH MANAGER
		 */

		// If we wrote anything to the PC, we need to flush the
		// pipeline
		if(Rc == 4'hE && ((Opc == `LOAD) || (writeBackEnable == 1'b1))) begin
		    state   <= `FLUSH;	
		    overrideEn	<= 2'b0;
		    rst	    <= 1'b1;
		end else
		    state <= `FETCH;

		/*
		 * PIPELINE HAZARD MANAGER
		 */
		// Check for branches
		if( !(Rc == 4'hE && writeBackEnable == 1'b1) ) begin
		    // This piece checks for Ra == Rc, with Rc being overwritten (ALU op)
		    if( writeBackEnable == 1'b1 && Opc != 5'h0 && RaExecute == Rc ) begin
			overrideA	<= ALUOut3;
			overrideEn[0]   <= 1'b1;	
		    // This piece checks for Ra == Rc, with Rc being overwritten (LOAD op)
		    end else if( Opc == `LOAD && RaExecute == Rc ) begin
			overrideA	<= dataIn;
			overrideEn[0]   <= 1'b1;
		    // This piece checks for Ra == overflow, and Rc != overflow
		    end else if( Opc != 5'h0 && RaExecute == 4'hF) begin
			overrideA	<= ALUOverflow3;
			overrideEn[0]   <= 1'b1;
		    // If not of the above...
		    end else begin
			overrideEn[0]   <= 1'b0;
		    end

		    /*
		     * Ditto for B
		     */
		    if( writeBackEnable == 1'b1 && Opc != 5'h0 && RbExecute == Rc ) begin
			overrideB	<= ALUOut3;
			overrideEn[1]   <= 1'b1;	
		    end else if( Opc == `LOAD && RbExecute == Rc ) begin
			overrideB	<= dataIn;
			overrideEn[1]   <= 1'b1;
		    end else if( Opc != 5'h0 && RbExecute == 4'hF) begin
			overrideB	<= ALUOverflow3;
			overrideEn[1]   <= 1'b1;
		    end else begin
			overrideEn[1]   <= 1'b0;
		    end
		end else begin
		    overrideEn		<= 2'b0;
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
    end else if( IRQ ) begin
	if( IRQAck == 1'b0 ) begin
	    overflow    <= pc - 12'h2; 
	    pc		<= IRQn;
	end
	IRQAck <= 1'b1;
    end
end

endmodule
