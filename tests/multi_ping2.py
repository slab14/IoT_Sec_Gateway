#!/usr/bin/env python                          

import argparse
import shlex
import subprocess
import ipaddress
import re
import random

import threading

BASE_IP='10.1.1.2'
NUM_THREADS=8
NUM_ITER=30

def get_ip_range(base_ip, num):
    try:
        base_ip = ipaddress.ip_address(base_ip)
    except:
        print('Invalid ip address: {}'.format(base_ip))
    ips = [base_ip + i for i in range(num)]
    return ips

def init_ping(ip):
    cmd='/sbin/ping -c 2 {}'.format(ip)
    subprocess.check_call(shlex.split(cmd))

def setup_output_files(file, ip):
    ip_string=str(ip)
    sub_ip=ip_string.split('.')
    o_str='{}/out{}.txt'.format(file, sub_ip[3])
    return o_str

def format_test_cmd(folder, ip):
    out_file=setup_output_files(folder, ip)
    cmd='/sbin/ping {} -c 3 >> {}'
    cmd=cmd.format(ip, out_file)
    return cmd

class Ping_test(object):
    status={'alive':{}, 'dead':[]}
    queue=[]
    thread_count=NUM_THREADS
    lock=threading.Lock()

    def exec_test(self, cmd_str):
        print(cmd_str)
        ret=subprocess.check_output(cmd_str, shell=True)
        return ret==0

    def pop_queue(self):
        cmd_str=None
        self.lock.acquire()
        if self.queue:
            cmd_str=self.queue.pop()
        self.lock.release()
        return cmd_str
    def dequeue(self):
        while True:
            cmd_str=self.pop_queue()
            if not cmd_str:
                return None
            result='alive' if self.exec_test(cmd_str) else 'dead'
            self.status[result].append(cmd_str)

    def start(self):
        threads=[]
        for i in range(self.thread_count):
            t=threading.Thread(target=self.dequeue)
            t.start()
            threads.append(t)
        [ t.join() for t in threads ]


def main():
    parser=argparse.ArgumentParser(description='Run N simultaneous ping tests/requrests')
    parser.add_argument('--number', '-n', required=True, type=int)
    parser.add_argument('--output', '-o', required=True, type=str)
    args=parser.parse_args()
    test_ips = get_ip_range(BASE_IP, args.number)
    test_args=[format_test_cmd(args.output, ip) for ip in test_ips]
    #for ip in test_ips:                                                                                
        #init_ping(ip)                                                                                  
    all_test_args=[]
    for i in range(0,NUM_ITER):
        all_test_args=all_test_args+test_args
    random.shuffle(all_test_args)
    #print(all_test_args)                                                                               
    test=Ping_test()
    test.thread_count=NUM_THREADS
    test.queue=all_test_args
    test.start()


if __name__=='__main__':
    main()


