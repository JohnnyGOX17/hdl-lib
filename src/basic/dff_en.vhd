-- File              : dff_en.vhd
-- Author            : John Gentile <johncgentile17@gmail.com>
-- Date              : 21.04.2018
-- Last Modified Date: 24.04.2018
-- Last Modified By  : John Gentile <johncgentile17@gmail.com>
--! @file
--! @brief D-type flip-flop w/synchronous enable
-------------------------------------------------------------------------------
-- Copyright (c) 2018 John Gentile <johncgentile17@gmail.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

entity DFF is
  port (
    cD  : in  std_logic; --! Data In
    cEn : in  std_logic; --! Synchronous Enable
    clk : in  std_logic; --! Clock In
    cQ  : out std_logic  --! Data Out
  );
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
