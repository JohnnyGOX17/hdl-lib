-- Implements a Direct Form Type 1 FIR Filter
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity FIR_type_I is
  generic (
    G_DATA_WIDTH : integer := 16;
    G_NUM_TAPS   : integer :=  8;
    G_COEF_PATH  : string  := "../scripts/coef.txt";
    G_COEF_WIDTH : integer := 16;
    G_SIGNED     : boolean := true -- [true = signed, false = unsigned] MAC ops
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
    din_valid    : in  std_logic := '1'; -- (optional) data valid for handshaking
    din          : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    dout_valid   : out std_logic;
    dout         : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
  );
end entity FIR_type_I;

architecture rtl of FIR_type_I is

  component dot_product_real is
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
  end component;

  constant K_OUTPUT_WIDTH : natural := F_clog2(G_NUM_TAPS) + G_DATA_WIDTH + G_COEF_WIDTH;
  constant K_OUT_SRL      : natural := F_clog2(G_NUM_TAPS) + G_COEF_WIDTH;

  signal sig_coef_array : T_slv_2D := F_read_file_slv_2D( G_COEF_PATH,
                                                          G_COEF_WIDTH,
                                                          G_NUM_TAPS );

  signal sig_data_delay_line : T_slv_2D(G_NUM_TAPS - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
  signal sig_data_valid      : std_logic := '0';
  signal sig_dout            : std_logic_vector(K_OUTPUT_WIDTH - 1 downto 0) := (others => '0');
  signal sig_dout_valid      : std_logic := '0';
  signal sig_dout_scaled     : std_logic_vector(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal sig_dout_scl_valid  : std_logic := '0';

begin

  dout_valid <= sig_dout_scl_valid;
  dout       <= sig_dout_scaled;

  -- process convolution of input data by serially registering input data through
  -- tapped delay line (NOTE: only move data forward when valid)
  S_tapped_delay_line: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_data_delay_line <= (others => (others => '0'));
        sig_data_valid      <= '0';
      else
        if din_valid = '1' then
          -- #TODO: is this the right order to feed data to match coefs?
          sig_data_delay_line(0) <= din;
          for i 0 to G_NUM_TAPS - 2 loop -- move older data down delay line
            sig_data_delay_line(i+1) <= sig_data_delay_line(i);
          end loop;
        end if;

        sig_data_valid <= din_valid;
      end if;
    end if;
  end process S_tapped_delay_line;

  -- A = data, B = filter weights
  U_dot_product_of_weights: dot_product_real
    generic map (
      G_AWIDTH  => G_DATA_WIDTH,
      G_BWIDTH  => G_COEF_WIDTH,
      G_VEC_LEN => G_NUM_TAPS,
      G_REG_IN  => false, -- we register samples with tapped delay line anyways
      G_SIGNED  => G_SIGNED
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => sig_data_valid,
      din_a        => sig_data_delay_line,
      din_b        => sig_coef_array,
      dout_valid   => sig_dout_valid,
      dout         => sig_dout
    );

  S_scale_outputs: process(clk)
  begin
    if rising_edge(clk) then
      if sig_dout_valid = '1' then
        if G_SIGNED then
          sig_dout_scaled <= std_logic_vector( resize( shift_right( to_signed(sig_dout),
                                                                    K_OUT_SRL ),
                                                       sig_dout_scaled'length ) );
        else
          sig_dout_scaled <= std_logic_vector( resize( shift_right( to_unsigned(sig_dout),
                                                                    K_OUT_SRL ),
                                                       sig_dout_scaled'length ) );
        end if;
      end if;

      sig_dout_scl_valid <= sig_dout_valid;
    end if;
  end process S_scale_outputs;

end rtl;

