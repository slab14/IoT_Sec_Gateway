#!/bin/bash

update() {
    sudo apt-get update -qq
    sudo apt-get install -yqq openjdk-8-jre openjdk-8-jdk maven jq
}

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


install_ovs() {
    sudo apt-get install -yqq openvswitch-common openvswitch-switch \
	 openvswitch-dbg
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch
}

