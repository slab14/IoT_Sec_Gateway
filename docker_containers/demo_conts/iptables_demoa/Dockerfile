FROM ubuntu:xenial

RUN apt-get update && \
    apt-get -y full-upgrade && \
    apt-get install -yqq python python-pip ulogd \
    net-tools bridge-utils iproute2 iptables \
    arptables tcpdump gcc libssl-dev

RUN pip install watchdog

COPY run.sh run.sh
COPY ulogd.conf /etc/ulogd.conf
COPY getAlerts.py sendAlert.c /

ENTRYPOINT ["/run.sh"]
