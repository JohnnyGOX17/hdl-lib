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
    G_O_WIDTH      : integer :=  5
  );
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;

    conv_kern      : in  T_signed_3D(G_K_HEIGHT - 1 downto 0)
                                    (G_K_WIDTH  - 1 downto 0)
                                    (G_WEIGHT_WIDTH - 1 downto 0);

    din_valid      : in  std_logic;
    din            : in  T_signed_3D(G_I_HEIGHT - 1 downto 0)
                                    (G_I_WIDTH  - 1 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);

    dout_valid     : out std_logic;
    dout           : out T_signed_3D(G_O_HEIGHT - 1 downto 0)
                                    (G_O_WIDTH  - 1 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0)
  );
end entity conv2D;

architecture rtl of conv2D is

  type T_conv2D_fsm is (S_IDLE,
                        S_CALC_KERN,
                        S_WAIT_FINAL_ACC,
                        S_OUT_VALID);
  signal sig_conv2D_state : T_conv2D_fsm := S_IDLE;

  signal sig_row_offst : integer range 0 to G_O_HEIGHT;
  signal sig_col_offst : integer range 0 to G_O_WIDTH;

  signal sig_final_row_offst : integer range 0 to G_O_HEIGHT;
  signal sig_final_col_offst : integer range 0 to G_O_WIDTH;

  constant K_POST_MULT_SZ    : integer := G_DATA_WIDTH + G_WEIGHT_WIDTH;
  constant K_POST_ROW_ADD_SZ : integer := K_POST_MULT_SZ + F_clog2(G_K_WIDTH);
  constant K_POST_COL_ADD_SZ : integer := K_POST_ROW_ADD_SZ + F_clog2(G_K_HEIGHT);

  signal sig_conv_kern_prd_valid : std_logic;
  signal sig_conv_kern_prd : T_signed_3D(G_K_HEIGHT - 1 downto 0)
                                        (G_K_WIDTH  - 1 downto 0)
                                        (K_POST_MULT_SZ - 1 downto 0);
  signal sig_conv_kern_prd_slv : T_slv_3D(G_K_HEIGHT - 1 downto 0)
                                         (G_K_WIDTH  - 1 downto 0)
                                         (K_POST_MULT_SZ - 1 downto 0);

  signal sig_kern_prd_row_acc_slv     : T_slv_2D(G_K_HEIGHT - 1 downto 0)
                                                (K_POST_ROW_ADD_SZ - 1 downto 0);
  signal sig_kern_prd_row_acc_vld_vec : std_logic_vector(G_K_HEIGHT - 1 downto 0);
  signal sig_kern_prd_row_acc_vld     : std_logic;

  signal sig_kern_prd_final_acc     : std_logic_vector(K_POST_COL_ADD_SZ - 1 downto 0);
  signal sig_kern_prd_final_acc_vld : std_logic;

  signal sig_dout      : T_signed_3D(G_O_HEIGHT - 1 downto 0)
                                    (G_O_WIDTH  - 1 downto 0)
                                    (G_DATA_WIDTH - 1 downto 0);

begin

  dout_valid <= '1' when sig_conv2D_state = S_OUT_VALID else '0';
  dout       <= sig_dout;

  -- create 2D adder tree which adds in parallel across rows, then adds
  -- the column-sum vector to a single output. design is pipelined so
  -- that we can start throwing 2D products to it, and a seperate valid
  -- counter indexes into the final registered 2D signal
  UG_parallel_adder_tree_rows: for i in 0 to G_K_HEIGHT - 1 generate
    -- convert to T_slv_3D type for adder tree component use
    UG_map_slv: for j in 0 to G_K_WIDTH - 1 generate
      sig_conv_kern_prd_slv(i)(j) <= std_logic_vector( sig_conv_kern_prd(i)(j) );
    end generate UG_map_slv;

    U_row_adder: entity work.adder_tree
      generic map (
        G_DATA_WIDTH => K_POST_MULT_SZ,
        G_NUM_INPUTS => G_K_WIDTH
      )
      port map (
        clk          => clk,
        reset        => reset,
        din_valid    => sig_conv_kern_prd_valid,
        din          => sig_conv_kern_prd_slv(i),
        dout_valid   => sig_kern_prd_row_acc_vld_vec(i),
        dout         => sig_kern_prd_row_acc_slv(i)
      );
  end generate UG_parallel_adder_tree_rows;

  -- just need to use one of the valids since all should complete at the same time
  --sig_kern_prd_row_acc_vld <= and_reduce( sig_kern_prd_row_acc_vld_vec );
  sig_kern_prd_row_acc_vld <= sig_kern_prd_row_acc_vld_vec(0);

  U_col_adder: entity work.adder_tree -- final add across rows
    generic map (
      G_DATA_WIDTH => K_POST_ROW_ADD_SZ,
      G_NUM_INPUTS => G_K_HEIGHT
    )
    port map (
      clk          => clk,
      reset        => reset,
      din_valid    => sig_kern_prd_row_acc_vld,
      din          => sig_kern_prd_row_acc_slv,
      dout_valid   => sig_kern_prd_final_acc_vld,
      dout         => sig_kern_prd_final_acc
    );



  S_build_output_matrix: process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') or (sig_conv2D_state = S_OUT_VALID) then
        sig_final_row_offst <= 0;
        sig_final_col_offst <= 0;
      else
        if sig_kern_prd_final_acc_vld = '1' then
          sig_dout(sig_final_row_offst)(sig_final_col_offst) <=
            signed( sig_kern_prd_final_acc(G_DATA_WIDTH - 1 downto 0) );

          if sig_final_col_offst = G_O_WIDTH - 1 then
            sig_final_row_offst <= sig_final_row_offst + 1;
            sig_final_col_offst <= 0;
          else
            sig_final_col_offst <= sig_final_col_offst + 1;
          end if;
        end if;
      end if;
    end if;
  end process S_build_output_matrix;



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
                                           din(i + sig_row_offst)(j + sig_col_offst);
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
            sig_conv_kern_prd_valid <= '0';
            -- #TODO: wait till parallel adder valid goes low? since we should have stuffed that pipeline
            if sig_kern_prd_final_acc_vld = '0' then
              sig_conv2D_state <= S_OUT_VALID;
            end if;

          when S_OUT_VALID =>
            sig_conv2D_state <= S_IDLE;

          when others => sig_conv2D_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process S_main_FSM;

end rtl;
