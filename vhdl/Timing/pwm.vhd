--
-- Pulse-Width Modulation component
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
  use ieee.numeric_std.all;

entity pwm is
  generic (
    G_MAX_PERIOD : integer := 256; -- max number of clk cycles for PWM period (sets vector sizes internal)
    G_FREQ_DIV   : integer := 16   -- divides input clk period to create slower PWM output (power of 2)
  );
  port (
    clk        : in  std_logic;
    reset      : in  std_logic;
    -- # of output clock cycles (clk/G_FREQ_DIV) for PWM period
    pwm_period : in  std_logic_vector(integer(ceil(log2(real(G_MAX_PERIOD))))-1 downto 0);
    -- # of output clock cycles the PWM output signal is high in the PWM period
    pwm_on     : in  std_logic_vector(integer(ceil(log2(real(G_MAX_PERIOD))))-1 downto 0);
    pwm_out    : out std_logic
  );
end entity pwm;

architecture rtl of pwm is

  signal sig_pwm_period   : std_logic_vector(integer(ceil(log2(real(G_MAX_PERIOD))))-1 downto 0);
  signal sig_pwm_on       : std_logic_vector(integer(ceil(log2(real(G_MAX_PERIOD))))-1 downto 0);

  signal sig_div_clk_cntr : unsigned(integer(ceil(log2(real(G_FREQ_DIV))))-1 downto 0);
  signal sig_div_clk      : std_logic;

begin

  pwm_out <= sig_div_clk;

  UG_div_clk: if G_FREQ_DIV > 1 generate
    sig_div_clk <= sig_div_clk_cntr(sig_div_clk_cntr'high);
    S_clk_div: process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          sig_div_clk_cntr <= (others => '0');
        else
          sig_div_clk_cntr <= sig_div_clk_cntr + 1;
        end if;
      end if;
    end process S_clk_div;
  end generate UG_div_clk;

  UG_pass_clk: if G_FREQ_DIV <= 1 generate
    sig_div_clk <= clk;
  end generate UG_pass_clk;

  S_reg_inputs: process(clk)
  begin
    if rising_edge(clk) then
      sig_pwm_period <= pwm_period;
      sig_pwm_on     <= pwm_on;
    end if;
  end process S_reg_inputs;

  S_pwm_fsm: process(sig_div_clk)
  begin
    if rising_edge(sig_div_clk) then
    end if;
  end process S_pwm_fsm;

end rtl;

--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;

entity tb_pwm is
end entity tb_pwm;

architecture behav of tb_pwm is

  signal clk        : std_logic := '0';
  signal reset      : std_logic;
  signal pwm_period : std_logic_vector(7 downto 0);
  signal pwm_on     : std_logic_vector(7 downto 0);
  signal pwm_out    : std_logic;

  signal sim_end : boolean := false;

begin

  U_DUT: entity work.pwm
    generic map (
      G_MAX_PERIOD => 256,
      G_FREQ_DIV   => 4
    )
    port map (
      clk        => clk,
      reset      => reset,
      pwm_period => pwm_period,
      pwm_on     => pwm_on,
      pwm_out    => pwm_out
    );

  clk   <= not clk after 2.5 ns when not sim_end else '0';
  reset <= '1','0' after 100 ns;

  CS_sim: process
  begin

    wait for 1 us;
    sim_end <= true;
    wait;
  end process;

end behav;
--synthesis translate_on
