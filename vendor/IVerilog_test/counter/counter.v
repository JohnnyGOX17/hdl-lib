// basic counter module

module counter
#(
  parameter G_WIDTH = 8
)
(
  input wire clk,
  input wire reset,
  output reg [G_WIDTH - 1 : 0] out
);


  /* async assert, sync deassert reset */
  always @(posedge clk or posedge reset)
  begin
    if (reset)
      out <= 0;
    else
      out <= out + 1;
  end

endmodule

