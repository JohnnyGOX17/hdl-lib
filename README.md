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

### VUnit

Run `python run.py -v`

