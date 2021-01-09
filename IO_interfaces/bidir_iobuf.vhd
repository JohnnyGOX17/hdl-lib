-- Diagram from Xilinx Vivado Language Templates:
--
--                           |---------- O
--                           |
--                           |
--    ________________       |
--   /       IO       \______|
--   \________________/      |
--                           |
--                           |     /|
--                           |____/ |______ I
--                                \ |
--                                |\|
--                                |
--                                |--- T
-- Infers IOBUF in Xilnix devices for Open Drain I/O usage
--
library ieee;
  use ieee.std_logic_1164.all;

entity bidir_iobuf is
  port (
    T  : in    std_logic; -- assert to tristate IO line (!Output Enable)
    I  : in    std_logic; -- logic value to push when not tristated
    O  : out   std_logic; -- logic value read on IO line
    IO : inout std_logic  -- IO line connected to top-level port
  );
end entity bidir_iobuf;

architecture rtl of bidir_iobuf is
begin

  IO <= I when T = '0' else 'Z';
  O  <= IO;

end architecture rtl;
