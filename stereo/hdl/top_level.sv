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

parameter BLOCK_SIZE = 6; // NOTE: the block size influences basically every aspect of this module

module top_level(
  input wire clk_100mhz,
  input wire sys_rst,
  input wire new_frame_in
  // input wire [$clog2(320):0] left_hcount,
  // input wire [$clog2(40):0]  left_vcount,
  // input wire [$clog2(320):0] right_hcount,
  // input wire [$clog2(40):0]  right_vcount
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
  // assign left_address  = (40*left_hcount + left_vcount);
  // assign right_address = (40*right_hcount + right_vcount);
  assign left_address  = (40*current_left_y  + current_left_x);
  assign right_address = (40*current_right_y + current_right_x);
  
  logic [47:0] left_front_buffer  [5:0];
  logic [47:0] left_back_buffer   [5:0];
  logic [47:0] right_front_buffer [5:0];
  logic [47:0] right_back_buffer  [5:0];

  // define all wires and params related to the state machine
  typedef enum {IDLE=0, UPDATE_CENTERS=1, UPDATE_BUFFERS=2, CALCULATE=3, UPDATE_DISPARITY=4, SAVE=5, NEW_FRAME=6} stereo_states;
  stereo_states top_state;

  
  logic [$clog2(320):0] current_left_y;
  logic [$clog2(240):0] current_left_x;
  logic [$clog2(320):0] current_right_y;
  logic [$clog2(240):0] current_right_x;

  logic [$clog2(240):0] left_block_idx;
  logic [$clog2(240):0] right_block_idx;

  logic write_to_front;
  logic [$clog2(BLOCK_SIZE):0] left_block_counter; //used to keep track of when to update left_block_idx
  logic [$clog2(BLOCK_SIZE):0] right_block_counter; //used to keep track of when to update right_block_idx

  logic update_buffer_valid_in;
  logic update_buffer_valid_out;
  logic calculate_ssd_valid_in;
  logic calculate_ssd_valid_out;

  // NOTE: these bounds are inclusive
  parameter left_y_min = 0+3;
  parameter left_y_max = 319-4;
  parameter left_x_min = 0+3;
  parameter left_x_max = 239-4;

  parameter right_y_min = 0+3;
  parameter right_y_max = 319-4;
  parameter right_x_min = 0+3;
  parameter right_x_max = 239-4;


  always_ff @ (posedge clk_100mhz) begin
    if (sys_rst) begin
      top_state <= IDLE;
    end else begin
      case(top_state)
        IDLE: begin
          if (new_frame_in) begin
            top_state <= NEW_FRAME;
          end
        end
        NEW_FRAME: begin
          current_left_y  <= left_y_min;
          current_left_x  <= left_x_min;
          current_right_y <= right_y_min;
          current_right_x <= right_x_min;
          top_state       <= UPDATE_BUFFERS;

          left_block_idx      <= 0;
          right_block_idx     <= 0;
          left_block_counter  <= 0;
          right_block_counter <= 0;

        end
        UPDATE_CENTERS: begin
          if ((current_left_x == left_x_max) && (current_left_y == left_y_max)) begin
            // terminate, we are done with this frame
            top_state <= IDLE;
          end else if (current_left_x == left_x_max) begin
            // we have reached end of row, start a new row
            current_left_x      <= left_x_min;
            current_right_x     <= right_x_min;
            current_left_y      <= current_left_y + 1;
            current_right_y     <= current_right_y + 1;
            left_block_idx      <= 0; // block idxs only relevant in 'x' direction
            right_block_idx     <= 0;
            left_block_counter  <= 0;
            right_block_counter <= 0;

            // update left/right buffers
          end else if (current_right_x == right_x_max) begin
            // we have reached end of disparity calc for the left pixel, shift the left pixel over by 1
            current_left_x  <= current_left_x + 1;
            current_right_x <= current_left_x + 1; // NOTE: we assume that any match in right image will be "ahead" of left image
            // update left/right buffers
            // ...
            // update left block counters/idx
            // this essentially implements the modulus operation using counters, we want left_block_idx to be incremented by 6
            if (left_block_counter == 5) begin
              left_block_idx     <= left_block_idx + 6;
              left_block_counter <= 0;
            end else begin 
              left_block_counter <= left_block_counter + 1;
            end
            
            right_block_idx <= 0;
            right_block_counter <= 0;

          end else begin
            // shift right block over by one pixel
            current_right_x <= current_right_x + 1;
            // update right buffer
            // ...
            // update right block counters/idx
            // this essentially implements the modulus operation using counters, we want right_block_idx to be incremented by 6
            if (right_block_counter == 5) begin
              right_block_idx <= right_block_idx + 6;
              right_block_counter <= 0;
            end else begin 
              right_block_counter <= right_block_counter + 1;
            end

          end
          
          // we also need to update left/right block idx

          top_state <= UPDATE_BUFFERS;
        end
        UPDATE_BUFFERS: begin
          // given some arbitrary center coord for x and y pixel, make sure front/back buffers have the correct values
          // access BRAM at appropriate addresses
          top_state <= UPDATE_CENTERS; // NOTE: for debugging purposes only

        end
        CALCULATE: begin
          top_state <= UPDATE_DISPARITY;
        end
        UPDATE_DISPARITY: begin
          top_state <= SAVE;
        end
        SAVE: begin
          top_state <= UPDATE_CENTERS;
        end

      endcase
    end


  end

  // update_buffers inst_update (
  //   .clk_in(clk_100mhz),
  //   .rst_in(sys_rst),
  //   .valid_in(),
  //   .left_current_x(current_left_x),
  //   .right_current_x(),
  //   .left_current_y(),
  //   .right_current_y(),
  //   .left_dout(),
  //   .right_dout(),
  //   .write_to_front(),
  //   .left_front_buffer(),
  //   .left_back_buffer(),
  //   .right_front_buffer(),
  //   .right_back_buffer(),
  //   .left_address(),
  //   .right_address(),
  //   .valid_out()
  // );

  // calculate_ssd_block inst_ssd (
  //   .clk_in(clk_100mhz),
  //   .rst_in(sys_rst),
  //   .valid_in(),
  //   .left_current_x(),
  //   .right_current_x(),
  //   .left_current_y(),
  //   .right_current_y(),
  //   .left_block_idx(),
  //   .right_block_idx(),
  //   .left_front_buffer(),
  //   .left_back_buffer(),
  //   .right_front_buffer(),
  //   .right_back_buffer(),
  //   .valid_out(),
  //   .ssd_out(),
  // );

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

  // xilinx_single_port_ram_read_first #(
  //   .RAM_WIDTH(48),// NOTE: assume block size = 6
  //   .RAM_DEPTH(320*40), // NOTE: assume block size = 6
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
  //   )
  //   ssd_result (
  //   .addra(), //pixels are stored using this math, assumes 0 indexing
  //   .clka(clk_100mhz),
  //   .wea(),
  //   .dina(),
  //   .ena(),
  //   .regcea(),
  //   .rsta(sys_rst),
  //   .douta()
  // );
    
endmodule


