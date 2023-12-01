/***********************************************************************
 * Test bench for the BCD encoder model.
 *
 * SystemVerilog Training Workshop.
 *
 * Copyright by Sutherland HDL, Inc.
 * Tualatin, Oregon, USA.
 * www.sutherland-hdl.com
 * All rights reserved.
 **********************************************************************/

module bcd_encoder_test
(output logic [9:1] decimal_in,
 input  logic [3:0] bcd_out,
 input  logic       test_clk
);
  timeunit 1ns; timeprecision 1ns;

  int error_count = 0;  // number of errors detected

  initial begin   // input stimulus
    // Randomly generate 20 input values
    repeat(20) begin
      @(posedge test_clk) randomize (decimal_in) with {$countones(decimal_in)<=2;};
      @(negedge test_clk) check_results;  // call output verification task
    end
    @(posedge test_clk) decimal_in = '0;  // test no bits set
    @(negedge test_clk) check_results;    // call output verification task
    $display("\nBCD ENCODING TESTS COMPLETED WITH %0d ERRORS!\n", error_count);
    // $stop;
    $finish;
  end

  initial begin  // output verification
    //display time in ns, no decimal places, 7 char column width
    $timeformat(-9, 0, " ns", 7);
  end

  task check_results;
    logic [3:0] expected;    // local variable
    case (decimal_in) inside
      9'b1????????: expected = 9;  // bit 9 is set
      9'b01???????: expected = 8;  // bit 8 is set
      9'b001??????: expected = 7;  // bit 7 is set
      9'b0001?????: expected = 6;  // bit 6 is set
      9'b00001????: expected = 5;  // bit 5 is set
      9'b000001???: expected = 4;  // bit 4 is set
      9'b0000001??: expected = 3;  // bit 3 is set
      9'b00000001?: expected = 2;  // bit 2 is set
      9'b000000001: expected = 1;  // bit 1 is set
      9'b000000000: expected = 0;  // no bits are set
    endcase
    $write("At %t:  decimal_in=%b : bcd_out=%d", $realtime, decimal_in, bcd_out);
    if (bcd_out === expected)
      $display(" - OK");
    else begin
      error_count++;
      $display(" - ERROR: expected %d\n", expected);
    end
  endtask

endmodule: bcd_encoder_test
