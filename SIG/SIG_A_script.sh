#!/bin/bash

SIG_B_AS="18-ffaa:1:d13"
SIG_B_IP="128.105.145.219"
SIG_A_IP="128.105.145.216"

START_DIR=$(pwd)

sudo apt-get install -yqq apt-transport-https ca-certificates
echo "deb [trusted=yes] https://packages.netsec.inf.ethz.ch/debian all main" | sudo tee /etc/apt/sources.list.d/scionlab.list
sudo apt-get update -qq
sudo apt-get install -yqq scionlab

#SIG A:
sudo scionlab-config --host-id=72805bf4c956422b9a087af7ff512628 --host-secret=ce3462d2903347059aa1fae225e74ca4

export SC=/etc/scion
export LOGS=/var/log/scion
export IA=$(cat $SC/gen/ia)
export IAd=$(cat $SC/gen/ia | sed 's/_/\:/g')
export AS=$(cat $SC/gen/ia | cut --fields=2 --delimiter="-")
export ISD=$(cat $SC/gen/ia | cut --fields=1 --delimiter="-")

printf "\n\n${IAd},[${SIG_A_IP}]\tlocalhost" | sudo tee -a /etc/hosts

sudo systemctl start scionlab.target

#Webapp
sudo apt install -yqq scion-apps-webapp
sudo systemctl start scion-webapp


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

sudo mkdir -p ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/
cd ~
git clone -b scionlab https://github.com/netsec-ethz/scion
go build -o $GOPATH/bin/sig ~/scion/go/sig/main.go
sudo setcap cap_net_admin+eip $GOPATH/bin/sig

sudo sysctl net.ipv4.conf.default.rp_filter=0
sudo sysctl net.ipv4.conf.all.rp_filter=0
sudo sysctl net.ipv4.ip_forward=1

cd $START_DIR

# sig.conf
sudo touch ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config
cat sigA.config | sudo tee -a ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config
sudo sed -i "s/\${IA}/${IA}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config
sudo sed -i "s/\${IAd}/${IAd}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config
sudo sed -i "s/\${AS}/${AS}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config
sudo sed -i "s/\${ISD}/${ISD}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config
sudo sed -i "s/\${SC}/\/etc\/scion/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config
sudo sed -i "s/\${LOG}/${LOG}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config

#sig.json
sudo touch ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.json
cat sigA.json | sudo tee -a ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.json
sudo sed -i "s/17-ffaa:1:XXX/$SIG_B_AS/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.json
sudo sed -i "s/10.0.8.XXX/$SIG_B_IP/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.json

#update *.topology files
sed -i "s/sig17-ffaa_1_XXX"/sig${IAd}-1/g topology.json
sed -i "s/172.16.0.XX/${SIG_A_IP}/g" topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/endhost/topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/br${IA}-1/topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/bs${IA}-1/topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/cs${IA}-1/topology.json
sudo sed -i '/^{/r topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/ps${IA}-1/topology.json  


# setup
sudo modprobe dummy

# host A
sudo ip link add dummy11 type dummy
sudo ip addr add 172.16.0.11/32 brd + dev dummy11 label dummy11:0
sudo ip rule add to 172.16.12.0/24 lookup 11 prio 11

#start-up SIG
sudo mkdir -p $SC/logs/sig${IA}-1
sudo touch $SC/logs/sig${IA}-1.log
$GOPATH/bin/sig -config=${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/sigA.config 2>&1 | sudo tee -a $SC/logs/sig${IA}-1.log > /dev/null &

# teting
# Host A
sudo ip link add client type dummy
sudo ip addr add 172.16.11.1/24 brd + dev client label client:0

curl --interface 172.16.11.1 172.16.12.1:8081/hello.html

echo 'SIG setup complete'
