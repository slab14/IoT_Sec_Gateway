#!/bin/bash

sudo ovs-docker del-ports br0 pingdetectclickbridge0
sudo ovs-docker del-ports br0 pingdetectclickbridge1

sudo docker kill pingdetectclickbridge0 pingdetectclickbridge1

sudo ovs-vsctl del-br br0
sudo ovs-vsctl add-br br0

sudo ovs-vsctl --may-exist add-port br0 enp6s0f0 -- set Interface enp6s0f0 ofport_request=1
sudo ovs-vsctl --may-exist add-port br0 enp6s0f1 -- set Interface enp6s0f1 ofport_request=2
