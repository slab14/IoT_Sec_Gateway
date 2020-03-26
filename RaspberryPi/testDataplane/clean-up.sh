#!/bin/bash

BRIDGE=br0

CONTAINER_NAMES=$(sudo docker ps -a --format {{.Names}})

for NAME in $CONTAINER_NAMES; do
    sudo ovs-docker del-ports $BRIDGE $NAME
done
sudo docker kill $(sudo docker ps -a -q)
sudo ovs-ofctl -OOpenflow13 del-flows br0
				    
