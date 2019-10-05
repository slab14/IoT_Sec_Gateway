#!/bin/bash

IMAGE=$1
BRIDGE="br0"
NAME="demo"

sudo docker run -itd --rm --network=none --cap-add=NET_ADMIN --name=$NAME $IMAGE

sudo ovs-docker add-port $BRIDGE eth0 $NAME
sudo ovs-docker add-port $BRIDGE eth1 $NAME
