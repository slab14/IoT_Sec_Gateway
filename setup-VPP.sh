#!/bin/bash

sudo apt-get update

##Set Ifaces down
IFACES=$(ifconfig -a | grep enp | awk -F ': ' '{ print $1 }')
for IFACE in $IFACES; do
        IP=$(ifconfig $IFACE | grep "inet addr" | awk -F ' ' '{ print $2 }' | awk -F ':' '{ pr\
int $2 }')
	testVal=$( echo $IP | awk -F '.' '{ print $1 }' )
	if [[ "$testVal" -eq 128 ]]; then
	    echo "skip"
	else
	    sudo ifconfig $IFACE down
	fi
done

#sudo ifconfig enp6s0f0 down
#sudo ifconfig enp6s0f1 down

cd ~
git clone -b master https://gerrit.fd.io/r/vpp fdio.1704
cd fdio.1704/
make install-dep
make bootstrap
#make build ##never tested (would replace the cd and other makes below)
cd build-root

#make PLATFORM=vpp TAG=vpp vpp-install
make PLATFORM=vpp TAG=vpp install-deb
sudo dpkg -i *.deb

## Turn NICs On
sudo vppctl set interface state TenGigabitEthernet6/0/0 up
sudo vppctl set interface state TenGigabitEthernet6/0/1 up

## Connect NICs to vSwitch
sudo vppctl set interface l2 bridge TenGigabitEthernet6/0/0 1
sudo vppctl set interface l2 bridge TenGigabitEthernet6/0/1 1

