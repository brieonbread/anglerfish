`timescale 1ns / 1ps
`default_nettype none

module mac_engine_48bit (
    input wire clk_in,
    input wire rst_in,
    input wire [47:0] left_row,
    input wire [47:0] right_row,
    input wire valid_in,
    output logic [$clog2(255*255*6):0] accumulator
);

    // logic [$clog2(255*255*6)] accumulator; // new! when get_output is high, return what is in accumulator
    logic [7:0] pixel_0_diff, pixel_1_diff, pixel_2_diff, pixel_3_diff, pixel_4_diff, pixel_5_diff;
    logic [7:0] left_pixel_0, left_pixel_1, left_pixel_2, left_pixel_3, left_pixel_4, left_pixel_5;
    logic [7:0] right_pixel_0, right_pixel_1, right_pixel_2, right_pixel_3, right_pixel_4, right_pixel_5;
    assign pixel_0_diff = left_row[47:40] > right_row[47:40] ? left_row[47:40] - right_row[47:40] : right_row[47:40] - left_row[47:40];
    assign pixel_1_diff = left_row[39:32] > right_row[39:32] ? left_row[39:32] - right_row[39:32] : right_row[39:32] - left_row[39:32];
    assign pixel_2_diff = left_row[31:24] > right_row[31:24] ? left_row[31:24] - right_row[31:24] : right_row[31:24] - left_row[31:24];
    assign pixel_3_diff = left_row[23:16] > right_row[23:16] ? left_row[23:16] - right_row[23:16] : right_row[23:16] - left_row[23:16];
    assign pixel_4_diff = left_row[15:8]  > right_row[15:8] ? left_row[15:8] - right_row[15:8] : right_row[15:8] - left_row[15:8];
    assign pixel_5_diff = left_row[7:0]   > right_row[7:0] ? left_row[7:0] - right_row[7:0] : right_row[7:0] - left_row[7:0];

    // end
    always_ff @ (posedge clk_in) begin
        if (rst_in) begin
            accumulator <= 0; // is this a good default?
        end else begin
            if (valid_in) begin
                // we assume left pixel and right pixel are always > 0
                // we have 6 pixels 
                accumulator <= pixel_0_diff*pixel_0_diff + pixel_1_diff*pixel_1_diff + pixel_2_diff*pixel_2_diff +
                               pixel_3_diff*pixel_3_diff + pixel_4_diff*pixel_4_diff + pixel_5_diff*pixel_5_diff;

            end

        end
    end



endmodule // mac_engine_new
`default_nettype wire

