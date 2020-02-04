#!/usr/bin/python                                                                                                     
import socket
import time
import threading
import argparse
import select

class EtherSniff:
    def __init__(self, iface1_name, iface2_name):
        self.iface1=iface1_name
        self.iface2=iface2_name
        self.sock1=socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(3))
        self.sock2=socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(3))
        #self.sock1.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 212992)
        #self.sock2.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 212992)
        self.sock1.bind((self.iface1, 3))
        self.sock2.bind((self.iface2, 3))

    def recv(self):
        timer1=0
        timer1_on=False
        timer2=0
        timer2_on=False
        while True:
            socket_list=[self.sock1, self.sock2]
            read_sockets, write_sockets, error_sockets=select.select(socket_list, [], [])
            if timer1_on:
                if (time.time()-timer1)>30:
                    #send reset
                    
            if timer2_on:
                if (time.time()-timer2)>30:
                    #send reset
                    self.sock2.close()
            for sock in read_sockets:
                data = sock.recv(2048)
                if not data: break
                else:
                    #if packet_callback(data):
                    if sock == self.sock1:
                        timer1=time.time()
                        if not timer1_on:
                            timer1_on=True
                            self.sock2.send(data)
                    elif sock == self.sock2:
                        timer2=time.time()
                        if not timer2_on:
                            timer2_on=True
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
