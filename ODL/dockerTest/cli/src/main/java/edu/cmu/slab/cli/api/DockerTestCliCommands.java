/*
 * Copyright © 2017 slab and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package edu.cmu.slab.cli.api;

public interface DockerTestCliCommands {

    /**
     * Define the Karaf command method signatures and the Javadoc for each.
     * Below method is just an example
     */
    Object testCommand(Object testArgument);
}
