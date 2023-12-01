`timescale 1ns / 1ps
`default_nettype none

// iverilog -g2012 -o sim/sim.out sim/calculate_ssd_tb.sv hdl/mac_engine_48bit.sv hdl/calculate_ssd.sv

module calculate_ssd_tb;
    logic clk_in;
    logic rst_in;
    logic valid_in;
    logic [$clog2(240):0] left_current_x;
    logic [$clog2(240):0] right_current_x;
    logic [$clog2(320):0] left_current_y;
    logic [$clog2(320):0] right_current_y;
    logic [$clog2(240):0] left_block_idx;
    logic [$clog2(240):0] right_block_idx;
    logic [47:0] left_front_buffer  [5:0];
    logic [47:0] left_back_buffer   [5:0];
    logic [47:0] right_front_buffer [5:0];
    logic [47:0] right_back_buffer  [5:0];
    logic valid_out;
    logic [$clog2(255*255*6*6):0] ssd_out;


    calculate_ssd_block uut (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .valid_in(valid_in),
        .left_current_x(left_current_x),
        .right_current_x(right_current_x),
        .left_current_y(left_current_y),
        .right_current_y(right_current_y),
        .left_block_idx(left_block_idx),
        .right_block_idx(right_block_idx),
        .left_front_buffer(left_front_buffer),
        .left_back_buffer(left_back_buffer),
        .right_front_buffer(right_front_buffer),
        .right_back_buffer(right_back_buffer),
        .valid_out(valid_out),
        .ssd_out(ssd_out)
    );

    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("ssd.vcd");
        $dumpvars(0, calculate_ssd_tb);
        $display("Starting Sim");

        clk_in = 0;
        rst_in = 0;

        #10;
        rst_in = 1;
        #10;
        rst_in = 0;

        // Test Case 1: 
        // Description: left block and right block located at same position (top left corner)
        left_current_x = 0;
        right_current_x = 0;
        left_current_y = 0;
        right_current_y = 0;
        left_block_idx = 0;
        right_block_idx = 0;

        left_front_buffer[0] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[1] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[2] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[3] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[4] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[5] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;

        left_back_buffer[0] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[1] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[2] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[3] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[4] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[5] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;

        right_front_buffer[0] = 0;
        right_front_buffer[1] = 0;
        right_front_buffer[2] = 0;
        right_front_buffer[3] = 0;
        right_front_buffer[4] = 0;
        right_front_buffer[5] = 0;
        
        right_back_buffer[0] = 0;
        right_back_buffer[1] = 0;
        right_back_buffer[2] = 0;
        right_back_buffer[3] = 0;
        right_back_buffer[4] = 0;
        right_back_buffer[5] = 0;
        valid_in = 1;

        #10;
        valid_in = 0;

        #100000;

        // Test Case 2: 
        // Description: left block and right block located at same position (top left corner)
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;


        left_current_x = 0;
        right_current_x = 2;
        left_current_y = 0;
        right_current_y = 0;
        left_block_idx = 0;
        right_block_idx = 0;

        left_front_buffer[0] = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_front_buffer[1] = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_front_buffer[2] = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_front_buffer[3] = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_front_buffer[4] = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_front_buffer[5] = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_back_buffer[0]  = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_back_buffer[1]  = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_back_buffer[2]  = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_back_buffer[3]  = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_back_buffer[4]  = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;
        left_back_buffer[5]  = 48'b1100_1000_1100_1000_1100_1000_1100_1000_1100_1000_1100_1000;

        right_front_buffer[0] = 0;
        right_front_buffer[1] = 0;
        right_front_buffer[2] = 0;
        right_front_buffer[3] = 0;
        right_front_buffer[4] = 0;
        right_front_buffer[5] = 0;
        
        right_back_buffer[0] = 0;
        right_back_buffer[1] = 0;
        right_back_buffer[2] = 0;
        right_back_buffer[3] = 0;
        right_back_buffer[4] = 0;
        right_back_buffer[5] = 0;
        valid_in = 1;

        #10;
        valid_in = 0;

        #100000;

        // Test Case 3: 
        // Description: left block and right block located at same position (top left corner)
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;


        left_current_x = 0;
        right_current_x = 5;
        left_current_y = 0;
        right_current_y = 0;
        left_block_idx = 0;
        right_block_idx = 0;

        left_front_buffer[0] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[1] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[2] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[3] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[4] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_front_buffer[5] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;

        left_back_buffer[0] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[1] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[2] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[3] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[4] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        left_back_buffer[5] = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;

        right_front_buffer[0] = 0;
        right_front_buffer[1] = 0;
        right_front_buffer[2] = 0;
        right_front_buffer[3] = 0;
        right_front_buffer[4] = 0;
        right_front_buffer[5] = 0;
        
        right_back_buffer[0] = 0;
        right_back_buffer[1] = 0;
        right_back_buffer[2] = 0;
        right_back_buffer[3] = 0;
        right_back_buffer[4] = 0;
        right_back_buffer[5] = 0;
        valid_in = 1;

        #10;
        valid_in = 0;

        #100000;




        $display("Finishing Sim"); //print nice message
        $finish;
    end

    

endmodule
`default_nettype wire

