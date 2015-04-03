module CPU(output data[15:0], input q[15:0], output wren, input clk, output [7:0]status);

`define NOP 8h0;
`define LOAD 8h1;
`define STORE 8h2;
`define MOV 8h3;


reg [15:0] pc;
reg [31:0]r[7:0];
wire [31:0]command;
wire [7:0]op;
wire [7:0]r1;
wire [7:0]r2;
wire [7:0]r3;
wire [15:0]addr;

assign op = memory[pc][31:24];
assign r1 = memory[pc][23:16];
assign r2 = memory[pc][15:8];
assign r3 = memory[pc][7:0];
assign addr = memory[pc][15:0];

always @(posedge clk) begin
    case (op)
	`LOAD: r1 <= memory[addr];
	`STORE: memory[addr] <= r1;
	`MOV: r2 <= r1;
	`LOADLI: r1 <= {r1[31:16], addr};
	`LOADHI: r1 <= {addr, r1[15:0]};
	default: ;
    endcase
    if( op == `JMPIFZERO ) begin
	pc <= pc + r1[15:0];				
    end else begin
	pc <= pc + 16'h01;
    end
end

endmodule;
