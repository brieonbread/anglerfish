`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH);

  logic [10:0] hcount_pipe;
  logic [9:0] vcount_pipe;

  pipelining #( .DEPTH(4), .DATA_WIDTH(11) )
              ( .clk_in(pixel_clk_in),
                .rst_in(rst_in),
                .data_in(hcount_in),
                .data_out(hcount_pipe) );
  
  pipelining #( .DEPTH(4), .DATA_WIDTH(10) )
              ( .clk_in(pixel_clk_in),
                .rst_in(rst_in),
                .data_in(vcount_in),
                .data_out(vcount_pipe) );

  logic in_sprite;
  assign in_sprite = ((hcount_pipe >= x_in && hcount_pipe < (x_in + WIDTH)) &&
                      (vcount_pipe >= y_in && vcount_pipe < (y_in + HEIGHT)));

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite ? color[23:16] : 0;
  assign green_out =  in_sprite ? color[15:8] : 0;
  assign blue_out =   in_sprite ? color[7:0] : 0;
  
  // BRAM presets
  logic dina;
  assign dina = 0;
  logic wea;
  assign wea = 0;
  logic ena;
  assign ena = 1;
  logic regcea;
  assign regcea = 1;
  
  logic [7:0] img_to_pal;
  logic [23:0] color;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(256*256),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_mem (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(dina),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(wea),         // Write enable
    .ena(ena),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(regcea),   // Output register enable
    .douta(img_to_pal)      // RAM output data, width determined from RAM_WIDTH
  );
  
 xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(24),                       // Specify RAM data width
    .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) palette_mem (
    .addra(img_to_pal),     // Address bus, width determined from RAM_DEPTH
    .dina(dina),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(wea),         // Write enable
    .ena(ena),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(regcea),   // Output register enable
    .douta(color)      // RAM output data, width determined from RAM_WIDTH
  ); 
endmodule






`default_nettype none

