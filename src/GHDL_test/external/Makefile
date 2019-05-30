CC=gcc

all:
	ghdl -a *.vhd
	$(CC) -fPIC -rdynamic -c main.c -o main.o
	#ghdl --bind tb_ext_add
	#$(CC) main.c -Wl,`ghdl --list-link tb_ext_add`
	ghdl -e -Wl,main.o tb_ext_add

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f tb_ext_add
