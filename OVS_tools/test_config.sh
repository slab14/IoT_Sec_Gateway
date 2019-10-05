#!/bin/bash

sudo ovs-vsctl --may-exist add-port br0 enp6s0f0 -- set Interface enp6s0f0 ofport_request=1
sudo ovs-vsctl --may-exist add-port br0 enp6s0f1 -- set Interface enp6s0f1 ofport_request=2

sudo ovs-ofctl del-flows br0

#sudo ovs-ofctl add-flow br0 "in_port=1, actions=verify,2"
#sudo ovs-ofctl add-flow br0 "in_port=2, actions=1"
