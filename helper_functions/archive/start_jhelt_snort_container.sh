NAME=$1

sudo docker run -itd --rm --network=none --name $NAME jhelt/snort
