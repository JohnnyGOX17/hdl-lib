#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <time.h>

extern int ghdl_main(int argc, char **argv);

static int32_t *p;
static const size_t mem_length = 20;

uint64_t get_p() {
	return *(uint64_t*)&p;
}

uint32_t ext_add(uint32_t num1, uint32_t num2) {
	return (num1 + num2);
}

int main(int argc, char **argv) {

	/* optional SW app can parse inputs */
	int gargc = argc;
	char **gargv = argv;
	int ghdl_status;

	clock_t start_clock = clock();
	clock_t end_clock;

	/* allocate some memory and fill w/data */
	p = mmap(NULL, mem_length, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_SHARED, -1, 0);
	if ((int*)p == (int*)-1) {
		perror("mmap() failed!\n");
		return -1;
	}
	for (int i=0; i < mem_length/4; i++) {
		p[i]=i*2;
		printf("External C Call: Index %d has value %d\n", i, p[i]);
	}

	/* this app is new main, invoke testbench by calling into ghdl_main */
	printf("\tStarting GHDL simulation...\n");
	ghdl_status = ghdl_main(gargc, gargv);

	end_clock = clock() - start_clock;
	printf("\tSimulation time: %ld sec %06ld usec\n",
			end_clock / CLOCKS_PER_SEC,
			end_clock % CLOCKS_PER_SEC);

	/* cleanup */
	munmap(p, mem_length);
	return ghdl_status;
}
