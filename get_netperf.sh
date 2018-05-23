#!/bin/bash

git clone https://github.com/HewlettPackard/netperf.git
cd netperf

git checkout netperf-2.7.0
./autogen.sh
./configure
make
sudo make install
