#!/bin/bash

NAME=$1
BRIDGE=br1
i=0

while true; do
    sudo ovs-docker add-port $BRIDGE eth$i $NAME
    echo $i
    i=$((i+1))
done
