NAME=$1
ACTION=$2
ODL_IP=$3
CONT_IP=$4

curl -X PUT -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     --user admin:admin \
     -d '{"dockerTest":{"action": "'$ACTION'", "name":"'$NAME'", "address": "'$CONT_IP'"}}' \
     http://$ODL_IP:8181/restconf/config/dockerTest:dockerTest

## actions = add | del
