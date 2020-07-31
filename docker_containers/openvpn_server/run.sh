#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break

    sleep 1

done

openvpn --dev tun0 --ifconfig 10.1.10.1 10.1.10.2 --cipher AES-256-CBC --secret key.secret &

#brctl addbr bridge0
#ifconfig eth0 down
#ifconfig tun0 down
#brctl addif bridge0 eth0 tun0
#ifconfig eth0 up
#ifconfig tun0 up
#ifconfig bridge0 up

iptables -t nat -A POSTROUTING -s 10.1.10.2 -o eth0 -j MASQUERADE

/bin/bash
