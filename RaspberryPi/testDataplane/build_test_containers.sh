#!/bin/bash


# Make container to generate and receive network packets
# This container simulates users/devices
sudo docker build -t iperf iperfCont/

# Make dataplane container, to filter packets
# This one blocks ICMP requests
sudo docker build -t pingblock pingBlockCont/
