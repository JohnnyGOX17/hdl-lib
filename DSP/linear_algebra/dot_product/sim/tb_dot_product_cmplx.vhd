library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity tb_dot_product_cmplx is
end tb_dot_product_cmplx;

architecture behav of tb_dot_product_cmplx is

  signal clk        : std_logic := '0';
  signal reset      : std_logic;
  signal din_valid  : std_logic := '0';
  signal din_a_real : T_slv_2D(7 downto 0)(15 downto 0);
  signal din_a_imag : T_slv_2D(7 downto 0)(15 downto 0);
  signal din_b_real : T_slv_2D(7 downto 0)(15 downto 0);
  signal din_b_imag : T_slv_2D(7 downto 0)(15 downto 0);
  signal dout_valid : std_logic;
  signal dout_real  : std_logic_vector(35 downto 0);
  signal dout_imag  : std_logic_vector(35 downto 0);

  signal sim_end    : boolean := false;

begin

  clk   <= not clk after 10.0 ns when not sim_end else '0';
  reset <= '1','0' after  100 ns;

  CS_data_inputs: process
    variable slv_tmp_a_real : std_logic_vector(15 downto 0);
    variable slv_tmp_b_real : std_logic_vector(15 downto 0);
    variable slv_tmp_a_imag : std_logic_vector(15 downto 0);
    variable slv_tmp_b_imag : std_logic_vector(15 downto 0);
  begin
    wait until reset = '0';
    wait until rising_edge(clk);

    for i in 0 to 7 loop
      slv_tmp_a_real := std_logic_vector( to_signed( i, 16 ) );
      slv_tmp_a_imag := std_logic_vector( to_signed( i-5, 16 ) );
      slv_tmp_b_real := std_logic_vector( to_signed( -i, 16 ) );
      slv_tmp_b_imag := std_logic_vector( to_signed( i*2, 16 ) );

      din_a_real(i)  <= slv_tmp_a_real;
      din_b_real(i)  <= slv_tmp_b_real;
      din_a_imag(i)  <= slv_tmp_a_imag;
      din_b_imag(i)  <= slv_tmp_b_imag;
    end loop;

    din_valid <= '1';
    wait until rising_edge(clk);
    din_valid <= '0';

    wait for 200 ns;
    sim_end <= true;
    wait;
  end process CS_data_inputs;

  CS_log_result: process
  begin
    wait until rising_edge(clk) and dout_valid = '1';
    -- constrain output value to 32-bit integer for sim logging
    report "Dot product result: " & integer'image(to_integer(signed(dout_real(31 downto 0)))) &
           " " & integer'image(to_integer(signed(dout_imag(31 downto 0)))) & "j";
    wait;
  end process CS_log_result;

  U_DUT: entity work.dot_product_cmplx
    generic map (
      G_AWIDTH  => 16,   -- input vector bitwidth
      G_BWIDTH  => 16,   -- input vector bitwidth
      G_VEC_LEN =>  8,   -- number of input samples in each vector
      G_CONJ    => true  -- compute a^{H}*b
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => din_valid,
      din_a_real   => din_a_real,
      din_a_imag   => din_a_imag,
      din_b_real   => din_b_real,
      din_b_imag   => din_b_imag,
      dout_valid   => dout_valid,
      dout_real    => dout_real,
      dout_imag    => dout_imag
    );

end architecture behav;

