`timescale 1ns / 1ps
`default_nettype none

// 

module calculate_ssd_tb;

    logic clk_in;
    logic rst_in;

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
        
        $display("Finishing Sim"); //print nice message
        $finish;
    end
    
    

endmodule
`default_nettype wire

