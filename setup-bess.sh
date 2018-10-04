#!/bin/bash

install_docker() {
    sudo apt-get update -qq
    sudo apt-get install -yqq docker-compose
    sudo apt-get install -yqq apt-transport-https ca-certificates \
	 curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -qq
    sudo apt-get install -yqq docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
}

sudo apt-get update -qq
apt-get install -yqq software-properties-common
## Ubuntu 18
#sudo apt-get install -yqq make apt-transport-https ca-certificates g++ make pkg-config libunwind8-dev liblzma-dev zlib1g-dev libpcap-dev libssl-dev libnuma-dev git python python-pip python-scapy libgflags-dev libgoogle-glog-dev libgraph-easy-perl libgtest-dev libgrpc++-dev libprotobuf-dev libc-ares-dev libbenchmark-dev libgtest-dev protobuf-compiler-grpc dpdk-igb-uio-dkms

## Ubuntu 16
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt-get update -qq
sudo apt-get install -yqq apt-transport-https ca-certificates g++ make \
     libunwind8-dev liblzma-dev zlib1g-dev libpcap-dev libnuma-dev libgflags-dev \
     libgoogle-glog-dev libgtest-dev python pkg-config autoconf libtool cmake clang\
     libc++-dev python-pip software-properties-common python-software-properties g++-7 \
     libssl-dev libc-ares-dev libprotobuf-dev

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 \
     --slave /usr/bin/g++ g++ /usr/bin/g++-7
sudo update-alternatives --config gcc

cd /tmp
git clone https://github.com/google/grpc.git
cd grpc
git checkout v1.3.2
git submodule update --init
make -j `nproc` EXTRA_CFLAGS='-Wno-error' HAS_SYSTEM_PROTOBUF=false
sudo make install
cd third_party/protobuf
sudo make install
cd ../benchmark
cmake .
sudo make install
sudo ldconfig

sudo apt-get install -yqq libgraph-easy-perl tcpdump
#pip install --upgrade pip
pip install --user protobuf
pip install --user grpcio
pip install --user scapy

cd ~
git clone https://github.com/NetSys/bess.git

##Note that this action must be done every time the machine is started
# Single Node:
#sudo sysctl vm.nr_hugepages=1024
# For multi-node (NUMA) systems
echo 1024 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 1024 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages
sudo mkdir /mnt/huge
sudo mount -t hugetlbfs nodev /mnt/huge

cd bess
./build.py

## Ubuntu 18
#sudo modprobe igb_uio
## Ubuntu 16
sudo modprobe uio
sudo insmod deps/dpdk-17.11/build/kmod/igb_uio.ko 

## Place interfaces to be used by DPDK down
## Then bind interface to DPDK
IFACES=$(ifconfig -a | grep enp | awk -F ' ' '{ print $1 }')

for IFACE in $IFACES; do
    IP=$(ifconfig $IFACE | grep "inet addr" | awk -F ' ' '{ print $2 }' | awk -F ':' '{ print $2 }')
    testVal=$( echo $IP | awk -F '.' '{ print $1 }' )
    if [[ "$testVal" -eq 128 ]]; then
	echo "skip"
    else
	sudo ifconfig $IFACE down
	DPDK_ID=$( bin/dpdk-devbind.py --status | grep $IFACE | awk -F ' ' '{ print $1 }' | awk -F ':' '{ print $2":"$3 }')
	echo $DPDK_ID
	sudo bin/dpdk-devbind.py -b igb_uio $DPDK_ID
    fi
done

## Python dependencies
python -m pip install grpcio
python -m pip install grpcio-tools

cp /users/slab/IoT_Sec_Gateway/bess_conf/McBridge.bess /users/slab/bess/bessctl/conf/
cp /users/slab/IoT_Sec_Gateway/bess_conf/ContBridge.bess /users/slab/bess/bessctl/conf/


#install_docker

## Instructions on starting up BESS
# cd bess/bessctl
# ./bessctl
# daemon start
# run McBridge

