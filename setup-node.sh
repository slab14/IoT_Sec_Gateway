#!/bin/bash

# Script to setup "node" for generating/sinking IP data traffic
## Asumes on a Ubuntu machine ##

#borrowed from Jeff Helt

CLIENT_IP=192.1.1.2
SERVER_IP=10.1.1.2

update() {
    echo "Updating apt-get..."
    sudo apt-get update -qq
    sudo apt-get install -yqq default-jdk default-jre jq maven
    echo "Update Complete"
}


install_iperf() {
    echo "Installing iperf..."
    sudo apt-get install -yqq iperf3
    echo "iperf Install Complete"
}

install_python_packages() {
    echo "Installing Python..."
    sudo apt-get install -yqq python python-dev python-pip
    sudo pip -qq install --upgrade pip
    sudo pip -qq install ipaddress subprocess32
    echo "Python Install Complete"
}

setup_maven() {
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
    export PATH=$PATH:$JAVA_HOME/bin/
    mkdir -p ~/.m2
    cp /usr/share/maven/conf/settings.xml ~/.m2/settings.xml
    cp -n ~/.m2/settings.xml{,.orig}
    wget -q -O - https://raw.githubusercontent.com/opendaylight/odlparent/stable/boron/settings.xml > ~/.m2/settings.xml
    export M2_HOME=/usr/share/maven/
    export M2=$M2_HOME
    export MAVEN_OPTS='-Xmx1048m -XX:MaxPermSize=512m -Xms256m'
    export PATH=$M2:$PATH
}

install_ovs() {
    echo "Installing OVS..."
    sudo apt-get -yqq install openvswitch-common openvswitch-switch \
	 openvswitch-dbg
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch
    echo "OVS Install Complete"
}

install_ovs_fromGit() {
    #Install Build Dependencies
    sudo apt-get update -qq
    sudo apt-get install -yqq make gcc libssl1.0.2 libssl1.0-dev \
	 libcap-ng0 libcap-ng-dev python python-pip autoconf \
	 libtool wget netcat curl clang sparse flake8 \
	 graphviz autoconf automake libtool python-dev
    sudo pip -qq install --upgrade pip
    pip -qq install --user six pyftpdlib tftpy

    #Clone repository, build, and install
    cd ~
    git clone https://github.com/slab14/ovs.git
    cd ovs
    git checkout slab
    ./boot.sh
    ./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
    make
    sudo make install
    cd ~

    # Install ovs-docker-remote dependencies
    sudo apt-get install -yqq jq curl uuid-runtime

    # Start OVS Deamons
    sudo /usr/share/openvswitch/scripts/ovs-ctl start
}

install_docker() {
    sudo apt-get update -qq
    sudo apt-get install -yqq apt-transport-https \
	 ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -qq
    sudo apt-get install -yqq docker-ce

    sudo systemctl start docker
    sudo systemctl enable docker
}


find_interface_for_ip() {
    local ip="$1"

    local interface=$(ip -o addr | grep "inet $ip" | awk -F ' ' '{ print $2 }')
    if [[ -z $interface ]]; then
	return 1
    else
	echo $interface
	return 0
    fi
}

ip2int() {
    local a b c d
    { IFS=. read a b c d; } <<< $1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

int2ip() {
    local ui32=$1; shift
    local ip n
    for n in 1 2 3 4; do
	ip=$((ui32 & 0xff))${ip:+.}$ip
	ui32=$((ui32 >> 8))
    done
    echo $ip
}

network() {
    local addr=$(ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    int2ip $((addr & mask))
}


setup_ip_routes() {
    local interface=$(find_interface_for_ip $CLIENT_IP \
			  || find_interface_for_ip $SERVER_IP)

    if find_interface_for_ip $CLIENT_IP; then
	local ip=$SERVER_IP
    else
	local ip=$CLIENT_IP
    fi

    local net=$(network $ip 16)
    sudo ip route add $net/16 dev $interface \
	|| sudo ip route change $net/16 dev $interface

    # Delete old routes using via
    IFS=$'\n'
    local oldrtes=($(ip route | grep via))
    for i in ${oldrtes[@]}; do
	sudo ip route del $i
    done
    
}

# Install packages
echo "Beginning Node Setup..."
update
install_iperf
install_python_packages
setup_maven
setup_ip_routes
install_ovs_fromGit
install_docker
echo "Node Setup Complete"
