#!/usr/bin/env python

from binascii import hexlify, unhexlify
import hashlib

def checkPCR(valPCR, inputData, init='0'*40):
    checkVal=hashlib.sha1(unhexlify(init))
    m=hashlib.sha1(inputData)
    checkVal.update(m.digest())
    if valPCR == checkVal.hexdigest():
        return True
    else:
        return False


def main():
    FINAL='5c25782c0fe23c0959a3f21752ec7aaa46b549b8'
    result=checkPCR(FINAL, "hello world\n")
    print("------")
    if result:
        print("got it!")
    else:
        print("help me")


if __name__=="__main__":
    main()
