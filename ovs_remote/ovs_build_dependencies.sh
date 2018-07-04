#!/bin/bash

update() {
    sudo apt-get update -qq
}

install_dependencies() {
    sudo apt-get install -yqq make gcc libssl1.0.0 libssl-dev \
	 libcap-ng0 libcap-ng-dev python python-pip autoconf \
	 libtool wget netcat curl clang sparse flake8 \
	 graphviz autoconf automake libtool python-dev

    sudo pip -qq install --upgrade pip
    pip -qq install --user six pyftpdlib tftpy
}

update
install_dependencies
