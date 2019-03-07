#!/bin/bash

BRIDGE_NAME='brDPDK'
SERVER_SIDE_IP=10.1.1.10
CONT_NAME='demo_container'
CONT_IMAGE='iperf3_container'

OSver=$(uname -r | awk -F '-' '{ print $1 }')
InitDir=$(pwd)

install_docker() {
    echo "Installing Docker"
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
    echo "Docker installed"
}

update() {
    "Performing a packet update"
    sudo apt-get update
    sudo apt-get install -yqq build-essential linux-headers-`uname -r` libnuma-dev libpcap-dev
    echo "Packages updated"
}

get_DPDK() {
    echo "Installing DPDK"
    cd ~
    git clone http://dpdk.org/git/dpdk
    cd dpdk
    git checkout v18.11
    export DPDK_DIR=`pwd`/build
    make config T=x86_64-native-linuxapp-gcc
    sed -ri 's,(PMD_PCAP=).*,\1y,' build/.config
    make

    echo "DPDK installed"
}


setup_DPDK_interfaces() {
    echo "Setting up physical interfaces to use DPDK"
    cd ~/dpdk
    
    sudo modprobe uio
    #sudo modprobe uio_pci_generic
    #sudo modprobe vfio-pci
    sudo insmod build/kmod/igb_uio.ko

    # Configure hugepages
    echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
    sudo mkdir /mnt/huge
    sudo mount -t hugetlbfs nodev /mnt/huge

    IFACES=$(ifconfig -a | grep enp1s | awk -F ': ' '{ print $1 }')
    for IFACE in $IFACES; do
	sudo ifconfig $IFACE down
    done
    DPDK_ID=$(./usertools/dpdk-devbind.py --status | grep XL710 | awk -F ' ' '{ print $1 }' | awk -F ':' '{ print $2":"$3 }')
    sudo ./usertools/dpdk-devbind.py -b igb_uio $DPDK_ID
    #sudo ./usertools/dpdk-devbind.py -b uio_pci_generic $DPDK_ID
    #sudo ./usertools/dpdk-devbind.py -b vfio-pci $DPDK_ID
    echo "DPDK physical interface setup. It will no longer show in ifconfig"
}


startup_ovsdb() {
    export PATH=$PATH:/usr/share/openvswitch/scripts
    export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
    sudo /usr/share/openvswitch/scripts/ovs-ctl restart
    sudo ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
}


install_ovs() {
    echo "Installing OVS, with DPDK option selected"
    sudo apt-get install -yqq make gcc libssl1.0.0 libssl-dev \
	 libcap-ng0 libcap-ng-dev python python-pip autoconf \
	 libtool wget netcat curl clang sparse flake8 \
	 graphviz autoconf automake libtool python-dev python-pip \
	 dh-autoreconf
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

    startup_ovsdb
    echo "OVS-DPDK installed"
}


setup_bridge() {
    echo "Setting up OVS bridge"
    ## Ensure that ovsdb is running
    if ! sudo ovs-vsctl show; then
	startup_ovsdb
    fi
    ## Setup bridge
    sudo ovs-vsctl add-br $BRIDGE_NAME -- set bridge $BRIDGE_NAME datapath_type=netdev
    cd ~
    DPDK_ARGS=`./dpdk/usertools/dpdk-devbind.py --status | grep XL710 | awk -F ' ' '{ print $1 }'`
    sudo ovs-vsctl add-port $BRIDGE_NAME port1 -- set Interface port1 type=dpdk options:dpdk-devargs=$DPDK_ARGS ofport_request=1
    # For 2nd physical interface
    #sudo ovs-vsctl add-port $BRIDGE_NAME port2 -- set Interface port2 type=dpdk options:dpdk-devargs=0000:5e:00.1 ofport_request=2
    echo "OVS bridge setup complete"
}

docker_check() {
    CHECK_DOCKER=$(command -v docker)
    if [[ -z CHECK_DOCKER ]]; then
	install_docker
    fi
}

build_docker_containers(){
    echo "Building Iperf3 Container"
    sudo docker pull ubuntu:xenial
    cd $InitDir
    #sudo docker build -t="$CONT_IMAGE" iperf_container/.
    # For SEI proxy
    sudo docker build --build-arg http_proxy=http://proxy.sei.cmu.edu:8080 --build-arg https_proxy=http://proxy.sei.cmu.edu:8080 --build-arg HTTP_PROXY=http://proxy.sei.cmu.edu:8080 --build-arg HTTPS_PROXY=http://proxy.sei.cmu.edu:8080 -t="$CONT_IMAGE" iperf_container/.
    echo "Docker containers built"
}

start_demo_container() {
    echo "Starting a container to receive iperf3 traffic"
    sudo docker run -itd --rm --network=none --name=$CONT_NAME $CONT_IMAGE
    sudo ovs-docker add-port $BRIDGE_NAME eth0 $CONT_NAME --ipaddress=$SERVER_SIDE_IP/24
    echo "iperf3 container up"
}

add_routing() {
    echo "Adding OVS routing rules"
    OVS_PORT=`sudo ovs-vsctl --data=bare --no-heading --columns=name find \
	 interface external_ids:container_id=$CONT_NAME \
	 external_ids:container_iface=eth0`
    OF_PORT=`sudo ovs-ofctl show $BRIDGE_NAME | grep $OVS_PORT | awk -F '(' '{ print $1 }' | awk -F ' ' '{ print $1 }'`
    sudo ovs-ofctl add-flow $BRIDGE_NAME "priority=100 in_port=1 actions=output:$OF_PORT"
    sudo ovs-ofctl add-flow $BRIDGE_NAME "priority=100 in_port=$OF_PORT actions=output:1"
    echo "OVS routes added"
}

update
cd ~
if [ ! -d "dpdk" ]; then
    get_DPDK
fi
if [ ! -d "ovs" ]; then
    install_ovs
fi
setup_DPDK_interfaces
docker_check
build_docker_containers

setup_bridge
start_demo_container
add_routing

echo "Dataplane Ready"
