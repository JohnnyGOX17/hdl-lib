TARGET_real=tb_dot_product_real
TARGET_cmplx=tb_dot_product_cmplx

all:
	ghdl -a --std=08 ../../../../util/util_pkg.vhd ../../../arithmetic/complex_multiply/hdl/complex_multiply_mult4.vhd ../../../arithmetic/adder_tree/hdl/adder_tree.vhd ../hdl/dot_product_real.vhd ../hdl/dot_product_cmplx.vhd ./tb_dot_product_real.vhd ./tb_dot_product_cmplx.vhd
	ghdl -e --std=08 $(TARGET_real)
	ghdl -e --std=08 $(TARGET_cmplx)
	ghdl -r $(TARGET_real)
	ghdl -r $(TARGET_cmplx)

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f *.ghw
	rm -f $(TARGET_real)
	rm -f $(TARGET_cmplx)
