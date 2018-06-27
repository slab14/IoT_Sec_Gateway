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

import com.google.common.collect.ImmutableSet;
import edu.cmu.slab.impl.decoders.AbstractPacketDecoder;
import edu.cmu.slab.impl.decoders.ArpDecoder;
import edu.cmu.slab.impl.decoders.EthernetDecoder;
import edu.cmu.slab.impl.decoders.IcmpDecoder;
import edu.cmu.slab.impl.decoders.Ipv4Decoder;
import edu.cmu.slab.impl.decoders.Ipv6Decoder;

public class SwitchDemoProvider {

    private static final Logger LOG = LoggerFactory.getLogger(SwitchDemoProvider.class);

    ImmutableSet<AbstractPacketDecoder> decoders;

    private final DataBroker dataBroker;
    private final NotificationProviderService notificationService;

    public SwitchDemoProvider(final DataBroker dataBroker, final NotificationProviderService notificationService) {
        this.dataBroker = dataBroker;
	this.notificationService = notificationService;
    }

    /**
     * Method called when the blueprint container is created.
     */
    public void init() {
	decoders = new ImmutableSet.Builder<AbstractPacketDecoder>()
                .add(new EthernetDecoder(notificationService))
                .add(new ArpDecoder(notificationService)).add(new Ipv4Decoder(notificationService))
                .add(new Ipv6Decoder(notificationService)).add(new IcmpDecoder(notificationService)).build();
        LOG.info("SwitchDemoProvider Session Initiated");
    }

    /**
     * Method called when the blueprint container is destroyed.
     */
    public void close() throws Exception {
	if (decoders != null && !decoders.isEmpty()) {
            for (AbstractPacketDecoder decoder : decoders) {
                decoder.close();
            }
	}
        LOG.info("SwitchDemoProvider Closed");
    }
}
