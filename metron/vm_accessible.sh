#!/bin/bash

## Find VM name
VM=`VBoxManage list runningvms | awk -F '"' '{ print $2 }'`

## Port Forwarding (8080 Ambari, 5000 Kibana, 8744 Storm, 9200 Elastisearch, 8089 NiFi, 6667 Kafka, 16000 HBase, 50070 hdfs)
VBoxManage controlvm $VM natpf1 ,tcp,,8080,,8080
VBoxManage controlvm $VM natpf1 ,tcp,,5000,,5000
VBoxManage controlvm $VM natpf1 ,tcp,,8744,,8744
VBoxManage controlvm $VM natpf1 ,tcp,,9200,,9200
VBoxManage controlvm $VM natpf1 ,tcp,,8089,,8089
VBoxManage controlvm $VM natpf1 ,tcp,,6667,,6667
VBoxManage controlvm $VM natpf1 ,tcp,,16000,,16000
VBoxManage controlvm $VM natpf1 ,tcp,,50070,,50070

## TODO could make port forwarding specific to ip addresses
