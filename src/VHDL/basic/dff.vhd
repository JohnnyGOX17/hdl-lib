--
-- Name: dff.vhd
-- Purpose: D-type flip-flop

library IEEE;
  use IEEE.std_logic_1164.all;

entity DFF is
  port ( cD, clk : in std_logic;
         cQ      : out std_logic);
end DFF;

architecture behav of DFF is
begin

  process (clk)
    if rising_edge(clk) then
      cQ <= cD;
    end if;
  end process;
end behav;
