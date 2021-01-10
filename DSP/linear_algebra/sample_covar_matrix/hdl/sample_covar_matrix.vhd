library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity sample_covar_matrix is
  generic (
    G_DATA_WIDTH : integer := 16; -- real & imag part sample bitwidth
    G_N          : integer :=  4; -- number of channels (rows)
    G_M          : integer := 32  -- number of estimation samples (columns), assumed power of 2 and >= N
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    din_valid    : in  std_logic;
    din_real     : in  T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    din_imag     : in  T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    dout_valid   : out std_logic;
    dout_real    : out T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    dout_imag    : out T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0)
  );
end sample_covar_matrix;

architecture rtl of sample_covar_matrix is

-- double-buffered covar matrix reg's so one can be read out while another is calculated with inputs

begin

  -- create triangular fused complext multiply of input and its complex transpose
  UG_gen_rows: for i in 0 to N - 1 generate
    UG_gen_columns: for j in 0 to i generate
    end generate UG_gen_columns;
  end generate UG_gen_rows;

  U_cmplx_mult: entity work.complex_multiply_mult4
    generic map (
      G_AWIDTH => G_DATA_WIDTH, -- size of 1st input of multiplier
      G_BWIDTH => G_DATA_WIDTH  -- size of 2nd input of multiplier
    )
    port map (
      clk      => clk,
      ab_valid => din_valid, -- A & B complex input data valid
      ar       => din_real(0), -- 1st input's real part
      ai       => din_imag(0), -- 1st input's imaginary part
      br       => din_real(0), -- 2nd input's real part
      bi       => din_imag(0), -- 2nd input's imaginary part
    );

end rtl;

