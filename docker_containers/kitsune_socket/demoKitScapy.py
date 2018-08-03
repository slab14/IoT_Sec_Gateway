#!/usr/bin/env python3

import socket
import select
import struct
import binascii
import time
import argparse
import numpy as np
import includes.netStat2 as ns
import includes.KitNET as kit

##Global Variables
maxHost = 100
maxSess = 100000000
nstat=ns.netStat(maxHost, maxSess)
maxAE=10
FMgrace=1000
ADgrace=3000
findThreshold=10000
threshold=0.5
pkt_cnt=0
K=kit.KitNET(len(nstat.getNetStatHeaders()), maxAE, FMgrace, ADgrace)


def getEthAddr(val):
    ethStr="%%.2x:%.2x:%.2x:%.2x:%.2x:%.2x" % (ord(val[0]), ord(val[1]), ord(val[2]), ord(val[3]), ord(val[4]), ord(val[5]))
    return ethStr

def newParsePacket(pkt):
    IPtype=np.nan
    srcproto=''
    dstproto=''
    #Frame data
    framelen=len(pkt)
    timestamp=time.time()
    #Ethernet data
    ETH_LEN=14
    eth_header=pkt[:ETH_LEN]
    eth=struct.unpack('!6s6sH', eth_header)
    eth_proto=str(socket.ntohs(eth[2]))
    #dstMAC=getEthAddr(pkt[0:6])
    dstMAC=str(binascii.hexlify(eth[0]), "utf-8")
    srcMAC=str(binascii.hexlify(eth[1]), "utf-8")
    srcIP=srcMAC
    dstIP=dstMAC
    if eth_proto=='8':  #IPv4
        IPtype=0
        IP_LEN=20
        ip_header=pkt[ETH_LEN:ETH_LEN+IP_LEN]
        iph=struct.unpack('!BBHHHBBH4s4s', ip_header)
        ip_proto=iph[6]
        srcIP=socket.inet_ntoa(iph[8])
        dstIP=socket.inet_ntoa(iph[9])
        iph_len=(iph[0]&0xF)*4
        if ip_proto==1:   #ICMP
            srcproto='icmp'
            dstproto='icmp'
            IPtype=0
        elif ip_proto==6:  #TCP
            t=iph_len+ETH_LEN
            tcp_header=pkt[t:t+IP_LEN]
            tcph=struct.unpack('!HHLLBBHHH', tcp_header)
            srcproto=str(tcph[0])
            dstproto=str(tcph[1])
        elif ip_proto==17:    #UDP
            u=iph_len+ETH_LEN
            UDPH_LEN=8
            udp_header=pkt[u:u+UDPH_LEN]
            udph=struct.unpack('!HHHH', udp_header)
            srcproto=str(udph[0])
            dstproto=str(udph[1])
    elif eth_proto=='1544':   #ARP
        scrproto='arp'
        dstproto='arp'
        IPtype=0
    elif eth_proto=='56710':   #IPv6
        IPtype=1
        IPv6_LEN=40
        ipv6_header=pkt[ETH_LEN:ETH_LEN+IPv6_LEN]
        ipv6h=struct.unpack('!BBHHBB16s16s', ipv6_header)
        ipv6_proto=ipv6h[4]
        srcIP=socket.inet_ntop(socket.AF_INET6, ipv6h[6])
        dstIP=socket.inet_ntop(socket.AF_INET6, ipv6h[7])
        if ipv6_proto==1:   #ICMP
            srcproto='icmp'
            dstproto='icmp'
            IPtype=0
        elif ipv6_proto==6:  #TCP
            TCPH_LEN=20
            t=IPv6_LEN+ETH_LEN
            tcp_header=pkt[t:t+TCP_LEN]
            tcph=struct.unpack('!HHLLBBHHH', tcp_header)
            srcproto=str(tcph[0])
            dstproto=str(tcph[1])
        elif ipv6_proto==17:    #UDP
            u=IPv6_LEN+ETH_LEN
            UDPH_LEN=8
            udp_header=pkt[u:u+UDPH_LEN]
            udph=struct.unpack('!HHHH', udp_header)
            srcproto=str(udph[0])
            dstproto=str(udph[1])
    return IPtype, srcMAC, dstMAC, srcIP, srcproto, dstIP, dstproto, framelen, timestamp    
    

def packet_callback(packet):
    global nstat
    X=np.zeros((1, len(nstat.getNetStatHeaders())))
    IPtype, srcMAC, dstMAC, srcIP, srcproto, dstIP, dstproto, framelen, timestamp = newParsePacket(packet)
    X=nstat.updateGetStats(IPtype, srcMAC, dstMAC, srcIP, srcproto, dstIP, dstproto, int(framelen), float(timestamp))
    global K
    RMSE=K.process(X)

    #For debugging
    print(RMSE)

    global pkt_cnt
    if pkt_cnt<findThreshold:
        pkt_cnt+=1
        global threshold
        if RMSE>threshold:
            threshold=RMSE
    if(RMSE < 3*threshold):
        return True
    else: 
        return False
    return True


class EtherSniff:
    def __init__(self, iface1_name, iface2_name):
        self.iface1=iface1_name
        self.iface2=iface2_name
        self.sock1=socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(3))
        self.sock2=socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(3))
        self.sock1.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 212992)
        self.sock2.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 212992)
        self.sock1.bind((self.iface1, 3))
        self.sock2.bind((self.iface2, 3))

    def recv(self):
        while True:
            socket_list=[self.sock1, self.sock2]
            read_sockets, write_sockets, error_sockets=select.select(socket_list, [], [])
            for sock in read_sockets:
                data = sock.recv(2048)
                if not data: break
                else:
                    if packet_callback(data):
                        if sock == self.sock1:
                            self.sock2.send(data)
                        elif sock == self.sock2:
                            self.sock1.send(data)
    

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--in_interface', '-i', required=True, type=str)
    parser.add_argument('--out_interface', '-o', required=True, type=str)    
    args=parser.parse_args()
    sniffer=EtherSniff(args.in_interface, args.out_interface)
    sniffer.recv()


if __name__=='__main__':
    main()
