BRIDGE=$1
NAME=$2

sudo ovs-docker del-ports $BRIDGE $NAME
sudo ovs-ofctl del-flows $BRIDGE
sudo ovs-ofctl add-flow $BRIDGE "priority=0 in_port=1 actions=output:2"
sudo ovs-ofctl add-flow $BRIDGE "priority=0 in_port=2 actions=output:1"

