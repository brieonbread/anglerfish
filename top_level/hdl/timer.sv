`timescale 1ns / 1ps
`default_nettype none

module stopwatch #(
                    parameter FREQUENCY = 100_000_000 // 100 MHz clock
                  )
                  (
                    input wire clk_in, // should be 100MHz or some other freq that easily forms 1/100 of a second, otherwise stopwatch may be inaccurate
                    input wire rst_in,
                    output logic [3:0] minutes, // max is 15 min
                    output logic [5:0] seconds, // 60 seconds in 1 min
                    output logic [6:0] hundredths // 100 hundredths in a second
                  );

  logic [$clog2(FREQUENCY/100):0] counter; // count on each clock cycle for next hundredth of second
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      counter <= 0;
      minutes <= 0;
      seconds <= 0;
      hundredths <= 0;
    end else begin
      counter <= (counter == ((FREQUENCY/100) - 1))? 0 : counter + 1;
      minutes <= (seconds == 59)? minutes + 1 : minutes; // disregard wraparound after 15 min
      seconds <= (hundredths == 99)? (seconds == 59)? 0 : seconds + 1 : seconds;
      hundredths <= (counter == ((FREQUENCY/100) - 1))? (hundredths == 99)? 0 : hundredths + 1 : hundredths;
    end
  end


endmodule

`default_nettype wire
