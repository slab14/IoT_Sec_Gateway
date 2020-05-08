import argparse
import shlex
import subprocess
import itertools
import ipaddress
from utils.OVS_Tools import start_container, attach_container, connect_container_wIPs

NODE_0='192.1.1.2'
NODE_1='10.1.1.2'
BRIDGE='br0'

# Syntax: python connect_container.py -C <image name> -n <number of containers>
def get_names(container,number):
    name = container+'{}'
    list = [name.format(i) for i in range(number)]
    return list

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
    parser.add_argument('--container', '-C', required=True, type=str)
#    parser.add_argument('--name', '-N', required=True, type=str)
    parser.add_argument('--instances', '-n', required=True, type=int)
    args=parser.parse_args()
    name_list = []
    client_ips = []
    server_ips = []
    name_list = get_names(args.container,args.instances)
    client_ips = get_ip_range(NODE_0, args.instances)
    server_ips = get_ip_range(NODE_1, args.instances)
    for i in range(0, len(name_list)):
        start_container(args.container, name_list[i])
#        attach_container(BRIDGE, name_list[i])
#        connect_container_wIPs(BRIDGE, client_ips[i], server_ips[i], name_list[i])

if __name__ == '__main__':
    main()
    
