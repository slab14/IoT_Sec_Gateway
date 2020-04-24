package slab.helloworld;

import java.util.Arrays;
import slab.helloworld.NativeStuff;

public class HelloWorld {
	public static void main(String args[]){
		System.out.println("Hello World, Maven");

		NativeStuff cfunc = new NativeStuff();

		//new NativeStuff().helloNative();
		cfunc.helloNative();

		System.out.println("Adding result = " + cfunc.add(1,2));

	        byte[] inData = "abcdefghijklmnop".getBytes();
		int len=inData.length;
		System.out.println("hypercall input: "+Arrays.toString(inData));

		byte[] outData = new byte[len];
		
		outData = cfunc.hypcall(inData, len);

		System.out.println("HypCall Result = " + Arrays.toString(outData));

	}
}
