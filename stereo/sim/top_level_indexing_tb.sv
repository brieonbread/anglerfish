`timescale 1ns / 1ps
`default_nettype none

// 

module top_level_indexing_tb;
    logic clk_in;
    logic rst_in;
    logic new_frame_in;

    top_level uut (
        .clk_100mhz(clk_in),
        .sys_rst(rst_in),
        .new_frame_in(new_frame_in)
    );

    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("top_index.vcd");
        $dumpvars(0, top_level_indexing_tb);
        $display("Starting Sim");

        clk_in = 0;
        rst_in = 0;

        #10;
        rst_in = 1;
        #10;
        rst_in = 0;
        new_frame_in = 1;
        #10;
        new_frame_in = 0;

        #100000000;
        $display("Finishing Sim"); //print nice message
        $finish;
    end
    
    

endmodule
`default_nettype wire

