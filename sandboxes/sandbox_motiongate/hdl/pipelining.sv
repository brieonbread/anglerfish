`timescale 1ns / 1ps
`default_nettype none

module pipelining #( 
                     parameter DEPTH = 1,
                     parameter DATA_WIDTH = 8
                   )
                   (
                     input wire clk_in,
                     input wire rst_in,
                     input wire [DATA_WIDTH-1:0] data_in,
                     output logic [DATA_WIDTH-1:0] data_out
                   );

  logic [DATA_WIDTH*(DEPTH+1)-1:0] buffer;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      buffer <= 0;
    end else begin
      data_out <= buffer[DATA_WIDTH-1:0];
      buffer <= { data_in, buffer[DATA_WIDTH*(DEPTH+1)-1:DATA_WIDTH] };
    end
  end

endmodule

`default_nettype wire
