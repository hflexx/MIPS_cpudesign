`timescale 1ns / 1ps

module datapath(
	input wire clk,rst,
	input [5:0] ext_int,
	//fetch stage
	output wire[31:0] pcF,
	output wire pc_error,
	input wire[31:0] instrF,
	//decode stage
	input wire pcsrcD,
	input wire branchD,balD,
	input wire jumpD,jrD,jalD,jalrD,
	input wire[4:0] alucontrolD,
	input wire eretD,syscallD,breakD,invalidD,
	output wire equalD,stallD,
	output wire [31:0] instrD,
	//execute stage
	input wire memtoregE,alusrcE,regdstE,regwriteE,
	input wire[4:0] alucontrolE,
	input wire hilo_readE,
	input wire cp0rE,
	output wire flushE,stallE,
	//mem stage
	input wire memtoregM,regwriteM,
	output wire[31:0] aluoutM,writedata2M,
	input wire[31:0] readdataM,
	output wire[3:0] selM,
	input wire hilo_writeM,
	input wire cp0weM,
	output wire flush_exceptM,
	output wire stallM,flushM,
	//writeback stage
	input wire memtoregW,regwriteW,
	input wire hilo_writeW,
	input wire cp0weW,
	output wire stallW,flushW,
	//debug
	output wire[31:0] pcW,
	output wire[3:0] rf_wen,
	output wire[4:0] writeregW,
	output wire[31:0] resultW,
	input wire i_stall,d_stall,
	output wire longest_stall//new
    );
	
	//fetch stage
	wire stallF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD,pcnext2FD,pcplus8F;
	wire flushF;//for except
	wire is_in_delayslotF; //for cp0
	wire [7:0] exceptF;
	//decode stage
	wire[5:0] opD,functD;
	wire jbalD;
	wire [1:0] typeD;
	wire [31:0] pcplus4D,pcplus8D;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rdD,rtD,saD;
	wire flushD;
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D,pcD;
	wire is_in_delayslotD;
	wire [7:0] exceptD;
	//execute stage
	wire jbalE,jalrE;
	wire [1:0] forwardaE,forwardbE,forwardhiloE,forwardcp0E;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [5:0] opE;
	wire [4:0] writeregE,writereg2E;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE,aluout2E,pcE;
	wire [63:0] hilo_iE, hilo_oE;
	wire [31:0] pcplus8E;
	wire is_in_delayslotE;
	wire [31:0] cp0dataE, cp0data2E;
	wire [7:0] exceptE;
	wire overflowE;//zeroE

	//mem stage
	wire [4:0] writeregM;
	wire [63:0] hilo_iM;
	wire [5:0] opM;
	wire [31:0] writedataM,readdata2M;
	wire [31:0] pcM,newpcM;
	wire [7:0] exceptM;
	wire adelM,adesM;
	wire [31:0] bad_addrM,excepttypeM;
	wire [4:0] rdM;
	//writeback stage
	wire [31:0] aluoutW,readdataW;
	wire [63:0] hilo_iW, hilo_oW;
	wire [4:0] rdW;
	wire flush_exceptW;
	wire is_in_delayslotM;
	wire[31:0] count_oW,compare_oW,status_oW,cause_oW,epc_oW,config_oW,prid_oW,badvaddrW;
	//div
	wire div_ready,div_stall,div_start,div_signed;
	wire[63:0] div_out;

	hazard h(
		// Fetch stage
		.stallF(stallF),.flushF(flushF),
		// Decode stage
		.rsD(rsD),
		.rtD(rtD),
		.branchD(branchD),
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
		.stallD(stallD),.flushD(flushD),
		.jrD(jrD),
		.jalrD(jalrD),
		// Execute stage
		.rsE(rsE),
		.rtE(rtE),
		.rdE(rdE),
		.writeregE(writeregE),
		.regwriteE(regwriteE),
		.memtoregE(memtoregE),
		.hilo_readE(hilo_readE),
		.cp0rE(cp0rE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.forwardhiloE(forwardhiloE),
		.forwardcp0E(forwardcp0E),
		.flushE(flushE),.stallE(stallE),
		.div_stall(div_stall & ~flush_exceptM),
		// Mem stage
		.writeregM(writeregM),.rdM(rdM),
		.regwriteM(regwriteM),
		.memtoregM(memtoregM),
		.hilo_writeM(hilo_writeM),
		.excepttypeM(excepttypeM),
		.cp0weM(cp0weM),
		.stallM(stallM),
		.flushM(flushM),
		.flush_exceptM(flush_exceptM),
		// Writeback stage
		.writeregW(writeregW),
		.regwriteW(regwriteW),.rdW(rdW),
		.hilo_writeW(hilo_writeW),
		.cp0weW(cp0weW),
		.stallW(stallW),
		.flushW(flushW),
		.i_stall(i_stall),
    	.d_stall(d_stall),
		.longest_stall(longest_stall)
	);


	//next PC logic (operates in fetch an decode)
	mux2 #( 32 ) pcbrmux(
    	.d0(pcplus4F),
    	.d1(pcbranchD),
    	.s(pcsrcD),
    	.y(pcnextbrFD)
	);

	mux2 #( .WIDTH(32) ) pcmux(
    	.d0(pcnextbrFD),
    	.d1({pcplus4D[31:28], instrD[25:0], 2'b00}),
    	.s(jumpD|jalD),
    	.y(pcnextFD)
	);

	mux2 #( .WIDTH(32) ) pcmux2(
    	.d0(pcnextFD),
    	.d1(srca2D),
		.s(jrD|jalrD),
    	.y(pcnext2FD)
	);


	//regfile (operates in decode and writeback)
	regfile rf(
		.clk(clk),
		.we3(regwriteW & ~flush_exceptW),
		.stallW(stallW),
		.rst(rst),
		.ra1(rsD),
		.ra2(rtD),
		.wa3(writeregW),
		.wd3(resultW),
		.rd1(srcaD),
		.rd2(srcbD)
	);

	//fetch stage logic
    pcflopenr #(32) pcreg(
		.clk(clk),
		.rst(rst),
		.en((~stallF & ~longest_stall) | flush_exceptM),
    	.flush(flushF),
		.d(pcnext2FD),
		.newpc(newpcM), //newpcM is exeception define
		.q(pcF)
	);

	adder pcadd1(
    	.a(pcF),
    	.b(32'b100),
    	.y(pcplus4F)
	);
		
	adder pcadd2(
    	.a(pcF),
    	.b(32'b1000),
    	.y(pcplus8F)
	);

    //excpet:keep,adel,ades,sys,bp,eret,ri,ov
    assign pc_error = (pcF[1:0] == 2'b00)?1'b0:1'b1;
    assign exceptF = (pcF[1:0] == 2'b00)? 8'b00000000 : 8'b01000000; //pc wrong
    assign is_in_delayslotF = (jumpD|jalD|jalrD|jrD|balD|branchD); //is exceptions in delayslot
	
	//decode stage
	flopenrc #( .WIDTH(32) ) r1D(
		.clk(clk),
		.rst(rst),
		.en(~stallD),
		.clear(flushD),
		.d(pcplus4F),
		.q(pcplus4D)
	);
	flopenrc #( .WIDTH(32) ) r2D(
		.clk(clk),
		.rst(rst),
		.en(~stallD),
		.clear(flushD),
		.d(instrF),
		.q(instrD)
	);
	flopenrc #( .WIDTH(32) ) r3D(
		.clk(clk),
		.rst(rst),
		.en(~stallD),
		.clear(flushD),
		.d(pcplus8F),
		.q(pcplus8D)
	);
	flopenrc #( .WIDTH(32) ) r4D(
		.clk(clk),
		.rst(rst),
		.en(~stallD),
		.clear(flushD),
		.d(exceptF),
		.q(exceptD)
	);
	flopenrc #( .WIDTH(1) ) r5D(
		.clk(clk),
		.rst(rst),
		.en(~stallD),
		.clear(flushD),
		.d(is_in_delayslotF),
		.q(is_in_delayslotD)
	);
	flopenrc #( .WIDTH(32) ) r6D(
		.clk(clk),
		.rst(rst),
		.en(~stallD),
		.clear(flushD),
		.d(pcF),
		.q(pcD)
	);

	signext se(
		.a(instrD[15:0]),
		.type(typeD),
		.y(signimmD)
	);
	sl2 immsh(
		.a(signimmD),
		.y(signimmshD)
	);
	adder pcadd3(
		.a(pcplus4D),
		.b(signimmshD),
		.y(pcbranchD)
	);

	mux2 #( .WIDTH(32) ) forwardamux(
		.d0(srcaD),
		.d1(aluoutM),
		.s(forwardaD),
		.y(srca2D)
	);
	mux2 #( .WIDTH(32) ) forwardbmux(
		.d0(srcbD),
		.d1(aluoutM),
		.s(forwardbD),
		.y(srcb2D)
	);

	eqcmp comp(
		.a(srca2D),
		.b(srcb2D),
		.op(opD),
		.rt(rtD),
		.y(equalD)
	);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign typeD = instrD[29:28];
	assign saD = instrD[10:6];
	assign jbalD = jalD|balD;

	//execute stage
    flopenrc #( .WIDTH(32) ) r1E(
        .clk(clk),
        .rst(rst),
        .en(~stallE),
        .clear(flushE),
        .d(srcaD),
        .q(srcaE)
    );
	flopenrc #( .WIDTH(32) ) r2E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(srcbD),
		.q(srcbE)
	);
	flopenrc #( .WIDTH(32) ) r3E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(signimmD),
		.q(signimmE)
	);
	flopenrc #( .WIDTH(5) ) r4E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(rsD),
		.q(rsE)
	);
	flopenrc #( .WIDTH(5) ) r5E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(rtD),
		.q(rtE)
	);
	flopenrc #( .WIDTH(5) ) r6E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(rdD),
		.q(rdE)
	);
	flopenrc #( .WIDTH(5) ) r7E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(saD),
		.q(saE)
	);
	flopenrc #( .WIDTH(6) ) r8E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(opD),
		.q(opE)
	);
	flopenrc #( .WIDTH(1) ) r9E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(jbalD),
		.q(jbalE)
	);
	flopenrc #( .WIDTH(32) ) r10E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(pcplus8D),
		.q(pcplus8E)
	);
	flopenrc #( .WIDTH(1) ) r11E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(jalrD),
		.q(jalrE)
	);
	flopenrc #( .WIDTH(8) ) r12E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d({exceptD[7:5],syscallD,breakD,eretD,invalidD,exceptD[0]}),
		.q(exceptE)
	);
	flopenrc #( .WIDTH(1) ) r13E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(is_in_delayslotD),
		.q(is_in_delayslotE)
	);
	flopenrc #( .WIDTH(32) ) r14E(
		.clk(clk),
		.rst(rst),
		.en(~stallE),
		.clear(flushE),
		.d(pcD),
		.q(pcE)
	);

	mux3 #( .WIDTH(32) ) forwardaemux(
    	.d0(srcaE),
    	.d1(resultW),
    	.d2(aluoutM),
    	.s(forwardaE),
    	.y(srca2E)
	);
	mux3 #( .WIDTH(32) ) forwardbemux(
    	.d0(srcbE),
    	.d1(resultW),
    	.d2(aluoutM),
    	.s(forwardbE),
    	.y(srcb2E)
	);
	mux2 #( .WIDTH(32) ) srcbmux(
    	.d0(srcb2E),
    	.d1(signimmE),
    	.s(alusrcE),
    	.y(srcb3E)
	);

	mux3 #( .WIDTH(64) ) forwardhilomux(
    	.d0(hilo_oW),
    	.d1(hilo_iW),
    	.d2(hilo_iM),
    	.s(forwardhiloE),
    	.y(hilo_oE)
	);
	mux3 #( .WIDTH(32) ) forwardcp0mux(
    	.d0(cp0dataE),
    	.d1(aluoutW),
    	.d2(aluoutM),
    	.s(forwardcp0E),
    	.y(cp0data2E)
	);

	alu alu(
    	.a(srca2E),
    	.b(srcb3E),
    	.op(alucontrolE),
    	.sa(saE),
		.hilo_o(hilo_oE),
		.hilo_i(hilo_iE),
		.cp0data(cp0data2E),
    	.y(aluoutE),
		.div_res(div_out),
		.overflow(overflowE)
		//.zero(zeroE)
	);

	mux2 #( .WIDTH(5) ) wrmux(
    	.d0(rtE),
    	.d1(rdE),
    	.s(regdstE),
    	.y(writeregE)
	);
	mux2 #( .WIDTH(5) ) wrmux2(
    	.d0(writeregE),
    	.d1(5'b11111),
    	.s(jbalE),
    	.y(writereg2E)
	);
	mux2 #( .WIDTH(32) ) wrmux3(
    	.d0(aluoutE),
    	.d1(pcplus8E),
    	.s(jbalE|jalrE),
    	.y(aluout2E)
	);

	//mem stage
	flopenrc #( .WIDTH(32) ) r1M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(srcb2E),
		.q(writedataM)
	);
	flopenrc #( .WIDTH(32) ) r2M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(aluout2E),
		.q(aluoutM)
	);
	flopenrc #( .WIDTH(5) ) r3M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(writereg2E),
		.q(writeregM)
	);
	flopenrc #( .WIDTH(6) ) r4M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(opE),
		.q(opM)
	);
	flopenrc #( .WIDTH(64) ) r5M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(hilo_iE),
		.q(hilo_iM)
	);
	flopenrc #( .WIDTH(8) ) r6M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d({exceptE[7:1],overflowE}),
		.q(exceptM)
	);
	flopenrc #( .WIDTH(5) ) r7M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(rdE),
		.q(rdM)
	);
	flopenrc #( .WIDTH(32) ) r8M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(pcE),
		.q(pcM)
	);
	flopenrc #( .WIDTH(1) ) r9M(
		.clk(clk),
		.rst(rst),
		.en(~stallM),
		.clear(flushM),
		.d(is_in_delayslotE),
		.q(is_in_delayslotM)
	);

	sel datasel(
		.op(opM),
		.addr(aluoutM[1:0]),
		.writedata(writedataM),.readdata(readdataM),
		.sel(selM),
		.writedata2(writedata2M),.readdata2(readdata2M),
		.adel(adelM),.ades(adesM)
	);

    exception except(
		.rst(rst),
		.cp0weW(cp0weW),
		.waddrW(rdW),.wdataW(aluoutW),
		.adel(adelM),.ades(adesM),
		.except(exceptM),
		.cp0_statusW(status_oW),.cp0_causeW(cause_oW),.cp0_epcW(epc_oW),
		.excepttypeM(excepttypeM),.newpcM(newpcM)
	);
    
    assign bad_addrM = (exceptM[6])? pcM:(adelM | adesM)? aluoutM: 32'b0;
	assign rf_wen = {4{regwriteW & ~longest_stall & ~flush_exceptW}} ;

	//writeback stage
	flopenrc #( .WIDTH(32) ) r1W(
    	.clk(clk),
    	.rst(rst),
		.en(~stallW),
		.clear(flushW),
    	.d(aluoutM),
    	.q(aluoutW)
    );
	flopenrc #( .WIDTH(32) ) r2W(
		.clk(clk),
		.rst(rst),
		.en(~stallW),
		.clear(flushW),
		.d(readdata2M),
		.q(readdataW)
	);
	flopenrc #( .WIDTH(5) ) r3W(
    	.clk(clk),
    	.rst(rst),
		.en(~stallW),
		.clear(flushW),
    	.d(writeregM),
    	.q(writeregW)
    );
	flopenrc #( .WIDTH(64) ) r4W(
    	.clk(clk),
    	.rst(rst),
		.en(~stallW),
		.clear(flushW),
    	.d(hilo_iM),
    	.q(hilo_iW)
    );
    flopenrc #( .WIDTH(5) ) r5W(
    	.clk(clk),
    	.rst(rst),
		.en(~stallW),
		.clear(flushW),
    	.d(rdM),
    	.q(rdW)
    );
    flopenrc #( .WIDTH(32) ) r6W(
    	.clk(clk),
    	.rst(rst),
		.en(~stallW),
		.clear(flushW),
    	.d(pcM),
    	.q(pcW)
    );
    flopr #( .WIDTH(1) ) r7W(
		.clk(clk),
    	.rst(rst),
    	.d(flush_exceptM),
    	.q(flush_exceptW)
	);

	mux2 #( .WIDTH(32) ) resmux(
		.d0(aluoutW),
		.d1(readdataW),
		.s(memtoregW),
		.y(resultW)
	);
	
	// hiloreg
	hilo_reg hilo (
    	.clk(clk),
		.rst(rst),
    	.we(hilo_writeW & ~stallW),
    	.hi_i(hilo_iW[63:32]),
    	.lo_i(hilo_iW[31:0 ]),
    	.hi_o(hilo_oW[63:32]),
    	.lo_o(hilo_oW[31:0 ])
	);

	div divider (
		.clk(clk),
		.rst(rst),
		.signed_div_i(div_signed),
		.opdata1_i(srca2E),
		.opdata2_i(srcb3E),
		.start_i(div_start),
		.annul_i(1'b0),
		.result_o(div_out),
		.ready_o(div_ready)
	);

	div_state divsate(
    	.alucontrol(alucontrolE),
    	.div_ready(div_ready),
    	.div_stall(div_stall),
    	.div_start(div_start),
    	.div_signed(div_signed)
	);

    //Wstage handle MTC0,Mstage handle exceptions
	cp0 CP0(
		.clk(clk),.rst(rst),
		.we_i(cp0weW& ~stallW),
		.waddr_i(rdW),.raddr_i(rdE),
		.data_i(aluoutW),
		.int_i(ext_int),
		.excepttype_i(excepttypeM),
		.current_inst_addr_i(pcM),
		.is_in_delayslot_i(is_in_delayslotM),
		.bad_addr_i(bad_addrM),
		.data_o(cp0dataE),
		.status_o(status_oW),.cause_o(cause_oW),.epc_o(epc_oW),
		.count_o(count_oW),.compare_o(compare_oW),.config_o(config_oW),
		.prid_o(prid_oW),.badvaddr(badvaddrW)
	);

endmodule
