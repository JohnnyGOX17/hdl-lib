-- File              : dff.vhd
-- Author            : John Gentile <johncgentile17@gmail.com>
-- Date              : 22.04.2018
-- Last Modified Date: 24.04.2018
-- Last Modified By  : John Gentile <johncgentile17@gmail.com>
--! @file
--! @brief Basic D-type flip-flop
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
    cD      : in  std _logic; --! Data In
    clk     : in  std _logic; --! Clock In
    cQ      : out std _logic  --! Data Out
  );
end DFF;

architecture behav of DFF is
begin

  process (clk)
    if rising_edge(clk) then
      cQ <= cD;
    end if;
  end process;
end behav;
