--synthesis translate_off

-- Sim Parallel Adder Tree w/recursion (VHDL-2008)
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;
-- Setup tb for use with VUnit
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_adder_tree is
  generic (
    runner_cfg   : string -- VUnit generic interface
  );
end tb_adder_tree;

architecture behav of tb_adder_tree is

  signal clk             : std_logic := '0';
  signal reset           : std_logic;
  signal din_valid_even  : std_logic := '0';
  signal din_valid_odd   : std_logic := '0';
  signal din_even        : T_slv_2D(7 downto 0)(15 downto 0);
  signal din_odd         : T_slv_2D(8 downto 0)(15 downto 0);
  signal dout_valid_even : std_logic;
  signal dout_valid_odd  : std_logic;
  signal dout_even       : std_logic_vector(18 downto 0);
  signal dout_odd        : std_logic_vector(19 downto 0);

  signal sim_end : boolean := false;

  signal exp_even_result : integer := 0;
  signal exp_odd_result  : integer := 0;

begin

  clk   <= not clk after 10.0 ns when not sim_end else '0';
  reset <= '1','0' after  100 ns;

  CS_data_inputs: process
    variable slv_tmp    : std_logic_vector(15 downto 0);
    variable accum_even : integer := 0;
    variable accum_odd  : integer := 0;
  begin

    test_runner_setup(runner, runner_cfg); -- VUnit entry call

    wait until reset = '0';
    wait until rising_edge(clk);

    for i in 0 to 7 loop
      slv_tmp     := std_logic_vector( to_unsigned( i, 16 ) );
      accum_even  := accum_even + to_integer( unsigned( slv_tmp ) );
      din_even(i) <= slv_tmp;
      report "din_even(" & integer'image(i) & "): " & to_hstring(slv_tmp);
    end loop;
    exp_even_result <= accum_even;

    for i in 0 to 8 loop
      slv_tmp    := std_logic_vector( to_unsigned( i+8, 16 ) );
      accum_odd  := accum_odd + to_integer( unsigned( slv_tmp ) );
      din_odd(i) <= slv_tmp;
      report "din_odd(" & integer'image(i) & "): " & to_hstring(slv_tmp);
    end loop;
    exp_odd_result <= accum_odd;

    din_valid_even <= '1';
    din_valid_odd  <= '1';
    wait until rising_edge(clk);
    din_valid_even <= '0';
    din_valid_odd  <= '0';

    wait for 200 ns;
    test_runner_cleanup(runner); -- VUnit exit call, sim ends here
    sim_end <= true;
    wait;
  end process CS_data_inputs;

  CS_log_even_result: process
  begin
    wait until rising_edge(clk) and dout_valid_even = '1';
    report "Even adder tree result: " & to_hstring(dout_even);
    if exp_even_result = to_integer( unsigned( dout_even ) ) then
      report "Matches expected result: " & integer'image(exp_even_result);
    else
      report "Does not match expected result: " & integer'image(exp_even_result)
        severity failure;
    end if;
    wait;
  end process CS_log_even_result;

  CS_log_odd_result: process
  begin
    wait until rising_edge(clk) and dout_valid_odd = '1';
    report "Odd adder tree result: " & to_hstring(dout_odd);
    if exp_odd_result = to_integer( unsigned( dout_odd ) ) then
      report "Matches expected result: " & integer'image(exp_odd_result);
    else
      report "Does not match expected result: " & integer'image(exp_odd_result)
        severity failure;
    end if;
    wait;
  end process CS_log_odd_result;

  U_DUT_even: entity work.adder_tree
    generic map (
      G_DATA_WIDTH => 16,
      G_NUM_INPUTS => 8
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => din_valid_even,
      din          => din_even,
      dout_valid   => dout_valid_even,
      dout         => dout_even
    );

  U_DUT_odd: entity work.adder_tree
    generic map (
      G_DATA_WIDTH => 16,
      G_NUM_INPUTS => 9
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => din_valid_odd,
      din          => din_odd,
      dout_valid   => dout_valid_odd,
      dout         => dout_odd
    );

end architecture behav;

--synthesis translate_on
