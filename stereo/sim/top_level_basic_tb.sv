`timescale 1ns / 1ps
`default_nettype none

module top_level_basic_tb;
    logic clk_in;
    logic sys_rst;

    logic [$clog2(320):0] left_hcount;
    logic [$clog2(40):0]  left_vcount;
    logic [$clog2(320):0] right_hcount;
    logic [$clog2(40):0]  right_vcount;

    top_level_basic uut (.clk_100mhz(clk_in),
                   .sys_rst(sys_rst),
                   .left_hcount(left_hcount),
                   .left_vcount(left_vcount),
                   .right_hcount(right_hcount),
                   .right_vcount(right_vcount));
    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top_level_tb);
        $display("Starting Sim");

        clk_in = 0;
        sys_rst = 0;
        #10;
        // Recall we are using zero indexing for hcount and vcount
        // case 1: try accesing some simple location
        // Correct: Left = 6f7569667176, Right = 72756e747575
        left_hcount = 1;
        left_vcount = 2;

        right_hcount = 1;
        right_vcount = 2;
        #100;
        // case 2: try accesing more last location
        // Correct: Left = 858585858685, Right = 8a8988868686
        left_hcount = 319;
        left_vcount = 39;

        right_hcount = 319;
        right_vcount = 39;
        #100;
        // case 3: try accesing different locations left/right
        // Correct: Left = 4a624b625758, Right = 5262515a5a6a
        left_hcount = 0;
        left_vcount = 10;

        right_hcount = 10;
        right_vcount = 10;
        #100;
        

        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule 

`default_nettype wire