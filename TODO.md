| File | Line | Comment |
| ---- | ---- | ------- |
| [conv2D.vhd](./DSP/filters/conv2D/hdl/conv2D.vhd#L199) | 199 |  wait till parallel adder valid goes low? since we should have stuffed that pipeline |
| [FIR_type_I.vhd](./DSP/filters/FIR/hdl/FIR_type_I.vhd#L78) | 78 |  is this the right order to feed data to match coefs? |
| [sample_covar_matrix.vhd](./DSP/linear_algebra/sample_covar_matrix/hdl/sample_covar_matrix.vhd#L7) | 7 |  use find first set bit in MSB (largest across matrix) to dynamically scale elements to output bitwidth? |
| [sample_covar_matrix.vhd](./DSP/linear_algebra/sample_covar_matrix/hdl/sample_covar_matrix.vhd#L50) | 50 |  double-buffered covar matrix reg's so one can be read out while another is calculated with inputs? |
| [run.py](./run.py#L10) | 10 |  Eventually use blob pattern to include all? -> lib.add_source_files("./vhdl/*/*.vhd") |
