#!/bin/bash

sudo /usr/share/openvswitch/scripts/ovs-ctl start --system-id

sudo ovs-vsctl add-br br0
sudo ovs-vsctl set bridge br0 datapath_type=netdev
sudo ovs-vsctl add-port br0 enp6s0f0
sudo ovs-vsctl add-port br0 enp6s0f1

sudo ovs-ofctl del-flows br0
