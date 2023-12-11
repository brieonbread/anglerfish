`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red) for debugging (for now)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock
  output logic [6:0] ss0_c, // seven segment display
  output logic [6:0] ss1_c,
  output logic [3:0] ss0_an,
  output logic [3:0] ss1_an,
  input wire [7:0] pmoda, // pins for first camera
  input wire [7:0] pmodb, // pins for second camera
  input wire [5:0] gpio, // technically, gpio[5] is actually a servo pin (DON'T use for any clocking of any sort)
  output logic camclk, // shared camera clock (technically a gpio pin)
  output logic uart_txd, // for debugging with manta
  input wire uart_rxd,
  input wire ir_rx // detects when IR signal low or high
  );
  // for quick access, look up "USER INPUTS", "CAMERA STUFF", "SSD", and "LED"
  // to find segments of SysVerilog that put those into detail

  // USER INPUTS

  logic sys_rst; //have btnd control system reset
  assign sys_rst = btn[0];

  logic camera_select; // for now, use sw[15] to switch between cameras for debugging
  assign camera_select = sw[15];
  logic camera_freeze;
  assign camera_freeze = sw[14]; // and use sw[14] to "freeze" images from camera


  // CAMERA STUFF
  camera_top cams (
    .clk_in(clk_100mhz), // should be 100 MHz
    .rst_in(sys_rst),
    .hdmi_tx_p(hdmi_tx_p), // HDMI output
    .hdmi_tx_n(hdmi_tx_n),
    .hdmi_clk_p(hdmi_clk_p),
    .hdmi_clk_n(hdmi_clk_n),
    .data_a_in(pmoda),
    .data_b_in(pmodb),
    .sync_a_in(gpio[2:0]),
    .sync_b_in(gpio[5:3]),
    .cam_sel(camera_select),
    .freeze_img(camera_freeze),
    .camclk(camclk)
    //.uart_txd(), // for manta debugging
    //.uart_rxd()
  );


  // SSD



  // LED
  typedef enum { IDLE, START, IN, END } led_state;


  // IR/motion gate
  logic old_ir_sig;
  

  always_ff @(posedge clk_100mhz) begin
    old_ir_sig <= ir_rx;
    if (!old_ir_sig && ir_rx) begin
    end
  end


endmodule // top_level


`default_nettype wire
