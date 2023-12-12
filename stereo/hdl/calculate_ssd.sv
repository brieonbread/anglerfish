`timescale 1ns / 1ps
`default_nettype none

// calculates ssd for a block in left image and block in right image
// assumes the front and back buffers have been updated to refelect the y position of the current blocks
// essentially repeats ssd row calculation down all rows and then accumulates the values across all SMAC engines

module calculate_ssd_block (
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,    // do we need a valid_in signal? so know when to reset stuff?
    input wire [$clog2(240):0] left_current_x,
    input wire [$clog2(240):0] right_current_x,
    input wire [$clog2(320):0] left_current_y,
    input wire [$clog2(320):0] right_current_y,
    input wire [$clog2(240):0] left_block_idx,
    input wire [$clog2(240):0] right_block_idx,
    input wire [5:0][47:0] left_front_buffer, // is this how to connect register to other modules?
    input wire [5:0][47:0] left_back_buffer,
    input wire [5:0][47:0] right_front_buffer,
    input wire [5:0][47:0] right_back_buffer,
    output logic valid_out,
    output logic [$clog2(255*255*6*6):0] ssd_out
);

    // define the wires needed for the SMAC engines
    logic [5:0] rst_smac;
    logic [5:0][47:0] left_smac_input;
    logic [5:0][47:0] right_smac_input;
    logic [5:0] valid_in_smac;
    logic [5:0][$clog2(255*255*6):0] ssd_by_col;

    logic [$clog2(6):0] left_diff;
    logic [$clog2(6):0] right_diff;

    assign left_diff = left_current_x-left_block_idx;
    assign right_diff = right_current_x-right_block_idx;

    assign ssd_out = ssd_by_col[0] + ssd_by_col[1] + ssd_by_col[2] + ssd_by_col[3] + ssd_by_col[4] + ssd_by_col[5];
    always_ff @ (posedge clk_in) begin
        
        if (rst_in) begin
            // ssd_out <= 0;
        end else begin
            // ssd_out <= ssd_by_col[0] + ssd_by_col[1] + ssd_by_col[2] + ssd_by_col[3] + ssd_by_col[4] + ssd_by_col[5];
            // input into SMAC engines
            if (valid_in) begin
                valid_in_smac <= 6'b11_1111;

                for(integer i=0;i<6;i=i+1) begin: left_input_loop
                    case (left_diff)
                        0: left_smac_input[i] <= left_back_buffer[i];
                        1: left_smac_input[i] <= {left_back_buffer[i][39:0], left_front_buffer[i][47:40]};
                        2: left_smac_input[i] <= {left_back_buffer[i][31:0], left_front_buffer[i][47:32]};
                        3: left_smac_input[i] <= {left_back_buffer[i][23:0], left_front_buffer[i][47:24]};
                        4: left_smac_input[i] <= {left_back_buffer[i][15:0], left_front_buffer[i][47:16]};
                        5: left_smac_input[i] <= {left_back_buffer[i][7:0],  left_front_buffer[i][47:8]};
                    endcase
                end

                for(integer i=0;i<6;i=i+1) begin: right_input_loop
                    case (right_diff)
                        0: right_smac_input[i] <= right_back_buffer[i];
                        1: right_smac_input[i] <= {right_back_buffer[i][39:0], right_front_buffer[i][47:40]};
                        2: right_smac_input[i] <= {right_back_buffer[i][31:0], right_front_buffer[i][47:32]};
                        3: right_smac_input[i] <= {right_back_buffer[i][23:0], right_front_buffer[i][47:24]};
                        4: right_smac_input[i] <= {right_back_buffer[i][15:0], right_front_buffer[i][47:16]};
                        5: right_smac_input[i] <= {right_back_buffer[i][7:0],  right_front_buffer[i][47:8]};
                    endcase
                end

            end else begin
                valid_in_smac <= 6'b00_0000;
            end
        end
    end


    // instantiate 6 copies of SMAC engine
    generate
        genvar a;
        for (a=0; a<6; a++) begin: smac_loop
            mac_engine_48bit inst (
                .clk_in(clk_in),
                .rst_in(rst_smac[a]),
                .left_row(left_smac_input[a]),
                .right_row(right_smac_input[a]),
                .valid_in(valid_in_smac[a]),
                .accumulator(ssd_by_col[a])
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
`default_nettype wire