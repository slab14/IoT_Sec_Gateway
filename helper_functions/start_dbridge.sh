NAME=$1

sudo docker run -itd --rm --network=none --privileged --name $NAME d_bridge
