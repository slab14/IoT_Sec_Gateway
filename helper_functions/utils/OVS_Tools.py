import subprocess
import shlex
import itertools

#Start container, assumes that image is already built
def start_containers(container, name, netPriv=False):
    if netPriv:
        cmd='/usr/bin/sudo /usr/bin/docker run -itd --rm --network=none --cap-add=NET_ADMIN --name {} {}'
    else:
        cmd='/usr/bin/sudo /usr/bin/docker run -itd --rm --network=none --name {} {}'
    cmd=cmd.format(name, container)
    subprocess.check_call(shlex.split(cmd))

#Add ethernet ports to a container that are connected to an OVS bridge
def attach_container(bridge, container_name, twoPorts=True):
    if twoPorts:
        interfaces=('eth0', 'eth1')
    else:
        interfaces=('eth0')
    for interface in interfaces:
        cmd = '/usr/bin/sudo /usr/bin/ovs-docker add-port {} {} {}'
        cmd = cmd.format(bridge, interface, container_name)
        subprocess.check_call(shlex.split(cmd))

def find_container_ports(bridge, container_name, twoPorts=True):
    if twoPorts:
        interfaces=('eth0', 'eth1')
    else:
        interfaces=('eth0')
    of_ports = []
    for interface in interfaces:
        cmd='/usr/bin/sudo /usr/bin/ovs-vsctl --data=bare --no-heading \
             --columns=name find interface external_ids:container_id={} \
             external_ids:container_iface={}'
        cmd = cmd.format(container_name, interface)
        ovs_port = subprocess.check_output(cmd, shell=True)
        ovs_port = ovs_port.strip()
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 show {} | grep {}'
        cmd=cmd.format(bridge, ovs_port) + " | awk -F '(' '{ print $1 }'"
        of_port = subprocess.check_output(cmd, shell=True)
        of_port= of_port.strip()
        of_ports.append(of_port)
    return of_ports

def pairwise(iterable):
    's -> (s0, s1), (s2, s3), s4, s5), ...'
    a = iter(iterable)
    return itertools.izip(a,a)

#Add OVS routing rules between predefined end points (OF ports 1 & 2) and container
def connect_container(bridge, container_name, twoPorts=True):
    if twoPorts:
        interfaces=('eth0', 'eth1')
    else:
        interfaces=('eth0')
    of_ports = find_container_ports(bridge, container_name)
    of_ports = [1] + of_ports + [2]
    for in_port,out_port in pairwise(of_ports):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "in_port={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, out_port)
        subprocess.check_call(shlex.split(cmd))
    for in_port,out_port in pairwise(reversed(of_ports)):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "in_port={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, out_port)
        subprocess.check_call(shlex.split(cmd))


def connect_container_wIPs(bridge, client_ip, server_ip, container_name, twoPorts=True):
    if twoPorts:
        interfaces=('eth0', 'eth1')
    else:
        interfaces=('eth0')
    of_ports = find_container_ports(bridge, container_name)
    of_ports = [1] + of_ports + [2]
    # Connect client to server (direction = 1 (only client to server) or 3)
    for in_port,out_port in pairwise(of_ports):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
    # Connect server to client (direction=2 (only server to client) or 3)
    for in_port,out_port in pairwise(reversed(of_ports)):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
        

## TODO: Update routing tools to be able to customize routing path more
# 1) different paths for different directions
# 2) more than a single middlebox for each chain
# 3) option to specify different paths for different hosts
