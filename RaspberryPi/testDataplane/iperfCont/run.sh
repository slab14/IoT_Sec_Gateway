#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier"
	break

    sleep 1

done

iperf3 -s && /bin/bash
