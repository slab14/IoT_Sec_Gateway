#!/bin/bash

gcc -fPIC -shared -o send.so sendQuote.c -lcrypto
