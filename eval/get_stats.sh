#!/bin/bash

if [ -z $SLEEP_TIME ]; then
    SLEEP_TIME=1
fi

getvals(){
    CPU=$(source cpu_usage.sh)
    Mem=$(source mem_usage.sh | awk -F ' ' '{ print $1 }')
    Swp=$(source mem_usage.sh | awk -F ' ' '{ print $2 }')
    printf -v data ' %03.5f\t %03.5f\t %03.5f' "$CPU" "$Mem" "$Swp"
}

echo "CPU%    Mem%    Swap%"
while true; do
    getvals
    echo $data
    sleep $SLEEP_TIME
done
