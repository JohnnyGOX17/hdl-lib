/*
 * Implements AXI-Stream register slice to break up timing in AXI-S path
 */

module AXIS_reg_slice
#(
  parameter DATA_WIDTH = 32
)
(
  input  wire  clk,
  input  wire  reset,

  input  wire                    s_axis_tvalid,
  input  wire [DATA_WIDTH - 1:0] s_axis_tdata,
  output wire                    s_axis_tready,

  output wire                    m_axis_tvalid,
  output wire [DATA_WIDTH - 1:0] m_axis_tdata,
  input  wire                    m_axis_tready
);

  localparam [1:0] // define states for AXI reg slice
    IDLE_STATE     = 2'b00,
    INPUT_VALID    = 2'b01,
    WAIT_FOR_SLAVE = 2'b10;

  reg fsm_state = IDLE_STATE;

  // double-buffer input data
  reg [DATA_WIDTH - 1:0] s_axis_tdata_reg0, s_axis_tdata_reg1;
  reg s_axis_tdata_reg_sel; // selects which to output


  assign s_axis_tready = (fsm_state != WAIT_FOR_SLAVE);
  assign m_axis_tvalid = (fsm_state == INPUT_VALID) || (fsm_state == WAIT_FOR_SLAVE);
  assign m_axis_tdata  = (s_axis_tdata_reg_sel) ? s_axis_tdata_reg0 : s_axis_tdata_reg1;


  // FSM for AXI input and slicing
  always @(posedge clk) begin
    if (reset) begin
      s_axis_tdata_reg0    <= {DATA_WIDTH{1'b0}}; // replicate op. for variable width
      s_axis_tdata_reg1    <= {DATA_WIDTH{1'b0}}; // all 0's on reset
      s_axis_tdata_reg_sel <= 1'b0;
      fsm_state            <= IDLE_STATE;
    end else begin
      case(fsm_state)
        IDLE_STATE: begin // waiting for input valid
          if (s_axis_tvalid) begin // register to first data reg
            if (s_axis_tdata_reg_sel) begin
              s_axis_tdata_reg1 <= s_axis_tdata;
            end else begin
              s_axis_tdata_reg0 <= s_axis_tdata;
            end
            s_axis_tdata_reg_sel <= ~s_axis_tdata_reg_sel;
            fsm_state <= INPUT_VALID;
          end
        end

        // best case, registered version of m_axis_tready is high here
        // since we already have something buffered here... if downstream tready is high
        // then we can give data right away, otherwise we have to wait, can capture at least one more
        INPUT_VALID: begin // waiting for downstream slave tready assertion
          if (m_axis_tready && ~s_axis_tvalid) begin
            fsm_state <= IDLE_STATE;
          end else if (~m_axis_tready && s_axis_tvalid) begin
            fsm_state <= WAIT_FOR_SLAVE;
          end else if (m_axis_tready && s_axis_tvalid) begin
            s_axis_tdata_reg_sel <= ~s_axis_tdata_reg_sel;
          end

          if (s_axis_tvalid) begin
            if (s_axis_tdata_reg_sel) begin
              s_axis_tdata_reg1 <= s_axis_tdata;
            end else begin
              s_axis_tdata_reg0 <= s_axis_tdata;
            end
          end
        end

        WAIT_FOR_SLAVE: begin // by nature of being here, both buffers valid
          if (m_axis_tready) begin
            s_axis_tdata_reg_sel <= ~s_axis_tdata_reg_sel;
            fsm_state            <= INPUT_VALID;
          end
        end

        default: fsm_state <= IDLE_STATE;
      endcase
    end
  end

endmodule

