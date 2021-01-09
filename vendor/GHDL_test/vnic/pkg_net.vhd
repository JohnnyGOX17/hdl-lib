
package pkg_net is

  type array_type is array(integer range 0 to 65535) of integer;
  type array_p is access array_type;

  impure function F_get_p_rx return array_p;
    attribute foreign of F_get_p_rx : function is "VHPIDIRECT F_get_p_rx";

  impure function F_get_p_tx return array_p;
    attribute foreign of F_get_p_tx : function is "VHPIDIRECT F_get_p_tx";

  function F_send_pkt( tx_length : integer ) return integer;
    attribute foreign of F_send_pkt : function is "VHPIDIRECT F_send_pkt";

  function F_receive_pkt return integer;
    attribute foreign of F_receive_pkt : function is "VHPIDIRECT F_receive_pkt";

  shared variable p_rx_buff : array_p := F_get_p_rx;
  shared variable p_tx_buff : array_p := F_get_p_tx;

end pkg_net;

package body pkg_net is

  -- function body doesn't need anything in it
  impure function F_get_p_rx return array_p is
  begin
    assert false report "VHPI" severity failure;
  end function;

  impure function F_get_p_tx return array_p is
  begin
    assert false report "VHPI" severity failure;
  end function;

  function F_send_pkt( tx_length : integer ) return integer is
  begin
    assert false report "VHPI" severity failure;
  end function;

  function F_receive_pkt return integer is
  begin
    assert false report "VHPI" severity failure;
  end function;

end pkg_net;
