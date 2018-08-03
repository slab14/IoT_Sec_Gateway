BRIDGE=$1
NAME=$2
OFversion=$3

sudo ovs-docker del-ports $BRIDGE $NAME
if [ $OFversion == "13" ]; then
    sudo ovs-ofctl -OOpenflow13 del-flows $BRIDGE
    sudo ovs-ofctl -OOpenflow13 add-flow $BRIDGE "priority=0 in_port=1 actions=output:2"
    sudo ovs-ofctl -OOpenflow13 add-flow $BRIDGE "priority=0 in_port=2 actions=output:1"
else
    sudo ovs-ofctl del-flows $BRIDGE
    sudo ovs-ofctl add-flow $BRIDGE "priority=0 in_port=1 actions=output:2"
    sudo ovs-ofctl add-flow $BRIDGE "priority=0 in_port=2 actions=output:1"
fi

