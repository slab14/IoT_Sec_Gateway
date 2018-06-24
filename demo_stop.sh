#!/bin/bash

# VARIABLES
BRIDGE="demo_ovs_br"
INTERFACE="eth0"
NAME="demo_cont"
IP=$1
DOCKER_PORT=$2
OVS_PORT=$3
BRIDGE_REMOTE_PORT=6633

# Kill Container
curl -s -X POST http://$IP:$DOCKER_PORT/v1.37/containers/$NAME/kill

# Delete OVS-Docker ports
./ovs-docker-remote del-ports $BRIDGE $NAME $IP $OVS_PORT $DOCKER_PORT

# Delete flows
sudo ovs-ofctl del-flows tcp:$IP:$BRIDGE_REMOTE_PORT

# Delete bridge
sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --if-exists del-br $BRIDGE
