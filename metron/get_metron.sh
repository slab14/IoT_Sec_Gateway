#!/bin/bash

## Dependencies
sudo apt-get install -yqq ansible vagrant npm nodejs-legacy
##assumes that docker and maven are already installed

## Download metron release
cd ~
wget https://github.com/apache/metron/archive/apache-metron-0.5.0-rc2.tar.gz
tar xzvf apache-metron-0.5.0-rc2.tar.gz
cd metron-apache-metron-0.5.0-rc2/

## Build
mvn clean install -DskipTests

