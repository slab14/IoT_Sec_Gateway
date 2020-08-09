#!/bin/bash

/usr/share/openvswitch/scripts/ovs-ctl start
ovs-vsctl add-br br0

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break

    sleep 1

done

ovs-vsctl add-port br0 eth0
ovs-vsctl add-port br0 eth1
ovs-ofctl add-flow br0 "in_port=1 actions=2"
ovs-ofctl add-flow br0 "in_port=2 actions=1"

/bin/bash
