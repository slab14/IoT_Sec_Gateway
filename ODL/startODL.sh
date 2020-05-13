#!/bin/bash

DIR=$(pwd)
if [[ $DIR == *"IoT_Sec_Gateway"* ]]; then
    DIR=$(echo $DIR | cut -d '/' -f -3)
fi
if [[ $DIR == *"l2switch"* ]]; then
    DIR=$(echo $DIR | cut -d '/' -f -3)
fi
# for some reason, maven is not downloading the jar for org.apache.karaf.jaas.boot:4.1.7, so we can manually download this.
FILE="$DIR/l2switch/distribution/karaf/target/assembly/system/org/apache/karaf/jaas/org.apache.karaf.jaas.boot/4.1.7/org.apache.karaf.jaas.boot-4.1.7.jar"
# first check if we have already installed it.
if [[ ! -f "$FILE" ]]; then
    touch $FILE
    wget -q -O - https://repo1.maven.org/maven2/org/apache/karaf/jaas/org.apache.karaf.jaas.boot/4.1.7/org.apache.karaf.jaas.boot-4.1.7.jar > $DIR/l2switch/distribution/karaf/target/assembly/system/org/apache/karaf/jaas/org.apache.karaf.jaas.boot/4.1.7/org.apache.karaf.jaas.boot-4.1.7.jar
fi

# start ODL
cd $DIR/l2switch/distribution/karaf/target/assembly
./bin/karaf
