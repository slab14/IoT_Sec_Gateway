#!/bin/bash

JAVA_HOME=`mvn -v | grep home | awk -F ':' '{ print $2 }' | sed 's/ //g' | tail -n 1`
MAVEN_HOME=`mvn -v | grep home | awk -F ':' '{ print $2 }' | sed 's/ //g' | head -n 1`
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environments
echo "MAVEN_HOME=$MAVEN_HOME" >> /etc/environments

