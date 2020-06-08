FROM ubuntu:xenial

RUN apt-get update && \
    apt-get -y full-upgrade && \
    apt-get install -yqq python python-pip ulogd vim net-tools bridge-utils iproute2 iptables arptables tcpdump


RUN pip install watchdog

COPY run.sh run.sh
COPY ulogd.conf /etc/ulogd.conf
COPY getAlerts.py /getAlerts.py

ENTRYPOINT ["/run.sh"]
