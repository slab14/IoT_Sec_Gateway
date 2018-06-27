/*
 * Copyright © 2018 sLab and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package edu.cmu.slab.cli.impl;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import edu.cmu.slab.cli.api.SwitchDemoCliCommands;

public class SwitchDemoCliCommandsImpl implements SwitchDemoCliCommands {

    private static final Logger LOG = LoggerFactory.getLogger(SwitchDemoCliCommandsImpl.class);
    private final DataBroker dataBroker;

    public SwitchDemoCliCommandsImpl(final DataBroker db) {
        this.dataBroker = db;
        LOG.info("SwitchDemoCliCommandImpl initialized");
    }

    @Override
    public Object testCommand(Object testArgument) {
        return "This is a test implementation of test-command";
    }
}