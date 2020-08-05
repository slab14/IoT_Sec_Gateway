FROM ubuntu:xenial

RUN apt-get update && \
    apt-get -y full-upgrade && \
    apt-get install -yqq iputils-ping netcat nmap vim net-tools \
    	    bridge-utils iproute2  iptables arptables tcpdump \
    	    build-essential autotools-dev bison flex gcc \
    	    libdumbnet-dev liblzma-dev libpcap-dev libpcre3-dev \
	    libssl-dev libluajit-5.1-dev pkg-config make  wget \
	    openssl zlib1g-dev libwlocate-dev cmake libtool \
	    autoconf libnetfilter-queue-dev libnghttp2-dev \
	    python python-pip libsqlite3-dev uuid-dev ethtool \
	    iptables libnetfilter-queue1 git
			 
RUN pip install watchdog

COPY run.sh run.sh

COPY getAlerts.py /getAlerts.py

COPY sendAlert.c addHash.c checkHash.c /

ENTRYPOINT ["/run.sh"]
