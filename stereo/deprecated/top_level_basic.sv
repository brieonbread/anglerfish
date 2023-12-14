// generate max_offset number of stereo match calculators
// iterate through pixels in left image, look up correspoding pixels in right image
// when ready, run the computation
// results written to a third bram
// assume for testing that left and right brams are initialized according to some test image values
// and that the brams are full
`timescale 1ns / 1ps
`default_nettype none

// NOTE: allows for easy switching between synthesis and simulation
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */


module top_level_basic(
  input wire clk_100mhz,
  input wire sys_rst,
  input wire [$clog2(320):0] left_hcount,
  input wire [$clog2(40):0]  left_vcount,
  input wire [$clog2(320):0] right_hcount,
  input wire [$clog2(40):0]  right_vcount
  );

  // used to index into the memory blocks, NOT pixel coordinates
  // logic [$clog2(320):0] left_hcount;
  // logic [$clog2(40):0]  left_vcount;
  // logic [$clog2(320):0] right_hcount;
  // logic [$clog2(40):0]  right_vcount;

  logic [47:0] left_dout;
  logic [47:0] right_dout;

  logic [$clog2(320*40)-1:0] left_address;
  logic [$clog2(320*40)-1:0] right_address;
  assign left_address  = (40*left_hcount + left_vcount);
  assign right_address = (40*right_hcount + right_vcount);
  
  

  logic [47:0] left_buffer_1;
  logic [47:0] left_buffer_2;
  logic [47:0] left_buffer_3;
  logic [47:0] left_buffer_4;
  logic [47:0] left_buffer_5;
  logic [47:0] left_buffer_6;

  logic [47:0] right_buffer_1;
  logic [47:0] right_buffer_2;
  logic [47:0] right_buffer_3;
  logic [47:0] right_buffer_4;
  logic [47:0] right_buffer_5;
  logic [47:0] right_buffer_6;



  // always_ff @ (posedge clk_100mhz) begin

  // end

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
xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(48), // NOTE: assume block size = 6
    .RAM_DEPTH(320*40), // NOTE: assume block size = 6
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(left_image.mem))
  )
    left_frame_buffer (
    .addra(left_address), //pixels are stored using this math, assumes 0 indexing
    .clka(clk_100mhz),
    .wea(1'b0),
    .dina(48'b0),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(left_dout)
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(48),// NOTE: assume block size = 6
    .RAM_DEPTH(320*40), // NOTE: assume block size = 6
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(right_image.mem))
    )
    right_frame_buffer (
    .addra(right_address), //pixels are stored using this math, assumes 0 indexing
    .clka(clk_100mhz),
    .wea(1'b0),
    .dina(48'b0),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(right_dout)
  );
    
endmodule


