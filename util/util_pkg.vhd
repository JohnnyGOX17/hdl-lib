-- Package for common utilities
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  use std.textio.all;

package util_pkg is

-- // Start: Common Types /////////////////////////////////////////////////////
  type T_slv_2D is array (integer range <>) of std_logic_vector;
-- // End: Common Types ///////////////////////////////////////////////////////

-- // Start: File I/O Utilities ///////////////////////////////////////////////
  --
  function F_read_file_slv_2D( file_path  : string;
                               slv_length : integer;
                               dim_length : integer ) return T_slv_2D;
-- // End: File I/O Utilities /////////////////////////////////////////////////

-- // Start: String Utilities /////////////////////////////////////////////////
  -- Converts a String to std_logic_vector
  function F_string_to_slv( X : string ) return std_logic_vector;
-- // End: String Utilities ///////////////////////////////////////////////////

-- // Start: Number Utilities /////////////////////////////////////////////////
  function F_return_smaller( A : integer;
                             B : integer ) return integer;
  function F_return_larger( A : integer;
                            B : integer ) return integer;
-- // End: Number Utilities ///////////////////////////////////////////////////

end util_pkg;

package body util_pkg is

-- // Start: File I/O Utilities ///////////////////////////////////////////////
  function F_read_file_slv_2D( file_path  : string;
                               slv_length : integer;
                               dim_length : integer ) return T_slv_2D is
    file     fd       : text;
    variable V_line   : line;
    variable V_bitvec : bit_vector(slv_length - 1 downto 0);
    variable V_return : T_slv_2D(dim_length - 1 downto 0)(slv_length -1 downto 0)
                        := (others => (others => '0'));
  begin
    if FilePath /= "" then
      file_open( fd, file_path, read_mode );
      for i in 0 to dim_length - 1 loop
        readline( fd, V_line );
        read( V_line, V_bitvec );
        V_return(i) := to_stdlogicvector( V_bitvec );
      end loop;
    end if;
    return V_return;
  end F_read_file_slv_2D;
-- // End: File I/O Utilities /////////////////////////////////////////////////

-- // Start: String Utilities /////////////////////////////////////////////////
  function F_string_to_slv( X : string ) return std_logic_vector is
    variable V_return : std_logic_vector((X'length*8)-1 downto 0);
  begin
    for i in X'range loop
      V_return(((i+1)*8)-1 downto i*8) :=
        std_logic_vector( to_unsigned( character'pos( X(i) ), 8 ) );
    end loop;
    return V_return;
  end F_string_to_slv;
-- // End: String Utilities ///////////////////////////////////////////////////

-- // Start: Number Utilities /////////////////////////////////////////////////
  function F_return_smaller( A : integer;
                             B : integer ) return integer is
  begin
    if A < B then
      return A;
    else
      return B;
    end if;
  end F_return_smaller;

  function F_return_larger( A : integer;
                            B : integer ) return integer is
  begin
    if A > B then
      return A;
    else
      return B;
    end if;
  end F_return_larger;
-- // End: Number Utilities ///////////////////////////////////////////////////

end util_pkg;

