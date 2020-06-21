#!/bin/bash

#gcc -fPIC -shared -o send.so sendQuote.c -lcrypto
gcc -I ./include -fPIC -shared -o send.so sendHypQuote.c -ldl lib/libuhcall.a

gcc -I ./include -fPIC -shared -o pcr.so hypTPM.c -ldl lib/libuhcall.a
