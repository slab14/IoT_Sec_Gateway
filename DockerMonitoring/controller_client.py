#!/usr/bin/python
import socket
import ast
from argparse import ArgumentParser
import time

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

print "Sleep"
time.sleep(1)

container_dict = ast.literal_eval(data)
checkpointed_containers = []

#perform logic for deciding which container to checkpoint
checkpoint_container = ""
min_score = 100

for cont_id in container_dict:
    l = container_dict[cont_id]
    base_score = l[2][1]
    
    if base_score < min_score :
        min_score = base_score
        checkpoint_container = l[1][1]

checkpoint_name = checkpoint_container + "_check"
cmd = bytes("CHECKPOINT {} {}".format(checkpoint_container,checkpoint_name))
s.sendall(cmd)
data = s.recv(1024)
print('Received', data)
if data == "Success":
    #save this information
    checkpointed_containers.append((checkpoint_container,checkpoint_name))
print "Checkpointed containers: ", checkpointed_containers
#end of logic, assume container name already available
print "Sleep"
time.sleep(2)

for i in checkpointed_containers:
    container_name = i[0]
    checkpoint_name = i[1]
    cmd = bytes("RESTORE {} {}".format(checkpoint_name,container_name))
    s.sendall(cmd)
    data = s.recv(1024)
    print('Received', data)
