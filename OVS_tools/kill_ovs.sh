#!/bin/bash

sudo ovs-ofctl del-flows br0
sudo ovs-vsctl del-br br0

sudo kill `cd /var/run/openvswitch && cat ovsdb-server.pid ovs-vswitchd.pid`
