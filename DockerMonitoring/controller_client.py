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
checkpointed_containers = []
#perform logic for deciding which container to checkpoint
for cont_id in container_dict:
    l = container_dict[cont_id]
    container_name = l[1]
    if container_name != "iperf_dontkillme":
        continue 
    checkpoint_name = l[0] + "_check"
    cmd = bytes("CHECKPOINT {} {}".format(container_name,checkpoint_name))
    s.sendall(cmd)
    data = s.recv(1024)
    print('Received', data)
    if data == "Success":
        #save this information
        checkpointed_containers.append((container_name,checkpoint_name))
print checkpointed_containers
#end of logic, assume container name already available

for i in checkpointed_containers:
    container_name = i[0]
    checkpoint_name = i[1]
    cmd = bytes("RESTORE {} {}".format(container_name,checkpoint_name))
    s.sendall(cmd)
    data = s.recv(1024)
    print('Received', data)
