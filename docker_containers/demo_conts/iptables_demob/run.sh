#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
	break

    sleep 1

done

brctl addbr bridge0
ifconfig eth1 down
ifconfig eth2 down
brctl addif bridge0 eth1 eth2
ifconfig eth1 up
ifconfig eth2 up
ifconfig bridge0 up

iptables -A FORWARD -p icmp -s 10.1.1.0/24 -j NFLOG --nflog-prefix "iptables: " --nflog-group 1
iptables -A FORWARD -p icmp -s 10.1.1.0/24 -j DROP

touch ID
echo $PROTECTION_ID > ID
service ulogd2 start
python getAlerts.py

<< ////
if [ -z "$MAX_CONN" ]; then
    MAX_CONN="6"
fi

if [ -z "$CONN_MASK" ]; then
    CONN_MASK="32"
fi

if [ -z "$MAX_RATE" ]; then
    MAX_RATE="1500"
fi

if [ -z "$MODE" ]; then
    MODE="srcip,srcport,dstip,dstport"
fi
////

#Limit number of simultaneous connections: --connlimit-above X, currently 15--allows 14 connections, drops the 15th
#iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above $MAX_CONN --connlimit-mask $CONN_MASK --connlimit-saddr -j REJECT --reject-with tcp-reset
#Limit the throughput (in either pkts/sec or Bytes/sec, for granularity/group desired--src&dst, only dst, dst&dstport, etc; specified in --hashlimit-mode). --hashlimit-above X/time (or Xb/time for Bytes, does not allow modifiers such as K or M)
#iptables -A FORWARD -m hashlimit --hashlimit-above "$MAX_RATE"/sec --hashlimit-mode $MODE --hashlimit-name foo -j DROP






/bin/bash
