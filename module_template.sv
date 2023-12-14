`timescale 1ns / 1ps
`default_nettype none

module calculate_ssd (
    input wire clk_in,
    input wire rst_in,

);

    always_ff @ (posedge clk_in) begin
    end
    

endmodule // calculate_ssd
`default_nettype wire