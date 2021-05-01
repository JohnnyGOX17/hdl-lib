--
-- Implements the boundary cell (BC) of the QR architecture using two vector-mode
-- CORDIC engines to perform the "vectoring" on complex input samples to
-- nullify their imaginary parts and form rotation angles used by internal cells.
--
-- Inputs:
-- =======
-- - `CORDIC_scale`: scale factor to counteract CORDIC gain on magnitude from
--    vectoring engines
-- - `lambda`: (optional) forgetting factor applied to feedback magnitude. This
--    value is often selected to be slightly less than 1 (e.g. 0.99). When the
--    generic `G_USE_LAMBDA` == false, this forgetting factor is ignored and no
--    multiplier is used.
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity boundary_cell is
  generic (
    G_DATA_WIDTH : natural := 16;   -- operational bitwidth of datapath (in & out)
    G_USE_LAMBDA : boolean := false -- use forgetting factor (lambda) in BC calc
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    CORDIC_scale : in  signed(G_DATA_WIDTH - 1 downto 0) := X"4DBA";
    lambda       : in  signed(G_DATA_WIDTH - 1 downto 0) := X"7EB8";

    x_real       : in  signed(G_DATA_WIDTH - 1 downto 0); -- real
    x_imag       : in  signed(G_DATA_WIDTH - 1 downto 0); -- imag
    x_valid      : in  std_logic;
    x_ready      : out std_logic;

    -- Current CORDIC/trig blocks use 32b unsigned angles, so keep to that
    -- since this will directly feed the Internal Cell CORDIC Rotators
    phi_out      : out unsigned(31 downto 0);
    theta_out    : out unsigned(31 downto 0);
    bc_valid_out : out std_logic;
    ic_ready     : in  std_logic  -- downstream internal cell (IC) ready to consume
  );
end entity boundary_cell;

architecture rtl of boundary_cell is

  component cordic_vec_scaled is
    generic (
      G_ITERATIONS : integer := 16 -- also equates to output precision
    );
    port (
      clk          : in  std_logic;
      reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
      valid_in     : in  std_logic;
      x_in         : in  signed(G_ITERATIONS - 1 downto 0);
      y_in         : in  signed(G_ITERATIONS - 1 downto 0);
      CORDIC_scale : in  signed(G_ITERATIONS - 1 downto 0) := X"4DBA";

      valid_out    : out std_logic;
      phase_out    : out unsigned(31 downto 0);
      mag_out      : out signed(G_ITERATIONS - 1 downto 0)
    );
  end component;

  type T_bc_fsm is (S_IDLE, S_WAIT_PHI, S_WAIT_THETA, S_OUT_VALID);
  signal sig_bc_state : T_bc_fsm := S_IDLE;

  -- related to U_input_vectoring
  signal sig_x_valid_gated   : std_logic;
  signal sig_input_vec_valid : std_logic := '0';
  signal sig_phi_out         : unsigned(31 downto 0);
  signal sig_input_vec_mag   : signed(G_DATA_WIDTH - 1 downto 0);

  -- related to U_output_vectoring
  signal sig_output_vec_valid_out : std_logic := '0';
  signal sig_theta_out            : unsigned(31 downto 0);
  signal sig_output_vec_mag       : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_feedback_mag         : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_feedback_mag_valid   : std_logic := '0';
  signal sig_output_vec_valid_in  : std_logic := '0';

  -- forgetting factor scaling
  signal sig_lambda_mag_valid      : std_logic := '0';
  signal sig_lambda_mag            : signed((2*G_DATA_WIDTH) - 1 downto 0);

  -- output registers of theta & phi
  signal sig_phi_out_q   : unsigned(31 downto 0) := (others => '0');
  signal sig_theta_out_q : unsigned(31 downto 0) := (others => '0');

begin

  x_ready      <= '1' when (sig_bc_state = S_IDLE) and (reset = '0') else '0';
  phi_out      <= sig_phi_out_q;
  theta_out    <= sig_theta_out_q;
  bc_valid_out <= '1' when sig_bc_state = S_OUT_VALID else '0';

  sig_x_valid_gated <= x_valid when sig_bc_state = S_IDLE else '0';

  U_input_vectoring: cordic_vec_scaled
    generic map (
      G_ITERATIONS => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      reset        => reset,
      valid_in     => sig_x_valid_gated,
      x_in         => x_real,
      y_in         => x_imag,
      CORDIC_scale => CORDIC_scale,

      valid_out    => sig_input_vec_valid,
      phase_out    => sig_phi_out,      -- phi = atan2(Q, I)
      mag_out      => sig_input_vec_mag -- mag = sqrt(I**2 + Q**2)
    );

  -- we need only care about input vectoring magnitude valid as feedback magnitude
  -- will _always_ be valid and stable before this point, due to being calculated
  -- from previous cycle (or from reset, default value). Thus the signal
  -- `sig_feedback_mag_valid` is purely for informational/debug value, and will
  -- get optmized out as a dead-path in synthesis as nothing reads it
  sig_output_vec_valid_in <= sig_input_vec_valid;

  U_output_vectoring: cordic_vec_scaled
    generic map (
      G_ITERATIONS => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      reset        => reset,
      valid_in     => sig_output_vec_valid_in,
      x_in         => sig_feedback_mag,
      -- scaled magnitude output from input vectoring
      y_in         => sig_input_vec_mag,
      CORDIC_scale => CORDIC_scale,

      valid_out    => sig_output_vec_valid_out,
      phase_out    => sig_theta_out,
      mag_out      => sig_output_vec_mag
    );


  UG_apply_forgetting_factor: if G_USE_LAMBDA generate
    S_scale_lambda: process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          -- feedback magnitude's zero'ed on reset
          sig_lambda_mag_valid   <= '0';
          sig_lambda_mag         <= (others => '0');
          sig_feedback_mag       <= (others => '0');
          sig_feedback_mag_valid <= '0';
        else
          -- apply lambda scaling/forgetting factor for feedback magnitude
          if sig_output_vec_valid_out = '1' then
            sig_lambda_mag     <= sig_output_vec_mag * lambda;
          end if;
          sig_lambda_mag_valid <= sig_output_vec_valid_out;

          -- scale back down to operational data width
          if sig_lambda_mag_valid = '1' then
            sig_feedback_mag     <= resize( shift_right( sig_lambda_mag,
                                                         G_DATA_WIDTH - 1 ),
                                            sig_feedback_mag'length );
          end if;
          sig_feedback_mag_valid <= sig_lambda_mag_valid;
        end if;
      end if;
    end process S_scale_lambda;
  end generate UG_apply_forgetting_factor;

  UG_no_forgetting_factor: if not G_USE_LAMBDA generate
    S_no_lambda: process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          -- feedback magnitude's zero'ed on reset
          sig_feedback_mag       <= (others => '0');
          sig_feedback_mag_valid <= '0';
        else
          if sig_output_vec_valid_out = '1' then
            sig_feedback_mag     <= sig_output_vec_mag;
          end if;
          sig_feedback_mag_valid <= sig_output_vec_valid_out;
        end if;
      end if;
    end process S_no_lambda;
  end generate UG_no_forgetting_factor;


  S_output_FSM: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_bc_state <= S_IDLE;
      else
        case sig_bc_state is
          when S_IDLE =>
            if x_valid = '1' then
              sig_bc_state <= S_WAIT_PHI;
            end if;

          when S_WAIT_PHI =>
            if sig_input_vec_valid = '1' then
              sig_phi_out_q <= sig_phi_out;
              sig_bc_state  <= S_WAIT_THETA;
            end if;

          -- since theta needs second CORDIC vectoring operation, it will always
          -- take longer than input/first CORDIC vectoring operation
          when S_WAIT_THETA =>
            if sig_output_vec_valid_out = '1' then
              sig_theta_out_q <= sig_theta_out;
              sig_bc_state    <= S_OUT_VALID;
            end if;

          when S_OUT_VALID =>
            -- wait till downstream internal cell is ready to consume theta & phi
            if ic_ready = '1' then
              sig_bc_state <= S_IDLE;
            end if;

          when others => sig_bc_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process S_output_FSM;

end architecture rtl;
