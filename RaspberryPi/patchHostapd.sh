#!/bin/bash

## Incorporates patch to fix hostapd to support encrypted WiFI (WPA/WPA2) after the interface has been added as a port to an ovs bridge

sudo apt-get -yqq install build-essential git libnl-3-dev iw crda libssl-dev libnl-genl-3-200 libnl-3-200

git clone git://w1.fi/srv/git/hostap.git
git checkout hostap_2_6
cp linux_ioctl.c hostap/src/drivers/linux_ioctl.c

cd hostap/hostapd/
cp defconfig .config

sed -i 's/^#CONFIG_DRIVER_NL80211=y/CONFIG_DRIVER_NL80211=y/g' .config

## enable 802.11n and 802.11ac
#sed -i 's/^#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/g' .config
#sed -i 's/^#CONFIG_IEEE80211AC=y/CONFIG_IEEE80211AC=y/g' .config

## enable automatic channel selection
#sed -i 's/^#CONFIG_ACS=y/CONFIG_ACS=y/g' .config

make && sudo make install


