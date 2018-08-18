#!/bin/bash

if [[ -z "$USERNAME" ]]; then
    USERNAME="tommy"
fi

if [[ -z "$PASSWORD" ]]; then
    PASSWORD="iotsec"
fi

if [[ -z "$REALM" ]]; then
    REALM="proxy"
fi

#htpasswd -b -c /etc/squid/passwords $USERNAME $PASSWORD
chmod +x genPwdFile.sh
source /genPwdFile.sh /etc/squid/passwords $USERNAME $PASSWORD $REALM
chmod o+r /etc/squid/passwords

exec "$@"
