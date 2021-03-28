TARGET=tb_adder_tree

all:
	ghdl -a --std=08 ../../../../util/util_pkg.vhd ../hdl/adder_tree.vhd ../sim/tb_adder_tree.vhd
	ghdl -e --std=08 $(TARGET)
	ghdl -r $(TARGET)

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f *.ghw
	rm -f $(TARGET)
