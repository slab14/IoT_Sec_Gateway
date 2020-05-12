import sys
import time
import logging
from watchdog.observers import Observer
from watchdog.events import LoggingEventHandler, FileSystemEventHandler

class SlabLogger(FileSystemEventHandler):
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
            logging.info("New Data: %s", diff)
            self.baseData=newData
        

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                        format='%(asctime)s - %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
    path = sys.argv[1] if len(sys.argv) > 1 else '.'
    event_handler = SlabLogger('./file.txt')
    observer = Observer()
    observer.schedule(event_handler, path)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
