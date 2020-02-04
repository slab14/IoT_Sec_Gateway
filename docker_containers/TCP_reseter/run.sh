#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break

    sleep 1

done

#python reset.py -i eth0 -o eth1
python reset2.py -i eth0 -o eth1

#/bin/bash
