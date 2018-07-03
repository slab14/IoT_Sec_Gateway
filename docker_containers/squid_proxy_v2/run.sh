#!/bin/bash

if [[ -z "$USERNAME" ]]; then
    USERNAME=tommy
fi

if [[ -z "$PASSWORD" ]]; then
    PASSWORD=iotsec
fi

htpasswd -b -c -B /etc/squid/passwords $USERNAME $PASSWORD
chmod o+r /etc/squid/passwords

exec "$@"
