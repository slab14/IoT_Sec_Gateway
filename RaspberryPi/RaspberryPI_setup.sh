#!/bin/bash

# Steps for setting up Raspberry Pi 3's with a fresh installation of Raspian
# for use in IoT Security Gateway
#
# File created: 9 January 2018 by Matt McCormack
# File updated: 23 August 2018 by Matt McCormack
#
# Invocation example ./RaspberryPI_setup.sh <STEP#>

# Step 1 - Get latest software
if [ $1 == 1 ]; then
    sudo apt-get update -y
    sudo apt-get dist-upgrade -y
    sudo reboot
fi

# Step 2 - Get latest firmware
if [ $1 == 2 ]; then
    sudo rpi-update -y
    sudo reboot
fi

# Step 3 - Setup *.conf files for static IP address for the PI (assumes single wifi)
if [ $1 == 3 ]; then
    sudo cp /etc/network/interfaces /etc/network/interfaces-wifi
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
ssid=Pi3_AP
country_code=US
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=0
macaddr_acl=0
ignore_broadcast_ssid=0
auth_algs=1
wpa=2
wpa_passphrase=raspberry
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" > /etc/hostapd/hostapd.conf-gateway'
    
fi

# Step 3 - Install standard packages & enable SSH
if [ $1 == 3 ]; then
    sudo apt-get update -y
    sudo apt-get install -y python python-dev python-pip emacs vim \
	 iperf3 nmap python-ipaddress python-subprocess32 \
	 apt-transport-https ca-certificates \
	 docker openvswitch-common openvswitch-switch openvswitch-dbg \
	 isc-dhcp-server wireshark tcpdump wavemon netcat hping3 \
	 iptables-persistent

    sudo dpkg-reconfigure wireshark-common
    sudo adduser $USER wireshark

    #TODO: Update getting hostapd to use modified linux_ioctl.c file
    
    curl -sSL https://get.docker.com | sh

    #TODO: Update to get my modified version of OVS
    cd /usr/bin
    sudo wget https://raw.githubusercontent.com/openvswitch/ovs/master/utilities/ovs-docker
    sudo chmod a+rwx ovs-docker
    
    sudo systemctl enable ssh
    sudo systemctl start ssh
    sudo dpkg-reconfigure openssh-server

    sudo reboot
fi

# Step 4 - Setup Pi as an access point
if [ $1 == 4 ]; then
    sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf-wifi
    sudo cp /etc/network/interfaces-gateway /etc/network/interfaces
    sudo cp /etc/dhcp/dhcpd.conf-gateway /etc/dhcp/dhcpd.conf
    sudo ip link set wlan0 down
    sudo ip link set wlan0 up
    sudo touch /etc/default/isc-dhcp-server-adhoc
    sudo sh -c 'echo "INTERFACESv4=\"br0\"
INTERFACESv6=\"\"">/etc/default/isc-dhcp-server-gateway'
    sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server-orig
    sudo cp /etc/default/isc-dhcp-server-gateway /etc/default/isc-dhcp-server
    sudo service isc-dhcp-server restart
    sudo cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf-orig
    sudo cp /etc/hostapd/hostapd.conf-gateway /etc/hostapd/hostapd.conf
    sudo sh -c 'echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" > /etc/default/hostapd'
    sudo service hostapd start
    sudo update-rc.d hostapd enable
    sudo update-rc.d isc-dhcp-server enable
    sudo reboot
fi


