#!/bin/bash

CONTAINER_COUNT=$1

for ((i=0; i<$CONTAINER_COUNT; i++)); do
    sudo docker run -itd count_box
done
