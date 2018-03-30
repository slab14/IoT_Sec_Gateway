#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break

    sleep 1

done

brctl addbr bridge0
ifconfig eth0 down
ifconfig eth1 down
brctl addif bridge0 eth0 eth1
ifconfig eth0 up
ifconfig eth1 up
ifconfig bridge0 up
#ip link set dev bridge0 up

#sysctl -w net.ipv4.ip_forward=1 
#iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT 
#iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

/bin/bash
