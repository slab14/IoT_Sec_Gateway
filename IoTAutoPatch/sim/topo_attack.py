#!/usr/bin/python
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import setLogLevel, info
from mininet.cli import CLI
from mininet.node import Node
from mininet.link import Link, Intf
from mininet.util import dumpNodeConnections

class create_topo(Topo):

    def build(self, n=2):

        h1 = self.addHost( 'h1' , ip = '192.168.1.100')
        h2 = self.addHost( 'h2' , ip = '192.168.1.101')
        h3 = self.addHost( 'h3' , ip = '192.168.1.102')
        s1 = self.addSwitch( 's1' )
        s2 = self.addSwitch( 's2' )

        self.addLink( h1,s1 )
        self.addLink( h3,s1 )
        self.addLink( h2,s2 )
        self.addLink( s1,s2 )
        #self.addLink( s1,h3 )
    

def start_cli():
    topo = create_topo()
    net = Mininet(topo=topo)
    net.start()
    dumpNodeConnections(net.hosts)
    s1, s2, h1, h2, h3 = net.get('s1', 's2', 'h1', 'h2', 'h3')
    net.pingAll()
    net.configLinkStatus('s1', 's2', 'down')
    net.pingAll()
    h1.cmd('ethtool --offload h1-eth0 rx off tx off')
    h2.cmd('ethtool --offload h2-eth0 rx off tx off')
    h3.cmd('ethtool --offload h3-eth0 rx off tx off')
    h2.cmd('python3 modbus_server.py &')
    h1.cmd('tcpdump -i h1-eth0 -w h1.pcap &')
    h2.cmd('tcpdump -i h2-eth0 -w h2.pcap &')
    h3.cmd('tcpdump -i h3-eth0 -2 h3.pcap &')
    CLI(net)
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    start_cli()
