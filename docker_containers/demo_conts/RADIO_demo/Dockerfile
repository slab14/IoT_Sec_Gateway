FROM ubuntu:xenial

ENV DAQ_VER=2.0.7 \
    SNORT_VER=2.9.16.1

# Install Dependencies
RUN apt-get update && \
	apt-get upgrade -yqq && \
    apt-get install -yqq build-essential autotools-dev bison flex gcc \
    	    	    	 libdumbnet-dev liblzma-dev libpcap-dev libpcre3-dev \
			 libssl-dev libluajit-5.1-dev pkg-config make  wget \
			 openssl zlib1g-dev libwlocate-dev cmake libtool \
			 autoconf libnetfilter-queue-dev libnghttp2-dev \
			 python python-pip libsqlite3-dev uuid-dev ethtool \
			 iptables libnetfilter-queue1 bridge-utils iproute2 \
			 net-tools tcpdump libffi-dev libncurses5-dev zlib1g-dev \
			 libgdbm-dev libnss3-dev libreadline-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 
# Install additional dependencies
RUN wget https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tar.xz && \
	tar -xf Python-3.6.9.tar.xz && \
	cd Python-3.6.9 && \
	./configure --enable-optimizations && \
	make && \
	make altinstall

# tools for sending alerts
RUN pip install watchdog
RUN mkdir /etc/radio

COPY run.sh getAlerts.py sendAlert.c addHash.c checkHash.c model2rule.py /

ENTRYPOINT ["/run.sh"]
