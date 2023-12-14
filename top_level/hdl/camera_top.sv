`timescale 1ns / 1ps
`default_nettype none

module camera_top(
  input wire clk_pixel, // should be 74.25 MHz
  input wire rst_in, // reset 
  input wire [7:0] data_in,
  input wire [2:0] sync_in,
  output logic camclk,
  output logic [16:0] addr_out,
  output logic wea_out,
  output logic [47:0] greyscale_data_out,
  output logic [23:0] rgb_out,
  output logic [10:0] h_out,
  output logic [9:0] v_out
  );

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

  //remapped frame_buffer outputs with 8 bits for r, g, b
  logic [7:0] fb_red, fb_green, fb_blue;

  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.
  always_ff @(posedge clk_pixel) begin
    cam_clk_buff <= sync_in[0]; //sync camera
    cam_clk_in <= cam_clk_buff;
    vsync_buff <= sync_in[1]; //sync vsync signal
    vsync_in <= vsync_buff;
    href_buff <= sync_in[2]; //sync href signal
    href_in <= href_buff;
    pixel_buff <= data_in; //sync pixels
    pixel_in <= pixel_buff;
  end

  //from week 04! (make sure you include in your hdl) (same as before)
  video_sig_gen mvg(
      .clk_pixel_in(clk_pixel),
      .rst_in(rst_in),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count)
  );

  //Controls and Processes Camera information
  camera camera_m(
    .clk_pixel_in(clk_pixel),
    .pmodbclk(camclk), //data lines in from camera
    .pmodblock(), //
    //returned information from camera (raw):
    .cam_clk_in(cam_clk_in),
    .vsync_in(vsync_in),
    .href_in(href_in),
    .pixel_in(pixel_in),
    //output framed info from camera for processing:
    .pixel_out(cam_pixel), //16 bit 565 RGB pixel
    .pixel_valid_out(valid_pixel), //pixel valid signal
    .frame_done_out(frame_done) //single-cycle indicator of finished frame
  );

  //camera and recover module are kept separate since some users may eventually
  //want to add pre-processing on signal prior to framing into hcount/vcount-based
  //values.

  //The recover module takes in information from the camera
  // and sends out:
  // * 5-6-5 pixels of camera information
  // * corresponding hcount and vcount for that pixel
  // * single-cycle valid indicator
  recover recover_m (
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),
    .frame_done_in(frame_done),
    .system_clk_in(clk_pixel),
    .rst_in(rst_in),
    .pixel_out(pixel_data_rec), //processed pixel data out
    .data_valid_out(data_valid_rec), //single-cycle valid indicator
    .hcount_out(hcount_rec), //corresponding hcount of camera pixel
    .vcount_out(vcount_rec) //corresponding vcount of camera pixel
  );


  //split frame_buff into 3 8 bit color channels (5:6:5 adjusted accordingly)
  assign fb_red = {pixel_data_rec[15:11],3'b0};
  assign fb_green = {pixel_data_rec[10:5], 2'b0};
  assign fb_blue = {pixel_data_rec[4:0],3'b0};

  logic [9:0] new_greyscale_data;

  rgb_to_ycrcb ( // 3-cycle latency
    .clk_in(clk_pixel),
    .r_in(fb_red),
    .g_in(fb_green),
    .b_in(fb_blue),
    .y_out(new_greyscale_data),
    .cr_out(),
    .cb_out()
  );


  logic [2:0] pixel_count;
  
  logic y_valid;
  logic [$clog2(320*40)-1:0] y_addr;
  always_ff @(posedge clk_pixel) begin
  //  y_valid <= data_valid_rec;  // y-is-valid signal
  //  y_addr <= (hcount_rec + (320 * vcount_rec)) / 6; // 6 pixels to an address
    if (rst_in) begin
      pixel_count <= 0;
      greyscale_data_out <= 0;
      wea_out <= 0;
    end else if (y_valid) begin
      pixel_count <= (pixel_count >= 5)? 0 : pixel_count + 1;
      greyscale_data_out <= {greyscale_data_out, new_greyscale_data[7:0]};
      addr_out <= y_addr;
      wea_out <= (pixel_count >= 5)? 1'b1 : 1'b0;
    end else wea_out <= 0;
    //wea_out <= (y_valid && pixel_count == 5)? 1'b1 : 1'b0; // pixel_count about to be 6 (full count)
  end
  //assign wea_out = (pixel_count >= 6);
  
  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(1) ) valid_pipe (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in(data_valid_rec),
    .data_out(y_valid) );

  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(17) ) addr_pipe (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in((hcount_rec + (320 * vcount_rec)) / 6),
    .data_out(y_addr) );

  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(24) ) rgb_pipe (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in({fb_red, fb_green, fb_blue}),
    .data_out(rgb_out) );

  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(11) ) h_pipe (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in(hcount_rec),
    .data_out(h_out) );
  
  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(10) ) v_pipe (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in(vcount_rec)),
    .data_out(v_out) );

endmodule

`default_nettype wire



