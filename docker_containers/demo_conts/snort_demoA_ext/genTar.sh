#!/bin/bash

RULESFILE=$1
CONFIGFILE=$2

tar -cf rules.tar $RULESFILE
tar -cf conf.tar $CONFIGFILE
