--
-- Static shift register (fixed depth, std_logic_vector)
--   * infers SRL-type primitive in synthesis tools
--
library ieee;
  use ieee.std_logic_1164.all;

entity static_shift_reg_vec is
  generic (
    G_DEPTH      : integer := 32;
    G_DATA_WIDTH : integer := 8
  );
  port (
    clk          : in  std_logic;
    din          : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    dvalid       : in  std_logic;
    dout         : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
  );
end entity static_shift_reg_vec;

architecture rtl of static_shift_reg_vec is

  component static_shift_reg_bit is
    generic (
      G_DEPTH : integer := 32
    );
    port (
      clk     : in  std_logic;
      din     : in  std_logic;
      dvalid  : in  std_logic;
      dout    : out std_logic
    );
  end component;

begin

  UG_parallel_SRLs: for i in 0 to G_DATA_WIDTH - 1 generate
    U_SRLx: static_shift_reg_bit
      generic map (
        G_DEPTH => G_DEPTH
      )
      port map (
        clk     => clk,
        din     => din(i),
        dvalid  => dvalid,
        dout    => dout(i)
      );
  end generate UG_parallel_SRLs;

end rtl;
