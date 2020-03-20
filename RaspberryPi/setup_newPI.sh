#!/bin/bash

BRIDGE_NAME=br0

OVS_PORT=6677
DOCKER_PORT=4243

update() {
    echo "Updating apt-get..."
    sudo apt-get update -qq
    sudo apt-get install -yqq python python-dev python-pip emacs vim \
	 iperf3 nmap python-ipaddress python-subprocess32 \
	 apt-transport-https ca-certificates \
	 docker openvswitch-common openvswitch-switch openvswitch-dbg \
	 isc-dhcp-server tcpdump wavemon netcat hping3 
    
    echo "Update complete"
}

install_docker() {
    echo "Installing Docker..."

    #Get Docker
    curl -sSL https://get.docker.com | sh
    cd /usr/bin
    sudo wget https://raw.githubusercontent.com/openvswitch/ovs/master/utilities/ovs-docker
    sudo chmod a+rwx ovs-docker   

    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker Install Complete"
}

build_docker_containers(){
    echo "Building Snort ICMP Packet Warning Container"
    sudo docker build -t="snort_icmp_alert" docker_containers/snort_icmp_alert
    sudo docker build -t="snort_icmp_block" docker_containers/snort_icmp_block
    echo "Docker containers built"
}

install_ovs() {
    echo "Installing OVS..."
    sudo apt-get install -yqq openvswitch-common openvswitch-switch \
	 openvswitch-dbg
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch
    echo "OVS Install Complete"
}

install_ovs_fromGit() {
    #Install Build Dependencies
    sudo apt-get update -qq
    sudo apt-get install -yqq make gcc \
	 libcap-ng0 libcap-ng-dev python python-pip autoconf \
	 libtool wget netcat curl clang sparse flake8 \
	 graphviz automake python-dev python3-pip \
	 graphviz build-essential pkg-config \
         libssl-dev gdb linux-headers-`uname -r`
    sudo pip3 -qq install --upgrade pip
    pip -qq install --user six pyftpdlib tftpy flake8 sparse

    #Clone repository, build, and install
    cd ~
    git clone https://github.com/slab14/ovs.git
    cd ovs
    git checkout slab
    ./boot.sh
    ./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
    make
    sudo make install
    cd ~

    # Install ovs-docker-remote dependencies
    sudo apt-get install -yqq jq curl uuid-runtime

    # Start OVS Deamons
    sudo /usr/share/openvswitch/scripts/ovs-ctl start --system-id
}

setup_remote_ovsdb_server() {
    sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:$OVS_PORT
}

setup_remote_docker() {
    sudo sed -i 's/fd\:\/\// fd\:\/\/ \-H tcp\:\/\/0\.0\.0\.0\:'"$DOCKER_PORT"'/g' /lib/systemd/system/docker.service
    sudo systemctl daemon-reload
    sudo service docker restart
}


setup_interfaces(){
    sudo cp /etc/network/interfaces /etc/network/interfaces-orig
    sudo touch /etc/network/interfaces-gateway
    sudo sh -c 'echo "auto lo
iface lo inet loopback 

auto eth0

auto eth1
iface eth1 inet static
      address 10.10.1.1
      netmask 255.255.255.0

auto eth2
iface eth2 inet static
      address 10.10.2.2
      netmask 255.255.255.0
" > /etc/network/interfaces-gateway'
    sudo cp /etc/network/interfaces-gateway /etc/network/interfaces
}


setup_bridge() {
    echo "Setting up basic Bridge..."
    sudo ovs-vsctl --may-exist add-br $BRIDGE_NAME
    sudo ip link set $BRIDGE_NAME up

    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME eth1 \
	 -- set Interface eth1 ofport_request=1
    sudo ovs-ofctl mod-port $BRIDGE_NAME eth1 up

    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME eth2 \
	 -- set Interface eth2 ofport_request=2
    sudo ovs-ofctl mod-port $BRIDGE_NAME eth2 up
    echo "Bridge Setup Complete"
}

configure_ovs_switch() {
    #sudo ovs-vsctl set-controller $BRIDGE_NAME tcp:127.0.0.1:6633 ptcp:6634
    sudo ovs-vsctl set-fail-mode $BRIDGE_NAME secure
    sudo ovs-ofctl add-flow $BRIDGE_NAME "in_port=1 actions=2"
    sudo ovs-ofctl add-flow $BRIDGE_NAME "in_port=2 actions=1"
}


# Install packages
echo "Beginning Dataplane Setup..."
update
install_docker
install_ovs_fromGit
#setup_remote_ovsdb_server
#setup_remote_docker
    
# Setup
setup_interfaces
#disable_gro
setup_bridge
configure_ovs_switch
echo "Dataplane Ready"
