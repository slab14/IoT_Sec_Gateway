cd ~/ovs
sudo /usr/share/openvswitch/scripts/ovs-ctl stop
sudo make clean
sudo make
sudo ovs-dpctl del-dp system@ovs-system
sudo rmmod openvswitch
sudo rm /lib/modules/$(uname -r)/extra/openvswitch.ko
sudo make modules_install
sudo modprobe -v openvswitch
modinfo openvswitch
sudo lsmod | grep openvswitch
sudo /usr/share/openvswitch/scripts/ovs-ctl start --system-id
