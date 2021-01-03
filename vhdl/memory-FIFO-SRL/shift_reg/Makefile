TARGET=tb_static_shift_reg_bit

all:
	ghdl -a *.vhd
	ghdl -e $(TARGET)
	ghdl -r $(TARGET) --wave=output.ghw
	gtkwave output.ghw

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f *.ghw
	rm -f $(TARGET)
