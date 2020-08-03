import sys
import dpkt
import socket

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
    
    @staticmethod
    def fnCode2Str(fn):
        if fn == MB.FNCODE_READ_DISCRETE_INPUTS:
            return "Read Discrete Inputs"
        if fn == MB.FNCODE_READ_COILS:
            return "Read Coils"
        if fn == MB.FNCODE_WRITE_SINGLE_COIL:
            return "Write Single Coil"
        if fn == MB.FNCODE_WRITE_MULTIPLE_COILS:
            return "Write Multiple Coils"
        if fn == MB.FNCODE_READ_INPUT_REGISTERS:
            return "Read Input Registers"
        if fn == MB.FNCODE_READ_MULTIPLE_HOLDING_REGISTERS:
            return "Read Multiple Holding Registers"
        if fn == MB.FNCODE_WRITE_SINGLE_HOLDING_REGISTER:
            return "Write Single Holding Register"
        if fn == MB.FNCODE_WRITE_MULTIPLE_HOLDING_REGISTERS:
            return "Write Multiple Holding Registers"
    

class MBTransaction():
    
    def __init__(self, timestamp, buf=None):
        self.buf = bytearray()
        self.len = -1
        self.time = timestamp
        self.valid = False
        
        self.reply_buf = bytearray()
        self.reply_len = -1
        self.reply_valid = False
        self.wait_for_reply = False
        
        if buf: self.append(buf)
    
    def append(self, buf):
        self.buf += buf
        self.check()
    
    def check(self):
        if len(self.buf) < 6: return
        self.len = int.from_bytes(self.buf[4:6], byteorder='big', signed=False) + 6
        if len(self.buf) < self.len: return
        if len(self.buf) > self.len: print("Warning: Multiple transaction in single connection or transaction longer than expected!")
        self.tn = int.from_bytes(self.buf[0:2], byteorder='big', signed=False)
        self.fn = self.buf[7]
        self.valid = True
    
    def append_reply(self, timestamp, buf):
        self.reply_buf += buf
        self.check_reply(timestamp)
          
    def check_reply(self, timestamp):
        if len(self.reply_buf) < 6: return
        self.reply_len = int.from_bytes(self.reply_buf[4:6], byteorder='big', signed=False) + 6
        if len(self.reply_buf) < self.reply_len: return
        if len(self.reply_buf) > self.reply_len: print("Warning: Reply longer than expected!")
        tn = int.from_bytes(self.reply_buf[0:2], byteorder='big', signed=False)
        fn = self.reply_buf[7]
        if tn != self.tn: print("Warning: Transaction number mismatch")
        if fn != self.fn: print("Warning: Function code mismatch")
        self.reply_valid = True
        self.response_time = timestamp
    
    def recv(self):
        recv_buf = bytearray()
        while True:
            msg = self.sock.recv(6 - len(recv_buf))
            if len(msg) == 0:
                print("No reply")
                break
            recv_buf.extend(msg)
            if len(recv_buf) == 6: break
        l = int.from_bytes(recv_buf[4:6], byteorder='big', signed=False) + 6
        while True:
            msg = self.sock.recv(l - len(recv_buf))
            if len(msg) == 0:
                print("No reply")
                break
            recv_buf.extend(msg)
            #print("%d bytes needed," % l, "%d bytes buffered" % len(recv_buf))
            if len(recv_buf) == l: break
    
    def __repr__(self):
        if self.valid:
            wait = "| Wait for reply" if self.wait_for_reply else ""
            return f"MODBUS | t={self.time:.6f} | {MB.fnCode2Str(self.fn)} | {' '.join(format(x, '02x') for x in self.buf[8:])} {wait}"
        elif self.len >= 0:
            return f"MODBUS | t={self.time:.6f} | Incomplete packet length {len(self.buf)}, expected {self.len}"
        else:
            return f"MODBUS | t={self.time:.6f} | Incomplete packet"

if len(sys.argv) < 4 or len(sys.argv) > 4:
    print("Usage: python3 mbfilter.py <pcap_file_name> <pcap slave/server IP> <pcap master/client IP>")
    exit(-1)

PCAP_SERVER_IP = sys.argv[2]
PCAP_CLIENT_IP = sys.argv[3]

fpcap = open(sys.argv[1], 'rb')
pcap = dpkt.pcap.Reader(fpcap)

flows = dict()
order = []
last = None
basetime = None
for timestamp, buf in pcap:
    if basetime is None: basetime = timestamp
    eth = dpkt.ethernet.Ethernet(buf)
    if not isinstance(eth.data, dpkt.ip.IP):
        continue
    ip = eth.data
    if not isinstance(ip.data, dpkt.tcp.TCP):
        continue
    tcp = ip.data
    src_addr = socket.inet_ntop(socket.AF_INET, ip.src)
    dst_addr = socket.inet_ntop(socket.AF_INET, ip.dst)
    #print(src_addr, tcp.sport, "->", dst_addr, tcp.dport)
    if src_addr == PCAP_CLIENT_IP and dst_addr == PCAP_SERVER_IP and tcp.dport == 502:
        if tcp.sport not in flows:
            flows[tcp.sport] = MBTransaction(timestamp - basetime)
            order.append(flows[tcp.sport])
            last = tcp.sport
        pkt = flows[tcp.sport]
        pkt.append(tcp.data)
    elif dst_addr == PCAP_CLIENT_IP and tcp.dport in flows and src_addr == PCAP_SERVER_IP and tcp.sport == 502:
        pkt = flows[tcp.dport]
        pkt.append_reply(timestamp - basetime, tcp.data)
        if pkt.reply_valid:
            pkt.wait_for_reply = pkt.wait_for_reply or (last == tcp.dport)
    
fpcap.close()
print("File parsing complete.")

total_rt = 0
max_rt = 0
min_rt = 999
count_rt = 0
count_inval = 0
for pkt in order:
    if pkt.reply_valid:
        rt = pkt.response_time - pkt.time
        max_rt = max(max_rt, rt)
        min_rt = min(min_rt, rt)
        total_rt += rt
        count_rt += 1
    else:
        count_inval += 1
print("Response time (SYN to response complete):")
print("Average:", total_rt / count_rt)
print("Max:", max_rt)
print("Min:", min_rt)
print("Number of transactions considered: ", count_rt)
print("Number of incomplete exchanges: ", count_inval)
