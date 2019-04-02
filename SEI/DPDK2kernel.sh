#!/bin/bash

BRIDGE_NAME=br0
CLIENT_SIDE_IP=10.1.1.2
SERVER_SIDE_IP=10.1.1.10
CONTAINER_NAME=demo_container
CONT_IMAGE=iperf3_container
BRIDGE=`sudo ovs-vsctl show | grep Bridge | awk -F 'Bridge "' '{ print $2 }' | awk -F '"' '{ print $1 }'`
sudo ovs-docker del-ports $BRIDGE $CONTAINER_NAME
sudo ovs-ofctl del-flows $BRIDGE
sudo ovs-vsctl del-br $BRIDGE
sudo docker kill $CONTAINER_NAME
export PATH=$PATH:/usr/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
sudo /usr/share/openvswitch/scripts/ovs-ctl restart
sudo ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=false

cd ~/dpdk
DPDK_ID=$(./usertools/dpdk-devbind.py --status | grep XL710 | awk -F ' ' '{ print $1 }' | awk -F ':' '{ print $2":"$3 }')
sudo ./usertools/dpdk-devbind.py -u $DPDK_ID
sudo ./usertools/dpdk-devbind.py -b i40e $DPDK_ID

sudo ifconfig enp1s0 $CLIENT_SIDE_IP/24 up
sudo ethtool -K enp1s0 gro off

sudo ovs-vsctl --may-exist add-br $BRIDGE_NAME
sudo ip link set $BRIDGE_NAME up

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

client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    
sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $client_side_if \
     -- set Interface $client_side_if ofport_request=1
sudo ovs-ofctl mod-port $BRIDGE_NAME $client_side_if up

sudo docker run -itd --rm --network=none --privileged --name=$CONTAINER_NAME -p 5101:5101 -p 5102:5102 $CONT_IMAGE
sudo ovs-docker add-port $BRIDGE_NAME eth0 $CONTAINER_NAME --ipaddress=$SERVER_SIDE_IP/24

OVS_PORT=`sudo ovs-vsctl --data=bare --no-heading --columns=name find \
	 interface external_ids:container_id=$CONTAINER_NAME \
	 external_ids:container_iface=eth0`
OF_PORT=`sudo ovs-ofctl show $BRIDGE_NAME | grep $OVS_PORT | awk -F '(' '{ print $1 }' | awk -F ' ' '{ print $1 }'`
sudo ovs-ofctl del-flows $BRIDGE_NAME
sudo ovs-ofctl add-flow $BRIDGE_NAME "priority=100 in_port=1 actions=output:$OF_PORT"
sudo ovs-ofctl add-flow $BRIDGE_NAME "priority=100 in_port=$OF_PORT actions=output:1"
