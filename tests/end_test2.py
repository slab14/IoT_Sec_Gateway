#!/usr/bin/env python

import argparse
import shlex
import subprocess
import threading

BRIDGE = 'br0'
NUM_THREADS=30

def docker_killall(name):
    cmd='/usr/bin/sudo /usr/bin/docker kill {}'
    cmd=cmd.format(name)
    subprocess.call(shlex.split(cmd))

def docker_delport(name):
    cmd='/usr/bin/sudo /usr/bin/ovs-docker del-ports {} {}'
    cmd=cmd.format(BRIDGE, name)
    subprocess.call(shlex.split(cmd))

def cleanup_switch():
    cmd='/usr/bin/sudo /usr/bin/ovs-ofctl del-flows {}'
    cmd=cmd.format(BRIDGE)
    subprocess.check_call(shlex.split(cmd))
    cmd='/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=0 in_port=1 actions=output:2"'
    cmd=cmd.format(BRIDGE)
    subprocess.check_call(shlex.split(cmd))
    cmd='/usr/bin/sudo /usr/bin/ovs-ofctl add-flow {} "priority=0 in_port=2 actions=output:1"'
    cmd=cmd.format(BRIDGE)
    subprocess.check_call(shlex.split(cmd))    

class Docker_down(object):
    queue=[]
    thread_count=NUM_THREADS
    lock=threading.Lock()

    def exec_tear_down(self, cmd_str):
        docker_delport(cmd_str)
        docker_killall(cmd_str)

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
            self.exec_tear_down(cmd_str)

    def start(self):
        threads=[]
        for i in range(self.thread_count):
            t=threading.Thread(target=self.dequeue)
            t.start()
            threads.append(t)
        [ t.join() for t in threads ]
    
def main():
    parser=argparse.ArgumentParser(description='Clean up containers and switch ports after experiment')
    parser.add_argument('--number', '-n', required=True, type=int)
    args=parser.parse_args()
    name_list=['test{}'.format(i) for i in range(args.number)]
    for i in range(args.number):
        name='test{}'.format(i)
    test=Docker_down()
    test.thread_count=NUM_THREADS
    test.queue=name_list
    test.start()
    cleanup_switch()

if __name__=='__main__':
    main()

