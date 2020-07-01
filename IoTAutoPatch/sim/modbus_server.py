import socket
import random
import threading

SERVER_PORT = 502

class MB():
    
    UNIT_ID = 1
    FNCODE_READ_DISCRETE_INPUTS = 2
    FNCODE_READ_COILS = 1
    FNCODE_WRITE_SINGLE_COIL = 5
    FNCODE_WRITE_MULTIPLE_COILS = 15
    FNCODE_READ_INPUT_REGISTERS = 4
    FNCODE_READ_MULTIPLE_HOLDING_REGISTERS = 3
    FNCODE_WRITE_SINGLE_HOLDING_REGISTER = 6
    FNCODE_WRITE_MULTIPLE_HOLDING_REGISTERS = 16

class MBReply():
    
    def __init__(self, b):
        l = int.from_bytes(b[4:6], byteorder='big', signed=False) + 6
        if l != len(b):
            print("Warning: length mismatch")
        self.tn = b[0:2]
        self.fn = b[7]
        if self.fn == MB.FNCODE_READ_COILS or self.fn == MB.FNCODE_READ_DISCRETE_INPUTS:
            bits = int.from_bytes(b[10:12], byteorder='big', signed=False)
            size = ((bits - 1) // 8) + 1
            self.data = bytearray(size + 1)
            self.data[0] = size
            # TODO: maybe randomize the actual reply values
            
        elif self.fn == MB.FNCODE_READ_MULTIPLE_HOLDING_REGISTERS or self.fn == MB.FNCODE_READ_INPUT_REGISTERS:
            reg_count = int.from_bytes(b[10:12], byteorder='big', signed=False)
            self.data = bytearray(2 * reg_count + 1)
            self.data[0] = 2 * reg_count
            for i in range(reg_count):
                self.data[i*2+1:i*2+3] = random.randint(1, 0xffff).to_bytes(2, byteorder='big', signed=False)
                
        elif self.fn == MB.FNCODE_WRITE_SINGLE_COIL or self.fn == MB.FNCODE_WRITE_SINGLE_HOLDING_REGISTER:
            self.data = b[8:12]
            
        elif self.fn == MB.FNCODE_WRITE_MULTIPLE_COILS or self.fn == MB.FNCODE_WRITE_MULTIPLE_HOLDING_REGISTERS:
            self.data = b[8:12]
            
        else:
            print("Unsupported function: %d" % self.fn)
        
    def send(self, sock):
        b = bytearray(8)
        b[0:2] = self.tn
        b[4:6] = (len(self.data) + 2).to_bytes(2, byteorder='big', signed=False)
        b[6] = MB.UNIT_ID
        b[7] = self.fn
        
        b = b + self.data
        #print("Reply length: %d" % len(b))
        i = 0
        while i < len(b):
            i += sock.send(b[i:])
            #print("Sent %d" % i)
    
def thread_fn(sock):
    buf = bytearray()
    while True:
        msg = sock.recv(256)
        if len(msg) == 0: break
        buf.extend(msg)
        if len(buf) < 6: continue
        l = int.from_bytes(buf[4:6], byteorder='big', signed=False) + 6
        #print("%d bytes needed," % l, "%d bytes buffered" % len(buf))
        if len(buf) < l: continue
        #print("Replying")
        P = MBReply(buf[:l])
        P.send(sock)
        buf = buf[l:]
        
threads = []
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('', SERVER_PORT))
s.setblocking(False)
s.listen()
while True:
    try:
        try:
            sock, addr = s.accept()
        except BlockingIOError:
            continue
    except KeyboardInterrupt:
        break
    sock.setblocking(True)
    th = threading.Thread(target=thread_fn, args=(sock,))
    threads.append(th)
    th.start()
    for th in threads:
        th.join(0)
        threads = list(filter(lambda t: t.is_alive(), threads))
        
print("Closing server.")
s.shutdown(socket.SHUT_RDWR)
s.close()
