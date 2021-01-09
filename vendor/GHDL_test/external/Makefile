CC=gcc
# Treat like shared library
# Use position independent code and export symbols
CFLAGS=-fPIC -rdynamic

all:
	$(CC) $(CFLAGS) -c main.c -o main.o
	ghdl -a *.vhd
	ghdl -e -Wl,main.o tb_ext_add

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f tb_ext_add
