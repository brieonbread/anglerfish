`timescale 1ns / 1ps
`default_nettype none

module mac_engine_8bit (
    input wire clk_in,
    input wire rst_in,
    input wire [7:0] left_pixel,
    input wire [7:0] right_pixel,
    input wire valid_in,
    output logic [$clog2(255*255*6):0] accumulator
);

    // logic [$clog2(255*255*6)] accumulator; // new! when get_output is high, return what is in accumulator

    // TODO: rewrite the rest of this module to use get_output + accumulator, redo testbench
    
    always_ff @ (posedge clk_in) begin
        if (rst_in) begin
            accumulator <= 0; // is this a good default?
        end else begin
            if (valid_in) begin
                // we assume left pixel and right pixel are always > 0
                if (left_pixel > right_pixel) begin
                    accumulator <= accumulator + (left_pixel - right_pixel) * (left_pixel - right_pixel);

                end else begin
                    accumulator <= accumulator + (right_pixel - left_pixel) * (right_pixel - left_pixel);
                end
            end

        end
    end



endmodule // smac
`default_nettype wire

