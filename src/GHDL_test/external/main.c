#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

extern int ghdl_main (int argc, char **argv);

uint32_t ext_add(uint32_t num1, uint32_t num2) {
	return (num1 + num2);
}

int main(int argc, char **argv) {

	// optional SW app can parse inputs
	int gargc = argc;
	char **gargv = argv;

	// this app is new main, invoke testbench by calling into ghdl_main
	ghdl_main(gargc, gargv);

	return 0;
}
