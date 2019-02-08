#!/bin/bash

START=$1
NUM=$2

TOTAL=$(($NUM-1))

for i in `seq 0 $TOTAL`; do
    #    echo $(($START+$i))
    VAL=$(($START+$i))
    httping -S -G 192.168.42.$VAL:8000 -v -i 1 -c 100 &
done

