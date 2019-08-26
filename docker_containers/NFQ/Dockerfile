FROM ubuntu:xenial


# Install Dependencies
RUN apt-get update && \
    apt-get install -yqq python-dev libpcap-dev net-tools \
    	    	    	 bridge-utils iproute2 iptables \
			 tcpdump python libnetfilter-queue1 \
			 libnetfilter-queue-dev python-pip \
			 build-essential python-dev gcc \
			 libssl-dev

RUN pip install NetfilterQueue ecdsa

COPY pyscript.py packetFilterandHash.c run.sh ./

ENTRYPOINT ["/run.sh"]

