#!/bin/bash

IP=$1
PORT=$2
NAME=$3
IMAGE=$4
CONFIG=$5
RULES=$6

curl -s -X POST -H "Content-Type: application/json" http://$IP:$PORT/v1.37/containers/create?name=$NAME -d '{"Image": "'"$IMAGE"'", "Cmd": ["/bin/sh"], "HostConfig": {"AutoRemove": true}, "Tty": true}'

tar cf $CONFIG.tar $CONFIG
tar cf $RULES.tar $RULES

curl -s -X PUT -T $CONFIG.tar http://$IP:$PORT/v1.37/containers/$NAME/archive?path=/etc/snort
curl -s -X PUT -T $RULES.tar http://$IP:$PORT/v1.37/containers/$NAME/archive?path=/etc/snort/rules

curl -s -X POST http://$IP:$PORT/v1.37/containers/$NAME/start 
