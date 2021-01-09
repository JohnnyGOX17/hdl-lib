--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_cordic is
  generic (
    G_ITERATIONS : integer := 16 -- also equates to output precision
  );
end tb_cordic;

architecture behav of tb_cordic is

  signal clk       : std_logic := '0';
  signal valid_in  : std_logic := '0';
  signal x_start   : signed(G_ITERATIONS - 1 downto 0) := (others => '0');
  signal y_start   : signed(G_ITERATIONS - 1 downto 0) := (others => '0');
  signal angle     : signed(31 downto 0) := (others => '0');
  signal valid_out : std_logic;
  signal sine      : signed(G_ITERATIONS - 1 downto 0);
  signal cosine    : signed(G_ITERATIONS - 1 downto 0);
  signal sim_end   : boolean := false;

begin

  U_DUT: entity work.cordic
    generic map (
      G_ITERATIONS => G_ITERATIONS
    )
    port map (
      clk          => clk,
      valid_in     => valid_in,
      x_start      => x_start,
      y_start      => y_start,
      angle        => angle,
      valid_out    => valid_out,
      sine         => sine,
      cosine       => cosine
    );

  clk  <= not clk after 5.0 ns when not sim_end else '0';

  sim_inputs: process
  begin
    valid_in <= '0';
    x_start  <= to_signed( 19429, G_ITERATIONS );
    wait for 100 ns;
    wait until rising_edge(clk);
    valid_in <= '1';
    angle    <= "00100000000000000000000000000000"; -- example: 45 deg = 45/360 * 2^32 = 32'b00100000000000000000000000000000 = 45.000 degrees -> atan(2^0)
    wait until rising_edge(clk);
    valid_in <= '0';

    --// Test 2
    --// #1500
    --// angle = 'b00101010101010101010101010101010; // 60 deg

    --// Test 3
    --// #10000
    --// angle = 'b01000000000000000000000000000000; // 90 deg

    --// Test 4
    --// #10000
    --// angle = 'b00110101010101010101010101010101; // 75 deg

    wait for 1 us;
    sim_end <= true;
    wait;
  end process;

end architecture behav;

--synthesis translate_on
