-- Parallel Adder Tree w/recursion (VHDL-2008)
--   inspired by: https://stackoverflow.com/a/50002251
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity adder_tree is
  generic (
    G_DATA_WIDTH : natural := 16; -- sample bitwidth
    G_NUM_INPUTS : natural :=  8  -- number of input samples in vector
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic := '0'; -- (optional) sync reset for *valid's
    -- input data valid across input row vector
    din_valid    : in  std_logic := '1';
    -- NOTE: input samples not registered
    din          : in  T_slv_2D(G_NUM_INPUTS - 1 downto 0)(G_DATA_WIDTH - 1 downto 0);

    dout_valid   : out std_logic;
    dout         : out std_logic_vector(F_clog2(G_NUM_INPUTS) + G_DATA_WIDTH - 1 downto 0)
  );
end adder_tree;

architecture rtl of adder_tree is
  constant K_NXT_NUM_INPUTS : natural := (G_NUM_INPUTS/2) + (G_NUM_INPUTS mod 2);

  -- registered adder outputs for next stage (+1 bit growth)
  -- NOTE: arbitrarily adding input slv's as unsigned since addition is same
  -- with sign extension and accounted overflow bit
  signal sig_nxt_din : T_unsigned_2D(K_NXT_NUM_INPUTS - 1 downto 0)(G_DATA_WIDTH downto 0)
                     := (others => (others => '0'));
  signal sig_nxt_slv : T_slv_2D(K_NXT_NUM_INPUTS - 1 downto 0)(G_DATA_WIDTH downto 0);
  signal sig_dvalid  : std_logic := '0';

begin

  UG_unsigned_to_slv_2D: for i in sig_nxt_din'range generate
    sig_nxt_slv(i) <= std_logic_vector( sig_nxt_din(i) );
  end generate UG_unsigned_to_slv_2D;

  S_adder: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sig_dvalid <= '0';
      else
        if din_valid = '1' then
          for i in 0 to (G_NUM_INPUTS/2) - 1 loop
            sig_nxt_din(i) <= resize( unsigned( din(i*2) ), G_DATA_WIDTH + 1 ) +
                              resize( unsigned( din((i*2)+1) ), G_DATA_WIDTH + 1);
          end loop;

          if F_is_odd( G_NUM_INPUTS ) then -- account for odd input -> next stage
            sig_nxt_din(sig_nxt_din'high) <= resize( unsigned( din(din'high) ),
                                                     G_DATA_WIDTH + 1 );
          end if;
        end if;
        sig_dvalid <= din_valid;
      end if;
    end if;
  end process S_adder;

  UG_recurse: if F_clog2( G_NUM_INPUTS ) > 1 generate
    U_next_adder_stage: entity work.adder_tree
      generic map (
        G_DATA_WIDTH => G_DATA_WIDTH + 1,
        G_NUM_INPUTS => K_NXT_NUM_INPUTS
      )
      port map (
        clk          => clk,
        reset        => reset,
        din_valid    => sig_dvalid,
        din          => sig_nxt_slv,
        dout_valid   => dout_valid,
        dout         => dout
      );
  end generate UG_recurse;

  UG_final_stage: if F_clog2( G_NUM_INPUTS ) = 1 generate
    dout_valid <= sig_dvalid;
    dout       <= std_logic_vector( sig_nxt_din(0) );
  end generate UG_final_stage;

end architecture rtl;

