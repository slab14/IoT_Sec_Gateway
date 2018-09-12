#!/bin/bash

IP=$1
PORT=$2
NAME=$3

curl -s -X POST http://$IP:$PORT/v1.37/containers/$NAME/kill
