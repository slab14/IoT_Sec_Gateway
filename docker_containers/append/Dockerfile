FROM ubuntu:xenial


# Install Dependencies
RUN apt-get update && \
    apt-get install -yqq python-dev libpcap-dev net-tools \
    	    	    	 bridge-utils iproute2 iptables \
			 tcpdump python libnetfilter-queue1 \
			 libnetfilter-queue-dev python-pip \
			 build-essential python-dev gcc \
			 libssl-dev ethtool

RUN pip install NetfilterQueue 

COPY pyscript.py packetAppend.c checkHash.c addHash.c run.sh ./

ENTRYPOINT ["/run.sh"]

