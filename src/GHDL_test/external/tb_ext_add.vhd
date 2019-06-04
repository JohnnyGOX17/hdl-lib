library ieee;
  use ieee.std_logic_1164.all;

  use work.pkg_c.all;

entity tb_ext_add is
end entity;

architecture behav of tb_ext_add is

  signal num1   : integer := 0;
  signal num2   : integer := 0;
  signal result : integer := 0;

  signal clk       : std_logic := '0';
  signal test_done : std_logic := '0';

begin

  -- no clk used here, but shows how to have GHDL auto-exit when test is done
  -- (otherwise, tb would keep running as clk keeps transitioning)
  clk <= not clk after 5 ns when test_done = '0' else '0';

  result <= ext_add( num1, num2 );

  main: process
  begin
    -- test adder external
    num1 <= 1;
    num2 <= 2;
    wait for 100 ns;
    num1 <= 5;
    num2 <= 7;
    wait for 100 ns;
    num1 <= 123;
    num2 <= 123;
    wait for 100 ns;

    -- test external pointer usage
    for i in 0 to 4 loop
      report "external memory[" & integer'image(i) & "]: " & integer'image(arr(i));
    end loop;
    report "Value of external memory[" & integer'image(0) & "] is " & integer'image(arr(0)) & ", changing to 69";
    arr(0) := 69;
    report "external memory[" & integer'image(0) & "]: " & integer'image(arr(0));
    test_done <= '1';
    wait;
  end process;

  result_p: process
  begin
    wait until result'event;
    report integer'image(num1) & " + " & integer'image(num2) & " = " & integer'image(result);
  end process;

end architecture behav;
