-- Inverse QR Decomposition (IQRD)
--   Solves the linear equation Ax = b for x, where:
--     · A = complex input matrix, of size (M,N), where M ≥ N
--     · b = complex input vector, of size (M,1)
--     · x = complex output vector to solve for, of size (N,1)
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity IQRD is
  generic (
    G_DATA_WIDTH : positive := 16;
    G_M          : positive :=  4;
    G_N          : positive :=  3
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;

    A_real       : in  T_signed_3D(G_M - 1 downto 0)(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    A_imag       : in  T_signed_3D(G_M - 1 downto 0)(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    A_valid      : in  std_logic;
    A_ready      : out std_logic;

    b_real       : in  T_signed_2D(G_M - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    b_imag       : in  T_signed_2D(G_M - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    b_valid      : in  std_logic;
    b_ready      : out std_logic;

    x_real       : out T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    x_imag       : out T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    x_valid      : out std_logic;
    x_ready      : in  std_logic
  );
end IQRD;

architecture rtl of IQRD is

begin

  -- Number of rows = size N
  UG_systolic_array_rows: for row_idx in 0 to G_N - 1 generate

    -- Number of columns = size N + 2
    UG_systolic_array_columns: for col_idx in 0 to G_N + 1 generate
    end generate UG_systolic_array_columns;

  end generate UG_systolic_array_rows;

end rtl;
