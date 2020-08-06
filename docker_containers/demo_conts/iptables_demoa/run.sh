#!/bin/bash

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto

while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
	break
    sleep 1
done

#setup bridge
brctl addbr bridge0
ifconfig eth1 down
ifconfig eth2 down
brctl addif bridge0 eth1 eth2
ifconfig eth1 up
ifconfig eth2 up
ifconfig bridge0 up

#maps to policy
touch ID
echo $PROTECTION_ID > ID

#iptables -A FORWARD -p icmp -s 10.1.1.0/24 -j NFLOG --nflog-prefix "iptables: " --nflog-group 1

# run iptables rules from controller
while ![ -f setup_iptables.sh]; do
    sleep 1
done
chmod +x setup_iptables.sh
./setup_iptables.sh


service ulogd2 start
python getAlerts.py &

/bin/bash
