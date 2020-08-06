import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import socket
import re
import ctypes
 
sender = ctypes.CDLL("/send.so")
sender.sendEncryptedAlert.argtype=[ctypes.POINTER(ctypes.c_char), ctypes.c_int]
sender.sendEncryptedAlert.restype=ctypes.c_int

class AlertSender(FileSystemEventHandler):
    

    def __init__(self, fileName):
        self.count=0
        self.part1_string=''
        self.fileName=fileName
        self.baseData=''
        with open(fileName, 'r') as f:
            self.baseData=f.read()
        self.protectionID=''
        with open("/ID", 'r') as f:
            self.protectionID=f.read().rstrip()
            
                
    def on_modified(self, event):
        super(AlertSender, self).on_modified(event)

        if self.fileName == event.src_path:
            newData=''
            diff=''
            with open(self.fileName, 'r') as f:
                newData=f.read()
            if self.baseData=='':
                diff=newData
            else:
                findNew=newData.split(self.baseData)
                if len(findNew)>1:
                    diff=findNew[1]
            self.baseData=newData
            if diff[:5] == '<?xml':
                self.part1_string = diff
            if diff[:5] == '<verb':
                IDdata="Policy ID:"+str(self.protectionID)+"; "
                diff = self.part1_string + diff
                alertData="Alert:"+str(diff).rstrip()
                sendData=str(IDdata+alertData)
                cipherLen=sender.sendEncryptedAlert(sendData, len(sendData))
           
            

if __name__ == "__main__":
    event_handler = AlertSender('/var/log/iptables.log')
    observer = Observer()
    observer.schedule(event_handler, '/var/log/')
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
