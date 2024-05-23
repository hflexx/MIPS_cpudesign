module i_sram_to_sram_like (
    input         clk, rst,
    output        i_stall       ,
    input         longest_stall ,
    
    //inst sram
    input         inst_sram_en   ,
  //input  [3 :0] inst_sram_wen  ,
    input  [31:0] inst_sram_addr ,
  //input  [31:0] inst_sram_wdata,
    output [31:0] inst_sram_rdata,
    
    //inst sram-like 
    output        inst_req     ,
    output        inst_wr      ,
    output [1 :0] inst_size    ,
    output [31:0] inst_addr    ,
    output [31:0] inst_wdata   ,
    input  [31:0] inst_rdata   ,
    input         inst_addr_ok ,
    input         inst_data_ok
    
);
    reg addr_rcv;      //地址握手成功
    reg do_finish;     //读事务结�?
    reg [31:0] inst_rdata_save;

    always @(posedge clk) begin
        if (rst) begin
            addr_rcv <= 1'b0;
        end else if (inst_req & inst_addr_ok & ~inst_data_ok) begin
            addr_rcv <= 1'b1;
        end else if (inst_data_ok) begin
            addr_rcv <= 1'b0;
        end else begin
            addr_rcv <= addr_rcv;  // 保持当前�?
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            do_finish <= 1'b0;
        end else if (inst_data_ok) begin
            do_finish <= 1'b1;
        end else if (~longest_stall) begin
            do_finish <= 1'b0;
        end else begin
            do_finish <= do_finish;  // 保持当前�?
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            inst_rdata_save <= 32'b0;
        end else if (inst_data_ok) begin
            inst_rdata_save <= inst_rdata;
        end else begin
            inst_rdata_save <= inst_rdata_save;  // 保持当前�?
        end
    end

    //sram like
    assign inst_req = inst_sram_en & ~addr_rcv & ~do_finish;
    assign inst_wr = 1'b0;
    assign inst_size = 2'b10;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'b0;

    //sram
    assign inst_sram_rdata = inst_rdata_save;
    assign i_stall = inst_sram_en & ~do_finish;
    
endmodule