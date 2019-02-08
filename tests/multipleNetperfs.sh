#!/bin/bash

START=$1
NUM=$2
TEST=$3

TOTAL=$(($NUM-1))

## old port values: 31337

for i in `seq 0 $TOTAL`; do
    #    echo $(($START+$i))
    VAL=$(($START+$i))
    if [ $TEST -eq 1 ]; then
	netperf -H 192.168.42.$VAL -p 7331 -l 30 -P 0 &
    else
	netperf -P 0 -t TCP_RR -H 192.168.42.$VAL -p 7331 -- -r 1,1 -o P50_LATENCY,P90_LATENCY,P99_LATENCY &
    fi
done

