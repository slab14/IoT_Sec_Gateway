#!/bin/bash

USERNAME=$1
PASSWORD=$2

if [[ -z "$USERNAME" ]]; then
    USERNAME=tommy
fi

if [[ -z "$PASSWORD" ]]; then
    PASSWORD=iotsec
fi

chmod +x /etc/squid/passwords
htpasswd -b -c /etc/squid/passwords $USERNAME $PASSWORD
chmod o+r /etc/squid/passwords

