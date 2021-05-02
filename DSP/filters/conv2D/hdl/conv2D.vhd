-- Implements 2D convolutional filter given a set of input kernel weights
-- of size K_HEIGHT x K_WIDTH and an input signal size of I_HEIGHT x I_WIDTH
-- resulting in a configurable output signal size of O_HEIGHT x O_WIDTH
-- assumes a single stride and spacing of 0 around input signal
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_misc.all;
library work;
  use work.util_pkg.all;

entity conv2D is
  generic (
    G_DATA_WIDTH   : integer := 16;
    G_WEIGHT_WIDTH : integer :=  8;
    G_I_HEIGHT     : integer :=  9;
    G_I_WIDTH      : integer :=  8;
    G_K_HEIGHT     : integer :=  5;
    G_K_WIDTH      : integer :=  4;
    G_O_HEIGHT     : integer :=  5;
    G_O_WIDTH      : integer :=  5;
  );
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;

    conv_kern      : in  T_signed_3D(G_K_HEIGHT - 1 downto 0)
                                    (G_K_WIDTH  - 1 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);

    din_valid      : in  std_logic;
    din            : in  T_signed_3D(G_I_HEIGHT - 1 downto 0)
                                    (G_I_WIDTH  - 1 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);

    dout_valid     : out std_logic;
    dout           : out T_signed_3D(G_O_HEIGHT - 1 downto 0)
                                    (G_O_WIDTH  - 1 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);
  );
end entity conv2D;

architecture rtl of conv2D is

  type T_conv2D_fsm is (S_IDLE,
                        S_CALC_KERN,
                        S_WAIT_FINAL_ACC,
                        S_OUT_VALID);
  signal sig_conv2D_state : T_percep_fsm := S_IDLE;

  signal sig_row_offst : integer range 0 to G_O_HEIGHT;
  signal sig_col_offst : integer range 0 to G_O_WIDTH;

  signal sig_conv_kern_prd_valid : std_logic;
  signal sig_conv_kern_prd : T_signed_3D(G_K_HEIGHT - 1 downto 0)
                                        (G_K_WIDTH  - 1 downto 0)
                                        (G_DATA_WIDTH*G_WEIGHT_WIDTH - 1 downto 0);

  signal sig_kern_prd_row_acc         : T_signed_2D(G_K_HEIGHT - 1 downto 0)
           (F_clog2(G_K_WIDTH) + G_DATA_WIDTH*G_WEIGHT_WIDTH - 1 downto 0);
  signal sig_kern_prd_row_acc_vld_vec : std_logic_vector(G_K_HEIGHT - 1 downto 0);
  signal sig_kern_prd_row_acc_vld     : std_logic;

  signal sig_kern_prd_final_acc     : std_logic_vector
           (F_clog2(G_K_WIDTH) + F_clog2(G_K_WIDTH) + G_DATA_WIDTH*G_WEIGHT_WIDTH - 1 downto 0);
  signal sig_kern_prd_final_acc_vld : std_logic;

  signal sig_dout      : T_signed_3D(G_O_HEIGHT - 1 downto 0)
                                    (G_O_WIDTH  - 1 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);

begin

  dout_valid <= '1' when sig_conv2D_state = S_OUT_VALID else '0';
  dout       <= sig_dout;

  -- create 2D adder tree which adds in parallel across rows, then adds
  -- the column vector together, and is pipelined so that we can start
  -- throwing 2D products to it, and a seperate valid counter indexes
  -- into the final registered 2D signal

  UG_parallel_adder_tree_rows: for i in 0 to G_K_HEIGHT - 1 generate
    U_row_adder: entity work.adder_tree
      generic map (
        G_DATA_WIDTH => G_DATA_WIDTH,
        G_NUM_INPUTS => G_K_WIDTH
      )
      port map (
        clk          => clk,
        reset        => reset,
        din_valid    => sig_conv_kern_prd_valid,
        din          => sig_conv_kern_prd(i),
        dout_valid   => sig_kern_prd_row_acc_vld_vec(i),
        dout         => sig_kern_prd_row_acc(i)
      );
  end generate UG_parallel_adder_tree_rows;

  sig_kern_prd_row_acc_vld <= and_reduce( sig_kern_prd_row_acc_vld_vec );

  U_col_adder: entity work.adder_tree -- final add across rows
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_NUM_INPUTS => G_K_HEIGHT
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => sig_kern_prd_row_acc_vld
      din          => sig_kern_prd_row_acc,
      dout_valid   => sig_kern_prd_final_acc_vld,
      dout         => sig_kern_prd_final_acc
    );


  S_main_FSM: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_row_offst    <= 0;
        sig_col_offst    <= 0;
        sig_conv2D_state <= S_IDLE;

        sig_conv_kern_prd_valid <= '0';
      else
        case sig_conv2D_state is
          when S_IDLE =>
            sig_conv_kern_prd_valid <= '0';

            sig_row_offst <= 0;
            sig_col_offst <= 0;
            if din_valid = '1' then
              sig_conv2D_state <= S_CALC_KERN;
            end if;

          when S_CALC_KERN =>
            sig_conv_kern_prd_valid <= '1';
            -- parallel products of 2D kernel and current offset into 2D input
            for i in 0 to G_K_HEIGHT - 1 loop
              for j in 0 to G_K_WIDTH - 1 loop
                sig_conv_kern_prd(i)(j) <= conv_kern(i)(j) *
                  sig_conv_kern_prd(i + sig_row_offst)(j + sig_col_offst);
              end loop;
            end loop;

            if sig_col_offst = G_O_WIDTH - 1 then
              if sig_row_offst = G_O_HEIGHT - 1 then
                -- should be at end of output size, wrap things up, change state
                sig_conv2D_state <= S_WAIT_FINAL_ACC;
              end if;
              sig_row_offst <= sig_row_offst + 1;
              sig_col_offst <= 0;
            else
              sig_col_offst <= sig_col_offst + 1;
            end if;


          when S_WAIT_FINAL_ACC =>
            -- wait till parallel adder valid goes low? since we should have stuffed that pipeline

          when S_OUT_VALID =>
            sig_conv2D_state <= S_IDLE;

          when others => sig_conv2D_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process S_main_FSM;

end rtl;
