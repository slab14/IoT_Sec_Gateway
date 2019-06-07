#!/usr/bin/python

import argparse
import shlex
import subprocess
import itertools
import ipaddress
from utils.OVS_Tools import start_container, attach_container, attach_container_wIP, connect_container_chain_wIPs, exec_cmd_in_container

# Syntax: python connect_container.py -C <image name> -n <number of containers>

NODE_0='192.1.1.2'
NODE_1='10.1.1.2'
BRIDGE='br0'

## mbox chain:
# controlPC -> antidos  -> VPN server -> IPS  -> 3dPrinter
# 3dPrinter -> antidos   -> IPS   -> VPN server -> controlPC

CONTAINER_NAME_and_IMAGE_LIST=[("antiDoS", 'antidos2'), ("VPNserver", 'openvpn'), ("IPS",'snort')]

INGRESS_CHAIN=['antiDoS:eth0', 'antiDoS:eth1', 'VPNserver:eth0', 'VPNserver:eth1', 'IPS:eth0', 'IPS:eth1']
EGRESS_CHAIN=['antiDoS:eth1', 'antiDoS:eth0', 'IPS:eth1', 'IPS:eth0', 'VPNserver:eth1', 'VPNserver:eth0']


def get_names(number):
    nameList = ['test{}'.format(i) for i in range(number)]
    return nameList

def get_ip_range(base_ip, num):
    try:
        base_ip = ipaddress.ip_address(unicode(base_ip))
    except:
        print('Invalid ip address: {}'.format(base_ip))
        sys.exit(1)
    ips = [base_ip + i for i in range(num)]
    return ips

def main():
    parser=argparse.ArgumentParser(description='Connect container to vswitch')
    parser.add_argument('--container', '-C', required=False, type=str)
    parser.add_argument('--instances', '-n', required=False, type=int)
    args=parser.parse_args()
    '''
    name_list = []
    client_ips = []
    server_ips = []
    name_list = get_names(args.instances)
    client_ips = get_ip_range(NODE_0, args.instances)
    server_ips = get_ip_range(NODE_1, args.instances)
    '''
    #for i in range(0, len(name_list)):
    for name,image in CONTAINER_NAME_and_IMAGE_LIST:
        if image=='openvpn':
            start_container(image, name, True, ' -v /users/slab/vpn:/etc/openvpn -p 1194:1194/udp')
            attach_container_wIP(BRIDGE, name, 'eth0', '192.1.2.2/16')
            attach_container_wIP(BRIDGE, name, 'eth1', '10.1.2.2/16')
            exec_cmd_in_container(name, '/sbin/iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE')
        else:
            start_container(image, name, True)            
            attach_container(BRIDGE, name)
        
    connect_container_chain_wIPs(BRIDGE, NODE_0, '192.1.2.2', INGRESS_CHAIN[0:3], twoPorts=False, forward=True, includeClient=True, includeServer=False)
    connect_container_chain_wIPs(BRIDGE, '10.1.2.2', NODE_1, INGRESS_CHAIN[3:], twoPorts=False, forward=True, includeClient=False, includeServer=True)    
    connect_container_chain_wIPs(BRIDGE, '10.1.2.2', NODE_1, EGRESS_CHAIN[0:5], twoPorts=False, forward=False, includeClient=False, includeServer=True)
    connect_container_chain_wIPs(BRIDGE, NODE_0, '192.1.2.2', EGRESS_CHAIN[5:], twoPorts=False, forward=False, includeClient=True, includeServer=False)    

        
if __name__ == '__main__':
    main()
    
