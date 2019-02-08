#!/bin/bash

START=$1
COUNT=$2

for i in `seq 0 $COUNT`; do
    NEW=$(($START+$i))
    sudo ip addr add 192.168.42.$NEW/24 dev eno1
done
