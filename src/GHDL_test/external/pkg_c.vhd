
package pkg_c is

  function ext_add ( num1 : integer; num2 : integer ) return integer;
    attribute foreign of ext_add : function is "VHPIDIRECT ext_add";

end pkg_c;

package body pkg_c is

  -- function body need not function
  function ext_add ( num1 : integer; num2 : integer ) return integer is
  begin
    assert false report "VHPI" severity failure;
  end function;

end pkg_c;
