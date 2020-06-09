#!/bin/bash

sudo insmod /home/pi/uhcallkmod.ko

sudo /usr/share/openvswitch/scripts/ovs-ctl start --system-id

sudo ovs-docker del-ports br0 demo

sudo ethtool -K eth1 tx off rx off
sudo ethtool -K eth2 tx off rx off

sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6677

sudo ovs-vsctl --may-exist add-br br0
sudo ovs-vsctl --may-exist add-port br0 eth1 -- set Interface eth1 ofport_request=1
sudo ovs-vsctl --may-exist add-port br0 eth2 -- set Interface eth2 ofport_request=2

sudo ovs-vsctl set-controller br0 tcp:127.0.0.1:6633 ptcp:6634
sudo ovs-vsctl set-fail-mode br0 secure
