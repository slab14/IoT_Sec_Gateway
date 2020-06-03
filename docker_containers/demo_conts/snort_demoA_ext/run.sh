#!/bin/bash

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto

while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
	break

    sleep 1

done

if [[ ! -s /etc/snort/snort.conf ]]; then
    mv /etc/snort/snort.conf.default /etc/snort/snort.conf
fi

if [[ ! -s /etc/snort/rules/local.rules ]]; then
    mv /etc/snort/rules/local.rules.default /etc/snort/rules/local.rules    
fi

# setup alert path to controller
touch ID
echo $PROTECTION_ID > ID
python getAlerts.py &

exec /usr/local/bin/snort "$@"
