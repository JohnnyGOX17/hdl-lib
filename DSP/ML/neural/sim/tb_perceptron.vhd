library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity tb_perceptron is
  generic (
    G_DATA_WIDTH   : integer := 16;
    G_WEIGHT_WIDTH : integer :=  8;
    -- number of connections from previous layer (== # of weights)
    G_NUM_CONNECT  : integer := 32;
    -- accumulator register word size
    G_ACCUM_WIDTH  : integer := 24;
    G_WEIGHT_PATH  : string   := "/home/jgentile/src/jhu-masters-thesis/src/hdl-lib/DSP/ML/neural/sim/FC_weights_layer_0_node_0.txt"
  );
end entity tb_perceptron;

architecture behav of tb_perceptron is


  signal clk        : std_logic := '0';
  signal reset      : std_logic;
  signal din_valid  : std_logic := '0';
  signal din        : T_signed_2D(G_NUM_CONNECT - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
  signal dout_valid : std_logic;
  signal dout       : signed(G_DATA_WIDTH - 1 downto 0);

begin

  clk   <= not clk after 5.0 ns;
  reset <= '1','0' after 100 ns;

  U_DUT: entity work.perceptron
    generic map (
      G_DATA_WIDTH   => G_DATA_WIDTH,
      G_WEIGHT_WIDTH => G_WEIGHT_WIDTH,
      G_NUM_CONNECT  => G_NUM_CONNECT,
      G_ACCUM_WIDTH  => G_ACCUM_WIDTH,
      G_WEIGHT_PATH  => G_WEIGHT_PATH
    )
    port map (
      clk            => clk,
      reset          => reset,
      din_valid      => din_valid,
      din            => din,
      dout_valid     => dout_valid,
      dout           => dout
    );

  CS_test_unity_inputs: process
  begin
    din <= (others => (others => '0'));
    wait until reset = '0' and rising_edge(clk);
    wait until rising_edge(clk);

    for i in 0 to G_NUM_CONNECT - 1 loop
      din(i) <= to_signed( 1, G_DATA_WIDTH);
    end loop;
    din_valid <= '1';
    wait until rising_edge(clk);
    -- din values are held, just like in previous FC layers
    din_valid <= '0';

    wait until rising_edge(clk) and dout_valid = '1';
    report "Output value of perceptron: " & integer'image(to_integer(dout));

    report "END OF SIM";
    wait;
  end process;

end behav;

