#!/bin/bash

sudo ovs-vsctl --may-exist add-br demo
sudo docker run -itd --name snort-demo --privileged snort-container
sudo ovs-docker add-port demo eth1 snort-demo
sudo ovs-docker add-port demo eth2 snort-demo
