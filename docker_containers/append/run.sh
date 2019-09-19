#!/bin/bash

gcc -O1 -o packetScript packetAppend.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto

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

#Send packets to NFQUEUE
iptables -t raw -A PREROUTING -j NFQUEUE --queue-num 1

#python -O pyscript.py

./packetScript
