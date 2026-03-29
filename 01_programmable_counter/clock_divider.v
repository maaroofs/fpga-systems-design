// ============================================================
// Module: clock_divider
// Description: Divides a 100 MHz input clock down to ~1 Hz
//              using a 27-bit prescaler counter. Suitable for
//              driving LEDs and other low-frequency outputs.
// ============================================================

module clock_divider (
    input  wire clk,       // 100 MHz input clock
    input  wire rst,       // Active-high reset
    output reg  clk_out    // ~1 Hz divided output clock
);

    // Half-period count for 100 MHz -> 1 Hz: 50_000_000 cycles
    localparam HALF_PERIOD = 27'd49_999_999;

    reg [26:0] prescaler;

    always @(posedge clk) begin
        if (rst) begin
            prescaler <= 27'd0;
            clk_out   <= 1'b0;
        end else if (prescaler == HALF_PERIOD) begin
            prescaler <= 27'd0;
            clk_out   <= ~clk_out;
        end else begin
            prescaler <= prescaler + 1'b1;
        end
    end

endmodule
