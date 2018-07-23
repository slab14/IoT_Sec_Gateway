#!/bin/bash

## Find VM name
VM=`VBoxManage list runningvms | awk -F '"' '{ print $2 }'`

## Port Forwarding (8080 Ambari, 5000 Kibana, 8744 Storm, 9200 Elastisearch, 8089 NiFi)
VBoxManage controlvm $VM natpf1 ,tcp,,8080,,8080
VBoxManage controlvm $VM natpf1 ,tcp,,5000,,5000
VBoxManage controlvm $VM natpf1 ,tcp,,8744,,8744
VBoxManage controlvm $VM natpf1 ,tcp,,9200,,9200
VBoxManage controlvm $VM natpf1 ,tcp,,8089,,8089

## TODO could make port forwarding specific to ip addresses
