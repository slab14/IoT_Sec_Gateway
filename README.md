# IoT_Sec_Gateway
Implementing a Software Defined Gateway for use with IoT devices

**Current version:** v0.1 

**Objective:** Implements a very basic static policy setup by an SDN Controller (OpenDayLight). There are two demonstrations; the first uses snort rules to capture/drop/log packets.  The seconds uses iptables to capture/drop/log packets.  Both of which run a python script which checks for new logged packets that match the specified rule (in our case, ICMP packets) and triggers the necessary middleboxes to block future ICMP packets.  

**How it works:**

0. The controller parses the [JSON policy file](https://github.com/brytul/IoT_Sec_Gateway/blob/master/policies/cloudlab-NewPolicy20.json).
1. The initial Snort container (docker_containers/demo_cont/snort_demoA) allows all packets to be passed from the user/attacker to the IoT device. It will create a Snort alert when it detects an ICMP packet (a ping).
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
- Device 2: "Dataplane" emulates the software-defined security gateway (both the controller and dataplane are on this host). It is running OVS to create a virtual switch for routing IP traffic through the middlebox specified in the [policy](https://github.com/brytul/IoT_Sec_Gateway/blob/master/policies/cloudlab-NewPolicy20.json). The controller which is running OpenDayLight will dynamically change the middlebox whenever a ICMP/ARP alert is triggered.  The ARP alerts is used to deploy the intial middlebox and the ICMP alert is used to trigger the next middlebox according to the policy file.
- Device 3: "Node_1" emulates an IoT device (IP address: 10.1.1.2)


## Steps for running the experiment in CloudLab using snort middlebox

  - **1) Initial setup**
      - Run the following command on all 3 nodes:
      `git clone https://github.com/slab14/IoT_Sec_Gateway.git`
      
  - **2) Setup each node**
  
      - On "Node_0" and "Node_1", `cd` into __IoT_Sec_Gateway__ and run the following:
      `./setup-node.sh`
        - This script will install our tree of OVS, and install the normal builds of Docker, Maven, etc.  It also adds the routing rules            to the apt network interface so that the nodes can talk to each other when we build the network bridge.  
      - On "Dataplane", `cd` into __IoT_Sec_Gateway__ and run the following:
      `./setup-data-plane.sh`
        - This script follows similar setup to the above bash script with additional configuration for the "Dataplane"; it also starts             the ovsdb_server, builds the docker containers, sets up docker to recevie remote commands from the controller and builds the              last part of the network bridge for "Node_0" and "Node_1" to talk to each other.
      
  - **3) Configure JSON policy** 
      - On "Dataplane", `cd` into __IoT_Sec_Gateway/policies/__
      - Open __cloudlab-NewPolicy20.json__ 
      - Scroll down to the name __TestNode0__ and change the __inMac__ variable to the MAC address of Node_0
        - Note: Referring to the MAC at iface enp6s0f0/enp6s0f1 
        
  - **4) Configure demo containers**
      - On "Dataplane", `cd` into __IoT_Sec_Gateway/docker_containers/demo_conts/__
      - In the __snort_demo(a/b)__ folders, there is a script called __getAlerts.py__ - you will need to edit both scripts.
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
      - You should see a "Ready" message on the ODL console letting you know it is ready to receive ARP packets
      
  - **6) Test**
      - Attempt to send a ping from "Node_0" to "Node_1" to create the ARP request
      - On "Dataplane", Node_0's MAC address will match with the policy (as specified in step 3) and deploy middlebox demoA
      - Attempt to send another ping from "Node_0" to "Node_1" 
      - On "Dataplane", you should see messages affirming a new container was started
      - ICMP packets should now be dropped.  Use netcat to test that other packets like TCP can still be received.
      
## Steps for running the experiment in CloudLab using iptables middlebox

  - **1) Initial setup**
      - Please follow steps 1 through 3 from above.
  - **2) Further configure JSON for iptables**
      - Open __IoT_Sec_Gateway/policies/cloudlab-NewPolicy20.json__ 
      - Under "TestNode0", there are two protection states.  Change the __images__ variable for the __normal__ state to `iptables_demoa`. Change the __images__ variable for the __scared__ state to `iptables_demob`
      - Save and close.        
  - **3) Configure demo containers**
      - On "Dataplane", `cd` into __IoT_Sec_Gateway/docker_containers/demo_conts/__
      - In the __iptables_demo(a/b)__ folders, there is a script called __getAlerts.py__ - you will need to edit both scripts.
      - In __getAlerts.py__, change the IP address to the public-facing IP address of the "Dataplane" node in CloudLab
        - Note: This is the address that CloudLab uses to ssh into the node (128.x.x.x)
      - Run the following commands to recompile the Docker containers with the new IP address:
        - `sudo docker build -t iptables_demoa ~/IoT_Sec_Gateway/docker_cont/demo_cont/iptables_demoa`
        - `sudo docker build -t iptables_demob ~/IoT_Sec_Gateway/docker_cont/demo_cont/iptables_demob`
 
  - **4) Start ODL on Data Plane**
      - On "Dataplane", you should now see the __l2switch__ folder in root
      - On "Dataplane", run the following command: 
      `./l2switch/startODL.sh`
      - If an error occurs, try running `sudo ./l2switch/build.sh` first and then rerun `./l2switch/startODL.sh`
      - You should see a "Ready" message on the ODL console letting you know it is ready to receive ARP packets
      
  - **5) Test**
      - Attempt to send 1 ping from "Node_0" to "Node_1" to create the ARP request (`ping 10.1.1.2 -c 1`)
        - __Note:__ This make take up to 30 seconds for the next ARP packet in case we missed it 
      - On "Dataplane", Node_0's MAC address will match with the policy (as specified in step 1) and deploy middlebox iptables_demoA
      - Attempt to send another ping from "Node_0" to "Node_1" 
      - On "Dataplane", you should see messages affirming a new container was started
      - ICMP packets should now be dropped.  Use netcat to test that other packets like TCP can still be received.
      
     
## Important info

We used a branched version of [l2switch](https://github.com/slab14/l2switch/tree/slab-demo) and [ovs](https://github.com/slab14/ovs/tree/slab).  Please refer to their repos for additional README info


      
      
      

