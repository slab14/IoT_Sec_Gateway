#!/bin/bash

FILE=$1
NUM=$2
START=$3
CONTS=$4
TEST=$5

for i in `seq 1 $NUM`; do
    echo "performing test $i"
    ./multipleNetperfs.sh $START $CONTS $TEST >> $1.txt
    sleep 40
    echo "--------------------------------------------" >> $1.txt
done
echo "done"
