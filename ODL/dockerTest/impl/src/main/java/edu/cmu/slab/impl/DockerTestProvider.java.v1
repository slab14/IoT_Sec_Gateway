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

public class DockerTestProvider implements DataTreeChangeListener<DockerTest> {
    private boolean firstUse=true;
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

    /**
     * Method called when the blueprint container is created.
     */
    public void init() {
	dataTreeChangeListenerRegistration = dataBroker.registerDataTreeChangeListener(new DataTreeIdentifier<>(CONFIGURATION, DOCKER_TEST_IID), this);
        LOG.info("DockerTestProvider Session Initiated");
    }

    /**
     * Method called when the blueprint container is destroyed.
     */
    public void close() {
	System.out.println("Shutting down");
	String cmd1 = "/usr/bin/sudo /usr/bin/docker kill $(/usr/bin/sudo /usr/bin/docker ps -a -q)";
	String cmd2 = "/usr/bin/sudo /usr/bin/docker kill $(/usr/bin/sudo /usr/bin/docker ps -a -q)";	
	for(int i=0; i<2; i++) {
	    Process p;
	    String cmd;
	    if(i==0)
		cmd = cmd1;
	    else
		cmd=cmd2;
	    ExecShellCmd obj = new ExecShellCmd();
	    String output=obj.exeCmd(cmd);	    
	}
	System.out.println("Good-bye");
	LOG.info("DockerTestProvider Closed");
    }

    @Override
    public void onDataTreeChanged(Collection<DataTreeModification<DockerTest>> changes) {
	for(DataTreeModification<DockerTest> change: changes) {
	    DataObjectModification<DockerTest> rootNode = change.getRootNode();
	    if(rootNode.getModificationType()==DataObjectModification.ModificationType.WRITE) {
		System.out.println("Got a new input");
		DockerTest oldObj = rootNode.getDataBefore();
		DockerTest newObj = rootNode.getDataAfter();
		String oldVal = oldObj.getName();
		String newVal = newObj.getName();
		boolean usedPreviously = inList(containerNames, newVal);
		//if((!(oldVal.equals(newVal)) && !(oldVal.equals(null))) || (firstUse==true)) {
		if(!usedPreviously) {
		    //firstUse=false;
		    String cmd = String.format("/usr/bin/sudo /usr/bin/docker run -itd --name %s ubuntu", newVal);
		    ExecShellCmd obj = new ExecShellCmd();
		    String output=obj.exeCmd(cmd);
		    containerNames.add(newVal);
		    System.out.println("New Container Started");
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
}
