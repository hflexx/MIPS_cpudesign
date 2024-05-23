`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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

module mips(
	input wire clk,rst,
	input [5:0] ext_int,
	//inst sram-like 
    output         inst_req     ,
    output         inst_wr      ,
    output  [1 :0] inst_size    ,
    output  [31:0] inst_addr    ,
    output  [31:0] inst_wdata   ,
    input   [31:0] inst_rdata   ,
    input          inst_addr_ok ,
    input          inst_data_ok ,
    //data sram-like 
    output         data_req     ,
    output         data_wr      ,
    output  [1 :0] data_size    ,
    output  [31:0] data_addr    ,
    output  [31:0] data_wdata   ,
    input   [31:0] data_rdata   ,
    input          data_addr_ok ,
    input          data_data_ok ,
	//debug signals
	output [31:0] debug_wb_pc      ,
	output [3 :0] debug_wb_rf_wen  ,
	output [4 :0] debug_wb_rf_wnum ,
	output [31:0] debug_wb_rf_wdata
    );
    wire pc_error;
	wire [31:0] instrD;
	wire branchD,balD,jumpD,jalD,jrD,jalrD,eretD,syscallD,breakD,invalidD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW;
	wire regwriteE,regwriteM,regwriteW;
	wire [4:0] alucontrolE,alucontrolD;
	wire flushE,equalD;
	wire hilo_readE,hilo_writeE,hilo_writeM,hilo_writeW,cp0rE;
	wire stallD,stallE,stallM,stallW;
	wire cp0weM,cp0weW;
    wire flushM,flushW;
	wire flush_except,memenM;
	wire [31:0] pcF,aluoutM;
	wire [31:0] instrF,writedataM,readdataM;
	wire [3:0] selM;
	wire i_stall,d_stall,longest_stall;
	
	controller c(
        .clk(clk), .rst(rst),
        // Decode stage
        .instrD(instrD),
        .pcsrcD(pcsrcD),
        .equalD(equalD),.branchD(branchD),
        .jumpD(jumpD),.jrD(jrD),.jalD(jalD),.jalrD(jalrD),.balD(balD),
	    .alucontrolD(alucontrolD),
	    .eretD(eretD),.syscallD(syscallD),.breakD(breakD),.invalidD(invalidD),
        .stallD(stallD),
        // Execute stage
        .memtoregE(memtoregE),.regdstE(regdstE),.alusrcE(alusrcE),
        .regwriteE(regwriteE),
        .alucontrolE(alucontrolE),
	    .hilo_writeE(hilo_writeE),.hilo_readE(hilo_readE),
        .cp0rE(cp0rE),
        .stallE(stallE),
	    .flushE(flushE),
        // Mem stage
        .memtoregM(memtoregM),.regwriteM(regwriteM),
        .memenM(memenM),
	    .hilo_writeM(hilo_writeM),
	    .cp0weM(cp0weM),
        .flush_except(flush_except),
	    .stallM(stallM),
	    .flushM(flushM),
        // Write back stage
        .memtoregW(memtoregW),.regwriteW(regwriteW),
	    .hilo_writeW(hilo_writeW),
	    .cp0weW(cp0weW),
	    .stallW(stallW),
	    .flushW(flushW)
	);

	datapath dp(
        .clk(clk),.rst(rst),.ext_int(ext_int),
	    .i_stall(i_stall),.d_stall(d_stall),.longest_stall(longest_stall),
        // Fetch stage
        .pcF(pcF),
        .pc_error(pc_error),
        .instrF(instrF),
        // Decode stage
        .pcsrcD(pcsrcD),
        .instrD(instrD),
        .alucontrolD(alucontrolD),
        .equalD(equalD),.branchD(branchD),
        .jumpD(jumpD),.jrD(jrD),.jalD(jalD),.jalrD(jalrD),.balD(balD),
	    .eretD(eretD),.syscallD(syscallD),.breakD(breakD),.invalidD(invalidD),
        .stallD(stallD),
        // Execute stage
        .memtoregE(memtoregE),.regdstE(regdstE),.regwriteE(regwriteE),
        .alusrcE(alusrcE),.alucontrolE(alucontrolE),
	    .hilo_readE(hilo_readE),
        .cp0rE(cp0rE),
	    .stallE(stallE),
	    .flushE(flushE),
        // Mem stage
        .memtoregM(memtoregM),.regwriteM(regwriteM),
        .aluoutM(aluoutM),
        .writedata2M(writedataM),.readdataM(readdataM),
        .selM(selM),
        .hilo_writeM(hilo_writeM),
	    .cp0weM(cp0weM),
	    .stallM(stallM),
	    .flushM(flushM),
	    .flush_exceptM(flush_except),
        // Writeback stage
        .memtoregW(memtoregW),.regwriteW(regwriteW),
	    .hilo_writeW(hilo_writeW),
	    .cp0weW(cp0weW),
	    .stallW(stallW),
	    .flushW(flushW),
	    // Debug output
	    .pcW(debug_wb_pc),
	    .rf_wen(debug_wb_rf_wen),
	    .writeregW(debug_wb_rf_wnum),
	    .resultW(debug_wb_rf_wdata)
	);

	wire inst_sram_en;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_rdata;
    wire data_sram_en;
	wire [3:0] data_sram_wen;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
	wire [31:0] data_sram_rdata;

    assign inst_sram_addr= pcF;
	assign inst_sram_en = ~pc_error & ~flush_except;
    assign instrF = inst_sram_rdata;
    assign data_sram_en = memenM & ~flush_except;
	assign data_sram_wen = selM;
    assign data_sram_wdata = writedataM;
	assign readdataM = data_sram_rdata;
	assign data_sram_addr = aluoutM;

	//inst sram to sram-like
    i_sram_to_sram_like i_sram_to_sram_like(
        .clk(clk), .rst(rst),
        .i_stall          (i_stall        ),
		.longest_stall    (longest_stall  ),
        //sram
		.inst_sram_en     (inst_sram_en   ),
      //.inst_sram_wen    ( 4'b0          ),
    	.inst_sram_addr   (inst_sram_addr ),
 	  //.inst_sram_wdata  ( 32'b0         ),
    	.inst_sram_rdata  (inst_sram_rdata),
        //sram like
        .inst_req       (inst_req    ),
        .inst_wr        (inst_wr     ),
        .inst_size      (inst_size   ),
        .inst_addr      (inst_addr   ),
        .inst_wdata     (inst_wdata  ),
        .inst_rdata     (inst_rdata  ),
        .inst_addr_ok   (inst_addr_ok),
        .inst_data_ok   (inst_data_ok)
    );

    //data sram to sram-like
    d_sram_to_sram_like d_sram_to_sram_like(
        .clk(clk), .rst(rst),
        .d_stall          (d_stall        ),
		.longest_stall    (longest_stall  ),
        //sram
		.data_sram_en     (data_sram_en   ),
    	.data_sram_wen    (data_sram_wen  ),
    	.data_sram_addr   (data_sram_addr ),
    	.data_sram_wdata  (data_sram_wdata),
    	.data_sram_rdata  (data_sram_rdata),
        //sram like
        .data_req       (data_req    ),
        .data_wr        (data_wr     ),
        .data_size      (data_size   ),
        .data_addr      (data_addr   ),
        .data_wdata     (data_wdata  ),
        .data_rdata     (data_rdata  ),
        .data_addr_ok   (data_addr_ok),
        .data_data_ok   (data_data_ok)
    );
	
endmodule
