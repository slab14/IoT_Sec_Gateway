#!/bin/bash

FILE=/etc/radio/model2

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto
#gcc -O1 -o checkHash checkHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto
#gcc -O1 -o addHash addHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto



while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
	break
    sleep 1
done

brctl addbr bridge0
ifconfig eth1 down
ifconfig eth2 down
brctl addif bridge0 eth1 eth2
ifconfig eth1 up
ifconfig eth2 up
ifconfig bridge0 up


# setup alert path to controller
touch ID
echo $PROTECTION_ID > ID
touch IOT_IP
echo $iot_IP > IOT_IP
touch /etc/radio/modbus.rules


while grep -q 0.0.0.0 "IOT_IP"; do
	sleep 1
done


if [ -f "$FILE" ]; then	
	
	python getAlerts.py &
	sleep 5
	python3.6 model2rule.py
	
else
	# capture pcap and convert to model2
	touch FAIL.txt
	echo "We currently don't support converting pcap to model2 yet"
fi





# setup packet signature actions
#iptables -t raw -A PREROUTING -i bridge1 -j NFQUEUE --queue-num 1
#iptables -t filter -A FORWARD -i bridge1 -j NFQUEUE --queue-num 2
#iptables -t raw -A PREROUTING -i bridge2 -j NFQUEUE --queue-num 1
#iptables -t filter -A FORWARD -i bridge2 -j NFQUEUE --queue-num 2
# ./checkHash &
# ./addHash &

/bin/bash
