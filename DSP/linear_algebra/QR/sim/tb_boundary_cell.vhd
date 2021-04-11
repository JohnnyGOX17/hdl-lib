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

  signal I_in         : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- real
  signal Q_in         : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- imag
  signal IQ_valid_in  : std_logic := '0';
  signal IQ_ready     : std_logic;

  signal phi_out      : signed(G_DATA_WIDTH - 1 downto 0);
  signal theta_out    : signed(G_DATA_WIDTH - 1 downto 0);
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
      I_in         => I_in,
      Q_in         => Q_in,
      IQ_valid_in  => IQ_valid_in,
      IQ_ready     => IQ_ready,
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
    I_in        <= to_signed(  4000, G_DATA_WIDTH );
    Q_in        <= to_signed( -2000, G_DATA_WIDTH );
    IQ_valid_in <= '1';
    wait until IQ_ready = '1' and rising_edge(clk);
    I_in        <= (others => '0');
    Q_in        <= (others => '0');
    IQ_valid_in <= '0';

    wait for 1 us;
    sim_end <= true;
    wait;
  end process CS_test_inputs;

end architecture behav;
