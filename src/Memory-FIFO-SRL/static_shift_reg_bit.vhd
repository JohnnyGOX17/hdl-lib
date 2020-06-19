--
-- Static shift register (fixed depth, single bit)
--   * infers SRL-type primitive in synthesis tools
--
library ieee;
  use ieee.std_logic_1164.all;

entity static_shift_reg_bit is
  generic (
    G_DEPTH : integer := 32
  );
  port (
    clk     : in  std_logic;
    din     : in  std_logic;
    dvalid  : in  std_logic;
    dout    : out std_logic
  );
end entity static_shift_reg_bit;

architecture rtl of static_shift_reg_bit is

  signal sig_shift_reg : std_logic_vector(G_DEPTH - 1 downto 0);

begin

  dout <= sig_shift_reg(G_DEPTH - 1);

  S_concat_input: process(clk)
  begin
    if rising_edge(clk) then
      if dvalid = '1' then
        sig_shift_reg <= sig_shift_reg(G_DEPTH - 2 downto 0) & din;
      end if;
    end if;
  end process S_concat_input;

end rtl;

--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;

entity tb_static_shift_reg_bit is
end entity tb_static_shift_reg_bit;

architecture behav of tb_static_shift_reg_bit is

  signal clk    : std_logic := '0';
  signal din    : std_logic;
  signal dvalid : std_logic;
  signal dout   : std_logic;

  signal sim_end : boolean := false;

begin

  U_DUT: entity work.static_shift_reg_bit
    generic map (
      G_DEPTH => 32
    )
    port map (
      clk     => clk,
      din     => din,
      dvalid  => dvalid,
      dout    => dout
    );

  clk <= not clk after 5.0 ns when not sim_end else '0';

  CS_sim: process
  begin
    for i in 0 to 63 loop
      wait until rising_edge(clk);
      din    <= '1';
      dvalid <= '1';
      wait until rising_edge(clk);
      dvalid <= '0';
      wait until rising_edge(clk);
      din    <= '0';
      dvalid <= '1';
      wait until rising_edge(clk);
      din    <= '1';
      dvalid <= '0';
      wait until rising_edge(clk);
      din    <= '0';
      dvalid <= '0';
    end loop;

    wait for 1 us;
    sim_end <= true;
    wait;
  end process;

end behav;
--synthesis translate_on
