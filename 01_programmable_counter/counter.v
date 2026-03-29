// ============================================================
// Module: programmable_counter
// Description: 4-bit synchronous up-counter with active-high
//              reset and clock-enable. Outputs carry_out on
//              rollover from 4'hF to 4'h0.
// Target: Zynq-7000 SoC (Zybo / Blackboard)
// Tools:  Vivado 2023.x, Verilog
// ============================================================

module programmable_counter (
    input  wire       clk,       // System clock
    input  wire       rst,       // Active-high synchronous reset
    input  wire       en,        // Clock enable
    output reg  [3:0] count,     // 4-bit count value
    output wire       carry_out  // Pulses high for one cycle on rollover
);

    assign carry_out = en & (count == 4'hF);

    always @(posedge clk) begin
        if (rst)
            count <= 4'h0;
        else if (en)
            count <= count + 1'b1;
    end

endmodule
