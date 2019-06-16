#!/bin/bash

sudo apt-get update
sudo apt-get install -y uvtool uvtool-libvirt

uvt-simplestreams-libvirt sync release=bionic arch=amd64

sudo uvt-kvm create ub1

VM_IP=$(sudo uvt-kvm ip ub1)

ssh -i ~/.ssh/id_rsa ubuntu@$VM_IP


