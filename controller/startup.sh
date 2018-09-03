#!/bin/bash
PATH=/usr/bin:/usr/sbin:/bin:/sbin

OVS_BRIDGE=br0
WLAN_BRIDGE=wlan-br
ADDR=192.168.42.1
ETHERNET=eno1
WIRELESS=wlan0
CONTROLLER=127.0.0.1

# not sure when this is called, but empirical testing seems to indicate a little to early in the boot process
sleep 10

# make sure taht OVS bridge (br0) exists
ovs-vsctl --may-exist add-br $OVS_BRIDGE
ovs-vsctl --may-exist add-br $WLAN_BRIDGE
ifconfig $WLAN_BRIDGE $ADDR/24 up

# make sure taht OVS bridge is configured correctly
ovs-vsctl set-controller $OVS_BRIDGE tcp:$CONTROLLER:6633 ptcp:6634
ovs-vsctl set bridge $OVS_BRIDGE protocol=OpenFlow13
ovs-vsctl set-fail-mode $OVS_BRIDGE secure

# add ports
ovs-vsctl --may-exist add-port $OVS_BRIDGE $ETHERNET -- set Interface $ETHERNET ofport_request=1
ovs-ofctl -OOpenflow13 mod-port $OVS_BRIDGE $ETHERNET up

ovs-vsctl --may-exist add-port $WLAN_BRIDGE $WIRELESS
ip link add $WIRELESS-$WLAN_BRIDGE type veth peer name $WIRELESS-$OVS_BRIDGE
ovs-vsctl --may-exist add-port $WLAN_BRIDGE $WIRELESS-$WLAN_BRIDGE
ip link set $WIRELESS-$WLAN_BRIDGE up
ovs-vsctl --may-exist add-port $OVS_BRIDGE $WIRELESS-$WLAN_BRIDGE -- set Interface $WIRELESS-$WLAN_BRIDGE ofport_request=1
ovs-ofctl -OOpenflow13 mod-port $OVS_BRIDGE $WIRELESS-$WLAN_BRIDGE up
ip link set $WIRELESS-$OVS_BRIDGE up

# add action to allow for EOPOL (4-way) WPA handshake
ovs-ofctl -OOpenflow13 add-flow $WLAN-BRIDGE "priority=1 actions=NORMAL"

# disable GRO
ethtool -K $ETHERNET gro off
ethtool -K $WIRELESS gro off
ethtool -K $OVS_BRIDGE gro off
ethtool -K $WLAN_BRIDGE gro off

# restart DHCP server & AP
sleep 10
rfkill unblock wlan
service isc-dhcp-server restart
service hostapd restart
