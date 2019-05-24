library IEEE;
  use IEEE.std_logic_1164.all;

--  A testbench has no ports.
entity tb_adder is
end entity tb_adder;

architecture behav of tb_adder is

  component adder is
    port (
      i0 : in  std_logic;
      i1 : in  std_logic;
      ci : in  std_logic;
      s  : out std_logic;
      co : out std_logic
    );
  end Component;

  signal i0 : std_logic;
  signal i1 : std_logic;
  signal ci : std_logic;
  signal s  : std_logic;
  signal co : std_logic;

begin
  --  Component instantiation.
  U_DUT : adder
    port map (
      i0 => i0,
      i1 => i1,
      ci => ci,
      s  => s,
      co => co
    );

  --  This process does the real job.
  process
    type pattern_type is record
      --  The inputs of the adder.
      i0, i1, ci : std_logic;
      --  The expected outputs of the adder.
      s, co : std_logic;
    end record;
    --  The patterns to apply.
    type pattern_array is array (natural range <>) of pattern_type;
    constant patterns : pattern_array :=
    (('0', '0', '0', '0', '0'),
    ('0', '0', '1', '1', '0'),
    ('0', '1', '0', '1', '0'),
    ('0', '1', '1', '0', '1'),
    ('1', '0', '0', '1', '0'),
    ('1', '0', '1', '0', '1'),
    ('1', '1', '0', '0', '1'),
    ('1', '1', '1', '1', '1'));
  begin
    --  Check each pattern.
    for i in patterns'range loop
      --  Set the inputs.
      i0 <= patterns(i).i0;
      i1 <= patterns(i).i1;
      ci <= patterns(i).ci;
      --  Wait for the results.
      wait for 1 ns;
      --  Check the outputs.
      assert s = patterns(i).s
        report "bad sum value" severity error;
      assert co = patterns(i).co
        report "bad carry out value" severity error;
    end loop;
    assert false report "end of test" severity note;
    --  Wait forever; this will finish the simulation.
    wait;
  end process;
end behav;
