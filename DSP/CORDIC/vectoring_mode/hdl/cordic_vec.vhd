-- inspired by https://github.com/ZipCPU/cordic/blob/master/rtl/topolar.v
--   ^ since GPL, this component shall be GPL licensed as well
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity cordic_vec is
  generic (
    G_ITERATIONS : integer := 16 -- also equates to output precision
  );
  port (
    clk          : in  std_logic;
    valid_in     : in  std_logic;
    x_in         : in  signed(G_ITERATIONS - 1 downto 0);
    y_in         : in  signed(G_ITERATIONS - 1 downto 0);

    valid_out    : out std_logic;
    phase_out    : out signed(31 downto 0);
    mag_out      : out signed(G_ITERATIONS - 1 downto 0)
  );
end entity cordic_vec;

architecture rtl of cordic_vec is

  type T_sign_iter is array (integer range<>) of signed(G_ITERATIONS downto 0);
  type T_sign_32b  is array (integer range<>) of signed(31 downto 0);

  function F_init_atan_LUT return T_sign_32b is
    variable V_return : T_sign_32b(29 downto 0);
  begin
    -- 45deg angle already accounted for in S_pre_cordic input stage
    V_return( 0) := "00010010111001000000010100011101"; -- 26.565 degrees -> atan(2^-1)
    V_return( 1) := "00001001111110110011100001011011"; -- 14.036 degrees -> atan(2^-2)
    V_return( 2) := "00000101000100010001000111010100"; -- atan(2^-3)
    V_return( 3) := "00000010100010110000110101000011"; -- ...
    V_return( 4) := "00000001010001011101011111100001";
    V_return( 5) := "00000000101000101111011000011110";
    V_return( 6) := "00000000010100010111110001010101";
    V_return( 7) := "00000000001010001011111001010011";
    V_return( 8) := "00000000000101000101111100101110";
    V_return( 9) := "00000000000010100010111110011000";
    V_return(10) := "00000000000001010001011111001100";
    V_return(11) := "00000000000000101000101111100110";
    V_return(12) := "00000000000000010100010111110011";
    V_return(13) := "00000000000000001010001011111001";
    V_return(14) := "00000000000000000101000101111100";
    V_return(15) := "00000000000000000010100010111110";
    V_return(16) := "00000000000000000001010001011111";
    V_return(17) := "00000000000000000000101000101111";
    V_return(18) := "00000000000000000000010100010111";
    V_return(19) := "00000000000000000000001010001011";
    V_return(20) := "00000000000000000000000101000101";
    V_return(21) := "00000000000000000000000010100010";
    V_return(22) := "00000000000000000000000001010001";
    V_return(23) := "00000000000000000000000000101000";
    V_return(24) := "00000000000000000000000000010100";
    V_return(25) := "00000000000000000000000000001010";
    V_return(26) := "00000000000000000000000000000101";
    V_return(27) := "00000000000000000000000000000010";
    V_return(28) := "00000000000000000000000000000001";
    V_return(29) := "00000000000000000000000000000000";
    return V_return;
  end F_init_atan_LUT;

  signal atan_LUT : T_sign_32b(29 downto 0) := F_init_atan_LUT;
  signal x, y     : T_sign_iter(G_ITERATIONS - 1 downto 0) := (others => (others => '0'));
  signal ph       :  T_sign_32b(G_ITERATIONS - 1 downto 0) := (others => (others => '0'));

  signal sig_valid_sr : std_logic_vector(G_ITERATIONS - 1 downto 0) := (others => '0');

begin

  -- valid pulse output after input pulse passes through shift reg
  valid_out <= sig_valid_sr(sig_valid_sr'high);
  phase_out <= ph(G_ITERATIONS - 1);
  -- sign extend magnitude output
  mag_out   <= resize( x(G_ITERATIONS - 1), mag_out'length );

  S_shift_reg_valid: process(clk)
  begin
    if rising_edge(clk) then
      -- shift register to delay data valid to match pipeline delay
      sig_valid_sr <= sig_valid_sr(G_ITERATIONS - 2 downto 0) & valid_in;
    end if;
  end process S_shift_reg_valid;

  -- Pre-CORDIC rotations to map input angle to +/- 45deg based on X/Y input quadrant
  -- NOTE: use hex(degree_to_signed_fx()) function in Python to help with angle conversions
  S_pre_cordic: process(clk)
  begin
    if rising_edge(clk) then
      -- Quad IV: rotate by -315deg (so set initial phase to 315deg)
      if (x_in(x_in'left) = '0') and (y_in(y_in'left) = '1') then
         x(0) <= resize( x_in, G_ITERATIONS + 1 ) - resize( y_in, G_ITERATIONS + 1 );
         y(0) <= resize( x_in, G_ITERATIONS + 1 ) + resize( y_in, G_ITERATIONS + 1 );
        ph(0) <= X"e000_0000";
      -- Quad II: rotate by -135deg (init phase = 135deg)
      elsif (x_in(x_in'left) = '1') and (y_in(y_in'left) = '0') then
         x(0) <= -resize( x_in, G_ITERATIONS + 1 ) + resize( y_in, G_ITERATIONS + 1 );
         y(0) <= -resize( x_in, G_ITERATIONS + 1 ) - resize( y_in, G_ITERATIONS + 1 );
        ph(0) <= X"6000_0000";
      -- Quad III: rotate by -225deg (init phase = 225deg)
      elsif (x_in(x_in'left) = '1') and (y_in(y_in'left) = '1') then
         x(0) <= -resize( x_in, G_ITERATIONS + 1 ) - resize( y_in, G_ITERATIONS + 1 );
         y(0) <=  resize( x_in, G_ITERATIONS + 1 ) - resize( y_in, G_ITERATIONS + 1 );
        ph(0) <= X"a000_0000";
      else -- Quad I ["00"]: rotate by -45deg (init phase = 45deg)
         x(0) <=  resize( x_in, G_ITERATIONS + 1 ) + resize( y_in, G_ITERATIONS + 1 );
         y(0) <= -resize( x_in, G_ITERATIONS + 1 ) + resize( y_in, G_ITERATIONS + 1 );
        ph(0) <= X"2000_0000";
      end if;
    end if;
  end process S_pre_cordic;

  -- generate each pipelined stage for CORDIC rotations
  UG_CORDIC_rotations: for i in 0 to G_ITERATIONS - 2 generate
    -- CORDIC process for rectangular -> polar rotates the Y value to 0 and
    -- gives the magnitude of the vector as our x value and the phase as the
    -- angle it took to rotate the Y component to 0
    S_add_sub: process(clk)
    begin
      if rising_edge(clk) then
        if y(i)(y(i)'left) = '1' then -- Negative Y val: rotate by CORDIC angle in (+) direction
           x(i + 1) <=  x(i) - shift_right( y(i), i+1 );
           y(i + 1) <=  y(i) + shift_right( x(i), i+1 );
          ph(i + 1) <= ph(i) - atan_LUT(i);
        else -- Positive Y val: rotate by CORDIC angle in (-) direction
           x(i + 1) <=  x(i) + shift_right( y(i), i+1 );
           y(i + 1) <=  y(i) - shift_right( x(i), i+1 );
          ph(i + 1) <= ph(i) + atan_LUT(i);
        end if;
      end if;
    end process S_add_sub;
  end generate UG_CORDIC_rotations;

end architecture rtl;

