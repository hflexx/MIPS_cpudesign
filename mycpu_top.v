module mycpu_top(
    input       aclk,
    input       aresetn,  //low active
    input [5:0] ext_int,  //high active

    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock       ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       ,

    //debug
    output [31:0] debug_wb_pc      ,
    output [3 :0] debug_wb_rf_wen  ,
    output [4 :0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);

    //inst sram-like 
    wire        cpu_inst_req     ;
    wire        cpu_inst_wr      ;
    wire [1 :0] cpu_inst_size    ;
    wire [31:0] cpu_inst_addr    ;
    wire [31:0] cpu_inst_wdata   ;
    wire [31:0] cpu_inst_rdata   ;
    wire        cpu_inst_addr_ok ;
    wire        cpu_inst_data_ok ;
    //data sram-like 
    wire        cpu_data_req     ;
    wire        cpu_data_wr      ;
    wire [1 :0] cpu_data_size    ;
    wire [31:0] cpu_data_addr    ;
    wire [31:0] cpu_data_wdata   ;
    wire [31:0] cpu_data_rdata   ;
    wire        cpu_data_addr_ok ;
    wire        cpu_data_data_ok ;

    wire [31:0] cpu_inst_paddr;
    wire [31:0] cpu_data_paddr;
    wire no_dcache;

    //ram
    wire        ram_data_req     ;
    wire        ram_data_wr      ;
    wire [1 :0] ram_data_size    ;
    wire [31:0] ram_data_addr    ;
    wire [31:0] ram_data_wdata   ;
    wire [31:0] ram_data_rdata   ;
    wire        ram_data_addr_ok ;
    wire        ram_data_data_ok ;
    //confreg
    wire        conf_data_req     ;
    wire        conf_data_wr      ;
    wire [1 :0] conf_data_size    ;
    wire [31:0] conf_data_addr    ;
    wire [31:0] conf_data_wdata   ;
    wire [31:0] conf_data_rdata   ;
    wire        conf_data_addr_ok ;
    wire        conf_data_data_ok ;

    //inst cache
    wire        cache_inst_req     ;
    wire        cache_inst_wr      ;
    wire [1 :0] cache_inst_size    ;
    wire [31:0] cache_inst_addr    ;
    wire [31:0] cache_inst_wdata   ;
    wire [31:0] cache_inst_rdata   ;
    wire        cache_inst_addr_ok ;
    wire        cache_inst_data_ok ;
    //data cache
    wire        cache_data_req     ;
    wire        cache_data_wr      ;
    wire [1 :0] cache_data_size    ;
    wire [31:0] cache_data_addr    ;
    wire [31:0] cache_data_wdata   ;
    wire [31:0] cache_data_rdata   ;
    wire        cache_data_addr_ok ;
    wire        cache_data_data_ok ;

    wire        wrap_data_req     ;
    wire        wrap_data_wr      ;
    wire [1 :0] wrap_data_size    ;
    wire [31:0] wrap_data_addr    ;
    wire [31:0] wrap_data_wdata   ;
    wire [31:0] wrap_data_rdata   ;
    wire        wrap_data_addr_ok ;
    wire        wrap_data_data_ok ;

    mips mips(
        .clk(aclk),
        .rst(~aresetn),
        .ext_int(ext_int),
        //instr
        .inst_req       (cpu_inst_req    ),
        .inst_wr        (cpu_inst_wr     ),
        .inst_size      (cpu_inst_size   ),
        .inst_addr      (cpu_inst_addr   ),
        .inst_wdata     (cpu_inst_wdata  ),
        .inst_rdata     (cpu_inst_rdata  ),
        .inst_addr_ok   (cpu_inst_addr_ok),
        .inst_data_ok   (cpu_inst_data_ok),
        //data
        .data_req       (cpu_data_req    ),
        .data_wr        (cpu_data_wr     ),
        .data_size      (cpu_data_size   ),
        .data_addr      (cpu_data_addr   ),
        .data_wdata     (cpu_data_wdata  ),
        .data_rdata     (cpu_data_rdata  ),
        .data_addr_ok   (cpu_data_addr_ok),
        .data_data_ok   (cpu_data_data_ok),
        //debug
        .debug_wb_pc        (debug_wb_pc      ),
        .debug_wb_rf_wen    (debug_wb_rf_wen  ),
        .debug_wb_rf_wnum   (debug_wb_rf_wnum ),
        .debug_wb_rf_wdata  (debug_wb_rf_wdata)

    );

    //ascii
    instdec instdec(
        .instr(cpu_inst_rdata)
    );

    //mmu
    mmu mmu (
        .inst_vaddr(cpu_inst_addr),
        .inst_paddr(cpu_inst_paddr),
        .data_vaddr(cpu_data_addr),
        .data_paddr(cpu_data_paddr),
        .no_dcache (no_dcache)
	);

    bridge_1x2 bridge_1x2(
        .no_dcache        (no_dcache       ),

        .cpu_data_req     (cpu_data_req    ),
        .cpu_data_wr      (cpu_data_wr     ),
        .cpu_data_addr    (cpu_data_paddr  ),
        .cpu_data_wdata   (cpu_data_wdata  ),
        .cpu_data_size    (cpu_data_size   ),
        .cpu_data_rdata   (cpu_data_rdata  ),
        .cpu_data_addr_ok (cpu_data_addr_ok),
        .cpu_data_data_ok (cpu_data_data_ok),

        .ram_data_req     (ram_data_req    ),
        .ram_data_wr      (ram_data_wr     ),
        .ram_data_addr    (ram_data_addr   ),
        .ram_data_wdata   (ram_data_wdata  ),
        .ram_data_size    (ram_data_size   ),
        .ram_data_rdata   (ram_data_rdata  ),
        .ram_data_addr_ok (ram_data_addr_ok),
        .ram_data_data_ok (ram_data_data_ok),

        .conf_data_req     (conf_data_req    ),
        .conf_data_wr      (conf_data_wr     ),
        .conf_data_addr    (conf_data_addr   ),
        .conf_data_wdata   (conf_data_wdata  ),
        .conf_data_size    (conf_data_size   ),
        .conf_data_rdata   (conf_data_rdata  ),
        .conf_data_addr_ok (conf_data_addr_ok),
        .conf_data_data_ok (conf_data_data_ok)
    );

    //i_cache
    i_cache_direct_map i_cache (
        .clk(aclk), .rst(~aresetn),
        //mips core
        .cpu_inst_req(cpu_inst_req),
        .cpu_inst_wr(cpu_inst_wr),
        .cpu_inst_size(cpu_inst_size),
        .cpu_inst_addr(cpu_inst_paddr),
        .cpu_inst_wdata(cpu_inst_wdata),
        .cpu_inst_rdata(cpu_inst_rdata),
        .cpu_inst_addr_ok(cpu_inst_addr_ok),
        .cpu_inst_data_ok(cpu_inst_data_ok),
        //sram-like interface
        .cache_inst_req(cache_inst_req),
        .cache_inst_wr(cache_inst_wr),
        .cache_inst_size(cache_inst_size),
        .cache_inst_addr(cache_inst_addr),
        .cache_inst_wdata(cache_inst_wdata),
        .cache_inst_rdata(cache_inst_rdata),
        .cache_inst_addr_ok(cache_inst_addr_ok),
        .cache_inst_data_ok(cache_inst_data_ok) 
    );

    //d_cache
    d_cache_wb_4ways d_cache (
        .clk(aclk), .rst(~aresetn),
        //mips core
        .cpu_data_req(ram_data_req),
        .cpu_data_wr(ram_data_wr),
        .cpu_data_size(ram_data_size),
        .cpu_data_addr(ram_data_addr),
        .cpu_data_wdata(ram_data_wdata),
        .cpu_data_rdata(ram_data_rdata),
        .cpu_data_addr_ok(ram_data_addr_ok),
        .cpu_data_data_ok(ram_data_data_ok),
        //sram-like interface
        .cache_data_req(cache_data_req),
        .cache_data_wr(cache_data_wr),
        .cache_data_size(cache_data_size),
        .cache_data_addr(cache_data_addr),
        .cache_data_wdata(cache_data_wdata),
        .cache_data_rdata(cache_data_rdata),
        .cache_data_addr_ok(cache_data_addr_ok),
        .cache_data_data_ok(cache_data_data_ok) 
    );

    bridge_2x1 bridge_2x1(
        .no_dcache        (no_dcache         ),

        .ram_data_req     (cache_data_req    ),
        .ram_data_wr      (cache_data_wr     ),
        .ram_data_addr    (cache_data_addr   ),
        .ram_data_wdata   (cache_data_wdata  ),
        .ram_data_size    (cache_data_size   ),
        .ram_data_rdata   (cache_data_rdata  ),
        .ram_data_addr_ok (cache_data_addr_ok),
        .ram_data_data_ok (cache_data_data_ok),

        .conf_data_req     (conf_data_req    ),
        .conf_data_wr      (conf_data_wr     ),
        .conf_data_addr    (conf_data_addr   ),
        .conf_data_wdata   (conf_data_wdata  ),
        .conf_data_size    (conf_data_size   ),
        .conf_data_rdata   (conf_data_rdata  ),
        .conf_data_addr_ok (conf_data_addr_ok),
        .conf_data_data_ok (conf_data_data_ok),

        .wrap_data_req     (wrap_data_req    ),
        .wrap_data_wr      (wrap_data_wr     ),
        .wrap_data_addr    (wrap_data_addr   ),
        .wrap_data_wdata   (wrap_data_wdata  ),
        .wrap_data_size    (wrap_data_size   ),
        .wrap_data_rdata   (wrap_data_rdata  ),
        .wrap_data_addr_ok (wrap_data_addr_ok),
        .wrap_data_data_ok (wrap_data_data_ok)
    );

    //axi
    cpu_axi_interface cpu_axi_interface(
        .clk(aclk),
        .resetn(aresetn),

        .inst_req       (cache_inst_req    ),
        .inst_wr        (cache_inst_wr     ),
        .inst_size      (cache_inst_size   ),
        .inst_addr      (cache_inst_addr   ),
        .inst_wdata     (cache_inst_wdata  ),
        .inst_rdata     (cache_inst_rdata  ),
        .inst_addr_ok   (cache_inst_addr_ok),
        .inst_data_ok   (cache_inst_data_ok),

        .data_req       (wrap_data_req     ),
        .data_wr        (wrap_data_wr      ),
        .data_size      (wrap_data_size    ),
        .data_addr      (wrap_data_addr    ),
        .data_wdata     (wrap_data_wdata   ),
        .data_rdata     (wrap_data_rdata   ),
        .data_addr_ok   (wrap_data_addr_ok ),
        .data_data_ok   (wrap_data_data_ok ),

        .arid      (arid      ),
        .araddr    (araddr    ),
        .arlen     (arlen     ),
        .arsize    (arsize    ),
        .arburst   (arburst   ),
        .arlock    (arlock    ),
        .arcache   (arcache   ),
        .arprot    (arprot    ),
        .arvalid   (arvalid   ),
        .arready   (arready   ),
                
        .rid       (rid       ),
        .rdata     (rdata     ),
        .rresp     (rresp     ),
        .rlast     (rlast     ),
        .rvalid    (rvalid    ),
        .rready    (rready    ),
               
        .awid      (awid      ),
        .awaddr    (awaddr    ),
        .awlen     (awlen     ),
        .awsize    (awsize    ),
        .awburst   (awburst   ),
        .awlock    (awlock    ),
        .awcache   (awcache   ),
        .awprot    (awprot    ),
        .awvalid   (awvalid   ),
        .awready   (awready   ),
    
        .wid       (wid       ),
        .wdata     (wdata     ),
        .wstrb     (wstrb     ),
        .wlast     (wlast     ),
        .wvalid    (wvalid    ),
        .wready    (wready    ),
    
        .bid       (bid       ),
        .bresp     (bresp     ),
        .bvalid    (bvalid    ),
        .bready    (bready    )

    );

endmodule