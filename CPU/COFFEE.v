module COFFEE(input CLK50, 
    output LEDG[9:0], 
    output HEX0_D[6:0], 
    output HEX1_D[6:0],
    output HEX2_D[6:0],
    output HEX3_D[6:0]);

wire [15:0]address;
wire [31:0]data;
wire [31:0]q;
wire [7:0]status;

wire clock;
wire wren;

assign LEDG[7:0] = status;

memory mem (
	{1'b0, address[14:0]},
	!clock,
	data,
	wren,
	q);

CPU cpu(data, 
    q, 
    address,
    wren, 
    clock,
    status);

endmodule
