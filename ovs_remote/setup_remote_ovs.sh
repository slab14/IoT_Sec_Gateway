#!bin/bash

PORT=$1

# Add a remote tcp port to listen on:
sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:$PORT
