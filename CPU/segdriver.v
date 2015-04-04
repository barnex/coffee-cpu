module segdriver(
	IN[3:0],
	OUT[6:0]
);

input [3:0]IN;
output reg [6:0]OUT;

always@(IN)
	case(IN)	
      4'h0: OUT = 7'b1000000;
      4'h1: OUT = 7'b1111001;
      4'h2: OUT = 7'b0100100;
      4'h3: OUT = 7'b0110000;
      4'h4: OUT = 7'b0011001;
      4'h5: OUT = 7'b0010010;
      4'h6: OUT = 7'b0000010;
      4'h7: OUT = 7'b1111000;
      4'h8: OUT = 7'b0000000;
      4'h9: OUT = 7'b0011000;
      4'hA: OUT = 7'b0001000;
      4'hB: OUT = 7'b0000011;
      4'hC: OUT = 7'b1000110;
      4'hD: OUT = 7'b0100001;
      4'hE: OUT = 7'b0000110;
      4'hF: OUT = 7'b0001110;
	endcase
	
endmodule