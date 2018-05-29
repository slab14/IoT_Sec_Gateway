#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break

    sleep 1

done

ethtool -K eth0 gro off
ethtool -K eth0 lro off
ethtool -K eth1 gro off
ethtool -K eth1 lro off

exec /usr/local/bin/snort "$@"
