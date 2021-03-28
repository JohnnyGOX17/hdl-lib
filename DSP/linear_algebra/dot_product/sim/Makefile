TARGET=tb_dot_product_real

all:
	ghdl -a --std=08 ../../../../util/util_pkg.vhd ../../../arithmetic/adder_tree/hdl/adder_tree.vhd ../hdl/dot_product_real.vhd ./tb_dot_product_real.vhd
	ghdl -e --std=08 $(TARGET)
	ghdl -r $(TARGET)

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f *.ghw
	rm -f $(TARGET)
