--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_cordic is
end tb_cordic;

architecture behav of tb_cordic is

  -- constant here since explicit checks on outputs used
  constant G_ITERATIONS : integer := 16;

  signal clk       : std_logic := '0';
  signal valid_in  : std_logic := '0';
  signal x_in      : signed(G_ITERATIONS - 1 downto 0) := (others => '0');
  signal y_in      : signed(G_ITERATIONS - 1 downto 0) := (others => '0');
  signal angle_in  : unsigned(31 downto 0) := (others => '0');
  signal valid_out : std_logic;
  signal sin_out   : signed(G_ITERATIONS - 1 downto 0);
  signal cos_out   : signed(G_ITERATIONS - 1 downto 0);
  signal sim_end   : boolean := false;

begin

  U_DUT: entity work.cordic
    generic map (
      G_ITERATIONS => G_ITERATIONS
    )
    port map (
      clk          => clk,
      valid_in     => valid_in,
      x_in         => x_in,
      y_in         => y_in,
      angle_in     => angle_in,
      valid_out    => valid_out,
      sin_out      => sin_out,
      cos_out      => cos_out
    );

  clk  <= not clk after 5.0 ns when not sim_end else '0';

  CS_sim_inputs: process
  begin
    valid_in <= '0';
    wait for 100 ns;
    wait until rising_edge(clk);

    --// Test Rotation Mode ---------------------------------------------------
    -- In rotation mode, we essentially are converting ("rotating") a polar
    -- format vector to rectangular/cartesian coordinates; the sine & cosine
    -- of an angle are not only calculated here, but really the input magnitude
    -- and phase are used as well to give X/Y coordinates of a vector with the
    -- same magnitude as the input vector.
    --
    -- Thus in this mode, we leave y_in = 0 and set x_in = to the vector
    -- magnitude and give an input phase (`angle_in`) to calculate:

    -- angle_in = 45 deg => 45/360 * 2^32 = 536,870,912
    --  => 32'b00100000000000000000000000000000
    angle_in <= b"00100000_00000000_00000000_00000000";
    x_in     <= to_signed( 19429, G_ITERATIONS ); -- arbitrary magnitude input
    valid_in <= '1';
    wait until rising_edge(clk);
    valid_in <= '0';
    wait until rising_edge(clk) and valid_out = '1';
    -- not the best, but using precalculated checks here...
    assert to_integer( cos_out ) = 22622 report "value did not match expected!" severity error;
    assert to_integer( sin_out ) = 22623 report "value did not match expected!" severity error;
    wait until rising_edge(clk);

    -- angle_in = 60 deg => 60/360 * 2^32 = 715,827,882.7
    --   => 32'b00101010101010101010101010101010
    --angle_in <= "00101010_10101010_10101010_10101010";
    angle_in <= to_unsigned( 715827882, 32 );
    x_in     <= to_signed( 5000, G_ITERATIONS ); -- arbitrary magnitude input
    valid_in <= '1';
    wait until rising_edge(clk);
    valid_in <= '0';
    wait until rising_edge(clk) and valid_out = '1';
    -- not the best, but using precalculated checks here...
    --assert to_integer( cos_out ) = 22622 report "value did not match expected!" severity error;
    --assert to_integer( sin_out ) = 22623 report "value did not match expected!" severity error;
    wait until rising_edge(clk);

    --// angle_in = 'b01000000000000000000000000000000; // 90 deg

    --// angle_in = 'b00110101010101010101010101010101; // 75 deg

    wait for 250 ns;
    sim_end <= true;
    wait;
  end process;

end architecture behav;

--synthesis translate_on
