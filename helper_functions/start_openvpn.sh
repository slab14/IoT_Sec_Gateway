#!/bin/bash

IMGNAME=$1
CONTIP=$2
DEVIP=$3
CLIENTNAME=$4
CONTNAME=$5
BRIDGE=$6

cd ~
mkdir -p vpn
# Generate the openvpn config file
# options: -N = NAT, -d = disable default, -t = use TAP interfaces (Layer 2), -u = specify IP address of server, -p = push info
# options: -a = auth, -T = TLS cipher, -C = cipher 
sudo docker run -v $PWD/vpn:/etc/openvpn --rm $IMGNAME ovpn_genconfig -N -d -t -u udp://$CONTIP -p "route 192.1.0.0 255.255.0.0"

# Generate cryto stuff
sudo docker run -v $PWD/vpn:/etc/openvpn --rm -it $IMGNAME ovpn_initpki
sudo docker run -v $PWD/vpn:/etc/openvpn -it --rm $IMGNAME easyrsa build-client-full $CLIENTNAME nopass
sudo docker run -v $PWD/vpn:/etc/openvpn --rm $IMGNAME ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn

# Start VPN container
sudo docker run -v $PWD/vpn:/etc/openvpn --rm -d -p 1194:1194/udp --cap-add=NET_ADMIN --network=none --name=$CONTNAME $IMGNAME

# Add interfaces
sudo ovs-docker add-port $BRIDGE eth0 $CONTNAME --ipaddress=$CONTIP/16
sudo ovs-docker add-port $BRIDGE eth1 $CONTNAME --ipaddress=$DEVIP/16

sudo docker exec $CONTNAME /sbin/iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# Instructions from: https://medium.com/@gurayy/set-up-a-vpn-server-with-docker-in-5-minutes-a66184882c45

# git repository: git clone https://github.com/kylemanna/docker-openvpn.git

# client routing requires (destination address) XX.XX.XX.XX/Y via 192.168.255.1 dev tap0 
