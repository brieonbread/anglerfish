`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  //your design here!
  logic [31:0] intermediate_sum_x;
  logic [31:0] intermediate_sum_y;
  logic [$clog2(960*640)-1:0] num_points;

  logic [1:0] done_computing;
  logic [1:0] busy;
  logic [1:0] xy_valid;
  logic [1:0] errors;

  logic [10:0] avg_x;
  logic [9:0] avg_y;

  divider dx (
              .clk_in(clk_in),
              .rst_in(rst_in),
              .dividend_in(intermediate_sum_x),
              .divisor_in(num_points),
              .data_valid_in(tabulate_in),
              .quotient_out(avg_x),
              .remainder_out(), // don't care about remainders
              .data_valid_out(done_computing[1]),
              .error_out(errors[1]),
              .busy_out(busy[1]));

  divider dy (
              .clk_in(clk_in),
              .rst_in(rst_in),
              .dividend_in(intermediate_sum_y),
              .divisor_in(num_points),
              .data_valid_in(tabulate_in),
              .quotient_out(avg_y),
              .remainder_out(),
              .data_valid_out(done_computing[0]),
              .error_out(errors[0]),
              .busy_out(busy[0]));

  always_ff @(posedge clk_in) begin
    if (rst_in) begin // rst
      intermediate_sum_x <= 0;
      intermediate_sum_y <= 0;
      num_points <= 0;
      x_out <= 0;
      y_out <= 0;
      valid_out <= 0;
      xy_valid <= 0;
    end else if (errors != 0) begin
      xy_valid <= 0;
      valid_out <= 0;
    end else if (xy_valid[1] & xy_valid[0]) begin // just finished calc
      if (errors == 0) valid_out <= 1;
      xy_valid <= 0;
      num_points <= 0;
    end else if (valid_in) begin // counting in new pixels
      intermediate_sum_x <= intermediate_sum_x + x_in;
      intermediate_sum_y <= intermediate_sum_y + y_in;
      num_points <= num_points + 1;
      valid_out <= 0;
    end else begin // not counting pixels, currently tabulating and/or not counting
      if (done_computing[1] && !errors[1] && !xy_valid[1] && num_points > 0) begin
        x_out <= avg_x;
        xy_valid[1] <= 1'b1;
        intermediate_sum_x <= 0;
      end
      if (done_computing[0] && !errors[0] && !xy_valid[0] && num_points > 0) begin
        y_out <= avg_y;
        xy_valid[0] <= 1'b1;
        intermediate_sum_y <= 0;
      end
      valid_out <= 0;
    end
  end

endmodule


`default_nettype wire
