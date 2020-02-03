FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq net-tools bridge-utils iproute2 iptables arptables tcpdump iputils-ping python

COPY run.sh counter.py /

ENTRYPOINT ["/run.sh"]
