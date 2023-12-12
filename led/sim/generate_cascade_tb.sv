`timescale 1ns / 1ps
`default_nettype none

// iverilog -g2012 -o sim/sim.out sim/generate_cascade_tb.sv hdl/led_driver.sv hdl/generate_cascade.sv

module generate_cascade_tb();
    parameter num_leds = 10;
    logic clk_in;
    logic sys_rst;
    logic [$clog2(num_leds):0] current_position;
    logic start_cascade;
    logic signal_out;
    logic finished_cascade;

    generate_cascade #(.num_leds(num_leds)) uut (.clk_100mhz(clk_in),
                              .sys_rst(sys_rst),
                              .current_position(current_position),
                              .start_cascade(start_cascade),
                              .signal_out(signal_out),
                              .finished_cascade(finished_cascade));
    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
    end

    initial begin
        $dumpfile("cascade.vcd");
        $dumpvars(0, generate_cascade_tb);
        $display("Starting Sim");
        clk_in = 0;
        #10;
        sys_rst = 1;
        #10;
        sys_rst = 0;
        current_position = 5;
        start_cascade = 1;
        #10;
        start_cascade = 0;
        #1500000;
        
        $display("Simulation finished");
        $finish;

        
    end
    

endmodule

`default_nettype wire