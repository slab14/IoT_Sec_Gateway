FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq net-tools bridge-utils iproute2 \
    iptables arptables tcpdump openvpn

COPY run.sh key.secret /

ENTRYPOINT ["/run.sh"]
