#!/bin/bash

if [ -z $1 ]; then
    PORT=4243
else
    PORT=$1
fi

sudo sed -i 's/fd\:\/\// fd\:\/\/ \-H tcp\:\/\/0\.0\.0\.0\:'"$PORT"'/g' /lib/systemd/system/docker.service

sudo systemctl daemon-reload

sudo service docker restart

curl http://localhost:4243/version
