#!/usr/bin/env python

import json
import subprocess
from docker import Client
from binascii import hexlify, unhexlify

def get_status(event):
    ret=''
    if 'status' in event:
        ret=event['status']
    return ret

def getNewContImageHash(cli, event):
    newImg=event['Actor']['Attributes']['image']
    ret=''
    newContID=event['id']
    contImage=cli.inspect_container(newContID)['Config']['Image']
    if newImg==contImage:
        imgHash=cli.inspect_container(newContID)['Image']
        ret=imgHash.split(':')[1]        
    return ret

def performAction(inputData):
    if isinstance(inputData, list):
        numInputs=len(inputData)
        if numInputs==1:
            subprocess.check_call(["echo", inputData[0]])
        else:
            for i in range(numInputs):
                subprocess.check_call(["echo", inputData[i]])
    elif isinstance(inputData, str):
        subprocess.check_call(["echo", inputData])

def extendPCR(hashData, register='16'):
    '''
    if isinstance(inputData, list):
        numInputs=len(inputData)
        if numInputs==1:
            subprocess.check_call(["echo", inputData[0]])
        else:
            for i in range(numInputs):
                subprocess.check_call(["echo", inputData[i]])
    '''
    if isinstance(inputData, str):
        subprocess.check_call(["tpm2_pcrextend", register+':sha256='+hashData])
        

def main():
    cli = Client(base_url='unix://var/run/docker.sock')
    for event in cli.events(decode=True):
        eventStatus=get_status(event)
        if eventStatus=='create':
            newImgHash=getNewContImageHash(cli, event)
            print(newImgHash)
            #performAction(newImgHash)
            extendPCR(newImgHash)
        

if __name__=='__main__':
    main()
