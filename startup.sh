#!/bin/bash

sudo insmod /home/pi/uhcallkmod.ko

sudo /usr/share/openvswitch/scripts/ovs-ctl start

sudo ovs-docker del-ports br0 snort_demo_cont

sudo ethtool -K eth1 tx off rx off
sudo ethtool -K eth2 tx off rx off

sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6677

sudo ovs-vsctl --may-exist add-br br0
sudo ovs-vsctl --may-exist add-port br0 eth1 -- set Interface eth1 ofport_request=1
sudo ovs-vsctl --may-exist add-port br0 eth2 -- set Interface eth2 ofport_request=2

sudo ovs-vsctl set-controller br0 tcp:127.0.0.1:6633 ptcp:6634
sudo ovs-vsctl set-fail-mode br0 secure

sudo ovs-vsctl --may-exist add-br wlan-br
sudo ifconfig wlan-br 192.168.2.1/24 up
sudo ovs-vsctl --may-exist add-port wlan-br wlan0 -- set Interface wlan0 ofport_request=1
sudo ovs-vsctl -- --may-exist add-port br0 patch0 -- set interface patch0 type=patch options:peer=patch1 ofport_request=3 \
     -- --may-exist add-port wlan-br patch1 -- set interface patch1 type=patch options:peer=patch0 ofport_request=2
sudo ovs-ofctl add-flow wlan-br "ip priority=10 ip_port=1 nw_dst=192.168.2.1 actions=NORMAL"
sudo ovs-ofctl add-flow wlan-br "arpp priority=10 ip_port=1 nw_dst=192.168.2.1 actions=NORMAL"
sudo ovs-ofctl add-flow wlan-br "ip priority=1 in_port=1 actions=2"
sudo ovs-ofctl add-flow wlan-br "arp priority=1 in_port=1 actions=2"

sudo systemctl restart dhcpcd
sudo systemctl restart dnsmasq
sudo hostapd -B /etc/hostapd/hostapd.conf

