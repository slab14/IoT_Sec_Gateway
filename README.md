# IoT_Sec_Gateway
Implementing a Software Defined Gateway for use with IoT devices

Current version: v0.1
- Implements a very basic static policy setup by an SDN Controller (OpenDayLight).
Demo: 
0. The controller parses the policy JSON file (policy/newPolicy0.json).
1. The initial Snort container (docker_containers/snort_direct_block_v2) allows only ping (ICMP) messages to be passed from the user/attacker to the IoT device. It will create a Snort alert when it detects an ICMP packet (a ping).
2.  When the controller receives an initial ARP packet, it starts up the middlebox and creates the routing rules. 


Demonstrated in Cloudlab, using 3 physical machines each running Ubuntu 16.04. The topology information can be found here: https://www.cloudlab.us/manage_profile.php?action=edit&uuid=0d1e3689-b5bb-11e7-b179-90e2ba22fee4

Topology picture:   Device 1 -- Device 2 -- Device 3

- Device 1: "Node_0" emulates the user/attacker trying to access the IoT device (IP address: 192.1.1.2)
- Device 2: "Dataplane" emulates the software-defined security gateway (both the controller and dataplane are on this host). It is running OVS to create a virtual switch for routing IP traffic through the middlebox specified in the policy (policy/newPolicy0.json). It runs a very basic "controller" (simple-controller.py) to dynamically change the middlebox and routing of IP traffic based upon events it receives from the middlebox.
- Device 3: "Node_1" emulates an IoT device (IP address: 10.1.1.2)


Running the experiment:
1. Initial device setup:

--A) Run setup-node.sh on the systems emulating the user/attacker and the IoT device (Device 1 & Device 3).

---- Runs apt-get update, docker, (modified version of) ovs (includes ovs-docker-remote) and ensures that the ip routing is setup to use the proper NIC for transmitting packets through the software-defined security gateway.

  ------ Hosts may require removing routes that are specified 'via' the dataplane host. 

--B) Run setup-data-plane.sh on the system emulating the software-defined security gateway (Device 2).

---- Runs apt-get update, docker, & (modified version of) OVS (includes ovs-docker-remote). Builds snort containers for this emonstration (docker_containers/*). Disables GRO, and sets up a bridge (br0) between the NIC connected to Device 1 (enp6s0f0) and the NIC connected to Device 3 (enps6s0f1).

---- NOTE: at this point, Device 1 and Device 3 should be able to send packets (i.e. ping) between each other. However, the IP addresses associated with Device 2's NICs will no longer be usable.

2. Ensure that desired JSON policy is specified (policy/*).

