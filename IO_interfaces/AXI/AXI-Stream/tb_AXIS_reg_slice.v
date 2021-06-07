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
    // dump value changes of nets & regs to *.vcd file for waveform viewing
    $dumpfile("test.vcd");
    // <levels>, <module_or_variable> http://www.referencedesigner.com/tutorials/verilog/verilog_62.php
    $dumpvars(0,tb_AXIS_reg_slice);
    // monitor tready to upstream logic from DUT
    $monitor("s_axis_tready = %b, @ %0t", s_axis_tready, $time);
    // initial values
    reset         = 0;
    s_axis_tvalid = 0;
    s_axis_tdata  = 32'h0000_0000;
    m_axis_tready = 0; // always ready for now...

    #10 reset = 1;
    #10 reset = 0;

    // Test Case 1: downstream/slave always ready for data
    m_axis_tready = 1; // always ready for now...
    $display("Test Case 1: downstream/slave always ready for data");
    for (i=0; i < 16; i = i + 1) begin
      // wait for reg slice ready
      while ( s_axis_tready == 0 )
        #10 forever;

      $display("\tAXI-S Data Input: 0x%0H, @ %0t", i, $time);
      s_axis_tvalid = 1;
      s_axis_tdata  = i;
      #10 s_axis_tvalid = 0;
      #10 s_axis_tdata  = 0;
    end

    // inter-test wait...
    #10 m_axis_tready = 0; // start w/downstream NOT ready for this test...
    #10 s_axis_tvalid = 0;

    // Test Case 2: downstream/slave ready after 2x cycles of valid data
    $display("Test Case 2: downstream/slave ready after 2x cycles of valid data");
    for (i=0; i < 16; i = i + 1) begin
      if (i > 1)
        m_axis_tready = 1;
      // wait for reg slice ready
      while ( s_axis_tready == 0 )
        #10 forever;

      $display("\tAXI-S Data Input: 0x%0H, @ %0t", i, $time);
      s_axis_tvalid = 1;
      s_axis_tdata  = i;
      #10 s_axis_tvalid = 0;
      #10 s_axis_tdata  = 0;
    end

    #20 $finish;
  end

  // generate clk w/5ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end



  // synchronous monitor of data output when valid consumption of data
  always @(posedge clk) begin
    // %0t removes unnecessary padding
    if (m_axis_tvalid && m_axis_tready)
      $display("\t\tAXI-S Data Output: 0x%0H, @ %0t", m_axis_tdata, $time);
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
