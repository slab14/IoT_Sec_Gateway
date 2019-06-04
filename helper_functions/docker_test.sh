#!/bin/bash

CONTAINER_COUNT=$1
CONTAINER_IMAGE=$2

for ((i=0; i<$CONTAINER_COUNT; i++)); do
    sudo docker run -itd $CONTAINER_IMAGE
done
