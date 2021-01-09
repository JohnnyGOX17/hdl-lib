-- Complex Multilier:
--   The following code implements a parameterizable complex multiplier
--   The style described uses 4 DSP's to implement the direct complex multiply
--   which can be optimized for a given architecture pipeline
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity complex_multiply_mult4 is
  generic (
    G_AWIDTH : natural := 16; -- size of 1st input of multiplier
    G_BWIDTH : natural := 18  -- size of 2nd input of multiplier
  );
  port (
    clk      : in  std_logic;
    ab_valid : in  std_logic; -- A & B complex input data valid
    ar       : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's real part
    ai       : in  signed(G_AWIDTH - 1 downto 0); -- 1st input's imaginary part
    br       : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's real part
    bi       : in  signed(G_BWIDTH - 1 downto 0); -- 2nd input's imaginary part
    p_valid  : out std_logic; -- Product complex output data valid
    pr       : out signed(G_AWIDTH + G_BWIDTH downto 0); -- real part of output
    pi       : out signed(G_AWIDTH + G_BWIDTH downto 0)  -- imaginary part of output
  );
end complex_multiply_mult4;

architecture rtl of complex_multiply_mult4 is

  signal ar_q, ai_q                     : signed(G_AWIDTH - 1 downto 0) := (others => '0');
  signal br_q, bi_q                     : signed(G_BWIDTH - 1 downto 0) := (others => '0');
  signal multr0, multr1, multi0, multi1 : signed(G_AWIDTH + G_BWIDTH - 1 downto 0) := (others => '0');
  signal addr, addi                     : signed(G_AWIDTH + G_BWIDTH downto 0) := (others => '0');

  constant K_PIPE_DELAY : integer := 3; -- # clk cycles of pipeline delay through component
  signal sig_valid_sr   : std_logic_vector(K_PIPE_DELAY - 1 downto 0) := (others => '0');

begin

  pr      <= addr;
  pi      <= addi;
  p_valid <= sig_valid_sr(sig_valid_sr'high);

  S_reg_inputs: process(clk)
  begin
    if rising_edge(clk) then
      ar_q <= ar;
      ai_q <= ai;
      br_q <= br;
      bi_q <= bi;
      -- shift register to delay data valid to match pipeline delay
      sig_valid_sr <= sig_valid_sr(K_PIPE_DELAY - 2 downto 0) & ab_valid;
    end if;
  end process S_reg_inputs;

  -- Implements pr = (ar*br) - (ai*bi)
  S_real: process(clk)
  begin
    if rising_edge(clk) then
      multr0 <= ar_q * br_q;
      multr1 <= ai_q * bi_q;
      addr   <= resize( multr0, G_AWIDTH + G_BWIDTH + 1 ) - resize( multr1, G_AWIDTH + G_BWIDTH + 1 );
    end if;
  end process S_real;

  -- Implements pi = (ar*bi) + (ai*br)
  S_imag: process(clk)
  begin
    if rising_edge(clk) then
      multi0 <= ar_q * bi_q;
      multi1 <= ai_q * br_q;
      addi   <= resize( multi0, G_AWIDTH + G_BWIDTH + 1 ) + resize( multi1, G_AWIDTH + G_BWIDTH + 1 );
    end if;
  end process S_imag;

end architecture rtl;

