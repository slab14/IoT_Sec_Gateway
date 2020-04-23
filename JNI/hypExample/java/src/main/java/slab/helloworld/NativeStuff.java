package slab.helloworld;

import slab.helloworld.utils.JavaUtils;

public class NativeStuff {

    static {
	JavaUtils.loadLibrary("libHypExample.so");
    }
    
    public native void helloNative();

    public native int add(int in_a, int in_b);

    public native byte[] hypcall(byte[] in, int len);

}
	      
