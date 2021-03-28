--
-- Infers a single-port RAM supporting these synchronization modes:
-- • Read-first: Old content is read before new content is loaded.
-- • Write-first: New content is immediately made available for reading Write-
--   first is also known as read-through.
-- • No-change: Data output does not change as new content is loaded into RAM.
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

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
    addr         : in  std_logic_vector(F_clog2(G_DEPTH)-1 downto 0);
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
  use ieee.math_real.all;
  use ieee.numeric_std.all;
  use std.textio.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_sp_ram is
  generic (
    G_DEPTH      : integer := 256;
    G_DATA_WIDTH : integer := 16;
    runner_cfg   : string -- VUnit generic interface
  );
end entity tb_sp_ram;

architecture behav of tb_sp_ram is

  signal clk   : std_logic := '0';
  signal wr_en : std_logic := '0'; -- Write enable
  signal en    : std_logic := '1'; -- Enable for overall RAM
  signal addr  : std_logic_vector(F_clog2(G_DEPTH)-1 downto 0)
                 := (others => '0');
  signal din   : std_logic_vector(G_DATA_WIDTH-1 downto 0)
                 := (others => '0');
  signal dout  : std_logic_vector(G_DATA_WIDTH-1 downto 0);

begin

  U_DUT: entity work.sp_ram
    generic map (
      G_DEPTH      => G_DEPTH,
      G_DATA_WIDTH => G_DATA_WIDTH
    )
    port map (
      clk          => clk,
      wr_en        => wr_en,
      en           => en,
      addr         => addr,
      din          => din,
      dout         => dout
    );

  clk <= not clk after 5.0 ns;

  S_main: process
  begin
    test_runner_setup(runner, runner_cfg); -- VUnit entry call
    report "Iterating through sp_ram address space and checking read/write";
    wait until rising_edge(clk);
    wr_en <= '1';
    for i in 0 to G_DEPTH - 1 loop
      addr <= std_logic_vector( to_unsigned( i, addr'length ) );
      din  <= std_logic_vector( to_unsigned( i, din'length ) );
      wait until rising_edge(clk);
    end loop;
    wr_en <= '0';
    wait until rising_edge(clk);

    for i in 0 to G_DEPTH - 1 loop
      addr <= std_logic_vector( to_unsigned( i, addr'length ) );
      wait until rising_edge(clk); -- 2x cycle latency
      wait until rising_edge(clk);
      assert ( dout = std_logic_vector( to_unsigned( i, din'length ) ) )
        report "Data read does not match expected! " &
        "Read: 0x" & to_hstring( dout ) &
        " | Expected: 0x" & to_hstring(to_signed(i, G_DATA_WIDTH))
        severity failure;
    end loop;
    test_runner_cleanup(runner); -- VUnit exit call, sim ends here
  end process S_main;

end behav;
--synthesis translate_on
