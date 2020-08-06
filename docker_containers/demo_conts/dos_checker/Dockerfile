FROM ubuntu:xenial

RUN apt-get update && \
    apt-get -y full-upgrade && \
    apt-get install -yqq iputils-ping netcat net-tools \
    	    bridge-utils iproute2  iptables arptables tcpdump \
	    build-essential autotools-dev gcc \
	    python python-pip ethtool libssl-dev \
	    iptables libnetfilter-queue1 libnetfilter-queue-dev \
	    emacs
	    
RUN pip install psutil watchdog

COPY conn_tester.py sendAlert.c addHash.c checkHash.c run.sh getAlerts.py sendAlert.py /

ENTRYPOINT ["/run.sh"]
