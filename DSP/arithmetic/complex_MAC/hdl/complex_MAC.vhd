-- Complex Multiply & Accumulate:
--   Computes complex multiplication of inputs on each clock cycle (when EN high)
--   and adds result to internal accumulator:
--     MAC = (ar + j*ai) * (br + j*bi) + accum
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity complex_mac is
  generic (
    G_AWIDTH    : natural := 16;    -- size of 1st input of multiplier
    G_BWIDTH    : natural := 16;    -- size of 2nd input of multiplier
    G_MAC_WIDTH : natural := 48;    -- size of accumulator (input & output)
    G_CONJ_A    : boolean := false; -- take complex conjugate of arg A
    G_CONJ_B    : boolean := false; -- take complex conjugate of arg B
    G_MUL_OPT   : boolean := false  -- true  == 3x multiplier design (less resources)
                                    -- false == 4x multiplier design (more performance)
  );
  port (
    clk         : in  std_logic;
    reset       : in  std_logic; -- sync reset for *valid's & accumulator register
    ab_valid    : in  std_logic; -- A & B input data valid
    ar          : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's real part
    ai          : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's imaginary part
    br          : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's real part
    bi          : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's imaginary part
    mac_valid   : out std_logic; -- MAC result valid
    mac_r       : out signed(G_MAC_WIDTH - 1 downto 0); -- real part of output
    mac_i       : out signed(G_MAC_WIDTH - 1 downto 0)  -- imaginary part of output
  );
end complex_mac;

architecture rtl of complex_mac is

  component complex_multiply_mult3 is
    generic (
      G_AWIDTH : natural := 16;    -- size of 1st input of multiplier
      G_BWIDTH : natural := 18;    -- size of 2nd input of multiplier
      G_CONJ_A : boolean := false; -- take complex conjugate of arg A
      G_CONJ_B : boolean := false  -- take complex conjugate of arg B
    );
    port (
      clk      : in  std_logic;
      reset    : in  std_logic := '0'; -- (optional) sync reset for *valid's
      ab_valid : in  std_logic; -- A & B complex input data valid
      ar       : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's real part
      ai       : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's imaginary part
      br       : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's real part
      bi       : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's imaginary part
      p_valid  : out std_logic; -- Product complex output data valid
      pr       : out signed(G_AWIDTH + G_BWIDTH downto 0); -- real part of output
      pi       : out signed(G_AWIDTH + G_BWIDTH downto 0)  -- imaginary part of output
    );
  end component;

  component complex_multiply_mult4 is
    generic (
      G_AWIDTH : natural := 16;    -- size of 1st input of multiplier
      G_BWIDTH : natural := 18;    -- size of 2nd input of multiplier
      G_CONJ_A : boolean := false; -- take complex conjugate of arg A
      G_CONJ_B : boolean := false  -- take complex conjugate of arg B
    );
    port (
      clk      : in  std_logic;
      reset    : in  std_logic := '0'; -- (optional) sync reset for *valid's
      ab_valid : in  std_logic; -- A & B complex input data valid
      ar       : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's real part
      ai       : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's imaginary part
      br       : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's real part
      bi       : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's imaginary part
      p_valid  : out std_logic; -- Product complex output data valid
      pr       : out signed(G_AWIDTH + G_BWIDTH downto 0); -- real part of output
      pi       : out signed(G_AWIDTH + G_BWIDTH downto 0)  -- imaginary part of output
    );
  end component;

  signal sig_p_valid   : std_logic; -- Product complex output data valid
  signal sig_pr        : signed(G_AWIDTH + G_BWIDTH downto 0); -- real part of output
  signal sig_pi        : signed(G_AWIDTH + G_BWIDTH downto 0); -- imaginary part of output
  signal sig_mac_valid : std_logic;
  signal sig_mac_r     : signed(G_MAC_WIDTH - 1 downto 0); -- real part of output
  signal sig_mac_i     : signed(G_MAC_WIDTH - 1 downto 0); -- imaginary part of output

begin

  mac_r     <= sig_mac_r;
  mac_i     <= sig_mac_i;
  mac_valid <= sig_mac_valid;

  UG_opt_multiply: if G_MUL_OPT generate
    U_cmplx_mult: complex_multiply_mult3
      generic map (
        G_AWIDTH => G_AWIDTH,
        G_BWIDTH => G_BWIDTH,
        G_CONJ_A => G_CONJ_A,
        G_CONJ_B => G_CONJ_B
      )
      port map (
        clk      => clk,
        reset    => reset,
        ab_valid => ab_valid,
        ar       => ar,
        ai       => ai,
        br       => br,
        bi       => bi,
        p_valid  => sig_p_valid,
        pr       => sig_pr,
        pi       => sig_pi
      );
  end generate UG_opt_multiply;

  UG_std_multiply: if not G_MUL_OPT generate
    U_cmplx_mult: complex_multiply_mult4
      generic map (
        G_AWIDTH => G_AWIDTH,
        G_BWIDTH => G_BWIDTH,
        G_CONJ_A => G_CONJ_A,
        G_CONJ_B => G_CONJ_B
      )
      port map (
        clk      => clk,
        reset    => reset,
        ab_valid => ab_valid,
        ar       => ar,
        ai       => ai,
        br       => br,
        bi       => bi,
        p_valid  => sig_p_valid,
        pr       => sig_pr,
        pi       => sig_pi
      );
  end generate UG_std_multiply;

  S_accumulate: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_mac_r     <= (others => '0');
        sig_mac_i     <= (others => '0');
        sig_mac_valid <= '0';
      elsif sig_p_valid = '1' then
        sig_mac_r     <= resize( sig_pr, G_MAC_WIDTH ) + sig_mac_r;
        sig_mac_i     <= resize( sig_pi, G_MAC_WIDTH ) + sig_mac_i;
        sig_mac_valid <= '1';
      else -- deassert MAC valid when no valid complex product to add
        sig_mac_valid <= '0';
      end if;
    end if;
  end process S_accumulate;

end architecture rtl;

