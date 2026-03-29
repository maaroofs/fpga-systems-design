// ============================================================
// Module: top_counter
// Description: Top-level design connecting the clock divider
//              output to the programmable counter clock enable.
//              The counter increments at ~1 Hz and displays
//              the count on 4 LEDs. BTN0 resets the counter.
// Board: Zybo Z7 / Blackboard
// ============================================================

`timescale 1ns / 1ps

module top_counter (
    input  wire       clk,         // 100 MHz board clock
    input  wire       rst_btn,     // Reset push button (active-high)
    output wire [3:0] leds,        // Count displayed on LEDs
    output wire       carry_led    // LED lights on rollover
);

    wire slow_clk;

    clock_divider clkdiv_inst (
        .clk     (clk),
        .rst     (rst_btn),
        .clk_out (slow_clk)
    );

    programmable_counter counter_inst (
        .clk       (clk),
        .rst       (rst_btn),
        .en        (slow_clk),
        .count     (leds),
        .carry_out (carry_led)
    );

endmodule
