#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/$1/carrier" && \
	break
    sleep 1
done

exec /usr/bin/iperf3 -s -p 5101 & /usr/bin/iperf3 -s -p -5102 
