NAME=$1

curl -X PUT -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     --user admin:admin \
     -d '{"dockerTest":{"name":"'$NAME'"}}' \
     http://localhost:8181/restconf/config/dockerTest:dockerTest 
