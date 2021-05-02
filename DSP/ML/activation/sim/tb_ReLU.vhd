library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_ReLU is
  generic (
    G_DATA_WIDTH : integer := 16
  );
end entity tb_ReLU;

architecture behav of tb_ReLU is

  signal clk          : std_logic := '0';
  signal din_valid    : std_logic;
  signal din          : signed(G_DATA_WIDTH - 1 downto 0);
  signal dout_valid   : std_logic;
  signal dout         : signed(G_DATA_WIDTH - 1 downto 0);

begin

  clk <= not clk after 5.0 ns;

  U_DUT: entity work.ReLU
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      din_valid    => din_valid,
      din          => din,
      dout_valid   => dout_valid,
      dout         => dout
    );

  CS_test_inputs: process
  begin
    din_valid <= '0';
    din       <= to_signed(0, G_DATA_WIDTH);
    wait until rising_edge(clk);
    din_valid <= '1';
    din       <= to_signed(10, G_DATA_WIDTH);
    wait until rising_edge(clk);
    din       <= to_signed(-3, G_DATA_WIDTH);
    wait until rising_edge(clk);
    din       <= to_signed(-17, G_DATA_WIDTH);
    wait until rising_edge(clk);
    din       <= to_signed(128, G_DATA_WIDTH);
    wait until rising_edge(clk);
    din_valid <= '0';

    report "SIM END";
    wait;
  end process CS_test_inputs;

end behav;
