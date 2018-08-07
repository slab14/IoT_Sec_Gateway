#!/bin/bash

BRIDGE=$1

if [ -z $BRIDGE ]; then
    BRIDGE=br0
fi

# Setting to make vswitch (br0) listen for commands from controller
sudo ovs-vsctl set-controller $BRIDGE tcp:127.0.0.1:6633 ptcp:6634
sudo ovs-vsctl set bridge $BRIDGE protocol=OpenFlow13
sudo ovs-vsctl set-fail-mode $BRIDGE secure
