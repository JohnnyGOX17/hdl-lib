module freq_meter
#(
  parameter REFCLK_FREQ   = 200000000, // reference clk frequency (Hz)
  parameter MAX_TEST_FREQ = 156250000  // maximum expected test clk frequency (Hz)
)
(
  input wire ref_clk, test_clk,
  output reg [$clog2(MAX_TEST_FREQ):0] test_clk_cycles,
  output reg test_clk_valid
);

// in case $clog2() is not supported in tools
function integer clogb2;
  input [31:0] value;
  begin
    value = value - 1;
    for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
      value = value >> 1;
    end
  end
endfunction


endmodule
