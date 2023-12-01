`timescale 1ns / 1ps
`default_nettype none

// we will create a two instance of this module, one for left updating and one for right updating
module update_buffers (
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire [$clog2(240):0] left_current_x,
    input wire [$clog2(240):0] right_current_x,
    input wire [$clog2(320):0] left_current_y,
    input wire [$clog2(320):0] right_current_y,
    input wire [47:0] left_dout,
    input wire [47:0] right_dout,
    input wire write_to_front, // 1: write to front L/R buffers, 0: write to back L/R buffers
    output logic [47:0] left_front_buffer  [5:0],
    output logic [47:0] left_back_buffer   [5:0],
    output logic [47:0] right_front_buffer [5:0],
    output logic [47:0] right_back_buffer  [5:0],
    output logic [$clog2(320*40)-1:0] left_address,
    output logic [$clog2(320*40)-1:0] right_address,
    output logic valid_out
    // output logic [$clog2(240):0] left_block_idx,
    // output logic [$clog2(240):0] right_block_idx,


);

    parameter BLOCK_SIZE = 6;
    logic [$clog2(BLOCK_SIZE):0] counter;

    typedef enum {IDLE=0, UPDATE_ADDRESS=1, SAVE_DATA=3} read_states;
    read_states state;

    always_ff @ (posedge clk_in) begin
        if(rst_in) begin
            counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                    // update left and right buffers at the same time
                    // should take n clock cycles to complete
                    state <= UPDATE_ADDRESS;
                    end
                    valid_out <= 0;
                    
                end
                UPDATE_ADDRESS: begin
                    // we are assuming that x and y occur on the "corner" of a word, so we can do the following indexing:
                    left_address  <= (left_current_y + counter ) * 40 + right_current_x;
                    right_address <= (right_current_y + counter ) * 40 + right_current_x;
                    state <= SAVE_DATA;
                end

                SAVE_DATA: begin
                    if (write_to_front) begin
                        left_front_buffer[counter]  <= left_dout;
                        right_front_buffer[counter] <= right_dout;
                    end else begin
                        left_back_buffer[counter]  <= left_dout;
                        right_back_buffer[counter] <= right_dout;
                    end
                    if (counter < BLOCK_SIZE-1) begin 
                        counter <= counter + 1;
                        state <= UPDATE_ADDRESS;
                    end else begin
                        state <= IDLE;
                        valid_out <= 1;
                    end
                end
            endcase
        end
    end
    

endmodule // update_buffers
`default_nettype wire