module VGA_gen(input VGAClk, // This is the pixel clock
    output [11:0]charAddress, // The address(row/col) of the character that needs to be rendered (hook up to char_ram read address)
    input [7:0]char,	    // The character that needs to be rendered (hook up to char_ram q)
    output vga_hsync,
    output vga_vsync,
    output vga_sig);


reg [11:0] fontAddress;	// The address of the row of the character that needs to be rendered (hook up to font_rom addr)
reg [9:0] CounterX;
reg [8:0] CounterY;
reg vga_HS, vga_VS;

wire CounterXmaxed = (CounterX==767);
assign vga_hsync = ~vga_HS;
assign vga_vsync = ~vga_VS;
assign vga_sig = CounterY[3] | (CounterX==256);

always @(posedge VGAClk) begin
    if(CounterXmaxed) begin
	CounterX <= 0;
	CounterY <= CounterY + 1;
    end else begin
	CounterX <= CounterX + 1;
    end
    vga_HS <= (CounterX[9:4]==0);   // active for 16 clocks
    vga_VS <= (CounterY==0);   // active for 768 clocks
end

endmodule

    
    
