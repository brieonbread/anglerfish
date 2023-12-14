`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module generate_cascade #(parameter num_leds = 10)(
  input wire clk_100mhz, //
  input wire sys_rst,
  input wire [$clog2(num_leds):0] current_position,
  input wire start_cascade,
  output logic signal_out,
  output logic finished_cascade

  );
 
  logic [23:0] color_on;
  assign color_on = 24'b0000_0000_1111_1111_0000_0000;

  logic [23:0] color_off;
  assign color_off = 24'b0000_0000_0000_0000_0000_0000;

  logic [23:0] color;
  assign color = (led_counter == current_position) ? color_on : color_off;


  logic finished;
  logic valid_in;
  logic transmitting; // high if transmitting, low if not transmitting
  logic [$clog2(num_leds):0] led_counter; // chose arbitrary size, should prob change me

  typedef enum {IDLE=0, START_BLOCK=1, IN_BLOCK=2, END_BLOCK=3} top_states;
  top_states top_state;

  // repeat valid_in 
  always_ff @ (posedge clk_100mhz) begin
    if (sys_rst) begin
      top_state <= IDLE;
      led_counter <= 0;
      transmitting <= 0;
      
    end else begin
        case(top_state)
          IDLE: begin
            if (start_cascade) begin
                top_state <= START_BLOCK;
            end 

            led_counter <= 0;
            finished_cascade <= 0;
          end
          START_BLOCK: begin
            if (led_counter < num_leds) begin
                valid_in <= 1;
                top_state <= IN_BLOCK;
                led_counter <= led_counter + 1;
            end else begin
                top_state <= IDLE;
                finished_cascade <= 1;
            end
          end
          IN_BLOCK: begin
            valid_in <= 0;
            if (finished) begin
              top_state <= START_BLOCK;
            end
          end

        endcase
    end 

  end
 
  led_driver uut_led 
        (.clk_in(clk_100mhz),
         .rst_in(sys_rst),
         .rgb_in(color),
         .valid_in(valid_in),
         .signal_out(signal_out), // should we also assign some kind of default value to the other pmod ports?
         .finished_led(finished)
        );

endmodule // top_level
`default_nettype wire