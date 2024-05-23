`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:29:33
// Design Name: 
// Module Name: signext
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


module signext (input [15:0] a,
                input [1:0] type,
                output [31:0] y);
    //                               zero extend or signed extend
    assign y = (type == 2'b11) ? {{16{1'b0}}, a} : {{16{a[15]}}, a};
endmodule
