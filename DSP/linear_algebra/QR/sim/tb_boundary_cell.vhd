library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_boundary_cell is
end entity tb_boundary_cell;

architecture behav of tb_boundary_cell is

  constant G_DATA_WIDTH : natural := 16;

  signal clk          : std_logic := '0';
  signal reset        : std_logic;
  -- default is CORDIC scaling for 16 iterations
  signal CORDIC_scale : signed(G_DATA_WIDTH - 1 downto 0) := X"4DBA";
  -- default is lambda = 0.99
  signal lambda       : signed(G_DATA_WIDTH - 1 downto 0) := X"7EB8";

  signal x_real       : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- real
  signal x_imag       : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- imag
  signal x_valid      : std_logic := '0';
  signal x_ready      : std_logic;

  signal phi_out      : unsigned(31 downto 0);
  signal theta_out    : unsigned(31 downto 0);
  signal bc_valid_out : std_logic;
  signal ic_ready     : std_logic := '0'; -- downstream internal cell (IC) ready to consume
  signal sim_end      : boolean := false;

begin

  U_DUT: entity work.boundary_cell
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_USE_LAMBDA => false
    )
    port map (
      clk          => clk,
      reset        => reset,
      CORDIC_scale => CORDIC_scale,
      lambda       => lambda,
      x_real       => x_real,
      x_imag       => x_imag,
      x_valid      => x_valid,
      x_ready      => x_ready,
      phi_out      => phi_out,
      theta_out    => theta_out,
      bc_valid_out => bc_valid_out,
      ic_ready     => ic_ready
    );

  clk   <= not clk after 5.0 ns when not sim_end else '0';
  reset <= '1','0' after 100 ns;

  CS_test_inputs: process
  begin
    wait until reset = '0';
    wait until rising_edge(clk);

    ic_ready <= '1';

    -- test some arbitrary I/Q input
    wait until rising_edge(clk);
    x_real  <= to_signed(  4000, G_DATA_WIDTH );
    x_imag  <= to_signed( -2000, G_DATA_WIDTH );
    x_valid <= '1';
    wait until x_ready = '1' and rising_edge(clk);
    x_real  <= (others => '0');
    x_imag  <= (others => '0');
    x_valid <= '0';

    wait until bc_valid_out = '1' and rising_edge(clk);
    -- NOTE: the current phi & theta output values are truncated due to issues
    --       with trying to represent an unsigned 32b integer directly in GHDL
    report "Phi Out: " & integer'image(to_integer(phi_out(30 downto 0))) & " [0x" & to_hstring(phi_out) & "]";
    report "Theta Out: " & integer'image(to_integer(theta_out(30 downto 0))) & " [0x" & to_hstring(theta_out) & "]";

    -- test out constantly valid inputs to check consumption timing
    x_valid <= '1';
    wait for 2 us;

    -- test hold-up in downstream IC logic
    wait until rising_edge(clk);
    ic_ready <= '0';
    wait until rising_edge(clk) and bc_valid_out = '1';
    wait for 100 ns;
    wait until rising_edge(clk);
    ic_ready <= '1';
    wait for 2 us;

    report "SIM COMPLETE";
    sim_end <= true;
    wait;
  end process CS_test_inputs;

end architecture behav;
