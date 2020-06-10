FROM ubuntu:xenial

RUN apt-get update && \
    apt-get -y full-upgrade && \
    apt-get install -yqq python python-pip ulogd vim net-tools bridge-utils iproute2 iptables arptables tcpdump

#CMD ["sh", "-c", "service rsyslog start ; tail -f /dev/null"]
#RUN sysctl -w net.ipv4.ip_forward=1 && \
#    iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT && \
#    iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT 

#CMD ["sh", "-c", "iptables -A FORWARD -s 10.1.1.0/24 -j NFLOG --nflog-prefix 'iptables: ' --nflog-group 1"]
RUN pip install watchdog

COPY run.sh run.sh
COPY ulogd.conf /etc/ulogd.conf
COPY getAlerts.py /getAlerts.py

ENTRYPOINT ["/run.sh"]
