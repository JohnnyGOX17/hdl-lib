-- Complex Multilier from Xilinx Vivado language template:
--   The following code implements a parameterizable complex multiplier
--   The style described uses 3 DSP's to implement the complex multiplier
--   taking advantage of the pre-adder, so widths chosen should be less
--   than what the architecture supports or else extra-logic/extra DSPs
--   will be inferred (NOTE: optimized for DSP48 architecture)
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity complex_multiply is
  generic (
    G_AWIDTH : natural := 16; -- size of 1st input of multiplier
    G_BWIDTH : natural := 18  -- size of 2nd input of multiplier
  );
  port (
    clk      : in  std_logic;
    ar       : in  std_logic_vector(G_AWIDTH - 1 downto 0); -- 1st input's real part
    ai       : in  std_logic_vector(G_AWIDTH - 1 downto 0); -- 1st input's imaginary part
    br       : in  std_logic_vector(G_BWIDTH - 1 downto 0); -- 2nd input's real part
    bi       : in  std_logic_vector(G_BWIDTH - 1 downto 0); -- 2nd input's imaginary part
    pr       : out std_logic_vector(G_AWIDTH + G_BWIDTH downto 0); -- real part of output
    pi       : out std_logic_vector(G_AWIDTH + G_BWIDTH downto 0)  -- imaginary part of output
  );
end complex_multiply;

architecture rtl of complex_multiply is

  signal ai_d, ai_dd, ai_ddd, ai_dddd             : signed(G_AWIDTH - 1 downto 0);
  signal ar_d, ar_dd, ar_ddd, ar_dddd             : signed(G_AWIDTH - 1 downto 0);
  signal bi_d, bi_dd, bi_ddd, br_d, br_dd, br_ddd : signed(G_BWIDTH - 1 downto 0);
  signal addcommon                                : signed(G_AWIDTH downto 0);
  signal addr, addi                               : signed(G_BWIDTH downto 0);
  signal mult0, multr, multi, pr_int, pi_int      : signed(G_AWIDTH + G_BWIDTH downto 0);
  signal common, commonr1, commonr2               : signed(G_AWIDTH + G_BWIDTH downto 0);

begin

  S_reg_products: process(clk)
  begin
    if rising_edge(clk) then
      ar_d   <= signed(ar);
      ar_dd  <= signed(ar_d);
      ai_d   <= signed(ai);
      ai_dd  <= signed(ai_d);
      br_d   <= signed(br);
      br_dd  <= signed(br_d);
      br_ddd <= signed(br_dd);
      bi_d   <= signed(bi);
      bi_dd  <= signed(bi_d);
      bi_ddd <= signed(bi_dd);
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

  pr <= std_logic_vector(pr_int);
  pi <= std_logic_vector(pi_int);

end architecture rtl;

