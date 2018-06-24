#!/bin/bash

BRIDGE="$1"
INTERFACE="$2"
CONTAINER="$3"
IP=$4
OVS_PORT=$5
DOCKER_PORT=$6
USERNAME=$7

if [ -z "$BRIDGE" ] || [ -z "$INTERFACE" ] || [ -z "$CONTAINER" ]; then
    echo >&2 "Not enough arguments"
    exit 1
fi

#Check if a port is already attached for a given container & interface
PORT=`sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --data=bare --no-heading --columns=name find interface external_ids:container_id="$CONTAINER" external_ids:container_iface="$INTERFACE"`

if [ -n "$PORT" ]; then
    echo >&2 "Port already attached"
    exit 1
fi

if sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT br-exists "$BRIDGE" || sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT add-br "$BRIDGE"; then :; else
    echo >&2 "Failed to create $BRIDGE"
    exit 1
fi

if PID=`curl -s -X GET -H "Content-Type: application/json" http://$IP:$DOCKER_PORT/v1.37/containers/$CONTAINER/json | jq -r '.State.Pid'`; then :; else
    echo >&2 "Failed to get the PID of the container"
    exit 1
fi

# create netns link
#ssh $USERNAME@$IP sudo mkdir -p /var/run/netns
OUT=ssh $USERNAME@$IP `sudo mkdir -p /var/run/netns; test -e /var/run/netns/"$PID"; echo $?`

OUT=${OUT%$'\r'}

if [ $OUT -eq 1 ]; then
    ssh $USERNAME@$IP sudo ln -s /proc/"$PID"/ns/net /var/run/netns/"$PID"
fi

# Create a weth pair
ID=`uuidgen | sed 's/-//g'`
PORTNAME="${ID:0:13}"

ssh $USERNAME@$IP sudo ip link add "${PORTNAME}_l" type veth peer name "${PORTNAME}_c"

# Add one end of veth to OVS bridge
if sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT --may-exist add-port "$BRIDGE" "${PORTNAME}_l" -- set interface \
	"${PORTNAME}_l" external_ids:container_id="$CONTAINER" external_ids:container_iface="$INTERFACE"; 
then :; else
    echo "Failed to add "${PORTNAME}_l" port to bridge $BRIDGE"
    ssh $USERNAME@$IP sudo ip link delete "${PORTNAME}_l"
    exit 1
fi

ssh $USERNAME@$IP 'sudo ip link set '"${PORTNAME}_l"' up; sudo ip link set '"${PORTNAME}_c"' netns '"$PID"'; sudo ip netns exec '"$PID"' ip link set dev '"${PORTNAME}_c"' name '"$INTERFACE"'; sudo ip netns exec '"$PID"' ip link set '"$INTERFACE"' up'

if [ $OUT -eq 1 ]; then
    ssh $USERNAME@$IP 'trap `sudo rm -f /var/run/netns/'"$PID"'` 0'
fi 
