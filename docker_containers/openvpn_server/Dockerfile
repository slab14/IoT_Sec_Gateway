FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq net-tools bridge-utils iproute2 \
    iptables arptables tcpdump openvpn netcat iputils-ping

COPY run.sh key.secret /

ENTRYPOINT ["/run.sh"]
