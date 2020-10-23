FROM ubuntu:xenial

RUN apt-get update && \
    apt-get upgrade -yqq && \
    apt-get install -yqq cmake make gcc g++ \
    	    	    	 flex bison libpcap-dev libssl-dev \
			 python-dev swig zlib1g-dev \
			 git wget bash tcpdump iptables \
			 net-tools bridge-utils libssl-dev \
			 bro openjdk-8-jre openjdk-8-jdk \
			 python python-pip
			 
RUN pip install watchdog

COPY sendAlert.c getAlerts.py Bro2Model.java printer_http.zeek U.pcapng D.pcapng run.sh /

ENTRYPOINT ["/run.sh"]