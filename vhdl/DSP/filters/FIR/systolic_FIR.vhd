library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity systolic_FIR is
  generic (
    G_DATA_WIDTH : integer := 16;
    G_NUM_TAPS   : integer :=  4;
    G_COEF_PATH  : string  := "";
    G_COEF_WIDTH : integer := 16
  );
  port (
    clk          : in  std_logic;
    din          : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    dout         : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
  )
end entity systolic_FIR;

architecture rtl of systolic_FIR is

  signal sig_coef_array : T_slv_2D := F_read_file_slv_2D( G_COEF_PATH,
                                                          G_COEF_WIDTH,
                                                          G_NUM_TAPS );

begin

end rtl;

