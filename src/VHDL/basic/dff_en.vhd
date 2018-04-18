--
-- Name: dff.vhd
-- Purpose: D-type flip-flop w/synchronous enable

library IEEE;
  use IEEE.std_logic_1164.all;

entity DFF is
  port ( cD, cEn, clk : in std_logic;
         cQ           : out std_logic);
end DFF;

architecture behav of DFF is
begin

  process (clk)
    if rising_edge(clk) then
      if (cEn = '1') then
        cQ <= cD;
      else
        cQ <='Z';
    end if;
  end process;
end behav;
