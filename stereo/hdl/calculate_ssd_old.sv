`timescale 1ns / 1ps
`default_nettype none

// calculates ssd for a block in left image and block in right image
// assumes the front and back buffers have been updated to refelect the y position of the current blocks
// essentially repeats ssd row calculation down all rows and then accumulates the values across all SMAC engines

module calculate_ssd_block (
    input wire clk_in,
    input wire rst_in,
    // do we need a valid_in signal? so know when to reset stuff?
    input wire [$clog2(240):0] left_current_x,
    input wire [$clog2(240):0] right_current_x,
    input wire [$clog2(320):0] left_current_y,
    input wire [$clog2(320):0] right_current_y,
    input wire [$clog2(240):0] left_block_idx,
    input wire [$clog2(240):0] right_block_idx,
    input wire [47:0] left_front_buffer  [5:0], // is this how to connect register to other modules?
    input wire [47:0] left_back_buffer   [5:0],
    input wire [47:0] right_front_buffer [5:0],
    input wire [47:0] right_back_buffer  [5:0],
    output logic valid_out,
    output logic [$clog2(255*255*6*6):0] ssd_out
);

    logic [7:0] left_front_buffer_row  [5:0];   // buffer B
    logic [7:0] left_back_buffer_row   [5:0];   // buffer A
    logic [7:0] right_front_buffer_row [5:0];   // buffer D
    logic [7:0] right_back_buffer_row  [5:0];   // buffer C

    logic [$clog2(6):0] row_counter;

    // define the wires needed for the SMAC engines
    logic [5:0] rst_smac;
    logic [7:0] left_smac_input [5:0];
    logic [7:0] right_smac_input [5:0];
    logic [5:0] valid_in;
    logic [$clog2(255*255*6):0] ssd_by_col [5:0];


    // can we do this...assign register value combinationally?
    always_comb begin
        left_front_buffer_row  = left_front_buffer[row_counter];
        left_back_buffer_row   = left_back_buffer[row_counter];
        right_front_buffer_row = right_front_buffer[row_counter];
        right_back_buffer_row  = right_back_buffer[row_counter];
        ssd_out = ssd_by_col[47:40] + ssd_by_col[39:32] + ssd_by_col[31:24] + ssd_by_col[23:16] + ssd_by_col[15:8] + ssd_by_col[7:0];
    end

    always_ff @ (posedge clk_in) begin
        if (rst_in) begin
            row_counter <= 0;
        end else begin
            valid_out <= 1?0:0;
            rst_smac  <= 1?0:0;
            if (row_counter < 6) begin
                // input into SMAC engines, should have 6 sets of pixels
                left_smac_input  <= {left_back_buffer_row[47-8*(left_current_x-left_block_idx):0], left_front_buffer_row[47:47-8*(left_current_x-left_block_idx)]};
                right_smac_input <= {right_back_buffer_row[47-8*(right_current_x-right_block_idx):0], right_front_buffer_row[47:47-8*(right_current_x-right_block_idx)]};

            end else begin
                valid_out  <= 1; // high for one cycle
                rst_smac   <= 1; // high for one cycle 
                // should we reset row_counter?
            end


            
        end
    end


    // instantiate 6 copies of SMAC engine
    generate
        genvar i;
        for (i=0; i<6; i++) begin
            mac_engine inst (
                .clk_in(clk_in),
                .rst_in(rst_smac[i]),
                .left_pixel(left_smac_input[i]),
                .right_pixel(right_smac_input[i]),
                .valid_in(valid_in[i]),
                .accumulator(ssd_by_col[i])
            );
        end
    endgenerate

    // calculate_ssd_row inst_ssd_row (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .left_current_x(left_current_x),
    //     .right_current_x(right_current_x),
    //     .left_block_idx(),
    //     .right_block_idx(),
    //     .left_front_buffer_row(),
    //     .left_back_buffer_row(),
    //     .right_front_buffer_row(),
    //     .right_back_buffer_row(),
    //     .left_smac_input(left_smac_input), // we are passing in an array, does this work?
    //     .right_smac_input(right_smac_input) // we are passing in an array, does this work?
    // );

endmodule

// calculates ssd for a block row in left image and a block row in right image
// module calculate_ssd_row (
//     input wire clk_in,
//     input wire rst_in,
//     input wire [$clog2(240):0] left_current_x,
//     input wire [$clog2(240):0] right_current_x,
//     input wire [$clog2(240):0] left_block_idx,
//     input wire [$clog2(240):0] right_block_idx,
//     input wire [47:0] left_front_buffer_row ,    // row in buffer B 
//     input wire [47:0] left_back_buffer_row  ,    // row in buffer A 
//     input wire [47:0] right_front_buffer_row,    // row in buffer D
//     input wire [47:0] right_back_buffer_row ,    // row in buffer C
//     // inputs to the 6 SMAC engines
//     output logic [47:0] left_smac_input,
//     output logic [47:0] right_smac_input,
//     // do we need any outputs?
// );

//     always_ff @ (posedge clk_in) begin
//         if (rst_in) begin
//         end else begin

//             // input into SMAC engines, should have 6 sets of pixels
//             left_smac_input  <= {left_back_buffer_row[47-8*(left_current_x-left_block_idx):0], left_front_buffer_row[47:47-8*(left_current_x-left_block_idx)]};
//             right_smac_input <= {right_back_buffer_row[47-8*(right_current_x-right_block_idx):0], right_front_buffer_row[47:47-8*(right_current_x-right_block_idx)]};
            
//         end

//     end


// endmodule // calculate_ssd_row
// `default_nettype wire