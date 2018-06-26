NAME=$1
IP=$2

curl -X PUT -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     --user admin:admin \
     -d '{"dockerTest":{"name":"'$NAME'"}}' \
     http://$IP:8181/restconf/config/dockerTest:dockerTest 
