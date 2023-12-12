`timescale 1ns / 1ps
`default_nettype none

// iverilog -g2012 -o sim/sim.out sim/update_buffers_tb.sv hdl/update_buffers.sv hdl/xilinx_single_port_ram_read_first.v

// NOTE: allows for easy switching between synthesis and simulation
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module update_buffers_tb;
    logic clk_in;
    logic rst_in;
    logic valid_in;
    logic [$clog2(240):0] left_current_x;
    logic [$clog2(240):0] right_current_x;
    logic [$clog2(320):0] left_current_y;
    logic [$clog2(320):0] right_current_y;
    logic [47:0] left_dout;
    logic [47:0] right_dout;
    logic write_to_front; // 1: write to front L/R buffers, 0: write to back L/R buffers
    logic [5:0][47:0]left_front_buffer;
    logic [5:0][47:0]left_back_buffer;
    logic [5:0][47:0]right_front_buffer;
    logic [5:0][47:0]right_back_buffer;
    logic [$clog2(320*40)-1:0] left_address;
    logic [$clog2(320*40)-1:0] right_address;
    logic valid_out;

    

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

    update_buffers uut (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .valid_in(valid_in),
        .left_current_x(left_current_x),
        .right_current_x(right_current_x),
        .left_current_y(left_current_y),
        .right_current_y(right_current_y),
        .left_dout(left_dout),
        .right_dout(right_dout),
        .write_to_front(write_to_front),
        .left_front_buffer(left_front_buffer),
        .left_back_buffer(left_back_buffer),
        .right_front_buffer(right_front_buffer),
        .right_back_buffer(right_back_buffer),
        .left_address(left_address),
        .right_address(right_address),
        .valid_out(valid_out)
    );


    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("update_buffers.vcd");
        $dumpvars(0, update_buffers_tb);
        $display("Starting Sim");

        clk_in = 0;
        rst_in = 0;

        # 10;
        rst_in = 1;
        # 10;
        rst_in = 0;

        // TODO: we need more comprehensive test cases here!!!

        // Test Case 1: write to front buffer
        
        left_current_x  = 0;
        right_current_x = 0;
        left_current_y  = 0;
        right_current_y = 0;
        valid_in = 1;
        # 10;
        valid_in = 0;

        write_to_front = 1;
        
        // Test Case 1: write to front buffer
        
        left_current_x  = 1;
        right_current_x = 0;
        left_current_y  = 0;
        right_current_y = 0;
        valid_in = 1;
        # 10;
        valid_in = 0;

        write_to_front = 1;
        

        // Test Case 1: write to front buffer
        
        left_current_x  = 0;
        right_current_x = 0;
        left_current_y  = 0;
        right_current_y = 0;
        valid_in = 1;
        # 10;
        valid_in = 0;

        write_to_front = 1;
        

        # 5000;

        // Test Case 2: write to back buffer
        left_current_x  = 0;
        right_current_x = 0;
        left_current_y  = 0;
        right_current_y = 0;
        valid_in = 1;
        # 10;
        valid_in = 0;

        write_to_front = 0;
        # 5000;

        // Test Case 3: try a non trivial x, y, front buffer
        left_current_x  = 1;
        left_current_y  = 1;
        right_current_x = 2;
        right_current_y = 2;
        valid_in = 1;
        # 10;
        valid_in = 0;

        write_to_front = 1;
        # 5000;

        // Test Case 4: try a non trivial x, y, back buffer
        left_current_x  = 1;
        right_current_x = 1;
        left_current_y  = 2;
        right_current_y = 2;
        valid_in = 1;
        # 10;
        valid_in = 0;

        write_to_front = 0;
        # 5000;

        $display("Finishing Sim"); //print nice message
        $finish;
    end
    
    
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
    .clka(clk_in),
    .wea(1'b0),
    .dina(48'b0),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
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
    .clka(clk_in),
    .wea(1'b0),
    .dina(48'b0),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(right_dout)
  );

endmodule
`default_nettype wire



