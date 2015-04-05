module COFFEE(input CLOCK_50, 
    output [9:0]LEDG, 
    output [6:0]HEX0_D, 
    output [6:0]HEX1_D,
    output [6:0]HEX2_D,
    output [6:0]HEX3_D,
    input [2:0]BUTTON,
    output [3:0]VGA_R, output [3:0]VGA_G, output [3:1]VGA_B, output VGA_VS, output VGA_HS
);

reg [26:0] prescaler;

wire [15:0]address;
wire [11:0]charAddress;
wire [7:0] charQ;
wire [31:0]data;
wire [31:0]q;
wire [7:0]status;
reg clock;
//wire clock;
//assign clock = CLOCK_50;
wire wren;
wire wrenCharRam;
wire vgaClk;
wire vgaSig;

assign LEDG[7:0] = status;

assign wrenCharRam = (address[15:12] == 4'hE);
assign VGA_R = {vgaSig, vgaSig, vgaSig, vgaSig};
assign VGA_G = {vgaSig, vgaSig, vgaSig, vgaSig};
assign VGA_B = {vgaSig, vgaSig, vgaSig};

reg [3:0] Digit0;
reg [3:0] Digit1;
reg [3:0] Digit2;
reg [3:0] Digit3;
reg nRst;

segdriver hex0(Digit0, HEX0_D);
segdriver hex1(Digit1, HEX1_D);
segdriver hex2(Digit2, HEX2_D);
segdriver hex3(Digit3, HEX3_D);
always @(posedge CLOCK_50) begin
    if(prescaler == 3) begin
	prescaler <= 0;
	clock <= ~clock;
    end else
	prescaler <= prescaler + 1;
end

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

VGA_gen vga_out(vgaClk, charAddress, charQ, VGA_HS, VGA_VS, vgaSig);

memory mem (
	address[12:0],
	!clock,
	data,
	wren,
	q);

char_ram ram(
	data[7:0],
	charAddress,
	!vgaClk,
	address[11:0],
	!clock,
	wrenCharRam,
	charQ);

CPU cpu(data, 
    q, 
    address,
    wren, 
    clock,
    status,
    nRst);

masterpll mainPLL(
	,
	CLOCK_50,
	,
	vgaClk,
	);

endmodule
