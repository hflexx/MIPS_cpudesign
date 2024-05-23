`timescale 1ns / 1ps
`include "defines2.vh"

module aludec(
    input wire[5:0] funct, //instrD[5:0]
    input wire[3:0] aluop,
    output reg[4:0] alucontrol
);

    always @(*) begin
        alucontrol = (aluop == `R_TYPE_OP) ? (
                        (funct == `AND  ) ? `AND_CONTROL   :
                        (funct == `OR   ) ? `OR_CONTROL    :
                        (funct == `NOR  ) ? `NOR_CONTROL   :
                        (funct == `XOR  ) ? `XOR_CONTROL   :
                        (funct == `SLL  ) ? `SLL_CONTROL   :
                        (funct == `SRL  ) ? `SRL_CONTROL   :
                        (funct == `SRA  ) ? `SRA_CONTROL   :
                        (funct == `SRAV ) ? `SRAV_CONTROL  :
                        (funct == `SLLV ) ? `SLLV_CONTROL  :
                        (funct == `SRLV ) ? `SRLV_CONTROL  :
                        (funct == `MFHI ) ? `MFHI_CONTROL  :
                        (funct == `MFLO ) ? `MFLO_CONTROL  :
                        (funct == `MTHI ) ? `MTHI_CONTROL  :
                        (funct == `MTLO ) ? `MTLO_CONTROL  :
                        (funct == `SLT  ) ? `SLT_CONTROL   :
                        (funct == `SLTU ) ? `SLTU_CONTROL  :
                        (funct == `ADD  ) ? `ADD_CONTROL   :
                        (funct == `ADDU ) ? `ADDU_CONTROL  :
                        (funct == `SUB  ) ? `SUB_CONTROL   :
                        (funct == `SUBU ) ? `SUBU_CONTROL  :
                        (funct == `MULT ) ? `MULT_CONTROL  :
                        (funct == `MULTU) ? `MULTU_CONTROL :
                        (funct == `DIV  ) ? `DIV_CONTROL   :
                        (funct == `DIVU ) ? `DIVU_CONTROL  :
                        5'b00000
                    ) :
                        (aluop == `ANDI_OP ) ? `AND_CONTROL  :
                        (aluop == `XORI_OP ) ? `XOR_CONTROL  :
                        (aluop == `ORI_OP  ) ? `OR_CONTROL   :
                        (aluop == `LUI_OP  ) ? `LUI_CONTROL  :
                        (aluop == `ADDI_OP ) ? `ADD_CONTROL  :
                        (aluop == `ADDIU_OP) ? `ADDU_CONTROL :
                        (aluop == `SLTI_OP ) ? `SLT_CONTROL  :
                        (aluop == `SLTIU_OP) ? `SLTU_CONTROL :
                        (aluop == `MTC0_OP ) ? `MTC0_CONTROL :
                        (aluop == `MFC0_OP ) ? `MFC0_CONTROL :
                        5'b00000;
    end

endmodule