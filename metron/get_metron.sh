s#!/bin/bash

## Dependencies
sudo apt-get install -yqq ansible npm nodejs-legacy
##assumes that docker and maven are already installed
## vagrant from distribution is v1.8.1, need v2.0+
wget https://releases.hashicorp.com/vagrant/2.1.2/vagrant_2.1.2_x86_64.deb
sudo dpkg -i vagrant_2.1.2_x86_64.deb
vagrant plugin install vagrant-hostmanager

## Setup paths
JAVA_HOME=`mvn -v | grep home | awk -F ':' '{ print $2 }' | sed 's/ //g' | tail -n 1`
MAVEN_HOME=`mvn -v | grep home | awk -F ':' '{ print $2 }' | sed 's/ //g' | head -n 1`
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environments
echo "MAVEN_HOME=$MAVEN_HOME" >> /etc/environments

## Download metron release
cd ~
wget https://github.com/apache/metron/archive/apache-metron-0.5.0-rc2.tar.gz
tar xzvf apache-metron-0.5.0-rc2.tar.gz
cd metron-apache-metron-0.5.0-rc2/

## Build
mvn clean install -DskipTests

## Install VirtualBox
sudo apt-add-repository "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib"
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo apt-get update
sudo apt-get install -yqq virtualbox-5.2
