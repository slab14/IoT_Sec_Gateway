import subprocess
import shlex
import itertools

#Start container, assumes that image is already built
def start_container(containerImage, name, netPriv=False, otherCmds=None):
    cmd='/usr/bin/sudo /usr/bin/docker run -itd --rm --network=none'
    if netPriv:
        cmd=cmd+' --cap-add=NET_ADMIN'
    if otherCmds != None:
        cmd=cmd+otherCmds
    cmd=cmd+' --name {} {}'
    cmd=cmd.format(name, containerImage)
    subprocess.check_call(shlex.split(cmd))
    ##Future improvement. Fails if container image doesn't exist. Is there a way to identify this situation and fix it?

#Exec container, assumes that it is running
def exec_cmd_in_container(name, cmd_args, noCheck=False):
    cmd='/usr/bin/sudo /usr/bin/docker exec {} {}'
    cmd=cmd.format(name, cmd_args)
    if noCheck:
        subprocess.call(shlex.split(cmd))
    else:
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
    cmd='/usr/bin/sudo /usr/bin/ovs-ofctl show {} | grep {}'
    cmd=cmd.format(bridge, ovs_port) + " | awk -F '(' '{ print $1 }'"
    of_port = subprocess.check_output(cmd, shell=True)
    of_port=of_port.strip()
    return of_port
    
def find_container_ports(bridge, container_name, twoPorts=True):
    of_ports = []    
    if twoPorts:
        interfaces=('eth0', 'eth1')
        for interface in interfaces:
            of_port=get_of_port(bridge, container_name, interface)        
            of_ports.append(of_port)
    else:
        interface=('eth0')
        of_ports=get_of_port(bridge, container_name, interface)        
    return of_ports    

def pairwise(iterable):
    's -> (s0, s1), (s2, s3), s4, s5), ...'
    a = iter(iterable)
    return itertools.izip(a,a)

def setup_flow(bridge, containerChain):
    of_ports=[]
    for containerName,containerIfaceCount in containerChain:
        twoPorts=False
        if containerIfaceCount > 1:
            twoPorts=True
        contPorts=find_container_ports(bridge, containerName, twoPorts=twoPorts)
        if isinstance(contPorts, list):
            for port in contPorts:
                of_ports.append(port)
        else:
            of_ports.append(contPorts)    
                    
    for in_port,out_port in pairwise(of_ports):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "in_port={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, out_port)
        subprocess.check_call(shlex.split(cmd))
    for in_port,out_port in pairwise(reversed(of_ports)):
        cmd='/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "in_port={} actions=output:{}"'
        cmd=cmd.format(bridge, in_port, out_port)
        subprocess.check_call(shlex.split(cmd))
