#!/bin/bash

FILE=$1
NUM=$2
START=$3
CONTS=$4

for i in `seq 1 $NUM`; do
    echo "performing test $i"
    ./multipleHttpings.sh $START $CONTS  >> $1.txt
    sleep 120
    echo "--------------------------------------------" >> $1.txt
done
echo "done"
