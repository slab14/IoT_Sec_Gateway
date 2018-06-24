#!/bin/bash

BRIDGE=$1
CONTAINER=$2
IP=$3
OVS_PORT=$4
USERNAME=$5

PORTS=`sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --data=bare --no-heading --columns=name find interface external_ids:container_id="$CONTAINER" external_ids:container_iface="$INTERFACE"`

if [ -z "$PORT" ]; then
    exit 1
fi

for PORT in $PORTS; do
    sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --if-exists del-port "$PORT"
    ssh $USERNAME@$IP sudo ip link delege "$PORT"
done

