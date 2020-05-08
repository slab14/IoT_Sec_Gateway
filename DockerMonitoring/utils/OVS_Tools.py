import subprocess
import shlex
import itertools

#Start container, assumes that image is already built
def start_container(container, name, netPriv=False, otherCmds=None):
    cmd='/usr/bin/sudo /usr/bin/docker run -itd --rm --network=none'
    if netPriv:
        cmd=cmd+' --cap-add=NET_ADMIN'
    if otherCmds != None:
        cmd=cmd+otherCmds
    cmd=cmd+' --name {} {}'
    cmd=cmd.format(name, container)
    subprocess.check_call(shlex.split(cmd))
    ##Future improvement. Fails if container image doesn't exist. Is there a way to identify this situation and fix it?

#Exec container, assumes that it is running
def exec_cmd_in_container(name, cmd_args):
    cmd='/usr/bin/sudo /usr/bin/docker exec {} {}'
    cmd=cmd.format(name, cmd_args)
    subprocess.check_call(shlex.split(cmd))


#Add ethernet ports to a container that are connected to an OVS bridge
def attach_container(bridge, container_name, twoPorts=True):
    interfaces=('eth0')
    if twoPorts:
        interfaces=('eth0', 'eth1')
    for interface in interfaces:
        cmd = '/usr/bin/sudo /usr/bin/ovs-docker add-port {} {} {}'
        cmd = cmd.format(bridge, interface, container_name)
        subprocess.check_call(shlex.split(cmd))

def attach_container_wIP(bridge, container_name, iface, ip):
    cmd = '/usr/bin/sudo /usr/bin/ovs-docker add-port {} {} {} --ipaddress={}'
    cmd = cmd.format(bridge, iface, container_name, ip)
    subprocess.check_call(shlex.split(cmd))        

def get_of_port(bridge, name, interface):
    cmd='/usr/bin/sudo /usr/bin/ovs-vsctl --data=bare --no-heading \
    --columns=name find interface external_ids:container_id={} \
    external_ids:container_iface={}'
    cmd = cmd.format(name, interface)
    ovs_port = subprocess.check_output(cmd, shell=True)
    ovs_port = ovs_port.strip()
    cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 show {} | grep {}'
    cmd=cmd.format(bridge, ovs_port) + " | awk -F '(' '{ print $1 }'"
    of_port = subprocess.check_output(cmd, shell=True)
    of_port= of_port.strip()
    return of_port
    
def find_container_ports(bridge, container_name, twoPorts=True, interfaces=None):
    if interfaces==None:
        interfaces=('eth0')        
        if twoPorts:
            interfaces=('eth0', 'eth1')
    of_ports = []
    for interface in interfaces:
        of_port=get_of_port(bridge, container_name, interface)
        of_ports.append(of_port)
    return of_ports    

def pairwise(iterable):
    's -> (s0, s1), (s2, s3), s4, s5), ...'
    a = iter(iterable)
    return itertools.izip(a,a)

#Add OVS routing rules between predefined end points (OF ports 1 & 2) and container
def connect_container(bridge, container_name, twoPorts=True):
    of_ports = find_container_ports(bridge, container_name, twoPorts)
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
    of_ports = find_container_ports(bridge, container_name, twoPorts)
    of_ports = [1] + of_ports + [2]
    for in_port,out_port in pairwise(of_ports):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=10 arp in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
    for in_port,out_port in pairwise(reversed(of_ports)):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=10 arp in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
        

## TODO: Update routing tools to be able to customize routing path more
# 1) different paths for different directions
# 2) more than a single middlebox for each chain
# 3) option to specify different paths for different hosts

def connect_container_chain_wIPs_mirror(bridge, client_ip, server_ip, container_name_list, twoPorts=True):
    of_ports=[]
    for container_name in container_name_list:
        of_ports += find_container_ports(bridge, container_name, twoPorts)
    of_ports = [1] + of_ports + [2]
    for in_port,out_port in pairwise(of_ports):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=10 arp in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
    for in_port,out_port in pairwise(reversed(of_ports)):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=10 arp in_port={} nw_src={} nw_dst={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))        


def connect_container_chain_wIPs(bridge, client_ip, server_ip, container_name_list, twoPorts=True, forward=True, includeClient=False, includeServer=False):
    of_ports=[]
    for container_name_val in container_name_list:
        container_name=container_name_val.split(":")
        if len(container_name)>1:
            cont_ports = find_container_ports(bridge, container_name[0], twoPorts=False, interfaces=(container_name[1],))
        else:
            cont_ports = find_container_ports(bridge, container_name[0], twoPorts)
        if forward:
            of_ports += cont_ports
        else:
            of_ports += reversed(cont_ports)
    if forward:
        if includeClient:
            of_ports = [1] + of_ports
        if includeServer:
            of_ports = of_ports + [2]
    else:
        if includeClient:
            of_ports = of_ports + [1]
        if includeServer:
            of_ports = [2] + of_ports
    for in_port,out_port in pairwise(of_ports):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=100 ip in_port={} nw_src={} nw_dst={} actions=output:{}"'
        if forward:
            cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        else:
            cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl -OOpenflow13 add-flow {} "priority=10 arp in_port={} nw_src={} nw_dst={} actions=output:{}"'
        if forward:
            cmd=cmd.format(bridge, in_port, client_ip, server_ip, out_port)
        else:
            cmd=cmd.format(bridge, in_port, server_ip, client_ip, out_port)
        subprocess.check_call(shlex.split(cmd))

