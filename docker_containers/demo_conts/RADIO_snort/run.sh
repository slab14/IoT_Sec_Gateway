#!/bin/bash

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto
gcc -O1 -o checkHash checkHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto
gcc -O1 -o addHash addHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto

# setup alert path to controller
touch ID
echo $PROTECTION_ID > ID
python getAlerts.py &

if [[ ! -s /etc/snort/snort.conf ]]; then
    mv /etc/snort/snort.conf.default /etc/snort/snort.conf
fi

if [[ ! -s /etc/snort/rules/local.rules ]]; then
    mv /etc/snort/rules/local.rules.default /etc/snort/rules/local.rules    
fi

while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
	break
    sleep 1
done

ip link add snort1 type veth peer name snort1_br
ip link add snort2 type veth peer name snort2_br
brctl addbr bridge1
brctl addbr bridge2
ip link set eth1 down
ip link set eth2 down
brctl addif bridge1 eth1 snort1_br
brctl addif bridge2 eth2 snort2_br
ip link set eth1 up mtu 1522
ip link set eth2 up mtu 1522
ip link set snort1 up mtu 1522
ip link set snort1_br up mtu 1522
ip link set snort2 up mtu 1522
ip link set snort2_br up mtu 1522
ip link set bridge1 up
ip link set bridge2 up

# setup packet signature actions
#iptables -t raw -A PREROUTING -i bridge1 -j NFQUEUE --queue-num 1
#iptables -t filter -A FORWARD -i bridge1 -j NFQUEUE --queue-num 2
#iptables -t raw -A PREROUTING -i bridge2 -j NFQUEUE --queue-num 1
#iptables -t filter -A FORWARD -i bridge2 -j NFQUEUE --queue-num 2
#./checkHash &
#./addHash &

/usr/local/bin/snort $SNORT_CMD &

/bin/bash
