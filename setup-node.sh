#!/bin/bash

# Script to setup "node" for generating/sinking IP data traffic
## Asumes on a Ubuntu machine ##

#borrowed from Jeff Helt

CLIENT_IP=192.1.1.2
SERVER_IP=10.1.1.2

update() {
    echo "Updating apt-get..."
    sudo apt-get -qq update
    echo "Update Complete"
}


install_iperf() {
    echo "Installing iperf..."
    sudo apt-get -yqq install iperf3
    echo "iperf Install Complete"
}

install_python_packages() {
    echo "Installing Python..."
    sudo apt-get -yqq install python python-dev python-pip
    sudo pip -qq install --upgrade pip
    sudo pip -qq install ipaddress subprocess32
    echo "Python Instll Complete"
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

ip2int() {
    local a b c d
    { IFS=. read a b c d; } <<< $1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

int2ip() {
    local ui32=$1; shift
    local ip n
    for n in 1 2 3 4; do
	ip=$((ui32 & 0xff))${ip:+.}$ip
	ui32=$((ui32 >> 8))
    done
    echo $ip
}

network() {
    local addr=$(ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    int2ip $((addr & mask))
}


setup_ip_routes() {
    local interface=$(find_interface_for_ip $CLIENT_IP \
			  || find_interface_for_ip $SERVER_IP)

    if find_interface_for_ip $CLIENT_IP; then
	local ip=$SERVER_IP
    else
	local ip=$CLIENT_IP
    fi

    local net=$(network $ip 16)
    sudo ip route add $net/16 dev $interface \
	|| sudo ip route change $net/16 dev $interface
}

# Install packages
echo "Beginning Node Setup..."
update
install_iperf
install_python_packages
setup_ip_routes
echo "Node Setup Complete"
