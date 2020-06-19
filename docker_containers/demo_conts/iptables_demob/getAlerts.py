import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import socket
import re

class AlertSender(FileSystemEventHandler):
    def __init__(self, fileName):
        self.fileName=fileName
        self.baseData=''
        with open(fileName, 'r') as f:
            self.baseData=f.read()
        self.protectionID=''
        with open("/ID", 'r') as f:
            self.protectionID=f.read()
            
                
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
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #s.connect(('192.168.1.86', 9696))
            s.connect(('128.105.145.219', 9696))
            # process data and send in appropriate format
            s.sendall("Policy ID:"+self.protectionID)
            s.sendall("Alert:"+diff)
            s.close()
        

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
