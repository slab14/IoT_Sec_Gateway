FROM ubuntu:xenial


# Install Dependencies
RUN apt-get update && \
    apt-get install -yqq libpcap-dev net-tools \
    	    	    	 bridge-utils iproute2 iptables \
			 tcpdump libnetfilter-queue1 \
			 libnetfilter-queue-dev \
			 build-essential gcc ethtool

COPY libuhcall.a uhcall.h checkHash.c addHash.c run.sh ./

ENTRYPOINT ["/run.sh"]

