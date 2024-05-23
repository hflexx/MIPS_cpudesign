`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[31:0] instrD,
	input wire equalD,
	output wire pcsrcD,branchD,jumpD,balD,jrD,jalD,jalrD,
	output wire eretD,syscallD,breakD,invalidD,
	input wire stallD,
	output wire[4:0] alucontrolD,
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,regdstE,regwriteE,
	output wire hilo_writeE,hilo_readE,cp0rE,
	output wire[4:0] alucontrolE,
	//mem stage
	input wire stallM,flushM,
	input wire flush_except,
	output wire memtoregM,regwriteM,memenM,
	output wire hilo_writeM,cp0weM,
	//write back stage
	input wire stallW,flushW,
	output wire memtoregW,regwriteW,
	output wire hilo_writeW,cp0weW
);
	
	//decode stage
	wire[3:0] aluopD;
	wire [5:0] functD;
	wire hilo_writeD,hilo_readD,cp0weD,cp0rD;
	wire memtoregD,alusrcD, regdstD,regwriteD,memenD;
	//execute stage
	wire memenE,cp0weE;

	assign functD = instrD[5:0];
	assign pcsrcD = branchD & equalD;

	maindec md(
		.instr(instrD),
		.memtoreg(memtoregD),
		.alusrc(alusrcD),
		.regdst(regdstD),
		.regwrite(regwriteD),
		.branch(branchD),.bal(balD),
		.jump(jumpD),.jr(jrD),.jal(jalD),.jalr(jalrD),
		.aluop(aluopD),
		.memen(memenD),
		.hilo_write(hilo_writeD),.hilo_read(hilo_readD),
		.stallD(stallD),
		.cp0we(cp0weD),.cp0r(cp0rD),
		.eret(eretD),.syscall(syscallD),.break(breakD),.invalid(invalidD)
	);

	aludec ad(
    	.funct(functD),
    	.aluop(aluopD),
    	.alucontrol(alucontrolD)
	);

  	flopenrc #( .WIDTH(14) ) regE(
    	.clk(clk),
    	.rst(rst),
		.en(~stallE | flush_except),
    	.clear(flushE),
    	.d({memtoregD, alusrcD, regdstD, regwriteD, hilo_writeD,hilo_readD, alucontrolD, memenD, cp0rD,cp0weD}),
    	.q({memtoregE, alusrcE, regdstE, regwriteE, hilo_writeE,hilo_readE, alucontrolE, memenE, cp0rE,cp0weE})
	);

	flopenrc #( .WIDTH(5) ) regM(
		.clk(clk),
		.rst(rst),
		.en(~stallM | flush_except),
		.clear(flushM),
		.d({memtoregE, regwriteE, hilo_writeE, memenE, cp0weE}),
		.q({memtoregM, regwriteM, hilo_writeM, memenM, cp0weM})
	);

	flopenrc #( .WIDTH(4) ) regW(
		.clk(clk),
		.rst(rst),
		.en(~stallW | flush_except),
		.clear(flushW),
		.d({memtoregM, regwriteM, hilo_writeM, cp0weM}),
		.q({memtoregW, regwriteW, hilo_writeW, cp0weW})
	);

endmodule
