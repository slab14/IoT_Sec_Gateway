#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	break

    sleep 1

done

CONNS=$(python counter.py --ip 10.1.1.2 --port 5201)

OUT="False"
if (($CONNS > 2)); then
    OUT="True"
fi


/bin/bash
