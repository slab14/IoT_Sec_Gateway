#include <stdio.h>
#include <stdlib.h>
#include <jni.h>

JNIEXPORT void JNICALL Java_slab_helloworld_NativeStuff_helloNative(JNIEnv *env, jobject obj) {
  printf("Hello from C!");
}
