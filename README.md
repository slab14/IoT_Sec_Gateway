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

## Important info

We used a branched version of [l2switch](https://github.com/slab14/l2switch/tree/slab-demo) and [ovs](https://github.com/slab14/ovs/tree/slab).  Please refer to their repos for additional README info

## JSON Syntax

In this section, we talk about the various fields in the JSON policy file.  

Field | Defintion
:----:|----------
n | The number of unique devices in your policy file
devices | Contains the full breakdown of each device and its properties
name | Arbitrary identifier for each device
inMac | The ARP packet's source Mac address we want to match (* for any)
outMac | The ARP packet's destination Mac address we want to match (* for any)
states | Identifies the condition of being that the device is in (normal, vulnerable, etc.)
transition | Takes the form <middlebox>:<regex> for message analysis.  Defines the parameters for when to transition to the next middlebox
protections | Contains the full breakdown of the middleboxes to be used by the device
state | Not to be confused with states (plural).  Break down of the states field to match state to a middlebox.  
chain | There are currently 3 types of chains: P, A and X.  P is for passthrough middleboxes (like Snort).  A is for addressable middleboxes that act as proxies for your internal network (like squid_proxy).  X is for addressable middleboxes that require an IP to operate on the IOT device (NMAP scanner).  Know which chain to use is imperative to proper function of the middleboxes deployed.  
images | specifies the compiled Docker image that is saved on your Dataplane
sha1 | verify the integriy of the middlebox on deployment
imageOpts | Contains the full breakdown of image properties that your middlebox may need to properly function
contName | Arbitrary name given to started middleboxes (The Docker container name)
ip | Specifies an IP address for your Docker container (used for X and A type containers)
hostFS | Specifies files you wish to pull from your Dataplane into your middlebox
contFS | Specifies the directory on the middlebox in which to place the hostFS files
archives | Contains the breakdown of tar files to be pulled from the Dataplane to your middlebox.  This is similar to how hostFS/contFS works except designed specifically for tar files (Snort middleboxes)
tar | Specifies tar file on the Dataplane to be pulled into middlebox
path | Specifies the directory on the middlebox in which to place the tar file
  
## Information about our Docker containers

In this section, we discuss inherent mechanisms of our middleboxes.  If you are using a snort, iptables or NMAP middlebox; you will find these features in all of them. 

* DockerFile
  > DockerFile contains the initial commands when building a Docker image.  We use [Ubuntu:Xenial](https://packages.ubuntu.com/xenial/docker) as our lightweight OS.  
  - Within DockerFile, there are a few common packages required to create the SDN relationship between controller and dataplane elements.
    - **Ethtool/iproute2/bridge-utils/net-tools:** Allows us to view and modify the NIC.  Particularly used when creating bridges for P-type middleboxes.
    - **iptables:** Iptables allows us to create various packet queues which *checkHash.c* and *addHash.c* rely upon.
    - **openssl:** We make use of its crypto library in conjunction with our *checkHash.c*, *addHash.c* and *sendAlert.c* scripts.
    - **gcc/python:** Respective C/Python compilers for our automated scripts like *sendAlert.c* and *getAlerts.py*.
    - **various lib* packages:** dependencies for installed programs such as snort, netcat, etc.    
    - **watchdog:** python package used to monitor log files for changes that need to be reported to the controller.
  - We also make use of the COPY command to transfer the *getAlerts.py*, *\*Hash.c* files into the middlebox.
* Run.sh
  > Run.sh is the main entrypoint for the DockerFile upon container activation.  It contains the commands to compile and run our scripts and bash commands.
  - There is a fundamental check for eth interfaces using: `grep -q '^1$' "/sys/class/net/eth{#}/carrier"` to ensure that our interfaces were properly attached when starting the container from the controller.
    - Typically we follow a predefined eth setup:
      - Eth0: Sending messages to the controller
      - Eth1/2/3/...: Processing packets on the dataplane and moving them across nodes.
  - Once the eth interfaces have been detected using the `grep` command, we copy important information to the middlebox:
    - **ProtectionID:** Provides a unique identifier to each middlebox so the controller knows who sent the message.  Used by *getAlerts.py*.
    - **IOT_IP:** For A/X-Type containers, the controller provides the IoT device that attempted to join the network.  This is used for middleboxes such as NMAP to scan for open          ports or CVEs.
  - If the middlebox is a P-type, we also set up a bridge, connecting eth1/2/3... so that multiple nodes can communicate with each other through the middlebox.  In other words, we turn the middlebox into a smart switch.  A bridge is not necessary for A/X type containers because the communication is limited between the middlebox and one IoT device.  The A/X container can still talk to the controller using encrypted alerts across the eth0 interface.
  
* CheckHash.c/AddHash.c
  > CheckHash.c/AddHash.c were written to ensure integrity of communcation between controller and dataplane.  This does not ensure confidentialty as packets are still un-encrypted.
  - **CheckHash.c:** Once compiled with gcc, this script monitors the nfqueue created by iptables to capture packets and verify the hash of incoming packets.  This ensures integrity of commands against MITM attacks.
  - **AddHash.c:** Similar to *CheckHash.c*, this script monitors the nfqueue responsible for outgoing packets.  A SHA1 hash is calculated over the packet and attached to the end of the packet before being sent off.
  
* sendAlert.c
  > sendAlert.c contains encryption information such as your secret key, iv and IP address of the controller.
  - GCC compiles this into a Linux dynamic library called send.so 
  - *getAlerts.py* passes data to this LDL which is then enrypted using SSL and sent over to the controller.
  
* getAlerts.py
  > getAlerts.py makes use of the [watchdog package](https://pythonhosted.org/watchdog/) to monitor a predefined log file for alerts that need to be sent to the controller.  We can customize what the watchdog pays attention to
  - This python script attaches the ProtectionID to each alert that is captured by watchdog.  It makes use of the send.so library, compiled from the *sendAlert.c* script to encrypt with SSL.
    

## Apendix of experiments to test
_Although we recommend going in order_

- [2 Snort middleboxes](#steps-for-running-the-experiment-in-cloudlab-using-2-snort-middleboxes)
- [2 Iptables middleboxes](#steps-for-running-the-experiment-in-cloudlab-using-iptables-middlebox)
- [1 Snort middlebox w/ multiple archive files](#steps-for-running-the-experiment-in-cloudlab-using-1-snort-middlebox-and-multiple-archive-files)
- [NMAP middlebox transitioning to Snort middlebox](#steps-for-running-the-experiment-in-cloudLab-using-nmap-to-snort-middleboxes)

## Steps for running the experiment in CloudLab using 2 snort middleboxes

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
      - On "Dataplane", `cd` into __/etc/sec_gate/policies/__
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
      - Please follow steps 1 through 3 from [above](#steps-for-running-the-experiment-in-cloudlab-using-2-snort-middleboxes).
  - **2) Further configure JSON for iptables**
      - Open __/etc/sec_gate/policies/cloudlab-NewPolicy20.json__ 
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
        - __Note:__ This may take up to 15 seconds for the next ARP packet in case we missed it 
      - On "Dataplane", Node_0's MAC address will match with the policy (as specified in step 1) and deploy middlebox iptables_demoA
      - Attempt to send another ping from "Node_0" to "Node_1" 
      - On "Dataplane", you should see messages affirming a new container was started
      - ICMP packets should now be dropped.  Use netcat to test that other packets like TCP can still be received.
      
## Steps for running the experiment in CloudLab using 1 snort middlebox and multiple archive files
_This experiment demonstrates the "archive" property of the JSON policy file and how you can transition to the same middlebox with a different set of configurations/rules.  The experiment starts when an ARP request is received by the dataplane by either "Node_0" or "Node_1" to deploy a Snort middlebox designed to log ICMP packets.  Instead of switching to another static middlebox, when an ICMP packet is received, the current middlebox logs the packet, triggers an alert and causes a transition where the middlebox deployed is the same but a new local.rules (the archive file) is being copied over to the middlebox.  This implementation requires only a few line changes in the JSON file._

- **1) Initial setup**
    - Please follow steps 1 and 2 from [above](#steps-for-running-the-experiment-in-cloudlab-using-2-snort-middleboxes).
- **2) Further configure JSON**
    - Open __/etc/sec_gate/policies/cloudlab-NewPolicy20.json__ 
    - Under the first device, "device0", change the __inMac__ to the MAC address of your "Node_0"
    - Look for the __archives__ section and you will notice two tar-path pairs.  The tar is the file on the controller and path               represent where it will be stored inside the middlebox
    - Save and close.        
 - **3) Configure middlebox files**
    - On "Dataplane", `cd` into __IoT_Sec_Gateway/docker_containers/demo_conts/snort_base__
    - Run the following command `sudo ./genTar.sh` to generate and move the snort rules and config file to your _/etc/IoT_Sec_ folder on your          controller/dataplane node.
     - In __getAlerts.py__, change the IP address to the public-facing IP address of the "Dataplane" node in CloudLab
        - Note: This is the address that CloudLab uses to ssh into the node (128.x.x.x)
 - **4) Start ODL on Data Plane**
      - On "Dataplane", you should now see the __l2switch__ folder in root
      - On "Dataplane", run the following command: 
      `./l2switch/startODL.sh`
      - If an error occurs, try running `sudo ./l2switch/build.sh` first and then rerun `./l2switch/startODL.sh`
      - You should see a "Ready" message on the ODL console letting you know it is ready to receive ARP packets
      
  - **5) Test**
      - Attempt to send 1 ping from "Node_0" to "Node_1" to create the ARP request (`ping 10.1.1.2 -c 1`)
        - __Note:__ This may take up to 15 seconds for the next ARP packet in case we missed it 
      - On "Dataplane", Node_0's MAC address will match with the policy (as specified in step 1) and deploy middlebox snort_base loaded         with rules_a.tar which logs and allows ICMP packets.
      - Attempt to send another ping from "Node_0" to "Node_1" 
      - On "Dataplane", you should see messages affirming a new container was started
      - The same middlebox is redeployed but with rules_b.tar.
      - ICMP packets should now be dropped.  Use netcat to test that other packets like TCP can still be received.
      
## Steps for running the experiment in CloudLab using nmap to snort middleboxes
_This experiment demonstrates the capabilities of the 'transition' field in the JSON policy file.  Here, we start an Nmap middlebox which scans for all open ports  of the IoT device and compares with the allowed ports in the transition field.  If an open port is not on the whitelist, we automatically transition to a snort middlebox with a new local.rules which drops the packets of the offending port._

  - **1) Initial setup**
      - Please follow steps 1 through 2 from [above](#steps-for-running-the-experiment-in-cloudlab-using-2-snort-middleboxes).
  - **2) JSON configuration**
      - Open __/etc/sec_gate/policies/cloudlab-NewPolicy20.json__
      - Search for the device entry, "nmap0".
      - Configure your __inMAC__ with the Mac address of "Node_0".
        - __Note:__ Verify no other devices in the policy have the same inMAC or the wrong device may activate.
      - In the __transition__ field, configure your whitelist of ports with the following syntax: `nmap:openports_{1,2,3..}` (remove braces).
        - During the NMAP scan, if a port is not on this whitelist, the controller has a reason to transition to the Snort middlebox.
  - **3) Open a bad port**
      - To test the functionality, use `nc -k -l -p {any port not on the whitelist} &` to create an TCP listening server on "Node_0".
        - __Note:__ You may need to `sudo apt-get install netcat` to enable this command.
  - **4) Start ODL on Data Plane**
      - On "Dataplane", you should now see the __l2switch__ folder in root.
      - On "Dataplane", run the following command: `./l2switch/startODL.sh`
      - If an error occurs, try running `./l2switch/build.sh` first and then rerun `./l2switch/startODL.sh`
      - You should see a "Ready" message on the ODL console letting you know it is ready to receive ARP packets.
  - **5) Test**
      - Attempt to send a ping from "Node_0" to "Node_1" to create the ARP request (`ping 10.1.1.2`)
        - __Note:__ This may take up to 15 seconds for the next ARP packet in case we missed it. 
      - From the "Dataplane", you should see output affirming that an Nmap middlebox has started and is scanning your inMac device.
      - From the "Dataplane", you should see output for a newly generated Snort rule.  This rule will drop all TCP packets from the offending port you chose in Step 3.
      - After the Snort middlebox has been deployed, attempt to communicate with the netcat server from "Node_1" using the following command `nc 192.1.1.2 {offending port}`.           This attempt should be unsuccessful.  If you try to create a UDP server on "Node_0" using the same port, or attempt to open another port, you should have no problems             communicating between "Node_0" and "Node_1".
      






      
      
      

