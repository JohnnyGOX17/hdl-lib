-- Hex value to 7-segment display combinatorial decoder w/pinout:
--      0
--     ---
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3
--
library ieee;
  use ieee.std_logic_1164.all;

entity seven_seg_disp is
  port (
    hex_val : in  std_logic_vector(3 downto 0);
    LED     : out std_logic_vector(6 downto 0)
  );
end entity seven_seg_disp;

architecture rtl of seven_seg_disp is
begin

  with hex_val select
    LED <= "1111001" when X"1",
           "0100100" when X"2",
           "0110000" when X"3",
           "0011001" when X"4",
           "0010010" when X"5",
           "0000010" when X"6",
           "1111000" when X"7",
           "0000000" when X"8",
           "0010000" when X"9",
           "0001000" when X"A",
           "0000011" when X"B",
           "1000110" when X"C",
           "0100001" when X"D",
           "0000110" when X"E",
           "0001110" when X"F",
           "1000000" when others; -- 0

end architecture rtl;
