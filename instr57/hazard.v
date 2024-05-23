`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module hazard(
	//fetch stage
	output wire stallF,flushF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,jrD,jalrD,
	output wire forwardaD,forwardbD,
	output wire stallD,flushD,
	//execute stage
	input wire[4:0] rsE,rtE,rdE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	input wire hilo_readE,
	input wire cp0rE,
	input wire div_stall,
	output reg[1:0] forwardaE,forwardbE,forwardhiloE,forwardcp0E,
	output wire flushE,stallE,
	//mem stage
	input wire[4:0] writeregM,rdM,
	input wire regwriteM,
	input wire memtoregM,
	input wire hilo_writeM,
	input wire [31:0] excepttypeM,
	input wire cp0weM,
	output wire stallM,flushM,
	//write back stage
	input wire[4:0] writeregW,rdW,
	input wire regwriteW,
	input wire hilo_writeW,
	input wire cp0weW,
	output wire stallW,flushW,
	output wire flush_exceptM,
	output wire longest_stall,
	input wire i_stall,d_stall
    );

	wire lwstallD,branchstallD,jrstallD,jalrstallD;

	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding sources to E stage (ALU)
	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		forwardhiloE = 2'b00;
		forwardcp0E = 2'b00;
		if(rsE != 0) begin
			if(rsE == writeregM & regwriteM) begin
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			if(rtE == writeregM & regwriteM) begin
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				forwardbE = 2'b01;
			end
		end
		if(hilo_readE != 0) begin
			if(hilo_writeM) begin
				forwardhiloE = 2'b10;
			end else if(hilo_writeW) begin
				forwardhiloE = 2'b01;
			end
		end
		if(cp0rE != 0) begin
			if(cp0weM && rdM == rdE) begin
				forwardcp0E  = 2'b10;
			end else if(cp0weW && rdW == rdE) begin
				forwardcp0E  = 2'b01;
			end
		end
	end

	//stalls
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign branchstallD = branchD &
				(regwriteE & 
				(writeregE == rsD | writeregE == rtD) |
			    memtoregM &
				(writeregM == rsD | writeregM == rtD));
	assign jrstallD =  jrD & ((regwriteE & (writeregE == rsD)) | (memtoregM & (writeregM == rsD)));
	assign jalrstallD =  jalrD & ((regwriteE & (writeregE == rsD)) | (memtoregM & (writeregM == rsD)));
    assign longest_stall = i_stall | d_stall | div_stall;
	
	assign stallD = longest_stall | lwstallD | branchstallD | jrstallD | jalrstallD;
	assign stallF = stallD;
	assign stallE = longest_stall;
	assign stallM = longest_stall;
    assign stallW = longest_stall;
		//stalling D stalls all previous stages

	assign flushF = (|excepttypeM);
	assign flushD = (|excepttypeM);
	assign flushE = (lwstallD | branchstallD | jrstallD | jalrstallD) & ~longest_stall | (|excepttypeM); 
    assign flushM = (|excepttypeM);
	assign flushW = (|excepttypeM);
	assign flush_exceptM = (|excepttypeM);
		//stalling D flushes next stage
	// Note: not necessary to stall D stage on store
  	//       if source comes from load;
  	//       instead, another bypass network could
  	//       be added from W to M
endmodule
