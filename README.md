# HDL Library


[![](https://github.com/JohnnyGOX17/hdl-lib/workflows/VUnit%20Tests/badge.svg)](https://github.com/JohnnyGOX17/hdl-lib/actions)
![GitHub](https://img.shields.io/github/license/JohnnyGOX17/hdl-lib)

Library of common and re-use components and HDL code.

## Catalog of Components

├── DSP
│   ├── arithmetic
│   │   ├── adder_tree
│   │   ├── complex_MAC
│   │   └── complex_multiply
│   │       ├── hdl
│   │       │   ├── complex_multiply_mult3.vhd
│   │       │   └── complex_multiply_mult4.vhd
│   ├── CORDIC
│   ├── filters
│   │   └── FIR
│   │       └── systolic_FIR.vhd
│   └── linear_algebra
│       ├── dot_product
│       └── sample_covar_matrix
├── IO_interfaces
│   ├── bidir_iobuf.vhd
│   ├── PWM
│   └── seven_seg_disp.vhd
├── memory-FIFO-SRL
│   ├── RAM-ROM
│   │   └── sp_ram.vhd
│   └── shift_reg
│       ├── Makefile
│       ├── static_shift_reg_bit.vhd
│       └── static_shift_reg_vec.vhd
├── util
│   └── util_pkg.vhd
└── vendor
    ├── GHDL_test
    └── Xilinx
        └── GlitchFreeBUFGCE.vhd


## Testing / Verification

### VUnit

Run `python run.py -v`

