`timescale 1ns / 1ps
`default_nettype none

module led_driver_tb();
    logic clk_in;
    logic rst_in;
    logic [23:0] rgb_in;
    logic valid_in;
    logic signal_out;

    led_driver uut (.clk_in(clk_in),
                    .rst_in(rst_in),
                    .rgb_in(rgb_in),
                    .valid_in(valid_in),
                    .signal_out(signal_out));

    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
    end

    initial begin
        $dumpfile("led.vcd");
        $dumpvars(0, led_driver_tb);
        $display("Starting Sim");
        clk_in = 0;
        rst_in = 1;

        #500;
        rst_in = 0;
        rgb_in = 24'b1111_1111_0000_0000_1111_1111;
        valid_in = 1;
    
        #20;
        valid_in = 0;
        rgb_in = 0;
        
        #100000;
        $display("Simulation finished");
        $finish;

        
    end
    

endmodule

`default_nettype wire