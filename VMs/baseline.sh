#!/bin/bash

# create 2 files in /etc/systemd/network/
# 10-eth0.netdev

# [NetDev]
# Name=eth0
# Kind=dummy

# 20-eth0.network
# [Match]
# Name=eth0
#
# [Network]
# Address=192.1.1.1

## Repeat for eth1

sudo apt-get update
sudo apt-get install bridge-utils
