`timescale 1ns / 1ps
`default_nettype none

module mac_engine_48bit (
    input wire clk_in,
    input wire rst_in,
    input wire [47:0] left_row,
    input wire [47:0] right_row,
    input wire valid_in,
    output logic [$clog2(255*255*6):0] accumulator,
    output logic valid_out
);
    // NOTE: should get valid output in accumulator in 3 clock cycles

    // logic [$clog2(255*255*6)] accumulator; // new! when get_output is high, return what is in accumulator
    logic [7:0] pixel_0_diff, pixel_1_diff, pixel_2_diff, pixel_3_diff, pixel_4_diff, pixel_5_diff;
    logic [$clog2(255*255)-1:0] pixel_0_squared, pixel_1_squared, pixel_2_squared, pixel_3_squared, pixel_4_squared, pixel_5_squared;
    logic [2:0] mac_counter;
    logic calculating; // high if still calculating, low if not
    always_ff  @ (posedge clk_in) begin
        if (rst_in) begin
            mac_counter <= 0;
            valid_out <= 0;
        end else begin
            if (valid_in) begin
                pixel_0_diff <= left_row[47:40] > right_row[47:40] ? left_row[47:40] - right_row[47:40] : right_row[47:40] - left_row[47:40];
                pixel_1_diff <= left_row[39:32] > right_row[39:32] ? left_row[39:32] - right_row[39:32] : right_row[39:32] - left_row[39:32];
                pixel_2_diff <= left_row[31:24] > right_row[31:24] ? left_row[31:24] - right_row[31:24] : right_row[31:24] - left_row[31:24];
                pixel_3_diff <= left_row[23:16] > right_row[23:16] ? left_row[23:16] - right_row[23:16] : right_row[23:16] - left_row[23:16];
                pixel_4_diff <= left_row[15:8]  > right_row[15:8]  ? left_row[15:8]  - right_row[15:8]  : right_row[15:8]  - left_row[15:8];
                pixel_5_diff <= left_row[7:0]   > right_row[7:0]   ? left_row[7:0]   - right_row[7:0]   : right_row[7:0]   - left_row[7:0];
                mac_counter <= 0;
                calculating <= 1;
            end

            pixel_0_squared <= pixel_0_diff * pixel_0_diff;
            pixel_1_squared <= pixel_1_diff * pixel_1_diff;
            pixel_2_squared <= pixel_2_diff * pixel_2_diff;
            pixel_3_squared <= pixel_3_diff * pixel_3_diff;
            pixel_4_squared <= pixel_4_diff * pixel_4_diff;
            pixel_5_squared <= pixel_5_diff * pixel_5_diff;

            accumulator <= (pixel_0_squared + pixel_1_squared) + (pixel_2_squared + pixel_3_squared) + (pixel_4_squared + pixel_5_squared);

            if (mac_counter == 1 && calculating) begin
                valid_out <= 1;
                mac_counter <= 0;
                calculating <= 0;
            end else if (calculating) begin
                mac_counter <= mac_counter + 1;
            end else begin
                valid_out <= 0;
            end
        end
    end
    

endmodule // mac_engine_48bit
`default_nettype wire

