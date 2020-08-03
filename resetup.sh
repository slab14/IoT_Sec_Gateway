#!/bin/bash

#borrowed form Jeff Helt
read -p "Press ENTER if you've already set up the dataplane (press CTRL+C to exit)"

BRIDGE_NAME=br0
CLIENT_SIDE_IP=192.1.1.1
SERVER_SIDE_IP=10.1.1.1

OVS_PORT=6677
DOCKER_PORT=4243

sudo /usr/share/openvswitch/scripts/ovs-ctl start --system-id

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

setup_remote_ovsdb_server() {
    sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:$OVS_PORT
}

disable_gro() {
    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    local server_side_if=$(find_interface_for_ip $SERVER_SIDE_IP)
    sudo ethtool -K $client_side_if gro off
    sudo ethtool -K $server_side_if gro off
}


setup_bridge() {
    echo "Setting up basic Bridge..."
    sudo ovs-vsctl del-br br0
    sudo ovs-vsctl --may-exist add-br $BRIDGE_NAME
    sudo ip link set $BRIDGE_NAME up

    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    local server_side_if=$(find_interface_for_ip $SERVER_SIDE_IP)
    
    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $client_side_if \
	 -- set Interface $client_side_if ofport_request=1
    sudo ovs-ofctl mod-port $BRIDGE_NAME $client_side_if up

    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $server_side_if \
	 -- set Interface $server_side_if ofport_request=2
    sudo ovs-ofctl mod-port $BRIDGE_NAME $server_side_if up
    echo "Bridge Setup Complete"
}

configure_ovs_switch() {
    sudo ovs-vsctl set-controller $BRIDGE_NAME tcp:127.0.0.1:6633 ptcp:6634
    sudo ovs-vsctl set-fail-mode $BRIDGE_NAME secure
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

    # Delete old routes using via
    IFS=$'\n'
    local oldrtes=($(ip route | grep via))
    for i in ${oldrtes[@]}; do
    IFS=$' '
    if [[ $i != *"default"* ]]; then
        sudo ip route del $i
    fi
    done
    
}



# Install packages
echo "Beginning Dataplane Setup..."

setup_remote_ovsdb_server


setup_ip_routes    
# Setup
disable_gro
setup_bridge
configure_ovs_switch
echo "Dataplane Ready"
