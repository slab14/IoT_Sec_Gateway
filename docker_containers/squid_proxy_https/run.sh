#!/bin/bash

if [[ -z "$USERNAME" ]]; then
    USERNAME="tommy"
fi

if [[ -z "$PASSWORD" ]]; then
    PASSWORD="iotsec"
fi

htpasswd -b -c /etc/squid/passwords $USERNAME $PASSWORD
chmod o+r /etc/squid/passwords

mkdir -p /etc/squid/ssl_cert
chown proxy:proxy /etc/squid/ssl_cert
chmod 600 /etc/squid/ssl_cert
openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout /etc/squid/ssl_cert/myCA.pem  -out /etc/squid/ssl_cert/myCA.pem -subj "/C=US/ST=PA/L=PGH/O=IoT/OU=IoTproxy/CN=IoT/emailAddress=email@iot.com"
openssl x509 -in /etc/squid/ssl_cert/myCA.pem -outform DER -out /etc/squid/ssl_cert/myCA.der


exec "$@"
