import argparse
import shlex
import subprocess
import itertools

NODE_0='192.1.1.2'
NODE_1='10.1.1.2'
BRIDGE='br0'

# Syntax: python connect_container.py -B br0 -N click0 -D 3

def attach_container(bridge, container_name):
    interfaces=('eth0', 'eth1')
    for interface in interfaces:
        cmd = '/usr/bin/sudo /usr/bin/ovs-docker add-port {} {} {}'
        cmd = cmd.format(bridge, interface, container_name)
        subprocess.check_call(shlex.split(cmd))

def find_container_ports(bridge, container_name):
    interfaces=('eth0', 'eth1')
    of_ports = []
    for interface in interfaces:
        cmd='/usr/bin/sudo /usr/bin/ovs-vsctl --data=bare --no-heading \
             --columns=name find interface external_ids:container_id={} \
             external_ids:container_iface={}'
        cmd = cmd.format(container_name, interface)
        ovs_port = subprocess.check_output(cmd, shell=True)
        ovs_port = ovs_port.strip()
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl show {} | grep {}'
        cmd=cmd.format(bridge, ovs_port) + " | awk -F '(' '{ print $1 }'"
        of_port = subprocess.check_output(cmd, shell=True)
        of_port= of_port.strip()
        of_ports.append(of_port)
    return of_ports

def pairwise(iterable):
    's -> (s0, s1), (s2, s3), s4, s5), ...'
    a = iter(iterable)
    return itertools.izip(a,a)

def connect_container(bridge, client_ip, server_ip, container_name):
    interfaces=('eth0', 'eth1')
    of_ports = find_container_ports(bridge, container_name)
    of_ports = [1] + of_ports + [2]
    # Connect client to server (direction = 1 (only client to server) or 3)
    for in_port,out_port in pairwise(of_ports):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
    # Connect server to client (direction=2 (only server to client) or 3)
    for in_port,out_port in pairwise(reversed(of_ports)):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))

def main():
    parser=argparse.ArgumentParser(description='Connect container to vswitch')
    parser.add_argument('--name', '-N', required=True, type=str)
    args=parser.parse_args()
    attach_container(BRIDGE, args.name)
    connect_container(BRIDGE, NODE_0, NODE_1, args.name)

if __name__ == '__main__':
    main()
    
