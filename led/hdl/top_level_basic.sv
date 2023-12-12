`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module top_level_basic(
  input wire clk_100mhz, //
  input wire [3:0] btn, //all four momentary button switches
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [7:0] pmoda //output I/O used for SPI TX (in part 3)
  // input wire [15:0] sw, //all 16 input slide switches
  // output logic [15:0] led, //16 green output LEDs (located right above switches)
  // output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  // output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  // output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  // output logic [6:0] ss1_c, //cathod controls for the segments of lower four digits
  );
 
  parameter num_led = 10;

  //shut up those rgb LEDs (active high):
  // assign rgb1 = 0;
  // assign rgb0 = 0;
 
  /* have btnd control system reset */
  logic sys_rst;
  assign sys_rst = btn[0];

  logic [23:0] test_pattern;
  // assign test_pattern = 24'b0000_0000_0000_0000_1111_1111;
  assign test_pattern = 24'b0000_0000_1111_1111_0000_0000;
  // assign test_pattern = 24'b0000_0000_0000_0000_0000_0000;
  // assign test_pattern = 24'b1111_1111_0000_0000_0000_0000;
  
  logic valid_in;
  logic finished;
  logic transmitting; // high if transmitting, low if not transmitting
  logic [23:0] led_counter; // chose arbitrary size, should prob change me

  typedef enum {IDLE=0, START_BLOCK=1, IN_BLOCK=2, END_BLOCK=3} top_states;
  top_states top_state;
  // assign pmoda[0] = 0;
  assign pmoda[1] = 0;
  assign pmoda[2] = 0;
  assign pmoda[3] = 0;
  assign pmoda[4] = 0;
  assign pmoda[5] = 0;
  assign pmoda[6] = 0;
  assign pmoda[7] = 0;


  // repeat valid_in 
  always_ff @ (posedge clk_100mhz) begin
    if (sys_rst) begin
      top_state <= IDLE;
      led_counter <= 0;
      transmitting <= 0;
      rgb1 <= 1;
      
    end else begin
        rgb1 <= 0;
        case(top_state)
          IDLE: begin
            
            if (led_counter < num_led) begin
              top_state <= START_BLOCK;
              led_counter <= led_counter +1;
              rgb0 <= 1;
            end 
            // we need some way to reset led_counter if we want to start another transmit cycle, use sys_rst?
            

          end
          START_BLOCK: begin
            valid_in <= 1;
            top_state <= IN_BLOCK;
          end
          IN_BLOCK: begin
            valid_in <= 0;
            if (finished) begin
              top_state <= IDLE;
              rgb0 <= 0;
            end
          end

        endcase
    end 

  end
 
  led_driver uut_led 
        (.clk_in(clk_100mhz),
         .rst_in(sys_rst),
         .rgb_in(test_pattern),
         .valid_in(valid_in),
         .signal_out(pmoda[0]), // should we also assign some kind of default value to the other pmod ports?
         .finished_led(finished)
        );

endmodule // top_level
`default_nettype wire