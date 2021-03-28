-- Computes real dot-product of two input vectors (uses parallel adder tree)
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity dot_product_real is
  generic (
    G_AWIDTH  : natural := 16;   -- input vector bitwidth
    G_BWIDTH  : natural := 16;   -- input vector bitwidth
    G_VEC_LEN : natural :=  8;   -- number of input samples in each vector
    G_REG_IN  : boolean := true; -- register inputs samples before multiplies?
    G_SIGNED  : boolean := true  -- {true = signed, false = unsigned} math
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
    -- input data valid across input row vectors
    din_valid    : in  std_logic := '1';
    din_a        : in  T_slv_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH - 1 downto 0);
    din_b        : in  T_slv_2D(G_VEC_LEN - 1 downto 0)(G_BWIDTH - 1 downto 0);

    dout_valid   : out std_logic;
    dout         : out std_logic_vector(F_clog2(G_VEC_LEN) + G_AWIDTH + G_BWIDTH - 1 downto 0)
  );
end dot_product_real;

architecture rtl of dot_product_real is

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

  signal sig_din_a : T_slv_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH - 1 downto 0)
                   := (others => (others => '0'));
  signal sig_din_b : T_slv_2D(G_VEC_LEN - 1 downto 0)(G_BWIDTH - 1 downto 0)
                   := (others => (others => '0'));

  signal sig_din_valid : std_logic := '0';

  -- registered product outputs -> adder tree
  signal sig_product : T_slv_2D(G_VEC_LEN - 1 downto 0)(G_AWIDTH + G_BWIDTH - 1 downto 0)
                     := (others => (others => '0'));

  signal sig_product_valid : std_logic := '0';

begin

  UG_reg_inputs: if G_REG_IN generate
    S_reg_in: process(clk)
    begin
      if rising_edge(clk) then
        sig_din_a     <= din_a;
        sig_din_b     <= din_b;
        sig_din_valid <= din_valid;
      end if;
    end process S_reg_in;
  end generate UG_reg_inputs;

  UG_dont_reg_inputs: if not G_REG_IN generate
    sig_din_a     <= din_a;
    sig_din_b     <= din_b;
    sig_din_valid <= din_valid;
  end generate UG_dont_reg_inputs;

  S_element_wise_product: process(clk)
  begin
    if rising_edge(clk) then
      if sig_din_valid = '1' then
        for i in 0 to G_VEC_LEN - 1 loop
          if G_SIGNED then
            sig_product(i) <= std_logic_vector( signed( sig_din_a(i) ) *
                                                signed( sig_din_b(i) ) );
          else
            sig_product(i) <= std_logic_vector( unsigned( sig_din_a(i) ) *
                                                unsigned( sig_din_b(i) ) );
          end if;
        end loop;
      end if;

      if reset = '1' then
        sig_product_valid <= '0';
      else
        sig_product_valid <= sig_din_valid;
      end if;
    end if;
  end process S_element_wise_product;

  U_adder_tree: adder_tree
    generic map (
      G_DATA_WIDTH => G_AWIDTH + G_BWIDTH,
      G_NUM_INPUTS => G_VEC_LEN
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => sig_product_valid,
      din          => sig_product,
      dout_valid   => dout_valid,
      dout         => dout
    );

end architecture rtl;

