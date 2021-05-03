library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_misc.all;
library work;
  use work.util_pkg.all;

entity tb_conv2D is
  generic (
    G_DATA_WIDTH   : integer := 16;
    G_WEIGHT_WIDTH : integer :=  8;
    G_I_HEIGHT     : integer :=  9;
    G_I_WIDTH      : integer :=  8;
    G_K_HEIGHT     : integer :=  5;
    G_K_WIDTH      : integer :=  4;
    G_O_HEIGHT     : integer :=  5;
    G_O_WIDTH      : integer :=  5
  );
end entity tb_conv2D;

architecture behav of tb_conv2D is

  signal clk            : std_logic := '0';
  signal reset          : std_logic;

  -- static kernel value
  signal conv_kern      : T_signed_3D(G_K_HEIGHT - 1 downto 0)
                                     (G_K_WIDTH  - 1 downto 0)
                                     (G_WEIGHT_WIDTH - 1 downto 0);
  signal conv_kern_int  : T_int_3D(G_K_HEIGHT - 1 downto 0)
                                  (G_K_WIDTH  - 1 downto 0) :=
                        (
                          (-26,  66,  16, -15),
                          (-62,  -5, -24, -36),
                          (-39,  29, -44, -38),
                          (-84,  53,  12,   9),
                          ( 99,  80, -65, -44)
                        );
  signal din_valid      : std_logic;
  signal din            : T_signed_3D(G_I_HEIGHT - 1 downto 0)
                                     (G_I_WIDTH  - 1 downto 0)
                                     (G_DATA_WIDTH - 1 downto 0);

  signal dout_valid     : std_logic;
  signal dout           : T_signed_3D(G_O_HEIGHT - 1 downto 0)
                                     (G_O_WIDTH  - 1 downto 0)
                                     (G_DATA_WIDTH - 1 downto 0);

begin

  clk   <= not clk after 5.0 ns;
  reset <= '1','0' after 100 ns;

  -- map integer values to signed input
  UG_row: for i in 0 to G_K_HEIGHT - 1 generate
    UG_col: for j in 0 to G_K_WIDTH - 1 generate
      conv_kern(i)(j) <= to_signed( conv_kern_int(i)(j), G_WEIGHT_WIDTH );
    end generate UG_col;
  end generate UG_row;

  U_DUT: entity work.conv2D
    generic map (
      G_DATA_WIDTH   => 16,
      G_WEIGHT_WIDTH =>  8,
      G_I_HEIGHT     =>  9,
      G_I_WIDTH      =>  8,
      G_K_HEIGHT     =>  5,
      G_K_WIDTH      =>  4,
      G_O_HEIGHT     =>  5,
      G_O_WIDTH      =>  5
    )
    port map (
      clk            => clk,
      reset          => reset,
      conv_kern      => conv_kern,
      din_valid      => din_valid,
      din            => din,
      dout_valid     => dout_valid,
      dout           => dout
    );


  CS_test_inputs: process
  begin
    din_valid <= '0';
    wait until rising_edge(clk) and reset = '0';
    wait until rising_edge(clk);
    -- test w/unity data
    for i in 0 to G_I_HEIGHT - 1 loop
      for j in 0 to G_I_WIDTH - 1 loop
        din(i)(j) <= to_signed( 1, G_DATA_WIDTH );
      end loop;
    end loop;
    din_valid <= '1';

    wait until rising_edge(clk);
    din_valid <= '0';

    wait;
  end process CS_test_inputs;

end behav;
