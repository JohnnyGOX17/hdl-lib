-- Package for common utilities
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package util_pkg is
  -- Converts a String to std_logic_vector
  function F_string_to_slv( X : string ) return std_logic_vector;
end util_pkg;

package body util_pkg is

  function F_string_to_slv( X : string ) return std_logic_vector is
    variable V_return : std_logic_vector((X'length*8)-1 downto 0);
  begin
    for i in X'range loop
      V_return(((i+1)*8)-1 downto i*8) :=
        std_logic_vector( to_unsigned( character'pos( X(i) ), 8 ) );
    end loop;
    return V_return;
  end F_string_to_slv;

end util_pkg;
