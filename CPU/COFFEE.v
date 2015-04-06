module COFFEE(input CLOCK_50, 
    output [9:0]LEDG, 
    output [6:0]HEX0_D, 
    output [6:0]HEX1_D,
    output [6:0]HEX2_D,
    output [6:0]HEX3_D,
    input [2:0]BUTTON
);

wire [15:0]address;
wire [31:0]data;
wire [31:0]q;
wire [7:0]status;
wire wren;
wire stall;

wire cpuClk; 
wire mmuClk;

assign LEDG[7:0] = status;

reg nRst;

always @(posedge cpuClk) begin
    if( BUTTON[0] == 1'b0 ) begin
	nRst <= 1'b1;
    end else if( BUTTON[1] == 1'b0) begin
	nRst <= 1'b0;
    end
end

MMU mmu(address, data, q, wren, stall, 
    HEX0_D, HEX1_D, HEX2_D, HEX3_D,
    nRst, mmuClk);

CPU cpu(data, 
    q, 
    address,
    wren, 
    cpuClk,
    status,
    nRst,
    stall, ,
    );

masterpll mainPLL(
	CLOCK_50,
	cpuClk,
	mmuClk
	);

endmodule
