#!/bin/bash

sudo apt-get update
sudo apt-get install -yqq libelf-dev 

VERSION='2.4.6'

cd ~
# driver 2.7.26
#wget https://downloadmirror.intel.com/28507/eng/i40e-2.7.26.tar.gz
# driver 2.4.6
wget https://downloadmirror.intel.com/27869/eng/i40e-$VERSION.tar.gz

sudo mkdir -p /usr/local/src/i40e

sudo mv i40e-$VERSION.tar.gz /usr/local/src/i40e/i40e-$VERSION.tar.gz

cd /usr/local/src/i40e

sudo tar zxf i40e-$VERSION.tar.gz
cd i40e-$VERSION/src
sudo make
sudo make install
sudo rmmod i40e
sudo modprobe i40e
