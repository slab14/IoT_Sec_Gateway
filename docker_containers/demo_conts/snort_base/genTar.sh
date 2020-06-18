#!/bin/bash

if [ -f "local.rules" ]; then
        echo "Found local.rules"
else
        echo "Missing local.rules.  Creating one..."
        touch local.rules
fi

echo "Tarrring rules_a"
echo "alert icmp any any -> 10.1.1.0/24 any (msg:"ICMP Packet"; itype:8; sid:10000001; rev:1;)
" > local.rules
tar -cf rules_a.tar local.rules
echo "Tarring rules_b"
echo "drop icmp any any -> 10.1.1.0/24 any (msg:"ICMP Packet"; itype:8; sid:10000001; rev:1;)
alert tcp any any -> 10.1.1.0/24 any (msg:"TCP Packet"; sid:10000002; rev:1;)" > local.rules
tar -cf rules_b.tar local.rules

if [ -f "snort.config" ]; then
        echo "Found snort.conf"
else
        echo "Missing snort.conf.  Creating one..."
        touch snort.conf
fi

echo "Tarring conf"
echo "config show_year
output alert_csv
include rules/local.rules" > snort.conf
tar -cf config.tar snort.conf

echo "moving to dataplane's /etc/IoT_Sec/ folder"
sudo mkdir -p /etc/IoT_Sec/
mv rules_a.tar /etc/IoT_Sec/
mv rules_b.tar /etc/IoT_Sec/
mv config.tar /etc/IoT_Sec/
