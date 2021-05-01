library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_internal_cell is
end entity tb_internal_cell;

architecture behav of tb_internal_cell is

  constant G_DATA_WIDTH : natural := 16;

  signal clk          : std_logic := '0';
  signal reset        : std_logic;
  -- default is CORDIC scaling for 16 iterations
  signal CORDIC_scale : signed(G_DATA_WIDTH - 1 downto 0) := X"4DBA";
  -- default is lambda = 0.99
  signal lambda       : signed(G_DATA_WIDTH - 1 downto 0) := X"7EB8";

  signal xin_real     : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- real
  signal xin_imag     : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- imag
  signal xin_valid    : std_logic := '0';
  signal xin_ready    : std_logic;

  signal phi_in       : unsigned(31 downto 0) := (others => '0');
  signal theta_in     : unsigned(31 downto 0) := (others => '0');
  signal bc_valid_in  : std_logic := '0';
  signal ic_ready     : std_logic;

  signal xout_real    : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- real
  signal xout_imag    : signed(G_DATA_WIDTH - 1 downto 0) := (others => '0'); -- imag
  signal xout_valid   : std_logic := '0';
  signal xout_ready   : std_logic := '1';

  signal phi_out      : unsigned(31 downto 0);
  signal theta_out    : unsigned(31 downto 0);
  signal angles_valid : std_logic;
  signal sim_end      : boolean := false;

begin

  U_DUT: entity work.internal_cell
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_USE_LAMBDA => false
    )
    port map (
      clk          => clk,
      reset        => reset,
      CORDIC_scale => CORDIC_scale,
      lambda       => lambda,
      xin_real     => xin_real,
      xin_imag     => xin_imag,
      xin_valid    => xin_valid,
      xin_ready    => xin_ready,

      phi_in       => phi_in,
      theta_in     => theta_in,
      bc_valid_in  => bc_valid_in,
      ic_ready     => ic_ready,

      xout_real    => xout_real,
      xout_imag    => xout_imag,
      xout_valid   => xout_valid,
      xout_ready   => xout_ready,

      phi_out      => phi_out,
      theta_out    => theta_out,
      angles_valid => angles_valid
    );

  clk   <= not clk after 5.0 ns when not sim_end else '0';
  reset <= '1','0' after 100 ns;

  CS_test_sample_inputs: process
  begin
    wait until reset = '0';
    wait until rising_edge(clk);
    -- test some arbitrary I/Q input
    xin_real  <= to_signed(  4000, G_DATA_WIDTH );
    xin_imag  <= to_signed( -2000, G_DATA_WIDTH );
    xin_valid <= '1';
    wait until xin_ready = '1' and rising_edge(clk);
    xin_real  <= (others => '0');
    xin_imag  <= (others => '0');
    xin_valid <= '0';

    -- test out constantly valid inputs to check consumption timing
    wait until xout_valid = '1' and rising_edge(clk);
    xin_valid <= '1';

    wait;
  end process CS_test_sample_inputs;

  CS_test_angle_inputs: process
  begin
    wait until reset = '0';
    wait until rising_edge(clk);
    -- test some arbitrary angle inputs
    phi_in      <= X"1234_5678";
    theta_in    <= X"4000_0000";
    bc_valid_in <= '1';
    wait until rising_edge(clk) and ic_ready = '1';
    phi_in      <= (others => '0');
    theta_in    <= (others => '0');
    bc_valid_in <= '0';

    -- test out constantly valid inputs to check consumption timing
    wait until xout_valid = '1' and rising_edge(clk);
    bc_valid_in <= '1';

    wait;
  end process CS_test_angle_inputs;

  CS_monitor_outputs: process
  begin
    xout_ready <= '1';
    wait until xout_valid = '1' and rising_edge(clk);
    -- NOTE: the current phi & theta output values are truncated due to issues
    --       with trying to represent an unsigned 32b integer directly in GHDL
    report "X Out: " & integer'image(to_integer(xout_real)) & " + " &
      integer'image(to_integer(xout_imag)) & "j";

    -- test out constantly valid inputs to check consumption timing
    wait for 2 us;

    -- test hold-up in downstream IC logic
    wait until rising_edge(clk);
    xout_ready <= '0';
    wait until rising_edge(clk) and xout_valid = '1';
    wait for 100 ns;
    wait until rising_edge(clk);
    xout_ready <= '1';
    wait for 2 us;

    report "SIM COMPLETE";
    sim_end <= true;
    wait;
  end process CS_monitor_outputs;

end architecture behav;
