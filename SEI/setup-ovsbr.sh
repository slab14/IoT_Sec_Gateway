#!/bin/bash

#borrowed form Jeff Helt

BRIDGE_NAME=br0
CLIENT_SIDE_IP=10.1.1.1
SERVER_SIDE_IP=10.1.1.10
CONT_NAME='demo_container'

update() {
    echo "Updating apt-get..."
    sudo apt-get -qq update
    echo "Update complete"
}

install_docker() {
    echo "Installing Docker..."
    sudo apt-get -yqq install docker-compose 

    sudo apt-get -yqq install apt-transport-https ca-certificates \
	 curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt-get -qq update
    sudo apt-get -yqq install docker-ce

    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker Install Complete"
}

build_docker_containers(){
    echo "Building Iperf3 Container"
    sudo docker build -t="$CONT_NAME" iperf_container/.
    echo "Docker containers built"
}

install_python_packages() {
    echo "Installing Python..."
    sudo apt-get -yqq install python python-ipaddress python-subprocess32 \
	 python-pip
    echo "Python Install Complete"
}

install_ovs() {
    echo "Installing OVS..."
    sudo apt-get -yqq install openvswitch-common openvswitch-switch \
	 openvswitch-dbg
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch
    echo "OVS Install Complete"

}

find_interface_for_ip() {
 local ip="$1"

  local interface=$(ip -o addr | grep "inet $ip" | awk -F ' ' '{ print $2 }')
  if [[ -z $interface ]]; then
    return 1
  else
    echo $interface
    return 0
  fi
}

disable_gro() {
    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    sudo ethtool -K $client_side_if gro off
 }

start_demo_container() {
    echo "Starting a container to receive iperf3 traffic"
    sudo docker -itd --rm --network=none demo_container iperf3_cont
    sudo ovs-docker add-port $BRIDGE_NAME eth0 $CONT_NAME --ipaddress=$SERVER_SIDE_IP/24
}


setup_bridge() {
    echo "Setting up basic Bridge..."
    sudo ovs-vsctl --may-exist add-br $BRIDGE_NAME
    sudo ip link set $BRIDGE_NAME up

    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    
    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $client_side_if \
	 -- set Interface $client_side_if ofport_request=1
    sudo ovs-ofctl mod-port $BRIDGE_NAME $client_side_if up
}

add_routing() {
    OVS_PORT=sudo ovs-vsctl --data=bare --no-heading --columns-name find \
	 interface external_ids:container_id=$CONT_NAME \
	 external_ids:container_iface=eth0

    echo $OVS_PORT

    OF_PORT=sudo ovs-ofctl show $BRIDGE_NAME | grep $OVS_PORT

    echo $OF_PORT
 
    sudo ovs-ofctl add-flow $BRIDGE_NAME "priority=100 in_port=1 actions=output:$OF_PORT"
    sudo ovs-ofctl add-flow $BRIDGE_NAME "priority=100 in_port=$OF_PORT actions=output:1"

    echo "OVS routes added"
}


# Install packages
echo "Beginning Dataplane Setup..."
update
command -v docker >/dev/null 2>&1 || { install_docker; }
command -v ovs-vsctl >/dev/null 2>&1 || { install_ovs; }
build_docker_containers

# Setup
disable_gro
setup_bridge
start_demo_container
add_routing
    
echo "Dataplane Ready"
