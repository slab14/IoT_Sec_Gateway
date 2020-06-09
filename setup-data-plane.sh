#!/bin/bash

BRIDGE_NAME=br0
CLIENT_SIDE=eth1
SERVER_SIDE=eth2

OVS_PORT=6677
DOCKER_PORT=4243

update() {
    echo "Updating apt-get..."
    sudo apt-get update -qq
    sudo apt-get install -yqq maven jq libxslt1.1 dpkg
    cd ~
    mkdir -p java11_deb
    cd java11_deb
    wget https://download.bell-sw.com/java/11.0.7+10/bellsoft-jdk11.0.7+10-linux-arm32-vfp-hflt.deb
    wget https://download.bell-sw.com/java/11.0.7+10/bellsoft-jre11.0.7+10-linux-arm32-vfp-hflt.deb
    sudo dpkg -i bellsoft-jdk11.0.7+10-linux-arm32-vfp-hflt.deb
    sudo dpkg -i bellsoft-jre11.0.7+10-linux-arm32-vfp-hflt.deb
    cd ~
    echo "Update complete"
}

install_docker() {
    echo "Installing Docker..."
    echo "Installing Docker..."

    #Get Docker
    curl -sSL https://get.docker.com | sh
    cd /usr/bin
    sudo wget https://raw.githubusercontent.com/openvswitch/ovs/master/utilities/ovs-docker
    sudo chmod a+rwx ovs-docker   

    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker Install Complete"
}

build_docker_containers(){
    echo "Building Snort ICMP Packet Warning Container"
    sudo docker build -t="snort_demoa" docker_containers/demo_conts/snort_demoA
    sudo docker build -t="snort_demob" docker_containers/demo_conts/snort_demoB
    echo "Docker containers built"
}

get_kernel_headers(){
    sudo apt-get update -qq
    sudo apt-get install -yqq libncurses5-dev git bc bison flex libssl-dev
    sudo wget -O /usr/src/linux-source.tar.gz https://github.com/raspberrypi/linux/archive/04c8e47067d4873c584395e5cb260b4f170a99ea.tar.gz
    sudo tar -xzf /usr/src/linux-source.tar.gz -C /usr/src/
    sudo touch 04c8e47067d4873c584395e5cb260b4f170a99ea/.scmversion
    echo + | sudo tee -a /usr/src/linux-04c8e47067d4873c584395e5cb260b4f170a99ea/.scmversion
    sudo ln -s /usr/src/linux-04c8e47067d4873c584395e5cb260b4f170a99ea /usr/src/linux
    sudo ln -sf /usr/src/linux /lib/modules/$(uname -r)/build
    sudo ln -sf /usr/src/linux /lib/modules/$(uname -r)/source
    cd /usr/src/linux
    sudo make modules
    sudo make modules_install
    sudo rm /usr/scr/linux-source.tar.gz
    cd ~
    /*
    // generates kernel headers based upon kernel commit in changelog (incorrect headers for hypervisor, kernel version of original raspbian image, not upgraded one from hypervisor install)
    // also sudo apt-get install raspberrypi-kernel-headers installs the wrong version (does not match uname -r)
    sudo wget https://raw.githubusercontent.com/notro/rpi-source/master/rpi-source -O /usr/local/bin/rpi-source
    sudo chmod +x /usr/local/bin/rpi-source
    /usr/local/bin/rpi-source -q --tag-update
    rpi-source
    */
}

install_ovs_fromGit() {
    #Install Build Dependencies
    sudo apt-get update -qq
    sudo apt-get install -yqq make gcc \
	 libcap-ng0 libcap-ng-dev python python-pip autoconf \
	 libtool wget netcat curl clang  \
	 graphviz automake python-dev python3-pip \
	 build-essential pkg-config \
         libssl-dev gdb linux-headers-`uname -r`
    sudo pip3 -qq install --upgrade pip
    pip -qq install --user six pyftpdlib tftpy flake8 sparse

    #Clone repository, build, and install
    cd ~
    git clone https://github.com/slab14/ovs.git
    cd ovs
    git checkout feature-kernsign
    ./boot.sh
    ./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-linux=/lib/modules/$(uname -r)/build
    make
    sudo make install
    sudo make modules_install
    sudo modprobe -v openvswitch
    cd ~

    # Install ovs-docker-remote dependencies
    sudo apt-get install -yqq jq curl uuid-runtime

    # Start OVS Deamons
    sudo /usr/share/openvswitch/scripts/ovs-ctl start --system-id
}

setup_maven() {
    export JAVA_HOME=`type -p javac|xargs readlink -f|xargs dirname|xargs dirname|sed '/s/8/11'`
    export PATH=$PATH:$JAVA_HOME/bin/
    mkdir -p ~/.m2
    cp /usr/share/maven/conf/settings.xml ~/.m2/settings.xml
    cp -n ~/.m2/settings.xml{,.orig}
    wget -q -O - https://raw.githubusercontent.com/opendaylight/odlparent/6.0.x/settings.xml > ~/.m2/settings.xml
    export M2_HOME=/usr/share/maven/
    export M2=$M2_HOME
    export MAVEN_OPTS='-Xmx768m -Xms256m'
    export PATH=$M2:$PATH
}

setup_remote_ovsdb_server() {
    sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:$OVS_PORT
}

setup_remote_docker() {
    sudo sed -i 's/fd\:\/\// fd\:\/\/ \-H tcp\:\/\/0\.0\.0\.0\:'"$DOCKER_PORT"'/g' /lib/systemd/system/docker.service
    sudo systemctl daemon-reload
    sudo service docker restart
}

disable_gro() {
    local client_side_if=eth1
    local server_side_if=eth2
    sudo ethtool -K $client_side_if gro off
    sudo ethtool -K $server_side_if gro off
}


setup_bridge() {
    echo "Setting up basic Bridge..."
    sudo ovs-vsctl --may-exist add-br $BRIDGE_NAME
    sudo ip link set $BRIDGE_NAME up

    local client_side_if=$CLIENT_SIDE
    local server_side_if=$SERVER_SIDE
    
    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $client_side_if \
	 -- set Interface $client_side_if ofport_request=1
    sudo ovs-ofctl mod-port $BRIDGE_NAME $client_side_if up

    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $server_side_if \
	 -- set Interface $server_side_if ofport_request=2
    sudo ovs-ofctl mod-port $BRIDGE_NAME $server_side_if up
    echo "Bridge Setup Complete"
}

configure_ovs_switch() {
    sudo ovs-vsctl set-controller $BRIDGE_NAME tcp:127.0.0.1:6633 ptcp:6634
    sudo ovs-vsctl set-fail-mode $BRIDGE_NAME secure
}

get_controller() {
    cd ~
    git clone https://github.com/slab14/l2switch.git
    cd l2switch/
    git checkout rpi-hyp
    export JAVA_HOME=`type -p javac|xargs readlink -f|xargs dirname|xargs dirname`
    mvn clean install -Pq -DskipTests -Dcheckstyle.skip=true -Dmaven.javadoc.skip=true
    cd ~
}

# Install packages
echo "Beginning Dataplane Setup..."
update
install_docker
build_docker_containers
install_ovs_fromGit
install_python_packages
setup_maven
setup_remote_ovsdb_server
setup_remote_docker
get_controller
    
# Setup
disable_gro
setup_bridge
configure_ovs_switch
echo "Dataplane Ready"
