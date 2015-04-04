module VGA_gen(input VGAClk, // This is the pixel clock
    output [11:0]charAddress, // The address(row/col) of the character that needs to be rendered (hook up to char_ram read address)
    input [7:0]char,	    // The character that needs to be rendered (hook up to char_ram q)
    output vga_hsync,
    output vga_vsync,
    output reg vga_sig);

wire [11:0] fontAddress;	// The address of the row of the character that needs to be rendered (hook up to font_rom addr)
wire [7:0] fontData;
reg [9:0] CounterX; // Counts from 0 to 640, from there on Sync
reg [8:0] CounterY; // Counter from 0 to 480, from there on Sync
reg [7:0] screenRow;
reg [7:0] screenCol;
reg [3:0] charRow;
reg [4:0] charCol;
reg vga_HS, vga_VS;

font_rom rom(VGAClk, fontAddress, fontData);

wire CounterXmaxed = (CounterX==800);
wire CounterYmaxed = (CounterY==525);
assign vga_hsync = ~vga_HS;
assign vga_vsync = ~vga_VS;

always @(posedge VGAClk) begin
    if( CounterX < 640  && CounterY < 480 ) begin
	charCol <= charCol + 4'h1;

	if(CounterX == 9'h000)
	    charRow <= charRow + 5'h1;

	if(charCol == 4'h0) begin
	    if( screenCol == 80 )
		screenCol <= 0;
	    else
		screenCol <= screenCol + 1;
	end

	if(charRow == 5'h00) begin
	    if( screenRow == 10 )
		screenRow <= 0;
	    else
		screenRow <= screenRow + 1;
	end
    end else begin
	vga_sig <= 1'b0;
    end

    if(CounterXmaxed) begin
	CounterX <= 0;
	if(CounterYmaxed) begin
	    CounterY <= 0;
	end else begin
	    CounterY <= CounterY + 1;
	end
    end else begin
	CounterX <= CounterX + 1;
    end

    if( CounterX == 656 )
	vga_HS <= 1'b1;
    if( CounterX == 752 )
	vga_HS <= 1'b0;

    if( CounterY == 490 )
	vga_VS <= 1'b1;
    if( CounterY == 492 )
	vga_VS <= 1'b0;
end

endmodule

    
    
