`include "defines2.vh"
`timescale 1ns / 1ps
module alu(
	input wire[31:0] a,b,	// operation num
	input wire[4:0] op,		// alucontrol 5bit
	input wire[4:0] sa,
	input wire[63:0] div_res,	// div
	input wire[63:0] hilo_o,
	input wire[31:0] cp0data,
	output reg[31:0] y,		// out
	output reg overflow,
	// output wire zero,
	output reg[63:0] hilo_i
);

    //sub
    wire [31:0] subresult;
   	assign subresult = a + (~b + 1);

	//mux
	wire [31:0] mult1, mult2;
	wire [63:0] mul_res;
	wire [63:0] premul_res;
	assign mult1 = ((op == `MULT_CONTROL) && (a[31] == 1'b1))?(~a+1):a;// if<0 || op== `MULTU_CONTROL
	assign mult2 = ((op == `MULT_CONTROL)  && (b[31] == 1'b1))?(~b+1):b;// signed |unsigned 
	assign premul_res = mult1 * mult2;
	assign mul_res = ((op == `MULT_CONTROL) && (a[31]^b[31] == 1'b1)) ? (~premul_res+1) : premul_res; //check if<0

	always @(*) begin
		case (op)//aluop
			//logic
			`AND_CONTROL:  	begin y <= a&b; overflow<=0; end
			`OR_CONTROL:	begin y <= a|b; overflow<=0; end
			`XOR_CONTROL:	begin y <= a^b; overflow<=0; end
			`NOR_CONTROL: 	begin y <= ~(a|b); overflow<=0; end
			`LUI_CONTROL:	begin y <= {b[15:0],b[31:16]}; overflow<=0; end

        	`ADD_CONTROL:
				begin
					y <= a+b;
		        	overflow <= (y[31] && ~a[31] && ~b[31]) | (~y[31] && a[31] && b[31]);
				end
			`ADDU_CONTROL:	begin y <= a+b; overflow<=0; end
			`SUB_CONTROL:
		  		begin
		      		y <= subresult;
		      		overflow <= ((a[31] & ~b[31]) & ~y[31]) | ((~a[31] & b[31]) & y[31]);
		  		end
			`SUBU_CONTROL:	begin y<=subresult; overflow<=0; end
			`SLT_CONTROL:
				begin
					if((a[31] && b[31])||(!a[31] && !b[31])) y<=subresult[31];
					else if (a[31] && !b[31]) y<=1;
					else y<=0;
				end
			`SLTU_CONTROL:	begin y <= a<b; overflow<=0; end

			`SLL_CONTROL: 	begin y <= b<<sa; overflow<=0; end
        	`SRL_CONTROL: 	begin y <= b>>sa; overflow<=0; end
        	`SRA_CONTROL: 	begin y <= ({32{b[31]}} << (6'd32 - {1'b0,sa})) | b>>sa; overflow<=0; end
        	`SLLV_CONTROL: 	begin y <= b<<a[4:0]; overflow<=0; end
        	`SRLV_CONTROL: 	begin y <= b>>a[4:0]; overflow<=0; end
        	`SRAV_CONTROL: 	begin y <= ({32{b[31]}} << (6'd32 - {1'b0,a[4:0]})) | b>>a[4:0]; overflow<=0; end

			`MULT_CONTROL,`MULTU_CONTROL: begin hilo_i<=mul_res; overflow<=0; end
			`DIV_CONTROL,`DIVU_CONTROL:	begin hilo_i <= div_res; overflow<=0; end
			`MTHI_CONTROL:	begin hilo_i <= {a, hilo_o[31:0]}; overflow<=0; end
			`MTLO_CONTROL:	begin hilo_i <= {hilo_o[63:32],a}; overflow<=0; end
			`MFHI_CONTROL:	begin y <= hilo_o[63:32]; overflow<=0; end
			`MFLO_CONTROL:	begin y <= hilo_o[31:0]; overflow<=0; end
			
			`MTC0_CONTROL: 	begin y <= b; overflow<=0; end
        	`MFC0_CONTROL: 	begin y <= cp0data; overflow<=0; end

        	default: begin y <= 32'h00000000; overflow <= 0; end 
		endcase	
	end
	// assign zero = (y == 32'b0);

endmodule