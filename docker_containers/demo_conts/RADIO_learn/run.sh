#!/bin/bash

gcc -fPIC -shared -o send.so sendAlert.c -lcrypto
#gcc -O1 -o checkHash checkHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto
#gcc -O1 -o addHash addHash.c -lnfnetlink -lnetfilter_queue -lpthread -lm -ldl -lssl -lcrypto

mkdir radio
mkdir bro
mkdir send

mv Bro2Model.java radio/.
mv *.zeek bro/.
mv *.pcapng bro/.

javac radio/Bro2Model.java

#while true; do
#    grep -q '^1$' "/sys/class/net/eth1/carrier" &&
#	grep -q '^1$' "/sys/class/net/eth2/carrier" &&
#	break
#    sleep 1
#done

#brctl addbr bridge0
#ifconfig eth1 down
#ifconfig eth2 down
#brctl addif bridge0 eth1 eth2
#ifconfig eth1 up
#ifconfig eth2 up
#ifconfig bridge0 up


# setup alert path to controller
touch ID
echo $PROTECTION_ID > ID
touch IOT_IP
echo $iot_IP > IOT_IP



# setup packet signature actions
#iptables -t raw -A PREROUTING -i bridge1 -j NFQUEUE --queue-num 1
#iptables -t filter -A FORWARD -i bridge1 -j NFQUEUE --queue-num 2
#iptables -t raw -A PREROUTING -i bridge2 -j NFQUEUE --queue-num 1
#iptables -t filter -A FORWARD -i bridge2 -j NFQUEUE --queue-num 2
# ./checkHash &
# ./addHash &


## simulate pcap capture



## Analyze pcap with bro/zeek
cd bro
bro -C -r U.pcapng printer_http.zeek
cd ..


## Once pcap analyzed generate FSM
cd radio
java Bro2Model ../bro/radio_http_msgs.log
mv model.txt ../send/.
mv proto.txt ../send/.
cd ..

## send to controller
python getAlerts.py 




/bin/bash
