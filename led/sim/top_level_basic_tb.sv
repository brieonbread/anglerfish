`timescale 1ns / 1ps
`default_nettype none

// iverilog -g2012 -o sim/sim.out sim/top_level_tb.sv hdl/led_driver.sv hdl/top_level.sv
// ./remote/r.py build.py build.tcl hdl/* xdc/top_level.xdc obj/
module top_level_basic_tb();
    logic clk_in;
    logic [3:0] btn;
    logic [2:0] rgb0;
    logic [2:0] rgb1;
    logic [7:0] pmoda;

    top_level uut (.clk_100mhz(clk_in),
                   .btn(btn),
                   .rgb0(rgb0),
                   .rgb1(rgb1),
                   .pmoda(pmoda));

    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
    end

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top_level_basic_tb);
        $display("Starting Sim");
        clk_in = 0;
        #10;
        btn[0] = 1;
        #10;
        btn[0] = 0;
        #1500000;
        btn[0] = 1;
        #10;
        btn[0] = 0;
        #1500000;
        btn[0] = 1;
        #10;
        btn[0] = 0;
        #1500000;

        $display("Simulation finished");
        $finish;

        
    end
    

endmodule

`default_nettype wire