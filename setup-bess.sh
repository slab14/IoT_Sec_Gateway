#!/bin/bash

sudo apt-get update
sudo apt-get install -yqq make apt-transport-https ca-certificates g++ make pkg-config libunwind8-dev liblzma-dev zlib1g-dev libpcap-dev libssl-dev libnuma-dev git python python-pip python-scapy libgflags-dev libgoogle-glog-dev libgraph-easy-perl libgtest-dev libgrpc++-dev libprotobuf-dev libc-ares-dev libbenchmark-dev libgtest-dev protobuf-compiler-grpc dpdk-igb-uio-dkms

cd ~
git clone https://github.com/NetSys/bess.git

##Note that this action must be done every time the machine is started
# Single Node:
#sudo sysctl vm.nr_hugepages=1024
# For multi-node (NUMA) systems
echo 1024 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 1024 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages

cd bess
./build.py

## Determine if name (not hardcoded)
sudo ifconfig enp94s0f0 down
sudo ifconfig enp94s0f1 down

sudo modprobe igb_uio
## Determine ID (not hardcoded)
sudo bin/dpdk-devbind.py -b igb_uio 5e:00.0 5e:00.1

## Python dependencies
python -m pip install grpcio
python -m pip install grpcio-tools


## Instructions on starting up BESS
# cd bess/bessctl
# ./bessctl
# daemon start
# run McBridge
