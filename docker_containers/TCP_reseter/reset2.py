#!/usr/bin/env python

from scapy.all import *
import argparse
import time
import threading

timer1=0.0
timer2=0.0
timer1_set=False
timer2_set=False
tcpData1={}
tcpData2={}

def watchdog():
    global timer1_set
    global timer2_set
    global timer1
    global timer2
    global tcpData1
    global tcpData2

    print("Thread started")
    #while timer1_set:
    while True:
        print("checking time")
        if (time.time()-timer1)>10:
            # send RST
            print("sending RST")
            p=IP(src=tcpData1['dst'], dst=tcpData1['src'])/TCP(sport=tcpData1['dport'], dport=tcpData1['sport'], flags="R", seq=tcpData1['ack'])
            send(p, iface=args.in_interface)
    '''
    while timer2_set:
        if (time.time()-timer2)>10:
            # send RST
            print("sending RST")
            p=IP(src=tcpData2['dst'], dst=tcpData2['src'])/TCP(sport=tcpData2['dport'], dport=tcpData2['sport'], flags="R", seq=tcpData2['ack'])
            send(p, iface=args.out_interface)    
    '''

def packet_callback(packet):
    '''
    Return True then packet is forwarded, return False then packet is dropped, 
    return packet then that packet is forwarded
    '''
    if True:
        return True
    else: 
        return False

def packet_callback12(packet):
    global timer1_set
    timer1_set=True
    global tcpData1
    if packet.haslayer(TCP):
        tcpData1={'src':packet[IP].src,'dst':packet[IP].dst,'sport':packet[TCP].sport,
                  'dport':packet[TCP].dport,'seq':packet[TCP].seq,'ack':packet[TCP].ack}
    global timer1
    timer1=time.time()
    print("Timer 1 = "+ str(timer1))
    return True

def packet_callback21(packet):
    global timer2_set
    timer2_set=True
    global tcpData2
    if packet.haslayer(TCP):
        tcpData2={'src':packet[IP].src,'dst':packet[IP].dst,'sport':packet[TCP].sport,
                  'dport':packet[TCP].dport,'seq':packet[TCP].seq,'ack':packet[TCP].ack}    
    global timer2
    timer2=time.time()
    print("Timer2: "+str(timer2))
    return True
    

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--in_interface', '-i', required=True, type=str)
    parser.add_argument('--out_interface', '-o', required=True, type=str)    
    args=parser.parse_args()
    t=threading.Thread(target=watchdog)
    t.start()
    while True:
        #bridge_and_sniff(args.in_interface, args.out_interface, prn=packet_callback)
        bridge_and_sniff(args.in_interface, args.out_interface, xfrm12=packet_callback12, xfrm21=packet_callback21)


if __name__=='__main__':
    main()
