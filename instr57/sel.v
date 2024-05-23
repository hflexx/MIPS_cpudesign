`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/28 16:42:30
// Design Name: 
// Module Name: sel
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


module sel(
  input wire[5:0] op,
  input wire[1:0] addr,
  input wire[31:0] writedata,readdata,
  output wire[3:0] sel, //дʹ��
  output wire[31:0] writedata2,readdata2,
  output wire adel,ades
  //output wire[1:0] size
    );
    assign sel = ((op == `LW || op == `LB || op == `LBU || op == `LH || op == `LHU)? 4'b0000:
              (op == `SW && addr == 2'b00)? 4'b1111:
              (op == `SH && addr == 2'b10)? 4'b1100:
              (op == `SH && addr == 2'b00)? 4'b0011:
              (op == `SB && addr == 2'b11)? 4'b1000:
              (op == `SB && addr == 2'b10)? 4'b0100:
              (op == `SB && addr == 2'b01)? 4'b0010:
              (op == `SB && addr == 2'b00)? 4'b0001:4'b0000);
              
     assign writedata2 = ((op == `SW)? writedata:
                     (op == `SH)? {writedata[15:0], writedata[15:0]}:
                     (op == `SB)? {writedata[7:0], writedata[7:0],writedata[7:0],writedata[7:0]}:32'b0);
                     
     assign readdata2 = ((op == `LW && addr == 2'b00)? readdata:
                   (op == `LB && addr == 2'b11)? {{24{readdata[31]}},readdata[31:24]}:
                   (op == `LB && addr == 2'b10)? {{24{readdata[23]}},readdata[23:16]}:
                   (op == `LB && addr == 2'b01)? {{24{readdata[15]}},readdata[15:8]}:
                   (op == `LB && addr == 2'b00)? {{24{readdata[7]}},readdata[7:0]}:
                   (op == `LBU && addr == 2'b11)? {{24{1'b0}},readdata[31:24]}:
                   (op == `LBU && addr == 2'b10)? {{24{1'b0}},readdata[23:16]}:
                   (op == `LBU && addr == 2'b01)? {{24{1'b0}},readdata[15:8]}:
                   (op == `LBU && addr == 2'b00)? {{24{1'b0}},readdata[7:0]}:
                   (op == `LH && addr == 2'b10)? {{16{readdata[31]}},readdata[31:16]}:
                   (op == `LH && addr == 2'b00)? {{16{readdata[15]}},readdata[15:0]}:
                   (op == `LHU && addr == 2'b10)? {{16{1'b0}},readdata[31:16]}:
                   (op == `LHU && addr == 2'b00)? {{16{1'b0}},readdata[15:0]}:32'b0);
       //�쳣    
       assign adel = ((op == `LH || op == `LHU) && addr[0]) || (op == `LW && addr != 2'b00);
       
       assign ades = (op == `SH & addr[0]) | (op == `SW & addr != 2'b00);
endmodule
