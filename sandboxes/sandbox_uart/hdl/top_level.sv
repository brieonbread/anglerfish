`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  output logic [15:0] led,
  output logic [2:0] rgb0,
  output logic [2:0] rgb1,
  input wire [1:0] btn,
  output logic uart_txd,
  input wire uart_rxd
  );
  localparam TEN_KHZ = 100_000_000 / 10_000; // ten kHz is 1/10_000 of 1 MHz


  logic clk_pixel;
  logic clk_5x;
  logic locked;
  assign locked = 1'b0;
  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS,respectively
  hdmi_clk_wiz_720p mhdmicw (
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x),
      .reset(0),
      .locked(locked),
      .clk_ref(clk_100mhz)
  );

  // this time I will be the one shutting up those RGB LEDs...     coolly  B)
  assign rgb0 = 0;
  assign rgb1 = 0;

  logic [7:0] data;
  //assign data = sw[7:0];
  logic [7:0] received_data;
  logic rx_valid;
  //logic [7:0] old_received_data;

  logic clean_btn;
  logic old_btn;

  always_ff @(posedge clk_pixel) old_btn <= clean_btn;

  logic done;
  assign led[15] = done;
  always_ff @(posedge clk_pixel) begin
    if (sw[7:0] == 0) data <= 0; // this is out "reset"
    else if ((clean_btn) && !(old_btn)) data <= data + 1; // change data every send
  end

  debouncer ( .clk_in(clk_pixel),
              .rst_in(btn[0]),
              .dirty_in(btn[1]),
              .clean_out(clean_btn)
            );
    
  uart_rx #(.CLOCKS_PER_BAUD(25)) (
            .clk(clk_pixel),
            .rx(uart_rxd),
            .data_o(received_data),
            .valid_o(rx_valid));

  assign led[7:0] = received_data;

  uart_tx #(.CLOCKS_PER_BAUD(25)) (
            .clk(clk_pixel),
            .data_i(data),
            .start_i((clean_btn) && !(old_btn)),
            .done_o(done),
            .tx(uart_txd)
          );


endmodule

`default_nettype wire
