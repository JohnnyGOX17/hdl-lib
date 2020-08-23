--
-- Infers a single-port RAM supporting these synchronization modes:
-- • Read-first: Old content is read before new content is loaded.
-- • Write-first: New content is immediately made available for reading Write-
--   first is also known as read-through.
-- • No-change: Data output does not change as new content is loaded into RAM.
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
  use ieee.numeric_std.all;

entity sp_ram is
  generic (
    G_DEPTH      : integer := 1024;
    G_DATA_WIDTH : integer := 16;
    G_SYNC_MODE  : string  := "READ"; -- "READ"|"WRITE" first, or "NO" change
    -- sets RAM type attribute (ex "distributed", "block", "registers" or "ultra")
    G_RAM_TYPE   : string  := "distributed"
  );
  port (
    clk          : in  std_logic;
    wr_en        : in  std_logic; -- Write enable
    en           : in  std_logic; -- Enable for overall RAM
    addr         : in  std_logic_vector(integer(ceil(log2(real(G_DEPTH))))-1 downto 0);
    din          : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
    dout         : out std_logic_vector(G_DATA_WIDTH-1 downto 0)
  );
end entity sp_ram;

architecture rtl of sp_ram is

  type T_RAM is array (G_DEPTH-1 downto 0) of std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal sig_ram : T_RAM;

  attribute ram_style : string;
  attribute ram_style of sig_ram : signal is G_RAM_TYPE;

begin

  S_ram: process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        -- generic sets synchronization mode used for RAM in synthesis
        if G_SYNC_MODE = "READ" then
          if wr_en = '1' then
            sig_ram( to_integer(unsigned(addr)) ) <= din;
          end if;
          dout <= sig_ram( to_integer(unsigned(addr)) );
        elsif G_SYNC_MODE = "WRITE" then
          if wr_en = '1' then
            sig_ram( to_integer(unsigned(addr)) ) <= din;
            dout                                  <= din;
          else
            dout <= sig_ram( to_integer(unsigned(addr)) );
          end if;
        else -- no-change mode
          if wr_en = '1' then
            sig_ram( to_integer(unsigned(addr)) ) <= din;
          else
            dout <= sig_ram( to_integer(unsigned(addr)) );
          end if;
        end if;
      end if;
    end if;
  end process S_ram;

end rtl;

--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;

entity tb_sp_ram is
end entity tb_sp_ram;

architecture behav of tb_sp_ram is


begin


end behav;
--synthesis translate_on
