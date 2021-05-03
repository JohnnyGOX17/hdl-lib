-- Package for common utilities
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  use std.textio.all;

package util_pkg is

-- // Start: Common Types /////////////////////////////////////////////////////
  -- VHDL-2008 unbounded array definitions
  type T_slv_2D      is array (integer range <>) of std_logic_vector;
  type T_signed_2D   is array (integer range <>) of signed;
  type T_unsigned_2D is array (integer range <>) of unsigned;
  type T_int_2D      is array (integer range <>) of integer;
  type T_slv_3D      is array (integer range <>) of T_slv_2D;
  type T_signed_3D   is array (integer range <>) of T_signed_2D;
  type T_unsigned_3D is array (integer range <>) of T_unsigned_2D;
  type T_int_3D      is array (integer range <>) of T_int_2D;
-- // End: Common Types ///////////////////////////////////////////////////////

-- // Start: File I/O Utilities ///////////////////////////////////////////////
  impure function F_read_file_slv_2D( file_path  : string;
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

  function   F_clog2( x : real )    return integer;
  function   F_clog2( x : natural ) return integer;
  function F_is_even( x : integer ) return boolean;
  function  F_is_odd( x : integer ) return boolean;

  function F_FFS_bit( x : std_logic_vector ) return integer;
  function F_FFS_bit( x : signed ) return integer;
  function F_FFS_bit( x : unsigned ) return integer;
-- // End: Number Utilities ///////////////////////////////////////////////////

end util_pkg;

package body util_pkg is

-- // Start: File I/O Utilities ///////////////////////////////////////////////
  -- Reads an ASCII file with bit-vector patterns on each line where:
  --   + each line has a single binary value of length `slv_length`
  --   + reads up to `dim_length` lines of file
  -- e.x. a file with values `0`, `1`, and `7` is:
  --      00000000
  --      00000001
  --      00000111
  impure function F_read_file_slv_2D( file_path  : string;
                                      slv_length : integer;
                                      dim_length : integer ) return T_slv_2D is
    file     fd       : text;
    variable V_line   : line;
    variable V_bitvec : bit_vector(slv_length - 1 downto 0);
    variable V_return : T_slv_2D(dim_length - 1 downto 0)(slv_length - 1 downto 0)
                        := (others => (others => '0'));
  begin
    if file_path /= "" then
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

  function F_clog2( x : real ) return integer is
  begin
    return integer(ceil(log2(x)));
  end F_clog2;

  function F_clog2( x : natural ) return integer is
  begin
    return F_clog2(real(x));
  end F_clog2;

  function F_is_even( x : integer ) return boolean is
  begin
    return (x mod 2) = 0;
  end F_is_even;

  function F_is_odd( x : integer ) return boolean is
  begin
    return (x mod 2) = 1;
  end F_is_odd;

  -- Find First Set bit: returns the first set bit, respecting
  --   given SLV range direction (e.g. if x(2 downto 0) := "011",
  --   F_FFS_bit(x) would return index '1', however if defined as
  --   x(0 to 2) := "011", F_FFS_bit(x) returns index '0')
  function F_FFS_bit( x : std_logic_vector ) return integer is
  begin
    for i in x'range loop
      if x(i) = '1' then
        return i;
      end if;
    end loop;
    -- set bit not found (all 0's), return left-most index since this
    -- function is often used to decide how much to shift
    return x'left;
  end F_FFS_bit;

  function F_FFS_bit( x : signed ) return integer is
  begin
    return F_FFS_bit( std_logic_vector( x ) );
  end F_FFS_bit;

  function F_FFS_bit( x : unsigned ) return integer is
  begin
    return F_FFS_bit( std_logic_vector( x ) );
  end F_FFS_bit;
-- // End: Number Utilities ///////////////////////////////////////////////////

end util_pkg;

