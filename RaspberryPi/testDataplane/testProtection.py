#!/usr/bin/python

from utils.OVS_Tools import start_container, attach_container, attach_container_wIP, setup_flow, exec_cmd_in_container

BRIDGE='br0'

CONTAINER_NAME_and_IMAGE_LIST=[("client", 'iperf', '10.1.1.1/24'), ("server", 'iperf', '10.1.1.2/24'), ("aegis", 'pingblock','')]
FLOW=[("client", 1), ("aegis", 2), ("server", 1)]

# start-up containers
for containerName,containerImage,containerIP in CONTAINER_NAME_and_IMAGE_LIST:
    if containerImage=='iperf':
        start_container(containerImage, containerName)
        attach_container_wIP(BRIDGE, containerName, 'eth0', containerIP)
    if containerImage=='pingblock':
        start_container(containerImage, containerName, True)
        attach_container(BRIDGE, containerName)        


# Create flow
setup_flow(BRIDGE, FLOW)

# Test pings
print("\n********\nTesting ping from server to client\n*********\n")
exec_cmd_in_container("server", "ping -c 4 10.1.1.1", noCheck=True)
print("\n********\nTesting ping from client to server\n*********\n")
exec_cmd_in_container("client", "ping -c 4 10.1.1.2", noCheck=True)

# Test iperf
print("\n********\nTesting TCP traffic using iperf3 from client to server\n********\n")
exec_cmd_in_container("client", "iperf3 -c 10.1.1.2")
