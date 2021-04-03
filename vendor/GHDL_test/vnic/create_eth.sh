#!/bin/bash
# from https://unix.stackexchange.com/questions/152331/how-can-i-create-a-virtual-ethernet-interface-on-a-machine-without-a-physical-ad

ethName="eth10"

# load iproute2 dummy driver
if [ -z "$(sudo lsmod | grep dummy)" ]; then
  sudo modprobe dummy
fi

# With the driver loaded create dummy network interface
sudo ip link add $ethName type dummy

