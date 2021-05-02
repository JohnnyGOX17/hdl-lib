-- Implements a perceptron with N-connections, and an activation function
-- For now, just use ReLU activation: max(0, x)
-- For quantizations like 16b data w/8b weights, we can simply keep the 24b product and accumulate
--   to something like a 32b/48b value (large adders are cheap nowadays) and then shift at very end
--   to keep relative precision
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity perceptron is
  generic (
    G_DATA_WIDTH   : positive := 16;
    G_WEIGHT_WIDTH : positive :=  8;
    G_NUM_CONNECT  : positive := 32; -- number of connections from previous layer
    G_WEIGHT_PATH  : string   := "../scripts/coef.txt";
    G_SIGNED       : boolean  := true -- [true = signed, false = unsigned] MAC ops
  );
  port (
    clk            : in  std_logic;
    reset          : in  std_logic; -- (optional) sync reset for *valid's

    -- only one valid required, since all nodes from previous layer need to be valid before moving here
    din_valid      : in  std_logic;
    din            : in  T_slv_2D(G_NUM_CONNECT - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    -- no handshaking/ready signaling required either, since we only do simple feed-forward operation

    dout_valid     : out std_logic;
    dout           : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
  )
end entity perceptron;

architecture rtl of perceptron is

  constant K_OUTPUT_WIDTH : natural := F_clog2(G_NUM_TAPS) + G_DATA_WIDTH + G_COEF_WIDTH;
  constant K_OUT_SRL      : natural := F_clog2(G_NUM_TAPS) + G_COEF_WIDTH;

  signal sig_coef_array : T_slv_2D := F_read_file_slv_2D( G_WEIGHT_PATH,
                                                          G_WEIGHT_WIDTH,
                                                          G_NUM_CONNECT );


begin


  S_iterate_weights_and_accumulate: process(clk)
  begin
    if rising_edge(clk) then
    end if;
  end process S_iterate_weights_and_accumulate;





  --S_scale_outputs: process(clk)
  --begin
  --  if rising_edge(clk) then
  --    if sig_dout_valid = '1' then
  --      if G_SIGNED then
  --        sig_dout_scaled <= std_logic_vector( resize( shift_right( to_signed(sig_dout),
  --                                                                  K_OUT_SRL ),
  --                                                     sig_dout_scaled'length ) );
  --      else
  --        sig_dout_scaled <= std_logic_vector( resize( shift_right( to_unsigned(sig_dout),
  --                                                                  K_OUT_SRL ),
  --                                                     sig_dout_scaled'length ) );
  --      end if;
  --    end if;

  --    sig_dout_scl_valid <= sig_dout_valid;
  --  end if;
  --end process S_scale_outputs;

end rtl;

