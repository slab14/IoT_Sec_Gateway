#!/bin/bash

# Steps for setting up Raspberry Pi 3's with a fresh installation of Raspian
# for use in CMU's 18-452/750 Wireless Network and Applications Course
#
# File created: 9 January 2018 by Matt McCormack
#
# Invocation example ./RaspberryPI_setup.sh STEP# PI#

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

# Step 2 - Setup *.conf files for static IP address for the PI
if [ $1 == 3 ]; then
    sudo cp /etc/network/interfaces /etc/network/interfaces-wifi
    sudo touch /etc/network/interfaces-adhoc
    sudo sh -c 'echo "auto lo 
iface lo inet loopback 
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet static
      address 192.168.1.1
      netmask 255.255.255.0
      wireless-channel 3
      wireless-essid RPi-AdHocNet
      wireless-mode ad-hoc" > /etc/network/interfaces-adhoc'

    sudo touch /etc/dhcp/dhcpd.conf-adhoc
    sudo sh -c 'echo "default-lease-time 600;
max-lease-time 7200;
ddns-update-style interim;
authoritative;
log-facility local7;
subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.25 192.168.1.230; 
}" > /etc/dhcp/dhcpd.conf-adhoc'
   
fi

# Step 3 - Install standard packages & enable SSH
if [ $1 == 3 ]; then
    sudo apt-get update -y
    sudo apt-get install -y python python-dev python-pip emacs vim \
	 iperf3 nmap python-ipaddress python-subprocess32 \
	 apt-transport-https ca-certificates \
	 docker openvswitch-common openvswitch-switch openvswitch-dbg \
	 isc-dhcp-server wireshark tcpdump wavemon netcat hping3

    sudo dpkg-reconfigure wireshark-common
    sudo adduser $USER wireshark
    
    sudo systemctl enable ssh
    sudo systemctl start ssh
    sudo dpkg-reconfigure openssh-server

    sudo reboot
fi

# Step 4 - Setup Pi as an access point
if [ $1 == 4 ]; then
    sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf-wifi
    sudo cp /etc/network/interfaces-adhoc /etc/network/interfaces
    sudo cp /etc/dhcp/dhcpd.conf-adhoc /etc/dhcp/dhcpd.conf
    sudo ip link set wlan0 down
    sudo ip link set wlan0 up
    sudo touch /etc/default/isc-dhcp-server-adhoc
    sudo sh -c 'echo "INTERFACESv4=\"wlan0\"">/etc/default/isc-dhcp-server-adhoc'
    sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server-orig
    sudo cp /etc/default/isc-dhcp-server-adhoc /etc/default/isc-dhcp-server
    sudo service isc-dhcp-server restart
    sudo reboot
fi


