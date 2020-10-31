--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_complex_multiply is
end tb_complex_multiply;

architecture behav of tb_complex_multiply is

  signal clk : std_logic := '0';
  signal ar  : std_logic_vector(15 downto 0) := (others => '0'); -- 1st input's real part
  signal ai  : std_logic_vector(15 downto 0) := (others => '0'); -- 1st input's imaginary part
  signal br  : std_logic_vector(15 downto 0) := (others => '0'); -- 2nd input's real part
  signal bi  : std_logic_vector(15 downto 0) := (others => '0'); -- 2nd input's imaginary part

  signal pr_3      : std_logic_vector(32 downto 0); -- real part of output
  signal pi_3      : std_logic_vector(32 downto 0); -- imaginary part of output
  signal pr_4      : std_logic_vector(32 downto 0); -- real part of output
  signal pi_4      : std_logic_vector(32 downto 0); -- imaginary part of output
  signal ab_valid  : std_logic := '0'; -- A & B complex input data valid
  signal p_valid_3 : std_logic; -- A & B complex input data valid
  signal p_valid_4 : std_logic; -- A & B complex input data valid

  signal sim_end : boolean := false;

begin

  U_DUT_3: entity work.complex_multiply_mult3
    generic map (
      G_AWIDTH => 16, -- size of 1st input of multiplier
      G_BWIDTH => 16  -- size of 2nd input of multiplier
    )
    port map (
      clk      => clk,
      ab_valid => ab_valid,
      ar       => ar,
      ai       => ai,
      br       => br,
      bi       => bi,
      p_valid  => p_valid_3,
      pr       => pr_3,
      pi       => pi_3
    );

  U_DUT_4: entity work.complex_multiply_mult4
    generic map (
      G_AWIDTH => 16, -- size of 1st input of multiplier
      G_BWIDTH => 16  -- size of 2nd input of multiplier
    )
    port map (
      clk      => clk,
      ab_valid => ab_valid,
      ar       => ar,
      ai       => ai,
      br       => br,
      bi       => bi,
      p_valid  => p_valid_4,
      pr       => pr_4,
      pi       => pi_4
    );


  clk  <= not clk after 5.0 ns when not sim_end else '0';

  sim_inputs: process
  begin
    wait for 100 ns;
    wait until rising_edge(clk);
    ab_valid <= '1';
    ar       <= std_logic_vector( to_signed( -32, 16) );
    ai       <= std_logic_vector( to_signed(   5, 16) );
    br       <= std_logic_vector( to_signed(  43, 16) );
    bi       <= std_logic_vector( to_signed(  -8, 16) );
    wait until rising_edge(clk);
    ab_valid <= '0';

    wait for 200 ns;
    sim_end <= true;
    wait;
  end process;

end architecture behav;

--synthesis translate_on
