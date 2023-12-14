`default_nettype none
 
module seven_segment_controller #(parameter COUNT_TO = 'd100_000)
                        (input wire         clk_in,
                         input wire         rst_in,
                         input wire [31:0]  val_in,
                         output logic[6:0]   cat_out,
                         output logic[7:0]   an_out
                        );
  logic [7:0]	segment_state;
  logic [31:0]	segment_counter;
  logic [3:0]	routed_vals;
  logic [6:0]	led_out;
  /* TODO: wire up routed_vals (-> x_in) with your input, val_in
   * Note that x_in is a 4 bit input, and val_in is 32 bits wide
   * Adjust accordingly, based on what you know re. which digits
   * are displayed when...
   */
   logic [3:0] part_1, part_2, part_3, part_4, part_5, part_6, part_7, part_8;
   assign part_1 = val_in[3:0];
   assign part_2 = val_in[7:4];
   assign part_3 = val_in[11:8];
   assign part_4 = val_in[15:12];
   assign part_5 = val_in[19:16];
   assign part_6 = val_in[23:20];
   assign part_7 = val_in[27:24];
   assign part_8 = val_in[31:28];
   
 
   always_comb begin
      case(segment_state)
        8'b0000_0001: routed_vals = part_1;
        8'b0000_0010: routed_vals = part_2;
        8'b0000_0100: routed_vals = part_3;
        8'b0000_1000: routed_vals = part_4;
        8'b0001_0000: routed_vals = part_5;
        8'b0010_0000: routed_vals = part_6;
        8'b0100_0000: routed_vals = part_7;
        8'b1000_0000: routed_vals = part_8;
        default: routed_vals = part_1;
      endcase 
   end

//    if (segment_state == 8'b0000_0001) begin
//         routed_vals = val_in[3:0];
//     end else if (segment_state == 8'b0000_0010) begin
//         routed_vals = val_in[7:4];
//     end else if (segment_state == 8'b0000_0100) begin
//         routed_vals = val_in[11:8];
//     end else if (segment_state == 8'b0000_1000) begin
//         routed_vals = val_in[15:12];
//     end else if (segment_state == 8'b0001_0000) begin
//         routed_vals = val_in[19:16];
//     end else if (segment_state == 8'b0010_0000) begin
//         routed_vals = val_in[23:20];
//     end else if (segment_state == 8'b0100_0000) begin
//         routed_vals = val_in[27:24];
//     end else if (segment_state == 8'b1000_0000) begin
//         routed_vals = val_in[31:28];
//     end
  bto7s mbto7s (.x_in(routed_vals), .s_out(led_out));
  
  assign cat_out = ~led_out; //<--note this inversion is needed
  assign an_out = ~segment_state; //note this inversion is needed

  // cycle through digits sequentially to make illusion
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_TO) begin
        segment_counter <= 32'd0;
        segment_state <= {segment_state[6:0],segment_state[7]};
    	end else begin
    	  segment_counter <= segment_counter +1;
    	end
    end
  end
endmodule // seven_segment_controller
 
/* TODO: drop your bto7s module from lab 1 here! */

 
 
`default_nettype wire