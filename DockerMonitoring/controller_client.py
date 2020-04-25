#!/usr/bin/python
import socket
import ast
from argparse import ArgumentParser

HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 65432        # The port used by the server

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
cmd = "GET"
cmd = bytes(cmd)
print cmd
s.sendall(cmd)
data = s.recv(1024)

if data == "No containers running":
    exit()
print('Received',data)

container_dict = ast.literal_eval(data)

#perform logic for deciding which container to checkpoint
for cont_id in container_dict:
    l = container_dict[cont_id]
    checkpoint_name = l[0] + "_check"
    container_name = l[1]
    if container_name != "iperf_dontkillme":
        continue
    cmd = bytes("CHECKPOINT {} {}".format(container_name,checkpoint_name))
    s.sendall(cmd)
    data = s.recv(1024)
    print('Received', data)
#end of logic, assume container name already available
