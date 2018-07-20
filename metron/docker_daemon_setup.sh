#!/bin/bash

# make docker able to run without sudo preface
sudo usermod -a -G docker $USER

# save docker images outside of / filesystem
## TODO: not working
sudo sed -i 's/\-H fd:\/\//\-H fd:\/\/ -g \/mnt/g' /lib/systemd/system/docker.service
#echo 'DOCKER_OPTS="-g /mnt"' | sudo tee -a /etc/default/docker
#sudo service docker restart

