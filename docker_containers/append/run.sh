#!/bin/bash

gcc -O1 -o packetScript packetAppend.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto

gcc -O1 -o checkHash checkHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto
gcc -O1 -o addHash addHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto

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
ifconfig eth0 mtu 1520
ifconfig eth1 mtu 1520

#Send packets to NFQUEUE
iptables -t raw -A PREROUTING -i eth0 -d 10.1.1.2 -j NFQUEUE --queue-num 2
iptables -t raw -A PREROUTING -i eth1 -d 10.1.1.2 -j NFQUEUE --queue-num 1

#python -O pyscript.py

#./packetScript

./checkHash &
./addHash
