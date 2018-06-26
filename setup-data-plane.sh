#!/bin/bash

#borrowed form Jeff Helt

BRIDGE_NAME=br0
CLIENT_SIDE_IP=192.1.1.1
SERVER_SIDE_IP=10.1.1.1

OVS_PORT=6677
DOCKER_PORT=4243

update() {
    echo "Updating apt-get..."
    sudo apt-get -qq update
    sudo apt-get install -yqq default-jre default-jdk maven jq
    echo "Update complete"
}

install_docker() {
    echo "Installing Docker..."
    sudo apt-get -yqq install docker-compose 

    sudo apt-get -yqq install apt-transport-https ca-certificates \
	 curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt-get -qq update
    sudo apt-get -yqq install docker-ce

    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker Install Complete"
}

build_docker_containers(){
    echo "Building Snort ICMP Packet Warning Container"
    sudo docker build -t="snort_icmp_alert" docker_containers/snort_icmp_alert
    sudo docker build -t="snort_icmp_block" docker_containers/snort_icmp_block
    echo "Docker containers built"
}

install_python_packages() {
    echo "Installing Python..."
    sudo apt-get -yqq install python python-ipaddress python-subprocess32 \
	 python-pip
    echo "Python Install Complete"
}

install_ovs() {
    echo "Installing OVS..."
    sudo apt-get -yqq install openvswitch-common openvswitch-switch \
	 openvswitch-dbg
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch
    echo "OVS Install Complete"

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

setup_remote_ovsdb_server() {
    sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:$OVS_PORT
}

setup_remote_docker(){
    sudo sed -i 's/fd\:\/\// fd\:\/\/ \-H tcp\:\/\/0\.0\.0\.0\:'"$DOCKER_PORT"'/g' /lib/systemd/system/docker.service
    sudo systemctl daemon-reload
    sudo service docker restart
}

disable_gro() {
    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    local server_side_if=$(find_interface_for_ip $SERVER_SIDE_IP)
    sudo ethtool -K $client_side_if gro off
    sudo ethtool -K $server_side_if gro off
}


setup_bridge() {
    echo "Setting up basic Bridge..."
    sudo ovs-vsctl --may-exist add-br $BRIDGE_NAME
    sudo ip link set $BRIDGE_NAME up

    local client_side_if=$(find_interface_for_ip $CLIENT_SIDE_IP)
    local server_side_if=$(find_interface_for_ip $SERVER_SIDE_IP)
    
    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $client_side_if \
	 -- set Interface $client_side_if ofport_request=1
    sudo ovs-ofctl mod-port $BRIDGE_NAME $client_side_if up

    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $server_side_if \
	 -- set Interface $server_side_if ofport_request=2
    sudo ovs-ofctl mod-port $BRIDGE_NAME $server_side_if up
    echo "Bridge Setup Complete"
}

# Install packages
echo "Beginning Dataplane Setup..."
update
install_docker
install_ovs
install_python_packages
setup_maven

# Setup
disable_gro
setup_bridge
echo "Dataplane Ready"
