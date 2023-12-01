`timescale 1ns / 1ps
`default_nettype none

// iverilog -g2012 -o sim/sim.out sim/mac_engine_tb.sv hdl/mac_engine.sv

module mac_tb_48bit;
    logic clk_in;
    logic rst_in;
    logic [47:0] left_pixel;
    logic [47:0] right_pixel;
    logic valid_in;
    logic [$clog2(255*255*6):0] accumulator;

    mac_engine_48bit uut (.clk_in(clk_in),
                    .rst_in(rst_in),
                    .left_row(left_pixel),
                    .right_row(right_pixel),
                    .valid_in(valid_in),
                    .accumulator(accumulator));
    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("mac_48.vcd");
        $dumpvars(0, mac_tb_48bit);
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

        // Test Case 1: Answer = 60000
        left_pixel = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        right_pixel = 0;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;

        // Test Case 2: Answer = 60000
        left_pixel = 0;
        right_pixel = 48'b0110_0100_0110_0100_0110_0100_0110_0100_0110_0100_0110_0100;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;

        // Test Case 3: Answer = 390150
        left_pixel = 0;
        right_pixel = 48'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
        valid_in = 1;
        #10
        valid_in = 0;
        #120;

        rst_in = 1;
        #10;
        rst_in = 0;


        $display("Finishing Sim"); //print nice message
        $finish;
    end


endmodule 

`default_nettype wire