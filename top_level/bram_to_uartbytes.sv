/*
 * This is a BRAM to UART readout module that allows you to export all data on
 * a BRAM on an FPGA to a computer via serial/UART communication.
 *
 * Set up module with:
 *   - BRAM_WIDTH = number of bits for each entry in the BRAM (must be
 *   multiple of 8 bits/multiple of bytes), default is 24
 *   - BRAM_DEPTH = number of entries in the BRAM, default is 320*240
 *   - BAUD_RATE = baud rate (bits per second) that you will be running serial
 *   communication
 *   - CLK_FREQ = clock frequency of the clock that you give this module
 *   - clk_in = clock
 *   - data_in = output value of your dual-port BRAM
 *   - send_data_in = signal that tells this module to begin dumping/transmitting all
 *   BRAM data, module will begin running as soon as this signal is high and
 *   reset/stop running when this signal is low
 *   - req_index_out = index at which this module fetches data from your BRAM,
 *   should be tied to the request address of your BRAM's output port
 *   - uart_txd = UART transmit output (connected to FPGA's top level UART
 *   transmit wire)
 *
 * Note that you will also need a uart_tx module (can be found in any
 * generated manta.sv files).
 */

// copy the below module template if you'd like

// bram_readout #( .BRAM_WIDTH(),
//                 .BRAM_DEPTH(),
//                 .BAUD_RATE(),
//                 .CLK_FREQ() )
//               ( .clk_in(),
//                 .data_in(),
//                 .send_data_in(),
//                 .req_index_out(),
//                 .uart_txd() );


`timescale 1ns / 1ps
`default_nettype none

module bram_readout #( parameter BRAM_WIDTH=24, // MUST BE MULTIPLE OF 8
                       parameter BRAM_DEPTH=320*240,
                       parameter BAUD_RATE=3000000,
                       parameter CLK_FREQ=100000000 )
                     (
                       input wire clk_in,
                       input wire [BRAM_WIDTH-1:0] data_in, // tie this to BRAM data out (make sure read enabled)
                       input wire send_data_in, 
                       output logic [$clog2(BRAM_DEPTH)-1:0] req_index_out,
                       output logic uart_txd
                     );

  localparam CLK_PER_BAUD = CLK_FREQ / BAUD_RATE;
  logic [BRAM_WIDTH-1:0] buffer; // width of data minus first byte
  logic [7:0] current_byte;
  assign current_byte = buffer[BRAM_WIDTH-1:BRAM_WIDTH-8];
  logic uart_start;
  logic uart_done;                
  
  logic [$clog2(BRAM_WIDTH)-1:0] counter; // must be able to count up to all bits sent
  typedef enum { IDLE, INIT, SET_DATA, SEND_DATA } readout_state;
  readout_state state;

  uart_tx #(.CLOCKS_PER_BAUD(CLK_PER_BAUD)) (
            .clk(clk_in),
            .data_i(current_byte),
            .start_i(uart_start),
            .done_o(uart_done),
            .tx(uart_txd)
          );

  always_ff @(posedge clk_in) begin
    if (!send_data_in) begin // default values (when not sending data)
      state <= IDLE;
      uart_start <= 0;
      req_index_out <= 0;
      counter <= 0;
      buffer <= 0;
    end else begin
      case (state)
        IDLE : begin
          counter <= 0;
          if (req_index_out == 0) state <= INIT; // begin sending data
        end
        INIT : begin
          if (counter >= 2) begin // give BRAM extra cycles to load first data entry
            counter <= 0;
            state <= SET_DATA;
          end else counter <= counter + 1;
        end
        SET_DATA : begin
          uart_start <= 0;
          state <= SEND_DATA;
          if (counter == 0 || counter >= BRAM_WIDTH) begin // get new data entry from BRAM (counter now used as # of bits sent)
            req_index_out <= req_index_out + 1;
            counter <= 0;
            buffer <= data_in;
          end else begin
            buffer <= buffer << 8; // shift new byte to leftmost position
          end
        end
        SEND_DATA : begin
          if (uart_start && uart_done) begin // uart_tx takes in new data
            state <= (req_index_out <  BRAM_DEPTH)? SET_DATA : IDLE; // check if done sending data
            uart_start <= 0;
            counter <= (counter >= BRAM_WIDTH)? 0 : counter + 8; // counter could wrap around if all bits sent
          end else begin
            uart_start <= 1;
          end
        end
      endcase
    end
  end
endmodule

`default_nettype wire
