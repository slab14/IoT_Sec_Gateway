# IoT_Sec_Gateway
Implementing a Software Defined Gateway for use with IoT devices

**Current version:** v0.1 

**Objective:** Implements a very basic static policy setup by an SDN Controller (OpenDayLight). 

**How it works:**

0. The controller parses the [JSON policy file](https://github.com/brytul/IoT_Sec_Gateway/blob/master/policies/cloudlab-NewPolicy20.json).
1. The initial Snort container (docker_containers/demo_cont/snort_demoA) allows only ping (ICMP) messages to be passed from the user/attacker to the IoT device. It will create a Snort alert when it detects an ICMP packet (a ping).
2.  When the controller receives an initial ARP packet, it starts up the middlebox and creates the routing rules. 
3. The initial middlebox (DemoA) allows ICMP packets as per snort configuration
4. Sending an ICMP packet will trigger a chnage of state for the IoT device and deploy a transitionary middlebox (DemoB)
5. The DemoB middlebox contains snort rules to now block ICMP packets
6. Try sending an ICMP packet (ping) and a TCP packet (netcat).  Only TCP packets will make it through.
7. Does not currently transition back to DemoA

Demonstrated in Cloudlab, using 3 physical machines each running Ubuntu 16.04. The topology information can be found here: https://www.cloudlab.us/manage_profile.php?action=edit&uuid=0d1e3689-b5bb-11e7-b179-90e2ba22fee4

Topology picture:   Device 1 -- Device 2 -- Device 3
![alt text](https://i.ibb.co/JpkNXzv/image.png)

- Device 1: "Node_0" emulates the user/attacker trying to access the IoT device (IP address: 192.1.1.2)
- Device 2: "Dataplane" emulates the software-defined security gateway (both the controller and dataplane are on this host). It is running OVS to create a virtual switch for routing IP traffic through the middlebox specified in the [policy](https://github.com/brytul/IoT_Sec_Gateway/blob/master/policies/cloudlab-NewPolicy20.json). It runs a very basic "controller" (simple-controller.py) to dynamically change the middlebox and routing of IP traffic based upon events it receives from the middlebox.
- Device 3: "Node_1" emulates an IoT device (IP address: 10.1.1.2)


## Steps for running the experiment in CloudLab

  - **1) Initial setup**
      - Run the following command on all 3 nodes:
      `git clone https://github.com/slab14/IoT_Sec_Gateway.git`
      
  - **2) Setup each node**
  
      - On "Node_0" and "Node_1", `cd` into __IoT_Sec_Gateway__ and run the following:
      `./setup-node.sh`
      - On "Dataplane", `cd` into __IoT_Sec_Gateway__ and run the following:
      `./setup-data-plane.sh`
      
  - **3) Configure JSON policy** 
      - On "Dataplane", `cd` into __IoT_Sec_Gateway/policies/__
      - Open __cloudlab-NewPolicy20.json__ 
      - Scroll down to the name __TestNode0__ and change the __inMac__ variable to the MAC address of either Node_0 or Node_1
        - Note: Referring to the MAC at iface enp6s0f0/enp6s0f1 
        
  - **4) Configure demo containers**
      - On "Dataplane", `cd` into __IoT_Sec_Gateway/docker_containers/demo_conts/__
      - In each of the 3 folders, there is a script called __getAlerts.py__ - you will need to edit all 3 scripts
      - In __getAlerts.py__, change the IP address to the public-facing IP address of the "Dataplane" node in CloudLab
        - Note: This is the address that CloudLab uses to ssh into the node (128.x.x.x)
      - Run the following commands to recompile the Docker containers with the new IP address:
        - `sudo docker build -t snort_demoa ~/IoT_Sec_Gateway/docker_cont/demo_cont/snort_demoA`
        - `sudo docker build -t snort_demob ~/IoT_Sec_Gateway/docker_cont/demo_cont/snort_demoB`
 
  - **5) Start ODL on Data Plane**
      - On "Dataplane", you should now see the __l2switch__ folder in root
      - On "Dataplane", run the following command: 
      `./l2switch/startODL.sh`
      - If an error occurs, try running `sudo ./l2switch/build.sh` first and then rerun `./l2switch/startODL.sh`
      
     
## Important info

We used a branched version of [l2switch](https://github.com/slab14/l2switch/tree/slab-demo).  Please refer to this repo for more info on ODL and custom scripts used to accomplish the demo
      
      
      

