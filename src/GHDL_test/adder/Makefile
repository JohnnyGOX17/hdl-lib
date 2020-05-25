all:
	ghdl -a *.vhd
	ghdl -e tb_adder
	ghdl -r tb_adder --wave=output.ghw
	gtkwave output.ghw

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f *.ghw
	rm -f tb_adder
