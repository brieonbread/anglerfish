`timescale 1ns / 1ps
`default_nettype none

module camera_debug(
  input wire clk_in, // should be 100 MHz
  input wire rst_in, // reset 
  output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock
  input wire [7:0] data_a_in,
  input wire [7:0] data_b_in,
  input wire [2:0] sync_a_in,
  input wire [2:0] sync_b_in,
  input wire cam_sel,
  input wire freeze_img,
  output logic camclk
  //output logic uart_txd, // for manta debugging
  //input wire uart_rxd
  );

  // most of this is just taken from Lab 5 (but modified)
  // TODO:
  //   - adapt for simultaneous output of two cameras' greyscale data
  //   - modify pipelining to make video signal generation more efficient
  //   - incorporate optional manta debugging
  //   - ???

  //Clocking Variables:
  logic clk_pixel, clk_5x; //clock lines (pixel clock and 1/2 tmds clock)

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

  //output of the scaled modules
  logic [10:0] hcount_scaled; //scaled hcount for looking up camera frame pixel
  logic [9:0] vcount_scaled; //scaled vcount for looking up camera frame pixel
  logic valid_addr_scaled; //whether or not two values above are valid (or out of frame)

  //outputs of the rotation module
  logic [16:0] img_addr_rot; //result of image transformation rotation
  logic valid_addr_rot; //forward propagated valid_addr_scaled
  logic [1:0] valid_addr_rot_pipe; //pipelining variables in || with frame_buffer

  //values from the frame buffer:
  logic [15:0] frame_buff_raw; //output of frame buffer (direct)
  logic [15:0] frame_buff; //output of frame buffer OR black (based on pipeline valid)

  //remapped frame_buffer outputs with 8 bits for r, g, b
  logic [7:0] fb_red, fb_green, fb_blue;

  //final processed red, gren, blue for consumption in tmds module
  logic [7:0] red, green, blue;

  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!
  
  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.
  always_ff @(posedge clk_pixel) begin
    cam_clk_buff <= (cam_sel)? sync_b_in[0] : sync_a_in[0]; //sync camera
    cam_clk_in <= cam_clk_buff;
    vsync_buff <= (cam_sel)? sync_b_in[1] : sync_a_in[1]; //sync vsync signal
    vsync_in <= vsync_buff;
    href_buff <= (cam_sel)? sync_b_in[2] : sync_a_in[2]; //sync href signal
    href_in <= href_buff;
    pixel_buff <= (cam_sel)? data_b_in : data_a_in; //sync pixels
    pixel_in <= pixel_buff;
  end

  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS,respectively
  hdmi_clk_wiz_720p mhdmicw (
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x),
      .reset(0),
      .locked(0),
      .clk_ref(clk_in)
  );

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

  //two-port BRAM used to hold image from camera.
  //because camera is producing video for 320 by 240 pixels at ~30 fps
  //but our display is running at 720p at 60 fps, there's no hope to have the
  //production and consumption of information be synchronized in this system
  //instead we use a frame buffer as a go-between. The camera places pixels in at
  //its own rate, and we pull them out for display at the 720p rate/requirement
  //this avoids the whole sync issue. It will however result in artifacts when you
  //introduce fast motion in front of the camera. These lines/tears in the image
  //are the result of unsynced frame-rewriting happening while displaying. It won't
  //matter for slow movement
  //also note the camera produces a 320*240 image, but we display it 240 by 320
  //(taken care of by the rotate module below).
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16), //each entry in this memory is 16 bits
    .RAM_DEPTH(320*240)) //there are 240*320 or 76800 entries for full frame
    frame_buffer (
    .addra((freeze_img)? 0 : hcount_rec + 320*vcount_rec), //pixels are stored using this math; "stop storing pixels" when told to freeze
    .clka(clk_pixel),
    .wea((freeze_img)? 0 : data_valid_rec),
    .dina(pixel_data_rec),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(), //never read from this side
    .addrb(img_addr_rot),//transformed lookup pixel; if running manta, edit this line to be pixel that manta requests
    .dinb(16'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(valid_addr_rot), // if using manta, edit this line to be always 1'b1
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb(frame_buff_raw)
  );

  //start of the full video pipeline is here...
  //hcount, vcount, etc... are used for coming up with what to draw.

  //first question, given an hcount,vcount, should we draw/not draw something from
  //the camera. Assume the camera image is normally a 240-by-320 (width, height)
  //image in the top left of the screen. Depending on inputs you may want to scale up
  // to either 480*640 or a horizontally stretched 960*640
  // valid_addr_out indicates if hcount/vcount within range of this scaling
  //scale_in specifies how much to scale up image:
  // * 'b00: factor of 1
  // * 'b01: undefined
  // * 'b10: factor of 4 in h and 2 in v
  // * 'b11: factor of 2
  scale(
    .scale_in(2'b0), // no scaling in this version
    .hcount_in(hcount),
    .vcount_in(vcount),
    .scaled_hcount_out(hcount_scaled),
    .scaled_vcount_out(vcount_scaled),
    .valid_addr_out(valid_addr_scaled)
  );

  //Rotates and mirror-images Image to render correctly (pi/2 CCW rotate):
  // The output address should be fed right into the frame buffer for lookup
  rotate rotate_m (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .hcount_in(hcount_scaled),
    .vcount_in(vcount_scaled),
    .valid_addr_in(valid_addr_scaled),
    .pixel_addr_out(img_addr_rot),
    .valid_addr_out(valid_addr_rot)
    );

  //the Port B of the frame buffer would exist here.
  // The output of rotate is used to grab a pixel from it
  // however the output of the memory is always *something* even when we are
  // reading at address 0...so we need to know whether or not what we're getting
  // is legit data (within the bounds of the frame buffer's render)
  // we utilize valid_addr_rot for this, but have to pipeline it by two cycles
  // in order to make sure the valid signal is lined up in time with the signal
  // it is being used to validate:

  always_ff @(posedge clk_pixel)begin
    valid_addr_rot_pipe[0] <= valid_addr_rot;
    valid_addr_rot_pipe[1] <= valid_addr_rot_pipe[0];
  end
  assign frame_buff = valid_addr_rot_pipe[1]?frame_buff_raw:16'b0;

  //split fame_buff into 3 8 bit color channels (5:6:5 adjusted accordingly)
  assign fb_red = {frame_buff[15:11],3'b0};
  assign fb_green = {frame_buff[10:5], 2'b0};
  assign fb_blue = {frame_buff[4:0],3'b0};

  // PIPELINING (PS1)
  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(8)) ps1_red (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in(fb_red),
    .data_out(p_red) );

  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(8)) pst_green (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in(fb_green),
    .data_out(p_green) );
  
  pipelining #(
    .DEPTH(3),
    .DATA_WIDTH(8)) ps1_blue (
    .clk_in(clk_pixel),
    .rst_in(rst_in),
    .data_in(fb_blue),
    .data_out(p_blue) );

  logic [7:0] p_red;
  logic [7:0] p_green;
  logic [7:0] p_blue;

  logic [10:0] hcount_pipe;
  logic [9:0] vcount_pipe;
  
  pipelining #(
                   .DEPTH(7),
                   .DATA_WIDTH(11)  )
                 (
                   .clk_in(clk_pixel),
                   .rst_in(rst_in),
                   .data_in(hcount),
                   .data_out(hcount_pipe)  );

  pipelining #(
                   .DEPTH(7),
                   .DATA_WIDTH(10)  )
                 (
                   .clk_in(clk_pixel),
                   .rst_in(rst_in),
                   .data_in(vcount),
                   .data_out(vcount_pipe)  );

  logic [23:0] pixelin_pipe;
  logic [7:0] channel_pipe;
  
  pipelining #( .DEPTH(4), .DATA_WIDTH(24) )
                ( .clk_in(clk_pixel),
                  .rst_in(rst_in),
                  .data_in({fb_red, fb_green, fb_blue}),
                  .data_out(pixelin_pipe) );

  video_mux (
    .bg_in(0), //choose background
    .target_in(0),//target_choice), //choose target
    .camera_pixel_in(pixelin_pipe), //TODO: needs (PS2)
    //.camera_y_in(y_pipe), //luminance TODO: needs (PS6)
    //.channel_in(channel_pipe), //current channel being drawn TODO: needs (PS5)
    //.thresholded_pixel_in(mask), //one bit mask signal TODO: needs (PS4)
    //.crosshair_in(chin_pipe), //TODO: needs (PS8)
    //.com_sprite_pixel_in(sprite_pipe), //TODO: needs (PS9) maybe?
    .pixel_out({red,green,blue}) //output to tmds
  );

  //TODO: Appropriate signals below need to use outputs from PS7

  //three tmds_encoders (blue, green, red)
  tmds_encoder tmds_red(
	.clk_in(clk_pixel),
  .rst_in(rst_in),
	.data_in(red),
  .control_in(2'b0),
	.ve_in(active_draw),
	.tmds_out(tmds_10b[2]));

  tmds_encoder tmds_green(
	.clk_in(clk_pixel),
  .rst_in(rst_in),
	.data_in(green),
  .control_in(2'b0),
	.ve_in(active_draw),
	.tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
	.clk_in(clk_pixel),
  .rst_in(rst_in),
	.data_in(blue),
  .control_in({vert_sync,hor_sync}),
	.ve_in(active_draw),
	.tmds_out(tmds_10b[0]));

  //four tmds_serializers (blue, green, red, and clock)
  tmds_serializer red_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(rst_in),
    .tmds_in(tmds_10b[2]),
    .tmds_out(tmds_signal[2]));

  tmds_serializer green_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(rst_in),
    .tmds_in(tmds_10b[1]),
    .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(rst_in),
    .tmds_in(tmds_10b[0]),
    .tmds_out(tmds_signal[0]));

  //output buffers generating differential signal:
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

endmodule

`default_nettype wire



