module d_cache_wb_4ways (
    input wire clk, rst,
    //mips core
    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,

    //axi interface
    output         cache_data_req     ,
    output         cache_data_wr      ,
    output  [1 :0] cache_data_size    ,
    output  reg [31:0] cache_data_addr    ,
    output reg [31:0] cache_data_wdata   ,
    input   [31:0] cache_data_rdata   ,
    input          cache_data_addr_ok ,
    input          cache_data_data_ok 
);
    //Cache
    parameter  INDEX_WIDTH  = 10 , OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
   
    reg [2:0] cache_used[CACHE_DEEPTH-1:0];  //LRU
    reg [CACHE_DEEPTH - 1 : 0] cache_valid [0:3];  //有效位
    reg [TAG_WIDTH-1:0] cache_tag0   [CACHE_DEEPTH - 1 : 0];  //标记存储体
    reg [TAG_WIDTH-1:0] cache_tag1   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag2   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag3   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block0 [CACHE_DEEPTH - 1 : 0];  //数据存储体
    reg [31:0]          cache_block1 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block2 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block3 [CACHE_DEEPTH - 1 : 0];
    reg [CACHE_DEEPTH-1:0] cache_clean[0:3];

  
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    wire hit, miss;
    wire [1:0] hit_addr;
    wire [1:0] way;
    reg  [1:0] way_save;
    reg [3:0] mask_save;
    wire [2:0] c_way; //每路使用情况
    assign hit_addr = (hit0 ==1 'b1) ? 2'b00 : (hit1 ==1 'b1) ? 2'b01 : (hit2 ==1 'b1) ?2'b10 :2'b11;
    assign c_way = cache_used[index];                                                             
    assign hit0 = cache_valid[0][index] &  (cache_tag0[index]==tag);
    assign hit1 = cache_valid[1][index] &  (cache_tag1[index]==tag);
    assign hit2 = cache_valid[2][index] &  (cache_tag2[index]==tag);    
    assign hit3 = cache_valid[3][index] &  (cache_tag3[index]==tag);
    assign hit = hit0 | hit1 | hit2 | hit3;  
    assign miss = ~hit;
    //choose least
    assign way = c_way[0] == 1'b0 ? 
                    (c_way[1] == 1'b0 ? 2'b11 : 2'b10) :
                    (c_way[2] == 1'b0 ? 2'b01 : 2'b00);
    // cpu指令读或写
    wire read, write;
    assign write = cpu_data_wr;
    assign read = ~write;

    //FSM状态机
    //IDLE:空闲状态
    //RM:读取内存状态
    //WM：写内存状态
    parameter IDLE = 2'b00, RM = 2'b10, WM=2'b11;
    reg   [1:0] state;
    reg   read_save;
    wire  read_finish; 
    wire  write_finish;   
    wire read_req;
    wire write_req;
    assign read_req = (state == RM);
    assign write_req = (state == WM);
    assign read_finish = (state == RM) & cache_data_data_ok;
    assign write_finish = (state == WM) & cache_data_data_ok;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:   state <= cpu_data_req & miss ? cache_valid[way][index] & 
                        ~cache_clean[way][index] ? WM : RM : IDLE;
                WM:     state <= write_finish ?~read_save & (mask_save==4'b1111) ? IDLE : RM : WM;
                RM:     state <= read_finish ? IDLE : RM; 
            endcase
        end
    end
    
    assign cpu_data_addr_ok = cpu_data_req & hit | cache_data_req & read_req & cache_data_addr_ok;
    assign cpu_data_rdata   = hit ? hit_addr == 0 ?  cache_block0[index] :
                                    hit_addr == 1 ?  cache_block1[index] :
                                    hit_addr == 2 ?  cache_block2[index] : cache_block3[index] : 
                                                  cache_data_rdata;
    assign cpu_data_data_ok = cpu_data_req & hit | read_req & cache_data_data_ok;
    assign cache_data_req   = read_req  & ~ cache_data_data_ok| write_req & ~cache_data_data_ok ;
    assign cache_data_wr    = write_req;
    assign cache_data_size  = cpu_data_size;

    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    reg [31:0] wdata_save,addr_save;
    reg [31:0] write_block_tmp;
    wire [31:0] write_cache_data,combined_data;
    wire [3:0] write_mask;

    //掩码的使用：位为1的代表需要更新的。
    //size: sb-00;sh-01
    assign write_mask = (cpu_data_size==2'b00 ? 
                        (cpu_data_addr[1] ? 
                        (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                        (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                        (cpu_data_size==2'b01 ? 
                        (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111)) ;
    //new_data = old_data & ~mask | write_data & mask       将原始数据不需要更新的和需要更新写入的数据进行结合       
    //hit时更新的data          
    assign write_cache_data = (hit_addr == 0 ?  cache_block0[index] :
                               hit_addr == 1 ?  cache_block1[index] :
                               hit_addr == 2 ?  cache_block2[index] : cache_block3[index] ) & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    assign combined_data = cache_data_rdata & ~{{8{mask_save[3]}}, {8{mask_save[2]}}, {8{mask_save[1]}}, {8{mask_save[0]}}} | 
                              wdata_save & {{8{mask_save[3]}}, {8{mask_save[2]}}, {8{mask_save[1]}}, {8{mask_save[0]}}};
    
    //axi interface   
    always @(negedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_data_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_data_req ? index : index_save;
        wdata_save <= rst ? 32'b0:
                      cpu_data_req ? cpu_data_wdata : wdata_save;
        read_save <= rst ? 1'b0:
              cpu_data_req ? read : read_save;
        mask_save <= rst ? 4'b0:
              cpu_data_req ? write_mask : mask_save;
        addr_save <= rst ? 32'b0:
              cpu_data_req ? cpu_data_addr : addr_save;
        way_save <= rst ? 2'b0:
              cpu_data_req ? way : way_save;
    end
    
    always @(posedge clk) begin
        if(rst) begin
            cache_data_wdata <= 32'b0; 
            cache_data_addr <= 32'b0;
       end
        else if(state==IDLE) begin
           //写回mem的是原来cache line的数据
            if(way == 2'b00)begin        
                cache_data_wdata <= cache_block0[index]; 
            end
            else if(way == 2'b01)begin
                cache_data_wdata <= cache_block1[index];
            end 
            else if(way == 2'b10)begin
                cache_data_wdata <= cache_block2[index];
            end 
            else begin
                cache_data_wdata <= cache_block3[index];
            end 
            
            if(cache_valid[way][index] & ~cache_clean[way][index])begin
                if(way == 2'b00)begin
                    cache_data_addr <= {cache_tag0[index],index,offset};
                end
                else if(way == 2'b01)begin
                   cache_data_addr <= {cache_tag1[index],index,offset};
                end 
                else if(way == 2'b10)begin
                   cache_data_addr <= {cache_tag2[index],index,offset};
                end 
                else begin
                   cache_data_addr <= {cache_tag3[index],index,offset};
                end 
            end
            else begin
                cache_data_addr <= cpu_data_addr;
            end
        end
        else if(state==WM) begin
            cache_data_addr <= write_finish ? addr_save : cache_data_addr;
        end
        else begin
            cache_data_wdata <= cache_data_wdata;
        end
    end
    wire[1:0] select_way;
    wire [INDEX_WIDTH-1 : 0]update_index;
    wire[2:0] new_used;
    //更新使用
    assign update_index = cpu_data_req & hit ? index : index_save;
    assign select_way = cpu_data_req & hit ? hit_addr : way_save;  //哪一路
    assign new_used = (select_way == 2'b11) ? 3'b100 &  cache_used[update_index] | 3'b011 :
                            (select_way == 2'b10) ? 3'b100 &  cache_used[update_index] | 3'b001:
                            (select_way == 2'b01) ? 3'b010 &  cache_used[update_index] | 3'b100:
                            (select_way == 2'b00) ? 3'b010 &  cache_used[update_index] | 3'b000 : 
                            3'b000;
    integer i,t;
    always @(posedge clk) begin
        if(rst) begin              
        for(t=0; t<CACHE_DEEPTH; t=t+1) begin   
            cache_used[t] <= 3'b0;
            for(i=0;i<4;i=i+1) begin
                    cache_valid[i][t] <= 1'b0;
                    cache_clean[i][t] <= 1'b0;
                end
            end
        end
        else begin
            if(read_finish) begin    //读miss
                if(way_save == 0)begin
                    cache_tag0[index_save] <= tag_save;
                    cache_block0[index_save] <= read_save ? cache_data_rdata : combined_data;
                end
                else if(way_save == 1)begin
                    cache_tag1[index_save] <= tag_save;
                    cache_block1[index_save] <= read_save ? cache_data_rdata : combined_data;
                end
                else if(way_save == 2)begin
                    cache_tag2[index_save] <= tag_save;
                    cache_block2[index_save] <= read_save ? cache_data_rdata : combined_data;
                end
                else begin
                    cache_tag3[index_save] <= tag_save;
                    cache_block3[index_save] <= read_save ? cache_data_rdata : combined_data;
                end 
                cache_valid[way_save][index_save] <= 1'b1;                  
                cache_clean [way_save][index_save] <= read_save ? 1'b1 : 1'b0; 
                cache_used[index_save] <= new_used;
            end
            else if(write_finish & ~read_save & (mask_save==4'b1111) ) begin    //写miss
                if(way_save == 0)begin 
                    cache_tag0[index_save] <= tag_save;
                    cache_block0[index_save ] <= wdata_save;
                end
                else if(way_save == 1)begin
                    cache_tag1[index_save ] <= tag_save;
                    cache_block1[index_save] <= wdata_save;
                end
                else if(way_save == 2)begin
                    cache_tag2[index_save ] <= tag_save;
                    cache_block2[index_save] <= wdata_save;
                end
                else begin
                    cache_tag3[index_save ] <= tag_save;
                    cache_block3[index_save] <= wdata_save;
                end                   
                cache_valid [way_save][index_save] <= 1'b1;
                cache_clean [way_save][index_save] <= 1'b0;
                cache_used[index_save] <= new_used;
            end 
            else if(write & cpu_data_req & hit) begin   //写命中
                if(hit_addr == 0)begin
                   cache_block0[index_save] <= write_cache_data;        
                end
                else if(hit_addr == 1)begin
                   cache_block1[index_save] <= write_cache_data; 
                end
                else if(hit_addr == 2)begin
                    cache_block2[index_save] <= write_cache_data; 
                end
                else begin
                   cache_block3[index_save] <= write_cache_data; 
                end                   
                cache_clean[hit_addr][index] <= 1'b0;
                cache_used[index] <= new_used;
            end
            else if(read & cpu_data_req & hit ) begin   //读命中
                cache_used[index] <= new_used;
            end
        end
    end
endmodule
