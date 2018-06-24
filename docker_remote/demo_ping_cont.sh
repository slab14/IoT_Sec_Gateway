#!/bin/bash

IP=$1
DOCKER_PORT=$2
OVS_PORT=$3
USERNAME=$4
NAME="demo_cont"
BRIDGE="demo_ovs_br"
CONT_IFACE="eth0"
BRIDGE_REMOTE_PORT=6633

# Create the container (one that will spin)
curl -X POST -H "Content-Type: application/json" -d '{"Image": "busybox", "Cmd": ["/bin/sh"], "NetworkDisabled": true, "HostConfig": {"AutoRemove": true}, "Tty": true}' http://"$IP":"$DOCKER_PORT"/v1.37/containers/create?name="$NAME"

# Start the container
curl -X POST http://"$IP":"$DOCKER_PORT"/v1.37/containers/"$NAME"/start

# Add OVS Bridge
sudo ovs-vsctl --db=tcp:"$IP":"$OVS_PORT" --may-exist add-br "$BRIDGE"

# Add port to dataplane external interface
sudo ovs-vsctl --db=tcp:"$IP":"$OVS_PORT" --may-exist add-port "$BRIDGE" enp6s0f1 -- set Interface enp6s0f1 ofport_request=1

# Add port to docker container interface (make sure to include mask for ip address, otherwise assigns /32)
./ovs-docker-remote add-port $BRIDGE $CONT_IFACE $NAME $IP $OVS_PORT $DOCKER_PORT $USERNAME --ipaddress=10.1.2.1/16

## Need to update ovs-docker-remote to include ability to set ipaddresses, macaddress, gateway, and mtu
# temp fix
## Get PID: curl -s -X GET -H "Content-Type: application/json" http://192.1.1.1:4243/v1.37/containers/demo2/json | jq -r '.State.Pid'
## Add IP address:
#ssh slab@192.1.1.1 sudo ln -s /proc/16729/ns/net /var/run/netns/16729
#ssh slab@192.1.1.1 'sudo ip netns exec 16729 ip addr add 10.1.2.1 dev eth0'
#ssh slab@192.1.1.1 'trap `sudo rm -f /var/run/netns/16729` 0'

# Add route for container
ssh $USERNAME@$IP sudo nsenter -t 16729 -n ip route add 10.1.0.0/16 dev $CONT_IFACE
## if container has ip in it, can do this through the container:
EXEC_ID=`curl -s -X POST -H "Content-Type: application/json" -d '{"AttachStdout": true, "Tty": true, "Cmd": ["ip", "route", "add", "10.1.0.0/16", "dev", "eth0"], "Privileged": true}' http://$IP:$DOCKER_PORT/v1.37/containers/$NAME/exec | jq -r '.Id'`
curl -s -X POST -H "Content-Type: application/json" -d '{"Detach": false, "Tty": true}' http://$IP:$DOCKER_PORT/exec/$EXEC_ID/start

# Add OVS routes
## Make switch listen for remote commands
sudo ovs-vsctl --db=tcp:$IP:$OVS_PORT set-controller $BRIDGE ptcp:$BRIDGE_REMOTE_PORT
## Add flow rules
sudo ovs-ofctl add-flow tcp:$IP:$BRIDGE_REMOTE_PORT "priority=100 ip in_port=1 nw_src=10.1.1.2 nw_dst=10.1.2.1 actions=output:2"
sudo ovs-ofctl add-flow tcp:$IP:$BRIDGE_REMOTE_PORT "priority=100 ip in_port=2 nw_src=10.1.2.1 nw_dst=10.1.1.2 actions=output:1"

