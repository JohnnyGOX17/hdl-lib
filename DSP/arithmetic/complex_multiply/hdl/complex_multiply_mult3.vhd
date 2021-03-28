-- Complex Multilier from Xilinx Vivado language template:
--   The following code implements a parameterizable complex multiplier
--   The style described uses 3 DSP's to implement the complex multiplier
--   taking advantage of the pre-adder, so widths chosen should be less
--   than what the architecture supports or else extra-logic/extra DSPs
--   will be inferred (NOTE: optimized for DSP48 architecture)
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity complex_multiply_mult3 is
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
end complex_multiply_mult3;

architecture rtl of complex_multiply_mult3 is

  signal ai_d, ai_dd, ai_ddd, ai_dddd             : signed(G_AWIDTH - 1 downto 0) := (others => '0');
  signal ar_d, ar_dd, ar_ddd, ar_dddd             : signed(G_AWIDTH - 1 downto 0) := (others => '0');
  signal bi_d, bi_dd, bi_ddd, br_d, br_dd, br_ddd : signed(G_BWIDTH - 1 downto 0) := (others => '0');
  signal addcommon                                : signed(G_AWIDTH downto 0) := (others => '0');
  signal addr, addi                               : signed(G_BWIDTH downto 0) := (others => '0');
  signal mult0, multr, multi, pr_int, pi_int      : signed(G_AWIDTH + G_BWIDTH downto 0) := (others => '0');
  signal common, commonr1, commonr2               : signed(G_AWIDTH + G_BWIDTH downto 0) := (others => '0');

  constant K_PIPE_DELAY : integer := 6; -- # clk cycles of pipeline delay through component
  signal sig_valid_sr   : std_logic_vector(K_PIPE_DELAY - 1 downto 0) := (others => '0');

begin

  p_valid <= sig_valid_sr(sig_valid_sr'high);
  pr      <= pr_int;
  pi      <= pi_int;

  S_reg_products: process(clk)
  begin
    if rising_edge(clk) then
      ar_d   <= ar;
      ar_dd  <= ar_d;
      if G_CONJ_A then
        ai_d   <= -ai;
      else
        ai_d   <= ai;
      end if;
      ai_dd  <= ai_d;
      br_d   <= br;
      br_dd  <= br_d;
      br_ddd <= br_dd;
      if G_CONJ_B then
        bi_d   <= -bi;
      else
        bi_d   <= bi;
      end if;
      bi_dd  <= bi_d;
      bi_ddd <= bi_dd;

      -- shift register to delay data valid to match pipeline delay
      if reset = '1' then
        sig_valid_sr <= (others => '0');
      else
        sig_valid_sr <= sig_valid_sr(K_PIPE_DELAY - 2 downto 0) & ab_valid;
      end if;
    end if;
  end process;

  -- Common factor (ar - ai) x bi, shared for the calculations
  -- of the real and imaginary final products.
  S_common: process(clk)
  begin
    if rising_edge(clk) then
      addcommon <= resize(ar_d, G_AWIDTH + 1) - resize(ai_d, G_AWIDTH + 1);
      mult0     <= addcommon * bi_dd;
      common    <= mult0;
    end if;
  end process;

  -- Real product
  S_real: process(clk)
  begin
    if rising_edge(clk) then
      ar_ddd   <= ar_dd;
      ar_dddd  <= ar_ddd;
      addr     <= resize(br_ddd, G_BWIDTH + 1) - resize(bi_ddd, G_BWIDTH + 1);
      multr    <= addr * ar_dddd;
      commonr1 <= common;
      pr_int   <= multr + commonr1;
    end if;
  end process;

  -- Imaginary product
  S_imag: process(clk)
  begin
    if rising_edge(clk) then
      ai_ddd   <= ai_dd;
      ai_dddd  <= ai_ddd;
      addi     <= resize(br_ddd, G_BWIDTH + 1) + resize(bi_ddd, G_BWIDTH + 1);
      multi    <= addi * ai_dddd;
      commonr2 <= common;
      pi_int   <= multi + commonr2;
    end if;
  end process;

end architecture rtl;

