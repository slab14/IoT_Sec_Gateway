#!/usr/bin/python

from utils.OVS_Tools import start_container, attach_container, attach_container_wIP, setup_flow, exec_cmd_in_container

BRIDGE='br0'

CONTAINER_NAME_and_IMAGE_LIST=[("client", 'iperf', '10.1.1.1/24'), ("server", 'iperf', '10.1.1.2/24')]
FLOW=[("client", 1), ("server", 1)]

# start-up containers
for containerName,containerImage,containerIP in CONTAINER_NAME_and_IMAGE_LIST:
    if containerImage=='iperf':
        start_container(containerImage, containerName)
        attach_container_wIP(BRIDGE, containerName, 'eth0', containerIP)


# Create flow
setup_flow(BRIDGE, FLOW)

# Test pings
print("\n********\nTesting ping from server to client\n*********\n")
exec_cmd_in_container("server", "ping -c 4 10.1.1.1")
print("\n********\nTesting ping from client to server\n*********\n")
exec_cmd_in_container("client", "ping -c 4 10.1.1.2")

