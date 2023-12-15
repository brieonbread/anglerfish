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
  output logic uart_txd, // for debugging and BRAM output
  input wire uart_rxd,
  input wire ir_rx, // detects when IR signal low or high
  output logic led_ctrl // output pin controlling LED strip
  );

  // for quick access, look up "USER INPUTS", "CAMERA STUFF", "SSD", and "LED"
  // to find segments of SysVerilog that put those into detail

  // ON-BOARD USER INPUTS AND OUTPUTS

  logic sys_rst; //have btnd control system reset
  assign sys_rst = btn[0];

  logic pacing; // begins FSM
  assign pacing = sw[0];

  //logic output_left, output_right; // buffer output stuff
  //assign output_left = sw[1];
  //assign output_right = sw[2];
  //logic output_disparity;
  //assign output_disparity = sw[3];

  logic [3:0] pace_speed; // set pacing for LED
  assign pace_speed = sw[15:12];
  logic use_leds;
  assign use_leds = sw[11];


  // TOP LEVEL FSM
  typedef enum {IDLE, CAMERA_COLLECTION, STEREO_START, STEREO_DONE, UPDATE_LED} top_state;
  top_state state;

  // variables for controlling state and module functioning
  logic collecting, new_frame, l_started, l_finished, r_started, r_finished, frame_done, get_output;
  assign collecting = (state == CAMERA_COLLECTION);

  always_ff @(posedge clk_pixel) begin
    if (sys_rst) begin
      state <= IDLE;
      new_frame <= 0;
      l_started <= 0;
      l_finished <= 0;
      r_started <= 0;
      r_finished <= 0;
      get_output <= 0;
    end else begin
      case (state)
        IDLE : begin
          if (pacing) state <= CAMERA_COLLECTION;
        end
        CAMERA_COLLECTION : begin
          if (left_addr == 0) l_started <= 1;
          if (right_addr == 0) r_started <= 1;
          if (l_started && (left_addr == (320*40))) l_finished <= 1;
          if (r_started && (right_addr == (320*40))) r_finished <= 1;
          if (l_finished && r_finished) begin
            state <= STEREO_START;
            new_frame <= 1; // this signals high only for one cycle in order to start algorithm
            get_output <= 0;
          end
        end
        STEREO_START : begin
          new_frame <= 0;
          l_started <= 0;
          l_finished <= 0;
          r_started <= 0;
          r_finished <= 0;
          if (frame_done) state <= STEREO_DONE;
        end
        STEREO_DONE : begin
          get_output <= 1;
          state <= (pacing)? CAMERA_COLLECTION : IDLE;
        end
        UPDATE_LED : begin // TODO: currently, depth not coupled with LED speed control
        end
      endcase
    end
  end

  // CAMERA STUFF

  logic clk_pixel;
  assign clk_pixel = clk_100mhz;
  //logic clk_5x;
  //hdmi_clk_wiz_720p mhdmicw (
  //    .clk_pixel(clk_pixel),
  //    .clk_tmds(clk_5x),
  //    .reset(0),
  //    .locked(0),
  //    .clk_ref(clk_100mhz)
  //);

  //left camera and BRAM
  logic left_wea;
  logic [16:0] left_addr;
  logic [47:0] left_bw;
  logic [23:0] left_rgb;
  logic [10:0] left_h;
  logic [9:0] left_v;
  camera_top left (
    .clk_pixel(clk_pixel),
    .rst_in(sys_rst),
    .data_in(pmoda),
    .sync_in(gpio[2:0]),
    .camclk(camclk),
    .addr_out(left_addr),
    .wea_out(left_wea),
    .greyscale_data_out(left_bw),
    .rgb_out(left_rgb), // for swimmer COM?
    .h_out(left_h),
    .v_out(left_v)
  );
  
  //logic [47:0] left_out;
  //logic [13:0] left_addr_out;

  //xilinx_true_dual_port_read_first_2_clock_ram #(
  //    .RAM_WIDTH(48), //each entry in this memory is 48 bits
  //    .RAM_DEPTH(320*40)) //there are 40*320 or 12800 entries for full frame
  //  left_image (
  //    .addra(left_addr), //pixels are stored using this math; "stop storing pixels" when told to freeze
  //    .clka(clk_pixel),
  //    .wea(left_wea && collecting),
  //    .dina(left_bw),
  //    .ena(1'b1),
  //    .regcea(1'b1),
  //    .rsta(sys_rst),
  //    .douta(), //never read from this side
  //    .addrb(rot_addr),//transformed lookup pixel; if running manta, edit this line to be pixel that manta requests
  //    .dinb(16'b0),
  //    .clkb(clk_pixel),
  //    .web(1'b0),
  //    .enb(rot_valid),
  //    .rstb(sys_rst),
  //    .regceb(1'b1),
  //    .doutb(left_out)
  //);

  //right camera and BRAM
  logic right_wea;
  logic [16:0] right_addr;
  logic [7:0] right_bw;
  logic [23:0] right_rgb;
  logic [10:0] right_h;
  logic [9:0] right_v;
  camera_top right (
    .clk_pixel(clk_pixel),
    .rst_in(sys_rst),
    .data_in(pmodb),
    .sync_in(gpio[5:3]),
    .camclk(),
    .addr_out(right_addr),
    .wea_out(right_wea),
    .greyscale_data_out(right_bw),
    .rgb_out(right_rgb),
    .h_out(right_h),
    .v_out(right_v)
  );
  
  //logic [47:0] right_out;
  //logic [13:0] right_addr_out;

  //xilinx_true_dual_port_read_first_2_clock_ram #(
  //    .RAM_WIDTH(48), //each entry in this memory is 16 bits
  //    .RAM_DEPTH(320*40)) //there are 240*320 or 76800 entries for full frame
  //  right_image (
  //    .addra(right_addr), //pixels are stored using this math; "stop storing pixels" when told to freeze
  //    .clka(clk_pixel),
  //    .wea(right_wea && collecting),
  //    .dina(right_bw),
  //    .ena(1'b1),
  //    .regcea(1'b1),
  //    .rsta(sys_rst),
  //    .douta(), //never read from this side
  //    .addrb(rot_addr),//transformed lookup pixel; if running manta, edit this line to be pixel that manta requests
  //    .dinb(16'b0),
  //    .clkb(clk_pixel),
  //    .web(1'b0),
  //    .enb(rot_valid), // if using manta, edit this line to be always 1'b1
  //    .rstb(sys_rst),
  //    .regceb(1'b1),
  //    .doutb(right_out)
  //);

  // finding center of mass of swimmer from live RGB values
  //center_of_mass ( // TODO (will need to adapt camera_top to output hcount and vcount)
  //  .clk_in(clk_pixel),
  //  .rst_in(sys_rst),
  //  .x_in(),
  //  .y_in(),
  //  .valid_in(),
  //  .tabulate_in(),
  //  .x_out(),
  //  .y_out(),
  //  .valid_out() );

  // combinationally rotate images from camera
  logic [$clog2(320*40)-1:0] left_rotated_addr;
  logic [31:0] left_intermediate; // because I'm worried about truncated values (32 is probably more bits than we need)
  logic [$clog2(320*40)-1:0] right_rotated_addr;
  logic [31:0] right_intermediate;
  always_comb begin // rotate 90 degrees, then group 6 pixels together at same address
    left_intermediate = ((320 * left_h) + (319 - left_v)) / 6;
    right_intermediate = ((320 * right_h) + (319 - right_v)) / 6;
  end
  assign left_rotated_addr = left_intermediate[$clog2(320*40)-1:0];
  assign right_rotated_addr = right_intermediate[$clog2(320*40)-1:0];

  // SSD
  logic default_lookup;
  assign default_lookup = 0;
  logic [7:0] disparity;

  stereo_match(
    .clk_100mhz(clk_pixel), // doesn't actually need to be 100 MHz
    .sys_rst(sys_rst),
    .new_frame_in(new_frame),   // flag tells us when new frame is ready for processing
    .writing_left(left_wea && collecting), // MUST be low if not writing
    .writing_right(right_wea && collecting),
    .external_left_addr(left_rotated_addr), 
    .external_right_addr(right_rotated_addr),
    .left_din(left_bw),
    .right_din(right_bw),
    .reading(get_output),
    .external_ssd_addr(default_lookup),  // address to look up in SSD results BRAM
    .ssd_dout(disparity),     // output from SSD results BRAM
    .new_frame_out(frame_done) // flag tells us when frame is done processing
    );
  
  // LED
  led_top (
      .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .start(use_leds),
      .speed(pace_speed),
      .led(led_ctrl) 
  );


  // IR/motion gate
  //logic old_ir_sig;
  //

  //always_ff @(posedge clk_100mhz) begin
  //  old_ir_sig <= ir_rx;
  //  if (!old_ir_sig && ir_rx) begin
  //  end
  //end


endmodule // top_level


`default_nettype wire
