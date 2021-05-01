-- Weight Extraction Cell:
-- W_{i,j}(k) =  W_{i,j}(k - 1) - a_{i}(k)b_{i}(k)

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity weight_extract_cell is
  generic (
    G_DATA_WIDTH : natural := 16
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;

    -- no `ready` signal as a is updated across final row
    ain_real     : in  signed(G_DATA_WIDTH - 1 downto 0);
    ain_imag     : in  signed(G_DATA_WIDTH - 1 downto 0);
    ain_valid    : in  std_logic;

    -- pipelined `a` to be passed to next weight extract cell
    aout_real    : out signed(G_DATA_WIDTH - 1 downto 0);
    aout_imag    : out signed(G_DATA_WIDTH - 1 downto 0);
    aout_valid   : out std_logic;

    b_real       : in  signed(G_DATA_WIDTH - 1 downto 0);
    b_imag       : in  signed(G_DATA_WIDTH - 1 downto 0);
    b_valid      : in  std_logic;
    b_ready      : out std_logic;

    w_real       : out signed(G_DATA_WIDTH - 1 downto 0);
    w_imag       : out signed(G_DATA_WIDTH - 1 downto 0);
    w_valid      : out std_logic;
    w_ready      : in  std_logic
  );
end entity weight_extract_cell;

architecture rtl of weight_extract_cell is

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
  end component;

  type T_weight_fsm is (S_IDLE, S_CONSUME, S_WAIT_CALC, S_OUT_VALID);
  signal sig_weight_state : T_weight_fsm := S_IDLE;

  signal sig_input_valid : std_logic;

  signal sig_ab_valid : std_logic := '0';
  signal sig_ab_real  : signed((2*G_DATA_WIDTH) downto 0);
  signal sig_ab_imag  : signed((2*G_DATA_WIDTH) downto 0);

  signal sig_weight_z_real : signed(G_DATA_WIDTH downto 0);
  signal sig_weight_z_imag : signed(G_DATA_WIDTH downto 0);

  signal sig_aout_real    : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_aout_imag    : signed(G_DATA_WIDTH - 1 downto 0);
  signal sig_aout_valid   : std_logic;

begin

  aout_real    <= sig_aout_real;
  aout_imag    <= sig_aout_imag;
  aout_valid   <= sig_aout_valid;

  sig_input_valid <= '1' when sig_weight_state = S_CONSUME else '0';
  b_ready         <= '1' when sig_weight_state = S_CONSUME else '0';

  w_real  <= resize( shift_right( sig_weight_z_real, 1 ), w_real'length );
  w_imag  <= resize( shift_right( sig_weight_z_imag, 1 ), w_imag'length );
  w_valid <= '1' when sig_weight_state = S_OUT_VALID else '0';

  -- register 'a' to next weight extract cell
  S_reg_a: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_aout_valid <= '0';
      else
        if ain_valid = '1' then
          sig_aout_real  <= ain_real;
          sig_aout_imag  <= ain_imag;
        end if;
        sig_aout_valid <= ain_valid;
      end if;
    end if;
  end process S_reg_a;

  U_cmult_AB: complex_multiply_mult4
    generic map (
      G_AWIDTH => G_DATA_WIDTH,
      G_BWIDTH => G_DATA_WIDTH,
      G_CONJ_A => false,
      G_CONJ_B => false
    )
    port map (
      clk      => clk,
      reset    => reset,
      ab_valid => sig_input_valid,
      ar       => ain_real,
      ai       => ain_imag,
      br       => b_real,
      bi       => b_imag,
      p_valid  => sig_ab_valid,
      pr       => sig_ab_real,
      pi       => sig_ab_imag
    );

  S_weight_diff: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_weight_z_real <= (others => '0');
        sig_weight_z_imag <= (others => '0');
      else
        if sig_ab_valid = '1' then
          sig_weight_z_real <= sig_weight_z_real - resize( shift_right( sig_ab_real,
                                                                        G_DATA_WIDTH + 1 ),
                                                           G_DATA_WIDTH + 1 );
          sig_weight_z_imag <= sig_weight_z_imag - resize( shift_right( sig_ab_imag,
                                                                        G_DATA_WIDTH + 1 ),
                                                           G_DATA_WIDTH + 1 );
        end if;
      end if;
    end if;
  end process S_weight_diff;

  S_output_FSM: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_weight_state <= S_IDLE;
      else
        case sig_weight_state is
          when S_IDLE =>
            -- only care about b_valid to continue, since a should always be updated
            -- before b value since it comes from a preceeding QRD column output
            if b_valid = '1' then
              sig_weight_state <= S_CONSUME;
            end if;

          when S_CONSUME =>
            sig_weight_state <= S_WAIT_CALC;

          when S_WAIT_CALC =>
            if sig_ab_valid = '1' then
              sig_weight_state <= S_OUT_VALID;
            end if;

          when S_OUT_VALID =>
            if w_ready = '1' then
              sig_weight_state <= S_IDLE;
            end if;

          when others => sig_weight_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process S_output_FSM;

end rtl;

