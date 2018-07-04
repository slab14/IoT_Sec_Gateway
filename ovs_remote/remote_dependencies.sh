#!/bin/bash

install_docker() {
    sudo apt-get update -qq
    sudo apt-get install -yqq\
	 apt-transport-https \
	 ca-certificates \
	 curl \
         software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -qq
    sudo apt-get install -yqq docker-ce
}

install_others() {
    sudo apt-get update -qq
    sudo apt-get install -yqq jq curl uuid-runtime
}

install_docker
install_others
