#!/bin/bash

remote_sig_AS="17-ffaa:1:d13"
remote_sig_IPnet="172.16.12.0"

while true; do
    grep -q '^1$' "/sys/class/net/eth0/carrier" &&
	break

    sleep 1

done

scionlab-config --host-id=72805bf4c956422b9a087af7ff512628 --host-secret=ce3462d2903347059aa1fae225e74ca4
systemctl start scionlab.target

SC=/etc/scion
LOG=/var/log/scion
ISD=$(ls /etc/scion/gen/ | grep ISD | awk -F 'ISD' '{ print $2 }')
AS=$( ls /etc/scion/gen/ISD${ISD}/ | grep AS | awk -F 'AS' '{ print $2 }')
IAd=$(echo $AS | sed 's/_/\:/g')
IA=${ISD}-${AS}

mkdir -p ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/

touch ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
cat sig.config | tee -a ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${IA}/${IA}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${IAd}/${IAd}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${AS}/${AS}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${ISD}/${ISD}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${SC}/\/etc\/scion/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${LOG}/${LOG}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${sigID}/${sigID}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config
sed -i "s/\${sigIP}/${sigIP}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config   

touch ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.json
cat sig.json | tee -a ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.json
sed -i "s/\${remote_sig_AS}/${remote_sig_AS}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.json
sed -i "s/\${remote_sig_IPnet}/${remote_sig_IPnet}/g" ${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.json

sed -i "s/\${ISD}/${ISD}/g" topology.json
sed -i "s/\${IAd}/${IAd}/g" topology.json

sed -i '/$IAd/e cat topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/endhost/topology.json
sed -i '/$IAd/e cat topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/br${IA}-1/topology.json
sed -i '/$IAd/e cat topology.json' ${SC}/gen/ISD${ISD}/AS${AS}/cs${IA}-1/topology.json

ip link add dummy11 type dummy
ip addr add ${sigIP}/32 brd + dev dummy11 label dummy11:0
ip rule add to ${remote_sig_IPnet} lookup 11 prio 11

ip link add client type dummy
ip addr add ${sigIP}/24 brd + dev client label client:0


/bin/bash $GOPATH/bin/sig -config=${SC}/gen/ISD${ISD}/AS${AS}/sig${IA}-1/${sigID}.config &
