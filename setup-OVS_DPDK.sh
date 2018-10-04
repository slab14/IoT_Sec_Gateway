#!/bin/bash

OSver=$(uname -r | awk -F '-' '{ print $1 }')

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

sudo apt-get update
sudo apt-get install -yqq build-essential linux-headers-`uname -r` libnuma-dev

cd ~
git clone http://dpdk.org/git/dpdk
cd dpdk
git checkout v17.11-rc3
export DPDK_DIR=`pwd`/build
make config T=x86_64-native-linuxapp-gcc
sed -ri 's,(PMD_PCAP=).*,\1y,' build/.config
make

sudo modprobe uio
sudo insmod build/kmod/igb_uio.ko

# Configure hugepages
echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
sudo mkdir /mnt/huge
sudo mount -t hugetlbfs nodev /mnt/huge

IFACES=$(ifconfig -a | grep enp | awk -F ': ' '{ print $1 }')
for IFACE in $IFACES; do
        IP=$(ifconfig $IFACE | grep "inet addr" | awk -F ' ' '{ print $2 }' | awk -F ':' '{ print $2 }')
	testVal=$( echo $IP | awk -F '.' '{ print $1 }' )
	if [[ "$testVal" -eq 128 ]]; then
	    echo "skip"
	else
	    sudo ifconfig $IFACE down
	    DPDK_ID=$( bin/dpdk-devbind.py --status | grep $IFACE | awk -F ' ' '{ print $1 }' | awk -F ':' '{ print $2":"$3 }')
	    sudo bin/dpdk-devbind.py -b igb_uio $DPDK_ID
	fi
done

sudo apt-get install -yqq make gcc libssl1.0.2 libssl1.0-dev \
	 libcap-ng0 libcap-ng-dev python python-pip autoconf \
	 libtool wget netcat curl clang sparse flake8 \
	 graphviz autoconf automake libtool python-dev python-pip
#    sudo pip -qq install --upgrade pip
pip -qq install --user six pyftpdlib tftpy

cd ~
git clone https://github.com/slab14/ovs.git
cd ovs
git checkout slab
./boot.sh
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-dpdk=$DPDK_DIR
make
sudo make install
cd ~

export PATH=$PATH:/usr/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
sudo /usr/share/openvswitch/scripts/ovs-ctl start
sudo ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true

## Setup bridge
sudo ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev
sudo ovs-vsctl add-port br0 port1 -- set Interface port1 type=dpdk options:dpdk-devargs=0000:5e:00.0
sudo ovs-vsctl add-port br0 port2 -- set Interface port2 type=dpdk options:dpdk-devargs=0000:5e:00.1

CHECK_DOCKER=$(which docker)
if [[ -z CHECK_DOCKER ]]; then
    install_docker
fi
if [[ "$OSver" = "4.15.0" ]]; then
    sudo systemctl disable apparmor.service --now
    sudo service apparmor teardown
fi

