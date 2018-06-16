#!/usr/bin/env python

from scapy.all import *
import argparse
import numpy as np
import includes.netStat2 as ns
import includes.KitNET as kit

##Global Variables
maxHost = 100000000000
maxSess = 100000000000
nstat=ns.netStat(maxHost, maxSess)
maxAE=10
FMgrace=5000
ADgrace=10000
findThreshold=71000
threshold=0.01
pkt_cnt=0
K=kit.KitNET(len(nstat.getNetStatHeaders()), maxAE, FMgrace, ADgrace)


def parsePacket(packet):
    timestamp=packet.time
    framelen=len(packet)
    IPtype=np.nan
    srcproto=''
    dstproto=''
    if('Ether' in packet):
        srcIP=packet[Ether].src
        dstIP=packet[Ether].dst
        srcMAC=packet[Ether].src
        dstMAC=packet[Ether].dst
    elif('802.3' in packet):
        srcIP=packet.src
        dstIP=packet.dst
        srcMAC=packet.src
        dstMAC=packet.dst
    if('IP' in packet):
        IPtype=0
        srcIP=packet[IP].src
        dstIP=packet[IP].dst
        if('UDP' in packet): #UDP packet
            srcproto=str(packet[UDP].sport)
            dstproto=str(packet[UDP].dport)
        elif('TCP' in  packet): #TCP packet
            srcproto=str(packet[TCP].sport)
            dstproto=str(packet[TCP].dport)
        elif('ICMP' in packet): #ICMP packet
            srcproto='icmp'
            dstproto='icmp'
            IPtype=0
    elif('IPv6' in packet):
        IPtype=1
        srcIP=packet[IPv6].src
        dstIP=packet[IPv6].dst
        if('UDP' in packet):
            srcproto=str(packet[UDP].sport)
            dstproto=str(packet[UDP].dport)
        elif('TCP' in packet):
            srcproto=str(packet[TCP].sport)
            dstproto=str(packet[TCP].dport)
        elif('ICMPv6' in packet):
            srcproto='icmp'
            dstproto='icmp'
            IPtype=0            
    if('ARP' in packet):
        srcproto='arp'
        dstproto='arp'
        srcIP=packet[ARP].psrc
        dstIP=packet[ARP].pdst
        IPtype=0
    return IPtype, srcMAC, dstMAC, srcIP, srcproto, dstIP, dstproto, framelen, timestamp
    

def packet_callback(packet):
    global nstat
    X=np.zeros((1, len(nstat.getNetStatHeaders())))
    IPtype, srcMAC, dstMAC, srcIP, srcproto, dstIP, dstproto, framelen, timestamp = parsePacket(packet)
    X=nstat.updateGetStats(IPtype, srcMAC, dstMAC, srcIP, srcproto, dstIP, dstproto, int(framelen), float(timestamp))
    global K
    RMSE=K.process(X)
    global pkt_cnt
    if pkt_cnt<findThreshold:
        pkt_cnt+=1
        global threshold
        if RMSE>threshold:
            threshold=RMSE
    if(RMSE < 1.001*threshold):
        return True
    else: 
        return False

    

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--in_interface', '-i', required=True, type=str)
    parser.add_argument('--out_interface', '-o', required=True, type=str)    
    args=parser.parse_args()
    while True:
        bridge_and_sniff(args.in_interface, args.out_interface, prn=packet_callback)


if __name__=='__main__':
    main()
