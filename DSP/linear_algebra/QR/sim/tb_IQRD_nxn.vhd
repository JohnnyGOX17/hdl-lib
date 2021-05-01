library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity tb_IQRD_nxn is
end entity tb_IQRD_nxn;

architecture behav of tb_IQRD_nxn is

  constant G_DATA_WIDTH : natural  := 16;
  constant G_USE_LAMBDA : boolean  := false; -- use forgetting factor (lambda) in BC calc
  constant G_M          : positive := 16;
  constant G_N          : positive := 16;

  signal clk          : std_logic := '0';
  signal reset        : std_logic;
  -- default is CORDIC scaling for 16 iterations
  signal CORDIC_scale : signed(G_DATA_WIDTH - 1 downto 0) := X"4DBA";
  -- default is lambda = 0.99
  signal lambda       : signed(G_DATA_WIDTH - 1 downto 0) := X"7EB8"; -- 0.99
  signal inv_lambda   : signed(G_DATA_WIDTH - 1 downto 0) := X"814A"; -- 1.01

  signal A_real       : T_signed_3D(G_M - 1 downto 0)
                                   (G_N - 1 downto 0)
                                   (G_DATA_WIDTH - 1 downto 0);
  signal A_imag       : T_signed_3D(G_M - 1 downto 0)
                                   (G_N - 1 downto 0)
                                   (G_DATA_WIDTH - 1 downto 0);
  signal A_valid      : std_logic;
  signal A_ready      : std_logic;

  signal b_real       : T_signed_2D(G_M - 1 downto 0)
                                   (G_DATA_WIDTH - 1 downto 0);
  signal b_imag       : T_signed_2D(G_M - 1 downto 0)
                                   (G_DATA_WIDTH - 1 downto 0);
  signal b_valid      : std_logic;
  signal b_ready      : std_logic;

  signal x_real       : T_signed_2D(G_N - 1 downto 0)
                                   (G_DATA_WIDTH - 1 downto 0);
  signal x_imag       : T_signed_2D(G_N - 1 downto 0)
                                   (G_DATA_WIDTH - 1 downto 0);
  signal x_valid      : std_logic;
  signal x_ready      : std_logic;

  signal sim_end      : boolean := false;

begin

  -- test nxn matrix inversion (mainly performance in test testbench rather than numerical accuracy)
  U_DUT: entity work.IQRD
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_USE_LAMBDA => G_USE_LAMBDA,
      G_M          => G_M,
      G_N          => G_N
    )
    port map (
      clk          => clk,
      reset        => reset,
      CORDIC_scale => CORDIC_scale,
      lambda       => lambda,
      inv_lambda   => inv_lambda,
      A_real       => A_real,
      A_imag       => A_imag,
      A_valid      => A_valid,
      A_ready      => A_ready,
      b_real       => b_real,
      b_imag       => b_imag,
      b_valid      => b_valid,
      b_ready      => b_ready,
      x_real       => x_real,
      x_imag       => x_imag,
      x_valid      => x_valid,
      x_ready      => x_ready
    );

  clk   <= not clk after 5.0 ns when not sim_end else '0';
  reset <= '1','0' after 100 ns;

  CS_test_inputs: process
  begin
    for k_idx in 0 to G_M - 1 loop
      for ch_idx in 0 to G_N - 1 loop
        A_real(k_idx)(ch_idx) <= to_signed( ch_idx*k_idx, G_DATA_WIDTH );
        A_imag(k_idx)(ch_idx) <= to_signed(      -ch_idx, G_DATA_WIDTH );
      end loop;
      b_real(k_idx) <= to_signed( 8192, G_DATA_WIDTH);
      b_imag(k_idx) <= to_signed(    0, G_DATA_WIDTH);
    end loop;

    -- stay ready for x output for now
    x_ready <= '1';
    A_valid <= '0';
    b_valid <= '0';

    wait until reset = '0';
    wait until rising_edge(clk);

    -- valid input data
    wait until rising_edge(clk);
    A_valid <= '1';
    b_valid <= '1';
    wait until rising_edge(clk) and (A_ready = '1') and (b_ready = '1');
    A_valid <= '0';
    b_valid <= '0';
    -- Zero-out input data
    for i in 0 to G_M - 1 loop
      b_real(i) <= (others => '0');
      b_imag(i) <= (others => '0');
      for j in 0 to G_N - 1 loop
        A_real(i)(j) <= (others => '0');
        A_imag(i)(j) <= (others => '0');
      end loop;
    end loop;

    -- wait for x vector output
    wait until rising_edge(clk) and (x_valid = '1');
    for i in 0 to G_N - 1 loop
      report "x(" & integer'image(i) & "): " & integer'image(to_integer(x_real(i))) &
        " + " & integer'image(to_integer(x_imag(i))) & "j";
    end loop;

    wait for 100 ns;
    sim_end <= true;
    wait;
  end process CS_test_inputs;

end architecture behav;
