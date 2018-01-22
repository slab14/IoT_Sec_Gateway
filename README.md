# IoT_Sec_Gateway
Implementing a Software Defined Gateway for use with IoT devices

Current version: v0
- Implements a very basic dynamic policy using a middlebox running Snort with 2 different versions of rules.
Demo: Ping detect/filter
0. The controller parses the policy JSON file (policy/policy0.json).
1. The initial Snort container (docker_containers/snort_icmp_alert) allows all messages to be passed from the user/attacher to the IoT device. It will create a Snort alert when it detects an ICMP packet (a ping).
2.  When the controller receives the Snort alert that a ping request was received, it terminates the running Snort container and removes the virtual switch routing to it. Then it starts up a new Snort container that will block ping requests (docker_containers/snort_icmp_block) and sets virtual switch routing to use this new Snort container. Now ICMP packets cannot be sent from the user/attacher to the device, but regular TCP packets can be sent.


Demonstrated in Cloudlab, using 3 physical machines each running Ubuntu 16.04. The topology information can be found here: https://www.cloudlab.us/manage_profile.php?action=edit&uuid=0d1e3689-b5bb-11e7-b179-90e2ba22fee4

Topology picture:   Device 1 -- Device 2 -- Device 3

- Device 1: "Node_0" emulates the user/attacher trying to access the IoT device (IP address: 192.1.1.2)
- Device 2: "Dataplane" emulates the software-defined security gateway. It is running OVS to create a virtual switch for routing IP traffic through the middlebox specified in the policy (policy/policy0.json). It runs a very basic "controller" (simple-controller.py) to dynamically change the middlebox and routing of IP traffic based upon events it receives from the middlebox.
- Device 3: "Node_1" emulates an IoT device (IP address: 10.1.1.2)


Running the experiment:
1. Initial device setup:

--A) Run setup-node.sh on the systems emulating the user/attacher and the IoT device (Device 1 & Device 3).

---- Runs apt-get update, installs python & iperf3, and ensures that the ip routing is setup to use the proper NIC for transmitting packets through the software-defined security gateway.

--B) Run setup-data-plane.sh on the system emulating the software-defined security gateway (Device 2).

---- Runs apt-get update, installs python, docker, & OVS. Builds snort containers for this emonstration (docker_containers/*). Disables GRO, and sets up a bridge (br0) between the NIC connected to Device 1 (enp6s0f0) and the NIC connected to Device 3 (enps6s0f1).

---- NOTE: at this point, Device 1 and Device 3 should be able to send packets (i.e. ping) between each other. However, the IP addresses associated with Device 2's NICs will no longer be usable.

2. Ensure that desired JSON policy is specified (policy/*).

3. Turn on the "simple controller" (simple-controller.py -B br0 -P policy/policy0.json).

-- Once the controller starts up, it parses the policy, and sets up routing for the initial middlebox (docker_container/snort_icmp_alert)

---- Can demonstrate sending TCP packets between Device 1 & 3 (e.g. nc -l 1234 & cat file | nc IP_address 1234).

-- Once an ICMP packet is sent (e.g. ping IP_address -c 1), the controller will receive the Snort alert and change the middlebox to be (docker_containers/snort_icmp_block)

---- Can demonstrate sending TCP packets between Device 1 & 3 (e.g. nc -l 1234 & cat file | nc IP_address 1234).

---- Can demonstrate that ICMP packets are dropped between Device 1 & 3 (e.g. ping IP_address -c 1) because they are being blocked by Snort container. 