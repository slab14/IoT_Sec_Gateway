#!/usr/bin/env python3

## notes. requires python3, & docker-py pip module

import json
import subprocess
import six
from time import sleep
from docker import Client
from binascii import hexlify, unhexlify

def get_status(event):
    ret=''
    if 'status' in event:
        ret=event['status']
    return ret

def getNewContID(event):
    ID=event['id']
    return ID

def extendPCR(hashData, register='16'):
    if isinstance(hashData, six.string_types):
        subprocess.check_call(["echo", register+':sha256='+hashData])
        
def sha1Contbin(cli, contID):
    sleep(1)
    execID=cli.exec_create(container=contID, cmd="sh -c 'find bin -type f -exec sha1sum {} \; | sha1sum'")
    outHash=cli.exec_start(execID)
    ret = outHash.split(b'  -')[0]
    print(ret)

        
def main():
    cli = Client(base_url='unix://var/run/docker.sock')
    for event in cli.events(decode=True):
        eventStatus=get_status(event)
        if eventStatus in ['create', 'die']:
            contID=getNewContID(event)
            sha1Contbin(cli, contID)
        

if __name__=='__main__':
    main()
