#!/bin/bash

sudo sed -i 's/fd\:\/\// fd\:\/\/ \-H tcp\:\/\/0\.0\.0\.0\:4243/g' /lib/systemd/system/docker.service

sudo systemctl daemon-reload

sudo service docker restart

curl http://localhost:4243/version
