import socket
from monitor import *

HOST = '127.0.0.1'  # Standard loopback interface address (localhost)
PORT = 65432        # Port to listen on (non-privileged ports are > 1023)

#supported commands
#GET 
#CHECKPOINT <container name>
def parse(input_data):

    if input_data == 'GET':
#        d = {'a': ['iperf',{'DRS': 522, 'RSS': 234}]}
        return str(get_container_stats())
    elif input_data.startswith('CHECKPOINT'):
        print "Checkpoint requested"
        return enable_checkpoint(input_data.split()[1], input_data.split()[2])

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))
s.listen(5)
while True:
    conn, addr = s.accept()
    print('Connected by', addr)
    while True:
        data = conn.recv(1024)
        if not data:
            break
        print data
        out = parse(data)
        conn.sendall(out)
