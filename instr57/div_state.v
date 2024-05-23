`timescale 1ns / 1ps

`include "defines2.vh"

module div_state(
    input [4:0] alucontrol,
    input div_ready,
    output reg div_stall,div_start,div_signed
    );
    
    always@(*) begin
        case(alucontrol)
            `DIV_CONTROL: begin
                if(div_ready == 1'b0) begin
                    div_start<=1'b1;
                    div_signed<=1'b1;
                    div_stall<=1'b1;
                end
                else if(div_ready == 1'b1) begin
                    div_start<=1'b0;
                    div_signed<=1'b1;
                    div_stall<=1'b0;
                end
                else begin
                    div_start<=1'b0;
                    div_signed<=1'b0;
                    div_stall<=1'b0;
                end
            end
            `DIVU_CONTROL: begin
                if(div_ready == 1'b0) begin
                    div_start<=1'b1;
                    div_signed<=1'b0;
                    div_stall<=1'b1;
                end
                else if(div_ready == 1'b1) begin
                    div_start<=1'b0;
                    div_signed<=1'b0;
                    div_stall<=1'b0;
                end
                else begin
                    div_start<=1'b0;
                    div_signed<=1'b0;
                    div_stall<=1'b0;
                end
            end
            default: begin
                div_start<=1'b0;
                div_signed<=1'b0;
                div_stall<=1'b0;
            end
        endcase
    end

endmodule
