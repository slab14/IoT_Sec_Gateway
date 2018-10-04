#!/bin/bash

OSver=$(uname -r | awk -F '-' '{ print $1 }')

install_docker() {
    sudo apt-get update -qq
    sudo apt-get install -yqq docker-compose
    sudo apt-get install -yqq apt-transport-https ca-certificates \
	 curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get update -qq
	sudo apt-get install -yqq docker-ce
	sudo systemctl start docker
	sudo systemctl enable docker
}

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

CHECK_DOCKER=$(which docker)
if [[ -z CHECK_DOCKER ]]; then
    install_docker
fi
if [[ "$OSver" = "4.15.0" ]]; then
    sudo systemctl disable apparmor.service --now
    sudo service apparmor teardown
fi
