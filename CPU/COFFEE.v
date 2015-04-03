module COFFEE(input CLOCK_50, 
    output [9:0]LEDG, 
    output [6:0]HEX0_D, 
    output [6:0]HEX1_D,
    output [6:0]HEX2_D,
    output [6:0]HEX3_D);

wire [15:0]address;
wire [31:0]data;
wire [31:0]q;
wire [7:0]status;

wire clock;
wire wren;

assign LEDG[7:0] = status;
assign clock = CLOCK_50;

reg [6:0] Digit0;
assign HEX0_D = Digit0;

always @(negedge clock) begin
    if( address == 16'hFFFF ) begin
	Digit0 <= data[6:0];
    end
end

memory mem (
	address[12:0],
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
