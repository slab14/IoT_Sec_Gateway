/*
 * Copyright © 2017 slab and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package edu.cmu.slab.impl;

import org.opendaylight.controller.md.sal.binding.api.NotificationPublishService;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.CONFIGURATION;
import java.util.Collection;
import org.opendaylight.yang.gen.v1.edu.cmu.slab.yang.dockertest.rev180606.DockerTest;
import org.opendaylight.controller.md.sal.binding.api.DataObjectModification;
import org.opendaylight.controller.md.sal.binding.api.DataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataTreeModification;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.concepts.ListenerRegistration;

import java.util.List;
import java.util.ArrayList;
import java.util.Scanner;
import java.io.IOException;

public class DockerTestProvider implements DataTreeChangeListener<DockerTest> {
    private List containerNames = new ArrayList();
    
    private static final Logger LOG = LoggerFactory.getLogger(DockerTestProvider.class);

    private DataBroker dataBroker;
    private NotificationPublishService notificationProvider;

    private ListenerRegistration<DockerTestProvider> dataTreeChangeListenerRegistration;
    private static final InstanceIdentifier<DockerTest> DOCKER_TEST_IID = InstanceIdentifier.builder(DockerTest.class).build();

    public DockerTestProvider(DataBroker dataBroker, NotificationPublishService notificationPublishService) {
        this.dataBroker = dataBroker;
	this.notificationProvider = notificationPublishService;

    }
    
    private String bridge_name="ovs_br1";
    private String external_iface="enp6s0f1";
    private String dataplaneIPAddr="192.1.1.1";
    private String dockerPort="4243";
    private String ovsPort="6677";
    private String bridge_port="6633";
    
    /**
     * Method called when the blueprint container is created.
     */
    public void init() {
	dataTreeChangeListenerRegistration = dataBroker.registerDataTreeChangeListener(new DataTreeIdentifier<>(CONFIGURATION, DOCKER_TEST_IID), this);
        LOG.info("DockerTestProvider Session Initiated");
	String cmd = "/usr/bin/sudo /usr/bin/docker ps --format '{{.Names}}'";
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	Iterable<String> sc = () -> new Scanner(output).useDelimiter("\n");
	for(String line:sc) {
	    String val = line.replace("\'", "");
	    containerNames.add(val);
	}
    }

    /**
     * Method called when the blueprint container is destroyed.
     */
    public void close() {
	System.out.println("Shutting down");
	for(int x=0; x<containerNames.size(); x++) {
	    System.out.println(containerNames.get(x));
	    remoteShutdownContainer(dataplaneIPAddr, dockerPort, (String) containerNames.get(x), bridge_name, ovsPort);
	    //Local Version
	    //shutdownContainer((String) containerNames.get(x));
	}
	remoteRemoveBridges(dataplaneIPAddr, bridge_port, bridge_name, ovsPort);
	//Local Version
	//removeBridges();
	System.out.println("Good-bye");
	LOG.info("DockerTestProvider Closed");
    }

    @Override
    public void onDataTreeChanged(Collection<DataTreeModification<DockerTest>> changes) {
	for(DataTreeModification<DockerTest> change: changes) {
	    DataObjectModification<DockerTest> rootNode = change.getRootNode();
	    if(rootNode.getModificationType()==DataObjectModification.ModificationType.WRITE) {
		System.out.println("Got a new input");
		DockerTest newObj = rootNode.getDataAfter();
		String newVal = newObj.getName();
		boolean usedPreviously = inList(containerNames, newVal);
		if(!usedPreviously) {
		    String cont_image="busybox";
		    String cont_iface="eth1";
		    //String bridge_port="6633";
		    remoteStartContainer(dataplaneIPAddr, dockerPort, newVal, cont_image);
		    remoteInstallOVSBridge(dataplaneIPAddr, ovsPort, bridge_name);
		    remoteAddExternalPort(dataplaneIPAddr, ovsPort, bridge_name, external_iface);
		    remoteAddContainerPort(bridge_name, newVal, cont_iface, dataplaneIPAddr, ovsPort, dockerPort, new String("10.1.6.1/16"));
		    setupRemoteSwitch(dataplaneIPAddr, ovsPort, bridge_name, bridge_port);
		    String extOFPort=remoteFindExternalOfPort(dataplaneIPAddr, bridge_port, external_iface);
		    String contOFPort=remoteFindContOfPort(dataplaneIPAddr, ovsPort, bridge_port, newVal, cont_iface);
		    remoteAddFlow2D(dataplaneIPAddr, bridge_port, extOFPort, contOFPort);
		    /*
		    //Local Version
		    startContainer(newVal, cont_image);
		    installOVSBridge(bridge_name);
		    addExternalPort(bridge_name, external_iface);
		    addContainerPort(bridge_name, newVal, cont_iface, new String("10.1.3.1/16"));
		    String extOFPort=findExternalOfPort(bridge_name, external_iface);
		    String contOFPort=findContOfPort(bridge_name, newVal, cont_iface);
		    addFlow2D(bridge_name, extOFPort, contOFPort);
		    */
		}
	    }
	    else if(rootNode.getModificationType()==DataObjectModification.ModificationType.DELETE) {
	    }
	}
    }

    private boolean inList(List l1, String testStr) {
	int index = l1.indexOf(testStr);
	if(index>=0)
	    return true;
	else
	    return false;
    }

    private void startContainer(String name, String image) {
	String cmd = String.format("/usr/bin/sudo /usr/bin/docker run -itd --name %s %s", name, image);
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	containerNames.add(name);
	System.out.println("New Container Started "+name);
    }

    private void remoteStartContainer(String ip, String docker_port, String cont_name, String container_image) {
	String cmd = String.format("/usr/bin/curl -s -X POST -H \"Content-Type: application/json\" http://%s:%s/v1.37/containers/create?name=%s -d \'{\"Image\": \"%s\", \"Cmd\": [\"/bin/sh\"], \"HostConfig\": {\"AutoRemove\": true}, \"Tty\": true}\'", ip, docker_port, cont_name, container_image);
	String[] newCmd = {"/bin/sh", "-c", cmd};
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(newCmd);
	System.out.println(output);
	
	cmd=String.format("/usr/bin/curl -s -X POST http://%s:%s/v1.37/containers/%s/start", ip, docker_port, cont_name);
	String[] newCmd2={"/bin/sh", "-c", cmd};
	output=obj.exeCmd(newCmd2);
	System.out.println(output);

	containerNames.add(cont_name);
	System.out.println("New Container Started "+cont_name);
    }    

    private void installOVSBridge(String name){
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --may-exist add-br %s", name);
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	System.out.println("Added Bridge "+name);
    }

    private void remoteInstallOVSBridge(String ip, String ovs_port, String name){
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --db=tcp:%s:%s --may-exist add-br %s", ip, ovs_port, name);
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	System.out.println("Added Bridge "+name);
    }    

    private void addExternalPort(String bridge, String iface){
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --may-exist add-port %s %s -- set Interface %s ofport_request=1", bridge, iface, iface);
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	System.out.println("Added port: to bridge "+bridge+" for interface "+iface);
    }

    private void remoteAddExternalPort(String ip, String ovs_port, String bridge, String iface){
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --db=tcp:%s:%s --may-exist add-port %s %s -- set Interface %s ofport_request=1", ip, ovs_port, bridge, iface, iface);
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	System.out.println("Added port: to bridge "+bridge+" for interface "+iface);
    }    

    private void addContainerPort(String bridge, String name, String iface) {
	String cmd = String.format("/usr/bin/sudo /usr/bin/ovs-docker add-port %s %s %s", bridge, iface, name);
	ExecShellCmd obj = new ExecShellCmd();
	String output = obj.exeCmd(cmd);
	System.out.println("Added interface "+iface+" to container "+name);
    }

    private void remoteAddContainerPort(String bridge, String name, String iface, String ip, String ovs_port, String docker_port, String cont_ip) {
	String ip_arg=String.format("--ipaddress=%s", cont_ip);
	try {
	    ProcessBuilder pb = new ProcessBuilder("/users/slab/IoT_Sec_Gateway/ovs_remote/ovs-docker-remote", "add-port", bridge, iface, name, ip, ovs_port, docker_port, ip_arg);
	    Process p = pb.start();
	    int errCode=p.waitFor();
	} catch (InterruptedException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}
	System.out.println("Added interface "+iface+" to container "+name);
    }

    private void addContainerPort(String bridge, String name, String iface, String ip) {
	String cmd = String.format("/usr/bin/sudo /usr/bin/ovs-docker add-port %s %s %s --ipaddress=%s", bridge, iface, name, ip);
	ExecShellCmd obj = new ExecShellCmd();
	String output = obj.exeCmd(cmd);
	System.out.println("Added interface "+iface+" to container "+name);
    }    

    private void remoteAddContainerPort(String bridge, String name, String iface, String ip, String ovs_port, String docker_port) {
	try {
	    ProcessBuilder pb = new ProcessBuilder("/users/slab/IoT_Sec_Gateway/ovs_remote/ovs-docker-remote", "add-port", bridge, iface, name, ip, ovs_port, docker_port);
	    Process p = pb.start();
	    int errCode=p.waitFor();
	} catch (InterruptedException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}	
	System.out.println("Added interface "+iface+" to container "+name);
    }    
    

    private String findContOfPort(String bridge, String name, String iface) {
	String cmd = String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --data=bare --no-heading --columns=name find interface external_ids:container_id=%s external_ids:container_iface=%s", name, iface);
	ExecShellCmd obj = new ExecShellCmd();
	String ovsPort=obj.exeCmd(cmd);
	ovsPort=ovsPort.replaceAll("\n","");
	System.out.println("OVS Port: "+ovsPort);

	cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl show %s | grep %s | awk -F '(' '{ print $1 }' | sed 's/ //g'", bridge, ovsPort);
	String[] pipeCmd={"/bin/sh", "-c", cmd};
	String ofPort=obj.exeCmd(pipeCmd);
	ofPort=ofPort.replaceAll("\n","");
	System.out.println("OF Port: "+ofPort);
	return ofPort;
    }


    private String remoteFindContOfPort(String ip, String ovs_port, String bridge_remote_port, String name, String iface) {
	String cmd = String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --db=tcp:%s:%s --data=bare --no-heading --columns=name find interface external_ids:container_id=%s external_ids:container_iface=%s", ip, ovs_port, name, iface);
	ExecShellCmd obj = new ExecShellCmd();
	String ovsPort=obj.exeCmd(cmd);
	ovsPort=ovsPort.replaceAll("\n","");
	System.out.println("OVS Port: "+ovsPort);

	cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl show tcp:%s:%s | grep %s | awk -F '(' '{ print $1 }' | sed 's/ //g'", ip, bridge_remote_port, ovsPort);
	String[] pipeCmd={"/bin/sh", "-c", cmd};
	String ofPort=obj.exeCmd(pipeCmd);
	ofPort=ofPort.replaceAll("\n","");
	System.out.println("OF Port: "+ofPort);
	return ofPort;
    }
    
    private String findExternalOfPort(String bridge, String iface) {
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl show %s | grep %s | awk -F '(' '{ print $1 }' | sed 's/ //g'", bridge, iface);
	String[] pipeCmd={"/bin/sh", "-c", cmd};
	ExecShellCmd obj = new ExecShellCmd();
	String ofPort=obj.exeCmd(pipeCmd);
	ofPort=ofPort.replaceAll("\n","");
	System.out.println("OF Port: "+ofPort);
	return ofPort;
    }

	private String remoteFindExternalOfPort(String ip, String bridge_remote_port, String iface) {
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl show tpc:%s:%s | grep %s | awk -F '(' '{ print $1 }' | sed 's/ //g'", ip, bridge_remote_port, iface);
	String[] pipeCmd={"/bin/sh", "-c", cmd};
	ExecShellCmd obj = new ExecShellCmd();
	String ofPort=obj.exeCmd(pipeCmd);
	ofPort=ofPort.replaceAll("\n","");
	System.out.println("OF Port: "+ofPort);
	return ofPort;
    }    

    private void addFlow(String bridge, String in_port, String out_port) {
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl add-flow %s 'priority=100 in_port=%s actions=output:%s'", bridge, in_port, out_port);
	ExecShellCmd obj = new ExecShellCmd();
	String output = obj.exeCmd(cmd);
	System.out.println("Added flow "+in_port+" to "+out_port);
    }
    
    private void remoteAddFlow(String ip, String remote_bridge_port, String in_port, String out_port) {
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl add-flow tcp:%s:%s 'priority=100 in_port=%s actions=output:%s'", ip, remote_bridge_port, in_port, out_port);
	ExecShellCmd obj = new ExecShellCmd();
	String output = obj.exeCmd(cmd);
	System.out.println("Added flow "+in_port+" to "+out_port);
    }
    
    private void addFlow2D(String bridge, String port1, String port2) {
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl add-flow %s 'priority=100 in_port=%s actions=output:%s'", bridge, port1, port2);
	ExecShellCmd obj = new ExecShellCmd();
	String output = obj.exeCmd(cmd);
	cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl add-flow %s 'priority=100 in_port=%s actions=output:%s'", bridge, port2, port1);
	output = obj.exeCmd(cmd);
	System.out.println("Added flow "+port1+" <==> "+port2);
    }

    private void remoteAddFlow2D(String ip, String remote_bridge_port, String port1, String port2) {
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl add-flow tcp:%s:%s 'priority=100 in_port=%s actions=output:%s'", ip, remote_bridge_port, port1, port2);
	ExecShellCmd obj = new ExecShellCmd();
	String output = obj.exeCmd(cmd);
	cmd=String.format("/usr/bin/sudo /usr/bin/ovs-ofctl add-flow tcp:%s:%s 'priority=100 in_port=%s actions=output:%s'", ip, remote_bridge_port, port2, port1);
	output = obj.exeCmd(cmd);
	System.out.println("Added flow "+port1+" <==> "+port2);
    }    

    private void setupRemoteSwitch(String ip, String ovs_port, String bridge, String remote_bridge_port) {
	String cmd=String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --db=tcp:%s:%s set-controller %s ptcp:%s");
	ExecShellCmd obj = new ExecShellCmd();
	String output = obj.exeCmd(cmd);
	System.out.println("Setup bridge "+bridge+" for remote operation, listening on port "+remote_bridge_port);
    }

    private void shutdownContainer(String name) {
	ExecShellCmd obj = new ExecShellCmd();
	String cmd = String.format("/usr/bin/sudo /usr/bin/docker kill %s", name);
	String output=obj.exeCmd(cmd);
	cmd = String.format("/usr/bin/sudo /usr/bin/docker rm %s", name);
	output=obj.exeCmd(cmd);
	cmd = String.format("/usr/bin/sudo /usr/bin/ovs-docker del-ports %s %s", bridge_name, name);
	output=obj.exeCmd(cmd);
    }

    private void remoteShutdownContainer(String ip, String docker_port, String name, String bridge, String ovs_port) {
	ExecShellCmd obj = new ExecShellCmd();
	String cmd = String.format("/usr/bin/curl -s -X POST http://%s:%s/v1.37/containers/%s/kill", ip, docker_port,  name);
	String[] newCmd = {"/bin/bash", "-c", cmd};
	String output=obj.exeCmd(newCmd);
	try {
	    ProcessBuilder pb = new ProcessBuilder("/users/slab/IoT_Sec_Gateway/ovs_remote/ovs-docker-remote", "del-ports", bridge, name, ip, ovs_port, docker_port);
	    Process p = pb.start();
	    int errCode=p.waitFor();
	} catch (InterruptedException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}
    }    

    private void removeBridges() {
	String cmd = String.format("/usr/bin/sudo /usr/bin/ovs-ofctl del-flows %s", bridge_name);
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	cmd = String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --if-exists del-br %s", bridge_name);
	output=obj.exeCmd(cmd);
    }

    private void remoteRemoveBridges(String ip, String remote_bridge_port, String bridge, String ovs_port) {
	String cmd = String.format("/usr/bin/sudo /usr/bin/ovs-ofctl del-flows tcp:%s:%s", ip, remote_bridge_port);
	ExecShellCmd obj = new ExecShellCmd();
	String output=obj.exeCmd(cmd);
	cmd = String.format("/usr/bin/sudo /usr/bin/ovs-vsctl --db=tcp:%s:%s --if-exists del-br %s", ip, ovs_port, bridge);
	output=obj.exeCmd(cmd);
    }    
    
}
