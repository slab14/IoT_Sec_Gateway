#!/usr/bin/python

import socket
from time import sleep
import threading
import sys, signal
import argparse
import resource
import psutil

filename='/var/log/dos.log'

def worker(num, ip, port, send=False):
    connected=False
    n=5
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2.0)
        s.connect((ip, port))
        connected=True
    except:
        pass
    try:
        while connected and (n>0):
            if send:
                s.send('a')
                a=1
            sleep(1)
            n-=1
    except:
        pass
    finally:
        s.close()


def test(ip, port, filename):
    resource.setrlimit(resource.RLIMIT_NOFILE, (4000, 4000))
    num_connections=20
    threads = []

    for i in range(num_connections):
        t = threading.Thread(target=worker, args=(i, ip, port, False))
        threads.append(t)
        t.start()
        sleep(0.01)

    sleep(3)
    count=0
    total_active=psutil.net_connections(kind='inet')
    for active in total_active:
        if active.status=='ESTABLISHED':
            count+=1
    with open(filename, 'wr') as f:
          f.write("total="+str(count))

    for i in range(num_connections):
        threads[i].join(10)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--ip', required=True, type=str)
    parser.add_argument('--port', required=True, type=int)          
    args=parser.parse_args()
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((args.ip, args.port))
    test(args.ip, args.port, filename)
    s.close()


if __name__=='__main__':
    main()
