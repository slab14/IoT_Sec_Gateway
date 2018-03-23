#!/bin/bash

# Steps for setting up Raspberry Pi 3's with a fresh installation of Raspian
# for use in 18-731 course project: IoT Security Gateway
#
# File created: 9 January 2018 by Matt McCormack
#
# Invocation example ./RaspberryPI_setup.sh <STEP#>

# Step 1a - Get latest software
if [ $1 == 1 ]; then
    sudo apt-get update -y
    sudo apt-get dist-upgrade -y
    sudo reboot
fi

# Step 1b - Get latest firmware
if [ $1 == 2 ]; then
    sudo rpi-update -y
    sudo reboot
fi

# Step 2 - Setup *.conf files for static IP address for the PI (assumes single wifi)
if [ $1 == 3 ]; then
    sudo cp /etc/network/interfaces /etc/network/interfaces-wifi
    sudo touch /etc/network/interfaces-gateway
    sudo sh -c 'echo "auto eth0
iface eth0 inet dhcp

auto lo 
iface lo inet loopback 

allow-hotplug wlan0

auto wlan0
iface wlan0 inet static
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
  option domain-name-server 8.8.8.8, 8.8.4.4; 
}" > /etc/dhcp/dhcpd.conf-gateway'


    sudo touch /etc/hostapd/hostapd.conf-gateway
    sudo sh -c 'echo "interface=wlan0
ssid=Pi3_AP
country_code=US
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
macaddr_acl=0
ignore_broadcast_ssid=0
auth_algs=1
wpa=2
wpa_passphrase=raspberry
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
	 hostapd iptables-persistent

    sudo dpkg-reconfigure wireshark-common
    sudo adduser $USER wireshark

    curl -sSL https://get.docker.com | sh
    
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
    sudo sh -c 'echo "INTERFACESv4=\"wlan0\"">/etc/default/isc-dhcp-server-adhoc'
    sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server-orig
    sudo cp /etc/default/isc-dhcp-server-adhoc /etc/default/isc-dhcp-server
    sudo service isc-dhcp-server restart
    sudo cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf-orig
    sudo cp /etc/hostapd/hostapd.conf-gateway /etc/hostapd/hostapd.conf
    sudo sh -c 'echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" > /etc/default/hostapd'
    sudo service hostapd start
    sudo update-rc.d hostapd enable
    sudo update-rc.d isc-dhcp-server enable
    sudo reboot
fi


