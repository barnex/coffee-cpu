module CPU(output [31:0]data, input [31:0]q, output [15:0]address, output wren, input clk, output [7:0]status);

`define NOP    8'h0;
`define LOAD   8'h1;
`define STORE  8'h2;
`define LOADLI 8'h3;
`define LOADHI 8'h4;
`define JUMPZ  8'h5;

`define MOV 8'h6;
`define AND 8'h7;
`define OR  8'h8;
`define XOR 8'h9;
`define ADD 8'hA;

`define FETCH	8'h0;
`define DECODE	8'h1;
`define EXECUTE	8'h2;


reg [15:0] pc;
reg [31:0]r[7:0];
reg [31:0] command;

reg [7:0] state;

wire [31:0]command;
wire [7:0]op;
wire [7:0]r1;
wire [7:0]r2;
wire [7:0]r3;
wire [15:0]addr;

assign op = command[31:24];
assign r1 = command[23:16];
assign r2 = command[15:8];
assign r3 = command[7:0];
assign addrOp = command[15:0];

always @(posedge clk) begin
    case(state)
	`FETCH: begin
	    command <= q;
	    state <= `DECODE;
	end
	`DECODE: begin
	    state <= `FETCH;
	    case (op)
		`LOAD: begin
		    address <= addrOp;
		    wren <= 1'b0;
		    state <= `LOAD1;
		end
		`STORE: begin
		    address <= addrOp;
		    wren <= 1'b1;
		    data <= r[r1];
		end
		`MOV: r2 <= r1;
		`LOADLI: r1 <= {r1[31:16], addr};
		`LOADHI: r1 <= {addr, r1[15:0]};
		default: ;
	    endcase
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

endmodule;
