TARGET=tb_complex_multiply

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
