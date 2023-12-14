`timescale 1ns / 1ps
`default_nettype none

module top_level( // this is top level for peripheral FPGA/motion gate!
  input wire clk_100mhz,
  input wire [15:0] sw, //all 16 input slide switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  input wire [7:0] pmoda, // pins for first camera
  output logic [7:0] pmodb, // pins for second camera
  input wire [3:0] btn,
  output logic [2:0] rgb0,
  output logic [2:0] rgb1
  );

  // presets for RGBs and buttoned reset
  assign rgb0 = 0;
  assign rgb1 = 0;
  logic sys_rst;
  assign sys_rst = btn[0];

  // clocking for cameras/video
  logic clk_pixel, clk_5x;
  logic locking;
  assign locking = 0;
 
  //Signals related to driving the video pipeline
  logic [10:0] hcount; //horizontal count
  logic [9:0] vcount; //vertical count
  logic vert_sync; //vertical sync signal
  logic hor_sync; //horizontal sync signal
  logic active_draw; //active draw signal
  logic new_frame; //new frame (use this to trigger center of mass calculations)
  logic [5:0] frame_count; //current frame

  //camera module: (see datasheet)
  logic cam_clk_buff, cam_clk_in; //returning camera clock
  logic vsync_buff, vsync_in; //vsync signals from camera
  logic href_buff, href_in; //href signals from camera
  logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
  logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
  logic valid_pixel; //indicates valid pixel from camera
  logic frame_done; //indicates completion of frame from camera

  //outputs of the recover module
  logic [15:0] pixel_data_rec; // pixel data from recovery module
  logic [10:0] hcount_rec; //hcount from recovery module
  logic [9:0] vcount_rec; //vcount from recovery module
  logic  data_valid_rec; //single-cycle (74.25 MHz) valid data from recovery module
 
  // for IR TX when lap finished
  module signal_high(
    .clk_in(clk_100mhz), // 100 MHz clock
    .rst_in(sys_rst),
    .burst(),
    .ir_sig(pmodb[2])
    );

endmodule

`default_nettype wire

