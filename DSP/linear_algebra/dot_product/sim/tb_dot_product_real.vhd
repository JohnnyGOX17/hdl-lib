library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity tb_dot_product_real is
end tb_dot_product_real;

architecture behav of tb_dot_product_real is

  signal clk        : std_logic := '0';
  signal reset      : std_logic;
  signal din_valid  : std_logic := '0';
  signal din_a      : T_slv_2D(7 downto 0)(15 downto 0);
  signal din_b      : T_slv_2D(7 downto 0)(15 downto 0);
  signal dout_valid : std_logic;
  signal dout       : std_logic_vector(34 downto 0);

  signal sim_end    : boolean := false;
  signal exp_result : integer := 0;

begin

  clk   <= not clk after 10.0 ns when not sim_end else '0';
  reset <= '1','0' after  100 ns;

  CS_data_inputs: process
    variable slv_tmp_a : std_logic_vector(15 downto 0);
    variable slv_tmp_b : std_logic_vector(15 downto 0);
    variable accum     : integer := 0;
  begin
    wait until reset = '0';
    wait until rising_edge(clk);

    for i in 0 to 7 loop
      slv_tmp_a := std_logic_vector( to_unsigned( i, 16 ) );
      slv_tmp_b := std_logic_vector( to_unsigned( i+8, 16 ) );
      accum     := accum + to_integer( signed( slv_tmp_a ) * signed( slv_tmp_b ) );
      din_a(i)  <= slv_tmp_a;
      din_b(i)  <= slv_tmp_b;
    end loop;
    exp_result <= accum;

    din_valid <= '1';
    wait until rising_edge(clk);
    din_valid <= '0';

    wait for 200 ns;
    sim_end <= true;
    wait;
  end process CS_data_inputs;

  CS_log_result: process
  begin
    wait until rising_edge(clk) and dout_valid = '1';
    report "Dot product result: " & to_hstring(dout);
    if exp_result = to_integer( unsigned( dout ) ) then
      report "Matches expected result: " & integer'image(exp_result);
    else
      report "Does not match expected result: " & integer'image(exp_result)
        severity failure;
    end if;
    wait;
  end process CS_log_result;

  U_DUT: entity work.dot_product_real
    generic map (
      G_AWIDTH  => 16,   -- input vector bitwidth
      G_BWIDTH  => 16,   -- input vector bitwidth
      G_VEC_LEN =>  8,   -- number of input samples in each vector
      G_REG_IN  => true, -- register inputs samples before multiplies?
      G_SIGNED  => true  -- {true = signed, false = unsigned} math
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => din_valid,
      din_a        => din_a,
      din_b        => din_b,
      dout_valid   => dout_valid,
      dout         => dout
    );

end architecture behav;

