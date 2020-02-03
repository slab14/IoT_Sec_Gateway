#!/usr/bin/python                                                                                                     
import socket
from time import sleep
import threading
import sys, signal
import argparse
import resource

global count
count = 0
lock = threading.Lock()

def worker(num, ip, port):
    try:
        connected=False
        while (not connected):
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.connect((ip, port))
                global count
                lock.acquire()
                count+=1
                lock.release()
            except Exception as msg:
                print "Connected #%3d Setup Refused" % int(num)
                print(msg)
            finally:
                if lock.locked():
                    lock.release()
        while True:
            a=1
            sleep(1)
    finally:
        s.close()

def main():
    resource.setrlimit(resource.RLIMIT_NOFILE, (10240, 10240))
    parser = argparse.ArgumentParser(description='Run PSI demo, json policy')
    parser.add_argument('--ip', required=True, type=str,
                        help='ip address of DUT')
    parser.add_argument('--port', required=True, type=int,
                        help='port to be checked')
    parser.add_argument('--max_conn', required=False, type=str,
                        help='max conn to check')    
    args=parser.parse_args()
    if args.max_conn==None:
        num_connections=100
    else:
        num_connections=args.max_conn
    #ip='10.1.1.2'
    ip=args.ip
    #port=5201
    port=args.port
    threads = []

    for i in range(num_connections):
        t = threading.Thread(target=worker, args=(i, ip, port))
        threads.append(t)
        t.start()

    global count
    #print("The value of count = "+str(count))
    print(count)

    with open("conns.txt", "w") as f:
        f.write(str(count))

    for i in range(num_connections):
        if threads[i].is_alive():
            threads[i]._Thread__stop()
        threads[i].join()

if __name__=='__main__':
    main()

