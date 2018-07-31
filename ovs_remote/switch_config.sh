#!/bin/bash

# Setting to make vswitch (br0) listen for commands from controller
sudo ovs-vsctl set-controller br0 tcp:127.0.0.1:6633 ptcp:6634
sudo ovs-vsctl set bridge br0 protocol=OpenFlow13
sudo ovs-vsctl set-fail-mode br0 secure
