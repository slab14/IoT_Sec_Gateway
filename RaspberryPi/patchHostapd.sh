#!/bin/bash

## Incorporates patch to fix hostapd to support encrypted WiFI (WPA/WPA2) after the interface has been added as a port to an ovs bridge

## Does not compile with OpenSSL v1.1.0 (type change in libssl, requires v1.0.2)
sudo apt-get -yqq install build-essential git libnl-3-dev libnl-genl-3-dev iw crda libssl1.0-dev libnl-genl-3-200 libnl-3-200

cd ~
git clone git://w1.fi/srv/git/hostap.git
cd hostap
git checkout hostap_2_6
cp ../linux_ioctl.c src/drivers/linux_ioctl.c

cd hostapd/
cp defconfig .config

sed -i 's/^#CONFIG_DRIVER_NL80211=y/CONFIG_DRIVER_NL80211=y/g' .config
sed -i 's/^#CONFIG_LIBNL32=y/CONFIG_LIBNL32=y/g' .config

## enable 802.11n and 802.11ac
#sed -i 's/^#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/g' .config
#sed -i 's/^#CONFIG_IEEE80211AC=y/CONFIG_IEEE80211AC=y/g' .config

## enable automatic channel selection
#sed -i 's/^#CONFIG_ACS=y/CONFIG_ACS=y/g' .config

make && sudo make install


