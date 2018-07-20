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
echo"{
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
}" | sudo tee ${METRON_HOME}/config/zookeeper/indexing/squid.json


sudo sed -i ':a;N;$!ba;s/.mmdb.gz\"\n}/.mmdb.gz",\n/g' ${METRON_HOME}/config/zookeeper/global.json

echo '"fieldValidations" : [
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
