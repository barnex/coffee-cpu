module CPU(output reg [31:0]data, input [31:0]q, output reg [15:0]address, output reg wren, input clk, output reg [7:0]status);

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

`define FETCH	8'h0
`define DECODE	8'h1
`define EXECUTE	8'h2


reg [15:0] pc;
reg [31:0]r[7:0];
reg [31:0] command;

reg [7:0] state;

wire [7:0]op;
wire [7:0]r1;
wire [7:0]r2;
wire [7:0]r3;
wire [15:0]addrOp;

assign op = command[31:24];
assign r1 = command[23:16];
assign r2 = command[15:8];
assign r3 = command[7:0];
assign addrOp = command[15:0];

always @(posedge clk) begin
    case(state)
	`FETCH: begin
	    pc <= pc + 1;
	    command <= q;
	    state <= `DECODE;
	end
	`DECODE: begin
	    case (op)
		`LOAD: begin
		    address <= addrOp;
		    wren <= 1'b0;
		end
		`STORE: begin
		    address <= addrOp;
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
		`JUMPZ: begin
		    if( r[r1] == 8'h0 )
			pc <= pc + addrOp;
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
	    state <= `EXECUTE;
	end
	`EXECUTE: begin
	    case(op)
		`LOAD: begin
		    state <= `FETCH;
		    r[r1] <= q;
		end
		default: begin
		    address <= pc;
		    wren <= 1'b0;
		    state <= `FETCH;
		end
	    endcase
	end
    endcase
end

endmodule
