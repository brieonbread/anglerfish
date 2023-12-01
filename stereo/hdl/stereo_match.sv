`timescale 1ns / 1ps
`default_nettype none

module stereo_match #(parameter max_offset=30,
                                block_size=3, 
                                block_width=1)(
        input wire clk_in,
        input wire rst_in,
        input wire [3:0] left_pixel_in[8:0],
        input wire [3:0] right_pixel_in [8:0],
        input wire valid_in,
        output logic [8:0] ssd_out,
        output logic valid_out);

always_ff @ (posedge clk_in) begin
    if (rst_in) begin
        ssd_out <= 0;
        valid_out <= 0;
    end else begin
        if (valid_in) begin
            ssd_out <=  ((left_pixel_in[0] - right_pixel_in[0]) * (left_pixel_in[0] - right_pixel_in[0])) +
                        ((left_pixel_in[1] - right_pixel_in[1]) * (left_pixel_in[1] - right_pixel_in[1])) +
                        ((left_pixel_in[2] - right_pixel_in[2]) * (left_pixel_in[2] - right_pixel_in[2])) +
                        ((left_pixel_in[3] - right_pixel_in[3]) * (left_pixel_in[3] - right_pixel_in[3])) +
                        ((left_pixel_in[4] - right_pixel_in[4]) * (left_pixel_in[4] - right_pixel_in[4])) +
                        ((left_pixel_in[5] - right_pixel_in[5]) * (left_pixel_in[5] - right_pixel_in[5])) +
                        ((left_pixel_in[6] - right_pixel_in[6]) * (left_pixel_in[6] - right_pixel_in[6])) +
                        ((left_pixel_in[7] - right_pixel_in[7]) * (left_pixel_in[7] - right_pixel_in[7])) +
                        ((left_pixel_in[8] - right_pixel_in[8]) * (left_pixel_in[8] - right_pixel_in[8])); 
            valid_out <= 1;
        end
    end
    

end
// assume that we have complete left and right images stored in buffer
// 


endmodule
`default_nettype wire

