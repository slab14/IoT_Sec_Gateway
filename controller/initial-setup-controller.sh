#!/bin/bash

BRIDGE_NAME=br0
DEVICE_SIDE_IP=192.168.42.1
ROUTER_SIDE_IP=10.1.1.1

OVS_PORT=6677
DOCKER_PORT=4243

update() {
    echo "Updating apt-get..."
    sudo apt-get update -qq
    sudo apt-get install -yqq default-jre default-jdk maven jq
    echo "Update complete"
}

install_docker() {
    echo "Installing Docker..."
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
    echo "Docker Install Complete"
}

build_docker_containers(){
    echo "Building Snort ICMP Packet Warning Container"
    sudo docker build -t="snort_icmp_alert" docker_containers/snort_base
    sudo docker build -t="snort_icmp_block" docker_containers/squid_proxy_v3
    echo "Docker containers built"
}

install_python_packages() {
    echo "Installing Python..."
    sudo apt-get install -yqq python python-ipaddress python-subprocess32 \
	 python-pip
    echo "Python Install Complete"
}

install_ovs() {
    echo "Installing OVS..."
    sudo apt-get install -yqq openvswitch-common openvswitch-switch \
	 openvswitch-dbg
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch
    echo "OVS Install Complete"
}

install_ovs_fromGit() {
    #Install Build Dependencies
    sudo apt-get update -qq
    sudo apt-get install -yqq make gcc libssl1.0.0 libssl-dev \
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

setup_remote_docker() {
    sudo sed -i 's/fd\:\/\// fd\:\/\/ \-H tcp\:\/\/0\.0\.0\.0\:'"$DOCKER_PORT"'/g' /lib/systemd/system/docker.service
    sudo systemctl daemon-reload
    sudo service docker restart
}

disable_gro() {
    local device_side_if=$(find_interface_for_ip $DEVICE_SIDE_IP)
    local router_side_if=$(find_interface_for_ip $ROUTER_SIDE_IP)
    sudo ethtool -K $device_side_if gro off
    sudo ethtool -K $router_side_if gro off
}

setup_bridge() {
    echo "Setting up basic Bridge..."
    sudo ovs-vsctl --may-exist add-br $BRIDGE_NAME
    sudo ip link set $BRIDGE_NAME up

    local device_side_if=$(find_interface_for_ip $DEVICE_SIDE_IP)
    local router_side_if=$(find_interface_for_ip $ROUTER_SIDE_IP)
    
    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $device_side_if \
	 -- set Interface $device_side_if ofport_request=1
    sudo ovs-ofctl mod-port $BRIDGE_NAME $device_side_if up

    sudo ovs-vsctl --may-exist add-port $BRIDGE_NAME $router_side_if \
	 -- set Interface $router_side_if ofport_request=2
    sudo ovs-ofctl mod-port $BRIDGE_NAME $router_side_if up
    echo "Bridge Setup Complete"
}

configure_ovs_switch() {
    sudo ovs-vsctl set-controller $BRIDGE_NAME tcp:127.0.0.1:6633 ptcp:6634
    sudo ovs-vsctl set bridge $BRIDGE_NAME protocol=OpenFlow13
    sudo ovs-vsctl set-fail-mode $BRIDGE_NAME secure
}

get_controller() {
    cd ~
    git clone https://github.com/slab14/l2switch.git
    cd l2switch/
    git checkout slab-demo
    mvn clean install -DskipTests
    cd ~
}

write_wifi_configs(){
    sudo cp /etc/network/interfaces /etc/network/interfaces-orig
    sudo touch /etc/network/interfaces-gateway
    sudo sh -c 'echo "auto lo
iface lo inet loopback 

allow-hotplug wlan0

auto eth1
iface eth1 inet static
      address 10.10.10.10
      netmask 255.255.255.0

allow-ovs br0
iface br0 inet static
      ovs_type OVSBridge
      ovs_ports eth0 wlan0
      address 192.168.42.1
      netmask 255.255.255.0

allow-br0 eth0
iface eth0 inet manual
      ovs_bridge br0
      ovs_type OVSPort

allow-br0 wlan0
iface wlan0 inet manual
      ovs_bridge br0
      ovs_type OVSPort
      address 192.168.42.1
      netmask 255.255.255.0" > /etc/network/interfaces-gateway'

    sudo touch /etc/dhcp/dhcpd.conf-gateway
    sudo sh -c 'echo "default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 192.168.42.0 netmask 255.255.255.0 {
  range 192.168.42.42 192.168.42.242;
  option broadcast-address 192.168.42.255;
  option routers 192.168.42.1;
  default-lease-time 600;
  max-lease-time 7200;
  option domain-name \"local\";
}" > /etc/dhcp/dhcpd.conf-gateway'

    sudo touch /etc/hostapd/hostapd.conf-gateway
    sudo sh -c 'echo "interface=wlan0
driver=nl80211
ssid=IoT_Security_Gateway
country_code=US
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=0
macaddr_acl=0
ignore_broadcast_ssid=0
auth_algs=1
wpa=2
wpa_passphrase=3w3Sha11NotPa$$
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" > /etc/hostapd/hostapd.conf-gateway'
}

install_std_pkgs() {
    sudo apt-get update -y
    sudo apt-get install -y python python-dev python-pip emacs vim \
	 iperf3 nmap python-ipaddress python-subprocess32 \
	 apt-transport-https ca-certificates \
	 isc-dhcp-server wireshark tcpdump wavemon netcat hping3 \
	 iptables-persistent

    sudo dpkg-reconfigure wireshark-common
    sudo adduser $USER wireshark
}

install_patched_hostapd(){
    sudo apt-get update 
    sudo apt-get -yqq install build-essential git libnl-3-dev \
	 libnl-genl-3-dev iw crda libssl1.0-dev libnl-genl-3-200 \
	 libnl-3-200

    cd ~
    git clone git://w1.fi/srv/git/hostap.git
    cd hostap
    git checkout hostap_2_6
    cp ../linux_ioctl.c src/drivers/linux_ioctl.c

    cd hostapd/
    cp defconfig .config

    sed -i 's/^#CONFIG_DRIVER_NL80211=y/CONFIG_DRIVER_NL80211=y/g' .config
    sed -i 's/^#CONFIG_LIBNL32=y/CONFIG_LIBNL32=y/g' .config

    ## enable 802.11n and 802.11ac
    sed -i 's/^#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/g' .config
    #sed -i 's/^#CONFIG_IEEE80211AC=y/CONFIG_IEEE80211AC=y/g' .config

    ## enable automatic channel selection
    #sed -i 's/^#CONFIG_ACS=y/CONFIG_ACS=y/g' .config

    make && sudo make install
}

setup_wifi_AP() {
    sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf-orig
    sudo cp /etc/network/interfaces-gateway /etc/network/interfaces
    sudo cp /etc/dhcp/dhcpd.conf-gateway /etc/dhcp/dhcpd.conf
    sudo ip link set wlan0 down
    sudo ip link set wlan0 up
    sudo touch /etc/default/isc-dhcp-server-gateway
    sudo sh -c 'echo "INTERFACESv4=\"br0\"
INTERFACESv6=\"\"">/etc/default/isc-dhcp-server-gateway'
    sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server-orig
    sudo cp /etc/default/isc-dhcp-server-adhoc /etc/default/isc-dhcp-server
    sudo service isc-dhcp-server restart
    sudo cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf-orig
    sudo cp /etc/hostapd/hostapd.conf-gateway /etc/hostapd/hostapd.conf
    sudo sh -c 'echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" > /etc/default/hostapd'
    sudo service hostapd start
    sudo update-rc.d hostapd enable
    sudo update-rc.d isc-dhcp-server enable
}


# Install packages
echo "Beginning Setup..."
update
install_std_pkgs
install_docker
install_ovs_fromGit
install_python_packages
setup_maven
setup_remote_ovsdb_server
setup_remote_docker
get_controller
build_docker_containers

# Configure WiFi AP
install_patched_hostapd
write_wifi_configs
setup_wifi_AP

# Setup
disable_gro
setup_bridge
configure_ovs_switch
echo "Ready"
