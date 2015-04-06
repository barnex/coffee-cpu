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

`define NOP	    8'h00
`define LOAD	    8'h01
`define STORE	    8'h02
`define LOADI	    8'h03
`define STORI	    8'h04
`define LOADLI	    8'h05
`define LOADHI	    8'h06
`define LOADLISE    8'h07
`define JUMPZ	    8'h08
`define JUMPNZ	    8'h09
`define JUMPLT	    8'h0A
`define JUMPGTE	    8'h0B

`define MOV	    8'h0C
`define AND	    8'h0D
`define OR	    8'h0E
`define XOR	    8'h0F
`define ADD	    8'h10
`define ADDC	    8'h11
`define SUB	    8'h12
`define MUL	    8'h13
`define DIV	    8'h14
`define SDIV	    8'h15

`define LEVEL1	8'h0
`define LEVEL2	8'h1
`define LEVEL3	8'h2
`define PREFETCH_LEVEL	8'h3


reg [15:0] pc;
reg [31:0]r[3:0];
wire [31:0]command;
reg [31:0]hCommand;
reg [15:0]hAddress;

reg hSelect;
reg [7:0] state;

wire [7:0]op;
wire [3:0]r1;
wire [3:0]r2;
wire [3:0]r3;
wire [15:0]addrOp;
wire [31:0] quotient;
wire [31:0] modulus;
wire [31:0] squotient;
wire [31:0] smodulus;
wire [63:0] mulres;
wire [32:0] addres;

wire [7:0]hOp;
wire [3:0] hR1, hR2, hR3;
wire [15:0]hAddrOp;

assign command = q;
assign op = command[31:24];
assign r1 = command[19:16];
assign r2 = command[11:8];
assign r3 = command[3:0];
assign addrOp = command[15:0];

assign hOp = hCommand[31:24];
assign hR1 = hCommand[19:16];
assign hR2 = hCommand[11:8];
assign hR3 = hCommand[3:0];
assign hAddrOp = hCommand[15:0];

uDivOp udiv(
    r[r1],
    r[r2],
    quotient,
    modulus
    );

sDivOp sdiv(
    r[r1],
    r[r2],
    squotient,
    smodulus
    );

assign mulres = r[r1] * r[r2];

assign addres = {1'b0, r[r1]} + {1'b0, r[r2]};

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
		end
		`LOADI: begin
		    wren <= 1'b0;
		end
		`STORI: begin
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
		`LOADLISE: begin
		    r[r1] <= { {16{addrOp[15]}}, addrOp};
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
		    r[r3] <= addres[31:0];
		    status[0] <= addres[32];
		end
		`ADDC: begin
		    r[r3] <= addres[31:0] + status[0];
		    status[0] <= addres[32];
		end
		`SUB: begin
		    r[r3] <= r[r1] - r[r2];
		end
		`MUL: begin
		    r[r3] <= mulres[31:0];
		    r[r3+1] <= mulres[63:32]; 
		end
		`DIV: begin
		    r[r3] <= quotient;
		    r[r3+1] <= modulus;
		end    
		`SDIV: begin
		    r[r3] <= squotient;
		    r[r3+1] <= smodulus;
		end    
	    endcase
	    // If we are dealing with a load/store operation, alter the
	    // address to the RAM
	    if( (op == `LOAD) || (op == `STORE) ) begin
		hCommand <= q;
		hAddress <= address;
		address <= r[r1+r2];
		state <= `LEVEL2;
	    end else if( (op == `LOADI) || (op == `STORI) ) begin
		hCommand <= q;
		hAddress <= address;
		address <= addrOp;
		state <= `LEVEL2;
	    // If we are dealing with a JUMPZ operation, alter the address
	    // with the correct jump value
	    end else if( op > (`JUMPZ - 1) && op < (`JUMPGTE + 1) ) begin
		case(op)
		    `JUMPZ: begin
			if( r[r1] == 8'h0 ) begin
			    pc <= pc + addrOp;
			    address <= address + addrOp;
			end else begin
			    pc <= pc + 1;
			    address <= address + 1;
			end
		    end
		    `JUMPNZ: begin
			if( r[r1] != 8'h0 ) begin
			    pc <= pc + addrOp;
			    address <= address + addrOp;
			end else begin
			    pc <= pc + 1;
			    address <= address + 1;
			end
		    end
		    `JUMPLT: begin
			if( r[r1][31] == 1'b1 ) begin
			    pc <= pc + addrOp;
			    address <= address + addrOp;
			end else begin
			    pc <= pc + 1;
			    address <= address + 1;
			end
		    end
		    `JUMPGTE: begin
			if( r[r1][31] == 1'b0 ) begin
			    pc <= pc + addrOp;
			    address <= address + addrOp;
			end else begin
			    pc <= pc + 1;
			    address <= address + 1;
			end
		    end
		endcase
	    end else begin
		pc <= pc + 1;
		address <= address + 1;
	    end
	end
	`LEVEL2: begin
	    case(hOp)
		// If we were dealing with a LOAD LEVEL2 operation, store the
		// result
		`LOAD: begin
		    r[hR3] <= q; 
		end
		`LOADI: begin
		    r[hR1] <= q;
		end
	    endcase
	    // Increase the program counter and address as usual and proceed to
	    pc <= pc + 1;
	    address <= hAddress + 1;
	    wren <= 1'b0;
	    state <= `LEVEL1;
	end
    endcase
    end
end

endmodule
