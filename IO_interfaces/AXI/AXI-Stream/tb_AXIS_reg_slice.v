/*
 * tb for AXIS reg slice component
*/
// timescale unit / precision
`timescale 1 ns / 1 ns

module tb_AXIS_reg_slice;

  // test inputs
  reg clk, reset, s_axis_tvalid, m_axis_tready;
  reg [31:0] s_axis_tdata;
  // DUT outputs
  wire s_axis_tready, m_axis_tvalid;
  wire [31:0] m_axis_tdata;

  // reset and test data generation
  integer i;
  initial begin
    // initial values
    reset         = 0;
    s_axis_tvalid = 0;
    s_axis_tdata  = 32'h0000_0000;
    m_axis_tready = 1; // always ready for now...

    #10 reset = 1;
    #10 reset = 0;

    for (i=0; i < 16; i = i + 1) begin
      $display("\tAXI-S Data Input: 0x%0H, @ %0t", i, $time);
      #10 s_axis_tvalid = 1;
      #10 s_axis_tdata  = i;
      #5  s_axis_tvalid = 0;
      #10 s_axis_tdata  = 0;
    end

    #20 $finish;
  end

  // generate clk w/5ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end


  // monitor tready from DUT
  initial
    $monitor("s_axis_tready = %b, @ %0t", s_axis_tready, $time);

  // synchronous monitor of data output
  always @(posedge clk) begin
    // %0t removes unnecessary padding
    if (m_axis_tvalid)
      $display("AXI-S Data Output: 0x%0H, @ %0t", m_axis_tdata, $time);
  end


  AXIS_reg_slice
  #(
    .DATA_WIDTH(32)
  )
  DUT
  (
    .clk(clk),
    .reset(reset),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tready(s_axis_tready),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tready(m_axis_tready)
  );

endmodule
