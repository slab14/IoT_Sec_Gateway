/*
 * Copyright © 2017 slab and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package edu.cmu.slab.impl;

import java.io.BufferedReader;
import java.io.InputStreamReader;

public class ExecShellCmd {
    public String exeCmd(String cmd) {
	StringBuffer output = new StringBuffer();
	Process p;
	try {
	    p = Runtime.getRuntime().exec(cmd);
	    p.waitFor();
	    BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
	    String line = "";
	    while((line=reader.readLine())!=null) {
		output.append(line+"\n");
	    }
	    p.destroy();
	} catch(Exception e) {
	    e.printStackTrace();
	}
	return output.toString();
    }
}
