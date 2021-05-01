library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_weight_extract_cell is
end entity tb_weight_extract_cell;

architecture behav of tb_weight_extract_cell is

  constant G_DATA_WIDTH : natural := 16;

  signal clk          : std_logic := '0';
  signal reset        : std_logic;

  -- no `ready` signal as a is updated across final row
  signal ain_real     : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal ain_imag     : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal ain_valid    : std_logic := '0';

  -- pipelined `a` to be passed to next weight extract cell
  signal aout_real    : signed(G_DATA_WIDTH - 1 downto 0);
  signal aout_imag    : signed(G_DATA_WIDTH - 1 downto 0);
  signal aout_valid   : std_logic;

  signal b_real       : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal b_imag       : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal b_valid      : std_logic := '0';
  signal b_ready      : std_logic;

  signal w_real       : signed(G_DATA_WIDTH - 1 downto 0);
  signal w_imag       : signed(G_DATA_WIDTH - 1 downto 0);
  signal w_valid      : std_logic;
  signal w_ready      : std_logic := '0';

  signal sim_end      : boolean := false;

begin

  U_DUT: entity work.weight_extract_cell
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      reset        => reset,
      ain_real     => ain_real,
      ain_imag     => ain_imag,
      ain_valid    => ain_valid,
      aout_real    => aout_real,
      aout_imag    => aout_imag,
      aout_valid   => aout_valid,
      b_real       => b_real,
      b_imag       => b_imag,
      b_valid      => b_valid,
      b_ready      => b_ready,
      w_real       => w_real,
      w_imag       => w_imag,
      w_valid      => w_valid,
      w_ready      => w_ready
    );

  clk   <= not clk after 5.0 ns when not sim_end else '0';
  reset <= '1','0' after 100 ns;

  CS_test_a_input: process
  begin
    wait until reset = '0';
    wait until rising_edge(clk);

    ain_real  <= to_signed(  4000, G_DATA_WIDTH );
    ain_imag  <= to_signed( -2000, G_DATA_WIDTH );
    ain_valid <= '1';
    wait until rising_edge(clk);
    ain_valid <= '0';

    wait until rising_edge(clk) and w_valid = '1';

    -- test out constantly valid inputs to check consumption timing
    for i in 0 to 5 loop
      wait until rising_edge(clk);
    end loop;
    ain_valid <= '1';

    wait;
  end process CS_test_a_input;

  CS_test_inputs: process
  begin
    wait until reset = '0';
    wait until rising_edge(clk);

    w_ready <= '1';

    -- test some arbitrary I/Q input
    wait until rising_edge(clk);
    b_real  <= to_signed(  4000, G_DATA_WIDTH );
    b_imag  <= to_signed( -2000, G_DATA_WIDTH );
    b_valid <= '1';
    wait until rising_edge(clk) and b_ready = '1';
    b_real  <= (others => '0');
    b_imag  <= (others => '0');
    b_valid <= '0';

    wait until rising_edge(clk) and w_valid = '1';

    -- test out constantly valid inputs to check consumption timing
    b_valid <= '1';
    wait for 2 us;

    -- test hold-up in downstream IC logic
    wait until rising_edge(clk);
    w_ready <= '0';
    wait until rising_edge(clk) and w_valid = '1';
    wait for 100 ns;
    wait until rising_edge(clk);
    w_ready <= '1';
    wait for 2 us;

    report "SIM COMPLETE";
    sim_end <= true;
    wait;
  end process CS_test_inputs;

end architecture behav;
