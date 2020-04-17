package slab.helloworld;

import slab.helloworld.NativeStuff;

public class HelloWorld {
	public static void main(String args[]){
		System.out.println("Hello World, Maven");

		new NativeStuff().helloNative();
	}
}
