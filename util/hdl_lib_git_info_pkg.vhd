-- Git metadata of HDL-lib repo for inclusion by components to be used for identification
-- NOTE: this is an auto-generate file from the 'pre-commit' git hook, DO NOT EDIT
library ieee;
  use ieee.std_logic_1164.all;

package hdl_lib_git_info_pkg is
  -- NOTE: these values are assigned to 32b constants for easy inclusion to SW-accessible registers
  -- Last commit hash of this repo
  constant K_hdl_lib_git_info_pkg_COMMIT_HASH : std_logic_vector(31 downto 0) := X"2c078d85";
  -- Date of most recent commit to repo of format "YYYY_MM_DD"
  constant K_hdl_lib_git_info_pkg_COMMIT_DATE : std_logic_vector(31 downto 0) := X"20210502";
end package hdl_lib_git_info_pkg;
