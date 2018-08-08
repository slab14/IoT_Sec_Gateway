#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
	break

    sleep 1

    if [[ ! -s /etc/snort/snort.conf ]]; then
	mv /etc/snort/snort.conf.default /etc/snort/snort.conf
    fi
    
    if [[ ! -s /etc/snort/rules/local.rules ]]; then
        mv /etc/snort/rules/local.rules.default /etc/snort/rules/local.rules
    fi

done

exec /usr/local/bin/snort "$@"
