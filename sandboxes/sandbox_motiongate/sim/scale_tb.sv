`timescale 1ns / 1ps
`default_nettype none

module scale_tb;

    //make logics for inputs and outputs!
    logic [10:0] hcount_in;
    logic [9:0] vcount_in;
    logic [1:0] scale_in;
    logic [10:0] scaled_hcount;
    logic [9:0] scaled_vcount;
    logic valid_addr;

  scale uut
            ( .scale_in(scale_in),
              .hcount_in(hcount_in),
              .vcount_in(vcount_in),
              .scaled_hcount_out(scaled_hcount),
              .scaled_vcount_out(scaled_vcount), 
              .valid_addr_out(valid_addr)
            );
    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        vcount_in = (vcount_in == 299 && hcount_in == 499)? 0 : (hcount_in == 499)? vcount_in + 1 : vcount_in;
        hcount_in = (hcount_in == 499)? 0 : hcount_in + 1;
        
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("scale.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,scale_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        hcount_in = 0;
        vcount_in = 0;
        scale_in = 0;
        #10  //wait a little bit of time at beginning
        #12000;
        scale_in = 2'b01;
        #12000;
        scale_in = 2'b10;
        #12000;
        scale_in = 2'b11;
        #12000;
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire


