#!/usr/bin/env python3

import subprocess
import six
import socket
import ctypes
from time import sleep
from binascii import hexlify, unhexlify

pcr= ctypes.CDLL("/home/pi/IoT_Sec_Gateway/tpm/pcr.so")
pcr.hypReadPCR.argtype=ctypes.c_int
pcr.hypReadPCR.restype=ctypes.POINTER(ctypes.c_char)
pcr.hypExtendPCR.argtype=[ctypes.POINTER(ctypes.c_char), ctypes.c_int]

def setup():
    pcr.setup()
    pcr.initTPM()
    
def readPCR(num):
    PCRnum=num
    out=pcr.hypReadPCR(PCRnum)
    PCRvalue=out[:20]
    print(PCRvalue)
    print(hexlify(PCRvalue))    
        
def main():
    # setup
    #setup()
    # read
    readPCR(0)
    # extend
    measure='1010101010101010101010101010101010101010'
    pcr.hypExtendPCR(unhexlify(measure), 0)
    readPCR(0)
    

if __name__=='__main__':
    main()
