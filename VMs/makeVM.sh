#!/bin/bash

sudo qemu-img convert -f qcow2 ~/ubuntu16_04.img /var/lib/libvirt/images/baseline.img
sudo cp baseline.txt /var/lib/libvirt/images/baseline.txt
echo "instance-id: $(uuidgen || echo i-abcdefg)" > my-meta-data
sudo cloud-localds -v /var/lib/libvert/images/ubuntu16_04.iso baseline.txt my-meta-data

sudo virt-install --name baseline --memory 4096 --disk /var/lib/libvirt/images/baseline.img,device=disk,bus=virtio --disk /var/lib/libvirt/images/ubuntu16_04.iso --os-type linux --os-variant ubuntu16.04 --virt-type kvm --graphics none --network network=default,model=virtio --import --extra-args='console=tty0'
