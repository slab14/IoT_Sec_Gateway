import time
import socket
import re
import ctypes
 
sender = ctypes.CDLL("/send.so")
sender.sendEncryptedAlert.argtype=[ctypes.POINTER(ctypes.c_char), ctypes.c_int]
sender.sendEncryptedAlert.restype=ctypes.c_int

fileName='/var/log/nmap.log'

def getData(fileName):
    data=''
    with open(fileName, 'r') as f:
        data=f.read()
    with open("/ID", 'r') as f:
        protectionID=f.read().rstrip()
    return (protectionID, data)
            
                
def send(protectionID, data):
    IDdata="Policy ID:"+str(protectionID)+"; "
    alertData="Alert:"+str(data).rstrip()
    sendData=str(IDdata+alertData)
    cipherLen=sender.sendEncryptedAlert(sendData, len(sendData))
           
            
                
if __name__ == "__main__":
    (protectionID, data) = getData(fileName)
    send(protectionID, data)
