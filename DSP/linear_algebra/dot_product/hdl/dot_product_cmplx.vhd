-- Computes dot-product of two complex, signed input vectors (uses parallel adder tree)
-- If G_CONJ is TRUE, the complex transpose product a^{H}b is computed, else does a^{T}b
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity dot_product_cmplx is
  generic (
    G_AWIDTH  : natural := 16;   -- input vector bitwidth
    G_BWIDTH  : natural := 16;   -- input vector bitwidth
    G_VEC_LEN : natural :=  8;   -- number of input samples in each vector
    G_CONJ    : boolean := true  -- if true, do complex conjugate on input vector a
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
    -- input data valid across input row vectors
    din_valid    : in  std_logic := '1';
    din_a_real   : in  T_slv_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH - 1 downto 0);
    din_a_imag   : in  T_slv_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH - 1 downto 0);
    din_b_real   : in  T_slv_2D(G_VEC_LEN - 1 downto 0)(G_BWIDTH - 1 downto 0);
    din_b_imag   : in  T_slv_2D(G_VEC_LEN - 1 downto 0)(G_BWIDTH - 1 downto 0);

    dout_valid   : out std_logic;
    dout_real    : out std_logic_vector(F_clog2(G_VEC_LEN) + G_AWIDTH + G_BWIDTH downto 0);
    dout_imag    : out std_logic_vector(F_clog2(G_VEC_LEN) + G_AWIDTH + G_BWIDTH downto 0)
  );
end dot_product_cmplx;

architecture rtl of dot_product_cmplx is

  component adder_tree is
    generic (
      G_DATA_WIDTH : natural := 16; -- sample bitwidth
      G_NUM_INPUTS : natural :=  8  -- number of input samples in vector
    );
    port (
      clk          : in  std_logic;
      reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
      -- input data valid across input row vector
      din_valid    : in  std_logic := '1';
      -- NOTE: input samples not registered
      din          : in  T_slv_2D(G_NUM_INPUTS - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);

      dout_valid   : out std_logic;
      dout         : out std_logic_vector(F_clog2(G_NUM_INPUTS) + G_DATA_WIDTH - 1 downto 0)
    );
  end component adder_tree;

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
  end component complex_multiply_mult4;

  -- registered product outputs -> adder tree
  signal sig_product_real : T_signed_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH + G_BWIDTH downto 0)
                          := (others => (others => '0'));
  signal sig_product_imag : T_signed_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH + G_BWIDTH downto 0)
                          := (others => (others => '0'));

  signal sig_product_slv_real : T_slv_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH + G_BWIDTH downto 0)
                              := (others => (others => '0'));
  signal sig_product_slv_imag : T_slv_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH + G_BWIDTH downto 0)
                              := (others => (others => '0'));

  signal sig_product_valid : std_logic := '0';
  signal dout_valid_real   : std_logic := '0';
  signal dout_valid_imag   : std_logic := '0';

begin

  -- NOTE: since initial complex products are enforced to be valid contiguously
  --       the output valid need only come from one of the adder tress since they
  --       have equal pipeline delay
  dout_valid <= dout_valid_real; -- and dout_valid_imag;

  UG_index_input_vectors: for i in 0 to G_VEC_LEN - 1 generate
    U_cmplx_mult: complex_multiply_mult4
      generic map (
        G_AWIDTH => G_AWIDTH,
        G_BWIDTH => G_BWIDTH,
        G_CONJ_A => G_CONJ,
        G_CONJ_B => false
      )
      port map (
        clk      => clk,
        reset    => reset,
        ab_valid => din_valid,
        ar       => signed( din_a_real(i) ),
        ai       => signed( din_a_imag(i) ),
        br       => signed( din_b_real(i) ),
        bi       => signed( din_b_imag(i) ),
        p_valid  => sig_product_valid,
        pr       => sig_product_real(i),
        pi       => sig_product_imag(i)
      );

      sig_product_slv_real(i) <= std_logic_vector( sig_product_real(i) );
      sig_product_slv_imag(i) <= std_logic_vector( sig_product_imag(i) );
  end generate UG_index_input_vectors;

  U_adder_tree_real: adder_tree
    generic map (
      G_DATA_WIDTH => G_AWIDTH + G_BWIDTH + 1,
      G_NUM_INPUTS => G_VEC_LEN
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => sig_product_valid,
      din          => sig_product_slv_real,
      dout_valid   => dout_valid_real,
      dout         => dout_real
    );

  U_adder_tree_imag: adder_tree
    generic map (
      G_DATA_WIDTH => G_AWIDTH + G_BWIDTH + 1,
      G_NUM_INPUTS => G_VEC_LEN
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => sig_product_valid,
      din          => sig_product_slv_imag,
      dout_valid   => dout_valid_imag,
      dout         => dout_imag
    );

end architecture rtl;

