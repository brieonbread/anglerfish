// Iterate through left/right center pixels
  // Iterate thorugh offsets
    // For a given center pixel, determine if we need to update buffers by reading from BRAMs
    // Assuming that buffers are updated, run ssd calculation on the buffers
  // Save this and then rerun process with a different offset, keep the smaller of the two
// When all offsets have been calculated, updates the ssd results BRAM

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
  input sys_rst,
  input wire new_frame_in,   // flag tells us when new frame is ready for processing
  input wire writing_image,  // high when writing to left/right frame buffer, low when not
  input wire [$clog2(320*40)-1:0] external_left_addr, 
  input wire [$clog2(320*40)-1:0] external_right_addr,
  input wire [7:0] left_din,
  input wire [7:0] right_din,
  input wire reading,    // high when reading from ssd buffer, low when not
  input wire [$clog2(320*240)-1:0] external_ssd_addr,
  output logic [7:0] ssd_dout,
  output logic new_frame_out, // flag tells us when frame is done processing
  );


  // logics associated with left/right BRAMs
  logic [47:0] left_dout;
  logic [47:0] right_dout;

  logic [$clog2(320*40)-1:0] left_address;
  logic [$clog2(320*40)-1:0] right_address;

  // logics associated with ssd result BRAM, we want to store offsets not ssd values
  logic [7:0] ssd_din; // assume max offset is 240

  logic ssd_wea;
  logic [$clog2(320*240)-1:0] ssd_addr;
  logic [$clog2(320*240)-1:0] readout_addr;

  
  // logics asociated with temp buffers
  logic [5:0][47:0] left_front_buffer;
  logic [5:0][47:0] left_back_buffer;
  logic [5:0][47:0] right_front_buffer;
  logic [5:0][47:0] right_back_buffer;

  // create a bunch of temp vars so we can see array in GTK wave
  logic [47:0] lfb_0, lfb_1, lfb_2, lfb_3, lfb_4, lfb_5;
  logic [47:0] lbb_0, lbb_1, lbb_2, lbb_3, lbb_4, lbb_5;
  logic [47:0] rfb_0, rfb_1, rfb_2, rfb_3, rfb_4, rfb_5;
  logic [47:0] rbb_0, rbb_1, rbb_2, rbb_3, rbb_4, rbb_5;
  
  assign lfb_0 = left_front_buffer[0];
  assign lfb_1 = left_front_buffer[1];
  assign lfb_2 = left_front_buffer[2];
  assign lfb_3 = left_front_buffer[3];
  assign lfb_4 = left_front_buffer[4];
  assign lfb_5 = left_front_buffer[5];

  assign lbb_0 = left_back_buffer[0];
  assign lbb_1 = left_back_buffer[1];
  assign lbb_2 = left_back_buffer[2];
  assign lbb_3 = left_back_buffer[3];
  assign lbb_4 = left_back_buffer[4];
  assign lbb_5 = left_back_buffer[5];

  assign rfb_0 = right_front_buffer[0];
  assign rfb_1 = right_front_buffer[1];
  assign rfb_2 = right_front_buffer[2];
  assign rfb_3 = right_front_buffer[3];
  assign rfb_4 = right_front_buffer[4];
  assign rfb_5 = right_front_buffer[5];

  assign rbb_0 = right_back_buffer[0];
  assign rbb_1 = right_back_buffer[1];
  assign rbb_2 = right_back_buffer[2];
  assign rbb_3 = right_back_buffer[3];
  assign rbb_4 = right_back_buffer[4];
  assign rbb_5 = right_back_buffer[5];


  // wires and params associated with the state machine
  typedef enum {IDLE=0, UPDATE_CENTERS=1, UPDATE_BUFFERS=2, CALCULATE=3, UPDATE_DISPARITY=4, SAVE=5, NEW_FRAME=6} stereo_states;
  stereo_states top_state;

  logic [2:0] SAVE_counter;


  // logics associated with top level indexing/coords
  logic [$clog2(320):0] current_left_y;
  logic [$clog2(240):0] current_left_x;
  logic [$clog2(320):0] current_right_y;
  logic [$clog2(240):0] current_right_x;

  logic [$clog2(320):0] prev_left_y; // used for remembering where to save ssd output to 
  logic [$clog2(240):0] prev_left_x;
  logic [$clog2(320):0] prev_right_y;
  logic [$clog2(240):0] prev_right_x;

  logic [$clog2(240):0] left_block_idx;   // increments by 6 each time
  logic [$clog2(240):0] right_block_idx;  // increments by 6 each time
  logic [$clog2(240):0] left_word_idx;    // increments by 1 each time
  logic [$clog2(240):0] right_word_idx;   // increments by 1 each time

  
  logic [$clog2(BLOCK_SIZE):0] left_block_counter; // counts within block, used to keep track of when to update left_block_idx
  logic [$clog2(BLOCK_SIZE):0] right_block_counter; // counts within block, used to keep track of when to update right_block_idx

  // logics associated with updating_buffes and calculate_ssd modules
  logic write_to_front;
  logic update_buffer_valid_in;
  logic update_buffer_valid_out;
  logic calculate_ssd_valid_in;
  logic calculate_ssd_valid_out;
  logic [$clog2(255*255*6*6):0] ssd_out;
  logic [$clog2(255*255*6*6):0] min_ssd_sofar;
  logic [$clog2(240)-1:0] min_offset_sofar;

  // NOTE: these bounds are inclusive
  parameter left_y_min = 0;
  parameter left_y_max = 320-BLOCK_SIZE;
  parameter left_x_min = 0;
  // parameter left_x_min = 20; // DEBUG
  parameter left_x_max = 240-BLOCK_SIZE;

  parameter right_y_min = 0;
  parameter right_y_max = 320-BLOCK_SIZE;
  parameter right_x_min = 0;
  parameter right_x_max = 240-BLOCK_SIZE;


  always_ff @ (posedge clk_100mhz) begin
    if (sys_rst) begin
      top_state               <= IDLE;
      new_frame_out           <= 0;
      update_buffer_valid_in  <= 0;
      calculate_ssd_valid_in  <= 0;
      
      current_left_y  <= left_y_min;
      current_left_x  <= left_x_min;
      current_right_y <= right_y_min;
      current_right_x <= right_x_min;

      left_block_idx      <= '0;
      left_word_idx       <= '0;
      right_word_idx      <= '0;
      right_block_idx     <= '0;
      left_block_counter  <= '0;	  
      right_block_counter <= '0;
      
      // set ssd_out to be some value
      
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
          update_buffer_valid_in <= 1;
          
          left_block_idx      <= 0;
          left_word_idx       <= 0;
          right_word_idx      <= 0;
          right_block_idx     <= 0;
          left_block_counter  <= 0;
          right_block_counter <= 0;

          min_ssd_sofar <= 23'b1111_1111_1111_1111_1111_111;

          new_frame_out           <= 0;
          calculate_ssd_valid_in  <= 0;


        end
        UPDATE_CENTERS: begin
          ssd_wea <= 0; // disable writing to sssd BRAM
          if ((current_left_x == left_x_max) && (current_left_y == left_y_max)) begin
            // terminate, we are done with this frame
            top_state <= IDLE;
            new_frame_out <= 1;
            
          end else if (current_left_x == left_x_max) begin
            // we have reached end of row, start a new row
            current_left_x      <= left_x_min;
            current_right_x     <= right_x_min;
            current_left_y      <= current_left_y + 1;
            current_right_y     <= current_right_y + 1;
            left_block_idx      <= 0; // block idxs only relevant in 'x' direction
            right_block_idx     <= 0;
            left_word_idx       <= 0;
            right_word_idx      <= 0;
            left_block_counter  <= 0;
            right_block_counter <= 0;

            // update left/right buffers
            top_state <= UPDATE_BUFFERS;
            update_buffer_valid_in <= 1;

          end else if (current_right_x == current_left_x) begin
            
            // we have reached end of disparity calc for the left pixel, shift the left pixel over by 1
            current_left_x  <= current_left_x + 1;
            current_right_x <= 0; // NOTE: we assume that any match in right image will be "ahead" of left image
            
            // reset min so far reg
            min_ssd_sofar <= 23'b1111_1111_1111_1111_1111_111;

            // update left/right buffers
            top_state <= UPDATE_BUFFERS;
            update_buffer_valid_in <= 1;

            // update left block counters/idx
            // this essentially implements the modulus operation using counters, we want left_block_idx to be incremented by 6
            if (left_block_counter == 5) begin
              left_block_idx     <= left_block_idx + 6;
              left_word_idx      <= left_word_idx + 1;
              left_block_counter <= 0;
            end else begin 
              left_block_counter <= left_block_counter + 1;
            end

            right_block_idx     <= 0;
            right_word_idx      <= 0;
            right_block_counter <= 0;

          end else begin
            // shift right block over by one pixel
            current_right_x <= current_right_x + 1;

            // update right block counters/idx
            // this essentially implements the modulus operation using counters, we want right_block_idx to be incremented by 6
            if (right_block_counter == 5) begin
              right_block_idx      <= right_block_idx + 6;
              right_word_idx       <= right_word_idx + 1;
              right_block_counter  <= 0;
            end else begin 
              right_block_counter <= right_block_counter + 1;
            end

            // update right buffer
            top_state <= UPDATE_BUFFERS;
            update_buffer_valid_in <= 1;

          end
          
        end
        UPDATE_BUFFERS: begin
          // given some arbitrary center coord for x and y pixel, make sure front/back buffers have the correct values
          // access BRAM at appropriate addresses
          update_buffer_valid_in <= 0;

          if (update_buffer_valid_out) begin
            // update_buffer_valid_in <= 0;
            top_state <= CALCULATE;
            calculate_ssd_valid_in <= 1;
          end

        end
        CALCULATE: begin
          calculate_ssd_valid_in <= 0;
          if (calculate_ssd_valid_out) begin
            top_state <= UPDATE_DISPARITY;
          end
          
        end
        UPDATE_DISPARITY: begin
          if (ssd_out <= min_ssd_sofar) begin
            min_ssd_sofar    <= ssd_out; // this might be sus... what if ssd_out changes on next cycle?
            min_offset_sofar <= current_left_x - current_right_x; // should be a non negative number
          end
          top_state <= SAVE;
          SAVE_counter <= 0;
        end
        SAVE: begin
          prev_left_y  <= current_left_y; // used for remembering where to save ssd output to 
          prev_left_x  <= current_left_x;
          prev_right_y <= current_right_y;
          prev_right_x <= current_right_x;

          // $display("(%d,%d): ", prev_left_x, prev_left_y);
          // $display("Min ssd so far: %d", ssd_out);

          if (SAVE_counter == 1) begin
            // save to bram
            top_state <= UPDATE_CENTERS;
            ssd_wea <= 1;
            ssd_addr <= prev_left_y * 240 + prev_left_x;
            ssd_din <= min_offset_sofar;

            // $display("(%d,%d): ", prev_left_x, prev_left_y);
            // $display("Min ssd so far: %d", min_ssd_sofar);

          end else begin
            SAVE_counter <= SAVE_counter + 1;
          end

          


        end

      endcase
    end


  end

  update_buffers_basic inst_update (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_in(update_buffer_valid_in),
    .left_current_y(current_left_y),
    .right_current_y(current_right_y),
    .left_word_idx(left_word_idx),
    .right_word_idx(right_word_idx),
    .left_dout(left_dout),
    .right_dout(right_dout),
    .left_front_buffer(left_front_buffer),
    .left_back_buffer(left_back_buffer),
    .right_front_buffer(right_front_buffer),
    .right_back_buffer(right_back_buffer),
    .left_address(left_address),
    .right_address(right_address),
    .valid_out(update_buffer_valid_out)
  );

  calculate_ssd_block inst_ssd (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_in(calculate_ssd_valid_in),
    .left_current_x(current_left_x),
    .right_current_x(current_right_x),
    .left_current_y(current_left_y),
    .right_current_y(current_right_y),
    .left_block_idx(left_block_idx),
    .right_block_idx(right_block_idx),
    .left_front_buffer(left_front_buffer),
    .left_back_buffer(left_back_buffer),
    .right_front_buffer(right_front_buffer),
    .right_back_buffer(right_back_buffer),
    .valid_out(calculate_ssd_valid_out),
    .ssd_out(ssd_out)
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
xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(48), // NOTE: assume block size = 6
    .RAM_DEPTH(320*40), // NOTE: assume block size = 6
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(left_image.mem))
  )
    left_frame_buffer (
    .addra((writing_image) ? external_left_addr : left_address), //pixels are stored using this math, assumes 0 indexing
    .clka(clk_100mhz),
    .wea(writing_image),
    .dina(left_din),
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
    .addra((writing_image) ? external_right_addr : right_address), //pixels are stored using this math, assumes 0 indexing
    .clka(clk_100mhz),
    .wea(writing_image),
    .dina(right_din),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(right_dout)
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),// CHANGE ME: assume max disparity = 240, assume max ssd = 360000
    .RAM_DEPTH(320*240), // NOTE: assume block size = 6
    .RAM_PERFORMANCE("HIGH_PERFORMANCE")
    )
    ssd_result (
    .addra((reading)? external_ssd_addr : ssd_addr), //pixels are stored using this math, assumes 0 indexing
    .clka(clk_100mhz),
    .wea((reading)? 1'b0 : 1'b1),
    .dina(ssd_din),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst), 
    .douta(ssd_dout)
  );

  

 
endmodule


