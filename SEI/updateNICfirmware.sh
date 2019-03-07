#!/bin/bash

cd ~

wget https://downloadmirror.intel.com/28332/eng/XL710_NVMUpdatePackage_v6_01_Linux.tar.gz

sudo mkdir -p /usr/local/src/i40e

sudo mv XL710_NVMUpdatePackage_v6_01_Linux.tar.gz /usr/local/src/i40e/
cd /usr/local/src/i40e

sudo tar xzf XL710_NVMUpdatePackage_v6_01_Linux.tar.gz

cd XL170/Linux_x64

sudo ./nvmupdate64e
