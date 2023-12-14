`timescale 1ns / 1ps
`default_nettype none

module led_driver 
        ( input wire clk_in,
          input wire rst_in,
          input wire [23:0] rgb_in, // following convention for 24bit data from WS2811 datasheet
          input wire valid_in,
          output logic signal_out,
          output logic finished_led
        );

        logic [$clog2(60+70):0] counter; // this will get really big for long string!!
        logic [$clog2(24):0] bit_counter;
        typedef enum {IDLE=0, RECEIVED_INPUT=1, TRANSMIT_1=2, TRANSMIT_0=3} state;
        state tx_state;
        logic [23:0] rgb_buffer;

        always_ff @(posedge clk_in) begin
            if (rst_in) begin
                counter     <= 0;
                bit_counter <= 0;
                signal_out  <= 0;
                tx_state    <= IDLE;
                rgb_buffer  <= 0;
                finished_led <= 0;
            end else begin
                case(tx_state)
                    IDLE: begin
                        if (valid_in) begin
                            rgb_buffer <= rgb_in;
                            tx_state <= RECEIVED_INPUT;
                        end
                        finished_led <= 0;
                        bit_counter <= 0;
                        signal_out  <= 0;
                    end
                    RECEIVED_INPUT: begin
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 24) begin
                            tx_state <= IDLE;
                            finished_led <= 1;
                        end else begin
                            if (rgb_buffer[23] == 1) begin
                                rgb_buffer <= rgb_buffer << 1;
                                tx_state <= TRANSMIT_1;
                                signal_out <= 1; // we still want to be setting signal out during our transition
                                counter <= 0;
                            
                            end else if (rgb_buffer[23] == 0) begin
                                rgb_buffer <= rgb_buffer << 1;
                                tx_state <= TRANSMIT_0;
                                // actually prob don't need to do this since flip flop holds value anyway
                                signal_out <= 1; // we still want to be setting signal out during our transition
                                counter <= 0;
                            end
                        end
                    end
                    TRANSMIT_1: begin
                        if (counter <= 120) begin
                            signal_out <= 1;
                            counter <= counter + 1;
                        end else if (counter <= 250) begin
                            signal_out <= 0;
                            counter <= counter + 1;
                        end else begin
                            signal_out <= 0; // we still want to be setting signal out during our transition
                            tx_state <= RECEIVED_INPUT;
                            counter <= 0;
                        end
                    end
                    TRANSMIT_0: begin
                        if (counter <= 50) begin
                            signal_out <= 1;
                            counter <= counter + 1;
                        end else if (counter <= 250) begin
                            signal_out <= 0;
                            counter <= counter + 1;
                        end else begin
                            signal_out <= 0; // we still want to be setting signal out during our transition
                            tx_state <= RECEIVED_INPUT;
                            counter <= 0;
                        end
                    end
                endcase 

            end

        
        end
endmodule
`default_nettype none