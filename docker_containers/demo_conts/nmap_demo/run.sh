#!/bin/bash

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto
#gcc -O1 -o checkHash checkHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto
#gcc -O1 -o addHash addHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto


while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	
	break

    sleep 1

done

#make sure we can ping the IoT

while ! ping -c1 '192.1.1.2' &>/dev/null
        do 
            echo "Ping Fail - `date`" > /tmp/pingtest.out
            sleep 1
done
echo "Ping Success - `date`" > /tmp/pingtest.out 

#------------------------#
touch ID                 
echo $PROTECTION_ID > ID 
touch IOT_IP             
echo $iot_IP > IOT_IP    
#------------------------#

if [ ! -f "/var/log/nmap.log" ]; then
	touch /var/log/nmap.log
fi

python getAlerts.py &
sleep 5
nmap -iL IOT_IP -oX /var/log/nmap.log --send-ip > /dev/null #remove any printing

<< ////
if [ -z "$MAX_CONN" ]; then
    MAX_CONN="6"
fi

if [ -z "$CONN_MASK" ]; then
    CONN_MASK="32"
fi

if [ -z "$MAX_RATE" ]; then
    MAX_RATE="1500"
fi

if [ -z "$MODE" ]; then
    MODE="srcip,srcport,dstip,dstport"
fi
////

# # setup packet signature actions
# iptables -t raw -A PREROUTING -i eth1 -d 10.1.1.2 -j NFQUEUE --queue-num 2
# iptables -t raw -A PREROUTING -i eth2 -d 10.1.1.2 -j NFQUEUE --queue-num 1
# ./checkHash &
# ./addHash &

/bin/bash
