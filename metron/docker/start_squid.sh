#!/bin/bash

if [ -z $1 ]; then
    sudo docker run -itd --rm -v /mnt/slab/squid/log/:/var/log/squid/ squid
else
    sudo docker run -itd --rm --name $1 -v /mnt/slab/squid/log/:/var/log/squid/ squid
fi
