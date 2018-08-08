#!/bin/bash

sudo /usr/testbed/bin/mkextrafs /mnt 

sudo chown $USER:`id -gn` /mnt
