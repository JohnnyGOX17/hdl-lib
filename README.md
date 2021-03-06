# HDL Library


[![](https://github.com/JohnnyGOX17/hdl-lib/workflows/VUnit%20Tests/badge.svg)](https://github.com/JohnnyGOX17/hdl-lib/actions)
![GitHub](https://img.shields.io/github/license/JohnnyGOX17/hdl-lib)

Library of common and re-use components and HDL code.

## Catalog of Components

```
├── DSP
│   ├── arithmetic
│   │   ├── adder_tree
│   │   ├── complex_MAC
│   │   └── complex_multiply
│   ├── CORDIC
│   ├── filters
│   │   └── FIR
│   │       └── systolic_FIR
│   └── linear_algebra
│       ├── dot_product
│       └── sample_covar_matrix
├── IO_interfaces
│   ├── bidir_iobuf
│   ├── PWM
│   └── seven_seg_disp
├── memory-FIFO-SRL
│   ├── RAM-ROM
│   │   └── sp_ram
│   └── shift_reg
│       ├── static_shift_reg_bit
│       └── static_shift_reg_vec
├── util
│   └── util_pkg
└── vendor
    ├── GHDL_test
    └── Xilinx
        └── GlitchFreeBUFGCE
```

## Testing / Verification

### VUnit Regression Tests

Run `$ python3 run.py` (or `$ python3 run.py -v` for verbose logging from testbench outputs) to kick off VUnit regression tests.

### Git Hooks

Install `scripts/pre-hook` to `.git/hooks/` (or [another directory if in a submodule](https://stackoverflow.com/a/15146529)) to auto-generate [TODO list](TODO_list.md) and [git metadata package](util/hdl_lib_git_info.pkg) when committing to git repo.


