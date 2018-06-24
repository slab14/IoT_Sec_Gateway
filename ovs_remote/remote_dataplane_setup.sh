#!/bin/bash

IP=$1
USERNAME=$2
OVS_PORT=$3

BRIDGE_NAME=br0
CLIENT_SIDE_IP=192.1.1.1
SERVER_SIDE_IP=10.1.1.1

find_interface_for_ip() {
    local ip="$1"

    local vals=`ssh $USERNAME@$IP 'ip -o addr'`
    local interface=$("$vals" | grep "inet $ip" | awk -F ' ' '{ print $2 }')
    if [[ -z $interface ]]; then
	return 1
    else
	echo $interface
	return 0
    fi
}

disable_gro() {
    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    local server_side_if=$(find_interface_for_ip $SERVER_SIDE_IP)
    ssh $USERNAME@$IP 'sudo ethtool -K '"$client_side_if"' gro off; sudo ethtool -K '"$server_side_if"' gro off'
}

setup_bridge() {
    echo "Setting up basic Bridge..."
    sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --may-exist add-br $BRIDGE_NAME
    ssh $USERNAME@$IP sudo ip link set $BRIDGE_NAME up

    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    local server_side_if=$(find_interface_for_ip $SERVER_SIDE_IP)

    sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --may-exist add-port $BRIDGE_NAME $client_side_if \
	 -- set Interface $client_side_if ofport_request=1
    sudo ovs-ofctl --db=tcp:$IP$OVS_PORT mod-port $BRIDGE_NAME $client_side_if up

    sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --may-exist add-port $BRIDGE_NAME $server_side_if \
	 -- set Interface $server_side_if ofport_request=2
    sudo ovs-ofctl --db=tcp:$IP_$OVS_PORT mod-port $BRIDGE_NAME $server_side_if up
    echo "Bridge Setup Complete"
}

disable_gro
setup_bridge
echo "remote bridge setup"



