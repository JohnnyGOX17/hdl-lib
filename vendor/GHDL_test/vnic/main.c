#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <netinet/if_ether.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

extern int ghdl_main(int argc, char **argv);

static int32_t *p_rx;
static int32_t *p_tx;
static const size_t mem_length = 65536;

int sd_rx;
int sd_tx;
int net_ifindex;

uint64_t F_get_p_rx() {
	return *(uint64_t*)&p_rx;
}

uint64_t F_get_p_tx() {
	return *(uint64_t*)&p_tx;
}

/* returns 0 if successful, any other return value is an error */
uint32_t F_send_pkt(size_t tx_length) {
	struct sockaddr_ll saddr_ll;
	saddr_ll.sll_ifindex = net_ifindex;
	saddr_ll.sll_halen = ETH_ALEN;

	int send_len = sendto(sd_tx, p_tx, tx_length, 0, (const struct sockaddr*)&saddr_ll, sizeof(struct sockaddr_ll));
	if (send_len < 0) {
		perror("Error sending packet!\n");
		return 1;
	}
	return 0;
}

/* receives data into RX buffer and returns number of bytes received
 * 0 == error
 */
uint32_t F_receive_pkt() {
	struct sockaddr saddr;
	int saddr_len = sizeof(saddr);
	/* receive network packet into buffer (will block until a packet is received) */
	int rx_len = recvfrom(sd_rx, p_rx, mem_length, 0, &saddr, (socklen_t *)&saddr_len);
	if (rx_len < 0) {
		perror("Error opening raw socket\n");
		return 0;
	}
	return rx_len;
}

int main(int argc, char **argv) {

	/* setup TX net dev */
	if (argc != 2) {
		fprintf(stderr, "Error: Must pass one net interface name. Example:\n"
				"\t$ tb_vnic eth0\n");
		return -1;
	}


	/* allocate some memory for RX and TX buffers */
	p_rx = mmap(NULL, mem_length, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_SHARED, -1, 0);
	if ((int*)p_rx == (int*)-1) {
		perror("mmap() of RX buffer failed!\n");
		return -1;
	}
	p_tx = mmap(NULL, mem_length, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_SHARED, -1, 0);
	if ((int*)p_tx == (int*)-1) {
		perror("mmap() of TX buffer failed!\n");
		return -1;
	}
	memset(p_rx, 0, mem_length);
	memset(p_tx, 0, mem_length);


	/* setup raw sockets for TX & RX */
	sd_rx = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
	if (sd_rx < 0) {
		perror("Error openning raw socket! Make sure this is launched with root priviliges\n");
		return -1;
	}
	sd_tx = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
	if (sd_tx < 0) {
		perror("Error openning raw socket! Make sure this is launched with root priviliges\n");
		return -1;
	}

	/* Get if_index */
	struct ifreq ifreq_i;
	memset(&ifreq_i, 0, sizeof(ifreq_i));
	strncpy(ifreq_i.ifr_name, argv[1], IFNAMSIZ-1);

	if (ioctl(sd_tx, SIOCGIFINDEX, &ifreq_i) < 0) {
		perror("Error trying to find net device index\n");
		return -1;
	}
	net_ifindex = ifreq_i.ifr_ifindex;
	printf("Netdev index for %s: %d\n", argv[1], net_ifindex);


	/* this app is new main, invoke testbench by calling into ghdl_main */
	printf("\tStarting GHDL simulation...\n");
	int gargc = argc - 1; /* don't use netdev name in ghdl */
	int ghdl_status = ghdl_main(gargc, argv);

	printf("\tSimulation done!\n");

	/* cleanup */
	close(sd_rx);
	close(sd_tx);
	munmap(p_rx, mem_length);
	munmap(p_tx, mem_length);
	return ghdl_status;
}
