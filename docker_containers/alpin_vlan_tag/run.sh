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
ifconfig eth0 down
ifconfig eth1 down
brctl addif bridge0 eth0 eth1
ifconfig eth0 up
ifconfig eth1 up
ifconfig bridge0 up
tc qdisc add dev eth0 handle 1: root prio
tc filter add dev eth0 parent 1: protocol all basic match 'not meta(protocol eq 0x8100)' action vlan push id $IN_VLAN
tc qdisc add dev eth1 handle 1: root prio
tc filter add dev eth1 parent 1: protocol all basic match 'not meta(protocol eq 0x8100)' action vlan push id $OUT_VLAN

/bin/bash
