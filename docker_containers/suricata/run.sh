#!/bin/bash

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
#	grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break

    sleep 1

done


#if [[ ! -s /etc/snort/snort.conf ]]; then
#    mv /etc/snort/snort.conf.default /etc/snort/snort.conf
#fi

exec /root/suricata_src/suricata-4.1.4/src/suricata "$@"
