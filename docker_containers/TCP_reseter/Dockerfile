FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq net-tools bridge-utils iproute2 iptables arptables tcpdump iputils-ping python python-pip

RUN pip install scapy

COPY run.sh reset.py reset2.py /

#CMD ["reset.py", "-i" "eth0", "-o", "eth1"]

ENTRYPOINT ["/run.sh"]
