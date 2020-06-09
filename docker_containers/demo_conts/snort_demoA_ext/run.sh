#!/bin/bash

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto
gcc -O1 -o checkHash checkHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto
gcc -O1 -o addHash addHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto

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

# setup packet signature actions
iptables -t raw -A PREROUTING -i eth1 -d 10.1.1.2 -j NFQUEUE --queue-num 2
iptables -t raw -A PREROUTING -i eth2 -d 10.1.1.2 -j NFQUEUE --queue-num 1
./checkHash &
./addHash &

# setup alert path to controller
touch ID
echo $PROTECTION_ID > ID
python getAlerts.py &

exec /usr/local/bin/snort "$@"
