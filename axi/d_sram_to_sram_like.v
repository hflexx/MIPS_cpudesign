module d_sram_to_sram_like(
    input         clk, rst,
    output        d_stall       ,
    input         longest_stall ,

    //data sram
    input         data_sram_en   ,
    input  [3 :0] data_sram_wen  ,
    input  [31:0] data_sram_addr ,
    input  [31:0] data_sram_wdata,
    output [31:0] data_sram_rdata,

    //data sram-like
    output        data_req     ,
    output        data_wr      ,
    output [1 :0] data_size    ,
    output [31:0] data_addr    ,
    output [31:0] data_wdata   ,
    input  [31:0] data_rdata   ,
    input         data_addr_ok ,
    input         data_data_ok
    
);
    reg addr_rcv;      //地址握手成功
    reg do_finish;     //读写事务结束
    reg [31:0] data_rdata_save;

    always @(posedge clk) begin
        if (rst) begin
            addr_rcv <= 1'b0;
        end else if (data_req & data_addr_ok & ~data_data_ok) begin
            addr_rcv <= 1'b1;
        end else if (data_data_ok) begin
            addr_rcv <= 1'b0;
        end else begin
            addr_rcv <= addr_rcv;  
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            do_finish <= 1'b0;
        end else if (data_data_ok) begin
            do_finish <= 1'b1;
        end else if (~longest_stall) begin
            do_finish <= 1'b0;
        end else begin
            do_finish <= do_finish;  
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            data_rdata_save <= 32'b0;
        end else if (data_data_ok) begin
            data_rdata_save <= data_rdata;
        end else begin
            data_rdata_save <= data_rdata_save;  
        end
    end

    //sram like
    assign data_req = data_sram_en & ~addr_rcv & ~do_finish;
    assign data_wr = data_sram_en & (data_sram_wen[0] | data_sram_wen[1] | data_sram_wen[2] | data_sram_wen[3]);
    assign data_size = (data_sram_wen==4'b0001 || data_sram_wen==4'b0010 || data_sram_wen==4'b0100 || data_sram_wen==4'b1000) ? 2'b00:
                       (data_sram_wen==4'b0011 || data_sram_wen==4'b1100 ) ? 2'b01 : 2'b10;
    assign data_addr = data_sram_addr;
    assign data_wdata = data_sram_wdata;

    //sram
    assign data_sram_rdata = data_rdata_save;
    assign d_stall = data_sram_en & ~do_finish;

endmodule