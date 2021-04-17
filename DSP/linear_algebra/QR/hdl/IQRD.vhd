-- Inverse QR Decomposition (IQRD)
--   Solves the linear equation Ax = b for x, where:
--     · A = complex input matrix, of size (M,N), where M ≥ N
--     · b = complex input vector, of size (M,1)
--     · x = complex output vector to solve for, of size (N,1)
--
-- NOTE: For ready/valid handshaking, components with multiple input dependencies
--       (such as this top-level component) expect data producers (e.x. A & b
--       driven inputs) to assert `valid` before this component asserts `ready`
--       which then signals to the driving component(s) that input data aligned
--       to that `valid` has been successfully consumed.
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity IQRD is
  generic (
    G_DATA_WIDTH : positive := 16;    -- operational bitwidth of datapath (in & out)
    G_USE_LAMBDA : boolean  := false; -- use forgetting factor (lambda) in BC calc
    G_M          : positive := 4;
    G_N          : positive := 3
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    CORDIC_scale : in  signed(G_DATA_WIDTH - 1 downto 0) := X"4DBA";
    lambda       : in  signed(G_DATA_WIDTH - 1 downto 0) := X"7EB8";
    inv_lambda   : in  signed(G_DATA_WIDTH - 1 downto 0) := X"0000";

    A_real       : in  T_signed_3D(G_M - 1 downto 0)
                                  (G_N - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
    A_imag       : in  T_signed_3D(G_M - 1 downto 0)
                                  (G_N - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
    A_valid      : in  std_logic;
    A_ready      : out std_logic;

    b_real       : in  T_signed_2D(G_M - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
    b_imag       : in  T_signed_2D(G_M - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
    b_valid      : in  std_logic;
    b_ready      : out std_logic;

    x_real       : out T_signed_2D(G_N - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
    x_imag       : out T_signed_2D(G_N - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
    x_valid      : out std_logic;
    x_ready      : in  std_logic
  );
end IQRD;

architecture rtl of IQRD is

  type T_IQRD_FSM is (S_IDLE, S_CONSUME, S_WAIT_X, S_OUT_VALID);
  signal sig_iqrd_state : T_IQRD_FSM := S_IDLE;

  signal sig_A_real : T_signed_3D(G_M - 1 downto 0)
                                 (G_N - 1 downto 0)
                                 (G_DATA_WIDTH - 1 downto 0);
  signal sig_A_imag : T_signed_3D(G_M - 1 downto 0)
                                 (G_N - 1 downto 0)
                                 (G_DATA_WIDTH - 1 downto 0);

  -- indexes A matrix, for each column, as it is consumed into the systolic array
  type T_2D_idx is array (integer range <>) of integer range 0 to G_M - 1;
  signal sig_A_idx   : T_2D_idx(G_N - 1 downto 0);
  signal sig_A_valid : std_logic_vector(G_N - 1 downto 0);
  signal sig_A_ready : std_logic_vector(G_N - 1 downto 0);

  signal sig_b_real  : T_signed_2D(G_M - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
  signal sig_b_imag  : T_signed_2D(G_M - 1 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
  -- indexes b vector as it is consumed into the systolic array
  signal sig_b_idx   : integer range 0 to G_M - 1 := 0;
  signal sig_b_valid : std_logic;
  signal sig_b_ready : std_logic;

  -- cmplx samples & handshaking from row -> row (up/down)
  --   +1 extra row to map outputs to weight extract cells
  --   dim: (row index)(column index)
  signal sig_X_real  : T_signed_3D(G_N     downto 0)
                                  (G_N + 2 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
  signal sig_X_imag  : T_signed_3D(G_N     downto 0)
                                  (G_N + 2 downto 0)
                                  (G_DATA_WIDTH - 1 downto 0);
  signal sig_X_valid :    T_slv_2D(G_N     downto 0)
                                  (G_N + 2 downto 0);
  signal sig_X_ready :    T_slv_2D(G_N     downto 0)
                                  (G_N + 2 downto 0);

begin

  A_ready <= '1' when sig_iqrd_state = S_CONSUME else '0';
  b_ready <= '1' when sig_iqrd_state = S_CONSUME else '0';


  UG_index_A_matrix_for_each_column: for col_idx in 0 to (G_N - 1) generate
    S_index_A_input_matrix: process(clk)
    begin
      if rising_edge(clk) then
        if (reset = '1') or (sig_iqrd_state = S_IDLE) then
          sig_A_idx(col_idx)   <= 0;
          sig_A_valid(col_idx) <= '0';
        else
          if sig_A_ready(col_idx) = '1' then
            -- if we're at the end of indexing the A matrix, samples are no longer valid
            if sig_A_idx(col_idx) = (G_M - 1) then
              sig_A_valid(col_idx) <= '0';
            end if;
            -- increment A-matrix index when systolic array consumes a sample
            sig_A_idx(col_idx) <= sig_A_idx(col_idx) + 1;
          end if;

          if sig_iqrd_state = S_CONSUME then
            sig_A_valid(col_idx) <= '1';
          end if;
        end if;
      end if;
    end process S_index_A_input_matrix;
  end generate UG_index_A_matrix_for_each_column;

  S_index_b_input_vector: process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') or (sig_iqrd_state = S_IDLE) then
        sig_b_idx   <= 0;
        sig_b_valid <= '0';
      else
        if sig_b_ready = '1' then
          -- if we're at the end of indexing the b vector, samples are no longer valid
          if sig_b_idx = (G_M - 1) then
            sig_b_valid <= '0';
          end if;
          -- increment b-vector index when systolic array consumes a sample
          sig_b_idx <= sig_b_idx + 1;
        end if;

        if sig_iqrd_state = S_CONSUME then
          sig_b_valid <= '1';
        end if;
      end if;
    end if;
  end process S_index_b_input_vector;

  UG_map_inputs_to_first_row: for col_idx in 0 to (G_N + 2) generate
    UG_input_from_matrix_A: if col_idx < G_N generate
      -- Indexes registed A matrix:        | index into M dim.  | samp column |
      sig_X_real (0)(col_idx) <= sig_A_real( sig_A_idx(col_idx) )(col_idx);
      sig_X_imag (0)(col_idx) <= sig_A_imag( sig_A_idx(col_idx) )(col_idx);
      sig_X_valid(0)(col_idx) <= sig_A_valid(col_idx);
         sig_A_ready(col_idx) <= sig_X_ready(0)(col_idx);
    end generate UG_input_from_matrix_A;

    UG_input_from_vector_b: if col_idx = G_N generate
      sig_X_real (0)(col_idx) <= sig_b_real(sig_b_idx);
      sig_X_imag (0)(col_idx) <= sig_b_imag(sig_b_idx);
      sig_X_valid(0)(col_idx) <= sig_b_valid;
      sig_b_ready             <= sig_X_ready(0)(col_idx);
    end generate UG_input_from_vector_b;

    UG_input_const_1: if col_idx = (G_N + 1) generate
      sig_X_real (0)(col_idx) <= to_signed( 1, G_DATA_WIDTH);
      sig_X_imag (0)(col_idx) <= to_signed( 0, G_DATA_WIDTH);
      sig_X_valid(0)(col_idx) <= '1';
    end generate UG_input_const_1;

    UG_input_null: if col_idx = (G_N + 2) generate
      sig_X_real (0)(col_idx) <= to_signed( 0, G_DATA_WIDTH);
      sig_X_imag (0)(col_idx) <= to_signed( 0, G_DATA_WIDTH);
      sig_X_valid(0)(col_idx) <= '1';
    end generate UG_input_null;
  end generate UG_map_inputs_to_first_row;

  -- Number of rows = size N
  UG_systolic_array_rows: for row_idx in 0 to (G_N - 1) generate

    -- Number of columns = size N + 3, where the first (left-most) processing
    --   element within a row is the BC
    UG_systolic_array_columns: for col_idx in 0 to (G_N + 2) generate

      -- Boundary Cell is always left-most/first in column
      UG_left_BC: if col_idx = 0 generate
        U_BC_top: entity work.boundary_cell
          generic map (
            G_DATA_WIDTH => G_DATA_WIDTH,
            G_USE_LAMBDA => G_USE_LAMBDA
          )
          port map (
            clk          => clk,
            reset        => reset,
            CORDIC_scale => CORDIC_scale,
            lambda       => lambda,
            x_real       => sig_X_real(row_idx)(col_idx),
            x_imag       => sig_X_imag(row_idx)(col_idx),
            x_valid      => sig_X_valid(row_idx)(col_idx),
            x_ready      => sig_X_ready(row_idx)(col_idx),
            phi_out      =>
            theta_out    =>
            bc_valid_out =>
            ic_ready     =>
          );
        end generate UG_left_BC;

      -- Inverse Interal Cell fed by null-sample is always right-most/last in column
      UG_right_IIC: if col_idx = (G_N + 2) generate
        U_null_IIC: entity work.internal_cell
          generic map (
            G_DATA_WIDTH => G_DATA_WIDTH,
            G_USE_LAMBDA => G_USE_LAMBDA
          )
          port map (
            clk          => clk,
            reset        => reset,
            CORDIC_scale => CORDIC_scale,
            lambda       => inv_lambda,

            xin_real     => to_signed( 0, G_DATA_WIDTH),
            xin_imag     => to_signed( 0, G_DATA_WIDTH),
            xin_valid    => '1',  -- always NULL input
            xin_ready    => open, -- d/c
            phi_in       =>
            theta_in     =>
            bc_valid_in  =>
            ic_ready     =>
            xout_real    => sig_X_real(row_idx+1)(col_idx-1),
            xout_imag    => sig_X_imag(row_idx+1)(col_idx-1),
            xout_valid   =>
            xout_ready   =>
            phi_out      =>
            theta_out    =>
            angles_valid =>
          );
      end generate UG_right_IIC;

    end generate UG_systolic_array_columns;
  end generate UG_systolic_array_rows;

  S_main_FSM: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_iqrd_state <= S_IDLE;
      else
        case sig_iqrd_state is
          when S_IDLE =>
            if (A_valid = '1') and (b_valid = '1') then
              sig_A_real     <= A_real;
              sig_A_imag     <= A_imag;
              sig_b_real     <= b_real;
              sig_b_imag     <= b_imag;
              sig_iqrd_state <= S_CONSUME;
            end if;

          when S_CONSUME =>
            sig_iqrd_state <= S_WAIT_X;

          when S_WAIT_X =>

          when S_OUT_VALID =>
            if x_ready = '1' then
              sig_iqrd_state <= S_IDLE;
            end if;

          when others => sig_iqrd_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process S_main_FSM;

end rtl;
