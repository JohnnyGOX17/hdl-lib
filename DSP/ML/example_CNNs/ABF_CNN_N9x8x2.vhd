-- Example CNN from thesis research of ABF CNN with N=8:
--     Input Size:  9x8x2
--     Output Size: 8x2
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_misc.all;
library work;
  use work.util_pkg.all;

entity ABF_CNN_N9x8x2 is
  generic (
    G_DATA_WIDTH   : integer := 16
  );
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;

    -- input from covariance matrix calculation
    din_valid      : in  std_logic;
    din_real       : in  T_signed_3D(8 downto 0)
                                    (7 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);
    din_imag       : in  T_signed_3D(8 downto 0)
                                    (7 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);

    -- output adaptive weights from CNN
    dout_valid     : out std_logic;
    dout_real      : out T_signed_2D(7 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);
    dout_imag      : out T_signed_2D(7 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0)
  );
end entity ABF_CNN_N9x8x2;

architecture rtl of ABF_CNN_N9x8x2 is

  constant K_WEIGHT_WIDTH : integer := 8; -- signed, 8b quantized weights throughout

  signal sig_conv_kern_real : T_signed_3D(4 downto 0)
                                         (3 downto 0)
                                         (K_WEIGHT_WIDTH - 1 downto 0);
  constant K_conv_kern_int_real  : T_int_3D(4 downto 0)
                                           (3 downto 0) :=
                                   (
                                     (-26,  66,  16, -15),
                                     (-62,  -5, -24, -36),
                                     (-39,  29, -44, -38),
                                     (-84,  53,  12,   9),
                                     ( 99,  80, -65, -44)
                                   );
  signal sig_conv_kern_imag : T_signed_3D(4 downto 0)
                                         (3 downto 0)
                                         (K_WEIGHT_WIDTH - 1 downto 0);
  constant K_conv_kern_int_imag  : T_int_3D(4 downto 0)
                                           (3 downto 0) :=
                                   (
                                     ( -10, -21, -13, -63),
                                     (  -4, -54, -30,  57),
                                     (  24,  10,  10, -32),
                                     (-104,  23,  17, -26),
                                     ( -97,-127,  96, 125)
                                   );

  signal sig_conv2D_out_real : T_signed_3D(4 downto 0)
                                          (4 downto 0)
                                          (G_DATA_WIDTH - 1 downto 0);
  signal sig_conv2D_out_real_valid : std_logic;
  signal sig_conv2D_out_imag : T_signed_3D(4 downto 0)
                                          (4 downto 0)
                                          (G_DATA_WIDTH - 1 downto 0);
  signal sig_conv2D_out_imag_valid : std_logic;

  signal sig_FC0_din        : T_signed_2D(49 downto 0)(G_DATA_WIDTH - 1 downto 0);
  signal sig_FC0_dout_valid : std_logic;
  signal sig_FC0_dout       : T_signed_2D(31 downto 0)(G_DATA_WIDTH - 1 downto 0);
  signal sig_FC1_dout_valid : std_logic;
  signal sig_FC1_dout       : T_signed_2D(15 downto 0)(G_DATA_WIDTH - 1 downto 0);

begin

  -- map integer values to signed input
  UG_row_conv2D: for i in 0 to 4 generate
    UG_col_conv2D: for j in 0 to 3 generate
      sig_conv_kern_real(i)(j) <= to_signed( K_conv_kern_int_real(i)(j), K_WEIGHT_WIDTH );
      sig_conv_kern_imag(i)(j) <= to_signed( K_conv_kern_int_imag(i)(j), K_WEIGHT_WIDTH );
    end generate UG_col_conv2D;
  end generate UG_row_conv2D;

  U_real_conv2D: entity work.conv2D
    generic map (
      G_DATA_WIDTH   => G_DATA_WIDTH,
      G_WEIGHT_WIDTH => K_WEIGHT_WIDTH,
      G_I_HEIGHT     => 9,
      G_I_WIDTH      => 8,
      G_K_HEIGHT     => 5,
      G_K_WIDTH      => 4,
      G_O_HEIGHT     => 5,
      G_O_WIDTH      => 5
    )
    port map (
      clk            => clk,
      reset          => reset,
      conv_kern      => sig_conv_kern_real,
      din_valid      => din_valid,
      din            => din_real,
      dout_valid     => sig_conv2D_out_real_valid,
      dout           => sig_conv2D_out_real
    );

  U_imag_conv2D: entity work.conv2D
    generic map (
      G_DATA_WIDTH   => G_DATA_WIDTH,
      G_WEIGHT_WIDTH => K_WEIGHT_WIDTH,
      G_I_HEIGHT     => 9,
      G_I_WIDTH      => 8,
      G_K_HEIGHT     => 5,
      G_K_WIDTH      => 4,
      G_O_HEIGHT     => 5,
      G_O_WIDTH      => 5
    )
    port map (
      clk            => clk,
      reset          => reset,
      conv_kern      => sig_conv_kern_imag,
      din_valid      => din_valid,
      din            => din_imag,
      dout_valid     => sig_conv2D_out_imag_valid,
      dout           => sig_conv2D_out_imag
    );

  -- flatten 2Dx2 outputs to wide 2D signal for input to first dense hidden layer
  --   goes from 5x5x2 -> 50x1
  UG_row_flatten: for i in 0 to 4 generate
    UG_col_flatten: for j in 0 to 4 generate
      sig_FC0_din( (i*10) + (j*2) )     <= sig_conv2D_out_real(i)(j);
      sig_FC0_din( (i*10) + (j*2) + 1 ) <= sig_conv2D_out_imag(i)(j);
    end generate UG_col_flatten;
  end generate UG_row_flatten;

  U_hidden_layer_4N: entity work.FC
    generic map (
      G_DATA_WIDTH   => G_DATA_WIDTH,
      G_WEIGHT_WIDTH => K_WEIGHT_WIDTH,
      G_NUM_INPUTS   => 50,
      G_NUM_OUTPUTS  => 32,
      G_ACCUM_WIDTH  => 24,
      G_LAYER_IDX    => 0,
      G_BASE_PATH    => "/home/jgentile/src/jhu-masters-thesis/src/hdl-lib/DSP/ML/neural/sim/FC_weights_layer_",
      G_ACTIVATION   => "RELU"
    )
    port map (
      clk            => clk,
      reset          => reset,
      din_valid      => sig_conv2D_out_real_valid, -- could've used *imag too, doesn't matter
      din            => sig_FC0_din,
      dout_valid     => sig_FC0_dout_valid,
      dout           => sig_FC0_dout
    );

  U_output_layer_2N: entity work.FC
    generic map (
      G_DATA_WIDTH   => G_DATA_WIDTH,
      G_WEIGHT_WIDTH => K_WEIGHT_WIDTH,
      G_NUM_INPUTS   => 32,
      G_NUM_OUTPUTS  => 16,
      G_ACCUM_WIDTH  => 24,
      G_LAYER_IDX    => 1,
      G_BASE_PATH    => "/home/jgentile/src/jhu-masters-thesis/src/hdl-lib/DSP/ML/neural/sim/FC_weights_layer_",
      G_ACTIVATION   => "NONE" -- no activation for final layer that gives weights
    )
    port map (
      clk            => clk,
      reset          => reset,
      din_valid      => sig_FC0_dout_valid,
      din            => sig_FC0_dout,
      dout_valid     => sig_FC1_dout_valid,
      dout           => sig_FC1_dout
    );


  dout_valid <= sig_FC1_dout_valid;
  dout_real  <= sig_FC1_dout( 7 downto 0);
  dout_imag  <= sig_FC1_dout(15 downto 8);

end rtl;
