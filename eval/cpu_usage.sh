#!/bin/bash

DATA=$(cat /proc/stat | grep 'cpu ')

user=$(echo $DATA | awk -F ' ' '{ print $2 }')
nice=$(echo $DATA | awk -F ' ' '{ print $3 }')
system=$(echo $DATA | awk -F ' ' '{ print $4 }')
idle=$(echo $DATA | awk -F ' ' '{ print $5 }')
iowait=$(echo $DATA | awk -F ' ' '{ print $6 }')
irq=$(echo $DATA | awk -F ' ' '{ print $7 }')
softirq=$(echo $DATA | awk -F ' ' '{ print $8 }')
steal=$(echo $DATA | awk -F ' ' '{ print $9 }')


Idle=$((idle + iowait))
NonIdle=$((user+nice+system+irq+softirq+steal))
Total=$((Idle+NonIdle))

CPU_Percent=$(awk "BEGIN {print ($Total - $Idle)/$Total*100}")
echo $CPU_Percent
