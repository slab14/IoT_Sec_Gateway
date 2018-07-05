#!/bin/bash

install_ovs() {
    ##sudo apt-get install -yqq openvswitch-switch
    cd ~
    git clone https://github.com/slab14/ovs.git
    cd ovs
    git checkout slab
    ./boot.sh
    ./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
    make
    sudo make install
}

install_ovs

