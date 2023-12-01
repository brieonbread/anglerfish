`timescale 1ns / 1ps
`default_nettype none

module stereo_match_tb;
    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic [3:0] left_pixel_in;
    logic [3:0] right_pixel_in [8:0];
    logic valid_in;
    logic [8:0] ssd_out;
    logic valid_out;

    parameter SIZEIN = 4;
    logic ce;
    logic [SIZEIN-1:0] a;
    logic [SIZEIN-1:0] b;
    logic [2*SIZEIN+1:0] square_out;

    stereo_match uut(.clk_in(clk_in),
                     .rst_in(rst_in),
                     .left_pixel_in(left_pixel_in),
                     .right_pixel_in(right_pixel_in),
                     .valid_in(valid_in),
                     .ssd_out(ssd_out),
                     .valid_out(valid_out));

    squarediffmult # (.SIZEIN(SIZEIN)) uut_sdm (
        .clk(clk_in),
        .ce(ce),
        .rst(rst_in),
        .a(a),
        .b(b),
        .square_out(square_out));


    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("match.vcd");
        $dumpvars(0, stereo_match_tb);
        $display("Starting Sim");

        clk_in = 0;
        rst_in = 0;

        left_pixel_in = 20;
        right_pixel_in[0] = 22;
        right_pixel_in[1] = 18;
        right_pixel_in[2] = 22;
        right_pixel_in[3] = 18;
        right_pixel_in[4] = 22;
        right_pixel_in[5] = 18;
        right_pixel_in[6] = 22;
        right_pixel_in[7] = 18;
        right_pixel_in[8] = 22;

        // #10;
        // rst_in = 1;
        #10;
        valid_in = 1;
        #1000;

        // a = 20;
        // b = 25;
        // ce = 1;
        // #1000;

        // a = 20;
        // b = 25;
        // ce = 1;
        // #1000;

        // a = 0;
        // b = 0;
        // ce = 1;
        // #1000;

        // a = 0;
        // b = 1;
        // ce = 1;
        // #1000;

        // a = 14;
        // b = 2;
        // ce = 1;
        // #1000;


        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule

`default_nettype wire