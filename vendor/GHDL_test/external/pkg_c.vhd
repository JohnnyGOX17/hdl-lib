
package pkg_c is

  type array_type is array(integer range 0 to 100) of integer;
  type array_p is access array_type;

  impure function get_p return array_p;
    attribute foreign of get_p : function is "VHPIDIRECT get_p";

  function ext_add ( num1 : integer; num2 : integer ) return integer;
    attribute foreign of ext_add : function is "VHPIDIRECT ext_add";

  function hello_world return string;
    attribute foreign of hello_world : function is "VHPIDIRECT hello_world";

  shared variable arr: array_p := get_p;

end pkg_c;

package body pkg_c is

  -- function body doesn't need anything in it
  impure function get_p return array_p is
  begin
    assert false report "VHPI" severity failure;
  end function;

  function ext_add ( num1 : integer; num2 : integer ) return integer is
  begin
    assert false report "VHPI" severity failure;
  end function;

  function hello_world return string is
  begin
    assert false report "VHPI" severity failure;
  end function;

end pkg_c;
