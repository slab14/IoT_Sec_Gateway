#!/bin/bash

BRIDGE=$1
CONT1=$2
CONT2=$3

sudo ovs-docker del-ports $BRIDGE $CONT1
sudo ovs-docker del-ports $BRIDGE $CONT2

sudo docker kill $CONT1 $CONT2

sudo ovs-vsctl del-br $BRIDGE
