import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import socket

class AlertSender(FileSystemEventHandler):
    def __init__(self, fileName):
        self.fileName=fileName
        self.baseData=''
        with open(fileName, 'r') as f:
            self.baseData=f.read()
                
    def on_modified(self, event):
        super(SlabLogger, self).on_modified(event)

        if event.src_path == self.fileName:
            newData=''
            with open(event.src_path, 'r') as f:
                newData=f.read()
            diff=newData.split(self.baseData)[1]
            self.baseData=newData
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect(('192.168.1.86', 9696))
            # process data and send in appropriate format
            s.sendall(diff)
            s.close()
        

if __name__ == "__main__":
    event_handler = AlertSender('./alert')
    observer = Observer()
    observer.schedule(event_handler, '/var/log/snort/alert')
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
