#!/bin/bash

sudo apt-get update

sudo apt-get install -y qemu-kvm libvirt-bin bridge-utils virt-manager libguestfs-tools cloud-image-utils

sudo adduser $USER libvirtd

sudo virsh -c qemu:///system list
