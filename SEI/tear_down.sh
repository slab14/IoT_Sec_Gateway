#!/bin/bash

sudo ovs-docker del-ports br0 demo_container
sudo docker kill $(sudo docker ps -a -q)
sudo ovs-ofctl del-flows br0


