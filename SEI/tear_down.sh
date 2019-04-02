#!/bin/bash

BRIDGE=`sudo ovs-vsctl show | grep Bridge | awk -F 'Bridge ' '{ print $2 }' | awk -F '"' '{ print $1 }'`
sudo ovs-docker del-ports $BRIDGE demo_container
sudo docker kill $(sudo docker ps -a -q)
sudo ovs-ofctl del-flows $BRIDGE
sudo ovs-vsctl del-br $BRIDGE

#cd ~/dpdk
#DPDK_ID=$(./usertools/dpdk-devbind.py --status | grep XL710 | awk -F ' ' '{ print $1 }' | awk -F ':' '{ print $2":"$3 }')
#sudo ./usertools/dpdk-devbind.py -u $DPDK_ID
#sudo ./usertools/dpdk-devbind.py -b i40e $DPDK_ID
#sudo ifconfig enp1s0 10.1.1.2/24 up


