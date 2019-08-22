#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break

    sleep 1

done

if [ -z "$IN_VLAN" ]; then
    IN_VLAN="9"
fi

if [ -z "$OUT_VLAN" ]; then
    OUT_VLAN="9"
fi

brctl addbr bridge0
brctl addbr bridge1
ifconfig eth0 down
ifconfig eth1 down
ip link add link eth0 name eth0.1 type vlan id $OUT_VLAN
ip link add link eth1 name eth1.1 type vlan id $IN_VLAN
brctl addif bridge0 eth0 eth1.1
brctl addif bridge1 eth0.1 eth1
ifconfig eth0 up
ifconfig eth0.1 up
ifconfig eth1 up
ifconfig eth1.1 up
ifconfig bridge0 up
ifconfig bridge1 up


/bin/bash
