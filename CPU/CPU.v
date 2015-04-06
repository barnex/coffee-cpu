module CPU(output reg [31:0]data, // Data is output on this bus
    input [31:0]q,	    // Data is input on this bus
    output reg [15:0]address, // Address for the RAM
    output reg wren,	    // Enable write for the RAM
    input clk,		    // What could this be? Do you have any idea? Seems irrelevant
    output reg [7:0]status, // Status indicator of the CPU
    input nreset,	    // Reset, active low, pull high to run CPU	
    input stall,	    // Puts the CPU on hold 
    input IRQ,		    // An interrupt service has been requested
    input [7:0] IRQn	    // and this is the interrupt number
    );

`define NOP    8'h0
`define LOAD   8'h1
`define STORE  8'h2
`define LOADLI 8'h3
`define LOADHI 8'h4
`define JUMPZ  8'h5

`define MOV 8'h6
`define AND 8'h7
`define OR  8'h8
`define XOR 8'h9
`define ADD 8'hA

`define LEVEL1	8'h0
`define LEVEL2	8'h1
`define LEVEL3	8'h2
`define PREFETCH_LEVEL	8'h3


reg [15:0] pc;
reg [31:0]r[7:0];
wire [31:0]command;
reg [31:0]hCommand;

reg hSelect;
reg [7:0] state;

wire [7:0]op;
wire [7:0]r1;
wire [7:0]r2;
wire [7:0]r3;
wire [15:0]addrOp;

wire [7:0]hOp, hR1, hR2, hR3;
wire [15:0]hAddrOp;

assign command = q;
assign op = command[31:24];
assign r1 = command[23:16];
assign r2 = command[15:8];
assign r3 = command[7:0];
assign addrOp = command[15:0];

assign hOp = hCommand[31:24];
assign hR1 = hCommand[23:16];
assign hR2 = hCommand[15:8];
assign hR3 = hCommand[7:0];
assign hAddrOp = hCommand[15:0];

always @(posedge clk) begin
    if( !nreset ) begin
	state <= `LEVEL1;
	pc <= 16'hFFFF;
	address <= 16'h0000;
	wren <= 1'b0;
	status <= 8'hA0;
	hSelect <= 1'b0;
    end else if( !stall ) begin
    case(state)
	`LEVEL1: begin
	    // Let know that the CPU is running as normal
	    status <= 8'h00;
	    hSelect <= 1'b0;
	    // Decode and process the current command
	    case (op)
		`LOAD: begin
		    wren <= 1'b0;
		end
		`STORE: begin
		    wren <= 1'b1;
		    data <= r[r1];
		end
		`MOV: begin
		    r[r2] <= r[r1];
		end
		`LOADLI: begin
		    r[r1] <= {r[r1][31:16], addrOp};
		end
		`LOADHI: begin 
		    r[r1] <= {addrOp, r[r1][15:0]};
		end
		`AND: begin
		    r[r3] <= r[r1] & r[r2];
		end
		`OR: begin
		    r[r3] <= r[r1] | r[r2]; 
		end
		`XOR: begin
		    r[r3] <= r[r1] ^ r[r2];
		end
		`ADD: begin
		    r[r3] <= r[r1] + r[r2];
		end
	    endcase
	    // If we are dealing with a load/store operation, alter the
	    // address to the RAM
	    if( (op == `LOAD) || (op == `STORE) ) begin
		hCommand <= q;
		address <= addrOp;
		state <= `LEVEL2;
	    // If we are dealing with a JUMPZ operation, alter the address
	    // with the correct jump value
	    end else if( op == `JUMPZ ) begin
		if( r[r1] == 8'h0 ) begin
		    pc <= pc + addrOp;
		    address <= address + addrOp;
		end else begin
		    pc <= pc + 1;
		    address <= pc + 2;
		end
	    end else begin
		pc <= pc + 1;
		address <= pc + 2;
	    end
	end
	`LEVEL2: begin
	    case(hOp)
		// If we were dealing with a LOAD LEVEL2 operation, store the
		// result
		`LOAD: begin
		    r[hR1] <= q;
		end
	    endcase
	    // Increase the program counter and address as usual and proceed to
	    pc <= pc + 1;
	    address <= pc + 2;
	    wren <= 1'b0;
	    state <= `LEVEL1;
	end
    endcase
    end
end

endmodule
