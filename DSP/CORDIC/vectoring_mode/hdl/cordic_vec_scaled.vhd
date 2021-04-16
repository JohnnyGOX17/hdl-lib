-- CORDIC logic with output scaling to cancel out CORDIC gain (via CORDIC_scale)

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity cordic_vec_scaled is
  generic (
    G_ITERATIONS : natural := 16 -- also equates to output precision
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
    valid_in     : in  std_logic;
    x_in         : in  signed(G_ITERATIONS - 1 downto 0);
    y_in         : in  signed(G_ITERATIONS - 1 downto 0);
    CORDIC_scale : in  signed(G_ITERATIONS - 1 downto 0) := X"4DBA";

    valid_out    : out std_logic;
    phase_out    : out unsigned(31 downto 0); -- 32b phase (0-360deg)
    mag_out      : out signed(G_ITERATIONS - 1 downto 0)
  );
end entity cordic_vec_scaled;

architecture rtl of cordic_vec_scaled is

  component cordic_vec is
    generic (
      G_ITERATIONS : natural := 16 -- also equates to output precision
    );
    port (
      clk          : in  std_logic;
      reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
      valid_in     : in  std_logic;
      x_in         : in  signed(G_ITERATIONS - 1 downto 0);
      y_in         : in  signed(G_ITERATIONS - 1 downto 0);

      valid_out    : out std_logic;
      phase_out    : out unsigned(31 downto 0); -- 32b phase (0-360deg)
      mag_out      : out signed(G_ITERATIONS - 1 downto 0)
    );
  end component cordic_vec;

  signal sig_valid_out : std_logic := '0';
  signal sig_mag_out   : signed(G_ITERATIONS - 1 downto 0);
  signal sig_phase_out : unsigned(31 downto 0);

  signal sig_scl_valid : std_logic := '0';
  signal sig_mag_scl   : signed((2*G_ITERATIONS) - 1 downto 0);
  signal sig_phase_q   : unsigned(31 downto 0);

  signal sig_sft_valid : std_logic := '0';
  signal sig_mag_sft   : signed(G_ITERATIONS - 1 downto 0);
  signal sig_phase_qq  : unsigned(31 downto 0);

begin

  valid_out <= sig_sft_valid;
  phase_out <= sig_phase_qq;
  mag_out   <= sig_mag_sft;

  U_CORDIC_vectoring: cordic_vec
    generic map (
      G_ITERATIONS => G_ITERATIONS
    )
    port map (
      clk          => clk,
      reset        => reset,
      valid_in     => valid_in,
      x_in         => x_in,
      y_in         => y_in,

      valid_out    => sig_valid_out,
      phase_out    => sig_phase_out,
      mag_out      => sig_mag_out
    );

  S_scale_magnitudes: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- NOTE: mostly we need only reset registers related to handshaking/dataflow,
        --       which will aid in easing timing (less reset routing required than
        --       resetting the wider, data output registers)
        sig_scl_valid <= '0';
        sig_sft_valid <= '0';
      else
        -- normalize/cancel CORDIC gain using given scale factor
        if sig_valid_out = '1' then
          sig_mag_scl <= sig_mag_out * CORDIC_scale;
        end if;
        sig_scl_valid <= sig_valid_out;
        -- since we don't care about scaling phase (for now, interacts with
        -- other CORDIC/trig functions at full 32b width) just pipeline to
        -- match delay of scale & shift of magnitude signal
        sig_phase_q   <= sig_phase_out;

        -- scale normalized CORDIC magnitude back down to operational data width
        if sig_scl_valid = '1' then
          -- since scaling & data are always of same data width, can simply shift right
          -- by >> G_ITERATIONS value (-1 data width since given signed scale factor)
          sig_mag_sft <= resize( shift_right( sig_mag_scl,
                                              G_ITERATIONS - 1 ),
                                 sig_mag_sft'length );
        end if;
        sig_sft_valid <= sig_scl_valid;
        sig_phase_qq  <= sig_phase_q;

      end if;
    end if;
  end process S_scale_magnitudes;

end architecture rtl;

