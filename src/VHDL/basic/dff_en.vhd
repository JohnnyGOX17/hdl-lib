-- File              : dff_en.vhd
-- Author            : John Gentile <johncgentile17@gmail.com>
-- Date              : 21.04.2018
-- Last Modified Date: 22.04.2018
-- Last Modified By  : John Gentile <johncgentile17@gmail.com>
-- Description:
--   D-type flip-flop w/synchronous enable
--
-------------------------------------------------------------------------------
-- dff_en.vhd
-- Copyright (c) 2018 John Gentile <johncgentile17@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

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
