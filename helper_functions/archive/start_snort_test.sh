NAME=$1

sudo docker run -itd --rm --network=none --name $NAME snort_flowbits
