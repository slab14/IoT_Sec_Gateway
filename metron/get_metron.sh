#!/bin/bash

install_docker() {
    sudo apt-get update -qq
    sudo apt-get install -yqq apt-transport-https \
	 ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -qq
    sudo apt-get install -yqq docker-ce

    sudo systemctl start docker
    sudo systemctl enable docker
}

## Dependencies
sudo apt-get update -qq
sudo apt-get install -yqq ansible npm nodejs-legacy maven
## JAVA
# sudo add-apt-repository ppa:webupd8team/java
# sudo apt-get update -qq
# sudo apt-get install -yqq oracle-java8-installer
##assumes that docker and maven are already installed
sudo apt-get install -yqq default-jdk default-jre
install_docker
sudo usermod -a -G docker $USER
## vagrant from distribution is v1.8.1, need v2.0+
wget https://releases.hashicorp.com/vagrant/2.1.2/vagrant_2.1.2_x86_64.deb
sudo dpkg -i vagrant_2.1.2_x86_64.deb
vagrant plugin install vagrant-hostmanager

## Setup paths
export JAVA_HOME=`mvn -v | grep home | awk -F ':' '{ print $2 }' | sed 's/ //g' | tail -n 1`
export MAVEN_HOME=`mvn -v | grep home | awk -F ':' '{ print $2 }' | sed 's/ //g' | head -n 1`
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environments
echo "MAVEN_HOME=$MAVEN_HOME" >> /etc/environments

## Download metron release
# cd ~
# wget https://github.com/apache/metron/archive/apache-metron-0.5.0-rc2.tar.gz
# tar xzvf apache-metron-0.5.0-rc2.tar.gz
# cd metron-apache-metron-0.5.0-rc2/
cd /mnt
git clone https://github.com/slab14/metron.git
cd metron
git checkout Metron_0.5.0

## Build
# mvn clean install -DskipTests
mvn package -DskipTests -T 2C -P HDP-2.5.0.0,mpack

## Install VirtualBox
sudo apt-add-repository "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib"
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo apt-get update -qq
sudo apt-get install -yqq virtualbox-5.2
vboxmanage setproperty machinefolder /mnt
