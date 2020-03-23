#!/bin/bash

SIG_A_AS="18-ffaa_1_d12"
SIG_A_IP="128.105.145.216"

START_DIR=$(pwd)

sudo apt-get install apt-transport-https ca-certificates
echo "deb [trusted=yes] https://packages.netsec.inf.ethz.ch/debian all main" | sudo tee /etc/apt/sources.list.d/scionlab.list
sudo apt-get update
sudo apt-get install scionlab

#SIG B:
sudo scionlab-config --host-id=329acd1a195c40c0a9e1b5064060d4bd --host-secret=0542629f113749349110b1d728e2ba2c

#Webapp
sudo apt install scion-apps-webapp
sudo systemctl start scion-webapp

export SC=/etc/scion
export LOGS=/var/log/scion

# configure golang build environment
echo 'export GOPATH="$HOME/go"' >> ~/.profile
echo 'export PATH="$HOME/.local/bin:$GOPATH/bin:/usr/local/go/bin:$PATH"' >> ~/.profile
source ~/.profile
mkdir -p "$GOPATH"
# install golang
cd ~
curl -O https://dl.google.com/go/go1.11.13.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.11.13.linux-amd64.tar.gz
# download scionlab's fork of scion and build and install sig
cd ~
git clone https://github.com/netsec-ethz/scion
cd ~/scion/go/sig
go install

export IA=$(cat $SC/gen/ia)
export IAd=$(cat $SC/gen/ia | sed 's/_/\:/g')
export AS=$(cat $SC/gen/ia | cut --fields=2 --delimiter="-")
export ISD=$(cat $SC/gen/ia | cut --fields=1 --delimiter="-")
sudo mkdir -p ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/
cd ~
git clone -b scionlab https://github.com/netsec-ethz/scion
go build -o $GOPATH/bin/sig ~/scion/go/sig/main.go
sudo setcap cap_net_admin+eip $GOPATH/bin/sig

sudo sysctl net.ipv4.conf.default.rp_filter=0
sudo sysctl net.ipv4.conf.all.rp_filter=0
sudo sysctl net.ipv4.ip_forward=1

cd $START_DIR

#sig.conf
sudo touch ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config
cat sigB.config | sudo tee -a ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config
sudo sed -i "s/\${IA}/${IA}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config
sudo sed -i "s/\${IAd}/${IAd}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config
sudo sed -i "s/\${AS}/${AS}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config
sudo sed -i "s/\${ISD}/${ISD}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config
sudo sed -i "s/\${SC}/\/etc\/scion/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config
sudo sed -i "s/\${LOG}/${LOG}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config

#sig.json
sudo touch ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.json
cat sigB.json | sudo tee -a ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.json
sudo sed -i "s/17-ffaa:1:XXX/$SIG_A_AS/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.json
sudo sed -i "s/10.0.8.XXX/$SIG_A_IP/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.json

#update *.topology files
sed -i "s/sig17-ffaa_1_XXX"/sig${ISD}-${ASD}/g topology.json
sed -i "s/172.16.0.XX/${SIG_B_IP}/g" topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/endhost/topology.json	
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/br${IA}-1/topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/bs${IA}-1/topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/cs${IA}-1/topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/ps${IA}-1/topology.json

# setup
sudo modprobe dummy

# Host B
sudo ip link add dummy12 type dummy
sudo ip addr add 172.16.0.12/32 brd + dev dummy12 label dummy12:0

sudo ip rule add to 172.16.11.0/24 lookup 12 prio 12

$GOPATH/bin/sig -config=${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigB.config > $SC/logs/sig${IA}-1.log 2>&1 &

# teting
# Host B
sudo ip link add server type dummy
sudo ip addr add 172.16.12.1/24 brd + dev server label server:0

mkdir $SC/WWW
echo "Hello World!" > $SC/WWW/hello.html
cd $SC/WWW/ && python3 -m http.server --bind 172.16.12.1 8081 &

echo "SIG setup complete"
