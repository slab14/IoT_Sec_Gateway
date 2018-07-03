/*
 * Copyright © 2018 sLab and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package edu.cmu.slab.impl;

import org.opendaylight.controller.sal.binding.api.NotificationProviderService;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.cmu.slab.impl.flow.FlowWriterServiceImpl;
import edu.cmu.slab.impl.flow.InitialFlowWriter;
import edu.cmu.slab.impl.flow.ReactiveFlowWriter;
import edu.cmu.slab.impl.inventory.InventoryReader;
import org.opendaylight.yangtools.concepts.Registration;

import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.SalFlowService;

public class SwitchDemoProvider {

    private static final Logger LOG = LoggerFactory.getLogger(SwitchDemoProvider.class);

    private final DataBroker dataBroker;
    private final NotificationProviderService notificationService;

    private final SalFlowService salFlowService;
    private Registration topoNodeListherReg = null, reactFlowWriterReg = null;

    public SwitchDemoProvider(final DataBroker dataBroker, final NotificationProviderService notificationService,
			      final SalFlowService salFlowService) {
        this.dataBroker = dataBroker;
	this.notificationService = notificationService;
	this.salFlowService = salFlowService;
    }

    /**
     * Method called when the blueprint container is created.
     */
    public void init() {
	System.out.println("SwitchDemoProvider init() called");
	FlowWriterServiceImpl flowWriterService = new FlowWriterServiceImpl(salFlowService);
	flowWriterService.setFlowTableId((short)0);
	flowWriterService.setFlowPriority(0);
	flowWriterService.setFlowIdleTimeout(0);
	flowWriterService.setFlowHardTimeout(0);
	InventoryReader inventoryReader = new InventoryReader(dataBroker);
	InitialFlowWriter initialFlowWriter = new InitialFlowWriter(salFlowService);
	initialFlowWriter.setFlowTableId((short)0);
	initialFlowWriter.setFlowPriority(0);
	initialFlowWriter.setFlowIdleTimeout(0);
	initialFlowWriter.setFlowHardTimeout(0);
	topoNodeListherReg = initialFlowWriter.registerAsDataChangeListener(dataBroker);
	ReactiveFlowWriter reactiveFlowWriter = new ReactiveFlowWriter(inventoryReader, flowWriterService);
	reactFlowWriterReg = notificationService.registerNotificationListener(reactiveFlowWriter);
        LOG.info("SwitchDemoProvider Session Initiated");
    }

    /**
     * Method called when the blueprint container is destroyed.
     */
    public void close() throws Exception {
	//if (decoders != null && !decoders.isEmpty()) {
        //    for (AbstractPacketDecoder decoder : decoders) {
        //        decoder.close();
        //    }
	//}
        LOG.info("SwitchDemoProvider Closed");
    }
}
