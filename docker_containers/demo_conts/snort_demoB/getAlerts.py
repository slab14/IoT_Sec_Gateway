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

            IDdata="Policy ID:"+str(self.protectionID)+"; "
            alertData="Alert:"+str(diff).rstrip()
            sendData=str(IDdata+alertData)
            cipherLen=sender.sendEncryptedAlert(sendData, len(sendData))
            

if __name__ == "__main__":
    event_handler = AlertSender('/var/log/snort/alert.csv')
    observer = Observer()
    observer.schedule(event_handler, '/var/log/snort/')
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
