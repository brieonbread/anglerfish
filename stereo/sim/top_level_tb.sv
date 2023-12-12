`timescale 1ns / 1ps
`default_nettype none

// IVERILOG:
// iverilog -g2012 -o sim/sim.out sim/top_level_indexing_tb.sv hdl/top_level.sv  hdl/xilinx_single_port_ram_read_first.v

// VIVADO:
// ./remote/r.py build.py xsim_run.tcl hdl/* sim/top_level_tb.sv obj data/

// BUILD:
// ./remote/r.py build.py build.tcl hdl/* xdc/top_level.xdc data/ obj/

module top_level_tb;
    logic clk_in;
    logic [3:0] btn;
    logic [15:0] sw;
    logic [2:0] rgb0;
    logic [2:0] rgb1;
    logic [7:0] pmoda;
    logic [15:0] led;
    logic uart_txd;
    
    

    top_level uut (
        .clk_100mhz(clk_in),
        .btn(btn),
        .sw(sw),
        .rgb0(rgb0),
        .rgb1(rgb1),
        .pmoda(pmoda),
        .led(led),
        .uart_txd(uart_txd)
    );

    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top_level_tb);
        $display("Starting Sim");

        clk_in = 0;
        btn[0] = 0;

        #10;
        btn[0] = 1;
        #10;
        btn[0] = 0;
        btn[1] = 1;
        #10;
        btn[1] = 0;

        #100000;
        // #3000000;    // for a truncated simulation
        // #10000000;    // for a medium simulation
        // #300000000; 
        
        #10;
        btn[0] = 1;
        #10;
        btn[0] = 1;
        sw[0] = 0;
        #10;
        sw[0] = 1;
        #300000;

        $display("Finishing Sim"); //print nice message
        $finish;
    end
    
    

endmodule
`default_nettype wire

