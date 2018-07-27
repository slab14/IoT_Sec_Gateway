#!/bin/bash

## Find VM name
VM=`VBoxManage list runningvms | awk -F '"' '{ print $2 }'`

## Port Forwarding (8080 Ambari, 5000 Kibana, 8744 Storm, 9200 Elastisearch, 8089 NiFi, 6667 Kafka, 16000 HBase, 50070 hdfs, 4201 metron alerts, 4200 metron mgmnt, 8082 swagger, 56431 supervisor for storm)
VBoxManage controlvm $VM natpf1 ,tcp,,8080,,8080
VBoxManage controlvm $VM natpf1 ,tcp,,5000,,5000
VBoxManage controlvm $VM natpf1 ,tcp,,8744,,8744
VBoxManage controlvm $VM natpf1 ,tcp,,9200,,9200
VBoxManage controlvm $VM natpf1 ,tcp,,8089,,8089
VBoxManage controlvm $VM natpf1 ,tcp,,4201,,4201
VBoxManage controlvm $VM natpf1 ,tcp,,4200,,4200

## TODO could make port forwarding specific to ip addresses
