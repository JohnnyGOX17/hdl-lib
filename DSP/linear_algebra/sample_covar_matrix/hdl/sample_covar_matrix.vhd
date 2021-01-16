library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity sample_covar_matrix is
  generic (
    G_DATA_WIDTH : natural := 16; -- real & imag part sample bitwidth
    G_ACC_WIDTH  : natural := 48; -- covariance matrix internal accumulator data width
    G_N          : natural :=  4  -- number of channels (rows)
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    num_est_samp : in  unsigned; -- number of estimation samples (columns), M
    din_valid    : in  std_logic; -- din_real & din_imag valid (assumed all rows are aligned)
    din_real     : in  T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    din_imag     : in  T_signed_2D(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    dout_valid   : out std_logic;
    dout_real    : out T_signed_3D(G_N - 1 downto 0)(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);
    dout_imag    : out T_signed_3D(G_N - 1 downto 0)(G_N - 1 downto 0)(G_DATA_WIDTH - 1 downto 0)
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

  constant K_PIPE_DELAY : integer := 3; -- # clk cycles of pipeline delay through component
  signal sig_valid_sr   : std_logic_vector(K_PIPE_DELAY - 1 downto 0) := (others => '0');
  signal sig_end_of_est : std_logic; -- # of estimation samples complete
  signal sig_samp_cnt   : unsigned(num_est_samp'range);

begin

  dout_valid <= sig_end_of_est;
  dout_real  <= sig_covar_re;
  dout_imag  <= sig_covar_im;

  S_dvalid_count: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_valid_sr   <= (others => '0');
        sig_samp_cnt   <= (others => '0');
        sig_end_of_est <= '0';
      else
        -- shift register to delay data valid to match pipeline delay of cmult
        sig_valid_sr <= sig_valid_sr(K_PIPE_DELAY - 2 downto 0) & din_valid;
        if sig_valid_sr(sig_valid_sr'high) = '1' then
          if sig_samp_cnt >= num_est_samp then
            sig_samp_cnt   <= (others => '0');
            sig_end_of_est <= '1';
          else
            sig_samp_cnt   <= sig_samp_cnt + 1;
          end if;
        end if;

        if sig_end_of_est = '1' then
          sig_end_of_est <= '0';
        end if;
      end if;
    end if;
  end process S_dvalid_count;

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
          ab_valid => '0',         -- not used, see S_dvalid_count
          ar       => din_real(i), -- 1st input's real part
          ai       => din_imag(i), -- 1st input's imaginary part
          br       => din_real(j), -- 2nd input's real part
          bi       => din_imag(j), -- 2nd input's imaginary part
          p_valid  => open,        -- not used, see S_dvalid_count
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
          -- reset accumulator at end of estimation cycle (number of samples hit)
          if (reset = '1') or (sig_end_of_est = '1') then
            sig_covar_re(i)(j) <= (others => '0');
            sig_covar_im(i)(j) <= (others => '0');
          else
            if sig_valid_sr(sig_valid_sr'high) = '1' then
              sig_covar_re(i)(j) <= resize( sig_pr(i)(j), G_ACC_WIDTH ) + sig_covar_re(i)(j);
              sig_covar_im(i)(j) <= resize( sig_pi(i)(j), G_ACC_WIDTH ) + sig_covar_im(i)(j);
            end if;
          end if;
        end if;
      end process S_accumulate;
    end generate UG_gen_columns;
  end generate UG_gen_rows;

end rtl;

