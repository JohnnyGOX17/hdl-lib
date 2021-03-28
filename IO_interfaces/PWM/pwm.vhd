--
-- Pulse-Width Modulation component
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity pwm is
  generic (
    G_MAX_PERIOD : integer := 256; -- max number of clk cycles for PWM period (sets vector sizes internal)
    G_FREQ_DIV   : integer := 16   -- divides input clk period to create slower PWM output (power of 2)
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic; -- sync reset
    -- # of output clock cycles (clk/G_FREQ_DIV) for PWM period
    pwm_period   : in  std_logic_vector(F_clog2(G_MAX_PERIOD) - 1 downto 0);
    -- # of output clock cycles the PWM output signal is high in the PWM period
    pwm_on       : in  std_logic_vector(F_clog2(G_MAX_PERIOD) - 1 downto 0);
    pwm_load     : in  std_logic; -- captures pwm_period & pwm_on when high
    pwm_out      : out std_logic
  );
end entity pwm;

architecture rtl of pwm is

  type T_pwm_state is (S_PWM_ON, S_PWM_OFF);
  signal sig_pwm_state    : T_pwm_state := S_PWM_ON;

  signal sig_pwm_period   : unsigned(F_clog2(G_MAX_PERIOD)-1 downto 0) := (others => '0');
  signal sig_pwm_on       : unsigned(F_clog2(G_MAX_PERIOD)-1 downto 0) := (others => '0');
  signal sig_pwm_cntr     : unsigned(F_clog2(G_MAX_PERIOD)-1 downto 0) := (others => '0');

  signal sig_div_clk_cntr : unsigned(F_clog2(G_FREQ_DIV)-1 downto 0)   := (others => '0');
  signal sig_div_clk      : std_logic;

begin

  -- also gate PWM output when PWM_ON is 0 (b/c it will be stuck in ON state but should be low)
  pwm_out <= '1' when (sig_pwm_state = S_PWM_ON) and (sig_pwm_on > 0) else '0';

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
      if pwm_load = '1' then
        sig_pwm_period <= unsigned( pwm_period );
        sig_pwm_on     <= unsigned( pwm_on );
      end if;
    end if;
  end process S_reg_inputs;

  S_pwm_fsm: process(sig_div_clk)
  begin
    if rising_edge(sig_div_clk) then
      if reset = '1' then
        sig_pwm_cntr  <= (others => '0');
        sig_pwm_state <= S_PWM_ON;
      else
        -- count is checked against value - 1 since starting from 0
        case sig_pwm_state is
          when S_PWM_ON =>
            sig_pwm_cntr <= sig_pwm_cntr + 1;
            if sig_pwm_cntr >= (sig_pwm_period - 1) then
              -- case where desired PWM duty cycle is >= PWM period
              sig_pwm_cntr  <= (others => '0');
            elsif sig_pwm_cntr >= (sig_pwm_on - 1) then
              sig_pwm_state <= S_PWM_OFF;
            end if;

          when S_PWM_OFF =>
            if sig_pwm_cntr >= (sig_pwm_period - 1) then
              sig_pwm_cntr  <= (others => '0');
              sig_pwm_state <= S_PWM_ON;
            else
              sig_pwm_cntr  <= sig_pwm_cntr + 1;
            end if;

          when others => sig_pwm_state <= S_PWM_ON;
        end case;
      end if;
    end if;
  end process S_pwm_fsm;

end rtl;

--synthesis translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
  use ieee.numeric_std.all;

entity tb_pwm is
end entity tb_pwm;

architecture behav of tb_pwm is

  signal clk        : std_logic := '0';
  signal reset      : std_logic := '0';
  signal pwm_period : std_logic_vector(7 downto 0) := (others => '0');
  signal pwm_on     : std_logic_vector(7 downto 0) := (others => '0');
  signal pwm_load   : std_logic := '0';
  signal pwm_out    : std_logic;

  signal sim_end    : boolean := false;

begin

  U_DUT: entity work.pwm
    generic map (
      G_MAX_PERIOD => 256,
      G_FREQ_DIV   => 4
    )
    port map (
      clk          => clk,
      reset        => reset,
      pwm_period   => pwm_period,
      pwm_on       => pwm_on,
      pwm_load     => pwm_load,
      pwm_out      => pwm_out
    );

  clk   <= not clk after 2.5 ns when not sim_end else '0';
  reset <= '1','0' after 100 ns;

  CS_load_params: process
  begin
    wait until reset = '0';
    wait until rising_edge(clk);

    pwm_period <= std_logic_vector( to_unsigned( 16, pwm_period'length ) );
    pwm_on     <= std_logic_vector( to_unsigned(  1, pwm_on'length ) );
    pwm_load   <= '1';
    wait until rising_edge(clk);
    pwm_period <= (others => '0');
    pwm_on     <= (others => '0');
    pwm_load   <= '0';

    wait for 2 us;

    pwm_period <= std_logic_vector( to_unsigned( 16, pwm_period'length ) );
    pwm_on     <= std_logic_vector( to_unsigned(  8, pwm_on'length ) );
    pwm_load   <= '1';
    wait until rising_edge(clk);
    pwm_period <= (others => '0');
    pwm_on     <= (others => '0');
    pwm_load   <= '0';

    wait for 2 us;

    pwm_period <= std_logic_vector( to_unsigned( 16, pwm_period'length ) );
    pwm_on     <= std_logic_vector( to_unsigned( 15, pwm_on'length ) );
    pwm_load   <= '1';
    wait until rising_edge(clk);
    pwm_period <= (others => '0');
    pwm_on     <= (others => '0');
    pwm_load   <= '0';

    wait for 2 us;

    pwm_period <= std_logic_vector( to_unsigned( 16, pwm_period'length ) );
    pwm_on     <= std_logic_vector( to_unsigned( 16, pwm_on'length ) );
    pwm_load   <= '1';
    wait until rising_edge(clk);
    pwm_period <= (others => '0');
    pwm_on     <= (others => '0');
    pwm_load   <= '0';

    wait for 2 us;

    sim_end <= true;
    wait;
  end process CS_load_params;

end behav;
--synthesis translate_on
