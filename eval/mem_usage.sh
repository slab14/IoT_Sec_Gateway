#!/bin/bash

DATA=$(cat /proc/meminfo)

total=$(echo $DATA | grep 'MemTotal:' | awk -F 'MemTotal: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
free=$(echo $DATA | grep 'MemFree:' | awk -F 'MemFree: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
buffers=$(echo $DATA | grep 'Buffers:' | awk -F 'Buffers: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
cached=$(echo $DATA | grep 'Cached:' | awk -F 'Cached: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
swap_total=$(echo $DATA | grep 'SwapTotal:' | awk -F 'SwapTotal: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
swap_free=$(echo $DATA | grep 'SwapFree:' | awk -F 'SwapFree: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
slab=$(echo $DATA | grep 'Slab:' | awk -F 'Slab: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
Srec=$(echo $DATA | grep 'SReclaimable:' | awk -F 'SReclaimable: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
Sunrec=$(echo $DATA | grep 'SUnreclaim:' | awk -F 'SUnreclaim: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
swap_cache=$(echo $DATA | grep 'SwapCached:' | awk -F 'SwapCached: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')
dirty=$(echo $DATA | grep 'Dirty:' | awk -F 'Dirty: ' '{ print $2 }' | awk -F ' kB' '{ print $1 }')

used=$((total-free-buffers-cached-slab))
swap_used=$((swap_total-swap_free-swap_cache))

Mem_Percent=$(awk "BEGIN {print $used/$total*100}")
Swap_Percent=$(awk "BEGIN {print $swap_used/$swap_total*100}")

echo $Mem_Percent $Swap_Percent
