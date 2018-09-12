#!/bin/bash

sudo ovs-docker del-ports demo snort-demo
sudo docker kill snort-demo
sudo docker rm snort-demo
