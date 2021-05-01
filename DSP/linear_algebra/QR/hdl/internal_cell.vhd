--
-- Implements the internal cell (IC) of the QR architecture using four rotation-mode
-- CORDIC engines
--
-- Inputs:
-- =======
-- - `CORDIC_scale`: scale factor to counteract CORDIC gain on magnitude from
--    vectoring engines
-- - `lambda`: (optional) forgetting factor applied to feedback magnitude. This
--    value is often selected to be slightly less than 1 (e.g. 0.99). When the
--    generic `G_USE_LAMBDA` == false, this forgetting factor is ignored and no
--    multiplier is used. For inverse internal cells, set this value to 1/lambda
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity internal_cell is
  generic (
    G_DATA_WIDTH : natural := 16;   -- operational bitwidth of datapath (in & out)
    G_USE_LAMBDA : boolean := false -- use forgetting factor (lambda) in BC calc
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    CORDIC_scale : in  signed(G_DATA_WIDTH - 1 downto 0) := X"4DBA";
    lambda       : in  signed(G_DATA_WIDTH - 1 downto 0) := X"7EB8";

    xin_real     : in  signed(G_DATA_WIDTH - 1 downto 0);
    xin_imag     : in  signed(G_DATA_WIDTH - 1 downto 0);
    xin_valid    : in  std_logic;
    xin_ready    : out std_logic;
    -- Current CORDIC/trig blocks use 32b unsigned angles, so keep to that
    -- since this is directly feed from Boundary Cell CORDIC Vector engines
    phi_in       : in  unsigned(31 downto 0);
    theta_in     : in  unsigned(31 downto 0);
    bc_valid_in  : in  std_logic; -- connected to BC on first IC in row, else connected to angles valid from previous IC in row
    ic_ready     : out std_logic; -- this internal cell (IC) ready to consume (only needed for first IC connected to BC)


    xout_real    : out signed(G_DATA_WIDTH - 1 downto 0);
    xout_imag    : out signed(G_DATA_WIDTH - 1 downto 0);
    xout_valid   : out std_logic;
    xout_ready   : in  std_logic;

    -- These are registered copies, propogated to next IC in row, to prevent
    -- high fan-out of 32b angle signals (no handshaking needed, since ICs not
    -- connected directly to a BC have handshaking/timing with rotations)
    phi_out      : out unsigned(31 downto 0);
    theta_out    : out unsigned(31 downto 0);
    angles_valid : out std_logic
  );
end entity internal_cell;

architecture rtl of internal_cell is

  component cordic_rot_scaled is
    generic (
      G_ITERATIONS : natural := 16 -- also equates to output precision
    );
    port (
      clk          : in  std_logic;
      reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
      valid_in     : in  std_logic;
      x_in         : in  signed(G_ITERATIONS - 1 downto 0);
      y_in         : in  signed(G_ITERATIONS - 1 downto 0);
      angle_in     : in  unsigned(31 downto 0);             -- 32b phase_in (0-360deg)
      CORDIC_scale : in  signed(G_ITERATIONS - 1 downto 0) := X"4DBA";

      valid_out    : out std_logic;
      cos_out      : out signed(G_ITERATIONS - 1 downto 0); -- cosine/x_out
      sin_out      : out signed(G_ITERATIONS - 1 downto 0)  -- sine/y_out
    );
  end component cordic_rot_scaled;

  type T_ic_fsm is (S_IDLE, S_CONSUME, S_WAIT_ROTATIONS, S_OUT_VALID);
  signal sig_ic_state : T_ic_fsm := S_IDLE;

  signal sig_inputs_valid        : std_logic;

  -- Input Rotator
  signal sig_in_rot_valid_out    : std_logic;
  signal sig_in_rot_cos_out      : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_in_rot_sin_out      : signed(G_DATA_WIDTH - 1 downto 0);

  -- Real Rotator
  signal sig_real_rot_valid      : std_logic;
  signal sig_real_x_feedback     : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_real_x_out          : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_real_y_out          : signed(G_DATA_WIDTH - 1 downto 0);

  -- Imag Rotator
  signal sig_imag_rot_valid      : std_logic;
  signal sig_imag_x_feedback     : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_imag_x_out          : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_imag_y_out          : signed(G_DATA_WIDTH - 1 downto 0);

  -- Registered outputs
  signal sig_xout_real        : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_xout_imag        : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_phi_out          : unsigned(31 downto 0);
  signal sig_theta_out        : unsigned(31 downto 0);

begin

  -- assert ready once able to consume both x/sample & BC inputs
  -- due to difference in timing between datapaths
  xin_ready    <= '1' when sig_ic_state = S_CONSUME   else '0';
  ic_ready     <= '1' when sig_ic_state = S_CONSUME   else '0';
  xout_valid   <= '1' when sig_ic_state = S_OUT_VALID else '0';
  angles_valid <= '1' when sig_ic_state = S_OUT_VALID else '0';

  xout_real <= sig_xout_real;
  xout_imag <= sig_xout_imag;
  phi_out   <= sig_phi_out;
  theta_out <= sig_theta_out;

  -- gated valid signal, only propagate through once we've consumed a sample
  sig_inputs_valid <= '1' when sig_ic_state = S_CONSUME else '0';

  U_input_rotator: cordic_rot_scaled
    generic map (
      G_ITERATIONS => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      reset        => reset,
      valid_in     => sig_inputs_valid,
      x_in         => xin_real,
      y_in         => xin_imag,
      angle_in     => phi_in,
      CORDIC_scale => CORDIC_scale,

      valid_out    => sig_in_rot_valid_out,
      cos_out      => sig_in_rot_cos_out,
      sin_out      => sig_in_rot_sin_out
    );

  U_real_rotator: cordic_rot_scaled
    generic map (
      G_ITERATIONS => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      reset        => reset,
      valid_in     => sig_in_rot_valid_out,
      x_in         => sig_real_x_feedback,
      y_in         => sig_in_rot_cos_out,
      angle_in     => theta_in,
      CORDIC_scale => CORDIC_scale,

      valid_out    => sig_real_rot_valid,
      cos_out      => sig_real_x_out,
      sin_out      => sig_real_y_out
    );

  U_imag_rotator: cordic_rot_scaled
    generic map (
      G_ITERATIONS => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      reset        => reset,
      valid_in     => sig_in_rot_valid_out,
      x_in         => sig_imag_x_feedback,
      y_in         => sig_in_rot_sin_out,
      angle_in     => theta_in,
      CORDIC_scale => CORDIC_scale,

      valid_out    => sig_imag_rot_valid,
      cos_out      => sig_imag_x_out,
      sin_out      => sig_imag_y_out
    );


  UG_no_lambda: if not G_USE_LAMBDA generate
    S_X_feedbacks: process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          sig_real_x_feedback <= (others => '0');
          sig_imag_x_feedback <= (others => '0');
        else
          if sig_real_rot_valid = '1' then
            sig_real_x_feedback <= sig_real_x_out;
          end if;

          if sig_imag_rot_valid = '1' then
            sig_imag_x_feedback <= sig_imag_x_out;
          end if;
        end if;
      end if;
    end process S_X_feedbacks;
  end generate UG_no_lambda;

  S_output_FSM: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_ic_state <= S_IDLE;
      else
        case sig_ic_state is
          when S_IDLE =>
            if (xin_valid = '1') and (bc_valid_in = '1') then
              sig_ic_state <= S_CONSUME;
            end if;

          when S_CONSUME =>
            sig_ic_state <= S_WAIT_ROTATIONS;

          when S_WAIT_ROTATIONS =>
            -- Real & Imag rotations should take exactly the same amount of time
            if (sig_real_rot_valid = '1') and (sig_imag_rot_valid = '1') then
              sig_xout_real <= sig_real_y_out;
              sig_xout_imag <= sig_imag_y_out;
              sig_ic_state  <= S_OUT_VALID;
            end if;

          when S_OUT_VALID =>
            -- wait till downstream internal/boundary cell in next row is ready
            if xout_ready = '1' then
              sig_ic_state <= S_IDLE;
            end if;

          when others => sig_ic_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process S_output_FSM;

  S_pipeline_angles: process(clk)
  begin
    if rising_edge(clk) then
      if bc_valid_in = '1' then -- reg angles whenever valid to hold until output
        sig_phi_out   <= phi_in;
        sig_theta_out <= theta_in;
      end if;
    end if;
  end process S_pipeline_angles;

end architecture rtl;
