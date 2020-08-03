#!/usr/bin/python
import sys
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import setLogLevel, info
from mininet.cli import CLI
from mininet.node import Node
from mininet.link import Link, Intf
from mininet.util import dumpNodeConnections

class create_topo(Topo):

    def build(self):

        h1 = self.addHost( 'h1' , ip = '192.168.1.192')
        s1 = self.addSwitch( 's1' )

        self.addLink( h1,s1 )
        
        for i in range(n):
            device = self.addHost( 'd%d' % i , ip = '192.168.1.10%d'%i)
            device_switch = self.addSwitch( 'ds%d' % i )#, inNamespace=True )
            self.addLink( device, device_switch )
            self.addLink( device_switch, s1 )
    

def start_cli():
    topo = create_topo()
    net = Mininet(topo=topo)
    net.start()
    dumpNodeConnections(net.hosts)
    s1, h1 = net.get('s1', 'h1')
    h1.cmd('ethtool --offload h1-eth0 rx off tx off')
    h1.cmd('tcpdump -i h1-eth0 -w h1_f.pcap &')
    
    #per device
    for i in range(n):
        dev, sw = net.get('d%d'%i, 'ds%d'%i)
        dev.cmd('ethtool --offload d%d-eth0 rx off tx off'%i)
        dev.cmd('tcpdump -i d%d-eth0 -w d%d.pcap &'%(i,i))
        dev.cmd('python3 modbus_server.py &')
        #sw.cmd('snort -c snort.conf -i ds%d-eth1:ds%d-eth2 -Q -l log -A console &'%(i,i))
        #sw.cmd('ovs-ofctl add-flow ds%d priority=65535,actions=drop'%i)
        
    CLI(net)
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    if len(sys.argv) == 1: n=1
    if len(sys.argv) == 2: n=int(sys.argv[1])
    start_cli()
