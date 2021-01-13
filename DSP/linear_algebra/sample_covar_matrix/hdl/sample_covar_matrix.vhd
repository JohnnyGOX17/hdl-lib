library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity sample_covar_matrix is
  generic (
    G_DATA_WIDTH : natural := 16; -- real & imag part sample bitwidth
    G_ACC_WIDTH  : natural := 48; -- covariance matrix internal accumulator data width
    G_N          : natural :=  4; -- number of channels (rows)
    G_M          : natural := 32  -- number of estimation samples (columns), assumed power of 2 and >= N
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

  component complex_multiply_mult4 is
    generic (
      G_AWIDTH : natural := 16;    -- size of 1st input of multiplier
      G_BWIDTH : natural := 18;    -- size of 2nd input of multiplier
      G_CONJ_A : boolean := false; -- take complex conjugate of arg A
      G_CONJ_B : boolean := false  -- take complex conjugate of arg B
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
  end component;

-- #TODO: double-buffered covar matrix reg's so one can be read out while another is calculated with inputs?

  signal sig_covar_re, sig_covar_im : T_signed_3D(G_N - 1 downto 0)
                                                 (G_N - 1 downto 0)
                                                 (G_ACC_WIDTH - 1 downto 0);
  signal sig_pr, sig_pi             : T_signed_3D(G_N - 1 downto 0)
                                                 (G_N - 1 downto 0)
                                                 (2*G_DATA_WIDTH downto 0);

  signal sig_p_valid : T_slv_2D(G_N - 1 downto 0)(G_N - 1 downto 0);

begin

  -- create triangular, fused, complex multiply of input and its complex transpose
  UG_gen_rows: for i in 0 to G_N - 1 generate
    UG_gen_columns: for j in 0 to i generate
      -- Perform z[i,k]*conj(z[j,k])
      U_cmplx_mult: complex_multiply_mult4
        generic map (
          G_AWIDTH => G_DATA_WIDTH, -- size of 1st input of multiplier
          G_BWIDTH => G_DATA_WIDTH, -- size of 2nd input of multiplier
          G_CONJ_A => false,
          G_CONJ_B => true          -- take complex conjugate of B arg
        )
        port map (
          clk      => clk,
          ab_valid => din_valid,   -- A & B complex input data valid
          ar       => din_real(i), -- 1st input's real part
          ai       => din_imag(i), -- 1st input's imaginary part
          br       => din_real(j), -- 2nd input's real part
          bi       => din_imag(j), -- 2nd input's imaginary part
          p_valid  => sig_p_valid(i)(j),
          pr       => sig_pr(i)(j),
          pi       => sig_pi(i)(j)
        );

      -- Since output is always Hermitian positive semi-definite, the calculated
      -- lower triangle can be copied to the upper triangle by its diagonal
      -- complex conjugate
      UG_upper_hermitian: if i /= j generate
        sig_covar_re(j)(i) <=  sig_covar_re(i)(j);
        sig_covar_im(j)(i) <= -sig_covar_im(i)(j);
      end generate UG_upper_hermitian;

      S_accumulate: process(clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            sig_covar_re(i)(j) <= (others => '0');
            sig_covar_im(i)(j) <= (others => '0');
          else
            if sig_p_valid(i)(j) = '1' then
              sig_covar_re(i)(j) <= resize( sig_pr(i)(j), G_ACC_WIDTH ) + sig_covar_re(i)(j);
              sig_covar_im(i)(j) <= resize( sig_pi(i)(j), G_ACC_WIDTH ) + sig_covar_im(i)(j);
            end if;
          end if;
        end if;
      end process S_accumulate;
    end generate UG_gen_columns;
  end generate UG_gen_rows;

end rtl;

