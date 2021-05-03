library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_misc.all;
library work;
  use work.util_pkg.all;

entity tb_ABF_CNN_N9x8x2 is
  generic (
    G_DATA_WIDTH   : integer := 16
  );
end entity tb_ABF_CNN_N9x8x2;

architecture behav of tb_ABF_CNN_N9x8x2 is

  signal clk            : std_logic := '0';
  signal reset          : std_logic;

  -- input from covariance matrix calculation
  signal din_valid      : std_logic;
  signal din_real       : T_signed_3D(8 downto 0)
                                     (7 downto 0)
                                     (G_DATA_WIDTH - 1 downto 0);
  signal din_imag       : T_signed_3D(8 downto 0)
                                     (7 downto 0)
                                     (G_DATA_WIDTH - 1 downto 0);

  -- output adaptive weights from CNN
  signal dout_valid     : std_logic;
  signal dout_real      : T_signed_2D(7 downto 0)
                                     (G_DATA_WIDTH - 1 downto 0);
  signal dout_imag      : T_signed_2D(7 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);

begin

  clk   <= not clk after 5.0 ns;
  reset <= '1','0' after 100 ns;

  U_DUT: entity work.ABF_CNN_N9x8x2
    generic map (
      G_DATA_WIDTH   => G_DATA_WIDTH
    )
    port map (
      clk            => clk,
      reset          => reset,
      din_valid      => din_valid,
      din_real       => din_real,
      din_imag       => din_imag,
      dout_valid     => dout_valid,
      dout_real      => dout_real,
      dout_imag      => dout_imag
    );

  CS_test_inputs: process
  begin
    -- test with unity input data
    for i in 0 to 8 loop
      for j in 0 to 7 loop
        din_real(i)(j) <= to_signed( 1, G_DATA_WIDTH );
        din_imag(i)(j) <= to_signed( 1, G_DATA_WIDTH );
      end loop;
    end loop;
    din_valid <= '0';
    wait until rising_edge(clk) and reset = '0';

    wait until rising_edge(clk);
    din_valid <= '1';
    wait until rising_edge(clk);
    din_valid <= '0';

    wait until rising_edge(clk) and dout_valid = '1';
    report "SIM COMPLETE" severity note;

    wait;
  end process CS_test_inputs;

end behav;

