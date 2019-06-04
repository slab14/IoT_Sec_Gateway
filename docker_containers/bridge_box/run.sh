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

#Limit number of simultaneous connections: --connlimit-above X, currently 15--allows 14 connections, drops the 15th
iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 15 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
#Limit the throughput (in either pkts/sec or Bytes/sec, for granularity/group desired--src&dst, only dst, dst&dstport, etc; specified in --hashlimit-mode). --hashlimit-above X/time (or Xb/time for Bytes, does not allow modifiers such as K or M)
iptables -A FORWARD -m hashlimit --hashlimit-above 1000/sec --hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name foo -j DROP

/bin/bash
