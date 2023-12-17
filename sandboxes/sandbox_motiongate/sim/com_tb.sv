`timescale 1ns / 1ps
`default_nettype none

module com_tb;

    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic [10:0] x_in;
    logic [9:0] y_in;
    logic valid_in;
    logic tabulate_in;
    logic [10:0] x_out;
    logic [9:0] y_out;
    logic valid_out;

    center_of_mass uut(.clk_in(clk_in), .rst_in(rst_in),
                         .x_in(x_in),
                         .y_in(y_in),
                         .valid_in(valid_in),
                         .tabulate_in(tabulate_in),
                         .x_out(x_out),
                         .y_out(y_out),
                         .valid_out(valid_out));


  //grab logic for above
  //update center of mass x_com, y_com based on new_com signal
  logic [10:0] x_com;
  logic [9:0] y_com;
  always_ff @(posedge clk_in) begin
    if (rst_in)begin
      x_com <= 0;
      y_com <= 0;
    end if(valid_out)begin
      x_com <= x_out;
      y_com <= y_out;
    end
  end

  // COM stuff for motion gate
  logic x_dir;
  logic old_x_dir;
  logic changed_direction;
  assign changed_direction = (x_dir !== old_x_dir);
  assign x_dir = (x_com < x_out); // will be 0 if moving left, 1 if moving right
  always_ff @(posedge clk_in) old_x_dir <= x_dir;


    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("com.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,com_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        x_in = 11'b0;
        y_in = 10'b0;
        valid_in = 0;
        tabulate_in = 0;
        #10;  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        // FIRST TEST CASE: both x and y increment over time, avg ~348 or 349
        for (int i = 0; i<700; i= i+1)begin
          x_in = i;
          y_in = i;
          valid_in = 1;
          #10;
        end
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #100;
        tabulate_in = 0;
        #10000;
        // SECOND TEST CASE: only x increments, x avg ~348-349, y avg = 10
        for (int i = 0; i<700; i= i+1)begin
          x_in = i;
          y_in = 10;
          valid_in = 1;
          #10;
        end
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #100;
        tabulate_in = 0;
        #10000;
        // THIRD TEST CASE: only one valid pixel, result is (57, 190)
        for (int i = 0; i<300; i= i+1)begin
          y_in = i;
          for (int j = 0; j<10; j= j+1) begin
            x_in = j;
            valid_in = (x_in == 7 && y_in == 57)? 1 : 0;
            #10;
          end
        end
        #100;
        tabulate_in = 1;
        #1000;
        tabulate_in = 0;
        #10000;
        // FOURTH TEST CASE: no valid pixels, should yield no valid results
        tabulate_in = 1;
        #100;
        tabulate_in = 0;
        #10000;
        // FIFTH TEST CASE: normal behavior, five points, result should be (16, 7)
        for (int i = 0; i<30; i= i+1)begin
          y_in = i;
          for (int j = 0; j<30; j= j+1)begin
            x_in = j;
            valid_in = ((x_in == 9 && y_in == 7) || (x_in == 23 && y_in == 22) || (x_in == 4 && y_in == 5) || (x_in == 18 && y_in == 0) || (x_in == 29 && y_in == 3))? 1: 0;
            #10;
          end
        end
        #100;
        tabulate_in = 1;
        #500;
        tabulate_in = 0;
        #100000;

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
