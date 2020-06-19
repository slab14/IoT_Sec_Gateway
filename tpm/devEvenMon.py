#!/usr/bin/env python3

## notes. requires python3, & docker-py pip module

import json
import subprocess
import six
import socket
import ctypes
from time import sleep
from docker import Client
from binascii import hexlify, unhexlify

sender = ctypes.CDLL("/users/slab/IoT_Sec_Gateway/tpm/send.so")
sender.sendEncrypted.argtype=[ctypes.POINTER(ctypes.c_char), ctypes.c_int]
sender.sendEncrypted.restype=ctypes.c_int

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
    execID=cli.exec_create(container=contID, cmd=["cat", "ID"])
    execOut=cli.exec_start(execID)
    devID=execOut.split(b'\n')[0].decode("utf-8") 
    execID=cli.exec_create(container=contID, cmd="sh -c 'find sbin bin usr -type f -exec sha1sum {} \; | sha1sum'")
    outHash=cli.exec_start(execID)
    imgHash = outHash.split(b'  -')[0].decode("utf-8") 
    return(devID, imgHash)


def sendData(msg):
    cipherLen=sender.sendEncrypted(msg, len(msg))
    '''
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('128.105.146.14', 38687))
    s.sendall(bytes(msg, 'utf-8'))
    s.close()
    '''
        
def main():
    cli = Client(base_url='unix://var/run/docker.sock')
    for event in cli.events(decode=True):
        eventStatus=get_status(event)
        if eventStatus in ['start']:
            contID=getNewContID(event)
            (devID,imgHash)=sha1Contbin(cli, contID)
            msg="ID: {};SHA1: {}".format(devID, imgHash)
            print(msg)
            sendData(bytes(msg, 'utf-8'))
        

if __name__=='__main__':
    main()
