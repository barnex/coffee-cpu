module COFFEE(input CLOCK_50, 
    output [9:0]LEDG, 
    output [6:0]HEX0_D, 
    output [6:0]HEX1_D,
    output [6:0]HEX2_D,
    output [6:0]HEX3_D,
    input [3:0]BUTTON);

wire [15:0]address;
wire [31:0]data;
wire [31:0]q;
wire [7:0]status;
wire clock;
wire wren;

assign LEDG[7:0] = status;
assign clock = CLOCK_50;

reg [3:0] Digit0;
reg [3:0] Digit1;
reg [3:0] Digit2;
reg [3:0] Digit3;
reg nRst;

segdriver hex0(Digit0, HEX0_D);
segdriver hex1(Digit1, HEX1_D);
segdriver hex2(Digit2, HEX2_D);
segdriver hex3(Digit3, HEX3_D);

always @(negedge clock) begin
    if( (address == 16'hFFFF) & wren ) begin
	Digit0 <= data[3:0];
	Digit1 <= data[7:4];
	Digit2 <= data[11:8];
	Digit3 <= data[15:12];
    end
    if( BUTTON[0] == 1'b0 ) begin
	nRst <= 1'b1;
    end else if( BUTTON[1] == 1'b0) begin
	nRst <= 1'b0;
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
    status,
    nRst);

endmodule
