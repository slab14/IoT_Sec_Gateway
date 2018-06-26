IP=$1

curl -X DELETE -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     --user admin:admin \
     http://$IP:8181/restconf/config/dockerTest:dockerTest 
