-- Pipelined ReLU activation: max(0, x)
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity ReLU is
  generic (
    G_DATA_WIDTH : integer := 16
  );
  port (
    clk          : in  std_logic;
    din_valid    : in  std_logic;
    din          : in  signed(G_DATA_WIDTH - 1 downto 0);
    dout_valid   : out std_logic;
    dout         : out signed(G_DATA_WIDTH - 1 downto 0)
  );
end entity ReLU;

architecture rtl of ReLU is

  signal sig_dout   : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_dvalid : std_logic := '0';

begin

  dout_valid <= sig_dvalid;
  dout       <= sig_dout;

  S_relu: process(clk)
  begin
    if rising_edge(clk) then
      if din > 0 then
        sig_dout <= din;
      else
        sig_dout <= (others => '0');
      end if;
      sig_dvalid <= din_valid;
    end if;
  end process S_relu;

end architecture rtl;
