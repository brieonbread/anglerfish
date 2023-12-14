/***********************************************************************
 * Top-level module to connect the testbench to the design under test.
 * Also generates the clock(s) used in the design and testbench.
 *
 * SystemVerilog Training Workshop.
 *
 * Copyright by Sutherland HDL, Inc.
 * Tualatin, Oregon, USA.
 * www.sutherland-hdl.com
 * All rights reserved.
 **********************************************************************/

module top;  // top-level netlist to connect testbench to dut
  timeunit 1ns; timeprecision 1ns;

  logic [9:1] decimal_in;
  logic [3:0] bcd_out;
  logic       test_clk;

  bcd_encoder      dut  (.*);
  bcd_encoder_test test (.*);

  // clock generators
  initial begin
    test_clk = 0;
    forever #5 test_clk = ~test_clk;
  end

endmodule: top


