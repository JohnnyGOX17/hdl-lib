-- CORDIC logic with output scaling to cancel out CORDIC gain (via CORDIC_scale)

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity cordic_rot_scaled is
  generic (
    G_ITERATIONS : natural := 16; -- also equates to output precision
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
    valid_in     : in  std_logic;
    x_in         : in  signed(G_ITERATIONS - 1 downto 0);
    y_in         : in  signed(G_ITERATIONS - 1 downto 0);
    angle_in     : in  unsigned(31 downto 0);             -- 32b phase_in (0-360deg)
    CORDIC_scale : in  signed(G_DATA_WIDTH - 1 downto 0) := X"4DBA";

    valid_out    : out std_logic;
    cos_out      : out signed(G_ITERATIONS - 1 downto 0); -- cosine/x_out
    sin_out      : out signed(G_ITERATIONS - 1 downto 0)  -- sine/y_out
  );
end entity cordic_rot_scaled;

architecture rtl of cordic_rot_scaled is

  component cordic is
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

      valid_out    : out std_logic;
      cos_out      : out signed(G_ITERATIONS - 1 downto 0); -- cosine/x_out
      sin_out      : out signed(G_ITERATIONS - 1 downto 0)  -- sine/y_out
    );
  end component cordic;

  signal sig_valid_out : std_logic := '0';
  signal sig_cos_out   : signed(G_ITERATIONS - 1 downto 0); -- cosine/x_out
  signal sig_sin_out   : signed(G_ITERATIONS - 1 downto 0); -- sine/y_out

  signal sig_scl_valid : std_logic := '0';
  signal sig_cos_scl   : signed((2*G_ITERATIONS) - 1 downto 0);
  signal sig_sin_scl   : signed((2*G_ITERATIONS) - 1 downto 0);

  signal sig_sft_valid : std_logic := '0';
  signal sig_cos_sft   : signed(G_ITERATIONS - 1 downto 0);
  signal sig_sin_sft   : signed(G_ITERATIONS - 1 downto 0);

begin

  valid_out <= sig_sft_valid;
  cos_out   <= sig_cos_sft;
  sin_out   <= sig_sin_sft;

  U_CORDIC_rotation: cordic
    generic map (
      G_ITERATIONS => G_ITERATIONS
    )
    port map (
      clk          => clk,
      reset        => reset,
      valid_in     => valid_in,
      x_in         => x_in,
      y_in         => y_in,
      angle_in     => angle_in,
      valid_out    => sig_valid_out,
      cos_out      => sig_cos_out,
      sin_out      => sig_sin_out
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
          sig_cos_scl <= sig_cos_out * CORDIC_scale;
          sig_sin_scl <= sig_sin_out * CORDIC_scale;
        end if;
        sig_scl_valid <= sig_valid_out;

        -- scale normalized CORDIC magnitude back down to operational data width
        if sig_scl_valid = '1' then
          -- since scaling & data are always of same data width, can simply shift right
          -- by >> G_ITERATIONS value (-1 data width since given signed scale factor)
          sig_cos_sft <= resize( shift_right( sig_cos_scl,
                                              G_ITERATIONS - 1 ),
                                 sig_cos_sft'length );
          sig_sin_sft <= resize( shift_right( sig_sin_scl,
                                              G_ITERATIONS - 1 ),
                                 sig_sin_sft'length );
        end if;
        sig_sft_valid <= sig_scl_valid;

      end if;
    end if;
  end process S_scale_magnitudes;

end architecture rtl;

