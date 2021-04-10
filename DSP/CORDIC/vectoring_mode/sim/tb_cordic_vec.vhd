--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_cordic_vec is
end tb_cordic_vec;

architecture behav of tb_cordic_vec is

  -- constant here since explicit checks on outputs used
  constant G_ITERATIONS : integer := 16;

  signal clk       : std_logic := '0';
  signal valid_in  : std_logic := '0';
  signal x_in      : signed(G_ITERATIONS - 1 downto 0) := (others => '0');
  signal y_in      : signed(G_ITERATIONS - 1 downto 0) := (others => '0');
  signal valid_out : std_logic;
  signal phase_out : signed(31 downto 0);
  signal mag_out   : signed(G_ITERATIONS - 1 downto 0);
  signal sim_end   : boolean := false;

begin

  U_DUT: entity work.cordic_vec
    generic map (
      G_ITERATIONS => G_ITERATIONS
    )
    port map (
      clk          => clk,
      valid_in     => valid_in,
      x_in         => x_in,
      y_in         => y_in,
      valid_out    => valid_out,
      phase_out    => phase_out,
      mag_out      => mag_out
    );

  clk  <= not clk after 5.0 ns when not sim_end else '0';

  CS_sim_inputs: process
  begin
    valid_in <= '0';
    wait for 100 ns;
    wait until rising_edge(clk);

    x_in     <= to_signed( 5000, G_ITERATIONS ); -- arbitrary magnitude input
    y_in     <= to_signed( 2000, G_ITERATIONS ); -- arbitrary magnitude input
    valid_in <= '1';
    wait until rising_edge(clk);
    valid_in <= '0';
    wait until rising_edge(clk) and valid_out = '1';


    wait for 250 ns;
    sim_end <= true;
    wait;
  end process;

end architecture behav;

--synthesis translate_on
