`timescale 1ns / 1ps
`default_nettype none

// iverilog -g2012 -o sim/sim.out sim/top_level_tb.sv hdl/*

module top_level (
    input wire clk_100mhz,
    input wire [3:0] btn,
    input wire [15:0] sw,
    output logic [7:0] pmoda

);
    parameter num_leds = 51;
    parameter velocity = 20; // #s per 25 yards
    // parameter num_latch_cycles = 5500000 * (1 + sw[3:0]); // TODO: come up with a formula for this based on desired vel
    logic [$clog2(5500000*16):0] num_latch_cycles;
    assign num_latch_cycles = 1000000 * (1 + sw[3:0]); // minimum latch cycles is 50000ns = 5000 cycle
    
    typedef enum {IDLE=0, FORWARD=1, LATCH=2, REVERSE=3, TRANSMIT=4} target_states;
    target_states state;

    logic [$clog2(num_leds):0] current_position;
    logic [$clog2(5500000*16):0] latch_counter; // NOTE: size depends on num_latch_cycles

    logic start_cascade;
    logic finished_cascade;

    logic is_forward; // high if going forward, low if going backward

    logic sys_rst;
    assign sys_rst = btn[0];

    always_ff @ (posedge clk_100mhz) begin
        if (sys_rst) begin
            is_forward <= 0;
            state <= IDLE;
            current_position <= 0;
            latch_counter <= 0;

        end else begin
            case(state)
                IDLE: begin
                    if (btn[1]) begin
                        state <= FORWARD;
                        is_forward <= 1;
                        
                    end
                    current_position <= 0;
                    latch_counter <= 0;
                end 
                FORWARD: begin
                    if (current_position < num_leds - 1) begin
                        current_position <= current_position + 1;
                        state <= TRANSMIT;
                        start_cascade <= 1;

                    end else begin
                        state <= REVERSE;
                        is_forward <= 0;
                    end
                end
                LATCH: begin
                    if (latch_counter < num_latch_cycles) begin
                        latch_counter <= latch_counter + 1;
                    end else begin
                        latch_counter <= 0;
                        state <= is_forward ? FORWARD : REVERSE;
                    end

                end
                REVERSE: begin
                    if (current_position > 0) begin
                        current_position <= current_position - 1;
                        state <= TRANSMIT;
                        start_cascade <= 1;
                    end else begin
                        state <= FORWARD;
                        is_forward <= 1;
                    end
                end
                TRANSMIT: begin
                    start_cascade <= 0;
                    
                    if (finished_cascade) begin
                        state <= LATCH;
                    end
                end
            endcase
        end
    end
    
    generate_cascade #(.num_leds(num_leds)) inst_cascade (.clk_100mhz(clk_100mhz),
                                                          .sys_rst(sys_rst),
                                                          .current_position(current_position),
                                                          .start_cascade(start_cascade),
                                                          .signal_out(pmoda[0]),
                                                          .finished_cascade(finished_cascade));

endmodule // top_level
`default_nettype wire