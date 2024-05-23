`timescale 1ns / 1ps
`include "defines2.vh"
module maindec( 
    input wire[31:0] instr,
    input stallD,
	output memtoreg, regdst, regwrite,
    output alusrc,
    output branch,bal,
    output jump,jal,jr,jalr,
	output wire[3:0] aluop,
    output wire memen,
    output wire hilo_write, hilo_read,cp0we,cp0r,
    output wire syscall,break,eret,invalid
);

    wire [5:0] funct,op;
	wire [4:0] rt,rs;
	reg invalid2;
	assign op = instr[31:26];
	assign funct = instr[5:0];
	assign rs = instr[25:21];
	assign rt = instr[20:16];
	
	assign regdst = (op == `R_TYPE)||(op == 6'b111111 && funct == 6'b000000);
	
	assign regwrite =  ((op == `ANDI  )||
                        (op == `ORI   )||
                        (op == `XORI  )||
                        (op == `ADDI  )||
                        (op == `ADDIU )||
                        (op == `SLTI  )||
                        (op == `SLTIU )||
                        (op == `R_TYPE && 
                            funct != `MTHI && funct != `MTLO  && 
                            funct != `MULT && funct != `MULTU && 
                            funct != `DIV  && funct != `DIVU) ||
                        (op == `LUI )||
                        (op == `LB  )||
                        (op == `LBU )||
                        (op == `LH  )||
                        (op == `LHU )||
                        (op == `LW  )||
                        (op == `JAL )||
                        (op == `REGIMM_INST   && rt == `BLTZAL) ||
                        (op == `REGIMM_INST   && rt == `BGEZAL) ||
                        (op == `SPECIAL3_INST && rs == `MFC0))  && ~stallD;

    assign memtoreg =  ((op ==`LB )||
                        (op ==`LBU)||
                        (op ==`LH )||
                        (op==`LHU )||
                        (op == `LW)) && ~stallD ;
         
	assign jump = (op == `J);
	
	assign jal = (op == `JAL);
	
	assign jr = (op == `R_TYPE && funct == `JR);
	
	assign jalr = (op == `R_TYPE && funct == `JALR);
	
    assign memen = ((op == `LB )||
                    (op == `LBU)||
                    (op == `LH )||
                    (op == `LHU)||
                    (op == `LW )||
                    (op == `SB )||
                    (op == `SH )||
                    (op == `SW )) && ~stallD;

    assign alusrc =((op == `ANDI )||
                    (op == `ORI  )||
                    (op == `XORI )||
                    (op == `LW   )||
                    (op == `SW   )||
                    (op == `ADDI )||
                    (op == `ADDIU)||
                    (op == `SLTI )||
                    (op == `SLTIU)||
                    (op == `LUI  )||                   
                    (op == `LB   )||
                    (op == `LBU  )||
                    (op == `LH   )||
                    (op == `LHU  )||
                    (op == `LW   )||
                    (op == `SB   )||
                    (op == `SH   )) && ~stallD ;
   
   assign branch = (op == `BEQ )||
                   (op == `BGTZ)||
                   (op == `BLEZ)||
                   (op == `BNE )||
                   (op == `REGIMM_INST && rt == `BLTZ  )||
                   (op == `REGIMM_INST && rt == `BLTZAL)||
                   (op == `REGIMM_INST && rt == `BGEZ  )||
                   (op == `REGIMM_INST && rt == `BGEZAL);
                   
   assign bal = (op == `REGIMM_INST && rt == `BLTZAL)||
                (op == `REGIMM_INST && rt == `BGEZAL);
              
   assign aluop=(op == `R_TYPE)? `R_TYPE_OP:
                (op == `LW    )? `ADDI_OP  :
                (op == `SW    )? `ADDI_OP  :
                (op == `LB    )? `ADDI_OP  :
                (op == `LBU   )? `ADDI_OP  :
                (op == `LH    )? `ADDI_OP  :
                (op == `LHU   )? `ADDI_OP  :
                (op == `SB    )? `ADDI_OP  :
                (op == `SH    )? `ADDI_OP  :
                (op == `ADDI  )? `ADDI_OP  :
                (op == `ADDIU )? `ADDIU_OP :
                (op == `SLTI  )? `SLTI_OP  :
                (op == `SLTIU )? `SLTIU_OP :
                (op == `ANDI  )? `ANDI_OP  :
                (op == `XORI  )? `XORI_OP  :
                (op == `ORI   )? `ORI_OP   :
                (op == `LUI   )? `LUI_OP   :
                (op == `SPECIAL3_INST && rs == `MTC0)? `MTC0_OP:
                (op == `SPECIAL3_INST && rs == `MFC0)? `MFC0_OP:
                `USELESS_OP;


    assign hilo_write = (op == `R_TYPE && funct == `MULT )||
                        (op == `R_TYPE && funct == `MULTU)||
                        (op == `R_TYPE && funct == `DIV  )||
                        (op == `R_TYPE && funct == `DIVU )||
                        (op == `R_TYPE && funct == `MTHI )||
                        (op == `R_TYPE && funct == `MTLO );
                        
    assign hilo_read =  (op == `R_TYPE && funct == `MFHI)||
                        (op == `R_TYPE && funct == `MFLO);
   
    //special inst
    assign syscall = (op == `R_TYPE && funct == `SYSCALL) && ~stallD;
   
    assign break  = (op == `R_TYPE && funct == `BREAK) && ~stallD;
   
    assign eret = (instr == 32'b01000010000000000000000000011000) && ~stallD;
   
    assign cp0we  = (op == `SPECIAL3_INST && rs == `MTC0) && ~stallD;
   
    assign cp0r  = (op == `SPECIAL3_INST && rs == `MFC0) && ~stallD;
   
    always @(*) begin
        case(op)
            `R_TYPE:   // R-type
                begin
                    case(funct)
                        /* logic instraction */
                        `AND: invalid2<= 1'b0;
                        `OR: invalid2<= 1'b0;
                        `XOR:invalid2<= 1'b0;
                        `NOR: invalid2<= 1'b0;
                        /* shift instraction */
                        `SLL: invalid2<= 1'b0;
                        `SRL: invalid2<= 1'b0;
                        `SRA: invalid2<= 1'b0;
                        `SLLV: invalid2<= 1'b0;
                        `SRLV: invalid2<= 1'b0;
                        `SRAV:invalid2<= 1'b0;
                        /* move instraction */
                        `MFHI: invalid2<= 1'b0;
                        `MTHI: invalid2<= 1'b0;
                        `MFLO: invalid2<= 1'b0;
                        `MTLO: invalid2<= 1'b0;
                        /* arithemtic instraction */
                        `ADD: invalid2<= 1'b0;
                        `ADDU: invalid2<= 1'b0;
                        `SUB: invalid2<= 1'b0;
                        `SUBU: invalid2<= 1'b0;
                        `SLT: invalid2<= 1'b0;
                        `SLTU: invalid2<= 1'b0;
                        `MULT: invalid2<= 1'b0;
                        `MULTU: invalid2<= 1'b0;
                        `DIV: invalid2<= 1'b0;
                        `DIVU: invalid2<= 1'b0;
                        /* jump instraction */
                        `JR: invalid2<= 1'b0;
                        `JALR: invalid2<= 1'b0;
                        
                        `SYSCALL: invalid2<= 1'b0;
                        `BREAK: invalid2<= 1'b0;
                        default: invalid2<= 1'b1;
                    endcase
                end
            `ANDI:invalid2<= 1'b0;
            `XORI:invalid2<= 1'b0;
            `LUI: invalid2<= 1'b0;
            `ORI: invalid2<= 1'b0;
            `ADDI:invalid2<= 1'b0;
            `ADDIU:invalid2<= 1'b0;
            `SLTI: invalid2<= 1'b0;
            `SLTIU: invalid2<= 1'b0;

            `J: invalid2<= 1'b0;
            `JAL:invalid2<= 1'b0;
            
            `BEQ:invalid2<= 1'b0;
            `BGTZ:invalid2<= 1'b0;
            `BLEZ:invalid2<= 1'b0;
            `BNE: invalid2<= 1'b0;
            
            `LB: invalid2<= 1'b0;
            `LBU:invalid2<= 1'b0;
            `LH:invalid2<= 1'b0;
            `LHU: invalid2<= 1'b0;
            `LW: invalid2<= 1'b0;
            `SB: invalid2<= 1'b0;
            `SH:invalid2<= 1'b0;
            `SW: invalid2<= 1'b0;
            `REGIMM_INST: begin 
                case (rt)
                    `BGEZ:invalid2<= 1'b0;
                    `BGEZAL: invalid2<= 1'b0;
                    `BLTZ: invalid2<= 1'b0;
                    `BLTZAL: invalid2<= 1'b0;
                    default :invalid2<= 1'b1;
                endcase
            end
            `SPECIAL3_INST: begin 
                if(instr==`ERET) begin
                    invalid2<= 1'b0;
                end else begin 
                    case (rs)
                        `MTC0: invalid2<= 1'b0;
                        `MFC0: invalid2<= 1'b0;
                        default: invalid2<= 1'b1;
                    endcase
                end
            end
            default: invalid2<= 1'b1;
        endcase

        if(!instr)
            invalid2<= 1'b0;
    end

    assign invalid = invalid2 && (~stallD);

endmodule
