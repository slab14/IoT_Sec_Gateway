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
        h4 = self.addHost( 'h4' , ip = '192.168.1.103')
        h5 = self.addHost( 'h5' , ip = '192.168.1.104')
        h6 = self.addHost( 'h6' , ip = '192.168.1.105')

        s1_2 = self.addSwitch( 's1_2' )
        s1_3 = self.addSwitch( 's1_3' )
        s1_4 = self.addSwitch( 's1_4' )
        s1_5 = self.addSwitch( 's1_5' )
        s1_6 = self.addSwitch( 's1_6' )
        s2 = self.addSwitch( 's2' )
        s3 = self.addSwitch( 's3' )
        s4 = self.addSwitch( 's4' )
        s5 = self.addSwitch( 's5' )
        s6 = self.addSwitch( 's6' )

        self.addLink( h1,s1_2 )
        self.addLink( h1,s1_3 )
        self.addLink( h1,s1_4 )
        self.addLink( h1,s1_5 )
        self.addLink( h1,s1_6 )
        self.addLink( h2,s2 )
        self.addLink( h3,s3 )
        self.addLink( h4,s4 )
        self.addLink( h5,s5 )
        self.addLink( h6,s6 )
        self.addLink( s1_2,s2 )
        self.addLink( s1_3,s3 )
        self.addLink( s1_4,s4 )
        self.addLink( s1_5,s5 )
        self.addLink( s1_6,s6 )

    

def start_cli():
    topo = create_topo()
    net = Mininet(topo=topo)
    net.start()
    dumpNodeConnections(net.hosts)
    #s1_2, s1_3, s1_4, s1_5, s1_6, s2, s3, s4, s5, s6, h1, h2, h3, h4, h5, h6 = net.get('s1_2', 's1_3', 's1_4', 's1_5', 's1_6', 's2', 's3', 's4', 's5', 's6', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6')
    net.pingAll()
    #net.configLinkStatus('s1_2', 's2', 'down')
    #net.configLinkStatus('s1_3', 's3', 'down')
    #net.configLinkStatus('s1_4', 's4', 'down')
    #net.configLinkStatus('s1_5', 's5', 'down')
    #net.configLinkStatus('s1_6', 's6', 'down')
    #net.pingAll()
    h2.cmd('python3 modbus_server.py &')
    h3.cmd('python3 modbus_server.py &')
    h4.cmd('python3 modbus_server.py &')
    h5.cmd('python3 modbus_server.py &')
    h6.cmd('python3 modbus_server.py &')
    h1.cmd('tcpdump -i h1-eth0 -w h1_multi.pcap &')
    h2.cmd('tcpdump -i h2-eth0 -w h2_multi.pcap &')
    h3.cmd('tcpdump -i h3-eth0 -w h3_multi.pcap &')
    h4.cmd('tcpdump -i h4-eth0 -w h4_multi.pcap &')
    h5.cmd('tcpdump -i h5-eth0 -w h5_multi.pcap &')
    h6.cmd('tcpdump -i h6-eth0 -w h6_multi.pcap &')
    #h1.cmd('python3 modbus_client.py h2')
    #h1.cmd('python3 modbus_client.py h3')
    #h1.cmd('python3 modbus_client.py h4')
    #h1.cmd('python3 modbus_client.py h5')
    #h1.cmd('python3 modbus_client.py h6')

    CLI(net)
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    start_cli()
