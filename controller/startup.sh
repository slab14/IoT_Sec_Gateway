#!/bin/bash
PATH=/usr/bin:/usr/sbin:/bin:/sbin

BRIDGE=br0
ADDR=192.168.42.1
ETHERNET=eno1
WIRELESS=wlan0
CONTROLLER=127.0.0.1

# not sure when this is called, but empirical testing seems to indicate a little to early in the boot process
sleep 10

# make sure taht OVS bridge (br0) exists
ovs-vsctl --may-exist add-br $BRIDGE
ifconfig $BRIDGE $ADDR/24 up

# make sure taht OVS bridge is configured correctly
ovs-vsctl set-controller $BRIDGE tcp:$CONTROLLER:6633 ptcp:6634
ovs-vsctl set bridge $BRIDGE protocol=OpenFlow13
ovs-vsctl set-fail-mode $BRIDGE secure

# add ports
ovs-vsctl --may-exist add-port $BRIDGE $ETHERNET -- set Interface $ETHERNET ofport_request=1
ovs-ofctl -OOpenflow13 mod-port $BRIDGE $ETHERNET up

ovs-vsctl --may-exist add-port $BRIDGE $WIRELESS -- set Interface $ETHERNET ofport_request=1
ovs-ofctl -OOpenflow13 mod-port $BRIDGE $WIRELESS up

# add action to allow for EOPOL (4-way) WPA handshake
ovs-ofctl -OOpenflow13 add-flow $BRIDGE "priority=1 actions=NORMAL"

# disable GRO
ethtool -K $ETHERNET gro off
ethtool -K $WIRELESS gro off
ethtool -K $BRIDGE gro off

# restart DHCP server & AP
sleep 10
rfkill unblock wlan
service isc-dhcp-server restart
service hostapd restart
