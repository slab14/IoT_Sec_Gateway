#!/bin/bash

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto
gcc -O1 -o checkHash checkHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto
gcc -O1 -o addHash addHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto


while true; do
    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
	break
    sleep 1
done



#------------------------#
touch ID                 
echo $PROTECTION_ID > ID 
touch IOT_IP             
echo $iot_IP > IOT_IP  
cont_IP=$(hostname -I | awk '{print $NF}')  #prints the last word from 'hostname -I' command
touch CONT_IP
echo $cont_IP > CONT_IP
#------------------------#

while grep -q 0.0.0.0 "IOT_IP"; do
    sleep 1
done


#make sure we can ping the IoT
while ! ping -c1 '192.1.1.2' &>/dev/null;  do 
    echo "Ping Fail - `date`" > /tmp/pingtest.out
    sleep 1
done
echo "Ping Success - `date`" > /tmp/pingtest.out 

if [ ! -f "/var/log/nmap.log" ]; then
	touch /var/log/nmap.log
fi

# setup packet signature actions (q1 = verify // q2 = sign)
iptables -t raw -A PREROUTING -i eth1 -s $iot_IP -j NFQUEUE --queue-num 1
iptables -t raw -A OUTPUT -o eth1 -d $iot_IP -j NFQUEUE --queue-num 2
./checkHash &
./addHash &

nmap -T5 -Pn --script vuln IOT_IP -oX /var/log/nmap.log --send-ip > /dev/null #remove any printing
python sendAlert.py

/bin/bash
