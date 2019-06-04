NAME=$1

sudo docker run -itd --rm --network=none --cap-add=NET_ADMIN --name $NAME kitsune_socket
