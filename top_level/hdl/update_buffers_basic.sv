`timescale 1ns / 1ps
`default_nettype none

// Simplified version of update_buffers
// The idea is that we will update all 4 buffers (left/right front/back) 
// each time we get valid_in high signal

module update_buffers_basic (
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire [$clog2(320):0] left_current_y,
    input wire [$clog2(320):0] right_current_y,
    input wire [$clog2(240):0] left_word_idx,
    input wire [$clog2(240):0] right_word_idx,
    input wire [47:0] left_dout,
    input wire [47:0] right_dout,
    output logic [5:0][47:0] left_front_buffer,
    output logic [5:0][47:0] left_back_buffer,
    output logic [5:0][47:0] right_front_buffer,
    output logic [5:0][47:0] right_back_buffer,
    output logic [$clog2(320*40)-1:0] left_address,
    output logic [$clog2(320*40)-1:0] right_address,
    output logic valid_out
);

    parameter BLOCK_SIZE = 6;
    logic [$clog2(BLOCK_SIZE):0] counter;

    typedef enum {IDLE=0, UPDATE_FRONT_ADDRESS=1, SAVE_FRONT_DATA=2, UPDATE_BACK_ADDRESS=3, SAVE_BACK_DATA=4} read_states;
    read_states state;

    always_ff @ (posedge clk_in) begin
        if(rst_in) begin
            counter <= 0;
            valid_out <= 0;
            
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        // update left and right buffers at the same time
                        // should take n clock cycles to complete
                        state <= UPDATE_FRONT_ADDRESS;
                        left_address  <= (left_current_y + counter ) * 40 + left_word_idx + 1;
                        right_address <= (right_current_y + counter ) * 40 + right_word_idx + 1;
                    end
                    valid_out <= 0;
                    counter <= 0;
                    
                end
                UPDATE_FRONT_ADDRESS: begin
                    // we are assuming that x and y occur on the "corner" of a word, so we can do the following indexing:
                    // left_address  <= (left_current_y + counter ) * 40 + left_word_idx + 1;
                    // right_address <= (right_current_y + counter ) * 40 + right_word_idx + 1;

                    left_address  <= (left_current_y + counter ) * 40 + left_word_idx;
                    right_address <= (right_current_y + counter ) * 40 + right_word_idx;
                    state <= UPDATE_BACK_ADDRESS;
                end
                
                UPDATE_BACK_ADDRESS: begin
                    // left_address  <= (left_current_y + counter ) * 40 + left_word_idx;
                    // right_address <= (right_current_y + counter ) * 40 + right_word_idx;
                    state <=  SAVE_FRONT_DATA;
                end
                SAVE_FRONT_DATA: begin
                    left_front_buffer[counter]  <= left_dout;
                    right_front_buffer[counter] <= right_dout;
                    
                    state <= SAVE_BACK_DATA;
                end
                SAVE_BACK_DATA: begin
                    left_back_buffer[counter]  <= left_dout;
                    right_back_buffer[counter] <= right_dout;

                    // TODO: we have a bug fix here, updating address 7 times instead of 6 
                    if (counter < BLOCK_SIZE - 1) begin 
                        counter <= counter + 1;

                        left_address  <= (left_current_y + counter + 1) * 40 + left_word_idx + 1;
                        right_address <= (right_current_y + counter +1) * 40 + right_word_idx + 1;

                        state <= UPDATE_FRONT_ADDRESS;
                    end else begin
                        state <= IDLE;
                        valid_out <= 1; // is valid_out too early?
                    end
                end

                
                
            endcase
        end
    end
    

endmodule // update_buffers_basic
`default_nettype wire