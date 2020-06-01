#!/bin/bash

ADDR=$1
FILE=$2
NUM=$3
MTU=$4
REPS=$5

options=""
if [ ! -z $MTU ]; then
    options="-M $MTU"
fi

IP=$ADDR

for j in `seq 1 $REPS`; do
    ADDR=$IP
    PORT=5202
    for i in `seq 0 $(($NUM - 1))`; do
	iperf3 -O 10 -i 1 -t 30 $options -c $ADDR -p $PORT --logfile $FILE$j$i.txt &
	PORT=$(($PORT + 1))
	ADDR=$(awk -F\. '{ print $1"."$2"."$3"."$4+1 }' <<< $ADDR )
    done
    PIDS=1
    while [ ! -z $PID ]; do
	sleep 1
	PIDS=$(pgrep iperf3)
    done
done

echo "Done!"
