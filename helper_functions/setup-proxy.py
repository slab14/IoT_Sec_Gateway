#!/usr/bin/python

## Invocation Example:
## python setup-proxy.py -A 2 -I 10.1.2.2

import argparse
import ipaddress
import subprocess
import shlex
import itertools

BRIDGE='ovs-br0'
PROXY_NAME='squid_cont'
CLIENT_IFACE='enp6s0f0'
CLIENT_IP='192.1.1.2'
SERVER_IFACE='enp6s0f1'
SERVER_IP='10.1.1.2'
PROXY_IMAGE='squid_proxy'

def start_squid_proxy(image_name):
    cmd=('/usr/bin/sudo /usr/bin/docker run -itd --rm ' +
         '--network=none --name={} {}')
    cmd=cmd.format(PROXY_NAME, image_name)
    subprocess.check_call(shlex.split(cmd))

def add_ovs_bridge(bridge):
    cmd='/usr/bin/sudo /usr/bin/ovs-vsctl --may-exist add-br {}'
    cmd=cmd.format(bridge)
    subprocess.check_call(shlex.split(cmd))

def gateway_iface2port(bridge):
    #Client Side
    cmd=('/usr/bin/sudo /usr/bin/ovs-vsctl --may-exist add-port {} {} ' +
         '-- set Interface {} ofport_request=1')
    cmd=cmd.format(bridge, CLIENT_IFACE, CLIENT_IFACE)
    subprocess.check_call(shlex.split(cmd))

    #Server Side
    cmd=('/usr/bin/sudo /usr/bin/ovs-vsctl --may-exist add-port {} {} ' +
         '-- set Interface {} ofport_request=2')
    cmd=cmd.format(bridge, SERVER_IFACE, SERVER_IFACE)
    subprocess.check_call(shlex.split(cmd))

def container_ovsport_ip(bridge, name, addr):
    cmd=('/usr/bin/sudo /usr/bin/ovs-docker add-port {} eth0 {} ' +
         '--ipaddress={}/16')
    cmd=cmd.format(bridge, name, addr)
    subprocess.check_call(shlex.split(cmd))

def container_add_route(name):
    cmd=('/usr/bin/sudo /usr/bin/docker inspect --format '+
         '"{{ .State.Pid }}" ' + '{}'.format(name))
    container_pid=subprocess.check_output(shlex.split(cmd))
    print(container_pid)
                  
    cmd='/usr/bin/sudo /usr/bin/nsenter -t {} -n ip route add {}/16 dev eth0'
    #cmd=cmd.format(container_pid, CLIENT_IP)
    # fix, make more robust for IP ranges
    cmd=cmd.format(container_pid, '192.1.0.0')
    subprocess.call(shlex.split(cmd))
    cmd='/usr/bin/sudo /usr/bin/nsenter -t {} -n ip route add {}/16 dev eth0'
    #cmd=cmd.format(container_pid, SERVER_IP)
    # fix, make more robust for IP ranges
    cmd=cmd.format(container_pid, '10.1.0.0')    
    subprocess.call(shlex.split(cmd))

def add_gateway_iface_routes(bridge):
    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip in_port=1'
         +' nw_src={} nw_dst={} actions=output:2"')
    cmd=cmd.format(bridge, CLIENT_IP, SERVER_IP)
    subprocess.call(shlex.split(cmd))

    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip in_port=2'
         +' nw_src={} nw_dst={} actions=output:1"')
    cmd=cmd.format(bridge, SERVER_IP, CLIENT_IP)
    subprocess.check_call(shlex.split(cmd))    

def find_of_port(bridge, name):
    interface='eth0'
    cmd = '/usr/bin/sudo '
    cmd += '/usr/bin/ovs-vsctl --data=bare --no-heading --columns=name find \
    interface external_ids:container_id={} external_ids:container_iface={}'
    cmd = cmd.format(name, interface)
    ovs_port = subprocess.check_output(shlex.split(cmd))
    ovs_port = ovs_port.strip()

    cmd = '/usr/bin/sudo /usr/bin/ovs-ofctl show {} | grep {} '
    cmd = cmd.format(bridge, ovs_port)
    cmd += "| awk -F '(' '{ print $1 }'"
    of_port = subprocess.check_output(cmd, shell=True)
    of_port = of_port.strip()

    return of_port
    
def add_proxy_routes(bridge, addr):
    proxy_port=find_of_port(bridge, PROXY_NAME)
    #Routes between proxy & Client
    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip ' +
         'in_port=1 nw_src={} nw_dst={} actions=output:{}"')
    cmd=cmd.format(bridge, CLIENT_IP, addr, proxy_port)
    subprocess.check_call(shlex.split(cmd))

    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip ' +
         'in_port={} nw_src={} nw_dst={} actions=output:1"')
    cmd=cmd.format(bridge, proxy_port, addr, CLIENT_IP)
    subprocess.check_call(shlex.split(cmd))

    #Routes between proxy & server
    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip ' +
         'in_port=2 nw_src={} nw_dst={} actions=output:{}"')
    cmd=cmd.format(bridge, SERVER_IP, addr, proxy_port)
    subprocess.check_call(shlex.split(cmd))

    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 ip ' +
         'in_port={} nw_src={} nw_dst={} actions=output:2"')
    cmd=cmd.format(bridge, proxy_port, addr, SERVER_IP)
    subprocess.check_call(shlex.split(cmd))

    #Setup ARP routes
    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 arp ' +
         'in_port=1 actions=output:2,{}"')
    cmd=cmd.format(bridge, proxy_port)
    subprocess.check_call(shlex.split(cmd))

    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 arp ' +
         'in_port=2 actions=output:1,{}"')
    cmd=cmd.format(bridge, proxy_port)
    subprocess.check_call(shlex.split(cmd))

    cmd=('/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=100 arp ' +
         'in_port={} actions=output:1,2"')
    cmd=cmd.format(bridge, proxy_port)
    subprocess.check_call(shlex.split(cmd))    

def teardown(bridge):
    cmd='/usr/bin/sudo /usr/bin/ovs-docker del-ports {} {}'
    cmd=cmd.format(bridge, PROXY_NAME)
    subprocess.call(shlex.split(cmd))
    
    cmd='/usr/bin/sudo /usr/bin/docker kill {}'.format(PROXY_NAME)
    subprocess.check_call(shlex.split(cmd))

#    cmd='/usr/bin/sudo /usr/bin/docker rm {}'.format(PROXY_NAME)
#    subprocess.check_call(shlex.split(cmd))

    cmd='/usr/bin/sudo /usr/bin/ovs-ofctl del-flows {}'.format(bridge)
    subprocess.check_call(shlex.split(cmd))

def main():
    parser=argparse.ArgumentParser(description="setup proxy ovs demo")
    parser.add_argument('--action', '-A', required=True, type=int)
    parser.add_argument('--address', '-I', required=True, type=str)
    args=parser.parse_args()

    # Setup
    if args.action == 1:
        #Add OVS Bridge
        add_ovs_bridge(BRIDGE)
        #Connect Gateway Interfaces to Bridge
        gateway_iface2port(BRIDGE)
        #Add Container
        start_squid_proxy(PROXY_IMAGE)
        #Add OVS port for Container & Container IP Address
        container_ovsport_ip(BRIDGE, PROXY_NAME, args.address)
        #Add IP route to container for both client & server
        container_add_route(PROXY_NAME)
        #Add routing table rules
        add_gateway_iface_routes(BRIDGE)
        add_proxy_routes(BRIDGE, args.address)

    # Teardown
    elif args.action == 2:
        teardown(BRIDGE)

if __name__=='__main__':
    main()
