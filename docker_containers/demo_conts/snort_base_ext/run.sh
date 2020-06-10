#!/bin/bash

gcc -I. -fPIC -shared -o send.so sendHypAlert.c -ldl libuhcall.a
gcc -O1 -I. -o checkHash checkHypHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl libuhcall.a
gcc -O1 -I. -o addHash addHypHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl libuhcall.a

# setup alert path to controller
touch ID
echo $PROTECTION_ID > ID
python getAlerts.py &

if [[ ! -s /etc/snort/snort.conf ]]; then
    mv /etc/snort/snort.conf.default /etc/snort/snort.conf
fi

if [[ ! -s /etc/snort/rules/local.rules ]]; then
    mv /etc/snort/rules/local.rules.default /etc/snort/rules/local.rules    
fi

while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
	break

    sleep 1

done

# setup packet signature actions
iptables -t raw -A PREROUTING -i eth1 -d 10.1.1.2 -j NFQUEUE --queue-num 2
iptables -t raw -A PREROUTING -i eth2 -d 10.1.1.2 -j NFQUEUE --queue-num 1
./checkHash &
./addHash &

/usr/local/bin/snort $SNORT_CMD &

/bin/bash
