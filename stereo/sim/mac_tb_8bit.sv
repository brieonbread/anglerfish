`timescale 1ns / 1ps
`default_nettype none

// iverilog -g2012 -o sim/sim.out sim/mac_engine_tb.sv hdl/mac_engine.sv

module mac_engine_tb;

    logic clk_in;
    logic rst_in;
    logic [7:0] left_pixel;
    logic [7:0] right_pixel;
    logic valid_in;
    logic [$clog2(255*255*6):0] accumulator;

    mac_engine_8bit uut (.clk_in(clk_in),
                    .rst_in(rst_in),
                    .left_pixel(left_pixel),
                    .right_pixel(right_pixel),
                    .valid_in(valid_in),
                    .accumulator(accumulator));
    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("mac.vcd");
        $dumpvars(0, mac_engine_tb);
        $display("Starting Sim");

        // TODO: define array instead for test cases
        // TODO: define input file with input/output data, one file with results
        // TODO: save mac engine output file
        clk_in = 0;
        rst_in = 0;
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;

        left_pixel = 100;
        right_pixel = 90;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;

        left_pixel = 90;
        right_pixel = 100;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;

        left_pixel = 0;
        right_pixel = 0;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;

        left_pixel = 255;
        right_pixel = 254;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;

        left_pixel = 255;
        right_pixel = 0;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;

        left_pixel = 255;
        right_pixel = 1;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;



        $display("Finishing Sim"); //print nice message
        $finish;
    end


endmodule 

`default_nettype wire