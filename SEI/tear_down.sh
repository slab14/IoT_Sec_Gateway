#!/bin/bash

BRIDGE=`sudo ovs-vsctl show | grep Bridge | awk -F 'Bridge ' '{ print $2 }'`
sudo ovs-docker del-ports $BRIDGE demo_container
sudo docker kill $(sudo docker ps -a -q)
sudo ovs-ofctl del-flows $BRIDGE
sudo ovs-vsctl del-br $BRIDGE

#sudo ifconfig enp1s0 10.1.1.2/24 up


