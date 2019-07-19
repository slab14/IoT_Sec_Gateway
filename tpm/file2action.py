#!/user/bin/env python

import time
import subprocess
from binascii import hexlify, unhexlify
import argparse

def checkFile(fileName, currentVal):
    newData=[]
    with open(fileName, 'r') as f:
        data = f.readlines()
        measure=len(data)
        if measure > currentVal:
            newData=[x.strip() for x in data[currentVal:]]
            currentVal=measure
    f.close()
    return (currentVal, newData)

def performAction(inputData):
    numInputs=len(inputData)
    if numInputs==1:
        subprocess.check_call(["echo", inputData[0]])
    else:
        for i in range(numInputs):
            subprocess.check_call(["echo", inputData[i]])

def actionOnNew(old, new, data):
        if new > old:
            old=new
            performAction(data)
        return old

def main():
    parser = argparse.ArgumentParser(description='Run PSI demo, json policy')
    parser.add_argument('--inputFile', '-i', required=True, type=str, help='path to file being monitorred')
    args=parser.parse_args()
    count, _=checkFile(args.inputFile,0)
    newData=[]
    while True:
        (newCount, newData)=checkFile(args.inputFile, count)
        count=actionOnNew(count, newCount, newData)
        time.sleep(1)


if __name__=="__main__":
    main()
