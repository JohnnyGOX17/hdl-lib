use work.pkg_c.all;

entity tb_ext_add is
end entity;

architecture behav of tb_ext_add is

  signal num1   : integer := 0;
  signal num2   : integer := 0;
  signal result : integer := 0;

begin

  result <= ext_add( num1, num2 );

  main: process
  begin
    num1 <= 1;
    num2 <= 2;
    wait for 100 ns;
    num1 <= 5;
    num2 <= 7;
    wait for 100 ns;
    num1 <= 123;
    num2 <= 123;
    wait;
  end process;

  result_p: process
  begin
    wait until result'event;
    report "The result is " & integer'image(result);
  end process;

end architecture behav;
