package slab.helloworld;

import slab.helloworld.utils.JavaUtils;

public class NativeStuff {

    static {
	JavaUtils.loadLibrary("libexample.so");
    }
    
    public native void helloNative();

}
	      
