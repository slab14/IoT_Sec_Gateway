#/!bin/bash

if [ -z $1 ]; then
    PORT=6677
else
    PORT=$1
fi


# Add a remote tcp port to listen on:
sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:$PORT
