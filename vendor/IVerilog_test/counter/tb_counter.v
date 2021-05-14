// basic testbench for counter
// timescale unit / precision
`timescale 1 ns / 1 ns

module tb_counter;

  reg reset = 0;
  initial begin
    #17 reset = 1;
    #11 reset = 0;
    #29 reset = 1;
    #11 reset = 0;
    #100 $stop;
  end

  reg clk = 0;
  always #5 clk = !clk;

  wire [3:0] value;
  counter DUT (
    .clk(clk),
    .reset(reset),
    .out(value)
  );
  defparam DUT.G_WIDTH = 4;

  initial
    $monitor("At time %t, value = %h (%0d)",
             $time,
             value,
             value);

endmodule
