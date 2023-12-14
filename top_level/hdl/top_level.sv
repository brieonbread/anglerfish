`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  //output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red) for debugging (for now)
  //output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  //output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock
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


  // CAMERA STUFF

  logic clk_pixel;
  logic clk_5x;
  hdmi_clk_wiz_720p mhdmicw (
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x),
      .reset(0),
      .locked(0),
      .clk_ref(clk_100mhz)
  );

  logic [1:0] cam_clks;
  assign camclk = cam_clks[0]; //&& cam_clks[1];

  //left camera and BRAM
  logic left_wea;
  logic [16:0] left_addr;
  logic [47:0] left_bw;
  camera_top left (
    .clk_pixel(clk_pixel),
    .rst_in(sys_rst),
    .data_in(pmoda),
    .sync_in(gpio[2:0]),
    .camclk(cam_clks[0]),
    .addr_out(left_addr),
    .wea_out(left_wea),
    .greyscale_data_out(left_bw)
  );
  
  logic [47:0] left_out;
  logic [13:0] left_addr_out;

  xilinx_true_dual_port_read_first_2_clock_ram #(
      .RAM_WIDTH(48), //each entry in this memory is 48 bits
      .RAM_DEPTH(320*40)) //there are 40*320 or 12800 entries for full frame
    left_image (
      .addra(left_addr), //pixels are stored using this math; "stop storing pixels" when told to freeze
      .clka(clk_pixel),
      .wea(left_wea && !(sw[1])), // freeze camera if sw[1] is high
      .dina(left_bw),
      .ena(1'b1),
      .regcea(1'b1),
      .rsta(sys_rst),
      .douta(), //never read from this side
      .addrb(left_addr_out),//transformed lookup pixel; if running manta, edit this line to be pixel that manta requests
      .dinb(16'b0),
      .clkb(clk_pixel),
      .web(1'b0),
      .enb(1'b1),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb(left_out)
  );

  bram_readout #( .BRAM_WIDTH(48), // debugging BW
                  .BRAM_DEPTH(320*40),
                  .BAUD_RATE(2970000),
                  .CLK_FREQ(74250000) )
                ( .clk_in(clk_pixel),
                  .data_in(left_out),
                  .send_data_in(sw[0]),
                  .req_index_out(left_addr_out),
                  .uart_txd(uart_txd) );

  //right camera and BRAM
  //logic right_wea;
  //logic [16:0] right_addr;
  //logic [7:0] right_bw;
  //camera_top right (
  //  .clk_pixel(clk_pixel),
  //  .rst_in(sys_rst),
  //  .data_in(pmodb),
  //  .sync_in(gpio[5:3]),
  //  .camclk(cam_clks[1]),
  //  .addr_out(right_addr),
  //  .wea_out(right_wea),
  //  .greyscale_data_out(right_bw)
  //);
  //
  //xilinx_true_dual_port_read_first_2_clock_ram #(
  //    .RAM_WIDTH(48), //each entry in this memory is 16 bits
  //    .RAM_DEPTH(320*40)) //there are 240*320 or 76800 entries for full frame
  //  right_image (
  //    .addra(right_addr), //pixels are stored using this math; "stop storing pixels" when told to freeze
  //    .clka(clk_pixel),
  //    .wea(right_wea),
  //    .dina(right_bw),
  //    .ena(1'b1),
  //    .regcea(1'b1),
  //    .rsta(sys_rst),
  //    .douta(), //never read from this side
  //    .addrb(),//transformed lookup pixel; if running manta, edit this line to be pixel that manta requests
  //    .dinb(16'b0),
  //    .clkb(clk_pixel),
  //    .web(1'b0),
  //    .enb(), // if using manta, edit this line to be always 1'b1
  //    .rstb(sys_rst),
  //    .regceb(1'b1),
  //    .doutb()
  //);


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
