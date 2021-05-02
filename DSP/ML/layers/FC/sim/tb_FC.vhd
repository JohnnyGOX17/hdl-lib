library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
library work;
  use work.util_pkg.all;

entity tb_FC is
  generic (
    G_DATA_WIDTH   : integer := 16;
    G_WEIGHT_WIDTH : integer :=  8;
    G_NUM_INPUTS   : integer := 50;
    G_NUM_OUTPUTS  : integer := 32;
    -- accumulator register word size
    G_ACCUM_WIDTH  : integer := 24;
    G_LAYER_IDX    : integer :=  0;
    -- base file system path to weight files for this FC layer, also uses
    -- layer index from above to match file pattern for node's weight file
    G_BASE_PATH    : string  := "/home/jgentile/src/jhu-masters-thesis/src/hdl-lib/DSP/ML/neural/sim/FC_weights_layer_"
  );
end entity tb_FC;

architecture behav of tb_FC is

  signal clk            : std_logic := '0';
  signal reset          : std_logic;
  signal din_valid      : std_logic;
  signal din            : T_signed_2D(G_NUM_INPUTS - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
  signal dout_valid     : std_logic;
  signal dout           : signed(G_DATA_WIDTH - 1 downto 0);

begin

  clk   <= not clk after 5.0 ns;
  reset <= '1','0' after 100 ns;

  U_DUT: entity work.FC
    generic map (
      G_DATA_WIDTH   => G_DATA_WIDTH,
      G_WEIGHT_WIDTH => G_WEIGHT_WIDTH,
      G_NUM_INPUTS   => G_NUM_INPUTS,
      G_NUM_OUTPUTS  => G_NUM_OUTPUTS,
      G_ACCUM_WIDTH  => G_ACCUM_WIDTH,
      G_LAYER_IDX    => G_LAYER_IDX,
      G_BASE_PATH    => G_BASE_PATH
    )
    port map (
      clk            => clk,
      reset          => reset,
      din_valid      => din_valid,
      din            => din,
      dout_valid     => dout_valid,
      dout           => dout
    );

  CS_test_inputs: process
  begin
    din_valid <= '0';
    din       <= (others => (others => '0'));
    wait until reset = '0' and rising_edge(clk);

    wait until rising_edge(clk);
    din_valid <= '1';
    for i in 0 to G_NUM_INPUTS - 1 loop
      din(i) <= to_signed( 1, G_DATA_WIDTH );
    end loop;
    wait until rising_edge(clk);
    din_valid <= '0';

    wait;
  end process CS_test_inputs;

end architecture behav;

