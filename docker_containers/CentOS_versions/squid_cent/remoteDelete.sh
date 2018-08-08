#!/bin/bash

IP=$1
PORT=$2
NAME=$3
UNAME=$4
PASS=$5

EXEC_ID=`curl -s -X POST -H "Content-Type: application/json" http://$IP:$PORT/v1.37/containers/$NAME/exec -d '{"AttachStdin": true, "AttachStdout": true, "Tty": true, "Cmd": ["/remove_password.sh",  "'$UNAME'",  "'$PASS'"]}' | jq -r '.Id'`

curl -s -X POST -H "Content-Type: application/json" http://$IP:$PORT/v1.37/exec/$EXEC_ID/start -d '{"Detach": false, "Tty": true}'
