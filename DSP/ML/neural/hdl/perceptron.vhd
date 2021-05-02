-- Implements a perceptron with N-connections
-- For quantizations like 16b data w/8b weights, we can simply keep the 24b product and accumulate
--   to something like a 32b/48b value (large adders are cheap nowadays) and then shift at very end
--   to keep relative precision
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
library work;
  use work.util_pkg.all;

entity perceptron is
  generic (
    G_DATA_WIDTH   : integer := 16;
    G_WEIGHT_WIDTH : integer :=  8;
    -- number of connections from previous layer (== # of weights)
    G_NUM_CONNECT  : integer := 32;
    -- accumulator register word size
    G_ACCUM_WIDTH  : integer := 24;
    G_WEIGHT_PATH  : string  := "../scripts/coef.txt"
  );
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;

    din_valid      : in  std_logic;
    din            : in  T_signed_2D(G_NUM_CONNECT - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);

    dout_valid     : out std_logic;
    dout           : out signed(G_DATA_WIDTH - 1 downto 0)
  );
end entity perceptron;

architecture rtl of perceptron is

  type T_percep_fsm is (S_IDLE,
                        S_ITER_MAC,
                        S_FINAL_ACC,
                        S_OUT_VALID);
  signal sig_percep_state : T_percep_fsm := S_IDLE;

  type T_rom_type is array (G_NUM_CONNECT - 1 downto 0) of std_logic_vector(G_WEIGHT_WIDTH - 1 downto 0);

  -- Reads an ASCII file with bit-vector patterns on each line where:
  --   + each line has a single binary value of length `slv_length`
  --   + reads up to `dim_length` lines of file
  -- e.x. a file with values `0`, `1`, and `7` is:
  --      00000000
  --      00000001
  --      00000111
  -- similar to Vivado RAM file init VHDL template
  function F_read_from_file( file_path  : string ) return T_rom_type is
    file     fd       : text is in file_path;
    variable V_line   : line;
    variable V_bitvec : bit_vector(G_WEIGHT_WIDTH - 1 downto 0);
    variable V_return : T_rom_type;
  begin
    for i in T_rom_type'range loop
      readline( fd, V_line );
      read( V_line, V_bitvec );
      V_return(i) := to_stdlogicvector( V_bitvec );
    end loop;
    return V_return;
  end F_read_from_file;


  -- infers as ROM by synthesis tools (LUTRAM vs BRAM left to tooling, could
  -- explicitly specificy here as an attribute) and initial values are weights
  -- from passed weight file path
  signal sig_weight_array : T_rom_type := F_read_from_file( G_WEIGHT_PATH );

  signal sig_idx  : unsigned( F_clog2(G_NUM_CONNECT) - 1 downto 0 );
  signal sig_prd  : signed(G_DATA_WIDTH + G_WEIGHT_WIDTH - 1 downto 0);
  signal sig_acc  : signed(G_ACCUM_WIDTH - 1 downto 0);

begin

  dout_valid <= '1' when sig_percep_state = S_OUT_VALID else '0';
  -- given large accumulator register, and we've been shift/scaling
  -- after each multiplication, we can simply take the LSBs for our
  -- final data output
  dout <= sig_acc(G_DATA_WIDTH - 1 downto 0);

  S_output_FSM: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_idx <= (others => '0');
        sig_acc <= (others => '0');

        sig_percep_state <= S_IDLE;
      else
        case sig_percep_state is
          when S_IDLE =>
            if din_valid = '1' then
              -- perform 1st lookup/mult here
              sig_prd <= din(to_integer(sig_idx)) *
                         signed( sig_weight_array(to_integer(sig_idx)) );
              sig_idx <= sig_idx + 1;

              sig_percep_state <= S_ITER_MAC;
            end if;


          -- iterate through weights & connections and accumulate result
          when S_ITER_MAC =>
            -- accumulate scaled/RSH product from last cycle
            sig_acc <= sig_acc + resize( shift_right( sig_prd, G_WEIGHT_WIDTH ),
                                         sig_acc'length );
            sig_prd <= din(to_integer(sig_idx)) *
                       signed( sig_weight_array(to_integer(sig_idx)) );

            if sig_idx = G_NUM_CONNECT - 1 then
              sig_percep_state <= S_FINAL_ACC;
            end if;
            sig_idx <= sig_idx + 1;


          when S_FINAL_ACC =>
            -- accumulate product from last cycle
            sig_acc <= sig_acc + resize( shift_right( sig_prd, G_WEIGHT_WIDTH ),
                                         sig_acc'length );
            sig_percep_state <= S_OUT_VALID;


          when S_OUT_VALID =>
            -- clear index & accumulator registers for next use
            sig_idx <= (others => '0');
            sig_acc <= (others => '0');
            -- since feed-forward, no need to wait for 'ready'
            sig_percep_state <= S_IDLE;

          when others => sig_percep_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process S_output_FSM;

end rtl;

