#!/bin/bash

BRIDGE=$1
INTERFACE=$2
CONTAINER=$3
IP=$4
OVS_PORT=$5
USERNAME=$6

PORT=`sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --data=bare --no-heading --columns=name find interface external_ids:container_id="$CONTAINER" external_ids:container_iface="$INTERFACE"`

if [ -z "$PORT" ]; then
    exit 1
fi

sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --if-exists del-port "$PORT"

ssh $USERNAME@$IP sudo ip link delege "$PORT"
