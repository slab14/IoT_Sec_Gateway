#!/bin/bash

update_es() {
    curl -XPUT 'http://node1:9200/_template/squid_index' -d '
{
  "template": "squid_index*",
  "mappings": {
    "squid_doc": {
      "dynamic_templates": [
      {
        "geo_location_point": {
          "match": "enrichments:geo:*:location_point",
          "match_mapping_type": "*",
          "mapping": {
            "type": "geo_point"
          }
        }
      },
      {
        "geo_country": {
          "match": "enrichments:geo:*:country",
          "match_mapping_type": "*",
          "mapping": {
            "type": "keyword"
          }
        }
      },
      {
        "geo_city": {
          "match": "enrichments:geo:*:city",
          "match_mapping_type": "*",
          "mapping": {
            "type": "keyword"
          }
        }
      },
      {
        "geo_location_id": {
          "match": "enrichments:geo:*:locID",
          "match_mapping_type": "*",
          "mapping": {
            "type": "keyword"
          }
        }
      },
      {
        "geo_dma_code": {
          "match": "enrichments:geo:*:dmaCode",
          "match_mapping_type": "*",
          "mapping": {
            "type": "keyword"
          }
        }
      },
      {
        "geo_postal_code": {
          "match": "enrichments:geo:*:postalCode",
          "match_mapping_type": "*",
          "mapping": {
            "type": "keyword"
          }
        }
      },
      {
        "geo_latitude": {
          "match": "enrichments:geo:*:latitude",
          "match_mapping_type": "*",
          "mapping": {
            "type": "float"
          }
        }
      },
      {
        "geo_longitude": {
          "match": "enrichments:geo:*:longitude",
          "match_mapping_type": "*",
          "mapping": {
            "type": "float"
          }
        }
      },
      {
        "timestamps": {
          "match": "*:ts",
          "match_mapping_type": "*",
          "mapping": {
            "type": "date",
            "format": "epoch_millis"
          }
        }
      },
      {
        "threat_triage_score": {
          "mapping": {
            "type": "float"
          },
          "match": "threat:triage:*score",
          "match_mapping_type": "*"
        }
      },
      {
        "threat_triage_reason": {
          "mapping": {
            "type": "text",
            "fielddata": "true"
          },
          "match": "threat:triage:rules:*:reason",
          "match_mapping_type": "*"
        }
      },
      {
        "threat_triage_name": {
          "mapping": {
            "type": "text",
            "fielddata": "true"
          },
          "match": "threat:triage:rules:*:name",
          "match_mapping_type": "*"
        }
      }
      ],
      "properties": {
        "timestamp": {
          "type": "date",
          "format": "epoch_millis"
        },
        "source:type": {
          "type": "keyword"
        },
        "ip_dst_addr": {
          "type": "ip"
        },
        "ip_dst_port": {
          "type": "integer"
        },
        "ip_src_addr": {
          "type": "ip"
        },
        "ip_src_port": {
          "type": "integer"
        },
        "alert": {
          "type": "nested"
        },
        "guid": {
          "type": "keyword"
        }
      }
    }
  }
}
'
}


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
echo '{
"elasti" :csearch": {
"index": "squid",
"batchSize": 5,
"enabled" : true
},
"hdfs" : {
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

## Elastisearch update??
update_es

## Upload configuration to zookeeper
${METRON_HOME}/bin/zk_load_configs.sh -i ${METRON_HOME}/config/zookeeper -m PUSH -z $ZOOKEEPER

## Start new parser
${METRON_HOME}/bin/start_parser_topology.sh -k $BROKERLIST -z $ZOOKEEPER -s squid

## currently implementation only has 6 supervisors and all are being used
## can kill an existing topology (sensor)
#storm kill bro

## Install NiFi
#cd /usr/lib
#sudo wget  http://public-repo-1.hortonworks.com/HDF/centos6/1.x/updates/1.2.0.0/HDF-1.2.0.0-91.tar.gz
#sudo tar -zxvf HDF-1.2.0.0-91.tar.gz
#cd HDF-1.2.0.0/nifi
#sudo sed -i 's/nifi.web.http.port=8080/nifi.web.http.port=8089/g' conf/nifi.properties
#sudo bin/nifi.sh install nifi
#sudo service nifi start

## Check /etc/hosts for node1 node1
#sudo sed -i '/node1\tnode1/d' /etc/hosts

## make elastic search accessible from remote
echo "
network.bind_host: 0" | sudo tee -a /etc/elasticsearch/elasticsearch.yml
sudo service elasticsearch restart

## kafka changes
sudo sed -i 's/listeners=PLAINTEXT:\/\/localhost:6667/listeners=PLAINTEXT:\/\/0.0.0.0:6667/g' /etc/kafka/conf/server.properties
echo '
advertised.listeners=PLAINTEXT://node1:6667' | sudo tee -a /etc/kafka/conf/server.properties

