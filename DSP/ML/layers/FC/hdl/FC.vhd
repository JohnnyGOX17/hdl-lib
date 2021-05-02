-- Implements a Fully-Connected (Dense) layer of perceptrons and activations
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
library work;
  use work.util_pkg.all;

entity FC is
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
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;

    -- only one valid required, since all nodes from previous layer need to be valid before moving here
    din_valid      : in  std_logic;
    din            : in  T_signed_2D(G_NUM_INPUTS - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    -- no handshaking/ready signaling required either, since we only do simple feed-forward operation
    dout_valid     : out std_logic;
    dout           : out signed(G_DATA_WIDTH - 1 downto 0)
  );
end entity FC;

architecture rtl of FC is
begin

  UG_gen_nodes: for i in 0 to G_NUM_OUTPUTS - 1 generate
    U_percep_x: entity work.perceptron
      generic map (
        G_DATA_WIDTH   => G_DATA_WIDTH,
        G_WEIGHT_WIDTH => G_WEIGHT_WIDTH,
        -- number of connections from previous layer (== # of weights)
        G_NUM_CONNECT  => G_NUM_INPUTS,
        -- accumulator register word size
        G_ACCUM_WIDTH  => G_ACCUM_WIDTH,
        -- build path to each weight file here
        G_WEIGHT_PATH  => G_BASE_PATH &
                          integer'image(G_LAYER_IDX) &
                          "_node_" &
                          integer'image(i) &
                          ".txt"
      )
      port map (
        clk            => clk,
        reset          => reset,
        din_valid      => din_valid,
        din            => din,
        dout_valid     => open, -- #TODO
        dout           => open
      );
  end generate UG_gen_nodes;

end rtl;
