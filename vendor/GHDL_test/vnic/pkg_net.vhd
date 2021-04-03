-- declares functions for external (VHPI) usage by C application
package pkg_net is

  -- declare 64k array type for buffer usage in tb, though memory will really
  -- be allocated in external C app
  type array_type is array(integer range 0 to 65535) of integer;
  type array_p is access array_type;

  -- attributes used to mark functions as externally defined in external C app
  impure function F_get_p_rx return array_p;
    attribute foreign of F_get_p_rx : function is "VHPIDIRECT F_get_p_rx";

  impure function F_get_p_tx return array_p;
    attribute foreign of F_get_p_tx : function is "VHPIDIRECT F_get_p_tx";

  function F_send_pkt( tx_length : integer ) return integer;
    attribute foreign of F_send_pkt : function is "VHPIDIRECT F_send_pkt";

  function F_receive_pkt return integer;
    attribute foreign of F_receive_pkt : function is "VHPIDIRECT F_receive_pkt";

  -- before entering GHDL tb processes, the external C app will have allocated
  -- these RX & TX buffers, so here we are getting the pointers for each to use
  -- within the testbench environment.
  shared variable p_rx_buff : array_p := F_get_p_rx;
  shared variable p_tx_buff : array_p := F_get_p_tx;

end pkg_net;

package body pkg_net is

  -- function bodies don't need anything but "VHPI" declaration
  -- function definitions are in main.c so that they can act on C data/code

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
