`default_nettype none

module signal_high(
  input wire clk_in, // 100 MHz clock
  input wire rst_in,
  input wire burst,
  output logic ir_sig
  );
  localparam CYCLES = (100_000_000 / 38_000_000) / 2; // 38 kHz
  
  logic [$clog2(CYCLES)-1:0] counter;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      counter <= 0;
      ir_sig <= 0;
    end else if (burst) begin
      counter <= (counter >= CYCLES - 1)? 0 : counter + 1;
      ir_sig <= ((counter == 0))? !ir_sig : ir_sig;
    end else begin
      counter <= 0;
      ir_sig <= 0;
    end
  end

endmodule

`default_nettype wire

