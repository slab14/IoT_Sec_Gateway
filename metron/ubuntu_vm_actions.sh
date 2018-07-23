#!/bin/bash

sudo apt-get install -yqq squid squidclient

# call squidclient

# variables
export ZOOKEEPER=node1:2181
export BROKERLIST=node1:6667
export HDP_HOME="/usr/hdp/current"
export METRON_VERSION="0.5.0"
export METRON_HOME="/usr/metron/${METRON_VERSION}"

# Setup new Kafka topic (called squid)
${HDP_HOME}/kafka-broker/bin/kafka-topics.sh --zookeeper $ZOOKEEPER --create --topic squid --partitions 1 --replication-factor 1

# Setup indexing
echo '
{
"hdfs" : {
"index": "squid",
"batchSize": 5,
"enabled" : true
},
"elasticsearch" : {
"index": "squid",
"batchSize": 5,
"enabled" : true
},
"solr" : {
"index": "squid",
"batchSize": 5,
"enabled" : true
}
}' | sudo tee ${METRON_HOME}/config/zookeeper/indexing/squid.json


sudo sed -i ':a;N;$!ba;s/.mmdb.gz\"\n}/.mmdb.gz",\n/g' ${METRON_HOME}/config/zookeeper/global.json

echo '
"fieldValidations" : [
{
"input" : [ "ip_src_addr", "ip_dst_addr" ],
"validation" : "IP",
"config" : {
"type" : "IPV4"
}
}
]
}' | sudo tee -a ${METRON_HOME}/config/zookeeper/global.json


## Upload configuration to zookeeper
${METRON_HOME}/bin/zk_load_configs.sh -i ${METRON_HOME}/config/zookeeper -m PUSH -z $ZOOKEEPER

## Verify Updates
# ${METRON_HOME}/bin/zk_load_configs.sh -m DUMP -z $ZOOKEEPER

## Elastisearch update??
##TODO skipped for now

## Start new parser
${METRON_HOME}/bin/start_parser_topology.sh -k $BROKERLIST -z $ZOOKEEPER -s squid


## currently implementation only has 6 supervisors and all are being used
## can kill an existing topology (sensor)
storm kill bro

## Install NiFi
cd /usr/lib
sudo wget  http://public-repo-1.hortonworks.com/HDF/centos6/1.x/updates/1.2.0.0/HDF-1.2.0.0-91.tar.gz
sudo tar -zxvf HDF-1.2.0.0-91.tar.gz
cd HDF-1.2.0.0/nifi
sudo sed -i 's/nifi.web.http.port=8080/nifi.web.http.port=8089/g' conf/nifi.properties
sudo bin/nifi.sh install nifi
sudo service nifi start

## Check /etc/hosts for node1 node1
sudo sed -i '/node1\tnode1/d' /etc/hosts

## make elastic search accessible from remote
echo "
network.bind_host: 0" | sudo tee -a /etc/elasticsearch/elasticsearch.yml
sudo service elasticsearch restart

sudo sed -i 's/supervisor.slots.ports : \[6700, 6701, 6702, 6703, 6704, 6705\]/supervisor.slots.ports : [6700, 6701, 6702, 6703, 6704, 6705, 6706]/g' /etc/storm/conf/storm.yaml
sudo service storm restart
