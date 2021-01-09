CC=gcc
# Treat like shared library
# Use position independent code and export symbols
CFLAGS=-fPIC -rdynamic -Wall
TARGET=tb_vnic

all:
	$(CC) $(CFLAGS) -c main.c -o main.o
	ghdl -a --ieee=synopsys -frelaxed-rules --std=08 *.vhd
	ghdl -e --ieee=synopsys -frelaxed-rules --std=08 -Wl,main.o $(TARGET)
	# set priviliges of tb so it can use raw sockets w/o being launched as root
	sudo setcap cap_net_raw+ep $(TARGET)

clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.lst
	rm -f $(TARGET)
