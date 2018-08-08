#!/bin/bash

IP=$1
PORT=$2
NAME=$3
IMAGE=$4
UNAME=$5
PASS=$6

curl -s -X POST -H "Content-Type: application/json" http://$IP:$PORT/v1.37/containers/create?name=$NAME -d '{"Image": "'"$IMAGE"'", "Cmd": ["/bin/sh"], "HostConfig": {"AutoRemove": true}, "Tty": true, "Env": ["USERNAME='"$UNAME"'", "PASSWORD='"$PASS"'"]}'

curl -s -X POST http://$IP:$PORT/v1.37/containers/$NAME/start
